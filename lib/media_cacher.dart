import 'package:flutter/services.dart';
import 'package:flutter_video_test/media_link.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'dart:developer';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'package:dio/dio.dart';
import 'package:idb_shim/idb_browser.dart';

class MediaCacher {
  MediaCacher({Dio? dio}) : _dio = dio ?? Dio();
  final Dio _dio;
  final _factory = getIdbFactory();

  // Cache for blob URLs to avoid creating multiple blob URLs for the same media.
  //  and for later retrieval of the same blob URL without re-fetching from IndexedDB.
  final Map<String, Future<String>> _blobUrlCache = {};
  Database? _db;

  // Returns IndexedDB for storage in web.
  Future<Database> get database async {
    if (_db != null) return _db!;

    _db = await _factory!.open(
      'media_cache',
      version: 3,
      onUpgradeNeeded: (VersionChangeEvent e) {
        final db = e.database;
        if (db.objectStoreNames.contains('videos')) {
          db.deleteObjectStore('videos');
        }
        db.createObjectStore('videos');
        if (!db.objectStoreNames.contains('images')) {
          db.createObjectStore('images', autoIncrement: true);
        }
      },
    );

    return _db!;
  }

  // Go through the list to download/cache all media.
  Future<List<MediaLink>> cacheAllMedia({
    required List<MediaLink> links,
  }) async {
    final downloadedLinks = <MediaLink>[];
    DefaultCacheManager().emptyCache();

    for (final media in links) {
      final path = media.type == 'image'
          ? await _cacheWebImage(_getTemporaryId(media.link), media.link, null)
          : await _cacheWebVideo(_getTemporaryId(media.link), media.link, null);

      downloadedLinks.add(
        MediaLink(
          link: media.link,
          type: media.type,
          duration: media.duration,
          blobUrl: path,
          id: _getTemporaryId(media.link),
        ),
      );
    }

    return downloadedLinks;
  }

  // Give the name of the file back as id.
  String _getTemporaryId(String link) {
    final path = Uri.parse(link).pathSegments.last;

    final extensionIndex = path.lastIndexOf('.');
    final name = extensionIndex == -1
        ? path
        : path.substring(0, extensionIndex);

    try {
      return Uri.decodeComponent(name);
    } catch (_) {
      return name;
    }
  }

  // Turn the bytes into a blob.
  Future<String> _createBlobUrl(
    Uint8List bytes, {
    String contentType = 'video/mp4',
  }) async {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: contentType),
    );

    return web.URL.createObjectURL(blob);
  }

  // Put video into IndexedDB
  // // Change to download to cache.
  // // Out of memory issue encountered on Firestick.
  Future<String> _cacheWebVideo(
    String videoId,
    String url,
    void Function(double progress)? onProgress,
  ) async {
    // Check if video exists
    // If exists skip download part
    if (await containsMediaWeb('videos', videoId)) {
      final bytes = await getMediaWeb('videos', videoId);
      if (bytes != null && bytes.isNotEmpty) {
        return url;
      }
    }

    try {
      // Get video in bytes
      final response = await Dio().get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
        ), // Set the response type to `bytes`.
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('[media_downloader.dart] Failed to download video');
      }

      final bytes = Uint8List.fromList(response.data!);

      final db = await database;

      final txn = db.transaction('videos', idbModeReadWrite);
      final store = txn.objectStore('videos');

      await store.put({'bytes': bytes}, videoId);

      await txn.completed;
    } catch (e) {
      log('Error caching video: $e');
      rethrow;
    }

    return url; // Return the video ID for retrieval later
  }

  Future<String> loadVideoBlobUrlFromIndexedDB(String id) async {
    return _getOrCreateBlobUrl('videos:$id', () async {
      final bytes = await getMediaWeb('videos', id);
      if (bytes == null || bytes.isEmpty) {
        throw StateError(
          'Video bytes are missing or empty in IndexedDB for "$id".',
        );
      }

      return _createBlobUrl(bytes);
    });
  }

  // Load image from IndexedDB and return a blob URL.
  Future<String> loadImageBlobUrlFromIndexedDB(String id) async {
    return _getOrCreateBlobUrl('images:$id', () async {
      final bytes = await getMediaWeb('images', id);
      if (bytes == null || bytes.isEmpty) {
        throw StateError(
          'Image bytes are missing or empty in IndexedDB for "$id".',
        );
      }

      return _createBlobUrl(bytes, contentType: '');
    });
  }

  // Get or create a blob URL for the given key. 
  // // If the blob URL is already cached, return it. 
  // // Otherwise, create a new blob URL using the provided `create` function and cache it.
  Future<String> _getOrCreateBlobUrl(
    String key,
    Future<String> Function() create,
  ) async {
    final cached = _blobUrlCache[key];
    if (cached != null) return cached;

    final pending = create();
    _blobUrlCache[key] = pending;
    try {
      return await pending;
    } catch (_) {
      if (identical(_blobUrlCache[key], pending)) {
        _blobUrlCache.remove(key);
      }
      rethrow;
    }
  }

  // Put image into IndexedDB
  Future<String> _cacheWebImage(
    String imageId,
    String url,
    void Function(double progress)? onProgress,
  ) async {
    // Check if image exists in database.
    // If it does skip download part.
    if (await containsMediaWeb('images', imageId)) {
      final bytes = await getMediaWeb('images', imageId);
      if (bytes != null) {
        return url;
      }
    }

    // Get image in bytes format.
    final response = await Dio().get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
      ), // Set the response type to `bytes`.
    );

    if (response.statusCode != 200 || response.data == null) {
      throw Exception('[media_downloader.dart] Failed to download image');
    }

    final bytes = Uint8List.fromList(response.data!);

    final db = await database;

    final txn = db.transaction('images', idbModeReadWrite);
    final store = txn.objectStore('images');

    await store.put({'bytes': bytes}, imageId);

    await txn.completed;

    return url; // Return the image url for retrieval later
  }

  // Get media from IndexedDB
  Future<Uint8List?> getMediaWeb(String store, String id) async {
    final db = await database;

    final transaction = db.transaction(store, idbModeReadOnly);

    final record = await transaction.objectStore(store).getObject(id);

    await transaction.completed;

    if (record is! Map) {
      return null;
    }

    final value = record['bytes'];
    if (value is Uint8List) {
      return value;
    }

    if (value is List<int>) {
      return Uint8List.fromList(value);
    }

    return null;
  }

  // Check if media exists in IndexedDB
  Future<bool> containsMediaWeb(String store, String id) async {
    final db = await database;

    final transaction = db.transaction(store, idbModeReadOnly);

    final record = await transaction.objectStore(store).getObject(id);

    await transaction.completed;

    return record != null;
  }

  // Delete media from IndexedDB
  Future<void> deleteMediaWeb(String store, String id) async {
    final db = await database;

    final transaction = db.transaction(store, idbModeReadWrite);

    await transaction.objectStore(store).delete(id);

    await transaction.completed;
  }
}

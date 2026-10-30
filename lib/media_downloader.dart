import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video_test/frame_link.dart';
import 'package:flutter_video_test/media_link.dart';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class MediaDownloader {
  MediaDownloader({Dio? dio}) : _dio = dio ?? Dio();
  final Dio _dio;

  Future<Directory> get downloadDirectory async {
    final directory = await getApplicationDocumentsDirectory();
    return directory;
  }

  Future<List<MediaLink>> loadDownloadedMedia() async {
    final order = await _loadOrder();
    final mediaEntries = order['media'] as List? ?? const [];
    final mediaLinks = <MediaLink>[];

    for (final entry in mediaEntries) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }

      final mediaId = entry['id'];
      if (mediaId is! String || mediaId.isEmpty) continue;

      final duration = entry['duration'] is num ? (entry['duration'] as num).toInt() : null;
      final localPath = entry['localPath'] is String ? entry['localPath'] as String : null;
      final link = entry['link'] is String ? entry['link'] as String : localPath;
      final type = entry['type'] is String ? entry['type'] as String : null;
      final filePath = localPath ?? await _findFileInDirectory(
        directoryName: type == 'video' ? 'videos' : 'images',
        mediaId: mediaId,
      );

      if (filePath == null || filePath.isEmpty) continue;

      mediaLinks.add(
        MediaLink(
          id: mediaId,
          link: link ?? filePath,
          type: type ?? (filePath.contains('/videos/') ? 'video' : 'image'),
          duration: duration,
          mimeType: entry['mimeType'] is String ? entry['mimeType'] as String : null,
          localPath: filePath,
        ),
      );
    }

    return mediaLinks;
  }

  Future<List<FrameLink>> loadDownloadedFrames() async {
    final order = await _loadOrder();
    final frameEntries = order['frames'] as List? ?? const [];
    final frameLinks = <FrameLink>[];

    for (final entry in frameEntries) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }

      final frameId = entry['id'];
      if (frameId is! String || frameId.isEmpty) continue;

      final duration = entry['duration'] is num ? (entry['duration'] as num).toInt() : null;
      final localPath = entry['localPath'] is String ? entry['localPath'] as String : null;
      final link = entry['link'] is String ? entry['link'] as String : localPath;
      final filePath = localPath ?? await _findFileInDirectory(
        directoryName: 'frames',
        mediaId: frameId,
      );
      if (filePath == null || filePath.isEmpty) continue;

      frameLinks.add(
        FrameLink(
          id: frameId,
          link: link ?? filePath,
          type: 'frame',
          duration: duration,
          mimeType: entry['mimeType'] is String ? entry['mimeType'] as String : null,
          localPath: filePath,
          creationType: entry['creationType'] is String ? entry['creationType'] as String : 'unknown',
          x1: entry['x1'] is num ? (entry['x1'] as num).toDouble() : 0,
          y1: entry['y1'] is num ? (entry['y1'] as num).toDouble() : 0,
          x2: entry['x2'] is num ? (entry['x2'] as num).toDouble() : 0,
          y2: entry['y2'] is num ? (entry['y2'] as num).toDouble() : 0,
        ),
      );
    }

    return frameLinks;
  }

  Future<void> _saveDownloadOrder({List<dynamic>? media, List<dynamic>? frames}) async {
    final directory = await downloadDirectory;
    final file = File('${directory.path}/download_order.json');
    final content = await _readOrderFile(file);

    final mediaOrder = <Map<String, dynamic>>[];
    if (media != null) {
      for (final item in media) {
        if (item is MediaLink) {
          mediaOrder.add({
            'id': item.id,
            'type': item.type,
            'duration': item.duration ?? 0,
            'localPath': item.localPath,
            'link': item.link,
            'mimeType': item.mimeType,
          });
        }
      }
    } else {
      mediaOrder.addAll(
        (content['media'] as List? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(),
      );
    }

    final frameOrder = <Map<String, dynamic>>[];
    if (frames != null) {
      for (final item in frames) {
        if (item is FrameLink) {
          frameOrder.add({
            'id': item.id,
            'type': item.type,
            'duration': item.duration ?? 0,
            'localPath': item.localPath,
            'link': item.link,
            'mimeType': item.mimeType,
            'creationType': item.creationType,
            'x1': item.x1,
            'y1': item.y1,
            'x2': item.x2,
            'y2': item.y2,
          });
        }
      }
    } else {
      frameOrder.addAll(
        (content['frames'] as List? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(),
      );
    }

    final serialized = <String, dynamic>{
      'media': mediaOrder,
      'frames': frameOrder,
    };

    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(serialized));
  }

  Future<Map<String, dynamic>> _readOrderFile(File file) async {
    if (!await file.exists()) {
      return <String, dynamic>{'media': <dynamic>[], 'frames': <dynamic>[]};
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map) {
        final media = decoded['media'] is List ? decoded['media'] as List : <dynamic>[];
        final frames = decoded['frames'] is List ? decoded['frames'] as List : <dynamic>[];
        return {
          'media': media,
          'frames': frames,
        };
      }
    } catch (_) {}

    return <String, dynamic>{'media': <dynamic>[], 'frames': <dynamic>[]};
  }

  Future<Map<String, dynamic>> _loadOrder() async {
    final directory = await downloadDirectory;
    final file = File('${directory.path}/download_order.json');
    return _readOrderFile(file);
  }

  Future<String?> _findFileInDirectory({
    required String directoryName,
    required String mediaId,
  }) async {
    final directory = await downloadDirectory;
    final targetDirectory = Directory('${directory.path}/$directoryName');
    if (!await targetDirectory.exists()) return null;

    final files = targetDirectory.listSync().whereType<File>();
    for (final file in files) {
      final name = file.uri.pathSegments.last;
      final baseName = name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name;
      if (baseName == mediaId) {
        return file.path;
      }
    }

    return null;
  }

  // Download all media gathered from media_sources
  Future<List<dynamic>> downloadAllMedia({
    required List<dynamic> links,
  }) async {
    final downloadedLinks = <dynamic>[];

    for (final media in links) {
      var path = '';
      debugPrint('(${media.type}) Downloaded ${media.link} as ${media.id!}');
      switch (media.type) {
        case 'image':
          path = await _downloadImage(link: media.link, name: media.id!);
          if (path == '') break;
          downloadedLinks.add(
            MediaLink(
              id: media.id,
              link: media.link,
              type: media.type,
              duration: media.duration,
              mimeType: media.mimeType,
              localPath: path,
            ),
          );
          break;
        case 'video':
          path = await _downloadVideo(link: media.link, name: media.id!);
          if (path == '') break;
          downloadedLinks.add(
            MediaLink(
              id: media.id,
              link: media.link,
              type: media.type,
              duration: media.duration,
              mimeType: media.mimeType,
              localPath: path,
            ),
          );
          break;
        case 'frame':
          path = await _downloadFrame(link: media.link, name: media.id!);
          if (path == '') break;
          downloadedLinks.add(
            FrameLink(
              id: media.id,
              link: media.link,
              type: media.type,
              duration: media.duration,
              mimeType: media.mimeType,
              localPath: path,
              creationType: media.creationType,
              x1: media.x1, x2: media.x2, y1: media.y1, y2: media.y2,
            ),
          );
          break;
        default:
          break;
      }
    }

    if (downloadedLinks.any((entry) => entry is MediaLink)) {
      await _saveDownloadOrder(
        media: downloadedLinks.whereType<MediaLink>().toList(),
      );
    }
    if (downloadedLinks.any((entry) => entry is FrameLink)) {
      await _saveDownloadOrder(
        frames: downloadedLinks.whereType<FrameLink>().toList(),
      );
    }

    return downloadedLinks;
  }

  // Start download on image
  Future<String> _downloadImage({
    required String link,
    required String name,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    // Get image directory
    final directory = await downloadDirectory;
    final imageDirectory = Directory('${directory.path}/images');
    final file = File('${imageDirectory.path}/$name.${_getFileExtension(link)}');

    try {
      if (!await file.exists()) {
        await imageDirectory.create(recursive: true);
        await _dio.download(
          link,
          file.path,
          onReceiveProgress: onReceiveProgress,
        );
      }
    } catch (e) {
      return '';
    }

    return file.path;
  }

  // Start download on video
  Future<String> _downloadVideo({
    required String link,
    required String name,
    void Function(int received, int total)? onReceiveProgress,
  }) async {

    // Get video directory
    final directory = await downloadDirectory;
    final videoDirectory = Directory('${directory.path}/videos');
    final file = File('${videoDirectory.path}/$name.${_getFileExtension(link)}');

    // File in assets folder
    if (!_checkHttp(link) && _checkAsset(link)){
      final byteData = await rootBundle.load(link);
      await file.writeAsBytes(
        byteData.buffer.asUint8List(),
        flush: true,
      );
      return file.path;
    }

    // File online
    try {
      if (!await file.exists()) {
        await videoDirectory.create(recursive: true);
        await _dio.download(
          link,
          file.path,
          onReceiveProgress: onReceiveProgress,
        );
      }
    } catch (e) {
      return '';
    }

    return file.path;
  }

  // Start download on frame
  Future<String> _downloadFrame({
    required String link,
    required String name,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    final directory = await downloadDirectory;
    final frameDirectory = Directory('${directory.path}/frames');
    final file = File('${frameDirectory.path}/$name.${_getFileExtension(link)}');

    try {
      if (!await file.exists()) {
        await frameDirectory.create(recursive: true);
        await _dio.download(
          link,
          file.path,
          onReceiveProgress: onReceiveProgress,
        );
      }
    } catch (e) {
      return '';
    }

    return file.path;
  }

  // Get the file name
  String _getFileExtension(String url) {
    return url.split('.').last;
  }

  // Check if video is a link
  bool _checkHttp(String link) {
    return link.contains('http');
  }

  // Check if video is an asset
  bool _checkAsset(String link) {
    return link.contains('assets/');
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video_test/classes/frame_link.dart';
import 'package:flutter_video_test/classes/frame_ticker_position.dart';
import 'package:flutter_video_test/classes/media_link.dart';

import 'package:dio/dio.dart';
import 'package:flutter_video_test/classes/ticker_link.dart';
import 'package:path_provider/path_provider.dart';

typedef FrameCoordinates = ({int x1, int x2, int y1, int y2, List<FrameTickerPosition> frameTickerPositions});

class MediaDownloader {
  MediaDownloader({Dio? dio}) : _dio = dio ?? Dio();
  final Dio _dio;

  Future<Directory> get downloadDirectory async {
    final directory = await getApplicationSupportDirectory();
    return directory;
  }

  Future<List<String>?> loadSavedTickerStrings(String tickerId) async {
    final directory = await downloadDirectory;
    final file = File('${directory.path}/tickers/$tickerId.txt');
    if (!await file.exists()) return null;
    return file.readAsLines();
  }

  Future<Map<String, FrameCoordinates>> loadSavedFrameCoordinates() async {
    final directory = await downloadDirectory;
    final file = File('${directory.path}/json/frame_coordinates.json');
    if (!await file.exists()) return {};

    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! List) {
      throw const FormatException('Frame coordinates must be a JSON list.');
    }

    final coordinates = <String, FrameCoordinates>{};
    for (final entry in decoded.whereType<Map<String, dynamic>>()) {
      final id = entry['id'];
      final x1 = entry['x1'];
      final x2 = entry['x2'];
      final y1 = entry['y1'];
      final y2 = entry['y2'];
      final frameTickerPositions = entry['frameTickerPositions'];
      if (id is! String ||
          id.isEmpty ||
          x1 is! num ||
          x2 is! num ||
          y1 is! num ||
          y2 is! num ||
          frameTickerPositions is! List) {
        continue;
      }

      final tickerPositions = <FrameTickerPosition>[];
      for (final position in frameTickerPositions) {
        if (position is Map<String, dynamic>) {
          tickerPositions.add(FrameTickerPosition.fromJson(position));
        }
      }

      coordinates[id] = (
        x1: x1.toInt(),
        x2: x2.toInt(),
        y1: y1.toInt(),
        y2: y2.toInt(),
        frameTickerPositions: tickerPositions,
      );
    }

    return coordinates;
  }

  Future<void> saveFrameCoordinates(
    Map<String, FrameCoordinates> coordinates,
  ) async {
    final directory = await downloadDirectory;
    final file = File('${directory.path}/json/frame_coordinates.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert([
        for (final entry in coordinates.entries)
          {
            'id': entry.key,
            'x1': entry.value.x1,
            'y1': entry.value.y1,
            'x2': entry.value.x2,
            'y2': entry.value.y2,
            'frameTickerPositions': entry.value.frameTickerPositions
                .map((position) => position.toJson())
                .toList(),
          },
      ]),
    );
  }

  Future<void> cleanupAppDirectory() async {
    final directory = await downloadDirectory;

    if (await directory.exists()) {
      await for (final entity in directory.list()) {
        await entity.delete(recursive: true);
      }
    }

    debugPrint('Cleaned: ${directory.path}');
  }

  // Download all media gathered from media_sources
  Future<List<dynamic>> downloadAllMedia({required List<dynamic> links}) async {
    final downloadedLinks = <dynamic>[];

    for (final media in links) {
      debugPrint("(${media.type}) Downloading: ${media.link} as ${media.id!}");
      var path = '';
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
          debugPrint("(${media.type}) Downloaded: ${media.link} to ${path}");
          debugPrint("-------------------------------------------");
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
          debugPrint("(${media.type}) Downloaded: ${media.link} to ${path}");
          debugPrint("-------------------------------------------");
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

              x1: media.x1,
              x2: media.x2,
              y1: media.y1,
              y2: media.y2,

              frameTickerPositions: media.frameTickerPositions,
            ),
          );
          debugPrint("(${media.type}) Downloaded: ${media.link} to ${path}");
          debugPrint("-------------------------------------------");
          break;
        case 'ticker':
          if(media.creationType == 'custom' && media.tickerType == 2) {
            path = await _downloadTicker(link: media.link, name: media.id!, tickerStrings: media.tickerStrings);
          }
          downloadedLinks.add(
            TickerLink(
              id: media.id,
              link: media.link,
              type: media.type,
              localPath: path,
              creationType: media.creationType,
              tickerStrings: media.tickerStrings
            ),
          );
          if(path != '') {
            debugPrint("(${media.type}) Downloaded: ${media.link} to ${path}");
            debugPrint("-------------------------------------------");
          } else {
            debugPrint("(${media.type}) No custom ticker. Didn't download.");
            debugPrint("-------------------------------------------");
          }
          break;
        default:
          break;
      }
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
    final file = File(
      '${imageDirectory.path}/$name.${_getFileExtension(link)}',
    );

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
    final file = File(
      '${videoDirectory.path}/$name.${_getFileExtension(link)}',
    );

    // File in assets folder
    if (!_checkHttp(link) && _checkAsset(link)) {
      final byteData = await rootBundle.load(link);
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
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
    final file = File(
      '${frameDirectory.path}/$name.${_getFileExtension(link)}',
    );

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

  // Start download on frame
  Future<String> _downloadTicker({
    required String link,
    required String name,
    required List<String> tickerStrings,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    final directory = await downloadDirectory;
    final tickerDirectory = Directory('${directory.path}/tickers');
    await tickerDirectory.create(recursive: true);
    final file = File('${tickerDirectory.path}/$name.txt');

    try {
      await file.writeAsString(tickerStrings.join('\n'));
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

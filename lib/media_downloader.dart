import 'dart:io';
import 'package:flutter/services.dart';
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

  // Download all media gathered from media_sources
  Future<List<MediaLink>> downloadAllMedia({
    required List<MediaLink> links,
  }) async {
    final downloadedLinks = <MediaLink>[];

    for (final media in links) {
      final path = media.type == 'image'
          ? await _downloadImage(link: media.link, name: media.id!)
          : await _downloadVideo(link: media.link, name: media.id!);

      if(path == '') {
        continue;
      }

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
    }

    return downloadedLinks;
  }

  // Start download on image
  Future<String> _downloadImage({
    required String link,
    required String name,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
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

    final directory = await downloadDirectory;
    final videoDirectory = Directory('${directory.path}/videos');
    final file = File('${videoDirectory.path}/$name.${_getFileExtension(link)}');

    if (!_checkHttp(link) && _checkAsset(link)){
      final byteData = await rootBundle.load(link);
      await file.writeAsBytes(
        byteData.buffer.asUint8List(),
        flush: true,
      );
      return file.path;
    }

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

import 'dart:io';

import 'package:flutter_video_test/media_downloader.dart';

class MediaDeletion {
  MediaDeletion({MediaDownloader? mediaDownloader})
    : _mediaDownloader = mediaDownloader ?? MediaDownloader();

  final MediaDownloader _mediaDownloader;

  Future<void> deleteMediaNotInApi({
    required Set<String> imageIds,
    required Set<String> videoIds,
  }) async {
    final directory = await _mediaDownloader.downloadDirectory;
    await _deleteFilesNotInApi(Directory('${directory.path}/images'), imageIds);
    await _deleteFilesNotInApi(Directory('${directory.path}/videos'), videoIds);
  }

  Future<void> _deleteFilesNotInApi(
    Directory directory,
    Set<String> apiIds,
  ) async {
    if (!await directory.exists()) return;

    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;

      final filename = entity.uri.pathSegments.last;
      final extensionIndex = filename.lastIndexOf('.');
      final id = extensionIndex == -1
          ? filename
          : filename.substring(0, extensionIndex);
      if (!apiIds.contains(id)) {
        print('Deleting ${id}');
        await entity.delete();
      }
    }
  }
}

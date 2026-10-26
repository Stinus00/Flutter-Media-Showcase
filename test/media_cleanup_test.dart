import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_video_test/api_call.dart';
import 'package:flutter_video_test/media_cache_deletion.dart';
import 'package:flutter_video_test/media_cacher_stub.dart';
import 'package:flutter_video_test/media_deletion.dart';
import 'package:flutter_video_test/media_downloader.dart';

class _TestMediaDownloader extends MediaDownloader {
  _TestMediaDownloader(this.directory);

  final Directory directory;

  @override
  Future<Directory> get downloadDirectory async => directory;
}

class _TestMediaCacher extends MediaCacher {
  final Map<String, Set<String>> stores = {};
  final Set<String> deletedKeys = {};

  @override
  Future<Set<String>> getMediaKeysWeb(String store) async =>
      stores[store] ?? {};

  @override
  Future<void> deleteMediaWeb(String store, String id) async {
    deletedKeys.add('$store:$id');
  }

  @override
  void forgetBlobUrlWeb(String store, String id) {}
}

void main() {
  group('getApiMediaIdsFromResponse', () {
    test('collects IDs only from scheduled slide playlists', () {
      final apiCall = ApiCall();
      final payload = {
        'group_schedules': {
          'slides': [
            {
              'playlist': {'id': 'group-playlist'},
            },
          ],
          'frames': [
            {
              'playlist': {'id': 'group-frame-playlist'},
            },
          ],
        },
        'system_schedules': {
          'slides': [
            {
              'playlist': {'id': 'system-playlist'},
            },
          ],
          'frames': [
            {
              'playlist': {'id': 'system-frame-playlist'},
            },
          ],
        },
        'playlists': {
          'slides': [
            {
              'id': 'group-playlist',
              'slides': [
                {
                  'media_type': 'image',
                  'image_id': 'image-1',
                  'image': {'id': 'image-1'},
                },
                {
                  'media_type': 'video',
                  'video_id': 'video-1',
                  'video': {'id': 'video-1'},
                },
              ],
            },
            {
              'id': 'system-playlist',
              'slides': [
                {
                  'media_type': 'image',
                  'image_id': 'image-2',
                  'image': {'id': 'image-2'},
                },
                {
                  'media_type': 'video',
                  'video_id': 'video-2',
                  'video': {'id': 'video-2'},
                },
              ],
            },
            {
              'id': 'unscheduled-playlist',
              'slides': [
                {
                  'media_type': 'image',
                  'image_id': 'image-3',
                  'image': {'id': 'image-3'},
                },
              ],
            },
          ],
          'frames': [
            {
              'id': 'group-frame-playlist',
              'frames': [
                {
                  'image': {'id': 'frame-1'},
                },
                {'image_id': 'frame-2'},
              ],
            },
            {
              'id': 'system-frame-playlist',
              'frames': [
                {
                  'image': {'id': 'frame-3'},
                },
              ],
            },
            {
              'id': 'unscheduled-frame-playlist',
              'frames': [
                {
                  'image': {'id': 'frame-4'},
                },
              ],
            },
          ],
        },
      };

      final mediaIds = apiCall.getApiMediaIdsFromResponse(jsonEncode(payload));

      expect(mediaIds.images, {'image-1', 'image-2'});
      expect(mediaIds.videos, {'video-1', 'video-2'});
      expect(mediaIds.frames, {'frame-1', 'frame-2', 'frame-3'});
    });
  });

  group('MediaDeletion', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'media-cleanup-test-',
      );
    });

    tearDown(() async {
      await tempDirectory.delete(recursive: true);
    });

    test(
      'deletes files not referenced by the API and keeps referenced files',
      () async {
        final imagesDirectory = Directory('${tempDirectory.path}/images');
        final videosDirectory = Directory('${tempDirectory.path}/videos');
        final framesDirectory = Directory('${tempDirectory.path}/frames');
        await imagesDirectory.create();
        await videosDirectory.create();
        await framesDirectory.create();

        final keptImage = File('${imagesDirectory.path}/image-1.jpg');
        final staleImage = File('${imagesDirectory.path}/old-image.png');
        final keptVideo = File('${videosDirectory.path}/video-1.mp4');
        final staleVideo = File('${videosDirectory.path}/old-video.mp4');
        final keptFrame = File('${framesDirectory.path}/frame-1.jpg');
        final staleFrame = File('${framesDirectory.path}/old-frame.jpg');
        await Future.wait([
          keptImage.writeAsString('kept'),
          staleImage.writeAsString('stale'),
          keptVideo.writeAsString('kept'),
          staleVideo.writeAsString('stale'),
          keptFrame.writeAsString('kept'),
          staleFrame.writeAsString('stale'),
        ]);

        final deletion = MediaDeletion(
          mediaDownloader: _TestMediaDownloader(tempDirectory),
        );
        await deletion.deleteMediaNotInApi(
          imageIds: {'image-1'},
          videoIds: {'video-1'},
          frameIds: {'frame-1'},
        );

        expect(await keptImage.exists(), isTrue);
        expect(await staleImage.exists(), isFalse);
        expect(await keptVideo.exists(), isTrue);
        expect(await staleVideo.exists(), isFalse);
        expect(await keptFrame.exists(), isTrue);
        expect(await staleFrame.exists(), isFalse);
      },
    );
  });

  group('MediaCacheDeletion', () {
    test('deletes cached frames not referenced by the API', () async {
      final cacher = _TestMediaCacher()
        ..stores['frames'] = {'frame-1', 'old-frame'};
      final deletion = MediaCacheDeletion(mediaCacher: cacher);

      await deletion.deleteMediaNotInApi(
        imageIds: {},
        videoIds: {},
        frameIds: {'frame-1'},
      );

      expect(cacher.deletedKeys, {'frames:old-frame'});
    });
  });
}

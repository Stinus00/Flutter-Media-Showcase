import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_video_test/api_call.dart';
import 'package:flutter_video_test/media_deletion.dart';
import 'package:flutter_video_test/media_downloader.dart';

class _TestMediaDownloader extends MediaDownloader {
  _TestMediaDownloader(this.directory);

  final Directory directory;

  @override
  Future<Directory> get downloadDirectory async => directory;
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
        },
        'system_schedules': {
          'slides': [
            {
              'playlist': {'id': 'system-playlist'},
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
        },
      };

      final mediaIds = apiCall.getApiMediaIdsFromResponse(jsonEncode(payload));

      expect(mediaIds.images, {'image-1', 'image-2'});
      expect(mediaIds.videos, {'video-1', 'video-2'});
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
        await imagesDirectory.create();
        await videosDirectory.create();

        final keptImage = File('${imagesDirectory.path}/image-1.jpg');
        final staleImage = File('${imagesDirectory.path}/old-image.png');
        final keptVideo = File('${videosDirectory.path}/video-1.mp4');
        final staleVideo = File('${videosDirectory.path}/old-video.mp4');
        await Future.wait([
          keptImage.writeAsString('kept'),
          staleImage.writeAsString('stale'),
          keptVideo.writeAsString('kept'),
          staleVideo.writeAsString('stale'),
        ]);

        final deletion = MediaDeletion(
          mediaDownloader: _TestMediaDownloader(tempDirectory),
        );
        await deletion.deleteMediaNotInApi(
          imageIds: {'image-1'},
          videoIds: {'video-1'},
        );

        expect(await keptImage.exists(), isTrue);
        expect(await staleImage.exists(), isFalse);
        expect(await keptVideo.exists(), isTrue);
        expect(await staleVideo.exists(), isFalse);
      },
    );
  });
}

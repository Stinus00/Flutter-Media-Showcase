import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_video_test/api/api_call.dart';
import 'package:flutter_video_test/app_download/media_downloader.dart';
import 'package:flutter_video_test/classes/frame_ticker_position.dart';

class _TestMediaDownloader extends MediaDownloader {
  _TestMediaDownloader(this.directory);

  final Directory directory;

  @override
  Future<Directory> get downloadDirectory async => directory;
}

void main() {
  group('saveApiResponse', () {
    late Directory tempDirectory;
    late ApiCall apiCall;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp('api-call-test-');
      apiCall = ApiCall(
        downloader: _TestMediaDownloader(
          Directory('${tempDirectory.path}/documents'),
        ),
      );
    });

    tearDown(() async {
      await tempDirectory.delete(recursive: true);
    });

    test(
      'creates the JSON directory and writes the formatted response',
      () async {
        final data = <String, dynamic>{
          'app_id': 'test-app',
          'name': 'Test display',
          'group': {'id': 'group-1', 'name': 'Test group'},
          'group_schedules': {'slides': [], 'frames': [], 'tickers': []},
          'system_schedules': {'slides': [], 'frames': [], 'tickers': []},
          'playlists': {'slides': [], 'frames': [], 'tickers': []},
        };

        await apiCall.saveApiResponse(jsonEncode(data));

        final file = File(
          '${tempDirectory.path}/documents/json/old_api_response.json',
        );
        expect(await file.exists(), isTrue);
        final savedContent = await file.readAsString();
        expect(savedContent, contains('\n  "app_id": "test-app"'));
        expect(jsonDecode(savedContent), {
          'app_id': 'test-app',
          'name': 'Test display',
          'group': {'id': 'group-1', 'name': 'Test group'},
          'group_schedules': {'slides': [], 'frames': [], 'tickers': []},
          'system_schedules': {'slides': [], 'frames': [], 'tickers': []},
          'playlists': {'slides': [], 'frames': [], 'tickers': []},
        });

        data['name'] = 'Updated display';
        await apiCall.saveApiResponse(jsonEncode(data));
        expect(
          jsonDecode(await file.readAsString())['name'],
          'Updated display',
        );
      },
    );
  });

  test('rebuilds downloaded links from the saved API response', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'saved-api-media-test-',
    );
    addTearDown(() => tempDirectory.delete(recursive: true));

    final documentsDirectory = Directory('${tempDirectory.path}/documents');
    final apiCall = ApiCall(
      downloader: _TestMediaDownloader(documentsDirectory),
    );
    final now = DateTime.now();
    final data = <String, dynamic>{
      'app_id': 'test-app',
      'name': 'Test display',
      'group': {'id': 'group-1', 'name': 'Test group'},
      'group_schedules': {'slides': [], 'frames': [], 'tickers': []},
      'system_schedules': {
        'slides': [
          {
            'id': 42,
            'start': now.subtract(const Duration(hours: 1)).toIso8601String(),
            'end': now.add(const Duration(hours: 1)).toIso8601String(),
            'playlist': {'id': 'playlist-1', 'type': 'custom'},
          },
        ],
        'frames': [
          {
            'id': 44,
            'start': now.subtract(const Duration(hours: 1)).toIso8601String(),
            'end': now.add(const Duration(hours: 1)).toIso8601String(),
            'playlist': {'id': 'frame-playlist-1', 'type': 'custom'},
          },
        ],
        'tickers': [
          {
            'id': 43,
            'start': now.subtract(const Duration(hours: 1)).toIso8601String(),
            'end': now.add(const Duration(hours: 1)).toIso8601String(),
            'playlist': {'id': 'ticker-playlist-1', 'type': 'custom'},
            'ticker_bar': 1,
          },
        ],
      },
      'playlists': {
        'slides': [
          {
            'id': 'playlist-1',
            'slides': [
              {
                'id': 'slide-1',
                'media_type': 'image',
                'ad_duration': 5,
                'image': {
                  'id': 'image-1',
                  'url': 'https://example.test/image-1.jpg',
                  'mime_type': 'image/jpeg',
                },
              },
            ],
          },
        ],
        'frames': [
          {
            'id': 'frame-playlist-1',
            'frames': [
              {
                'id': 'frame-entry-1',
                'type': 'custom',
                'interval_minutes': 1,
                'image': {
                  'id': 'frame-1',
                  'url': 'https://example.test/frame-1.jpg',
                  'mime_type': 'image/jpeg',
                },
              },
            ],
          },
        ],
        'tickers': [
          {
            'id': 'ticker-playlist-1',
            'tickers': [
              {
                'id': 'ticker-1',
                'type': 'custom',
                'amount': 2,
                'url': 'https://example.test/ticker.xml',
              },
            ],
          },
        ],
      },
    };

    await apiCall.saveApiResponse(jsonEncode(data));
    final imageFile = File('${documentsDirectory.path}/images/image-1.jpg');
    await imageFile.parent.create(recursive: true);
    await imageFile.writeAsString('cached image');
    final frameFile = File('${documentsDirectory.path}/frames/frame-1.jpg');
    await frameFile.parent.create(recursive: true);
    await frameFile.writeAsString('cached frame');
    await _TestMediaDownloader(documentsDirectory).saveFrameCoordinates({
      'frame-1': (
        x1: 10,
        x2: 30,
        y1: 20,
        y2: 40,
        frameTickerPositions: [
          const FrameTickerPosition(
            index: 1,
            frameId: 'frame-1',
            x1: 3,
            y1: 4,
            x2: 15,
            y2: 16,
            fontSize: 12,
          ),
          const FrameTickerPosition(
            index: 2,
            frameId: 'frame-1',
            x1: 20,
            y1: 21,
            x2: 30,
            y2: 31,
          ),
        ],
      ),
    });
    final savedCoordinates = await _TestMediaDownloader(documentsDirectory)
        .loadSavedFrameCoordinates();
    final savedTickerPositions =
        savedCoordinates['frame-1']!.frameTickerPositions;
    expect(savedTickerPositions, hasLength(2));
    final savedTickerPosition = savedTickerPositions.first;
    expect(savedTickerPosition.index, 1);
    expect(savedTickerPosition.frameId, 'frame-1');
    expect(savedTickerPosition.x1, 3);
    expect(savedTickerPosition.y1, 4);
    expect(savedTickerPosition.x2, 15);
    expect(savedTickerPosition.y2, 16);
    expect(savedTickerPosition.fontSize, 12);
    final tickerPositionWithoutFontSize = savedTickerPositions.last;
    expect(tickerPositionWithoutFontSize.index, 2);
    expect(tickerPositionWithoutFontSize.fontSize, isNull);
    final tickerFile = File('${documentsDirectory.path}/tickers/ticker-1.txt');
    await tickerFile.parent.create(recursive: true);
    await tickerFile.writeAsString('Headline\nSummary');

    final cached = await apiCall.loadSavedApiMedia();

    expect(cached.media, hasLength(1));
    expect(cached.media.single.id, 'image-1');
    expect(cached.media.single.localPath, imageFile.path);
    expect(cached.frames, hasLength(1));
    expect(cached.frames.single.id, 'frame-1');
    expect(cached.frames.single.localPath, frameFile.path);
    expect(cached.frames.single.x1, 10);
    expect(cached.frames.single.x2, 30);
    expect(cached.frames.single.y1, 20);
    expect(cached.frames.single.y2, 40);
    final (mainTickers, secondaryTickers) = cached.tickers;
    expect(mainTickers, hasLength(1));
    expect(mainTickers.single.id, 'ticker-1');
    expect(mainTickers.single.tickerStrings, ['Headline', 'Summary']);
    expect(secondaryTickers, isEmpty);
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_video_test/api_call.dart';
import 'package:flutter_video_test/media_downloader.dart';

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
}

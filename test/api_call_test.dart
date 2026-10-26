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

const scheduleResponseJson = '''
{
  "group_schedules": {
		"music": [],
		"slides": [],
		"frames": [],
		"tickers": []
	},
	"system_schedules": {
		"music": [],
		"slides": [
			{
				"id": 1558,
				"type": "slides",
				"title": "test-shuffle",
				"description": "",
				"start": "2026-10-01T07:00:00.000Z",
				"end": "2026-10-01T17:30:00.000Z",
				"start_timezone": "",
				"end_timezone": "",
				"recurrence_id": 0,
				"recurrence_rule": "FREQ=DAILY;WKST=SU",
				"recurrence_exception": "20261003T070000Z,20261004T070000Z,20261005T070000Z,20261007T070000Z",
				"playlist": {
					"id": "0b7bf7e4-d318-401b-ad00-19fab4515426",
					"type": "custom"
				},
				"slide_interval": 7,
				"slide_shuffle": 1,
				"slide_override_system_advertising": 0,
				"slide_advertising_display_duration": 30,
				"slide_advertising_interval": 1
			},
			{
				"id": 1560,
				"type": "slides",
				"title": "test-no-shuffle",
				"description": "",
				"start": "2026-10-06T08:00:00.000Z",
				"end": "2026-10-06T18:00:00.000Z",
				"start_timezone": "",
				"end_timezone": "",
				"recurrence_id": 0,
				"recurrence_rule": "FREQ=DAILY;WKST=SU",
				"recurrence_exception": "20261008T080000Z",
				"playlist": {
					"id": "0b7bf7e4-d318-401b-ad00-19fab4515426",
					"type": "custom"
				},
				"slide_interval": 7,
				"slide_shuffle": 0,
				"slide_override_system_advertising": 0,
				"slide_advertising_display_duration": 30,
				"slide_advertising_interval": 1
			},
			{
				"id": 1561,
				"type": "slides",
				"title": "test-no-shuffle",
				"description": "",
				"start": "2026-10-08T08:28:48.000Z",
				"end": "2026-10-08T18:28:48.000Z",
				"start_timezone": "",
				"end_timezone": "",
				"recurrence_id": 1560,
				"recurrence_rule": null,
				"recurrence_exception": null,
				"playlist": {
					"id": "0b7bf7e4-d318-401b-ad00-19fab4515426",
					"type": "custom"
				},
				"slide_interval": 7,
				"slide_shuffle": 0,
				"slide_override_system_advertising": 0,
				"slide_advertising_display_duration": 30,
				"slide_advertising_interval": 1
			}
		],
		"frames": [],
		"tickers": []
	}
}

''';

Map<String, dynamic> decodeScheduleResponse() =>
    jsonDecode(scheduleResponseJson) as Map<String, dynamic>;

void main() {
  group('getActiveGroupSchedules', () {
    final apiCall = ApiCall();
    test('does not include a schedule', () {
      final activeSlides = apiCall.getActiveGroupSchedules(
        decodeScheduleResponse(),
        DateTime(2026, 10, 6, 9),
      );

      expect(activeSlides, isEmpty);
    });
  });

  group('getActiveSystemSchedules', () {
    final apiCall = ApiCall();

    test('includes schedules active during their recurring time window', () {
      final activeSlides = apiCall.getActiveSystemSchedules(
        decodeScheduleResponse(),
        DateTime(2026, 10, 6, 9),
      );

      expect(activeSlides.map((slide) => slide['id']), [1558, 1560]);
    });

    test('excludes recurrence exception dates', () {
      final activeSlides = apiCall.getActiveSystemSchedules(
        decodeScheduleResponse(),
        DateTime(2026, 10, 7, 9),
      );

      expect(activeSlides.map((slide) => slide['id']), [1560]);
    });

    test('does not include a schedule at its end time', () {
      final activeSlides = apiCall.getActiveSystemSchedules(
        decodeScheduleResponse(),
        DateTime(2026, 10, 7, 18),
      );

      expect(activeSlides, isEmpty);
    });

    test('exception moved', () {
      final activeSlides = apiCall.getActiveSystemSchedules(
        decodeScheduleResponse(),
        DateTime(2026, 10, 8, 8, 30),
      );

      final inactiveSlides = apiCall.getActiveSystemSchedules(
        decodeScheduleResponse(),
        DateTime(2026, 10, 8, 8),
      );

      expect(activeSlides.map((slide) => slide['id']), [1558, 1561]);
      expect(inactiveSlides.map((slide) => slide['id']), [1558]);
    });

    test('includes a one-off schedule only inside its start/end window', () {
      final activeSlides = apiCall.getActiveSystemSchedules(
        decodeScheduleResponse(),
        DateTime(2026, 10, 8, 8, 30),
      );

      final expiredSlides = apiCall.getActiveSystemSchedules(
        decodeScheduleResponse(),
        DateTime(2026, 10, 8, 18, 28, 48),
      );

      expect(activeSlides.map((slide) => slide['id']), [1558, 1561]);
      expect(expiredSlides, isEmpty);
    });
  });

  group('getActiveScheduleIds', () {
    final apiCall = ApiCall();

    test('changes when a one-off schedule becomes active', () {
      final beforeStart = apiCall.getActiveScheduleIds(
        decodeScheduleResponse(),
        DateTime(2026, 10, 8, 8),
      );
      final afterStart = apiCall.getActiveScheduleIds(
        decodeScheduleResponse(),
        DateTime(2026, 10, 8, 8, 30),
      );

      expect(beforeStart, {'system:1558'});
      expect(afterStart, {'system:1558', 'system:1561'});
      expect(afterStart, isNot(equals(beforeStart)));
    });
  });

  group('saveApiResponse', () {
    late Directory tempDirectory;
    late ApiCall apiCall;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'schedule-save-test-',
      );
      apiCall = ApiCall(
        downloader: _TestMediaDownloader(
          Directory('${tempDirectory.path}/documents'),
        ),
      );
    });

    tearDown(() async {
      await tempDirectory.delete(recursive: true);
    });

    test('saves the schedules from scheduleResponseJson', () async {
      await apiCall.saveApiResponse(jsonEncode(decodeScheduleResponse()));

      final savedFile = File(
        '${tempDirectory.path}/documents/json/old_api_response.json',
      );
      expect(await savedFile.exists(), isTrue);

      final savedResponse =
          jsonDecode(await savedFile.readAsString()) as Map<String, dynamic>;
      final savedSlides =
          (savedResponse['system_schedules'] as Map<String, dynamic>)['slides']
              as List<dynamic>;

      expect(savedSlides.map((slide) => slide['id']), [1558, 1560, 1561]);
      expect(savedSlides.last['recurrence_rule'], isNull);
      expect(savedSlides.last['recurrence_exception'], isNull);
    });
  });
}

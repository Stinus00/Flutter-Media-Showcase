import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_video_test/api/api_call.dart';
import 'package:flutter_video_test/main.dart';
import 'package:flutter_video_test/widgets/activity_monitor.dart';
import 'package:flutter_video_test/widgets/floating_settings_box.dart';

class _SystemIdMockAdapter implements HttpClientAdapter {
  static const _validRequestPath =
      '/api/v1/system/112233445566_1/export-full';
  static const _validResponse = {
    'group': {'id': 'test-group', 'name': 'Test group'},
    'group_schedules': {'slides': [], 'frames': [], 'tickers': []},
    'system_schedules': {"slides": [
			{
				"id": 1558,
				"type": "slides",
				"title": "test-shuffle",
				"description": "",
				"start": "2026-10-26T00:00:00.000Z",
				"end": "2026-10-26T16:00:00.000Z",
				"start_timezone": "",
				"end_timezone": "",
				"recurrence_id": 0,
				"recurrence_rule": "FREQ=DAILY;WKST=SU",
				"recurrence_exception": "",
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
    ], 'frames': [], 'tickers': []},
    'playlists': {'slides': [
      {
				"id": "0b7bf7e4-d318-401b-ad00-19fab4515426",
				"type": "custom",
				"title": "test",
				"owner": "Stijn Vossen",
				"description": "a",
				"image_path": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/customers/7eac3bea-4a28-4646-accd-616d9af72608/regions/N/playlists/37710073-31c3-43e1-8663-e08c431ab007/37710073-31c3-43e1-8663-e08c431ab007.png",
				"status": "published",
				"systems": [],
				"groups": [],
				"slides": [
					{
						"id": "192d7a78-f001-4df2-9683-d1bdcec81a99",
						"region_id": "N",
						"type": "custom",
						"name": "Spacetravel-0001",
						"description": null,
						"media_type": "video",
						"image_id": null,
						"image": null,
						"video_id": "413dbb9f-f24f-4588-9998-9d289a5fbc3b",
						"video": {
							"id": "413dbb9f-f24f-4588-9998-9d289a5fbc3b",
							"name": "Spacetravel-0001.mp4",
							"path": "videos/413dbb9f-f24f-4588-9998-9d289a5fbc3b",
							"url": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos/413dbb9f-f24f-4588-9998-9d289a5fbc3b/Spacetravel-0001.mp4",
							"mime_type": "video/mp4",
							"size": 12096840,
							"in_progress": false,
							"is_temporary": true,
							"preview_image": "https://s3.eu-central-003.backblazeb2.com/production--remote-webapp/videos%2F413dbb9f-f24f-4588-9998-9d289a5fbc3b%2FSpacetravel-0001_252.png",
							"preview_video": null
						},
						"is_uploading": false,
						"playlist_count": 1,
						"playlists": [
							{
								"id": "0b7bf7e4-d318-401b-ad00-19fab4515426",
								"name": "test"
							}
						],
						"datetime_start": null,
						"datetime_end": null,
						"delete_after_end": false,
						"ad_duration": 7
					}
				],
				"item_count": 6
			}
    ], 'frames': [], 'tickers': []},
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final isValidRequest =
        options.method == 'GET' && options.uri.path == _validRequestPath;
    return ResponseBody.fromString(
      jsonEncode(isValidRequest ? _validResponse : {'error': 'Not found'}),
      isValidRequest ? 200 : 404,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('floatingSettingsBox', () {
    testWidgets('Open Floating Settings Box', (tester) async {
      // Create the widget by telling the tester to build it.
      await tester.pumpWidget(
        const VideoApp()
      );

      final activityFinder = find.byType(ActivityMonitor);
      expect(activityFinder, findsOneWidget);

      final floatingActionButtonFinder = find.byType(FloatingActionButton);
      expect(floatingActionButtonFinder, findsExactly(2));

      final floatingSettingsFinder = find.byType(FloatingSettingsBox);
      expect(floatingSettingsFinder, findsNothing);

      final settingsButton = find.byKey(const ValueKey('settings-button'));
      expect(settingsButton, findsOne);

      await tester.tap(settingsButton);
      await tester.pump();

      expect(floatingSettingsFinder, findsOneWidget);
    });

    testWidgets('Test Focus Settings Box', (tester) async {
      // setup
      await tester.pumpWidget(
        const VideoApp()
      );
      final settingsButton = find.byKey(const ValueKey('settings-button'));
      await tester.tap(settingsButton);
      await tester.pump();

      final systemIdFinder = find.byKey(const ValueKey('Systeem ID'));
      expect(systemIdFinder, findsOne);

      final focusFinder = find.descendant(
        of: systemIdFinder,
        matching: find.byWidgetPredicate(
          (widget) => widget is Focus,
        ),
      );

      final focusNode = tester.widget<Focus>(focusFinder).focusNode;

      expect(focusNode, isNotNull);
      expect(focusNode!.hasFocus, isTrue);

      final koppelCodeFinder = find.byKey(const ValueKey('MCC Koppel Code'));
      expect(koppelCodeFinder, findsOne);

      final focusFinder2 = find.descendant(
        of: koppelCodeFinder,
        matching: find.byWidgetPredicate(
          (widget) => widget is Focus,
        ),
      );

      final focusNode2 = tester.widget<Focus>(focusFinder2).focusNode;

      expect(focusNode2, isNotNull);
      expect(focusNode2!.hasFocus, isFalse);
    });

    testWidgets('Test Regex Settings Box', (tester) async {
      // setup
      await tester.pumpWidget(
        const VideoApp()
      );
      final settingsButton = find.byKey(const ValueKey('settings-button'));
      await tester.tap(settingsButton);
      await tester.pump();

      // Start focus check
      final systemIdFinder = find.byKey(const ValueKey('Systeem ID'));
      expect(systemIdFinder, findsOne);

      final koppelCode1Finder = find.byKey(const ValueKey('MCC Koppel Code'));
      expect(koppelCode1Finder, findsOne);

      final koppelCode2Finder = find.byKey(const ValueKey(''));
      expect(koppelCode2Finder, findsOne);

      final systemIdField = tester.widget<TextFormField>(systemIdFinder);
      final koppelCode1Field = tester.widget<TextFormField>(koppelCode1Finder);
      final koppelCode2Field = tester.widget<TextFormField>(koppelCode2Finder);

      await tester.tap(systemIdFinder);
      await tester.pump();

      await tester.enterText(systemIdFinder, 'Pietje-Puk 123');
      await tester.enterText(koppelCode1Finder, '1122aa33---');
      await tester.enterText(koppelCode2Finder, 'ABCDEF456');

      await tester.pump();

      expect(systemIdField.controller!.text, '123');
      expect(koppelCode1Field.controller!.text, 'AA');
      expect(koppelCode2Field.controller!.text, '456');

      await tester.enterText(systemIdFinder, '123456789012');
      await tester.enterText(koppelCode1Finder, 'aBc');
      await tester.enterText(koppelCode2Finder, '12345678');

      await tester.pump();

      expect(systemIdField.controller!.text, '123456789012');
      expect(koppelCode1Field.controller!.text, 'ABC');
      expect(koppelCode2Field.controller!.text, '12345');
    });

    test('Check if connection can be made', () async {
      final dio = Dio()..httpClientAdapter = _SystemIdMockAdapter();
      addTearDown(() => dio.close(force: true));
      final apiCall = ApiCall(dio: dio);
      // await tester.pump();

      expect(
        await apiCall.tryConnect('112233445566'),
        isTrue,
      );

      Future<bool> rejectedInvalidId() async {
        try {
          await apiCall.tryConnect('000000000000');
          return false;
        } on Exception {
          return true;
        }
      }
      bool id = await rejectedInvalidId();
      expect(id, isTrue);
    });
  });
 
}
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
      '/api/v1/system/251112101888_1/export-full';
  static const _validResponse = {
    'group': {'id': 'test-group', 'name': 'Test group'},
    'group_schedules': {'slides': [], 'frames': [], 'tickers': []},
    'system_schedules': {'slides': [], 'frames': [], 'tickers': []},
    'playlists': {'slides': [], 'frames': [], 'tickers': []},
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

    testWidgets('Test Focus', (tester) async {
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

    testWidgets('Test Regex', (tester) async {
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

    testWidgets('Connect to API', (tester) async {
      final dio = Dio()..httpClientAdapter = _SystemIdMockAdapter();
      addTearDown(() => dio.close(force: true));
      final apiCall = ApiCall(dio: dio);
      await tester.pump();

      expect(
        await tester.runAsync(() => apiCall.tryConnect('251112101888')),
        isTrue,
      );

      final rejectedInvalidId = await tester.runAsync(() async {
        try {
          await apiCall.tryConnect('000000000000');
          return false;
        } on Exception {
          return true;
        }
      });
      expect(rejectedInvalidId, isTrue);
    });
  });
}
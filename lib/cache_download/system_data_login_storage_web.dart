import 'package:web/web.dart' as web;

const _systemDataKey = 'flutter_video_test.system_data';

Future<String?> readSystemData() async {
  return web.window.localStorage.getItem(_systemDataKey);
}

Future<void> writeSystemData(String contents) async {
  web.window.localStorage.setItem(_systemDataKey, contents);
}

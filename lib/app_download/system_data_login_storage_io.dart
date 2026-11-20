import 'dart:io';

import 'package:flutter_video_test/app_download/media_downloader.dart';

Future<File> _getSystemDataFile() async {
  final directory = await MediaDownloader().downloadDirectory;
  final file = File('${directory.path}/system_data.json');
  if (!await file.exists()) await file.create(recursive: true);
  return file;
}

Future<String?> readSystemData() async {
  final file = await _getSystemDataFile();
  if (await file.length() == 0) return null;
  return file.readAsString();
}

Future<void> writeSystemData(String contents) async {
  final file = await _getSystemDataFile();
  await file.writeAsString(contents);
}

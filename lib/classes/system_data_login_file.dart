import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_video_test/app_download/media_downloader.dart';
import 'package:uuid/uuid.dart';

class SystemDataLoginFile{
  String _generateUuid() {
    var uuid = Uuid();
    return uuid.v7();
  }

  Future<File> _getSystemDataFile() async {
    Directory directory = await MediaDownloader().downloadDirectory;
    final file = File('${directory.path}/system_data.json');

    if(!await file.exists()) await file.create(recursive: true);
    return file;
  }

  Future<void> storeUuid() async {
    if(kIsWeb) {

    } else {
      final file = await _getSystemDataFile();
      dynamic decoded;
      if(await file.length() != 0) {
        decoded = jsonDecode(await file.readAsString());
        if(decoded['uuid'] != null) return;
      }

      file.writeAsString(JsonEncoder.withIndent('  ').convert({
        'uuid': _generateUuid()
      }));

      debugPrint('Created system_data.json at ${file.path}');
    }
  }

  Future<String?> readUuid() async {
    final file = await _getSystemDataFile();
    dynamic decoded;
    if(await file.length() != 0) {
      decoded = jsonDecode(await file.readAsString());
      if(decoded['uuid'] != null) return decoded['uuid'];
    }
    return null;
  }

  Future<void> storeIds({
    required String mccAppId, 
    required String systemId
  }) async {
    final file = await _getSystemDataFile();

    final data = jsonDecode(await file.readAsString());
    data['mccAppId'] = mccAppId;
    data['systemId'] = '${systemId}_1';
    await file.writeAsString(JsonEncoder.withIndent('  ').convert(data));
  }

  Future<(String, String)?> readIds() async {
    final file = await _getSystemDataFile();
    dynamic decoded;
    if(await file.length() != 0) {
      decoded = jsonDecode(await file.readAsString());
      if( decoded['mccAppId'] != null && 
          decoded['systemId'] != null ) {
            return (decoded['mccAppId'], decoded['systemId']) as (String, String);
      }
    }
    return null;
  }
}
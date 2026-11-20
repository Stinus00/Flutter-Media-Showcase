import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'system_data_login_storage_io.dart'
    if (dart.library.js_interop) 'system_data_login_storage_web.dart'
    as storage;

class SystemDataLoginFile {
  Future<Map<String, dynamic>> _readData() async {
    final contents = await storage.readSystemData();
    if (contents == null || contents.isEmpty) return <String, dynamic>{};

    final decoded = jsonDecode(contents);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('System data must be a JSON object.');
    }
    return decoded;
  }

  Future<void> _writeData(Map<String, dynamic> data) {
    return storage.writeSystemData(
      const JsonEncoder.withIndent('  ').convert(data),
    );
  }

  Future<void> storeUuid() async {
    final data = await _readData();
    if (data['uuid'] is String) return;

    data['uuid'] = const Uuid().v7();
    await _writeData(data);
  }

  Future<String?> readUuid() async {
    final uuid = (await _readData())['uuid'];
    return uuid is String ? uuid : null;
  }

  Future<void> storeIds({
    required String mccAppId,
    required String systemId,
  }) async {
    final data = await _readData();
    data['mccAppId'] = mccAppId;
    data['systemId'] = '${systemId}_1';
    await _writeData(data);
  }

  Future<(String, String)?> readIds() async {
    final data = await _readData();
    final mccAppId = data['mccAppId'];
    final systemId = data['systemId'];
    if (mccAppId is String && systemId is String) {
      return (mccAppId, systemId);
    }
    return null;
  }
}

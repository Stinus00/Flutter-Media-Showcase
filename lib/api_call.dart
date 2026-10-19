import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video_test/api_mcc_data.dart';
import 'package:flutter_video_test/media_downloader.dart';
import 'package:flutter_video_test/media_link.dart';
import 'package:intl/intl.dart';
import 'package:teno_rrule/teno_rrule.dart';

class ApiCall {
  ApiCall({Dio? dio, MediaDownloader? downloader})
    : _dio = dio ?? Dio(),
      _downloader = downloader ?? MediaDownloader();

  final Dio _dio;
  final MediaDownloader _downloader;
  String? _currentResponseJson;
  String? _pendingResponseJson;
  Set<String>? _lastActiveScheduleIds;

  final _playlistsMap = {};

  // Get data from URL
  Future<List<MediaLink>> getMediaFromApi() async {
    try {
      final data = await _getJsonFromUrl();
      final jsonString = await _shortenJsonData(data);
      return await _buildMediaFromResponse(jsonString, now: DateTime.now());
    } catch (e) {
      debugPrint('Error fetching media from API: $e');
      rethrow;
    }
  }

  // Check if API responses are different
  Future<bool> hasPayloadChanged() async {
    try {
      final data = await _getJsonFromUrl();
      final jsonString = await _shortenJsonData(data);
      final currentResponseJson = _currentResponseJson;
      if (currentResponseJson == null) {
        throw StateError('Media must be loaded before checking the API.');
      }

      final newData = jsonDecode(jsonString);
      final oldData = await _loadOldApiResponse();
      final payloadChanged = jsonEncode(newData) != jsonEncode(oldData);
      _pendingResponseJson = payloadChanged ? jsonString : null;
      return payloadChanged;
    } catch (e) {
      debugPrint('Error checking for API payload changes: $e');
      rethrow;
    }
  }

  // Check if schedules are different (without calling API)
  bool haveSchedulesChanged({DateTime? now}) {
    final responseJson = _pendingResponseJson ?? _currentResponseJson;
    if (responseJson == null || _lastActiveScheduleIds == null) {
      throw StateError('Media must be loaded before checking schedules.');
    }

    final data = jsonDecode(responseJson) as Map<String, dynamic>;
    final activeScheduleIds = _getActiveScheduleIds(
      data,
      now: now ?? DateTime.now(),
    );
    return !setEquals(activeScheduleIds, _lastActiveScheduleIds);
  }

  // Rebuild media if needed
  // // Depends if schedules which are already loaded need to be unloaded
  // // Depends if schedules gathered from API get active at this time.
  Future<List<MediaLink>> rebuildMediaForCurrentSchedules({
    DateTime? now,
  }) async {
    final responseJson = _pendingResponseJson ?? _currentResponseJson;
    if (responseJson == null) {
      throw StateError('Media must be loaded before rebuilding the playlist.');
    }
    return _buildMediaFromResponse(responseJson, now: now ?? DateTime.now());
  }

  // Build media list from response
  Future<List<MediaLink>> _buildMediaFromResponse(
    String jsonString, {
    required DateTime now,
  }) async {
    final media = <dynamic>[];
    final shuffleList = <dynamic>[];
    final mainList = <dynamic>[];
    final combinedList = <dynamic>[];
    final mapJson = jsonDecode(jsonString) as Map<String, dynamic>;
    final playlists = mapJson['playlists']['slides'];
    _playlistsMap.clear();
    _mapPlaylists(playlists);

    final groupSchedules = _getGroupSchedules(media, mapJson, now: now);
    final systemSchedules = _getSystemSchedules(media, mapJson, now: now);

    _getPlaylistData(media, shuffleList, mainList);
    shuffleList.shuffle();

    combinedList
      ..addAll(mainList)
      ..addAll(shuffleList);

    final mediaLinks = await _convertMediaToMediaLink(combinedList);
    final downloadedMediaLinks = await _downloadMedia(mediaLinks);
    await _saveApiResponse(jsonString);
    _currentResponseJson = jsonString;
    _pendingResponseJson = null;
    _lastActiveScheduleIds = _scheduleIds(groupSchedules, systemSchedules);
    return downloadedMediaLinks;
  }

  // Get JSON from api
  Future<Map<String, dynamic>> _getJsonFromUrl() async {
    try {
      final secrets = await _getSecrets();
      _dio.options.headers[secrets['api_header']] = secrets['api_key'];
      final url = secrets['api_url'];
      final urlNow = '$url?start=${_getCurrentDate()}';

      final response = await _dio.get(urlNow);
      // await _saveApiResponse(response);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load JSON from $url');
      }
    } catch (e) {
      debugPrint('Error fetching JSON: $e');
      rethrow;
    }
  }

  // Get the group schedules and return list.
  List<dynamic> _getGroupSchedules(
    List<dynamic> media,
    Map<String, dynamic> data, {
    DateTime? now,
  }) {
    List<dynamic> groupSchedules = _getActiveGroupSchedules(data, now: now);
    media.addAll(groupSchedules);
    return groupSchedules;
  }

  @visibleForTesting
  List<dynamic> getActiveGroupSchedules(
    Map<String, dynamic> data,
    DateTime? now,
  ) {
    return _getActiveGroupSchedules(data, now: now);
  }

  List<dynamic> _getActiveGroupSchedules(
    Map<String, dynamic> data, {
    DateTime? now,
  }) {
    final groupSchedules = data['group_schedules'] as Map<String, dynamic>;
    final slides = groupSchedules['slides'] as List<dynamic>;

    return slides.where((slide) {
      return _createRRule(slide as Map<String, dynamic>, now: now);
    }).toList();
  }

  // Get the system schedules and return list
  List<dynamic> _getSystemSchedules(
    List<dynamic> media,
    Map<String, dynamic> data, {
    DateTime? now,
  }) {
    List<dynamic> systemSchedules = _getActiveSystemSchedules(data, now: now);
    media.addAll(systemSchedules);
    return systemSchedules;
  }

  @visibleForTesting
  List<dynamic> getActiveSystemSchedules(
    Map<String, dynamic> data,
    DateTime? now,
  ) {
    return _getActiveSystemSchedules(data, now: now);
  }

  List<dynamic> _getActiveSystemSchedules(
    Map<String, dynamic> data, {
    DateTime? now,
  }) {
    final systemSchedules = data['system_schedules'] as Map<String, dynamic>;
    final slides = systemSchedules['slides'] as List<dynamic>;

    return slides.where((slide) {
      return _createRRule(slide as Map<String, dynamic>, now: now);
    }).toList();
  }

  @visibleForTesting
  Set<String> getActiveScheduleIds(Map<String, dynamic> data, DateTime? now) {
    final groupSchedules = _getActiveGroupSchedules(data, now: now);
    final systemSchedules = _getActiveSystemSchedules(data, now: now);
    return _scheduleIds(groupSchedules, systemSchedules);
  }

  Set<String> _getActiveScheduleIds(
    Map<String, dynamic> data, {
    required DateTime now,
  }) {
    final groupSchedules = _getActiveGroupSchedules(data, now: now);
    final systemSchedules = _getActiveSystemSchedules(data, now: now);
    return _scheduleIds(groupSchedules, systemSchedules);
  }

  // Get all schedule ids and put them in a set for later use in checking data.
  Set<String> _scheduleIds(
    List<dynamic> groupSchedules,
    List<dynamic> systemSchedules,
  ) {
    return {
      ...groupSchedules.map((schedule) => 'group:${schedule['id']}'),
      ...systemSchedules.map((schedule) => 'system:${schedule['id']}'),
    };
  }

  // Get media that will be shown right now.
  bool _createRRule(Map<String, dynamic> slide, {DateTime? now}) {
    final start = _parseApiDateTime(slide['start'] as String);
    final end = _parseApiDateTime(slide['end'] as String);
    if (!end.isAfter(start)) {
      throw FormatException('Schedule end must be after start.');
    }

    final currentTime = (now ?? DateTime.now());
    final recurrenceRule = (slide['recurrence_rule'] as String?)?.trim();
    if (recurrenceRule == null || recurrenceRule.isEmpty) {
      return !currentTime.isBefore(start) && currentTime.isBefore(end);
    }

    final exceptionDates = (slide['recurrence_exception'] as String? ?? '')
        .trim();
    final localExceptionDates = exceptionDates
        .split(',')
        .map((date) => date.trim().replaceFirst(RegExp(r'Z$'), ''))
        .join(',');
    final exDateLine = exceptionDates.isEmpty
        ? ''
        : 'EXDATE:$localExceptionDates\n';
    final rule = RecurrenceRule.from(
      'DTSTART:${_formatDateForRRule(start)}\n'
      '${exDateLine}RRULE:$recurrenceRule',
    );
    if (rule == null) {
      throw FormatException(
        'Invalid recurrence rule for slide ${slide['id']}.',
      );
    }

    // Add today
    final startOfToday = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );
    final tomorrow = startOfToday.add(const Duration(days: 1));
    final duration = end.difference(start);

    return rule.between(startOfToday.subtract(duration), tomorrow).any((
      occurrenceStart,
    ) {
      final occurrenceEnd = occurrenceStart.add(duration);
      return !currentTime.isBefore(occurrenceStart) &&
          currentTime.isBefore(occurrenceEnd);
    });
  }

  // Place playlists in dictionary for easier retrieval later
  Future<void> _mapPlaylists(List<dynamic> playlists) async {
    for (var playlist in playlists) {
      if (_playlistsMap[playlist['id']] != null) continue;

      _playlistsMap[playlist['id']] = playlist;
    }
  }

  // For each schedule get playlist associated with it.
  Future<void> _getPlaylistData(
    List<dynamic> schedules,
    List<dynamic> shuffleList,
    List<dynamic> mainList,
  ) async {
    for (var schedule in schedules) {
      String playlistId = schedule["playlist"]["id"];
      bool slideShuffle = schedule["slide_shuffle"] == 1;

      var playlist = _playlistsMap[playlistId];
      var slidesList = playlist['slides'];

      slideShuffle
          ? shuffleList.addAll(slidesList)
          : mainList.addAll(slidesList);
    }
  }

  // Convert media gotten from API to MediaLink
  Future<List<MediaLink>> _convertMediaToMediaLink(List<dynamic> media) async {
    // Get mimetype from given mimetype or from link extension
    String getMimeType(String type, item) {
      if (type == 'image') {
        if (item['image']['mime_type']?.isNotEmpty ?? true) {
          return item['image']['mime_type'];
        }
        switch (_getFileExtension(item['image']['url'])) {
          case 'mp4':
            return 'image/mp4';
          case 'jpg':
            return 'image/jpeg';
          case 'jpeg':
            return 'image/jpeg';
          case 'bmp':
            return 'image/bmp';
          default:
            return 'image/jpeg';
        }
      }
      if (item['video']['mime_type']?.isNotEmpty ?? true) {
        return item['video']['mime_type'];
      }
      return 'video/mp4';
    }

    // Set variables in medialink
    List<MediaLink> mediaLinks = [];
    for (var item in media) {
      final type = item['media_type'];
      final duration = item['ad_duration'] * 1000;
      final url = type == 'image' ? item['image']['url'] : item['video']['url'];
      final id = type == 'image' ? item['image']['id'] : item['video']['id'];
      final mimeType = getMimeType(type, item);
      mediaLinks.add(
        MediaLink(
          link: url,
          type: type,
          duration: duration,
          id: id,
          mimeType: mimeType,
        ),
      );
    }

    return mediaLinks;
  }

  // return file extension (last part of link after .)
  String _getFileExtension(String url) {
    return url.split('.').last;
  }

  // Download all media gotten from API
  Future<List<MediaLink>> _downloadMedia(List<MediaLink> media) async {
    return await _downloader.downloadAllMedia(links: media);
  }

  // Shorten json data given, removing unnecessary objects.
  Future<String> _shortenJsonData(Map<String, dynamic> data) async {
    final system = SystemData.fromJson(data);
    final jsonString = const JsonEncoder.withIndent('  ')
        .convert(system.toJson());
    return jsonString;
  }

  @visibleForTesting
  Future<void> saveApiResponse(String jsonString) {
    return _saveApiResponse(jsonString);
  }

  // Save API response to file for comparison later
  Future<void> _saveApiResponse(String jsonString) async {
    final decodedJson = jsonDecode(jsonString);
    final formattedJson = const JsonEncoder.withIndent('  ')
        .convert(decodedJson);

    final directory = await _downloader.downloadDirectory;
    final jsonDirectory = Directory('${directory.path}/json');
    final file = File('${jsonDirectory.path}/old_api_response.json');
    await file.create(recursive: true);
    await file.writeAsString(formattedJson);
  }

  // Load saved API response for comparison
  Future<Map<String, dynamic>> _loadOldApiResponse() async {
    final directory = await _downloader.downloadDirectory;
    final file = File('${directory.path}/json/old_api_response.json');
    if (!file.existsSync()) {
      throw Exception('Old API response file not found.');
    }
    final jsonString = file.readAsStringSync();
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  // Get current date
  String _getCurrentDate() {
    var now = DateTime.now();
    var formatter = DateFormat('yyyy-MM-dd');
    String formattedDate = formatter.format(now);
    return formattedDate;
  }

  DateTime _parseApiDateTime(String value) {
    final parsed = DateTime.parse(value);
    return DateTime(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    );
  }

  // Get secrets in secrets.json
  Future<dynamic> _getSecrets() async {
    final String jsonString = await rootBundle.loadString(
      'assets/json/secrets.json',
    );

    return jsonDecode(jsonString);
  }

  // Format date for Recurrence Rule
  String _formatDateForRRule(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');

    return '${date.year}'
        '${two(date.month)}'
        '${two(date.day)}T'
        '${two(date.hour)}'
        '${two(date.minute)}'
        '${two(date.second)}';
  }
}

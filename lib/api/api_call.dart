import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video_test/classes/api_mcc_data.dart';
import 'package:flutter_video_test/cache_download/media_cache_deletion.dart';
import 'package:flutter_video_test/api/api_xml_handler.dart';
import 'package:flutter_video_test/classes/frame_link.dart';
import 'package:flutter_video_test/cache_download/media_cacher_stub.dart'
    if (dart.library.js_interop) 'package:flutter_video_test/cache_download/media_cacher.dart';
import 'package:flutter_video_test/app_download/media_deletion.dart';
import 'package:flutter_video_test/app_download/media_downloader.dart';
import 'package:flutter_video_test/classes/frame_ticker_position.dart';
import 'package:flutter_video_test/classes/media_link.dart';
import 'package:flutter_video_test/classes/ticker_link.dart';
import 'package:intl/intl.dart';
import 'package:teno_rrule/teno_rrule.dart';

class ApiCall {
  ApiCall({
    Dio? dio,
    MediaDownloader? downloader,
    MediaCacher? cacher,
    ApiXmlHandler? apiXmlHandler,
  }) : this._(
         dio ?? Dio(),
         downloader ?? MediaDownloader(),
         cacher ?? MediaCacher(),
         apiXmlHandler ?? ApiXmlHandler(),
       );

  ApiCall._(this._dio, this._downloader, this._cacher, this._apiXmlHandler)
    : _mediaDeletion = MediaDeletion(mediaDownloader: _downloader),
      _mediaCacheDeletion = MediaCacheDeletion(mediaCacher: _cacher);

  final Dio _dio;
  final MediaDownloader _downloader;
  final MediaCacher _cacher;
  final MediaDeletion _mediaDeletion;
  final MediaCacheDeletion _mediaCacheDeletion;
  final ApiXmlHandler _apiXmlHandler;

  String? _currentResponseJson;
  String? _pendingResponseJson;
  Set<String>? _lastActiveScheduleIds;
  Set<String>? _lastActiveScheduleFrameIds;
  Set<String>? _lastActiveScheduleTickerIds;

  // For Web
  String? oldJson;

  final _playlistsMapMedia = {};
  final _playlistsMapFrames = {};
  final _playlistsMapTickers = {};

  // Get data from URL
  Future<List<MediaLink>> getMediaFromApi() async {
    // await _downloader.cleanupAppDirectory();

    try {
      final responseJson = _currentResponseJson;
      final data = responseJson == null
          ? await _getJsonFromUrl()
          : jsonDecode(responseJson) as Map<String, dynamic>;

      final jsonString = await _shortenJsonData(data);
      final media = await _buildMediaFromResponse(
        jsonString,
        now: DateTime.now(),
      );
      await cleanupStoredMedia();
      return media;
    } catch (e) {
      debugPrint('Error fetching media from API: $e');
      rethrow;
    }
  }

  Future<List<FrameLink>> getFrameLinksFromApi() async {
    try {
      final responseJson = _currentResponseJson;
      final data = responseJson == null
          ? await _getJsonFromUrl()
          : jsonDecode(responseJson) as Map<String, dynamic>;
      final jsonString = await _shortenJsonData(data);

      return await _buildFramesFromResponse(jsonString, now: DateTime.now());
    } catch (e) {
      debugPrint('Error fetching frames from API: $e');
      rethrow;
    }
  }

  Future<(List<TickerLink>, List<TickerLink>)> getTickerLinksFromApi() async {
    try {
      final responseJson = _currentResponseJson;
      final data = responseJson == null
          ? await _getJsonFromUrl()
          : jsonDecode(responseJson) as Map<String, dynamic>;
      final jsonString = await _shortenJsonData(data);

      return await _buildTickersFromResponse(jsonString, now: DateTime.now());
    } catch (e) {
      debugPrint('Error fetching tickers from API: $e');
      rethrow;
    }
  }

  Future<({List<MediaLink> media, List<FrameLink> frames, (List<TickerLink>, List<TickerLink>) tickers})> loadSavedApiMedia() async {
    final data = await _loadOldApiResponse();
    final jsonString = await _shortenJsonData(data);
    final now = DateTime.now();
    final media = await _buildMediaFromResponse(
      jsonString,
      now: now,
    );
    await cleanupStoredMedia();
    final frames = await _buildFramesFromResponse(
      jsonString,
      now: now,
    );
    final tickers = await _buildTickersFromResponse(
      jsonString,
      now: now,
      useSavedTickerStrings: true,
    );
    return (media: media, frames: frames, tickers: tickers);
  }

  // Check if API responses are different
  Future<bool> hasPayloadChanged() async {
    try {
      final data = await _getJsonFromUrl();
      final jsonString = await _shortenJsonData(data);
      final currentResponseJson = _currentResponseJson;

      if (currentResponseJson == null) {
        _pendingResponseJson = jsonString;
        return true;
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
    if (responseJson == null ||
        _lastActiveScheduleIds == null ||
        _lastActiveScheduleFrameIds == null ||
        _lastActiveScheduleTickerIds == null
        ) {
      return false;
      // throw StateError('Media must be loaded before checking schedules.');
    }

    final data = jsonDecode(responseJson) as Map<String, dynamic>;
    final activeScheduleIds = _getActiveScheduleIds(
      data,
      now: now ?? DateTime.now(),
    );
    final activeScheduleFrameIds = _getActiveScheduleFrameIds(
      data,
      now: now ?? DateTime.now(),
    );
    final activeScheduleTickerIds = _getActiveScheduleTickerIds(
      data,
      now: now ?? DateTime.now(),
    );


    return !setEquals(activeScheduleIds, _lastActiveScheduleIds) ||
        !setEquals(activeScheduleFrameIds, _lastActiveScheduleFrameIds) ||
        !setEquals(activeScheduleTickerIds, _lastActiveScheduleTickerIds);
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

  Future<List<FrameLink>> rebuildFramesForCurrentSchedules({
    DateTime? now,
  }) async {
    final responseJson = _pendingResponseJson ?? _currentResponseJson;
    if (responseJson == null) {
      throw StateError('Media must be loaded before rebuilding the playlist.');
    }
    return _buildFramesFromResponse(responseJson, now: now ?? DateTime.now());
  }

  Future<(List<TickerLink>, List<TickerLink>)> rebuildTickersForCurrentSchedules({
    DateTime? now,
  }) async {
    final responseJson = _pendingResponseJson ?? _currentResponseJson;
    if (responseJson == null) {
      throw StateError('Media must be loaded before rebuilding the playlist.');
    }
    return _buildTickersFromResponse(responseJson, now: now ?? DateTime.now());
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
    _playlistsMapMedia.clear();
    _mapPlaylists(playlists);

    final groupSchedules = _getGroupSchedules(
      media,
      mapJson,
      'slides',
      now: now,
    );
    final systemSchedules = _getSystemSchedules(
      media,
      mapJson,
      'slides',
      now: now,
    );

    _getPlaylistData(media, shuffleList, mainList, 'slides');
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

  // Get the media Ids gathered from response
  @visibleForTesting
  ({Set<String> images, Set<String> videos, Set<String> frames})
  getApiMediaIdsFromResponse(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final playlists = json['playlists'] as Map<String, dynamic>;
    final slidePlaylists = playlists['slides'] as List<dynamic>;
    final framePlaylists = playlists['frames'] as List<dynamic>? ?? [];
    final scheduledPlaylistIds = <String>{};
    final imageIds = <String>{};
    final videoIds = <String>{};
    final scheduledFramePlaylistIds = <String>{};
    final frameIds = <String>{};

    for (final scheduleType in ['group_schedules', 'system_schedules']) {
      final schedules =
          (json[scheduleType] as Map<String, dynamic>)['slides']
              as List<dynamic>;
      for (final schedule in schedules) {
        if (schedule is! Map) continue;
        final playlist = schedule['playlist'];
        final playlistId = playlist is Map ? playlist['id'] : null;
        if (playlistId != null) {
          scheduledPlaylistIds.add(playlistId.toString());
        }
      }

      final frameSchedules =
          (json[scheduleType] as Map<String, dynamic>)['frames']
              as List<dynamic>? ??
          [];
      for (final schedule in frameSchedules) {
        if (schedule is! Map) continue;
        final playlist = schedule['playlist'];
        final playlistId = playlist is Map ? playlist['id'] : null;
        if (playlistId != null) {
          scheduledFramePlaylistIds.add(playlistId.toString());
        }
      }
    }

    for (final playlist in slidePlaylists) {
      if (playlist is! Map) continue;
      if (!scheduledPlaylistIds.contains(playlist['id']?.toString())) continue;
      final slides = playlist['slides'];
      if (slides is! List) continue;

      for (final slide in slides) {
        if (slide is! Map) continue;
        final mediaType = slide['media_type'];
        final targetIds = mediaType == 'image'
            ? imageIds
            : mediaType == 'video'
            ? videoIds
            : null;
        if (targetIds == null) continue;

        final media = slide[mediaType];
        final id = media is Map ? media['id'] : null;
        if (id is String && id.isNotEmpty) {
          targetIds.add(id);
        }

        final referencedId = slide['${mediaType}_id'];
        if (referencedId is String && referencedId.isNotEmpty) {
          targetIds.add(referencedId);
        }
      }
    }

    for (final playlist in framePlaylists) {
      if (playlist is! Map) continue;
      if (!scheduledFramePlaylistIds.contains(playlist['id']?.toString())) {
        continue;
      }
      final frames = playlist['frames'];
      if (frames is! List) continue;

      for (final frame in frames) {
        if (frame is! Map) continue;
        final image = frame['image'];
        final id = image is Map ? image['id'] : null;
        if (id is String && id.isNotEmpty) {
          frameIds.add(id);
        }

        final referencedId = frame['image_id'];
        if (referencedId is String && referencedId.isNotEmpty) {
          frameIds.add(referencedId);
        }
      }
    }

    return (images: imageIds, videos: videoIds, frames: frameIds);
  }

  // Build frames list from response
  Future<List<FrameLink>> _buildFramesFromResponse(
    String jsonString, {
    required DateTime now,
  }) async {
    final frames = <dynamic>[];
    final mainList = <dynamic>[];
    final mapJson = jsonDecode(jsonString) as Map<String, dynamic>;
    final playlists = mapJson['playlists']['frames'];
    _playlistsMapFrames.clear();
    _mapFramePlaylists(playlists);

    final groupSchedules = _getGroupSchedules(
      frames,
      mapJson,
      'frames',
      now: now,
    );
    final systemSchedules = _getSystemSchedules(
      frames,
      mapJson,
      'frames',
      now: now,
    );

    _getPlaylistData(frames, List.empty(), mainList, 'frames');

    final frameLinks = await _convertFramesToFrameLinks(mainList);
    final downloadedFramesLinks = await _downloadFrames(frameLinks);
    _currentResponseJson = jsonString;
    _pendingResponseJson = null;
    _lastActiveScheduleFrameIds = _scheduleIds(groupSchedules, systemSchedules);
    return downloadedFramesLinks;
  }

  Future<(List<TickerLink>, List<TickerLink>)> _buildTickersFromResponse(
    String jsonString, {
    required DateTime now,
    bool useSavedTickerStrings = false,
  }) async {
    final tickers = <dynamic>[];
    final mainList = <dynamic>[];
    final secondaryList = <dynamic>[];
    final mapJson = jsonDecode(jsonString) as Map<String, dynamic>;
    final playlists = mapJson['playlists']['tickers'];
    _playlistsMapTickers.clear();
    _mapTickerPlaylists(playlists);

    final groupSchedules = _getGroupSchedules(
      tickers,
      mapJson,
      'tickers',
      now: now,
    );
    final systemSchedules = _getSystemSchedules(
      tickers,
      mapJson,
      'tickers',
      now: now,
    );

    _getPlaylistData(tickers, secondaryList, mainList, 'tickers');

    final tickerLinksMain = await convertTickersToTickerLinks(
      mainList,
      useSavedTickerStrings: useSavedTickerStrings,
    );
    final tickerLinksSecondary = await convertTickersToTickerLinks(
      secondaryList,
      useSavedTickerStrings: useSavedTickerStrings,
    );
    final downloadedTickerLinksMain = await _downloadTickers(tickerLinksMain);
    final downloadedTickerLinksSecondary = await _downloadTickers(tickerLinksSecondary);
    _currentResponseJson = jsonString;
    _pendingResponseJson = null;
    _lastActiveScheduleTickerIds = _scheduleIds(groupSchedules, systemSchedules);
    return (downloadedTickerLinksMain, downloadedTickerLinksSecondary);
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
    Map<String, dynamic> data,
    String type, {
    DateTime? now,
  }) {
    List<dynamic> groupSchedules = _getActiveGroupSchedules(
      data,
      type,
      now: now,
    );
    media.addAll(groupSchedules);
    return groupSchedules;
  }

  @visibleForTesting
  List<dynamic> getActiveGroupSchedules(
    Map<String, dynamic> data,
    String type,
    DateTime? now,
  ) {
    return _getActiveGroupSchedules(data, type, now: now);
  }

  List<dynamic> _getActiveGroupSchedules(
    Map<String, dynamic> data,
    String type, {
    DateTime? now,
  }) {
    final groupSchedules = data['group_schedules'] as Map<String, dynamic>;
    final slides = groupSchedules[type] as List<dynamic>;

    return slides.where((slide) {
      return _createRRule(slide as Map<String, dynamic>, now: now);
    }).toList();
  }

  // Get the system schedules and return list
  List<dynamic> _getSystemSchedules(
    List<dynamic> media,
    Map<String, dynamic> data,
    String type, {
    DateTime? now,
  }) {
    List<dynamic> systemSchedules = _getActiveSystemSchedules(
      data,
      type,
      now: now,
    );
    media.addAll(systemSchedules);
    return systemSchedules;
  }

  @visibleForTesting
  List<dynamic> getActiveSystemSchedules(
    Map<String, dynamic> data,
    String type,
    DateTime? now,
  ) {
    return _getActiveSystemSchedules(data, type, now: now);
  }

  List<dynamic> _getActiveSystemSchedules(
    Map<String, dynamic> data,
    String type, {
    DateTime? now,
  }) {
    final systemSchedules = data['system_schedules'] as Map<String, dynamic>;
    final slides = systemSchedules[type] as List<dynamic>;

    return slides.where((slide) {
      return _createRRule(slide as Map<String, dynamic>, now: now);
    }).toList();
  }

  @visibleForTesting
  Set<String> getActiveScheduleIds(Map<String, dynamic> data, DateTime? now) {
    final groupSchedules = _getActiveGroupSchedules(data, 'slides', now: now);
    final systemSchedules = _getActiveSystemSchedules(data, 'slides', now: now);
    return _scheduleIds(groupSchedules, systemSchedules);
  }

  Set<String> _getActiveScheduleIds(
    Map<String, dynamic> data, {
    required DateTime now,
  }) {
    final groupSchedules = _getActiveGroupSchedules(data, 'slides', now: now);
    final systemSchedules = _getActiveSystemSchedules(data, 'slides', now: now);
    return _scheduleIds(groupSchedules, systemSchedules);
  }

  Set<String> _getActiveScheduleFrameIds(
    Map<String, dynamic> data, {
    required DateTime now,
  }) {
    final groupSchedules = _getActiveGroupSchedules(data, 'frames', now: now);
    final systemSchedules = _getActiveSystemSchedules(data, 'frames', now: now);
    return _scheduleIds(groupSchedules, systemSchedules);
  }

  Set<String> _getActiveScheduleTickerIds(
    Map<String, dynamic> data, {
      required DateTime now,
  }) {
    final groupSchedules = _getActiveGroupSchedules(data, 'tickers', now: now);
    final systemSchedules = _getActiveSystemSchedules(data, 'tickers', now: now);
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
      if (_playlistsMapMedia[playlist['id']] != null) continue;

      _playlistsMapMedia[playlist['id']] = playlist;
    }
  }

  Future<void> _mapFramePlaylists(List<dynamic> playlists) async {
    for (var playlist in playlists) {
      if (_playlistsMapFrames[playlist['id']] != null) continue;

      _playlistsMapFrames[playlist['id']] = playlist;
    }
  }

  Future<void> _mapTickerPlaylists(List<dynamic> playlists) async {
    for (var playlist in playlists) {
      if (_playlistsMapTickers[playlist['id']] != null) continue;

      _playlistsMapTickers[playlist['id']] = playlist;
    }
  }

  // For each schedule get playlist associated with it.
  Future<void> _getPlaylistData(
    List<dynamic> schedules,
    List<dynamic> shuffleList,
    List<dynamic> mainList,
    String type,
  ) async {
    for (var schedule in schedules) {
      String playlistId = schedule["playlist"]["id"];
      bool slideShuffle = false;
      int tickerBar = 0;
      dynamic playlist;
      switch (type) {
        case 'slides':
          slideShuffle = schedule["slide_shuffle"] == 1;
          playlist = _playlistsMapMedia[playlistId];
          break;
        case 'frames':
          playlist = _playlistsMapFrames[playlistId];
          break;
        case 'tickers':
          tickerBar = schedule["ticker_bar"];
          playlist = _playlistsMapTickers[playlistId];
          break;
      }
      var slidesList = playlist[type];
      
      if (tickerBar != 0) {
        tickerBar == 2
            ? shuffleList.addAll(slidesList)
            : mainList.addAll(slidesList);
      } else {
        slideShuffle
          ? shuffleList.addAll(slidesList)
          : mainList.addAll(slidesList);
      }
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
      final duration = type == 'image' ? item['ad_duration'] * 1000 : null;
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

  // Convert frames gotten from API to FrameLinks
  Future<List<FrameLink>> _convertFramesToFrameLinks(
    List<dynamic> frames,
  ) async {
    final savedCoordinates = kIsWeb
        ? <String, FrameCoordinates>{}
        : await _downloader.loadSavedFrameCoordinates();

    // Get mimetype from given mimetype or from link extension
    String getMimeType(String type, item) {
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

    // Set variables in medialink
    List<FrameLink> frameLinks = [];
    for (var item in frames) {
      final type = 'frame';
      final duration = item['interval_minutes'] * 60 * 1000;
      final url = item['image']['url'];
      final id = item['image']['id'];
      final mimeType = getMimeType(type, item);
      final creationType = item['type'];
      int x1 = 0;
      int y1 = 0;
      int x2 = 0;
      int y2 = 0;
      List<FrameTickerPosition> frameTickerPositions = [];

      if (_apiXmlHandler.checkPropertyExists(item)) {
        x1 = item['properties']['cutout']['x1'];
        y1 = item['properties']['cutout']['y1'];
        x2 = item['properties']['cutout']['x2'];
        y2 = item['properties']['cutout']['y2'];
      } else if (_apiXmlHandler.checkCoordsInLink(url)) {
        (x1, y1, x2, y2) = _apiXmlHandler.extractAllQueryParams(url);
      } else {
        final cachedCoordinates = id is String
            ? savedCoordinates[id]
            : null;
        if (cachedCoordinates != null) {
          x1 = cachedCoordinates.x1;
          x2 = cachedCoordinates.x2;
          y1 = cachedCoordinates.y1;
          y2 = cachedCoordinates.y2;
          frameTickerPositions = cachedCoordinates.frameTickerPositions;
        } else {
          String? xmlUrl = await _apiXmlHandler.convertLinkToXMLString(url);
          if (xmlUrl == null || xmlUrl.isEmpty) {
            continue;
          }
          (x1, y1, x2, y2) = await _apiXmlHandler.getCoordinates(xmlUrl);
          frameTickerPositions = await _apiXmlHandler.getTickerCoordinates(xmlUrl, id);

          if (!kIsWeb && id is String) {
            savedCoordinates[id] = (x1: x1, x2: x2, y1: y1, y2: y2, frameTickerPositions: frameTickerPositions);
          }
        }
      }

      frameLinks.add(
        FrameLink(
          link: url,
          type: type,
          duration: duration,
          id: id,
          mimeType: mimeType,
          creationType: creationType,
          x1: x1.toDouble(),
          y1: y1.toDouble(),
          x2: x2.toDouble(),
          y2: y2.toDouble(),
          frameTickerPositions: frameTickerPositions,
        ),
      );
    }

    if (!kIsWeb && savedCoordinates.isNotEmpty) {
      await _downloader.saveFrameCoordinates(savedCoordinates);
    }

    return frameLinks;
  }

  @visibleForTesting
  Future<List<TickerLink>> convertTickersToTickerLinks(
    List<dynamic> tickers, {
    bool useSavedTickerStrings = false,
  }) async {
    List<TickerLink> tickerLinks = [];
    for (var item in tickers) {
      final type = 'ticker';
      var url = item['url'] as String;
      final id = item['id'] as String?;
      final amount = item['amount'] as int;
      final creationType = item['type'] as String;
      final tickerType = item['ticker_type'] as int?;
      if (url.isEmpty) {
        continue;
      }
      final tickerStrings = useSavedTickerStrings
          ? await _downloader.loadSavedTickerStrings(id ?? '')
          : await _apiXmlHandler.getTickerStringFromXML(url, amount);
      if (tickerStrings == null || tickerStrings.isEmpty) continue;
      tickerLinks.add(
        TickerLink(
          link: url,
          type: type,
          id: id,
          tickerStrings: tickerStrings,
          creationType: creationType,
          tickerType: tickerType,
        ),
      );
    }
    return tickerLinks;
  }

  // return file extension (last part of link after .)
  String _getFileExtension(String url) {
    return url.split('.').last;
  }

  // Download all media gotten from API
  Future<List<MediaLink>> _downloadMedia(List<MediaLink> media) async {
    if (kIsWeb) {
      return List<MediaLink>.from(
        await _cacher.cacheAllMedia(links: media)
      );
    } else {
      return List<MediaLink>.from(
        await _downloader.downloadAllMedia(links: media),
      );
    }
  }

  Future<List<FrameLink>> _downloadFrames(List<FrameLink> frames) async {
    if (kIsWeb) {
      return List<FrameLink>.from(
        await _cacher.cacheAllMedia(links: frames)
      );
    } else {
      return List<FrameLink>.from(
        await _downloader.downloadAllMedia(links: frames),
      );
    }
  }

  Future<List<TickerLink>> _downloadTickers(List<TickerLink> tickers) async {
    if (kIsWeb) {
      return List<TickerLink>.from(
        await _cacher.cacheAllMedia(links: tickers)
      );
    } else {
      return List<TickerLink>.from(
        await _downloader.downloadAllMedia(links: tickers)
      );
    }
  }

  // Cleans up all media available which isn't used anymore.
  Future<void> cleanupStoredMedia() async {
    final responseJson = _currentResponseJson;
    if (responseJson == null) {
      throw StateError('Media must be loaded before cleaning stored media.');
    }

    final ids = getApiMediaIdsFromResponse(responseJson);
    if (kIsWeb) {
      await _mediaCacheDeletion.deleteMediaNotInApi(
        imageIds: ids.images,
        videoIds: ids.videos,
        frameIds: ids.frames,
      );
    } else {
      await _mediaDeletion.deleteMediaNotInApi(
        imageIds: ids.images,
        videoIds: ids.videos,
        frameIds: ids.frames,
      );
    }
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

    if (kIsWeb) {
      oldJson = formattedJson;
    } else {
      final directory = await _downloader.downloadDirectory;
      final jsonDirectory = Directory('${directory.path}/json');
      final file = File('${jsonDirectory.path}/old_api_response.json');
      await file.create(recursive: true);
      await file.writeAsString(formattedJson);
    }
  }

  // Load saved API response for comparison
  Future<Map<String, dynamic>> _loadOldApiResponse() async {
    if (kIsWeb) {
      return jsonDecode(oldJson!);
    } else {
      final directory = await _downloader.downloadDirectory;
      final file = File('${directory.path}/json/old_api_response.json');
      if (!file.existsSync()) {
        throw Exception('Old API response file not found.');
      }
      final jsonString = file.readAsStringSync();
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
  }

  // Shorten json data given, removing unnecessary objects.
  Future<String> _shortenJsonData(Map<String, dynamic> data) async {
    final system = SystemData.fromJson(data);
    final jsonString = const JsonEncoder.withIndent('  ')
        .convert(system.toJson());
    return jsonString;
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

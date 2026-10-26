import 'dart:convert';

class SystemData {
  final String appId;
  final String name;
  final Group group;
  final GroupSchedules groupSchedules;
  final SystemSchedules systemSchedules;
  final Playlists playlists;

  SystemData({
    required this.appId,
    required this.name,
    required this.group,
    required this.groupSchedules,
    required this.systemSchedules,
    required this.playlists,
  });

  factory SystemData.fromJson(Map<String, dynamic> json) {
    return SystemData(
      appId: json['app_id'] ?? '',
      name: json['name'] ?? '',
      group: Group.fromJson(json['group'] ?? {}),
      groupSchedules: GroupSchedules.fromJson(json['group_schedules'] ?? {}),
      systemSchedules: SystemSchedules.fromJson(json['system_schedules'] ?? {}),
      playlists: Playlists.fromJson(json['playlists'] ?? {}),
    );
  }

  factory SystemData.fromRawJson(String source) {
    return SystemData.fromJson(jsonDecode(source));
  }

  Map<String, dynamic> toJson() {
    return {
      'app_id': appId,
      'name': name,
      'group': group.toJson(),
      'group_schedules': groupSchedules.toJson(),
      'system_schedules': systemSchedules.toJson(),
      'playlists': playlists.toJson(),
    };
  }

  String toRawJson() => jsonEncode(toJson());
}

class Group {
  final String id;
  final String name;

  Group({
    required this.id,
    required this.name,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}

class GroupSchedules {
  final List<dynamic> slides;
  final List<dynamic> frames;
  final List<dynamic> tickers;

  GroupSchedules({
    required this.slides,
    required this.frames,
    required this.tickers,
  });

  factory GroupSchedules.fromJson(Map<String, dynamic> json) {
    return GroupSchedules(
      slides: json['slides'] as List? ?? [],
      frames: json['frames'] as List? ?? [],
      tickers: json['tickers'] as List? ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'slides': slides,
        'frames': frames,
        'tickers': tickers,
      };
}

class SystemSchedules {
  final List<ScheduleItem> slides;
  final List<dynamic> frames;
  final List<dynamic> tickers;

  SystemSchedules({
    required this.slides,
    required this.frames,
    required this.tickers,
  });

  factory SystemSchedules.fromJson(Map<String, dynamic> json) {
    return SystemSchedules(
      slides: (json['slides'] as List? ?? [])
          .map((e) => ScheduleItem.fromJson(e))
          .toList(),
      frames: json['frames'] as List? ?? [],
      tickers: json['tickers'] as List? ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'slides': slides.map((e) => e.toJson()).toList(),
        'frames': frames,
        'tickers': tickers,
      };
}

class ScheduleItem {
  final int id;
  final String start;
  final String end;
  final String startTimezone;
  final String endTimezone;
  final int recurrenceId;
  final String? recurrenceRule;
  final String? recurrenceException;
  final PlaylistReference playlist;
  final int slideShuffle;
  final int slideOverrideSystemAdvertising;
  final int slideAdvertisingDisplayDuration;
  final int slideAdvertisingInterval;

  ScheduleItem({
    required this.id,
    required this.start,
    required this.end,
    required this.startTimezone,
    required this.endTimezone,
    required this.recurrenceId,
    required this.recurrenceRule,
    required this.recurrenceException,
    required this.playlist,
    required this.slideShuffle,
    required this.slideOverrideSystemAdvertising,
    required this.slideAdvertisingDisplayDuration,
    required this.slideAdvertisingInterval,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'] ?? 0,
      start: json['start'] ?? '',
      end: json['end'] ?? '',
      startTimezone: json['start_timezone'] ?? '',
      endTimezone: json['end_timezone'] ?? '',
      recurrenceId: json['recurrence_id'] ?? 0,
      recurrenceRule: json['recurrence_rule'],
      recurrenceException: json['recurrence_exception'],
      playlist: PlaylistReference.fromJson(json['playlist'] ?? {}),
      slideShuffle: json['slide_shuffle'] ?? 0,
      slideOverrideSystemAdvertising:
          json['slide_override_system_advertising'] ?? 0,
      slideAdvertisingDisplayDuration:
          json['slide_advertising_display_duration'] ?? 0,
      slideAdvertisingInterval:
          json['slide_advertising_interval'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'start': start,
        'end': end,
        'start_timezone': startTimezone,
        'end_timezone': endTimezone,
        'recurrence_id': recurrenceId,
        'recurrence_rule': recurrenceRule,
        'recurrence_exception': recurrenceException,
        'playlist': playlist.toJson(),
        'slide_shuffle': slideShuffle,
        'slide_override_system_advertising':
            slideOverrideSystemAdvertising,
        'slide_advertising_display_duration':
            slideAdvertisingDisplayDuration,
        'slide_advertising_interval': slideAdvertisingInterval,
      };
}

class PlaylistReference {
  final String id;
  final String type;

  PlaylistReference({
    required this.id,
    required this.type,
  });

  factory PlaylistReference.fromJson(Map<String, dynamic> json) {
    return PlaylistReference(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
      };
}

class Playlists {
  final List<SlidePlaylist> slides;
  final List<dynamic> frames;
  final List<TickerPlaylist> tickers;

  Playlists({
    required this.slides,
    required this.frames,
    required this.tickers,
  });

  factory Playlists.fromJson(Map<String, dynamic> json) {
    return Playlists(
      slides: (json['slides'] as List? ?? [])
          .map((e) => SlidePlaylist.fromJson(e))
          .toList(),
      frames: json['frames'] as List? ?? [],
      tickers: (json['tickers'] as List? ?? [])
          .map((e) => TickerPlaylist.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'slides': slides.map((e) => e.toJson()).toList(),
        'frames': frames,
        'tickers': tickers.map((e) => e.toJson()).toList(),
      };
}

class SlidePlaylist {
  final String id;
  final String status;
  final List<dynamic> groups;
  final List<SlideItem> slides;

  SlidePlaylist({
    required this.id,
    required this.status,
    required this.groups,
    required this.slides,
  });

  factory SlidePlaylist.fromJson(Map<String, dynamic> json) {
    return SlidePlaylist(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      groups: json['groups'] as List? ?? [],
      slides: (json['slides'] as List? ?? [])
          .map((e) => SlideItem.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'groups': groups,
        'slides': slides.map((e) => e.toJson()).toList(),
      };
}

class SlideItem {
  final String id;
  final String mediaType;
  final String? imageId;
  final MediaImage? image;
  final String? videoId;
  final MediaVideo? video;
  final bool isUploading;
  final String? datetimeStart;
  final String? datetimeEnd;
  final bool deleteAfterEnd;
  final int? adDuration;

  SlideItem({
    required this.id,
    required this.mediaType,
    required this.imageId,
    required this.image,
    required this.videoId,
    required this.video,
    required this.isUploading,
    required this.datetimeStart,
    required this.datetimeEnd,
    required this.deleteAfterEnd,
    required this.adDuration,
  });

  factory SlideItem.fromJson(Map<String, dynamic> json) {
    return SlideItem(
      id: json['id']?.toString() ?? '',
      mediaType: json['media_type'] ?? '',
      imageId: json['image_id']?.toString(),
      image: json['image'] != null
          ? MediaImage.fromJson(json['image'])
          : null,
      videoId: json['video_id']?.toString(),
      video: json['video'] != null
          ? MediaVideo.fromJson(json['video'])
          : null,
      isUploading: json['is_uploading'] ?? false,
      datetimeStart: json['datetime_start'],
      datetimeEnd: json['datetime_end'],
      deleteAfterEnd: json['delete_after_end'] ?? false,
      adDuration: json['ad_duration'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'media_type': mediaType,
        'image_id': imageId,
        'image': image?.toJson(),
        'video_id': videoId,
        'video': video?.toJson(),
        'is_uploading': isUploading,
        'datetime_start': datetimeStart,
        'datetime_end': datetimeEnd,
        'delete_after_end': deleteAfterEnd,
        'ad_duration': adDuration,
      };
}

class MediaImage {
  final String id;
  final String url;
  final String mimeType;

  MediaImage({
    required this.id,
    required this.url,
    required this.mimeType,
  });

  factory MediaImage.fromJson(Map<String, dynamic> json) {
    return MediaImage(
      id: json['id']?.toString() ?? '',
      url: json['url'] ?? '',
      mimeType: json['mime_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'mime_type': mimeType,
      };
}

class MediaVideo {
  final String id;
  final String url;
  final String mimeType;

  MediaVideo({
    required this.id,
    required this.url,
    required this.mimeType,
  });

  factory MediaVideo.fromJson(Map<String, dynamic> json) {
    return MediaVideo(
      id: json['id']?.toString() ?? '',
      url: json['url'] ?? '',
      mimeType: json['mime_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'mime_type': mimeType,
      };
}

class PlaylistInfo {
  final String id;
  final String name;

  PlaylistInfo({
    required this.id,
    required this.name,
  });

  factory PlaylistInfo.fromJson(Map<String, dynamic> json) {
    return PlaylistInfo(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}

class TickerPlaylist {
  final String id;
  final String type;
  final String title;
  final String owner;
  final String? description;
  final String? imagePath;
  final String status;
  final List<dynamic> groups;
  final List<Ticker> tickers;
  final int itemCount;

  TickerPlaylist({
    required this.id,
    required this.type,
    required this.title,
    required this.owner,
    required this.description,
    required this.imagePath,
    required this.status,
    required this.groups,
    required this.tickers,
    required this.itemCount,
  });

  factory TickerPlaylist.fromJson(Map<String, dynamic> json) {
    return TickerPlaylist(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      owner: json['owner'] ?? '',
      description: json['description'],
      imagePath: json['image_path'],
      status: json['status'] ?? '',
      groups: json['groups'] as List? ?? [],
      tickers: (json['tickers'] as List? ?? [])
          .map((e) => Ticker.fromJson(e))
          .toList(),
      itemCount: json['item_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'owner': owner,
        'description': description,
        'image_path': imagePath,
        'status': status,
        'groups': groups,
        'tickers': tickers.map((e) => e.toJson()).toList(),
        'item_count': itemCount,
      };
}

class Ticker {
  final String id;
  final String type;
  final int tickerType;
  final String name;
  final int amount;
  final String url;

  Ticker({
    required this.id,
    required this.type,
    required this.tickerType,
    required this.name,
    required this.amount,
    required this.url,
  });

  factory Ticker.fromJson(Map<String, dynamic> json) {
    return Ticker(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? '',
      tickerType: json['ticker_type'] ?? 0,
      name: json['name'] ?? '',
      amount: json['amount'] ?? 0,
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'ticker_type': tickerType,
        'name': name,
        'amount': amount,
        'url': url,
      };
}

class FrameItem {
  final String id;
  final String regionId;
  final String type;
  final String name;
  final String? description;
  final String? imageId;
  final MediaImage? image;
  final FrameProperties? properties;
  final String? datetimeStart;
  final String? datetimeEnd;
  final bool deleteAfterEnd;
  final int? playlistCount;
  final List<PlaylistInfo> playlists;

  FrameItem({
    required this.id,
    required this.regionId,
    required this.type,
    required this.name,
    required this.description,
    required this.imageId,
    required this.image,
    required this.properties,
    required this.datetimeStart,
    required this.datetimeEnd,
    required this.deleteAfterEnd,
    required this.playlistCount,
    required this.playlists,
  });

  factory FrameItem.fromJson(Map<String, dynamic> json) {
    return FrameItem(
      id: json['id']?.toString() ?? '',
      regionId: json['region_id'] ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      imageId: json['image_id']?.toString(),
      image: json['image'] != null
          ? MediaImage.fromJson(json['image'])
          : null,
      properties: json['properties'] != null
          ? FrameProperties.fromJson(json['properties'])
          : null,
      datetimeStart: json['datetime_start'],
      datetimeEnd: json['datetime_end'],
      deleteAfterEnd: json['delete_after_end'] ?? false,
      playlistCount: json['playlist_count'],
      playlists: (json['playlists'] as List? ?? [])
          .map((e) => PlaylistInfo.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'region_id': regionId,
        'type': type,
        'name': name,
        'description': description,
        'image_id': imageId,
        'image': image?.toJson(),
        'properties': properties?.toJson(),
        'datetime_start': datetimeStart,
        'datetime_end': datetimeEnd,
        'delete_after_end': deleteAfterEnd,
        'playlist_count': playlistCount,
        'playlists': playlists.map((e) => e.toJson()).toList(),
      };
}

class FrameProperties {
  final Cutout? cutout;

  FrameProperties({
    required this.cutout,
  });

  factory FrameProperties.fromJson(Map<String, dynamic> json) {
    return FrameProperties(
      cutout: json['cutout'] != null
          ? Cutout.fromJson(json['cutout'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'cutout': cutout?.toJson(),
      };
}

class Cutout {
  final int x1;
  final int y1;
  final int x2;
  final int y2;

  Cutout({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  factory Cutout.fromJson(Map<String, dynamic> json) {
    return Cutout(
      x1: json['x1'] ?? 0,
      y1: json['y1'] ?? 0,
      x2: json['x2'] ?? 0,
      y2: json['y2'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'x1': x1,
        'y1': y1,
        'x2': x2,
        'y2': y2,
      };
}

class TickerItem {
  final String id;
  final String regionId;
  final String type;
  final String name;
  final String? description;
  final int? tickerType;
  final int? amount;
  final String? url;

  TickerItem({
    required this.id,
    required this.regionId,
    required this.type,
    required this.name,
    required this.description,
    required this.tickerType,
    required this.amount,
    required this.url,
  });

  factory TickerItem.fromJson(Map<String, dynamic> json) {
    return TickerItem(
      id: json['id']?.toString() ?? '',
      regionId: json['region_id'] ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      tickerType: json['ticker_type'],
      amount: json['amount'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'region_id': regionId,
        'type': type,
        'name': name,
        'description': description,
        'ticker_type': tickerType,
        'amount': amount,
        'url': url,
      };
}

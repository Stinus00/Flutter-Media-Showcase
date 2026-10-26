import 'package:flutter_video_test/media_cacher_stub.dart'
    if (dart.library.js_interop) 'package:flutter_video_test/media_cacher.dart';

class MediaCacheDeletion {
  MediaCacheDeletion({MediaCacher? mediaCacher})
    : _mediaCacher = mediaCacher ?? MediaCacher();

  final MediaCacher _mediaCacher;

  Future<void> deleteMediaNotInApi({
    required Set<String> imageIds,
    required Set<String> videoIds,
  }) async {
    await _deleteStoreEntries('images', imageIds);
    await _deleteStoreEntries('videos', videoIds);
  }

  Future<void> _deleteStoreEntries(String store, Set<String> apiIds) async {
    final cachedIds = await _mediaCacher.getMediaKeysWeb(store);
    for (final id in cachedIds.difference(apiIds)) {
      await _mediaCacher.deleteMediaWeb(store, id);
      _mediaCacher.forgetBlobUrlWeb(store, id);
    }
  }
}

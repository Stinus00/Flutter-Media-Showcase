import 'media_link.dart';

class MediaCacher {
  Future<List<MediaLink>> cacheAllMedia({required List<MediaLink> links}) =>
      throw UnsupportedError('MediaCacher is only available on web.');

  Future<String> loadImageBlobUrlFromIndexedDB(String id) =>
      throw UnsupportedError('MediaCacher is only available on web.');

  Future<String> loadVideoBlobUrlFromIndexedDB(String id) =>
      throw UnsupportedError('MediaCacher is only available on web.');

  Future<Set<String>> getMediaKeysWeb(String store) =>
      throw UnsupportedError('MediaCacher is only available on web.');

  Future<void> deleteMediaWeb(String store, String id) =>
      throw UnsupportedError('MediaCacher is only available on web.');

  void forgetBlobUrlWeb(String store, String id) =>
      throw UnsupportedError('MediaCacher is only available on web.');
}

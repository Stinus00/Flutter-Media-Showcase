class MediaCacher {
  Future<List<dynamic>> cacheAllMedia({required List<dynamic> links}) =>
      throw UnsupportedError('MediaCacher is only available on web.');

  Future<String> loadImageBlobUrlFromIndexedDB(String id) =>
      throw UnsupportedError('MediaCacher is only available on web.');

  Future<String> loadVideoBlobUrlFromIndexedDB(String id) =>
      throw UnsupportedError('MediaCacher is only available on web.');
}

class MediaLink {
  const MediaLink({required this.link, required this.type, this.duration, this.id, this.blobUrl, this.mimeType, this.localPath});

  final String? id;
  final String link;
  final String type;
  final String? blobUrl;
  final String? mimeType;
  final int? duration;
  final String? localPath;
}

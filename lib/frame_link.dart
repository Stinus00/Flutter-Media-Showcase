class FrameLink {
  const FrameLink({required this.link, required this.type, this.duration, this.id, this.blobUrl, this.mimeType, this.localPath, required this.x1, required this.y1, required this.x2, required this.y2});

  final String? id;
  final String link;
  final String type;
  final String? blobUrl;
  final String? mimeType;
  final int? duration;
  final String? localPath;

  final double x1;
  final double y1;
  final double x2;
  final double y2;
}

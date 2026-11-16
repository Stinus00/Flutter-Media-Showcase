class TickerLink {
  const TickerLink({
    required this.link,
    required this.type,
    this.id,
    this.blobUrl,
    this.localPath,
    this.creationType,
    this.tickerType,
    required this.tickerStrings,
  });

  final String? id;
  final String link;
  final String type;
  final String? blobUrl;
  final String? localPath;
  final String? creationType;
  final int? tickerType;
  final List<String> tickerStrings;
}

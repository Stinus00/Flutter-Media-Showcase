class TickerLink {
  const TickerLink({
    required this.link,
    required this.type,
    this.id,
    this.blobUrl,
    this.localPath,
    required this.tickerStrings,
  });

  final String? id;
  final String link;
  final String type;
  final String? blobUrl;
  final String? localPath;
  final List<String> tickerStrings;

}

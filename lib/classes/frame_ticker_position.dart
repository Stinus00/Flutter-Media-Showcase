class FrameTickerPosition {
  const FrameTickerPosition({
    required this.index,
    required this.frameId,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    this.fontSize,
  });

  final int index;
  final String frameId;
  final int x1;
  final int y1;
  final int x2;
  final int y2;
  final int? fontSize;

  FrameTickerPosition.fromJson(Map<String, dynamic> json)
    : index = _readInt(json['index']),
      frameId = json['frameId'] as String,
      x1 = _readInt(json['x1']),
      y1 = _readInt(json['y1']),
      x2 = _readInt(json['x2']),
      y2 = _readInt(json['y2']),
      fontSize = json['fontSize'] == null ? null : _readInt(json['fontSize']);

  Map<String, dynamic> toJson() {
    return {
      'index': index.toString(),
      'frameId': frameId,
      'x1': x1.toString(),
      'y1': y1.toString(),
      'x2': x2.toString(),
      'y2': y2.toString(),
      'fontSize': fontSize?.toString(),
    };
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    throw const FormatException('Frame ticker coordinates must be integers.');
  }
}

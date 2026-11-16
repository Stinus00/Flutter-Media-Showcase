import 'package:flutter/material.dart';

class FrameTickerPosition {
  const FrameTickerPosition({
    required this.index,
    required this.frameId,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    this.fontSize,
    this.fontColor,
  });

  final int index;
  final String frameId;
  final int x1;
  final int y1;
  final int x2;
  final int y2;
  final int? fontSize;
  final Color? fontColor;

  FrameTickerPosition.fromJson(Map<String, dynamic> json)
    : index = _readInt(json['index']),
      frameId = json['frameId'] as String,
      x1 = _readInt(json['x1']),
      y1 = _readInt(json['y1']),
      x2 = _readInt(json['x2']),
      y2 = _readInt(json['y2']),
      fontSize = json['fontSize'] == null ? null : _readInt(json['fontSize']),
      fontColor = json['fontColor'] == null
          ? null
          : _readColor(json['fontColor']);

  Map<String, dynamic> toJson() {
    return {
      'index': index.toString(),
      'frameId': frameId,
      'x1': x1.toString(),
      'y1': y1.toString(),
      'x2': x2.toString(),
      'y2': y2.toString(),
      'fontSize': fontSize?.toString(),
      'fontColor': fontColor?.toARGB32(),
    };
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    throw const FormatException('Frame ticker coordinates must be integers.');
  }

  static Color _readColor(Object? value) {
    if (value is Color) return value;
    final argb = switch (value) {
      int value => value,
      String value => int.tryParse(value),
      _ => null,
    };
    if (argb == null) {
      throw const FormatException('Frame ticker font color must be an ARGB integer.');
    }

    return Color.fromARGB(
      (argb >> 24) & 0xff,
      (argb >> 16) & 0xff,
      (argb >> 8) & 0xff,
      argb & 0xff,
    );
  }
}

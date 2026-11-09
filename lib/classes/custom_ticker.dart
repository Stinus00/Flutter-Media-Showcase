import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

class CustomTicker extends StatefulWidget {
  const CustomTicker(
    this.textList, {
    super.key,
    this.leftToRight = true,
    this.tickerSymbol = '',
    this.tickerSpeed = 50.0,
    this.tickerFontSize = 14.0,
    this.border = false,
    this.borderColor = Colors.black,
    this.borderWidth = 0.0,
    this.textColor = Colors.black,
    this.lastWord = '',
  });

  final List<String> textList;
  final bool leftToRight;
  final String tickerSymbol;
  final double tickerSpeed;
  final double tickerFontSize;
  final Color textColor;
  final bool border;
  final Color borderColor;
  final double borderWidth;

  // Unused might be used in the future
  final String lastWord;

  @override
  State<CustomTicker> createState() => _CustomTickerState();
}

class _CustomTickerState extends State<CustomTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double? _animationDistance;
  double? _animationSpeed;
  bool? _animationDirection;
  late List<String> oldTextList;

  // Join all tickers together with symbol
  String get _tickerText => widget.textList
      .map((text) => '${widget.tickerSymbol} $text')
      .join(' ');

  // Regular text style for the ticker
  TextStyle get _textStyle => TextStyle(
    fontSize: widget.tickerFontSize,
    height: 1.3,
    color: widget.textColor,
  );

  // Outline for the ticker
  TextStyle get _borderTextStyle => TextStyle(
    fontSize: widget.tickerFontSize,
    height: 1.3,
    foreground: Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = widget.borderWidth
      ..color = widget.borderColor,
  );

  @override
  void initState() {
    super.initState();
    oldTextList = List<String>.of(widget.textList);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void didUpdateWidget(covariant CustomTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldTextList, widget.textList)) {
      oldTextList = List<String>.of(widget.textList);
      _controller
        ..stop()
        ..value = 0;
      _animationDistance = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scheduleAnimation(double distance) {
    final speed = widget.tickerSpeed.abs();
    final direction = widget.leftToRight == (widget.tickerSpeed >= 0);
    // Avoid restarting the ticker on rebuilds unless its geometry or motion changes.
    if (_animationDistance == distance &&
        _animationSpeed == speed &&
        _animationDirection == direction) {
      return;
    }

    _animationDistance = distance;
    _animationSpeed = speed;
    _animationDirection = direction;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _animationDistance != distance ||
          _animationSpeed != speed ||
          _animationDirection != direction) {
        return;
      }

      _controller.stop();
      if (speed == 0 || distance == 0) {
        _controller.value = 0;
        return;
      }

      // One animation cycle moves exactly one ticker text.
      final durationMilliseconds = (distance / speed * 1000).round();
      _controller.repeat(
        period: Duration(
          milliseconds: durationMilliseconds < 1 ? 1 : durationMilliseconds,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final tickerText = _tickerText;
    // Get usual style and combine with custom styles
    final inheritedStyle = DefaultTextStyle.of(context).style;
    final style = inheritedStyle.merge(_textStyle);
    final borderStyle = inheritedStyle.merge(_borderTextStyle);
    
    final textDirection = Directionality.of(context);
    // Measure the text so copies fit edge-to-edge and the viewport can fit its line box.
    final textPainter = TextPainter(
      text: TextSpan(text: tickerText, style: style),
      textDirection: textDirection,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth || tickerText.isEmpty) {
          return Text(
            tickerText,
            style: style,
            maxLines: 1,
            softWrap: false,
            textDirection: textDirection,
          );
        }

        final viewportWidth = constraints.maxWidth;
        final textWidth = textPainter.width;
        if (textWidth <= 0) {
          return SizedBox(width: viewportWidth);
        }
        final borderPadding = widget.border ? widget.borderWidth : 0.0;
        final verticalPadding = borderPadding + 2;
        // TextPainter width can omit a glyph's final antialiased/stroke pixels.
        final textEndPadding = widget.tickerFontSize * 0.25 + borderPadding * 2;
        final renderedTextWidth = textWidth + textEndPadding;
        // Keep the next copy far enough away that it cannot overlap the last word.
        // For some reason tickerGap not being variable makes it give error, 
        //  so I made it as small as possible.
        final tickerGap = borderPadding / 10;
        final tickerWidth = renderedTextWidth + tickerGap + borderPadding * 2;
        _scheduleAnimation(tickerWidth);
        final copies = (viewportWidth / tickerWidth).ceil() + 2;
        final scrollRight = widget.leftToRight == (widget.tickerSpeed >= 0);
        final contentWidth = tickerWidth * copies;

        // Clip the moving row to the available viewport; vertical padding protects
        //  glyph outlines and descenders from being cut off by the clip.
        return ClipRect(
          child: SizedBox(
            width: viewportWidth,
            height: textPainter.height + verticalPadding * 2,
            child: AnimatedBuilder(
              animation: _controller,
              child: Row(
                textDirection: textDirection,
                children: List.generate(
                  copies,
                  (_) => SizedBox(
                    width: tickerWidth,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: borderPadding,
                        vertical: verticalPadding,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: renderedTextWidth,
                            child: Stack(
                              children: [
                                // Draw the stroke first so the solid text sits cleanly on top.
                                if (widget.border)
                                  Text(
                                    tickerText,
                                    style: borderStyle,
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.visible,
                                    textDirection: textDirection,
                                  ),
                                Text(
                                  tickerText,
                                  style: style,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.visible,
                                  textDirection: textDirection,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: tickerGap),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              builder: (context, child) {
                final progress = _controller.value;
                final offset = scrollRight
                    ? tickerWidth * (progress - 1)
                    : -tickerWidth * progress;
                // Let the repeated row exceed the viewport while keeping its parent
                // constrained to the ticker's visible width.
                return OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: contentWidth,
                  maxWidth: contentWidth,
                  child: Transform.translate(
                    offset: Offset(offset, 0),
                    child: SizedBox(width: contentWidth, child: child),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

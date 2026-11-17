import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ActivityMonitor extends StatefulWidget {
  const ActivityMonitor({
    super.key, 
    required this.child,
    required this.onVisibilityChanged,
    required this.nextPlaylistButtonFocusNode,
    required this.settingsButtonFocusNode,
  });

  final Widget child;
  final ValueChanged<bool> onVisibilityChanged;
  final FocusNode nextPlaylistButtonFocusNode;
  final FocusNode settingsButtonFocusNode;

  @override
  State<ActivityMonitor> createState() => _ActivityMonitorState();
}

class _ActivityMonitorState extends State<ActivityMonitor> {
  Timer? _showSettingsTimer;

  bool _buttonsVisible = true;

  void _setButtonsVisible(bool visible) {
    if (_buttonsVisible == visible) return;

    setState(() {
      _buttonsVisible = visible;
    });
    widget.onVisibilityChanged(visible);
  }

  void _updateActivity() {
    _startIdleTimer();
    _setButtonsVisible(true);
  }

  void _startIdleTimer() {
    _showSettingsTimer?.cancel();
    _showSettingsTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      _setButtonsVisible(false);
    });
  }

  @override
  void initState() {
    super.initState();
    _startIdleTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        final isArrowKey =
            event.logicalKey == LogicalKeyboardKey.arrowUp ||
            event.logicalKey == LogicalKeyboardKey.arrowDown ||
            event.logicalKey == LogicalKeyboardKey.arrowLeft ||
            event.logicalKey == LogicalKeyboardKey.arrowRight;
        if (isArrowKey &&
            (event is KeyDownEvent || event is KeyRepeatEvent)) {
          final wasHidden = _buttonsVisible;
          _updateActivity();
          if (wasHidden) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                widget.settingsButtonFocusNode.requestFocus();
              }
            });
          } else if (widget.settingsButtonFocusNode.hasFocus &&
              event.logicalKey == LogicalKeyboardKey.arrowDown) {
            widget.nextPlaylistButtonFocusNode.requestFocus();
          } else if (widget.nextPlaylistButtonFocusNode.hasFocus &&
              event.logicalKey == LogicalKeyboardKey.arrowUp) {
            widget.settingsButtonFocusNode.requestFocus();
          } else if (!widget.settingsButtonFocusNode.hasFocus &&
              !widget.nextPlaylistButtonFocusNode.hasFocus) {
            widget.settingsButtonFocusNode.requestFocus();
          } else {
            return KeyEventResult.handled;
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onHover: (event) => _updateActivity(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _updateActivity(),
          child: widget.child
        )
      )
    );
  }

  @override
  void dispose() {
    _showSettingsTimer?.cancel();
    super.dispose();
  }
}
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
    required this.isSettingsOpen,
  });

  final Widget child;
  final ValueChanged<bool> onVisibilityChanged;
  final FocusNode nextPlaylistButtonFocusNode;
  final FocusNode settingsButtonFocusNode;
  final bool isSettingsOpen;

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
    if(widget.isSettingsOpen) {
      _stopIdleTimer();
    } else {
      _startIdleTimer();
    }
    _setButtonsVisible(true);
  }

  void _startIdleTimer() {
    _showSettingsTimer?.cancel();
    _showSettingsTimer = Timer(const Duration(seconds: 6), () { // 6 seconds
      if (!mounted) return;
      _setButtonsVisible(false);
    });
  }

  void _startFastTimer() {
    _showSettingsTimer?.cancel();
    _showSettingsTimer = Timer(const Duration(milliseconds: 3500), () { // 3.5 seconds
      if(!mounted) return;
      _setButtonsVisible(false);
    });
  }

  void _stopIdleTimer() {
    _showSettingsTimer?.cancel();
  }

  @override
  void initState() {
    super.initState();
    _startIdleTimer();
  }

  @override
  void didUpdateWidget(covariant ActivityMonitor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSettingsOpen != oldWidget.isSettingsOpen) {
      if (widget.isSettingsOpen) {
        _stopIdleTimer();
      } else {
        _startFastTimer();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (widget.isSettingsOpen) return KeyEventResult.ignored;

        final isArrowKey =
            event.logicalKey == LogicalKeyboardKey.arrowUp ||
            event.logicalKey == LogicalKeyboardKey.arrowDown ||
            event.logicalKey == LogicalKeyboardKey.arrowLeft ||
            event.logicalKey == LogicalKeyboardKey.arrowRight ||
            event.logicalKey == LogicalKeyboardKey.select;
        if (isArrowKey &&
            (event is KeyDownEvent || event is KeyRepeatEvent)) {
          final wasHidden = !_buttonsVisible;
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
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              widget.nextPlaylistButtonFocusNode.requestFocus();
            } else {
              widget.settingsButtonFocusNode.requestFocus();
            }
          } else {
            return KeyEventResult.ignored;
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: _buttonsVisible ? SystemMouseCursors.basic : SystemMouseCursors.none,
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
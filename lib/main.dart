import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'media_downloader.dart';
import 'media_link.dart';
import 'media_sources.dart';

void main() => runApp(const VideoApp());

class VideoApp extends StatefulWidget {
  const VideoApp({super.key});

  @override
  State<VideoApp> createState() => _VideoAppState();
}

class _VideoAppState extends State<VideoApp> {
  final MediaDownloader _mediaDownloader = MediaDownloader();
  List<MediaLink> _mediaLinks = [];

  String? _imagePath;
  String? _videoPath;
  VideoPlayerController? _controller;
  Timer? _imageTimer;
  String? _videoError;
  bool _isChangingVideo = false;
  bool _hasStartedPlayback = false;
  bool _isPreparingMedia = true;
  String? _preloadError;
  int _currentLinkIndex = 0;

  MediaLink? get _currentMedia =>
      _mediaLinks.isEmpty ? null : _mediaLinks[_currentLinkIndex];

  @override
  void initState() {
    super.initState();
    unawaited(WakelockPlus.enable());
    unawaited(_prepareMedia());
  }

  // Download the media given and initialize the first media.
  Future<void> _prepareMedia() async {
    try {
      // If on web give back just the links, 
      //  otherwise download media.
      _mediaLinks = kIsWeb == true
          ? List.of(mediaLinks)
          : await _mediaDownloader.downloadAllMedia(links: mediaLinks);
      _isPreparingMedia = false;
      if (mounted) setState(() {});
      await _initializeMedia();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isPreparingMedia = false;
        _preloadError = error.toString();
      });
    }
  }

  // Check if first media is image or video
  //  then set first media appropriately
  //  (set timer for image and set controller for video)
  Future<void> _initializeMedia() async {
    final media = _currentMedia;
    if (media == null) return;
    if (media.type == 'image') {
      _imagePath = kIsWeb ? null : media.link;

      if (!mounted) return;
      setState(() {});
      _imageTimer = Timer(
        Duration(milliseconds: (media.duration ?? 5000).round()),
        _playNextMedia,
      );
      return;
    }

    // Use file path if not on web and
    //  use url if on web.
    VideoPlayerController controller;
    if (!kIsWeb) {
      _videoPath = media.link;
      controller = VideoPlayerController.file(File(_videoPath!));
    } else {
      controller = VideoPlayerController.networkUrl(Uri.parse(media.link));
    }

    _controller = controller;
    controller.addListener(_handleVideoState);

    // Add controller settings.
    try {
      await controller.setLooping(false);
      controller.value = controller.value.copyWith(volume: 0.0);
      await controller.initialize();
      if (!mounted) return;
      if (!kIsWeb || _hasStartedPlayback) {
        await controller.play();
      }
      setState(() {});
    } catch (error) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _videoError = error.toString();
      });
    }
  }

  void _handleVideoState() {
    final value = _controller?.value;
    if (value == null) return;
    if (value.isInitialized &&
        !value.isPlaying &&
        value.position >= value.duration &&
        !_isChangingVideo) {
      unawaited(_playNextMedia());
    }
  }

  // Play next media.
  // // Stop image timer if there is one
  // // Remove controller if there is one
  // // Find next link
  Future<void> _playNextMedia() async {
    if (_mediaLinks.isEmpty) return;

    _isChangingVideo = true;
    _imageTimer?.cancel();
    _imageTimer = null;
    final controller = _controller;
    controller?.removeListener(_handleVideoState);
    await controller?.dispose();
    _controller = null;
    _currentLinkIndex = (_currentLinkIndex + 1) % _mediaLinks.length;
    _videoError = null;
    _imagePath = null;
    _videoPath = null;
    _isChangingVideo = false;
    await _initializeMedia();
  }

  // Widget to display the app
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Demo',
      home: Scaffold(
        body: Stack(
          alignment: Alignment.center,
          children: [
            // Center(child: _buildMedia()),
            // _buildStartButton(),
            // if (kIsWeb)
            //   Column(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     mainAxisSize: MainAxisSize.min,
            //     children: [
            //       Text('Browser is ${_browser?.browser ?? 'Not on web'}'),
            //       Text('Version is ${_browser?.version ?? 'Not on web'}'),
            //     ],
            //   ),
            _buildTickers(),
          ],
        ),
      ),
    );
  }

  // Widget to show the media
  // // Image loading using Image.network on web
  // //  and Image.file on app
  // // Video loading using Videoplayer and controller
  // // Loading screen while media gets downloaded
  Widget _buildMedia() {
    if (_isPreparingMedia) {
      return const CircularProgressIndicator();
    }
    if (_preloadError != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Could not download media:\n$_preloadError',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_videoError != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Could not load video:\n$_videoError\n$_videoPath',
          textAlign: TextAlign.center,
        ),
      );
    }

    final media = _currentMedia!;
    if (media.type == 'image') {
      if (kIsWeb) {
        return Image.network(
          media.link,
          fit: BoxFit.contain,
          height: double.infinity,
          width: double.infinity,
        );
      }
      return _imagePath == null
          ? const CircularProgressIndicator()
          : Image.file(
              File(_imagePath!),
              fit: BoxFit.contain,
              height: double.infinity,
              width: double.infinity,
            );
    }

    return _controller?.value.isInitialized ?? false
        ? AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          )
        : const CircularProgressIndicator();
  }

  Widget _buildTickers() {
    final tickers = textTickers;
    var allTickerThing = '';

    for(String ticker in tickers) {
      allTickerThing += ticker;
      allTickerThing += " -|-|- ";
    }

    return 
      ConstrainedBox(
        constraints: const BoxConstraints(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextScroll(allTickerThing,
              velocity: Velocity(pixelsPerSecond: Offset(200, 0)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
        
  }

  // Start button widget for web
  //  to comply with autoplay restrictions.
  Widget _buildStartButton() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: _videoError == null &&
              kIsWeb &&
              !_hasStartedPlayback &&
              _controller?.value.isInitialized == true &&
              !_controller!.value.isPlaying
          ? FloatingActionButton.extended(
              key: const ValueKey('sample-button'),
              backgroundColor: const Color.fromARGB(99, 0, 0, 0),
              hoverColor: const Color.fromARGB(175, 0, 0, 0),
              foregroundColor: Colors.white,
              elevation: 0,
              onPressed: () {
                setState(() {
                  _hasStartedPlayback = true;
                  _controller!.play();
                });
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start'),
            )
          : const SizedBox.shrink(key: ValueKey('hidden-button')),
    );
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    _controller?.dispose();
    unawaited(WakelockPlus.disable());
    super.dispose();
  }
}

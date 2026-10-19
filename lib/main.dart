import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  List<MediaLink> _mediaLinksFrame = [];

  // Testing
  bool _initialPlaylistActive = true;

  String? _imagePath;
  String? _framePath;
  String? _videoPath;
  VideoPlayerController? _controller;
  Timer? _imageTimer;
  Timer? _frameTimer;
  String? _videoError;
  bool _isChangingVideo = false;
  bool _hasStartedPlayback = false;
  bool _isPreparingMedia = true;
  bool _changingPlaylist = false;
  String? _preloadError;
  int _currentLinkIndex = 0;
  int _currentLinkIndexFrame = 0;

  // Frame coordinates
  double? x1;
  double? y1;
  double? x2;
  double? y2;

  MediaLink? get _currentMedia =>
      _mediaLinks.isEmpty ? null : _mediaLinks[_currentLinkIndex];
  MediaLink? get _currentMediaFrame =>
      _mediaLinksFrame.isEmpty ? null : _mediaLinksFrame[_currentLinkIndexFrame];

  @override
  void initState() {
    super.initState();
    unawaited(WakelockPlus.enable());
    unawaited(_prepareMedia(mediaLinks, mediaLinksFrames));
  }

  Future<void> _startNextPlaylist() async {
    _currentLinkIndex = 0;
    _prepareMedia(mediaLinks, mediaLinksFrames);
    _initialPlaylistActive = !_initialPlaylistActive;
    _changingPlaylist = false;
  }

  // Download the media given and initialize the first media.
  Future<void> _prepareMedia(List<MediaLink> links, List<MediaLink> frameLinks) async {
    try {
      // If on web give back just the links, 
      //  otherwise download media.
      _mediaLinks = kIsWeb == true
          ? List.of(links)
          : await _mediaDownloader.downloadAllMedia(links: links);
      _mediaLinksFrame = kIsWeb == true
          ? List.of(frameLinks)
          : await _mediaDownloader.downloadAllMedia(links: frameLinks);
      _isPreparingMedia = false;
      if (mounted) setState(() {});
      await _initializeMedia();
      await _initializeFrame();
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
    if (media == null) {
      return;
    }
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

  Future<void> _initializeFrame() async {
    final mediaFrame = _currentMediaFrame;

    if (mediaFrame == null) {
      _updateFrameCoordinates(null);
      return;
    }
    _updateFrameCoordinates(mediaFrame.link);
    if (mediaFrame.type == 'image') {
      _framePath = kIsWeb ? null : mediaFrame.link;

      if (!mounted) return;
      setState(() {});
      _frameTimer = Timer(
        Duration(milliseconds: (mediaFrame.duration ?? 5000).round()),
        _playNextFrame,
      );
      return;
    }
  }

  void _updateFrameCoordinates(String? link) {
    final decodedLink = link == null ? '' : Uri.decodeComponent(link);

    double? readCoordinate(String name) {
      final match = RegExp(
        '\\b$name\\s*=\\s*(-?\\d+(?:\\.\\d+)?)',
        caseSensitive: false,
      ).firstMatch(decodedLink);
      return match == null ? null : double.tryParse(match.group(1)!);
    }

    final nextX1 = readCoordinate('X1');
    final nextY1 = readCoordinate('Y1');
    final nextX2 = readCoordinate('X2');
    final nextY2 = readCoordinate('Y2');

    if (nextX1 == null || nextY1 == null || nextX2 == null || nextY2 == null) {
      x1 = null;
      y1 = null;
      x2 = null;
      y2 = null;
      return;
    }

    x1 = nextX1;
    y1 = nextY1;
    x2 = nextX2;
    y2 = nextY2;
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

  // Skip current media because of error
  // // Remove media from list
  void _skipMedia() {
    _mediaLinks.removeAt(_currentLinkIndex);
    _currentLinkIndex -= 1;
    _playNextMedia();
  }

  // Skip current media because of error
  // // Remove media from list
  void _skipFrame() {
    _mediaLinksFrame.removeAt(_currentLinkIndexFrame);
    _currentLinkIndexFrame -= 1;
    _playNextFrame();
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
    if (_changingPlaylist) {
      unawaited(_startNextPlaylist());
      return;
    }
    await _initializeMedia();
  }

  Future<void> _playNextFrame() async {
    if (_mediaLinksFrame.isEmpty) return;

    _frameTimer?.cancel();
    _frameTimer = null;
    _currentLinkIndexFrame = (_currentLinkIndexFrame + 1) % _mediaLinksFrame.length;
    _framePath = null;

    await _initializeFrame();
  }

  // Widget to display the app
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Demo',
      home: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            const canvasWidth = 1920.0;
            const canvasHeight = 1080.0;
            final scale = math.min(
              constraints.maxWidth / canvasWidth,
              constraints.maxHeight / canvasHeight,
            );

            return Stack(
              alignment: Alignment.center,
              children: [
                if (x1 != null)
                  Center(
                    child: SizedBox(
                      width: canvasWidth * scale,
                      height: canvasHeight * scale,
                      child: Stack(
                        children: [
                          Positioned(
                            left: x1! * scale,
                            top: y1! * scale,
                            width: (x2! - x1!) * scale,
                            height: (y2! - y1!) * scale,
                            child: ClipRect(child: _buildMedia()),
                          ),
                          _buildMediaFrame(),
                        ],
                      ),
                    ),
                  )
                else
                  Center(child: _buildMedia()),
                _buildStartButton(),
                // Positioned(
                //   right: 16,
                //   bottom: 16,
                //   child: _buildNextPlaylistButton(),
                // ),
                // if (kIsWeb)
                //   Column(
                //     mainAxisAlignment: MainAxisAlignment.center,
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //       Text('Browser is ${_browser?.browser ?? 'Not on web'}'),
                //       Text('Version is ${_browser?.version ?? 'Not on web'}'),
                //     ],
                //   ),
              ],
            );
          },
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
      _skipMedia();

      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Could not load video:\n$_videoError\n$_videoPath',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_mediaLinks.isEmpty) {
      return Image.asset(
        'assets/placeholder.png',
        fit: BoxFit.contain,
        height: double.infinity,
        width: double.infinity,
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

  Widget _buildMediaFrame() {
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

    if (_mediaLinksFrame.isEmpty) {
      return Image.asset(
        'assets/placeholder.png',
        fit: BoxFit.contain,
        height: double.infinity,
        width: double.infinity,
      );
    }

    final media = _currentMediaFrame!;

    if (media.type == 'image') {
      if (kIsWeb) {
        return Image.network(
          media.link,
          fit: BoxFit.contain,
          height: double.infinity,
          width: double.infinity,
        );
      }
      return _framePath == null
          ? const CircularProgressIndicator()
          : Image.file(
              File(_framePath!),
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

  // Button to play next playlist for testing
  Widget _buildNextPlaylistButton() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child:
        FloatingActionButton.extended(
          key: const ValueKey('sample-button'),
          backgroundColor: const Color.fromARGB(98, 59, 128, 255),
          hoverColor: const Color.fromARGB(97, 45, 119, 255),
          foregroundColor: Colors.white,
          elevation: 0,
          onPressed: () {
            setState(() {
              _changingPlaylist = true;
              if (_mediaLinks.isEmpty) _startNextPlaylist();
            });
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Next'),
        )
    );
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    _frameTimer?.cancel();
    _controller?.dispose();
    unawaited(WakelockPlus.disable());
    super.dispose();
  }
}

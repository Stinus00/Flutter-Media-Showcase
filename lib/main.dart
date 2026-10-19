import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_video_test/media_cacher_stub.dart'
    if (dart.library.js_interop) 'package:flutter_video_test/media_cacher.dart';
import 'package:flutter_video_test/media_downloader.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'media_link.dart';
import 'media_sources.dart';
import 'api_call.dart';

void main() => runApp(const VideoApp());

class VideoApp extends StatefulWidget {
  const VideoApp({super.key});

  @override
  State<VideoApp> createState() => _VideoAppState();
}

class _VideoAppState extends State<VideoApp> {
  final MediaCacher _mediaCacher = MediaCacher();
  final ApiCall _apiCall = ApiCall();
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
  ImageProvider? _activeImageProvider;
  String? _imageError;
  String? _videoError;
  bool _isChangingVideo = false;
  bool _hasStartedPlayback = false;
  bool _isPreparingMedia = true;
  bool _changingPlaylist = false;
  String? _preloadError;
  int _currentLinkIndex = 0;
  int _currentLinkIndexFrame = 0;
  Timer? _scheduleCheckTimer;
  Timer? _payloadCheckTimer;
  bool _checkSchedule = false;
  bool _checkPayload = false;
  bool _isCheckingForChanges = false;
  bool _payloadCheckQueued = false;

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
    unawaited(_prepareMedia(mediaLinks, mediaLinksFrames, startChangeChecks: true));
  }

  // Start Next Playlist
  Future<void> _startNextPlaylist() async {
    _currentLinkIndex = 0;
    _prepareMedia(mediaLinks, mediaLinksFrames);
    _initialPlaylistActive = !_initialPlaylistActive;
    _changingPlaylist = false;
  }

  // Download the media given and initialize the first media.
  Future<void> _prepareMedia(
    List<MediaLink> links,
    List<MediaLink> frameLinks, {
    bool startChangeChecks = false,
  }) async {
    try {
      print('test');
      // If on web give back just the links,
      //  otherwise download media.
      //  otherwise if media is empty download media.

      // if (kIsWeb) {
      //   _mediaLinks = await _mediaCacher.cacheAllMedia(links: mediaLinks);
      // } else 
      if (_mediaLinks.isEmpty) {
        _mediaLinks = await _apiCall.getMediaFromApi();
      }
      _mediaLinksFrame = kIsWeb == true
          ? List.of(frameLinks)
          : await _mediaDownloader.downloadAllMedia(links: frameLinks);

      _isPreparingMedia = false;
      if (mounted) setState(() {});
      await _initializeMedia();
      await _initializeFrame();
      if (startChangeChecks) {
        _startChangeChecks();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isPreparingMedia = false;
        _preloadError = error.toString();
      });
    }
  }

  // Start timers
  // // 1 minute for checking if schedules changed
  // // 15 minutes for checking if api changed
  void _startChangeChecks() {
    _scheduleCheckTimer ??= Timer.periodic(
      const Duration(minutes: 1),
      (_) { 
        _checkSchedule = true;
        if(_mediaLinks.isEmpty) {
            unawaited(_prepareMedia(mediaLinks, mediaLinksFrames));
        }
      }
    );
    _payloadCheckTimer ??= Timer.periodic(
      const Duration(minutes: 15),
      (_) {
        _checkPayload = true;
        if(_mediaLinks.isEmpty) {
            unawaited(_prepareMedia(mediaLinks, mediaLinksFrames));
        }
      }
    );
  }

  // Check if there's any changes in api or schedules
  // Clear everything if there are changes.
  Future<void> _checkForMediaChanges({bool checkPayload = false}) async {
    if (_isPreparingMedia) return;
    if (_isCheckingForChanges) {
      _payloadCheckQueued = _payloadCheckQueued || checkPayload;
      return;
    }

    _isCheckingForChanges = true;
    try {
      final payloadChanged = checkPayload
          ? await _apiCall.hasPayloadChanged()
          : false;
      final schedulesChanged = _apiCall.haveSchedulesChanged();
      if (!payloadChanged && !schedulesChanged) return;

      final updatedMediaLinks = await _apiCall
          .rebuildMediaForCurrentSchedules();
      _isChangingVideo = true;
      _imageTimer?.cancel();
      _imageTimer = null;
      final controller = _controller;
      controller?.removeListener(_handleVideoState);
      await controller?.dispose();
      _controller = null;
      _mediaLinks = updatedMediaLinks;
      _currentLinkIndex = 0;
      _videoError = null;
      _imagePath = null;
      _videoPath = null;
      _isChangingVideo = false;

      if (!mounted) return;
      setState(() {});
      await _initializeMedia();
    } catch (error) {
      debugPrint('Error checking for media changes: $error');
    } finally {
      _isChangingVideo = false;
      _isCheckingForChanges = false;
      if (_payloadCheckQueued && mounted) {
        _payloadCheckQueued = false;
        unawaited(_checkForMediaChanges(checkPayload: true));
      }
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
      if (kIsWeb) {
        try {
          final blobUrl = await _mediaCacher.loadImageBlobUrlFromIndexedDB(
            media.id!,
          );
          if (!mounted) return;
          _imagePath = blobUrl;
          _activeImageProvider = NetworkImage(blobUrl);
        } catch (error) {
          if (!mounted) return;
          setState(() {
            _imageError = error.toString();
          });
          return;
        }
      } else {
        _imagePath = media.localPath;
      }

      if (!mounted) return;
      setState(() {});
      if (!kIsWeb || _hasStartedPlayback) {
        _startImageTimer(media);
      }
      return;
    }

    // Use file path if not on web and
    //  use url if on web.
    VideoPlayerController controller;
    if (!kIsWeb) {
      _videoPath = media.localPath;
      controller = VideoPlayerController.file(File(_videoPath!));
    } else {
      try {
        final blobUrl = await _mediaCacher.loadVideoBlobUrlFromIndexedDB(
          media.id!,
        );
        if (!mounted) return;
        _videoPath = blobUrl;
        controller = VideoPlayerController.networkUrl(Uri.parse(blobUrl));
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _videoError = "$error\nid: ${media.id}\ntype: ${media.type}";
        });
        return;
      }
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
        _videoError =
            "$error\nid: ${media.link}\ntype: ${media.type}\ncontroller: ${controller.value}";
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

  // Handle video state changes
  //  and play next media if video is finished.
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

  // Start timer for image
  // Cancel any existing timer
  void _startImageTimer(MediaLink media) {
    _imageTimer?.cancel();
    _imageTimer = Timer(
      Duration(milliseconds: (media.duration ?? 5000).round()),
      _playNextMedia,
    );
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

    final nextIndex = (_currentLinkIndex + 1) % _mediaLinks.length;
    final nextMedia = _mediaLinks[nextIndex];
    if (nextMedia.type == 'image') {
      await _playNextImage(nextIndex, nextMedia);
      return;
    }

    await _playNextVideo(nextIndex, nextMedia);
  }

  // Play next video.
  // // Dispose of current controller
  // // Load next video from blob url if on web
  // // Load next video from file if not on web
  // // Initialize next video controller
  Future<void> _playNextVideo(int nextIndex, MediaLink media) async {
    VideoPlayerController? nextController;
    String? nextVideoPath;

    try {
      if (kIsWeb) {
        final blobUrl = await _mediaCacher.loadVideoBlobUrlFromIndexedDB(
          media.id!,
        );
        nextVideoPath = blobUrl;
        nextController = VideoPlayerController.networkUrl(Uri.parse(blobUrl));
      } else {
        nextVideoPath = media.localPath!;
        nextController = VideoPlayerController.file(File(nextVideoPath));
      }

      final controllerToInitialize = nextController;
      await controllerToInitialize.setLooping(false);
      controllerToInitialize.value = controllerToInitialize.value.copyWith(
        volume: 0.0,
      );
      await controllerToInitialize.initialize();
      if (!kIsWeb || _hasStartedPlayback) {
        await controllerToInitialize.play();
      }
    } catch (error) {
      await nextController?.dispose();
      if (!mounted) return;
      setState(() {
        _videoError = '$error\nid: ${media.link}\ntype: ${media.type}';
        _isChangingVideo = false;
      });
      return;
    }

    final readyController = nextController;
    if (!mounted) {
      await readyController.dispose();
      return;
    }

    final controller = _controller;
    controller?.removeListener(_handleVideoState);
    readyController.addListener(_handleVideoState);
    _controller = readyController;
    _currentLinkIndex = nextIndex;
    _videoPath = nextVideoPath;
    _videoError = null;
    _imageError = null;
    _imagePath = null;
    _isChangingVideo = false;
    setState(() {});

    await controller?.dispose();
    await _evictActiveImage();
    _handleVideoState();
  }

  // Play next image.
  // // Dispose of current controller
  // // Load next image from blob url if on web
  // // Load next image from file if not on web
  // // Precache next image
  // // Set next image as active image
  Future<void> _playNextImage(int nextIndex, MediaLink media) async {
    String? imagePath;
    ImageProvider? imageProvider;
    String? imageError;

    try {
      if (kIsWeb) {
        imagePath = await _mediaCacher.loadImageBlobUrlFromIndexedDB(media.id!);
        imageProvider = NetworkImage(imagePath);
      } else {
        imagePath = media.localPath!;
        imageProvider = FileImage(File(imagePath));
      }

      if (!mounted) return;
      Object? loadingError;
      await precacheImage(
        imageProvider,
        context,
        onError: (exception, _) {
          loadingError = exception;
        },
      );
      if (loadingError != null) {
        throw StateError('Could not decode image: $loadingError');
      }
    } catch (error) {
      imageError = error.toString();
      imagePath = null;
      imageProvider = null;
    }

    final controller = _controller;
    controller?.removeListener(_handleVideoState);
    await controller?.dispose();
    await _evictActiveImage();
    if (!mounted) return;

    _controller = null;
    _currentLinkIndex = nextIndex;
    _videoError = null;
    _imageError = imageError;
    _imagePath = imagePath;
    _activeImageProvider = imageProvider;
    _videoPath = null;
    _isChangingVideo = false;
    
    if(_checkSchedule) {
      await _checkForMediaChanges();
      _checkSchedule = false;
    }
    if(_checkPayload) {
      await _checkForMediaChanges(checkPayload: true);
      _checkPayload = false;
    }
    if (_changingPlaylist) {
      unawaited(_startNextPlaylist());
      return;
    }
    await _initializeMedia();
    setState(() {});

    if (imageError == null && (!kIsWeb || _hasStartedPlayback)) {
      _startImageTimer(media);
    }
  }

  // Evict the active image from memory to free up resources.
  Future<void> _evictActiveImage() async {
    final imageProvider = _activeImageProvider;
    _activeImageProvider = null;
    _imagePath = null;
    if (imageProvider != null) {
      await imageProvider.evict();
    }
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
      theme: ThemeData(scaffoldBackgroundColor: Colors.black),
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
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: _buildNextPlaylistButton(),
                ),  
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
    // Show any error if there is one
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
    if (_imageError != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Could not load image:\n$_imageError',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_mediaLinks.isEmpty) {
      return Image.asset(
        'assets/placeholder-green.png',
        fit: BoxFit.contain,
        height: double.infinity,
        width: double.infinity,
      );
    }

    final media = _currentMedia!;

    if (media.type == 'image') {
      if (kIsWeb) {
        return _imagePath == null
            ? const CircularProgressIndicator()
            : Image(
                image: _activeImageProvider!,
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
    final media = _currentMedia;
    final isImage = media?.type == 'image';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child:
          _videoError == null &&
              kIsWeb &&
              !_hasStartedPlayback &&
              (isImage ||
                  (_controller?.value.isInitialized == true &&
                      !_controller!.value.isPlaying))
          ? FloatingActionButton.extended(
              key: const ValueKey('sample-button'),
              backgroundColor: const Color.fromARGB(99, 0, 0, 0),
              hoverColor: const Color.fromARGB(175, 0, 0, 0),
              foregroundColor: Colors.white,
              elevation: 0,
              onPressed: () {
                setState(() {
                  _hasStartedPlayback = true;
                  if (isImage) {
                    _startImageTimer(media!);
                  } else {
                    _controller!.play();
                  }
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
      child: FloatingActionButton.extended(
        key: const ValueKey('sample-button'),
        backgroundColor: const Color.fromARGB(98, 59, 128, 255),
        hoverColor: const Color.fromARGB(97, 45, 119, 255),
        foregroundColor: Colors.white,
        elevation: 0,
        onPressed: () {
          setState(() {
            _checkPayload = true;
            if(_mediaLinks.isEmpty) {
              _prepareMedia(mediaLinks, mediaLinksFrames);
            }
          });
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('Refresh'),
      ),
    );
  }

  // Dispose of the controller and cancel the timer when the widget is disposed.
  @override
  void dispose() {
    _imageTimer?.cancel();
    _frameTimer?.cancel();
    _controller?.dispose();
    _scheduleCheckTimer?.cancel();
    _payloadCheckTimer?.cancel();
    final controller = _controller;
    unawaited(() async {
      await controller?.dispose();
      await _evictActiveImage();
    }());
    unawaited(WakelockPlus.disable());
    super.dispose();
  }
}
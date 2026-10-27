import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_video_test/frame_link.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_video_test/media_cacher_stub.dart'
    if (dart.library.js_interop) 'package:flutter_video_test/media_cacher.dart';
import 'package:flutter_video_test/media_downloader.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'ticker_sources.dart';
import 'media_link.dart';
import 'api_call.dart';
import 'page_reloader_stub.dart'
    if (dart.library.js_interop) 'page_reloader.dart';

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
  List<FrameLink> _frameLinks = [];

  // Testing
  bool _initialPlaylistActive = true;

  // Media Paths
  String? _imagePath;
  String? _framePath;
  String? _videoPath;
  VideoPlayerController? _controller;

  // Timers
  Timer? _imageTimer;
  Timer? _frameTimer;
  Timer? _reloadTimer;
  ImageProvider? _activeImageProvider;

  // Errors
  String? _imageError;
  String? _videoError;
  String? _preloadError;

  // Global booleans
  bool _isChangingVideo = false;
  bool _isSkippingMedia = false;
  bool _isPreparingMedia = true;
  bool _changingPlaylist = false;
  int _currentLinkIndex = 0;
  int _currentLinkIndexFrame = 0;
  FrameLink? _frameErrorPending;
  // Check API timers
  Timer? _scheduleCheckTimer;
  Timer? _payloadCheckTimer;
  // Check API booleans
  bool _checkSchedule = false;
  bool _checkPayload = false;
  bool _isCheckingForChanges = false;
  bool _payloadCheckQueued = false;

  // Frame coordinates
  double? x1;
  double? y1;
  double? x2;
  double? y2;
  String? creationType;

  MediaLink? get _currentMedia =>
      _mediaLinks.isEmpty ? null : _mediaLinks[_currentLinkIndex];
  FrameLink? get _currentMediaFrame =>
      _frameLinks.isEmpty ? null : _frameLinks[_currentLinkIndexFrame];

  @override
  void initState() {
    super.initState();
    unawaited(WakelockPlus.enable());
    if (kIsWeb) {
      _reloadTimer = Timer(const Duration(hours: 12), reloadPage);
    }
    unawaited(_prepareMedia(startChangeChecks: true));
  }

  // Start Next Playlist
  Future<void> _startNextPlaylist() async {
    _currentLinkIndex = 0;
    _prepareMedia();
    _initialPlaylistActive = !_initialPlaylistActive;
    _changingPlaylist = false;
  }

  // Download the media given and initialize the first media.
  Future<void> _prepareMedia({bool startChangeChecks = false}) async {
    try {
      if (_mediaLinks.isEmpty) {
        _mediaLinks = await _apiCall.getMediaFromApi();
      }
      final frameLinks = await _apiCall.getFrameLinksFromApi();
      _frameLinks = kIsWeb == true
          ? List.of(frameLinks)
          : List<FrameLink>.from(
              await _mediaDownloader.downloadAllMedia(links: frameLinks),
            );

      _isPreparingMedia = false;
      if (mounted) setState(() {});
      await _initializeMedia();
      await _initializeFrame();
      if (startChangeChecks) {
        _startChangeChecks();
      }
    } catch (error) {
      if (!mounted) return;
      final cachedMedia = await _mediaDownloader.loadDownloadedMedia();
      final cachedFrames = await _mediaDownloader.loadDownloadedFrames();
      if (cachedMedia.isNotEmpty) {
        _mediaLinks = cachedMedia;
        _frameLinks = cachedFrames;
        _isPreparingMedia = false;
        _preloadError = null;
        if (mounted) setState(() {});
        await _initializeMedia();
        await _initializeFrame();
        return;
      }
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
    _scheduleCheckTimer ??= Timer.periodic(const Duration(minutes: 1), (_) {
      _checkSchedule = true;
      if (_mediaLinks.isEmpty) {
        unawaited(_checkForMediaChanges());
      }
    });
    _payloadCheckTimer ??= Timer.periodic(const Duration(minutes: 15), (_) {
      _checkPayload = true;
      if (_mediaLinks.isEmpty) {
        unawaited(_checkForMediaChanges());
      }
    });
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
      if (!payloadChanged && !schedulesChanged) {
        await _apiCall.cleanupStoredMedia();
        return;
      }

      final updatedMediaLinks = await _apiCall
          .rebuildMediaForCurrentSchedules();
      final updatedFrameLinks = await _apiCall
          .rebuildFramesForCurrentSchedules();
      _isChangingVideo = true;
      _imageTimer?.cancel();
      _imageTimer = null;
      var controller = _controller;
      controller?.removeListener(_handleVideoState);
      await controller?.dispose();
      controller = null;
      _controller = null;
      _videoError = null;
      _imagePath = null;
      _videoPath = null;
      _isChangingVideo = false;

      _currentLinkIndex = 0;
      _currentLinkIndexFrame = 0;

      _mediaLinks = updatedMediaLinks;
      _frameLinks = updatedFrameLinks;

      await _initializeMedia();
      await _initializeFrame();

      if (!mounted) return;
      setState(() {});
      try {
        await _apiCall.cleanupStoredMedia();
      } catch (error) {
        debugPrint('Error deleting stale media: $error');
      }
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
      _startImageTimer(media);
      return;
    }

    // Use file path if not on web and
    //  use url if on web.
    VideoPlayerController? controller;
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
      await controller.setVolume(0.0);
      await controller.initialize();
      if (!mounted) return;
      await controller.play();
      setState(() {});
    } catch (error) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _videoError =
            "$error\nid: ${media.link}\ntype: ${media.type}\ncontroller: ${controller?.value}";
      });
      controller = null;
    }
  }

  Future<void> _initializeFrame() async {
    final mediaFrame = _currentMediaFrame;
    _frameErrorPending = null;

    if (mediaFrame == null) {
      _framePath = null;
      _updateFrameCoordinates(null);
      return;
    }
    _updateFrameCoordinates(mediaFrame);
    _framePath = kIsWeb ? null : mediaFrame.localPath;

    if (!mounted) return;
    setState(() {});
    _startFrameTimer(mediaFrame);
    return;
  }

  void _updateFrameCoordinates(FrameLink? frame) {
    x1 = frame?.x1;
    y1 = frame?.y1;
    x2 = frame?.x2;
    y2 = frame?.y2;
    creationType = frame?.creationType;
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

  void _startFrameTimer(FrameLink mediaFrame) {
    _frameTimer?.cancel();
    _frameTimer = Timer(
      Duration(milliseconds: (mediaFrame.duration ?? 5000).round()),
      _playNextFrame,
    );
  }

  void _skipMedia() {
    if (_isSkippingMedia || (_videoError == null && _imageError == null)) {
      return;
    }

    _isSkippingMedia = true;
    scheduleMicrotask(() => unawaited(_skipFailedMedia()));
  }

  Future<void> _skipFailedMedia() async {
    try {
      if (mounted && _mediaLinks.isEmpty) {
        _imageTimer?.cancel();
        _imageTimer = null;
        final controller = _controller;
        controller?.removeListener(_handleVideoState);
        _controller = null;
        await controller?.dispose();
        await _evictActiveImage();
        if (!mounted) return;
        _currentLinkIndex = 0;
        _imageError = null;
        _videoError = null;
        _imagePath = null;
        _videoPath = null;
        _isChangingVideo = false;
        setState(() {});
        return;
      }

      while (mounted &&
          _mediaLinks.isNotEmpty &&
          (_videoError != null || _imageError != null)) {
        final failedIndex =
            _currentLinkIndex < 0 || _currentLinkIndex >= _mediaLinks.length
            ? 0
            : _currentLinkIndex;
        final failedMedia = _mediaLinks.removeAt(failedIndex);
        debugPrint('Skipping media ${failedMedia.link} after load error');

        _imageTimer?.cancel();
        _imageTimer = null;
        final controller = _controller;
        controller?.removeListener(_handleVideoState);
        _controller = null;
        await controller?.dispose();
        await _evictActiveImage();
        if (!mounted) return;

        _imageError = null;
        _videoError = null;
        _imagePath = null;
        _videoPath = null;

        if (_mediaLinks.isEmpty) {
          _currentLinkIndex = 0;
          _isChangingVideo = false;
          setState(() {});
          return;
        }

        _currentLinkIndex =
            (failedIndex - 1 + _mediaLinks.length) % _mediaLinks.length;
        await _playNextMedia();
      }
    } finally {
      _isSkippingMedia = false;
    }
  }

  // Skip current media because of error
  // // Remove media from list
  void _skipFrame() {
    if (_frameLinks.isEmpty) return;
    _frameTimer?.cancel();
    _frameTimer = null;
    _frameLinks.removeAt(_currentLinkIndexFrame);
    if (_frameLinks.isEmpty) {
      _currentLinkIndexFrame = 0;
      _framePath = null;
      _updateFrameCoordinates(null);
      if (mounted) setState(() {});
      return;
    }
    _currentLinkIndexFrame =
        (_currentLinkIndexFrame - 1 + _frameLinks.length) % _frameLinks.length;
    unawaited(_playNextFrame());
  }

  void _handleFrameError(FrameLink frame, Object error) {
    if (!identical(_currentMediaFrame, frame) ||
        identical(_frameErrorPending, frame)) {
      return;
    }

    _frameErrorPending = frame;
    debugPrint('Skipping frame ${frame.link} after load error: $error');
    scheduleMicrotask(() {
      if (mounted && identical(_currentMediaFrame, frame)) {
        _skipFrame();
      }
    });
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
      await controllerToInitialize.setVolume(0.0);
      await controllerToInitialize.initialize();
      await controllerToInitialize.play();
    } catch (error) {
      await nextController?.dispose();
      nextController = null;
      if (!mounted) return;
      setState(() {
        _videoError = '$error\nid: ${media.link}\ntype: ${media.type}';
        _isChangingVideo = false;
      });
      return;
    }

    VideoPlayerController? readyController = nextController;
    if (!mounted) {
      await readyController.dispose();
      readyController = null;
      return;
    }

    var controller = _controller;
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
    controller = null;
    await _evictActiveImage();
    await _checkPendingMediaChanges();
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

    var controller = _controller;
    controller?.removeListener(_handleVideoState);
    await controller?.dispose();
    controller = null;
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

    await _checkPendingMediaChanges();
    if (_changingPlaylist) {
      unawaited(_startNextPlaylist());
      return;
    }
    if (!identical(_currentMedia, media)) return;
    setState(() {});

    if (imageError == null) {
      _startImageTimer(media);
    }
  }

  Future<void> _checkPendingMediaChanges() async {
    if (_checkSchedule) {
      _checkSchedule = false;
      await _checkForMediaChanges();
    }
    if (_checkPayload) {
      _checkPayload = false;
      await _checkForMediaChanges(checkPayload: true);
    }
  }

  Future<void> _playNextFrame() async {
    if (_frameLinks.isEmpty) return;

    _frameTimer?.cancel();
    _frameTimer = null;
    _currentLinkIndexFrame = (_currentLinkIndexFrame + 1) % _frameLinks.length;
    _framePath = null;

    await _initializeFrame();
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
                          _buildMediaFrame(),
                          Positioned(
                            left: x1! * scale,
                            top: y1! * scale,
                            width: (x2! - x1!) * scale,
                            height: (y2! - y1!) * scale,
                            child: ClipRect(child: _buildMedia((y2! - y1!) * scale)),
                          ),
                          if (creationType == 'bcm') _buildMediaFrame(),
                        ],
                      ),
                    ),
                  )
                else
                  Center(child: _buildMedia(canvasHeight * scale)),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: _buildNextPlaylistButton(),
                ),
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
  Widget _buildMedia(double mediaHeight) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        _buildMediaContent(),
        // Positioned(
        //   left: 0,
        //   right: 0,
        //   bottom: 0,
        //   child: _buildTickers(mediaHeight, false),
        // ),
        // Positioned(
        //   left: 0,
        //   right: 0,
        //   top: 0,
        //   child: _buildTickers(mediaHeight, true),
        // ),
      ],
    );
  }

  Widget _buildMediaContent() {
    if (_isPreparingMedia) {
      return const CircularProgressIndicator();
    }
    // Show any error if there is one
    if (_preloadError != null) {
      final media = _currentMedia;
      final localPath = media?.localPath;
      if (!kIsWeb && media != null && localPath != null && File(localPath).existsSync()) {
        return Image.file(
          File(localPath),
          fit: BoxFit.contain,
          height: double.infinity,
          width: double.infinity,
        );
      }
      return Image.asset(
        'assets/placeholder-green.png',
        fit: BoxFit.contain,
        height: double.infinity,
        width: double.infinity,
      );
    }

    // If there's a video error, skip media and display the error temporarily.
    if (_videoError != null) {
      _skipMedia();
      return
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load video:\n$_videoError\n$_videoPath',
            textAlign: TextAlign.center,
          ),
        );
    }

    // If there's an image error, skip media and display the error temporarily.
    if (_imageError != null) {
      _skipMedia();
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Could not load image:\n$_imageError',
          textAlign: TextAlign.center,
        ),
      );
    }

    // Placeholder if no media available
    if (_mediaLinks.isEmpty) {
      return Image.asset(
        'assets/placeholder-green.png',
        fit: BoxFit.contain,
        height: double.infinity,
        width: double.infinity,
      );
    }

    final media = _currentMedia!;

    // Return Image on web
    // Return Image File on web
    if (media.type == 'image') {
      if (kIsWeb) {
        return _imagePath == null
            ? const CircularProgressIndicator()
            : Image(
                image: _activeImageProvider!,
                fit: BoxFit.contain,
                height: double.infinity,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  _handleMediaImageError(media, error);
                  return const SizedBox.shrink();
                },
              );
      }
      return _imagePath == null
          ? const CircularProgressIndicator()
          : Image.file(
              File(_imagePath!),
              fit: BoxFit.contain,
              height: double.infinity,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                _handleMediaImageError(media, error);
                return const SizedBox.shrink();
              },
            );
    }

    // Return Video if its not an image
    return _controller?.value.isInitialized ?? false
        ? AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          )
        : const CircularProgressIndicator();
  }

  void _handleMediaImageError(MediaLink media, Object error) {
    if (!identical(_currentMedia, media) || _imageError != null) return;
    scheduleMicrotask(() {
      if (!mounted || !identical(_currentMedia, media) || _imageError != null) {
        return;
      }
      setState(() {
        _imageError = error.toString();
      });
    });
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

    if (_frameLinks.isEmpty) {
      return Image.asset(
        'assets/placeholder.png',
        fit: BoxFit.contain,
        height: double.infinity,
        width: double.infinity,
      );
    }

    final media = _currentMediaFrame!;

    if (kIsWeb) {
      return Image.network(
        media.link,
        fit: BoxFit.contain,
        height: double.infinity,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          _handleFrameError(media, error);
          return const SizedBox.shrink();
        },
      );
    }
    return _framePath == null
        ? const CircularProgressIndicator()
        : Image.file(
            File(_framePath!),
            fit: BoxFit.contain,
            height: double.infinity,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              _handleFrameError(media, error);
              return const SizedBox.shrink();
            },
          );
  }

  Widget _buildTickers(double mediaHeight, bool backwards) {
    String allTickers = '';
    for (String ticker in tickers) {
      allTickers += ticker;
      allTickers += ' • ';
    }

    final percent = 0.1;
    final fontSize = mediaHeight * percent;
    const textColor = Colors.white;
    const borderColor = Colors.black;
    final borderWidth = fontSize * 0.1;
    final tickerSpeed = fontSize;
    final textDirection = backwards ? TextDirection.rtl : TextDirection.ltr;

    return Stack(
      children: <Widget>[
        TextScroll(
          allTickers,
          style: TextStyle(
            fontSize: fontSize,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = borderWidth
              ..color = borderColor,
          ),
          velocity: Velocity(pixelsPerSecond: Offset(tickerSpeed, 0)),
          textDirection: textDirection,
        ),
        TextScroll(
          allTickers,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
          ),
          velocity: Velocity(pixelsPerSecond: Offset(tickerSpeed, 0)),
          textDirection: textDirection,
        ),
      ],
    );
  }

  // Button to re-ask API data for testing
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
          if (_isPreparingMedia) return;

          if (_mediaLinks.isEmpty) {
            setState(() {
              _preloadError = null;
            });
            unawaited(_checkForMediaChanges(checkPayload: true));
          } else {
            setState(() {
              _checkPayload = true;
            });
          }
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('Refresh A'),
      ),
    );
  }

  // Dispose of the controller and cancel the timer when the widget is disposed.
  @override
  void dispose() {
    _imageTimer?.cancel();
    _frameTimer?.cancel();
    _reloadTimer?.cancel();
    _controller?.dispose();
    _scheduleCheckTimer?.cancel();
    _payloadCheckTimer?.cancel();
    var controller = _controller;
    unawaited(() async {
      await controller?.dispose();
      controller = null;
      await _evictActiveImage();
    }());
    unawaited(WakelockPlus.disable());
    super.dispose();
  }
}

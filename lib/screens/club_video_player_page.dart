import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import 'club_gallery.dart'; // for ClubVideo model

class ClubVideoPlayerPage extends StatefulWidget {
  final ClubVideo video;

  const ClubVideoPlayerPage({super.key, required this.video});

  @override
  State<ClubVideoPlayerPage> createState() => _ClubVideoPlayerPageState();
}

class _ClubVideoPlayerPageState extends State<ClubVideoPlayerPage>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _playerCtrl;
  bool _isInitialized = false;
  bool _isError = false;
  bool _showControls = true;
  bool _isFullscreen = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final url = widget.video.videoUrl;
    if (url == null || url.isEmpty) {
      setState(() => _isError = true);
      return;
    }

    try {
      _playerCtrl = VideoPlayerController.networkUrl(Uri.parse(url));
      await _playerCtrl!.initialize();
      _playerCtrl!.addListener(() {
        if (mounted) setState(() {});
      });
      setState(() => _isInitialized = true);
      // Auto-play on open
      _playerCtrl!.play();
      // Hide controls after 3 s
      Future.delayed(const Duration(seconds: 3), _hideControls);
    } catch (e) {
      debugPrint('Video init error: $e');
      setState(() => _isError = true);
    }
  }

  void _hideControls() {
    if (mounted && (_playerCtrl?.value.isPlaying ?? false)) {
      setState(() => _showControls = false);
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls && (_playerCtrl?.value.isPlaying ?? false)) {
      Future.delayed(const Duration(seconds: 3), _hideControls);
    }
  }

  void _togglePlay() {
    if (_playerCtrl == null) return;
    setState(() {
      _playerCtrl!.value.isPlaying
          ? _playerCtrl!.pause()
          : _playerCtrl!.play();
    });
    if (_playerCtrl!.value.isPlaying) {
      Future.delayed(const Duration(seconds: 3), _hideControls);
    }
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$m:$s';
  }

  @override
  void dispose() {
    _playerCtrl?.dispose();
    _fadeCtrl.dispose();
    // Restore orientation and system UI
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: _isFullscreen
              ? _buildFullscreenPlayer()
              : _buildPortraitLayout(),
        ),
      ),
    );
  }

  // ── Portrait layout: video top, info below ────────────────────────
  Widget _buildPortraitLayout() {
    return SafeArea(
      child: Column(
        children: [
          // ── Video area ────────────────────────────────────────
          _buildVideoArea(isFullscreen: false),

          // ── Info panel ────────────────────────────────────────
          Expanded(
            child: Container(
              color: Colors.black,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button + title row
                    Row(children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.video.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // Meta chips
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _infoChip(Icons.book_rounded,
                          widget.video.topic, const Color(0xff4A90E2)),
                      _infoChip(Icons.bar_chart_rounded,
                          widget.video.level, _levelColor(widget.video.level)),
                      if (widget.video.academicYear != null)
                        _infoChip(Icons.calendar_today_rounded,
                            widget.video.academicYear!, Colors.grey),
                      if (widget.video.uploadDate.isNotEmpty)
                        _infoChip(Icons.upload_rounded,
                            widget.video.uploadDate, Colors.grey.shade600),
                    ]),
                    const SizedBox(height: 20),

                    // Divider
                    Container(height: 1,
                        color: Colors.white.withOpacity(0.08)),
                    const SizedBox(height: 16),

                    // Placeholder for description / related
                    Text('About this video',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Text(
                      'Topic: ${widget.video.topic}  ·  Level: ${widget.video.level}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                          height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Fullscreen layout ─────────────────────────────────────────────
  Widget _buildFullscreenPlayer() {
    return _buildVideoArea(isFullscreen: true);
  }

  // ── Shared video area (portrait top / fullscreen) ─────────────────
  Widget _buildVideoArea({required bool isFullscreen}) {
    final videoHeight = isFullscreen
        ? MediaQuery.of(context).size.height
        : MediaQuery.of(context).size.width * 9 / 16;

    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        height: videoHeight,
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Video / thumbnail / loading ────────────────────
            if (_isInitialized && _playerCtrl != null)
              AspectRatio(
                aspectRatio: _playerCtrl!.value.aspectRatio,
                child: VideoPlayer(_playerCtrl!),
              )
            else if (_isError)
              _buildErrorState()
            else
              _buildLoadingState(),

            // ── Controls overlay ───────────────────────────────
            if (_isInitialized && !_isError)
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: _buildControls(isFullscreen: isFullscreen),
              ),
          ],
        ),
      ),
    );
  }

  // ── Controls overlay ──────────────────────────────────────────────
  Widget _buildControls({required bool isFullscreen}) {
    final ctrl    = _playerCtrl!;
    final pos     = ctrl.value.position;
    final dur     = ctrl.value.duration;
    final isPlaying = ctrl.value.isPlaying;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.5),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Column(
        children: [
          // ── Top bar ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(children: [
              if (!isFullscreen)
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 18),
                ),
              const Spacer(),
              GestureDetector(
                onTap: _toggleFullscreen,
                child: Icon(
                  isFullscreen
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                  color: Colors.white, size: 24,
                ),
              ),
            ]),
          ),

          const Spacer(),

          // ── Centre play/pause ─────────────────────────────
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                border: Border.all(
                    color: Colors.white.withOpacity(0.6), width: 1.5),
              ),
              child: Icon(
                isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white, size: 34,
              ),
            ),
          ),

          const Spacer(),

          // ── Bottom: progress + time ────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Seek bar
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14),
                    activeTrackColor: const Color(0xff4A90E2),
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    overlayColor: Colors.white12,
                  ),
                  child: Slider(
                    value: dur.inMilliseconds > 0
                        ? pos.inMilliseconds
                        .toDouble()
                        .clamp(0, dur.inMilliseconds.toDouble())
                        : 0,
                    min: 0,
                    max: dur.inMilliseconds.toDouble().clamp(1, double.infinity),
                    onChanged: (v) {
                      ctrl.seekTo(
                          Duration(milliseconds: v.toInt()));
                    },
                  ),
                ),
                // Time row
                Row(children: [
                  Text(_formatDuration(pos),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11)),
                  const Spacer(),
                  Text(_formatDuration(dur),
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Loading state ─────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Thumbnail as background while loading
        if (widget.video.thumbnailUrl != null &&
            widget.video.thumbnailUrl!.isNotEmpty)
          Image.network(
            widget.video.thumbnailUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.black),
          ),
        Container(color: Colors.black54),
        const Center(
          child: CircularProgressIndicator(
              color: Color(0xff4A90E2), strokeWidth: 2.5),
        ),
      ],
    );
  }

  // ── Error state ───────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Container(
      color: const Color(0xff111111),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off_rounded,
              color: Colors.grey.shade600, size: 48),
          const SizedBox(height: 12),
          Text('Unable to play video',
              style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('The video URL may be unavailable.',
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () { setState(() => _isError = false); _initPlayer(); },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xff4A90E2).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xff4A90E2).withOpacity(0.4)),
              ),
              child: const Text('Retry',
                  style: TextStyle(
                      color: Color(0xff4A90E2),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────
  Color _levelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':     return const Color(0xFF50C878);
      case 'intermediate': return const Color(0xFFFFD700);
      case 'advanced':     return const Color(0xFFFF7F50);
      default:             return Colors.grey;
    }
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color)),
      ]),
    );
  }
}
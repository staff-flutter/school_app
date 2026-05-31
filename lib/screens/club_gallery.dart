import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../services/user_session.dart';
import 'club_video_player_page.dart';

// ── Model ─────────────────────────────────────────────────────────
class ClubVideo {
  final String id;
  final String title;
  final String topic;
  final String level;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? academicYear;
  final String uploadDate;

  const ClubVideo({
    required this.id,
    required this.title,
    required this.topic,
    required this.level,
    this.videoUrl,
    this.thumbnailUrl,
    this.academicYear,
    required this.uploadDate,
  });

  factory ClubVideo.fromJson(Map<String, dynamic> json) {
    return ClubVideo(
      id:           json['_id']?.toString() ?? '',
      title:        json['title']?.toString() ?? 'Untitled',
      topic:        json['topic']?.toString() ?? 'General',
      level:        json['level']?.toString() ?? 'Beginner',
      videoUrl:     json['video']?['url']?.toString(),
      thumbnailUrl: json['thumbnail']?['url']?.toString(),
      academicYear: json['academicYear']?.toString(),
      uploadDate:   json['createdAt']?.toString().split('T')[0] ?? '',
    );
  }
}

// ── Page ──────────────────────────────────────────────────────────
class SchoolGalleryPage extends StatefulWidget {
  final String clubName;
  final String description;
  final String clubId;      // ← pass this from ClubAndActivitiesPage

  const SchoolGalleryPage({
    super.key,
    required this.clubName,
    required this.description,
    required this.clubId,
  });

  static const Color _primaryBlue = Color(0xff4A90E2);
  static const Color _lightBlue   = Color(0xff6FD3F7);

  @override
  State<SchoolGalleryPage> createState() => _SchoolGalleryPageState();
}

class _SchoolGalleryPageState extends State<SchoolGalleryPage> {
  List<ClubVideo> _videos = [];
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    setState(() { _isLoading = true; _errorMsg = null; });

    try {
      final session  = Get.find<UserSession>();
      final token    = session.token ?? '';
      final schoolId = session.schoolId ?? '';

      final uri = Uri.parse('${ApiConstants.baseUrl}/api/club/video/getall')
          .replace(queryParameters: {
        'schoolId': schoolId,
        'clubId':   widget.clubId,
        'page':     '1',
        'limit':    '50',
      });

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept':        'application/json',
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> list = decoded['data'] ?? [];
        setState(() {
          _videos   = list.map((j) => ClubVideo.fromJson(j)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMsg  = 'Failed to load videos (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg  = 'Connection error — tap to retry';
        _isLoading = false;
      });
      debugPrint('ClubVideos fetch error: $e');
    }
  }

  // Alternate tile heights for a staggered feel
  int _heightFor(int index) => (index % 3 == 0) ? 2 : 1;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness:     Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          top: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ───────────────────────────────────────────
              SliverToBoxAdapter(child: _buildHeader()),

              // ── Content ──────────────────────────────────────────
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(
                      color: SchoolGalleryPage._primaryBlue)),
                )
              else if (_errorMsg != null)
                SliverFillRemaining(child: _buildError())
              else if (_videos.isEmpty)
                  SliverFillRemaining(child: _buildEmpty())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                    sliver: SliverToBoxAdapter(
                      child: StaggeredGrid.count(
                        crossAxisCount:  2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: List.generate(
                          _videos.length,
                              (i) => _buildVideoTile(_videos[i], _heightFor(i)),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SchoolGalleryPage._primaryBlue,
            SchoolGalleryPage._lightBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back + video count row
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 18),
                ),
              ),
              const Spacer(),
              if (!_isLoading && _videos.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_circle_outline_rounded,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        '${_videos.length} video${_videos.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ]),
            const SizedBox(height: 22),
            Text(
              widget.clubName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            if (widget.description.isNotEmpty)
              Text(
                widget.description,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 18),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Video tile ───────────────────────────────────────────────────
  Widget _buildVideoTile(ClubVideo video, int heightFactor) {
    return StaggeredGridTile.count(
      crossAxisCellCount: 1,
      mainAxisCellCount:  heightFactor,
      child: Hero(
        tag: 'video_${video.id}',
        child: GestureDetector(
          onTap: () => Get.to(
                () => ClubVideoPlayerPage(video: video),
            transition: Transition.fadeIn,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xffF1F4F9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Thumbnail ──────────────────────────────────────
                if (video.thumbnailUrl != null &&
                    video.thumbnailUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: video.thumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: const Color(0xffEEF3FB),
                      child: const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: SchoolGalleryPage._primaryBlue),
                      ),
                    ),
                    errorWidget: (_, __, ___) =>
                        _buildThumbnailFallback(video),
                  )
                else
                  _buildThumbnailFallback(video),

                // ── Gradient overlay ───────────────────────────────
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // ── Play button ────────────────────────────────────
                Center(
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.9),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8)
                      ],
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: SchoolGalleryPage._primaryBlue, size: 26),
                  ),
                ),

                // ── Title + meta at bottom ─────────────────────────
                Positioned(
                  left: 10, right: 10, bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        video.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black54)
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(children: [
                        _metaChip(video.topic),
                        const SizedBox(width: 4),
                        _levelChip(video.level),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Fallback when no thumbnail
  Widget _buildThumbnailFallback(ClubVideo video) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff4A90E2), Color(0xff6FD3F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.play_circle_fill_rounded,
            color: Colors.white.withOpacity(0.6), size: 48),
      ),
    );
  }

  Widget _metaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _levelChip(String level) {
    final colors = {
      'beginner':     const Color(0xFF50C878),
      'intermediate': const Color(0xFFFFD700),
      'advanced':     const Color(0xFFFF7F50),
    };
    final color =
        colors[level.toLowerCase()] ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5),
      ),
      child: Text(level,
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700)),
    );
  }

  // ── Empty / Error states ──────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.video_library_outlined,
            size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('No videos yet',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        Text('Videos uploaded to this club\nwill appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 14),
        Text(_errorMsg ?? 'Something went wrong',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _fetchVideos,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(
            backgroundColor: SchoolGalleryPage._primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ]),
    );
  }
}
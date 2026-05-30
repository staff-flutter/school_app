import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:school_app/services/user_session.dart';
import 'package:video_player/video_player.dart';

import '../controllers/my_children_controller.dart';
import '../constants/api_constants.dart';
import '../core/theme/app_theme.dart';
import 'club_gallery.dart';


// ─── New standalone "Campus Management" page ─────────────────────────────────
// This is separate from the existing Clubs & Activities page.

class CampusManagementPage extends StatefulWidget {
  const CampusManagementPage({super.key});

  @override
  State<CampusManagementPage> createState() => _CampusManagementPageState();
}

class _CampusManagementPageState extends State<CampusManagementPage> {
  late final MyChildrenController controller;

  List<_ClubItem> apiClubs = [];
  bool isLoading = true;
  final session = Get.find<UserSession>();

  late VideoPlayerController _videoController;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    // Safe find — MyChildrenController may or may not be registered
    if (Get.isRegistered<MyChildrenController>()) {
      controller = Get.find<MyChildrenController>();
    } else {
      controller = Get.put(MyChildrenController());
    }
    _fetchClubs();

    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(
        'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      ),
    );
    _initializeVideoPlayerFuture = _videoController.initialize();
    _videoController.setLooping(true);
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _fetchClubs() async {
    final String baseUrl = ApiConstants.baseUrl;
    final String? token = session.token;
    final String? schoolId = session.schoolId ?? '';

    final uri = Uri.parse('$baseUrl/api/club/getall').replace(
      queryParameters: {'schoolId': schoolId, 'page': '1', 'limit': '10'},
    );

    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> list = decoded['data'] ?? [];
        setState(() {
          apiClubs = list.map((d) => _ClubItem.fromJson(d)).toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFEEF3FB),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildClubGrid(),
                  const SizedBox(height: 20),
                  _buildCampusStars(),
                  const SizedBox(height: 20),
                  _buildPostCard(),
                  SizedBox(height: AppTheme.navBarPadding(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        const CircleAvatar(
          backgroundColor: Color(0xFFE3ECFF),
          child: Icon(Icons.school, color: Color(0xFF4A6CF7)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            session.schoolName ?? '',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.search),
        ),
      ],
    );
  }

  // ─── Club Cards ──────────────────────────────────────────────────────────────

  Widget _buildClubGrid() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (apiClubs.isEmpty) {
      return const Center(child: Text('No clubs found'));
    }

    return SizedBox(
      height: 200,
      child: GridView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: apiClubs.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
          childAspectRatio: 0.6,
        ),
        itemBuilder: (context, index) {
          final club = apiClubs[index];
          final clubId=apiClubs[index].id;
          return _BounceCard(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SchoolGalleryPage(
                    clubName: club.name,
                    description: club.description, clubId: clubId,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A90E2), Color(0xFF6FD3F7)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A90E2).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    club.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Campus Stars ────────────────────────────────────────────────────────────

  Widget _buildCampusStars() {
    final name = controller.selectedChild['studentName'] ?? 'Unknown';
    final image = controller.selectedChild['studentImage']?['url'] ?? '';

    return Column(
      children: [
        Row(
          children: const [
            Text(
              'The campus star',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Spacer(),
            Text('more', style: TextStyle(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [_StarCard(name, image)],
          ),
        ),
      ],
    );
  }

  // ─── Post / Video Card ───────────────────────────────────────────────────────

  Widget _buildPostCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              CircleAvatar(
                backgroundImage: NetworkImage(
                    'https://randomuser.me/api/portraits/women/44.jpg'),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cynthia Hall',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('5 minutes ago',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              Spacer(),
              Icon(Icons.more_vert),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'The 2019 Christmas and New Year party has started. New Year\'s eve party, wonderful.',
          ),
          const SizedBox(height: 12),
          FutureBuilder(
            future: _initializeVideoPlayerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(
                        'https://images.unsplash.com/photo-1507874457470-272b3c8d8ee2',
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        height: 55,
                        width: 55,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.5),
                        ),
                        child: const Icon(Icons.play_arrow,
                            color: Colors.white, size: 30),
                      ),
                    ],
                  ),
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ],
      ),
    );
  }
}

// ─── Model ────────────────────────────────────────────────────────────────────

class _ClubItem {
  final String id;
  final String name;
  final String description;
  final String? thumbnail;

  const _ClubItem({
    required this.id,
    required this.name,
    required this.description,
    this.thumbnail,
  });

  factory _ClubItem.fromJson(Map<String, dynamic> json) => _ClubItem(
        id: json['_id'] ?? '',
        name: json['name'] ?? 'Unknown Club',
        description: json['description'] ?? '',
        thumbnail: json['thumbnail'],
      );
}

// ─── Star Card ────────────────────────────────────────────────────────────────

class _StarCard extends StatelessWidget {
  final String name;
  final String imageUrl;

  const _StarCard(this.name, this.imageUrl);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(imageUrl),
          ),
          const SizedBox(height: 8),
          Text(name,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          const Text('Student leader',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ─── Bounce Card ─────────────────────────────────────────────────────────────

class _BounceCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _BounceCard({required this.child, required this.onTap});

  @override
  State<_BounceCard> createState() => _BounceCardState();
}

class _BounceCardState extends State<_BounceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _anim.forward(),
      onTapUp: (_) async {
        await _anim.reverse();
        await Future.delayed(const Duration(milliseconds: 50));
        widget.onTap();
      },
      onTapCancel: () => _anim.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SchoolGalleryPage extends StatefulWidget {
  final String clubName;
  final String description;

  const SchoolGalleryPage({
    super.key,
    required this.clubName ,
    required this.description ,
  });

  // Professional Color Palette
  static const Color _primaryBlue = Color(0xff4A90E2);
  static const Color _lightBlue = Color(0xff6FD3F7);

  @override
  State<SchoolGalleryPage> createState() => _SchoolGalleryPageState();
}

class _SchoolGalleryPageState extends State<SchoolGalleryPage> {
  final List<Map<String, dynamic>> galleryItems = [
    {'id': '1', 'url': 'https://images.pexels.com/photos/256417/pexels-photo-256417.jpeg'},
    {'id': '2', 'url': 'https://images.pexels.com/photos/159823/kids-girl-pencil-drawing-159823.jpeg'},
    {'id': '3', 'url': 'https://images.pexels.com/photos/301920/pexels-photo-301920.jpeg'},
    {'id': '4', 'url': 'https://images.pexels.com/photos/207662/pexels-photo-207662.jpeg'},
    {'id': '5', 'url': 'https://images.pexels.com/photos/1438072/pexels-photo-1438072.jpeg'},
    {'id': '6', 'url': 'https://images.pexels.com/photos/256417/pexels-photo-256417.jpeg'},
    {'id': '7', 'url': 'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f'},
    {'id': '8', 'url': 'https://images.pexels.com/photos/5212345/pexels-photo-5212345.jpeg'},
    {'id': '9', 'url': 'https://images.pexels.com/photos/3184418/pexels-photo-3184418.jpeg'},
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    //   statusBarColor: Colors.black, // transparent so AppBar image shows through
    //   statusBarIconBrightness: Brightness.light, // dark icons (visible on light bg)
    //   // or Brightness.light if your header image is dark
    // ));
  }
  @override
  Widget build(BuildContext context) {
    // Syncs the status bar color with the blue header
    // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    //   statusBarColor: Colors.black,
    //   statusBarIconBrightness: Brightness.light,
    // ));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light, // white icons
        statusBarBrightness: Brightness.dark,       // iOS
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── UNIFIED BLUE HEADER ──
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [SchoolGalleryPage._primaryBlue, SchoolGalleryPage._lightBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 35),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back Button
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(height: 25),
                        // Title
                        Text(
                          "${widget.clubName} Gallery",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Description
                        Text(
                          widget.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Professional Divider
                        Container(
                          width: 45,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── GALLERY GRID ON WHITE BACKGROUND ──
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                sliver: SliverToBoxAdapter(
                  child: StaggeredGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      // _buildTile(id: '1', height: 2, url: 'https://images.pexels.com/photos/256417/pexels-photo-256417.jpeg'),
                      // _buildTile(id: '2', height: 1, url: 'https://images.pexels.com/photos/159823/kids-girl-pencil-drawing-159823.jpeg'),
                      // _buildTile(id: '3', height: 1, url: 'https://images.pexels.com/photos/301920/pexels-photo-301920.jpeg'),
                      // _buildTile(id: '4', height: 2, url: 'https://images.pexels.com/photos/207662/pexels-photo-207662.jpeg'),
                      // _buildTile(id: '5', height: 1, url: 'https://images.pexels.com/photos/1438072/pexels-photo-1438072.jpeg'),
                      // _buildTile(id: '6', height: 1, url: 'https://images.pexels.com/photos/256417/pexels-photo-256417.jpeg'),
                      // _buildTile(id: '7', height: 2, url: 'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f'),
                      // _buildTile(id: '8', height: 1, url: 'https://images.pexels.com/photos/5212345/pexels-photo-5212345.jpeg'),
                      // _buildTile(id: '9', height: 1, url: 'https://images.pexels.com/photos/3184418/pexels-photo-3184418.jpeg'),

                      _buildTile(id: '1', height: 2, url: 'IMAGE'),
                      _buildTile(id: '2', height: 1, url: 'IMAGE'),
                      _buildTile(id: '3', height: 1, url: 'IMAGE'),
                      _buildTile(id: '4', height: 2, url: 'IMAGE'),
                      _buildTile(id: '5', height: 1, url: 'IMAGE'),
                      _buildTile(id: '6', height: 1, url: 'IMAGE'),
                      _buildTile(id: '7', height: 2, url: 'IMAGE'),
                      _buildTile(id: '8', height: 1, url: 'IMAGE'),
                      _buildTile(id: '9', height: 1, url: 'IMAGE'),


                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── REUSABLE TILE WIDGET ──
  Widget _buildTile({required String id, required int height, required String url}) {
    return StaggeredGridTile.count(
      crossAxisCellCount: 1,
      mainAxisCellCount: height,
      child: Hero(
        tag: id,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child:
          // CachedNetworkImage(
          //   imageUrl: url,
          //   fit: BoxFit.cover,
          //   placeholder: (context, url) => Container(
          //     color: const Color(0xffF1F4F9),
          //     child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          //   ),
          //   errorWidget: (context, url, error) => const Icon(Icons.error),
          // ),
          Container(
            child: Center(
              child: Text(url),
            ),
          )
        ),
      ),
    );
  }
}
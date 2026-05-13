import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

import '../controllers/auth_controller.dart';
import '../controllers/my_children_controller.dart';
import '../constants/api_constants.dart';
import '../core/theme/app_theme.dart';
import '../services/user_session.dart';
import 'club_gallery.dart';


class ClubAndActivitiesPage extends StatefulWidget {
  const ClubAndActivitiesPage({super.key});

  @override
  State<ClubAndActivitiesPage> createState() => _ClubPageState();
}

class _ClubPageState extends State<ClubAndActivitiesPage> {
 // final controller = Get.find<MyChildrenController>();
  MyChildrenController? get _childrenController =>
      Get.isRegistered<MyChildrenController>()
          ? Get.find<MyChildrenController>()
          : null;

  List<ClubsAndActivitiesStrings> apiClubs = [];
  bool isLoading = true;
  final session = Get.find<UserSession>();

  late VideoPlayerController _controller ;
  late Future<void> _initializeVideoPlayerFuture;


  final List <String> clubNames =['Music','Dance','Science & Technology','Theatre','Arts & Culture','Dance','Science & Technology','Theatre''Music','Dance','Science & Technology','Theatre'];


// ------------------------------------THE  CLUBS&ACTIVITIES FUNCTION -----------------------------


  Future<void> fetchClubsAndActivities() async {
    String baseUrl = ApiConstants.baseUrl;

    final String? token = session.token;
    String? schoolId = session.schoolId ?? '';
    if (schoolId == null || schoolId.isEmpty) {
      try {
        schoolId = Get.find<AuthController>().user.value?.schoolId;
      } catch (_) {}
    }

    if (schoolId == null || schoolId.isEmpty) {
      setState(() => isLoading = false);
      debugPrint('⚠️ No schoolId available for clubs fetch');
      return;
    }

    final queryParameters = {
      "schoolId": schoolId,
      "page": "1",
      "limit": "10"
    };
    print('schoolId:$schoolId');

    final uri = Uri.parse('$baseUrl/api/club/getall').replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        final List<dynamic> list = decodedData['data'] ?? [];

        setState(() {
          apiClubs = list.map((data) => ClubsAndActivitiesStrings.fromJson(data)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching clubs: $e");
    }
  }


  @override
  void initState() {
    super.initState();
    fetchClubsAndActivities();
    // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    //   statusBarColor: Colors.black, // transparent so AppBar image shows through
    //   statusBarIconBrightness: Brightness.light, // dark icons (visible on light bg)
    //   // or Brightness.light if your header image is dark
    // ));

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(
        'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      ),
    );

    _initializeVideoPlayerFuture = _controller.initialize();

    _controller.setLooping(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  // --------------------------------------------- BUILD METHOD ----------------------------------------


  @override
  Widget build(BuildContext context) {

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFEEF3FB),
        statusBarIconBrightness: Brightness.dark, // white icons
        statusBarBrightness: Brightness.dark,       // iOS
      ),
      child: Scaffold(
        backgroundColor: const Color(0xffF5F6FA),
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _header(),
                  const SizedBox(height: 20),
                  _gridCards(),
                  const SizedBox(height: 20),
                  _campusStars(),
                  const SizedBox(height: 20),
                  _postCard(),
                  SizedBox(height: AppTheme.navBarPadding(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  // -------------------------- HEADER FOR UNIVERSITY OR SCHOOL NAME --------------------------------------


  Widget _header() {
    return Row(
      children: [
        const CircleAvatar(
          backgroundColor: Color(0xffE3ECFF),
          child: Icon(Icons.school, color: Color(0xff4A6CF7)),
        ),
        const SizedBox(width: 10),
        Text(
          '${session.schoolName}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,color: Colors.black),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.search),
        )
      ],
    );
  }


  // -------------------------------------- CLUB CARDS ---------------------------------------------


  Widget _gridCards() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (apiClubs.isEmpty) return const Center(child: Text("No clubs found"));

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
        itemBuilder: (BuildContext context, int index) {
          final club = apiClubs[index];
          return _BounceCard(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SchoolGalleryPage(clubName: club.name,description:club.description, )),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xff4A90E2), Color(0xff6FD3F7)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff4A90E2).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    club.name,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
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


  //------------------------------------------ CAMPUS STARS ----------------------------------------


  Widget _campusStars() {
    // String campusStarName= controller.selectedChild['studentName']?? 'Unknown';
   // String campusStarImage= controller.selectedChild['studentImage']?['url']?? '';

     final child = _childrenController?.selectedChild;
     String campusStarName = child?['studentName'] ?? 'Unknown';
     String campusStarImage = child?['studentImage']?['url'] ?? '';
     return Column(
      children: [
        Row(
          children: const [
            Text("The campus star",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Spacer(),
            Text("more", style: TextStyle(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              UserCard(campusStarName,campusStarImage),

            ],
          ),
        ),
      ],
    );
  }


  // ----------------------------------------- VIDEO PLAYER CARD ----------------------------------------


  Widget _postCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              CircleAvatar(
                backgroundImage: NetworkImage(
                    "https://randomuser.me/api/portraits/women/44.jpg"),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Cynthia Hall",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text("5 minutes ago",
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              Spacer(),
              Icon(Icons.more_vert)
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "The 2019 Christmas and New Year party has started. New Year's eve party, wonderful.",
          ),
          const SizedBox(height: 12),

          FutureBuilder(
            future: _initializeVideoPlayerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Stack(
                  alignment: Alignment.center, // Center the children
                  children: [
                    // ClipRRect(
                    //   borderRadius: BorderRadius.circular(20.0),
                    //   child: AspectRatio(
                    //     aspectRatio: _controller.value.aspectRatio,
                    //     //  VideoPlayer widget to display the video.
                    //     child: Container(
                    //         decoration: BoxDecoration(
                    //             color: Colors.black,
                    //             borderRadius: BorderRadius.circular(20)
                    //         ),
                    //         child: VideoPlayer(_controller)),
                    //   ),
                    // ),
                    // // Center the button overlay
                    // IconButton(
                    //   icon: Icon(
                    //     _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    //     size: 40.0,
                    //     color: Colors.white,
                    //   ),
                    //   onPressed: () {
                    //     setState(() {
                    //       _controller.value.isPlaying ? _controller.pause() : _controller.play();
                    //     });
                    //   },
                    // ),
                    //  Image with Play Button
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(
                            "https://images.unsplash.com/photo-1507874457470-272b3c8d8ee2",
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
                          )
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                // If the VideoPlayerController is still initializing, show a
                // loading spinner.
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ],
      ),
    );
  }
}


// ---------------------------------------- MODEL CLASS TO GET THE DATA FOR UI NEED not in use ------------------------------------


class ClubsAndActivitiesStrings1{
  final String universityName;
  final String clubName;
  final String studentName;
  final String videoURL;
  final String description;

   ClubsAndActivitiesStrings1({required this.universityName, required this. clubName, required this.studentName, required this.videoURL, required this.description});


  factory ClubsAndActivitiesStrings1.fromJson(Map<String, dynamic> json) {
    return ClubsAndActivitiesStrings1(

      universityName: json['universityName'] ?? "Unknown",
      clubName: json['clubName'] ?? "Unknown",
      studentName: json['studentName'] ?? "Unknown",
      videoURL: json['videoURL']?? "Unknown",
      description: json['description'] ?? "Unknown",
    );
  }
}


// ---------------------------------------- MODEL CLASS TO GET THE DATA WHICH IS PRESENT IN DATABASE ------------------


class ClubsAndActivitiesStrings {
  final String id;
  final String name;
  final String description;
  final String? thumbnail;

  ClubsAndActivitiesStrings({
    required this.id,
    required this.name,
    required this.description,
    this.thumbnail,
  });

  factory ClubsAndActivitiesStrings.fromJson(Map<String, dynamic> json) {
    return ClubsAndActivitiesStrings(
      id: json['_id'] ?? "",
      name: json['name'] ?? "Unknown Club",
      description: json['description'] ?? "",
      thumbnail: json['thumbnail'],
    );
  }
}


// -------------------------------------------- CAMPUS STAR CARD ---------------------------------------------


class UserCard extends StatelessWidget {
  final String name;
  final String imageUrl;

   UserCard(this.name,this.imageUrl );

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
          )
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(
                imageUrl),
          ),
          const SizedBox(height: 8),
          Text(name,
              style:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          const Text("Student leader",
              style: TextStyle(fontSize: 11, color: Colors.grey)),

        ],
      ),
    );
  }
}
class _BounceCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _BounceCard({required this.child, required this.onTap});

  @override
  State<_BounceCard> createState() => _BounceCardState();
}

class _BounceCardState extends State<_BounceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) async {
        await _controller.reverse();
        await Future.delayed(const Duration(milliseconds: 500));
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
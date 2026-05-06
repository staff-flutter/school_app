import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_social_button/flutter_social_button.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/my_children_controller.dart';
import '../constants/api_constants.dart';
import '../services/user_session.dart';
import 'home_page.dart';


class ParentProfile extends StatefulWidget {
  const ParentProfile({super.key});

  @override
  State<ParentProfile> createState() => _ParentProfileState();
}

class _ParentProfileState extends State<ParentProfile> {
  final session = Get.find<UserSession>();



 // 1. THE LOGIN FUNCTION
  Future<void> loginAndGetToken() async {
    final url = Uri.parse('https://bmbbackend.com/api/user/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "identifier": "parent1@gmail.com",
          "password": "parent1@123",
        }),
      );

      if (response.statusCode == 200) {
        print(response.body);
        final data = jsonDecode(response.body);

        String token = data['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_token', token);

        print("Login Successful! Token Saved.");
      } else {
        print("Login Failed: ${response.body}");
      }
    } catch (e) {
      print("Login Error: $e");
    }
  }


// -------------------------------------- THE  PARENT PROFILE FUNCTION ---------------------------------


  Future<List<ParentProfileStrings>> fetchParentProfile() async {
    String baseUrl = ApiConstants.baseUrl;

    final controller = Get.find<MyChildrenController>();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
   // String? token = prefs.getString('token');
   // String? token = prefs.getString('user_token');
    String?  userId =prefs.getString('parentId');

    final String? token = session.token;



    // If no token, try to login first
    // if (token == null) {
    //   await loginAndGetToken();
    //   token = prefs.getString('user_token');
    // }

    final Map<String, String> queryParameters = {
      "userId":"69be7cac7648454b51f80127"
    };
    //const userId="69be7cac7648454b51f80127";

    final uri = Uri.parse('$baseUrl/api/user/$userId');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
print('token:$token');
print('userid:$userId');
    if (response.statusCode == 200) {
      print('parentbody response ${response.body}');

      final dynamic decodedData = jsonDecode(response.body);

      if(decodedData is List){
        return decodedData.map((data) => ParentProfileStrings.fromJson(data)).toList();
      }
      else if (decodedData is Map<String, dynamic>) {
        // 1. Get the value from the 'data' key
        final dataValue = decodedData['data'];

        // 2. Check if that specific value is a List
        if (dataValue is List) {
          return dataValue.map((data) => ParentProfileStrings.fromJson(data)).toList();
        }

        // 3. If 'data' is a single Map instead of a List, wrap it in a List
        if (dataValue is Map<String, dynamic>) {
          return [ParentProfileStrings.fromJson(dataValue)];
        }
      }
      return [];
      //List jsonResponse = jsonDecode(response.body);
      // return jsonResponse.map((data) => TimetableEntry.fromJson(data)).toList();
    } else {
      print("Parent profile Error: ${response.statusCode}-${response.body}");
      return [];
    }
  }


  // ------------------------------------ INIT STATE () -------------------------------------------


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchParentProfile();
    // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    //   statusBarColor: Colors.black, // transparent so AppBar image shows through
    //   statusBarIconBrightness: Brightness.light, // dark icons (visible on light bg)
    // ));
  }

  @override
  Widget build(BuildContext context) {
    var children = [].obs; // Your list of children from API
    var selectedChild = {}.obs; // The child currently being viewed
    final controller = Get.find<MyChildrenController>();



    final session = Get.find<UserSession>();
    String rawData = session.schoolSocialPlatform ?? "";
    String cleaned = rawData.replaceAll('{', '').replaceAll('}', '');
    List<String> pairs = cleaned.split(',');

    Map<String, String> socialMap = {};
    for (var pair in pairs) {
      if (pair.contains(':')) {
        int colonIndex = pair.indexOf(':');
        String key = pair.substring(0, colonIndex).trim();
        String value = pair.substring(colonIndex + 1).trim();
        socialMap[key] = value;
      }
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // white icons
        statusBarBrightness: Brightness.dark,       // iOS
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FB),
        body: Stack(
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,


                // -------------------------------------- HEADER IMAGE ----------------------------------------


                child: Image.asset(
                  'assets/images/Blue science and education collection footer.png', // transparent footer image
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: SafeArea(
                    top: false,
                    bottom: true,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        //  Gradient Header
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipPath(
                              clipper: HeaderClipper(),
                              child: Stack(
                                  children: [
                                    Container(
                                      height: 250,
                                      width: double.infinity,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xff4A90E2),
                                            Color(0xff6FD3F7),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                    ),

                                  ]
                              ),
                            ),
                            Align(
                                alignment: Alignment.topCenter,
                                child: Image.asset('assets/images/Scientific UI background design header.png' , fit: BoxFit.cover,)
                            ),


                  // ---------------------------------------  Avatar + Edit Button  ------------------------------------


                            Positioned(
                              bottom: -60,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          )
                                        ],
                                      ),
                                      child: const CircleAvatar(
                                        radius: 55,
                                        backgroundColor: Colors.white,
                                        child: CircleAvatar(
                                            radius: 50,
                                            backgroundImage:AssetImage('assets/images/parent_image.webp')
                                        ),
                                      ),
                                    ),

                                    //  Edit Button
                                    Positioned(
                                      bottom: 5,
                                      right: 5,
                                      child: GestureDetector(
                                        onTap: () {
                                          debugPrint("Edit Profile Clicked");
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(
                                              colors: [
                                                // Color(0xFF4F6DB8),
                                                // Color(0xFF3E5AA8),
                                                Color(0xff4A90E2),
                                                Color(0xff6FD3F7),
                                              ],
                                            ),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 75),


                  // -----------------------------------------------  Name  ---------------------------------------------


                        const Text(
                          "Parent Profile",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 8),
                        Container(
                          width: 120,
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.grey.shade400,
                                Colors.transparent
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),


                                 // ---------------------------------  PERSONAL INFORMATION  ---------------------------------------------------


                        buildGradientSection(
                          title: "Personal Information",
                          icon: Icons.info_outline,
                          children: [
                            InfoRow( title:"Email", icon:Icons.email,data:session.parentEmail),
                            InfoRow(title:"Mobile Number" ,icon: Icons.phone,data:session.parentPhoneNo),

                          ],
                        ),


                  // ---------------------------------  SCHOOL INFORMATION  ------------------------------------------------


                        buildGradientSection(
                          title: "School Information",
                          icon: Icons.description_outlined,
                          children: [
                            InfoRow( title:"School Name", icon: Icons.apartment,data:session.schoolName),
                            InfoRow( title:"Address", icon: Icons.location_on,data:session.schoolAddress),
                            InfoRow( title:"Contact Email", icon: Icons.email,data:session.schoolEmail),
                            //InfoRow( title:"Social Media", icon: Icons.share,data:session.schoolSocialPlatform),
                            buildSocialMediaRow(socialMap),

                          ],
                        ),


                  // ---------------------------------  MY CHILDREN  ---------------------------------------------------


                        buildGradientSection(
                          title: "My Children",
                          icon: Icons.child_care,
                          children: [
                            Obx(() {
                              if (controller.children.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text("No children found"),
                                );
                              }
                              return Column(
                                children: [...controller.children.map((childData) {

                                  final String name = childData['studentName']?.toString() ?? "Unknown";
                                  String? imageUrl;
                                  if (childData['studentImage'] is Map) {
                                    imageUrl = childData['studentImage']['url'];
                                  } else if (childData['studentImage'] is String) {
                                    imageUrl = childData['studentImage'];
                                  }



                                  final bool isSelected = controller.selectedChild['_id'] == childData['_id'];

                                  return childListTile(name, imageUrl, isSelected, () {
                                    controller.selectedChild.value = childData;
                                  });
                                }).toList(),

                                // --- LOGOUT BUTTON START ---
                                const Divider(indent: 20, endIndent: 20), // Subtle separator
                                ListTile(
                                  onTap: () => _handleLogout(),
                                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                                  title: const Text(
                                    "Logout Account",
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.redAccent),
                                ),
                                const SizedBox(height: 10),
                              ]
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
        ),
      ),
    );
  }
  Future<void> _handleLogout() async {
    // Show a confirmation dialog
    Get.dialog(
      AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to exit?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              // final prefs = await SharedPreferences.getInstance();
              // await prefs.clear(); // Clears all saved tokens/data
              Get.offAllNamed('/login'); // Redirect to login and clear stack
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  Widget buildGradientSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: ExpansionTile(
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          leading: CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(icon, color:Colors.black),
          ),
          title: Text(
            title,
            style: const TextStyle(color: Colors.black, fontSize: 18),
          ),
          iconColor: Colors.black,
          collapsedIconColor: Colors.black,
          children: children,
        ),
      ),
    );
  }


  // ---------------------------------  CIRCLE AVATAR METHOD  ------------------------------------------


  Widget circleAvatarMethod(bool isSelected,String studentName, String className, String? imageUrl,VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.grey : Colors.green,
                width: isSelected ? 4.0 : 3.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                )
              ],
            ),
            child: ClipOval(
              child: Container(

                color: Colors.grey.shade200,
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholder(studentName),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  },
                )
                    : _buildPlaceholder(studentName),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            studentName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            "Class: $className",
            style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
          )
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget buildSocialMediaRow(Map<String, String> socialMap) {
    if (socialMap.isEmpty) {
      return const InfoRow(title: "Social Media", icon: Icons.share, data: "-");
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.share, color: Colors.black),
                SizedBox(width: 10),
                Text("Social Media", style: TextStyle(color: Colors.black, fontSize: 15)),
              ],
            ),
            Row(
              children: [
                if (socialMap.containsKey('facebook'))
                  _socialIcon(FontAwesomeIcons.facebook, Colors.blue, socialMap['facebook']!),
                if (socialMap.containsKey('instagram'))
                  _socialIcon(FontAwesomeIcons.instagram, Colors.pink, socialMap['instagram']!),
                if (socialMap.containsKey('youtube'))
                  _socialIcon(FontAwesomeIcons.youtube, Colors.red, socialMap['youtube']!),
                if (socialMap.containsKey('linkedin'))
                  _socialIcon(FontAwesomeIcons.linkedin, Colors.blue.shade800, socialMap['linkedin']!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialIcon(IconData icon, Color color, String url) {
    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: () async {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}


// ----------------------------------------  MODEL CLASS FOR PARENT PROFILE --------------------------------


class ParentProfileStrings {
  final String title;
  final String icon;

  ParentProfileStrings({
    required this.title,
    required this.icon,

  });


  factory ParentProfileStrings.fromJson(Map<String, dynamic> json) {
    return ParentProfileStrings(

      title: json['title'] ?? "Unknown",
      icon: json['icon'] ?? "Unknown",

    );
  }
}


Widget childListTile(String name, String? imageUrl, bool isSelected, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xff4A90E2).withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected ? const Color(0xff4A90E2) : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xff4A90E2),
            backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                ? NetworkImage(imageUrl) : null,
            child: (imageUrl == null || imageUrl.isEmpty)
                ? Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white))
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xff4A90E2) : Colors.black87,
              ),
            ),
          ),
          if (isSelected) const Icon(Icons.check_circle, color: Color(0xff4A90E2), size: 20),
        ],
      ),
    ),
  );
}//  Info Row
class InfoRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? data;

  const InfoRow({
    super.key,
    required this.title,
    required this.icon,
    this.data,
  });
  @override
  Widget build(BuildContext context) {
    // final List<String> data =['Parent@gmail.com','123456789','jai hind Public School','Thirumalasai,chennai','-'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon,color: Colors.black),
                SizedBox(width: 10),
                Text(
                  "$title :",
                  style: const TextStyle(color: Colors.black, fontSize: 15),
                ),
              ],
            ),
          //  SizedBox(width:40),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  (data == null || data!.isEmpty) ? '-' : data!,
                  textAlign: TextAlign.end,
                  style: const TextStyle(color: Colors.black54, fontSize: 15),
                  softWrap: true, // Allows wrapping to next line if very long
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//  Curved Header
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);

    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 60,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
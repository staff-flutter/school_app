import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/my_children_controller.dart';
import 'package:get/get.dart';
import '../widgets/main_wrapper.dart';


class ProfileSelection extends StatefulWidget {
  const ProfileSelection({super.key});

  @override
  State<ProfileSelection> createState() => _ProfileSelectionState();
}

class _ProfileSelectionState extends State<ProfileSelection> {
  late MyChildrenController controller;

  List<String>? studentIds;
  // 1. THE LOGIN FUNCTION
  // Future<void> loginAndGetToken() async {
  //   final url = Uri.parse('https://bmbbackend.com/api/user/login');
  //
  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({
  //         "identifier": "parent1@gmail.com",
  //         "password": "parent1@123",
  //       }),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       print(response.body);
  //       final data = jsonDecode(response.body);
  //
  //       String token = data['token'];
  //
  //       final prefs = await SharedPreferences.getInstance();
  //       await prefs.setString('user_token', token);
  //
  //       print("Login Successful! Token Saved.");
  //     } else {
  //       print("Login Failed: ${response.body}");
  //     }
  //   } catch (e) {
  //     print("Login Error: $e");
  //   }
  // }

// 2. THE UPDATED TIMETABLE FUNCTION
  Future<List<ProfileSelectionListStrings>> fetchProfileSelection() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('user_token');
    String?  userid =prefs.getString('parentId');

    // If no token, try to login first
    // if (token == null) {
    //   //await loginAndGetToken();
    //   token = prefs.getString('user_token');
    // }

    final Map<String, String> queryParameters = {
      "userId": "parent1@gmail.com",

    };
    print('userId:$userid');
    const userId = "694ab187bab204b91c6b6849";
    final uri = Uri.https('bmbbackend.com', '/api/user/associated-students/get/$userid');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      print('responseOfProfileSelectionPage:${response.body}');
      print(response.statusCode);

      final dynamic decodedData = jsonDecode(response.body);

      if(decodedData is List){
        return decodedData.map((data) => ProfileSelectionListStrings.fromJson(data)).toList();
      }
      else if (decodedData is Map<String, dynamic>) {
        // ADJUST THE KEY BELOW ('data') based on what your backend actually sends
        final List<dynamic> list = decodedData['data'] ?? [];
        return list.map((data) => ProfileSelectionListStrings.fromJson(data)).toList();
      }

      return [];
      //List jsonResponse = jsonDecode(response.body);
      // return jsonResponse.map((data) => TimetableEntry.fromJson(data)).toList();
    } else {
      print("ProfileSelection Error: ${response.statusCode}-${response.body}");
      return [];
    }
  }


  // ---------------------------------- FETCH PROFILE SECTION -------------------------------------------


  Future<List<ProfileSelectionListStrings>> fetchProfileSelection1() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('user_token');
    String?  userid =prefs.getString('parent_id');
    studentIds = prefs.getStringList('studentId');

    if (studentIds != null && studentIds!.isNotEmpty) {
      print("--- Printing Individual Student IDs ---");
      for (var id in studentIds!) {
        print("Student ID: $id");
      }
    } else {
      print("No Student IDs found in session.");
    }
    return[];
  }


  // ------------------------------------------- INIT STATE () ---------------------------------------


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    //   statusBarColor: Colors.black, // transparent so AppBar image shows through
    //   statusBarIconBrightness: Brightness.light, // dark icons
    // ));
    controller = Get.find<MyChildrenController>();

    // Trigger data load immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadMyChildren();
    });
    _initializeAttendance();
  }
  Future<void> _initializeAttendance() async {
    //await loginAndGetToken();
    await fetchProfileSelection1();

    setState(() {});
  }


  // -------------------------------------------- BUILD METHOD ----------------------------------------


  @override
  Widget build(BuildContext context) {
    return GetBuilder<MyChildrenController>(
      builder: (controller) {
        // Use the controller's loading state or check if list is empty
        if (controller.children.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.black,
            statusBarIconBrightness: Brightness.light, // white icons
            statusBarBrightness: Brightness.dark,       // iOS
          ),
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(

              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 110),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 20,
                    children: List.generate(controller.children.length, (index) {
                      final child = controller.children[index];

                      final bool isSelected = controller.selectedChild['id'] == child['id'];
                      final String name = child['studentName'] ?? "Unknown";
                      final String className = child['className'] ?? "N/A";

                      String? imageUrl;
                      if (child['studentImage'] is Map) {
                        imageUrl = child['studentImage']['url'];
                      } else if (child['studentImage'] is String) {
                        imageUrl = child['studentImage'];
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: circleAvatarMethod(
                          isSelected, name, className, imageUrl, () async {
                          controller.selectChild(child);
                          await Future.delayed(const Duration(milliseconds: 100));
                          Get.to(() => MainWrapper(child: HomePage()));
                        },
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  // ---------------------------------------CIRCLE AVATAR METHOD -----------------------------------------


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
            studentName != "Unknown Student" ? "$studentName" : "Unknown",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            className != "Unknown Class" ? "Class: $className" :"Class:Unknown",
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
}



class ProfileSelectionListStrings {
  final String subjectName;
  final String time;
  final String teacherName;
  final String periodNumber;
  final bool isBreak;

  ProfileSelectionListStrings({
    required this.subjectName,
    required this.time,
    required this.teacherName,
    required this.periodNumber,
    required this.isBreak
  });


  factory ProfileSelectionListStrings.fromJson(Map<String, dynamic> json) {
    return ProfileSelectionListStrings(

      subjectName: json['isBreak'] == true ? "Break" : (json['subjectName'] ?? "Unknown"),
      time: json['timeRange'] ?? "00:00 - 00:00",
      teacherName: json['teacherName'] ?? json['teacherId'] ?? "N/A",
      periodNumber: json['periodNumber']?.toString() ?? "-",
      isBreak: json['isBreak'] ?? false,
    );
  }
}
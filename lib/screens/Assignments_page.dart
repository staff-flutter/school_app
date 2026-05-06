import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../controllers/my_children_controller.dart';
import '../core/theme/app_theme.dart';
import '../services/user_session.dart';

class AssignmentUI extends StatefulWidget {
  const AssignmentUI({super.key});

  @override
  State<AssignmentUI> createState() => _AssignmentUIState();
}

class _AssignmentUIState extends State<AssignmentUI> {

  final Map<int, Future<List<AssignmentListStrings>>> _assignmentFutures = {};

  final session = Get.find<UserSession>();
  int selectedIndex = 1;
  int toggleIndex = 0;

  final PageController _pageController = PageController(initialPage: 1);

  final List<Map<String, String>> dates = [
    {"day": "Sun", "date": "17", "fullDay": "sunday"},
    {"day": "Mon", "date": "18", "fullDay": "monday"},
    {"day": "Tue", "date": "19", "fullDay": "tuesday"},
    {"day": "Wed", "date": "20", "fullDay": "wednesday"},
    {"day": "Thu", "date": "21", "fullDay": "thursday"},
    {"day": "Fri", "date": "22", "fullDay": "friday"},
    {"day": "Sat", "date": "23", "fullDay": "saturday"},
  ];




  void onDateTap(int index) {
    setState(() => selectedIndex = index);
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut);
  }


  // 1. THE LOGIN FUNCTION
  // Future<void> loginAndGetToken() async {
  //   String baseurl = ApiConstants.baseUrl;
  //   final url = Uri.parse('$baseurl/api/user/login');
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
  //       final data = jsonDecode(response.body);
  //
  //       String token = data['token'];
  //
  //       final prefs = await SharedPreferences.getInstance();
  //       await prefs.setString('user_token', token);
  //
  //
  //       print("Login Successful! Token Saved.");
  //     } else {
  //       print("Login Failed: ${response.body}");
  //     }
  //   } catch (e) {
  //     print("Login Error: $e");
  //   }
  // }



//------------------------------------------ THE  ASSIGNMENT FUNCTION----------------------------------------------



  Future<List<AssignmentListStrings>> fetchAssignments(String day) async {
    String baseUrl = ApiConstants.baseUrl;

    final controller = Get.find<MyChildrenController>();
    final selectedStudent = Get.find<MyChildrenController>().selectedChild;
    final String? token = session.token;
  //  final SharedPreferences prefs = await SharedPreferences.getInstance();
   // String? token = prefs.getString('user_token');

  //  If no token, try to login first
  //   if (token == null) {
  //     await loginAndGetToken();
  //     token = prefs.getString('user_token');
  //   }

    final String? schoolId =session.schoolId;
    final String? classId = controller.selectedChild['classId']?? 'null';
    final String? sectionId =selectedStudent['sectionId']?? 'null';



    final Map<String, String> queryParameters = {
      if(schoolId!= null)
        "schoolId": '$schoolId',
        "classId":'$classId',
        "sectionId":'$sectionId',
        "page":"1",
        "limit":"10"
    };
    print("token:$token");
     print("schoolId:$schoolId");
    print("classId:$classId");
    print("sectionId:$sectionId");
    final uri = Uri.parse('$baseUrl/api/homework/getall').replace(queryParameters: queryParameters);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> decodedData = jsonDecode(response.body);
      final List<AssignmentListStrings> allAssignments = [];

      if (decodedData['ok'] == true && decodedData['data'] is List) {
        for (var homeworkDay in decodedData['data']) {
          String dateStr = homeworkDay['homeworkDate'] ?? "";
          List subjects = homeworkDay['subjects'] ?? [];

          for (var subjectJson in subjects) {
            allAssignments.add(AssignmentListStrings.fromJson(subjectJson, dateStr));
          }
        }
      }
      return allAssignments;
    } else {
      return [];
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _assignmentFutures[selectedIndex] = fetchAssignments(dates[selectedIndex]["fullDay"]!);

    //fetchAssignments('Monday');
    // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    //   statusBarColor: Colors.black, // transparent so AppBar image shows through
    //   statusBarIconBrightness: Brightness.light, // dark icons (visible on light bg)
    //   // or Brightness.light if your header image is dark
    // ));
  }



  //-------------------------------------- BUILD METHOD ------------------------------------------------------



  @override
  Widget build(BuildContext context) {

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFEEF3FB),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(

        bottomNavigationBar: SizedBox(
          height: MediaQuery.of(context).viewPadding.bottom, // ✅ add this
        ),
        backgroundColor: const Color(0xFFEEF3FB),
       // backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding:  EdgeInsets.only( top: 12,left: 10,right: 10
             // bottom: MediaQuery.of(context).viewPadding.bottom,
              ),
            child: Column(
              children: [
      
      
      
       //--------------------------------------- ASSIGNMENTS HEADING ------------------------------------------------
      
      
      
                Row(
                  children: [
                    InkWell(
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new), // Change your icon here
                        color: Colors.black, // Change your color here
                        onPressed: () {
                          Get.back(); // Or Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Assignments",
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
      
                const SizedBox(height: 15),
      
      
       //---------------------------------------- DATE AND WEEK SELECTOR ---------------------------------------------
      
      
      
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: dates.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => onDateTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 65,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: selectedIndex == index
                                ? Colors.blue
                                : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dates[index]["day"]!,
                                style: TextStyle(
                                  color: selectedIndex == index
                                      ? Colors.white
                                      : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                dates[index]["date"]!,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: selectedIndex == index
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      
                const SizedBox(height: 20),
      
      
      
       //------------------------------------------ PAGE VIEW BUILDER(SWIPE PAGES) ------------------------------------------
      
      
      
                Expanded(
                   child: PageView.builder(
                     controller: _pageController,
                     onPageChanged: (index) {
                       setState(() => selectedIndex = index);
                     },
                    itemCount: dates.length,
                     itemBuilder: (context, index) {
                       _assignmentFutures[index] ??= fetchAssignments(dates[index]["fullDay"]!);
      
                       String selectedDayName = dates[index]["day"]!;
      
        return FutureBuilder<List<AssignmentListStrings>>(
          future: _assignmentFutures[index], // ← cached
         //   future: fetchAssignments(selectedDayName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
      
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('No assignments today!',
                      style: TextStyle(color: Colors.grey.shade400,
                          fontSize: 15, fontWeight: FontWeight.w500)),
                ],
              ),
            );        }
      
          final assignments = snapshot.data!;
      
      
      
       // ----------------------------------------- LIST VIEW BUILDER ----------------------------------------------------
      
      
      
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(16, 12, 16, AppTheme.navBarPadding(context)),

            itemCount: assignments.length,
            itemBuilder: (ctx, i) {
              final item = assignments[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Column(
                  children: [
                    AssignmentContainer(
                          subject: item.subject,
                          title: item.description,
                          pages: "View Attachments (${item.imageUrls.length})",
                          date: item.date.split('T')[0],
                          color: Colors.blue,
                        ),
                    SizedBox(height: 20,),
                    AssignmentContainer(
                      subject: item.subject,
                      title: item.description,
                      pages: "View Attachments (${item.imageUrls.length})",
                      date: item.date.split('T')[0],
                      color: Colors.blue,
                    ),
                  ],
                ),

              );
            },
          );
        },
      );
        },
                ),
                )],
            ),
          ),
        ),
      ),
    );
  }


}



//------------------------------------------------MODEL CLASS TO GET DATA -------------------------------------



class AssignmentListStrings {
  final String subject;
  final String description;
  final String date;
  final List<String> imageUrls;

  const AssignmentListStrings({
    required this.subject,
    required this.description,
    required this.date,
    required this.imageUrls,
  });

  factory AssignmentListStrings.fromJson(Map<String, dynamic> json, String homeworkDate) {
    return AssignmentListStrings(
      subject: json['subjectName'] ?? "Unknown",
      description: json['description'] ?? "No description provided",
      date: homeworkDate,
      imageUrls: (json['attachments'] as List?)
          ?.map((e) => e['url'] as String)
          .toList() ?? [],
    );
  }
}

class AssignmentContainer extends StatelessWidget {
  final String subject;
  final String title;
  final String pages;
  final String date;
  final Color color;

  const AssignmentContainer({
    super.key,
    required this.subject,
    required this.title,
    required this.pages,
    required this.date,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              subject,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w600)),

          const SizedBox(height: 5),

          Text(pages, style: const TextStyle(color: Colors.grey)),

          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Text(date, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
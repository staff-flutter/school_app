import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
// import 'package:school_app/app/core/widgets/dark_status_bar.dart'; // TODO: widget not in lib
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../controllers/auth_controller.dart';
import '../controllers/my_children_controller.dart';
import '../constants/api_constants.dart';
import '../core/theme/app_theme.dart';
import '../services/user_session.dart';



class TimeTablePage extends StatefulWidget {
  const TimeTablePage({super.key});

  @override
  State<TimeTablePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<TimeTablePage> {
  static const double _chipWidth = 95.0;   // fixed width per chip
  static const double _chipMargin = 6.0;   // horizontal margin each side
  late final MyChildrenController controller;

  final session = Get.find<UserSession>();
  final PageController _pageController = PageController();
  final ScrollController _textScrollController = ScrollController();
  int _currentPageIndex = 0;
  int selectedRowIndex = 0;
  final ScrollController _dayScrollController = ScrollController(); // New controller

  final List<String> days = [
    'Sunday', // Added Sunday
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  final Map<int, Future<List<TimetableListStrings>>> _timetableFutures = {};


  //---------------------------------------INIT STATE() -------------------------------------


  @override
  void initState() {
    // TODO: implement initState
    super.initState();

     controller = Get.put(MyChildrenController());
    _currentPageIndex=0;
    _timetableFutures[0] = fetchTimetable(days[0]);
    loginAndGetToken();
  }


  //------------------------------------DISPOSE METHOD() -----------------------------------


  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _pageController.dispose();
    _textScrollController.dispose();
  }


  //1. THE LOGIN FUNCTION
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

      print("Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        final userData = data['user'];

        if (userData != null) {

          if (userData['studentId'] != null) {
            List<String> studentIds = (userData['studentId'] as List)
                .map((e) => e.toString())
                .toList();
            await prefs.setStringList('studentId', studentIds);
          }


          await prefs.setString('token', (data['token'] ?? '').toString());
          await prefs.setString('parentId', (userData['_id'] ?? '').toString());
          await prefs.setString('parentName', (userData['userName'] ?? '').toString());
          await prefs.setString('parentEmail', (userData['email'] ?? '').toString());
          await prefs.setString('parentPhoneNo', (userData['phoneNo'] ?? '').toString());
          await prefs.setString('role', (userData['role'] ?? '').toString());
          await prefs.setBool('isPlatformAdmin', userData['isPlatformAdmin'] ?? false);


          final schoolData = userData['schoolId'];
          if (schoolData != null) {
            await prefs.setString('schoolId', (schoolData['_id'] ?? '').toString());
            await prefs.setString('schoolName', (schoolData['name'] ?? '').toString());
            await prefs.setString('schoolEmail', (schoolData['email'] ?? '').toString());
            await prefs.setString('schoolPhoneNo', (schoolData['phoneNo'] ?? '').toString());
            await prefs.setString('schoolAddress', (schoolData['address'] ?? '').toString());
            await prefs.setString('schoolSocialPlatform', (schoolData['socialPlatform'] ?? '').toString());
          }

          print("Login Successful and Data Saved");
        }
      } else {
        print("Login Failed: ${response.body}");
      }
    } catch (e) {
      print("Login Error: $e");
    }
  }


//----------------------------------THE  TIMETABLE FUNCTION ------------------------------------------


  Future<List<TimetableListStrings>> fetchTimetable(String day) async {
    String baseUrl = ApiConstants.baseUrl;
    // controller = Get.find<MyChildrenController>();
    final selectedStudent = controller.selectedChild;
 //   final selectedStudent = Get.find<MyChildrenController>().selectedChild;
   // final TimetableController timetableController = Get.find<TimetableController>();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    //String? token = prefs.getString('token');

    // Dynamically get IDs saved during login
    // String schoolId = prefs.getString('schoolId') ?? "null";
    //
    // String sectionId = prefs.getString('sectionId') ?? "null";
    //
    // String studentId = prefs.getString('studentId') ?? "null";
    final String? token =session.token;
    final String? schoolId =session.schoolId;
    final String? classId= controller.selectedChild['classId']??'null';
    final String? sectionId =selectedStudent['sectionId']?? 'null';
    //final  weeklyScheduleId =timetableController.weeklyScheduleId;

    // final List<String>? studentId =session.studentId;

    final Map<String, String> queryParameters = {
      "schoolId": schoolId?? "null",
      "classId":'$classId',
      "SectionId":'$sectionId',
     // "weeklyScheduleId":"$weeklyScheduleId",
      "day": day.toLowerCase(),
      // If the backend needs studentId instead of class/section for parents:
     // if (studentId != null) "studentId": studentId[0],
    };
    print("schoolId:$schoolId");
    print("classId:$classId");
    print("SectionId:$sectionId");
   // print("weeklyScheduleId:$weeklyScheduleId");




    final uri = Uri.parse('$baseUrl/api/timetable/getall').replace(queryParameters: queryParameters);

    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {

      print(response.body);
      final decodedData = jsonDecode(response.body);
      final List<dynamic> list = (decodedData is List) ? decodedData : (decodedData['data'] ?? []);
      return list.map((data) => TimetableListStrings.fromJson(data)).toList();
    }else{
      print("Timetable Error");
    }
    return [];
  }
  @override
  Widget build(BuildContext context) {
    final dummyData = getDummyTimetable();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light, // white icons
      statusBarBrightness: Brightness.dark,       // iOS
    ));
    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: AppBarTheme(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
      ),
      child: Scaffold(

        extendBody: true,
        body: SafeArea(

          top: false,
          bottom: false,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
              // 1. Update your SliverAppBar inside headerSliverBuilder
              SliverAppBar(
                expandedHeight: (screenHeight * 0.18).clamp(100.0, 180.0),
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xff4A90E2),
                leading: _shouldShowBack()
                    ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Get.back(),
                )
                    : const SizedBox.shrink(),
                title: const Text(
                  'Timetable',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                centerTitle: false,
                flexibleSpace: FlexibleSpaceBar(
                  // title: const Text('Timetable', style: TextStyle(color: Colors.white, fontSize: 18)),
                  // centerTitle: false,
                  //titlePadding: const EdgeInsets.only(left: 56, bottom: 65),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/Scientific UI background design header.png',
                        fit: BoxFit.cover,
                      ),
                      // Optional: dark overlay so image doesn't clash
                      Container(color: Colors.black.withOpacity(0.15)),
                    ],
                  ),
                ),
                // THIS IS THE KEY: Use the bottom property to pin the chips
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    decoration: const BoxDecoration(
                      color:const Color(0xFFEEF3FB),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    //day chips
                    child: SizedBox(
                      height: 44,
                      child: ListView.builder(
                        controller: _dayScrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: days.length,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        itemBuilder: (context, index) {
                          final isSelected = _currentPageIndex == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _currentPageIndex = index);
                              _pageController.animateToPage(index,
                                  duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                              _scrollDayIntoView(index);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: _chipWidth,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xff4A90E2) : Colors.white,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Center(
                                child: Text(
                                  days[index],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),


              ];
            },

            // Full white background
            // Container(
            //   height: screenHeight,
            //   decoration: const BoxDecoration(
            //    color: const Color(0xFFEEF3FB),
            //   ),
            // ),
            body: Stack(
              children: [
                Container(
                  height: screenHeight,
                  decoration: const BoxDecoration(
                   color: const Color(0xFFEEF3FB),
                  ),
                ),
                Positioned.fill(
                  top: 5,
                  // ✅ Add bottom padding equal to nav bar height
                 // bottom: AppTheme.navBarHeight + AppTheme.navBarBottomMargin,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: days.length,
                          onPageChanged: (index) {
                            setState(() => _currentPageIndex = index);
                            if (_dayScrollController.hasClients) {
                              _scrollDayIntoView(index);
                              _timetableFutures[index] ??= fetchTimetable(days[index]);
                            }
                            _timetableFutures[index] ??= fetchTimetable(days[index]);
                          },
                          itemBuilder: (context, pageIndex) {
                            _timetableFutures[pageIndex] ??= fetchTimetable(days[pageIndex]);
                            return FutureBuilder<List<TimetableListStrings>>(
                              future: _timetableFutures[pageIndex],
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(child: Text('Error: ${snapshot.error}'));
                                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return const Center(child: Text('No classes scheduled for today.'));
                                }
                                return ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  padding: EdgeInsets.only(
                                    left: screenWidth * 0.03,
                                    right: screenWidth * 0.03,
                                    top: 10,
                                    bottom: 20, // ✅ small buffer only
                                  ),
                                  itemCount: dummyData.length,
                                  itemBuilder: (context, index) => TimeTableTile(user: dummyData[index]),
                                );
                              },
                            );
                          },
                        ),
                      ),
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

// Key list to measure each chip's position
  final List<GlobalKey> _dayKeys = List.generate(7, (_) => GlobalKey());

  void _scrollDayIntoView(int index) {
    if (!_dayScrollController.hasClients) return;
    final viewportWidth = _dayScrollController.position.viewportDimension;
    final maxScroll = _dayScrollController.position.maxScrollExtent;
    final itemOffset = index * (_chipWidth + _chipMargin * 2);
    final centeredOffset = itemOffset - (viewportWidth - _chipWidth) / 2;


    _dayScrollController.animateTo(
      centeredOffset.clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  bool _shouldShowBack() {
    try {
      final role = Get.find<AuthController>().user.value?.role?.toLowerCase() ?? '';
      const sidebarRoles = {'correspondent', 'administrator', 'principal', 'viceprincipal', 'teacher', 'accountant'};
      return !sidebarRoles.contains(role);
    } catch (_) {
      return true;
    }
  }
}
//------------------------------------------------- DUMMY DATA -------------------------------------------

List<TimetableListStrings> getDummyTimetable() {
  return [
    TimetableListStrings(
      subjectName: "Mathematics",
      time: "08:30 AM - 09:15 AM",
      teacherName: "Dr. Robert Fox",
      periodNumber: "1",
      isBreak: false,
    ),
    TimetableListStrings(
      subjectName: "English Literature",
      time: "09:15 AM - 10:00 AM",
      teacherName: "Ms. Sarah Jenkins",
      periodNumber: "2",
      isBreak: false,
    ),
    TimetableListStrings(
      subjectName: "Short Break",
      time: "10:00 AM - 10:15 AM",
      teacherName: "N/A",
      periodNumber: "-",
      isBreak: true, // This will show your yellow/amber break tile
    ),
    TimetableListStrings(
      subjectName: "Physics",
      time: "10:15 AM - 11:00 AM",
      teacherName: "Mr. Albert Wright",
      periodNumber: "3",
      isBreak: false,
    ),
    TimetableListStrings(
      subjectName: "Computer Science",
      time: "11:00 AM - 11:45 AM",
      teacherName: "Mrs. Linda Chen",
      periodNumber: "4",
      isBreak: false,
    ),
    TimetableListStrings(
      subjectName: "Lunch Break",
      time: "11:45 AM - 12:45 PM",
      teacherName: "Cafeteria",
      periodNumber: "-",
      isBreak: true,
    ),
    TimetableListStrings(
      subjectName: "History",
      time: "12:45 PM - 01:30 PM",
      teacherName: "Mr. David Miller",
      periodNumber: "5",
      isBreak: false,
    ),
  ];
}

//------------------------------------------------- MODEL CLASS FOR TIME TABLE ----------------------------


class TimetableListStrings {
  final String subjectName;
  final String time;
  final String teacherName;
  final String periodNumber;
  final bool isBreak;

  TimetableListStrings({
    required this.subjectName,
    required this.time,
    required this.teacherName,
    required this.periodNumber,
    required this.isBreak
  });


factory TimetableListStrings.fromJson(Map<String, dynamic> json) {
return TimetableListStrings(

subjectName: json['isBreak'] == true ? "Break" : (json['subjectName'] ?? "Unknown"),
time: json['timeRange'] ?? "00:00 - 00:00",
teacherName: json['teacherName'] ?? json['teacherId'] ?? "N/A",
periodNumber: json['periodNumber']?.toString() ?? "-",
isBreak: json['isBreak'] ?? false,
);
}
}

const List<Widget> options = <Widget>[
  Text('Mon'),
  Text('Tue'),
  Text('Wed'),
  Text('Thu'),
  Text('Fri'),
  Text('Sat'),
];


// -------------------------------------------TIMETABLE CONTAINER ------------------------------


class TimeTableTile extends StatelessWidget {
  final TimetableListStrings user;

  const TimeTableTile({Key? key, required this.user}) : super(key: key);

  static const List<Color> _subjectColors = [
    Color(0xFF4A90E2), Color(0xFF7B68EE), Color(0xFF50C878),
    Color(0xFFFF7F50), Color(0xFFFFD700), Color(0xFF20B2AA),
  ];


  @override
  Widget build(BuildContext context) {
    if (user.isBreak) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color:const Color(0xFFE6E6FA),),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.free_breakfast, color: Colors.blue.shade300, size: 16),
            const SizedBox(width: 8),
            Text('Break', style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            )),
            const SizedBox(width: 8),
            Text(user.time, style: TextStyle(
              color: Colors.blue, fontSize: 12,
            )),
          ],
        ),
      );
    }

    final colorIndex = int.tryParse(user.periodNumber) ?? 0;
    final accent = _subjectColors[colorIndex % _subjectColors.length];
    // return Container(
    //   margin: const EdgeInsets.symmetric(vertical: 8.0,horizontal: 5),
    //   padding: const EdgeInsets.all(10.0),
    //   width: MediaQuery
    //       .sizeOf(context)
    //       .width,
    //
    //   decoration: BoxDecoration(
    //     borderRadius: BorderRadius.circular(20),
    //     border: Border.all(
    //       color: Colors.grey, // Set border color
    //       width: 1.0, // Set border width
    //     ),
    //   ),
    //   child: Column(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       Text(user.subjectName, style: TextStyle(
    //           fontWeight: FontWeight.bold,color: Colors.black87,
    //           fontSize: 15),),
    //       Text(user.time, style: TextStyle(
    //           fontSize: 12, color: Colors.grey),),
    //       SizedBox(
    //         height: 5,
    //       ),
    //       Divider(),
    //       Row(
    //         mainAxisAlignment: MainAxisAlignment
    //             .spaceBetween,
    //         children: [
    //           Text(user.teacherName,style: TextStyle(fontSize: 15, color: Colors.grey),),
    //           Text(user.periodNumber, style: TextStyle(
    //               fontSize: 15,color: Colors.black87,
    //               fontWeight: FontWeight.bold),)
    //         ],
    //       )
    //     ],
    //   ),
    // );
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Colored left bar
            // Container(
            //   width: 5,
            //   decoration: BoxDecoration(
            //     color: accent,
            //     borderRadius: const BorderRadius.only(
            //       topLeft: Radius.circular(16),
            //       bottomLeft: Radius.circular(16),
            //     ),
            //   ),
            // ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.subjectName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 10, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(user.time,
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 10, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(user.teacherName,
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Period badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text('Period', style: TextStyle(
                            fontSize: 10, color: accent, fontWeight: FontWeight.w500,
                          )),
                          Text(user.periodNumber, style: TextStyle(
                            fontSize: 18, color: accent, fontWeight: FontWeight.w800,
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

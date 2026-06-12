import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  static const double _chipWidth = 95.0;
  static const double _chipMargin = 6.0;
  late final MyChildrenController controller;

  final session = Get.find<UserSession>();
  final PageController _pageController = PageController();
  final ScrollController _textScrollController = ScrollController();
  int _currentPageIndex = 0;
  int selectedRowIndex = 0;
  final ScrollController _dayScrollController = ScrollController();

  final List<String> days = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  final Map<int, Future<List<TimetableListStrings>>> _timetableFutures = {};

  @override
  void initState() {
    super.initState();
    controller = Get.put(MyChildrenController());
    _currentPageIndex = 0;
    _timetableFutures[0] = fetchTimetable(days[0]);
    //loginAndGetToken();
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
    _textScrollController.dispose();
    _dayScrollController.dispose();
  }

  // Future<void> loginAndGetToken() async {
  //   final url = Uri.parse('${ApiConstants.baseUrl}/api/user/login');
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
  //       final Map<String, dynamic> data = jsonDecode(response.body);
  //       final prefs = await SharedPreferences.getInstance();
  //       final userData = data['user'];
  //
  //       if (userData != null) {
  //         if (userData['studentId'] != null) {
  //           List<String> studentIds = (userData['studentId'] as List)
  //               .map((e) => e.toString())
  //               .toList();
  //           await prefs.setStringList('studentId', studentIds);
  //         }
  //
  //         await prefs.setString('token', (data['token'] ?? '').toString());
  //         await prefs.setString('parentId', (userData['_id'] ?? '').toString());
  //         await prefs.setString('parentName', (userData['userName'] ?? '').toString());
  //         await prefs.setString('parentEmail', (userData['email'] ?? '').toString());
  //         await prefs.setString('parentPhoneNo', (userData['phoneNo'] ?? '').toString());
  //         await prefs.setString('role', (userData['role'] ?? '').toString());
  //         await prefs.setBool('isPlatformAdmin', userData['isPlatformAdmin'] ?? false);
  //
  //         final schoolData = userData['schoolId'];
  //         if (schoolData != null) {
  //           await prefs.setString('schoolId', (schoolData['_id'] ?? '').toString());
  //           await prefs.setString('schoolName', (schoolData['name'] ?? '').toString());
  //           await prefs.setString('schoolEmail', (schoolData['email'] ?? '').toString());
  //           await prefs.setString('schoolPhoneNo', (schoolData['phoneNo'] ?? '').toString());
  //           await prefs.setString('schoolAddress', (schoolData['address'] ?? '').toString());
  //           await prefs.setString('schoolSocialPlatform', (schoolData['socialPlatform'] ?? '').toString());
  //         }
  //       }
  //     }
  //   } catch (e) {
  //     debugPrint("Login Error: $e");
  //   }
  // }

  // ─── FIX 1: Parse nested weeklySchedule → periods for the requested day ───
  Future<List<TimetableListStrings>> fetchTimetable(String day) async {
    final String baseUrl = ApiConstants.baseUrl;
    final selectedStudent = controller.selectedChild;

    final String? token = session.token;
    final String? schoolId = session.schoolId;
    final String? classId = controller.selectedChild['classId'] ?? 'null';
    final String? sectionId = selectedStudent['sectionId'] ?? 'null';

    debugPrint("TIMETABLE FETCH → schoolId:$schoolId | classId:$classId | sectionId:$sectionId | day:$day | token:$token");

    final Map<String, String> queryParameters = {
      "schoolId": schoolId ?? "null",
      "classId": '$classId',
      "SectionId": '$sectionId',
      "day": day.toLowerCase(),
    };

    debugPrint("schoolId:$schoolId | classId:$classId | SectionId:$sectionId | day:$day");
    if (schoolId == null || classId == null) {
      debugPrint("TIMETABLE: Missing schoolId or classId, aborting fetch");
      return [];
    }
    final uri = Uri.parse('$baseUrl/api/timetable/getall')
        .replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        final List<dynamic> scheduleList =
        (decodedData is Map ? (decodedData['data'] ?? []) : decodedData) as List;

        // ✅ Prefer the record whose sectionId matches, fallback to null-section record
        Map<String, dynamic>? matchedSchedule;
        Map<String, dynamic>? fallbackSchedule;

        for (final schedule in scheduleList) {
          final sec = schedule['sectionId'];
          final secId = sec is Map ? sec['_id'] : sec;

          if (secId == sectionId) {
            matchedSchedule = schedule;
            break;
          } else if (sec == null) {
            fallbackSchedule = schedule;
          }
        }

        final targetSchedule = matchedSchedule ?? fallbackSchedule;
        if (targetSchedule == null) return [];

        final weeklySchedule = (targetSchedule['weeklySchedule'] as List?) ?? [];
        for (final dayEntry in weeklySchedule) {
          final entryDay = (dayEntry['day'] as String? ?? '').toLowerCase();
          if (entryDay == day.toLowerCase()) {
            final periods = (dayEntry['periods'] as List?) ?? [];
            return periods
                .map((p) => TimetableListStrings.fromJson(p as Map<String, dynamic>))
                .toList();
          }
        }
      } else {
        debugPrint("Timetable Error: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      debugPrint("Timetable fetch exception: $e");
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
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
                SliverAppBar(
                  expandedHeight: (screenHeight * 0.18).clamp(100.0, 180.0),
                  floating: false,
                  pinned: true,
                  backgroundColor: const Color(0xff4A90E2),
                  leading: _shouldShowBack()
                      ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
                    onPressed: () => Get.back(),
                  )
                      : const SizedBox.shrink(),
                  title: const Text(
                    'Timetable',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                  ),
                  centerTitle: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/Scientific UI background design header.png',
                          fit: BoxFit.cover,
                        ),
                        Container(color: Colors.black.withOpacity(0.15)),
                      ],
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEF3FB),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
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
                                    duration:
                                    const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut);
                                _scrollDayIntoView(index);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: _chipWidth,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xff4A90E2)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Center(
                                  child: Text(
                                    days[index],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
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
            body: Stack(
              children: [
                Container(
                  height: screenHeight,
                  decoration:
                  const BoxDecoration(color: Color(0xFFEEF3FB)),
                ),
                Positioned.fill(
                  top: 5,
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
                            }
                            _timetableFutures[index] ??=
                                fetchTimetable(days[index]);
                          },
                          itemBuilder: (context, pageIndex) {
                            _timetableFutures[pageIndex] ??=
                                fetchTimetable(days[pageIndex]);
                            return FutureBuilder<List<TimetableListStrings>>(
                              future: _timetableFutures[pageIndex],
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(
                                      child: Text(
                                          'Error: ${snapshot.error}'));
                                } else if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return const Center(
                                      child: Text(
                                          'No classes scheduled for today.'));
                                }

                                // ─── FIX 3: Use real API data, not dummyData ───
                                final items = snapshot.data!;
                                return ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  padding: EdgeInsets.only(
                                    left: screenWidth * 0.03,
                                    right: screenWidth * 0.03,
                                    top: 10,
                                    bottom: 20,
                                  ),
                                  itemCount: items.length,
                                  itemBuilder: (context, index) =>
                                      TimeTableTile(user: items[index]),
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

  void _scrollDayIntoView(int index) {
    if (!_dayScrollController.hasClients) return;
    final viewportWidth =
        _dayScrollController.position.viewportDimension;
    final maxScroll = _dayScrollController.position.maxScrollExtent;
    final itemOffset = index * (_chipWidth + _chipMargin * 2);
    final centeredOffset =
        itemOffset - (viewportWidth - _chipWidth) / 2;

    _dayScrollController.animateTo(
      centeredOffset.clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  bool _shouldShowBack() {
    try {
      final role =
          Get.find<AuthController>().user.value?.role?.toLowerCase() ?? '';
      const sidebarRoles = {
        'correspondent',
        'administrator',
        'principal',
        'viceprincipal',
        'teacher',
        'accountant'
      };
      return !sidebarRoles.contains(role);
    } catch (_) {
      return true;
    }
  }
}

// ─── MODEL ──────────────────────────────────────────────────────────────────

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
    required this.isBreak,
  });

  // ─── FIX 2: teacherId can be a String OR a nested Map {_id, userName} ───
  factory TimetableListStrings.fromJson(Map<String, dynamic> json) {
    final teacherRaw = json['teacherId'];
    final String teacherName;
    if (teacherRaw is Map) {
      teacherName = (teacherRaw['userName'] ?? 'N/A').toString();
    } else {
      teacherName = (teacherRaw ?? 'N/A').toString();
    }

    return TimetableListStrings(
      subjectName: json['isBreak'] == true
          ? "Break"
          : (json['subjectName'] ?? "Unknown").toString(),
      time:json['timeRange'] ??
    (json['startTime'] != null && json['endTime'] != null
    ? '${json['startTime']} - ${json['endTime']}'
        : "No time set"),
      teacherName: teacherName,
      periodNumber: json['periodNumber']?.toString() ?? "-",
      isBreak: json['isBreak'] ?? false,
    );
  }
}

// ─── TILE WIDGET ─────────────────────────────────────────────────────────────

class TimeTableTile extends StatelessWidget {
  final TimetableListStrings user;

  const TimeTableTile({Key? key, required this.user}) : super(key: key);

  static const List<Color> _subjectColors = [
    Color(0xFF4A90E2),
    Color(0xFF7B68EE),
    Color(0xFF50C878),
    Color(0xFFFF7F50),
    Color(0xFFFFD700),
    Color(0xFF20B2AA),
  ];

  @override
  Widget build(BuildContext context) {
    if (user.isBreak) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        padding:
        const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6E6FA)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.free_breakfast,
                color: Colors.blue.shade300, size: 16),
            const SizedBox(width: 8),
            Text('Break',
                style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            const SizedBox(width: 8),
            Text(user.time,
                style: const TextStyle(color: Colors.blue, fontSize: 12)),
          ],
        ),
      );
    }

    final colorIndex = int.tryParse(user.periodNumber) ?? 0;
    final accent = _subjectColors[colorIndex % _subjectColors.length];

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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.subjectName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 10,
                                  color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(user.time,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.person_outline,
                                  size: 10,
                                  color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(user.teacherName,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text('Period',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: accent,
                                  fontWeight: FontWeight.w500)),
                          Text(user.periodNumber,
                              style: TextStyle(
                                  fontSize: 18,
                                  color: accent,
                                  fontWeight: FontWeight.w800)),
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
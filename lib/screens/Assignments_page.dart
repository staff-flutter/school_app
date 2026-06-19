import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../controllers/auth_controller.dart';
import '../controllers/my_children_controller.dart';
import '../core/theme/app_theme.dart';

class AssignmentUI extends StatefulWidget {
  const AssignmentUI({super.key});

  @override
  State<AssignmentUI> createState() => _AssignmentUIState();
}

class _AssignmentUIState extends State<AssignmentUI> {
  final Map<int, Future<List<AssignmentListStrings>>> _assignmentFutures = {};
  final auth_ctrl = Get.find<AuthController>();

  int selectedIndex = 0;
  late final List<Map<String, String>> dates;
  late final PageController _pageController;
  static String _currentAcademicYear() {
    final now = DateTime.now();
    final startYear = now.month >= 6 ? now.year : now.year - 1;
    return '$startYear-${startYear + 1}';
  }
  @override
  void initState() {
    super.initState();
    dates = _buildDates(); // Computed once safely
    selectedIndex = DateTime.now().weekday % 7;

    // Fixed: page controller initialization matches the current day
    _pageController = PageController(initialPage: selectedIndex);
    _assignmentFutures[selectedIndex] = fetchAssignments(selectedIndex);
  }

  List<Map<String, String>> _buildDates() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final dayNames     = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
    final fullDayNames = ["sunday","monday","tuesday","wednesday","thursday","friday","saturday"];
    return List.generate(7, (i) {
      final day = startOfWeek.add(Duration(days: i));
      return {
        "day":     dayNames[i],
        "date":    day.day.toString(),
        "fullDay": fullDayNames[i],
        "isoDate": "${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}",
      };
    });
  }

  void onDateTap(int index) {
    setState(() {
      selectedIndex = index;
      _assignmentFutures[index] = fetchAssignments(index);
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<List<AssignmentListStrings>> fetchAssignments(int dayIndex) async {
    String baseUrl = ApiConstants.baseUrl;
    final controller = Get.find<MyChildrenController>();
    final selectedStudent = controller.selectedChild;
    final String? token = auth_ctrl.storage.read('token');

    final String? schoolId = auth_ctrl.user.value?.schoolId;
    final String? classId = controller.selectedChild['classId'] ?? 'null';
    final String? sectionId = selectedStudent['sectionId'] ?? 'null';

    final Map<String, String> queryParameters = {
      if (schoolId != null) "schoolId": '$schoolId',
      "classId": '$classId',
      "sectionId": '$sectionId',
      "academicYear": _currentAcademicYear(),
      "page": "1",
      "limit": "100"
    };

    final uri = Uri.parse('$baseUrl/api/homework/getall').replace(queryParameters: queryParameters);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('SCHOOLID:$schoolId');
        print('CLASSID:$classId');
        print('sectionId:$sectionId');
        print(response.body);
        final Map<String, dynamic> decodedData = jsonDecode(response.body);
        final List<AssignmentListStrings> allAssignments = [];
        final homeworkData = decodedData['homework'] ?? decodedData['data'];
        final selectedIsoDate = dates[dayIndex]["isoDate"]!;

        if (homeworkData is List) {
          for (var homeworkDay in homeworkData) {
            String dateStr = homeworkDay['homeworkDate'] ?? "";
            if (!dateStr.startsWith(selectedIsoDate)) continue;

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
    } catch (e) {
      return [];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
          height: MediaQuery.of(context).viewPadding.bottom,
        ),
        backgroundColor: const Color(0xFFEEF3FB),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 12, left: 10, right: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    if (_shouldShowBack())
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 15),
                        color: Colors.black,
                        onPressed: () => Get.back(),
                      ),
                    if (_shouldShowBack()) const SizedBox(width: 10),
                    const Text(
                      "Assignments",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
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
                          width: 55,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: selectedIndex == index ? Colors.blue : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dates[index]["day"]!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: selectedIndex == index ? Colors.white : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                dates[index]["date"]!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: selectedIndex == index ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        selectedIndex = index;
                        _assignmentFutures[index] = fetchAssignments(index);
                      });
                    },
                    itemCount: dates.length,
                    itemBuilder: (context, index) {
                      _assignmentFutures[index] ??= fetchAssignments(index);
                      return FutureBuilder<List<AssignmentListStrings>>(
                        future: _assignmentFutures[index],
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
                                  Text(
                                    'No assignments today!',
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            );
                          }

                          final assignments = snapshot.data!;
                          return ListView.builder(
                            padding: EdgeInsets.fromLTRB(16, 12, 16, AppTheme.navBarPadding(context)),
                            itemCount: assignments.length,
                            itemBuilder: (ctx, i) {
                              final item = assignments[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: AssignmentContainer(
                                  subject: item.subject,
                                  title: item.description,
                                  pages: "View Attachments (${item.imageUrls.length})",
                                  date: item.date.split('T')[0],
                                  color: Colors.blue,
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
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
      imageUrls: (json['attachments'] as List?)?.map((e) => e['url'] as String).toList() ?? [],
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              subject,
              style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          Text(pages, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Text(date, style: const TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../core/utils/responsive_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/my_children_controller.dart';
import '../constants/api_constants.dart';
import '../services/user_session.dart';

class MarksList extends StatefulWidget {
  const MarksList({super.key});

  @override
  State<MarksList> createState() => _MarksListState();
}

class _MarksListState extends State<MarksList> {
  String _selectedExam = '';
  List<String> _examList = [];
  final session = Get.find<UserSession>();

  final List<MarksTable> marksTableList = const [
    MarksTable(outOfMarks: 100, scoredMarks: 74, grade: 'B', subjectName: 'English'),
    MarksTable(outOfMarks: 100, scoredMarks: 87, grade: 'B', subjectName: 'Hindi'),
    MarksTable(outOfMarks: 100, scoredMarks: 74, grade: 'B', subjectName: 'Science'),
    MarksTable(outOfMarks: 100, scoredMarks: 87, grade: 'B', subjectName: 'Math'),
    MarksTable(outOfMarks: 100, scoredMarks: 89, grade: 'B', subjectName: 'Social Study'),
    MarksTable(outOfMarks: 100, scoredMarks: 78, grade: 'B', subjectName: 'Drawing'),
    MarksTable(outOfMarks: 100, scoredMarks: 96, grade: 'A', subjectName: 'Computer'),
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await getMarkReport("69d75a5d5d26eade45328e26");
    if (mounted) setState(() {});
  }

  Future<List<MarksListStrings>> getMarkReport(String id) async {
    try {
      String baseUrl = ApiConstants.baseUrl;
      final controller = Get.find<MyChildrenController>();
      final String? token = session.token;

      // final SharedPreferences prefs = await SharedPreferences.getInstance();
      //String? token = prefs.getString('user_token');
      final schoolId = session.schoolId;
      final String studentId = controller.selectedChild['_id'] ?? '';

      final Map<String, String> queryParameters = {
        "schoolId": "$schoolId",
        "academicYear": "2025-2026",
        "studentId": studentId,
        if (_selectedExam.isNotEmpty) "examType": _selectedExam,
      };

      final uri = Uri.parse('$baseUrl/api/markreport/get-all')
          .replace(queryParameters: queryParameters);

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);
        List<dynamic> list = [];
        if (decodedData is List) {
          list = decodedData;
        } else if (decodedData is Map<String, dynamic>) {
           list = decodedData['data'] ?? [];
        }
        final exams = list
            .map((d) => d['examType']?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();

        if (mounted) setState(() { _examList = exams; });

        return list.map((data) => MarksListStrings.fromJson(data)).toList();
        }

    } catch (e) {
      debugPrint("MarksList Error: $e");
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    // ── Screen metrics ──────────────────────────────────────────
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double screenWidth  = MediaQuery.sizeOf(context).width;
    final bool   isTablet     = ResponsiveHelper.isTablet(context);
    final bool   isSmall      = ResponsiveHelper.isSmallHeight(context);
    final double bottomInset  = MediaQuery.of(context).viewPadding.bottom;

    final _examList = ['Unit Test', 'Unit Test 2','Half Early', 'Final'];

    // ── Layout values ────────────────────────────────────────────
    final double headerHeight = isTablet
        ? screenHeight * 0.16
        : screenHeight * 0.22;

    final double circleSize = isTablet
        ? screenWidth * 0.14
        : ResponsiveHelper.w(context, 110);

    // how much of the circle hangs below the header into the white area
    final double circleBelowHeader = circleSize * 0.55;

    // where the white rounded container starts
    final double whiteTopOffset = headerHeight - (circleSize * 0.45);

    // usable height inside the white container
    final double whiteHeight = screenHeight - whiteTopOffset;

    // marks table fixed height
    final double tableHeight = whiteHeight * (isTablet ? 0.45 : 0.40);

    // footer image height
    final double footerHeight = isTablet
        ? screenHeight * 0.16
        : isSmall
        ? screenHeight * 0.11
        : screenHeight * 0.13;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness:     Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [

            // ── 1. HEADER IMAGE ─────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: Image.asset(
                'assets/images/Scientific UI background design header.png',
                height: headerHeight,
                fit: BoxFit.fill,
              ),
            ),

            // ── 2. MAIN CONTENT ──────────────────────────────────
            SafeArea(
              top: false,
              bottom: false, // handled manually via bottomInset
              child: Column(
                children: [
                  SizedBox(height: whiteTopOffset),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft:  Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),

                      // ── SINGLE flat Column ──────────────────────
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [

                          // space for bottom half of floating circle
                          SizedBox(height: circleBelowHeader),

                          // greeting
                          Text(
                            'You are Excellent,',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.sp(context, 12),
                            ),
                          ),
                          Text(
                            'AKSHAY SYAL !!',
                            style: TextStyle(
                              fontSize:   ResponsiveHelper.sp(context, 18),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ResponsiveHelper.vSpace(context, 8),

                          if (_examList.isNotEmpty)
                            _ExamSelector(
                              exams:    _examList,
                              selected: _selectedExam,
                              onChanged: (val) {
                                setState(() => _selectedExam = val);
                                _initializeData(); // re-fetch marks for chosen exam
                              },
                            ),
                          // ── MARKS TABLE ─────────────────────────
                          Container(
                            height: tableHeight,
                            margin: EdgeInsets.symmetric(
                              horizontal: ResponsiveHelper.w(context, 15),
                              vertical:   ResponsiveHelper.h(context, 8),
                            ),
                            decoration: BoxDecoration(
                              border:       Border.all(color: Colors.grey.shade300, width: 1.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18.5),
                              child: Column(
                                children: [
                                  // header row
                                  IntrinsicHeight(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Container(
                                            color: const Color(0xFFEEF3FA),
                                            padding: EdgeInsets.symmetric(
                                              vertical:   ResponsiveHelper.h(context, 10),
                                              horizontal: ResponsiveHelper.w(context, 16),
                                            ),
                                            child: Text(
                                              'Subject',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize:   ResponsiveHelper.sp(context, 11),
                                                color:      Colors.black54,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Container(
                                            color: const Color(0xFFB8C8E8),
                                            padding: EdgeInsets.symmetric(
                                              vertical: ResponsiveHelper.h(context, 10),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Out of',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:   ResponsiveHelper.sp(context, 11),
                                                  color:      Colors.black54,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Container(
                                            color: const Color(0xFFB8DECA),
                                            padding: EdgeInsets.symmetric(
                                              vertical: ResponsiveHelper.h(context, 10),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Score',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:   ResponsiveHelper.sp(context, 11),
                                                  color:      Colors.black54,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(height: 1, color: Colors.grey.shade300),

                                  // scrollable data rows
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Row(
                                            children: [
                                              Expanded(flex: 3, child: Container(color: Colors.white)),
                                              Expanded(flex: 1, child: Container(color: const Color(0xFFC7D4EE))),
                                              Expanded(flex: 1, child: Container(color: const Color(0xFFCFE9DB))),
                                            ],
                                          ),
                                        ),
                                        ListView.separated(
                                          padding: EdgeInsets.zero,
                                          itemCount: marksTableList.length,
                                          separatorBuilder: (_, __) =>
                                              Divider(height: 1, color: Colors.grey.shade200),
                                          itemBuilder: (context, index) =>
                                              MarksListContainerItems1(
                                                marksTable1: marksTableList[index],
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── DOWNLOAD BUTTON ─────────────────────
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet
                                  ? screenWidth * 0.2
                                  : ResponsiveHelper.w(context, 60),
                              vertical: ResponsiveHelper.h(context, 10),
                            ),
                            child: InkWell(
                              onTap: () => debugPrint("Download PDF clicked"),
                              child: Container(
                                height: ResponsiveHelper.h(context, 48),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xff4A90E2), Color(0xff6FD3F7)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "DOWNLOAD PDF",
                                        style: TextStyle(
                                          color:      Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize:   ResponsiveHelper.sp(context, 11),
                                        ),
                                      ),
                                      Image.asset(
                                        'assets/images/acrobat_icon_transparent.png',
                                        height: ResponsiveHelper.h(context, 26),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: bottomInset),
                              child: Image.asset(
                                'assets/images/Blue science and education collection footer.png',
                                width:  double.infinity,
                                fit:    BoxFit.fill, // stretches to fill whatever height Expanded gives
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── 3. FLOATING GRADE CIRCLE ─────────────────────────
            Positioned(
              top:   whiteTopOffset - circleBelowHeader,
              left:  0,
              right: 0,
              child: Center(child: _buildGradeCircle(circleSize)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeCircle(double circleSize) {
    final double innerSize = circleSize * 0.8;
    return Container(
      width:  circleSize,
      height: circleSize,
      decoration: BoxDecoration(
        shape:     BoxShape.circle,
        color:     const Color(0xFFCFE9DB),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: Center(
        child: Container(
          width:  innerSize,
          height: innerSize,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "85%",
                style: TextStyle(
                  fontSize:   ResponsiveHelper.sp(context, 22),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "GRADE A",
                style: TextStyle(
                  fontSize:   ResponsiveHelper.sp(context, 9),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _ExamSelector extends StatelessWidget {
  final List<String> exams;
  final String selected;
  final ValueChanged<String> onChanged;
  const _ExamSelector({required this.exams, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.w(context, 15),
        vertical:   ResponsiveHelper.h(context, 6),
      ),
      child: Container(
        decoration: BoxDecoration(
          color:        const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: Colors.grey.shade300, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded:  true,
            isDense:     true,
            value:       selected.isEmpty ? null : selected,
            hint:        const Text('Select Exam',style: TextStyle(fontSize: 12),),
            icon:        const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            borderRadius: BorderRadius.circular(12),
            items: exams.map((exam) => DropdownMenuItem(
              value: exam,
              child: Text(exam, style: const TextStyle(fontSize: 13)),
            )).toList(),
            onChanged: (val) { if (val != null) onChanged(val); },
          ),
        ),
      ),
    );
  }
}

// ── ITEM WIDGET ───────────────────────────────────────────────────
class MarksListContainerItems1 extends StatelessWidget {
  final MarksTable marksTable1;
  const MarksListContainerItems1({super.key, required this.marksTable1});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.w(context, 16),
                vertical:   ResponsiveHelper.h(context, 12),
              ),
              child: Text(
                marksTable1.subjectName,
                style: TextStyle(fontSize: ResponsiveHelper.sp(context, 11)),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveHelper.h(context, 12),
                ),
                child: Text(
                  '${marksTable1.outOfMarks}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize:   ResponsiveHelper.sp(context, 11),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveHelper.h(context, 12),
                ),
                child: Text(
                  '${marksTable1.scoredMarks}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize:   ResponsiveHelper.sp(context, 11),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── DATA MODELS ───────────────────────────────────────────────────
class MarksTable {
  final String subjectName;
  final int    outOfMarks;
  final int    scoredMarks;
  final String grade;
  const MarksTable({
    required this.subjectName,
    required this.outOfMarks,
    required this.scoredMarks,
    required this.grade,
  });
}

class MarksListStrings {
  final String subjectName;
  final String outOfMarks;
  final String scoredMarks;
  final String grade;

  const MarksListStrings({
    required this.subjectName,
    required this.outOfMarks,
    required this.scoredMarks,
    required this.grade,
  });

  factory MarksListStrings.fromJson(Map<String, dynamic> json) {
    return MarksListStrings(
      subjectName: json['subject']?.toString()       ?? "Unknown",
      outOfMarks:  json['maxMarks']?.toString()      ?? "0",
      scoredMarks: json['marksObtained']?.toString() ?? "0",
      grade:       json['grade']?.toString()         ?? "-",
    );
  }
}
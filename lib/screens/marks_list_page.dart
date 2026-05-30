import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../core/utils/responsive_helper.dart';

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

  // ── FIX 4: real data replaces hardcoded marksTableList ──
  List<MarksTable> _marksTableList = [];

  // ── FIX 3: top-level metadata from API ──
  String _studentName = '';
  String _overallGrade = '';
  String _overallPercent = '';
  String _remarks = '';

  final session = Get.find<UserSession>();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await getMarkReport();
    if (mounted) setState(() {});
  }

  // ── FIX 1: parse data.subjects[], handle single-object response ──
  Future<void> getMarkReport() async {
    try {
      final String baseUrl = ApiConstants.baseUrl;
      final controller = Get.find<MyChildrenController>();
      final String? token = session.token;
      final schoolId = session.schoolId;
      final String studentId = controller.selectedChild['_id'] ?? '';

      final Map<String, String> queryParameters = {
        "schoolId": "$schoolId",
        "academicYear": "2025-2026",
        "studentId": studentId,
        if (_selectedExam.isNotEmpty) "examType": _selectedExam,
      };

      final uri = Uri.parse('$baseUrl/api/markreport/v1/v1/get/student/$studentId')
          .replace(queryParameters: queryParameters);

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        print("👍 RAW RESPONSE: ${response.body}");
        final dynamic decoded = jsonDecode(response.body);

        // API returns { ok, data: { subjects: [...], studentId, remarks, ... } }
        // or data could be a list of such objects
        final dynamic rawData =
        decoded is Map ? decoded['data'] : decoded;

        Map<String, dynamic>? record;
        List<dynamic> subjects = [];

        if (rawData is Map<String, dynamic>) {
          // Single record
          record = rawData;
          subjects = rawData['subjects'] ?? [];
        } else if (rawData is List && rawData.isNotEmpty) {
          // Multiple records — pick the one matching selected exam or first
          record = (rawData.firstWhere(
                (r) =>
            _selectedExam.isEmpty ||
                (r['examType']?.toString() ?? '') == _selectedExam,
            orElse: () => rawData.first,
          )) as Map<String, dynamic>;
          subjects = record['subjects'] ?? [];

          // Build exam filter list from all records
          final exams = rawData
              .map((r) => r['examType']?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList()
              .cast<String>();
          if (mounted) setState(() => _examList = exams);
        }

        if (record != null) {
          // Compute overall percentage & grade from subjects
          int totalScored = 0;
          int totalMax = 0;
          for (final s in subjects) {
            totalScored += (s['marksObtained'] as num?)?.toInt() ?? 0;
            totalMax += (s['maxMarks'] as num?)?.toInt() ?? 0;
          }
          final double pct =
          totalMax > 0 ? (totalScored / totalMax * 100) : 0;
          final String grade = _computeGrade(pct);

          final List<MarksTable> rows = (subjects as List)
              .map((s) => MarksTable(
            subjectName: s['subject']?.toString() ?? 'Unknown',
            outOfMarks: (s['maxMarks'] as num?)?.toInt() ?? 0,
            scoredMarks:
            (s['marksObtained'] as num?)?.toInt() ?? 0,
            grade: s['grade']?.toString() ?? '-',
          ))
              .toList();

          if (mounted) {
            setState(() {
              _marksTableList = rows;
              _overallPercent = '${pct.toStringAsFixed(0)}%';
              _overallGrade = 'GRADE $grade';
              _remarks = record!['remarks']?.toString() ?? '';
              // Student name comes from MyChildrenController
              _studentName = controller.selectedChild['name']?.toString() ??
                  controller.selectedChild['studentName']?.toString() ??
                  '';
            });
          }
        }
      } else {
        debugPrint("MarksReport Error: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      debugPrint("MarksList Error: $e");
    }
  }

  String _computeGrade(double pct) {
    if (pct >= 90) return 'A+';
    if (pct >= 75) return 'A';
    if (pct >= 60) return 'B';
    if (pct >= 50) return 'C';
    if (pct >= 35) return 'D';
    return 'F';
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isTablet = ResponsiveHelper.isTablet(context);
    final bool isSmall = ResponsiveHelper.isSmallHeight(context);
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;

    final double headerHeight =
    isTablet ? screenHeight * 0.16 : screenHeight * 0.22;
    final double circleSize = isTablet
        ? screenWidth * 0.14
        : ResponsiveHelper.w(context, 110);
    final double circleBelowHeader = circleSize * 0.55;
    final double whiteTopOffset = headerHeight - (circleSize * 0.45);
    final double whiteHeight = screenHeight - whiteTopOffset;
    final double tableHeight = whiteHeight * (isTablet ? 0.45 : 0.40);
    final double footerHeight = isTablet
        ? screenHeight * 0.16
        : isSmall
        ? screenHeight * 0.11
        : screenHeight * 0.13;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ── 1. HEADER IMAGE ───────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/Scientific UI background design header.png',
                height: headerHeight,
                fit: BoxFit.fill,
              ),
            ),

            // ── 2. MAIN CONTENT ───────────────────────────────────
            SafeArea(
              top: false,
              bottom: false,
              child: Column(
                children: [
                  SizedBox(height: whiteTopOffset),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          SizedBox(height: circleBelowHeader),

                          // ── FIX 3: show real name & remarks ──
                          Text(
                            _remarks.isNotEmpty
                                ? _remarks
                                : 'Keep it up!',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.sp(context, 12),
                            ),
                          ),
                          Text(
                            _studentName.isNotEmpty
                                ? '${_studentName.toUpperCase()} !!'
                                : '',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.sp(context, 18),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ResponsiveHelper.vSpace(context, 8),

                          if (_examList.isNotEmpty)
                            _ExamSelector(
                              exams: _examList,
                              selected: _selectedExam,
                              onChanged: (val) {
                                setState(() => _selectedExam = val);
                                _initializeData();
                              },
                            ),

                          // ── MARKS TABLE ─────────────────────────
                          Container(
                            height: tableHeight,
                            margin: EdgeInsets.symmetric(
                              horizontal: ResponsiveHelper.w(context, 15),
                              vertical: ResponsiveHelper.h(context, 8),
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.grey.shade300, width: 1.5),
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
                                              vertical: ResponsiveHelper.h(
                                                  context, 10),
                                              horizontal: ResponsiveHelper.w(
                                                  context, 16),
                                            ),
                                            child: Text(
                                              'Subject',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                ResponsiveHelper.sp(
                                                    context, 11),
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Container(
                                            color: const Color(0xFFB8C8E8),
                                            padding: EdgeInsets.symmetric(
                                              vertical: ResponsiveHelper.h(
                                                  context, 10),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Out of',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:
                                                  ResponsiveHelper.sp(
                                                      context, 11),
                                                  color: Colors.black54,
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
                                              vertical: ResponsiveHelper.h(
                                                  context, 10),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Score',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:
                                                  ResponsiveHelper.sp(
                                                      context, 11),
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                      height: 1,
                                      color: Colors.grey.shade300),

                                  // ── FIX 4: real rows from API ──
                                  Expanded(
                                    child: _marksTableList.isEmpty
                                        ? const Center(
                                        child:
                                        CircularProgressIndicator())
                                        : Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Row(
                                            children: [
                                              Expanded(
                                                  flex: 3,
                                                  child: Container(
                                                      color: Colors
                                                          .white)),
                                              Expanded(
                                                  flex: 1,
                                                  child: Container(
                                                      color: const Color(
                                                          0xFFC7D4EE))),
                                              Expanded(
                                                  flex: 1,
                                                  child: Container(
                                                      color: const Color(
                                                          0xFFCFE9DB))),
                                            ],
                                          ),
                                        ),
                                        ListView.separated(
                                          padding: EdgeInsets.zero,
                                          itemCount:
                                          _marksTableList.length,
                                          separatorBuilder: (_, __) =>
                                              Divider(
                                                  height: 1,
                                                  color: Colors
                                                      .grey.shade200),
                                          itemBuilder:
                                              (context, index) =>
                                              MarksListContainerItems1(
                                                marksTable1:
                                                _marksTableList[
                                                index],
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── DOWNLOAD BUTTON ──────────────────────
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet
                                  ? screenWidth * 0.2
                                  : ResponsiveHelper.w(context, 60),
                              vertical: ResponsiveHelper.h(context, 10),
                            ),
                            child: InkWell(
                              onTap: () =>
                                  debugPrint("Download PDF clicked"),
                              child: Container(
                                height: ResponsiveHelper.h(context, 48),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xff4A90E2),
                                      Color(0xff6FD3F7)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "DOWNLOAD PDF",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: ResponsiveHelper.sp(
                                              context, 11),
                                        ),
                                      ),
                                      Image.asset(
                                        'assets/images/acrobat_icon_transparent.png',
                                        height:
                                        ResponsiveHelper.h(context, 26),
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
                                width: double.infinity,
                                fit: BoxFit.fill,
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

            // ── 3. FLOATING GRADE CIRCLE ──────────────────────────
            Positioned(
              top: whiteTopOffset - circleBelowHeader,
              left: 0,
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
      width: circleSize,
      height: circleSize,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFCFE9DB),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: Center(
        child: Container(
          width: innerSize,
          height: innerSize,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          // ── FIX 3: show real percent & grade ──
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _overallPercent.isNotEmpty ? _overallPercent : '—',
                style: TextStyle(
                  fontSize: ResponsiveHelper.sp(context, 22),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _overallGrade.isNotEmpty ? _overallGrade : '',
                style: TextStyle(
                  fontSize: ResponsiveHelper.sp(context, 9),
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

// ── EXAM SELECTOR ─────────────────────────────────────────────────
class _ExamSelector extends StatelessWidget {
  final List<String> exams;
  final String selected;
  final ValueChanged<String> onChanged;
  const _ExamSelector(
      {required this.exams,
        required this.selected,
        required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.w(context, 15),
        vertical: ResponsiveHelper.h(context, 6),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            isDense: true,
            value: selected.isEmpty ? null : selected,
            hint: const Text('Select Exam',
                style: TextStyle(fontSize: 12)),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            borderRadius: BorderRadius.circular(12),
            items: exams
                .map((exam) => DropdownMenuItem(
              value: exam,
              child:
              Text(exam, style: const TextStyle(fontSize: 13)),
            ))
                .toList(),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ),
      ),
    );
  }
}

// ── ITEM WIDGET ───────────────────────────────────────────────────
class MarksListContainerItems1 extends StatelessWidget {
  final MarksTable marksTable1;
  const MarksListContainerItems1(
      {super.key, required this.marksTable1});

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
                vertical: ResponsiveHelper.h(context, 12),
              ),
              child: Text(
                marksTable1.subjectName,
                style:
                TextStyle(fontSize: ResponsiveHelper.sp(context, 11)),
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
                    fontSize: ResponsiveHelper.sp(context, 11),
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
                    fontSize: ResponsiveHelper.sp(context, 11),
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

// ── DATA MODEL ────────────────────────────────────────────────────
class MarksTable {
  final String subjectName;
  final int outOfMarks;
  final int scoredMarks;
  final String grade;

  const MarksTable({
    required this.subjectName,
    required this.outOfMarks,
    required this.scoredMarks,
    required this.grade,
  });

  // ── FIX 2: field names already match API (subject / marksObtained / maxMarks) ──
  factory MarksTable.fromJson(Map<String, dynamic> json) {
    return MarksTable(
      subjectName: json['subject']?.toString() ?? 'Unknown',
      outOfMarks: (json['maxMarks'] as num?)?.toInt() ?? 0,
      scoredMarks: (json['marksObtained'] as num?)?.toInt() ?? 0,
      grade: json['grade']?.toString() ?? '-',
    );
  }
}
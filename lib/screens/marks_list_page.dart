import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/core/utils/academic_year_utils.dart';
import '../core/utils/responsive_helper.dart';

import '../controllers/my_children_controller.dart';
import '../constants/api_constants.dart';
import '../services/user_session.dart';
import 'package:school_app/controllers/school_controller.dart';

// =============================================================================
// DATA MODELS — mirror the Mongoose schema exactly
// =============================================================================

/// Mirrors subjectSchema
class SubjectRecord {
  final String subject;
  final int marksObtained;
  final int maxMarks;
  final int minPassingMarks; // schema field name
  final String grade;

  const SubjectRecord({
    required this.subject,
    required this.marksObtained,
    required this.maxMarks,
    required this.minPassingMarks,
    required this.grade,
  });

  factory SubjectRecord.fromJson(Map<String, dynamic> j) {
    final int max = (j['maxMarks'] as num?)?.toInt() ?? 100;
    return SubjectRecord(
      subject:         j['subject']?.toString() ?? 'Unknown',
      marksObtained:   (j['marksObtained'] as num?)?.toInt() ?? 0,
      maxMarks:        max,
      // schema default is 35; fall back to 35 % of maxMarks if missing
      minPassingMarks: (j['minPassingMarks'] as num?)?.toInt() ??
          (max * 0.35).ceil(),
      grade:           j['grade']?.toString() ?? '-',
    );
  }

  bool get passed => marksObtained >= minPassingMarks;
}

/// Mirrors examRecordSchema
class ExamRecord {
  final String examName;
  final List<SubjectRecord> subjects;
  final String remarks;
  final bool isAbsent;

  const ExamRecord({
    required this.examName,
    required this.subjects,
    required this.remarks,
    required this.isAbsent,
  });

  factory ExamRecord.fromJson(Map<String, dynamic> j) => ExamRecord(
    examName: j['examName']?.toString() ?? '',
    subjects: ((j['subjects'] as List?) ?? [])
        .map((s) => SubjectRecord.fromJson(s as Map<String, dynamic>))
        .toList(),
    remarks:  j['remarks']?.toString() ?? '',
    isAbsent: j['isAbsent'] as bool? ?? false,
  );

  /// Overall percentage across all subjects in this exam
  double get percentage {
    if (subjects.isEmpty) return 0;
    final scored = subjects.fold(0, (s, r) => s + r.marksObtained);
    final max    = subjects.fold(0, (s, r) => s + r.maxMarks);
    return max > 0 ? scored / max * 100 : 0;
  }
}

/// Mirrors markReportSchema (one document per student)
class MarkReport {
  final List<SubjectRecord> subjects;      // top-level subjects (legacy)
  final List<ExamRecord>    examRecords;   // per-exam breakdown
  final String remarks;
  final bool isAbsent;

  const MarkReport({
    required this.subjects,
    required this.examRecords,
    required this.remarks,
    required this.isAbsent,
  });

  factory MarkReport.fromJson(Map<String, dynamic> j) => MarkReport(
    subjects: ((j['subjects'] as List?) ?? [])
        .map((s) => SubjectRecord.fromJson(s as Map<String, dynamic>))
        .toList(),
    examRecords: ((j['examRecords'] as List?) ?? [])
        .map((e) => ExamRecord.fromJson(e as Map<String, dynamic>))
        .toList(),
    remarks:  j['remarks']?.toString() ?? '',
    isAbsent: j['isAbsent'] as bool? ?? false,
  );
}

// =============================================================================
// WIDGET
// =============================================================================

class MarksList extends StatefulWidget {
  const MarksList({super.key});

  @override
  State<MarksList> createState() => _MarksListState();
}

class _MarksListState extends State<MarksList> {
  // ── State ─────────────────────────────────────────────────────────────────
  MarkReport? _report;
  String      _selectedExam = ''; // '' = show top-level subjects
  bool        _loading = true;

  String _studentName = '';

  //final _session = Get.find<UserSession>();
 final auth_ctrl = Get.find<AuthController>();
  // ── Derived from selected exam ─────────────────────────────────────────────

  /// The subjects to show in the table — either from a specific examRecord
  /// or from the top-level subjects array.
  List<SubjectRecord> get _activeSubjects {
    if (_selectedExam.isNotEmpty && _report != null) {
      final exam = _report!.examRecords
          .where((e) => e.examName == _selectedExam)
          .firstOrNull;
      if (exam != null) return exam.subjects;
    }
    return _report?.subjects ?? [];
  }

  /// Remarks for the currently selected view
  String get _activeRemarks {
    if (_selectedExam.isNotEmpty && _report != null) {
      final exam = _report!.examRecords
          .where((e) => e.examName == _selectedExam)
          .firstOrNull;
      if (exam != null && exam.remarks.isNotEmpty) return exam.remarks;
    }
    return _report?.remarks ?? '';
  }

  double get _overallPct {
    final subs = _activeSubjects;
    if (subs.isEmpty) return 0;
    final scored = subs.fold(0, (s, r) => s + r.marksObtained);
    final max    = subs.fold(0, (s, r) => s + r.maxMarks);
    return max > 0 ? scored / max * 100 : 0;
  }

  String _gradeLabel(double pct) {
    if (pct >= 90) return 'A+';
    if (pct >= 75) return 'A';
    if (pct >= 60) return 'B';
    if (pct >= 50) return 'C';
    if (pct >= 35) return 'D';
    return 'F';
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }
  Future<String> _resolveAcademicYear() async {
    final schoolController = Get.find<SchoolController>();

    // If we don't have a school loaded yet, try to load it.
    // For non-correspondent roles this internally calls _loadUserSchool(),
    // which fetches the user's own school by their schoolId.
    if (schoolController.selectedSchool.value == null) {
      await schoolController.getAllSchools();
    }

    final year = schoolController.selectedSchool.value?.currentAcademicYear;
    if (year != null && year.trim().isNotEmpty) {
      return year;
    }

    // Fallback only — shouldn't normally be hit.
    final now = DateTime.now();
    final startYear = now.month >= 6 ? now.year : now.year - 1;
    return '$startYear-${startYear + 1}';
  }
  Future<void> _fetchReport() async {
    if (mounted) setState(() => _loading = true);
    try {
      final baseUrl    = ApiConstants.baseUrl;
      final controller = Get.find<MyChildrenController>();
      final token      = auth_ctrl.storage.read('token');
      final schoolId   = auth_ctrl.user.value?.schoolId;
      final studentId  = controller.selectedChild['_id']?.toString() ?? '';
      if (studentId.isEmpty) {
        debugPrint('❌ studentId is empty — cannot fetch marks');
        if (mounted) setState(() => _loading = false);
        return;
      }
      _studentName =
          controller.selectedChild['name']?.toString() ??
              controller.selectedChild['studentName']?.toString() ??
              '';
      final academicYear = AcademicYearUtils.getCurrentAcademicYear();

      final uri = Uri.parse(
        '$baseUrl/api/markreport/v1/get/student/$studentId',
      ).replace(queryParameters: {
        'schoolId':     '$schoolId',
        'academicYear': academicYear,
        'studentId':    studentId,
      });

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      debugPrint('👍 MarksReport ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('👍 MarksReport ${response.statusCode}: ${response.body}');
        final decoded  = jsonDecode(response.body);
        debugPrint('DECODED TYPE: ${decoded.runtimeType}');
        debugPrint('DECODED: $decoded');

        debugPrint('studentId: $studentId');
        debugPrint('URL: $uri');
        debugPrint('Status: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
        // API returns { ok, data: <markReportDoc or list> }
        final rawData  = decoded is Map ? decoded['data'] : decoded;

        Map<String, dynamic>? doc;
        if (rawData is Map<String, dynamic>) {
          doc = rawData;
        } else if (rawData is List && rawData.isNotEmpty) {
          doc = rawData.first as Map<String, dynamic>;
        }

        if (doc != null && mounted) {
          final report = MarkReport.fromJson(doc);
          // Auto-select first examRecord if top-level subjects are empty
          String defaultExam = '';
          if (report.examRecords.isNotEmpty) {
            defaultExam = report.examRecords.first.examName;
          }
          setState(() {
            _report       = report;
            _selectedExam = defaultExam;
          });
        }
      }
    } catch (e) {
      debugPrint('MarksList Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double screenHeight  = MediaQuery.sizeOf(context).height;
    final double screenWidth   = MediaQuery.sizeOf(context).width;
    final bool   isTablet      = ResponsiveHelper.isTablet(context);
    final bool   isSmall       = ResponsiveHelper.isSmallHeight(context);
    final double bottomInset   = MediaQuery.of(context).viewPadding.bottom;

    final double headerHeight     = isTablet ? screenHeight * 0.16 : screenHeight * 0.22;
    final double circleSize       = isTablet ? screenWidth * 0.14 : ResponsiveHelper.w(context, 110);
    final double circleBelowHeader = circleSize * 0.55;
    final double whiteTopOffset   = headerHeight - (circleSize * 0.45);
    final double whiteHeight      = screenHeight - whiteTopOffset;
    final double tableHeight      = whiteHeight * (isTablet ? 0.45 : 0.40);

    final pct   = _overallPct;
    final grade = _gradeLabel(pct);

    // Exam names for the selector — from examRecords
    final examNames = _report?.examRecords.map((e) => e.examName).toList() ?? [];

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
            // ── Header image ─────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: Image.asset(
                'assets/images/Scientific UI background design header.png',
                height: headerHeight,
                fit: BoxFit.fill,
              ),
            ),

            // ── Main content ─────────────────────────────────────
            SafeArea(
              top: false, bottom: false,
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
                      child: Column(
                        children: [
                          SizedBox(height: circleBelowHeader),

                          // Remarks & student name
                          Text(
                            _activeRemarks.isNotEmpty ? _activeRemarks : 'Keep it up!',
                            style: TextStyle(fontSize: ResponsiveHelper.sp(context, 12)),
                          ),
                          if (_studentName.isNotEmpty)
                            Text(
                              '${_studentName.toUpperCase()} !!',
                              style: TextStyle(
                                fontSize:   ResponsiveHelper.sp(context, 18),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ResponsiveHelper.vSpace(context, 8),

                          // Exam selector (only shown when examRecords exist)
                          if (examNames.isNotEmpty)
                            _ExamSelector(
                              exams:    examNames,
                              selected: _selectedExam,
                              onChanged: (val) =>
                                  setState(() => _selectedExam = val),
                            ),

                          // ── Marks table ─────────────────────────
                          Container(
                            height: tableHeight,
                            margin: EdgeInsets.symmetric(
                              horizontal: ResponsiveHelper.w(context, 15),
                              vertical:   ResponsiveHelper.h(context, 8),
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
                                  // Header row
                                  IntrinsicHeight(
                                    child: Row(children: [
                                      _HeaderCell(label: 'Subject', flex: 3,
                                          color: const Color(0xFFEEF3FA), align: Alignment.centerLeft,
                                          padding: EdgeInsets.symmetric(
                                            vertical:   ResponsiveHelper.h(context, 10),
                                            horizontal: ResponsiveHelper.w(context, 16),
                                          )),
                                      _HeaderCell(label: 'Out of', flex: 1,
                                          color: const Color(0xFFB8C8E8)),
                                      _HeaderCell(label: 'Pass',   flex: 1,
                                          color: const Color(0xFFFFE0B2)),
                                      _HeaderCell(label: 'Score',  flex: 1,
                                          color: const Color(0xFFB8DECA)),
                                    ]),
                                  ),
                                  Container(height: 1, color: Colors.grey.shade300),

                                  // Data rows
                                  Expanded(
                                    child: _loading
                                        ? const Center(child: CircularProgressIndicator())
                                        : _activeSubjects.isEmpty
                                        ? Center(
                                      child: Text('No marks available',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: ResponsiveHelper.sp(context, 13),
                                          )),
                                    )
                                        : Stack(children: [
                                      // Column background tints
                                      Positioned.fill(
                                        child: Row(children: [
                                          Expanded(flex: 3, child: Container(color: Colors.white)),
                                          Expanded(flex: 1, child: Container(color: const Color(0xFFC7D4EE))),
                                          Expanded(flex: 1, child: Container(color: const Color(0xFFFFECCC))),
                                          Expanded(flex: 1, child: Container(color: const Color(0xFFCFE9DB))),
                                        ]),
                                      ),
                                      ListView.separated(
                                        padding: EdgeInsets.zero,
                                        itemCount: _activeSubjects.length,
                                        separatorBuilder: (_, __) =>
                                            Divider(height: 1, color: Colors.grey.shade200),
                                        itemBuilder: (ctx, i) =>
                                            _SubjectRow(subject: _activeSubjects[i]),
                                      ),
                                    ]),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Download button
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet
                                  ? screenWidth * 0.2
                                  : ResponsiveHelper.w(context, 60),
                              vertical: ResponsiveHelper.h(context, 10),
                            ),
                            child: InkWell(
                              onTap: () => debugPrint('Download PDF clicked'),
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
                                        'DOWNLOAD PDF',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: ResponsiveHelper.sp(context, 11),
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

            // ── Floating grade circle ─────────────────────────────
            Positioned(
              top:   whiteTopOffset - circleBelowHeader,
              left:  0,
              right: 0,
              child: Center(child: _buildGradeCircle(circleSize, pct, grade)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeCircle(double circleSize, double pct, String grade) {
    final double innerSize = circleSize * 0.8;
    return Container(
      width: circleSize, height: circleSize,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFCFE9DB),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Center(
        child: Container(
          width: innerSize, height: innerSize,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize:   ResponsiveHelper.sp(context, 22),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'GRADE $grade',
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

// =============================================================================
// SMALL REUSABLE WIDGETS
// =============================================================================

class _HeaderCell extends StatelessWidget {
  final String     label;
  final int        flex;
  final Color      color;
  final Alignment  align;
  final EdgeInsets? padding;

  const _HeaderCell({
    required this.label,
    required this.flex,
    required this.color,
    this.align   = Alignment.center,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        color:   color,
        padding: padding ??
            EdgeInsets.symmetric(vertical: ResponsiveHelper.h(context, 10)),
        alignment: align,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize:   ResponsiveHelper.sp(context, 11),
            color:      Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  final SubjectRecord subject;
  const _SubjectRow({required this.subject});

  @override
  Widget build(BuildContext context) {
    final bool passed = subject.passed;

    return IntrinsicHeight(
      child: Row(children: [
        // Subject name
        Expanded(
          flex: 3,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.w(context, 16),
              vertical:   ResponsiveHelper.h(context, 12),
            ),
            child: Text(
              subject.subject,
              style: TextStyle(fontSize: ResponsiveHelper.sp(context, 11)),
            ),
          ),
        ),
        // Out of (maxMarks)
        Expanded(
          flex: 1,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.h(context, 12)),
              child: Text(
                '${subject.maxMarks}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize:   ResponsiveHelper.sp(context, 11),
                ),
              ),
            ),
          ),
        ),
        // Pass (minPassingMarks)
        Expanded(
          flex: 1,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.h(context, 12)),
              child: Text(
                '${subject.minPassingMarks}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize:   ResponsiveHelper.sp(context, 11),
                  color:      const Color(0xFFE65100), // deep amber
                ),
              ),
            ),
          ),
        ),
        // Score (marksObtained) — green if passed, red if failed
        Expanded(
          flex: 1,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.h(context, 12)),
              child: Text(
                '${subject.marksObtained}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize:   ResponsiveHelper.sp(context, 11),
                  color: passed
                      ? const Color(0xFF2E7D32)  // green
                      : const Color(0xFFC62828), // red
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// =============================================================================
// EXAM SELECTOR
// =============================================================================

class _ExamSelector extends StatelessWidget {
  final List<String>      exams;
  final String            selected;
  final ValueChanged<String> onChanged;

  const _ExamSelector({
    required this.exams,
    required this.selected,
    required this.onChanged,
  });

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
            isExpanded:   true,
            isDense:      true,
            value:        selected.isEmpty ? null : selected,
            hint:         const Text('All Exams', style: TextStyle(fontSize: 12)),
            icon:         const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            borderRadius: BorderRadius.circular(12),
            items: exams
                .map((e) => DropdownMenuItem(
              value: e,
              child: Text(e, style: const TextStyle(fontSize: 13)),
            ))
                .toList(),
            onChanged: (val) { if (val != null) onChanged(val); },
          ),
        ),
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:school_app/controllers/auth_controller.dart';
import '../constants/api_constants.dart';
import '../core/utils/academic_year_utils.dart';
import '../services/user_session.dart';
import '../controllers/school_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

class StudentAttendanceItem {
  final String id;
  final String name;
  final String rollNumber;
  String status; // 'present' | 'absent' | 'leave'
  String remark;

  StudentAttendanceItem({
    required this.id,
    required this.name,
    required this.rollNumber,
    this.status = 'present',
    this.remark='',
  });

  factory StudentAttendanceItem.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceItem(
      id: json['_id'] ?? '',
      name: json['studentName'] ?? json['name'] ?? 'Unknown',
      rollNumber: json['rollNumber']?.toString() ?? '',
    );
  }
}

class CalendarEvent {
  final String? id;
  final String name;
  final DateTime fromDate;
  final DateTime toDate;
  final String type; // 'holiday' | 'leave' | 'exam'
  final String? description;
  final String academicYear;

  CalendarEvent({
    this.id,
    required this.name,
    required this.fromDate,
    required this.toDate,
    required this.type,
    this.description,
    required this.academicYear,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['_id'],
      name: json['title'] ?? json['name'] ?? '',
      fromDate: DateTime.parse(json['startDate'] ?? json['fromDate'] ?? json['date']),
      toDate: DateTime.parse(json['endDate'] ?? json['toDate'] ?? json['date']),
      type: json['type'] ?? 'holiday',
      description: json['description'],
      academicYear: json['academicYear'] ?? AcademicYearUtils.getCurrentAcademicYear(),
    );
  }

  /// Body for CREATE (114). schoolId is added by the caller.
  Map<String, dynamic> toCreateJson() => {
    'title': name,
    'startDate': fromDate.toIso8601String(),
    'endDate': toDate.toIso8601String(),
    'type': type,
    if (description != null) 'description': description,
    if (academicYear.isNotEmpty) 'academicYear': academicYear,
  };

  /// Body for UPDATE (115). id goes in the URL, not the body.
  Map<String, dynamic> toUpdateJson() => {
    'title': name,
    'startDate': fromDate.toIso8601String(),
    'endDate': toDate.toIso8601String(),
    'type': type,
    if (description != null) 'description': description,
    if (academicYear.isNotEmpty) 'academicYear': academicYear,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// VIEW
// ─────────────────────────────────────────────────────────────────────────────

class AdminAttendanceView extends StatefulWidget {
  const AdminAttendanceView({super.key});

  @override
  State<AdminAttendanceView> createState() => _AdminAttendanceViewState();
}

class _AdminAttendanceViewState extends State<AdminAttendanceView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  //final session = Get.find<UserSession>();
  final _AuthCtrl = Get.find<AuthController>();

  // ── Attendance state ────────────────────────────────────────────────────────
  String? _selectedClassId;
  String? _selectedSectionId;
  String _selectedYear = AcademicYearUtils.getCurrentAcademicYear();
  DateTime _selectedDate = DateTime.now();
  bool _loadingStudents = false;
  bool _submitting = false;
  List<StudentAttendanceItem> _students = [];

  // class/section lists from SchoolController
  List<Map<String, String>> _classes = [];
  List<Map<String, String>> _sections = [];

  // ── Holiday calendar state ──────────────────────────────────────────────────
  bool _loadingEvents = false;
  bool _savingEvent = false;
  List<CalendarEvent> _events = [];
  final _eventNameCtrl = TextEditingController();
  final _eventDescCtrl = TextEditingController();
  DateTime _eventFrom = DateTime.now();
  DateTime _eventTo = DateTime.now();
  String _eventType = 'holiday';
  String _eventYear = AcademicYearUtils.getCurrentAcademicYear();
  String? _editingEventId;

  static final _years = AcademicYearUtils.getRecentAcademicYears(3);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClassesFromController();
    _loadCalendarEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _eventNameCtrl.dispose();
    _eventDescCtrl.dispose();
    super.dispose();
  }

  // ── Load classes from SchoolController ──────────────────────────────────────

  void _loadClassesFromController() {
    try {
      final sc = Get.find<SchoolController>();
      final schoolId = sc.selectedSchool.value?.id;
      if (schoolId != null) sc.getAllClasses(schoolId);

      ever(sc.classes, (list) {
        if (!mounted) return;
        setState(() {
          _classes = list
              .map((c) => {'id': c.id, 'name': c.name})
              .toList();
        });
      });

      if (sc.classes.isNotEmpty) {
        setState(() {
          _classes = sc.classes
              .map((c) => {'id': c.id, 'name': c.name})
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSections(String classId) async {
    try {
      final sc = Get.find<SchoolController>();
      await sc.getAllSections(classId: classId);
      if (!mounted) return;
      setState(() {
        _sections = sc.sections
            .map((s) => {'id': s.id, 'name': s.name})
            .toList();
        _selectedSectionId = null;
      });
    } catch (_) {}
  }

  // ── Load students ────────────────────────────────────────────────────────────

  Future<void> _loadStudents() async {
    if (_selectedClassId == null || _selectedSectionId == null) {
      Get.snackbar('Error', 'Please select class and section',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    setState(() => _loadingStudents = true);
    try {
      final sc = Get.find<SchoolController>();
      await sc.getAllStudents(
        schoolId: sc.selectedSchool.value?.id,
        classId: _selectedClassId,
        sectionId: _selectedSectionId,
      );
      if (!mounted) return;
      setState(() {
        _students = sc.students
            .map((s) => StudentAttendanceItem(
          id: s.id ?? '',
          name: s.studentName ?? s.name ?? 'Unknown',
          rollNumber: s.rollNumber?.toString() ?? '',
        ))
            .toList();
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to load students',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _loadingStudents = false);
    }
  }

  // ── Submit attendance ────────────────────────────────────────────────────────

  Future<void> _submitAttendance() async {
    if (_students.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final sc = Get.find<SchoolController>();

      print('selectedSchool: ${sc.selectedSchool.value}');
      String schoolId = '';
      try {
        schoolId = sc.selectedSchool.value?.id ?? _AuthCtrl.user.value?.schoolId ?? '';
      } catch (e) {
        print('schoolId getter threw: $e');
        schoolId = _AuthCtrl.user.value?.schoolId ?? '';
      }
      print('schoolId resolved: $schoolId');

      final token = _AuthCtrl.storage.read('token') ?? '';
      print('token: $token');
      print('classId: $_selectedClassId, sectionId: $_selectedSectionId');

      final records = _students.map((s) {
        print('mapping student id=${s.id} name=${s.name} status=${s.status}');
        return {
          'studentId': s.id,
          'studentName': s.name,
          'status': s.status,
          'remark': s.remark,
        };
      }).toList();

      final uri = Uri.parse('${ApiConstants.baseUrl}/api/attendance/mark'); // fixed endpoint

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'schoolId': schoolId,
          'classId': _selectedClassId,
          'sectionId': _selectedSectionId,
          'academicYear': _selectedYear,
          'date': _selectedDate.toIso8601String().split('T').first,
          'records': records,
        }),
      );

      print('Mark attendance response (${response.statusCode}): ${response.body}'); // temp debug log

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar('Success', 'Attendance submitted successfully',
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        final err = jsonDecode(response.body);
        Get.snackbar('Error', err['message'] ?? 'Submission failed',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      print('Submit attendance exception: $e'); // temp debug log
      Get.snackbar('Error', 'Failed to submit attendance: $e', // include $e temporarily
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _markAll(String status) {
    setState(() {
      for (final s in _students) {
        s.status = status;
      }
    });
  }

  // ── Calendar events ──────────────────────────────────────────────────────────

  Future<void> _loadCalendarEvents() async {
    setState(() => _loadingEvents = true);
    try {
      final sc = Get.find<SchoolController>();
      final schoolId = sc.selectedSchool.value?.id ?? _AuthCtrl.user.value?.schoolId ?? '';
      final token = _AuthCtrl.storage.read('token') ?? '';

      final uri = Uri.parse(
          '${ApiConstants.baseUrl}/api/calendar/getall?schoolId=$schoolId');
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map) {
          list = decoded['data'] ?? [];
        }
        if (!mounted) return;
        setState(() {
          _events =
              list.map((e) => CalendarEvent.fromJson(e)).toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingEvents = false);
    }
  }

  Future<void> _saveCalendarEvent() async {
    if (_eventNameCtrl.text.trim().isEmpty) {
      Get.snackbar('Error', 'Event name is required',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    setState(() => _savingEvent = true);
    try {
      final sc = Get.find<SchoolController>();
      final schoolId = sc.selectedSchool.value?.id ?? _AuthCtrl.user.value?.schoolId ?? '';
      final token = _AuthCtrl.storage.read('token') ?? '';

      final event = CalendarEvent(
        name: _eventNameCtrl.text.trim(),
        fromDate: _eventFrom,
        toDate: _eventTo,
        type: _eventType,
        description: _eventDescCtrl.text.trim().isEmpty
            ? null
            : _eventDescCtrl.text.trim(),
        academicYear: _eventYear,
      );

      http.Response response;

      if (_editingEventId == null) {
        // CREATE — api no 114
        final uri = Uri.parse('${ApiConstants.baseUrl}/api/calendar/create');
        response = await http.post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({...event.toCreateJson(), 'schoolId': schoolId}),
        );
      } else {
        // UPDATE — api no 115
        final uri = Uri.parse('${ApiConstants.baseUrl}/api/calendar/update/$_editingEventId');
        response = await http.put(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(event.toUpdateJson()),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar(
          'Success',
          _editingEventId == null ? 'Event added successfully' : 'Event updated successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _resetEventForm();
        await _loadCalendarEvents();
      } else {
        final err = jsonDecode(response.body);
        Get.snackbar('Error', err['message'] ?? 'Failed to save event',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save event',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _savingEvent = false);
    }
  }

  void _resetEventForm() {
    _eventNameCtrl.clear();
    _eventDescCtrl.clear();
    setState(() {
      _editingEventId = null;
      _eventFrom = DateTime.now();
      _eventTo = DateTime.now();
      _eventType = 'holiday';
      _eventYear = AcademicYearUtils.getCurrentAcademicYear();
    });
  }

  void _startEditEvent(CalendarEvent event) {
    setState(() {
      _editingEventId = event.id;
      _eventNameCtrl.text = event.name;
      _eventDescCtrl.text = event.description ?? '';
      _eventFrom = event.fromDate;
      _eventTo = event.toDate;
      _eventType = event.type;
      _eventYear = event.academicYear;
    });
  }

  Future<void> _deleteEvent(CalendarEvent event) async {
    if (event.id == null) return;
    try {
      final token = _AuthCtrl.storage.read('token') ?? '';
      final uri = Uri.parse(
          '${ApiConstants.baseUrl}/api/calendar/delete/${event.id}');
      final response = await http.delete(uri, headers: {
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        setState(() {
          _events.removeWhere((e) => e.id == event.id);
          if (_editingEventId == event.id) _editingEventId = null;
        });
        Get.snackbar('Deleted', 'Event removed',
            backgroundColor: Colors.blue, colorText: Colors.white);
      }
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attendance & calendar',
                style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Admin panel',
                style:
                TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Attendance'),
            Tab(text: 'Holiday calendar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAttendanceTab(),
          _buildCalendarTab(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ATTENDANCE TAB
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildAttendanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _filterCard(),
          const SizedBox(height: 12),
          if (_loadingStudents)
            const Card(
                child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator())))
          else if (_students.isNotEmpty)
            _attendanceCard(),
        ],
      ),
    );
  }

  Widget _filterCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.filter_list_rounded, 'Select class'),
          Row(
            children: [
              Expanded(
                child: _dropdown(
                  label: 'Class',
                  value: _selectedClassId,
                  items: _classes
                      .map((c) =>
                      DropdownMenuItem(value: c['id'], child: Text(c['name']!)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedClassId = v;
                      _selectedSectionId = null;
                      _sections = [];
                      _students = [];
                    });
                    if (v != null) _loadSections(v);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dropdown(
                  label: 'Section',
                  value: _selectedSectionId,
                  items: _sections
                      .map((s) =>
                      DropdownMenuItem(value: s['id'], child: Text(s['name']!)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedSectionId = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _dropdown(
                  label: 'Academic year',
                  value: _selectedYear,
                  items: _years
                      .map((y) =>
                      DropdownMenuItem(value: y, child: Text(y)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedYear = v!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _datePicker(
                  label: 'Date',
                  date: _selectedDate,
                  onChanged: (d) => setState(() => _selectedDate = d),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loadStudents,
              icon: const Icon(Icons.search_rounded, size: 16),
              label: const Text('Load students',
                  style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2563EB)),
                foregroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceCard() {
    final presentCount = _students.where((s) => s.status == 'present').length;
    final absentCount = _students.where((s) => s.status == 'absent').length;
    final leaveCount = _students.where((s) => s.status == 'leave').length;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.people_rounded, 'Mark attendance'),
          // Summary chips
          Row(
            children: [
              _summaryChip('$presentCount present', Colors.green),
              const SizedBox(width: 8),
              _summaryChip('$absentCount absent', Colors.red),
              const SizedBox(width: 8),
              _summaryChip('$leaveCount leave', Colors.orange),
            ],
          ),
          const SizedBox(height: 10),
          // Bulk actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _markAll('present'),
                  icon: const Icon(Icons.check_rounded, size: 14),
                  label: const Text('All present',
                      style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                    foregroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _markAll('absent'),
                  icon: const Icon(Icons.close_rounded, size: 14),
                  label: const Text('All absent',
                      style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Student list
          ..._students.map((student) => _studentRow(student)),
          const Divider(height: 24),
          // Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submitAttendance,
              icon: _submitting
                  ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cloud_upload_rounded, size: 16),
              label: Text(
                  _submitting ? 'Submitting…' : 'Submit attendance',
                  style: const TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentRow(StudentAttendanceItem student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text('Roll ${student.rollNumber}',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          _statusToggle(student, 'present', 'P', Colors.green),
          const SizedBox(width: 5),
          _statusToggle(student, 'absent', 'A', Colors.red),
          const SizedBox(width: 5),
          _statusToggle(student, 'leave', 'L', Colors.orange),
        ],
      ),
    );
  }

  Widget _statusToggle(StudentAttendanceItem student, String status,
      String label, Color color) {
    final selected = student.status == status;
    return GestureDetector(
      onTap: () => setState(() => student.status = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 1.5 : 0.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: selected ? color : Colors.grey)),
      ),
    );
  }

  Widget _summaryChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.9))),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HOLIDAY CALENDAR TAB
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCalendarTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _statsCard(),
          const SizedBox(height: 12),
          _addEventCard(),
          const SizedBox(height: 12),
          _eventListCard(),
        ],
      ),
    );
  }

  Widget _statsCard() {
    final holidays = _events.where((e) => e.type == 'holiday').length;
    final leaves = _events.where((e) => e.type == 'leave').length;
    final exams = _events.where((e) => e.type == 'exam').length;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.bar_chart_rounded, 'Calendar overview'),
          Row(
            children: [
              Expanded(child: _miniStat('$holidays', 'Holidays', Colors.orange)),
              const SizedBox(width: 8),
              Expanded(child: _miniStat('$leaves', 'Leave days', Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _miniStat('$exams', 'Exam blocks', Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _addEventCard() {
    final isEditing = _editingEventId != null;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            isEditing ? Icons.edit_calendar_rounded : Icons.add_circle_outline_rounded,
            isEditing ? 'Edit calendar event' : 'Add calendar event',
          ),
          _field(label: 'Event name', controller: _eventNameCtrl,
              hint: 'e.g. Diwali, Christmas break…'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _datePicker(
                      label: 'From date',
                      date: _eventFrom,
                      onChanged: (d) => setState(() => _eventFrom = d))),
              const SizedBox(width: 10),
              Expanded(
                  child: _datePicker(
                      label: 'To date',
                      date: _eventTo,
                      onChanged: (d) => setState(() => _eventTo = d))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _dropdown(
                  label: 'Type',
                  value: _eventType,
                  items: const [
                    DropdownMenuItem(value: 'holiday', child: Text('Public holiday')),
                    DropdownMenuItem(value: 'leave', child: Text('School leave')),
                    DropdownMenuItem(value: 'exam', child: Text('Exam block')),
                  ],
                  onChanged: (v) => setState(() => _eventType = v!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dropdown(
                  label: 'Academic year',
                  value: _eventYear,
                  items: _years
                      .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                      .toList(),
                  onChanged: (v) => setState(() => _eventYear = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _field(
              label: 'Description (optional)',
              controller: _eventDescCtrl,
              hint: 'Short note…'),
          const SizedBox(height: 12),
          Row(
            children: [
              if (isEditing) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _savingEvent ? null : _resetEventForm,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: isEditing ? 2 : 1,
                child: ElevatedButton.icon(
                  onPressed: _savingEvent ? null : _saveCalendarEvent,
                  icon: _savingEvent
                      ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(isEditing ? Icons.check_rounded : Icons.add_rounded, size: 16),
                  label: Text(
                      _savingEvent ? 'Saving…' : (isEditing ? 'Update event' : 'Add event'),
                      style: const TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _eventListCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.list_alt_rounded, 'Upcoming events'),
          if (_loadingEvents)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator()))
          else if (_events.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No events added yet',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ..._events.map((e) => _eventRow(e)),
        ],
      ),
    );
  }

  Widget _eventRow(CalendarEvent event) {
    final colorMap = {
      'holiday': Colors.orange,
      'leave': Colors.blue,
      'exam': Colors.red,
    };
    final iconMap = {
      'holiday': Icons.celebration_rounded,
      'leave': Icons.beach_access_rounded,
      'exam': Icons.edit_note_rounded,
    };
    final color = colorMap[event.type] ?? Colors.grey;
    final icon = iconMap[event.type] ?? Icons.event_rounded;
    final df = _fmtDate(event.fromDate);
    final dt = _fmtDate(event.toDate);
    final dateLabel =
    df == dt ? df : '$df – $dt';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(dateLabel,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          _typeBadge(event.type),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => _startEditEvent(event),
            icon: const Icon(Icons.edit_rounded, color: Color(0xFF2563EB), size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => _confirmDelete(event),
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.red, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
                minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  Widget _typeBadge(String type) {
    final map = {
      'holiday': [Colors.orange, 'Holiday'],
      'leave': [Colors.blue, 'Leave'],
      'exam': [Colors.red, 'Exam'],
    };
    final color = map[type]?[0] as Color? ?? Colors.grey;
    final label = map[type]?[1] as String? ?? type;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color)),
    );
  }

  void _confirmDelete(CalendarEvent event) {
    Get.dialog(AlertDialog(
      title: const Text('Delete event'),
      content: Text('Remove "${event.name}"?'),
      actions: [
        TextButton(
            onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            Get.back();
            _deleteEvent(event);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHARED HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
  }

  Widget _cardTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 18),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          isDense: true,
          decoration: InputDecoration(
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          hint: Text('Select',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _datePicker({
    required String label,
    required DateTime date,
    required void Function(DateTime) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(_fmtDate(date),
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black87)),
                ),
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String hint = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                fontSize: 12, color: Colors.grey.shade400),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),
      ],
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
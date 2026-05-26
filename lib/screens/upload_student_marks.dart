import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/models/school_models.dart';
import 'package:http/http.dart' as http;


import '../constants/api_constants.dart';
import '../widgets/admin_sidebar.dart';

// ─── Constants ────────────────────────────────────────────────────────────────

const List<Map<String, dynamic>> kExamTypes = [
  {'label': 'Unit Test 1',  'value': 'unit_test_1',  'icon': Icons.looks_one_rounded},
  {'label': 'Unit Test 2',  'value': 'unit_test_2',  'icon': Icons.looks_two_rounded},
  {'label': 'Half Yearly',  'value': 'half_yearly',  'icon': Icons.contrast_rounded},
  {'label': 'Annual',       'value': 'annual',       'icon': Icons.emoji_events_rounded},
  {'label': 'Pre-Board',    'value': 'pre_board',    'icon': Icons.assignment_rounded},
  {'label': 'Board',        'value': 'board',        'icon': Icons.school_rounded},
];

const List<String> kDefaultSubjects = [
  'Tamil', 'English', 'Mathematics', 'Science', 'Social Science',
];

// ─── Mark Entry Model ─────────────────────────────────────────────────────────

class _MarkEntry {
  final String studentId;
  final String studentName;
  final String rollNumber;
  final Map<String, TextEditingController> controllers;

  _MarkEntry({
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required List<String> subjects,
    Map<String, String>? prefillMarks,
  }) : controllers = {for (final s in subjects) s: TextEditingController()};

  void dispose() { for (final c in controllers.values) c.dispose(); }
}

// ─── Main Page ────────────────────────────────────────────────────────────────

class StudentMarksUploadPage extends StatefulWidget {
  const StudentMarksUploadPage({super.key});

  @override
  State<StudentMarksUploadPage> createState() => _StudentMarksUploadPageState();
}

class _StudentMarksUploadPageState extends State<StudentMarksUploadPage>
    with TickerProviderStateMixin  {
  // Add these state variables alongside _examTypes
  List<Map<String, dynamic>> _subjectTypes = [];
  bool _subjectTypesLoading = false;
// ── Exam Types ──
  List<Map<String, dynamic>> _examTypes = [];
  bool _examTypesLoading = false;
  final _schoolCtrl = Get.find<SchoolController>();
  final _authCtrl   = Get.find<AuthController>();

  late  TabController _tabCtrl;

  // ── Filter state ──
  School?      _school;
  SchoolClass? _schoolClass;
  Section?     _section;
  String       _examType  = 'unit_test_1';
  String       _term      = '1';
  int          _maxMarks  = 100;
  final _maxMarksCtrl = TextEditingController(text: '100');

  // ── Subjects ──
  List<String> _subjects = List.from(kDefaultSubjects);

  // ── Students ──
  List<_MarkEntry> _entries     = [];
  bool             _isLoading   = false;
  bool             _isSaving    = false;
  bool             _showFilters = true;   // inline expand/collapse like CampusView

  // ── Search ──
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() =>
        setState(() => _query = _searchCtrl.text.trim().toLowerCase()));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Get.find<AuthController>();
      if (!auth.canUploadMarks) {
        Get.back();
        Get.snackbar(
          'Access Denied',
          'You do not have permission to access this page.',
          backgroundColor: Colors.red[700],
          colorText: Colors.white,
        );
      }
      _schoolCtrl.getAllSchools();
      _autoSelectSchool();
    });
  }

  void _autoSelectSchool() {
    final auth  = Get.find<AuthController>();
    final role  = auth.user.value?.role?.toLowerCase();
    final id = _authCtrl.user.value?.schoolId;
    if (id == null) return;
    final s = _schoolCtrl.schools.firstWhereOrNull((s) => s.id == id);
    if (s != null) {
      setState(() => _school = s);
      _schoolCtrl.getAllClasses(s.id);
      _loadExamTypes();
      // if (role == 'teacher' && auth.user.value?.classId != null) {
      //   // pre-select their class once classes load

      // }
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    _maxMarksCtrl.dispose();
    for (final e in _entries) e.dispose();
    super.dispose();
  }

  // ── Grade ─────────────────────────────────────────────────────────────────
  Map<String, dynamic> _grade(int? marks) {
    if (marks == null) return {'label': '—', 'color': Colors.grey[400]!, 'bg': Colors.grey.shade100};
    final p = marks / _maxMarks * 100;
    if (p >= 90) return {'label': 'A+', 'color': const Color(0xFF059669), 'bg': const Color(0xFFD1FAE5)};
    if (p >= 75) return {'label': 'A',  'color': const Color(0xFF059669), 'bg': const Color(0xFFD1FAE5)};
    if (p >= 60) return {'label': 'B',  'color': Colors.blue[700]!,        'bg': Colors.blue.shade50};
    if (p >= 50) return {'label': 'C',  'color': const Color(0xFFD97706), 'bg': const Color(0xFFFEF3C7)};
    if (p >= 35) return {'label': 'D',  'color': const Color(0xFFD97706), 'bg': const Color(0xFFFEF3C7)};
    return           {'label': 'F',  'color': Colors.red[700]!,           'bg': Colors.red.shade50};
  }

  int? _total(_MarkEntry e) {
    int sum = 0; bool any = false;
    for (final s in _subjects) {
      final v = int.tryParse(e.controllers[s]?.text ?? '');
      if (v != null) { sum += v; any = true; }
    }
    return any ? sum : null;
  }
  Future<void> _loadSubjects() async {
    if (_school == null) return;
    setState(() => _subjectTypesLoading = true);

    try {
      final token = _authCtrl.storage.read('token');
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/marks/getbyclass')
            .replace(queryParameters: {
          'schoolId': _school!.id,
          'classId':  _schoolClass?.id ?? '',
        }),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data is List ? data : data['data'] ?? [];
        setState(() {
          _subjectTypes = list.map((e) => {
            'label':    e['subjectName']?.toString() ?? 'Unknown', // 👈 adjust key
            'value':    e['_id']?.toString()         ?? '',        // 👈 adjust key
            'maxMarks': e['maxMarks']?.toString()    ?? '100',     // 👈 adjust key
          }).toList();

          // sync _subjects list for mark entry cards
          _subjects = _subjectTypes.map((s) => s['label'] as String).toList();
        });
      }
    } catch (e) {
      debugPrint('LoadSubjects Error: $e');
    } finally {
      setState(() => _subjectTypesLoading = false);
    }
  }

  Future<void> _createSubject(String subjectName, int maxMarks) async {
    if (_school == null) return;

    try {
      final token = _authCtrl.storage.read('token');
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/subjects/create'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type':  'application/json',
          'Accept':        'application/json',
        },
        body: jsonEncode({
          'subjectName': subjectName,
          'schoolId':    _school!.id,
          'classId':     _schoolClass?.id ?? '',
          'maxMarks':    maxMarks,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _snack('Success', '"$subjectName" added successfully');
        _loadSubjects();
      } else {
        _snack('Error', 'Failed to add subject', error: true);
      }
    } catch (e) {
      debugPrint('CreateSubject Error: $e');
      _snack('Error', 'Something went wrong', error: true);
    }
  }

  Future<void> _updateSubject(String subjectId, String subjectName, int maxMarks) async {
    try {
      final token = _authCtrl.storage.read('token');
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/api/subjects/update/$subjectId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type':  'application/json',
          'Accept':        'application/json',
        },
        body: jsonEncode({
          'subjectName': subjectName,
          'maxMarks':    maxMarks,
        }),
      );

      if (response.statusCode == 200) {
        _snack('Updated', '"$subjectName" updated successfully');
        _loadSubjects();
      } else {
        _snack('Error', 'Failed to update subject', error: true);
      }
    } catch (e) {
      debugPrint('UpdateSubject Error: $e');
    }
  }

  Future<void> _deleteSubject(String subjectId, String subjectName) async {
    try {
      final token = _authCtrl.storage.read('token');
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/subjects/delete/$subjectId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept':        'application/json',
        },
      );

      if (response.statusCode == 200) {
        _snack('Deleted', '"$subjectName" removed successfully');
        _loadSubjects();
      } else {
        _snack('Error', 'Failed to delete subject', error: true);
      }
    } catch (e) {
      debugPrint('DeleteSubject Error: $e');
    }
  }
  Future<void> _createExamType(String examName) async {
    if (_school == null) return;

    try {
      final token = _authCtrl.storage.read('token');
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/examtypes/create'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'examName': examName,
          'schoolId': _school!.id,
          'term':     _term,
          // add any other fields your API requires
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _snack('Success', 'Exam type "$examName" added successfully');
        _loadExamTypes(); // refresh the list after adding
      } else {
        _snack('Error', 'Failed to add exam type', error: true);
      }
    } catch (e) {
      debugPrint('CreateExamType Error: $e');
      _snack('Error', 'Something went wrong', error: true);
    }
  }

  Future<void> _deleteExamType(String examId, String examName) async {
    try {
      final token = _authCtrl.storage.read('token');
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/examtypes/delete/$examId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _snack('Deleted', '"$examName" removed successfully');
        _loadExamTypes();
      } else {
        _snack('Error', 'Failed to delete exam type', error: true);
      }
    } catch (e) {
      debugPrint('DeleteExamType Error: $e');
    }
  }
  Future<void> _loadExamTypes() async {
    if (_school == null) return;
    setState(() => _examTypesLoading = true);

    try {
      final token = _authCtrl.storage.read('token');
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/examtypes/get-all')
            .replace(queryParameters: {'schoolId': _school!.id}),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data is List ? data : data['data'] ?? [];
        setState(() {
          _examTypes = list.map((e) => {
            'label': e['examName']?.toString() ?? 'Unknown', // 👈 adjust key to your API
            'value': e['_id']?.toString() ?? '',             // 👈 adjust key to your API
            'icon':  Icons.assignment_rounded,
          }).toList();
          if (_examTypes.isNotEmpty && _examType.isEmpty) {
            _examType = _examTypes.first['value'];
          }
        });
      }
    } catch (e) {
      debugPrint('LoadExamTypes Error: $e');
    } finally {
      setState(() => _examTypesLoading = false);
    }
  }
  // ── Load students ─────────────────────────────────────────────────────────
  Future<void> _loadStudents() async {
    if (_school == null || _schoolClass == null) return;
    setState(() { _isLoading = true; _entries = []; });

    try {
      final token = _authCtrl.storage.read('token');
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getMarksByClass}')
          .replace(queryParameters: {
        'schoolId':     _school!.id,
        'classId':      _schoolClass!.id,
        if (_section != null) 'sectionId': _section!.id,
        'examType':     _examType,
        'term':         _term,
        'academicYear': '2025-2026',
      });

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data is List ? data : data['data'] ?? [];

        // use loaded subjects or fall back to current _subjects
        final subjects = _subjects.isNotEmpty ? _subjects : List<String>.from(kDefaultSubjects);

        setState(() {
          _entries = list.map((item) {
            // pre-fill scored marks per subject
            final List<dynamic> subjectMarks = item['subjects'] ?? [];
            final prefill = <String, String>{
              for (final s in subjectMarks)
                if (s['subject'] != null)
                  s['subject'].toString(): (s['marksObtained'] ?? '').toString(),
            };

            return _MarkEntry(
              studentId:   item['studentId']?['_id']?.toString()       ?? item['studentId']?.toString() ?? '',
              studentName: item['studentId']?['userName']?.toString()   ?? 'Unknown',
              rollNumber:  item['studentId']?['rollNumber']?.toString() ?? '—',
              subjects:    subjects,
              prefillMarks: prefill,
            );
          }).toList();
          _isLoading   = false;
          _showFilters = false;
        });
      } else if (response.statusCode == 404) {
        // no marks yet — load just the students list without marks
        await _loadStudentsOnly();
      } else {
        debugPrint('LoadStudents Error: ${response.statusCode} ${response.body}');
        setState(() => _isLoading = false);
        _snack('Error', 'Failed to load students', error: true);
      }
    } catch (e) {
      debugPrint('LoadStudents Exception: $e');
      if (mounted) setState(() => _isLoading = false);
      _snack('Error', 'Something went wrong', error: true);
    }
  }

// ── Fallback: load students without marks (blank entry cards) ──
  Future<void> _loadStudentsOnly() async {
    try {
      final token = _authCtrl.storage.read('token');
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/students/get-all')
          .replace(queryParameters: {
        'schoolId': _school!.id,
        'classId':  _schoolClass!.id,
        if (_section != null) 'sectionId': _section!.id,
      });

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data is List ? data : data['data'] ?? [];
        final subjects = _subjects.isNotEmpty ? _subjects : List<String>.from(kDefaultSubjects);

        setState(() {
          _entries = list.map((item) => _MarkEntry(
            studentId:   item['_id']?.toString()         ?? '',
            studentName: item['userName']?.toString()    ?? 'Unknown',
            rollNumber:  item['rollNumber']?.toString()  ?? '—',
            subjects:    subjects,
          )).toList();
          _isLoading   = false;
          _showFilters = false;
        });
      } else {
        setState(() => _isLoading = false);
        _snack('Error', 'Failed to load students', error: true);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // ── Save marks ────────────────────────────────────────────────────────────
  Future<void> _saveMarks() async {
    // ── Validation ──
    for (final e in _entries) {
      for (final s in _subjects) {
        final subjectMaxMarks = int.tryParse(
            _subjectTypes.firstWhereOrNull((st) => st['label'] == s)?['maxMarks'] ?? '$_maxMarks'
        ) ?? _maxMarks;
        final v = int.tryParse(e.controllers[s]?.text ?? '');
        if (v != null && v > subjectMaxMarks) {
          _snack('Validation Error',
              '${e.studentName} — $s exceeds max marks ($subjectMaxMarks)', error: true);
          return;
        }
      }
    }

    setState(() => _isSaving = true);

    try {
      final token = _authCtrl.storage.read('token');

      // ── Build payload ──
      final payload = _entries.map((e) => {
        'studentId':    e.studentId,
        'schoolId':     _school!.id,
        'classId':      _schoolClass!.id,
        if (_section != null) 'sectionId': _section!.id,
        'examType':     _examType,
        'term':         _term,
        'academicYear': '2025-2026',
        'subjects': _subjects.map((s) {
          final subjectData = _subjectTypes.firstWhereOrNull((st) => st['label'] == s);
          final maxM = int.tryParse(subjectData?['maxMarks'] ?? '$_maxMarks') ?? _maxMarks;
          final scored = int.tryParse(e.controllers[s]?.text ?? '') ?? 0;
          return {
            'subject':       s,
            'subjectId':     subjectData?['value'] ?? '',
            'marksObtained': scored,
            'maxMarks':      maxM,
          };
        }).toList(),
      }).toList();

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.uploadMarks}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type':  'application/json',
          'Accept':        'application/json',
        },
        body: jsonEncode({'marks': payload}),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        _snack('Success', 'Marks saved successfully');
      } else {
        debugPrint('SaveMarks Error: ${response.statusCode} ${response.body}');
        _snack('Error', 'Failed to save marks', error: true);
      }
    } catch (e) {
      debugPrint('SaveMarks Exception: $e');
      _snack('Error', 'Something went wrong', error: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
  void _snack(String title, String msg, {bool error = false}) {
    Get.snackbar(title, msg,
      backgroundColor: error ? Colors.red[700] : const Color(0xFF059669),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }
  void _addSubjectDialog({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(
        text: existing?['label'] ?? '');
    final maxMarksCtrl = TextEditingController(
        text: existing?['maxMarks'] ?? '100');
    final isEdit = existing != null;

    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        Icon(isEdit ? Icons.edit_rounded : Icons.book_rounded,
            color: const Color(0xFF3B82F6), size: 20),
        const SizedBox(width: 8),
        Text(isEdit ? 'Edit Subject' : 'Add Subject',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _styledInput(nameCtrl, 'Subject Name', 'e.g. Physics, Chemistry...'),
        const SizedBox(height: 12),
        _styledInput(maxMarksCtrl, 'Max Marks (Out of)', 'e.g. 100'),
      ]),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final name     = nameCtrl.text.trim();
            final maxMarks = int.tryParse(maxMarksCtrl.text.trim()) ?? 100;
            if (name.isEmpty) return;
            Get.back();
            if (isEdit) {
              _updateSubject(existing!['value'], name, maxMarks);
            } else {
              _createSubject(name, maxMarks);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: Text(isEdit ? 'Update' : 'Add'),
        ),
      ],
    ));
  }
  // ── Subject management ────────────────────────────────────────────────────
  // void _addSubjectDialog() {
  //   final ctrl = TextEditingController();
  //   Get.dialog(AlertDialog(
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //     title: const Text('Add Subject', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
  //     content: _styledInput(ctrl, 'Subject name', 'e.g. Physics'),
  //     actions: [
  //       TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
  //       ElevatedButton(
  //         onPressed: () {
  //           final name = ctrl.text.trim();
  //           if (name.isNotEmpty && !_subjects.contains(name)) {
  //             setState(() {
  //               _subjects.add(name);
  //               for (final e in _entries) e.controllers[name] = TextEditingController();
  //             });
  //           }
  //           Get.back();
  //         },
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: Colors.blue[700], foregroundColor: Colors.white,
  //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  //           elevation: 0,
  //         ),
  //         child: const Text('Add'),
  //       ),
  //     ],
  //   ));
  // }
  void _addExamTypeDialog() {
    final nameCtrl = TextEditingController();
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.assignment_add, color: Color(0xFF3B82F6), size: 20),
        SizedBox(width: 8),
        Text('Add Exam Type', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _styledInput(nameCtrl, 'Exam Name', 'e.g. Mid Term, Quarterly, Final...'),
      ]),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            Get.back();
            _createExamType(name);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: const Text('Add'),
        ),
      ],
    ));
  }
  void _removeSubject(String s) {
    setState(() {
      _subjects.remove(s);
      for (final e in _entries) { e.controllers[s]?.dispose(); e.controllers.remove(s); }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final filtered = _entries.where((e) =>
    _query.isEmpty ||
        e.studentName.toLowerCase().contains(_query) ||
        e.rollNumber.contains(_query)
    ).toList();

    return  Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: _buildAppBar(),
        body: Column(children: [
          _buildTabBar(),
          Expanded(child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildEnterMarksTab(filtered),
              _buildSummaryTab(filtered),
            ],
          )),
        ]),
      );

  }

  // ── App Bar (matches CampusManagementView) ────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.grade_rounded, color: Colors.blue[700], size: 20),
        ),
        const SizedBox(width: 12),
        const Text('Marks Upload', style: TextStyle(
          color: Color(0xFF1A1A2E), fontSize: 17, fontWeight: FontWeight.w600,
        )),
      ]),
      actions: [
        if (_entries.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _isSaving
                ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A2E))),
            )
                : ElevatedButton.icon(
              onPressed: _saveMarks,
              icon: const Icon(Icons.save_rounded, size: 16),
              label: const Text('Save', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
      ],
    );
  }

  // ── Tab Bar (matches CampusManagementView exactly) ────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: const BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(width: 3.0, color: Colors.blue[700]!),
          insets: const EdgeInsets.symmetric(horizontal: 16.0),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: Colors.blue[700],
        unselectedLabelColor: Colors.grey[500],
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: const [
          Tab(child: Row(children: [
            Icon(Icons.upload_rounded, size: 18),
            SizedBox(width: 8),
            Text('Enter '),
          ])),
          Tab(child: Row(children: [
            Icon(Icons.bar_chart_rounded, size: 18),
            SizedBox(width: 8),
            Text('Summary'),
          ])),
        ],
      ),
    );
  }

  // ── Enter Marks Tab ───────────────────────────────────────────────────────
  Widget _buildEnterMarksTab(List<_MarkEntry> filtered) {
    return ListView(
      children: [
        // ── Section header with toggle ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filters & Settings', style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
              GestureDetector(
                onTap: () => setState(() => _showFilters = !_showFilters),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_showFilters ? Icons.expand_less : Icons.tune_rounded,
                        size: 15, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text(_showFilters ? 'Collapse' : 'Edit Filters',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700],
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ],
          ),
        ),

        // ── Filter form ──
        if (_showFilters) _buildFiltersForm(),

        // ── Compact chips when collapsed ──
        if (!_showFilters && _schoolClass != null) _buildCompactFilterChips(),

        // ── Subject bar — ONCE, when class is selected ──
        if (_school != null && _schoolClass != null) _buildSubjectBar(),

        // ── Search — only when entries loaded ──
        if (_entries.isNotEmpty) _buildSearchBar(),

        // ── Content ──
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
          )
        else if (_entries.isEmpty)
          _buildEmptyState()
        else
          ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                '${filtered.length} student${filtered.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600],
                    fontWeight: FontWeight.w500),
              ),
            ),
            ...filtered.map((e) => _buildStudentCard(e)),
            const SizedBox(height: 80),
          ],
      ],
    );
  }
  // ── Filters Form (matches _buildForm in ClubsTab) ─────────────────────────
  Widget _buildFiltersForm() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // School
        // GetX<SchoolController>(builder: (sc) {
        //   if (sc.schools.length <= 1) {
        //     return _readonlyRow(Icons.school_rounded, _school?.name ?? 'Loading...', 'School');
        //   }
        //   return _styledDropdown<School>(
        //     label: 'School',
        //     value: _school,
        //     hint: 'Select school',
        //     items: sc.schools.map((s) => DropdownMenuItem(
        //       value: s, child: Text(s.name, style: const TextStyle(fontSize: 13)),
        //     )).toList(),
        //     onChanged: (s) {
        //       setState(() {
        //         _school = s;
        //         _schoolClass = null;
        //         _section = null;
        //         _entries = [];
        //         _examTypes = [];
        //         _examType = '';
        //       });
        //       if (s != null) _schoolCtrl.getAllClasses(s.id);
        //       _loadExamTypes();
        //     },
        //   );
        // }),
        const SizedBox(height: 12),

        // Class + Section side by side
        Row(children: [
          Expanded(child: GetX<SchoolController>(builder: (sc) =>
              _styledDropdown<SchoolClass>(
                label: 'Class',
                value: _schoolClass,
                hint: 'class',
                items: sc.classes.map((c) => DropdownMenuItem(
                  value: c, child: Text(c.name, style: const TextStyle(fontSize: 13)),
                )).toList(),
                onChanged: (c) {
                  setState(() {
                    _schoolClass = c;
                    _section = null;
                    _entries = [];
                    _subjectTypes = [];
                    _subjects     = [];
                  });
                  if (c != null && _school != null)
                    _schoolCtrl.getAllSections(classId: c.id, schoolId: _school!.id);
                  _loadSubjects();
                },
              ),
          )),
          const SizedBox(width: 10),
          Expanded(child: GetX<SchoolController>(builder: (sc) =>
              _styledDropdown<Section>(
                label: 'Section',
                value: _section,
                hint: 'All sections',
                items: [
                  const DropdownMenuItem<Section>(value: null,
                      child: Text('All', style: TextStyle(fontSize: 13))),
                  ...sc.sections.map((s) => DropdownMenuItem(
                    value: s, child: Text(s.name, style: const TextStyle(fontSize: 13)),
                  )),
                ],
                onChanged: (s) => setState(() => _section = s),
              ),
          )),
        ]),
        const SizedBox(height: 14),

        // Exam type
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Exam Type', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            // ── Add button ──
            GestureDetector(
              onTap: _school == null ? null : _addExamTypeDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _school == null ? Colors.grey.shade100 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _school == null ? Colors.grey.shade200 : Colors.blue.shade100,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded, size: 14,
                      color: _school == null ? Colors.grey : Colors.blue[700]),
                  const SizedBox(width: 4),
                  Text('Add',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _school == null ? Colors.grey : Colors.blue[700],
                      )),
                ]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

// Loading state
        if (_examTypesLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6))),
              SizedBox(width: 10),
              Text('Loading...', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          )

// No school selected hint
        else if (_school == null)
          Text('Select a school first to manage exam types.',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]))

// Empty — no exam types yet
        else if (_examTypes.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200, width: 0.5),
              ),
              child: Row(children: [
                Icon(Icons.info_outline_rounded, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('No exam types yet. Tap "Add" to create one.',
                      style: TextStyle(fontSize: 12, color: Colors.orange[800])),
                ),
              ]),
            )

// Dynamic exam type chips with delete (long press)
          else
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _examTypes.map((exam) {
                final sel = _examType == exam['value'];
                return GestureDetector(
                  onTap: () => setState(() => _examType = exam['value']),
                  onLongPress: () {
                    // long press to delete
                    Get.dialog(AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('Delete Exam Type?',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      content: Text('Remove "${exam['label']}" from this school?',
                          style: const TextStyle(fontSize: 13)),
                      actions: [
                        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () {
                            Get.back();
                            _deleteExamType(exam['value'], exam['label']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? Colors.blue[700] : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel ? Colors.blue[700]! : Colors.grey.shade300, width: 0.5),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.assignment_rounded, size: 14,
                          color: sel ? Colors.white : Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(exam['label'], style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : Colors.grey[700],
                      )),
                      const SizedBox(width: 6),
                      // small delete icon on chip
                      Icon(Icons.close_rounded, size: 12,
                          color: sel ? Colors.white70 : Colors.grey[400]),
                    ]),
                  ),
                );
              }).toList(),
            ),
        const SizedBox(height: 14),

        // Term + Max Marks
        Row(children: [
          Expanded(child: _styledDropdown<String>(
            label: 'Term',
            value: _term,
            hint: 'Term',
            items: ['1','2','3'].map((t) => DropdownMenuItem(
              value: t, child: Text('Term $t', style: const TextStyle(fontSize: 13)),
            )).toList(),
            onChanged: (t) { if (t != null) setState(() => _term = t); },
          )),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Max Marks', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              const SizedBox(height: 4),
              TextField(
                controller: _maxMarksCtrl,
                keyboardType: TextInputType.number,
                onChanged: (v) => _maxMarks = int.tryParse(v) ?? 100,
                decoration: InputDecoration(
                  hintText: '100',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.blue.shade400, width: 1),
                  ),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          )),
        ]),
        const SizedBox(height: 16),

        // Load Students button
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          if (_entries.isNotEmpty)
            TextButton(
              onPressed: () => setState(() { _entries = []; _showFilters = true; }),
              child: const Text('Clear'),
            ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: (_school != null && _schoolClass != null) ? _loadStudents : null,
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Load Students', style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.blue.shade100,
              disabledForegroundColor: Colors.blue.shade300,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Compact filter chips when collapsed ───────────────────────────────────
  Widget _buildCompactFilterChips() {
    //final examLabel = kExamTypes.firstWhere((e) => e['value'] == _examType)['label'];
    final examLabel = _examTypes
        .firstWhereOrNull((e) => e['value'] == _examType)?['label'] ?? _examType;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Wrap(spacing: 8, runSpacing: 6, children: [
        _chip(Icons.class_rounded, _schoolClass!.name),
        if (_section != null) _chip(Icons.group_rounded, _section!.name),
        _chip(Icons.assignment_rounded, examLabel),
        _chip(Icons.calendar_today_rounded, 'Term $_term'),
        _chip(Icons.score_rounded, 'Max: $_maxMarks'),
      ]),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: Colors.blue[700]),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[800],
            fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ── Subject bar ───────────────────────────────────────────────────────────
  Widget _buildSubjectBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header row ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Subjects', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
            GestureDetector(
              onTap: _school == null ? null : () => _addSubjectDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _school == null ? Colors.grey.shade100 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _school == null ? Colors.grey.shade200 : Colors.blue.shade100,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded, size: 14,
                      color: _school == null ? Colors.grey : Colors.blue[700]),
                  const SizedBox(width: 4),
                  Text('Add Subject', style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: _school == null ? Colors.grey : Colors.blue[700],
                  )),
                ]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Loading ──
        if (_subjectTypesLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2,
                      color: Color(0xFF3B82F6))),
              SizedBox(width: 10),
              Text('Loading subjects...', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          )

        // ── Empty ──
        else if (_subjectTypes.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200, width: 0.5),
            ),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, size: 16, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Expanded(child: Text(
                _schoolClass == null
                    ? 'Select a class first to manage subjects.'
                    : 'No subjects yet. Tap "Add Subject" to create one.',
                style: TextStyle(fontSize: 12, color: Colors.orange[800]),
              )),
            ]),
          )

        // ── Subject chips ──
        else
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _subjectTypes.map((subject) {
              return GestureDetector(
                // tap → edit
                onTap: () => _addSubjectDialog(existing: subject),
                // long press → delete
                onLongPress: () {
                  Get.dialog(AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Delete Subject?',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    content: Text(
                        'Remove "${subject['label']}" from this class?',
                        style: const TextStyle(fontSize: 13)),
                    actions: [
                      TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () {
                          Get.back();
                          _deleteSubject(subject['value'], subject['label']);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300, width: 0.5),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.book_rounded, size: 13, color: Colors.blue[700]),
                          const SizedBox(width: 6),
                          Text(subject['label'], style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[800],
                          )),
                          const SizedBox(width: 6),
                          Icon(Icons.edit_rounded, size: 11, color: Colors.grey[400]),
                        ]),
                        const SizedBox(height: 3),
                        // ── Out of marks shown below name ──
                        Text('Out of ${subject['maxMarks']}',
                            style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                      ]),
                ),
              );
            }).toList(),
          ),
      ]),
    );
  }// In _buildSubjectBar(), the onTap calls _addSubjectDialog()
// But that method is commented out — uncomment it:


  // ── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search by name or roll number...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.upload_file_rounded, size: 36, color: Colors.blue[700]),
          ),
          const SizedBox(height: 20),
          const Text('No Students Loaded', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 6),
          Text('Select filters above and tap\n"Load Students" to begin',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ]),
      ),
    );
  }

  // ── Student mark card (matches _ItemCard style) ───────────────────────────
  Widget _buildStudentCard(_MarkEntry entry) {
    final total   = _total(entry);
    final maxTot  = _maxMarks * _subjects.length;
    final gInfo   = _grade(total != null ? (total / _subjects.length).round() : null);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10, offset: const Offset(0, 2),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Student header row (like _ItemCard) ───────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue.shade100,
              child: Text(entry.studentName[0].toUpperCase(),
                  style: TextStyle(color: Colors.blue[700],
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.studentName, style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
              Text('Roll No: ${entry.rollNumber}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ])),
            // Grade badge
            if (total != null)
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: gInfo['bg'] as Color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(gInfo['label'] as String, style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800,
                    color: gInfo['color'] as Color,
                  )),
                ),
                const SizedBox(height: 2),
                Text('$total / $maxTot', style: TextStyle(
                    fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600)),
              ]),
          ]),
        ),

        // ── Divider ──
        Divider(height: 1, color: Colors.grey.shade100),

        // ── Subject mark fields ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8, runSpacing: 8,
            children: _subjects.map((subject) {
              final ctrl = entry.controllers[subject]!;
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 72) / 2,
                child: StatefulBuilder(
                  builder: (_, inner) {
                    final val  = int.tryParse(ctrl.text);
                    final over = val != null && val > _maxMarks;
                    final g    = _grade(val);
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: over ? Colors.red.shade50
                            : (val != null ? (g['bg'] as Color).withOpacity(0.5)
                            : Colors.grey.shade50),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: over ? Colors.red.shade300
                              : (val != null
                              ? (g['color'] as Color).withOpacity(0.25)
                              : Colors.grey.shade200),
                          width: 0.5,
                        ),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(subject, style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[600],
                          ), overflow: TextOverflow.ellipsis)),
                          if (val != null && !over)
                            Text(g['label'] as String, style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800,
                              color: g['color'] as Color,
                            )),
                          if (over)
                            Icon(Icons.warning_rounded, size: 13, color: Colors.red[700]),
                        ]),
                        const SizedBox(height: 6),
                        TextField(
                          controller: ctrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          onChanged: (_) => inner(() {}),
                          style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700,
                            color: over ? Colors.red[700] : const Color(0xFF1A1A2E),
                          ),
                          decoration: InputDecoration(
                            hintText: '—',
                            hintStyle: TextStyle(color: Colors.grey[400],
                                fontSize: 18, fontWeight: FontWeight.w700),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            border: InputBorder.none,
                            suffixText: '/$_maxMarks',
                            suffixStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
                          ),
                        ),
                      ]),
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  // ── Summary Tab ───────────────────────────────────────────────────────────
  Widget _buildSummaryTab(List<_MarkEntry> entries) {
    if (_entries.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
            child: Icon(Icons.bar_chart_rounded, size: 36, color: Colors.blue[700]),
          ),
          const SizedBox(height: 20),
          const Text('No Data Yet', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 6),
          Text('Load students and enter marks\nto see the summary.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ]),
      ));
    }

    // Stats
    final subjectStats = <String, Map<String, dynamic>>{};
    for (final s in _subjects) {
      final vals = entries.map((e) => int.tryParse(e.controllers[s]?.text ?? ''))
          .whereType<int>().toList();
      subjectStats[s] = vals.isEmpty ? {'avg': 0.0, 'high': 0, 'low': 0, 'n': 0}
          : {
        'avg':  vals.reduce((a, b) => a + b) / vals.length,
        'high': vals.reduce((a, b) => a > b ? a : b),
        'low':  vals.reduce((a, b) => a < b ? a : b),
        'n':    vals.length,
      };
    }

    final gradeDist = <String, int>{'A+': 0,'A': 0,'B': 0,'C': 0,'D': 0,'F': 0};
    for (final e in entries) {
      final t = _total(e);
      if (t != null) {
        final g = _grade((t / _subjects.length).round())['label'] as String;
        gradeDist[g] = (gradeDist[g] ?? 0) + 1;
      }
    }

    final entered   = entries.where((e) => _total(e) != null).length;
    final passCount = entries.where((e) {
      final t = _total(e);
      return t != null && (t / (_maxMarks * _subjects.length) * 100) >= 35;
    }).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Overview row
        Row(children: [
          Expanded(child: _statBox('Students', '${entries.length}',
              Icons.people_rounded, Colors.blue[700]!, Colors.blue.shade50)),
          const SizedBox(width: 10),
          Expanded(child: _statBox('Entered', '$entered',
              Icons.edit_rounded, const Color(0xFFD97706), const Color(0xFFFEF3C7))),
          const SizedBox(width: 10),
          Expanded(child: _statBox('Passed', '$passCount',
              Icons.check_circle_rounded, const Color(0xFF059669), const Color(0xFFD1FAE5))),
        ]),
        const SizedBox(height: 16),

        // Grade distribution
        _summaryCard('Grade Distribution', Icons.pie_chart_rounded,
          child: Column(children: gradeDist.entries.map((entry) {
            final count = entry.value;
            final pct   = entries.isEmpty ? 0.0 : count / entries.length;
            final color = {'A+': const Color(0xFF059669),'A': const Color(0xFF059669),
              'B': Colors.blue[700]!,'C': const Color(0xFFD97706),
              'D': const Color(0xFFD97706),'F': Colors.red[700]!,
            }[entry.key]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(child: Text(entry.key, style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800, color: color))),
                ),
                const SizedBox(width: 12),
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct, backgroundColor: Colors.grey.shade100,
                    color: color, minHeight: 10,
                  ),
                )),
                const SizedBox(width: 10),
                SizedBox(width: 24, child: Text('$count',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                    textAlign: TextAlign.right)),
              ]),
            );
          }).toList()),
        ),

        // Subject analysis
        _summaryCard('Subject Analysis', Icons.analytics_rounded,
          child: Column(children: _subjects.map((s) {
            final stat = subjectStats[s]!;
            final avg  = stat['avg'] as double;
            final pct  = _maxMarks == 0 ? 0.0 : avg / _maxMarks;
            final g    = _grade(avg.round());
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200, width: 0.5),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(s, style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: g['bg'] as Color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Avg ${avg.toStringAsFixed(1)}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: g['color'] as Color)),
                  ),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade200,
                    color: g['color'] as Color,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  _miniStat('High', '${stat['high']}', const Color(0xFF059669)),
                  const SizedBox(width: 16),
                  _miniStat('Low', '${stat['low']}', Colors.red[700]!),
                  const SizedBox(width: 16),
                  _miniStat('Count', '${stat['n']}', Colors.blue[700]!),
                ]),
              ]),
            );
          }).toList()),
        ),

        // Rankings
        _summaryCard('Student Rankings', Icons.emoji_events_rounded,
          child: Column(children: () {
            final ranked = entries.where((e) => _total(e) != null).toList()
              ..sort((a, b) => (_total(b) ?? 0).compareTo(_total(a) ?? 0));
            return ranked.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final e    = entry.value;
              final tot  = _total(e)!;
              final pct  = (tot / (_maxMarks * _subjects.length) * 100);
              final g    = _grade((tot / _subjects.length).round());
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: rank <= 3
                      ? (g['bg'] as Color).withOpacity(0.4)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: rank <= 3
                        ? (g['color'] as Color).withOpacity(0.25)
                        : Colors.grey.shade200,
                    width: 0.5,
                  ),
                ),
                child: Row(children: [
                  SizedBox(width: 28, child: Text(
                    rank <= 3 ? ['🥇','🥈','🥉'][rank - 1] : '$rank',
                    style: TextStyle(
                        fontSize: rank <= 3 ? 18 : 13,
                        fontWeight: FontWeight.w700, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.studentName, style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)))),
                  Text('$tot / ${_maxMarks * _subjects.length}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600],
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: g['bg'] as Color, borderRadius: BorderRadius.circular(6)),
                    child: Text('${pct.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: g['color'] as Color)),
                  ),
                ]),
              );
            }).toList();
          }()),
        ),
      ],
    );
  }

  // ── Shared small helpers ──────────────────────────────────────────────────

  Widget _statBox(String label, String value, IconData icon, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withOpacity(0.15)),
      ),
      child: Column(children: [
        Icon(icon, color: fg, size: 22),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: fg)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600],
            fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _summaryCard(String title, IconData icon, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: Colors.blue[700], size: 16),
            ),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
          ]),
        ),
        Divider(height: 1, color: Colors.grey.shade100),
        Padding(padding: const EdgeInsets.all(14), child: child),
      ]),
    );
  }

  Widget _miniStat(String label, String value, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$label: ', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    ],
  );

  Widget _readonlyRow(IconData icon, String label, String tag) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(tag, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
            child: Text(tag, style: TextStyle(fontSize: 11, color: Colors.blue[700],
                fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    ]);
  }

  Widget _styledInput(TextEditingController ctrl, String label, String hint) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      const SizedBox(height: 4),
      TextField(
        controller: ctrl,
        autofocus: true,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          filled: true, fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.blue.shade400, width: 1)),
        ),
        style: const TextStyle(fontSize: 13),
      ),
    ]);
  }

  Widget _styledDropdown<T>({
    required String label,
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      const SizedBox(height: 4),
      DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          filled: true, fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.blue.shade400, width: 1)),
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
        icon: Icon(Icons.keyboard_arrow_down, color: Colors.blue[700]),
        style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A2E)),
        items: items,
        onChanged: onChanged,
      ),
    ]);
  }
}

// ─── Extension ────────────────────────────────────────────────────────────────
extension _Ext<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) { if (test(e)) return e; }
    return null;
  }
}
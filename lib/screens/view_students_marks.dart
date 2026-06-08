import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/constants/api_constants.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/models/school_models.dart';
import 'package:school_app/services/api_service.dart';

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
  bool isAbsent;

  _MarkEntry({
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required List<String> subjects,
    this.isAbsent = false,
  }) : controllers = {for (final s in subjects) s: TextEditingController()};

  void dispose() { for (final c in controllers.values) c.dispose(); }
}

// ─── Main Page ────────────────────────────────────────────────────────────────

class StudentMarksViewPage extends StatefulWidget {
  const StudentMarksViewPage({super.key});

  @override
  State<StudentMarksViewPage> createState() => _StudentMarksViewPageState();
}

class _StudentMarksViewPageState extends State<StudentMarksViewPage>
    with SingleTickerProviderStateMixin {

  final _schoolCtrl = Get.find<SchoolController>();
  final _authCtrl   = Get.find<AuthController>();
  final _api        = Get.find<ApiService>();

  late final TabController _tabCtrl;

  // ── Filter state ──
  School?      _school;
  SchoolClass? _schoolClass;
  Section?     _section;
  String       _examType  = 'unit_test_1';
  String       _term      = '1';
  int          _maxMarks  = 100;
  final _maxMarksCtrl = TextEditingController(text: '100');

  // ── Config state ──
  String?                   _configId;
  String                    _academicYear = '2025-2026';
  List<Map<String,dynamic>> _configExams    = [];
  List<Map<String,dynamic>> _configSubjects = [];

  // ── Existing reports (studentId -> report doc) ──
  Map<String, Map<String,dynamic>> _studentReports = {};

  // ── Subjects ──
  List<String> _subjects = List.from(kDefaultSubjects);

  // ── Students ──
  List<_MarkEntry> _entries     = [];
  bool             _isLoading   = false;
  bool             _isSaving    = false;
  bool             _showFilters = true;

  // ── Per-student saving state ──
  final Map<String, bool> _savingStudent = {};

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
      _schoolCtrl.getAllSchools();
      _autoSelectSchool();
    });
  }

  void _autoSelectSchool() {
    final id = _authCtrl.user.value?.schoolId;
    if (id == null) return;
    final s = _schoolCtrl.schools.firstWhereOrNull((s) => s.id == id);
    if (s != null) {
      setState(() => _school = s);
      _schoolCtrl.getAllClasses(s.id);
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns true only if [id] looks like a 24-char hex MongoDB ObjectId.
  bool _isValidObjectId(String? id) {
    if (id == null || id.isEmpty) return false;
    return RegExp(r'^[a-f\d]{24}$', caseSensitive: false).hasMatch(id);
  }

  /// Extract the MongoDB _id from a config response map.
  String? _extractConfigId(Map<String,dynamic> cfg) {
    for (final key in ['_id', 'id', 'configId']) {
      final val = cfg[key]?.toString();
      if (_isValidObjectId(val)) return val;
    }
    debugPrint('[VIEW CONFIG ID SEARCH] No valid ObjectId found. Keys: ${cfg.keys.toList()}');
    debugPrint('[VIEW CONFIG ID SEARCH] Values: ${cfg.entries.map((e) => "${e.key}=${e.value}").join(", ")}');
    return null;
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

  // ── Extract roll number from raw student map ──────────────────────────────
  String _extractRollNumber(Map<String, dynamic> s) {
    final nonMandatory = s['nonMandatory'];
    if (nonMandatory is Map) {
      final roll = nonMandatory['rollNumber']?.toString()
          ?? nonMandatory['roll']?.toString();
      if (roll != null && roll.isNotEmpty) return roll;
    }
    return s['rollNumber']?.toString()
        ?? s['roll']?.toString()
        ?? '—';
  }

  // ── Fetch config (tries with and without academicYear) ────────────────────
  Future<Map<String,dynamic>?> _fetchConfig({required bool withAcademicYear}) async {
    try {
      final params = <String, dynamic>{
        'schoolId': _school!.id,
        'classId': _schoolClass!.id,
        if (withAcademicYear) 'academicYear': _academicYear,
      };
      debugPrint('[VIEW CONFIG FETCH] params=$params');
      final resp = await _api.get(ApiConstants.getMarkReportConfigByClass, queryParameters: params);
      debugPrint('[VIEW CONFIG FETCH] ok=${resp.data['ok']} hasData=${resp.data['data'] != null}');
      if (resp.data['ok'] == true && resp.data['data'] != null) {
        return resp.data['data'] as Map<String,dynamic>;
      }
    } catch (e) {
      debugPrint('[VIEW CONFIG FETCH error withAcademicYear=$withAcademicYear] $e');
    }
    return null;
  }

  // ── Load students ─────────────────────────────────────────────────────────
  Future<void> _loadStudents() async {
    if (_school == null || _schoolClass == null) return;
    setState(() { _isLoading = true; _entries = []; _studentReports = {}; _savingStudent.clear(); });

    try {
      // 1. Load mark report config
      Map<String, dynamic>? cfg = await _fetchConfig(withAcademicYear: true);
      if (cfg == null) {
        debugPrint('[VIEW CONFIG] First attempt failed, trying without academicYear...');
        cfg = await _fetchConfig(withAcademicYear: false);
      }

      if (cfg != null) {
        debugPrint('[VIEW CONFIG] Raw cfg keys: ${cfg.keys.toList()}');
        final extractedId = _extractConfigId(cfg);
        _configId       = extractedId;
        _configExams    = List<Map<String,dynamic>>.from(cfg['exams']    ?? []);
        _configSubjects = List<Map<String,dynamic>>.from(cfg['subjects'] ?? []);
        debugPrint('[VIEW CONFIG] id=$_configId exams=${_configExams.length} subjects=${_configSubjects.length}');
        if (!_isValidObjectId(_configId)) {
          debugPrint('[VIEW CONFIG] WARNING: configId "$_configId" is not a valid ObjectId!');
        }
        if (_configSubjects.isNotEmpty) {
          setState(() {
            _subjects = _configSubjects
                .map((s) => s['subjectName']?.toString() ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
          });
        }
        if (_configExams.isNotEmpty) {
          final cfgExamNames = _configExams.map((e) => e['examName']?.toString() ?? '').toList();
          if (!cfgExamNames.contains(_examType)) {
            _examType = cfgExamNames.first;
          }
          _maxMarks = (_configExams.firstWhereOrNull(
                  (e) => e['examName']?.toString() == _examType)?['maxMarks'] ?? 100) as int;
          _maxMarksCtrl.text = _maxMarks.toString();
        }
      } else {
        debugPrint('[VIEW CONFIG] No config found for class=${_schoolClass!.id}');
      }

      // 2. Fetch students
      final sResp = await _api.get(ApiConstants.getAllStudents, queryParameters: {
        'schoolId': _school!.id,
        'classId': _schoolClass!.id,
        if (_section != null) 'sectionId': _section!.id,
      });
      final rawStudents = <Map<String,dynamic>>[];
      if (sResp.data['ok'] == true || sResp.data['data'] != null) {
        rawStudents.addAll(
            List<Map<String,dynamic>>.from(sResp.data['data'] ?? sResp.data ?? []));
      }

      // 3. Fetch existing mark reports
      final rResp = await _api.get(ApiConstants.getAllMarkReportsV1, queryParameters: {
        'schoolId': _school!.id,
        'classId': _schoolClass!.id,
        if (_section != null) 'sectionId': _section!.id,
        'academicYear': _academicYear,
      });
      if (rResp.data['ok'] == true) {
        final reports = List<Map<String,dynamic>>.from(rResp.data['data'] ?? []);
        setState(() {
          _studentReports = {
            for (final r in reports)
              (r['studentId'] is Map ? r['studentId']['_id'] : r['studentId'])
                  ?.toString() ?? '': r
          };
        });
      }

      // 4. Build entries
      if (!mounted) return;
      setState(() {
        _entries = rawStudents.map((s) {
          final sid  = s['_id']?.toString() ?? '';
          final name = s['name']?.toString()
              ?? s['studentName']?.toString()
              ?? s['fullName']?.toString()
              ?? s['userName']?.toString()
              ?? 'Unknown';
          final roll     = _extractRollNumber(s);
          final report   = _studentReports[sid];
          final isAbsent = report?['isAbsent'] as bool? ?? false;

          final entry = _MarkEntry(
            studentId: sid,
            studentName: name,
            rollNumber: roll,
            subjects: _subjects,
            isAbsent: isAbsent,
          );

          if (report != null) {
            final examRecords = List<Map<String,dynamic>>.from(report['examRecords'] ?? []);
            final examRecord  = examRecords.firstWhereOrNull(
                  (er) => er['examName']?.toString() == _examType,
            );
            if (examRecord != null) {
              final subs = List<Map<String,dynamic>>.from(examRecord['subjects'] ?? []);
              for (final sub in subs) {
                final subName = (sub['subject'] ?? sub['subjectName'])?.toString() ?? '';
                final marks   = sub['marksObtained'];
                if (entry.controllers.containsKey(subName) && marks != null && marks != 0) {
                  entry.controllers[subName]!.text = marks.toString();
                }
              }
            }
          }
          return entry;
        }).toList();

        for (final e in _entries) _savingStudent[e.studentId] = false;
        _isLoading   = false;
        _showFilters = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack('Error', 'Failed to load students: $e', error: true);
    }
  }

  // ── Save all marks ────────────────────────────────────────────────────────
  Future<void> _saveMarks() async {
    if (_school == null || _schoolClass == null) return;
    if (!_isValidObjectId(_configId)) {
      _snack('No Config',
          'No valid configuration found for this class. '
              'Please ask the administrator to set it up.',
          error: true);
      return;
    }
    for (final e in _entries) {
      for (final s in _subjects) {
        final v = int.tryParse(e.controllers[s]?.text ?? '');
        if (v != null && v > _maxMarks) {
          _snack('Validation Error',
              '${e.studentName} — $s exceeds max marks ($_maxMarks)', error: true);
          return;
        }
      }
    }
    setState(() => _isSaving = true);
    int saved = 0; int failed = 0;
    try {
      for (final entry in _entries) {
        final err = await _saveEntryMarks(entry);
        if (err == null) saved++; else failed++;
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
    if (failed == 0) {
      _snack('Saved', 'Marks saved for $saved student${saved != 1 ? 's' : ''}');
    } else {
      _snack('Partial', '$saved saved, $failed failed', error: failed > saved);
    }
  }

  // ── Save a single student — returns null on success, error string on failure ──
  Future<String?> _saveEntryMarks(_MarkEntry entry) async {
    final sid = entry.studentId;

    final cfgExam = _configExams.firstWhereOrNull(
            (e) => e['examName']?.toString() == _examType);
    final examSubjects = _subjects.map((subName) => {
      'subject'        : subName,
      'marksObtained'  : int.tryParse(entry.controllers[subName]?.text.trim() ?? '') ?? 0,
      'maxMarks'       : cfgExam?['maxMarks'] ?? _maxMarks,
      'minPassingMarks': cfgExam?['passingMarks'] ?? 35,
    }).toList();

    // Top-level subjects from config (names/codes only, NOT marks)
    final topLevelSubjects = _configSubjects.isNotEmpty
        ? _configSubjects.map((s) => {
      'subject'    : s['subjectName']?.toString() ?? '',
      'subjectCode': s['subjectCode']?.toString() ?? '',
    }).toList()
        : _subjects.map((s) => {'subject': s, 'subjectCode': ''}).toList();

    final newExamRecord = {'examName': _examType, 'subjects': examSubjects};
    final existing = _studentReports[sid];

    // Helper: extract readable error from DioException
    String dioError(dynamic e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) return data['message'].toString();
        return 'HTTP ${e.response?.statusCode ?? 'error'}: ${e.message}';
      }
      return e.toString();
    }

    if (existing != null) {
      // ── UPDATE ─────────────────────────────────────────────────────────────
      // Normalise existing examRecords back to plain format
      final rawRecords = List<Map<String,dynamic>>.from(existing['examRecords'] ?? []);
      final allExamRecords = <Map<String,dynamic>>[];
      bool replaced = false;

      for (final er in rawRecords) {
        final eName = er['examName']?.toString() ?? '';
        if (eName == _examType) {
          allExamRecords.add(newExamRecord);
          replaced = true;
        } else {
          final subs = List<Map<String,dynamic>>.from(er['subjects'] ?? []);
          allExamRecords.add({
            'examName': eName,
            'subjects': subs.map((s) {
              final raw = s['subject'];
              final subjectName = raw is Map
                  ? (raw['name'] ?? raw['subjectName'] ?? '')?.toString()
                  : raw?.toString() ?? s['subjectName']?.toString() ?? '';
              return {
                'subject'        : subjectName,
                'marksObtained'  : s['marksObtained'] ?? 0,
                'maxMarks'       : s['maxMarks'] ?? 100,
                'minPassingMarks': s['minPassingMarks'] ?? s['passingMarks'] ?? 35,
              };
            }).toList(),
          });
        }
      }
      if (!replaced) allExamRecords.add(newExamRecord);

      final rid = existing['_id']?.toString() ?? '';

      // Use the report's own markReportConfigId as fallback if _configId is invalid
      String? effectiveConfigId = _isValidObjectId(_configId) ? _configId : null;
      if (effectiveConfigId == null) {
        final reportCfgId = existing['markReportConfigId'];
        final reportCfgIdStr = reportCfgId is Map
            ? reportCfgId['_id']?.toString()
            : reportCfgId?.toString();
        if (_isValidObjectId(reportCfgIdStr)) effectiveConfigId = reportCfgIdStr;
      }

      debugPrint('[VIEW UPDATE] rid=$rid configId=$effectiveConfigId exams=${allExamRecords.length}');

      if (effectiveConfigId == null) {
        return 'No valid configuration ID available. Please reload students or contact your administrator.';
      }

      try {
        final payload = {
          'schoolId'          : _school!.id,
          'classId'           : _schoolClass!.id,
          if (_section != null) 'sectionId': _section!.id,
          'studentId'         : sid,
          'academicYear'      : _academicYear,
          'markReportConfigId': effectiveConfigId,
          'examRecords'       : allExamRecords,
          'subjects'          : topLevelSubjects,
          'isAbsent'          : entry.isAbsent,
        };
        debugPrint('[VIEW UPDATE] payload configId=${payload['markReportConfigId']}');
        final resp = await _api.put('${ApiConstants.updateMarkReportV1}/$rid', data: payload);
        debugPrint('[VIEW UPDATE] ok=${resp.data['ok']} msg=${resp.data['message']}');
        if (resp.data['ok'] == true) {
          if (resp.data['data'] != null) {
            setState(() => _studentReports[sid] = resp.data['data']);
          }
          return null;
        }
        return resp.data['message']?.toString() ?? 'Update failed';
      } catch (e) {
        debugPrint('[VIEW UPDATE ERROR] $e');
        return dioError(e);
      }
    } else {
      // ── CREATE ─────────────────────────────────────────────────────────────
      if (!_isValidObjectId(_configId)) {
        return 'No valid class configuration found. Please ask the administrator to set it up.';
      }
      debugPrint('[VIEW CREATE] sid=$sid exam=$_examType configId=$_configId');

      try {
        final payload = {
          'schoolId'          : _school!.id,
          'classId'           : _schoolClass!.id,
          if (_section != null) 'sectionId': _section!.id,
          'studentId'         : sid,
          'academicYear'      : _academicYear,
          'markReportConfigId': _configId!,
          'examRecords'       : [newExamRecord],
          'subjects'          : topLevelSubjects,
          'isAbsent'          : entry.isAbsent,
        };
        debugPrint('[VIEW CREATE] payload configId=${payload['markReportConfigId']}');
        final resp = await _api.post(ApiConstants.createMarkReportV1, data: payload);
        debugPrint('[VIEW CREATE] ok=${resp.data['ok']} msg=${resp.data['message']}');
        if (resp.data['ok'] == true) {
          if (resp.data['data'] != null) {
            setState(() => _studentReports[sid] = resp.data['data']);
          }
          return null;
        }
        return resp.data['message']?.toString() ?? 'Create failed';
      } catch (e) {
        debugPrint('[VIEW CREATE ERROR] $e');
        return dioError(e);
      }
    }
  }

  // ── Save a single student inline ──────────────────────────────────────────
  Future<void> _saveSingleStudent(_MarkEntry entry) async {
    if (!_isValidObjectId(_configId)) {
      // For updates, we can still proceed if the existing report has a valid configId
      final existing = _studentReports[entry.studentId];
      if (existing == null) {
        _snack('No Config',
            'No valid configuration found for this class. '
                'Please ask the administrator to set it up.',
            error: true);
        return;
      }
    }
    for (final s in _subjects) {
      final v = int.tryParse(entry.controllers[s]?.text ?? '');
      if (v != null && v > _maxMarks) {
        _snack('Validation Error',
            '${entry.studentName} — $s exceeds max marks ($_maxMarks)', error: true);
        return;
      }
    }
    setState(() => _savingStudent[entry.studentId] = true);
    final err = await _saveEntryMarks(entry);
    if (mounted) setState(() => _savingStudent[entry.studentId] = false);
    if (err == null) {
      _snack('Saved', 'Marks saved for ${entry.studentName}');
    } else {
      _snack('Error', err, error: true);
    }
  }

  void _snack(String title, String msg, {bool error = false}) {
    Get.snackbar(title, msg,
      backgroundColor: error ? Colors.red[700] : const Color(0xFF059669),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  // ── Subject management ────────────────────────────────────────────────────
  void _addSubjectDialog() {
    final ctrl = TextEditingController();
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add Subject',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      content: _styledInput(ctrl, 'Subject name', 'e.g. Physics'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final name = ctrl.text.trim();
            if (name.isNotEmpty && !_subjects.contains(name)) {
              setState(() {
                _subjects.add(name);
                for (final e in _entries) {
                  e.controllers[name] = TextEditingController();
                }
              });
            }
            Get.back();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700], foregroundColor: Colors.white,
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Column(children: [
        Expanded(child: _buildEnterMarksTab(filtered)),
      ]),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────
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
        const Text('View Marks', style: TextStyle(
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
                  child: CircularProgressIndicator(strokeWidth: 2,
                      color: Color(0xFF1A1A2E))),
            )
                : ElevatedButton.icon(
              onPressed: _saveMarks,
              icon: const Icon(Icons.save_rounded, size: 16),
              label: const Text('Save All', style: TextStyle(fontSize: 13)),
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

  // ── Enter Marks Tab ───────────────────────────────────────────────────────
  Widget _buildEnterMarksTab(List<_MarkEntry> filtered) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filters & Settings', style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E))),
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

        if (_showFilters) _buildFiltersForm(),
        if (!_showFilters && _schoolClass != null) _buildCompactFilterChips(),
        if (_entries.isNotEmpty) _buildSubjectBar(),
        if (_entries.isNotEmpty) _buildSearchBar(),
        if (_entries.isNotEmpty && !_showFilters) _buildConfigBanner(),

        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
          )
        else if (_entries.isEmpty)
          _buildEmptyState()
        else ...[
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

  // ── Config status banner ──────────────────────────────────────────────────
  Widget _buildConfigBanner() {
    if (_isValidObjectId(_configId)) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFD1FAE5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF6EE7B7)),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF059669)),
          const SizedBox(width: 8),
          Expanded(child: Text(
            'Config loaded · ${_configExams.length} exam${_configExams.length == 1 ? '' : 's'}'
                ' · ${_subjects.length} subject${_subjects.length == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF065F46),
                fontWeight: FontWeight.w500),
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.blue[700],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(_examType, style: const TextStyle(
                fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ]),
      );
    } else {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFDBA74)),
        ),
        child: Row(children: [
          const Icon(Icons.warning_amber_rounded, size: 15, color: Color(0xFFD97706)),
          const SizedBox(width: 8),
          Expanded(child: Text(
            'No valid configuration found for this class / academic year. '
                'Marks can only be updated for existing reports. '
                'Please ask the administrator to set up a configuration.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
          )),
        ]),
      );
    }
  }

  // ── Filters Form ──────────────────────────────────────────────────────────
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

        const SizedBox(height: 12),

        Row(children: [
          Expanded(child: GetX<SchoolController>(builder: (sc) =>
              _styledDropdown<SchoolClass>(
                label: 'Class',
                value: _schoolClass,
                hint: 'class',
                items: sc.classes.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c.name, style: const TextStyle(fontSize: 13)),
                )).toList(),
                onChanged: (c) {
                  setState(() { _schoolClass = c; _section = null; _entries = []; });
                  if (c != null && _school != null) {
                    _schoolCtrl.getAllSections(classId: c.id, schoolId: _school!.id);
                  }
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
                    value: s,
                    child: Text(s.name, style: const TextStyle(fontSize: 13)),
                  )),
                ],
                onChanged: (s) => setState(() => _section = s),
              ),
          )),
        ]),
        const SizedBox(height: 14),

        Text('Exam Type', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        const SizedBox(height: 8),
        _configExams.isNotEmpty
            ? Wrap(spacing: 8, runSpacing: 8,
            children: _configExams.map((exam) {
              final name = exam['examName']?.toString() ?? '';
              final sel  = _examType == name;
              return GestureDetector(
                onTap: () => setState(() {
                  _examType = name;
                  _maxMarks = (exam['maxMarks'] ?? 100) as int;
                  _maxMarksCtrl.text = _maxMarks.toString();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? Colors.blue[700] : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: sel ? Colors.blue[700]! : Colors.grey.shade300,
                        width: 0.5),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.assignment_rounded, size: 14,
                        color: sel ? Colors.white : Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(name, style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : Colors.grey[700],
                    )),
                  ]),
                ),
              );
            }).toList())
            : Wrap(spacing: 8, runSpacing: 8,
            children: kExamTypes.map((exam) {
              final sel = _examType == exam['value'];
              return GestureDetector(
                onTap: () => setState(() => _examType = exam['value']),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? Colors.blue[700] : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: sel ? Colors.blue[700]! : Colors.grey.shade300,
                        width: 0.5),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(exam['icon'] as IconData, size: 14,
                        color: sel ? Colors.white : Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(exam['label'] as String, style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : Colors.grey[700],
                    )),
                  ]),
                ),
              );
            }).toList()),
        const SizedBox(height: 14),

        Row(children: [
          Expanded(child: _styledDropdown<String>(
            label: 'Term',
            value: _term,
            hint: 'Term',
            items: ['1','2','3'].map((t) => DropdownMenuItem(
              value: t,
              child: Text('Term $t', style: const TextStyle(fontSize: 13)),
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
                  filled: true, fillColor: Colors.grey.shade50,
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

  // ── Compact filter chips ───────────────────────────────────────────────────
  Widget _buildCompactFilterChips() {
    final examLabel = kExamTypes
        .firstWhereOrNull((e) => e['value'] == _examType)?['label'] as String?
        ?? _examType;
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(children: [
        Text('Subjects', style: TextStyle(fontSize: 12,
            fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(width: 10),
        Expanded(child: SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _subjects.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final s = _subjects[i];
              return GestureDetector(
                onLongPress: () => _removeSubject(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300, width: 0.5),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(s, style: TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w500, color: Colors.grey[800])),
                    const SizedBox(width: 4),
                    Icon(Icons.close_rounded, size: 11, color: Colors.grey[500]),
                  ]),
                ),
              );
            },
          ),
        )),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _addSubjectDialog,
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Icon(Icons.add_rounded, size: 18, color: Colors.blue[700]),
          ),
        ),
      ]),
    );
  }

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

  // ── Student mark card ─────────────────────────────────────────────────────
  Widget _buildStudentCard(_MarkEntry entry) {
    final total      = _total(entry);
    final maxTot     = _maxMarks * _subjects.length;
    final gInfo      = _grade(total != null ? (total / _subjects.length).round() : null);
    final sid        = entry.studentId;
    final isSavingThis = _savingStudent[sid] ?? false;
    final hasReport    = _studentReports.containsKey(sid);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: hasReport ? Border.all(color: const Color(0xFF86EFAC), width: 1.5) : null,
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10, offset: const Offset(0, 2),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Student header row
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue.shade100,
              child: Text(entry.studentName[0].toUpperCase(),
                  style: TextStyle(color: Colors.blue[700],
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.studentName, style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E))),
              Text('Roll No: ${entry.rollNumber}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (hasReport)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Saved', style: TextStyle(
                      fontSize: 11, color: Color(0xFF15803D),
                      fontWeight: FontWeight.w600)),
                ),
              if (total != null) ...[
                const SizedBox(height: 4),
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
                    fontSize: 10, color: Colors.grey[500],
                    fontWeight: FontWeight.w600)),
              ],
            ]),
          ]),
        ),

        // Absent toggle
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Row(children: [
            Icon(Icons.event_busy_outlined, size: 15, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text('Mark as Absent', style: TextStyle(
                fontSize: 13, color: Colors.grey[700],
                fontWeight: FontWeight.w500)),
            const Spacer(),
            Switch.adaptive(
              value: entry.isAbsent,
              activeColor: Colors.red[600],
              onChanged: (v) => setState(() => entry.isAbsent = v),
            ),
          ]),
        ),

        // Absent banner or mark fields
        if (entry.isAbsent)
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, size: 15, color: Colors.red[700]),
              const SizedBox(width: 8),
              Text('Student marked as absent for this exam.',
                  style: TextStyle(fontSize: 12, color: Colors.red[700])),
            ]),
          )
        else ...[
          Divider(height: 1, color: Colors.grey.shade100),
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
                          color: over
                              ? Colors.red.shade50
                              : (val != null
                              ? (g['bg'] as Color).withOpacity(0.5)
                              : Colors.grey.shade50),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: over
                                ? Colors.red.shade300
                                : (val != null
                                ? (g['color'] as Color).withOpacity(0.25)
                                : Colors.grey.shade200),
                            width: 0.5,
                          ),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(child: Text(subject, style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
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
                                  hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                  border: InputBorder.none,
                                  suffixText: '/$_maxMarks',
                                  suffixStyle: TextStyle(
                                      fontSize: 11, color: Colors.grey[400]),
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
        ],

        // Per-student Save / Update button
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSavingThis ? null : () => _saveSingleStudent(entry),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                disabledBackgroundColor: Colors.blue.shade100,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: isSavingThis
                  ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                hasReport ? 'Update Marks' : 'Save Marks',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Shared small helpers ──────────────────────────────────────────────────

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
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
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
        isDense: true,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          filled: true, fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
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
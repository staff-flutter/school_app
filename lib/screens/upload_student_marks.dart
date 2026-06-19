import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/constants/api_constants.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/models/school_models.dart';
import 'package:school_app/services/api_service.dart';

// ── Design tokens (light-blue professional theme) ─────────────────────────────
const _kPrimary    = Color(0xFF2563EB);
const _kLightBlue  = Color(0xFFEFF6FF);
const _kBlueBorder = Color(0xFFBFDBFE);
const _kBg         = Color(0xFFF4F4F6);
const _kCard       = Colors.white;
const _kText       = Color(0xFF1C1C1E);
const _kMuted      = Color(0xFF6B7280);
const _kSuccess    = Color(0xFF059669);
const _kError      = Color(0xFFEF4444);
const _kDark       = Color(0xFF1E293B);

// ─────────────────────────────────────────────────────────────────────────────
class StudentMarksUploadPage extends StatefulWidget {
  const StudentMarksUploadPage({super.key});
  @override
  State<StudentMarksUploadPage> createState() => _StudentMarksUploadPageState();
}

class _StudentMarksUploadPageState extends State<StudentMarksUploadPage>
    with TickerProviderStateMixin {
  // ── Services ─────────────────────────────────────────────────────────────
  final _auth       = Get.find<AuthController>();
  final _schoolCtrl = Get.find<SchoolController>();
  final _api        = Get.find<ApiService>();

  late final TabController _tabCtrl;

  // ── Filter state ──────────────────────────────────────────────────────────
  SchoolClass? _class;
  Section?     _section;
  String       _academicYear = '2026-2027';
  bool         _showFilters  = true;

  // ── Config state ──────────────────────────────────────────────────────────
  String?                   _configId;
  List<Map<String,dynamic>> _cfgSubjects = [];
  List<Map<String,dynamic>> _cfgExams    = [];
  bool _configLoading = false;
  bool _configSaving  = false;

  // Inline-add controllers
  final _subNameCtrl  = TextEditingController();
  final _subCodeCtrl  = TextEditingController();
  final _examNameCtrl = TextEditingController();
  final _examMaxCtrl  = TextEditingController(text: '100');
  final _examPassCtrl = TextEditingController(text: '35');

  // ── Students state ────────────────────────────────────────────────────────
  List<Map<String,dynamic>> _students       = [];
  bool                      _studentsLoading = false;

  // ── Reports state ─────────────────────────────────────────────────────────
  Map<String, Map<String,dynamic>> _reports = {};

  // ── Marks data ────────────────────────────────────────────────────────────
  Map<String, List<List<TextEditingController>>> _cells   = {};
  Map<String, bool>                              _absent  = {};
  Map<String, bool>                              _saving  = {};
  Map<String, bool>                              _expanded = {};
  final Map<String, TextEditingController>       _remarks  = {};

  // ── Role helpers ──────────────────────────────────────────────────────────
  bool get _canConfigure {
    final role = _auth.user.value?.role?.toLowerCase() ?? '';
    return ['administrator','principal','viceprincipal'].contains(role);
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _canConfigure ? 2 : 1, vsync: this);
    final school = _schoolCtrl.selectedSchool.value;
    if (school?.currentAcademicYear != null) _academicYear = school!.currentAcademicYear!;
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSchoolLoaded());
  }

  Future<void> _ensureSchoolLoaded() async {
    if (_schoolCtrl.selectedSchool.value != null && _schoolCtrl.classes.isNotEmpty) return;
    try {
      final user = _auth.user.value;
      if (user?.schoolId == null) return;
      if (_schoolCtrl.schools.isEmpty) await _schoolCtrl.getAllSchools();
      if (_schoolCtrl.selectedSchool.value == null) {
        final school = _schoolCtrl.schools.firstWhereOrNull((s) => s.id == user!.schoolId);
        if (school != null) _schoolCtrl.selectedSchool.value = school;
      }
      final sid = _schoolCtrl.selectedSchool.value?.id;
      if (sid != null && _schoolCtrl.classes.isEmpty) {
        await _schoolCtrl.getAllClasses(sid);
        await _schoolCtrl.getAllSections(schoolId: sid);
      }
      final schoolAY = _schoolCtrl.selectedSchool.value?.currentAcademicYear;
      if (schoolAY != null && mounted) setState(() => _academicYear = schoolAY);
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _subNameCtrl.dispose(); _subCodeCtrl.dispose();
    _examNameCtrl.dispose(); _examMaxCtrl.dispose(); _examPassCtrl.dispose();
    _disposeCells();
    for (final c in _remarks.values) c.dispose();
    super.dispose();
  }

  void _disposeCells() {
    for (final rows in _cells.values) for (final row in rows) for (final c in row) c.dispose();
    _cells.clear();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String? get _schoolId => _schoolCtrl.selectedSchool.value?.id;

  /// Returns true only if [id] looks like a 24-char hex MongoDB ObjectId.
  bool _isValidObjectId(String? id) {
    if (id == null || id.isEmpty) return false;
    return RegExp(r'^[a-f\d]{24}$', caseSensitive: false).hasMatch(id);
  }

  /// Extract the MongoDB _id from a config response map.
  /// Tries '_id', 'id', 'configId' in order and validates it looks like an ObjectId.
  String? _extractConfigId(Map<String,dynamic> cfg) {
    for (final key in ['_id', 'id', 'configId']) {
      final val = cfg[key]?.toString();
      if (_isValidObjectId(val)) return val;
    }
    // Log what we actually got so we can debug
    debugPrint('[CONFIG ID SEARCH] Could not find valid ObjectId in cfg keys: ${cfg.keys.toList()}');
    debugPrint('[CONFIG ID SEARCH] cfg values: ${cfg.entries.map((e) => "${e.key}=${e.value}").join(", ")}');
    return null;
  }

  /// Extract roll number from raw API student map.
  String _extractRollNumber(Map<String,dynamic> s) {
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

  // ── Load config ───────────────────────────────────────────────────────────
  Future<void> _loadConfig() async {
    if (_class == null || _schoolId == null) return;
    setState(() => _configLoading = true);
    try {
      // Map<String,dynamic>? cfg = await _fetchConfig(withAcademicYear: true);
      // if (cfg == null) {
      //   debugPrint('[CONFIG] First attempt (with academicYear) returned no data, trying without...');
      //   cfg = await _fetchConfig(withAcademicYear: false);
      // }

      Map<String,dynamic>? cfg = await _fetchConfig(withAcademicYear: true);

      if (cfg != null) {
        final extractedId = _extractConfigId(cfg);
        debugPrint('[CONFIG] Raw cfg: ${cfg.keys.toList()}');
        debugPrint('[CONFIG] Extracted configId=$extractedId');
        setState(() {
          _configId    = extractedId;
          _cfgSubjects = List<Map<String,dynamic>>.from(cfg!['subjects'] ?? []);
          _cfgExams    = List<Map<String,dynamic>>.from(cfg['exams']    ?? []);
        });
        debugPrint('[CONFIG] Loaded: id=$_configId exams=${_cfgExams.length} subjects=${_cfgSubjects.length}');
        if (!_isValidObjectId(_configId)) {
          debugPrint('[CONFIG] WARNING: configId "$_configId" is not a valid ObjectId! Marks save will fail.');
        }
      } else {
        debugPrint('[CONFIG] No config found for class=${_class!.id} school=$_schoolId');
        setState(() { _configId = null; _cfgSubjects = []; _cfgExams = []; });
      }
    } catch (e) {
      debugPrint('[CONFIG error] $e');
      setState(() { _configId = null; _cfgSubjects = []; _cfgExams = []; });
    } finally {
      setState(() => _configLoading = false);
    }
  }

  /// Fetches the config and returns the data map, or null if not found.
  Future<Map<String,dynamic>?> _fetchConfig({required bool withAcademicYear}) async {
    try {
      final params = <String, dynamic>{
        'schoolId': _schoolId!,
        'classId': _class!.id,
        if (withAcademicYear) 'academicYear': _academicYear,
      };
      debugPrint('[CONFIG FETCH] params=$params');
      final resp = await _api.get(ApiConstants.getMarkReportConfigByClass, queryParameters: params);
      debugPrint('[CONFIG FETCH] ok=${resp.data['ok']} hasData=${resp.data['data'] != null}');
      if (resp.data['ok'] == true && resp.data['data'] != null) {
        return resp.data['data'] as Map<String,dynamic>;
      }
    } catch (e) {
      debugPrint('[CONFIG FETCH error withAcademicYear=$withAcademicYear] $e');
    }
    return null;
  }

  Future<void> _saveConfig() async {
    if (_class == null || _schoolId == null) return;
    if (_cfgSubjects.isEmpty || _cfgExams.isEmpty) {
      _snack('Validation', 'Add at least one subject and one exam', error: true); return;
    }
    setState(() => _configSaving = true);
    try {
      if (_configId == null) {
        final resp = await _api.post(ApiConstants.createMarkReportConfig, data: {
          'schoolId': _schoolId!,
          'classId': _class!.id,
          'academicYear': _academicYear,
          'subjects': _cfgSubjects,
          'exams': _cfgExams,
        });
        if (resp.data['ok'] == true) {
          final newId = _extractConfigId(
              (resp.data['data'] as Map<String,dynamic>?) ?? {});
          setState(() => _configId = newId);
          debugPrint('[CONFIG SAVE] Created with id=$_configId');
          _snack('Saved', 'Configuration created');
        } else {
          _snack('Error', resp.data['message'] ?? 'Failed', error: true);
        }
      } else {
        final resp = await _api.put(
          '${ApiConstants.updateMarkReportConfig}/$_configId',
          data: {'subjects': _cfgSubjects, 'exams': _cfgExams},
        );
        if (resp.data['ok'] == true) {
          _snack('Saved', 'Configuration updated');
        } else {
          _snack('Error', resp.data['message'] ?? 'Failed', error: true);
        }
      }
    } on DioException catch (e) {
      final msg = (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : 'HTTP ${e.response?.statusCode}: ${e.message}';
      _snack('Error', msg, error: true);
    } catch (e) {
      debugPrint('[CONFIG SAVE ERROR] $e');
      _snack('Error', e.toString(), error: true);
    } finally {
      setState(() => _configSaving = false);
    }
  }

  // ── Load students ─────────────────────────────────────────────────────────
  Future<void> _loadStudents() async {
    if (_class == null || _schoolId == null) return;
    setState(() {
      _studentsLoading = true;
      _students = [];
      _disposeCells();
      _absent = {};
      _saving = {};
      _expanded = {};
      _reports = {};
    });
    try {
      await _loadConfig();
      debugPrint('[DEBUG] configId=$_configId subjects=${_cfgSubjects.length} exams=${_cfgExams.length}');
      final sResp = await _api.get(ApiConstants.getAllStudents, queryParameters: {
        'schoolId': _schoolId!,
        'classId': _class!.id,
        if (_section != null) 'sectionId': _section!.id,
      });
      if (sResp.data['ok'] == true || sResp.data['data'] != null) {
        setState(() {
          _students = List<Map<String,dynamic>>.from(sResp.data['data'] ?? sResp.data ?? []);
        });
      }
      final rResp = await _api.get(ApiConstants.getAllMarkReportsV1, queryParameters: {
        'schoolId': _schoolId!,
        'classId': _class!.id,
        if (_section != null) 'sectionId': _section!.id,
        'academicYear': _academicYear,
      });
      if (rResp.data['ok'] == true) {
        final list = List<Map<String,dynamic>>.from(rResp.data['data'] ?? []);
        setState(() {
          _reports = {
            for (final r in list)
              (r['studentId'] is Map ? r['studentId']['_id'] : r['studentId'])?.toString() ?? '': r
          };
        });
      }
      _initCells();
    } on DioException catch (e) {
      debugPrint('[LOAD STUDENTS DIO ERROR] ${e.response?.statusCode}: ${e.response?.data}');
      _snack('Error', 'Failed to load students: HTTP ${e.response?.statusCode}', error: true);
    } catch (e) {
      debugPrint('[LOAD STUDENTS ERROR] $e');
      _snack('Error', 'Failed to load students', error: true);
    } finally {
      setState(() { _studentsLoading = false; _showFilters = false; });
    }
  }

  void _initCells() {
    _disposeCells();
    for (final student in _students) {
      final sid = student['_id']?.toString() ?? '';
      final report = _reports[sid];
      final Map<String, Map<String,dynamic>> existing = {};
      if (report != null) {
        for (final er in List<Map<String,dynamic>>.from(report['examRecords'] ?? [])) {
          final en = er['examName']?.toString() ?? '';
          existing[en] = {
            for (final s in List<Map<String,dynamic>>.from(er['subjects'] ?? []))
              (s['subject'] ?? s['subjectName'])?.toString() ?? '': s['marksObtained']
          };
        }
      }
      _cells[sid] = List.generate(_cfgExams.length, (ei) {
        final en = _cfgExams[ei]['examName']?.toString() ?? '';
        return List.generate(_cfgSubjects.length, (si) {
          final sn  = _cfgSubjects[si]['subjectName']?.toString() ?? '';
          final val = existing[en]?[sn];
          final txt = (val != null && val != 0) ? val.toString() : '';
          return TextEditingController(text: txt);
        });
      });
      _absent[sid]   = report?['isAbsent'] ?? false;
      _saving[sid]   = false;
      _expanded[sid] = false;
      _remarks[sid] ??= TextEditingController(text: report?['remarks']?.toString() ?? '');
    }
    setState(() {});
  }

  // ── Save student marks ────────────────────────────────────────────────────
  Future<void> _saveStudent(String sid) async {
    if (!_isValidObjectId(_configId)) {
      _snack(
        'No Config',
        _configId == null
            ? 'Please save the class configuration first'
            : 'Invalid configuration ID "$_configId". Please re-save the configuration.',
        error: true,
      );
      return;
    }
    if (_schoolId == null) return;

    final cells = _cells[sid];
    if (cells == null) {
      _snack('Error', 'Student data not loaded. Please reload students.', error: true);
      return;
    }

    setState(() => _saving[sid] = true);
    try {
      final examRecords = <Map<String,dynamic>>[
        for (int ei = 0; ei < _cfgExams.length; ei++)
          {
            'examName': _cfgExams[ei]['examName'],
            'subjects': [
              for (int si = 0; si < _cfgSubjects.length; si++)
                {
                  'subject'        : _cfgSubjects[si]['subjectName'],
                  'marksObtained'  : int.tryParse(cells[ei][si].text.trim()) ?? 0,
                  'maxMarks'       : _cfgExams[ei]['maxMarks'] ?? 100,
                  'minPassingMarks': _cfgExams[ei]['passingMarks'] ?? 35,
                }
            ],
          }
      ];

      final topLevelSubjects = _cfgSubjects.map((s) => {
        'subject'    : s['subjectName'],
        'subjectCode': s['subjectCode'] ?? '',
      }).toList();

      debugPrint('[MARKS SAVE] sid=$sid exams=${examRecords.length} subjects=${topLevelSubjects.length} configId=$_configId');

      final existing = _reports[sid];
      if (existing != null) {
        // ── UPDATE ──────────────────────────────────────────────────────────
        final rid = existing['_id']?.toString() ?? '';
        debugPrint('[MARKS UPDATE] PUT ${ApiConstants.updateMarkReportV1}/$rid');
        final payload = {
          'schoolId'          : _schoolId!,
          'classId'           : _class!.id,
          if (_section != null) 'sectionId': _section!.id,
          'studentId'         : sid,
          'academicYear'      : _academicYear,
          'markReportConfigId': _configId!,
          'subjects'          : topLevelSubjects,
          'examRecords'       : examRecords,
          'remarks'           : _remarks[sid]?.text.trim() ?? '',
          'isAbsent'          : _absent[sid] ?? false,
        };
        debugPrint('[MARKS UPDATE] payload keys=${payload.keys.toList()} configId=${payload['markReportConfigId']}');
        final resp = await _api.put('${ApiConstants.updateMarkReportV1}/$rid', data: payload);
        debugPrint('[MARKS UPDATE] response ok=${resp.data['ok']} msg=${resp.data['message']}');
        if (resp.data['ok'] == true) {
          if (resp.data['data'] != null) setState(() => _reports[sid] = resp.data['data']);
          _snack('Updated', 'Marks updated successfully');
        } else {
          _snack('Error', resp.data['message']?.toString() ?? 'Failed to update', error: true);
        }
      } else {
        // ── CREATE ──────────────────────────────────────────────────────────
        debugPrint('[MARKS CREATE] POST ${ApiConstants.createMarkReportV1}');
        final payload = {
          'schoolId'          : _schoolId!,
          'classId'           : _class!.id,
          if (_section != null) 'sectionId': _section!.id,
          'studentId'         : sid,
          'academicYear'      : _academicYear,
          'markReportConfigId': _configId!,
          'subjects'          : topLevelSubjects,
          'examRecords'       : examRecords,
          'remarks'           : _remarks[sid]?.text.trim() ?? '',
          'isAbsent'          : _absent[sid] ?? false,
        };
        debugPrint('[MARKS CREATE] payload keys=${payload.keys.toList()} configId=${payload['markReportConfigId']}');
        final resp = await _api.post(ApiConstants.createMarkReportV1, data: payload);
        debugPrint('[MARKS CREATE] response ok=${resp.data['ok']} msg=${resp.data['message']}');
        if (resp.data['ok'] == true) {
          if (resp.data['data'] != null) setState(() => _reports[sid] = resp.data['data']);
          _snack('Saved', 'Marks saved successfully');
        } else {
          _snack('Error', resp.data['message']?.toString() ?? 'Failed to save', error: true);
        }
      }
    } on DioException catch (e) {
      debugPrint('[MARKS DIO ERROR] ${e.response?.statusCode}: ${e.response?.data}');
      final data = e.response?.data;
      final msg  = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'HTTP ${e.response?.statusCode ?? 'error'}: ${e.message ?? 'Network error'}';
      _snack('Error', msg, error: true);
    } catch (e, st) {
      debugPrint('[MARKS ERROR] $e\n$st');
      _snack('Error', e.toString(), error: true);
    } finally {
      setState(() => _saving[sid] = false);
    }
  }

  void _snack(String title, String msg, {bool error = false}) {
    Get.snackbar(title, msg,
        backgroundColor: error ? _kError : _kSuccess,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4));
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _appBar(),
      body: TabBarView(
        controller: _tabCtrl,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _uploadTab(),
          if (_canConfigure) _configTab(),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
    backgroundColor: _kCard,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    automaticallyImplyLeading: false,
    title: const Text('Marks Upload',
        style: TextStyle(color: _kText, fontWeight: FontWeight.w700, fontSize: 18)),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(48),
      child: Container(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
        child: TabBar(
          controller: _tabCtrl,
          indicatorColor: _kPrimary,
          indicatorWeight: 3,
          labelColor: _kPrimary,
          unselectedLabelColor: _kMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: [
            const Tab(icon: Icon(Icons.upload_rounded, size: 16), text: 'Enter Marks'),
            if (_canConfigure) const Tab(icon: Icon(Icons.settings_outlined, size: 16), text: 'Configure'),
          ],
        ),
      ),
    ),
  );

  // ══════════════════════════════════════════════════════════════════
  //  TAB 1 — ENTER MARKS
  // ══════════════════════════════════════════════════════════════════
  Widget _uploadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(children: [
        if (_showFilters || _students.isEmpty) _filterCard(),
        if (!_showFilters && _students.isNotEmpty) ...[_filterSummary(), const SizedBox(height: 12)],
        if (_studentsLoading)
          const Padding(padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator(color: _kPrimary)))
        else if (!_showFilters && _students.isEmpty)
          _emptyState()
        else if (_students.isNotEmpty) ...[
            if (!_isValidObjectId(_configId) && !_configLoading) _configBanner(),
            const SizedBox(height: 4),
            ..._students.map(_studentCard),
          ],
      ]),
    );
  }

  Widget _configBanner() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFBEB),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFFCD34D)),
    ),
    child: Row(children: [
      const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(
        _canConfigure
            ? 'No valid configuration found for this class. Tap "Configure" tab to set up subjects & exams.'
            : 'No configuration found for this class. Please ask your administrator to set it up.',
        style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
      )),
      if (_canConfigure) ...[
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _tabCtrl.animateTo(1),
          child: const Text('Set up', style: TextStyle(fontSize: 12, color: _kPrimary, fontWeight: FontWeight.w700)),
        ),
      ],
    ]),
  );

  Widget _filterCard() => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _kCard,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader(Icons.filter_list_rounded, 'Filters & Settings'),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _dropdown('Class', _class?.name ?? 'Select', Icons.school_outlined, _classPicker)),
        const SizedBox(width: 12),
        Expanded(child: _dropdown('Section', _section?.name ?? 'All', Icons.group_outlined, _sectionPicker)),
      ]),
      const SizedBox(height: 12),
      _dropdown('Academic Year', _academicYear, Icons.calendar_today_outlined, _yearPicker),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _class == null ? null : _loadStudents,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            disabledBackgroundColor: _kBlueBorder,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
          label: const Text('Load Students',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
        ),
      ),
    ]),
  );

  Widget _filterSummary() => GestureDetector(
    onTap: () => setState(() => _showFilters = true),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kLightBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBlueBorder),
      ),
      child: Row(children: [
        const Icon(Icons.filter_list_rounded, color: _kPrimary, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(
          '${_class?.name ?? ''} · ${_section?.name ?? 'All sections'} · $_academicYear',
          style: const TextStyle(fontSize: 13, color: _kText, fontWeight: FontWeight.w500),
        )),
        const Text('Change', style: TextStyle(fontSize: 12, color: _kPrimary, fontWeight: FontWeight.w600)),
      ]),
    ),
  );

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(children: [
        Container(width: 80, height: 80,
            decoration: BoxDecoration(color: _kLightBlue, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.upload_file_rounded, color: _kPrimary, size: 40)),
        const SizedBox(height: 16),
        const Text('No Students Loaded',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kText)),
        const SizedBox(height: 6),
        const Text('Select filters above and tap\n"Load Students" to begin',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _kMuted)),
      ]),
    ),
  );

  Widget _studentCard(Map<String,dynamic> student) {
    final sid  = student['_id']?.toString() ?? '';
    final name = student['name']?.toString()
        ?? student['studentName']?.toString()
        ?? student['fullName']?.toString()
        ?? student['userName']?.toString()
        ?? 'Unknown';
    final roll = _extractRollNumber(student);
    final isExp    = _expanded[sid] ?? false;
    final isSaving = _saving[sid]   ?? false;
    final hasReport = _reports.containsKey(sid);
    final isAbsent  = _absent[sid] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: hasReport ? Border.all(color: const Color(0xFF86EFAC), width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0,2))],
      ),
      child: Column(children: [
        // Header row
        GestureDetector(
          onTap: () {
            if (_cfgSubjects.isEmpty || _cfgExams.isEmpty) {
              _snack('No Config', 'Set up class configuration first', error: true); return;
            }
            setState(() => _expanded[sid] = !isExp);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(color: _kLightBlue, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w800, fontSize: 16),
                )),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _kText)),
                Text('Roll No: $roll', style: const TextStyle(fontSize: 12, color: _kMuted)),
              ])),
              if (hasReport)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Saved', style: TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.w600)),
                ),
              const SizedBox(width: 8),
              Icon(isExp ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: _kMuted, size: 22),
            ]),
          ),
        ),

        // Expanded content
        if (isExp) ...[
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Absent toggle
              Row(children: [
                const Icon(Icons.event_busy_outlined, size: 15, color: _kMuted),
                const SizedBox(width: 6),
                const Text('Mark as Absent', style: TextStyle(fontSize: 13, color: _kText, fontWeight: FontWeight.w500)),
                const Spacer(),
                Switch.adaptive(value: isAbsent,
                    activeColor: _kError,
                    onChanged: (v) => setState(() => _absent[sid] = v)),
              ]),

              if (!isAbsent) ...[
                const SizedBox(height: 10),
                _marksMatrix(sid),
                const SizedBox(height: 12),
                _remarksField(sid),
              ] else ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline_rounded, size: 15, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Text('Student is absent for this exam.',
                        style: TextStyle(fontSize: 12, color: Colors.red[700])),
                  ]),
                ),
              ],

              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : () => _saveStudent(sid),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: isSaving
                      ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(hasReport ? 'Update Marks' : 'Save Marks',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _marksMatrix(String sid) {
    final cells = _cells[sid];
    if (cells == null || _cfgExams.isEmpty || _cfgSubjects.isEmpty) {
      return const Text('No configuration available.', style: TextStyle(color: _kMuted, fontSize: 12));
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _kBlueBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              color: _kLightBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(children: [
              const SizedBox(width: 110,
                  child: Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Text('Subject', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kMuted)))),
              ..._cfgExams.map((e) => Container(
                width: 90,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Text(e['examName']?.toString() ?? '',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kPrimary),
                    maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
              )),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          // Data rows
          ...List.generate(_cfgSubjects.length, (si) {
            final sn = _cfgSubjects[si]['subjectName']?.toString() ?? '';
            final isLast = si == _cfgSubjects.length - 1;
            return Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                SizedBox(width: 110,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(sn,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _kText),
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
                ...List.generate(_cfgExams.length, (ei) {
                  final max = (_cfgExams[ei]['maxMarks'] ?? 100).toString();
                  return Container(
                    width: 90,
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                    child: TextField(
                      controller: cells[ei][si],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kText),
                      decoration: InputDecoration(
                        hintText: '/$max',
                        hintStyle: TextStyle(fontSize: 10, color: _kMuted.withOpacity(0.55)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFF),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
                        ),
                      ),
                    ),
                  );
                }),
              ]),
              if (!isLast) const Divider(height: 1, color: Color(0xFFF3F4F6)),
            ]);
          }),
        ]),
      ),
    );
  }

  Widget _remarksField(String sid) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Remarks (optional)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kMuted)),
      const SizedBox(height: 6),
      TextField(
        controller: _remarks[sid],
        maxLines: 2,
        style: const TextStyle(fontSize: 13, color: _kText),
        decoration: InputDecoration(
          hintText: 'e.g. Student performed well...',
          hintStyle: TextStyle(color: _kMuted.withOpacity(0.7), fontSize: 12),
          filled: true, fillColor: _kLightBlue,
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
        ),
      ),
    ],
  );

  // ══════════════════════════════════════════════════════════════════
  //  TAB 2 — CONFIGURE
  // ══════════════════════════════════════════════════════════════════
  Widget _configTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(children: [
        if (_class == null) _selectClassFirst(),
        if (_class != null) ...[
          _configInfoCard(),
          const SizedBox(height: 12),
          _configLoading
              ? const Center(child: Padding(padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: _kPrimary)))
              : Column(children: [
            _panel(
              title: 'SUBJECTS (ROWS)',
              icon: Icons.table_rows_outlined,
              onAdd: _addSubjectSheet,
              children: [
                ..._cfgSubjects.asMap().entries.map((e) => _subjectRow(e.key, e.value)),
                if (_cfgSubjects.isEmpty) _emptyHint('No subjects yet. Tap + Add to create one.'),
              ],
            ),
            const SizedBox(height: 12),
            _panel(
              title: 'EXAMS (COLUMNS)',
              icon: Icons.view_column_outlined,
              onAdd: _addExamSheet,
              children: [
                ..._cfgExams.asMap().entries.map((e) => _examRow(e.key, e.value)),
                if (_cfgExams.isEmpty) _emptyHint('No exams yet. Tap + Add to create one.'),
              ],
            ),
            const SizedBox(height: 12),
            _matrixPreview(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_configSaving || _class == null) ? null : _saveConfig,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kDark,
                  disabledBackgroundColor: _kMuted,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: _configSaving
                    ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                label: Text(
                  _configId == null ? 'Create Configuration' : 'Update Configuration',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ]),
        ],
      ]),
    );
  }

  Widget _selectClassFirst() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _kLightBlue,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _kBlueBorder),
    ),
    child: Column(children: [
      const Icon(Icons.school_outlined, color: _kPrimary, size: 36),
      const SizedBox(height: 10),
      const Text('Select a Class First', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _kText)),
      const SizedBox(height: 6),
      const Text('Go to "Enter Marks" tab and select a class to configure.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _kMuted)),
      const SizedBox(height: 14),
      TextButton(
        onPressed: () => _tabCtrl.animateTo(0),
        style: TextButton.styleFrom(
          backgroundColor: _kPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('Go to Enter Marks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    ]),
  );

  Widget _configInfoCard() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: _kCard,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _kBlueBorder),
    ),
    child: Row(children: [
      Container(width: 36, height: 36,
          decoration: BoxDecoration(color: _kLightBlue, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.table_chart_outlined, color: _kPrimary, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${_class?.name ?? ''} · $_academicYear',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _kText)),
        const Text('Configure subjects and exams to generate the report matrix.',
            style: TextStyle(fontSize: 11, color: _kMuted)),
      ])),
      if (_isValidObjectId(_configId))
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: _kLightBlue, borderRadius: BorderRadius.circular(20), border: Border.all(color: _kBlueBorder)),
          child: const Text('Configured', style: TextStyle(fontSize: 10, color: _kPrimary, fontWeight: FontWeight.w600)),
        ),
    ]),
  );

  Widget _panel({
    required String title,
    required IconData icon,
    required VoidCallback onAdd,
    required List<Widget> children,
  }) => Container(
    decoration: BoxDecoration(
      color: _kCard,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0,2))],
    ),
    child: Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Icon(icon, color: _kPrimary, size: 18),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _kText, letterSpacing: 0.4)),
          const Spacer(),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _kLightBlue,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kBlueBorder),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, color: _kPrimary, size: 14),
                SizedBox(width: 4),
                Text('Add', style: TextStyle(fontSize: 12, color: _kPrimary, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),
      ),
      const Divider(height: 1, color: Color(0xFFE5E7EB)),
      Padding(padding: const EdgeInsets.all(12), child: Column(children: children)),
    ]),
  );

  Widget _subjectRow(int i, Map<String,dynamic> s) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: _kLightBlue,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _kBlueBorder),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s['subjectName']?.toString() ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _kText)),
        if ((s['subjectCode']?.toString() ?? '').isNotEmpty)
          Text(s['subjectCode']?.toString() ?? '',
              style: const TextStyle(fontSize: 11, color: _kMuted)),
      ])),
      _orderBadge('${i + 1}'),
      const SizedBox(width: 8),
      GestureDetector(
          onTap: () => setState(() => _cfgSubjects.removeAt(i)),
          child: const Icon(Icons.delete_outline_rounded, color: _kError, size: 18)),
    ]),
  );

  Widget _examRow(int i, Map<String,dynamic> e) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _kLightBlue,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _kBlueBorder),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(e['examName']?.toString() ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _kText)),
        const SizedBox(height: 4),
        Wrap(spacing: 6, children: [
          _chip('Max: ${e['maxMarks'] ?? 100}'),
          _chip('Pass: ${e['passingMarks'] ?? 35}'),
        ]),
      ])),
      _orderBadge('${i + 1}'),
      const SizedBox(width: 8),
      GestureDetector(
          onTap: () => setState(() => _cfgExams.removeAt(i)),
          child: const Icon(Icons.delete_outline_rounded, color: _kError, size: 18)),
    ]),
  );

  Widget _orderBadge(String n) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
    child: Text(n, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kMuted)),
  );

  Widget _chip(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
    child: Text(t, style: const TextStyle(fontSize: 11, color: _kMuted)),
  );

  Widget _emptyHint(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Center(child: Text(text, style: const TextStyle(fontSize: 12, color: _kMuted))),
  );

  Widget _matrixPreview() => Container(
    decoration: BoxDecoration(
      color: _kCard,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0,2))],
    ),
    child: Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          const Icon(Icons.grid_on_rounded, color: _kPrimary, size: 18),
          const SizedBox(width: 8),
          const Text('Live Matrix Preview',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _kText)),
        ]),
      ),
      const Divider(height: 1, color: Color(0xFFE5E7EB)),
      if (_cfgSubjects.isEmpty || _cfgExams.isEmpty)
        _emptyHint('Add subjects and exams above to see the preview.')
      else
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder.all(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(4)),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: _kLightBlue),
                children: [
                  _tCell('SUBJECTS', isHeader: true),
                  ..._cfgExams.map((e) {
                    final n    = e['examName']?.toString() ?? '';
                    final max  = e['maxMarks'] ?? 100;
                    final pass = e['passingMarks'] ?? 35;
                    return _tCell('$n\nMax: $max | Pass: $pass', isHeader: true);
                  }),
                ],
              ),
              ..._cfgSubjects.map((s) => TableRow(children: [
                _tCell(s['subjectName']?.toString() ?? '', isSub: true),
                ..._cfgExams.map((_) => _tCell('Empty', isEmpty: true)),
              ])),
            ],
          ),
        ),
    ]),
  );

  Widget _tCell(String t, {bool isHeader = false, bool isSub = false, bool isEmpty = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(t,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isEmpty ? 11 : (isHeader ? 10 : 12),
              fontWeight: isHeader || isSub ? FontWeight.w700 : FontWeight.w400,
              color: isEmpty ? _kMuted : (isHeader ? _kPrimary : _kText),
            )),
      );

  // ── Shared helpers ────────────────────────────────────────────────────────
  Widget _sectionHeader(IconData icon, String label) => Row(children: [
    Container(width: 30, height: 30,
        decoration: BoxDecoration(color: _kLightBlue, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: _kPrimary, size: 16)),
    const SizedBox(width: 10),
    Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _kText)),
  ]);

  Widget _dropdown(String label, String value, IconData icon, VoidCallback onTap) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kMuted)),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: _kLightBlue,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBlueBorder),
            ),
            child: Row(children: [
              Icon(icon, color: _kPrimary, size: 15),
              const SizedBox(width: 8),
              Expanded(child: Text(value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kText),
                  overflow: TextOverflow.ellipsis)),
              const Icon(Icons.keyboard_arrow_down_rounded, color: _kMuted, size: 18),
            ]),
          ),
        ),
      ]);

  // ── Bottom Sheets ─────────────────────────────────────────────────────────
  void _addSubjectSheet() {
    _subNameCtrl.clear(); _subCodeCtrl.clear();
    _sheet('Add Subject', [
      _sheetField('Subject Name *', _subNameCtrl, hint: 'e.g. Mathematics'),
      const SizedBox(height: 12),
      _sheetField('Subject Code', _subCodeCtrl, hint: 'e.g. MTH-101'),
    ], onSave: () {
      if (_subNameCtrl.text.trim().isEmpty) { _snack('Error', 'Name required', error: true); return; }
      setState(() => _cfgSubjects.add({
        'subjectName': _subNameCtrl.text.trim(),
        'subjectCode': _subCodeCtrl.text.trim(),
        'order': _cfgSubjects.length + 1,
      }));
      Get.back();
    });
  }

  void _addExamSheet() {
    _examNameCtrl.clear(); _examMaxCtrl.text = '100'; _examPassCtrl.text = '35';
    _sheet('Add Exam', [
      _sheetField('Exam Name *', _examNameCtrl, hint: 'e.g. I Mid Term'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _sheetField('Max Marks', _examMaxCtrl, hint: '100', numeric: true)),
        const SizedBox(width: 12),
        Expanded(child: _sheetField('Pass Marks', _examPassCtrl, hint: '35', numeric: true)),
      ]),
    ], onSave: () {
      if (_examNameCtrl.text.trim().isEmpty) { _snack('Error', 'Name required', error: true); return; }
      setState(() => _cfgExams.add({
        'examName'    : _examNameCtrl.text.trim(),
        'maxMarks'    : int.tryParse(_examMaxCtrl.text) ?? 100,
        'passingMarks': int.tryParse(_examPassCtrl.text) ?? 35,
        'order'       : _cfgExams.length + 1,
      }));
      Get.back();
    });
  }

  void _sheet(String title, List<Widget> children, {required VoidCallback onSave}) {
    Get.bottomSheet(
      Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(Get.context!).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: _kText)),
              const Spacer(),
              GestureDetector(onTap: () => Get.back(), child: const Icon(Icons.close_rounded, color: _kMuted)),
            ]),
            const SizedBox(height: 16),
            ...children,
            const SizedBox(height: 20),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _sheetField(String label, TextEditingController ctrl, {String? hint, bool numeric = false}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kMuted)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 14, color: _kText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _kMuted.withOpacity(0.7)),
            filled: true, fillColor: _kLightBlue,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
          ),
        ),
      ]);

  // ── Pickers ───────────────────────────────────────────────────────────────
  void _classPicker() {
    final list = _schoolCtrl.classes;
    if (list.isEmpty) { _snack('No Classes', 'No classes available', error: true); return; }
    _picker('Select Class', list.map((c) => c.name).toList(), (i) {
      final school = _schoolCtrl.selectedSchool.value;
      setState(() { _class = list[i]; _section = null; _students = []; _showFilters = true; });
      if (school != null) _schoolCtrl.getAllSections(classId: list[i].id, schoolId: school.id);
      Get.back();
    });
  }

  void _sectionPicker() {
    if (_class == null) { _snack('Select Class', 'Select a class first', error: true); return; }
    final list = _schoolCtrl.sections.where((s) => s.classId == _class!.id).toList();
    _picker('Select Section', ['All Sections', ...list.map((s) => s.name)], (i) {
      setState(() => _section = i == 0 ? null : list[i - 1]);
      Get.back();
    });
  }

  void _yearPicker() {
    const years = ['2023-2024', '2024-2025', '2025-2026', '2026-2027'];
    _picker('Academic Year', years, (i) { setState(() => _academicYear = years[i]); Get.back(); });
  }

  void _picker(String title, List<String> items, void Function(int) onSelect) {
    Get.bottomSheet(Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _kText)),
        ),
        const Divider(height: 1),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(items[i], style: const TextStyle(fontSize: 14, color: _kText)),
              trailing: const Icon(Icons.chevron_right_rounded, color: _kMuted, size: 18),
              onTap: () => onSelect(i),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    ));
  }
}

// ─── Extension ────────────────────────────────────────────────────────────────
extension _Ext<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) { if (test(e)) return e; }
    return null;
  }
}
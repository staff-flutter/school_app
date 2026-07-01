import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/api_constants.dart';
import '../controllers/auth_controller.dart';
import '../controllers/school_controller.dart';
import '../models/school_models.dart';
import '../models/student_model.dart';
import '../services/api_service.dart';
import 'create_student_profile_page.dart';

// =============================================================================
// DESIGN TOKENS
// =============================================================================
const _kPrimary = Color(0xFF1565C0);
const _kPrimaryLight = Color(0xFFE3EEF9);
const _kPrimaryMid = Color(0xFF1976D2);
const _kPrimaryDark = Color(0xFF0D47A1);
const _kSurface = Color(0xFFF5F7FA);
const _kCard = Color(0xFFFFFFFF);
const _kSectionBg = Color(0xFFF0F4FA);
const _kTextPrimary = Color(0xFF1A2340);
const _kTextSecondary = Color(0xFF5B6880);
const _kTextHint = Color(0xFF9AA5B4);
const _kBorder = Color(0xFFDDE3EC);
const _kSuccess = Color(0xFF2E7D32);
const _kSuccessBg = Color(0xFFE8F5E9);
const _kError = Color(0xFFC62828);
const _kErrorBg = Color(0xFFFFEBEE);

// =============================================================================
// HELPERS
// =============================================================================
/// Some endpoints (e.g. /api/studentrecord/v1/getall) may nest the core
/// student-profile fields under a `student` key, while others return them
/// flat. This merges both shapes so field lookups work either way, with
/// top-level keys taking precedence.
Map<String, dynamic> _studentData(Map<String, dynamic> raw) {
  final inner = raw['student'];
  if (inner is Map) {
    return {...Map<String, dynamic>.from(inner), ...raw};
  }
  return raw;
}

// =============================================================================
// PAGE
// =============================================================================
class StudentProfileManagementPage extends StatefulWidget {
  const StudentProfileManagementPage({super.key});

  @override
  State<StudentProfileManagementPage> createState() =>
      _StudentProfileManagementPageState();
}

class _StudentProfileManagementPageState
    extends State<StudentProfileManagementPage> {
  final _api = Get.find<ApiService>();
  final _auth = Get.find<AuthController>();
  final _school = Get.find<SchoolController>();

  // ── Filter state ──────────────────────────────────────────────────────────
  SchoolClass? _selClass;
  Section? _selSection;
  final _searchCtrl = TextEditingController();
  String _search = '';

  // ── Data state ────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _students = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _limit = 20;

  // ── Per-row delete state ──────────────────────────────────────────────────
  String? _deletingId;

  // ── Per-row "opening edit" loading state ────────────────────────────────────
  String? _openingId;

  // ── Role helpers ──────────────────────────────────────────────────────────
  String get _role => _auth.user.value?.role?.toLowerCase() ?? '';
  bool get _canDelete => _role == 'correspondent';
  bool get _canEdit =>
      ['correspondent', 'administrator', 'accountant'].contains(_role);

  String? get _schoolId {
    if (_role == 'correspondent') return _school.selectedSchool.value?.id;
    return _auth.user.value?.schoolId;
  }

  // ── Debounce ──────────────────────────────────────────────────────────────
  DateTime _lastSearch = DateTime.now();

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureSchoolLoaded();
      _loadStudents(reset: true);
    });
  }

  void _onSearchChanged() {
    final v = _searchCtrl.text.trim();
    if (v == _search) return;
    setState(() => _search = v);
    _lastSearch = DateTime.now();
    Future.delayed(const Duration(milliseconds: 420), () {
      if (DateTime.now().difference(_lastSearch).inMilliseconds >= 400) {
        _loadStudents(reset: true);
      }
    });
  }

  Future<void> _ensureSchoolLoaded() async {
    try {
      if (_school.schools.isEmpty) await _school.getAllSchools();
      if (_school.selectedSchool.value == null &&
          _school.schools.isNotEmpty) {
        final uid = _auth.user.value?.schoolId;
        if (uid != null) {
          _school.selectedSchool.value =
              _school.schools.firstWhereOrNull((s) => s.id == uid) ??
                  _school.schools.first;
        } else {
          _school.selectedSchool.value = _school.schools.first;
        }
      }

      final sid = _schoolId;
      if (sid != null && _school.classes.isEmpty) {
        await _school.getAllClasses(sid);
      }
    } catch (e) {
      debugPrint('[MGMT] ensureSchoolLoaded: $e');
    }
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── API: load students ─────────────────────────────────────────────────────
  Future<void> _loadStudents({bool reset = false}) async {
    if (_loading) return;
    if (reset) {
      setState(() {
        _students = [];
        _page = 1;
        _hasMore = true;
      });
    }
    if (!_hasMore && !reset) return;

    final sid = _schoolId;
    if (sid == null) return;

    setState(() => _loading = true);
    try {
      final q = <String, dynamic>{
        'schoolId': sid,
        'page': _page,
        'limit': _limit,
        if (_selClass != null) 'classId': _selClass!.id,
        if (_selSection != null) 'sectionId': _selSection!.id,
        if (_search.isNotEmpty) 'search': _search,
      };

      debugPrint('[MGMT] GET ${ApiConstants.getAllStudents}: $q');
      final resp = await _api.get(ApiConstants.getAllStudents,
          queryParameters: q);

      debugPrint('[MGMT] ok=${resp.data['ok']} '
          'count=${(resp.data['data'] as List?)?.length ?? 0}');

      if (resp.data['ok'] == true) {
        final list =
        List<Map<String, dynamic>>.from(resp.data['data'] ?? []);
        if (reset && list.isNotEmpty) {
          debugPrint('[MGMT] sample record keys: '
              '${_studentData(list.first).keys.toList()}');
        }

        setState(() {
          if (reset) {
            _students = list;
          } else {
            _students.addAll(list);
          }
          _hasMore = list.length >= _limit;
          _page++;
        });
      }
    } on dio_pkg.DioException catch (e) {
      debugPrint('[MGMT] load DioException '
          '${e.response?.statusCode}: ${e.response?.data}');
      _snack('Error',
          'Failed to load students: HTTP ${e.response?.statusCode}',
          error: true);
    } catch (e) {
      debugPrint('[MGMT] load error: $e');
      _snack('Error', 'Failed to load students', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── API: delete student ────────────────────────────────────────────────────
  Future<void> _deleteStudent(String studentId, String name) async {
    final ok = await Get.dialog<bool>(AlertDialog(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Student',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary)),
      content: RichText(
        text: TextSpan(
          style: const TextStyle(
              fontSize: 14, color: _kTextSecondary, height: 1.5),
          children: [
            const TextSpan(text: 'Delete profile for '),
            TextSpan(
                text: name,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: _kTextPrimary)),
            const TextSpan(text: '?\nThis action cannot be undone.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('Cancel',
              style: TextStyle(color: _kTextSecondary)),
        ),
        ElevatedButton(
          onPressed: () => Get.back(result: true),
          style: ElevatedButton.styleFrom(
              backgroundColor: _kError,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          child: const Text('Delete',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ));

    if (ok != true) return;

    setState(() => _deletingId = studentId);
    try {
      debugPrint('[MGMT] DELETE ${ApiConstants.deleteStudent}/$studentId');
      final resp =
      await _api.delete('${ApiConstants.deleteStudent}/$studentId');
      debugPrint('[MGMT] delete ok=${resp.data['ok']}');

      if (resp.data['ok'] == true) {
        setState(() => _students
            .removeWhere((s) => s['_id']?.toString() == studentId));
        _snack('Deleted', '"$name" has been removed');
      } else {
        _snack('Error',
            resp.data['message']?.toString() ?? 'Delete failed',
            error: true);
      }
    } on dio_pkg.DioException catch (e) {
      debugPrint('[MGMT] delete DioException '
          '${e.response?.statusCode}: ${e.response?.data}');
      final msg =
      (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : 'HTTP ${e.response?.statusCode}: Delete failed';
      _snack('Error', msg, error: true);
    } catch (e) {
      debugPrint('[MGMT] delete error: $e');
      _snack('Error', e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  // ── Navigate to edit ───────────────────────────────────────────────────────
  Future<void> _openEdit(Map<String, dynamic> raw) async {
    final sd = _studentData(raw);
    final studentId = (sd['_id'] ?? raw['_id'])?.toString();
    Map<String, dynamic> fullData = sd;

    if (studentId != null) {
      setState(() => _openingId = studentId);
      try {
        // FIX: Use the correct endpoint to fetch the full student profile
        // (including mandatory/nonMandatory, studentImage, documents).
        // The previous endpoint (/api/studentrecord/v1/getrecord) only returns
        // fee/academic record data and lacks the profile fields.
        final endpoint = '/api/student/get/$studentId';

        // Note: If you have this defined in ApiConstants, you can use:
        // final endpoint = '${ApiConstants.getStudent}/$studentId';

        debugPrint('[MGMT] GET $endpoint');
        final resp = await _api.get(endpoint);
        debugPrint('[MGMT] getstudent ok=${resp.data['ok']}');

        if (resp.data['ok'] == true && resp.data['data'] is Map) {
          fullData =
              _studentData(Map<String, dynamic>.from(resp.data['data']));
          debugPrint('[MGMT] getstudent keys: ${fullData.keys.toList()}');
        }
      } on dio_pkg.DioException catch (e) {
        debugPrint('[MGMT] getstudent DioException '
            '${e.response?.statusCode}: ${e.response?.data}');
      } catch (e) {
        debugPrint('[MGMT] getstudent error: $e');
      } finally {
        if (mounted) setState(() => _openingId = null);
      }
    }

    final student = _buildStudent(fullData);
    final imageUrl = extractProfileImageUrl(fullData);
    final docsRaw = fullData['documents'] ??
        fullData['files'] ??
        fullData['uploadedFiles'] ??
        fullData['attachments'] ??
        fullData['workPhotos'];

    final documents = (docsRaw is List)
        ? docsRaw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
        : <Map<String, dynamic>>[];

    if (!mounted) return;
    final result = await Get.to<bool>(
          () => CreateStudentProfilePage(
        schoolId: _schoolId,
        student: student,
        isEdit: true,
        existingImageUrl: imageUrl,
        existingDocuments: documents,
      ),
    );
    if (result == true) _loadStudents(reset: true);
  }

  /// Constructs a [Student] from the nested API response.
  Student _buildStudent(Map<String, dynamic> data) {
    final m = (data['mandatory'] as Map<String, dynamic>?) ?? {};
    final nm = (data['nonMandatory'] as Map<String, dynamic>?) ?? {};

    String? s(dynamic v) =>
        v?.toString()?.isNotEmpty == true ? v.toString() : null;
    String? id(dynamic v) => v is Map ? s(v['_id']) : s(v);

    return Student(
      id: s(data['_id']) ?? '',
      name: s(data['studentName']),
      srId: s(data['srId']),
      isActive: data['isActive'] as bool? ?? true,
      classId: id(data['currentClassId']),
      sectionId: id(data['currentSectionId']),
      // mandatory
      gender: s(m['gender']),
      dob: s(m['dob']),
      educationNumber: s(m['educationNumber']),
      motherName: s(m['motherName']),
      fatherName: s(m['fatherName']),
      guardianName: s(m['guardianName']),
      aadhaarNumber: s(m['aadhaarNumber']),
      aadhaarName: s(m['aadhaarName']),
      address: s(m['address']),
      pincode: s(m['pincode']),
      mobileNumber: s(m['mobileNumber']),
      alternateMobile: s(m['alternateMobile']),
      email: s(m['email']),
      motherTongue: s(m['motherTongue']),
      socialCategory: s(m['socialCategory']),
      minorityGroup: s(m['minorityGroup']),
      bpl: s(m['bpl']),
      aay: s(m['aay']),
      ews: s(m['ews']),
      cwsn: s(m['cwsn']),
      impairments: s(m['impairments']),
      indian: s(m['indian']),
      outOfSchool: s(m['outOfSchool']),
      mainstreamedDate: s(m['mainstreamedDate']),
      disabilityCert: s(m['disabilityCert']),
      disabilityPercent: s(m['disabilityPercent']),
      bloodGroup: s(m['bloodGroup']),
      // non-mandatory
      facilitiesProvided: s(nm['facilitiesProvided']),
      facilitiesForCWSN: s(nm['facilitiesForCWSN']),
      screenedForSLD: s(nm['screenedForSLD']),
      sldType: s(nm['sldType']),
      screenedForASD: s(nm['screenedForASD']),
      screenedForADHD: s(nm['screenedForADHD']),
      isGiftedOrTalented: s(nm['isGiftedOrTalented']),
      participatedInCompetitions: s(nm['participatedInCompetitions']),
      participatedInActivities: s(nm['participatedInActivities']),
      canHandleDigitalDevices: s(nm['canHandleDigitalDevices']),
      heightInCm: s(nm['heightInCm']),
      weightInKg: s(nm['weightInKg']),
      distanceToSchool: s(nm['distanceToSchool']),
      parentEducationLevel: s(nm['parentEducationLevel']),
      admissionNumber: s(nm['admissionNumber']),
      admissionDate: s(nm['admissionDate']),
      rollNumber: s(nm['rollNumber']),
      mediumOfInstruction: s(nm['mediumOfInstruction']),
      languagesStudied: s(nm['languagesStudied']),
      academicStream: s(nm['academicStream']),
      subjectsStudied: s(nm['subjectsStudied']),
      statusInPreviousYear: s(nm['statusInPreviousYear']),
      gradeStudiedLastYear: s(nm['gradeStudiedLastYear']),
      enrolledUnder: s(nm['enrolledUnder']),
      previousResult: s(nm['previousResult']),
      marksObtainedPercentage: s(nm['marksObtainedPercentage']),
      daysAttendedLastYear: s(nm['daysAttendedLastYear']),
    );
  }

  void _snack(String title, String msg, {bool error = false}) =>
      Get.snackbar(title, msg,
          backgroundColor: error ? _kError : _kSuccess,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3));

  // ==========================================================================
  // BUILD
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Get.to<bool>(
                () => CreateStudentProfilePage(schoolId: _schoolId),
          );
          if (result == true) _loadStudents(reset: true);
        },
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.person_add_rounded, size: 20),
        label: const Text('Add Student',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
      body: Column(children: [
        _buildTopBar(),
        Expanded(
          child: RefreshIndicator(
            color: _kPrimary,
            onRefresh: () => _loadStudents(reset: true),
            child: _students.isEmpty && !_loading
                ? _buildEmptyState()
                : _buildList(),
          ),
        ),
      ]),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: _kPrimary,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Student Profile Management',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        Text(
          _loading
              ? 'Loading…'
              : '${_students.length} student${_students.length == 1 ? '' : 's'}'
              '${_selClass != null ? " · ${_selClass!.name}" : ""}'
              '${_selSection != null ? " · Sec ${_selSection!.name}" : ""}',
          style: TextStyle(
              fontSize: 11, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.refresh_rounded, size: 20),
        tooltip: 'Refresh',
        onPressed: () => _loadStudents(reset: true),
      ),
    ],
  );

  // ── Filter / search bar ────────────────────────────────────────────────────
  Widget _buildTopBar() => Container(
    color: _kPrimary,
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    child: Column(children: [
      _SearchBar(
          ctrl: _searchCtrl,
          onClear: () {
            _searchCtrl.clear();
            setState(() => _search = '');
            _loadStudents(reset: true);
          }),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: _ClassChip(
            selected: _selClass,
            onTap: _showClassPicker,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SectionChip(
            selected: _selSection,
            enabled: _selClass != null,
            onTap: _selClass == null ? null : _showSectionPicker,
            onClear: () {
              setState(() => _selSection = null);
              _loadStudents(reset: true);
            },
          ),
        ),
      ]),
    ]),
  );

  // ── List ───────────────────────────────────────────────────────────────────
  Widget _buildList() {
    if (_loading && _students.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: _kPrimary));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      itemCount: _students.length + (_hasMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _students.length) {
          if (!_loading) _loadStudents();
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
                child: CircularProgressIndicator(
                    color: _kPrimary, strokeWidth: 2)),
          );
        }

        final raw = _students[i];
        final sd = _studentData(raw);
        final studentId = (sd['_id'] ?? raw['_id'])?.toString();

        return _StudentCard(
          raw: raw,
          canEdit: _canEdit,
          canDelete: _canDelete,
          isDeleting: _deletingId == studentId,
          isOpening: _openingId == studentId,
          onEdit: () => _openEdit(raw),
          onDelete: () {
            final sidVal = studentId ?? '';
            final name = sd['studentName']?.toString() ?? 'Student';
            _deleteStudent(sidVal, name);
          },
        );
      },
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: _kPrimaryLight,
                borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.people_outline_rounded,
                size: 40, color: _kPrimary),
          ),
          const SizedBox(height: 20),
          const Text('No Students Found',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary)),
          const SizedBox(height: 6),
          Text(
            _search.isNotEmpty || _selClass != null
                ? 'Try adjusting filters or clearing search.'
                : 'Tap "Add Student" to create the first profile.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: _kTextSecondary),
          ),
        ],
      ),
    ),
  );

  // ── Pickers ────────────────────────────────────────────────────────────────
  void _showClassPicker() {
    final classes = _school.classes.toList();
    Get.bottomSheet(
      _PickerSheet(
        title: 'Select Class',
        showAll: true,
        allLabel: 'All Classes',
        allSelected: _selClass == null,
        onAllTap: () {
          setState(() {
            _selClass = null;
            _selSection = null;
          });
          _loadStudents(reset: true);
          Get.back();
        },
        items: classes
            .map((c) => _PickerItem(
          label: c.name,
          selected: _selClass?.id == c.id,
          onTap: () {
            setState(() {
              _selClass = c;
              _selSection = null;
            });
            _school.getAllSections(
                classId: c.id, schoolId: _schoolId);
            _loadStudents(reset: true);
            Get.back();
          },
        ))
            .toList(),
      ),
    );
  }

  void _showSectionPicker() {
    final sections = _school.sections.toList();
    if (sections.isEmpty) {
      _snack('No Sections',
          'No sections available for ${_selClass!.name}');
      return;
    }

    Get.bottomSheet(
      _SectionGridSheet(
        sections: sections,
        selected: _selSection,
        onSelect: (sec) {
          setState(() => _selSection = sec);
          _loadStudents(reset: true);
          Get.back();
        },
      ),
    );
  }
}

// =============================================================================
// STUDENT CARD
// =============================================================================
class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> raw;
  final bool canEdit;
  final bool canDelete;
  final bool isDeleting;
  final bool isOpening;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudentCard({
    required this.raw,
    required this.canEdit,
    required this.canDelete,
    required this.isDeleting,
    required this.isOpening,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sd = _studentData(raw);
    final name = sd['studentName']?.toString() ?? 'Unknown';
    final nm = (sd['nonMandatory'] as Map?) ?? {};
    final m = (sd['mandatory'] as Map?) ?? {};
    final isActive = sd['isActive'] as bool? ?? true;
    final roll = nm['rollNumber']?.toString();
    final gender = m['gender']?.toString();
    final srId = sd['srId']?.toString();
    final imageUrl = extractProfileImageUrl(sd);
    final clsField = sd['currentClassId'];
    final secField = sd['currentSectionId'];
    final className =
    clsField is Map ? clsField['name']?.toString() : null;
    final sectionName =
    secField is Map ? secField['name']?.toString() : null;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _kPrimaryLight,
                shape: BoxShape.circle,
                border: Border.all(
                    color: _kPrimary.withOpacity(0.25), width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: imageUrl != null
                  ? Image.network(
                imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Text(initial,
                    style: const TextStyle(
                        color: _kPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                loadingBuilder: (_, child, progress) =>
                progress == null
                    ? child
                    : Text(initial,
                    style: const TextStyle(
                        color: _kPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
              )
                  : Text(initial,
                  style: const TextStyle(
                      color: _kPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(name,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _kTextPrimary),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 6),

                  ]),
                  const SizedBox(height: 3),
                  if (srId != null)
                    _MetaRow(Icons.tag_rounded, 'SR: $srId'),
                  if (roll != null)
                    _MetaRow(Icons.format_list_numbered_rounded,
                        'Roll: $roll'),
                  if (gender != null)
                    _MetaRow(Icons.wc_rounded, gender),
                  if (className != null || sectionName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(spacing: 6, children: [
                        if (className != null)
                          _TagChip(Icons.class_rounded, className),
                        if (sectionName != null)
                          _TagChip(
                              Icons.group_rounded, 'Sec $sectionName'),
                      ]),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(mainAxisSize: MainAxisSize.min, children: [
              if (canEdit)
                isOpening
                    ? Container(
                    width: 34,
                    height: 34,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        color: _kPrimaryLight,
                        borderRadius: BorderRadius.circular(8)),
                    child: const CircularProgressIndicator(
                        color: _kPrimary, strokeWidth: 2))
                    : _IconBtn(
                  icon: Icons.edit_rounded,
                  color: _kPrimary,
                  bg: _kPrimaryLight,
                  tooltip: 'Edit',
                  onTap: onEdit,
                ),
              if (canEdit && canDelete) const SizedBox(height: 6),
              if (canDelete)
                isDeleting
                    ? Container(
                    width: 34,
                    height: 34,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        color: _kErrorBg,
                        borderRadius: BorderRadius.circular(8)),
                    child: const CircularProgressIndicator(
                        color: _kError, strokeWidth: 2))
                    : _IconBtn(
                  icon: Icons.delete_outline_rounded,
                  color: _kError,
                  bg: _kErrorBg,
                  tooltip: 'Delete',
                  onTap: onDelete,
                ),
            ]),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SMALL WIDGETS
// =============================================================================
class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaRow(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Row(children: [
      Icon(icon, size: 12, color: _kTextHint),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(
              fontSize: 12, color: _kTextSecondary)),
    ]),
  );
}

class _TagChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TagChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: _kPrimaryLight,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: _kBorder),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: _kPrimaryMid),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(
              fontSize: 11,
              color: _kPrimary,
              fontWeight: FontWeight.w600)),
    ]),
  );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _Badge(
      {required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color)),
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String tooltip;
  final VoidCallback onTap;
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.bg,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.center,
        child: Icon(icon, size: 17, color: color),
      ),
    ),
  );
}

// ── Search bar ────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onClear;
  const _SearchBar({required this.ctrl, required this.onClear});

  @override
  Widget build(BuildContext context) => Container(
    height: 42,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
          color: Colors.white.withOpacity(0.3)),
    ),
    child: TextField(
      controller: ctrl,
      style:
      const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Search by name or SR ID…',
        hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13),
        prefixIcon: Icon(Icons.search_rounded,
            color: Colors.white.withOpacity(0.7), size: 18),
        suffixIcon: ctrl.text.isNotEmpty
            ? IconButton(
            icon: Icon(Icons.close_rounded,
                color: Colors.white.withOpacity(0.8),
                size: 18),
            onPressed: onClear)
            : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 11),
      ),
    ),
  );
}

// ── Class chip ────────────────────────────────────────────────────────────────
class _ClassChip extends StatelessWidget {
  final SchoolClass? selected;
  final VoidCallback onTap;
  const _ClassChip({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasVal = selected != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color:
          hasVal ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: hasVal
                  ? _kPrimary
                  : Colors.white.withOpacity(0.4)),
        ),
        child: Row(children: [
          Icon(Icons.school_outlined,
              size: 14,
              color: hasVal ? _kPrimary : Colors.white),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              selected?.name ?? 'All Classes',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: hasVal ? _kPrimary : Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.arrow_drop_down_rounded,
              size: 16,
              color: hasVal ? _kPrimary : Colors.white),
        ]),
      ),
    );
  }
}

// ── Section chip ──────────────────────────────────────────────────────────────
class _SectionChip extends StatelessWidget {
  final Section? selected;
  final bool enabled;
  final VoidCallback? onTap;
  final VoidCallback onClear;
  const _SectionChip({
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasVal = selected != null;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.55,
        child: Container(
          height: 36,
          padding:
          const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: hasVal
                ? Colors.white
                : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: hasVal
                    ? _kPrimary
                    : Colors.white.withOpacity(0.4)),
          ),
          child: Row(children: [
            Icon(Icons.group_outlined,
                size: 14,
                color: hasVal ? _kPrimary : Colors.white),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                selected != null
                    ? 'Sec ${selected!.name}'
                    : 'All Sections',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasVal ? _kPrimary : Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasVal)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded,
                    size: 14, color: _kPrimary),
              )
            else
              Icon(Icons.arrow_drop_down_rounded,
                  size: 16,
                  color: hasVal ? _kPrimary : Colors.white),
          ]),
        ),
      ),
    );
  }
}

// =============================================================================
// PICKER BOTTOM SHEETS
// =============================================================================
class _PickerItem {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PickerItem(
      {required this.label,
        required this.selected,
        required this.onTap});
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final bool showAll;
  final String allLabel;
  final bool allSelected;
  final VoidCallback onAllTap;
  final List<_PickerItem> items;
  const _PickerSheet({
    required this.title,
    required this.showAll,
    required this.allLabel,
    required this.allSelected,
    required this.onAllTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kCard,
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary)),
        ),
        const Divider(height: 1, color: _kBorder),
        if (showAll)
          ListTile(
            leading: const Icon(Icons.all_inclusive_rounded,
                color: _kPrimary, size: 20),
            title: Text(allLabel,
                style: const TextStyle(
                    fontSize: 14, color: _kTextPrimary)),
            trailing: allSelected
                ? const Icon(Icons.check_rounded,
                color: _kPrimary, size: 18)
                : null,
            onTap: onAllTap,
          ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              return ListTile(
                leading: const Icon(Icons.class_rounded,
                    color: _kPrimary, size: 20),
                title: Text(item.label,
                    style: TextStyle(
                        fontSize: 14,
                        color: _kTextPrimary,
                        fontWeight: item.selected
                            ? FontWeight.w700
                            : FontWeight.w400)),
                trailing: item.selected
                    ? const Icon(Icons.check_rounded,
                    color: _kPrimary, size: 18)
                    : null,
                onTap: item.onTap,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }
}

class _SectionGridSheet extends StatelessWidget {
  final List<Section> sections;
  final Section? selected;
  final void Function(Section) onSelect;
  const _SectionGridSheet({
    required this.sections,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kCard,
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding:
      const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(2))),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Select Section',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary)),
        ),
        const Divider(height: 1, color: _kBorder),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: sections.map((sec) {
            final sel = selected?.id == sec.id;
            return GestureDetector(
              onTap: () => onSelect(sec),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color:
                  sel ? _kPrimary : _kSectionBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color:
                      sel ? _kPrimary : _kBorder,
                      width: sel ? 1.5 : 1),
                ),
                alignment: Alignment.center,
                child: Text(sec.name,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: sel
                            ? Colors.white
                            : _kTextPrimary)),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }
}
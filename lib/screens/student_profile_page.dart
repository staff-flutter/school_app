import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/my_children_controller.dart';
import '../controllers/school_controller.dart';
import '../constants/api_constants.dart';
import '../models/student_model.dart' show Student;
import '../services/user_session.dart';

class ProfilePage extends StatefulWidget {
  final Student? student;
  final String schoolId;

  const ProfilePage({
    super.key,
    this.student,
    required this.schoolId,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final schoolController = Get.find<SchoolController>();

  final Map<String, TextEditingController> _editControllers = {};
  final Set<String> _editingFields = {};
  final Set<String> _savingFields = {};

  // ── Live (approved) values ──────────────────────────────────────
  Map<String, String> _fieldValues = {};

  // ── Pending changes waiting for admin approval ──────────────────
  // key = field label, value = what the parent requested
  Map<String, String> _pendingValues = {};
  String? _pendingRequestId;

  String? selectedGender;
  String _studentId = '';
  bool _isLoading = true;

  // ─── Label lists ────────────────────────────────────────────────
  static const List<String> _mandatoryLabelsList = [
    'Gender', 'Father Name', 'Mother Name', 'Guardian Name',
    'Mobile Number', 'Alternate Mobile', 'Email', 'Date of Birth',
    'Aadhaar Number', 'Aadhaar Name', 'Education Number', 'Address',
    'Pincode', 'Mother Tongue', 'Social Category', 'Minority Group',
    'BPL', 'AAY', 'EWS', 'CWSN', 'Impairments', 'Indian',
    'Out Of School', 'Mainstreamed Date', 'Disability Certificate',
    'Disability Percent', 'Blood Group',
  ];

  static const List<String> _udiseLabelsList = [
    'Facilities Provided', 'Facilities For CWSN', 'Screened For SLD',
    'SLD Type', 'Screened for ASD', 'Screened for ADHD',
    'Gifted Talented', 'Participated in Competitions',
    'Participated in Activities', 'Can Handle Digital Devices',
    'Height (cm)', 'Weight (Kg)', 'Distance to School',
    'Parent Education Level', 'Admission Number', 'Admission Date',
    'Roll Number', 'Medium of Instruction', 'Languages Studied',
    'Academic Stream', 'Subjects Studied', 'Status in Previous Year',
    'Grade Studied Last Year', 'Enrolled Under', 'Previous Result',
    'Marks List', 'Days Attended Last Year',
  ];

  static const Set<String> _mandatoryLabels = {
    'Gender', 'Father Name', 'Mother Name', 'Guardian Name',
    'Mobile Number', 'Alternate Mobile', 'Email', 'Date of Birth',
    'Aadhaar Number', 'Aadhaar Name', 'Education Number', 'Address',
    'Pincode', 'Mother Tongue', 'Social Category', 'Minority Group',
    'BPL', 'AAY', 'EWS', 'CWSN', 'Impairments', 'Indian',
    'Out Of School', 'Mainstreamed Date', 'Disability Certificate',
    'Disability Percent', 'Blood Group',
  };

  @override
  void initState() {
    super.initState();
    _initFieldValues();
    _load();
  }

  void _initFieldValues() {
    for (final l in _mandatoryLabelsList) _fieldValues[l] = '';
    for (final l in _udiseLabelsList) _fieldValues[l] = '';
  }

  // ─── Cache ──────────────────────────────────────────────────────
  String get _cacheKey => 'student_profile_$_studentId';
  String get _pendingCacheKey => 'student_pending_$_studentId';

  Future<void> _saveToCache(Map<String, String> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(values));
  }

  Future<void> _savePendingToCache(Map<String, String> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingCacheKey, jsonEncode(values));
  }

  Future<Map<String, String>?> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    return (jsonDecode(raw) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v.toString()));
  }

  Future<Map<String, String>?> _loadPendingFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingCacheKey);
    if (raw == null) return null;
    return (jsonDecode(raw) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v.toString()));
  }

  // ─── Load ───────────────────────────────────────────────────────
  Future<void> _load() async {
    try {
      final childController = Get.find<MyChildrenController>();
      _studentId = childController.selectedChild['_id'] ?? '';

      debugPrint('Loading profile for studentId: $_studentId'); // verify ID

      if (_studentId.isEmpty) {
        debugPrint('ERROR: studentId is empty!');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (widget.student != null) {
        _populateFromStudent(widget.student!);
        if (mounted) setState(() => _isLoading = false);
      }

      final cached = await _loadFromCache();
      if (cached != null && cached.isNotEmpty) {
        if (mounted) setState(() { _mergeValues(cached); _isLoading = false; });
      }

      final cachedPending = await _loadPendingFromCache();
      if (cachedPending != null && mounted) {
        setState(() => _pendingValues = cachedPending);
      }

      await _fetchStudentProfile();
      await _fetchPendingRequest();

    } catch (e) {
      debugPrint('Load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  String? _getToken() {
    try { return Get.find<UserSession>().token; } catch (_) { return null; }
  }

  String? _getUserId() {
    try { return Get.find<UserSession>().parentId; } catch (_) { return null; }
  }
  String? _getSchoolId() {
    try { return Get.find<UserSession>().schoolId; } catch (_) { return null; }
  }

  Future<void> _fetchStudentProfile() async {
    final token = _getToken();

    if (token == null) {
      debugPrint('ERROR: token is null');
      return;
    }
    if (_studentId.isEmpty) {
      debugPrint('ERROR: studentId is empty, cannot fetch profile');
      return;
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/api/student/get/$_studentId');
    debugPrint('Fetching profile from: $uri');

    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 15));

      debugPrint('Profile status: ${response.statusCode}');
      debugPrint('Profile body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // Handle multiple possible response shapes:
        // { data: { mandatory: {}, nonMandatory: {} } }
        // { data: { gender: '', fatherName: '' ... } }
        // { mandatory: {}, nonMandatory: {} }
        // { gender: '', fatherName: '' ... }
        Map<String, dynamic>? data;

        if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is Map<String, dynamic>) {
            data = decoded['data'] as Map<String, dynamic>;
          } else if (decoded['student'] is Map<String, dynamic>) {
            data = decoded['student'] as Map<String, dynamic>;
          } else {
            data = decoded;
          }
        }

        debugPrint('Parsed data keys: ${data?.keys.toList()}');
        debugPrint('mandatory keys: ${(data?['mandatory'] as Map?)?.keys.toList()}');
        debugPrint('nonMandatory keys: ${(data?['nonMandatory'] as Map?)?.keys.toList()}');

        if (data != null && mounted) {
          setState(() => _mapResponseToFields(data!));
          await _saveToCache(_fieldValues);
          debugPrint('Gender after mapping: ${_fieldValues['Gender']}');
          debugPrint('Father Name after mapping: ${_fieldValues['Father Name']}');
          debugPrint('Mobile after mapping: ${_fieldValues['Mobile Number']}');
        }
      } else {
        debugPrint('Profile fetch failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Profile fetch error: $e');
    }
  }  // ── Fetch any pending request for this student ─────────────────
// ── Fetch any pending request for this student ─────────────────
  Future<void> _fetchPendingRequest() async {
    final token = _getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/student/pending-requests')
        .replace(queryParameters: {'studentId': _studentId});
    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      debugPrint('Pending status: ${response.statusCode}');
      debugPrint('Pending body: ${response.body}'); // check key names here

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> list = decoded['data'] ?? [];
        final pending = list.firstWhere(
              (r) => r['status'] == 'pending',
          orElse: () => null,
        );

        if (pending != null && mounted) {
          final rawChanges = (pending['changes'] as Map<String, dynamic>?) ?? {};

          // Convert camelCase API keys → display labels
          final labelChanges = <String, String>{};
          rawChanges.forEach((apiKey, value) {
            if (value != null && value.toString() != 'null' && value.toString().isNotEmpty) {
              final label = _apiKeyToLabel(apiKey);
              if (label != null) labelChanges[label] = value.toString();
            }
          });

          setState(() {
            _pendingValues = labelChanges;
            _pendingRequestId = pending['_id']?.toString();
          });
          await _savePendingToCache(labelChanges);
        } else if (mounted) {
          setState(() { _pendingValues = {}; _pendingRequestId = null; });
          await _savePendingToCache({});
        }
      }
    } catch (e) { debugPrint('Pending fetch error: $e'); }
  }

// Reverse lookup: camelCase API key → display label
  String? _apiKeyToLabel(String apiKey) {
    const map = {
      'gender': 'Gender',
      'fatherName': 'Father Name',
      'motherName': 'Mother Name',
      'guardianName': 'Guardian Name',
      'mobileNumber': 'Mobile Number',
      'alternateMobile': 'Alternate Mobile',
      'email': 'Email',
      'dob': 'Date of Birth',
      'aadhaarNumber': 'Aadhaar Number',
      'aadhaarName': 'Aadhaar Name',
      'educationNumber': 'Education Number',
      'address': 'Address',
      'pincode': 'Pincode',
      'motherTongue': 'Mother Tongue',
      'socialCategory': 'Social Category',
      'minorityGroup': 'Minority Group',
      'bpl': 'BPL',
      'aay': 'AAY',
      'ews': 'EWS',
      'cwsn': 'CWSN',
      'impairments': 'Impairments',
      'indian': 'Indian',
      'outOfSchool': 'Out Of School',
      'mainstreamedDate': 'Mainstreamed Date',
      'disabilityCert': 'Disability Certificate',
      'disabilityPercent': 'Disability Percent',
      'bloodGroup': 'Blood Group',
      'facilitiesProvided': 'Facilities Provided',
      'facilitiesForCWSN': 'Facilities For CWSN',
      'screenedForSLD': 'Screened For SLD',
      'sldType': 'SLD Type',
      'screenedForASD': 'Screened for ASD',
      'screenedForADHD': 'Screened for ADHD',
      'isGiftedOrTalented': 'Gifted Talented',
      'participatedInCompetitions': 'Participated in Competitions',
      'participatedInActivities': 'Participated in Activities',
      'canHandleDigitalDevices': 'Can Handle Digital Devices',
      'heightInCm': 'Height (cm)',
      'weightInKg': 'Weight (Kg)',
      'distanceToSchool': 'Distance to School',
      'parentEducationLevel': 'Parent Education Level',
      'admissionNumber': 'Admission Number',
      'admissionDate': 'Admission Date',
      'rollNumber': 'Roll Number',
      'mediumOfInstruction': 'Medium of Instruction',
      'languagesStudied': 'Languages Studied',
      'academicStream': 'Academic Stream',
      'subjectsStudied': 'Subjects Studied',
      'statusInPreviousYear': 'Status in Previous Year',
      'gradeStudiedLastYear': 'Grade Studied Last Year',
      'enrolledUnder': 'Enrolled Under',
      'previousResult': 'Previous Result',
      'marksList': 'Marks List',
      'daysAttendedLastYear': 'Days Attended Last Year',
    };
    return map[apiKey];
  }
  // ─── Map API response to fields ─────────────────────────────────
  void _mapResponseToFields(Map<String, dynamic> data) {
    final m = data['mandatory'] is Map<String, dynamic>
        ? data['mandatory'] as Map<String, dynamic>
        : <String, dynamic>{};
    final n = data['nonMandatory'] is Map<String, dynamic>
        ? data['nonMandatory'] as Map<String, dynamic>
        : <String, dynamic>{};

    String pick(List<String> keys) {
      for (final k in keys) {
        final v = m[k] ?? n[k] ?? data[k];
        if (v != null && v.toString().isNotEmpty && v.toString() != 'null') {
          return v.toString();
        }
      }
      return '';
    }

    final updated = <String, String>{
      // ── Mandatory ──────────────────────────────────────────────────
      'Gender':                 pick(['gender']),
      'Father Name':            pick(['fatherName']),
      'Mother Name':            pick(['motherName']),
      'Guardian Name':          pick(['guardianName']),
      'Mobile Number':          pick(['mobileNumber']),
      'Alternate Mobile':       pick(['alternateMobile']),
      'Email':                  pick(['email']),
      'Date of Birth':          pick(['dob']),
      'Aadhaar Number':         pick(['aadhaarNumber']),
      'Aadhaar Name':           pick(['aadhaarName']),
      'Education Number':       pick(['educationNumber']),
      'Address':                pick(['address']),
      'Pincode':                pick(['pincode']),
      'Mother Tongue':          pick(['motherTongue']),
      'Social Category':        pick(['socialCategory']),
      'Minority Group':         pick(['minorityGroup']),
      'BPL':                    pick(['bpl']),
      'AAY':                    pick(['aay']),
      'EWS':                    pick(['ews']),
      'CWSN':                   pick(['cwsn']),
      'Impairments':            pick(['impairments']),
      'Indian':                 pick(['indian']),
      'Out Of School':          pick(['outOfSchool']),
      'Mainstreamed Date':      pick(['mainstreamedDate']),
      'Disability Certificate': pick(['disabilityCert']),
      'Disability Percent':     pick(['disabilityPercent']),
      'Blood Group':            pick(['bloodGroup']),

      // ── Non-Mandatory (UDISE) ──────────────────────────────────────
      'Facilities Provided':          pick(['facilitiesProvided']),
      'Facilities For CWSN':          pick(['facilitiesForCWSN']),
      'Screened For SLD':             pick(['screenedForSLD']),
      'SLD Type':                     pick(['sldType']),
      'Screened for ASD':             pick(['screenedForASD']),
      'Screened for ADHD':            pick(['screenedForADHD']),
      'Gifted Talented':              pick(['isGiftedOrTalented']),
      'Participated in Competitions': pick(['participatedInCompetitions']),
      'Participated in Activities':   pick(['participatedInActivities']),
      'Can Handle Digital Devices':   pick(['canHandleDigitalDevices']),
      'Height (cm)':                  pick(['heightInCm']),
      'Weight (Kg)':                  pick(['weightInKg']),
      'Distance to School':           pick(['distanceToSchool']),
      'Parent Education Level':       pick(['parentEducationLevel']),
      'Admission Number':             pick(['admissionNumber']),
      'Admission Date':               pick(['admissionDate']),
      'Roll Number':                  pick(['rollNumber']),
      'Medium of Instruction':        pick(['mediumOfInstruction']),
      'Languages Studied':            pick(['languagesStudied']),
      'Academic Stream':              pick(['academicStream']),
      'Subjects Studied':             pick(['subjectsStudied']),
      'Status in Previous Year':      pick(['statusInPreviousYear']),
      'Grade Studied Last Year':      pick(['gradeStudiedLastYear', 'gradeStudiedLastYear']),
      'Enrolled Under':               pick(['enrolledUnder']),
      'Previous Result':              pick(['previousResult']),
      'Marks List':                   pick(['marksList']),
      'Days Attended Last Year':      pick(['daysAttendedLastYear']),
    };

    for (final entry in updated.entries) {
      if (entry.value.isNotEmpty) _fieldValues[entry.key] = entry.value;
    }

    final g = _fieldValues['Gender'] ?? '';
    final normalized = _normalizeGender(g);
    _fieldValues['Gender'] = normalized ?? '';
    selectedGender = normalized;
  }

  void _mergeValues(Map<String, String> incoming) {
    for (final entry in incoming.entries) {
      if (entry.value.isNotEmpty) _fieldValues[entry.key] = entry.value;
    }
    final g = _fieldValues['Gender'] ?? '';
    final normalized = _normalizeGender(g);
    _fieldValues['Gender'] = normalized ?? '';
    selectedGender = normalized;
  }

  void _populateFromStudent(Student student) {
    void set(String k, String? v) {
      if (v != null && v.isNotEmpty) _fieldValues[k] = v;
    }
    set('Gender', student.gender);
    set('Father Name', student.fatherName);
    set('Mother Name', student.motherName);
    set('Guardian Name', student.guardianName);
    set('Mobile Number', student.mobileNumber);
    set('Alternate Mobile', student.alternateMobile);
    set('Email', student.email);
    set('Date of Birth', student.dob);
    set('Aadhaar Number', student.aadhaarNumber);
    set('Aadhaar Name', student.aadhaarName);
    set('Education Number', student.educationNumber);
    set('Address', student.address);
    set('Pincode', student.pincode);
    set('Mother Tongue', student.motherTongue);
    set('Social Category', student.socialCategory);
    set('Minority Group', student.minorityGroup);
    set('BPL', student.bpl);
    set('AAY', student.aay);
    set('EWS', student.ews);
    set('CWSN', student.cwsn);
    set('Impairments', student.impairments);
    set('Indian', student.indian);
    set('Out Of School', student.outOfSchool);
    set('Mainstreamed Date', student.mainstreamedDate);
    set('Disability Certificate', student.disabilityCert);
    set('Disability Percent', student.disabilityPercent);
    set('Blood Group', student.bloodGroup);
    final g = student.gender ?? '';
    final normalized = _normalizeGender(g);
    _fieldValues['Gender'] = normalized ?? '';
    selectedGender = normalized;
  }

  // ─── Submit pending update request ──────────────────────────────
  Future<void> _submitUpdateRequest(String label, String newValue) async {
    setState(() => _savingFields.add(label));

    final token = _getToken();
    final userId = _getUserId();

    // Guard clause against missing session tokens
    if (token == null || userId == null) {
      setState(() => _savingFields.remove(label));
      _showSnack('Session expired. Please log in again.', Colors.red);
      return;
    }

    // Merge with existing pending changes
    final allChanges = Map<String, String>.from(_pendingValues)..[label] = newValue;
    final allPrevious = <String, String>{};

    for (final k in allChanges.keys) {
      allPrevious[k] = _fieldValues[k] ?? '';
    }
    final allSections = <String, String>{};
    for (final k in allChanges.keys) {
      allSections[k] = _mandatoryLabels.contains(k) ? 'mandatory' : 'nonMandatory';
    }
    // Create payload body matching the exact expectations of your verification schema
    final body = {
      'studentId':      _studentId,
      'schoolId':       _getSchoolId() ?? '',
      'requestedBy':    userId,
      'changes':        allChanges,
      'previousValues': allPrevious,
      'section':        allSections,
    };

    try {
      // Print payload immediately before sending to copy-paste into Postman/Thunder Client
      debugPrint('--- SENDING PAYLOAD ---');
      debugPrint(jsonEncode(body));
      debugPrint('-----------------------');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/student/request-update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _pendingValues[label] = newValue;
          _pendingRequestId = decoded['data']?['_id']?.toString() ?? _pendingRequestId;
          _editingFields.remove(label);

          // Target specific controller teardown safely
          if (_editControllers.containsKey(label)) {
            _editControllers[label]?.dispose();
            _editControllers.remove(label);
          }
        });
        await _savePendingToCache(_pendingValues);
        _showSnack('✓ Sent for admin verification', Colors.orange.shade700);
      } else {
        // Print backend error details to narrow down what broke on the server side
        debugPrint('Backend Error [${response.statusCode}]: ${response.body}');
        _showSnack('Failed to submit — try again', Colors.red);
      }
    } catch (e) {
      debugPrint('Submit error: $e');
      _showSnack('Connection error', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _savingFields.remove(label));
      }
    }
  }
  void _showSnack(String msg, Color color) {
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    Get.snackbar('', msg,
        titleText: const SizedBox.shrink(),
        messageText: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        duration: const Duration(seconds: 3));
  }

  // ─── Gender normalizer ───────────────────────────────────────────
  static const _genderOptions = ['Male', 'Female', 'Other'];
  String? _normalizeGender(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final lower = raw.toLowerCase().trim();
    if (lower == 'male'   || lower == 'm') return 'Male';
    if (lower == 'female' || lower == 'f') return 'Female';
    if (lower == 'other') return 'Other';
    return _genderOptions.contains(raw) ? raw : null;
  }

  String _labelToApiKey(String label) {
    const map = {
      'Gender': 'gender',
      'Father Name': 'fatherName',
      'Mother Name': 'motherName',
      'Guardian Name': 'guardianName',
      'Mobile Number': 'mobileNumber',
      'Alternate Mobile': 'alternateMobile',
      'Email': 'email',
      'Date of Birth': 'dob',
      'Aadhaar Number': 'aadhaarNumber',
      'Aadhaar Name': 'aadhaarName',
      'Education Number': 'educationNumber',
      'Address': 'address',
      'Pincode': 'pincode',
      'Mother Tongue': 'motherTongue',
      'Social Category': 'socialCategory',
      'Minority Group': 'minorityGroup',
      'BPL': 'bpl',
      'AAY': 'aay',
      'EWS': 'ews',
      'CWSN': 'cwsn',
      'Impairments': 'impairments',
      'Indian': 'indian',
      'Out Of School': 'outOfSchool',
      'Mainstreamed Date': 'mainstreamedDate',
      'Disability Certificate': 'disabilityCert',
      'Disability Percent': 'disabilityPercent',
      'Blood Group': 'bloodGroup',
      'Facilities Provided': 'facilitiesProvided',
      'Facilities For CWSN': 'facilitiesForCWSN',
      'Screened For SLD': 'screenedForSLD',
      'SLD Type': 'sldType',
      'Screened for ASD': 'screenedForASD',
      'Screened for ADHD': 'screenedForADHD',
      'Gifted Talented': 'isGiftedOrTalented',
      'Participated in Competitions': 'participatedInCompetitions',
      'Participated in Activities': 'participatedInActivities',
      'Can Handle Digital Devices': 'canHandleDigitalDevices',
      'Height (cm)': 'heightInCm',
      'Weight (Kg)': 'weightInKg',
      'Distance to School': 'distanceToSchool',
      'Parent Education Level': 'parentEducationLevel',
      'Admission Number': 'admissionNumber',
      'Admission Date': 'admissionDate',
      'Roll Number': 'rollNumber',
      'Medium of Instruction': 'mediumOfInstruction',
      'Languages Studied': 'languagesStudied',
      'Academic Stream': 'academicStream',
      'Subjects Studied': 'subjectsStudied',
      'Status in Previous Year': 'statusInPreviousYear',
      'Grade Studied Last Year': 'gradeStudiedLastYear',
      'Enrolled Under': 'enrolledUnder',
      'Previous Result': 'previousResult',
      'Marks List': 'marksList',
      'Days Attended Last Year': 'daysAttendedLastYear',
    };
    return map[label] ?? label;
  }
  // ─── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final childController = Get.find<MyChildrenController>();
    final String studentName =
        childController.selectedChild['studentName'] ?? 'Student';
    final String studentImageUrl =
        childController.selectedChild['studentImage']?['url'] ?? '';

    final pendingCount = _pendingValues.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
        Get.back();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFEEF3FB),
          body: Stack(
            children: [
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Image.asset(
                  'assets/images/Blue science and education collection footer.png',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: SafeArea(
                  top: false, bottom: true,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                         onRefresh: () async {
                         await _fetchStudentProfile();
                         await _fetchPendingRequest();
                           },
                         child: SingleChildScrollView(
                                            physics: const AlwaysScrollableScrollPhysics(),
                                            child: Column(children: [
                        _buildHeader(studentName, studentImageUrl),
                        const SizedBox(height: 75),
                        Text('$studentName Profile',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Container(
                          width: 120, height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.transparent,
                              Colors.grey.shade400,
                              Colors.transparent,
                            ]),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // ── Pending banner ─────────────────────
                        if (pendingCount > 0) _buildPendingBanner(pendingCount),
                        
                        const SizedBox(height: 8),
                        _buildSection(
                          title: 'Mandatory Information',
                          icon: Icons.info_outline,
                          labels: _mandatoryLabelsList,
                        ),
                        _buildSection(
                          title: 'UDISE',
                          icon: Icons.description_outlined,
                          labels: _udiseLabelsList,
                        ),
                        const SizedBox(height: 30),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xff4A90E2), Color(0xff6FD3F7)]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            onPressed: () => _showSnack(
                                "Your child's form is submitted for verification",
                                Colors.green),
                            child: const Text('Submit For Verification',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 40),
                                            ]),
                                          ),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Pending changes banner ───────────────────────────────────────
  Widget _buildPendingBanner(int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade300, width: 1),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.pending_actions_rounded,
              color: Colors.orange.shade800, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '$count field${count == 1 ? '' : 's'} pending verification',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.orange.shade900),
            ),
            const SizedBox(height: 2),
            Text(
              'Your changes are waiting for admin approval. '
                  'Current values are shown until approved.',
              style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildHeader(String studentName, String imageUrl) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: HeaderClipper(),
          child: Container(
            height: 250, width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff4A90E2), Color(0xff6FD3F7)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Image.asset(
            'assets/images/Scientific UI background design header.png',
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          bottom: -60, left: 0, right: 0,
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15, offset: const Offset(0, 5),
                )],
              ),
              child: CircleAvatar(
                radius: 55, backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage:
                  imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                  child: imageUrl.isEmpty
                      ? const Icon(Icons.person, size: 40) : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<String> labels,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [BoxShadow(
          color: Colors.blue.withOpacity(0.2),
          blurRadius: 12, offset: const Offset(0, 6),
        )],
      ),
      child: Theme(
        data: ThemeData().copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: ExpansionTile(
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          leading: CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(icon, color: const Color(0xFF4F6DB8), size: 15),
          ),
          title: Text(title,
              style: const TextStyle(color: Colors.black, fontSize: 13)),
          iconColor: Colors.black,
          collapsedIconColor: Colors.black,
          children: labels.map((l) => _buildFieldRow(l)).toList(),
        ),
      ),
    );
  }

  Widget _buildFieldRow(String label) {
    if (label == 'Gender') return _buildGenderRow();
    if (label == 'Date of Birth') return _buildDateRow(label);
    return _buildTextRow(label);
  }

  // ─── Generic text row ────────────────────────────────────────────
  Widget _buildTextRow(String label) {
    final isEditing = _editingFields.contains(label);
    final isSaving  = _savingFields.contains(label);
    final value     = _fieldValues[label] ?? '';
    final pending   = _pendingValues[label];
    final hasPending = pending != null && pending != value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: hasPending
              ? Colors.orange.shade50
              : isEditing
              ? const Color(0xffF0F6FF)
              : const Color(0xffF1F4F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasPending
                ? Colors.orange.shade300
                : isEditing
                ? const Color(0xff4A90E2)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: isEditing
                    ? TextField(
                  controller: _editControllers[label],
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: const TextStyle(
                        color: Color(0xff4A90E2), fontSize: 12),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 15),
                )
                    : _fieldDisplay(label, value, pendingValue: pending),
              ),
              const SizedBox(width: 8),
              _buildActionButtons(
                label: label,
                isEditing: isEditing,
                isSaving: isSaving,
                hasPending: hasPending,
                onEdit: () {
                  final tc = TextEditingController(text: value);
                  setState(() {
                    _editControllers[label] = tc;
                    _editingFields.add(label);
                  });
                },
                onCancel: () => setState(() {
                  _editingFields.remove(label);
                  _editControllers[label]?.dispose();
                  _editControllers.remove(label);
                }),
                onSave: () => _submitUpdateRequest(
                    label, _editControllers[label]?.text.trim() ?? ''),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Gender row ──────────────────────────────────────────────────
  Widget _buildGenderRow() {
    final isEditing  = _editingFields.contains('Gender');
    final isSaving   = _savingFields.contains('Gender');
    final value      = _fieldValues['Gender'] ?? '';
    final pending    = _pendingValues['Gender'];
    final hasPending = pending != null && pending != value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: hasPending
              ? Colors.orange.shade50
              : isEditing
              ? const Color(0xffF0F6FF)
              : const Color(0xffF1F4F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasPending
                ? Colors.orange.shade300
                : isEditing
                ? const Color(0xff4A90E2)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            Expanded(
              child: isEditing
                  ? DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _normalizeGender(selectedGender),
                  isExpanded: true,
                  hint: const Text('Select Gender'),
                  items: ['Male', 'Female', 'Other']
                      .map((g) => DropdownMenuItem(
                      value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => selectedGender = v),
                ),
              )
                  : _fieldDisplay('Gender', value, pendingValue: pending),
            ),
            const SizedBox(width: 8),
            _buildActionButtons(
              label: 'Gender',
              isEditing: isEditing,
              isSaving: isSaving,
              hasPending: hasPending,
              onEdit: () => setState(() => _editingFields.add('Gender')),
              onCancel: () => setState(() {
                _editingFields.remove('Gender');
                selectedGender = _normalizeGender(_fieldValues['Gender']);
              }),
              onSave: () => _submitUpdateRequest(
                  'Gender', selectedGender ?? ''),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── Date row ────────────────────────────────────────────────────
  Widget _buildDateRow(String label) {
    final isSaving   = _savingFields.contains(label);
    final value      = _fieldValues[label] ?? '';
    final pending    = _pendingValues[label];
    final hasPending = pending != null && pending != value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: hasPending ? Colors.orange.shade50 : const Color(0xffF1F4F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasPending ? Colors.orange.shade300 : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            Expanded(child: _fieldDisplay(label, value, pendingValue: pending)),
            const SizedBox(width: 8),
            isSaving
                ? const SizedBox(width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
                : GestureDetector(
              onTap: () async {
                DateTime initial = DateTime.now();
                if (value.isNotEmpty) {
                  try {
                    final parts = value.split('/');
                    if (parts.length == 3) {
                      initial = DateTime(int.parse(parts[2]),
                          int.parse(parts[1]), int.parse(parts[0]));
                    }
                  } catch (_) {}
                }
                final picked = await showDatePicker(
                  context: context,
                  initialDate: initial,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  final formatted =
                      '${picked.day.toString().padLeft(2, '0')}/'
                      '${picked.month.toString().padLeft(2, '0')}/'
                      '${picked.year}';
                  await _submitUpdateRequest(label, formatted);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: hasPending
                        ? Colors.orange.withOpacity(0.15)
                        : const Color(0xff4A90E2).withOpacity(0.1),
                    shape: BoxShape.circle),
                child: Icon(Icons.calendar_today_outlined,
                    size: 16,
                    color: hasPending
                        ? Colors.orange.shade800
                        : const Color(0xff4A90E2)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── Field display — shows current value + pending chip ─────────
  Widget _fieldDisplay(String label, String value, {String? pendingValue}) {
    final hasPending = pendingValue != null && pendingValue != value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        // Current approved value
        Text(
          value.isNotEmpty ? value : '—',
          style: TextStyle(
            fontSize: 15,
            color: value.isNotEmpty ? Colors.black87 : Colors.grey.shade400,
            fontWeight: FontWeight.w500,
            decoration: hasPending ? TextDecoration.lineThrough : null,
            decorationColor: Colors.orange.shade400,
          ),
        ),
        // Pending value chip shown below current value
        if (hasPending) ...[
          const SizedBox(height: 4),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.shade300, width: 0.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.pending_rounded,
                    size: 11, color: Colors.orange.shade800),
                const SizedBox(width: 4),
                Text(
                  pendingValue,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900,
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 6),
            Text('pending',
                style: TextStyle(fontSize: 10, color: Colors.orange.shade600)),
          ]),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  // ─── Action buttons ──────────────────────────────────────────────
  Widget _buildActionButtons({
    required String label,
    required bool isEditing,
    required bool isSaving,
    required bool hasPending,
    required VoidCallback onEdit,
    required VoidCallback onCancel,
    required VoidCallback onSave,
  }) {
    if (isSaving) {
      return const SizedBox(width: 24, height: 24,
          child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (isEditing) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          onTap: onCancel,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: Colors.grey.shade200, shape: BoxShape.circle),
            child: const Icon(Icons.close, size: 16, color: Colors.grey),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onSave,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xff4A90E2), Color(0xff6FD3F7)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 16, color: Colors.white),
          ),
        ),
      ]);
    }
    // Show orange edit icon if pending, blue otherwise
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: hasPending
                ? Colors.orange.withOpacity(0.15)
                : const Color(0xff4A90E2).withOpacity(0.1),
            shape: BoxShape.circle),
        child: Icon(Icons.edit_outlined,
            size: 16,
            color: hasPending
                ? Colors.orange.shade800
                : const Color(0xff4A90E2)),
      ),
    );
  }

  @override
  void dispose() {
    for (final tc in _editControllers.values) tc.dispose();
    super.dispose();
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 60);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
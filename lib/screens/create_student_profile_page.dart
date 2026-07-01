import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Response;
import 'package:image_picker/image_picker.dart';
import 'package:school_app/constants/api_constants.dart';
import '../controllers/auth_controller.dart';
import '../controllers/school_controller.dart';
import '../core/theme/app_theme.dart';
import '../models/school_models.dart';
import '../models/student_model.dart';
import '../services/api_service.dart';
import 'package:dio/dio.dart' as dio;
import 'package:file_picker/file_picker.dart';
import 'package:school_app/controllers/student_management_controller.dart';

// =============================================================================
// DESIGN TOKENS
// =============================================================================

class _AppColors {
  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFFE3EEF9);
  static const primaryMid = Color(0xFF1976D2);
  static const primaryDark = Color(0xFF0D47A1);
  static const surface = Color(0xFFF5F7FA);
  static const cardBg = Color(0xFFFFFFFF);
  static const sectionBg = Color(0xFFF0F4FA);
  static const textPrimary = Color(0xFF1A2340);
  static const textSecondary = Color(0xFF5B6880);
  static const textHint = Color(0xFF9AA5B4);
  static const border = Color(0xFFDDE3EC);
  static const borderFocus = Color(0xFF1976D2);
  static const success = Color(0xFF2E7D32);
  static const successBg = Color(0xFFE8F5E9);
  static const error = Color(0xFFC62828);
  static const errorBg = Color(0xFFFFEBEE);
  static const stepDone = Color(0xFF1976D2);
  static const stepInactive = Color(0xFFCDD4E0);
}

// =============================================================================
// MODELS
// =============================================================================

class StudentPayload {
  final String schoolId;
  final String? srId;
  final String studentName;
  final String? currentClassId;
  final String? currentSectionId;
  final bool isActive;
  final MandatoryDetails mandatory;
  final NonMandatoryDetails nonMandatory;

  StudentPayload({
    required this.schoolId,
    this.srId,
    required this.studentName,
    this.currentClassId,
    this.currentSectionId,
    required this.isActive,
    required this.mandatory,
    required this.nonMandatory,
  });

  Map<String, dynamic> toJson() => {
    'schoolId': schoolId,
    if (srId != null) 'srId': srId,
    'studentName': studentName,
    if (currentClassId != null) 'currentClassId': currentClassId,
    if (currentSectionId != null) 'currentSectionId': currentSectionId,
    'isActive': isActive,
    'mandatory': mandatory.toJson(),
    'nonMandatory': nonMandatory.toJson(),
  };
}

class MandatoryDetails {
  String? gender, dob, educationNumber, motherName, fatherName, guardianName;
  String? aadhaarNumber, aadhaarName, address, pincode, mobileNumber;
  String? alternateMobile, email, motherTongue, socialCategory, minorityGroup;
  String? bpl, aay, ews, cwsn, impairments, indian, outOfSchool;
  String? mainstreamedDate, disabilityCert, disabilityPercent, bloodGroup;

  Map<String, dynamic> toJson() => {
    'gender': gender,
    'dob': dob,
    'educationNumber': educationNumber,
    'motherName': motherName,
    'fatherName': fatherName,
    'guardianName': guardianName,
    'aadhaarNumber': aadhaarNumber,
    'aadhaarName': aadhaarName,
    'address': address,
    'pincode': pincode,
    'mobileNumber': mobileNumber,
    'alternateMobile': alternateMobile,
    'email': email,
    'motherTongue': motherTongue,
    'socialCategory': socialCategory,
    'minorityGroup': minorityGroup,
    'bpl': bpl,
    'aay': aay,
    'ews': ews,
    'cwsn': cwsn,
    'impairments': impairments,
    'indian': indian,
    'outOfSchool': outOfSchool,
    'mainstreamedDate': mainstreamedDate,
    'disabilityCert': disabilityCert,
    'disabilityPercent': disabilityPercent,
    'bloodGroup': bloodGroup,
  };
}

class NonMandatoryDetails {
  String? facilitiesProvided, facilitiesForCWSN, screenedForSLD, sldType;
  String? screenedForASD, screenedForADHD, isGiftedOrTalented;
  String? participatedInCompetitions, participatedInActivities;
  String? canHandleDigitalDevices, heightInCm, weightInKg;
  String? distanceToSchool, parentEducationLevel;
  String? admissionNumber, admissionDate, rollNumber, mediumOfInstruction;
  String? languagesStudied, academicStream, subjectsStudied;
  String? statusInPreviousYear, gradeStudiedLastYear, enrolledUnder;
  String? previousResult, marksObtainedPercentage, daysAttendedLastYear;

  Map<String, dynamic> toJson() => {
    'facilitiesProvided': facilitiesProvided,
    'facilitiesForCWSN': facilitiesForCWSN,
    'screenedForSLD': screenedForSLD,
    'sldType': sldType,
    'screenedForASD': screenedForASD,
    'screenedForADHD': screenedForADHD,
    'isGiftedOrTalented': isGiftedOrTalented,
    'participatedInCompetitions': participatedInCompetitions,
    'participatedInActivities': participatedInActivities,
    'canHandleDigitalDevices': canHandleDigitalDevices,
    'heightInCm': heightInCm,
    'weightInKg': weightInKg,
    'distanceToSchool': distanceToSchool,
    'parentEducationLevel': parentEducationLevel,
    'admissionNumber': admissionNumber,
    'admissionDate': admissionDate,
    'rollNumber': rollNumber,
    'mediumOfInstruction': mediumOfInstruction,
    'languagesStudied': languagesStudied,
    'academicStream': academicStream,
    'subjectsStudied': subjectsStudied,
    'statusInPreviousYear': statusInPreviousYear,
    'gradeStudiedLastYear': gradeStudiedLastYear,
    'enrolledUnder': enrolledUnder,
    'previousResult': previousResult,
    'marksObtainedPercentage': marksObtainedPercentage,
    'daysAttendedLastYear': daysAttendedLastYear,
  };
}

/// Represents a single uploaded document/work-photo attached to a student,
/// as returned by GET /api/studentrecord/v1/getrecord/:schoolId/:studentId
/// (or the legacy getall response). Field names on the server are not fully
/// standardized, so [fromJson] checks several common keys.
class StudentDocument {
  final String id;
  final String url;
  final String name;

  const StudentDocument({required this.id, required this.url, required this.name});

  static StudentDocument? fromJson(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json as Map);
    final id = (m['_id'] ?? m['id'] ?? m['documentId'])?.toString();
    final url =
    (m['url'] ?? m['fileUrl'] ?? m['path'] ?? m['location'] ?? m['link'])
        ?.toString();
    if (id == null || url == null || url.isEmpty) return null;
    final name = (m['originalName'] ?? m['filename'] ?? m['name'] ?? 'File')
        .toString();
    return StudentDocument(id: id, url: resolveStudentFileUrl(url)!, name: name);
  }
}

/// Resolves a possibly-relative file path returned by the API into an
/// absolute URL the app can load with Image.network / url_launcher.
String? resolveStudentFileUrl(String? path) {
  if (path == null || path.trim().isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final base = ApiConstants.baseUrl.endsWith('/')
      ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
      : ApiConstants.baseUrl;
  final p = path.startsWith('/') ? path : '/$path';
  return '$base$p';
}

/// Best-effort extraction of a profile image URL from a student / student
/// record JSON object. Checks several common key names since the API isn't
/// fully standardized across endpoints.
String? extractProfileImageUrl(Map<String, dynamic> data) {
  for (final key in [
    'profileImage',
    'profileImageUrl',
    'profilePic',
    'profilePicture',
    'profilePhoto',
    'photo',
    'photoUrl',
    'image',
    'imageUrl',
    'studentImage',
    'studentImageUrl',
  ]) {
    final v = data[key];
    if (v is String && v.trim().isNotEmpty) return resolveStudentFileUrl(v);
    if (v is Map) {
      final nested = (v['url'] ?? v['path'] ?? v['fileUrl'])?.toString();
      if (nested != null && nested.isNotEmpty) {
        return resolveStudentFileUrl(nested);
      }
    }
  }
  return null;
}

/// Best-effort extraction of the document/work-photo list from a student /
/// student record JSON object.
List<StudentDocument> extractStudentDocuments(Map<String, dynamic> data) {
  for (final key in [
    'documents',
    'files',
    'uploadedFiles',
    'attachments',
    'workPhotos',
    'workPhotoFiles',
  ]) {
    final v = data[key];
    if (v is List && v.isNotEmpty) {
      return v
          .map(StudentDocument.fromJson)
          .whereType<StudentDocument>()
          .toList();
    }
  }
  return const [];
}

// =============================================================================
// CREATE / EDIT STUDENT PROFILE PAGE
// =============================================================================

class CreateStudentProfilePage extends StatefulWidget {
  final String? schoolId;
  final Student? student;
  final bool isEdit;

  /// Profile photo URL fetched via GET /api/studentrecord/v1/getrecord
  /// (or extracted from the management list), shown until the user picks a
  /// new image.
  final String? existingImageUrl;

  /// Previously-uploaded work-photo documents for this student, fetched via
  /// GET /api/studentrecord/v1/getrecord. Each entry is the raw JSON map
  /// from the API and is parsed with [StudentDocument.fromJson].
  final List<Map<String, dynamic>>? existingDocuments;

  const CreateStudentProfilePage({
    super.key,
    this.schoolId,
    this.student,
    this.isEdit = false,
    this.existingImageUrl,
    this.existingDocuments,
  });

  @override
  State<CreateStudentProfilePage> createState() =>
      _CreateStudentProfilePageState();
}

class _CreateStudentProfilePageState extends State<CreateStudentProfilePage>
    with TickerProviderStateMixin {
  final _auth = Get.find<AuthController>();
  final _school = Get.find<SchoolController>();
  final billFiles = <PlatformFile>[].obs;
  final workPhotoFiles = <PlatformFile>[].obs;

  String? get _resolvedSchoolId {
    final argSchoolId = Get.arguments?['schoolId'] as String?;
    final id = widget.schoolId ?? argSchoolId;
    if (id != null && id.isNotEmpty) return id;
    final role = _auth.user.value?.role?.toLowerCase() ?? '';
    if (role == 'correspondent') return _school.selectedSchool.value?.id;
    return _auth.user.value?.schoolId;
  }

  Student? get _resolvedStudent =>
      widget.student ?? Get.arguments?['student'] as Student?;

  bool get _resolvedIsEdit =>
      widget.isEdit || (Get.arguments?['isEdit'] as bool? ?? false);

  String? get _resolvedExistingImageUrl =>
      widget.existingImageUrl ?? Get.arguments?['existingImageUrl'] as String?;

  List<Map<String, dynamic>>? get _resolvedExistingDocuments =>
      widget.existingDocuments ??
          (Get.arguments?['existingDocuments'] as List?)?.cast<Map<String, dynamic>>();

  bool get _isCorrespondent =>
      (_auth.user.value?.role?.toLowerCase() ?? '') == 'correspondent';



  /// Display label for the picked class/section. Handles the case where a
  /// student has no class/section assigned yet (currentClassId == null in
  /// the getrecord response) instead of literally showing "null".
  String _classSectionLabel({bool compact = false}) {
    if (_pickedClassName == null) return 'No Class Assigned';
    final secPrefix = compact ? 'Sec' : 'Section';
    return '$_pickedClassName'
        '${_pickedSectionName != null ? "  ·  $secPrefix $_pickedSectionName" : ""}';
  }

  String? _pickedClassId;
  String? _pickedClassName;
  String? _pickedSectionId;
  String? _pickedSectionName;
  bool _selectionDone = false;

  final _pageCtrl = PageController();
  int _currentPage = 0;
  bool _isSubmitting = false;
  File? _pickedImage;

  /// Existing profile image URL (from GET getrecord). Shown until the user
  /// picks a new [_pickedImage].
  String? _existingImageUrl;

  /// Previously-uploaded documents/work-photos for this student. Mutable so
  /// deleted items can be removed from the UI immediately.
  final List<StudentDocument> _documents = [];
  String? _deletingDocId;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  final _basicKey = GlobalKey<FormState>();
  final _mandatoryKey = GlobalKey<FormState>();
  final _additionalKey = GlobalKey<FormState>();
  final _enrollmentKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _srIdCtrl = TextEditingController();
  bool _isActive = true;

  final _dobCtrl = TextEditingController();
  final _eduNoCtrl = TextEditingController();
  final _motherCtrl = TextEditingController();
  final _fatherCtrl = TextEditingController();
  final _guardianCtrl = TextEditingController();
  final _aadhaarNoCtrl = TextEditingController();
  final _aadhaarNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _altMobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _motherTongueCtrl = TextEditingController();
  final _minorityCtrl = TextEditingController();
  final _impairmentsCtrl = TextEditingController();
  final _mainstreamedDateCtrl = TextEditingController();
  final _disabilityPctCtrl = TextEditingController();
  String? _selGender, _selBlood, _selSocialCat;
  String? _selBpl, _selAay, _selEws, _selCwsn, _selIndian, _selOos,
      _selDisCert;
  String? _selMedium, _selStream, _selPrevStatus, _selPrevResult;

  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _distanceCtrl = TextEditingController();
  final _sldTypeCtrl = TextEditingController();
  final _activitiesCtrl = TextEditingController();
  final _parentEduCtrl = TextEditingController();
  final _facilitiesCtrl = TextEditingController();
  final _facCwsnCtrl = TextEditingController();
  String? _selSLD, _selASD, _selADHD, _selGifted, _selCompetitions,
      _selDigital;

  final _admNoCtrl = TextEditingController();
  final _admDateCtrl = TextEditingController();
  final _rollNoCtrl = TextEditingController();
  final _languagesCtrl = TextEditingController();
  final _subjectsCtrl = TextEditingController();
  final _enrolledCtrl = TextEditingController();
  final _gradeLastCtrl = TextEditingController();
  final _marksPctCtrl = TextEditingController();
  final _daysCtrl = TextEditingController();

  static const _yesNo = ['Yes', 'No'];
  static const _genders = ['Male', 'Female', 'Other'];
  static const _bloods = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  static const _socCats = ['General', 'OBC', 'SC', 'ST'];
  static const _mediums = ['Telugu', 'Hindi', 'English', 'Urdu', 'Tamil'];
  static const _streams = ['Science', 'Commerce', 'Arts', 'Vocational'];
  static const _prevSts = [
    'Promoted',
    'Detained',
    'Transferred',
    'Dropped out'
  ];
  static const _prevRes = ['Pass', 'Fail', 'Absent'];

  static const _stepLabels = [
    'Basic',
    'Mandatory',
    'Additional',
    'Enrollment'
  ];
  static const _stepIcons = [
    Icons.person_outline_rounded,
    Icons.family_restroom_rounded,
    Icons.monitor_heart_outlined,
    Icons.school_outlined,
  ];

  Map<String, dynamic> _stripNulls(Map<String, dynamic> map) =>
      Map.fromEntries(map.entries.where((e) => e.value != null));

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Pre-fill existing profile photo + previously-uploaded documents, as
    // fetched via GET /api/studentrecord/v1/getrecord by the management page.
    _existingImageUrl = resolveStudentFileUrl(_resolvedExistingImageUrl);
    if (_resolvedExistingDocuments != null) {
      for (final raw in _resolvedExistingDocuments!) {
        final doc = StudentDocument.fromJson(raw);
        if (doc != null) _documents.add(doc);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sid = _resolvedSchoolId;
      if (sid != null) {
        _school.getAllClasses(sid).then((_) {
          if (_resolvedIsEdit && _resolvedStudent?.classId != null) {
            _school.getAllSections(
              classId: _resolvedStudent!.classId,
              schoolId: sid,
            ).then((_) => _applyEditPreFill());
          }
        });
      }

      if (_resolvedIsEdit  && _resolvedStudent != null) {
        _applyEditPreFill();
        // Don't auto-open the picker for edit mode — the form is shown
        // regardless of whether a class/section is assigned (see
        // _applyEditPreFill). Users can tap "Change" to assign one.
      } else {
        _showClassSectionPicker();
      }
    });
  }

  // ── Date helpers ────────────────────────────────────────────────────────────

  /// DD/MM/YYYY (UI) → YYYY-MM-DD (server)
  String? _isoDate(String? ddmmyyyy) {
    if (ddmmyyyy == null || ddmmyyyy.trim().isEmpty) return null;
    final parts = ddmmyyyy.split('/');
    if (parts.length != 3) return ddmmyyyy; // already ISO or unknown format
    final day = parts[0].padLeft(2, '0');
    final month = parts[1].padLeft(2, '0');
    final year = parts[2];
    return '$year-$month-$day';
  }

  /// YYYY-MM-DD (server) → DD/MM/YYYY (UI) — used when pre-filling edit form
  String? _fromIsoDate(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (v.contains('/')) return v; // already DD/MM/YYYY
    final parts = v.split('-');
    if (parts.length == 3 && parts[0].length == 4) {
      return '${parts[2].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[0]}';
    }
    return v;
  }

  void _applyEditPreFill() {
    final s = _resolvedStudent;
    if (s == null) return;

    _nameCtrl.text = s.name ?? '';
    _srIdCtrl.text = s.srId ?? '';
    _isActive = s.isActive ?? true;

    if (s.classId != null) {
      final matchedClass =
      _school.classes.firstWhereOrNull((c) => c.id == s.classId);
      _pickedClassId = s.classId;
      _pickedClassName = matchedClass?.name ?? s.classId;
    }
    if (s.sectionId != null) {
      final matchedSection =
      _school.sections.firstWhereOrNull((sec) => sec.id == s.sectionId);
      _pickedSectionId = s.sectionId;
      _pickedSectionName = matchedSection?.name ?? s.sectionId;
    }

    // Edit mode: always proceed to the form, even if this student has no
    // class/section assigned yet (currentClassId/currentSectionId == null).
    // The user can still assign one later via the "Change" banner.
    if (widget.isEdit || _pickedClassId != null) _selectionDone = true;

    _selGender = s.gender;
    // FIX: convert ISO dates → DD/MM/YYYY for display in date fields
    _dobCtrl.text = _fromIsoDate(s.dob) ?? '';
    _eduNoCtrl.text = s.educationNumber ?? '';
    _motherCtrl.text = s.motherName ?? '';
    _fatherCtrl.text = s.fatherName ?? '';
    _guardianCtrl.text = s.guardianName ?? '';
    _aadhaarNoCtrl.text = s.aadhaarNumber ?? '';
    _aadhaarNameCtrl.text = s.aadhaarName ?? '';
    _addressCtrl.text = s.address ?? '';
    _pincodeCtrl.text = s.pincode ?? '';
    _mobileCtrl.text = s.mobileNumber ?? '';
    _altMobileCtrl.text = s.alternateMobile ?? '';
    _emailCtrl.text = s.email ?? '';
    _motherTongueCtrl.text = s.motherTongue ?? '';
    _selSocialCat = s.socialCategory;
    _minorityCtrl.text = s.minorityGroup ?? '';
    _selBpl = s.bpl;
    _selAay = s.aay;
    _selEws = s.ews;
    _selCwsn = s.cwsn;
    _impairmentsCtrl.text = s.impairments ?? '';
    _selIndian = s.indian;
    _selOos = s.outOfSchool;
    _mainstreamedDateCtrl.text = _fromIsoDate(s.mainstreamedDate) ?? '';
    _selDisCert = s.disabilityCert;
    _disabilityPctCtrl.text = s.disabilityPercent ?? '';
    _selBlood = s.bloodGroup;

    _facilitiesCtrl.text = s.facilitiesProvided ?? '';
    _facCwsnCtrl.text = s.facilitiesForCWSN ?? '';
    _selSLD = s.screenedForSLD;
    _sldTypeCtrl.text = s.sldType ?? '';
    _selASD = s.screenedForASD;
    _selADHD = s.screenedForADHD;
    _selGifted = s.isGiftedOrTalented;
    _selCompetitions = s.participatedInCompetitions;
    _activitiesCtrl.text = s.participatedInActivities ?? '';
    _selDigital = s.canHandleDigitalDevices;
    _heightCtrl.text = s.heightInCm ?? '';
    _weightCtrl.text = s.weightInKg ?? '';
    _distanceCtrl.text = s.distanceToSchool ?? '';
    _parentEduCtrl.text = s.parentEducationLevel ?? '';

    _admNoCtrl.text = s.admissionNumber ?? '';
    _admDateCtrl.text = _fromIsoDate(s.admissionDate) ?? '';
    _rollNoCtrl.text = s.rollNumber ?? '';
    _selMedium = s.mediumOfInstruction;
    _languagesCtrl.text = s.languagesStudied ?? '';
    _selStream = s.academicStream;
    _subjectsCtrl.text = s.subjectsStudied ?? '';
    _selPrevStatus = s.statusInPreviousYear;
    _gradeLastCtrl.text = s.gradeStudiedLastYear ?? '';
    _enrolledCtrl.text = s.enrolledUnder ?? '';
    _selPrevResult = s.previousResult;
    _marksPctCtrl.text = s.marksObtainedPercentage ?? '';
    _daysCtrl.text = s.daysAttendedLastYear ?? '';

    setState(() {});
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pageCtrl.dispose();
    for (final c in [
      _nameCtrl,
      _srIdCtrl,
      _dobCtrl,
      _eduNoCtrl,
      _motherCtrl,
      _fatherCtrl,
      _guardianCtrl,
      _aadhaarNoCtrl,
      _aadhaarNameCtrl,
      _addressCtrl,
      _pincodeCtrl,
      _mobileCtrl,
      _altMobileCtrl,
      _emailCtrl,
      _motherTongueCtrl,
      _minorityCtrl,
      _impairmentsCtrl,
      _mainstreamedDateCtrl,
      _disabilityPctCtrl,
      _heightCtrl,
      _weightCtrl,
      _distanceCtrl,
      _sldTypeCtrl,
      _activitiesCtrl,
      _parentEduCtrl,
      _facilitiesCtrl,
      _facCwsnCtrl,
      _admNoCtrl,
      _admDateCtrl,
      _rollNoCtrl,
      _languagesCtrl,
      _subjectsCtrl,
      _enrolledCtrl,
      _gradeLastCtrl,
      _marksPctCtrl,
      _daysCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _showClassSectionPicker() {
    if (_isCorrespondent &&
        _school.selectedSchool.value == null &&
        _resolvedSchoolId  == null) {
      Get.snackbar('No School Selected',
          'Please select a school from the sidebar first.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: _AppColors.error,
          colorText: Colors.white);
      Get.back();
      return;
    }

    if (_pickedClassId != null && _school.sections.isEmpty) {
      _school.getAllSections(
          classId: _pickedClassId, schoolId: _resolvedSchoolId);
    }

    Get.bottomSheet(
      _ClassSectionPickerSheet(
        schoolController: _school,
        resolvedSchoolId: _resolvedSchoolId,
        isEdit: _resolvedIsEdit,
        initialClassId: _pickedClassId,
        initialClassName: _pickedClassName,
        initialSectionId: _pickedSectionId,
        initialSectionName: _pickedSectionName,
        onConfirm: (classId, className, sectionId, sectionName) {
          setState(() {
            _pickedClassId = classId;
            _pickedClassName = className;
            _pickedSectionId = sectionId;
            _pickedSectionName = sectionName;
            _selectionDone = true;
          });
        },
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
      backgroundColor: Colors.transparent,
    );
  }

  bool _validateCurrentStep() {
    switch (_currentPage) {
      case 0:
        return _basicKey.currentState?.validate() ?? false;
      case 1:
        return _mandatoryKey.currentState?.validate() ?? false;
      case 2:
        return _additionalKey.currentState?.validate() ?? false;
      case 3:
        return _enrollmentKey.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  void _nextPage() {
    if (!_validateCurrentStep()) return;
    if (_currentPage < 3) {
      setState(() => _currentPage++);
      _pageCtrl.animateToPage(_currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic);
    } else {
      _submit();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _pageCtrl.animateToPage(_currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic);
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _pickedImage = File(picked.path));
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ctrl.text =
      '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  String? _t(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  StudentPayload _buildPayload() {
    final mandatory = MandatoryDetails()
      ..gender = _selGender
      ..dob = _t(_dobCtrl)
      ..educationNumber = _t(_eduNoCtrl)
      ..motherName = _t(_motherCtrl)
      ..fatherName = _t(_fatherCtrl)
      ..guardianName = _t(_guardianCtrl)
      ..aadhaarNumber = _t(_aadhaarNoCtrl)
      ..aadhaarName = _t(_aadhaarNameCtrl)
      ..address = _t(_addressCtrl)
      ..pincode = _t(_pincodeCtrl)
      ..mobileNumber = _t(_mobileCtrl)
      ..alternateMobile = _t(_altMobileCtrl)
      ..email = _t(_emailCtrl)
      ..motherTongue = _t(_motherTongueCtrl)
      ..socialCategory = _selSocialCat
      ..minorityGroup = _t(_minorityCtrl)
      ..bpl = _selBpl
      ..aay = _selAay
      ..ews = _selEws
      ..cwsn = _selCwsn
      ..impairments = _t(_impairmentsCtrl)
      ..indian = _selIndian
      ..outOfSchool = _selOos
      ..mainstreamedDate = _t(_mainstreamedDateCtrl)
      ..disabilityCert = _selDisCert
      ..disabilityPercent = _t(_disabilityPctCtrl)
      ..bloodGroup = _selBlood;

    final nonMandatory = NonMandatoryDetails()
      ..facilitiesProvided = _t(_facilitiesCtrl)
      ..facilitiesForCWSN = _t(_facCwsnCtrl)
      ..screenedForSLD = _selSLD
      ..sldType = _t(_sldTypeCtrl)
      ..screenedForASD = _selASD
      ..screenedForADHD = _selADHD
      ..isGiftedOrTalented = _selGifted
      ..participatedInCompetitions = _selCompetitions
      ..participatedInActivities = _t(_activitiesCtrl)
      ..canHandleDigitalDevices = _selDigital
      ..heightInCm = _t(_heightCtrl)
      ..weightInKg = _t(_weightCtrl)
      ..distanceToSchool = _t(_distanceCtrl)
      ..parentEducationLevel = _t(_parentEduCtrl)
      ..admissionNumber = _t(_admNoCtrl)
      ..admissionDate = _t(_admDateCtrl)
      ..rollNumber = _t(_rollNoCtrl)
      ..mediumOfInstruction = _selMedium
      ..languagesStudied = _t(_languagesCtrl)
      ..academicStream = _selStream
      ..subjectsStudied = _t(_subjectsCtrl)
      ..statusInPreviousYear = _selPrevStatus
      ..gradeStudiedLastYear = _t(_gradeLastCtrl)
      ..enrolledUnder = _t(_enrolledCtrl)
      ..previousResult = _selPrevResult
      ..marksObtainedPercentage = _t(_marksPctCtrl)
      ..daysAttendedLastYear = _t(_daysCtrl);

    return StudentPayload(
      schoolId: _resolvedSchoolId!,
      srId: _t(_srIdCtrl),
      studentName: _nameCtrl.text.trim(),
      currentClassId: _pickedClassId,
      currentSectionId: _pickedSectionId,
      isActive: _isActive,
      mandatory: mandatory,
      nonMandatory: nonMandatory,
    );
  }

  // ── Separate file upload ───────────────────────────────────────────────────
  //
  // POST /api/student/v1/upload-files/:studentId
  // Field name : 'files'  (multipart, multiple allowed)
  // Auth header: x-school-id  ← was missing, caused 403/404
  // Called AFTER the student record is successfully created / updated.
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _uploadFilesToStudent(
      String studentId, String schoolId) async {
    if (workPhotoFiles.isEmpty) return;
    final apiService = Get.find<ApiService>();

    final formData = dio.FormData();
    for (final wf in workPhotoFiles) {
      if (wf.path != null) {
        formData.files.add(MapEntry(
          'files',
          await dio.MultipartFile.fromFile(wf.path!, filename: wf.name),
        ));
      } else if (wf.bytes != null) {
        formData.files.add(MapEntry(
          'files',
          dio.MultipartFile.fromBytes(wf.bytes!, filename: wf.name),
        ));
      }
    }

    debugPrint('[STUDENT UPLOAD] POST ${ApiConstants.uploadStudentFiles}/$studentId '
        '(${workPhotoFiles.length} file(s))');

    final resp = await apiService.dio.post(
      '${ApiConstants.uploadStudentFiles}/$studentId',
      data: formData,
      options: dio.Options(headers: {'x-school-id': schoolId}),
    );

    debugPrint('[STUDENT UPLOAD] status=${resp.statusCode} ok=${resp.data['ok']}');
    debugPrint('[STUDENT UPLOAD] 📦 FULL RESPONSE: ${resp.data}');
    final verifyResp = await apiService.get('${ApiConstants.getStudent}/$studentId');
    debugPrint('[STUDENT UPLOAD] 🔍 Re-fetched student: ${verifyResp.data}');
    final jsonStr = verifyResp.data.toString();
    const chunkSize = 800;
    for (var i = 0; i < jsonStr.length; i += chunkSize) {
      debugPrint('🔍 CHUNK: ${jsonStr.substring(i, i + chunkSize > jsonStr.length ? jsonStr.length : i + chunkSize)}');
    }
    if (resp.data['ok'] != true) {
      throw Exception('File upload failed: ${resp.data['message']}');
    }
  }

  // ── Main submit ────────────────────────────────────────────────────────────
  //
  // mandatory/nonMandatory → JSON-encoded strings (server calls JSON.parse())
  // 'file'  field           → profile photo, sent with the main create/update
  // 'files' field           → work-photo files, sent to the SEPARATE endpoint
  //                           /api/student/v1/upload-files/:studentId AFTER
  //                           the student record is saved.
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    final schoolId = _resolvedSchoolId;
    if (schoolId == null || schoolId.isEmpty) {
      _showError(_isCorrespondent
          ? 'Please select a school from the sidebar first.'
          : 'School information missing. Please log in again.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiService = Get.find<ApiService>();
      final payload = _buildPayload();

      final mandatoryMap = _stripNulls(payload.mandatory.toJson());
      final nonMandatoryMap = _stripNulls(payload.nonMandatory.toJson());

      // Convert date fields UI (DD/MM/YYYY) → server (YYYY-MM-DD)
      if (mandatoryMap['dob'] != null) {
        mandatoryMap['dob'] = _isoDate(mandatoryMap['dob'] as String);
      }
      if (mandatoryMap['mainstreamedDate'] != null) {
        mandatoryMap['mainstreamedDate'] =
            _isoDate(mandatoryMap['mainstreamedDate'] as String);
      }
      if (nonMandatoryMap['admissionDate'] != null) {
        nonMandatoryMap['admissionDate'] =
            _isoDate(nonMandatoryMap['admissionDate'] as String);
      }

      debugPrint('[STUDENT ${_resolvedIsEdit  ? "UPDATE" : "CREATE"}] '
          'name=${payload.studentName} classId=${payload.currentClassId}');

      // Build flat FormData — mandatory & nonMandatory are JSON strings so the
      // server can call JSON.parse() on them directly (no bracket notation).
      final formData = dio.FormData.fromMap({
        if (!_resolvedIsEdit ) 'schoolId': schoolId,
        if (!_resolvedIsEdit  && payload.srId != null) 'srId': payload.srId,
        'studentName': payload.studentName,
        if (payload.currentClassId != null)
          'currentClassId': payload.currentClassId,
        if (payload.currentSectionId != null)
          'currentSectionId': payload.currentSectionId,
        'isActive': payload.isActive.toString(),
        'mandatory': jsonEncode(mandatoryMap),       // ← JSON string
        'nonMandatory': jsonEncode(nonMandatoryMap), // ← JSON string
      });

      // Profile photo only — sent with the main create/update request.
      if (_pickedImage != null) {
        formData.files.add(MapEntry(
          'file',
          await dio.MultipartFile.fromFile(
            _pickedImage!.path,
            filename:
            'student_image.${_pickedImage!.path.split('.').last}',
          ),
        ));
      }

      // (work-photo files are uploaded separately after save — see below)

      // Debug: log every field
      debugPrint('[STUDENT PAYLOAD FIELDS]');
      for (final f in formData.fields) {
        debugPrint('  ${f.key} = ${f.value}');
      }
      for (final f in formData.files) {
        debugPrint('  ${f.key} = <binary: ${f.value.filename}>');
      }

      Map<String, dynamic>? responseData;

      if (_resolvedIsEdit) {
        final studentId = _resolvedStudent!.id!;
        debugPrint(
            '[STUDENT UPDATE] PUT ${ApiConstants.updateStudent}/$studentId');
        final res = await apiService.dio.put(
          '${ApiConstants.updateStudent}/$studentId',
          data: formData,
          options: dio.Options(headers: {'x-school-id': schoolId}),
        );
        debugPrint(
            '[STUDENT UPDATE] status=${res.statusCode} ok=${res.data['ok']}');
        responseData = res.data as Map<String, dynamic>?;
      } else {
        debugPrint('[STUDENT CREATE] POST ${ApiConstants.createStudent}');
        final res = await apiService.dio.post(
          ApiConstants.createStudent,
          data: formData,
          options: dio.Options(headers: {'x-school-id': schoolId}),
        );
        debugPrint(
            '[STUDENT CREATE] status=${res.statusCode} ok=${res.data['ok']}');
        responseData = res.data as Map<String, dynamic>?;
      }

      if (!mounted) return;

      if (responseData?['ok'] == true) {
        final studentId = responseData?['data']?['_id']?.toString() ??
            responseData?['student']?['_id']?.toString();
        debugPrint('[STUDENT SUCCESS] studentId=$studentId');

        // Upload work-photo files via the dedicated endpoint AFTER save.
        if (studentId != null && workPhotoFiles.isNotEmpty) {
          debugPrint(
              '[STUDENT] Uploading ${workPhotoFiles.length} work photo(s)…');
          try {
            await _uploadFilesToStudent(studentId, schoolId);
            debugPrint('[STUDENT] File upload complete');
          } catch (e) {
            debugPrint('[STUDENT] File upload failed (non-critical): $e');
            // Non-fatal: student was saved; notify but don't block nav.
            Get.snackbar('Upload Warning',
                'Student saved, but file upload failed: $e',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: const Color(0xFFF57C00),
                colorText: Colors.white,
                duration: const Duration(seconds: 4));
          }
        }
        if (studentId != null && _pickedClassId != null) {
          try {
            final mgmtCtrl = Get.isRegistered<StudentManagementController>()
                ? Get.find<StudentManagementController>()
                : Get.put(StudentManagementController());

            final assigned = await mgmtCtrl.assignStudentToClass({
              'schoolId': schoolId,
              'studentId': studentId,
              'classId': _pickedClassId,
              'sectionId': _pickedSectionId,
              'newOld': _resolvedIsEdit  ? 'old' : 'new',
              'rollNumber': _rollNoCtrl.text.trim(),
              'className': _pickedClassName ?? '',
              'sectionName': _pickedSectionName ?? '',
              'isBusApplicable': false,
              'studentName': payload.studentName,
              // 'academicYear': omitted — API docs say it defaults to current
              // academic year if not provided; pass one explicitly if you collect it.
            });

            debugPrint('[STUDENT] class assignment ${assigned ? "succeeded" : "failed"}');
          } catch (e) {
            debugPrint('[STUDENT] class assignment error: $e');
          }
        }
        final action = _resolvedIsEdit  ? 'Updated' : 'Created';
        Get.snackbar(
          '✅ Student $action',
          'Profile for ${_nameCtrl.text.trim()} has been $action successfully!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF2E7D32),
          colorText: Colors.white,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        );
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) Get.back(result: true);
        });
      } else {
        final msg = responseData?['message']?.toString() ??
            'Failed to ${_resolvedIsEdit  ? 'update' : 'create'} student.';
        debugPrint('[STUDENT ERROR] $msg');
        _showError(msg);
      }
    } on dio.DioException catch (e) {
      if (!mounted) return;
      debugPrint(
          '[STUDENT DioException] ${e.response?.statusCode}: ${e.response?.data}');
      _showError(
        (e.response?.data is Map
            ? e.response!.data['message']?.toString()
            : null) ??
            e.message ??
            'Request failed',
      );
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('[STUDENT CATCH] $e\n$st');
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    Get.snackbar('Error', message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: _AppColors.error,
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16));
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    if (!_selectionDone) {
      return Scaffold(
        backgroundColor: _AppColors.surface,
        appBar: _buildAppBar(),
        body: _buildSelectionPrompt(),
      );
    }

    return Scaffold(
      backgroundColor: _AppColors.surface,
      appBar: _buildAppBar(),
      body: Column(children: [
        _buildContextBanner(),
        _buildStepperBar(),
        Expanded(
          child: PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildBasicPage(),
              _buildMandatoryPage(),
              _buildAdditionalPage(),
              _buildEnrollmentPage(),
            ],
          ),
        ),
      ]),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _resolvedIsEdit  ? 'Edit Student Profile' : 'Create Student Profile',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
          if (_selectionDone)
            Text(
              '${_classSectionLabel()}'
                  '${_isCorrespondent ? "  ·  ${_school.selectedSchool.value?.name ?? ''}" : ""}',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }

  Widget _buildContextBanner() {
    return Container(
      color: _AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.class_outlined, size: 13, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              _classSectionLabel(compact: true),
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600),
            ),
          ]),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _showClassSectionPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(children: [
              Icon(Icons.edit_rounded, size: 12, color: Colors.white),
              SizedBox(width: 4),
              Text('Change',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildStepperBar() {
    return Container(
      color: _AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _AppColors.primaryDark.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_stepLabels.length, (i) {
            final done = i < _currentPage;
            final active = i == _currentPage;
            return Expanded(
              child: Row(children: [
                _StepIndicator(
                  index: i,
                  label: _stepLabels[i],
                  icon: _stepIcons[i],
                  isDone: done,
                  isActive: active,
                ),
                if (i < _stepLabels.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: done
                            ? _AppColors.primary
                            : _AppColors.border,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ]),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLast = _currentPage == 3;
    return Container(
      decoration: const BoxDecoration(
        color: _AppColors.cardBg,
        border: Border(top: BorderSide(color: _AppColors.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            if (_currentPage > 0) ...[
              _NavButton(
                label: 'Back',
                icon: Icons.arrow_back_ios_new_rounded,
                onPressed: _isSubmitting ? null : _prevPage,
                outlined: true,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: _NavButton(
                label: isLast
                    ? (_resolvedIsEdit ? 'Update Student' : 'Create Student')
                    : 'Next Step',
                icon: isLast
                    ? Icons.check_circle_outline_rounded
                    : Icons.arrow_forward_ios_rounded,
                onPressed: _isSubmitting ? null : _nextPage,
                loading: _isSubmitting,
                filled: true,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelectionPrompt() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.school_rounded,
                  size: 40, color: _AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text('Select Class & Section',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text(
              'Choose where this student will be enrolled before filling out the profile.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: _AppColors.textSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _showClassSectionPicker,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Select Class & Section'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Pages ──────────────────────────────────────────────────────────────────

  Widget _buildBasicPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Form(
        key: _basicKey,
        child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _FormCard(
            child: Column(children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(alignment: Alignment.bottomRight, children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _AppColors.primaryLight,
                      border: Border.all(
                          color: _AppColors.primary.withOpacity(0.3),
                          width: 2),
                      image: _pickedImage != null
                          ? DecorationImage(
                          image: FileImage(_pickedImage!),
                          fit: BoxFit.cover)
                          : (_existingImageUrl != null
                          ? DecorationImage(
                        image: NetworkImage(_existingImageUrl!),
                        fit: BoxFit.cover,
                        onError: (_, __) {
                          // Broken/expired URL — fall back silently
                          // to the placeholder icon.
                          if (mounted) {
                            setState(() => _existingImageUrl = null);
                          }
                        },
                      )
                          : null),
                    ),
                    child: (_pickedImage == null && _existingImageUrl == null)
                        ? const Icon(Icons.person_rounded,
                        size: 44, color: _AppColors.primary)
                        : null,
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 14, color: Colors.white),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              const Text('Tap to upload photo',
                  style: TextStyle(
                      fontSize: 12, color: _AppColors.textSecondary)),
            ]),
          ),
          const SizedBox(height: 10),
          _buildFileUploadSection(
            'Photo of Work/Item',
            'Upload photo of actual work done or item purchased (Optional)',
            workPhotoFiles,
            false,
            false,
          ),
          if (_documents.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildExistingDocumentsSection(),
          ],
          const SizedBox(height: 16),
          _secHeader(Icons.person_outline_rounded, 'Basic Information'),
          const SizedBox(height: 12),
          _FormCard(
            child: Column(children: [
              _field(_nameCtrl, 'Student Name',
                  required: true,
                  icon: Icons.badge_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Student name is required'
                      : null),
              _divider(),
              _field(_srIdCtrl, 'SR ID',
                  hint: 'Auto-generated if left blank',
                  icon: Icons.tag_rounded),
            ]),
          ),
          const SizedBox(height: 16),
          _FormCard(
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Active Student',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      const Text('Shows on class rosters',
                          style: TextStyle(
                              fontSize: 12,
                              color: _AppColors.textSecondary)),
                    ]),
              ),
              Switch.adaptive(
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                activeColor: _AppColors.primary,
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildMandatoryPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Form(
        key: _mandatoryKey,
        child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _secHeader(Icons.family_restroom_rounded, 'Personal & Family'),
          const SizedBox(height: 12),
          _FormCard(
              child: Column(children: [
                _dropRow('Gender', _selGender, _genders,
                        (v) => setState(() => _selGender = v), Icons.wc_rounded),
                _divider(),
                _dateFieldRow(_dobCtrl, 'Date of Birth'),
                _divider(),
                _field(_motherCtrl, "Mother's Name",
                    icon: Icons.person_2_outlined),
                _divider(),
                _field(_fatherCtrl, "Father's Name",
                    icon: Icons.person_outlined),
                _divider(),
                _field(_guardianCtrl, "Guardian's Name",
                    icon: Icons.supervisor_account_outlined),
                _divider(),
                _dropRow('Blood Group', _selBlood, _bloods,
                        (v) => setState(() => _selBlood = v),
                    Icons.bloodtype_outlined),
              ])),
          const SizedBox(height: 20),
          _secHeader(Icons.phone_outlined, 'Contact Details'),
          const SizedBox(height: 12),
          _FormCard(
              child: Column(children: [
                _field(_mobileCtrl, 'Mobile Number',
                    keyboard: TextInputType.phone,
                    icon: Icons.phone_rounded),
                _divider(),
                _field(_altMobileCtrl, 'Alternate Mobile',
                    keyboard: TextInputType.phone,
                    icon: Icons.phone_callback_outlined),
                _divider(),
                _field(_emailCtrl, 'Email',
                    keyboard: TextInputType.emailAddress,
                    icon: Icons.mail_outline_rounded),
                _divider(),
                _field(_motherTongueCtrl, 'Mother Tongue',
                    icon: Icons.language_rounded),
              ])),
          const SizedBox(height: 20),
          _secHeader(Icons.location_on_outlined, 'Address & ID'),
          const SizedBox(height: 12),
          _FormCard(
              child: Column(children: [
                _field(_addressCtrl, 'Address',
                    maxLines: 3, icon: Icons.home_outlined),
                _divider(),
                _field(_pincodeCtrl, 'Pincode',
                    keyboard: TextInputType.number,
                    icon: Icons.pin_drop_outlined,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ]),
                _divider(),
                _field(_eduNoCtrl, 'Education Number',
                    icon: Icons.numbers_rounded),
                _divider(),
                _field(_aadhaarNoCtrl, 'Aadhaar Number',
                    keyboard: TextInputType.number,
                    icon: Icons.credit_card_outlined,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ]),
                _divider(),
                _field(_aadhaarNameCtrl, 'Name on Aadhaar',
                    icon: Icons.person_pin_outlined),
              ])),
          const SizedBox(height: 20),
          _secHeader(Icons.checklist_rounded, 'Social & Welfare'),
          const SizedBox(height: 12),
          _FormCard(
              child: Column(children: [
                _dropRow('Social Category', _selSocialCat, _socCats,
                        (v) => setState(() => _selSocialCat = v),
                    Icons.group_outlined),
                _divider(),
                _field(_minorityCtrl, 'Minority Group',
                    icon: Icons.people_outline),
                _divider(),
                Row(children: [
                  Expanded(
                      child: _dropCompact('BPL', _selBpl, _yesNo,
                              (v) => setState(() => _selBpl = v))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _dropCompact('AAY', _selAay, _yesNo,
                              (v) => setState(() => _selAay = v))),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _dropCompact('EWS', _selEws, _yesNo,
                              (v) => setState(() => _selEws = v))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _dropCompact('CWSN', _selCwsn, _yesNo,
                              (v) => setState(() => _selCwsn = v))),
                ]),
                _divider(),
                _field(_impairmentsCtrl, 'Impairments',
                    icon: Icons.accessibility_new_outlined),
                _divider(),
                Row(children: [
                  Expanded(
                      child: _dropCompact('Indian National', _selIndian, _yesNo,
                              (v) => setState(() => _selIndian = v))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _dropCompact('Out of School', _selOos, _yesNo,
                              (v) => setState(() => _selOos = v))),
                ]),
                _divider(),
                _dateFieldRow(_mainstreamedDateCtrl, 'Mainstreamed Date'),
                _divider(),
                Row(children: [
                  Expanded(
                      child: _dropCompact(
                          'Disability Cert', _selDisCert, _yesNo,
                              (v) => setState(() => _selDisCert = v))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _field(_disabilityPctCtrl, 'Disability %',
                          keyboard: TextInputType.number)),
                ]),
              ])),
        ]),
      ),
    );
  }

  Widget _buildAdditionalPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Form(
        key: _additionalKey,
        child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _secHeader(Icons.monitor_heart_outlined, 'Health & Physical'),
          const SizedBox(height: 12),
          _FormCard(
              child: Column(children: [
                Row(children: [
                  Expanded(
                      child: _field(_heightCtrl, 'Height (cm)',
                          keyboard: TextInputType.number,
                          icon: Icons.height_rounded)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _field(_weightCtrl, 'Weight (kg)',
                          keyboard: TextInputType.number,
                          icon: Icons.monitor_weight_outlined)),
                ]),
                _divider(),
                _field(_distanceCtrl, 'Distance to School (km)',
                    icon: Icons.directions_walk_rounded),
                _divider(),
                _dropRow('Screened for SLD', _selSLD, _yesNo,
                        (v) => setState(() => _selSLD = v),
                    Icons.psychology_outlined),
                _divider(),
                _field(_sldTypeCtrl, 'SLD Type', icon: Icons.notes_rounded),
                _divider(),
                Row(children: [
                  Expanded(
                      child: _dropCompact('ASD', _selASD, _yesNo,
                              (v) => setState(() => _selASD = v))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _dropCompact('ADHD', _selADHD, _yesNo,
                              (v) => setState(() => _selADHD = v))),
                ]),
                _divider(),
                _field(_facilitiesCtrl, 'Facilities Provided',
                    icon: Icons.house_outlined),
                _divider(),
                _field(_facCwsnCtrl, 'Facilities for CWSN',
                    icon: Icons.accessible_outlined),
              ])),
          const SizedBox(height: 20),
          _secHeader(Icons.star_outline_rounded, 'Talents & Digital'),
          const SizedBox(height: 12),
          _FormCard(
              child: Column(children: [
                _dropRow(
                    'Gifted / Talented',
                    _selGifted,
                    _yesNo,
                        (v) => setState(() => _selGifted = v),
                    Icons.emoji_events_outlined),
                _divider(),
                _dropRow(
                    'Participated in Competitions',
                    _selCompetitions,
                    _yesNo,
                        (v) => setState(() => _selCompetitions = v),
                    Icons.military_tech_outlined),
                _divider(),
                _field(_activitiesCtrl, 'Activities (sports, arts…)',
                    icon: Icons.sports_soccer_outlined),
                _divider(),
                _dropRow(
                    'Handles Digital Devices',
                    _selDigital,
                    _yesNo,
                        (v) => setState(() => _selDigital = v),
                    Icons.tablet_android_outlined),
                _divider(),
                _field(_parentEduCtrl, 'Parent Education Level',
                    icon: Icons.school_outlined),
              ])),
        ]),
      ),
    );
  }

  Widget _buildEnrollmentPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Form(
        key: _enrollmentKey,
        child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _secHeader(Icons.school_outlined, 'Enrollment Details'),
          const SizedBox(height: 12),
          _FormCard(
              child: Column(children: [
                Row(children: [
                  Expanded(
                      child: _field(_admNoCtrl, 'Admission No.',
                          icon: Icons.tag_rounded)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _dateFieldRow(_admDateCtrl, 'Admission Date')),
                ]),
                _divider(),
                _field(_rollNoCtrl, 'Roll Number',
                    icon: Icons.format_list_numbered_rounded),
                _divider(),
                _dropRow('Medium of Instruction', _selMedium, _mediums,
                        (v) => setState(() => _selMedium = v),
                    Icons.translate_rounded),
                _divider(),
                _field(_languagesCtrl, 'Languages Studied',
                    hint: 'e.g. English, Telugu', icon: Icons.language_rounded),
                _divider(),
                _dropRow('Academic Stream', _selStream, _streams,
                        (v) => setState(() => _selStream = v),
                    Icons.timeline_rounded),
                _divider(),
                _field(_subjectsCtrl, 'Subjects Studied',
                    hint: 'Comma-separated', icon: Icons.book_outlined),
                _divider(),
                _field(_enrolledCtrl, 'Enrolled Under',
                    icon: Icons.assignment_outlined),
              ])),
          const SizedBox(height: 20),
          _secHeader(Icons.history_rounded, 'Previous Academic Year'),
          const SizedBox(height: 12),
          _FormCard(
              child: Column(children: [
                _dropRow(
                    'Status in Previous Year',
                    _selPrevStatus,
                    _prevSts,
                        (v) => setState(() => _selPrevStatus = v),
                    Icons.grade_outlined),
                _divider(),
                _field(_gradeLastCtrl, 'Grade Last Year',
                    hint: 'e.g. Class 5', icon: Icons.class_outlined),
                _divider(),
                _dropRow(
                    'Previous Result',
                    _selPrevResult,
                    _prevRes,
                        (v) => setState(() => _selPrevResult = v),
                    Icons.fact_check_outlined),
                _divider(),
                Row(children: [
                  Expanded(
                      child: _field(_marksPctCtrl, 'Marks %',
                          keyboard: TextInputType.number,
                          icon: Icons.percent_rounded)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _field(_daysCtrl, 'Days Attended',
                          keyboard: TextInputType.number,
                          icon: Icons.calendar_today_rounded)),
                ]),
              ])),
        ]),
      ),
    );
  }

  // ── Small helpers ──────────────────────────────────────────────────────────

  Widget _secHeader(IconData icon, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 0),
    child: Row(children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
            color: _AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: _AppColors.primary),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _AppColors.textPrimary)),
    ]),
  );

  Widget _divider() =>
      const Divider(height: 1, thickness: 0.5, color: _AppColors.border);

  Widget _field(
      TextEditingController ctrl,
      String label, {
        String? hint,
        int maxLines = 1,
        TextInputType keyboard = TextInputType.text,
        List<TextInputFormatter>? formatters,
        String? Function(String?)? validator,
        IconData? icon,
        bool required = false,
      }) {
    final effectiveValidator = validator ??
        (required
            ? (String? v) =>
        (v == null || v.trim().isEmpty) ? '$label is required' : null
            : null);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboard,
        inputFormatters: formatters,
        validator: effectiveValidator,
        style: const TextStyle(
            fontSize: 14,
            color: _AppColors.textPrimary,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          prefixIcon: icon != null
              ? Icon(icon, size: 18, color: _AppColors.textHint)
              : null,
          labelStyle: const TextStyle(
              fontSize: 13, color: _AppColors.textSecondary),
          hintStyle:
          const TextStyle(fontSize: 13, color: _AppColors.textHint),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
          isDense: true,
        ),
      ),
    );
  }

  Widget _dropRow(
      String label,
      String? value,
      List<String> items,
      void Function(String?) onChanged,
      IconData icon, {
        bool required = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        validator: required
            ? (v) => (v == null || v.isEmpty) ? '$label is required' : null
            : null,
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: _AppColors.textHint, size: 20),
        style: const TextStyle(
            fontSize: 14,
            color: _AppColors.textPrimary,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          prefixIcon: Icon(icon, size: 18, color: _AppColors.textHint),
          labelStyle: const TextStyle(
              fontSize: 13, color: _AppColors.textSecondary),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
          isDense: true,
        ),
        items: items
            .map((e) => DropdownMenuItem(
            value: e,
            child: Text(e, style: const TextStyle(fontSize: 14))))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _dropCompact(
      String label,
      String? value,
      List<String> items,
      void Function(String?) onChanged, {
        bool required = false,
      }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      validator: required
          ? (v) => (v == null || v.isEmpty) ? '$label is required' : null
          : null,
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: _AppColors.textHint, size: 18),
      style:
      const TextStyle(fontSize: 13, color: _AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        labelStyle: const TextStyle(
            fontSize: 12, color: _AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
          const BorderSide(color: _AppColors.primary, width: 1.5),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        isDense: true,
        filled: true,
        fillColor: _AppColors.sectionBg,
      ),
      items: items
          .map((e) => DropdownMenuItem(
          value: e,
          child: Text(e, style: const TextStyle(fontSize: 13))))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _dateFieldRow(
      TextEditingController ctrl,
      String label, {
        bool required = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: TextFormField(
        controller: ctrl,
        readOnly: true,
        onTap: () => _pickDate(ctrl),
        validator: required
            ? (v) =>
        (v == null || v.trim().isEmpty) ? '$label is required' : null
            : null,
        style: const TextStyle(
            fontSize: 14,
            color: _AppColors.textPrimary,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: 'DD / MM / YYYY',
          labelStyle: const TextStyle(
              fontSize: 13, color: _AppColors.textSecondary),
          hintStyle:
          const TextStyle(fontSize: 13, color: _AppColors.textHint),
          prefixIcon: const Icon(Icons.calendar_month_rounded,
              size: 18, color: _AppColors.textHint),
          suffixIcon: const Icon(Icons.arrow_drop_down_rounded,
              size: 18, color: _AppColors.textHint),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildFileUploadSection(
      String title,
      String subtitle,
      RxList<PlatformFile> files,
      bool isMandatory,
      bool isBillFile,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: AppTheme.primaryText)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(fontSize: 10, color: AppTheme.mutedText)),
        const SizedBox(height: 12),
        Obx(() => Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: files.isEmpty && isMandatory
                  ? AppTheme.errorRed
                  : Colors.grey.shade200,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _pickFile(isBillFile),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: files.isEmpty
                    ? Column(children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        const Color(0xFF2563EB).withOpacity(0.1),
                        const Color(0xFF2563EB).withOpacity(0.05),
                      ]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_upload,
                        size: 32, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap to upload file${isMandatory ? " *" : ""}',
                    style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.mutedText,
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'JPG, PNG, PDF (Multiple files allowed)',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedText),
                  ),
                ])
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF2563EB),
                              Color(0xFF1D4ED8)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.check_circle,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${files.length} file(s) selected',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB)),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius:
                            BorderRadius.circular(8)),
                        child: IconButton(
                          onPressed: () => files.clear(),
                          icon: Icon(Icons.close,
                              color: AppTheme.mutedText),
                          iconSize: 20,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    ...files.map((file) => Padding(
                      padding:
                      const EdgeInsets.only(top: 4),
                      child: Row(children: [
                        const Icon(
                            Icons.insert_drive_file,
                            size: 16,
                            color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(file.name,
                              style: const TextStyle(
                                  fontSize: 12),
                              overflow:
                              TextOverflow.ellipsis),
                        ),
                      ]),
                    )),
                  ],
                ),
              ),
            ),
          ),
        )),
      ],
    );
  }

  void _pickFile(bool isBillFile) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      if (isBillFile) {
        billFiles.value = result.files;
        Get.snackbar(
            'Success', '${result.files.length} bill file(s) selected');
      } else {
        workPhotoFiles.value = result.files;
        Get.snackbar(
            'Success', '${result.files.length} work photo(s) selected');
      }
    }
  }

  // ── Existing uploaded documents (from getrecord) ──────────────────────────

  Widget _buildExistingDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Uploaded Documents',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: AppTheme.primaryText)),
        const SizedBox(height: 4),
        Text('Previously uploaded files for this student',
            style: TextStyle(fontSize: 10, color: AppTheme.mutedText)),
        const SizedBox(height: 10),
        _FormCard(
          child: Column(
            children: List.generate(_documents.length, (i) {
              final doc = _documents[i];
              final isDeleting = _deletingDocId == doc.id;
              final isImage = RegExp(r'\.(png|jpe?g|gif|webp)$',
                  caseSensitive: false)
                  .hasMatch(doc.url);
              return Column(children: [
                if (i > 0) _divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: isImage
                          ? Image.network(
                        doc.url,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 40,
                          height: 40,
                          color: _AppColors.sectionBg,
                          child: const Icon(Icons.insert_drive_file,
                              size: 18, color: _AppColors.primary),
                        ),
                      )
                          : Container(
                        width: 40,
                        height: 40,
                        color: _AppColors.sectionBg,
                        child: const Icon(Icons.description_outlined,
                            size: 18, color: _AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(doc.name,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (isDeleting)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _AppColors.error),
                      )
                    else
                      IconButton(
                        onPressed: () => _deleteDocument(doc),
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 20, color: _AppColors.error),
                        tooltip: 'Delete',
                      ),
                  ]),
                ),
              ]);
            }),
          ),
        ),
      ],
    );
  }

  // ── Delete an existing document ────────────────────────────────────────────
  //
  // DELETE /api/student/v1/delete-document/:studentId/:documentId
  // Roles: correspondent, administrator, accountant
  // Returns {ok: true, data: ...}
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _deleteDocument(StudentDocument doc) async {
    if (!_resolvedIsEdit  || _resolvedStudent?.id == null) return;
    final studentId = _resolvedStudent!.id!;
    final schoolId = _resolvedSchoolId;
    if (schoolId == null) return;

    final confirmed = await Get.dialog<bool>(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Document',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _AppColors.textPrimary)),
      content: Text('Delete "${doc.name}"? This cannot be undone.',
          style: const TextStyle(
              fontSize: 14, color: _AppColors.textSecondary, height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('Cancel',
              style: TextStyle(color: _AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () => Get.back(result: true),
          style: ElevatedButton.styleFrom(
              backgroundColor: _AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          child: const Text('Delete',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ));
    if (confirmed != true) return;

    setState(() => _deletingDocId = doc.id);
    try {
      final apiService = Get.find<ApiService>();
      debugPrint('[STUDENT] DELETE '
          '${ApiConstants.deleteStudentDocument}/$studentId/${doc.id}');
      final resp = await apiService.dio.delete(
        '${ApiConstants.deleteStudentDocument}/$studentId/${doc.id}',
        options: dio.Options(headers: {'x-school-id': schoolId}),
      );
      debugPrint('[STUDENT] delete-document ok=${resp.data['ok']}');
      if (resp.data['ok'] == true) {
        setState(() {
          _documents.removeWhere((d) => d.id == doc.id);
          _deletingDocId = null;
        });
        Get.snackbar('Deleted', '"${doc.name}" has been removed',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF2E7D32),
            colorText: Colors.white,
            duration: const Duration(seconds: 2));
      } else {
        throw Exception(resp.data['message']?.toString() ?? 'Delete failed');
      }
    } on dio.DioException catch (e) {
      debugPrint('[STUDENT] delete-document DioException '
          '${e.response?.statusCode}: ${e.response?.data}');
      if (mounted) setState(() => _deletingDocId = null);
      _showError((e.response?.data is Map
          ? e.response!.data['message']?.toString()
          : null) ??
          'Failed to delete document');
    } catch (e) {
      debugPrint('[STUDENT] delete-document error: $e');
      if (mounted) setState(() => _deletingDocId = null);
      _showError('Failed to delete document: $e');
    }
  }
}

// =============================================================================
// SHARED WIDGETS
// =============================================================================

class _FormCard extends StatelessWidget {
  final Widget child;
  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      color: _AppColors.cardBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _AppColors.border),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2)),
      ],
    ),
    child: child,
  );
}

class _SheetSectionLabel extends StatelessWidget {
  final String text;
  const _SheetSectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _AppColors.textSecondary,
          letterSpacing: 0.8));
}

class _StepIndicator extends StatelessWidget {
  final int index;
  final String label;
  final IconData icon;
  final bool isDone;
  final bool isActive;

  const _StepIndicator({
    required this.index,
    required this.label,
    required this.icon,
    required this.isDone,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: (isDone || isActive)
                ? _AppColors.primary
                : _AppColors.stepInactive,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check_rounded,
              size: 16, color: Colors.white)
              : Icon(icon,
              size: 15,
              color:
              isActive ? Colors.white : _AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
              fontSize: 10,
              fontWeight:
              isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive
                  ? _AppColors.primary
                  : _AppColors.textSecondary,
            )),
      ]);
}

// =============================================================================
// CLASS / SECTION PICKER SHEET
// =============================================================================

class _ClassSectionPickerSheet extends StatefulWidget {
  final SchoolController schoolController;
  final String? resolvedSchoolId;
  final bool isEdit;
  final String? initialClassId;
  final String? initialClassName;
  final String? initialSectionId;
  final String? initialSectionName;
  final void Function(String, String, String?, String?) onConfirm;

  const _ClassSectionPickerSheet({
    required this.schoolController,
    required this.resolvedSchoolId,
    required this.isEdit,
    required this.onConfirm,
    this.initialClassId,
    this.initialClassName,
    this.initialSectionId,
    this.initialSectionName,
  });

  @override
  State<_ClassSectionPickerSheet> createState() =>
      _ClassSectionPickerSheetState();
}

class _ClassSectionPickerSheetState
    extends State<_ClassSectionPickerSheet> {
  final _classId = Rx<String?>(null);
  final _className = Rx<String?>(null);
  final _sectionId = Rx<String?>(null);
  final _sectionName = Rx<String?>(null);

  @override
  void initState() {
    super.initState();
    _classId.value = widget.initialClassId;
    _className.value = widget.initialClassName;
    _sectionId.value = widget.initialSectionId;
    _sectionName.value = widget.initialSectionName;
  }

  void _selectClass(SchoolClass cls) {
    _classId.value = cls.id;
    _className.value = cls.name;
    _sectionId.value = null;
    _sectionName.value = null;
    widget.schoolController
        .getAllSections(classId: cls.id, schoolId: widget.resolvedSchoolId);
  }

  void _selectSection(Section sec) {
    _sectionId.value = sec.id;
    _sectionName.value = sec.name;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _AppColors.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 8, 20,
          MediaQuery.of(context).viewInsets.bottom + 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin:
                const EdgeInsets.only(bottom: 20, top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: _AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: _AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.school_rounded,
                    color: _AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isEdit
                          ? 'Change Class & Section'
                          : 'Select Class & Section',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _AppColors.textPrimary),
                    ),
                    const Text('Assign student to class and section',
                        style: TextStyle(
                            fontSize: 12,
                            color: _AppColors.textSecondary)),
                  ]),
            ]),
            const SizedBox(height: 24),

            // Class chips
            const _SheetSectionLabel('CLASS'),
            const SizedBox(height: 10),
            Obx(() {
              final classes = widget.schoolController.classes;
              if (classes.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No classes available',
                      style: TextStyle(
                          fontSize: 13,
                          color: _AppColors.textHint)),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: classes.map((cls) {
                  final sel = _classId.value == cls.id;
                  return GestureDetector(
                    onTap: () => _selectClass(cls),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? _AppColors.primary
                            : _AppColors.sectionBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: sel
                              ? _AppColors.primary
                              : _AppColors.border,
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Text(cls.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: sel
                                ? Colors.white
                                : _AppColors.textPrimary,
                          )),
                    ),
                  );
                }).toList(),
              );
            }),

            // Section chips
            Obx(() {
              final sections = widget.schoolController.sections;
              if (_classId.value == null) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const _SheetSectionLabel('SECTION'),
                  const SizedBox(height: 10),
                  if (sections.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                          'No sections available for this class',
                          style: TextStyle(
                              fontSize: 13,
                              color: _AppColors.textHint)),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: sections.map((sec) {
                        final sel = _sectionId.value == sec.id;
                        return GestureDetector(
                          onTap: () => _selectSection(sec),
                          child: AnimatedContainer(
                            duration:
                            const Duration(milliseconds: 150),
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: sel
                                  ? _AppColors.primary
                                  : _AppColors.sectionBg,
                              borderRadius:
                              BorderRadius.circular(12),
                              border: Border.all(
                                color: sel
                                    ? _AppColors.primary
                                    : _AppColors.border,
                                width: sel ? 1.5 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(sec.name,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: sel
                                      ? Colors.white
                                      : _AppColors.textPrimary,
                                )),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              );
            }),
            const SizedBox(height: 28),

            // CTA button
            Obx(() {
              final sections = widget.schoolController.sections;
              final isListEmpty = sections.isEmpty;
              final classId = _classId.value;
              final sectionId = _sectionId.value;
              final standsValid =
                  classId != null && (isListEmpty || sectionId != null);

              String buttonText =
                  'Select class and section to continue';
              if (classId != null) {
                if (isListEmpty) {
                  buttonText = 'Continue · ${_className.value}';
                } else if (sectionId != null) {
                  buttonText =
                  'Continue · ${_className.value}, Section ${_sectionName.value}';
                } else {
                  buttonText = 'Select a section to continue';
                }
              }

              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: standsValid
                      ? () {
                    widget.onConfirm(
                      _classId.value!,
                      _className.value!,
                      _sectionId.value,
                      _sectionName.value,
                    );
                    Get.back();
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _AppColors.primary,
                    disabledBackgroundColor: _AppColors.stepInactive,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(buttonText,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// NAV BUTTON
// =============================================================================

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool filled;
  final bool loading;

  const _NavButton({
    required this.label,
    required this.icon,
    this.onPressed,
    this.outlined = false,
    this.filled = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
        else
          Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );

    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _AppColors.primary,
          side: const BorderSide(color: _AppColors.border),
          padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _AppColors.stepInactive,
        elevation: 0,
        padding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
      child: child,
    );
  }
}
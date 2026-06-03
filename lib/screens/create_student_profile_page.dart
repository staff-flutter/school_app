import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';
import 'package:school_app/constants/api_constants.dart';

import '../controllers/auth_controller.dart';
import '../controllers/school_controller.dart';
import '../services/api_service.dart';

// =============================================================================
// DESIGN TOKENS — matches sidebar palette
// =============================================================================

class _AppColors {
  // Primary blue — matches the sidebar active item blue
  static const primary       = Color(0xFF1565C0);
  static const primaryLight  = Color(0xFFE3EEF9);
  static const primaryMid    = Color(0xFF1976D2);
  static const primaryDark   = Color(0xFF0D47A1);

  // Surface / backgrounds
  static const surface       = Color(0xFFF5F7FA);
  static const cardBg        = Color(0xFFFFFFFF);
  static const sectionBg     = Color(0xFFF0F4FA);

  // Text
  static const textPrimary   = Color(0xFF1A2340);
  static const textSecondary = Color(0xFF5B6880);
  static const textHint      = Color(0xFF9AA5B4);

  // Border
  static const border        = Color(0xFFDDE3EC);
  static const borderFocus   = Color(0xFF1976D2);

  // Semantic
  static const success       = Color(0xFF2E7D32);
  static const successBg     = Color(0xFFE8F5E9);
  static const error         = Color(0xFFC62828);
  static const errorBg       = Color(0xFFFFEBEE);

  // Step indicator
  static const stepDone      = Color(0xFF1976D2);
  static const stepInactive  = Color(0xFFCDD4E0);
}

// =============================================================================
// MODELS (unchanged from original)
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
    'gender': gender, 'dob': dob, 'educationNumber': educationNumber,
    'motherName': motherName, 'fatherName': fatherName,
    'guardianName': guardianName, 'aadhaarNumber': aadhaarNumber,
    'aadhaarName': aadhaarName, 'address': address, 'pincode': pincode,
    'mobileNumber': mobileNumber, 'alternateMobile': alternateMobile,
    'email': email, 'motherTongue': motherTongue,
    'socialCategory': socialCategory, 'minorityGroup': minorityGroup,
    'bpl': bpl, 'aay': aay, 'ews': ews, 'cwsn': cwsn,
    'impairments': impairments, 'indian': indian, 'outOfSchool': outOfSchool,
    'mainstreamedDate': mainstreamedDate, 'disabilityCert': disabilityCert,
    'disabilityPercent': disabilityPercent, 'bloodGroup': bloodGroup,
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
    'screenedForSLD': screenedForSLD, 'sldType': sldType,
    'screenedForASD': screenedForASD, 'screenedForADHD': screenedForADHD,
    'isGiftedOrTalented': isGiftedOrTalented,
    'participatedInCompetitions': participatedInCompetitions,
    'participatedInActivities': participatedInActivities,
    'canHandleDigitalDevices': canHandleDigitalDevices,
    'heightInCm': heightInCm, 'weightInKg': weightInKg,
    'distanceToSchool': distanceToSchool,
    'parentEducationLevel': parentEducationLevel,
    'admissionNumber': admissionNumber, 'admissionDate': admissionDate,
    'rollNumber': rollNumber, 'mediumOfInstruction': mediumOfInstruction,
    'languagesStudied': languagesStudied, 'academicStream': academicStream,
    'subjectsStudied': subjectsStudied,
    'statusInPreviousYear': statusInPreviousYear,
    'gradeStudiedLastYear': gradeStudiedLastYear,
    'enrolledUnder': enrolledUnder, 'previousResult': previousResult,
    'marksObtainedPercentage': marksObtainedPercentage,
    'daysAttendedLastYear': daysAttendedLastYear,
  };
}

// =============================================================================
// CREATE STUDENT PROFILE PAGE
// =============================================================================

class CreateStudentProfilePage extends StatefulWidget {
  const CreateStudentProfilePage({super.key});

  @override
  State<CreateStudentProfilePage> createState() =>
      _CreateStudentProfilePageState();
}

class _CreateStudentProfilePageState extends State<CreateStudentProfilePage>
    with TickerProviderStateMixin {
  final _auth   = Get.find<AuthController>();
  final _school = Get.find<SchoolController>();

  String? get _resolvedSchoolId {
    final role = _auth.user.value?.role?.toLowerCase() ?? '';
    if (role == 'correspondent') return _school.selectedSchool.value?.id;
    return _auth.user.value?.schoolId;
  }

  bool get _isCorrespondent =>
      (_auth.user.value?.role?.toLowerCase() ?? '') == 'correspondent';

  // ── Step 0 ─────────────────────────────────────────────────────────────────
  String? _pickedClass;
  String? _pickedSection;
  bool _selectionDone = false;

  // ── Stepper ────────────────────────────────────────────────────────────────
  final _pageCtrl = PageController();
  int _currentPage = 0;
  bool _isSubmitting = false;
  File? _pickedImage;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // ── Form keys ──────────────────────────────────────────────────────────────
  final _basicKey      = GlobalKey<FormState>();
  final _mandatoryKey  = GlobalKey<FormState>();
  final _additionalKey = GlobalKey<FormState>();
  final _enrollmentKey = GlobalKey<FormState>();

  // ── Controllers: Basic ─────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _srIdCtrl = TextEditingController();
  bool _isActive  = true;

  // ── Controllers: Mandatory ─────────────────────────────────────────────────
  final _dobCtrl              = TextEditingController();
  final _eduNoCtrl            = TextEditingController();
  final _motherCtrl           = TextEditingController();
  final _fatherCtrl           = TextEditingController();
  final _guardianCtrl         = TextEditingController();
  final _aadhaarNoCtrl        = TextEditingController();
  final _aadhaarNameCtrl      = TextEditingController();
  final _addressCtrl          = TextEditingController();
  final _pincodeCtrl          = TextEditingController();
  final _mobileCtrl           = TextEditingController();
  final _altMobileCtrl        = TextEditingController();
  final _emailCtrl            = TextEditingController();
  final _motherTongueCtrl     = TextEditingController();
  final _minorityCtrl         = TextEditingController();
  final _impairmentsCtrl      = TextEditingController();
  final _mainstreamedDateCtrl = TextEditingController();
  final _disabilityPctCtrl    = TextEditingController();
  String? _selGender, _selBlood, _selSocialCat;
  String? _selBpl, _selAay, _selEws, _selCwsn, _selIndian, _selOos, _selDisCert;

  // ── Controllers: Additional ────────────────────────────────────────────────
  final _heightCtrl     = TextEditingController();
  final _weightCtrl     = TextEditingController();
  final _distanceCtrl   = TextEditingController();
  final _sldTypeCtrl    = TextEditingController();
  final _activitiesCtrl = TextEditingController();
  final _parentEduCtrl  = TextEditingController();
  final _facilitiesCtrl = TextEditingController();
  final _facCwsnCtrl    = TextEditingController();
  String? _selSLD, _selASD, _selADHD, _selGifted, _selCompetitions, _selDigital;

  // ── Controllers: Enrollment ────────────────────────────────────────────────
  final _admNoCtrl     = TextEditingController();
  final _admDateCtrl   = TextEditingController();
  final _rollNoCtrl    = TextEditingController();
  final _languagesCtrl = TextEditingController();
  final _subjectsCtrl  = TextEditingController();
  final _enrolledCtrl  = TextEditingController();
  final _gradeLastCtrl = TextEditingController();
  final _marksPctCtrl  = TextEditingController();
  final _daysCtrl      = TextEditingController();
  String? _selMedium, _selStream, _selPrevStatus, _selPrevResult;

  // ── Options ────────────────────────────────────────────────────────────────
  static const _yesNo   = ['Yes', 'No'];
  static const _genders = ['Male', 'Female', 'Other'];
  static const _bloods  = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  static const _socCats = ['General', 'OBC', 'SC', 'ST'];
  static const _classes = [
    'LKG','UKG','Class 1','Class 2','Class 3','Class 4','Class 5','Class 6',
    'Class 7','Class 8','Class 9','Class 10','Class 11','Class 12'
  ];
  static const _sections = ['A', 'B', 'C', 'D'];
  static const _mediums  = ['Telugu', 'Hindi', 'English', 'Urdu', 'Tamil'];
  static const _streams  = ['Science', 'Commerce', 'Arts', 'Vocational'];
  static const _prevSts  = ['Promoted', 'Detained', 'Transferred', 'Dropped out'];
  static const _prevRes  = ['Pass', 'Fail', 'Absent'];

  static const _stepLabels = ['Basic', 'Mandatory', 'Additional', 'Enrollment'];
  static const _stepIcons  = [
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
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _showClassSectionPicker());
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pageCtrl.dispose();
    for (final c in [
      _nameCtrl, _srIdCtrl, _dobCtrl, _eduNoCtrl, _motherCtrl, _fatherCtrl,
      _guardianCtrl, _aadhaarNoCtrl, _aadhaarNameCtrl, _addressCtrl,
      _pincodeCtrl, _mobileCtrl, _altMobileCtrl, _emailCtrl, _motherTongueCtrl,
      _minorityCtrl, _impairmentsCtrl, _mainstreamedDateCtrl, _disabilityPctCtrl,
      _heightCtrl, _weightCtrl, _distanceCtrl, _sldTypeCtrl, _activitiesCtrl,
      _parentEduCtrl, _facilitiesCtrl, _facCwsnCtrl, _admNoCtrl, _admDateCtrl,
      _rollNoCtrl, _languagesCtrl, _subjectsCtrl, _enrolledCtrl, _gradeLastCtrl,
      _marksPctCtrl, _daysCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  // ── Class / Section bottom sheet ───────────────────────────────────────────

  void _showClassSectionPicker() {
    if (_isCorrespondent && (_school.selectedSchool.value == null)) {
      Get.snackbar('No School Selected',
          'Please select a school from the sidebar first.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: _AppColors.error,
          colorText: Colors.white);
      Get.back();
      return;
    }

    String? tempClass   = _pickedClass;
    String? tempSection = _pickedSection;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (ctx, setSheet) {
          return Container(
            decoration: const BoxDecoration(
              color: _AppColors.cardBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20, 8, 20,
              MediaQuery.of(ctx).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20, top: 8),
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: _AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: _AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Select Class & Section',
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: _AppColors.textPrimary,
                        )),
                    const Text('Assign student to class and section',
                        style: TextStyle(
                            fontSize: 12, color: _AppColors.textSecondary)),
                  ]),
                ]),
                const SizedBox(height: 24),

                // Class label
                const _SheetSectionLabel('Class'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _classes.map((cls) {
                    final sel = tempClass == cls;
                    return GestureDetector(
                      onTap: () => setSheet(() => tempClass = cls),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? _AppColors.primary : _AppColors.sectionBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: sel ? _AppColors.primary : _AppColors.border,
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Text(cls,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : _AppColors.textPrimary,
                            )),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Section label
                const _SheetSectionLabel('Section'),
                const SizedBox(height: 10),
                Row(
                  children: _sections.map((sec) {
                    final sel = tempSection == sec;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => setSheet(() => tempSection = sec),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: sel ? _AppColors.primary : _AppColors.sectionBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel ? _AppColors.primary : _AppColors.border,
                              width: sel ? 1.5 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(sec,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: sel ? Colors.white : _AppColors.textPrimary,
                              )),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                // CTA
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (tempClass != null && tempSection != null)
                        ? () {
                      setState(() {
                        _pickedClass   = tempClass;
                        _pickedSection = tempSection;
                        _selectionDone = true;
                      });
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
                    child: Text(
                      (tempClass != null && tempSection != null)
                          ? 'Continue · $tempClass, Section $tempSection'
                          : 'Select class and section to continue',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
      backgroundColor: Colors.transparent,
    );
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  bool _validateCurrentStep() {
    switch (_currentPage) {
      case 0: return _basicKey.currentState?.validate() ?? false;
      case 1: return _mandatoryKey.currentState?.validate() ?? false;
      case 2: return _additionalKey.currentState?.validate() ?? false;
      case 3: return _enrollmentKey.currentState?.validate() ?? false;
      default: return true;
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
    // 1. Resolve the matching Class ObjectId from SchoolController cache
    String? resolvedClassId;
    if (_pickedClass != null) {
      try {
        // 🟢 FIXED: Changed .className to .name
        final matchingClass = _school.classes.firstWhere(
                (c) => c.name.toString().toLowerCase().trim() == _pickedClass!.toLowerCase().replaceAll('class', '').trim()
                || c.name.toString().toLowerCase().trim() == _pickedClass!.toLowerCase().trim()
        );
        resolvedClassId = matchingClass.id;
      } catch (_) {
        resolvedClassId = null;
      }
    }

    // 2. Resolve the matching Section ObjectId from SchoolController cache
    String? resolvedSectionId;
    if (_pickedSection != null) {
      try {
        // 🟢 FIXED: Changed .sectionName to .name
        final matchingSection = _school.sections.firstWhere(
                (s) => s.name.toString().toLowerCase().trim() == _pickedSection!.toLowerCase().trim()
        );
        resolvedSectionId = matchingSection.id;
      } catch (_) {
        resolvedSectionId = null;
      }
    }

    final mandatory = MandatoryDetails()
      ..gender           = _selGender
      ..dob              = _t(_dobCtrl)
      ..educationNumber  = _t(_eduNoCtrl)
      ..motherName       = _t(_motherCtrl)
      ..fatherName       = _t(_fatherCtrl)
      ..guardianName     = _t(_guardianCtrl)
      ..aadhaarNumber    = _t(_aadhaarNoCtrl)
      ..aadhaarName      = _t(_aadhaarNameCtrl)
      ..address          = _t(_addressCtrl)
      ..pincode          = _t(_pincodeCtrl)
      ..mobileNumber     = _t(_mobileCtrl)
      ..alternateMobile  = _t(_altMobileCtrl)
      ..email            = _t(_emailCtrl)
      ..motherTongue     = _t(_motherTongueCtrl)
      ..socialCategory   = _selSocialCat
      ..minorityGroup    = _t(_minorityCtrl)
      ..bpl              = _selBpl
      ..aay              = _selAay
      ..ews              = _selEws
      ..cwsn             = _selCwsn
      ..impairments      = _t(_impairmentsCtrl)
      ..indian           = _selIndian
      ..outOfSchool      = _selOos
      ..mainstreamedDate = _t(_mainstreamedDateCtrl)
      ..disabilityCert   = _selDisCert
      ..disabilityPercent = _t(_disabilityPctCtrl)
      ..bloodGroup       = _selBlood;

    final nonMandatory = NonMandatoryDetails()
      ..facilitiesProvided         = _t(_facilitiesCtrl)
      ..facilitiesForCWSN          = _t(_facCwsnCtrl)
      ..screenedForSLD             = _selSLD
      ..sldType                    = _t(_sldTypeCtrl)
      ..screenedForASD             = _selASD
      ..screenedForADHD            = _selADHD
      ..isGiftedOrTalented         = _selGifted
      ..participatedInCompetitions = _selCompetitions
      ..participatedInActivities   = _t(_activitiesCtrl)
      ..canHandleDigitalDevices    = _selDigital
      ..heightInCm                 = _t(_heightCtrl)
      ..weightInKg                 = _t(_weightCtrl)
      ..distanceToSchool           = _t(_distanceCtrl)
      ..parentEducationLevel       = _t(_parentEduCtrl)
      ..admissionNumber            = _t(_admNoCtrl)
      ..admissionDate              = _t(_admDateCtrl)
      ..rollNumber                 = _t(_rollNoCtrl)
      ..mediumOfInstruction        = _selMedium
      ..languagesStudied           = _t(_languagesCtrl)
      ..academicStream             = _selStream
      ..subjectsStudied            = _t(_subjectsCtrl)
      ..statusInPreviousYear       = _selPrevStatus
      ..gradeStudiedLastYear       = _t(_gradeLastCtrl)
      ..enrolledUnder              = _t(_enrolledCtrl)
      ..previousResult             = _selPrevResult
      ..marksObtainedPercentage    = _t(_marksPctCtrl)
      ..daysAttendedLastYear       = _t(_daysCtrl);

    return StudentPayload(
      schoolId:         _resolvedSchoolId!,
      srId:             _t(_srIdCtrl),
      studentName:      _nameCtrl.text.trim(),
      currentClassId:   resolvedClassId,
      currentSectionId: resolvedSectionId,
      isActive:         _isActive,
      mandatory:        mandatory,
      nonMandatory:     nonMandatory,
    );
  }

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
      final payload    = _buildPayload();

      // Always strip nulls from nested objects
      final mandatoryMap    = _stripNulls(payload.mandatory.toJson());
      final nonMandatoryMap = _stripNulls(payload.nonMandatory.toJson());
      final mandatoryJson    = jsonEncode(_stripNulls(payload.mandatory.toJson()).isEmpty
          ? <String, dynamic>{}
          : _stripNulls(payload.mandatory.toJson()));
      final nonMandatoryJson = jsonEncode(_stripNulls(payload.nonMandatory.toJson()).isEmpty
          ? <String, dynamic>{}
          : _stripNulls(payload.nonMandatory.toJson()));


      if (_pickedImage != null) {
        final formData = FormData.fromMap({
          'schoolId': schoolId,
          if (payload.srId != null) 'srId': payload.srId,
          'studentName': payload.studentName,
          if (payload.currentClassId != null) 'currentClassId': payload.currentClassId,
          if (payload.currentSectionId != null) 'currentSectionId': payload.currentSectionId,
          'isActive': payload.isActive.toString(),
          'mandatory':    mandatoryJson,   // JSON string
          'nonMandatory': nonMandatoryJson, // JSON string
          'studentImage': await MultipartFile.fromFile(
            _pickedImage!.path,
            filename: 'student_image.${_pickedImage!.path.split('.').last}',
          ),
        });
        final res = await apiService.dio.post(
          ApiConstants.createStudent,
          data: formData,
          options: Options(headers: {'x-school-id': schoolId}),
        );
        if (!mounted) return;
        _handleResponse(res.data);

      } else {
        // Server expects mandatory/nonMandatory as JSON STRINGS even in JSON body
        // because it calls JSON.parse() on them server-side
        final res = await apiService.dio.post(

          ApiConstants.createStudent,
          data: {
            'schoolId':     schoolId,
            if (payload.srId != null) 'srId': payload.srId,
            'studentName':  payload.studentName,
            if (payload.currentClassId != null) 'currentClassId': payload.currentClassId,
            if (payload.currentSectionId != null) 'currentSectionId': payload.currentSectionId,
            'isActive':     payload.isActive,
            'mandatory':    mandatoryJson,    // JSON string, NOT a Map
            'nonMandatory': nonMandatoryJson, // JSON string, NOT a Map
          },
          options: Options(headers: {
            'x-school-id':  schoolId,
            'Content-Type': 'application/json',
          }),
        );
        print('=== RAW RESPONSE ===');
        print('status: ${res.statusCode}');
        print('data: ${res.data}');
        print('data type: ${res.data.runtimeType}');

        if (!mounted) return;
        _handleResponse(res.data);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      print('=== DIO ERROR ===');
      print('Status: ${e.response?.statusCode}');
      print('Data: ${e.response?.data}');   // <-- full server message
      print('Message: ${e.message}');

      _showError(e.response?.data?['message']?.toString()
          ?? e.message ?? 'Request failed');
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
  void _handleResponse(dynamic data) {
    if (data is Map && data['ok'] == true) {
      Get.snackbar(
        '✅ Student Created',
        'Profile for ${_nameCtrl.text.trim()} has been created successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF2E7D32),
        colorText: Colors.white,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        animationDuration: const Duration(milliseconds: 400),
        isDismissible: false,
        forwardAnimationCurve: Curves.easeOutBack,
      );
      // Wait for snackbar to be visible before navigating back
      Future.delayed(const Duration(seconds: 3), () {
        Get.back(result: true);
      });
    } else {
      _showError((data is Map ? data['message']?.toString() : null)
          ?? 'Failed to create student.');
    }
  }  void _showError(String message) {
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

  // ── App bar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,

      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create Student Profile',
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: Colors.white,
              )),
          if (_selectionDone)
            Text(
              '$_pickedClass  ·  Section $_pickedSection'
                  '${_isCorrespondent ? '  ·  ${_school.selectedSchool.value?.name ?? ''}' : ''}',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }

  // ── Context banner (class/section pill) ────────────────────────────────────

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
            Text('$_pickedClass  ·  Sec $_pickedSection',
                style: const TextStyle(
                    fontSize: 12, color: Colors.white,
                    fontWeight: FontWeight.w600)),
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
                  style: TextStyle(fontSize: 12, color: Colors.white,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Stepper bar ────────────────────────────────────────────────────────────

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
            final done   = i < _currentPage;
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
                        color: done ? _AppColors.primary : _AppColors.border,
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

  // ── Bottom bar ─────────────────────────────────────────────────────────────

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
                label: isLast ? 'Create Student' : 'Next Step',
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

  // ── Selection prompt (before class/section chosen) ─────────────────────────

  Widget _buildSelectionPrompt() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 80, height: 80,
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
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: _AppColors.textPrimary,
                )),
            const SizedBox(height: 8),
            const Text(
              'Choose where this student will be enrolled before filling out the profile.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: _AppColors.textSecondary, height: 1.5),
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

  // ==========================================================================
  // PAGES
  // ==========================================================================

  Widget _buildBasicPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Form(
        key: _basicKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Photo upload card
          _FormCard(
            child: Column(children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(alignment: Alignment.bottomRight, children: [
                  Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _AppColors.primaryLight,
                      border: Border.all(
                          color: _AppColors.primary.withOpacity(0.3), width: 2),
                      image: _pickedImage != null
                          ? DecorationImage(
                          image: FileImage(_pickedImage!),
                          fit: BoxFit.cover)
                          : null,
                    ),
                    child: _pickedImage == null
                        ? const Icon(Icons.person_rounded,
                        size: 44, color: _AppColors.primary)
                        : null,
                  ),
                  Container(
                    width: 30, height: 30,
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
                  style: TextStyle(fontSize: 12, color: _AppColors.textSecondary)),
            ]),
          ),

          const SizedBox(height: 16),
          _secHeader(Icons.person_outline_rounded, 'Basic Information'),
          const SizedBox(height: 12),

          _FormCard(
            child: Column(children: [
              _field(_nameCtrl, 'Student Name',
                  required: true,
                  icon: Icons.badge_outlined,
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Student name is required' : null),
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
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Active Student',
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: _AppColors.textPrimary,
                          )),
                      const SizedBox(height: 2),
                      const Text('Shows on class rosters',
                          style: TextStyle(
                              fontSize: 12, color: _AppColors.textSecondary)),
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _secHeader(Icons.family_restroom_rounded, 'Personal & Family'),
          const SizedBox(height: 12),
          _FormCard(child: Column(children: [
            _dropRow('Gender', _selGender, _genders,
                    (v) => setState(() => _selGender = v), Icons.wc_rounded),
            _divider(),
            _dateFieldRow(_dobCtrl, 'Date of Birth'),
            _divider(),
            _field(_motherCtrl, "Mother's Name", icon: Icons.person_2_outlined),
            _divider(),
            _field(_fatherCtrl, "Father's Name", icon: Icons.person_outlined),
            _divider(),
            _field(_guardianCtrl, "Guardian's Name", icon: Icons.supervisor_account_outlined),
            _divider(),
            _dropRow('Blood Group', _selBlood, _bloods,
                    (v) => setState(() => _selBlood = v), Icons.bloodtype_outlined),
          ])),

          const SizedBox(height: 20),
          _secHeader(Icons.phone_outlined, 'Contact Details'),
          const SizedBox(height: 12),
          _FormCard(child: Column(children: [
            _field(_mobileCtrl, 'Mobile Number',
                keyboard: TextInputType.phone, icon: Icons.phone_rounded),
            _divider(),
            _field(_altMobileCtrl, 'Alternate Mobile',
                keyboard: TextInputType.phone, icon: Icons.phone_callback_outlined),
            _divider(),
            _field(_emailCtrl, 'Email',
                keyboard: TextInputType.emailAddress, icon: Icons.mail_outline_rounded),
            _divider(),
            _field(_motherTongueCtrl, 'Mother Tongue', icon: Icons.language_rounded),
          ])),

          const SizedBox(height: 20),
          _secHeader(Icons.location_on_outlined, 'Address & ID'),
          const SizedBox(height: 12),
          _FormCard(child: Column(children: [
            _field(_addressCtrl, 'Address', maxLines: 3, icon: Icons.home_outlined),
            _divider(),
            _field(_pincodeCtrl, 'Pincode',
                keyboard: TextInputType.number,
                icon: Icons.pin_drop_outlined,
                formatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ]),
            _divider(),
            _field(_eduNoCtrl, 'Education Number', icon: Icons.numbers_rounded),
            _divider(),
            _field(_aadhaarNoCtrl, 'Aadhaar Number',
                keyboard: TextInputType.number,
                icon: Icons.credit_card_outlined,
                formatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ]),
            _divider(),
            _field(_aadhaarNameCtrl, 'Name on Aadhaar', icon: Icons.person_pin_outlined),
          ])),

          const SizedBox(height: 20),
          _secHeader(Icons.checklist_rounded, 'Social & Welfare'),
          const SizedBox(height: 12),
          _FormCard(child: Column(children: [
            _dropRow('Social Category', _selSocialCat, _socCats,
                    (v) => setState(() => _selSocialCat = v), Icons.group_outlined),
            _divider(),
            _field(_minorityCtrl, 'Minority Group', icon: Icons.people_outline),
            _divider(),
            Row(children: [
              Expanded(child: _dropCompact('BPL', _selBpl, _yesNo,
                      (v) => setState(() => _selBpl = v))),
              const SizedBox(width: 12),
              Expanded(child: _dropCompact('AAY', _selAay, _yesNo,
                      (v) => setState(() => _selAay = v))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _dropCompact('EWS', _selEws, _yesNo,
                      (v) => setState(() => _selEws = v))),
              const SizedBox(width: 12),
              Expanded(child: _dropCompact('CWSN', _selCwsn, _yesNo,
                      (v) => setState(() => _selCwsn = v))),
            ]),
            _divider(),
            _field(_impairmentsCtrl, 'Impairments', icon: Icons.accessibility_new_outlined),
            _divider(),
            Row(children: [
              Expanded(child: _dropCompact('Indian National', _selIndian,
                  _yesNo, (v) => setState(() => _selIndian = v))),
              const SizedBox(width: 12),
              Expanded(child: _dropCompact('Out of School', _selOos,
                  _yesNo, (v) => setState(() => _selOos = v))),
            ]),
            _divider(),
            _dateFieldRow(_mainstreamedDateCtrl, 'Mainstreamed Date'),
            _divider(),
            Row(children: [
              Expanded(child: _dropCompact('Disability Cert', _selDisCert,
                  _yesNo, (v) => setState(() => _selDisCert = v))),
              const SizedBox(width: 12),
              Expanded(child: _field(_disabilityPctCtrl, 'Disability %',
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _secHeader(Icons.monitor_heart_outlined, 'Health & Physical'),
          const SizedBox(height: 12),
          _FormCard(child: Column(children: [
            Row(children: [
              Expanded(child: _field(_heightCtrl, 'Height (cm)',
                  keyboard: TextInputType.number, icon: Icons.height_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _field(_weightCtrl, 'Weight (kg)',
                  keyboard: TextInputType.number, icon: Icons.monitor_weight_outlined)),
            ]),
            _divider(),
            _field(_distanceCtrl, 'Distance to School (km)',
                icon: Icons.directions_walk_rounded),
            _divider(),
            _dropRow('Screened for SLD', _selSLD, _yesNo,
                    (v) => setState(() => _selSLD = v), Icons.psychology_outlined),
            _divider(),
            _field(_sldTypeCtrl, 'SLD Type', icon: Icons.notes_rounded),
            _divider(),
            Row(children: [
              Expanded(child: _dropCompact('ASD', _selASD, _yesNo,
                      (v) => setState(() => _selASD = v))),
              const SizedBox(width: 12),
              Expanded(child: _dropCompact('ADHD', _selADHD, _yesNo,
                      (v) => setState(() => _selADHD = v))),
            ]),
            _divider(),
            _field(_facilitiesCtrl, 'Facilities Provided', icon: Icons.house_outlined),
            _divider(),
            _field(_facCwsnCtrl, 'Facilities for CWSN', icon: Icons.accessible_outlined),
          ])),

          const SizedBox(height: 20),
          _secHeader(Icons.star_outline_rounded, 'Talents & Digital'),
          const SizedBox(height: 12),
          _FormCard(child: Column(children: [
            _dropRow('Gifted / Talented', _selGifted, _yesNo,
                    (v) => setState(() => _selGifted = v), Icons.emoji_events_outlined),
            _divider(),
            _dropRow('Participated in Competitions', _selCompetitions, _yesNo,
                    (v) => setState(() => _selCompetitions = v), Icons.military_tech_outlined),
            _divider(),
            _field(_activitiesCtrl, 'Activities (sports, arts…)',
                icon: Icons.sports_soccer_outlined),
            _divider(),
            _dropRow('Handles Digital Devices', _selDigital, _yesNo,
                    (v) => setState(() => _selDigital = v), Icons.tablet_android_outlined),
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _secHeader(Icons.school_outlined, 'Enrollment Details'),
          const SizedBox(height: 12),
          _FormCard(child: Column(children: [
            Row(children: [
              Expanded(child: _field(_admNoCtrl, 'Admission No.',
                  icon: Icons.tag_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _dateFieldRow(_admDateCtrl, 'Admission Date')),
            ]),
            _divider(),
            _field(_rollNoCtrl, 'Roll Number', icon: Icons.format_list_numbered_rounded),
            _divider(),
            _dropRow('Medium of Instruction', _selMedium, _mediums,
                    (v) => setState(() => _selMedium = v), Icons.translate_rounded),
            _divider(),
            _field(_languagesCtrl, 'Languages Studied',
                hint: 'e.g. English, Telugu', icon: Icons.language_rounded),
            _divider(),
            _dropRow('Academic Stream', _selStream, _streams,
                    (v) => setState(() => _selStream = v), Icons.timeline_rounded),
            _divider(),
            _field(_subjectsCtrl, 'Subjects Studied',
                hint: 'Comma-separated', icon: Icons.book_outlined),
            _divider(),
            _field(_enrolledCtrl, 'Enrolled Under', icon: Icons.assignment_outlined),
          ])),

          const SizedBox(height: 20),
          _secHeader(Icons.history_rounded, 'Previous Academic Year'),
          const SizedBox(height: 12),
          _FormCard(child: Column(children: [
            _dropRow('Status in Previous Year', _selPrevStatus, _prevSts,
                    (v) => setState(() => _selPrevStatus = v), Icons.grade_outlined),
            _divider(),
            _field(_gradeLastCtrl, 'Grade Last Year',
                hint: 'e.g. Class 5', icon: Icons.class_outlined),
            _divider(),
            _dropRow('Previous Result', _selPrevResult, _prevRes,
                    (v) => setState(() => _selPrevResult = v), Icons.fact_check_outlined),
            _divider(),
            Row(children: [
              Expanded(child: _field(_marksPctCtrl, 'Marks %',
                  keyboard: TextInputType.number, icon: Icons.percent_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _field(_daysCtrl, 'Days Attended',
                  keyboard: TextInputType.number, icon: Icons.calendar_today_rounded)),
            ]),
          ])),
        ]),
      ),
    );
  }

  // ==========================================================================
  // WIDGET HELPERS
  // ==========================================================================

  Widget _secHeader(IconData icon, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 0),
    child: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: _AppColors.primaryLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: _AppColors.primary),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: _AppColors.textPrimary,
          )),
    ]),
  );

  Widget _divider() => const Divider(
      height: 1, thickness: 0.5, color: _AppColors.border);

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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboard,
        inputFormatters: formatters,
        validator: validator,
        style: const TextStyle(
            fontSize: 14, color: _AppColors.textPrimary,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          prefixIcon: icon != null
              ? Icon(icon, size: 18, color: _AppColors.textHint)
              : null,
          labelStyle: const TextStyle(
              fontSize: 13, color: _AppColors.textSecondary),
          hintStyle: const TextStyle(
              fontSize: 13, color: _AppColors.textHint),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 0, vertical: 12),
          isDense: true,
        ),
      ),
    );
  }

  Widget _dropRow(String label, String? value, List<String> items,
      void Function(String?) onChanged, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: _AppColors.textHint, size: 20),
        style: const TextStyle(
            fontSize: 14, color: _AppColors.textPrimary,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18, color: _AppColors.textHint),
          labelStyle: const TextStyle(
              fontSize: 13, color: _AppColors.textSecondary),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 0, vertical: 12),
          isDense: true,
        ),
        items: items
            .map((e) => DropdownMenuItem(
          value: e,
          child: Text(e,
              style: const TextStyle(fontSize: 14)),
        ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _dropCompact(String label, String? value, List<String> items,
      void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: _AppColors.textHint, size: 18),
      style: const TextStyle(
          fontSize: 13, color: _AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
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
          borderSide: const BorderSide(color: _AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 10),
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

  Widget _dateFieldRow(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: TextFormField(
        controller: ctrl,
        readOnly: true,
        onTap: () => _pickDate(ctrl),
        style: const TextStyle(
            fontSize: 14, color: _AppColors.textPrimary,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          hintText: 'DD / MM / YYYY',
          labelStyle: const TextStyle(
              fontSize: 13, color: _AppColors.textSecondary),
          hintStyle: const TextStyle(
              fontSize: 13, color: _AppColors.textHint),
          prefixIcon: const Icon(Icons.calendar_month_rounded,
              size: 18, color: _AppColors.textHint),
          suffixIcon: const Icon(Icons.arrow_drop_down_rounded,
              size: 18, color: _AppColors.textHint),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 0, vertical: 12),
          isDense: true,
        ),
      ),
    );
  }
}

// =============================================================================
// REUSABLE COMPONENTS
// =============================================================================

/// Card container for form sections
class _FormCard extends StatelessWidget {
  final Widget child;
  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Sheet section label helper
class _SheetSectionLabel extends StatelessWidget {
  final String text;
  const _SheetSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}

/// Step indicator dot with label
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
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: (isDone || isActive)
              ? _AppColors.primary
              : _AppColors.stepInactive,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: isDone
            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
            : Icon(icon,
            size: 15,
            color: isActive ? Colors.white : _AppColors.textSecondary),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          color: isActive ? _AppColors.primary : _AppColors.textSecondary,
        ),
      ),
    ]);
  }
}

/// Navigation button (Back / Next / Submit)
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
    final child = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (loading)
        const SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.white),
        )
      else
        Icon(icon, size: 16),
      const SizedBox(width: 6),
      Text(label,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600)),
    ]);

    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _AppColors.primary,
          side: const BorderSide(color: _AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
      child: child,
    );
  }
}
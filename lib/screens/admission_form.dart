import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:school_app/constants/api_constants.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/bill_admission_controller.dart';
import 'package:school_app/models/school_models.dart';
import 'package:school_app/models/student_model.dart';

import '../controllers/school_controller.dart';
import 'admission_form_detail_view.dart';

class AdmissionBillBookView extends StatefulWidget {
  const AdmissionBillBookView({super.key});

  @override
  State<AdmissionBillBookView> createState() => _AdmissionBillBookViewState();
}

class _AdmissionBillBookViewState extends State<AdmissionBillBookView> {
  final BillAdmissionController _controller = Get.find<BillAdmissionController>();
  final AuthController _authController = Get.find<AuthController>();
  final SchoolController _schoolController = Get.find<SchoolController>();

  // Displayed in the header badge - replaced with the server-assigned
  // formNumber once a record has actually been saved.
  String _formNumberLabel = '—';
  String? _admissionFormId;
// Syntax: ReturnType get getterName => expression;
  String? get schoolId {
    // 1. Get the current user's role
    final String role = _authController.user.value?.role?.toLowerCase() ?? '';

    // 2. Conditionally return the correct school ID
    if (role == 'correspondent') {
      return _schoolController.selectedSchool.value?.id;
    } else {
      return _authController.user.value?.schoolId;
    }
  }

  // --- Student picker (class → section → student) used to autofill the form ---
  final selectedClass = Rxn<SchoolClass>();
  final selectedSection = Rxn<Section>();
  final selectedStudent = Rxn<Student>();
  final classHasSections = true.obs;
  bool _isFetchingStudentDetails = false;

  String? _getToken() => _authController.storage.read('token');

  // --- Form Field Controllers (mapped to the IAdmissionForm schema) ---
  // 1. Student Details
  final _studentNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _ageController = TextEditingController();
  String? _gender ;
  final _motherTongueController = TextEditingController();
  final _religionController = TextEditingController();
  final _communityController = TextEditingController();
  final _emisNumberController = TextEditingController(); // optional

  // 2. Academic & Contact
  final _academicYearController = TextEditingController(text: _defaultAcademicYear());
  final _admissionSoughtForController = TextEditingController();
  final _examinationPassedController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _currentAddressController = TextEditingController();
  final _permanentAddressController = TextEditingController();
  bool _permanentSameAsCurrent = false;

  // 3. Parent Information
  final _fatherNameController = TextEditingController();
  final _fatherEducationController = TextEditingController();
  final _fatherOccupationController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _motherEducationController = TextEditingController();
  final _motherOccupationController = TextEditingController();

  // System Profile Linking
  final _studentIdController = TextEditingController();

  static String _defaultAcademicYear() {
    final now = DateTime.now();
    final startYear = now.month >= 6 ? now.year : now.year - 1;
    return '$startYear-${startYear + 1}';
  }
  @override
  void initState() {
    super.initState();
    _ensureSchoolLoaded();
    ever(_schoolController.selectedSchool, (_) {
      if (mounted) {
        _previewFormNumber();
      }
    });
  }

  Future<void> _ensureSchoolLoaded() async {
    if (_schoolController.selectedSchool.value == null) {
      await _schoolController.getAllSchools();
    }

    if (mounted) {
      await _previewFormNumber();
    }
  }

  Future<void> _previewFormNumber() async {
    final String? resolvedSchoolId = schoolId; // getter checking role / selected school
    if (resolvedSchoolId == null || resolvedSchoolId.isEmpty) {
      debugPrint('⚠️ School ID not resolved yet');
      return;
    }

    final nextNum = await _controller.getNextFormNumberPreview(schoolId: resolvedSchoolId);

    if (mounted && nextNum != null && nextNum.isNotEmpty) {
      setState(() {
        _formNumberLabel = nextNum;
      });
    }
  }
  @override
  void dispose() {
    _studentNameController.dispose();
    _dobController.dispose();
    _ageController.dispose();
    _motherTongueController.dispose();
    _religionController.dispose();
    _communityController.dispose();
    _emisNumberController.dispose();
    _academicYearController.dispose();
    _admissionSoughtForController.dispose();
    _examinationPassedController.dispose();
    _mobileNumberController.dispose();
    _currentAddressController.dispose();
    _permanentAddressController.dispose();
    _fatherNameController.dispose();
    _fatherEducationController.dispose();
    _fatherOccupationController.dispose();
    _motherNameController.dispose();
    _motherEducationController.dispose();
    _motherOccupationController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _formPayload => {
    'academicYear': _academicYearController.text.trim(),
    'studentName': _studentNameController.text.trim(),
    'mobileNumber': _mobileNumberController.text.trim(),
    'dob': _dobController.text.trim(),
    'age': int.tryParse(_ageController.text.trim()) ?? 0,
    'gender': _gender,
    'motherTongue': _motherTongueController.text.trim(),
    'religion': _religionController.text.trim(),
    'community': _communityController.text.trim(),
    if (_emisNumberController.text.trim().isNotEmpty) 'emisNumber': _emisNumberController.text.trim(),
    'currentAddress': _currentAddressController.text.trim(),
    'permanentAddress': _permanentSameAsCurrent
        ? _currentAddressController.text.trim()
        : _permanentAddressController.text.trim(),
    'fatherName': _fatherNameController.text.trim(),
    'fatherEducation': _fatherEducationController.text.trim(),
    'fatherOccupation': _fatherOccupationController.text.trim(),
    'motherName': _motherNameController.text.trim(),
    'motherEducation': _motherEducationController.text.trim(),
    'motherOccupation': _motherOccupationController.text.trim(),
    'examinationPassed': _examinationPassedController.text.trim(),
    'admissionSoughtFor': _admissionSoughtForController.text.trim(),
  };

  bool _validateRequiredFields() {
    final missing = <String>[];
    if (_studentNameController.text.trim().isEmpty) missing.add('Student Name');
    if (_dobController.text.trim().isEmpty) missing.add('Date of Birth');
    if (_ageController.text.trim().isEmpty) missing.add('Age');
    if (_mobileNumberController.text.trim().isEmpty) missing.add('Mobile Number');
    if (_academicYearController.text.trim().isEmpty) missing.add('Academic Year');
    if (_fatherNameController.text.trim().isEmpty) missing.add("Father's Name");
    if (_motherNameController.text.trim().isEmpty) missing.add("Mother's Name");

    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill: ${missing.join(', ')}')),
      );
      return false;
    }
    return true;
  }

  Future<void> _saveRecord() async {
    if (!_validateRequiredFields()) return;

    final String? resolvedSchoolId = schoolId;
    if (resolvedSchoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School ID not found. Please login again.')),
      );
      return;
    }

    if (_admissionFormId == null) {
      final linkResult = await _controller.generateNewAdmissionFormLink(schoolId: resolvedSchoolId);
      if (linkResult == null) return;

      _admissionFormId = (linkResult['_id'] ?? linkResult['id'] ?? linkResult['admissionFormId'])?.toString();
      final assignedFormNumber = linkResult['formNumber']?.toString();
      if (assignedFormNumber != null) {
        setState(() => _formNumberLabel = assignedFormNumber);
      }
    }

    if (_admissionFormId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not generate an admission form ID. Please try again.')),
      );
      return;
    }

    final submitted = await _controller.submitAdmissionForm(
      admissionFormId: _admissionFormId!,
      formData: _formPayload,
    );
    if (!submitted) return;

    // Capture these BEFORE _clearFormForNextEntry() wipes the controllers.
    final savedFormId = _admissionFormId!;
    final savedFormNumber = _formNumberLabel;
    final knownStudentId = _studentIdController.text.trim();

    bool linked = false;
    if (knownStudentId.isNotEmpty) {
      linked = await _controller.linkAdmissionFormToStudent(
        admissionFormId: savedFormId,
        studentId: knownStudentId,
      );
    }
    // if (knownStudentId.isNotEmpty) {
    //   // Student was chosen via the chip picker (or typed manually) — link it now.
    //   await _controller.linkAdmissionFormToStudent(
    //     admissionFormId: savedFormId,
    //     studentId: knownStudentId,
    //   );
    // }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Form Saved! Form No. $savedFormNumber')),
    );

    setState(() => _admissionFormId = null);
    _clearFormForNextEntry();
    await _previewFormNumber();

    // No student was linked during save — offer to link one now, or later.
    if (!linked && mounted) {
      _showLinkStudentDialog(savedFormId, savedFormNumber, prefillId: knownStudentId);
    }
  }
  void _clearFormForNextEntry() {
    _studentNameController.clear();
    _dobController.clear();
    _ageController.clear();
    _gender = null;
    _motherTongueController.clear();
    _religionController.clear();
    _communityController.clear();
    _emisNumberController.clear();
    _academicYearController.text = _defaultAcademicYear();
    _admissionSoughtForController.clear();
    _examinationPassedController.clear();
    _mobileNumberController.clear();
    _currentAddressController.clear();
    _permanentAddressController.clear();
    _permanentSameAsCurrent = false;
    _fatherNameController.clear();
    _fatherEducationController.clear();
    _fatherOccupationController.clear();
    _motherNameController.clear();
    _motherEducationController.clear();
    _motherOccupationController.clear();
    _studentIdController.clear();
    selectedClass.value = null;
    selectedSection.value = null;
    selectedStudent.value = null;
    classHasSections.value = true;
  }

  Future<void> _assignStudentProfile() async {
    if (_admissionFormId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save the record first before assigning a student profile.')),
      );
      return;
    }

    final studentId = _studentIdController.text.trim();
    if (studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a Student ID to link.')),
      );
      return;
    }

    await _controller.linkAdmissionFormToStudent(
      admissionFormId: _admissionFormId!,
      studentId: studentId,
    );
  }

  // ─── Class → Section → Student picker used to autofill the form ───────────

  void _resetSelection({bool clearForm = false}) {
    setState(() {
      selectedClass.value = null;
      selectedSection.value = null;
      selectedStudent.value = null;
      classHasSections.value = true;
    });
  }

  void _showClassSelectorSheet() {
    final sid = schoolId;
    if (sid == null || sid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School could not be resolved. Please login again.')),
      );
      return;
    }
    if (_schoolController.classes.isEmpty && !_schoolController.isLoading.value) {
      _schoolController.getAllClasses(sid);
    }

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(maxHeight: Get.height * 0.65),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
              ),
              const Text('Select Class', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F2042))),
              const Divider(),
              Expanded(
                child: Obx(() {
                  if (_schoolController.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final sortedClasses = List<SchoolClass>.from(_schoolController.classes)
                    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                  if (sortedClasses.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text('No classes found', style: TextStyle(color: Colors.black54)),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: sortedClasses.length,
                    itemBuilder: (context, index) {
                      final c = sortedClasses[index];
                      final isSelected = selectedClass.value?.id == c.id;
                      return ListTile(
                        leading: const Icon(Icons.class_rounded, color: Color(0xFF1E3A8A)),
                        title: Text(c.name,
                            style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: const Color(0xFF0F2042))),
                        trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF1E3A8A)) : null,
                        onTap: () {
                          setState(() {
                            selectedClass.value = c;
                            selectedSection.value = null;
                            selectedStudent.value = null;
                            classHasSections.value = c.hasSections;
                          });
                          Get.back();
                          final sid2 = schoolId;
                          if (sid2 == null) return;
                          if (c.hasSections) {
                            _schoolController.getAllSections(classId: c.id, schoolId: sid2);
                            _showSectionSelectorSheet();
                          } else {
                            _schoolController.getAllStudents(schoolId: sid2, classId: c.id);
                            _showStudentSelectorSheet();
                          }
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showSectionSelectorSheet() {
    if (selectedClass.value == null) return;
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(maxHeight: Get.height * 0.65),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
              ),
              Obx(() => Text(
                  'Select Section for ${selectedClass.value?.name ?? ""}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F2042)))),
              const Divider(),
              Expanded(
                child: Obx(() {
                  if (_schoolController.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final classSections = _schoolController.sections
                      .where((s) => s.classId == selectedClass.value?.id)
                      .toList();
                  if (classSections.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text('No sections found for this class', style: TextStyle(color: Colors.black54)),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: classSections.length,
                    itemBuilder: (context, index) {
                      final sec = classSections[index];
                      final isSelected = selectedSection.value?.id == sec.id;
                      return ListTile(
                        leading: const Icon(Icons.group_rounded, color: Color(0xFF1E3A8A)),
                        title: Text(sec.name,
                            style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: const Color(0xFF0F2042))),
                        trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF1E3A8A)) : null,
                        onTap: () {
                          setState(() {
                            selectedSection.value = sec;
                            selectedStudent.value = null;
                          });
                          Get.back();
                          final sid2 = schoolId;
                          if (sid2 == null) return;
                          _schoolController.getAllStudents(
                            schoolId: sid2,
                            classId: selectedClass.value?.id,
                            sectionId: sec.id,
                          );
                          _showStudentSelectorSheet();
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showStudentSelectorSheet() {
    if (selectedClass.value == null) return;
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(maxHeight: Get.height * 0.65),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
              ),
              const Text('Select Student', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F2042))),
              const Divider(),
              Expanded(
                child: Obx(() {
                  if (_schoolController.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final students = _schoolController.students;
                  if (students.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text('No students found for this selection', style: TextStyle(color: Colors.black54)),
                      ),
                    );
                  }
                  final sorted = List<Student>.from(students)
                    ..sort((a, b) => (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()));
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final st = sorted[index];
                      final isSelected = selectedStudent.value?.id == st.id;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE0F2FE),
                          child: Text(
                            (st.name ?? 'S').isNotEmpty ? st.name!.substring(0, 1).toUpperCase() : 'S',
                            style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(st.name ?? 'Unknown',
                            style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: const Color(0xFF0F2042))),
                        subtitle: Text('Roll No: ${st.rollNumber ?? "N/A"}'),
                        trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF1E3A8A)) : null,
                        onTap: () {
                          setState(() => selectedStudent.value = st);
                          Get.back();
                          _fetchAndAutofillStudent(st.id);
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // ─── Autofill: pulls the full student profile and fills the form fields ───

  String _formatDobForDisplay(String raw) {
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
    }
    return raw; // already in DD/MM/YYYY or another display format
  }

  String _computeAgeFromDob(String raw) {
    if (raw.isEmpty) return '';
    DateTime? dob = DateTime.tryParse(raw);
    if (dob == null && raw.contains('/')) {
      final parts = raw.split('/');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          dob = DateTime(year, month, day);
        }
      }
    }
    if (dob == null) return '';
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
    return age >= 0 ? age.toString() : '';
  }

  Future<void> _fetchAndAutofillStudent(String studentId) async {
    setState(() => _isFetchingStudentDetails = true);

    final uri = Uri.parse('${ApiConstants.baseUrl}/api/student/get/$studentId');

    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer ${_getToken()}',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load that student\'s profile.')),
          );
        }
        return;
      }

      final decoded = jsonDecode(response.body);
      final Map<String, dynamic> doc = decoded['data'] ?? decoded['student'] ?? decoded;
      final Map<String, dynamic> m = doc['mandatory'] ?? {};
      final Map<String, dynamic> n = doc['nonMandatory'] ?? {};

      String v(String key) {
        for (final src in [m, n, doc]) {
          if (src[key] != null && src[key].toString().isNotEmpty && src[key].toString() != 'null') {
            return src[key].toString();
          }
        }
        return '';
      }

      if (!mounted) return;
      setState(() {
        _studentIdController.text = studentId;

        final rawName = v('studentName').isNotEmpty ? v('studentName') : v('aadhaarName');
        _studentNameController.text = rawName;

        _dobController.text = _formatDobForDisplay(v('dob'));
        _ageController.text = _computeAgeFromDob(v('dob'));

        final genderVal = v('gender');
        if (['male', 'female', 'other'].contains(genderVal.toLowerCase())) {
          _gender = genderVal[0].toUpperCase() + genderVal.substring(1).toLowerCase();
        }

        _motherTongueController.text = v('motherTongue');
        _religionController.text = v('religion');
        final communityVal = v('community').isNotEmpty ? v('community') : v('caste');
        _communityController.text = communityVal;
        _emisNumberController.text = v('emisNumber');

        _mobileNumberController.text = v('mobileNumber');
        _currentAddressController.text = v('address');
        if (!_permanentSameAsCurrent) {
          final permanentVal = v('permanentAddress');
          if (permanentVal.isNotEmpty) _permanentAddressController.text = permanentVal;
        }

        _fatherNameController.text = v('fatherName');
        _motherNameController.text = v('motherName');

        // Default "sought for" to the class the student is already enrolled in —
        // editable if this admission is for a different grade.
        if (selectedClass.value != null) {
          _admissionSoughtForController.text = selectedClass.value!.name;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Autofilled from ${_studentNameController.text.isEmpty ? "student profile" : _studentNameController.text}. '
            'Father/Mother education & occupation and exam details still need manual entry.')),
      );
    } catch (e) {
      debugPrint('Autofill fetch error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong while loading the student profile.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingStudentDetails = false);
    }
  }

  Widget _selectorChip({
    required IconData icon,
    required String label,
    required bool isSet,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSet ? const Color(0xFF1E3A8A) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF1E3A8A)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSet ? Colors.white : const Color(0xFF1E3A8A)),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 85),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSet ? Colors.white : const Color(0xFF1E3A8A),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: isSet ? Colors.white : const Color(0xFF1E3A8A)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentSelectorBar() {
    return Obx(() => Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_fix_high_rounded, size: 16, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Autofill from an existing student',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A))),
              ),
              if (selectedClass.value != null || selectedSection.value != null || selectedStudent.value != null)
                GestureDetector(
                  onTap: () => _resetSelection(),
                  child: const Text('Clear', style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
              child: Row(
            children: [
              _selectorChip(
                icon: Icons.class_rounded,
                label: selectedClass.value?.name ?? 'Select Class',
                isSet: selectedClass.value != null,
                onTap: _showClassSelectorSheet,
              ),
              SizedBox(width: 10),
              _selectorChip(
                icon: Icons.group_rounded,
                label: selectedSection.value?.name ??
                    (classHasSections.value ? 'Select Section' : 'No Sections'),
                isSet: selectedSection.value != null,
                enabled: selectedClass.value != null && classHasSections.value,
                onTap: _showSectionSelectorSheet,
              ),
              SizedBox(width: 10),
              _selectorChip(
                icon: Icons.person_rounded,
                label: selectedStudent.value?.name ?? 'Select Student',
                isSet: selectedStudent.value != null,
                enabled: selectedClass.value != null,
                onTap: _showStudentSelectorSheet,
              ),
            ],
              )
          ),
          if (_isFetchingStudentDetails) ...[
            const SizedBox(height: 10),
            const Row(children: [
              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('Loading student details…', style: TextStyle(fontSize: 11, color: Colors.black54)),
            ]),
          ],
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCC2A8),
      appBar: AppBar(
        title: const Text('Admission Book Registrar'),
        backgroundColor: const Color(0xFF0F2042),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.print_rounded), onPressed: () {}),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 850),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStudentSelectorBar(),
                      _buildLinkPreviewBanner(),
                      _buildBookHeader(),
                      const SizedBox(height: 24),
                      _buildStudentDetailsSection(),
                      const SizedBox(height: 24),
                      _buildAcademicContactSection(),
                      const SizedBox(height: 24),
                      _buildParentInformationSection(),
                      const SizedBox(height: 28),
                      Row(
                        children: List.generate(
                          40,
                              (index) => Expanded(
                            child: Container(
                              color: index % 2 == 0 ? Colors.transparent : Colors.grey.withOpacity(0.6),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    //  _buildStudentIDLinkingSection(),
                    ],
                  ),
                ),
                _buildActionFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookHeader() {
    return Obx(() {
      final school = _schoolController.selectedSchool.value;
      final rawSchoolName = school?.name ?? 'School Name Not Set';
      final schoolAddress = school?.address ?? '';

      // Convert ALL CAPS text to Title Case for cleaner layout readability
      final schoolName = rawSchoolName.isNotEmpty
          ? rawSchoolName
          .split(' ')
          .map((str) => str.isNotEmpty
          ? '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}'
          : '')
          .join(' ')
          : 'School Name Not Set';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form Number aligned to top right
          Align(
            alignment: Alignment.centerRight,
            child: _buildFormNumberBadge(),
          ),
          const SizedBox(height: 8),

          // Header main row: Icon + School Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF0F2042), width: 1.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_rounded, size: 28, color: Color(0xFF0F2042)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schoolName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15, // Reduced font size to avoid aggressive line wrapping
                        height: 1.25,
                        color: Color(0xFF0F2042),
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (schoolAddress.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        schoolAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 8),

          // Document Title centered underneath
          const Center(
            child: Text(
              'REGISTRATION & ADMISSION MASTER RECORD',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E3A8A),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      );
    });
  }
  Widget _buildFormNumberBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E3A8A), width: 1.5),
      ),
      child: Column(
        children: [
          const Text('Form No.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          Text(_formNumberLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildStudentDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionBanner('I. STUDENT DETAILS'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(flex: 3, child: _buildUnderlinedField(_studentNameController, 'Student Name')),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildUnderlinedField(_dobController, 'Date of Birth (DD/MM/YYYY)')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildUnderlinedField(_ageController, 'Age', keyboardType: TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(child: _buildGenderDropdown()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildUnderlinedField(_motherTongueController, 'Mother Tongue')),
            const SizedBox(width: 8),
            Expanded(child: _buildUnderlinedField(_religionController, 'Religion')),
            const SizedBox(width: 16),
            Expanded(child: _buildUnderlinedField(_communityController, 'Community')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildUnderlinedField(_emisNumberController, 'EMIS Number (optional)')),
          ],
        )
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _gender,
      decoration: InputDecoration(
        labelText: 'Gender',
        labelStyle: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.normal),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black38, width: 1)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E3A8A), width: 1.8)),
        contentPadding: const EdgeInsets.only(top: 10, bottom: 4),
      ),
      items: const [
        DropdownMenuItem(value: 'Male', child: Text('Male')),
        DropdownMenuItem(value: 'Female', child: Text('Female')),
        DropdownMenuItem(value: 'Other', child: Text('Other')),
      ],
      onChanged: (value) {
        if (value != null) setState(() => _gender = value);
      },
    );
  }

  Widget _buildAcademicContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionBanner('II. ACADEMIC & CONTACT'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildUnderlinedField(_academicYearController, 'Academic Year (e.g. 2025-2026)')),
            const SizedBox(width: 16),
            Expanded(child: _buildUnderlinedField(_admissionSoughtForController, 'Admission Sought For (Class/Grade)')),
            const SizedBox(width: 16),
            Expanded(child: _buildUnderlinedField(_examinationPassedController, 'Previous Exam / Last Class Passed')),
          ],
        ),
        const SizedBox(height: 12),
        _buildUnderlinedField(_mobileNumberController, 'Mobile Number'),
        const SizedBox(height: 12),
        _buildUnderlinedField(_currentAddressController, 'Current Address'),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: _permanentSameAsCurrent,
              onChanged: (value) => setState(() => _permanentSameAsCurrent = value ?? false),
            ),
            const Text('Permanent address ', style: TextStyle(fontSize: 12)),
          ],
        ),
        if (!_permanentSameAsCurrent) _buildUnderlinedField(_permanentAddressController, 'Permanent Address'),
      ],
    );
  }

  Widget _buildParentInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionBanner('III. PARENT INFORMATION'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(flex: 2, child: _buildUnderlinedField(_fatherNameController, "Father's Name")),
            const SizedBox(width: 16),
            Expanded(flex: 1, child: _buildUnderlinedField(_fatherEducationController, 'Education')),
            const SizedBox(width: 16),
            Expanded(flex: 1, child: _buildUnderlinedField(_fatherOccupationController, 'Occupation')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(flex: 2, child: _buildUnderlinedField(_motherNameController, "Mother's Name")),
            const SizedBox(width: 16),
            Expanded(flex: 1, child: _buildUnderlinedField(_motherEducationController, 'Education')),
            const SizedBox(width: 16),
            Expanded(flex: 1, child: _buildUnderlinedField(_motherOccupationController, 'Occupation')),
          ],
        ),
      ],
    );
  }

  Widget _buildStudentIDLinkingSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.link_rounded, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _admissionFormId == null
                      ? 'OFFICE DISPATCH ASSIGNMENT\nSave the record first, then link it to a Student profile.'
                      : 'OFFICE DISPATCH ASSIGNMENT\nLinked Registry Form Association Reference: #$_formNumberLabel',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 200,
                height: 40,
                child: TextField(
                  controller: _studentIdController,
                  decoration: InputDecoration(
                    hintText: 'Assign Student ID Profile',
                    hintStyle: const TextStyle(fontSize: 12),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Obx(() {
                final loading = _controller.isLoading.value;
                return SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: loading ? null : _assignStudentProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: loading
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text('Link', style: TextStyle(fontSize: 12)),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionBanner(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      color: const Color(0xFF0F2042),
      child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
    );
  }

  Widget _buildUnderlinedField(
      TextEditingController controller,
      String hint, {
        TextInputType? keyboardType,
      }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.normal),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black38, width: 1)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E3A8A), width: 1.8)),
        contentPadding: const EdgeInsets.only(top: 10, bottom: 4),
      ),
    );
  }

  Widget _buildActionFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Obx(() {
            final loading = _controller.isLoading.value;
            return ElevatedButton.icon(
              onPressed: loading ? null : _saveRecord,
              icon: loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add_task_rounded),
              label: Text(loading ? 'Saving...' : 'Save Record '),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _showLinkStudentDialog(
      String admissionFormId,
      String formNumber, {
        String prefillId = '',
      }) async {
    final tempController = TextEditingController(text: prefillId);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link Student Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              prefillId.isNotEmpty
                  ? 'Form No. $formNumber was saved, but linking to Student ID "$prefillId" failed. Confirm and retry, or skip and link it later.'
                  : 'Form No. $formNumber was saved without a linked student profile.\nEnter a Student ID to link it now, or skip and link it later.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tempController,
              decoration: const InputDecoration(hintText: 'Student ID', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final carriedId = tempController.text.trim();
              Navigator.of(ctx).pop();
              // Carry the known ID forward so it isn't lost — the detail
              // view will prefill its Student ID field with it.
              Get.to(() => AdmissionFormDetailView(
                admissionFormId: admissionFormId,
                prefillStudentId: carriedId.isNotEmpty ? carriedId : null,
              ));
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () async {
              final sid = tempController.text.trim();
              if (sid.isEmpty) return;
              final ok = await _controller.linkAdmissionFormToStudent(
                admissionFormId: admissionFormId,
                studentId: sid,
              );
              if (ok) Navigator.of(ctx).pop();
            },
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }
  Widget _buildLinkPreviewBanner() {
    return Obx(() {
      final pickedStudent = selectedStudent.value;
      final typedId = _studentIdController.text.trim();

      // Nothing selected and nothing typed — allow manual entry inline.
      if (pickedStudent == null && typedId.isEmpty) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text Label On Top
              const Row(
                children: [
                  Icon(Icons.link_off_rounded, size: 16, color: Color(0xFFB45309)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'No student will be linked. Select above or enter ID:',
                      style: TextStyle(fontSize: 11, color: Color(0xFFB45309), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Student ID Box Below
              SizedBox(
                height: 38,
                child: TextField(
                  controller: _studentIdController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Enter Student ID...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      // Something will be linked — show a clear, read-only preview.
      final displayName = pickedStudent?.name ?? 'Manually entered ID';
      final displayId = typedId.isNotEmpty ? typedId : (pickedStudent?.id ?? '');

      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.link_rounded, size: 16, color: Color(0xFF15803D)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Will link to: $displayName  (ID: $displayId)',
                style: const TextStyle(fontSize: 12, color: Color(0xFF15803D), fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedStudent.value = null;
                  _studentIdController.clear();
                });
              },
              child: const Text('Unlink', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
            ),
          ],
        ),
      );
    });
  }}
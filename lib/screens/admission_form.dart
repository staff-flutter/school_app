import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/bill_admission_controller.dart';

import '../controllers/school_controller.dart';

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
  // --- Form Field Controllers (mapped to the IAdmissionForm schema) ---
  // 1. Student Details
  final _studentNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'Male';
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
  }

  Future<void> _ensureSchoolLoaded() async {
    if (_schoolController.selectedSchool.value == null) {
      await _schoolController.getAllSchools();
      if (mounted) setState(() {});
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

    //final schoolId = _authController.user.value?.schoolId;
   // if (schoolId == null) {
      final String? resolvedSchoolId = schoolId;
        if (resolvedSchoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School ID not found. Please login again.')),
      );
      return;
    }

    // Step 1: ask the active Admission Book for a new blank form + form number.
   // final linkResult = await _controller.generateNewAdmissionFormLink(schoolId: schoolId);
    final linkResult = await _controller.generateNewAdmissionFormLink(schoolId: resolvedSchoolId);
    if (linkResult == null) return; // controller already showed the error
    debugPrint('🔍 generateNewAdmissionFormLink result: $linkResult');

    final newAdmissionFormId = linkResult['_id'] ?? linkResult['id'] ?? linkResult['admissionFormId'];
    final newFormNumber = linkResult['formNumber'];

    if (newAdmissionFormId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not generate an admission form ID. Please try again.')),
      );
      return;
    }
    debugPrint('📝 Submitting payload: $_formPayload');

    // Step 2: submit the filled-in details against that form id.
    final submitted = await _controller.submitAdmissionForm(
      admissionFormId: newAdmissionFormId.toString(),
      formData: _formPayload,
    );

    if (!submitted) return;

    setState(() {
      _admissionFormId = newAdmissionFormId.toString();
      _formNumberLabel = newFormNumber?.toString() ?? newAdmissionFormId.toString();
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Form Saved! Form No. $_formNumberLabel')),
    );
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
                      _buildStudentIDLinkingSection(),
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
      final schoolName = school?.name ?? 'School Name Not Set';
      final schoolAddress = school?.address ?? '';
      //final schoolPhone = school?.phone ?? ''; // adjust field name to match your School model

      return Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [_buildFormNumberBadge()]),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF0F2042), width: 2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_rounded, size: 30, color: Color(0xFF0F2042)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(schoolName.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F2042), letterSpacing: 0.5)),
                    Text(
                      [
                        if (schoolAddress.isNotEmpty) schoolAddress,
                       // if (schoolPhone.isNotEmpty) 'Contact: $schoolPhone',
                      ].join(' | '),
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    const Text('REGISTRATION & ADMISSION MASTER RECORD',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
                  ],
                ),
              ),
            ],
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
      initialValue: _gender,
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
}
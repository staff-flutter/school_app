import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/bill_admission_controller.dart';

class AdmissionFormDetailView extends StatefulWidget {
  final String admissionFormId;
  final Map<String, dynamic>? initialData;
  final String? prefillStudentId;

  const AdmissionFormDetailView({
    super.key,
    required this.admissionFormId,
    this.initialData,
    this.prefillStudentId,
  });

  @override
  State<AdmissionFormDetailView> createState() => _AdmissionFormDetailViewState();
}

class _AdmissionFormDetailViewState extends State<AdmissionFormDetailView> {
  final BillAdmissionController _controller = Get.find<BillAdmissionController>();

  Map<String, dynamic>? _formData;
  bool _loading = true;
  bool _editMode = false;
  bool _changed = false;

  // Matches the IAdmissionForm schema's status enum exactly.
  static const List<String> _statusOptions = ['Pending', 'Approved', 'Rejected'];

  // Editable field controllers - populated once the form data is available.
  final _studentNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _motherTongueController = TextEditingController();
  final _religionController = TextEditingController();
  final _communityController = TextEditingController();
  final _emisNumberController = TextEditingController();
  final _academicYearController = TextEditingController();
  final _admissionSoughtForController = TextEditingController();
  final _examinationPassedController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _currentAddressController = TextEditingController();
  final _permanentAddressController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _fatherEducationController = TextEditingController();
  final _fatherOccupationController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _motherEducationController = TextEditingController();
  final _motherOccupationController = TextEditingController();
  final _studentIdController = TextEditingController();

  @override
  void initState() {

    super.initState();
    if (widget.initialData != null) {
      _formData = widget.initialData;
      _populateControllers(widget.initialData!);
      _loading = false;
    }
    // If a studentId was passed in from navigation, prefill it
    if (widget.prefillStudentId != null && widget.prefillStudentId!.isNotEmpty) {
      _studentIdController.text = widget.prefillStudentId!;
      print('prefillStudentId:${widget.prefillStudentId}');
    }
    _loadForm();
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _dobController.dispose();
    _ageController.dispose();
    _genderController.dispose();
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

  void _populateControllers(Map<String, dynamic> data) {
    _studentNameController.text = data['studentName']?.toString() ?? '';
    _dobController.text = data['dob']?.toString() ?? '';
    _ageController.text = data['age']?.toString() ?? '';
    _genderController.text = data['gender']?.toString() ?? '';
    _motherTongueController.text = data['motherTongue']?.toString() ?? '';
    _religionController.text = data['religion']?.toString() ?? '';
    _communityController.text = data['community']?.toString() ?? '';
    _emisNumberController.text = data['emisNumber']?.toString() ?? '';
    _academicYearController.text = data['academicYear']?.toString() ?? '';
    _admissionSoughtForController.text = data['admissionSoughtFor']?.toString() ?? '';
    _examinationPassedController.text = data['examinationPassed']?.toString() ?? '';
    _mobileNumberController.text = data['mobileNumber']?.toString() ?? '';
    _currentAddressController.text = data['currentAddress']?.toString() ?? '';
    _permanentAddressController.text = data['permanentAddress']?.toString() ?? '';
    _fatherNameController.text = data['fatherName']?.toString() ?? '';
    _fatherEducationController.text = data['fatherEducation']?.toString() ?? '';
    _fatherOccupationController.text = data['fatherOccupation']?.toString() ?? '';
    _motherNameController.text = data['motherName']?.toString() ?? '';
    _motherEducationController.text = data['motherEducation']?.toString() ?? '';
    _motherOccupationController.text = data['motherOccupation']?.toString() ?? '';
   // _studentIdController.text = (data['studentId'] ?? '').toString();
    final fetchedStudentId = data['studentId']?.toString() ?? '';
    if (fetchedStudentId.isNotEmpty) {
      _studentIdController.text = fetchedStudentId;
    } else if (widget.prefillStudentId != null && widget.prefillStudentId!.isNotEmpty) {
      _studentIdController.text = widget.prefillStudentId!;
    } else {
      _studentIdController.text = '';
    }
  }

  Future<void> _loadForm() async {
    // Wait until the current build frame is completely finished
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final data = await _controller.getSingleAdmissionForm(admissionFormId: widget.admissionFormId);

      if (data != null && mounted) {
        setState(() {
          _formData = data;
          _populateControllers(data);
        });
      }
      if (mounted) {
        setState(() => _loading = false);
      }
    });
  }

  Map<String, dynamic> get _editedPayload => {
    'studentName': _studentNameController.text.trim(),
    'dob': _dobController.text.trim(),
    'age': int.tryParse(_ageController.text.trim()) ?? 0,
    'gender': _genderController.text.trim(),
    'motherTongue': _motherTongueController.text.trim(),
    'religion': _religionController.text.trim(),
    'community': _communityController.text.trim(),
    if (_emisNumberController.text.trim().isNotEmpty) 'emisNumber': _emisNumberController.text.trim(),
    'academicYear': _academicYearController.text.trim(),
    'admissionSoughtFor': _admissionSoughtForController.text.trim(),
    'examinationPassed': _examinationPassedController.text.trim(),
    'mobileNumber': _mobileNumberController.text.trim(),
    'currentAddress': _currentAddressController.text.trim(),
    'permanentAddress': _permanentAddressController.text.trim(),
    'fatherName': _fatherNameController.text.trim(),
    'fatherEducation': _fatherEducationController.text.trim(),
    'fatherOccupation': _fatherOccupationController.text.trim(),
    'motherName': _motherNameController.text.trim(),
    'motherEducation': _motherEducationController.text.trim(),
    'motherOccupation': _motherOccupationController.text.trim(),
  };

  Future<void> _saveEdits() async {
    final success = await _controller.updateAdmissionFormAfterSubmission(
      admissionFormId: widget.admissionFormId,
      updatedData: _editedPayload,
    );
    if (success) {
      _changed = true;
      setState(() => _editMode = false);
      _loadForm();
    }
  }

  Future<void> _updateStatus(String status) async {
    final success = await _controller.updateAdmissionFormStatus(
      admissionFormId: widget.admissionFormId,
      status: status,
    );
    if (success) {
      _changed = true;
      _loadForm();
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Admission Form'),
        content: const Text('This action cannot be undone. Are you sure you want to delete this form?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _controller.deleteAdmissionForm(admissionFormId: widget.admissionFormId);
      if (success && mounted) {
        Get.back(result: true);
      }
    }
  }

  Future<void> _linkStudent() async {
    final studentId = _studentIdController.text.trim();
    if (studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a Student ID to link.')),
      );
      return;
    }

    final success = await _controller.linkAdmissionFormToStudent(
      admissionFormId: '${widget.admissionFormId}',
      studentId: studentId,
    );
    String? admissionformid='${widget.admissionFormId}';
    print('admissionformid:$admissionformid');
    print('studentid:$studentId');
    if (success) {
      _changed = true;
      _loadForm();
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return const Color(0xFF15803D);
      case 'rejected':
        return const Color(0xFFB91C1C);
      case 'pending':
        return const Color(0xFFB45309);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('admissionformId:$widget.admissionFormId');
    return WillPopScope(
      onWillPop: () async {
        Get.back(result: _changed);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Admission Form'),
          backgroundColor: const Color(0xFF0F2042),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(result: _changed),
          ),
          actions: [
            if (!_loading && _formData != null)
              IconButton(
                icon: Icon(_editMode ? Icons.close_rounded : Icons.edit_rounded),
                onPressed: () => setState(() => _editMode = !_editMode),
              ),
            if (!_loading && _formData != null)
              IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: _confirmDelete),
          ],
        ),
        body: Obx(() {
          final saving = _controller.isLoading.value;

          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_formData == null) {
            return const Center(child: Text('Admission form not found.'));
          }

          final status = _formData?['status']?.toString() ?? 'Pending';
          final formNumber = (_formData?['formNumber'] ?? widget.admissionFormId).toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHeader(status, formNumber, saving),
                const SizedBox(height: 20),
                _buildSectionBanner('I. STUDENT DETAILS'),
                const SizedBox(height: 12),
                _buildField(_studentNameController, 'Student Name'),
                _buildField(_dobController, 'Date of Birth'),
                _buildField(_ageController, 'Age'),
                _buildField(_genderController, 'Gender'),
                _buildField(_motherTongueController, 'Mother Tongue'),
                _buildField(_religionController, 'Religion'),
                _buildField(_communityController, 'Community'),
                _buildField(_emisNumberController, 'EMIS Number'),
                const SizedBox(height: 20),
                _buildSectionBanner('II. ACADEMIC & CONTACT'),
                const SizedBox(height: 12),
                _buildField(_academicYearController, 'Academic Year'),
                _buildField(_admissionSoughtForController, 'Admission Sought For (Class/Grade)'),
                _buildField(_examinationPassedController, 'Previous Exam / Last Class Passed'),
                _buildField(_mobileNumberController, 'Mobile Number'),
                _buildField(_currentAddressController, 'Current Address'),
                _buildField(_permanentAddressController, 'Permanent Address'),
                const SizedBox(height: 20),
                _buildSectionBanner('III. PARENT INFORMATION'),
                const SizedBox(height: 12),
                _buildField(_fatherNameController, "Father's Name"),
                _buildField(_fatherEducationController, "Father's Education"),
                _buildField(_fatherOccupationController, "Father's Occupation"),
                _buildField(_motherNameController, "Mother's Name"),
                _buildField(_motherEducationController, "Mother's Education"),
                _buildField(_motherOccupationController, "Mother's Occupation"),
                if (_editMode) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving ? null : _saveEdits,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: saving
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _buildLinkingSection(saving),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatusHeader(String status, String formNumber, bool saving) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Form No. $formNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _statusColor(status))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statusOptions.map((s) {
              final isCurrent = s.toLowerCase() == status.toLowerCase();
              return OutlinedButton(
                onPressed: (saving || isCurrent) ? null : () => _updateStatus(s),
                style: OutlinedButton.styleFrom(foregroundColor: _statusColor(s), side: BorderSide(color: _statusColor(s))),
                child: Text(s),
              );
            }).toList(),
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

  Widget _buildField(TextEditingController controller, String label) {
    if (!_editMode) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 160, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500))),
            Expanded(
              child: Text(
                controller.text.isEmpty ? '—' : controller.text,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  Widget _buildLinkingSection(bool saving) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.link_rounded, color: Color(0xFF1E3A8A)),
              SizedBox(width: 10),
              Expanded(
                child: Text('STUDENT PROFILE LINK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _studentIdController,
                  decoration: InputDecoration(
                    hintText: 'Student ID',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: saving ? null : _linkStudent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Link'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
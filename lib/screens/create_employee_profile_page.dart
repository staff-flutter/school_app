import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart' hide Response;
import 'package:dio/dio.dart' as dio;
import 'package:school_app/constants/api_constants.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/school_controller.dart';
import '../../services/api_service.dart';

// =============================================================================
// API ROUTES
// =============================================================================
class _EmployeeApi {
  static String getOne(String userId) => '/api/employee-profile/get/$userId';
  static String upsert(String userId) => '/api/employee-profile/$userId/upsert';
  static String deleteDocument(String userId, String documentId) =>
      '/api/employee-profile/$userId/documents/$documentId';
}

// =============================================================================
// MODELS
// =============================================================================

class EmployeeDocument {
  final String id;
  final String url;
  final String name;

  const EmployeeDocument({required this.id, required this.url, required this.name});

  static EmployeeDocument? fromJson(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json as Map);
    final id = m['_id']?.toString();
    final url = m['url']?.toString();
    if (id == null || url == null || url.isEmpty) return null;
    final name = (m['originalName'] ?? 'File').toString();
    return EmployeeDocument(id: id, url: resolveEmployeeFileUrl(url)!, name: name);
  }
}

String? resolveEmployeeFileUrl(String? path) {
  if (path == null || path.trim().isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final base = ApiConstants.baseUrl.endsWith('/')
      ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
      : ApiConstants.baseUrl;
  final p = path.startsWith('/') ? path : '/$path';
  return '$base$p';
}

class EducationEntry {
  final degreeCtrl = TextEditingController();
  final institutionCtrl = TextEditingController();
  final yearCtrl = TextEditingController();
  final gradeCtrl = TextEditingController();

  EducationEntry();

  factory EducationEntry.fromJson(Map<String, dynamic> json) {
    final e = EducationEntry();
    e.degreeCtrl.text = json['degree']?.toString() ?? '';
    e.institutionCtrl.text = json['institution']?.toString() ?? '';
    e.yearCtrl.text = json['yearOfPassing']?.toString() ?? '';
    e.gradeCtrl.text = json['grade']?.toString() ?? '';
    return e;
  }

  Map<String, dynamic> toJson() => {
    'degree': degreeCtrl.text.trim().isEmpty ? null : degreeCtrl.text.trim(),
    'institution': institutionCtrl.text.trim().isEmpty ? null : institutionCtrl.text.trim(),
    'yearOfPassing': yearCtrl.text.trim().isEmpty ? null : yearCtrl.text.trim(),
    'grade': gradeCtrl.text.trim().isEmpty ? null : gradeCtrl.text.trim(),
  };

  void dispose() {
    degreeCtrl.dispose();
    institutionCtrl.dispose();
    yearCtrl.dispose();
    gradeCtrl.dispose();
  }
}

// =============================================================================
// PAGE
// =============================================================================

class CreateEmployeeProfilePage extends StatefulWidget {
  final String? userId;
  final String? schoolId;
  final bool isEdit;

  const CreateEmployeeProfilePage({
    super.key,
    this.userId,
    this.schoolId,
    this.isEdit = false,
  });

  @override
  State<CreateEmployeeProfilePage> createState() => _CreateEmployeeProfilePageState();
}

class _CreateEmployeeProfilePageState extends State<CreateEmployeeProfilePage> {
  final _auth = Get.find<AuthController>();
  final _school = Get.find<SchoolController>();
  final ApiService _apiService = Get.find<ApiService>();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isFetching = false;

  String? _userId;
  bool get _isNewStaff => _userId == null || _userId!.trim().isEmpty;

  String? get _resolvedSchoolId {
    final id = widget.schoolId;
    if (id != null && id.isNotEmpty) return id;
    final role = _auth.user.value?.role?.toLowerCase() ?? '';
    if (role == 'correspondent') return _school.selectedSchool.value?.id;
    return _auth.user.value?.schoolId;
  }

  // Account / registration controllers
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  static const List<String> _roleOptions = [
    'Teacher',
    'Principal',
    'Accountant',
    'Administrator',
    'Correspondent',
  ];
  String? _selectedAccountRole;

  // Text controllers
  final _currentAddressCtrl = TextEditingController();
  final _permanentAddressCtrl = TextEditingController();
  final _employeeNoCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _dateOfJoiningCtrl = TextEditingController();
  final _nationalIdCtrl = TextEditingController();
  final _pfNumberCtrl = TextEditingController();
  final _yearsOfExpCtrl = TextEditingController();
  final _previousWorkplaceCtrl = TextEditingController();

  final _bankAccountNameCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountNoCtrl = TextEditingController();
  final _ifscCodeCtrl = TextEditingController();

  final _emgNameCtrl = TextEditingController();
  final _emgRelationCtrl = TextEditingController();
  final _emgPhoneCtrl = TextEditingController();

  String _employmentType = 'full_time';
  static const _employmentOptions = ['full_time', 'part_time', 'contract', 'temporary'];
  bool _isActive = true;

  final List<EducationEntry> _education = [];
  final List<File> _selectedFiles = [];
  File? _salarySlipFile;
  EmployeeDocument? _existingSalarySlip;
  final List<EmployeeDocument> _existingDocuments = [];
  String? _deletingDocId;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId;
    if (widget.isEdit && _userId != null) {
      _loadExistingProfile();
    } else {
      _education.add(EducationEntry());
    }
  }

  @override
  void dispose() {
    for (final c in [
      _fullNameCtrl, _emailCtrl, _phoneCtrl, _passwordCtrl,
      _currentAddressCtrl, _permanentAddressCtrl, _employeeNoCtrl, _designationCtrl,
      _departmentCtrl, _dateOfJoiningCtrl, _nationalIdCtrl, _pfNumberCtrl,
      _yearsOfExpCtrl, _previousWorkplaceCtrl, _bankAccountNameCtrl, _bankNameCtrl,
      _accountNoCtrl, _ifscCodeCtrl, _emgNameCtrl, _emgRelationCtrl, _emgPhoneCtrl,
    ]) {
      c.dispose();
    }
    for (final e in _education) {
      e.dispose();
    }
    super.dispose();
  }

  String? _isoDate(String? ddmmyyyy) {
    if (ddmmyyyy == null || ddmmyyyy.trim().isEmpty) return null;
    final parts = ddmmyyyy.split('/');
    if (parts.length != 3) return ddmmyyyy;
    return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
  }

  String? _fromIsoDate(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (v.contains('/')) return v;
    final datePart = v.split('T').first;
    final parts = datePart.split('-');
    if (parts.length == 3 && parts[0].length == 4) {
      return '${parts[2].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[0]}';
    }
    return v;
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ctrl.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  Future<void> _loadExistingProfile() async {
    if (_userId == null) return;
    setState(() => _isFetching = true);
    try {
      final res = await _apiService.get(_EmployeeApi.getOne(_userId!));
      final data = (res.data is Map && res.data['data'] is Map)
          ? Map<String, dynamic>.from(res.data['data'])
          : Map<String, dynamic>.from(res.data ?? {});

      final user = data['userId'];
      if (user is Map) {
        _fullNameCtrl.text = user['fullName']?.toString() ?? user['name']?.toString() ?? '';
        _emailCtrl.text = user['email']?.toString() ?? '';
        _phoneCtrl.text = user['phone']?.toString() ?? user['phoneNumber']?.toString() ?? '';
        final role = user['role']?.toString();
        if (role != null && _roleOptions.contains(role)) _selectedAccountRole = role;
      }

      _currentAddressCtrl.text = data['currentAddress']?.toString() ?? '';
      _permanentAddressCtrl.text = data['permanentAddress']?.toString() ?? '';
      _employeeNoCtrl.text = data['employeeNo']?.toString() ?? '';
      _designationCtrl.text = data['designation']?.toString() ?? '';
      _departmentCtrl.text = data['department']?.toString() ?? '';
      _dateOfJoiningCtrl.text = _fromIsoDate(data['dateOfJoining']?.toString()) ?? '';
      _nationalIdCtrl.text = data['nationalId']?.toString() ?? '';
      _pfNumberCtrl.text = data['pfNumber']?.toString() ?? '';
      _yearsOfExpCtrl.text = data['yearsOfExperience']?.toString() ?? '';
      _previousWorkplaceCtrl.text = data['previousWorkplace']?.toString() ?? '';
      _isActive = data['isActive'] ?? true;

      final salarySlip = data['salarySlip'];
      if (salarySlip != null) {
        _existingSalarySlip = EmployeeDocument.fromJson(salarySlip);
      }
      final employmentType = data['employmentType']?.toString();
      if (employmentType != null && _employmentOptions.contains(employmentType)) {
        _employmentType = employmentType;
      }

      final bank = data['bankDetails'];
      if (bank is Map) {
        _bankAccountNameCtrl.text = bank['accountName']?.toString() ?? '';
        _bankNameCtrl.text = bank['bankName']?.toString() ?? '';
        _accountNoCtrl.text = bank['accountNumber']?.toString() ?? '';
        _ifscCodeCtrl.text = bank['ifscCode']?.toString() ?? '';
      }

      final emg = data['emergencyContact'];
      if (emg is Map) {
        _emgNameCtrl.text = emg['name']?.toString() ?? '';
        _emgRelationCtrl.text = emg['relation']?.toString() ?? '';
        _emgPhoneCtrl.text = emg['phone']?.toString() ?? '';
      }

      final edu = data['educationDetails'];
      _education.clear();
      if (edu is List && edu.isNotEmpty) {
        for (final e in edu) {
          if (e is Map) _education.add(EducationEntry.fromJson(Map<String, dynamic>.from(e)));
        }
      } else {
        _education.add(EducationEntry());
      }

      final docs = data['documents'];
      _existingDocuments.clear();
      if (docs is List) {
        for (final d in docs) {
          final doc = EmployeeDocument.fromJson(d);
          if (doc != null) _existingDocuments.add(doc);
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null) {
      setState(() {
        _selectedFiles.addAll(result.paths.whereType<String>().map((p) => File(p)));
      });
    }
  }

  Future<void> _pickSalarySlip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _salarySlipFile = File(result.files.single.path!));
    }
  }

  Future<void> _deleteExistingDocument(EmployeeDocument doc) async {
    final schoolId = _resolvedSchoolId;
    if (schoolId == null || _userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Delete "${doc.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deletingDocId = doc.id);
    try {
      final resp = await _apiService.dio.delete(
        _EmployeeApi.deleteDocument(_userId!, doc.id),
        options: dio.Options(headers: {'x-school-id': schoolId}),
      );
      if (resp.data['ok'] == true) {
        setState(() {
          _existingDocuments.removeWhere((d) => d.id == doc.id);
          _deletingDocId = null;
        });
      } else {
        throw Exception(resp.data['message']?.toString() ?? 'Delete failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deletingDocId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete document: $e')),
        );
      }
    }
  }

  Future<String> _registerStaffUser(String schoolId) async {
    final resp = await _apiService.dio.post(
      ApiConstants.createUser,
      data: {
        'userName': _fullNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phoneNo': _phoneCtrl.text.trim(),
        'role': _selectedAccountRole,
        'password': _passwordCtrl.text,
        'schoolId': schoolId,
      },
      options: dio.Options(headers: {'x-school-id': schoolId}),
    );

    final data = resp.data;
    if (data is Map && (data['ok'] == true || data['success'] == true)) {
      final created = data['data'] ?? data['user'];
      final id = (created is Map ? (created['_id'] ?? created['id']) : null)?.toString();
      if (id != null && id.isNotEmpty) return id;
    }
    final msg = data is Map ? data['message']?.toString() : null;
    throw Exception(msg ?? 'Failed to register staff account');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final schoolId = _resolvedSchoolId;
    if (schoolId == null || schoolId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School information missing. Please log in again.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isNewStaff) {
        _userId = await _registerStaffUser(schoolId);
      }
      if (_userId == null || _userId!.trim().isEmpty) {
        throw Exception('No valid user id available to save this profile against.');
      }
      final bankDetails = {
        'accountName': _bankAccountNameCtrl.text.trim().isEmpty ? null : _bankAccountNameCtrl.text.trim(),
        'bankName': _bankNameCtrl.text.trim().isEmpty ? null : _bankNameCtrl.text.trim(),
        'accountNumber': _accountNoCtrl.text.trim().isEmpty ? null : _accountNoCtrl.text.trim(),
        'ifscCode': _ifscCodeCtrl.text.trim().isEmpty ? null : _ifscCodeCtrl.text.trim(),
      };

      final emergencyContact = {
        'name': _emgNameCtrl.text.trim().isEmpty ? null : _emgNameCtrl.text.trim(),
        'relation': _emgRelationCtrl.text.trim().isEmpty ? null : _emgRelationCtrl.text.trim(),
        'phone': _emgPhoneCtrl.text.trim().isEmpty ? null : _emgPhoneCtrl.text.trim(),
      };

      final educationDetails = _education
          .map((e) => e.toJson())
          .where((e) => e.values.any((v) => v != null))
          .toList();

      final fields = <String, dynamic>{
        'schoolId': schoolId,
        'currentAddress': _currentAddressCtrl.text.trim(),
        'permanentAddress': _permanentAddressCtrl.text.trim(),
        'employeeNo': _employeeNoCtrl.text.trim(),
        'designation': _designationCtrl.text.trim(),
        'department': _departmentCtrl.text.trim(),
        if (_isoDate(_dateOfJoiningCtrl.text) != null) 'dateOfJoining': _isoDate(_dateOfJoiningCtrl.text),
        'employmentType': _employmentType,
        'nationalId': _nationalIdCtrl.text.trim(),
        'pfNumber': _pfNumberCtrl.text.trim(),
        'yearsOfExperience': _yearsOfExpCtrl.text.trim(),
        'previousWorkplace': _previousWorkplaceCtrl.text.trim(),
        'isActive': _isActive.toString(),
        'bankDetails': jsonEncode(bankDetails),
        'emergencyContact': jsonEncode(emergencyContact),
        'educationDetails': jsonEncode(educationDetails),
      };

      final formData = dio.FormData.fromMap(fields);

      for (final file in _selectedFiles) {
        formData.files.add(MapEntry(
          'documents',
          await dio.MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
        ));
      }

      if (_salarySlipFile != null) {
        formData.files.add(MapEntry(
          'salarySlipFile',
          await dio.MultipartFile.fromFile(_salarySlipFile!.path, filename: _salarySlipFile!.path.split('/').last),
        ));
      }

      final response = await _apiService.dio.post(
        _EmployeeApi.upsert(_userId!),
        data: formData,
        options: dio.Options(headers: {'x-school-id': schoolId}),
      );

      final ok = response.data is Map && response.data['ok'] == true;
      if (ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employee profile saved successfully!')),
          );
          if (Navigator.canPop(context)) {
            Navigator.pop(context, true);
          }
        }
      } else {
        final msg = response.data is Map ? response.data['message']?.toString() : null;
        throw Exception(msg ?? 'Failed to save profile');
      }
    } on dio.DioException catch (e) {
      final msg = (e.response?.data is Map ? e.response!.data['message']?.toString() : null) ?? e.message;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $msg')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _buildInputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF374151)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildCardContainer({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          widget.isEdit ? 'Edit Employee Profile' : 'Add Staff',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _isFetching
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      // 1. Account Details
                      _buildCardContainer(
                        children: [
                          _buildSectionHeader(Icons.person_outline, 'Account Details'),
                          const SizedBox(height: 14),
                          if (_isNewStaff) ...[
                            _buildFieldLabel('Full Name *'),
                            TextFormField(
                              controller: _fullNameCtrl,
                              style: const TextStyle(fontSize: 13),
                              decoration: _buildInputDecoration(hintText: 'e.g. Rahul'),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 14),
                            _buildFieldLabel('Email Address *'),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(fontSize: 13),
                              decoration: _buildInputDecoration(hintText: 'name@school.com'),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 14),
                            _buildFieldLabel('Phone Number *'),
                            TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(fontSize: 13),
                              decoration: _buildInputDecoration(hintText: '10-digit mobile number'),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 14),
                            _buildFieldLabel('Assign Role *'),
                            DropdownButtonFormField<String>(
                              value: _selectedAccountRole,
                              icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF6B7280)),
                              decoration: _buildInputDecoration(hintText: 'Select Role'),
                              style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
                              items: _roleOptions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                              onChanged: (v) => setState(() => _selectedAccountRole = v),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 14),
                            _buildFieldLabel('Password *'),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              style: const TextStyle(fontSize: 13),
                              decoration: _buildInputDecoration(hintText: 'Enter password').copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18, color: const Color(0xFF6B7280)),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
                            ),
                          ] else ...[
                            _buildFieldLabel('Full Name'),
                            TextFormField(
                              controller: _fullNameCtrl,
                              readOnly: true,
                              style: const TextStyle(fontSize: 13),
                              decoration: _buildInputDecoration(),
                            ),
                            const SizedBox(height: 14),
                            _buildFieldLabel('Email Address'),
                            TextFormField(
                              controller: _emailCtrl,
                              readOnly: true,
                              style: const TextStyle(fontSize: 13),
                              decoration: _buildInputDecoration(),
                            ),
                            const SizedBox(height: 14),
                            _buildFieldLabel('Phone Number'),
                            TextFormField(
                              controller: _phoneCtrl,
                              readOnly: true,
                              style: const TextStyle(fontSize: 13),
                              decoration: _buildInputDecoration(),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 2. Personal Details
                      _buildCardContainer(
                        children: [
                          _buildSectionHeader(Icons.contact_mail_outlined, 'Personal Details'),
                          const SizedBox(height: 14),
                          _buildFieldLabel('Current Address'),
                          TextFormField(
                            controller: _currentAddressCtrl,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 13),
                            decoration: _buildInputDecoration(hintText: 'Enter current address'),
                          ),
                          const SizedBox(height: 14),
                          _buildFieldLabel('Permanent Address'),
                          TextFormField(
                            controller: _permanentAddressCtrl,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 13),
                            decoration: _buildInputDecoration(hintText: 'Enter permanent address'),
                          ),
                          const SizedBox(height: 14),
                          _buildFieldLabel('National ID'),
                          TextFormField(
                            controller: _nationalIdCtrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: _buildInputDecoration(hintText: 'Aadhaar / National ID No.'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 3. Work Details
                      _buildCardContainer(
                        children: [
                          _buildSectionHeader(Icons.work_outline, 'Work Details'),
                          const SizedBox(height: 14),
                          _buildFieldLabel('Employee Number *'),
                          TextFormField(
                            controller: _employeeNoCtrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: _buildInputDecoration(hintText: 'e.g. EMP-102'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 14),
                          _buildFieldLabel('Designation *'),
                          TextFormField(
                            controller: _designationCtrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: _buildInputDecoration(hintText: 'e.g. Senior Teacher'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 14),
                          _buildFieldLabel('Department'),
                          TextFormField(
                            controller: _departmentCtrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: _buildInputDecoration(hintText: 'e.g. Science'),
                          ),
                          const SizedBox(height: 14),
                          _buildFieldLabel('Date of Joining'),
                          InkWell(
                            onTap: () => _pickDate(_dateOfJoiningCtrl),
                            borderRadius: BorderRadius.circular(8),
                            child: InputDecorator(
                              decoration: _buildInputDecoration(hintText: 'DD/MM/YYYY'),
                              child: Text(
                                _dateOfJoiningCtrl.text.isEmpty ? 'Select Date' : _dateOfJoiningCtrl.text,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _dateOfJoiningCtrl.text.isEmpty ? const Color(0xFF9CA3AF) : const Color(0xFF1F2937),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildFieldLabel('Employment Type'),
                          DropdownButtonFormField<String>(
                            value: _employmentType,
                            icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF6B7280)),
                            decoration: _buildInputDecoration(),
                            style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
                            items: _employmentOptions
                                .map((v) => DropdownMenuItem(
                              value: v,
                              child: Text(v.toUpperCase(), style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937))),
                            ))
                                .toList(),
                            onChanged: (v) => setState(() => _employmentType = v!),
                          ),
                          const SizedBox(height: 14),
                          _buildFieldLabel('Years of Experience'),
                          TextFormField(
                            controller: _yearsOfExpCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 13),
                            decoration: _buildInputDecoration(hintText: 'e.g. 5'),
                          ),
                          const SizedBox(height: 14),
                          _buildFieldLabel('Previous Workplace'),
                          TextFormField(
                            controller: _previousWorkplaceCtrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: _buildInputDecoration(hintText: 'Previous School / Organization'),
                          ),
                          const SizedBox(height: 14),
                          _buildFieldLabel('PF Number'),
                          TextFormField(
                            controller: _pfNumberCtrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: _buildInputDecoration(hintText: 'Provident Fund No.'),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Active Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                              Switch(
                                value: _isActive,
                                activeColor: const Color(0xFF2563EB),
                                onChanged: (v) => setState(() => _isActive = v),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 4. Education Details
                      _buildCardContainer(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionHeader(Icons.school_outlined, 'Education Details'),
                              OutlinedButton.icon(
                                onPressed: () => setState(() => _education.add(EducationEntry())),
                                icon: const Icon(Icons.add, size: 16, color: Color(0xFF2563EB)),
                                label: const Text('Add Entry', style: TextStyle(color: Color(0xFF2563EB), fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF2563EB)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ..._education.asMap().entries.map((entry) {
                            final i = entry.key;
                            final e = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('ENTRY #${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF6B7280))),
                                      if (_education.length > 1)
                                        IconButton(
                                          icon: const Icon(Icons.close, size: 16, color: Color(0xFFEF4444)),
                                          onPressed: () => setState(() {
                                            e.dispose();
                                            _education.removeAt(i);
                                          }),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildFieldLabel('Degree'),
                                            TextFormField(
                                              controller: e.degreeCtrl,
                                              style: const TextStyle(fontSize: 13),
                                              decoration: _buildInputDecoration(hintText: 'e.g. B.Ed'),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildFieldLabel('Institution'),
                                            TextFormField(
                                              controller: e.institutionCtrl,
                                              style: const TextStyle(fontSize: 13),
                                              decoration: _buildInputDecoration(hintText: 'University Name'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildFieldLabel('Year of Passing'),
                                            TextFormField(
                                              controller: e.yearCtrl,
                                              keyboardType: TextInputType.number,
                                              style: const TextStyle(fontSize: 13),
                                              decoration: _buildInputDecoration(hintText: 'e.g. 2018'),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildFieldLabel('Grade / Class'),
                                            TextFormField(
                                              controller: e.gradeCtrl,
                                              style: const TextStyle(fontSize: 13),
                                              decoration: _buildInputDecoration(hintText: 'e.g. First Class'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 5. Bank Details
                      _buildCardContainer(
                        children: [
                          _buildSectionHeader(Icons.account_balance_outlined, 'Bank Details'),
                          const SizedBox(height: 14),
                          _buildFieldLabel('Account Holder Name'),
                          TextFormField(
                            controller: _bankAccountNameCtrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: _buildInputDecoration(hintText: 'As per bank records'),
                          ),
                          const SizedBox(height: 14),
                          _buildFieldLabel('Bank Name'),
                          TextFormField(
                            controller: _bankNameCtrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: _buildInputDecoration(hintText: 'e.g. State Bank of India'),
                          ),
                          const SizedBox(height: 14),
                          _buildFieldLabel('Account Number'),
                          TextFormField(
                            controller: _accountNoCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 13),
                            decoration: _buildInputDecoration(hintText: 'Account No.'),
                          ),
                          const SizedBox(height: 14),
                          _buildFieldLabel('IFSC Code'),
                          TextFormField(
                            controller: _ifscCodeCtrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: _buildInputDecoration(hintText: 'e.g. SBIN0001234'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 6. Emergency Contact
                      _buildCardContainer(
                        children: [
                          _buildSectionHeader(Icons.contact_phone_outlined, 'Emergency Contact'),
                          const SizedBox(height: 14),
                          _buildFieldLabel('Contact Person Name'),
                          TextFormField(
                            controller: _emgNameCtrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: _buildInputDecoration(hintText: 'Contact Name'),
                          ),
                          const SizedBox(height: 14),
                          _buildFieldLabel('Relation'),
                          TextFormField(
                            controller: _emgRelationCtrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: _buildInputDecoration(hintText: 'e.g. Spouse / Parent'),
                          ),
                          const SizedBox(height: 14),
                          _buildFieldLabel('Phone Number'),
                          TextFormField(
                            controller: _emgPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(fontSize: 13),
                            decoration: _buildInputDecoration(hintText: 'Mobile Number'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 7. Documents & Attachments
                      _buildCardContainer(
                        children: [
                          _buildSectionHeader(Icons.attach_file_outlined, 'Documents / Attachments'),
                          const SizedBox(height: 14),
                          if (_existingDocuments.isNotEmpty) ...[
                            ..._existingDocuments.map((doc) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.description_outlined, color: Color(0xFF2563EB), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(doc.name, style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
                                  ),
                                  if (_deletingDocId == doc.id)
                                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  else
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                                      onPressed: () => _deleteExistingDocument(doc),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                ],
                              ),
                            )),
                            const SizedBox(height: 8),
                          ],
                          OutlinedButton.icon(
                            onPressed: _pickDocuments,
                            icon: const Icon(Icons.file_upload_outlined, size: 16, color: Color(0xFF2563EB)),
                            label: const Text('Select Documents (PDF / Images)', style: TextStyle(color: Color(0xFF2563EB), fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF2563EB)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          if (_selectedFiles.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            ..._selectedFiles.asMap().entries.map((entry) {
                              final index = entry.key;
                              final file = entry.value;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.insert_drive_file_outlined, size: 16, color: Color(0xFF6B7280)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        file.path.split('/').last,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 16, color: Color(0xFFEF4444)),
                                      onPressed: () => setState(() => _selectedFiles.removeAt(index)),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 8. Salary Slip
                      _buildCardContainer(
                        children: [
                          _buildSectionHeader(Icons.receipt_long_outlined, 'Salary Slip'),
                          const SizedBox(height: 14),
                          if (_existingSalarySlip != null && _salarySlipFile == null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.receipt_outlined, color: Color(0xFF2563EB), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _existingSalarySlip!.name,
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: _pickSalarySlip,
                                icon: const Icon(Icons.upload_file_outlined, size: 16, color: Color(0xFF2563EB)),
                                label: Text(
                                  _salarySlipFile == null ? 'Upload Salary Slip' : 'Change File',
                                  style: const TextStyle(color: Color(0xFF2563EB), fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF2563EB)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              if (_salarySlipFile != null) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Color(0xFFEF4444), size: 18),
                                  onPressed: () => setState(() => _salarySlipFile = null),
                                ),
                              ],
                            ],
                          ),
                          if (_salarySlipFile != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _salarySlipFile!.path.split('/').last,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Action Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.maybePop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF374151),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                              : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.isEdit ? 'Update Profile' : 'Save & Upload',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
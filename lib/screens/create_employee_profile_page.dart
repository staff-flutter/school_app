import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart' hide Response;
import 'package:dio/dio.dart' as dio;
import 'package:school_app/constants/api_constants.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/school_controller.dart';
import '../../services/api_service.dart';

// =============================================================================
// API ROUTES  (move these into ApiConstants once you confirm naming there)
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

/// Mirrors `uploadSchema` on the server: {type, key, url, originalName, uploadedAt, _id}
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
  /// The user (staff member) this employee profile belongs to.
  /// Pass `null` to create a brand-new staff member from scratch (this page
  /// will then also collect Full Name / Email / Phone / Role / Password and
  /// register the user before saving the profile) — this is what "Add Staff"
  /// on the Staff Management page uses.
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

  /// The resolved user id for this profile. Null until a brand-new staff
  /// member has been registered (see `_registerStaffUser`).
  String? _userId;
  // 1. Harden the check so empty string is treated the same as null.
  bool get _isNewStaff => _userId == null || _userId!.trim().isEmpty;

  String? get _resolvedSchoolId {
    final id = widget.schoolId;
    if (id != null && id.isNotEmpty) return id;
    final role = _auth.user.value?.role?.toLowerCase() ?? '';
    if (role == 'correspondent') return _school.selectedSchool.value?.id;
    return _auth.user.value?.schoolId;
  }

  // ── Account / registration controllers (new staff only) ──────────────────
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  // TODO: replace with roles pulled from your roles API if available.
  static const List<String> _roleOptions = [
    'Teacher',
    'Principal',
    'Accountant',
    'Administrator',
    'Correspondent',
  ];
  String? _selectedAccountRole;

  // ── Text controllers matching schema fields directly ──────────────────────
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

  Future<void> _pickSalarySlip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _salarySlipFile = File(result.files.single.path!));
    }
  }

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

  // ── Date helpers (DD/MM/YYYY UI <-> ISO server) ────────────────────────────
  String? _isoDate(String? ddmmyyyy) {
    if (ddmmyyyy == null || ddmmyyyy.trim().isEmpty) return null;
    final parts = ddmmyyyy.split('/');
    if (parts.length != 3) return ddmmyyyy;
    return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
  }

  String? _fromIsoDate(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (v.contains('/')) return v;
    // Handles both "YYYY-MM-DD" and full ISO timestamps.
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

  // ── Load existing profile for edit mode (GET /get/:userId) ────────────────
  Future<void> _loadExistingProfile() async {
    if (_userId == null) return;
    setState(() => _isFetching = true);
    try {
      final res = await _apiService.get(_EmployeeApi.getOne(_userId!));
      final data = (res.data is Map && res.data['data'] is Map)
          ? Map<String, dynamic>.from(res.data['data'])
          : Map<String, dynamic>.from(res.data ?? {});

      // Basic account info, if the backend nests it under `user`.
      final user = data['user'];
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

  // ── File picking ────────────────────────────────────────────────────────
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

  // ── Register a brand-new staff user, returns the new user id ─────────────
  Future<String> _registerStaffUser(String schoolId) async {
    // ApiConstants.createUser = '/api/user/v1/create'
    final resp = await _apiService.dio.post(
      ApiConstants.createUser,
      data: {
        'userName': _fullNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
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

  // ── Submit (create or update) ──────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    print('_submit start: _userId="$_userId" isNewStaff=$_isNewStaff widget.userId="${widget.userId}" widget.isEdit=${widget.isEdit}');

    final schoolId = _resolvedSchoolId;
    if (schoolId == null || schoolId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School information missing. Please log in again.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step 1: if this is a brand-new staff member, register the user
      // account first so we have a userId to attach the profile to.
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
        // schoolId still useful to send in case the backend needs it on
        // first-time creation via upsert.
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

      // Documents — multiple, key: 'documents'
      for (final file in _selectedFiles) {
        formData.files.add(MapEntry(
          'documents',
          await dio.MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
        ));
      }

      // Salary slip — single file, key: 'salarySlipFile'
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
      print('DioException on ${e.requestOptions.method} ${e.requestOptions.uri}');
      print('Response: ${e.response?.statusCode} ${e.response?.data}');
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

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? 'Edit Employee Profile' : 'Add Staff')),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Account Details'),
              if (_isNewStaff) ...[
                TextFormField(
                  controller: _fullNameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name *', hintText: 'e.g. Rahul'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email Address *', hintText: 'name@school.com'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone Number *', hintText: '10-digit mobile number'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                DropdownButtonFormField<String>(
                  value: _selectedAccountRole,
                  decoration: const InputDecoration(labelText: 'Assign Role *'),
                  items: _roleOptions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setState(() => _selectedAccountRole = v),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    hintText: 'Enter password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
                ),
              ] else ...[
                // Editing an existing staff member — account fields are
                // read-only here; wire up a separate "Edit Account" call if
                // you want to allow changing name/email/role after creation.
                TextFormField(
                  controller: _fullNameCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                TextFormField(
                  controller: _emailCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                ),
                TextFormField(
                  controller: _phoneCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
              ],

              const SizedBox(height: 24),
              _buildSectionHeader('Personal Details'),
              TextFormField(controller: _currentAddressCtrl, decoration: const InputDecoration(labelText: 'Current Address'), maxLines: 2),
              TextFormField(controller: _permanentAddressCtrl, decoration: const InputDecoration(labelText: 'Permanent Address'), maxLines: 2),
              TextFormField(controller: _nationalIdCtrl, decoration: const InputDecoration(labelText: 'National ID')),

              const SizedBox(height: 24),
              _buildSectionHeader('Work Details'),
              TextFormField(
                controller: _employeeNoCtrl,
                decoration: const InputDecoration(labelText: 'Employee Number *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _designationCtrl,
                decoration: const InputDecoration(labelText: 'Designation *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(controller: _departmentCtrl, decoration: const InputDecoration(labelText: 'Department')),
              TextFormField(
                controller: _dateOfJoiningCtrl,
                readOnly: true,
                onTap: () => _pickDate(_dateOfJoiningCtrl),
                decoration: const InputDecoration(labelText: 'Date of Joining', hintText: 'DD/MM/YYYY'),
              ),
              DropdownButtonFormField<String>(
                value: _employmentType,
                decoration: const InputDecoration(labelText: 'Employment Type'),
                items: _employmentOptions.map((v) => DropdownMenuItem(value: v, child: Text(v.toUpperCase()))).toList(),
                onChanged: (v) => setState(() => _employmentType = v!),
              ),
              TextFormField(controller: _yearsOfExpCtrl, decoration: const InputDecoration(labelText: 'Years of Experience'), keyboardType: TextInputType.number),
              TextFormField(controller: _previousWorkplaceCtrl, decoration: const InputDecoration(labelText: 'Previous Workplace')),
              TextFormField(controller: _pfNumberCtrl, decoration: const InputDecoration(labelText: 'PF Number')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),

              const SizedBox(height: 24),
              _buildSectionHeaderWithAction(
                'Education Details',
                onAdd: () => setState(() => _education.add(EducationEntry())),
              ),
              ..._education.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text('Entry ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600))),
                              if (_education.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => setState(() {
                                    e.dispose();
                                    _education.removeAt(i);
                                  }),
                                ),
                            ],
                          ),
                          TextFormField(controller: e.degreeCtrl, decoration: const InputDecoration(labelText: 'Degree')),
                          TextFormField(controller: e.institutionCtrl, decoration: const InputDecoration(labelText: 'Institution')),
                          TextFormField(controller: e.yearCtrl, decoration: const InputDecoration(labelText: 'Year of Passing')),
                          TextFormField(controller: e.gradeCtrl, decoration: const InputDecoration(labelText: 'Grade')),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),
              _buildSectionHeader('Bank Details'),
              TextFormField(controller: _bankAccountNameCtrl, decoration: const InputDecoration(labelText: 'Account Holder Name')),
              TextFormField(controller: _bankNameCtrl, decoration: const InputDecoration(labelText: 'Bank Name')),
              TextFormField(controller: _accountNoCtrl, decoration: const InputDecoration(labelText: 'Account Number')),
              TextFormField(controller: _ifscCodeCtrl, decoration: const InputDecoration(labelText: 'IFSC Code')),

              const SizedBox(height: 24),
              _buildSectionHeader('Emergency Contact'),
              TextFormField(controller: _emgNameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextFormField(controller: _emgRelationCtrl, decoration: const InputDecoration(labelText: 'Relation')),
              TextFormField(controller: _emgPhoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),

              const SizedBox(height: 24),
              _buildSectionHeader('Documents / Attachments'),
              if (_existingDocuments.isNotEmpty) ...[
                ..._existingDocuments.map((doc) => ListTile(
                  leading: const Icon(Icons.description, color: Colors.blue),
                  title: Text(doc.name),
                  trailing: _deletingDocId == doc.id
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteExistingDocument(doc),
                  ),
                )),
                const Divider(),
              ],
              ElevatedButton.icon(
                onPressed: _pickDocuments,
                icon: const Icon(Icons.attach_file),
                label: const Text('Select Documents (PDF / Images)'),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedFiles.length,
                itemBuilder: (context, index) => ListTile(
                  leading: const Icon(Icons.description, color: Colors.blue),
                  title: Text(_selectedFiles[index].path.split('/').last),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _selectedFiles.removeAt(index)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Salary Slip'),
              if (_existingSalarySlip != null && _salarySlipFile == null)
                ListTile(
                  leading: const Icon(Icons.receipt_long, color: Colors.blue),
                  title: Text(_existingSalarySlip!.name),
                  subtitle: const Text('Current salary slip'),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickSalarySlip,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_salarySlipFile == null ? 'Upload Salary Slip' : 'Change File'),
                    ),
                  ),
                  if (_salarySlipFile != null)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => setState(() => _salarySlipFile = null),
                    ),
                ],
              ),
              if (_salarySlipFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_salarySlipFile!.path.split('/').last, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(widget.isEdit ? 'Update Profile' : 'Save & Upload to Server',
                      style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
  );

  Widget _buildSectionHeaderWithAction(String title, {required VoidCallback onAdd}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey))),
        IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.blue), onPressed: onAdd),
      ],
    ),
  );
}
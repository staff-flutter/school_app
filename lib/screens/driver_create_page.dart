import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/transport_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';

/// Full-page "Register New Driver" / "Edit Driver" form — matches the web
/// dashboard's Driver Photo / Personal Details / Statutory Documents layout,
/// adapted to a scrollable mobile page.
///
/// Pass `driver` (the full driver map, e.g. from `currentDriver.value` or a
/// directory row) to switch into edit mode: fields are pre-filled and Save
/// calls `updateDriver` instead of `createDriver`.
///
/// Pop with `true` on success so the caller (Driver Directory / Profile)
/// knows to refresh.
///
/// NOTE: requires the `file_picker` package in pubspec.yaml.
class DriverCreateScreen extends StatefulWidget {
  final Map<String, dynamic>? driver;

  const DriverCreateScreen({super.key, this.driver});

  @override
  State<DriverCreateScreen> createState() => _DriverCreateScreenState();
}

class _DriverDocumentDraft {
  final TextEditingController detailController = TextEditingController();
  DateTime? expiryDate;
  List<PlatformFile> files = [];

  // Populated in edit mode when this document already exists on the driver.
  String? documentId;
  List<Map<String, dynamic>> existingFiles = [];

  bool get hasData =>
      detailController.text.trim().isNotEmpty || expiryDate != null || files.isNotEmpty;

  void dispose() => detailController.dispose();
}

class _DriverCreateScreenState extends State<DriverCreateScreen> {
  static const List<String> _allowedDocumentNames = [
    'Driving License',
    'Badge',
    'Police Verification',
    'Medical Certificate',
    'Aadhar Card',
    'Other',
  ];

  static const List<String> _statusOptions = ['active', 'inactive', 'on_leave'];

  final TransportController _controller = Get.find();
  final AuthController _authController = Get.find();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _dateOfBirth;
  DateTime? _joinedDate;
  String? _status = 'active';
  String? _assignedBusId;
  String? _assignedBusLabel;
  PlatformFile? _photo;
  String? _existingPhotoUrl;
  bool _submitting = false;

  late final Map<String, _DriverDocumentDraft> _documentDrafts = {
    for (final name in _allowedDocumentNames) name: _DriverDocumentDraft(),
  };

  bool get _isEditMode => widget.driver != null;

  SchoolController? get _school =>
      Get.isRegistered<SchoolController>() ? Get.find<SchoolController>() : null;

  // Same role-aware resolution as the Driver Directory: correspondents are
  // scoped to whichever school they've currently selected; every other role
  // is scoped to the single school on their own profile.
  String? get _schoolId {
    final role = _authController.user.value?.role?.toLowerCase() ?? '';
    if (role == 'correspondent') {
      return _school?.selectedSchool.value?.id;
    }
    return _authController.user.value?.schoolId;
  }

  @override
  void initState() {
    super.initState();
    if (_isEditMode) _prefillFromDriver(widget.driver!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_schoolId != null) _controller.getBusDropdown(_schoolId!);
    });
  }

  void _prefillFromDriver(Map<String, dynamic> driver) {
    _nameController.text = driver['name']?.toString() ?? '';
    _phoneController.text = driver['phone']?.toString() ?? '';
    _emergencyContactController.text = driver['emergencyContact']?.toString() ?? '';
    _addressController.text = driver['address']?.toString() ?? '';
    _status = driver['status']?.toString() ?? 'active';

    _dateOfBirth = DateTime.tryParse(driver['dateOfBirth']?.toString() ?? '');
    _joinedDate = DateTime.tryParse(driver['joinedDate']?.toString() ?? '');

    final assignedBus = driver['assignedBusId'];
    if (assignedBus is Map) {
      _assignedBusId = assignedBus['_id']?.toString();
      _assignedBusLabel = (assignedBus['busNumber'] ?? assignedBus['registrationNo'])?.toString();
    } else if (assignedBus != null) {
      _assignedBusId = assignedBus.toString();
    }

    final photo = driver['photo'];
    if (photo is Map && photo['url'] != null) {
      _existingPhotoUrl = photo['url'].toString();
    }

    final documents = (driver['documents'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (final doc in documents) {
      final name = doc['documentName']?.toString();
      final draft = _documentDrafts[name];
      if (draft == null) continue; // unknown/legacy document name, skip
      draft.documentId = doc['_id']?.toString();
      draft.detailController.text = doc['detail']?.toString() ?? '';
      draft.expiryDate = DateTime.tryParse(doc['expiryDate']?.toString() ?? '');
      draft.existingFiles = (doc['files'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emergencyContactController.dispose();
    _addressController.dispose();
    for (final d in _documentDrafts.values) {
      d.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _photo = result.files.first);
    }
  }

  Future<void> _pickDocumentFiles(String documentName) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _documentDrafts[documentName]!.files.addAll(result.files));
    }
  }

  Future<void> _pickDate({required bool isDob}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isDob) {
        _dateOfBirth = picked;
      } else {
        _joinedDate = picked;
      }
    });
  }

  Future<void> _pickDocumentExpiry(String documentName) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _documentDrafts[documentName]!.expiryDate = picked);
    }
  }

  void _openAssignedBusSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Assign Bus', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const Divider(height: 20),
                Obx(() {
                  final buses = _controller.busDropdown;
                  if (buses.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('No buses available'),
                    );
                  }
                  return ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                    child: ListView(
                      shrinkWrap: true,
                      children: buses.map((bus) {
                        final id = bus['_id']?.toString();
                        final label = (bus['busNumber'] ?? bus['registrationNo'] ?? 'Bus').toString();
                        return ListTile(
                          title: Text(label),
                          trailing: _assignedBusId == id ? const Icon(Icons.check, color: Colors.black87) : null,
                          onTap: () {
                            setState(() {
                              _assignedBusId = id;
                              _assignedBusLabel = label;
                            });
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEditMode && _schoolId == null) return;

    setState(() => _submitting = true);

    final documents = <Map<String, dynamic>>[];
    final documentFiles = <int, List<File>>{};
    int idx = 0;
    for (final name in _allowedDocumentNames) {
      final draft = _documentDrafts[name]!;
      // Include this document if the user entered/changed anything, OR it
      // already existed on the driver (so we don't silently drop it).
      if (!draft.hasData && draft.documentId == null) continue;
      documents.add({
        if (draft.documentId != null) '_id': draft.documentId,
        'documentName': name,
        if (draft.detailController.text.trim().isNotEmpty) 'detail': draft.detailController.text.trim(),
        if (draft.expiryDate != null) 'expiryDate': draft.expiryDate!.toIso8601String(),
      });
      if (draft.files.isNotEmpty) {
        documentFiles[idx] = draft.files
            .where((f) => f.path != null)
            .map((f) => File(f.path!))
            .toList();
      }
      idx++;
    }

    final photoFile = _photo?.path != null ? File(_photo!.path!) : null;

    final ok = _isEditMode
        ? await _controller.updateDriver(
      id: widget.driver!['_id'].toString(),
      name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      assignedBusId: _assignedBusId,
      dateOfBirth: _dateOfBirth?.toIso8601String(),
      joinedDate: _joinedDate?.toIso8601String(),
      emergencyContact: _emergencyContactController.text.trim().isEmpty
          ? null
          : _emergencyContactController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      status: _status,
      photo: photoFile,
      documents: documents.isEmpty ? null : documents,
      documentFiles: documentFiles.isEmpty ? null : documentFiles,
    )
        : await _controller.createDriver(
      schoolId: _schoolId!,
      name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      assignedBusId: _assignedBusId,
      dateOfBirth: _dateOfBirth?.toIso8601String(),
      joinedDate: _joinedDate?.toIso8601String(),
      emergencyContact: _emergencyContactController.text.trim().isEmpty
          ? null
          : _emergencyContactController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      photo: photoFile,
      documents: documents.isEmpty ? null : documents,
      documentFiles: documentFiles.isEmpty ? null : documentFiles,
    );

    setState(() => _submitting = false);
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
        title: Text(_isEditMode ? 'Edit Driver' : 'Register New Driver',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _SectionCard(
              title: 'Driver Photo',
              icon: Icons.image_outlined,
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: _pickPhoto,
                    child: const Text('Choose File'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _photo?.name ??
                          (_existingPhotoUrl != null ? 'Current photo on file (tap Choose File to replace)' : 'No file chosen'),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Personal Details',
              icon: Icons.person_outline,
              child: Column(
                children: [
                  _LabeledField(
                    label: 'Full Name *',
                    child: TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('Enter driver\'s name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                    ),
                  ),
                  _LabeledField(
                    label: 'Phone Number',
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('10-digit number'),
                    ),
                  ),
                  _LabeledField(
                    label: 'Date of Birth',
                    child: _DateField(
                      value: _dateOfBirth,
                      onTap: () => _pickDate(isDob: true),
                    ),
                  ),
                  _LabeledField(
                    label: 'Joining Date',
                    child: _DateField(
                      value: _joinedDate,
                      onTap: () => _pickDate(isDob: false),
                    ),
                  ),
                  _LabeledField(
                    label: 'Emergency Contact',
                    child: TextFormField(
                      controller: _emergencyContactController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('10-digit number'),
                    ),
                  ),
                  _LabeledField(
                    label: 'Assigned Bus',
                    child: InkWell(
                      onTap: _openAssignedBusSheet,
                      child: InputDecorator(
                        decoration: _inputDecoration(_assignedBusLabel ?? 'Search & Assign Bus...').copyWith(
                          suffixIcon: const Icon(Icons.keyboard_arrow_down),
                        ),
                        child: Text(_assignedBusLabel ?? 'Search & Assign Bus...',
                            style: TextStyle(
                                color: _assignedBusLabel == null ? Colors.grey.shade500 : Colors.black87)),
                      ),
                    ),
                  ),
                  _LabeledField(
                    label: 'Status',
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: _inputDecoration('Status Options...'),
                      items: _statusOptions
                          .map((s) => DropdownMenuItem(value: s, child: Text(_statusLabel(s))))
                          .toList(),
                      onChanged: (v) => setState(() => _status = v),
                    ),
                  ),
                  _LabeledField(
                    label: 'Address',
                    child: TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: _inputDecoration('Enter full address...'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Statutory Documents',
              icon: Icons.folder_open_outlined,
              child: Column(
                children: _allowedDocumentNames.map((name) {
                  final draft = _documentDrafts[name]!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 8),
                        _LabeledField(
                          label: 'Details / Remarks',
                          child: TextFormField(
                            controller: draft.detailController,
                            decoration: _inputDecoration('e.g., ID No: XXXX'),
                          ),
                        ),
                        _LabeledField(
                          label: 'Expiry Date',
                          child: _DateField(
                            value: draft.expiryDate,
                            onTap: () => _pickDocumentExpiry(name),
                          ),
                        ),
                        _LabeledField(
                          label: 'Upload Files',
                          child: Row(
                            children: [
                              OutlinedButton(
                                onPressed: () => _pickDocumentFiles(name),
                                child: const Text('Choose Files'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  draft.files.isEmpty ? 'No new files chosen' : '${draft.files.length} new file(s) selected',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (draft.existingFiles.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: draft.existingFiles.map((f) {
                                final label = f['originalName']?.toString() ?? 'file';
                                return Chip(
                                  avatar: const Icon(Icons.attach_file, size: 14),
                                  label: Text('Already attached: $label', style: const TextStyle(fontSize: 11)),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                );
                              }).toList(),
                            ),
                          ),
                        const Divider(height: 24),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Text(_isEditMode ? 'Update Driver' : 'Save Driver'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  String _statusLabel(String value) {
    switch (value) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'on_leave':
        return 'On Leave';
      default:
        return value;
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.black54),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final DateTime? value;
  final VoidCallback onTap;

  const _DateField({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = value != null ? DateFormat('dd-MM-yyyy').format(value!) : 'dd-mm-yyyy';
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: value == null ? Colors.grey.shade500 : Colors.black87)),
            const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}
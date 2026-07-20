import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/transport_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';

/// Full-page "Register New Bus" / "Edit Bus" form — matches the web
/// dashboard's Vehicle Specifications / Ownership & Maintenance / Statutory
/// Documents layout, adapted to a scrollable mobile page.
///
/// Pass `bus` (the full bus map, e.g. from `currentBus.value` or a
/// directory row) to switch into edit mode: fields are pre-filled and Save
/// calls `updateBus` instead of `createBus`.
///
/// Pop with `true` on success so the caller (Fleet Directory / Bus Details)
/// knows to refresh.
///
/// NOTE: requires the `file_picker` package in pubspec.yaml.
class BusCreateScreen extends StatefulWidget {
  final Map<String, dynamic>? bus;

  const BusCreateScreen({super.key, this.bus});

  @override
  State<BusCreateScreen> createState() => _BusCreateScreenState();
}

class _BusDocumentDraft {
  final TextEditingController costController = TextEditingController();
  DateTime? expiryDate;
  List<PlatformFile> files = [];

  // Populated in edit mode when this document already exists on the bus.
  String? documentId;
  List<Map<String, dynamic>> existingFiles = [];

  bool get hasData => costController.text.trim().isNotEmpty || expiryDate != null || files.isNotEmpty;

  void dispose() => costController.dispose();
}

class _BusCreateScreenState extends State<BusCreateScreen> {
  static const List<String> _allowedDocumentNames = ['FC', 'Insurance', 'Permit', 'Pollution', 'Road Tax'];
  static const List<String> _statusOptions = ['active', 'in_service', 'on_trip', 'inactive'];
  static const List<String> _fuelTypeOptions = ['Diesel', 'Petrol', 'CNG', 'Electric'];

  final TransportController _controller = Get.find();
  final AuthController _authController = Get.find();
  final _formKey = GlobalKey<FormState>();

  final _registrationNoController = TextEditingController();
  final _busNumberController = TextEditingController();
  final _makeModelController = TextEditingController();
  final _yearController = TextEditingController();
  final _seatingCapacityController = TextEditingController();
  final _chassisNoController = TextEditingController();
  final _engineNoController = TextEditingController();
  final _rcOwnerController = TextEditingController();

  String? _operationalStatus = 'active';
  String? _fuelType;
  String? _assignedDriverId;
  String? _assignedDriverLabel;
  DateTime? _purchaseDate;
  DateTime? _lastServiceDate;
  DateTime? _nextServiceDate;
  bool _submitting = false;

  late final Map<String, _BusDocumentDraft> _documentDrafts = {
    for (final name in _allowedDocumentNames) name: _BusDocumentDraft(),
  };

  bool get _isEditMode => widget.bus != null;

  SchoolController? get _school =>
      Get.isRegistered<SchoolController>() ? Get.find<SchoolController>() : null;

  // Same role-aware resolution as the Fleet Directory: correspondents are
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
    if (_isEditMode) _prefillFromBus(widget.bus!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_schoolId != null) _controller.getDriverDropdown(_schoolId!);
    });
  }

  void _prefillFromBus(Map<String, dynamic> bus) {
    _registrationNoController.text = bus['registrationNo']?.toString() ?? '';
    _busNumberController.text = bus['busNumber']?.toString() ?? '';
    _makeModelController.text = bus['makeModel']?.toString() ?? '';
    _yearController.text = bus['year']?.toString() ?? '';
    _seatingCapacityController.text = bus['seatingCapacity']?.toString() ?? '';
    _chassisNoController.text = bus['chassisNo']?.toString() ?? '';
    _engineNoController.text = bus['engineNo']?.toString() ?? '';
    _rcOwnerController.text = bus['rcOwner']?.toString() ?? '';
    _operationalStatus = bus['operationalStatus']?.toString() ?? 'active';
    _fuelType = bus['fuelType']?.toString().isNotEmpty == true ? bus['fuelType'].toString() : null;

    _purchaseDate = DateTime.tryParse(bus['purchaseDate']?.toString() ?? '');
    _lastServiceDate = DateTime.tryParse(bus['lastServiceDate']?.toString() ?? '');
    _nextServiceDate = DateTime.tryParse(bus['nextServiceDate']?.toString() ?? '');

    final assignedDriver = bus['assignedDriverId'];
    if (assignedDriver is Map) {
      _assignedDriverId = assignedDriver['_id']?.toString();
      _assignedDriverLabel = assignedDriver['name']?.toString();
    } else if (assignedDriver != null) {
      _assignedDriverId = assignedDriver.toString();
    }

    final documents = (bus['statutoryDocuments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (final doc in documents) {
      final name = doc['documentName']?.toString();
      final draft = _documentDrafts[name];
      if (draft == null) continue; // unknown/legacy document name, skip
      draft.documentId = doc['_id']?.toString();
      final cost = doc['lastCost'];
      draft.costController.text = (cost == null || cost == 0) ? '' : cost.toString();
      draft.expiryDate = DateTime.tryParse(doc['expiry']?.toString() ?? '');
      draft.existingFiles = (doc['files'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    }
  }

  @override
  void dispose() {
    _registrationNoController.dispose();
    _busNumberController.dispose();
    _makeModelController.dispose();
    _yearController.dispose();
    _seatingCapacityController.dispose();
    _chassisNoController.dispose();
    _engineNoController.dispose();
    _rcOwnerController.dispose();
    for (final d in _documentDrafts.values) {
      d.dispose();
    }
    super.dispose();
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

  Future<void> _pickDate({required void Function(DateTime) onPicked, DateTime? initial}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => onPicked(picked));
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

  void _openAssignedDriverSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Assign Driver', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const Divider(height: 20),
                Obx(() {
                  final drivers = _controller.driverDropdown;
                  if (drivers.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('No drivers available'),
                    );
                  }
                  return ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                    child: ListView(
                      shrinkWrap: true,
                      children: drivers.map((driver) {
                        final id = driver['_id']?.toString();
                        final label = driver['name']?.toString() ?? 'Driver';
                        return ListTile(
                          title: Text(label),
                          trailing: _assignedDriverId == id ? const Icon(Icons.check, color: Colors.black87) : null,
                          onTap: () {
                            setState(() {
                              _assignedDriverId = id;
                              _assignedDriverLabel = label;
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

  void _openFuelTypeSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Fuel Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const Divider(height: 20),
                ..._fuelTypeOptions.map((option) {
                  return ListTile(
                    title: Text(option),
                    trailing: _fuelType == option ? const Icon(Icons.check, color: Colors.black87) : null,
                    onTap: () {
                      setState(() => _fuelType = option);
                      Navigator.pop(context);
                    },
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

    final statutoryDocuments = <Map<String, dynamic>>[];
    final statutoryDocumentFiles = <int, List<File>>{};
    int idx = 0;
    for (final name in _allowedDocumentNames) {
      final draft = _documentDrafts[name]!;
      // Include if the user entered/changed anything, OR it already existed
      // on the bus (so we don't silently drop it).
      if (!draft.hasData && draft.documentId == null) continue;
      statutoryDocuments.add({
        if (draft.documentId != null) '_id': draft.documentId,
        'documentName': name,
        if (draft.costController.text.trim().isNotEmpty)
          'lastCost': double.tryParse(draft.costController.text.trim()) ?? 0,
        if (draft.expiryDate != null) 'expiry': draft.expiryDate!.toIso8601String(),
      });
      if (draft.files.isNotEmpty) {
        statutoryDocumentFiles[idx] =
            draft.files.where((f) => f.path != null).map((f) => File(f.path!)).toList();
      }
      idx++;
    }

    final year = int.tryParse(_yearController.text.trim());
    final seatingCapacity = int.tryParse(_seatingCapacityController.text.trim());

    final ok = _isEditMode
        ? await _controller.updateBus(
      id: widget.bus!['_id'].toString(),
      busNumber: _busNumberController.text.trim().isEmpty ? null : _busNumberController.text.trim(),
      registrationNo:
      _registrationNoController.text.trim().isEmpty ? null : _registrationNoController.text.trim(),
      makeModel: _makeModelController.text.trim().isEmpty ? null : _makeModelController.text.trim(),
      year: year,
      seatingCapacity: seatingCapacity,
      fuelType: _fuelType,
      chassisNo: _chassisNoController.text.trim().isEmpty ? null : _chassisNoController.text.trim(),
      engineNo: _engineNoController.text.trim().isEmpty ? null : _engineNoController.text.trim(),
      purchaseDate: _purchaseDate?.toIso8601String(),
      rcOwner: _rcOwnerController.text.trim().isEmpty ? null : _rcOwnerController.text.trim(),
      nextServiceDate: _nextServiceDate?.toIso8601String(),
      lastServiceDate: _lastServiceDate?.toIso8601String(),
      assignedDriverId: _assignedDriverId,
      operationalStatus: _operationalStatus,
      statutoryDocuments: statutoryDocuments.isEmpty ? null : statutoryDocuments,
      statutoryDocumentFiles: statutoryDocumentFiles.isEmpty ? null : statutoryDocumentFiles,
    )
        : await _controller.createBus(
      schoolId: _schoolId!,
      busNumber: _busNumberController.text.trim().isEmpty ? null : _busNumberController.text.trim(),
      registrationNo:
      _registrationNoController.text.trim().isEmpty ? null : _registrationNoController.text.trim(),
      makeModel: _makeModelController.text.trim().isEmpty ? null : _makeModelController.text.trim(),
      year: year,
      seatingCapacity: seatingCapacity,
      fuelType: _fuelType,
      chassisNo: _chassisNoController.text.trim().isEmpty ? null : _chassisNoController.text.trim(),
      engineNo: _engineNoController.text.trim().isEmpty ? null : _engineNoController.text.trim(),
      purchaseDate: _purchaseDate?.toIso8601String(),
      rcOwner: _rcOwnerController.text.trim().isEmpty ? null : _rcOwnerController.text.trim(),
      nextServiceDate: _nextServiceDate?.toIso8601String(),
      lastServiceDate: _lastServiceDate?.toIso8601String(),
      assignedDriverId: _assignedDriverId,
      operationalStatus: _operationalStatus,
      statutoryDocuments: statutoryDocuments.isEmpty ? null : statutoryDocuments,
      statutoryDocumentFiles: statutoryDocumentFiles.isEmpty ? null : statutoryDocumentFiles,
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
        title: Text(_isEditMode ? 'Edit Bus' : 'Register New Bus',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _SectionCard(
              title: 'Vehicle Specifications',
              icon: Icons.directions_bus_outlined,
              child: Column(
                children: [
                  _LabeledField(
                    label: 'Registration No *',
                    child: TextFormField(
                      controller: _registrationNoController,
                      decoration: _inputDecoration('e.g. TN-00-A-0000'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Registration number is required' : null,
                    ),
                  ),
                  _LabeledField(
                    label: 'Internal Bus No',
                    child: TextFormField(
                      controller: _busNumberController,
                      decoration: _inputDecoration('e.g. BUS-01'),
                    ),
                  ),
                  _LabeledField(
                    label: 'Operational Status',
                    child: DropdownButtonFormField<String>(
                      value: _operationalStatus,
                      decoration: _inputDecoration('Status'),
                      items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(_statusLabel(s)))).toList(),
                      onChanged: (v) => setState(() => _operationalStatus = v),
                    ),
                  ),
                  _LabeledField(
                    label: 'Make & Model',
                    child: TextFormField(
                      controller: _makeModelController,
                      decoration: _inputDecoration('e.g. Tata Marcopolo'),
                    ),
                  ),
                  _LabeledField(
                    label: 'Manufacture Year',
                    child: TextFormField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('e.g. 2022'),
                    ),
                  ),
                  _LabeledField(
                    label: 'Fuel Type',
                    child: InkWell(
                      onTap: _openFuelTypeSheet,
                      child: InputDecorator(
                        decoration: _inputDecoration(_fuelType ?? 'Select Fuel Type').copyWith(
                          suffixIcon: const Icon(Icons.keyboard_arrow_down),
                        ),
                        child: Text(_fuelType ?? 'Select Fuel Type',
                            style: TextStyle(color: _fuelType == null ? Colors.grey.shade500 : Colors.black87)),
                      ),
                    ),
                  ),
                  _LabeledField(
                    label: 'Seating Capacity',
                    child: TextFormField(
                      controller: _seatingCapacityController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('e.g. 40'),
                    ),
                  ),
                  _LabeledField(
                    label: 'Chassis No',
                    child: TextFormField(
                      controller: _chassisNoController,
                      decoration: _inputDecoration('Enter Chassis Number'),
                    ),
                  ),
                  _LabeledField(
                    label: 'Engine No',
                    child: TextFormField(
                      controller: _engineNoController,
                      decoration: _inputDecoration('Enter Engine Number'),
                    ),
                  ),
                  _LabeledField(
                    label: 'Assigned Driver',
                    child: InkWell(
                      onTap: _openAssignedDriverSheet,
                      child: InputDecorator(
                        decoration: _inputDecoration(_assignedDriverLabel ?? 'Search & Select Driver...').copyWith(
                          suffixIcon: const Icon(Icons.keyboard_arrow_down),
                        ),
                        child: Text(_assignedDriverLabel ?? 'Search & Select Driver...',
                            style: TextStyle(
                                color: _assignedDriverLabel == null ? Colors.grey.shade500 : Colors.black87)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Ownership & Maintenance',
              icon: Icons.build_outlined,
              child: Column(
                children: [
                  _LabeledField(
                    label: 'RC Owner Name',
                    child: TextFormField(
                      controller: _rcOwnerController,
                      decoration: _inputDecoration('Name on Registration'),
                    ),
                  ),
                  _LabeledField(
                    label: 'Purchase Date',
                    child: _DateField(
                      value: _purchaseDate,
                      onTap: () => _pickDate(initial: _purchaseDate, onPicked: (d) => _purchaseDate = d),
                    ),
                  ),
                  _LabeledField(
                    label: 'Last Service Date',
                    child: _DateField(
                      value: _lastServiceDate,
                      onTap: () => _pickDate(initial: _lastServiceDate, onPicked: (d) => _lastServiceDate = d),
                    ),
                  ),
                  _LabeledField(
                    label: 'Next Service Date',
                    child: _DateField(
                      value: _nextServiceDate,
                      onTap: () => _pickDate(initial: _nextServiceDate, onPicked: (d) => _nextServiceDate = d),
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
                          label: 'Cost (₹)',
                          child: TextFormField(
                            controller: draft.costController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _inputDecoration('e.g. 5000'),
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
                        const Text('PDF or images', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                      : Text(_isEditMode ? 'Update Bus' : 'Register Bus'),
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
      case 'in_service':
        return 'In Service';
      case 'on_trip':
        return 'On Trip';
      case 'inactive':
        return 'Inactive';
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
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
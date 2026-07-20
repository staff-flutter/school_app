import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/transport_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/core/utils/academic_year_utils.dart';

/// Full-page "Create Daily Trip Log" / "Edit Trip Log" form — matches the
/// web dashboard's "Trip Information" panel (Assigned Bus, Trip Date,
/// Opening/Closing Odometer, Trip Notes), adapted to a scrollable mobile
/// page.
///
/// Pass `tripLog` (the full trip log map) to switch into edit mode: fields
/// are pre-filled and Save calls `updateDailyTripLog` instead of
/// `createDailyTripLog`.
///
/// Pop with `true` on success so the caller (Directory / Details) knows to
/// refresh.
class DailyTripLogCreateScreen extends StatefulWidget {
  final Map<String, dynamic>? tripLog;

  const DailyTripLogCreateScreen({super.key, this.tripLog});

  @override
  State<DailyTripLogCreateScreen> createState() => _DailyTripLogCreateScreenState();
}

class _DailyTripLogCreateScreenState extends State<DailyTripLogCreateScreen> {
  final TransportController _controller = Get.find();
  final AuthController _authController = Get.find();
  final _formKey = GlobalKey<FormState>();

  final _openingOdometerController = TextEditingController();
  final _closingOdometerController = TextEditingController();
  final _notesController = TextEditingController();

  String? _assignedBusId;
  String? _assignedBusLabel;
  DateTime _tripDate = DateTime.now();
  bool _submitting = false;

  bool get _isEditMode => widget.tripLog != null;

  SchoolController? get _school =>
      Get.isRegistered<SchoolController>() ? Get.find<SchoolController>() : null;

  // Same role-aware resolution as the rest of the Transport module:
  // correspondents are scoped to whichever school they've currently
  // selected; every other role is scoped to the single school on their own
  // profile.
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
    if (_isEditMode) _prefillFromTripLog(widget.tripLog!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_schoolId != null) _controller.getBusDropdown(_schoolId!);
    });
  }

  void _prefillFromTripLog(Map<String, dynamic> log) {
    _openingOdometerController.text = log['openingOdometer']?.toString() ?? '';
    _closingOdometerController.text = log['closingOdometer']?.toString() ?? '';
    _notesController.text = log['notes']?.toString() ?? '';
    _tripDate = DateTime.tryParse(log['date']?.toString() ?? '') ?? DateTime.now();

    final bus = log['busId'];
    if (bus is Map) {
      _assignedBusId = bus['_id']?.toString();
      _assignedBusLabel = (bus['registrationNo'] ?? bus['busNumber'])?.toString();
    } else if (bus != null) {
      _assignedBusId = bus.toString();
    }
  }

  @override
  void dispose() {
    _openingOdometerController.dispose();
    _closingOdometerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _openAssignedBusSheet() {
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
                    child: Text('Assigned Bus', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
                        final label = (bus['registrationNo'] ?? bus['busNumber'] ?? 'Bus').toString();
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

  Future<void> _pickTripDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tripDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _tripDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_assignedBusId == null) {
      Get.snackbar('Missing Bus', 'Please select the assigned bus', backgroundColor: AppTheme.errorRed, colorText: Colors.white);
      return;
    }
    if (!_isEditMode && _schoolId == null) return;

    setState(() => _submitting = true);

    final opening = num.tryParse(_openingOdometerController.text.trim());
    final closing = num.tryParse(_closingOdometerController.text.trim());
    final kmRun = (opening != null && closing != null) ? (closing - opening) : null;

    final data = {
      'busId': _assignedBusId,
      'date': _tripDate.toIso8601String(),
      if (opening != null) 'openingOdometer': opening,
      if (closing != null) 'closingOdometer': closing,
      if (kmRun != null) 'kmRun': kmRun,
      if (_notesController.text.trim().isNotEmpty) 'notes': _notesController.text.trim(),
      if (!_isEditMode) 'schoolId': _schoolId,
      if (!_isEditMode) 'academicYear': AcademicYearUtils.getCurrentAcademicYear(),
    };

    final ok = _isEditMode
        ? await _controller.updateDailyTripLog(widget.tripLog!['_id'].toString(), data)
        : await _controller.createDailyTripLog(data);

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
        title: Text(_isEditMode ? 'Edit Trip Log' : 'Create Daily Trip Log',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _SectionCard(
              title: 'Trip Information',
              icon: Icons.route_outlined,
              child: Column(
                children: [
                  _LabeledField(
                    label: 'Assigned Bus *',
                    child: InkWell(
                      onTap: _openAssignedBusSheet,
                      child: InputDecorator(
                        decoration: _inputDecoration(_assignedBusLabel ?? 'Search & Select Bus...').copyWith(
                          suffixIcon: const Icon(Icons.keyboard_arrow_down),
                        ),
                        child: Text(
                          _assignedBusLabel ?? 'Search & Select Bus...',
                          style: TextStyle(color: _assignedBusLabel == null ? Colors.grey.shade500 : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                  _LabeledField(
                    label: 'Trip Date',
                    child: InkWell(
                      onTap: _pickTripDate,
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
                            Text(DateFormat('dd-MM-yyyy').format(_tripDate), style: const TextStyle(fontSize: 13)),
                            const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.black45),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _LabeledField(
                    label: 'Opening Odometer (KM) *',
                    child: TextFormField(
                      controller: _openingOdometerController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration('e.g. 12500'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Opening odometer is required' : null,
                    ),
                  ),
                  _LabeledField(
                    label: 'Closing Odometer (KM) *',
                    child: TextFormField(
                      controller: _closingOdometerController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration('e.g. 12650'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Closing odometer is required';
                        final opening = num.tryParse(_openingOdometerController.text.trim());
                        final closing = num.tryParse(v.trim());
                        if (opening != null && closing != null && closing < opening) {
                          return 'Closing odometer must be ≥ opening odometer';
                        }
                        return null;
                      },
                    ),
                  ),
                  _LabeledField(
                    label: 'Trip Notes / Remarks',
                    child: TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: _inputDecoration('Enter any incidents or notes...'),
                    ),
                  ),
                ],
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
                  child: const Text('Close'),
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
                      : Text(_isEditMode ? 'Update Trip Log' : 'Create Trip Log'),
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
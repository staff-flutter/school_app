import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/transport_controller.dart';

/// "Assign Bus to Route" screen — used both to add a new assignment and to
/// edit an existing one. Mirrors Images 4-5: Select Bus, Select Driver,
/// Shift, then a per-stop "Stop Timings Config" section.
///
/// [stops] is the route's stop list (each needs at least `stopName`), used
/// to render one time field per stop. Pass [existing] (a raw assignment map)
/// to edit; leave null to add a new assignment.
class AssignBusScreen extends StatefulWidget {
  final String schoolId;
  final String routeId;
  final List<dynamic> stops;
  final Map<String, dynamic>? existing;

  const AssignBusScreen({
    super.key,
    required this.schoolId,
    required this.routeId,
    required this.stops,
    this.existing,
  });

  bool get isEdit => existing != null;

  @override
  State<AssignBusScreen> createState() => _AssignBusScreenState();
}

class _AssignBusScreenState extends State<AssignBusScreen> {
  final TransportController controller = Get.find<TransportController>();
  final _formKey = GlobalKey<FormState>();

  String? _selectedBusId;
  String? _selectedDriverId;
  String _shift = 'pickup'; // 'pickup' | 'drop'

  // stopName -> TimeOfDay
  final Map<String, TimeOfDay?> _stopTimes = {};
  bool _submitting = false;

  static const Map<String, String> _shiftLabels = {'pickup': 'Pick Up', 'drop': 'Drop'};

  @override
  void initState() {
    super.initState();

    for (final s in widget.stops) {
      final name = s['stopName']?.toString() ?? '';
      if (name.isNotEmpty) _stopTimes[name] = null;
    }

    final e = widget.existing;
    if (e != null) {
      final bus = e['busId'];
      _selectedBusId = bus is Map ? bus['_id']?.toString() : bus?.toString();
      final driver = e['driverId'];
      _selectedDriverId = driver is Map ? driver['_id']?.toString() : driver?.toString();
      _shift = e['shift']?.toString() ?? 'pickup';

      final timings = (e['stopTimings'] as List?) ?? [];
      for (final t in timings) {
        final name = t['stopName']?.toString();
        final timeStr = t['time']?.toString();
        if (name != null && timeStr != null) {
          _stopTimes[name] = _parseTime(timeStr);
        }
      }
    }

    // Defer network calls until after the first frame so isLoading.value = true
    // doesn't fire while this screen is still mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getBusDropdown(widget.schoolId);
      controller.getDriverDropdown(widget.schoolId);
    });
  }

  TimeOfDay? _parseTime(String raw) {
    // Expects "HH:mm" (24h) or "h:mm AM/PM"
    try {
      final upper = raw.toUpperCase();
      if (upper.contains('AM') || upper.contains('PM')) {
        final isPm = upper.contains('PM');
        final clean = upper.replaceAll('AM', '').replaceAll('PM', '').trim();
        final parts = clean.split(':');
        int hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        if (isPm && hour != 12) hour += 12;
        if (!isPm && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
      final parts = raw.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickTime(String stopName) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _stopTimes[stopName] ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _stopTimes[stopName] = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBusId == null || _selectedDriverId == null) {
      Get.snackbar('Error', 'Please select a bus and driver', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _submitting = true);

    final stopTimingsPayload = _stopTimes.entries
        .where((e) => e.value != null)
        .map((e) => {'stopName': e.key, 'time': _formatTime(e.value!)})
        .toList();

    bool ok;
    if (widget.isEdit) {
      ok = await controller.updateBusRouteAssignment(
        routeId: widget.routeId,
        schoolId: widget.schoolId,
        assignmentId: widget.existing!['_id'].toString(),
        busId: _selectedBusId,
        driverId: _selectedDriverId,
        shift: _shift,
        stopTimings: stopTimingsPayload,
      );
    } else {
      ok = await controller.addBusRouteAssignments(
        routeId: widget.routeId,
        schoolId: widget.schoolId,
        assignments: [
          {
            'busId': _selectedBusId,
            'driverId': _selectedDriverId,
            'shift': _shift,
            'stopTimings': stopTimingsPayload,
          },
        ],
      );
    }

    setState(() => _submitting = false);
    if (ok) Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? 'Edit Assignment' : 'Assign Bus to Route')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Obx(() => DropdownButtonFormField<String>(
              value: _selectedBusId,
              decoration: const InputDecoration(labelText: 'Select Bus *', border: OutlineInputBorder()),
              items: controller.busDropdown
                  .map((b) => DropdownMenuItem(
                value: b['_id'].toString(),
                child: Text(b['busNumber']?.toString() ?? b['registrationNo']?.toString() ?? 'Bus'),
              ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedBusId = val),
              validator: (val) => val == null ? 'Required' : null,
            )),
            const SizedBox(height: 16),
            Obx(() => DropdownButtonFormField<String>(
              value: _selectedDriverId,
              decoration: const InputDecoration(labelText: 'Select Driver *', border: OutlineInputBorder()),
              items: controller.driverDropdown
                  .map((d) => DropdownMenuItem(
                value: d['_id'].toString(),
                child: Text(d['name']?.toString() ?? 'Driver'),
              ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedDriverId = val),
              validator: (val) => val == null ? 'Required' : null,
            )),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _shift,
              decoration: const InputDecoration(labelText: 'Shift *', border: OutlineInputBorder()),
              items: _shiftLabels.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (val) => setState(() => _shift = val ?? 'pickup'),
            ),
            const SizedBox(height: 24),
            const Text('Stop Timings Config', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('Set the expected arrival time for each stop on this route.',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            for (final stopName in _stopTimes.keys) _buildStopTimeRow(stopName),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                        height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(widget.isEdit ? 'Save Changes' : 'Add Assignment'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopTimeRow(String stopName) {
    final time = _stopTimes[stopName];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(stopName, style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => _pickTime(stopName),
            child: Container(
              width: 130,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(6)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(time == null ? '--:--' : _formatTime(time)),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
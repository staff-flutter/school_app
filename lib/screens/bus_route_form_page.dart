import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/transport_controller.dart';

/// Create / Edit Bus Route screen.
/// Create mode mirrors "Create New Bus Route" (Image 2): Route Information
/// (name, fee) + Route Stops (Add Stop, each stop: name, landmark, lat, lng).
/// Edit mode mirrors "Edit Bus Route" (Images 6-7): same fields under
/// "Manage Stops", with a delete (X) action per stop.
///
/// Pass [existing] (raw bus route map from the API) to edit; leave null to create.
class BusRouteFormScreen extends StatefulWidget {
  final String schoolId;
  final Map<String, dynamic>? existing;

  const BusRouteFormScreen({super.key, required this.schoolId, this.existing});

  bool get isEdit => existing != null;

  @override
  State<BusRouteFormScreen> createState() => _BusRouteFormScreenState();
}

class _StopEntry {
  String? id; // existing stop's _id (omit when creating a new stop)
  final nameCtrl = TextEditingController();
  final landmarkCtrl = TextEditingController();
  final latCtrl = TextEditingController();
  final lngCtrl = TextEditingController();

  _StopEntry({this.id});

  void dispose() {
    nameCtrl.dispose();
    landmarkCtrl.dispose();
    latCtrl.dispose();
    lngCtrl.dispose();
  }
}

class _BusRouteFormScreenState extends State<BusRouteFormScreen> {
  final TransportController controller = Get.find<TransportController>();
  final _formKey = GlobalKey<FormState>();

  final _routeNameCtrl = TextEditingController();
  final _feeAmountCtrl = TextEditingController();
  String _feeFrequency = 'term';

  final List<_StopEntry> _stops = [];
  bool _submitting = false;

  static const List<String> _feeFrequencies = ['term', 'monthly', 'annual'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _routeNameCtrl.text = e['routeName']?.toString() ?? '';
      _feeAmountCtrl.text = e['feeAmount']?.toString() ?? '';
      _feeFrequency = e['feeFrequency']?.toString() ?? 'term';
      final existingStops = (e['stops'] as List?) ?? [];
      for (final s in existingStops) {
        final entry = _StopEntry(id: s['_id']?.toString());
        entry.nameCtrl.text = s['stopName']?.toString() ?? '';
        entry.landmarkCtrl.text = s['landmark']?.toString() ?? '';
        entry.latCtrl.text = s['latitude']?.toString() ?? '';
        entry.lngCtrl.text = s['longitude']?.toString() ?? '';
        _stops.add(entry);
      }
    }
    if (_stops.isEmpty) _stops.add(_StopEntry());
  }

  @override
  void dispose() {
    _routeNameCtrl.dispose();
    _feeAmountCtrl.dispose();
    for (final s in _stops) {
      s.dispose();
    }
    super.dispose();
  }

  void _addStop() => setState(() => _stops.add(_StopEntry()));

  void _removeStop(int index) {
    setState(() {
      _stops[index].dispose();
      _stops.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final validStops = _stops.where((s) => s.nameCtrl.text.trim().isNotEmpty).toList();
    if (validStops.isEmpty) {
      Get.snackbar('Error', 'Add at least one stop', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _submitting = true);

    final stopsPayload = <Map<String, dynamic>>[];
    for (var i = 0; i < validStops.length; i++) {
      final s = validStops[i];
      stopsPayload.add({
        if (s.id != null) '_id': s.id,
        'stopName': s.nameCtrl.text.trim(),
        'landmark': s.landmarkCtrl.text.trim(),
        'order': i + 1,
        if (s.latCtrl.text.isNotEmpty) 'latitude': double.tryParse(s.latCtrl.text),
        if (s.lngCtrl.text.isNotEmpty) 'longitude': double.tryParse(s.lngCtrl.text),
      });
    }

    bool ok;
    if (widget.isEdit) {
      ok = await controller.updateBusRoute(
        routeId: widget.existing!['_id'].toString(),
        schoolId: widget.schoolId,
        routeName: _routeNameCtrl.text.trim(),
        stops: stopsPayload,
        feeAmount: double.tryParse(_feeAmountCtrl.text),
        feeFrequency: _feeFrequency,
      );
    } else {
      ok = await controller.createBusRoute(
        schoolId: widget.schoolId,
        routeName: _routeNameCtrl.text.trim(),
        stops: stopsPayload,
        feeAmount: double.tryParse(_feeAmountCtrl.text),
        feeFrequency: _feeFrequency,
      );
    }

    setState(() => _submitting = false);
    if (ok) Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? 'Edit Bus Route' : 'Create New Bus Route')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle(Icons.info_outline, widget.isEdit ? 'Route Details' : 'Route Information'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _routeNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Route Name *',
                hintText: 'e.g. North City Express',
                border: OutlineInputBorder(),
              ),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _feeAmountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Route Fee Amount (₹)',
                hintText: 'e.g. 1500',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _feeFrequency,
              decoration: const InputDecoration(labelText: 'Fee Frequency', border: OutlineInputBorder()),
              items: _feeFrequencies
                  .map((f) => DropdownMenuItem(value: f, child: Text(f[0].toUpperCase() + f.substring(1))))
                  .toList(),
              onChanged: (val) => setState(() => _feeFrequency = val ?? 'term'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(widget.isEdit ? 'Manage Stops' : 'Route Stops',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _addStop,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Stop'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _stops.length; i++) _buildStopCard(i),
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
                        : Text(widget.isEdit ? 'Save Changes' : 'Create Route'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopCard(int index) {
    final stop = _stops[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('STOP #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                if (_stops.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                    onPressed: () => _removeStop(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: stop.nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Stop Name *',
                      hintText: 'e.g. Central Library',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: stop.landmarkCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Landmark',
                      hintText: 'e.g. Near Metro Station',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: stop.latCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Latitude (Optional)',
                      hintText: 'e.g. 13.0827',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: stop.lngCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Longitude (Optional)',
                      hintText: 'e.g. 80.2707',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
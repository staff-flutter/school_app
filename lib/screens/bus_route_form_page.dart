import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/transport_controller.dart';

/// Create / Edit Bus Route screen.
class BusRouteFormScreen extends StatefulWidget {
  final String schoolId;
  final Map<String, dynamic>? existing;

  const BusRouteFormScreen({super.key, required this.schoolId, this.existing});

  bool get isEdit => existing != null;

  @override
  State<BusRouteFormScreen> createState() => _BusRouteFormScreenState();
}

class _StopEntry {
  String? id;
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
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.isEdit ? 'Edit Bus Route' : 'Create New Bus Route',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Container(
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
                      children: [
                        _sectionTitle(
                          Icons.info_outline,
                          widget.isEdit ? 'Route Details' : 'Route Information',
                        ),
                        const SizedBox(height: 14),

                        _buildFieldLabel('Route Name *'),
                        TextFormField(
                          controller: _routeNameCtrl,
                          style: const TextStyle(fontSize: 13),
                          decoration: _buildInputDecoration(hintText: 'e.g. North City Express'),
                          validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),

                        _buildFieldLabel('Route Fee Amount (₹)'),
                        TextFormField(
                          controller: _feeAmountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 13),
                          decoration: _buildInputDecoration(hintText: 'e.g. 1500'),
                        ),
                        const SizedBox(height: 14),

                        _buildFieldLabel('Fee Frequency'),
                        DropdownButtonFormField<String>(
                          value: _feeFrequency,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF6B7280)),
                          decoration: _buildInputDecoration(),
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
                          items: _feeFrequencies
                              .map((f) => DropdownMenuItem(
                            value: f,
                            child: Text(
                              f[0].toUpperCase() + f.substring(1),
                              style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
                            ),
                          ))
                              .toList(),
                          onChanged: (val) => setState(() => _feeFrequency = val ?? 'term'),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _sectionTitle(
                              Icons.place_outlined,
                              widget.isEdit ? 'Manage Stops' : 'Route Stops',
                            ),
                            OutlinedButton.icon(
                              onPressed: _addStop,
                              icon: const Icon(Icons.add, size: 16, color: Color(0xFF2563EB)),
                              label: const Text(
                                'Add Stop',
                                style: TextStyle(color: Color(0xFF2563EB), fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF2563EB)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        for (var i = 0; i < _stops.length; i++) _buildStopCard(i),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Action Buttons
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
                          onPressed: _submitting ? null : () => Get.back(),
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
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                          ),
                          child: _submitting
                              ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                              : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.isEdit ? 'Save Changes' : 'Create Route',
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

  Widget _buildStopCard(int index) {
    final stop = _stops[index];
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
              Text(
                'STOP #${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF6B7280)),
              ),
              if (_stops.length > 1)
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Color(0xFFEF4444)),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Stop Name *'),
                    TextFormField(
                      controller: stop.nameCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: _buildInputDecoration(hintText: 'e.g. Central Library'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Landmark'),
                    TextFormField(
                      controller: stop.landmarkCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: _buildInputDecoration(hintText: 'e.g. Metro Station'),
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
                    _buildFieldLabel('Latitude'),
                    TextFormField(
                      controller: stop.latCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      style: const TextStyle(fontSize: 13),
                      decoration: _buildInputDecoration(hintText: 'e.g. 13.0827'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Longitude'),
                    TextFormField(
                      controller: stop.lngCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      style: const TextStyle(fontSize: 13),
                      decoration: _buildInputDecoration(hintText: 'e.g. 80.2707'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
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
}
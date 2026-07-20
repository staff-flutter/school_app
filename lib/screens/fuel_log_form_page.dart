import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:school_app/controllers/transport_controller.dart';

/// Register / Edit Fuel Log screen.
/// Mirrors the "Register Fuel Log" side panel from the web app:
///   Vehicle & Fuel Metrics -> Assigned Bus, Fill Date, Odometer Reading, Fuel Station Name
///   Billing Information    -> Fuel Quantity, Total Amount, Price/Liter, Bill No, Payment Mode
///   Notes / Remarks
///
/// Pass [existing] (the raw fuel log map from the API) to edit; leave null to create.
class FuelLogFormScreen extends StatefulWidget {
  final String schoolId;
  final Map<String, dynamic>? existing;

  const FuelLogFormScreen({super.key, required this.schoolId, this.existing});

  bool get isEdit => existing != null;

  @override
  State<FuelLogFormScreen> createState() => _FuelLogFormScreenState();
}

class _FuelLogFormScreenState extends State<FuelLogFormScreen> {
  final TransportController controller = Get.find<TransportController>();
  final _formKey = GlobalKey<FormState>();

  final DateFormat _apiDateFmt = DateFormat('yyyy-MM-dd');
  final DateFormat _displayDateFmt = DateFormat('dd-MM-yyyy');

  String? _selectedBusId;
  DateTime _fillDate = DateTime.now();

  final _odometerCtrl = TextEditingController();
  final _fuelStationCtrl = TextEditingController();
  final _fuelQuantityCtrl = TextEditingController();
  final _totalAmountCtrl = TextEditingController();
  final _pricePerLiterCtrl = TextEditingController();
  final _billNoCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  static const List<String> _paymentModes = ['Cash', 'Card', 'UPI', 'Online', 'Cheque'];
  String? _paymentMode = 'Cash';

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    controller.getBusDropdown(widget.schoolId);

    final e = widget.existing;
    if (e != null) {
      final bus = e['busId'];
      _selectedBusId = bus is Map ? bus['_id']?.toString() : bus?.toString();
      if (e['date'] != null) {
        try {
          _fillDate = DateTime.parse(e['date'].toString());
        } catch (_) {}
      }
      _odometerCtrl.text = e['odometerReading']?.toString() ?? '';
      _fuelStationCtrl.text = e['fuelStation']?.toString() ?? '';
      _fuelQuantityCtrl.text = e['fuelQuantity']?.toString() ?? '';
      _totalAmountCtrl.text = e['totalAmount']?.toString() ?? '';
      _pricePerLiterCtrl.text = e['pricePerLiter']?.toString() ?? '';
      _billNoCtrl.text = e['fuelBillNo']?.toString() ?? '';
      _notesCtrl.text = e['notes']?.toString() ?? '';
      _paymentMode = e['paymentMode']?.toString() ?? 'Cash';
    }

    // Auto-calculate price per liter whenever quantity or total amount changes,
    // matching the web form's "Auto-calculated or type" behaviour.
    _fuelQuantityCtrl.addListener(_recalculatePrice);
    _totalAmountCtrl.addListener(_recalculatePrice);
  }

  void _recalculatePrice() {
    final qty = double.tryParse(_fuelQuantityCtrl.text);
    final total = double.tryParse(_totalAmountCtrl.text);
    if (qty != null && qty > 0 && total != null) {
      final price = (total / qty);
      _pricePerLiterCtrl.text = price.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _odometerCtrl.dispose();
    _fuelStationCtrl.dispose();
    _fuelQuantityCtrl.dispose();
    _totalAmountCtrl.dispose();
    _pricePerLiterCtrl.dispose();
    _billNoCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFillDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fillDate,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _fillDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBusId == null) {
      Get.snackbar('Error', 'Please select a bus', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _submitting = true);

    final data = <String, dynamic>{
      'schoolId': widget.schoolId,
      'busId': _selectedBusId,
      'date': _apiDateFmt.format(_fillDate),
      if (_odometerCtrl.text.isNotEmpty) 'odometerReading': num.tryParse(_odometerCtrl.text),
      if (_fuelStationCtrl.text.isNotEmpty) 'fuelStation': _fuelStationCtrl.text,
      'fuelQuantity': num.tryParse(_fuelQuantityCtrl.text),
      'totalAmount': num.tryParse(_totalAmountCtrl.text),
      if (_pricePerLiterCtrl.text.isNotEmpty) 'pricePerLiter': num.tryParse(_pricePerLiterCtrl.text),
      if (_billNoCtrl.text.isNotEmpty) 'fuelBillNo': _billNoCtrl.text,
      if (_paymentMode != null) 'paymentMode': _paymentMode,
      if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text,
    };

    bool ok;
    if (widget.isEdit) {
      ok = await controller.updateFuelLog(widget.existing!['_id'].toString(), data);
    } else {
      ok = await controller.createFuelLog(data);
    }

    setState(() => _submitting = false);
    if (ok) Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? 'Edit Fuel Log' : 'Register Fuel Log')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle(Icons.directions_bus, 'Vehicle & Fuel Metrics'),
            const SizedBox(height: 8),
            Obx(() => DropdownButtonFormField<String>(
              value: _selectedBusId,
              decoration: const InputDecoration(
                labelText: 'Assigned Bus',
                border: OutlineInputBorder(),
              ),
              items: controller.busDropdown
                  .map((b) => DropdownMenuItem(
                value: b['_id'].toString(),
                child: Text(b['busNumber']?.toString() ?? b['registrationNo']?.toString() ?? 'Bus'),
              ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedBusId = val),
              validator: (val) => val == null ? 'Required' : null,
            )),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickFillDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Fill Date', border: OutlineInputBorder()),
                child: Text(_displayDateFmt.format(_fillDate)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _odometerCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Odometer Reading (KM)', hintText: 'e.g. 12500', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fuelStationCtrl,
              decoration: const InputDecoration(
                labelText: 'Fuel Station Name',
                hintText: 'e.g. Indian Oil, Bharat Petroleum',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle(Icons.receipt_long, 'Billing Information'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _fuelQuantityCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Fuel Quantity (Liters) *', hintText: 'e.g. 45.5', border: OutlineInputBorder()),
              validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _totalAmountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Total Amount (₹) *', hintText: 'e.g. 4000', border: OutlineInputBorder()),
              validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pricePerLiterCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price Per Liter (₹)',
                hintText: 'Auto-calculated or type',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _billNoCtrl,
              decoration: const InputDecoration(labelText: 'Bill / Receipt No', hintText: 'Enter Bill No', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _paymentMode,
              decoration: const InputDecoration(labelText: 'Payment Mode', border: OutlineInputBorder()),
              items: _paymentModes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) => setState(() => _paymentMode = val),
            ),
            const SizedBox(height: 24),
            const Text('Notes / Remarks', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Any additional remarks...', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : () => Get.back(),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                        height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(widget.isEdit ? 'Update Fuel Log' : 'Register Fuel Log'),
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
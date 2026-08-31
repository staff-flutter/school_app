import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:school_app/controllers/transport_controller.dart';
import 'package:flutter/services.dart';

/// Register / Edit Fuel Log screen.
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
          widget.isEdit ? 'Edit Fuel Log' : 'Register Fuel Log',
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
                        _sectionTitle(Icons.directions_bus_outlined, 'Vehicle & Fuel Metrics'),
                        const SizedBox(height: 14),

                        _buildFieldLabel('Assigned Bus *'),
                        Obx(() => DropdownButtonFormField<String>(
                          value: _selectedBusId,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF6B7280)),
                          decoration: _buildInputDecoration(hintText: 'Select Bus'),
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
                          items: controller.busDropdown
                              .map((b) => DropdownMenuItem(
                            value: b['_id'].toString(),
                            child: Text(
                              b['busNumber']?.toString() ?? b['registrationNo']?.toString() ?? 'Bus',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
                            ),
                          ))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedBusId = val),
                          validator: (val) => val == null ? 'Please select a bus' : null,
                        )),
                        const SizedBox(height: 14),

                        _buildFieldLabel('Fill Date'),
                        InkWell(
                          onTap: _pickFillDate,
                          borderRadius: BorderRadius.circular(8),
                          child: InputDecorator(
                            decoration: _buildInputDecoration(),
                            child: Text(
                              _displayDateFmt.format(_fillDate),
                              style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildFieldLabel('Odometer Reading (KM)'),
                        TextFormField(
                          controller: _odometerCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 13),
                          decoration: _buildInputDecoration(hintText: 'e.g. 12500'),
                        ),
                        const SizedBox(height: 14),

                        _buildFieldLabel('Fuel Station Name'),
                        TextFormField(
                          controller: _fuelStationCtrl,
                          style: const TextStyle(fontSize: 13),
                          decoration: _buildInputDecoration(hintText: 'e.g. Indian Oil, Bharat Petroleum'),
                        ),
                        const SizedBox(height: 20),

                        _sectionTitle(Icons.receipt_long_outlined, 'Billing Information'),
                        const SizedBox(height: 14),

                        _buildFieldLabel('Fuel Quantity (Liters) *'),
                        TextFormField(
                          controller: _fuelQuantityCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 13),
                          decoration: _buildInputDecoration(hintText: 'e.g. 45.5'),
                          validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),

                        _buildFieldLabel('Total Amount (₹) *'),
                        TextFormField(
                          controller: _totalAmountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 13),
                          decoration: _buildInputDecoration(hintText: 'e.g. 4000'),
                          validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),

                        _buildFieldLabel('Price Per Liter (₹)'),
                        TextFormField(
                          controller: _pricePerLiterCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 13),
                          decoration: _buildInputDecoration(hintText: 'Auto-calculated or type'),
                        ),
                        const SizedBox(height: 14),

                        _buildFieldLabel('Bill / Receipt No'),
                        TextFormField(
                          controller: _billNoCtrl,
                          style: const TextStyle(fontSize: 13),
                          decoration: _buildInputDecoration(hintText: 'Enter Bill No'),
                        ),
                        const SizedBox(height: 14),

                        _buildFieldLabel('Payment Mode'),
                        DropdownButtonFormField<String>(
                          value: _paymentMode,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF6B7280)),
                          decoration: _buildInputDecoration(),
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
                          items: _paymentModes
                              .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m, style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937))),
                          ))
                              .toList(),
                          onChanged: (val) => setState(() => _paymentMode = val),
                        ),
                        const SizedBox(height: 14),

                        _buildFieldLabel('Notes / Remarks'),
                        TextFormField(
                          controller: _notesCtrl,
                          maxLines: 3,
                          style: const TextStyle(fontSize: 13),
                          decoration: _buildInputDecoration(hintText: 'Any additional remarks...'),
                        ),
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
                    const SizedBox(width: 11),
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
                              widget.isEdit ? 'Update Fuel Log' : 'Register Fuel Log',
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
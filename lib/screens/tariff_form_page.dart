import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/eb_controller.dart';

class TariffFormScreen extends StatefulWidget {
  final String schoolId;
  final Map<String, dynamic>? existingTariff;

  const TariffFormScreen({
    super.key,
    required this.schoolId,
    this.existingTariff,
  });

  @override
  State<TariffFormScreen> createState() => _TariffFormScreenState();
}

class _TariffFormScreenState extends State<TariffFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final EBController ebController = Get.find();

  final TextEditingController _tariffNameController = TextEditingController();
  final TextEditingController _fixedChargeController = TextEditingController();

  bool _isActive = true;
  final List<Map<String, TextEditingController>> _slabControllers = [];

  bool get _isEditing => widget.existingTariff != null;

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  void _populateFields() {
    if (_isEditing) {
      final t = widget.existingTariff!;
      _tariffNameController.text = t['tariffName']?.toString() ?? '';
      _fixedChargeController.text = t['fixedChargePerKw']?.toString() ?? '';
      _isActive = t['isActive'] ?? true;

      if (t['slabs'] is List) {
        for (var slab in t['slabs']) {
          _addSlab(
            upto: slab['upto']?.toString() ?? '',
            rate: slab['ratePerUnit']?.toString() ?? '',
          );
        }
      }
    }

    if (_slabControllers.isEmpty) {
      _addSlab(); // Default 1 slab if empty
    }
  }

  void _addSlab({String upto = '', String rate = ''}) {
    setState(() {
      _slabControllers.add({
        'upto': TextEditingController(text: upto),
        'rate': TextEditingController(text: rate),
      });
    });
  }

  void _removeSlab(int index) {
    if (_slabControllers.length > 1) {
      setState(() {
        final removed = _slabControllers.removeAt(index);
        removed['upto']?.dispose();
        removed['rate']?.dispose();
      });
    }
  }

  @override
  void dispose() {
    _tariffNameController.dispose();
    _fixedChargeController.dispose();
    for (var slab in _slabControllers) {
      slab['upto']?.dispose();
      slab['rate']?.dispose();
    }
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final slabsPayload = _slabControllers.map((slab) {
      return {
        'upto': num.tryParse(slab['upto']!.text.trim()) ?? 0,
        'ratePerUnit': num.tryParse(slab['rate']!.text.trim()) ?? 0,
      };
    }).toList();

    final payload = {
      'tariffName': _tariffNameController.text.trim(),
      'fixedChargePerKw': num.tryParse(_fixedChargeController.text.trim()) ?? 0,
      'isActive': _isActive,
      'slabs': slabsPayload,
    };

    bool success;
    if (_isEditing) {
      final tariffId = (widget.existingTariff!['_id'] ?? widget.existingTariff!['id']).toString();
      success = await ebController.updateTariff(widget.schoolId, tariffId, payload);
    } else {
      success = await ebController.createTariff(widget.schoolId, payload);
    }

    if (success) {
      Get.back(result: true);
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Tariff' : 'Create New Tariff',
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Get.back(),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // General Details Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 18, color: Colors.grey.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'General Details',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Text(
                              'TARIFF PLAN NAME *',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _tariffNameController,
                              style: const TextStyle(fontSize: 12),
                              decoration: _inputDecoration('e.g. Commercial Plan A, Residential'),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'FIXED CHARGE PER KW (₹) *',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _fixedChargeController,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(fontSize: 12),
                                        decoration: _inputDecoration('e.g. 150'),
                                        validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _isActive,
                                      onChanged: (val) => setState(() => _isActive = val ?? true),
                                    ),
                                    const Text('Plan is Active',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Usage Slabs Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.layers_outlined, size: 18, color: Colors.grey.shade700),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Usage Slabs',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _addSlab(),
                                  icon: const Icon(Icons.add, size: 14),
                                  label: const Text('Add Slab', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    side: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _slabControllers.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final slabMap = _slabControllers[index];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'SLAB ${index + 1}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          if (_slabControllers.length > 1)
                                            GestureDetector(
                                              onTap: () => _removeSlab(index),
                                              child: const Icon(Icons.close, size: 16, color: Colors.red),
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
                                                Text(
                                                  'UP TO (KW)',
                                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                                ),
                                                const SizedBox(height: 4),
                                                TextFormField(
                                                  controller: slabMap['upto'],
                                                  keyboardType: TextInputType.number,
                                                  style: const TextStyle(fontSize: 12),
                                                  decoration: _inputDecoration('100'),
                                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'RATE PER UNIT (₹)',
                                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                                ),
                                                const SizedBox(height: 4),
                                                TextFormField(
                                                  controller: slabMap['rate'],
                                                  keyboardType: TextInputType.number,
                                                  style: const TextStyle(fontSize: 12),
                                                  decoration: _inputDecoration('0'),
                                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Actions Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Close', style: TextStyle(color: Colors.black87, fontSize: 13)),
                    ),
                    const SizedBox(width: 10),
                    Obx(() {
                      final loading = ebController.isLoading.value;
                      return ElevatedButton(
                        onPressed: loading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF323B4A),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: loading
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                            : Text(
                          _isEditing ? 'Update Tariff' : 'Create Tariff',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      );
                    }),
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
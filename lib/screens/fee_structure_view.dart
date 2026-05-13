import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/accounting_controller.dart';
import 'package:school_app/controllers/fee_structure_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';

const _kBg = Color(0xFFF0F5FF);
const _kBlue = Color(0xFF2563EB);
const _kBlueDark = Color(0xFF1A2A3A);
const _kBlueMuted = Color(0xFF90A4BE);
const _kBlueBorder = Color(0xFFDDE6F5);

class FeeStructureView extends GetView<AccountingController> {
  FeeStructureView({super.key});
  final selectedClass = ''.obs;
  final selectedSection = ''.obs;
  final feeControllers = <String, TextEditingController>{}.obs;

  @override
  Widget build(BuildContext context) {
    _initializeFeeControllers();
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            // ── Header ────────────────────────────────────
            _buildHeader(),

            // ── Body ──────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 20 : 12,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildClassSectionCard(context, isTablet),
                    const SizedBox(height: 12),
                    _buildFeeFormCard(context, isTablet),
                    const SizedBox(height: 16),
                    _buildSaveButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBlueBorder),
        boxShadow: [BoxShadow(color: _kBlueBorder.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Fee Structure', style: TextStyle(color: _kBlueDark, fontSize: 15, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                Text('Configure class-wise fee heads', style: TextStyle(color: _kBlueMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Class & Section Card ──────────────────────────────────────────────────
  Widget _buildClassSectionCard(BuildContext context, bool isTablet) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Select Class & Section', Icons.class_rounded),
          const SizedBox(height: 14),
          isTablet
              ? Row(children: [
                  Expanded(child: _classDropdown()),
                  const SizedBox(width: 12),
                  Expanded(child: _sectionDropdown()),
                ])
              : Column(children: [
                  _classDropdown(),
                  const SizedBox(height: 12),
                  _sectionDropdown(),
                ]),
        ],
      ),
    );
  }

  Widget _classDropdown() {
    return Obx(() => DropdownButtonFormField<String>(
      value: selectedClass.value.isEmpty ? null : selectedClass.value,
      decoration: _inputDecoration('Class', Icons.school_rounded),
      items: ['LKG', 'UKG', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10']
          .map((cls) => DropdownMenuItem(value: cls, child: Text('Class $cls')))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          selectedClass.value = value;
          selectedSection.value = '';
        }
      },
    ));
  }

  Widget _sectionDropdown() {
    return Obx(() => DropdownButtonFormField<String>(
      value: selectedSection.value.isEmpty ? null : selectedSection.value,
      decoration: _inputDecoration('Section (Optional)', Icons.segment_rounded),
      items: ['A', 'B', 'C', 'D']
          .map((s) => DropdownMenuItem(value: s, child: Text('Section $s')))
          .toList(),
      onChanged: (value) => selectedSection.value = value ?? '',
    ));
  }

  // ── Fee Form Card ─────────────────────────────────────────────────────────
  Widget _buildFeeFormCard(BuildContext context, bool isTablet) {
    final feeFields = [
      ('Admission Fee', 'admissionFee', Icons.badge_rounded, 'One-time admission fee'),
      ('First Term Amount', 'firstTermAmt', Icons.looks_one_rounded, 'Tuition fee for first term'),
      ('Second Term Amount', 'secondTermAmt', Icons.looks_two_rounded, 'Tuition fee for second term'),
      ('Annual Fee', 'annualFee', Icons.calendar_today_rounded, 'Annual charges (books, activities, etc.)'),
      ('Bus First Term Amount', 'busFirstTermAmt', Icons.directions_bus_rounded, 'Transportation fee for first term'),
      ('Bus Second Term Amount', 'busSecondTermAmt', Icons.directions_bus_filled_rounded, 'Transportation fee for second term'),
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Fee Configuration', Icons.payments_rounded),
          const SizedBox(height: 14),
          if (isTablet)
            ...List.generate((feeFields.length / 2).ceil(), (i) {
              final left = feeFields[i * 2];
              final rightIndex = i * 2 + 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(child: _buildFeeField(left.$1, left.$2, left.$3, left.$4)),
                    const SizedBox(width: 12),
                    if (rightIndex < feeFields.length)
                      Expanded(child: _buildFeeField(feeFields[rightIndex].$1, feeFields[rightIndex].$2, feeFields[rightIndex].$3, feeFields[rightIndex].$4))
                    else
                      const Expanded(child: SizedBox()),
                  ],
                ),
              );
            })
          else
            ...feeFields.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildFeeField(f.$1, f.$2, f.$3, f.$4),
            )),
        ],
      ),
    );
  }

  Widget _buildFeeField(String label, String key, IconData icon, String helper) {
    return TextFormField(
      controller: feeControllers[key],
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: '0',
        prefixText: '₹ ',
        helperText: helper,
        prefixIcon: Icon(icon, color: _kBlue, size: 18),
        filled: true,
        fillColor: _kBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBlueBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBlueBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBlue, width: 1.5)),
        labelStyle: const TextStyle(color: _kBlueMuted, fontSize: 13),
        helperStyle: const TextStyle(color: _kBlueMuted, fontSize: 10),
      ),
    );
  }

  // ── Save Button ───────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return Obx(() => SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: selectedClass.value.isEmpty || controller.isLoading.value
              ? LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade300])
              : const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: selectedClass.value.isEmpty ? [] : [BoxShadow(color: _kBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: selectedClass.value.isEmpty || controller.isLoading.value ? null : _saveFeeStructure,
          icon: controller.isLoading.value
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.save_rounded, color: Colors.white, size: 18),
          label: Text(
            controller.isLoading.value ? 'Saving…' : 'Save Fee Structure',
            style: TextStyle(color: selectedClass.value.isEmpty ? Colors.grey.shade500 : Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ),
    ));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _kBlue, size: 18),
      filled: true,
      fillColor: _kBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBlueBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBlueBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBlue, width: 1.5)),
      labelStyle: const TextStyle(color: _kBlueMuted, fontSize: 13),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBlueBorder),
        boxShadow: [BoxShadow(color: _kBlueBorder.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: _kBlue.withOpacity(0.10), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: _kBlue, size: 16)),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kBlueDark)),
    ]);
  }

  void _initializeFeeControllers() {
    for (final field in ['admissionFee', 'firstTermAmt', 'secondTermAmt', 'annualFee', 'busFirstTermAmt', 'busSecondTermAmt']) {
      if (!feeControllers.containsKey(field)) feeControllers[field] = TextEditingController();
    }
  }

  void _saveFeeStructure() {
    bool hasValue = false;
    final feeData = <String, double>{};
    for (final key in feeControllers.keys) {
      final text = feeControllers[key]!.text.trim();
      if (text.isNotEmpty) {
        final value = double.tryParse(text);
        if (value != null && value > 0) { feeData[key] = value; hasValue = true; }
      }
    }
    if (!hasValue) { Get.snackbar('Error', 'Please enter at least one fee amount', backgroundColor: Colors.red, colorText: Colors.white); return; }

    final labelMap = {
      'admissionFee': 'Admission Fee', 'firstTermAmt': 'First Term Amount',
      'secondTermAmt': 'Second Term Amount', 'annualFee': 'Annual Fee',
      'busFirstTermAmt': 'Bus First Term Amount', 'busSecondTermAmt': 'Bus Second Term Amount',
    };

    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _kBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.info_outline_rounded, color: _kBlue, size: 20)), const SizedBox(width: 8), const Text('Confirm Fee Structure', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kBlueDark))]),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _dialogRow('Class', selectedClass.value),
        if (selectedSection.value.isNotEmpty) _dialogRow('Section', selectedSection.value),
        const Divider(height: 20),
        ...feeData.entries.map((e) => _dialogRow(labelMap[e.key] ?? e.key, '₹${e.value.toStringAsFixed(0)}')),
      ])),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel', style: TextStyle(color: _kBlueMuted))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _kBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: () { Get.back(); _submitFeeStructure(feeData); },
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  Widget _dialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _kBlueMuted)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kBlueDark)),
      ]),
    );
  }

  void _submitFeeStructure(Map<String, double> feeData) async {
    final feeController = Get.put(FeeStructureController());
    final authController = Get.find<AuthController>();
    final schoolId = authController.user.value?.schoolId;
    if (schoolId == null) { Get.snackbar('Error', 'School ID not found'); return; }
    await feeController.setFeeStructure(schoolId: schoolId, classId: 'class_${selectedClass.value.toLowerCase()}', feeHead: feeData);
    for (final c in feeControllers.values) c.clear();
    selectedClass.value = '';
    selectedSection.value = '';
  }
}

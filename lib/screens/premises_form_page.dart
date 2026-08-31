import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/eb_controller.dart';

/// Register / Edit Premises screen — mirrors the "Register New Bus" mobile
/// form styling: back-arrow header, white section cards with an icon +
/// section title, bold field labels over rounded outlined inputs, and a
/// fixed bottom bar with an outlined "Cancel" and a solid blue action button.
class PremisesFormScreen extends StatefulWidget {
  final String schoolId;
  final Map<String, dynamic>? existingPremises; // null => create mode

  const PremisesFormScreen({
    super.key,
    required this.schoolId,
    this.existingPremises,
  });

  @override
  State<PremisesFormScreen> createState() => _PremisesFormScreenState();
}

class _PremisesFormScreenState extends State<PremisesFormScreen> {
  final EBController ebController = Get.put(EBController());
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _consumerNumberController;
  late final TextEditingController _sanctionedLoadController;
  late final TextEditingController _meterLocationController;

  String? _tariffId;
  String? _tariffName;
  DateTime? _billingCycleStart;
  bool _isActive = true;
  bool _saving = false;

  // Tariffs are only fetched the first time the user opens the tariff
  // picker, not on page load — avoids firing an error snackbar on top of
  // the form before the user has even touched that field.
  bool _tariffsRequested = false;

  bool get _isEditMode => widget.existingPremises != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existingPremises;
    _nameController = TextEditingController(text: p?['premisesName'] ?? '');
    _addressController = TextEditingController(text: p?['premisesAddress'] ?? '');
    _consumerNumberController = TextEditingController(text: p?['consumerNumber'] ?? '');
    _sanctionedLoadController = TextEditingController(text: p?['sanctionedLoad']?.toString() ?? '');
    _meterLocationController = TextEditingController(text: p?['meterLocation'] ?? '');
    _isActive = p?['isActive'] ?? true;

    final tariffRaw = p?['tariffId'];
    if (tariffRaw is Map) {
      _tariffId = tariffRaw['_id']?.toString();
      _tariffName = tariffRaw['tariffName']?.toString();
    } else {
      _tariffId = tariffRaw?.toString();
      _tariffName = null;
    }

    if (p?['billingCycleStartDate'] != null) {
      _billingCycleStart = DateTime.tryParse(p!['billingCycleStartDate'].toString());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _consumerNumberController.dispose();
    _sanctionedLoadController.dispose();
    _meterLocationController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  Future<void> _pickBillingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _billingCycleStart ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _billingCycleStart = picked);
  }

  Future<void> _pickTariff() async {
    // Lazy-load tariffs the first time this field is opened.
    if (!_tariffsRequested) {
      _tariffsRequested = true;
      await ebController.getAllTariffs(widget.schoolId);
    }

    final searchController = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final query = searchController.text.trim().toLowerCase();
              final tariffs = ebController.tariffs.where((t) {
                final tariffName = (t['tariffName'] ?? '').toString().toLowerCase();
                return query.isEmpty || tariffName.contains(query);
              }).toList();

              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Tariff',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: searchController,
                        style: const TextStyle(fontSize: 13),
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search and select tariff...',
                          hintStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Obx(() {
                          if (ebController.isLoading.value && ebController.tariffs.isEmpty) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (tariffs.isEmpty) {
                            return Center(
                              child: Text(
                                'No tariffs found',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            );
                          }
                          return ListView.separated(
                            itemCount: tariffs.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final t = tariffs[index];
                              return ListTile(
                                dense: true,
                                title: Text(t['tariffName'] ?? '', style: const TextStyle(fontSize: 13)),
                                subtitle: Text(
                                  'Fixed charge: ${t['fixedChargePerKw'] ?? 'N/A'} / kW',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onTap: () {
                                  setState(() {
                                    _tariffId = t['_id'];
                                    _tariffName = t['tariffName'];
                                  });
                                  Get.back();
                                },
                              );
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final data = <String, dynamic>{
      'premisesName': _nameController.text.trim(),
      'premisesAddress': _addressController.text.trim(),
      'consumerNumber': _consumerNumberController.text.trim(),
      'meterLocation': _meterLocationController.text.trim(),
      'isActive': _isActive,
      if (_tariffId != null) 'tariffId': _tariffId,
      if (_sanctionedLoadController.text.trim().isNotEmpty)
        'sanctionedLoad': num.tryParse(_sanctionedLoadController.text.trim()),
      if (_billingCycleStart != null)
        'billingCycleStartDate': _billingCycleStart!.toIso8601String(),
    };

    bool ok;
    if (_isEditMode) {
      final id = (widget.existingPremises!['_id'] ?? widget.existingPremises!['id']).toString();
      ok = await ebController.updatePremises(widget.schoolId, id, data);
    } else {
      ok = await ebController.createPremises(widget.schoolId, data);
    }

    setState(() => _saving = false);
    if (ok) Get.back(result: true);
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black87),
      ),
    );
  }

  Widget _fieldLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
          children: required
              ? const [TextSpan(text: ' *', style: TextStyle(color: Colors.red))]
              : null,
        ),
      ),
    );
  }

  Widget _sectionCard({required IconData icon, required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.black87),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const Divider(height: 22),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    _isEditMode ? 'Edit Premises' : 'Register New Premises',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            // Form body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _sectionCard(
                        icon: Icons.info_outline,
                        title: 'Basic Details',
                        children: [
                          _fieldLabel('Premises Name', required: true),
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(fontSize: 13),
                            decoration: _inputDecoration('e.g. Main Block, Admin Wing'),
                            validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Premises name is required' : null,
                          ),
                          const SizedBox(height: 14),
                          _fieldLabel('Address'),
                          TextFormField(
                            controller: _addressController,
                            style: const TextStyle(fontSize: 13),
                            minLines: 2,
                            maxLines: 3,
                            decoration: _inputDecoration('Enter physical address...'),
                          ),
                          const SizedBox(height: 14),
                          _fieldLabel('Tariff Plan'),
                          InkWell(
                            onTap: _pickTariff,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.search, color: Colors.grey, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _tariffName ?? 'Search and select tariff...',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _tariffName == null ? Colors.grey.shade500 : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Transform.scale(
                                scale: 0.9,
                                child: Checkbox(
                                  value: _isActive,
                                  onChanged: (v) => setState(() => _isActive = v ?? true),
                                ),
                              ),
                              const Text(
                                'Active Status',
                                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                      _sectionCard(
                        icon: Icons.bolt,
                        title: 'Meter & Billing Details',
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _fieldLabel('Consumer Number'),
                                    TextFormField(
                                      controller: _consumerNumberController,
                                      style: const TextStyle(fontSize: 13),
                                      decoration: _inputDecoration('EB Consumer No'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _fieldLabel('Sanctioned Load (kW)'),
                                    TextFormField(
                                      controller: _sanctionedLoadController,
                                      style: const TextStyle(fontSize: 13),
                                      keyboardType: TextInputType.number,
                                      decoration: _inputDecoration('e.g. 50'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _fieldLabel('Meter Location'),
                                    TextFormField(
                                      controller: _meterLocationController,
                                      style: const TextStyle(fontSize: 13),
                                      decoration: _inputDecoration('e.g. Ground Floor Panel'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _fieldLabel('Billing Cycle Start'),
                                    InkWell(
                                      onTap: _pickBillingDate,
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _billingCycleStart == null
                                                  ? 'dd-mm-yyyy'
                                                  : _formatDate(_billingCycleStart!),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: _billingCycleStart == null
                                                    ? Colors.grey.shade500
                                                    : Colors.black87,
                                              ),
                                            ),
                                            const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6F8),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: _saving
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Text(
                    _isEditMode ? 'Update Premises' : 'Create Premises',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
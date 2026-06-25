import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/fee_structure_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/core/utils/class_utils.dart';
import 'package:school_app/models/school_models.dart';

const _kBg         = Color(0xFFF0F5FF);
const _kBlue       = Color(0xFF2563EB);
const _kBlueDark   = Color(0xFF1A2A3A);
const _kBlueMuted  = Color(0xFF90A4BE);
const _kBlueBorder = Color(0xFFDDE6F5);
const _kSuccess    = Color(0xFF059669);
const _kSuccessBg  = Color(0xFFD1FAE5);
const _kDanger     = Color(0xFFDC2626);
const _kDangerBg   = Color(0xFFFEE2E2);

const _kTerms = ['firstTerm', 'secondTerm', 'thirdTerm'];

String _termLabel(String t) => switch (t) {
  'firstTerm' => '1st Term',
  'secondTerm' => '2nd Term',
  'thirdTerm' => '3rd Term',
  _ => t,
};

class FeeSetupView extends StatefulWidget {
  const FeeSetupView({super.key});

  @override
  State<FeeSetupView> createState() => _FeeSetupViewState();
}

class _FeeSetupViewState extends State<FeeSetupView> {
  final feeController    = Get.put(FeeStructureController());
  final schoolController = Get.find<SchoolController>();
  final authController   = Get.find<AuthController>();

  final _selectedClass       = Rxn<SchoolClass>();
  final _selectedStudentType = 'old'.obs;
  SchoolClass? get selectedClass       => _selectedClass.value;
  String       get selectedStudentType => _selectedStudentType.value;

  /// Global fee-config heads for this school.
  /// Each: { _id, feeHead, associatedTerm, isTerm }
  final RxList<Map<String, dynamic>> _configHeads = <Map<String, dynamic>>[].obs;

  /// Per-class amount entries currently displayed/edited.
  /// Each: { name, amount }
  final RxList<Map<String, dynamic>> _classHeads = <Map<String, dynamic>>[].obs;

  final _amountControllers = <String, TextEditingController>{};
  final _isBusy = false.obs;

  String? get _schoolId =>
      schoolController.selectedSchool.value?.id ?? authController.user.value?.schoolId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final school = schoolController.selectedSchool.value;
      if (school != null) await schoolController.getAllClasses(school.id);
      await _loadConfigHeads();
    });
    everAll([_selectedClass, _selectedStudentType], (_) => _loadClassAmounts());
  }

  @override
  void dispose() {
    for (final c in _amountControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _loadConfigHeads() async {
    final sid = _schoolId;
    if (sid == null) return;
    final heads = await feeController.getFeeConfigHeads(sid);
    _configHeads.assignAll(heads);
  }

  Future<void> _loadClassAmounts() async {
    final sid = _schoolId;
    if (sid == null || selectedClass == null) return;

    for (final c in _amountControllers.values) c.dispose();
    _amountControllers.clear();

    final heads = await feeController.getCustomFeeHeads(
      schoolId: sid,
      classId: selectedClass!.id,
      type: selectedStudentType,
    );

    final built = <Map<String, dynamic>>[];
    for (final h in heads) {
      final name = (h['feeName'] ?? '').toString();
      final amount = (h['feeAmount'] as num?)?.toDouble() ?? 0.0;
      _amountControllers[name] = TextEditingController(
        text: amount == 0.0 ? '' : (amount % 1 == 0 ? amount.toInt().toString() : amount.toStringAsFixed(2)),
      );
      built.add({'name': name, 'amount': amount});
    }
    _classHeads.assignAll(built);
  }

  bool _headInClass(String name) => _classHeads.any((h) => h['name'] == name);

  void _toggleHeadForClass(String name) {
    if (_headInClass(name)) {
      _classHeads.removeWhere((h) => h['name'] == name);
    } else {
      _amountControllers.putIfAbsent(name, () => TextEditingController());
      _classHeads.add({'name': name, 'amount': 0.0});
    }
  }
  void _showEditHeadSheet(Map<String, dynamic> head) {
    final nameCtrl = TextEditingController(text: head['feeHead']?.toString() ?? '');
    bool isTerm = head['isTerm'] == true;
    String term = head['associatedTerm']?.toString() ?? _kTerms.first;
    final formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(Get.context!).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: _kBlueBorder, borderRadius: BorderRadius.circular(100)),
                ),
                const Text('Edit Fee Head',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kBlueDark)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Fee Head Name',
                    filled: true, fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Belongs to a term', style: TextStyle(fontSize: 13)),
                  value: isTerm,
                  onChanged: (v) => setSheetState(() => isTerm = v),
                ),
                if (isTerm)
                  Wrap(
                    spacing: 8,
                    children: _kTerms.map((t) {
                      final sel = term == t;
                      return GestureDetector(
                        onTap: () => setSheetState(() => term = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? _kBlue.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: sel ? _kBlue : _kBlueBorder),
                          ),
                          child: Text(_termLabel(t),
                              style: TextStyle(fontSize: 12, color: sel ? _kBlue : _kBlueMuted,
                                  fontWeight: FontWeight.w600)),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final sid = _schoolId;
                      if (sid == null) return;
                      Get.back();

                      // Replace this head in place, keep its _id, keep everyone else untouched.
                      final payload = _configHeads.map((h) {
                        if (h['_id'] == head['_id']) {
                          return {
                            '_id': h['_id'],
                            'feeHead': nameCtrl.text.trim(),
                            'associatedTerm': isTerm ? term : null,
                            'isTerm': isTerm,
                          };
                        }
                        return h;
                      }).toList();

                      _isBusy.value = true;
                      final ok = await feeController.ensureFeeConfigV1(
                        schoolId: sid,
                        feeHeads: payload,
                      );
                      _isBusy.value = false;
                      if (ok) await _loadConfigHeads();
                    },
                    child: const Text('Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
          );
        }),
      ),
    );
  }
  void _deleteHead(Map<String, dynamic> head) {
    final name = head['feeHead']?.toString() ?? 'this fee head';
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Fee Head',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kBlueDark)),
        content: Text('Remove "$name" from fee configuration? This affects all classes using it.',
            style: const TextStyle(fontSize: 13, color: _kBlueMuted)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel', style: TextStyle(color: _kBlueMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kDanger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Get.back();
              final sid = _schoolId;
              if (sid == null) return;

              final payload = _configHeads
                  .where((h) => h['_id'] != head['_id'])
                  .toList();

              _isBusy.value = true;
              final ok = await feeController.ensureFeeConfigV1(
                schoolId: sid,
                feeHeads: payload,
              );
              _isBusy.value = false;
              if (ok) await _loadConfigHeads();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
  // ── Add a brand-new global fee head (151A) ─────────────────────
  void _showAddHeadSheet() {
    final nameCtrl = TextEditingController();
    bool isTerm = false;
    String term = _kTerms.first;
    final formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(Get.context!).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: _kBlueBorder, borderRadius: BorderRadius.circular(100)),
                ),
                const Text('Add Fee Head',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kBlueDark)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Fee Head Name',
                    hintText: 'e.g. Admission Fee, Transport Fee…',
                    filled: true, fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Belongs to a term', style: TextStyle(fontSize: 13)),
                  subtitle: const Text('Toggle on for term-based fees', style: TextStyle(fontSize: 11)),
                  value: isTerm,
                  onChanged: (v) => setSheetState(() => isTerm = v),
                ),
                if (isTerm)
                  Wrap(
                    spacing: 8,
                    children: _kTerms.map((t) {
                      final sel = term == t;
                      return GestureDetector(
                        onTap: () => setSheetState(() => term = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? _kBlue.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: sel ? _kBlue : _kBlueBorder),
                          ),
                          child: Text(_termLabel(t),
                              style: TextStyle(fontSize: 12, color: sel ? _kBlue : _kBlueMuted,
                                  fontWeight: FontWeight.w600)),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final sid = _schoolId;
                      if (sid == null) return;
                      Get.back();

                      final payload = [
                        ..._configHeads, // keep existing as-is (with _id)
                        {
                          'feeHead': nameCtrl.text.trim(),
                          'associatedTerm': isTerm ? term : null,
                          'isTerm': isTerm,
                        },
                      ];
                      _isBusy.value = true;
                      final ok = await feeController.ensureFeeConfigV1(
                        schoolId: sid,
                        feeHeads: payload,
                      );
                      _isBusy.value = false;
                      if (ok) await _loadConfigHeads();
                    },
                    child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
          );
        }),
      ),
    );
  }

  // ── Save: amounts for the selected class+type ──────────────────
  Future<void> _saveAmounts() async {
    final sid = _schoolId;
    if (sid == null || selectedClass == null) {
      Get.snackbar('Error', 'Select a class first', backgroundColor: _kDanger, colorText: Colors.white);
      return;
    }
    if (_classHeads.isEmpty) {
      Get.snackbar('Error', 'Select at least one fee head', backgroundColor: _kDanger, colorText: Colors.white);
      return;
    }

    final list = _classHeads.map((h) {
      final name = h['name'] as String;
      final text = _amountControllers[name]?.text.trim() ?? '';
      return {'feeName': name, 'feeAmount': double.tryParse(text) ?? 0.0};
    }).toList();

    final ok = await feeController.saveAllCustomFeeHeads(
      schoolId: sid,
      classId: selectedClass!.id,
      type: selectedStudentType,
      feeHeads: list,
    );

    if (ok) {
      Get.snackbar('Saved', 'Fee structure updated', backgroundColor: _kSuccess, colorText: Colors.white);
      await _loadClassAmounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Fee Setup', style: TextStyle(color: _kBlueDark, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kBlueDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: _kBlue),
            tooltip: 'Add Fee Head',
            onPressed: _showAddHeadSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (_isBusy.value || feeController.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: _kBlue));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildFilters(),
              const SizedBox(height: 14),
              const Text('AVAILABLE FEE HEADS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _kBlueMuted)),
              const SizedBox(height: 8),
              if (_configHeads.isEmpty)
                _emptyBox('No fee heads configured yet. Tap "+" above to add one.')
              else
                ..._configHeads.map(_buildConfigHeadRow),
              const SizedBox(height: 22),
              if (selectedClass != null) ...[
                Text('AMOUNTS — ${selectedClass!.name} · ${selectedStudentType == 'new' ? 'New' : 'Old'} Students',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _kBlueMuted)),
                const SizedBox(height: 8),
                if (_classHeads.isEmpty)
                  _emptyBox('Select fee heads above to set amounts for this class.')
                else
                  ..._classHeads.asMap().entries.map((e) => _buildAmountRow(e.value)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveAmounts,
                    icon: const Icon(Icons.save_rounded, color: Colors.white),
                    label: const Text('Save Fee Structure',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ]),
          );
        }),
      ),
    );
  }

  Widget _buildFilters() {
    return Obx(() {
      final cls = _selectedClass.value;
      final type = _selectedStudentType.value;
      return Wrap(spacing: 8, runSpacing: 8, children: [
        GestureDetector(
          onTap: _showClassSheet,
          child: _pill(
            icon: Icons.class_rounded,
            label: cls?.name ?? 'Select Class',
            active: cls != null,
          ),
        ),
        GestureDetector(
          onTap: () => _selectedStudentType.value = type == 'old' ? 'new' : 'old',
          child: _pill(
            icon: type == 'new' ? Icons.person_add_rounded : Icons.school_rounded,
            label: type == 'new' ? 'New Students' : 'Old Students',
            active: true,
            color: type == 'new' ? _kSuccess : _kBlue,
          ),
        ),
      ]);
    });
  }

  Widget _pill({required IconData icon, required String label, required bool active, Color color = _kBlue}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: active ? color : _kBlueBorder, width: active ? 1.5 : 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: active ? color : _kBlueMuted),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? color : _kBlueMuted)),
      ]),
    );
  }

  Widget _buildConfigHeadRow(Map<String, dynamic> head) {
    final name = head['feeHead']?.toString() ?? '';
    final isTerm = head['isTerm'] == true;
    final term = head['associatedTerm']?.toString();
    final selected = _headInClass(name);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? _kBlue.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? _kBlue.withOpacity(0.4) : _kBlueBorder),
      ),
      child: Row(children: [
        Checkbox(
          value: selected,
          activeColor: _kBlue,
          onChanged: selectedClass == null ? null : (_) => _toggleHeadForClass(name),
        ),
        Expanded(
          child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kBlueDark)),
        ),
        if (isTerm && term != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(color: _kSuccessBg, borderRadius: BorderRadius.circular(6)),
            child: Text(_termLabel(term),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kSuccess)),
          ),
        GestureDetector(
          onTap: () => _showEditHeadSheet(head),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(Icons.edit_rounded, color: _kBlue, size: 16),
          ),
        ),
        GestureDetector(
          onTap: () => _deleteHead(head),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.delete_outline_rounded, color: _kDanger, size: 16),
          ),
        ),
      ]),
    );
  }

  Widget _buildAmountRow(Map<String, dynamic> head) {
    final name = head['name'] as String;
    final ctrl = _amountControllers.putIfAbsent(name, () => TextEditingController());
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBlueBorder),
      ),
      child: Row(children: [
        Expanded(child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kBlueDark))),
        SizedBox(
          width: 120,
          child: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              prefixText: '₹ ',
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _emptyBox(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _kBlueBorder),
    ),
    child: Text(text, style: const TextStyle(fontSize: 12, color: _kBlueMuted), textAlign: TextAlign.center),
  );

  void _showClassSheet() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: Obx(() {
            final sorted = ClassUtils.sortClasses(schoolController.classes);
            return ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              itemCount: sorted.length,
              itemBuilder: (_, i) {
                final c = sorted[i];
                return ListTile(
                  title: Text(c.name),
                  onTap: () {
                    _selectedClass.value = c;
                    Get.back();
                  },
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
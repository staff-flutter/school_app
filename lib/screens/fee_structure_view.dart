import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/fee_structure_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/core/rbac/api_rbac.dart';
import 'package:school_app/core/utils/class_utils.dart';
import 'package:school_app/models/school_models.dart';

// ── Design tokens ──────────────────────────────────────────────
const _kBg         = Color(0xFFF0F5FF);
const _kBlue       = Color(0xFF2563EB);
const _kBlueDark   = Color(0xFF1A2A3A);
const _kBlueMuted  = Color(0xFF90A4BE);
const _kBlueBorder = Color(0xFFDDE6F5);
const _kSuccess    = Color(0xFF059669);
const _kSuccessBg  = Color(0xFFD1FAE5);
const _kDanger     = Color(0xFFDC2626);
const _kDangerBg   = Color(0xFFFEE2E2);
const _kWarning    = Color(0xFFD97706);
const _kWarningBg  = Color(0xFFFEF3C7);

// Cycling colors for fee head cards
const _kFeeColors = [
  (_kBlue,               Color(0xFFEFF6FF)),
  (_kSuccess,            _kSuccessBg),
  (Color(0xFFD97706),    Color(0xFFFEF3C7)),
  (Color(0xFF7C3AED),    Color(0xFFEDE9FE)),
  (Color(0xFF0891B2),    Color(0xFFCFFAFE)),
  (Color(0xFF9333EA),    Color(0xFFF3E8FF)),
  (Color(0xFFDB2777),    Color(0xFFFCE7F3)),
  (Color(0xFF0D9488),    Color(0xFFCCFBF1)),
];

class FeeStructureView extends StatefulWidget {
  const FeeStructureView({super.key});

  @override
  State<FeeStructureView> createState() => _FeeStructureViewState();
}

class _FeeStructureViewState extends State<FeeStructureView> {
  // ── Controllers ────────────────────────────────────────────────
  final feeController    = Get.put(FeeStructureController());
  final schoolController = Get.find<SchoolController>();
  final authController   = Get.find<AuthController>();

  // ── State (Rx so Obx can safely observe them) ─────────────────
  final _selectedClass       = Rxn<SchoolClass>();
  final _selectedStudentType = 'old'.obs;

  SchoolClass? get selectedClass        => _selectedClass.value;
  String       get selectedStudentType  => _selectedStudentType.value;

  // ── Dynamic fee heads (all custom, no hardcoded fields) ───────
  /// Each entry: { 'id': String?, 'name': String, 'amount': double }
  /// 'id' is null for newly added (not yet saved) heads.
  final RxList<Map<String, dynamic>> _feeHeads = <Map<String, dynamic>>[].obs;

  String get currentUserRole =>
      authController.user.value?.role?.toLowerCase() ?? '';

  bool get canSetFee =>
      ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/feestructure/set');
  final _amountControllers = <String, TextEditingController>{};
// 1. Inside _FeeStructureViewState, update your initState:
  @override
  void initState() {
    super.initState();
    everAll([_selectedClass, _selectedStudentType], (_) {
      final schoolId = schoolController.selectedSchool.value?.id
          ?? authController.user.value?.schoolId;
      if (schoolId != null && selectedClass != null) {
        _loadFeeHeads(schoolId, selectedClass!.id);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final school = schoolController.selectedSchool.value;
      if (school != null) schoolController.getAllClasses(school.id);
    });
  }


  void _disposeAmountControllers() {
    for (final c in _amountControllers.values) c.dispose();
    _amountControllers.clear();
  }

  @override
  void dispose() {
    _disposeAmountControllers();
    super.dispose();
  }

// 2. Clean up your callback handlers so they don't fight with the workers:
  void _onClassSelected(SchoolClass cls) {
    _selectedClass.value = cls; // Worker will automatically fetch data now!
  }

  void _onStudentTypeSelected(String type) {
    _selectedStudentType.value = type; // Worker will automatically fetch data now!
  }
  // ── API: load fee heads ────────────────────────────────────────
// ── API: load fee heads (Fully Dynamic Setup) ─────────────────

  Future<void> _loadFeeHeads(String schoolId, String classId) async {
    debugPrint('🔵 _loadFeeHeads: schoolId=$schoolId classId=$classId type=$selectedStudentType');
    feeController.isLoading.value = true;
    _disposeAmountControllers();

    try {
      final heads = await feeController.getCustomFeeHeads(
        schoolId: schoolId,
        classId:  classId,
        type:     selectedStudentType,
      );

      debugPrint('🔵 _loadFeeHeads got ${heads.length} heads: $heads');

      final List<Map<String, dynamic>> built = [];

      for (final h in heads) {
        final name   = (h['feeName'] ?? '').toString();
        final amount = (h['feeAmount'] as num?)?.toDouble() ?? 0.0;

        debugPrint('   building: name="$name" amount=$amount (${amount.runtimeType})');

        final text = amount == 0.0
            ? ''
            : (amount % 1 == 0
            ? amount.toInt().toString()
            : amount.toStringAsFixed(2));

        debugPrint('controller text will be: "$text"');

        _amountControllers[name] = TextEditingController(text: text);

        built.add({'id': h['id']?.toString(), 'name': name, 'amount': amount});
      }

      debugPrint('🔵 _feeHeads built: $built');
      debugPrint('🔵 controllers: ${_amountControllers.map((k, v) => MapEntry(k, v.text))}');

      _feeHeads.assignAll(built);
    } finally {
      feeController.isLoading.value = false;
    }
  }


  // void _onClassSelected(SchoolClass cls) {
  //   _selectedClass.value = cls;
  //   _feeHeads.clear();
  //   final schoolId = schoolController.selectedSchool.value?.id;
  //   if (schoolId != null) _loadFeeHeads(schoolId, cls.id);
  // }
  //
  // void _onStudentTypeSelected(String type) {
  //   _selectedStudentType.value = type;
  //   _feeHeads.clear();
  //   final schoolId = schoolController.selectedSchool.value?.id;
  //   if (schoolId != null && selectedClass != null)
  //     _loadFeeHeads(schoolId, selectedClass!.id);
  // }

  // ── Save all fee heads ─────────────────────────────────────────
  // ── Save all fee heads (Fully Dynamic Setup) ─────────────────
  Future<void> _saveAll() async {
    final schoolId = schoolController.selectedSchool.value?.id
        ?? authController.user.value?.schoolId;

    debugPrint('🔵 _saveAll called');
    debugPrint('   schoolId: $schoolId');
    debugPrint('   selectedClass: ${selectedClass?.name}');
    debugPrint('   _feeHeads count: ${_feeHeads.length}');
    debugPrint('   controllers: ${_amountControllers.map((k, v) => MapEntry(k, v.text))}');

    if (schoolId == null) {
      Get.snackbar('Error', 'School not found',
          backgroundColor: _kDanger, colorText: Colors.white);
      return;
    }
    if (selectedClass == null) {
      Get.snackbar('Error', 'Please select a class first',
          backgroundColor: _kDanger, colorText: Colors.white);
      return;
    }
    if (_feeHeads.isEmpty) {
      Get.snackbar('Error', 'No fee heads to save',
          backgroundColor: _kDanger, colorText: Colors.white);
      return;
    }

    try {
      feeController.isLoading.value = true;

      final feeHeadsList = <Map<String, dynamic>>[];

      for (final h in _feeHeads) {
        final name   = h['name'].toString();
        final ctrl   = _amountControllers[name];
        final text   = ctrl?.text.trim() ?? '';
        final amount = double.tryParse(text) ?? 0.0;

        debugPrint('   → name="$name" ctrlText="$text" parsed=$amount');

        feeHeadsList.add({'feeName': name, 'feeAmount': amount});
      }

      debugPrint('🔵 feeHeadsList to save: $feeHeadsList');

      final ok = await feeController.saveAllCustomFeeHeads(
        schoolId: schoolId,
        classId:  selectedClass!.id,
        type:     selectedStudentType,
        feeHeads: feeHeadsList,
      );

      debugPrint('🔵 saveAllCustomFeeHeads returned: $ok');

      if (!ok) return;

      Get.snackbar('Success', 'Fee amounts saved successfully',
          backgroundColor: _kSuccess, colorText: Colors.white);

      // ✅ Reload to confirm what backend actually stored
      await _loadFeeHeads(schoolId, selectedClass!.id);
    } catch (e, stack) {
      debugPrint('❌ _saveAll error: $e\n$stack');
      Get.snackbar('Error', 'Failed to save',
          backgroundColor: _kDanger, colorText: Colors.white);
    } finally {
      feeController.isLoading.value = false;
    }
  }

  // ── Delete a single fee head ───────────────────────────────────
  void _deleteFeeHead(int index) {
    final head = _feeHeads[index];
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kDangerBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: _kDanger, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Delete Fee Head',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: _kBlueDark)),
        ]),
        content: Text(
          'Remove "${head['name']}" from the fee structure?',
          style: const TextStyle(fontSize: 13, color: _kBlueMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel',
                style: TextStyle(color: _kBlueMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kDanger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Get.back();
              _feeHeads.removeAt(index);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      floatingActionButton: canSetFee
          ? FloatingActionButton(
        onPressed: _showAddOrEditSheet,
        backgroundColor: _kBlue,
        tooltip: 'Add Fee Head',
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded,
            color: Colors.white, size: 26),
      )
          : null,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterChipsRow(),
                  const SizedBox(height: 14),
                  // Summary chip row (total categories + amount)
                  Obx(() {
                    if (_feeHeads.isEmpty) return const SizedBox.shrink();
                    return _buildSummaryRow();
                  }),
                  const SizedBox(height: 10),
                  // Fee heads list
                  Obx(() {
                    if (selectedClass == null) {
                      return _buildEmptyState(
                        icon: Icons.class_rounded,
                        title: 'Select a Class',
                        subtitle: 'Choose a class and student type to view or configure its fee structure.',
                      );
                    }
                    if (feeController.isLoading.value) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: _kBlue),
                        ),
                      );
                    }
                    if (_feeHeads.isEmpty) {
                      return _buildEmptyFeeHeads();
                    }
                    return Column(
                      key: ValueKey(_feeHeads.length),
                      children: List.generate(_feeHeads.length, (i) {
                        final head = _feeHeads[i];
                        final name = head['name'] as String;
                        final c    = _kFeeColors[i % _kFeeColors.length];
                        final ctrl = _amountControllers.putIfAbsent(
                          name, () => TextEditingController(
                          text: () {
                            final amt = (head['amount'] as num?)?.toDouble() ?? 0.0;
                            return amt == 0.0 ? '' : (amt % 1 == 0
                                ? amt.toInt().toString()
                                : amt.toStringAsFixed(2));
                          }(),
                        ),
                        );
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: c.$1.withOpacity(0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: c.$1.withOpacity(0.06),
                                blurRadius: 6, offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Row(children: [
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: c.$1.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.label_important_rounded,
                                  color: c.$1, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: c.$1)),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: ctrl,
                                    enabled: canSetFee,
                                    keyboardType: const TextInputType.numberWithOptions(
                                        decimal: true),
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: _kBlueDark),
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      prefixText: '₹ ',
                                      prefixStyle: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: _kBlueMuted),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                      filled: true,
                                      fillColor: c.$2,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: c.$1.withOpacity(0.3)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: c.$1.withOpacity(0.3)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: c.$1, width: 1.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                        );
                      }),
                    );
                  }),
                  const SizedBox(height: 16),
                  if (canSetFee) _buildSaveButton(),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBlueBorder),
        boxShadow: [
          BoxShadow(
            color: _kBlueBorder.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: _kBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.payments_rounded, color: _kBlue, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Fee Structure',
                style: TextStyle(color: _kBlueDark, fontSize: 15,
                    fontWeight: FontWeight.w700)),
            Text('Add & manage fee heads per class',
                style: TextStyle(color: _kBlueMuted, fontSize: 11)),
          ]),
        ),
        if (canSetFee)
          GestureDetector(
            onTap: _showAddOrEditSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _kBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kBlue.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.add_rounded, color: _kBlue, size: 14),
                SizedBox(width: 4),
                Text('Add Fee Head',
                    style: TextStyle(
                        color: _kBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
      ]),
    );
  }

  // ── Filter chips ───────────────────────────────────────────────
  Widget _buildFilterChipsRow() {
    return Obx(() {
      final cls  = _selectedClass.value;
      final type = _selectedStudentType.value;
      return Row(children: [
        GestureDetector(
          onTap: _showClassSheet,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: cls != null ? _kBlue.withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: cls != null ? _kBlue : _kBlueBorder,
                width: cls != null ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kBlueBorder.withOpacity(0.4),
                  blurRadius: 4, offset: const Offset(0, 1),
                )
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.class_rounded,
                  size: 14,
                  color: cls != null ? _kBlue : _kBlueMuted),
              const SizedBox(width: 6),
              Text(
                cls?.name ?? 'Select Class',
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: cls != null ? _kBlue : _kBlueMuted,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: cls != null ? _kBlue : _kBlueMuted),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _showStudentTypeSheet,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: type == 'new' ? _kSuccessBg : _kBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: type == 'new' ? _kSuccess : _kBlue,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kBlueBorder.withOpacity(0.4),
                  blurRadius: 4, offset: const Offset(0, 1),
                )
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                type == 'new' ? Icons.person_add_rounded : Icons.school_rounded,
                size: 14,
                color: type == 'new' ? _kSuccess : _kBlue,
              ),
              const SizedBox(width: 6),
              Text(
                type == 'new' ? 'New Students' : 'Old Students',
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: type == 'new' ? _kSuccess : _kBlue,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: type == 'new' ? _kSuccess : _kBlue),
            ]),
          ),
        ),
      ]);
    });
  }

  // ── Summary row ────────────────────────────────────────────────
  Widget _buildSummaryRow() {
    final total = _feeHeads.fold<double>(
        0.0, (sum, h) => sum + ((h['amount'] ?? 0.0) as double));
    final count = _feeHeads.length;

    return Row(children: [
      _summaryChip(Icons.category_rounded, '$count Fee Heads', _kBlue),
      const SizedBox(width: 8),
      _summaryChip(Icons.currency_rupee_rounded,
          total % 1 == 0
              ? total.toInt().toString()
              : total.toStringAsFixed(2),
          _kSuccess),
    ]);
  }

  Widget _summaryChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  // ── Fee heads list ─────────────────────────────────────────────
  Widget _buildFeeHeadsList() {
    // ✅ Plain Column — NOT Obx — so TextField controllers stay stable
    return Column(
      children: List.generate(_feeHeads.length, (i) {
        final head = _feeHeads[i];
        final name = head['name'] as String;
        final c    = _kFeeColors[i % _kFeeColors.length];
        final ctrl = _amountControllers.putIfAbsent(
            name, () => TextEditingController());

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.$1.withOpacity(0.2)),
            boxShadow: [BoxShadow(
                color: c.$1.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                  color: c.$1.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.label_important_rounded,
                  color: c.$1, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: c.$1)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: ctrl,         // ✅ stable
                    enabled: canSetFee,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kBlueDark),
                    decoration: InputDecoration(
                      hintText: '0',
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _kBlueMuted),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: c.$2,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                          BorderSide(color: c.$1.withOpacity(0.3))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                          BorderSide(color: c.$1.withOpacity(0.3))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                          BorderSide(color: c.$1, width: 1.5)),
                    ),
                    // ✅ No onChanged — read from controller on save only
                  ),
                ],
              ),
            ),
          ]),
        );
      }),
    );
  }

  Widget _buildFeeHeadCard(
      int index, Map<String, dynamic> head, Color fg, Color bg) {
    final name   = (head['name'] ?? 'Fee Head').toString();
    final amount = (head['amount'] ?? 0.0) as double;
    final isStd  = head['isStandard'] == true;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: fg.withOpacity(0.08),
            blurRadius: 6, offset: const Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: fg.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isStd ? Icons.receipt_long_rounded : Icons.label_important_rounded,
            color: fg, size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(name,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: fg)),
              if (isStd) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: fg.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Standard',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: fg)),
                ),
              ],
            ]),
            const SizedBox(height: 3),
            Text(
              '₹ ${amount % 1 == 0 ? amount.toInt() : amount.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _kBlueDark),
            ),
          ]),
        ),
        // Edit + Delete buttons (only if canSetFee)
        if (canSetFee) ...[
          GestureDetector(
            onTap: () => _showAddOrEditSheet(
                editIndex: index, existing: head),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _kBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_rounded,
                  color: _kBlue, size: 15),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _deleteFeeHead(index),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _kDangerBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: _kDanger, size: 15),
            ),
          ),
        ],
      ]),
    );
  }

  // ── Empty states ───────────────────────────────────────────────
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBlueBorder),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: _kBlue.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _kBlue, size: 26),
        ),
        const SizedBox(height: 12),
        Text(title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: _kBlueDark)),
        const SizedBox(height: 6),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: _kBlueMuted)),
      ]),
    );
  }

  Widget _buildEmptyFeeHeads() {
    return _buildEmptyState(
      icon: Icons.receipt_long_rounded,
      title: 'No Fee Heads Configured',
      subtitle:
      'Go to Fee Configuration first to add fee head names for ${selectedClass?.name ?? 'this class'}, then come back here to set amounts.',
    );
  }

  // ── Save button ────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return Obx(() {
      final disabled = selectedClass == null ||
          feeController.isLoading.value || _feeHeads.isEmpty;
      return SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: disabled
                ? LinearGradient(
                colors: [Colors.grey.shade300, Colors.grey.shade300])
                : const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: disabled
                ? []
                : [
              BoxShadow(
                color: _kBlue.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: disabled ? null : _saveAll,
            icon: feeController.isLoading.value
                ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save_rounded,
                color: Colors.white, size: 18),
            label: Text(
              feeController.isLoading.value ? 'Saving…' : 'Save Fee Structure',
              style: TextStyle(
                color: disabled ? Colors.grey.shade500 : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // ADD / EDIT FEE HEAD BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════
  void _showAddOrEditSheet({int? editIndex, Map<String, dynamic>? existing}) {
    if (selectedClass == null) {
      Get.snackbar(
          'Select a Class', 'Please select a class before adding fee heads.',
          backgroundColor: _kDanger, colorText: Colors.white);
      return;
    }

    final isEdit = editIndex != null && existing != null;
    final nameCtrl =
    TextEditingController(text: isEdit ? existing['name'] : '');
    final amountCtrl = TextEditingController(
        text: isEdit
            ? ((existing['amount'] as double?) ?? 0.0)
            .toStringAsFixed(
            ((existing['amount'] as double?) ?? 0.0) % 1 == 0 ? 0 : 2)
            : '');
    final formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(Get.context!).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: _kBlueBorder,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),

              // Title row
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isEdit
                        ? Icons.edit_rounded
                        : Icons.add_circle_outline_rounded,
                    color: _kBlue, size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isEdit ? 'Edit Fee Head' : 'Add Fee Head',
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: _kBlueDark)),
                        Text(
                          isEdit
                              ? 'Update this fee category'
                              : 'Create a new fee category',
                          style: const TextStyle(
                              fontSize: 11, color: _kBlueMuted),
                        ),
                      ]),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.close_rounded,
                      color: _kBlueMuted, size: 22),
                ),
              ]),

              const SizedBox(height: 8),
              Divider(color: _kBlueBorder),
              const SizedBox(height: 16),

              // Context pill
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _kBlue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: _kBlue.withOpacity(0.2)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.info_outline_rounded,
                      color: _kBlueMuted, size: 13),
                  const SizedBox(width: 6),
                  Text(
                    '${selectedClass!.name} · '
                        '${selectedStudentType == 'new' ? 'New Students' : 'Old Students'}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: _kBlueMuted,
                        fontWeight: FontWeight.w500),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // Name field
              TextFormField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 14, color: _kBlueDark),
                decoration: InputDecoration(
                  labelText: 'Fee Head Name',
                  hintText: 'e.g. Admission Fee, Lab Fee, Sports Fee…',
                  prefixIcon: const Icon(Icons.label_outline_rounded,
                      color: _kBlueMuted, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _kBlueBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _kBlueBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kBlue, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kDanger),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Fee head name is required';
                  return null;
                },
              ),

              const SizedBox(height: 14),

              // Amount field
              TextFormField(
                controller: amountCtrl,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 14, color: _kBlueDark),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  hintText: '0',
                  prefixText: '₹ ',
                  prefixIcon: const Icon(Icons.currency_rupee_rounded,
                      color: _kBlueMuted, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _kBlueBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _kBlueBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kBlue, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kDanger),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Amount is required';
                  if (double.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: _kBlueBorder),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: _kBlueMuted, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _kBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _submitFeeHead(
                          formKey, nameCtrl, amountCtrl,
                          editIndex: editIndex, existing: existing),
                      icon: Icon(
                        isEdit ? Icons.check_rounded : Icons.add_rounded,
                        color: Colors.white, size: 18,
                      ),
                      label: Text(
                        isEdit ? 'Update Fee Head' : 'Add Fee Head',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  void _submitFeeHead(
      GlobalKey<FormState> formKey,
      TextEditingController nameCtrl,
      TextEditingController amountCtrl, {
        int? editIndex,
        Map<String, dynamic>? existing,
      }) {
    if (!formKey.currentState!.validate()) return;

    final name   = nameCtrl.text.trim();
    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
    final isEdit = editIndex != null && existing != null;

    if (isEdit) {
      // Update in place
      _feeHeads[editIndex] = {
        ...existing,
        'name':   name,
        'amount': amount,
      };
    } else {
      // Add new (not yet persisted; saved when user taps Save)
      _feeHeads.add({
        'id':         null,
        'name':       name,
        'amount':     amount,
        'isStandard': false,
      });
    }

    Get.back();
    Get.snackbar(
      isEdit ? 'Updated' : 'Added',
      isEdit
          ? '"$name" updated. Tap Save to persist.'
          : '"$name" added. Tap Save to persist.',
      backgroundColor: _kSuccess,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  // ── Class bottom sheet ─────────────────────────────────────────
  void _showClassSheet() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: _kBlueBorder,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(children: [
              const Text('Select Class',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _kBlueDark)),
              const Spacer(),
              GestureDetector(
                onTap: () => Get.back(),
                child: const Icon(Icons.close_rounded,
                    color: _kBlueMuted, size: 22),
              ),
            ]),
          ),
          Divider(height: 1, color: _kBlueBorder),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 380),
            child: Obx(() {
              final sorted = ClassUtils.sortClasses(schoolController.classes);
              if (sorted.isEmpty)
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No classes available',
                        style: TextStyle(color: _kBlueMuted, fontSize: 14)),
                  ),
                );
              return ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                itemCount: sorted.length,
                itemBuilder: (_, i) {
                  final c = sorted[i];
                  final isSelected = selectedClass?.id == c.id;
                  return GestureDetector(
                    onTap: () {
                      _onClassSelected(c);
                      Get.back();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _kBlue.withOpacity(0.08)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? _kBlue : _kBlueBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: isSelected ? _kBlue : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: isSelected ? _kBlue : _kBlueBorder),
                          ),
                          child: Icon(
                            ClassUtils.getClassIcon(c.name),
                            size: 16,
                            color: isSelected ? Colors.white : _kBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(c.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected ? _kBlue : _kBlueDark,
                              )),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: _kBlue, size: 18),
                      ]),
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 20),
        ]),
      ),
      isScrollControlled: true,
    );
  }

  // ── Student type bottom sheet ──────────────────────────────────
  void _showStudentTypeSheet() {
    final options = [
      (
      'old',
      'Old Students',
      'Existing enrolled students',
      Icons.school_rounded,
      _kBlue,
      _kBlue.withOpacity(0.08),
      ),
      (
      'new',
      'New Students',
      'Newly admitted students',
      Icons.person_add_rounded,
      _kSuccess,
      _kSuccessBg,
      ),
    ];

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: _kBlueBorder,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(children: [
              const Text('Student Type',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _kBlueDark)),
              const Spacer(),
              GestureDetector(
                onTap: () => Get.back(),
                child: const Icon(Icons.close_rounded,
                    color: _kBlueMuted, size: 22),
              ),
            ]),
          ),
          Divider(height: 1, color: _kBlueBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
            child: Column(
              children: options.map((o) {
                final isSelected = selectedStudentType == o.$1;
                return GestureDetector(
                  onTap: () {
                    _onStudentTypeSelected(o.$1);
                    Get.back();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? o.$6 : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? o.$5 : _kBlueBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: isSelected ? o.$5 : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isSelected ? o.$5 : _kBlueBorder),
                        ),
                        child: Icon(o.$4,
                            size: 20,
                            color: isSelected ? Colors.white : _kBlueMuted),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(o.$2,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? o.$5 : _kBlueDark,
                                  )),
                              const SizedBox(height: 2),
                              Text(o.$3,
                                  style: const TextStyle(
                                      fontSize: 11, color: _kBlueMuted)),
                            ]),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded,
                            color: o.$5, size: 20),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
        ]),
      ),
      isScrollControlled: true,
    );
  }
}
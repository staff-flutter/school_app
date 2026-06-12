import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/accounting_controller.dart';
import 'package:school_app/controllers/fee_structure_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/core/rbac/api_rbac.dart';
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

  // ── State ──────────────────────────────────────────────────────
  SchoolClass? selectedClass;
  String selectedStudentType = 'old'; // 'old' | 'new'

  // ── Fee text controllers ───────────────────────────────────────
  final _admissionFeeCtrl    = TextEditingController();
  final _firstTermCtrl       = TextEditingController();
  final _secondTermCtrl      = TextEditingController();
  final _annualFeeCtrl       = TextEditingController();
  final _busFirstTermCtrl    = TextEditingController();
  final _busSecondTermCtrl   = TextEditingController();

  String get currentUserRole =>
      authController.user.value?.role?.toLowerCase() ?? '';

  bool get canSetFee =>
      ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/feestructure/set');

  @override
  void initState() {
    super.initState();

    _firstTermCtrl.addListener(_calculateAndSetAnnualFee);
    _secondTermCtrl.addListener(_calculateAndSetAnnualFee);
    _busFirstTermCtrl.addListener(_calculateAndSetAnnualFee);
    _busSecondTermCtrl.addListener(_calculateAndSetAnnualFee);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final school = schoolController.selectedSchool.value;
      if (school != null) schoolController.getAllClasses(school.id);
    });
  }

  @override
  void dispose() {
    _admissionFeeCtrl.dispose();
    _firstTermCtrl.dispose();
    _secondTermCtrl.dispose();
    _annualFeeCtrl.dispose();
    _busFirstTermCtrl.dispose();
    _busSecondTermCtrl.dispose();
    super.dispose();
  }

  // ── API: load existing fee structure ──────────────────────────
  Future<void> _loadFeeStructure(String schoolId, String classId) async {
    final data = await feeController.getFeeStructureByClass(
      schoolId, classId,
      type: selectedStudentType,
    );
    final feeHead = data?['feeHead'] ?? data?['data']?['feeHead'] ?? {};
    setState(() {
      _admissionFeeCtrl.text  = feeHead['admissionFee']?.toString()    ?? '';
      _firstTermCtrl.text     = feeHead['firstTermAmt']?.toString()     ?? '';
      _secondTermCtrl.text    = feeHead['secondTermAmt']?.toString()    ?? '';
    //  _annualFeeCtrl.text     = feeHead['annualFee']?.toString()        ?? '';
      _busFirstTermCtrl.text  = feeHead['busFirstTermAmt']?.toString()  ?? '';
      _busSecondTermCtrl.text = feeHead['busSecondTermAmt']?.toString() ?? '';

      _calculateAndSetAnnualFee();
    });
  }

  void _clearForm() {
    _admissionFeeCtrl.clear();
    _firstTermCtrl.clear();
    _secondTermCtrl.clear();
    _annualFeeCtrl.clear();
    _busFirstTermCtrl.clear();
    _busSecondTermCtrl.clear();
  }

  void _onClassSelected(SchoolClass cls) {
    setState(() { selectedClass = cls; });
    final schoolId = schoolController.selectedSchool.value?.id;
    if (schoolId != null) _loadFeeStructure(schoolId, cls.id);
  }

  void _onStudentTypeSelected(String type) {
    setState(() { selectedStudentType = type; });
    final schoolId = schoolController.selectedSchool.value?.id;
    if (schoolId != null && selectedClass != null)
      _loadFeeStructure(schoolId, selectedClass!.id);
  }

  // ── API: save ─────────────────────────────────────────────────
  void _save() {
    final schoolId = schoolController.selectedSchool.value?.id
        ?? authController.user.value?.schoolId;
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
    feeController.setFeeStructure(
      schoolId:  schoolId,
      classId:   selectedClass!.id,
      type:      selectedStudentType,
      feeHead: {
        'admissionFee':    double.tryParse(_admissionFeeCtrl.text)  ?? 0,
        'firstTermAmt':    double.tryParse(_firstTermCtrl.text)     ?? 0,
        'secondTermAmt':   double.tryParse(_secondTermCtrl.text)    ?? 0,
        'annualFee':       double.tryParse(_annualFeeCtrl.text)     ?? 0,
        'busFirstTermAmt': double.tryParse(_busFirstTermCtrl.text)  ?? 0,
        'busSecondTermAmt':double.tryParse(_busSecondTermCtrl.text) ?? 0,
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterChipsRow(),
                  const SizedBox(height: 14),
                  _buildFeeCard(),
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
            Text('Configure class-wise fee heads',
                style: TextStyle(color: _kBlueMuted, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  // ── Filter chips row: Class + Student Type ─────────────────────
  Widget _buildFilterChipsRow() {
    return Row(children: [
      // Class chip
      GestureDetector(
        onTap: _showClassSheet,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selectedClass != null
                ? _kBlue.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selectedClass != null ? _kBlue : _kBlueBorder,
              width: selectedClass != null ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _kBlueBorder.withOpacity(0.4),
                blurRadius: 4,
                offset: const Offset(0, 1),
              )
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.class_rounded,
                size: 14,
                color: selectedClass != null ? _kBlue : _kBlueMuted),
            const SizedBox(width: 6),
            Text(
              selectedClass?.name ?? 'Select Class',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selectedClass != null ? _kBlue : _kBlueMuted,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: selectedClass != null ? _kBlue : _kBlueMuted),
          ]),
        ),
      ),
      const SizedBox(width: 8),

      // Student type chip
      GestureDetector(
        onTap: _showStudentTypeSheet,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selectedStudentType == 'new'
                ? _kSuccessBg : _kBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selectedStudentType == 'new' ? _kSuccess : _kBlue,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _kBlueBorder.withOpacity(0.4),
                blurRadius: 4,
                offset: const Offset(0, 1),
              )
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              selectedStudentType == 'new'
                  ? Icons.person_add_rounded : Icons.school_rounded,
              size: 14,
              color: selectedStudentType == 'new' ? _kSuccess : _kBlue,
            ),
            const SizedBox(width: 6),
            Text(
              selectedStudentType == 'new' ? 'New Students' : 'Old Students',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selectedStudentType == 'new' ? _kSuccess : _kBlue,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: selectedStudentType == 'new' ? _kSuccess : _kBlue),
          ]),
        ),
      ),
    ]);
  }

  // ── Fee fields card ────────────────────────────────────────────
  Widget _buildFeeCard() {
    final fields = [
      ('Admission Fee',       _admissionFeeCtrl,  Icons.login_rounded,                   _kSuccess,            _kSuccessBg,                  'One-time admission charge',true),
      ('First Term',          _firstTermCtrl,     Icons.looks_one_rounded,               _kBlue,               _kBlue.withOpacity(0.08),     'Tuition fee for first term',true),
      ('Second Term',         _secondTermCtrl,    Icons.looks_two_rounded,               const Color(0xFFD97706), const Color(0xFFFEF3C7),   'Tuition fee for second term',true),
      ('Annual Fee',          _annualFeeCtrl,     Icons.calendar_today_rounded,          const Color(0xFF7C3AED), const Color(0xFFEDE9FE),   'Calculated automatically from terms',false),
      ('Bus First Term',      _busFirstTermCtrl,  Icons.directions_bus_rounded,          const Color(0xFF0891B2), const Color(0xFFCFFAFE),   'Transport fee for first term',true),
      ('Bus Second Term',     _busSecondTermCtrl, Icons.directions_bus_filled_rounded,   const Color(0xFF9333EA), const Color(0xFFF3E8FF),   'Transport fee for second term',true),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBlueBorder),
        boxShadow: [
          BoxShadow(
            color: _kBlueBorder.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(children: [
        // Card header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: _kBlue.withOpacity(0.05),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(bottom: BorderSide(color: _kBlueBorder)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _kBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  color: _kBlue, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Fee Configuration',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: _kBlueDark)),
            const Spacer(),
            if (selectedClass != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${selectedClass!.name} · ${selectedStudentType == 'new' ? 'New' : 'Old'}',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _kBlue),
                ),
              ),
          ]),
        ),

        // Fee rows
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: fields.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _feeField(
                label:      f.$1,
                ctrl:       f.$2,
                icon:       f.$3,
                fg:         f.$4,
                bg:         f.$5,
                helperText: f.$6,
                enabled:    canSetFee && f.$7,
              ),
            )).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _feeField({
    required String label,
    required TextEditingController ctrl,
    required IconData icon,
    required Color fg,
    required Color bg,
    required String helperText,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(children: [
        Icon(icon, color: fg, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: fg)),
            const SizedBox(height: 5),
            TextFormField(
              controller: ctrl,
              enabled: enabled,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                  fontSize: 14, color: _kBlueDark),
              decoration: InputDecoration(
                prefixText: '₹ ',
                hintText: '0',
                helperText: helperText,
                helperStyle: TextStyle(
                    fontSize: 10,
                    color: fg.withOpacity(0.6)),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                    BorderSide(color: fg.withOpacity(0.3))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                    BorderSide(color: fg.withOpacity(0.3))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: fg, width: 1.5)),
                disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: fg.withOpacity(0.15))),
              ),
            ),
          ],
        )),
      ]),
    );
  }

  // ── Save button ────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return Obx(() => SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: (selectedClass == null || feeController.isLoading.value)
              ? LinearGradient(
              colors: [Colors.grey.shade300, Colors.grey.shade300])
              : const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: (selectedClass == null || feeController.isLoading.value)
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
          onPressed: (selectedClass == null || feeController.isLoading.value)
              ? null
              : _save,
          icon: feeController.isLoading.value
              ? const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.save_rounded,
              color: Colors.white, size: 18),
          label: Text(
            feeController.isLoading.value
                ? 'Saving…'
                : 'Save Fee Structure',
            style: TextStyle(
              color: (selectedClass == null ||
                  feeController.isLoading.value)
                  ? Colors.grey.shade500
                  : Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    ));
  }
  void _calculateAndSetAnnualFee() {
    // Parse numbers safely. If empty or invalid string, defaults to 0.0
    final double admission   = double.tryParse(_admissionFeeCtrl.text)   ?? 0.0;
    final double firstTerm   = double.tryParse(_firstTermCtrl.text)   ?? 0.0;
    final double secondTerm  = double.tryParse(_secondTermCtrl.text)  ?? 0.0;
    final double busFirst    = double.tryParse(_busFirstTermCtrl.text) ?? 0.0;
    final double busSecond   = double.tryParse(_busSecondTermCtrl.text) ?? 0.0;

    final double totalSum = admission + firstTerm + secondTerm + busFirst + busSecond;

    // Update the Annual Fee controller.
    // If the total ends in .0, we can display it cleaner as an integer format.
    _annualFeeCtrl.text = totalSum % 1 == 0
        ? totalSum.toInt().toString()
        : totalSum.toStringAsFixed(2);
  }
  // ── Bottom sheet: class picker ─────────────────────────────────
  void _showClassSheet() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
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
              final sorted =
              ClassUtils.sortClasses(schoolController.classes);
              if (sorted.isEmpty)
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No classes available',
                        style: TextStyle(
                            color: _kBlueMuted, fontSize: 14)),
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
                            color: isSelected
                                ? _kBlue
                                : Colors.white,
                            borderRadius:
                            BorderRadius.circular(8),
                            border: Border.all(
                                color: isSelected
                                    ? _kBlue
                                    : _kBlueBorder),
                          ),
                          child: Icon(
                            ClassUtils.getClassIcon(c.name),
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : _kBlue,
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
                                color: isSelected
                                    ? _kBlue
                                    : _kBlueDark,
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

  // ── Bottom sheet: student type picker ─────────────────────────
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
                                    fontSize: 11,
                                    color: _kBlueMuted)),
                          ],
                        ),
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
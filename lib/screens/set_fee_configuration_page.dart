import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/fee_structure_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/models/school_models.dart';
import 'package:school_app/services/api_service.dart';

const _kBg         = Color(0xFFF0F5FF);
const _kBlue       = Color(0xFF2563EB);
const _kBlueDark   = Color(0xFF1A2A3A);
const _kBlueMuted  = Color(0xFF90A4BE);
const _kBlueBorder = Color(0xFFDDE6F5);
const _kSuccess    = Color(0xFF059669);
const _kDanger     = Color(0xFFDC2626);
const _kDangerBg   = Color(0xFFFEE2E2);

class SetFeeConfigurationPage extends StatefulWidget {
  const SetFeeConfigurationPage({super.key});

  @override
  State<SetFeeConfigurationPage> createState() =>
      _SetFeeConfigurationPageState();
}

class _SetFeeConfigurationPageState extends State<SetFeeConfigurationPage> {
  final feeController    = Get.find<FeeStructureController>();
  final authController   = Get.find<AuthController>();
  final schoolController = Get.find<SchoolController>();

  final RxList<SchoolClass> _classes          = <SchoolClass>[].obs;
  final RxList<String>      _feeHeadNames     = <String>[].obs;
  final RxBool              _isLoading        = false.obs;

  SchoolClass? selectedClass;
  String       selectedStudentType = 'old';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final schoolId = _schoolId;
      if (schoolId != null) {
        await _loadClasses(schoolId);
        await _loadFeeHeadNames(schoolId);
      }
    });
  }

  String? get _schoolId =>
      schoolController.selectedSchool.value?.id ??
          authController.user.value?.schoolId;

  // ── Load classes ───────────────────────────────────────────────
  Future<void> _loadClasses(String schoolId) async {
    await schoolController.getAllClasses(schoolId);
    _classes.assignAll(schoolController.classes);
    if (_classes.isNotEmpty && selectedClass == null) {
      selectedClass = _classes.first;
      setState(() {});
      await _loadExistingForClass(schoolId, selectedClass!.id);
    }
  }

  // ── Load fee head NAMES from fee-config (global for school) ───
  Future<void> _loadFeeHeadNames(String schoolId) async {
    try {
      _isLoading.value = true;
      final response = await Get.find<ApiService>()
          .get('/api/fee-config/get/$schoolId');
      if (response.data?['ok'] == true) {
        final data = response.data['data'];
        if (data?['feeHeads'] is List) {
          _feeHeadNames.assignAll(List<String>.from(data['feeHeads']));
          return;
        }
      }
      _feeHeadNames.clear();
    } catch (e) {
      debugPrint('⚠️ fetch fee-config error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // ── Which names are already selected for this class+type ──────
  final RxList<String> _selectedNames = <String>[].obs;

  Future<void> _loadExistingForClass(String schoolId, String classId) async {
    try {
      _isLoading.value = true;
      final heads = await feeController.getCustomFeeHeads(
        schoolId: schoolId,
        classId:  classId,
        type:     selectedStudentType,
      );
      _selectedNames.assignAll(
        heads.map((h) => (h['feeName'] ?? '').toString()).where((n) => n.isNotEmpty),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // ── Add new fee head name globally ─────────────────────────────
  void _showAddNameDialog() {
    final ctrl    = TextEditingController();
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
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: _kBlueBorder,
                    borderRadius: BorderRadius.circular(100)),
              ),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: _kBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.add_circle_outline_rounded,
                      color: _kBlue, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add Fee Head Name',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _kBlueDark)),
                      Text('This will be available across all classes',
                          style:
                          TextStyle(fontSize: 11, color: _kBlueMuted)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.close_rounded,
                      color: _kBlueMuted, size: 22),
                ),
              ]),
              const SizedBox(height: 20),
              TextFormField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 14, color: _kBlueDark),
                decoration: InputDecoration(
                  labelText: 'Fee Head Name',
                  hintText: 'e.g. Tuition Fee, Lab Fee…',
                  prefixIcon: const Icon(Icons.label_outline_rounded,
                      color: _kBlueMuted, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(color: _kBlueBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(color: _kBlueBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(color: _kBlue, width: 1.5)),
                  errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(color: _kDanger)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Name is required';
                  if (_feeHeadNames.contains(v.trim()))
                    return 'Already exists';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: _kBlueBorder),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(color: _kBlueMuted)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFF2563EB),
                        Color(0xFF1D4ED8)
                      ]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final name  = ctrl.text.trim();
                        final sid   = _schoolId;
                        if (sid == null) return;
                        Get.back();
                        _isLoading.value = true;
                        try {
                          // Register globally
                          await feeController.ensureFeeConfig(
                            schoolId: sid,
                            feeHeads: [..._feeHeadNames, name],
                          );
                          await _loadFeeHeadNames(sid);
                        } finally {
                          _isLoading.value = false;
                        }
                      },
                      icon: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 18),
                      label: const Text('Add',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
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

  // ── Edit fee head name globally ────────────────────────────────
  void _showEditNameDialog(int index) {
    final oldName = _feeHeadNames[index];
    final ctrl    = TextEditingController(text: oldName);
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
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: _kBlueBorder,
                    borderRadius: BorderRadius.circular(100)),
              ),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: _kBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.edit_rounded,
                      color: _kBlue, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Edit Fee Head Name',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _kBlueDark)),
                      Text('Updates globally across all classes',
                          style:
                          TextStyle(fontSize: 11, color: _kBlueMuted)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.close_rounded,
                      color: _kBlueMuted, size: 22),
                ),
              ]),
              const SizedBox(height: 20),
              TextFormField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 14, color: _kBlueDark),
                decoration: InputDecoration(
                  labelText: 'Fee Head Name',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(color: _kBlueBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(color: _kBlueBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(color: _kBlue, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Name is required';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: _kBlueBorder),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(color: _kBlueMuted)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlue,
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final newName = ctrl.text.trim();
                      final sid    = _schoolId;
                      if (sid == null) return;
                      Get.back();
                      _isLoading.value = true;
                      try {
                        // Replace old name with new name in the global list
                        final updated = _feeHeadNames.toList();
                        updated[index] = newName;
                        await feeController.ensureFeeConfig(
                          schoolId: sid,
                          feeHeads: updated,
                        );
                        await _loadFeeHeadNames(sid);
                      } finally {
                        _isLoading.value = false;
                      }
                    },
                    icon: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18),
                    label: const Text('Update',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Delete fee head name globally ──────────────────────────────
  void _deleteName(int index) {
    final name = _feeHeadNames[index];
    Get.dialog(AlertDialog(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: _kDangerBg,
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.delete_outline_rounded,
              color: _kDanger, size: 18),
        ),
        const SizedBox(width: 10),
        const Text('Delete Fee Head',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kBlueDark)),
      ]),
      content: Text('Remove "$name" from all fee configurations?',
          style: const TextStyle(fontSize: 13, color: _kBlueMuted)),
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
          onPressed: () async {
            Get.back();
            final sid = _schoolId;
            if (sid == null) return;
            _isLoading.value = true;
            try {
              final updated = _feeHeadNames.toList()..removeAt(index);
              await feeController.ensureFeeConfig(
                schoolId: sid,
                feeHeads: updated,
              );
              await _loadFeeHeadNames(sid);
            } finally {
              _isLoading.value = false;
            }
          },
          child: const Text('Delete',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }

  // ── Save which names are selected for this class+type ─────────
  Future<void> _saveSelection() async {
    final sid = _schoolId;
    if (sid == null || selectedClass == null) return;
    if (_selectedNames.isEmpty) {
      Get.snackbar('Warning', 'Select at least one fee head',
          backgroundColor: _kDanger, colorText: Colors.white);
      return;
    }

    _isLoading.value = true;
    try {
      // Save selected heads with amount 0 — amounts set in FeeStructureView
      final feeHeadsList = _selectedNames
          .map((n) => {'feeName': n, 'feeAmount': 0.0})
          .toList();

      final ok = await feeController.saveAllCustomFeeHeads(
        schoolId: sid,
        classId:  selectedClass!.id,
        type:     selectedStudentType,
        feeHeads: feeHeadsList,
      );

      if (ok) {
        Get.snackbar(
          'Saved',
          'Fee heads configured. Now go to Fee Structure to set amounts.',
          backgroundColor: _kSuccess,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Fee Configuration',
            style: TextStyle(
                color: _kBlueDark,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _kBlueDark, size: 20),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: _kBlue, size: 24),
            tooltip: 'Add Fee Head Name',
            onPressed: _showAddNameDialog,
          ),
        ],
      ),
      body: Obx(() {
        final sid = _schoolId;
        return Column(children: [
          // ── Filters ──────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(children: [
              // Class dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CLASS',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _kBlueMuted)),
                    const SizedBox(height: 6),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: _kBg,
                          borderRadius: BorderRadius.circular(10)),
                      child: DropdownButtonHideUnderline(
                        child: Obx(() => DropdownButton<SchoolClass>(
                          value: selectedClass,
                          isExpanded: true,
                          hint: const Text('Select Class',
                              style: TextStyle(fontSize: 13)),
                          items: _classes
                              .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.name,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _kBlueDark)),
                          ))
                              .toList(),
                          onChanged: (val) async {
                            setState(() => selectedClass = val);
                            if (sid != null && val != null) {
                              await _loadExistingForClass(sid, val.id);
                            }
                          },
                        )),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Student type dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TYPE',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _kBlueMuted)),
                    const SizedBox(height: 6),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: _kBg,
                          borderRadius: BorderRadius.circular(10)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedStudentType,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                                value: 'old',
                                child: Text('Old Students',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _kBlueDark))),
                            DropdownMenuItem(
                                value: 'new',
                                child: Text('New Students',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _kBlueDark))),
                          ],
                          onChanged: (val) async {
                            if (val == null) return;
                            setState(() => selectedStudentType = val);
                            if (sid != null && selectedClass != null) {
                              await _loadExistingForClass(
                                  sid, selectedClass!.id);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),

          // ── Fee head names list with checkboxes ───────────────
          Expanded(
            child: _isLoading.value
                ? const Center(
                child: CircularProgressIndicator(color: _kBlue))
                : _feeHeadNames.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                        color: _kBlue.withOpacity(0.08),
                        shape: BoxShape.circle),
                    child: const Icon(
                        Icons.receipt_long_rounded,
                        color: _kBlue,
                        size: 30),
                  ),
                  const SizedBox(height: 12),
                  const Text('No fee heads yet',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _kBlueDark,
                          fontSize: 15)),
                  const SizedBox(height: 6),
                  const Text(
                      'Tap "+" above to add fee head names',
                      style: TextStyle(
                          fontSize: 12, color: _kBlueMuted)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _feeHeadNames.length,
              itemBuilder: (context, i) {
                final name       = _feeHeadNames[i];
                final isSelected = _selectedNames.contains(name);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _kBlue.withOpacity(0.04)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isSelected
                            ? _kBlue.withOpacity(0.4)
                            : _kBlueBorder),
                  ),
                  child: Row(children: [
                    // Checkbox to select for this class
                    Expanded(
                      child: CheckboxListTile(
                        title: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _kBlueDark,
                                fontSize: 14)),
                        activeColor: _kBlue,
                        value: isSelected,
                        controlAffinity:
                        ListTileControlAffinity.leading,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12)),
                        onChanged: (checked) {
                          if (checked == true) {
                            _selectedNames.add(name);
                          } else {
                            _selectedNames.remove(name);
                          }
                        },
                      ),
                    ),
                    // Edit button
                    IconButton(
                      icon: const Icon(Icons.edit_rounded,
                          color: _kBlue, size: 18),
                      onPressed: () => _showEditNameDialog(i),
                      tooltip: 'Edit name',
                    ),
                    // Delete button
                    IconButton(
                      icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: _kDanger,
                          size: 18),
                      onPressed: () => _deleteName(i),
                      tooltip: 'Delete',
                    ),
                    const SizedBox(width: 4),
                  ]),
                );
              },
            ),
          ),

          // ── Save button ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -1))
              ],
            ),
            child: SafeArea(
              child: Obx(() => SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading.value ? null : _saveSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading.value
                      ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : const Text('Save Fee Configuration',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ),
              )),
            ),
          ),
        ]);
      }),
    );
  }
}
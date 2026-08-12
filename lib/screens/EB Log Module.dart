import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/eb_controller.dart';
import 'package:school_app/controllers/school_controller.dart';

import '../core/permissions/eb_permissions.dart';
import 'eb_log_form_page.dart';

/// Mobile "EB Logs" screen restyled with clean white and blue theme system.
class EBLogListScreen extends StatefulWidget {
  const EBLogListScreen({super.key});

  @override
  State<EBLogListScreen> createState() => _EBLogListScreenState();
}

class _EBLogListScreenState extends State<EBLogListScreen> {
  final EBController ebController = Get.find();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _searchController = TextEditingController();

  SchoolController? get _school =>
      Get.isRegistered<SchoolController>() ? Get.find<SchoolController>() : null;
  Worker? _authWorker;
  Worker? _schoolWorker;
  String _lastLoadedSchoolId = '';

  // Theme Colors
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color lightBlueBg = Color(0xFFEFF6FF);
  static const Color amberYellow = Color(0xFFD97706);
  static const Color lightAmberBg = Color(0xFFFEF3C7);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);

  String get role => _authController.user.value?.role?.toLowerCase() ?? '';

  String get schoolId {
    if (role == 'correspondent') {
      return _school?.selectedSchool.value?.id ?? '';
    }
    return _authController.user.value?.schoolId ?? '';
  }

  String? _selectedPremisesId;
  String? _selectedPremisesName;
  DateTime? _fromDate;
  DateTime? _toDate;
  num? _minReading;
  num? _maxReading;
  bool _premisesRequested = false;

  bool get _hasActiveFilters =>
      _selectedPremisesId != null ||
          _fromDate != null ||
          _toDate != null ||
          _minReading != null ||
          _maxReading != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryLoadLogs());

    _authWorker = ever(_authController.user, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tryLoadLogs();
      });
    });

    if (_school != null) {
      _schoolWorker = ever(_school!.selectedSchool, (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _tryLoadLogs();
        });
      });
    }
  }

  @override
  void dispose() {
    _authWorker?.dispose();
    _schoolWorker?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    if (schoolId.isEmpty) return;
    await ebController.getAllEBLogs(
      schoolId: schoolId,
      premisesId: _selectedPremisesId,
      fromDate: _fromDate?.toIso8601String(),
      toDate: _toDate?.toIso8601String(),
      minReading: _minReading,
      maxReading: _maxReading,
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedPremisesId = null;
      _selectedPremisesName = null;
      _fromDate = null;
      _toDate = null;
      _minReading = null;
      _maxReading = null;
      _searchController.clear();
    });
    _loadLogs();
  }

  Future<void> _openForm({Map<String, dynamic>? log}) async {
    final result = await Get.to(() => EBLogFormScreen(schoolId: schoolId, existingLog: log));
    if (result == true) _loadLogs();
  }

  Future<void> _confirmDelete(Map<String, dynamic> log) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete EB Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
        content: Text(
          'Remove log "${log['ebLogNo'] ?? ''}"? This action cannot be undone.',
          style: const TextStyle(fontSize: 13, color: textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel', style: TextStyle(fontSize: 13, color: textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final id = (log['_id'] ?? log['id']).toString();
      final ok = await ebController.deleteEBLog(schoolId, id);
      if (ok) _loadLogs();
    }
  }

  Future<void> _openPremisesFilterSheet() async {
    if (schoolId.isEmpty) {
      Get.snackbar('Please wait', 'Still loading school info...',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (!_premisesRequested) {
      _premisesRequested = true;
      await ebController.getAllPremises(schoolId);
    }
    final searchController = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final query = searchController.text.trim().toLowerCase();
              final premisesList = ebController.premisesList.where((p) {
                final name = (p['premisesName'] ?? '').toString().toLowerCase();
                return query.isEmpty || name.contains(query);
              }).toList();

              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Filter by Premises', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedPremisesId = null;
                                _selectedPremisesName = null;
                              });
                              Get.back();
                            },
                            child: const Text('Clear', style: TextStyle(fontSize: 13, color: primaryBlue)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: searchController,
                        style: const TextStyle(fontSize: 13, color: textDark),
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search premises...',
                          hintStyle: const TextStyle(fontSize: 13, color: textMuted),
                          prefixIcon: const Icon(Icons.search, size: 20, color: textMuted),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryBlue)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Obx(() {
                          if (ebController.isLoading.value && ebController.premisesList.isEmpty) {
                            return const Center(child: CircularProgressIndicator(color: primaryBlue));
                          }
                          if (premisesList.isEmpty) {
                            return const Center(child: Text('No premises found', style: TextStyle(color: textMuted, fontSize: 13)));
                          }
                          return ListView.separated(
                            itemCount: premisesList.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: borderColor),
                            itemBuilder: (context, index) {
                              final p = premisesList[index];
                              return ListTile(
                                dense: true,
                                title: Text(p['premisesName'] ?? '', style: const TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.w500)),
                                onTap: () {
                                  setState(() {
                                    _selectedPremisesId = (p['_id'] ?? p['id']).toString();
                                    _selectedPremisesName = p['premisesName'];
                                  });
                                  Get.back();
                                  _loadLogs();
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

  Future<void> _openDateRangeSheet() async {
    DateTime? tempFrom = _fromDate;
    DateTime? tempTo = _toDate;
    final fmt = DateFormat('dd-MM-yyyy');

    await showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Date Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
                        TextButton(
                          onPressed: () => setSheetState(() {
                            tempFrom = null;
                            tempTo = null;
                          }),
                          child: const Text('Clear', style: TextStyle(fontSize: 13, color: primaryBlue)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniDateField(
                            label: 'From',
                            value: tempFrom != null ? fmt.format(tempFrom!) : 'dd-mm-yyyy',
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: tempFrom ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) setSheetState(() => tempFrom = picked);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MiniDateField(
                            label: 'To',
                            value: tempTo != null ? fmt.format(tempTo!) : 'dd-mm-yyyy',
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: tempTo ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) setSheetState(() => tempTo = picked);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _fromDate = tempFrom;
                            _toDate = tempTo;
                          });
                          Get.back();
                          _loadLogs();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Apply', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openReadingRangeSheet() async {
    final minController = TextEditingController(text: _minReading?.toString() ?? '');
    final maxController = TextEditingController(text: _maxReading?.toString() ?? '');

    await showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Meter Reading', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
                    TextButton(
                      onPressed: () {
                        minController.clear();
                        maxController.clear();
                      },
                      child: const Text('Clear', style: TextStyle(fontSize: 13, color: primaryBlue)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 13, color: textDark),
                        decoration: InputDecoration(
                          labelText: 'Min',
                          labelStyle: const TextStyle(fontSize: 12, color: textMuted),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryBlue)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 13, color: textDark),
                        decoration: InputDecoration(
                          labelText: 'Max',
                          labelStyle: const TextStyle(fontSize: 12, color: textMuted),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryBlue)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _minReading = num.tryParse(minController.text.trim());
                        _maxReading = num.tryParse(maxController.text.trim());
                      });
                      Get.back();
                      _loadLogs();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Apply', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EB Logs',
              style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Monitor electricity meter readings',
              style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          if (EBPermissions.canEditEBLogs(role))
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () => _openForm(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Log Reading', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13, color: textDark),
                onSubmitted: (_) => _loadLogs(),
                decoration: InputDecoration(
                  hintText: 'Log No, Notes...',
                  hintStyle: const TextStyle(color: textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 20, color: textMuted),
                  filled: true,
                  fillColor: cardBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryBlue)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: _selectedPremisesName ?? 'Premises',
                      active: _selectedPremisesId != null,
                      onTap: _openPremisesFilterSheet,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: (_fromDate == null && _toDate == null)
                          ? 'Date Range'
                          : '${_fromDate != null ? DateFormat('dd MMM').format(_fromDate!) : '...'} - ${_toDate != null ? DateFormat('dd MMM').format(_toDate!) : '...'}',
                      active: _fromDate != null || _toDate != null,
                      onTap: _openDateRangeSheet,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: (_minReading == null && _maxReading == null)
                          ? 'Meter Reading'
                          : '${_minReading ?? '...'} - ${_maxReading ?? '...'}',
                      active: _minReading != null || _maxReading != null,
                      onTap: _openReadingRangeSheet,
                    ),
                    if (_hasActiveFilters) ...[
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.close, size: 14, color: textMuted),
                        label: const Text('Clear', style: TextStyle(fontSize: 12, color: textDark)),
                        onPressed: _clearFilters,
                        backgroundColor: const Color(0xFFF1F5F9),
                        side: BorderSide.none,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Obx(() {
                  if (ebController.isLoading.value && ebController.ebLogs.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: primaryBlue));
                  }
                  final logs = ebController.ebLogs;
                  if (logs.isEmpty) {
                    return const Center(child: Text('No EB logs found', style: TextStyle(color: textMuted, fontSize: 13)));
                  }
                  return RefreshIndicator(
                    color: primaryBlue,
                    onRefresh: _loadLogs,
                    child: ListView.separated(
                      itemCount: logs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _EBLogCard(
                        log: logs[index],
                        canEdit: EBPermissions.canEditEBLogs(role),
                        canDelete: EBPermissions.canDeleteEBLogs(role),
                        onEdit: () => _openForm(log: logs[index]),
                        onDelete: () => _confirmDelete(logs[index]),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _tryLoadLogs() {
    final id = schoolId;
    if (id.isEmpty || id == _lastLoadedSchoolId) return;
    _lastLoadedSchoolId = id;
    ebController.ebLogs.clear();
    ebController.premisesList.clear();
    _premisesRequested = false;
    _loadLogs();
  }
}

class _MiniDateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _MiniDateField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: _EBLogListScreenState.textMuted)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(border: Border.all(color: _EBLogListScreenState.borderColor), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(fontSize: 12, color: _EBLogListScreenState.textDark)),
                const Icon(Icons.calendar_today_outlined, size: 14, color: _EBLogListScreenState.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _EBLogListScreenState.primaryBlue : _EBLogListScreenState.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? _EBLogListScreenState.primaryBlue : _EBLogListScreenState.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : _EBLogListScreenState.textDark,
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 14, color: active ? Colors.white : _EBLogListScreenState.textMuted),
          ],
        ),
      ),
    );
  }
}

class _EBLogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EBLogCard({
    required this.log,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatDate(dynamic raw) {
    if (raw == null) return 'N/A';
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final ebLogNo = (log['ebLogNo'] ?? 'N/A').toString();
    final time = (log['time'] ?? '').toString();
    final reading = log['meterReading'];
    final premisesRaw = log['premisesId'];
    final premisesName = premisesRaw is Map ? (premisesRaw['premisesName'] ?? 'N/A').toString() : 'N/A';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _EBLogListScreenState.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _EBLogListScreenState.lightAmberBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bolt, color: _EBLogListScreenState.amberYellow, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        ebLogNo,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _EBLogListScreenState.textDark),
                      ),
                    ),
                    if (canEdit)
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18, color: _EBLogListScreenState.textMuted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (canEdit && canDelete) const SizedBox(width: 10),
                    if (canDelete)
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${_formatDate(log['date'])}${time.isNotEmpty ? ' · $time' : ''}',
                    style: const TextStyle(color: _EBLogListScreenState.textMuted, fontSize: 11),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.apartment, size: 13, color: _EBLogListScreenState.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        premisesName,
                        style: const TextStyle(color: _EBLogListScreenState.textDark, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _EBLogListScreenState.lightBlueBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reading == null ? 'N/A' : '$reading kWh',
                    style: const TextStyle(color: _EBLogListScreenState.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
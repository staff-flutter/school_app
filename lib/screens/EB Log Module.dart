import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/eb_controller.dart';
import 'package:school_app/controllers/school_controller.dart';

import '../core/permissions/eb_permissions.dart';
import 'eb_log_form_page.dart';

/// Mobile "EB Logs" screen — mirrors the web "Electricity (EB) Logs" page:
/// search, Premises / Date Range / Meter Reading filters, and a list of
/// log cards (log no, date/time, premises, reading, edit/delete actions).
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
      _selectedPremisesId != null || _fromDate != null || _toDate != null || _minReading != null || _maxReading != null;

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
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
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
        title: const Text('Delete EB Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'Remove log "${log['ebLogNo'] ?? ''}"? This cannot be undone.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel', style: TextStyle(fontSize: 13))),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontSize: 13)),
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
      Get.snackbar('Please wait', 'Still loading your school info...',
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
                          const Text('Filter by Premises', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedPremisesId = null;
                                _selectedPremisesName = null;
                              });
                              Get.back();
                            },
                            child: const Text('Clear', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: searchController,
                        style: const TextStyle(fontSize: 13),
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search premises...',
                          hintStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Obx(() {
                          if (ebController.isLoading.value && ebController.premisesList.isEmpty) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (premisesList.isEmpty) {
                            return Center(child: Text('No premises found', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)));
                          }
                          return ListView.separated(
                            itemCount: premisesList.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final p = premisesList[index];
                              return ListTile(
                                dense: true,
                                title: Text(p['premisesName'] ?? '', style: const TextStyle(fontSize: 13)),
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
                        const Text('Date Range', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        TextButton(
                          onPressed: () => setSheetState(() {
                            tempFrom = null;
                            tempTo = null;
                          }),
                          child: const Text('Clear', style: TextStyle(fontSize: 13)),
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
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Apply', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                    const Text('Meter Reading', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    TextButton(
                      onPressed: () {
                        minController.clear();
                        maxController.clear();
                      },
                      child: const Text('Clear', style: TextStyle(fontSize: 13)),
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
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Min',
                          labelStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Max',
                          labelStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Apply', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('EB Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openForm(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Log Reading', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13),
                onSubmitted: (_) => _loadLogs(),
                decoration: InputDecoration(
                  hintText: 'Log No, Notes...',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 38,
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
                        avatar: const Icon(Icons.close, size: 14),
                        label: const Text('Clear', style: TextStyle(fontSize: 12)),
                        onPressed: _clearFilters,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Obx(() {
                  if (ebController.isLoading.value && ebController.ebLogs.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final logs = ebController.ebLogs;
                  if (logs.isEmpty) {
                    return Center(child: Text('No EB logs found', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)));
                  }
                  return RefreshIndicator(
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
    ebController.ebLogs.clear();       // drop stale previous-user data
    ebController.premisesList.clear(); // clear so the filter sheet doesn't show old premises either
    _premisesRequested = false;        // force premises to be refetched for the new school
    _loadLogs();
  }}

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
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(fontSize: 12)),
                const Icon(Icons.calendar_today_outlined, size: 14),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.black87 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? Colors.black87 : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: active ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 14, color: active ? Colors.white : Colors.black54),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: const Color(0xFFFFF3D6), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.bolt, color: Color(0xFFCA8A04), size: 20),
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
                      child: Text(ebLogNo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                    if (canEdit)
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.black54),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (canEdit && canDelete) const SizedBox(width: 10),
                    if (canDelete)
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
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
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.apartment, size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(premisesName, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFDCEBFC), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    reading == null ? 'N/A' : '$reading kWh',
                    style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w700, fontSize: 11),
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
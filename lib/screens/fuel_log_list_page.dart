import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/controllers/transport_controller.dart';

import 'fuel_log_detail_page.dart';
import 'fuel_log_form_page.dart';

/// Fuel Consumption Logs list screen transformed to match application theme.
class FuelLogListScreen extends StatefulWidget {
  final String schoolId;

  const FuelLogListScreen({super.key, required this.schoolId});

  @override
  State<FuelLogListScreen> createState() => _FuelLogListScreenState();
}

class _FuelLogListScreenState extends State<FuelLogListScreen> {
  final TransportController controller = Get.find<TransportController>();

  final TextEditingController _searchCtrl = TextEditingController();
  String? _selectedBusId;
  String? _selectedBusLabel;
  DateTime? _fromDate;
  DateTime? _toDate;
  RangeValues _amountRange = const RangeValues(0, 100000);

  final DateFormat _displayDateFmt = DateFormat('dd MMM yyyy');
  final DateFormat _apiDateFmt = DateFormat('yyyy-MM-dd');

  // Theme Constants
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color lightBlueBg = Color(0xFFEFF6FF);
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color lightGreenBg = Color(0xFFD1FAE5);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    controller.getBusDropdown(widget.schoolId);
    _fetchLogs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _fetchLogs() {
    controller.getFuelLogs(
      schoolId: widget.schoolId,
      busId: _selectedBusId,
      search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
      fromDate: _fromDate != null ? _apiDateFmt.format(_fromDate!) : null,
      toDate: _toDate != null ? _apiDateFmt.format(_toDate!) : null,
      minAmount: _amountRange.start > 0 ? _amountRange.start : null,
      maxAmount: _amountRange.end < 100000 ? _amountRange.end : null,
    );
  }

  bool get _hasActiveFilters =>
      _selectedBusId != null ||
          _fromDate != null ||
          _toDate != null ||
          _searchCtrl.text.isNotEmpty ||
          _amountRange.start > 0 ||
          _amountRange.end < 100000;

  void _clearFilters() {
    setState(() {
      _selectedBusId = null;
      _selectedBusLabel = null;
      _searchCtrl.clear();
      _fromDate = null;
      _toDate = null;
      _amountRange = const RangeValues(0, 100000);
    });
    _fetchLogs();
  }

  Future<void> _confirmDelete(String id) async {
    Get.defaultDialog(
      title: 'Delete Fuel Log',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: textDark),
      middleText: 'Are you sure you want to delete this fuel log? This action cannot be undone.',
      middleTextStyle: const TextStyle(color: textMuted),
      textCancel: 'Cancel',
      textConfirm: 'Delete',
      confirmTextColor: Colors.white,
      buttonColor: AppTheme.errorRed,
      cancelTextColor: textMuted,
      radius: 12,
      onConfirm: () async {
        Get.back();
        final ok = await controller.deleteFuelLog(id);
        if (ok) _fetchLogs();
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
        title: const Text(
          'Fuel Logs',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () async {
                final created = await Get.to(() => FuelLogFormScreen(schoolId: widget.schoolId));
                if (created == true) _fetchLogs();
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Log Fuel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChipsBar(),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.fuelLogs.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: primaryBlue));
              }

              if (controller.fuelLogs.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                color: primaryBlue,
                onRefresh: () async => _fetchLogs(),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.fuelLogs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final log = controller.fuelLogs[index];
                    return _FuelLogCard(
                      serial: index + 1,
                      log: log,
                      dateFmt: _displayDateFmt,
                      onView: () async {
                        final changed = await Get.to(
                              () => FuelLogDetailScreen(schoolId: widget.schoolId, fuelLogId: log['_id']),
                        );
                        if (changed == true) _fetchLogs();
                      },
                      onDelete: () => _confirmDelete(log['_id']),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: textDark, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Station, bill no, notes...',
          hintStyle: const TextStyle(color: textMuted, fontSize: 14),
          prefixIcon: const Icon(Icons.search, size: 20, color: textMuted),
          filled: true,
          fillColor: cardBg,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue, width: 1.5),
          ),
        ),
        onSubmitted: (_) => _fetchLogs(),
        onChanged: (val) {
          if (val.isEmpty) _fetchLogs();
        },
      ),
    );
  }

  Widget _buildFilterChipsBar() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterChip(
            label: _selectedBusLabel == null ? 'Filter by Bus' : 'Bus: $_selectedBusLabel',
            active: _selectedBusId != null,
            onTap: _openBusSheet,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: _fromDate == null && _toDate == null ? 'Date Range' : _dateRangeLabel(),
            active: _fromDate != null || _toDate != null,
            onTap: _openDateRangeSheet,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: _amountRange.start == 0 && _amountRange.end == 100000
                ? 'Amount'
                : '₹${_amountRange.start.round()} - ₹${_amountRange.end.round()}',
            active: _amountRange.start > 0 || _amountRange.end < 100000,
            onTap: _openAmountSheet,
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.close, size: 14, color: textMuted),
              label: const Text('Clear Filters', style: TextStyle(color: textMuted, fontSize: 12)),
              onPressed: _clearFilters,
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _dateRangeLabel() {
    final fmt = DateFormat('dd MMM');
    final from = _fromDate != null ? fmt.format(_fromDate!) : '...';
    final to = _toDate != null ? fmt.format(_toDate!) : '...';
    return '$from - $to';
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: lightBlueBg, shape: BoxShape.circle),
                child: const Icon(Icons.local_gas_station_outlined, size: 36, color: primaryBlue),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Fuel Logs Found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
              ),
              const SizedBox(height: 6),
              const Text(
                'Adjust your filters or log a new fuel entry to see data here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- Bottom sheets ----------------

  void _openBusSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String? tempBusId = _selectedBusId;
        String? tempBusLabel = _selectedBusLabel;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return _BottomSheetShell(
              title: 'Filter by Bus',
              onClear: () => setSheetState(() {
                tempBusId = null;
                tempBusLabel = null;
              }),
              onApply: () {
                setState(() {
                  _selectedBusId = tempBusId;
                  _selectedBusLabel = tempBusLabel;
                });
                Navigator.pop(context);
                _fetchLogs();
              },
              child: Obx(() {
                final buses = controller.busDropdown;
                if (buses.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No buses available', style: TextStyle(color: textMuted)),
                  );
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                  child: ListView(
                    shrinkWrap: true,
                    children: buses.map((bus) {
                      final id = bus['_id']?.toString();
                      final label = (bus['busNumber'] ?? bus['registrationNo'] ?? 'Bus').toString();
                      return RadioListTile<String>(
                        activeColor: primaryBlue,
                        value: id ?? '',
                        groupValue: tempBusId,
                        title: Text(label, style: const TextStyle(color: textDark, fontWeight: FontWeight.w500)),
                        onChanged: (v) => setSheetState(() {
                          tempBusId = v;
                          tempBusLabel = label;
                        }),
                      );
                    }).toList(),
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }

  void _openDateRangeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        DateTime? tempFrom = _fromDate;
        DateTime? tempTo = _toDate;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final fmt = DateFormat('dd-MM-yyyy');
            return _BottomSheetShell(
              title: 'Date Range',
              onClear: () => setSheetState(() {
                tempFrom = null;
                tempTo = null;
              }),
              onApply: () {
                setState(() {
                  _fromDate = tempFrom;
                  _toDate = tempTo;
                });
                Navigator.pop(context);
                _fetchLogs();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _DatePickerField(
                        label: 'From',
                        value: tempFrom != null ? fmt.format(tempFrom!) : 'dd-mm-yyyy',
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tempFrom ?? DateTime.now(),
                            firstDate: DateTime(2015),
                            lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(primary: primaryBlue),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) setSheetState(() => tempFrom = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DatePickerField(
                        label: 'To',
                        value: tempTo != null ? fmt.format(tempTo!) : 'dd-mm-yyyy',
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tempTo ?? DateTime.now(),
                            firstDate: DateTime(2015),
                            lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(primary: primaryBlue),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) setSheetState(() => tempTo = picked);
                        },
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

  void _openAmountSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        RangeValues tempRange = _amountRange;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return _BottomSheetShell(
              title: 'Amount Filter',
              onClear: () => setSheetState(() {
                tempRange = const RangeValues(0, 100000);
              }),
              onApply: () {
                setState(() => _amountRange = tempRange);
                Navigator.pop(context);
                _fetchLogs();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${tempRange.start.round()} - ₹${tempRange.end.round()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark),
                    ),
                    const SizedBox(height: 12),
                    RangeSlider(
                      values: tempRange,
                      activeColor: primaryBlue,
                      inactiveColor: const Color(0xFFE2E8F0),
                      min: 0,
                      max: 100000,
                      divisions: 100,
                      labels: RangeLabels(
                        '₹${tempRange.start.round()}',
                        '₹${tempRange.end.round()}',
                      ),
                      onChanged: (values) => setSheetState(() => tempRange = values),
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
}

// ---------------- Reusable Filter & Bottom Sheet Widgets ----------------

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
          color: active ? _FuelLogListScreenState.lightBlueBg : _FuelLogListScreenState.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? _FuelLogListScreenState.primaryBlue : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? _FuelLogListScreenState.primaryBlue : _FuelLogListScreenState.textMuted,
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: active ? _FuelLogListScreenState.primaryBlue : _FuelLogListScreenState.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomSheetShell extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onClear;
  final VoidCallback onApply;

  const _BottomSheetShell({
    required this.title,
    required this.child,
    required this.onClear,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _FuelLogListScreenState.textDark)),
                  TextButton(
                    onPressed: onClear,
                    child: const Text('Clear', style: TextStyle(color: _FuelLogListScreenState.textMuted)),
                  ),
                ],
              ),
            ),
            const Divider(height: 16, color: Color(0xFFF1F5F9)),
            Flexible(child: child),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _FuelLogListScreenState.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DatePickerField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _FuelLogListScreenState.textMuted, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(10),
              color: _FuelLogListScreenState.cardBg,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(fontSize: 13, color: _FuelLogListScreenState.textDark)),
                const Icon(Icons.calendar_today_outlined, size: 16, color: _FuelLogListScreenState.primaryBlue),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FuelLogCard extends StatelessWidget {
  final int serial;
  final Map<String, dynamic> log;
  final DateFormat dateFmt;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const _FuelLogCard({
    required this.serial,
    required this.log,
    required this.dateFmt,
    required this.onView,
    required this.onDelete,
  });

  String _formatDate(dynamic raw) {
    if (raw == null) return 'N/A';
    try {
      return dateFmt.format(DateTime.parse(raw.toString()));
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bus = log['busId'];
    final busLabel = bus is Map ? (bus['busNumber'] ?? bus['registrationNo'] ?? 'Bus').toString() : 'N/A';
    final busSubLabel = bus is Map ? bus['busNumber']?.toString() : null;

    final quantity = log['fuelQuantity'];
    final pricePerLiter = log['pricePerLiter'];
    final totalAmount = log['totalAmount'];
    final billingLabel = log['fuelStation']?.toString().isNotEmpty == true ? log['fuelStation'].toString() : 'N/A';
    final paymentMode = log['paymentMode']?.toString() ?? '';
    final billNo = log['fuelBillNo']?.toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _FuelLogListScreenState.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _FuelLogListScreenState.lightBlueBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_gas_station_outlined,
                  color: _FuelLogListScreenState.primaryBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(log['date']),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _FuelLogListScreenState.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      busLabel,
                      style: const TextStyle(fontSize: 12, color: _FuelLogListScreenState.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (busSubLabel != null)
                      Text(
                        'ID: $busSubLabel',
                        style: const TextStyle(fontSize: 11, color: _FuelLogListScreenState.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.visibility_outlined, color: _FuelLogListScreenState.primaryBlue, size: 18),
                  tooltip: 'View details',
                  onPressed: onView,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 18),
                  tooltip: 'Delete',
                  onPressed: onDelete,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${quantity ?? '-'} L @ ₹${pricePerLiter ?? '-'}/L',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _FuelLogListScreenState.textDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$billingLabel • $paymentMode${billNo != null && billNo.isNotEmpty ? ' • Bill: $billNo' : ''}',
                    style: const TextStyle(fontSize: 11, color: _FuelLogListScreenState.textMuted),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '₹${totalAmount ?? 0}',
                  style: TextStyle(
                    color: AppTheme.errorRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
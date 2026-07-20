import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/controllers/transport_controller.dart';

import 'fuel_log_detail_page.dart';
import 'fuel_log_form_page.dart';

/// Fuel Consumption Logs list screen.
/// Mirrors the web dashboard at /dashboard/fuellog:
///  - left/top filter panel (bus, search, date range, amount range)
///  - list of fuel logs with date, bus, fuel details, amount, billing info
///  - "+ Log Fuel" action that opens [FuelLogFormScreen] in create mode
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
  DateTime? _fromDate;
  DateTime? _toDate;
  RangeValues _amountRange = const RangeValues(0, 100000);
  bool _filtersExpanded = false;

  final DateFormat _displayDateFmt = DateFormat('dd MMM yyyy');
  final DateFormat _apiDateFmt = DateFormat('yyyy-MM-dd');

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

  void _clearFilters() {
    setState(() {
      _selectedBusId = null;
      _searchCtrl.clear();
      _fromDate = null;
      _toDate = null;
      _amountRange = const RangeValues(0, 100000);
    });
    _fetchLogs();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
      _fetchLogs();
    }
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Fuel Log'),
        content: const Text('Are you sure you want to delete this fuel log? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final ok = await controller.deleteFuelLog(id);
      if (ok) _fetchLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Consumption Logs'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () async {
                final created = await Get.to(() => FuelLogFormScreen(schoolId: widget.schoolId));
                if (created == true) _fetchLogs();
              },
              icon: const Icon(Icons.add),
              label: const Text('Log Fuel'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterPanel(),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.fuelLogs.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.fuelLogs.isEmpty) {
                return const Center(child: Text('No fuel logs found'));
              }
              return RefreshIndicator(
                onRefresh: () async => _fetchLogs(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: controller.fuelLogs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
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

  Widget _buildFilterPanel() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
              child: Row(
                children: [
                  const Icon(Icons.filter_list),
                  const SizedBox(width: 8),
                  const Text('Log Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  Icon(_filtersExpanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
            if (_filtersExpanded) ...[
              const SizedBox(height: 12),
              const Text('Filter by Bus', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Obx(() => DropdownButtonFormField<String>(
                value: _selectedBusId,
                decoration: const InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Icons.search, size: 18),
                  hintText: 'Select Bus...',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Buses')),
                  ...controller.busDropdown.map(
                        (b) => DropdownMenuItem(
                      value: b['_id'].toString(),
                      child: Text(b['busNumber']?.toString() ?? b['registrationNo']?.toString() ?? 'Bus'),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() => _selectedBusId = val);
                  _fetchLogs();
                },
              )),
              const SizedBox(height: 12),
              const Text('Search', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Station, bill no, notes...',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _fetchLogs(),
              ),
              const SizedBox(height: 12),
              const Text('Date Range', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(isFrom: true),
                      child: Text(_fromDate == null ? 'From date' : _displayDateFmt.format(_fromDate!)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(isFrom: false),
                      child: Text(_toDate == null ? 'To date' : _displayDateFmt.format(_toDate!)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Amount: ₹${_amountRange.start.round()} - ₹${_amountRange.end.round()}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              RangeSlider(
                values: _amountRange,
                min: 0,
                max: 100000,
                divisions: 100,
                labels: RangeLabels(
                  '₹${_amountRange.start.round()}',
                  '₹${_amountRange.end.round()}',
                ),
                onChanged: (values) => setState(() => _amountRange = values),
                onChangeEnd: (_) => _fetchLogs(),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear Filters'),
                ),
              ),
            ],
          ],
        ),
      ),
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
    if (raw == null) return '-';
    try {
      return dateFmt.format(DateTime.parse(raw.toString()));
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bus = log['busId'];
    final busLabel = bus is Map ? (bus['busNumber']?.toString() ?? bus['registrationNo']?.toString() ?? '-') : '-';
    final busIdLabel = bus is Map ? (bus['_id']?.toString() ?? '') : (bus?.toString() ?? '');

    final quantity = log['fuelQuantity'];
    final pricePerLiter = log['pricePerLiter'];
    final totalAmount = log['totalAmount'];
    final billingLabel = log['fuelStation']?.toString().isNotEmpty == true ? log['fuelStation'].toString() : 'N/A';
    final paymentMode = log['paymentMode']?.toString() ?? '';
    final billNo = log['fuelBillNo']?.toString();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 14, child: Text('$serial', style: const TextStyle(fontSize: 12))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(_formatDate(log['date']),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '₹${totalAmount ?? 0}',
                          style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(busLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (busIdLabel.isNotEmpty)
                    Text('ID: $busIdLabel', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text('${quantity ?? '-'} L @ ₹${pricePerLiter ?? '-'}/L'),
                  const SizedBox(height: 4),
                  Text(
                    '$billingLabel • $paymentMode${billNo != null && billNo.isNotEmpty ? ' • Bill: $billNo' : ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(icon: const Icon(Icons.visibility_outlined), onPressed: onView),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: AppTheme.errorRed),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
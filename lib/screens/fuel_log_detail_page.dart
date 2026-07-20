import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/controllers/transport_controller.dart';

import 'fuel_log_form_page.dart';


/// Read-only "Fuel Log Details" screen with an Edit Details action,
/// mirroring the web app's detail panel.
class FuelLogDetailScreen extends StatefulWidget {
  final String schoolId;
  final String fuelLogId;

  const FuelLogDetailScreen({super.key, required this.schoolId, required this.fuelLogId});

  @override
  State<FuelLogDetailScreen> createState() => _FuelLogDetailScreenState();
}

class _FuelLogDetailScreenState extends State<FuelLogDetailScreen> {
  final TransportController controller = Get.find<TransportController>();
  final DateFormat _displayDateFmt = DateFormat('dd MMM yyyy');

  Map<String, dynamic>? _log;
  bool _loading = true;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await controller.getFuelLogById(widget.fuelLogId, schoolId: widget.schoolId);
    setState(() {
      _log = data;
      _loading = false;
    });
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '-';
    try {
      return _displayDateFmt.format(DateTime.parse(raw.toString()));
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.back(result: _changed);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fuel Log Details'),
          actions: [
            if (_log != null)
              TextButton.icon(
                onPressed: () async {
                  final updated = await Get.to(
                        () => FuelLogFormScreen(schoolId: widget.schoolId, existing: _log),
                  );
                  if (updated == true) {
                    _changed = true;
                    _load();
                  }
                },
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text('Edit Details', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _log == null
            ? const Center(child: Text('Fuel log not found'))
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionCard(
              icon: Icons.directions_bus,
              title: 'Vehicle & Fuel Metrics',
              children: [
                _detailRow('Assigned Bus', _busLabel(_log!['busId'])),
                _detailRow('Fill Date', _formatDate(_log!['date'])),
                _detailRow('Odometer Reading (KM)', _log!['odometerReading']?.toString() ?? '-'),
                _detailRow('Fuel Station Name', _log!['fuelStation']?.toString() ?? '-'),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              icon: Icons.receipt_long,
              title: 'Billing Information',
              children: [
                _detailRow('Fuel Quantity (Liters)', '${_log!['fuelQuantity'] ?? '-'} L'),
                _detailRow(
                  'Total Amount (₹)',
                  '₹${_log!['totalAmount'] ?? 0}',
                  valueColor: AppTheme.errorRed,
                  highlight: true,
                ),
                _detailRow('Price Per Liter (₹)', '₹${_log!['pricePerLiter'] ?? '-'}'),
                _detailRow('Bill / Receipt No', _log!['fuelBillNo']?.toString() ?? '-'),
                _detailRow('Payment Mode', _log!['paymentMode']?.toString() ?? '-'),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              icon: Icons.notes,
              title: 'Notes / Remarks',
              children: [
                Text(
                  (_log!['notes']?.toString().isNotEmpty ?? false)
                      ? _log!['notes'].toString()
                      : 'No remarks provided.',
                  style: TextStyle(
                    color: (_log!['notes']?.toString().isNotEmpty ?? false) ? Colors.black87 : Colors.grey,
                    fontStyle: (_log!['notes']?.toString().isNotEmpty ?? false)
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.back(result: _changed),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _busLabel(dynamic bus) {
    if (bus is Map) {
      return bus['busNumber']?.toString() ?? bus['registrationNo']?.toString() ?? '-';
    }
    return bus?.toString() ?? '-';
  }

  Widget _sectionCard({required IconData icon, required String title, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 0.3),
            ),
          ),
          Expanded(
            flex: 3,
            child: highlight
                ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (valueColor ?? Colors.black).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(value,
                  style: TextStyle(fontWeight: FontWeight.bold, color: valueColor)),
            )
                : Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor)),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:school_app/controllers/transport_controller.dart';

/// Read-only Trip Log Details page — mirrors the web dashboard's "Trip Log
/// Details" panel: Assigned Bus, Trip Date, Opening/Closing Odometer,
/// Distance Travelled, and Trip Notes/Remarks.
class DailyTripLogProfileScreen extends StatefulWidget {
  final String tripLogId;
  final Future<bool?> Function(Map<String, dynamic> tripLog)? onEdit;

  const DailyTripLogProfileScreen({super.key, required this.tripLogId, this.onEdit});

  @override
  State<DailyTripLogProfileScreen> createState() => _DailyTripLogProfileScreenState();
}

class _DailyTripLogProfileScreenState extends State<DailyTripLogProfileScreen> {
  final TransportController _controller = Get.find();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.getDailyTripLogById(widget.tripLogId);
    });
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return 'N/A';
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
        title: const Text('Trip Log Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () async {
                final log = _controller.currentDailyTripLog.value;
                if (log == null || widget.onEdit == null) return;
                final updated = await widget.onEdit!(log);
                if (updated == true) {
                  _controller.getDailyTripLogById(widget.tripLogId);
                }
              },
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Details'),
              style: TextButton.styleFrom(foregroundColor: Colors.black87),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.currentDailyTripLog.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final log = _controller.currentDailyTripLog.value;
        if (log == null) {
          return const Center(child: Text('Trip log not found'));
        }

        final bus = log['busId'];
        final busLabel = bus is Map ? (bus['registrationNo'] ?? bus['busNumber'] ?? 'N/A').toString() : 'N/A';
        final tripDate = _formatDate(log['date']);
        final opening = log['openingOdometer']?.toString() ?? 'N/A';
        final closing = log['closingOdometer']?.toString() ?? 'N/A';
        final kmRun = log['kmRun'];
        final notes = log['notes']?.toString();

        return RefreshIndicator(
          onRefresh: () => _controller.getDailyTripLogById(widget.tripLogId),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.route_outlined, size: 18, color: Colors.black54),
                        SizedBox(width: 8),
                        Text('Trip Information', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _InfoBlock(label: 'Assigned Bus', value: busLabel)),
                        Expanded(child: _InfoBlock(label: 'Trip Date', value: tripDate)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoBlock(
                            label: 'Opening Odometer (KM)',
                            value: opening,
                            boxed: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoBlock(
                            label: 'Closing Odometer (KM)',
                            value: closing,
                            boxed: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _InfoBlock(
                      label: 'Distance Travelled',
                      value: kmRun != null ? '$kmRun km' : 'N/A',
                      valueColor: Colors.green,
                      valueBold: true,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'TRIP NOTES / REMARKS',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (notes == null || notes.isEmpty) ? 'No notes added.' : notes,
                        style: TextStyle(
                          fontSize: 13,
                          color: (notes == null || notes.isEmpty) ? Colors.grey.shade500 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;
  final bool boxed;
  final Color? valueColor;
  final bool valueBold;

  const _InfoBlock({
    required this.label,
    required this.value,
    this.boxed = false,
    this.valueColor,
    this.valueBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueWidget = Text(
      value,
      style: TextStyle(
        fontSize: boxed ? 13 : 14,
        fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
        color: valueColor ?? Colors.black87,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        if (boxed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: valueWidget,
          )
        else
          valueWidget,
      ],
    );
  }
}
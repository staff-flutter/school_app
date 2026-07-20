import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:school_app/controllers/transport_controller.dart';

/// Read-only Bus Details page — mirrors the web dashboard's bus single-view:
/// "Vehicle & Operational Specifications" card and a "Statutory Documents &
/// Renewals" list below.
class BusProfileScreen extends StatefulWidget {
  final String busId;
  final Future<bool?> Function(Map<String, dynamic> bus)? onEdit;

  const BusProfileScreen({super.key, required this.busId, this.onEdit});

  @override
  State<BusProfileScreen> createState() => _BusProfileScreenState();
}

class _BusProfileScreenState extends State<BusProfileScreen> {
  final TransportController _controller = Get.find();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.getBusById(widget.busId);
    });
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return 'N/A';
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(parsed);
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'in_service':
        return Colors.blue;
      case 'on_trip':
        return Colors.orange;
      case 'inactive':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'active':
        return 'ACTIVE';
      case 'in_service':
        return 'IN SERVICE';
      case 'on_trip':
        return 'ON TRIP';
      case 'inactive':
        return 'INACTIVE';
      default:
        return (status ?? 'UNKNOWN').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
        title: Obx(() {
          final bus = _controller.currentBus.value;
          final regNo = bus?['registrationNo']?.toString();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bus Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
              if (regNo != null)
                Text(regNo, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w400)),
            ],
          );
        }),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () async {
                final bus = _controller.currentBus.value;
                if (bus == null || widget.onEdit == null) return;
                final updated = await widget.onEdit!(bus);
                if (updated == true) {
                  _controller.getBusById(widget.busId);
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
        if (_controller.isLoading.value && _controller.currentBus.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final bus = _controller.currentBus.value;
        if (bus == null) {
          return const Center(child: Text('Bus not found'));
        }

        final registrationNo = bus['registrationNo']?.toString() ?? 'N/A';
        final busNumber = bus['busNumber']?.toString().isNotEmpty == true ? bus['busNumber'].toString() : 'N/A';
        final status = bus['operationalStatus']?.toString();
        final makeModel = bus['makeModel']?.toString().isNotEmpty == true ? bus['makeModel'].toString() : 'N/A';
        final year = bus['year']?.toString().isNotEmpty == true ? bus['year'].toString() : 'N/A';
        final fuelType = bus['fuelType']?.toString().isNotEmpty == true ? bus['fuelType'].toString() : 'N/A';
        final seatingCapacity =
        bus['seatingCapacity']?.toString().isNotEmpty == true ? bus['seatingCapacity'].toString() : 'N/A';
        final chassisNo = bus['chassisNo']?.toString().isNotEmpty == true ? bus['chassisNo'].toString() : 'N/A';
        final engineNo = bus['engineNo']?.toString().isNotEmpty == true ? bus['engineNo'].toString() : 'N/A';
        final rcOwner = bus['rcOwner']?.toString().isNotEmpty == true ? bus['rcOwner'].toString() : 'N/A';
        final purchaseDate = _formatDate(bus['purchaseDate']);
        final lastServiceDate = _formatDate(bus['lastServiceDate']);
        final nextServiceDate = _formatDate(bus['nextServiceDate']);
        final assignedDriver = bus['assignedDriverId'];
        final driverLabel = assignedDriver is Map
            ? (assignedDriver['name'] ?? 'Assigned').toString()
            : (assignedDriver == null ? 'Not Assigned' : 'Assigned');
        final documents = (bus['statutoryDocuments'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        return RefreshIndicator(
          onRefresh: () => _controller.getBusById(widget.busId),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header card with reg no / bus no + status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.directions_bus_filled_outlined, color: Colors.blueGrey, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(registrationNo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text('ID: $busNumber', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w700, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Vehicle & Operational Specifications
              _InfoCard(
                title: 'Vehicle & Operational Specifications',
                icon: Icons.directions_bus_outlined,
                rows: [
                  _InfoRow('Registration No', registrationNo),
                  _InfoRow('Internal Bus No', busNumber),
                  _InfoRow('Operational Status', _statusLabel(status)),
                  _InfoRow('Make & Model', makeModel),
                  _InfoRow('Manufacture Year', year),
                  _InfoRow('Fuel Type', fuelType),
                  _InfoRow('Seating Capacity', seatingCapacity),
                  _InfoRow('Chassis No', chassisNo),
                  _InfoRow('Engine No', engineNo),
                  _InfoRow('RC Owner', rcOwner),
                  _InfoRow('Purchase Date', purchaseDate),
                  _InfoRow('Last Service Date', lastServiceDate),
                  _InfoRow('Next Service Date', nextServiceDate),
                  _InfoRow('Assigned Driver', driverLabel),
                ],
              ),
              const SizedBox(height: 14),

              // Statutory documents & renewals
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
                        Icon(Icons.folder_open_outlined, size: 18, color: Colors.black54),
                        SizedBox(width: 8),
                        Text('Statutory Documents & Renewals', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (documents.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text('No documents uploaded yet.', style: TextStyle(color: Colors.grey.shade600)),
                      )
                    else
                      ...documents.map((doc) => _DocumentTile(document: doc)),
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

class _InfoRow {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_InfoRow> rows;

  const _InfoCard({required this.title, required this.icon, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
            ],
          ),
          const SizedBox(height: 12),
          // Two-column grid on wider content, falls back to single column
          // naturally since each row is full width in this list-style layout.
          ...rows.map(
                (row) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.label.toUpperCase(),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(row.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final Map<String, dynamic> document;

  const _DocumentTile({required this.document});

  Color _statusColor(String? status) {
    switch (status) {
      case 'valid':
        return Colors.green;
      case 'expiring_soon':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = document['documentName']?.toString() ?? 'Document';
    final cost = document['lastCost'];
    final costLabel = (cost == null || cost == 0) ? 'N/A' : '₹$cost';
    final expiryRaw = document['expiry'];
    final expiry = expiryRaw != null
        ? (DateTime.tryParse(expiryRaw.toString()) != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(expiryRaw.toString()))
        : 'N/A')
        : 'N/A';
    final status = document['status']?.toString();
    final files = (document['files'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              if (status != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.replaceAll('_', ' '),
                    style: TextStyle(fontSize: 10, color: _statusColor(status), fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Renewal Cost: $costLabel', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          const SizedBox(height: 2),
          Text('Expiry / Validity: $expiry', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          const SizedBox(height: 6),
          if (files.isEmpty)
            Text('Attached files: Not uploaded', style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: files.map<Widget>((f) {
                final fileMap = f as Map<String, dynamic>;
                final originalName = fileMap['originalName']?.toString() ?? 'file';
                return Chip(
                  avatar: const Icon(Icons.attach_file, size: 14),
                  label: Text(originalName, style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
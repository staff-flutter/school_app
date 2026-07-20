import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:school_app/controllers/transport_controller.dart';

/// Read-only Driver Profile page — mirrors the web dashboard's driver
/// single-view: avatar + name + status on top, Personal Information card,
/// and a Statutory Documents list below.
class DriverProfileScreen extends StatefulWidget {
  final String driverId;
  final Future<bool?> Function(Map<String, dynamic> driver)? onEdit;

  const DriverProfileScreen({super.key, required this.driverId, this.onEdit});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final TransportController _controller = Get.find();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.getDriverById(widget.driverId);
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
      case 'on_leave':
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
      case 'on_leave':
        return 'ON LEAVE';
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
        title: const Text('Driver Profile', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () async {
                final driver = _controller.currentDriver.value;
                if (driver == null || widget.onEdit == null) return;
                final updated = await widget.onEdit!(driver);
                if (updated == true) {
                  _controller.getDriverById(widget.driverId);
                }
              },
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Profile'),
              style: TextButton.styleFrom(foregroundColor: Colors.black87),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.currentDriver.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final driver = _controller.currentDriver.value;
        if (driver == null) {
          return const Center(child: Text('Driver not found'));
        }

        final name = driver['name']?.toString() ?? 'Unnamed Driver';
        final status = driver['status']?.toString();
        final phone = driver['phone']?.toString() ?? 'N/A';
        final dob = _formatDate(driver['dateOfBirth']);
        final joined = _formatDate(driver['joinedDate']);
        final emergencyContact = driver['emergencyContact']?.toString().isNotEmpty == true
            ? driver['emergencyContact'].toString()
            : 'N/A';
        final address =
        driver['address']?.toString().isNotEmpty == true ? driver['address'].toString() : 'N/A';
        final assignedBus = driver['assignedBusId'];
        final busLabel = assignedBus is Map
            ? (assignedBus['busNumber'] ?? assignedBus['registrationNo'] ?? 'Assigned').toString()
            : 'Not Assigned';
        final documents = (driver['documents'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        return RefreshIndicator(
          onRefresh: () => _controller.getDriverById(widget.driverId),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Avatar card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.deepPurple.shade50,
                      backgroundImage: (driver['photo'] is Map && driver['photo']['url'] != null)
                          ? NetworkImage(driver['photo']['url'])
                          : null,
                      child: (driver['photo'] == null || driver['photo']['url'] == null)
                          ? Text(
                        name.isNotEmpty ? name[0].toLowerCase() : '?',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.deepPurple),
                      )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

              // Personal information
              _InfoCard(
                title: 'Personal Information',
                icon: Icons.badge_outlined,
                rows: [
                  _InfoRow('Full Name', name),
                  _InfoRow('Phone Number', phone),
                  _InfoRow('Date of Birth', dob),
                  _InfoRow('Joined Date', joined),
                  _InfoRow('Emergency Contact', emergencyContact),
                  _InfoRow('Assigned Bus', busLabel),
                  _InfoRow('Address', address),
                ],
              ),
              const SizedBox(height: 14),

              // Statutory documents
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.folder_open_outlined, size: 18, color: Colors.black54),
                        SizedBox(width: 8),
                        Text('Statutory Documents', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.black54),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
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
    final detail = document['detail']?.toString().isNotEmpty == true ? document['detail'].toString() : 'N/A';
    final expiryRaw = document['expiryDate'];
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
          Text('Details: $detail', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          const SizedBox(height: 2),
          Text('Expiry: $expiry', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
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
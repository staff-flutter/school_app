import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/transport_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';

/// Fleet Directory screen — mirrors the web dashboard's bus list page:
/// search bar, filter chips (Operational Status, Next Service Date), and a
/// list/empty-state below. Same interaction pattern as DriverDirectoryScreen.
class BusDirectoryScreen extends StatefulWidget {
  final VoidCallback? onRegisterBus;
  final Future<bool?> Function(Map<String, dynamic> bus)? onEditBus;
  final void Function(Map<String, dynamic> bus)? onViewBus;

  const BusDirectoryScreen({
    super.key,
    this.onRegisterBus,
    this.onEditBus,
    this.onViewBus,
  });

  @override
  State<BusDirectoryScreen> createState() => _BusDirectoryScreenState();
}

class _BusDirectoryScreenState extends State<BusDirectoryScreen> {
  final TransportController _controller = Get.find();
  final AuthController _authController = Get.find();
  final TextEditingController _searchController = TextEditingController();

  SchoolController? get _school =>
      Get.isRegistered<SchoolController>() ? Get.find<SchoolController>() : null;

  static const List<String> _statusOptions = ['active', 'in_service', 'on_trip', 'inactive'];

  String? _selectedStatus;
  DateTime? _serviceDateFrom;
  DateTime? _serviceDateTo;
  String _search = '';

  // Correspondents can switch between multiple schools, so their schoolId
  // comes from the currently-selected school; every other role is scoped
  // to the single school on their own user profile.
  String? get _schoolId {
    final role = _authController.user.value?.role?.toLowerCase() ?? '';
    if (role == 'correspondent') {
      return _school?.selectedSchool.value?.id;
    }
    return _authController.user.value?.schoolId;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBuses());

    final role = _authController.user.value?.role?.toLowerCase() ?? '';
    if (role == 'correspondent') {
      ever(_school!.selectedSchool, (_) {
        if (mounted) _loadBuses();
      });
    } else {
      ever(_authController.user, (user) {
        if (mounted && user?.schoolId != null && user!.schoolId!.isNotEmpty) {
          _loadBuses();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBuses() async {
    if (_schoolId == null) return;
    await _controller.getBuses(
      schoolId: _schoolId,
      operationalStatus: _selectedStatus,
      search: _search.isEmpty ? null : _search,
    );
  }

  bool get _hasActiveFilters =>
      _selectedStatus != null || _serviceDateFrom != null || _serviceDateTo != null || _search.isNotEmpty;

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _serviceDateFrom = null;
      _serviceDateTo = null;
      _search = '';
      _searchController.clear();
    });
    _loadBuses();
  }

  // Next-service-date range isn't a supported query param on
  // /api/transport/bus/, so it's applied client-side on the fetched list.
  List<Map<String, dynamic>> get _visibleBuses {
    return _controller.buses.where((bus) {
      if (_serviceDateFrom != null || _serviceDateTo != null) {
        final raw = bus['nextServiceDate'];
        if (raw == null) return false;
        final date = DateTime.tryParse(raw.toString());
        if (date == null) return false;
        if (_serviceDateFrom != null && date.isBefore(_serviceDateFrom!)) return false;
        if (_serviceDateTo != null && date.isAfter(_serviceDateTo!)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 16,
        title: const Text(
          'Fleet Directory',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        foregroundColor: Colors.black87,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: widget.onRegisterBus,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Register Bus'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChipsBar(),
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value && _controller.buses.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final visible = _visibleBuses;

              return RefreshIndicator(
                onRefresh: _loadBuses,
                child: visible.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _BusCard(
                    bus: visible[index],
                    onView: () => widget.onViewBus?.call(visible[index]),
                    onDelete: () => _confirmDelete(visible[index]),
                  ),
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Reg No, Chassis No, Engine No...',
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        onChanged: (value) => _search = value,
        onSubmitted: (_) => _loadBuses(),
      ),
    );
  }

  Widget _buildFilterChipsBar() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _FilterChip(
            label: _selectedStatus == null ? 'Operational Status' : 'Status: ${_statusLabel(_selectedStatus!)}',
            active: _selectedStatus != null,
            onTap: _openStatusSheet,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: _serviceDateFrom == null && _serviceDateTo == null ? 'Next Service Date' : _dateRangeLabel(),
            active: _serviceDateFrom != null || _serviceDateTo != null,
            onTap: _openServiceDateSheet,
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.close, size: 16),
              label: const Text('Clear Filters'),
              onPressed: _clearFilters,
              backgroundColor: Colors.grey.shade200,
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(String value) {
    switch (value) {
      case 'active':
        return 'Active';
      case 'in_service':
        return 'In Service';
      case 'on_trip':
        return 'On Trip';
      case 'inactive':
        return 'Inactive';
      default:
        return value;
    }
  }

  String _dateRangeLabel() {
    final fmt = DateFormat('dd MMM');
    final from = _serviceDateFrom != null ? fmt.format(_serviceDateFrom!) : '...';
    final to = _serviceDateTo != null ? fmt.format(_serviceDateTo!) : '...';
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
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.grey.shade200,
                child: const Icon(Icons.directions_bus_outlined, size: 32, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text('No Buses Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(
                'Adjust your filters or register a new bus to see data here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDelete(Map<String, dynamic> bus) {
    Get.defaultDialog(
      title: 'Delete Bus',
      middleText: 'Are you sure you want to delete ${bus['registrationNo'] ?? 'this bus'}?',
      textCancel: 'Cancel',
      textConfirm: 'Delete',
      confirmTextColor: Colors.white,
      buttonColor: AppTheme.errorRed,
      onConfirm: () async {
        Get.back();
        final id = bus['_id']?.toString();
        if (id == null) return;
        final ok = await _controller.deleteBus(id);
        if (ok) _loadBuses();
      },
    );
  }

  // ---------------- Bottom sheets ----------------

  void _openStatusSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        String? tempSelected = _selectedStatus;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return _BottomSheetShell(
              title: 'Operational Status',
              onClear: () => setSheetState(() => tempSelected = null),
              onApply: () {
                setState(() => _selectedStatus = tempSelected);
                Navigator.pop(context);
                _loadBuses();
              },
              child: Column(
                children: _statusOptions.map((status) {
                  return RadioListTile<String>(
                    value: status,
                    groupValue: tempSelected,
                    title: Text(_statusLabel(status)),
                    onChanged: (value) => setSheetState(() => tempSelected = value),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  void _openServiceDateSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        DateTime? tempFrom = _serviceDateFrom;
        DateTime? tempTo = _serviceDateTo;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final fmt = DateFormat('dd-MM-yyyy');
            return _BottomSheetShell(
              title: 'Next Service Date',
              onClear: () => setSheetState(() {
                tempFrom = null;
                tempTo = null;
              }),
              onApply: () {
                setState(() {
                  _serviceDateFrom = tempFrom;
                  _serviceDateTo = tempTo;
                });
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
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
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
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
}

// ---------------- Reusable pieces ----------------

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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.black87 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? Colors.black87 : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(color: active ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16, color: active ? Colors.white : Colors.black54),
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

  const _BottomSheetShell({required this.title, required this.child, required this.onClear, required this.onApply});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  TextButton(onPressed: onClear, child: const Text('Clear')),
                ],
              ),
            ),
            const Divider(height: 20),
            Flexible(child: child),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Apply'),
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
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(fontSize: 13)),
                const Icon(Icons.calendar_today_outlined, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BusCard extends StatelessWidget {
  final Map<String, dynamic> bus;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const _BusCard({required this.bus, required this.onView, required this.onDelete});

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

  String _formatDate(dynamic raw) {
    if (raw == null) return 'N/A';
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return 'N/A';
    return DateFormat('dd/MM/yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final registrationNo = bus['registrationNo']?.toString() ?? 'N/A';
    final busNumber = bus['busNumber']?.toString();
    final makeModel = bus['makeModel']?.toString() ?? 'N/A';
    final year = bus['year']?.toString() ?? 'Unknown';
    final seatingCapacity = bus['seatingCapacity']?.toString();
    final fuelType = bus['fuelType']?.toString();
    final status = bus['operationalStatus']?.toString();
    final nextService = _formatDate(bus['nextServiceDate']);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.directions_bus_filled_outlined, color: Colors.blueGrey, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(registrationNo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                if (busNumber != null && busNumber.isNotEmpty)
                  Text('ID: $busNumber', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(height: 3),
                Text('$makeModel · Year: $year', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                if (seatingCapacity != null || fuelType != null)
                  Text(
                    [
                      if (seatingCapacity != null) '$seatingCapacity Seats',
                      if (fuelType != null && fuelType.isNotEmpty) fuelType,
                    ].join(' · '),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status ?? 'unknown',
                        style: TextStyle(fontSize: 11, color: _statusColor(status), fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Next: $nextService', style: TextStyle(fontSize: 11, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis, maxLines: 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility_outlined, color: Colors.black54, size: 20),
            tooltip: 'View details',
            onPressed: onView,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 20),
            tooltip: 'Delete',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
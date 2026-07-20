import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/transport_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';

/// Driver Directory screen — mirrors the web dashboard's driver list page:
/// search bar, a row of filter chips (each opening a bottom sheet), and a
/// list/empty-state below. Wire `onCreateDriver` / `onEditDriver` to your
/// navigation (e.g. Get.toNamed('/driver-create')).
class DriverDirectoryScreen extends StatefulWidget {
  final VoidCallback? onCreateDriver;
  final void Function(Map<String, dynamic> driver)? onEditDriver;
  final void Function(Map<String, dynamic> driver)? onViewDriver;

  const DriverDirectoryScreen({
    super.key,
    this.onCreateDriver,
    this.onEditDriver,
    this.onViewDriver,
  });

  @override
  State<DriverDirectoryScreen> createState() => _DriverDirectoryScreenState();
}

class _DriverDirectoryScreenState extends State<DriverDirectoryScreen> {
  final TransportController _controller = Get.find();
  final AuthController _authController = Get.find();
  final TextEditingController _searchController = TextEditingController();

  SchoolController? get _school =>
      Get.isRegistered<SchoolController>() ? Get.find<SchoolController>() : null;

  static const List<String> _statusOptions = ['active', 'inactive', 'on_leave'];

  String? _selectedStatus;
  String _busAssignmentFilter = 'all'; // 'all' | 'unassigned'
  String? _selectedBusId;
  String? _selectedBusLabel;
  DateTime? _dateFrom;
  DateTime? _dateTo;
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadForCurrentSchool());

    final role = _authController.user.value?.role?.toLowerCase() ?? '';
    if (role == 'correspondent') {
      ever(_school!.selectedSchool, (_) {
        if (mounted) _loadForCurrentSchool();
      });
    } else {
      ever(_authController.user, (user) {
        if (mounted && user?.schoolId != null && user!.schoolId!.isNotEmpty) {
          _loadForCurrentSchool();
        }
      });
    }
  }

  void _loadForCurrentSchool() {
    _loadDrivers();
    if (_schoolId != null) {
      _controller.getBusDropdown(_schoolId!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDrivers() async {
    if (_schoolId == null) return;
    await _controller.getDrivers(
      schoolId: _schoolId,
      status: _selectedStatus,
      search: _search.isEmpty ? null : _search,
    );
  }

  bool get _hasActiveFilters =>
      _selectedStatus != null ||
          _busAssignmentFilter != 'all' ||
          _selectedBusId != null ||
          _dateFrom != null ||
          _dateTo != null ||
          _search.isNotEmpty;

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _busAssignmentFilter = 'all';
      _selectedBusId = null;
      _selectedBusLabel = null;
      _dateFrom = null;
      _dateTo = null;
      _search = '';
      _searchController.clear();
    });
    _loadDrivers();
  }

  // Applies client-side filters (bus assignment / specific bus / date joined)
  // on top of the server-filtered list, since those aren't supported by the
  // /api/transport/driver query params.
  List<Map<String, dynamic>> get _visibleDrivers {
    return _controller.drivers.where((driver) {
      if (_busAssignmentFilter == 'unassigned' && driver['assignedBusId'] != null) {
        return false;
      }
      if (_selectedBusId != null) {
        final assignedId = driver['assignedBusId'] is Map
            ? driver['assignedBusId']['_id']
            : driver['assignedBusId'];
        if (assignedId != _selectedBusId) return false;
      }
      if (_dateFrom != null || _dateTo != null) {
        final joinedRaw = driver['joinedDate'];
        if (joinedRaw == null) return false;
        final joined = DateTime.tryParse(joinedRaw.toString());
        if (joined == null) return false;
        if (_dateFrom != null && joined.isBefore(_dateFrom!)) return false;
        if (_dateTo != null && joined.isAfter(_dateTo!)) return false;
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
          'Driver Directory',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        foregroundColor: Colors.black87,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: widget.onCreateDriver,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Driver'),
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
              if (_controller.isLoading.value && _controller.drivers.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final visible = _visibleDrivers;
              if (visible.isEmpty) {
                return _buildEmptyState();
              }
              return RefreshIndicator(
                onRefresh: _loadDrivers,
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _DriverCard(
                    index: index + 1,
                    driver: visible[index],
                    onView: () => widget.onViewDriver?.call(visible[index]),
                    onEdit: () => widget.onEditDriver?.call(visible[index]),
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
          hintText: 'Name, phone, or address...',
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
        onSubmitted: (_) => _loadDrivers(),
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
            label: _selectedStatus == null
                ? 'Status'
                : 'Status: ${_statusLabel(_selectedStatus!)}',
            active: _selectedStatus != null,
            onTap: _openStatusSheet,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: _busAssignmentFilter == 'unassigned' ? 'Unassigned Only' : 'Bus Assignment',
            active: _busAssignmentFilter != 'all',
            onTap: _openBusAssignmentSheet,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: _selectedBusLabel == null ? 'Specific Bus' : 'Bus: $_selectedBusLabel',
            active: _selectedBusId != null,
            onTap: _openSpecificBusSheet,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: _dateFrom == null && _dateTo == null
                ? 'Date Joined'
                : _dateRangeLabel(),
            active: _dateFrom != null || _dateTo != null,
            onTap: _openDateJoinedSheet,
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
      case 'inactive':
        return 'Inactive';
      case 'on_leave':
        return 'On Leave';
      default:
        return value;
    }
  }

  String _dateRangeLabel() {
    final fmt = DateFormat('dd MMM');
    final from = _dateFrom != null ? fmt.format(_dateFrom!) : '...';
    final to = _dateTo != null ? fmt.format(_dateTo!) : '...';
    return '$from - $to';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.grey.shade200,
              child: const Icon(Icons.person_outline, size: 32, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Drivers Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Adjust your filters or register a new driver to see data here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> driver) {
    Get.defaultDialog(
      title: 'Delete Driver',
      middleText: 'Are you sure you want to delete ${driver['name'] ?? 'this driver'}?',
      textCancel: 'Cancel',
      textConfirm: 'Delete',
      confirmTextColor: Colors.white,
      buttonColor: AppTheme.errorRed,
      onConfirm: () async {
        Get.back();
        final id = driver['_id']?.toString();
        if (id == null) return;
        final ok = await _controller.deleteDriver(id);
        if (ok) _loadDrivers();
      },
    );
  }

  // ---------------- Bottom sheets ----------------

  void _openStatusSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        String? tempSelected = _selectedStatus;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return _BottomSheetShell(
              title: 'Operational Status',
              onClear: () {
                setSheetState(() => tempSelected = null);
              },
              onApply: () {
                setState(() => _selectedStatus = tempSelected);
                Navigator.pop(context);
                _loadDrivers();
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

  void _openBusAssignmentSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        String tempSelected = _busAssignmentFilter;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return _BottomSheetShell(
              title: 'Bus Assignment',
              onClear: () => setSheetState(() => tempSelected = 'all'),
              onApply: () {
                setState(() => _busAssignmentFilter = tempSelected);
                Navigator.pop(context);
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'all',
                    groupValue: tempSelected,
                    title: const Text('All Drivers'),
                    onChanged: (v) => setSheetState(() => tempSelected = v!),
                  ),
                  RadioListTile<String>(
                    value: 'unassigned',
                    groupValue: tempSelected,
                    title: const Text('Unassigned (No Bus)'),
                    onChanged: (v) => setSheetState(() => tempSelected = v!),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openSpecificBusSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        String? tempBusId = _selectedBusId;
        String? tempBusLabel = _selectedBusLabel;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return _BottomSheetShell(
              title: 'Filter by Specific Bus',
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
              },
              child: Obx(() {
                final buses = _controller.busDropdown;
                if (buses.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No buses available'),
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
                        value: id ?? '',
                        groupValue: tempBusId,
                        title: Text(label),
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

  void _openDateJoinedSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        DateTime? tempFrom = _dateFrom;
        DateTime? tempTo = _dateTo;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final fmt = DateFormat('dd-MM-yyyy');
            return _BottomSheetShell(
              title: 'Date Joined',
              onClear: () => setSheetState(() {
                tempFrom = null;
                tempTo = null;
              }),
              onApply: () {
                setState(() {
                  _dateFrom = tempFrom;
                  _dateTo = tempTo;
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
              style: TextStyle(
                color: active ? Colors.white : Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: active ? Colors.white : Colors.black54,
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
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
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
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
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

class _DriverCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> driver;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DriverCard({
    required this.index,
    required this.driver,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

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

  @override
  Widget build(BuildContext context) {
    final name = driver['name']?.toString() ?? 'Unnamed Driver';
    final phone = driver['phone']?.toString() ?? '-';
    final status = driver['status']?.toString();
    final assignedBus = driver['assignedBusId'];
    final busLabel = assignedBus is Map
        ? (assignedBus['busNumber'] ?? assignedBus['registrationNo'] ?? 'Assigned').toString()
        : (assignedBus == null ? 'Unassigned' : 'Assigned');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade200,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(phone, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
                    Text(busLabel, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility_outlined, color: Colors.black54, size: 20),
            tooltip: 'View profile',
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
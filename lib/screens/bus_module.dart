import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/transport_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';

/// Fleet Directory screen — styled with the application theme
/// (White, Blue primary, Green, Yellow accents, Red preserved for delete actions).
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

  // Theme Constants
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color lightBlueBg = Color(0xFFEFF6FF);
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color lightGreenBg = Color(0xFFD1FAE5);
  static const Color primaryYellow = Color(0xFFF59E0B);
  static const Color lightYellowBg = Color(0xFFFEF3C7);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);

  String? _selectedStatus;
  DateTime? _serviceDateFrom;
  DateTime? _serviceDateTo;
  String _search = '';

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: const Text(
          'Fleet Directory',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: widget.onRegisterBus,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Register Bus'),
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
              if (_controller.isLoading.value && _controller.buses.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: primaryBlue));
              }

              final visible = _visibleBuses;

              return RefreshIndicator(
                color: primaryBlue,
                onRefresh: _loadBuses,
                child: visible.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: textDark, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Reg No, Chassis No, Engine No...',
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
        onChanged: (value) => _search = value,
        onSubmitted: (_) => _loadBuses(),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: lightBlueBg, shape: BoxShape.circle),
                child: const Icon(Icons.directions_bus_outlined, size: 36, color: primaryBlue),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Buses Found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
              ),
              const SizedBox(height: 6),
              const Text(
                'Adjust your filters or register a new bus to see data here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textMuted, fontSize: 13),
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
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: textDark),
      middleText: 'Are you sure you want to delete ${bus['registrationNo'] ?? 'this bus'}?',
      middleTextStyle: const TextStyle(color: textMuted),
      textCancel: 'Cancel',
      textConfirm: 'Delete',
      confirmTextColor: Colors.white,
      buttonColor: AppTheme.errorRed,
      cancelTextColor: textMuted,
      radius: 12,
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
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                    activeColor: primaryBlue,
                    value: status,
                    groupValue: tempSelected,
                    title: Text(_statusLabel(status), style: const TextStyle(color: textDark, fontWeight: FontWeight.w500)),
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
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                            firstDate: DateTime(2000),
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
                            firstDate: DateTime(2000),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _BusDirectoryScreenState.lightBlueBg : _BusDirectoryScreenState.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? _BusDirectoryScreenState.primaryBlue : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? _BusDirectoryScreenState.primaryBlue : _BusDirectoryScreenState.textMuted,
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: active ? _BusDirectoryScreenState.primaryBlue : _BusDirectoryScreenState.textMuted,
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

  const _BottomSheetShell({required this.title, required this.child, required this.onClear, required this.onApply});

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
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _BusDirectoryScreenState.textDark)),
                  TextButton(
                    onPressed: onClear,
                    child: const Text('Clear', style: TextStyle(color: _BusDirectoryScreenState.textMuted)),
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
                    backgroundColor: _BusDirectoryScreenState.primaryBlue,
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
        Text(label, style: const TextStyle(fontSize: 12, color: _BusDirectoryScreenState.textMuted, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(10),
              color: _BusDirectoryScreenState.cardBg,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(fontSize: 13, color: _BusDirectoryScreenState.textDark)),
                const Icon(Icons.calendar_today_outlined, size: 16, color: _BusDirectoryScreenState.primaryBlue),
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
        return _BusDirectoryScreenState.primaryGreen;
      case 'in_service':
      case 'on_trip':
        return _BusDirectoryScreenState.primaryBlue;
      case 'inactive':
        return AppTheme.errorRed;
      default:
        return _BusDirectoryScreenState.textMuted;
    }
  }

  Color _statusBgColor(String? status) {
    switch (status) {
      case 'active':
        return _BusDirectoryScreenState.lightGreenBg;
      case 'in_service':
      case 'on_trip':
        return _BusDirectoryScreenState.lightBlueBg;
      case 'inactive':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
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
        color: _BusDirectoryScreenState.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _BusDirectoryScreenState.lightBlueBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.directions_bus_filled_outlined, color: _BusDirectoryScreenState.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(registrationNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _BusDirectoryScreenState.textDark)),
                if (busNumber != null && busNumber.isNotEmpty)
                  Text('ID: $busNumber', style: const TextStyle(fontSize: 11, color: _BusDirectoryScreenState.textMuted)),
                const SizedBox(height: 3),
                Text('$makeModel · Year: $year', style: const TextStyle(fontSize: 12, color: _BusDirectoryScreenState.textDark)),
                if (seatingCapacity != null || fuelType != null)
                  Text(
                    [
                      if (seatingCapacity != null) '$seatingCapacity Seats',
                      if (fuelType != null && fuelType.isNotEmpty) fuelType,
                    ].join(' · '),
                    style: const TextStyle(fontSize: 11, color: _BusDirectoryScreenState.textMuted),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusBgColor(status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status ?? 'unknown',
                        style: TextStyle(fontSize: 11, color: _statusColor(status), fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Next: $nextService',
                        style: const TextStyle(fontSize: 11, color: _BusDirectoryScreenState.textMuted, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility_outlined, color: _BusDirectoryScreenState.primaryBlue, size: 20),
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
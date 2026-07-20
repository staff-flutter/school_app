import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/transport_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';

/// Daily Trip Logs screen — mirrors the web dashboard's trip log list page:
/// search bar, filter chips (Bus, Date Range), and a list/empty-state below.
/// Wire `onLogTrip` / `onEditTripLog` / `onViewTripLog` to your navigation.
class DailyTripLogDirectoryScreen extends StatefulWidget {
  final VoidCallback? onLogTrip;
  final Future<bool?> Function(Map<String, dynamic> tripLog)? onEditTripLog;
  final void Function(Map<String, dynamic> tripLog)? onViewTripLog;

  const DailyTripLogDirectoryScreen({
    super.key,
    this.onLogTrip,
    this.onEditTripLog,
    this.onViewTripLog,
  });

  @override
  State<DailyTripLogDirectoryScreen> createState() => _DailyTripLogDirectoryScreenState();
}

class _DailyTripLogDirectoryScreenState extends State<DailyTripLogDirectoryScreen> {
  final TransportController _controller = Get.find();
  final AuthController _authController = Get.find();
  final TextEditingController _searchController = TextEditingController();

  SchoolController? get _school =>
      Get.isRegistered<SchoolController>() ? Get.find<SchoolController>() : null;

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
    _loadLogs();
    if (_schoolId != null) {
      _controller.getBusDropdown(_schoolId!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    if (_schoolId == null) return;
    await _controller.getDailyTripLogs(
      schoolId: _schoolId,
      busId: _selectedBusId,
    );
  }

  bool get _hasActiveFilters =>
      _selectedBusId != null || _dateFrom != null || _dateTo != null || _search.isNotEmpty;

  void _clearFilters() {
    setState(() {
      _selectedBusId = null;
      _selectedBusLabel = null;
      _dateFrom = null;
      _dateTo = null;
      _search = '';
      _searchController.clear();
    });
    _loadLogs();
  }

  // Search text and date range aren't supported by the
  // /api/transport/dailytriplog/ query params (only schoolId, busId,
  // academicYear, page, limit), so they're applied client-side.
  List<Map<String, dynamic>> get _visibleLogs {
    return _controller.dailyTripLogs.where((log) {
      if (_search.isNotEmpty) {
        final logNo = (log['dailyLogNo']?.toString() ?? '').toLowerCase();
        final notes = (log['notes']?.toString() ?? '').toLowerCase();
        final query = _search.toLowerCase();
        if (!logNo.contains(query) && !notes.contains(query)) return false;
      }
      if (_dateFrom != null || _dateTo != null) {
        final raw = log['date'];
        if (raw == null) return false;
        final date = DateTime.tryParse(raw.toString());
        if (date == null) return false;
        if (_dateFrom != null && date.isBefore(_dateFrom!)) return false;
        if (_dateTo != null && date.isAfter(_dateTo!)) return false;
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
          'Daily Trip Logs',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        foregroundColor: Colors.black87,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: widget.onLogTrip,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Log Trip'),
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
              if (_controller.isLoading.value && _controller.dailyTripLogs.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final visible = _visibleLogs;
              if (visible.isEmpty) {
                return _buildEmptyState();
              }
              return RefreshIndicator(
                onRefresh: _loadLogs,
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _TripLogCard(
                    tripLog: visible[index],
                    onView: () => widget.onViewTripLog?.call(visible[index]),
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
          hintText: 'Log no, notes...',
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
        onChanged: (value) => setState(() => _search = value),
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
            label: _selectedBusLabel == null ? 'Filter by Bus' : 'Bus: $_selectedBusLabel',
            active: _selectedBusId != null,
            onTap: _openBusSheet,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: _dateFrom == null && _dateTo == null ? 'Date Range' : _dateRangeLabel(),
            active: _dateFrom != null || _dateTo != null,
            onTap: _openDateRangeSheet,
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
              child: const Icon(Icons.route_outlined, size: 32, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text('No Trip Logs Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Adjust your filters or log a new trip to see data here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> tripLog) {
    Get.defaultDialog(
      title: 'Delete Trip Log',
      middleText: 'Are you sure you want to delete this trip log?',
      textCancel: 'Cancel',
      textConfirm: 'Delete',
      confirmTextColor: Colors.white,
      buttonColor: AppTheme.errorRed,
      onConfirm: () async {
        Get.back();
        final id = tripLog['_id']?.toString();
        if (id == null) return;
        final ok = await _controller.deleteDailyTripLog(id);
        if (ok) _loadLogs();
      },
    );
  }

  // ---------------- Bottom sheets ----------------

  void _openBusSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
                _loadLogs();
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

  void _openDateRangeSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        DateTime? tempFrom = _dateFrom;
        DateTime? tempTo = _dateTo;
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

class _TripLogCard extends StatelessWidget {
  final Map<String, dynamic> tripLog;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const _TripLogCard({required this.tripLog, required this.onView, required this.onDelete});

  String _formatDate(dynamic raw) {
    if (raw == null) return 'N/A';
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final date = _formatDate(tripLog['date']);
    final bus = tripLog['busId'];
    final busLabel = bus is Map ? (bus['registrationNo'] ?? bus['busNumber'] ?? 'Bus').toString() : 'N/A';
    final busSubLabel = bus is Map ? bus['busNumber']?.toString() : null;
    final opening = tripLog['openingOdometer']?.toString() ?? 'N/A';
    final closing = tripLog['closingOdometer']?.toString() ?? 'N/A';
    final kmRun = tripLog['kmRun'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(date, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(busLabel, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    if (busSubLabel != null)
                      Text('ID: $busSubLabel', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
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
          const SizedBox(height: 8),
          Row(
            children: [
              _OdometerChip(label: 'Opening', value: opening),
              const SizedBox(width: 8),
              _OdometerChip(label: 'Closing', value: closing),
              const Spacer(),
              if (kmRun != null)
                Text('$kmRun km', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _OdometerChip extends StatelessWidget {
  final String label;
  final String value;

  const _OdometerChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: $value', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700)),
    );
  }
}
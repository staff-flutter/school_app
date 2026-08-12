import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/controllers/transport_controller.dart';

import 'bus_route_detail_page.dart';
import 'bus_route_form_page.dart';

/// "Bus Routes & Stops" list screen styled to match the clean white and blue design system.
class BusRouteListScreen extends StatefulWidget {
  final String schoolId;

  const BusRouteListScreen({super.key, required this.schoolId});

  @override
  State<BusRouteListScreen> createState() => _BusRouteListScreenState();
}

class _BusRouteListScreenState extends State<BusRouteListScreen> {
  final TransportController controller = Get.find<TransportController>();

  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _minFeeCtrl = TextEditingController();
  final TextEditingController _maxFeeCtrl = TextEditingController();

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchRoutes());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _minFeeCtrl.dispose();
    _maxFeeCtrl.dispose();
    super.dispose();
  }

  void _fetchRoutes() {
    controller.getBusRoutes(
      schoolId: widget.schoolId,
      search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
      minFee: _minFeeCtrl.text.isEmpty ? null : double.tryParse(_minFeeCtrl.text),
      maxFee: _maxFeeCtrl.text.isEmpty ? null : double.tryParse(_maxFeeCtrl.text),
    );
  }

  bool get _hasActiveFilters =>
      _searchCtrl.text.isNotEmpty || _minFeeCtrl.text.isNotEmpty || _maxFeeCtrl.text.isNotEmpty;

  void _clearFilters() {
    setState(() {
      _searchCtrl.clear();
      _minFeeCtrl.clear();
      _maxFeeCtrl.clear();
    });
    _fetchRoutes();
  }

  Future<void> _confirmDelete(String routeId) async {
    Get.defaultDialog(
      title: 'Delete Route',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: textDark),
      middleText: 'Are you sure you want to delete this bus route? This action cannot be undone.',
      middleTextStyle: const TextStyle(color: textMuted),
      textCancel: 'Cancel',
      textConfirm: 'Delete',
      confirmTextColor: Colors.white,
      buttonColor: AppTheme.errorRed,
      cancelTextColor: textMuted,
      radius: 12,
      onConfirm: () async {
        Get.back();
        final ok = await controller.deleteBusRoute(routeId);
        if (ok) _fetchRoutes();
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
          'Bus Routes & Stops',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () async {
                final created = await Get.to(() => BusRouteFormScreen(schoolId: widget.schoolId));
                if (created == true) _fetchRoutes();
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Route'),
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
              if (controller.isLoading.value && controller.busRoutes.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: primaryBlue));
              }

              if (controller.busRoutes.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                color: primaryBlue,
                onRefresh: () async => _fetchRoutes(),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.busRoutes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final route = controller.busRoutes[index];
                    return _RouteCard(
                      serial: index + 1,
                      route: route,
                      onView: () async {
                        final changed = await Get.to(
                              () => BusRouteDetailScreen(schoolId: widget.schoolId, routeId: route['_id']),
                        );
                        if (changed == true) _fetchRoutes();
                      },
                      onDelete: () => _confirmDelete(route['_id']),
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
          hintText: 'Search Route No or Name...',
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
        onSubmitted: (_) => _fetchRoutes(),
        onChanged: (val) {
          if (val.isEmpty) _fetchRoutes();
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
            label: (_minFeeCtrl.text.isEmpty && _maxFeeCtrl.text.isEmpty)
                ? 'Fee Filter'
                : 'Fee: ₹${_minFeeCtrl.text.isEmpty ? '0' : _minFeeCtrl.text} - ₹${_maxFeeCtrl.text.isEmpty ? 'Any' : _maxFeeCtrl.text}',
            active: _minFeeCtrl.text.isNotEmpty || _maxFeeCtrl.text.isNotEmpty,
            onTap: _openFeeSheet,
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
                child: const Icon(Icons.alt_route, size: 36, color: primaryBlue),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Bus Routes Found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
              ),
              const SizedBox(height: 6),
              const Text(
                'Adjust your search terms or add a new bus route to see data here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- Bottom sheet ----------------

  void _openFeeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _BottomSheetShell(
          title: 'Fee Filter',
          onClear: () {
            _minFeeCtrl.clear();
            _maxFeeCtrl.clear();
            Navigator.pop(context);
            _fetchRoutes();
          },
          onApply: () {
            Navigator.pop(context);
            _fetchRoutes();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Min Fee (₹)', style: TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _minFeeCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: textDark, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '0',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Max Fee (₹)', style: TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _maxFeeCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: textDark, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Any',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------- Reusable Helpers ----------------

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
          color: active ? _BusRouteListScreenState.lightBlueBg : _BusRouteListScreenState.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? _BusRouteListScreenState.primaryBlue : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? _BusRouteListScreenState.primaryBlue : _BusRouteListScreenState.textMuted,
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: active ? _BusRouteListScreenState.primaryBlue : _BusRouteListScreenState.textMuted,
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
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _BusRouteListScreenState.textDark)),
                  TextButton(
                    onPressed: onClear,
                    child: const Text('Clear', style: TextStyle(color: _BusRouteListScreenState.textMuted)),
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
                    backgroundColor: _BusRouteListScreenState.primaryBlue,
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

class _RouteCard extends StatelessWidget {
  final int serial;
  final Map<String, dynamic> route;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const _RouteCard({
    required this.serial,
    required this.route,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final stops = (route['stops'] as List?) ?? [];
    final stopCount = stops.length;
    final firstStop = stopCount > 0 ? (stops.first['stopName']?.toString() ?? '') : '';
    final lastStop = stopCount > 0 ? (stops.last['stopName']?.toString() ?? '') : '';
    final routeName = route['routeName']?.toString() ?? 'Route';
    final routeNo = route['routeNo']?.toString() ?? route['_id']?.toString() ?? '';
    final feeAmount = route['feeAmount'];

    return Container(
      decoration: BoxDecoration(
        color: _BusRouteListScreenState.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _BusRouteListScreenState.lightBlueBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.alt_route,
                      color: _BusRouteListScreenState.primaryBlue,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _BusRouteListScreenState.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (routeNo.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Route No: $routeNo',
                            style: const TextStyle(fontSize: 11, color: _BusRouteListScreenState.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.visibility_outlined, color: _BusRouteListScreenState.primaryBlue, size: 18),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$stopCount Stops',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _BusRouteListScreenState.textDark),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (stopCount > 0)
                    Expanded(
                      child: Text(
                        '$firstStop → $lastStop',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: _BusRouteListScreenState.textMuted),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _BusRouteListScreenState.lightGreenBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '₹${feeAmount ?? 0}',
                      style: const TextStyle(
                        color: _BusRouteListScreenState.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
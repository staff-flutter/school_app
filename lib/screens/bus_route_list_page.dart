import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/controllers/transport_controller.dart';

import 'bus_route_detail_page.dart';
import 'bus_route_form_page.dart';


/// "Bus Routes & Stops" list screen — mirrors the web dashboard at
/// /dashboard/routes: a filter panel (search by route no/name, min/max fee)
/// plus a list of routes showing route info, stops mapping, and fee.
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
  bool _filtersExpanded = false;

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

  void _clearFilters() {
    setState(() {
      _searchCtrl.clear();
      _minFeeCtrl.clear();
      _maxFeeCtrl.clear();
    });
    _fetchRoutes();
  }

  Future<void> _confirmDelete(String routeId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Route'),
        content: const Text('Are you sure you want to delete this bus route? This cannot be undone.'),
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
      final ok = await controller.deleteBusRoute(routeId);
      if (ok) _fetchRoutes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Routes & Stops'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () async {
                final created = await Get.to(() => BusRouteFormScreen(schoolId: widget.schoolId));
                if (created == true) _fetchRoutes();
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Route'),
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
              if (controller.isLoading.value && controller.busRoutes.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.busRoutes.isEmpty) {
                return const Center(child: Text('No bus routes found'));
              }
              return RefreshIndicator(
                onRefresh: () async => _fetchRoutes(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: controller.busRoutes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                  const Text('Route Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  Icon(_filtersExpanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
            if (_filtersExpanded) ...[
              const SizedBox(height: 12),
              const Text('SEARCH ROUTES', style: TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 0.3)),
              const SizedBox(height: 6),
              TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Icons.search, size: 18),
                  hintText: 'Route No or Name...',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _fetchRoutes(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('MIN FEE (₹)', style: TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 0.3)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _minFeeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(isDense: true, hintText: '0', border: OutlineInputBorder()),
                          onSubmitted: (_) => _fetchRoutes(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('MAX FEE (₹)', style: TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 0.3)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _maxFeeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(isDense: true, hintText: 'Any', border: OutlineInputBorder()),
                          onSubmitted: (_) => _fetchRoutes(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(onPressed: _clearFilters, child: const Text('Clear Filters')),
              ),
            ],
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

    return Card(
      child: InkWell(
        onTap: onView,
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
                    Text(routeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    if (routeNo.isNotEmpty)
                      Text('ID: $routeNo', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('$stopCount Stops', style: const TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        if (stopCount > 0)
                          Expanded(
                            child: Text(
                              '$firstStop → $lastStop',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('₹${feeAmount ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
      ),
    );
  }
}
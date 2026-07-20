import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/controllers/transport_controller.dart';

import 'assign_bus_page.dart';
import 'bus_route_form_page.dart';


/// Single Bus Route detail screen — mirrors Image 3:
///   header (route name, ID badge, fee, stop count, Edit Route / Assign Bus)
///   Route Journey timeline (ordered stops)
///   Active Assignments (assigned bus, driver, stop timings, edit/delete)
class BusRouteDetailScreen extends StatefulWidget {
  final String schoolId;
  final String routeId;

  const BusRouteDetailScreen({super.key, required this.schoolId, required this.routeId});

  @override
  State<BusRouteDetailScreen> createState() => _BusRouteDetailScreenState();
}

class _BusRouteDetailScreenState extends State<BusRouteDetailScreen> {
  final TransportController controller = Get.find<TransportController>();

  Map<String, dynamic>? _route;
  bool _loading = true;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await controller.getBusRouteById(widget.routeId);
    setState(() {
      _route = data;
      _loading = false;
    });
  }

  Future<void> _confirmDeleteAssignment(String assignmentId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Remove Assignment'),
        content: const Text('Remove this bus assignment from the route?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('Remove', style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final ok = await controller.deleteBusRouteAssignment(
        routeId: widget.routeId,
        schoolId: widget.schoolId,
        assignmentId: assignmentId,
      );
      if (ok) {
        _changed = true;
        _load();
      }
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
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back(result: _changed)),
          title: Text(_route?['routeName']?.toString() ?? 'Route Details'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _route == null
            ? const Center(child: Text('Route not found'))
            : RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _sectionTitle(Icons.place_outlined, 'Route Journey'),
              const SizedBox(height: 8),
              _buildJourneyCard(),
              const SizedBox(height: 20),
              _sectionTitle(Icons.directions_bus_outlined, 'Active Assignments'),
              const SizedBox(height: 8),
              _buildAssignments(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final routeNo = _route!['routeNo']?.toString() ?? _route!['_id']?.toString() ?? '';
    final feeAmount = _route!['feeAmount'];
    final stopCount = ((_route!['stops'] as List?) ?? []).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(_route!['routeName']?.toString() ?? 'Route', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            if (routeNo.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Text('ID: $routeNo', style: const TextStyle(fontSize: 11)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Fee: ₹${feeAmount ?? 0} • $stopCount Stops', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit Route'),
                onPressed: () async {
                  final updated = await Get.to(
                        () => BusRouteFormScreen(schoolId: widget.schoolId, existing: _route),
                  );
                  if (updated == true) {
                    _changed = true;
                    _load();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Assign Bus'),
                onPressed: () async {
                  final stops = (_route!['stops'] as List?) ?? [];
                  final added = await Get.to(
                        () => AssignBusScreen(schoolId: widget.schoolId, routeId: widget.routeId, stops: stops),
                  );
                  if (added == true) {
                    _changed = true;
                    _load();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJourneyCard() {
    final stops = (_route!['stops'] as List?) ?? [];
    if (stops.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No stops configured for this route.')));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(stops.length, (i) {
            final isFirst = i == 0;
            final isLast = i == stops.length - 1;
            final dotColor = isFirst
                ? Colors.green
                : isLast
                ? Colors.red
                : Colors.grey.shade700;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                      if (!isLast) Expanded(child: Container(width: 2, color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stops[i]['stopName']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                          if ((stops[i]['landmark']?.toString() ?? '').isNotEmpty)
                            Text(stops[i]['landmark'].toString(), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildAssignments() {
    final assignments = (_route!['assignments'] as List?) ?? [];
    if (assignments.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No buses assigned to this route yet.')));
    }
    return Column(
      children: assignments.map<Widget>((a) => _buildAssignmentCard(a)).toList(),
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> a) {
    final bus = a['busId'];
    final busLabel = bus is Map ? (bus['busNumber']?.toString() ?? bus['registrationNo']?.toString() ?? '-') : '-';
    final driver = a['driverId'];
    final driverLabel = driver is Map ? (driver['name']?.toString() ?? '-') : (driver?.toString() ?? '-');
    final shift = a['shift']?.toString() ?? '';
    final shiftLabel = shift == 'drop' ? 'Drop Shift' : 'Pick Up Shift';
    final timings = (a['stopTimings'] as List?) ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 18, backgroundColor: Colors.grey.shade200, child: const Icon(Icons.directions_bus, size: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ASSIGNED BUS', style: TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 0.3)),
                      Text(busLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(shiftLabel.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 0.3)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            final stops = (_route!['stops'] as List?) ?? [];
                            final updated = await Get.to(
                                  () => AssignBusScreen(
                                schoolId: widget.schoolId,
                                routeId: widget.routeId,
                                stops: stops,
                                existing: a,
                              ),
                            );
                            if (updated == true) {
                              _changed = true;
                              _load();
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 18, color: AppTheme.errorRed),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _confirmDeleteAssignment(a['_id'].toString()),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.badge_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Driver: $driverLabel'),
              ],
            ),
            const Divider(height: 24),
            const Text('STOP TIMINGS', style: TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 0.3)),
            const SizedBox(height: 8),
            for (final t in timings)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t['stopName']?.toString() ?? '-'),
                    Text(t['time']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
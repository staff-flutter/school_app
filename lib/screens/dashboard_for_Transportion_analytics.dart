import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:school_app/controllers/transport_controller.dart';

import '../controllers/auth_controller.dart';
import '../controllers/school_controller.dart';

/// "Transportation Analytics" screen — mirrors /dashboard/transportaion-analytics.
///
/// Requires the `fl_chart` package: add `fl_chart: ^0.68.0` (or latest) to pubspec.yaml.
///
/// CHANGELOG vs previous version:
///   - FIXED: stat-card grid overflow ("BOTTOM OVERFLOWED BY N PIXELS"). The
///     old GridView.count(childAspectRatio: 1.8) forced a fixed card height
///     that didn't fit longer labels ("PROJECTED MONTH-END") or larger text
///     scale settings. Cards now size to their own content via IntrinsicHeight
///     row-pairs + a FittedBox on the value text, so they can never overflow
///     regardless of label length or accessibility text scaling.
///   - CONFIRMED: the fuel-log `dailyTrend` field (date/totalAmountSpent)
///     rendered correctly on-device and matches the web's "Total Fleet Spend
///     Over Time" card shape — no longer flagged as unconfirmed.
///   - ADDED (fuel tab, matching the web reference screenshots):
///       * Bus-Wise Fuel Consumption — grouped bars (amount/quantity/fill-ups)
///       * Payment Modes — donut chart
///       * Fleet Mileage Performance — km/L per bus
///       * Top Fuel Stations — ranked list
///     These read GUESSED field names (see comments on each) and are built
///     defensively: if the key isn't in the API response yet, the section
///     just doesn't render — nothing crashes. Swap in real field names once
///     you can confirm them from a fuller getFuelLogAnalytics payload.
///
/// STILL UNCONFIRMED: the query param names used to filter by
/// Today/Week/Month/Year and the custom Apply range — check the Network tab
/// and adjust `period`/`fromDate`/`toDate` in TransportController if wrong.
class TransportationAnalyticsScreen extends StatefulWidget {
  const TransportationAnalyticsScreen({super.key});

  @override
  State<TransportationAnalyticsScreen> createState() => _TransportationAnalyticsScreenState();
}

enum _AnalyticsTab { dailyTrips, fuelLogs }

enum _RangeType { today, week, month, year, custom }

class _TransportationAnalyticsScreenState extends State<TransportationAnalyticsScreen> {
  final TransportController controller = Get.find<TransportController>();
  SchoolController? get _school => Get.isRegistered<SchoolController>() ? Get.find<SchoolController>() : null;
  final AuthController _authController = Get.find<AuthController>();

  _AnalyticsTab _tab = _AnalyticsTab.dailyTrips;
  _RangeType _range = _RangeType.month;
  DateTime? _customFrom;
  DateTime? _customTo;

  Map<String, dynamic>? _tripAnalytics;
  Map<String, dynamic>? _fuelAnalytics;
  bool _loading = true;
  String? schoolId;
  late final role = _authController.user.value?.role?.toLowerCase() ?? '';

  final DateFormat _apiDateFmt = DateFormat('yyyy-MM-dd');
  final DateFormat _chartDateFmt = DateFormat('dd MMM');

  static const List<Color> _busColors = [Colors.indigo, Colors.teal, Colors.deepOrange, Colors.purple, Colors.blueGrey, Colors.pink];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (role == 'correspondent') {
      schoolId = _school?.selectedSchool.value?.id;
    } else {
      schoolId = _authController.user.value?.schoolId;
    }
    if (schoolId == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    if (!mounted) return;
    setState(() => _loading = true);

    if (_tab == _AnalyticsTab.dailyTrips) {
      final data = await controller.getDailyTripLogAnalytics(
        schoolId!,
        period: _range == _RangeType.custom ? null : _range.name,
        fromDate: _range == _RangeType.custom && _customFrom != null ? _apiDateFmt.format(_customFrom!) : null,
        toDate: _range == _RangeType.custom && _customTo != null ? _apiDateFmt.format(_customTo!) : null,
      );
      if (!mounted) return;
      setState(() {
        _tripAnalytics = data;
        _loading = false;
      });
    } else {
      final data = await controller.getFuelLogAnalytics(schoolId!);
      if (!mounted) return;
      setState(() {
        _fuelAnalytics = data;
        _loading = false;
      });
    }
  }

  Future<void> _pickCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
      initialDateRange: _customFrom != null && _customTo != null ? DateTimeRange(start: _customFrom!, end: _customTo!) : null,
    );
    if (range != null) {
      setState(() {
        _customFrom = range.start;
        _customTo = range.end;
        _range = _RangeType.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transportation Analytics'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SegmentedButton<_AnalyticsTab>(
              segments: const [
                ButtonSegment(value: _AnalyticsTab.dailyTrips, label: Text('Daily Trips'), icon: Icon(Icons.alt_route, size: 16)),
                ButtonSegment(value: _AnalyticsTab.fuelLogs, label: Text('Fuel Logs'), icon: Icon(Icons.local_gas_station, size: 16)),
              ],
              selected: {_tab},
              onSelectionChanged: (sel) {
                setState(() => _tab = sel.first);
                _load();
              },
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : schoolId == null
          ? const Center(child: Text('No school selected.'))
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildRangeSelector(),
            const SizedBox(height: 16),
            if (_tab == _AnalyticsTab.dailyTrips) _buildDailyTripsTab() else _buildFuelLogsTab(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Range / period selector
  // ---------------------------------------------------------------------

  Widget _buildRangeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final r in [_RangeType.today, _RangeType.week, _RangeType.month, _RangeType.year])
          ChoiceChip(
            label: Text(r.name[0].toUpperCase() + r.name.substring(1)),
            selected: _range == r,
            onSelected: (_) {
              setState(() => _range = r);
              _load();
            },
          ),
        OutlinedButton.icon(
          onPressed: _pickCustomRange,
          icon: const Icon(Icons.date_range, size: 16),
          label: Text(
            _customFrom != null && _customTo != null ? '${_apiDateFmt.format(_customFrom!)} - ${_apiDateFmt.format(_customTo!)}' : 'Custom range',
          ),
        ),
        if (_range == _RangeType.custom && _customFrom != null && _customTo != null) ElevatedButton(onPressed: _load, child: const Text('Apply')),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Daily Trips tab
  // ---------------------------------------------------------------------

  Widget _buildDailyTripsTab() {
    if (_tripAnalytics == null) {
      return const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No trip analytics available.')));
    }

    final summary = (_tripAnalytics!['summary'] as Map?) ?? {};
    final busWise = (_tripAnalytics!['busWiseBreakdown'] as List?) ?? [];
    final dailyTrend = (_tripAnalytics!['dailyTrend'] as List?) ?? [];
    final busDailyTrend = (_tripAnalytics!['busDailyTrend'] as List?) ?? [];
    final idleBuses = (_tripAnalytics!['idleBuses'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Daily Trip Analytics'),
        const SizedBox(height: 12),
        _buildStatGrid([
          _StatCardData('Total Distance', '${summary['totalKmRun'] ?? 0} km', Icons.map_outlined, Colors.indigo),
          _StatCardData('Total Trips', '${summary['totalTrips'] ?? 0}', Icons.alt_route, Colors.teal),
          _StatCardData('Avg KM / Trip', '${_fmtNum(summary['avgKmPerTrip'])} km', Icons.speed, Colors.orange),
          _StatCardData('Max KM in a Day', '${summary['maxKmInADay'] ?? 0} km', Icons.event, Colors.pink),
        ]),
        const SizedBox(height: 24),
        _sectionTitle('Daily Distance Trend'),
        const Text('Kilometers covered across all fleet vehicles per day.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),
        SizedBox(height: 220, child: _buildFleetDailyTrendChart(dailyTrend)),
        const SizedBox(height: 24),
        _sectionTitle('Individual Bus Trends'),
        const Text('Daily distance covered by each vehicle.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),
        SizedBox(height: 220, child: _buildBusDailyTrendChart(busDailyTrend)),
        const SizedBox(height: 24),
        _sectionTitle('Fleet Utilization'),
        const Text('Total distance driven segmented by individual buses.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),
        SizedBox(height: 220, child: _buildFleetUtilizationChart(busWise)),
        const SizedBox(height: 24),
        _buildIdleVehiclesCard(idleBuses),
      ],
    );
  }

  Widget _buildFleetDailyTrendChart(List dailyTrend) {
    if (dailyTrend.isEmpty) return const Center(child: Text('No trend data for this period.'));

    final spots = <FlSpot>[];
    final labels = <String>[];
    for (var i = 0; i < dailyTrend.length; i++) {
      final entry = dailyTrend[i];
      final km = (entry['totalKmRun'] as num?)?.toDouble() ?? 0;
      spots.add(FlSpot(i.toDouble(), km));
      labels.add(_formatChartDate(entry['date']));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, m) => _axisLabel(v, labels))),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.indigo,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: Colors.indigo.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }

  Widget _buildBusDailyTrendChart(List busDailyTrend) {
    if (busDailyTrend.isEmpty) return const Center(child: Text('No per-bus trend data for this period.'));

    final allDates = busDailyTrend.map((e) => e['date']?.toString() ?? '').toSet().toList()..sort();
    final dateIndex = {for (var i = 0; i < allDates.length; i++) allDates[i]: i};

    final Map<String, List<dynamic>> byBus = {};
    for (final entry in busDailyTrend) {
      final busId = entry['busId']?.toString() ?? 'unknown';
      byBus.putIfAbsent(busId, () => []).add(entry);
    }

    final busIds = byBus.keys.toList();
    final lines = <LineChartBarData>[];
    final legend = <Widget>[];

    for (var i = 0; i < busIds.length; i++) {
      final busId = busIds[i];
      final entries = byBus[busId]!;
      final color = _busColors[i % _busColors.length];
      final label = entries.first['registrationNo']?.toString() ?? entries.first['busNumber']?.toString() ?? busId;

      final spots = entries.map((e) {
        final idx = dateIndex[e['date']?.toString() ?? ''] ?? 0;
        final km = (e['dailyKmRun'] as num?)?.toDouble() ?? 0;
        return FlSpot(idx.toDouble(), km);
      }).toList()
        ..sort((a, b) => a.x.compareTo(b.x));

      lines.add(LineChartBarData(spots: spots, isCurved: true, color: color, barWidth: 3, dotData: const FlDotData(show: true)));
      legend.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ));
    }

    final labels = allDates.map(_formatChartDate).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 12, runSpacing: 4, children: legend),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, m) => _axisLabel(v, labels))),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: lines,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFleetUtilizationChart(List busWise) {
    if (busWise.isEmpty) return const Center(child: Text('No bus activity for this period.'));

    final bars = <BarChartGroupData>[];
    final labels = <String>[];
    for (var i = 0; i < busWise.length; i++) {
      final b = busWise[i];
      final km = (b['totalKmRun'] as num?)?.toDouble() ?? 0;
      bars.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: km, color: _busColors[i % _busColors.length], width: 28, borderRadius: BorderRadius.circular(4)),
      ]));
      labels.add(b['registrationNo']?.toString() ?? b['busNumber']?.toString() ?? 'Bus');
    }

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, m) => _axisLabel(v, labels))),
        ),
        borderData: FlBorderData(show: false),
        barGroups: bars,
      ),
    );
  }

  Widget _buildIdleVehiclesCard(List idleBuses) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                const Text('Idle Vehicles', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text('${idleBuses.length} Inactive', style: const TextStyle(fontSize: 12, color: Colors.orange)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (idleBuses.isEmpty)
              const Text('All buses had activity this period.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: idleBuses
                    .map((b) => Chip(
                  avatar: const Icon(Icons.directions_bus, size: 16),
                  label: Text(b['registrationNo']?.toString() ?? b['busNumber']?.toString() ?? 'Bus'),
                ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Fuel Logs tab
  // ---------------------------------------------------------------------

  Widget _buildFuelLogsTab() {
    if (_fuelAnalytics == null) {
      return const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No fuel analytics available.')));
    }

    final summary = (_fuelAnalytics!['summary'] as Map?) ?? {};
    final busWise = (_fuelAnalytics!['busWiseBreakdown'] as List?) ?? [];
    final dailyTrend = (_fuelAnalytics!['dailyTrend'] as List?) ?? [];

    // GUESSED — not in the sample payload shared so far. Each section only
    // renders if its list is non-empty, so this is safe even if the backend
    // never sends these keys.
    final paymentModeBreakdown = (_fuelAnalytics!['paymentModeBreakdown'] as List?) ?? [];
    final mileageBreakdown = (_fuelAnalytics!['mileageBreakdown'] as List?) ?? [];
    final topFuelStations = (_fuelAnalytics!['topFuelStations'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Fuel Log Analytics'),
        const SizedBox(height: 12),
        _buildStatGrid([
          _StatCardData('Total Spent', '₹${summary['totalAmountSpent'] ?? 0}', Icons.currency_rupee, Colors.red),
          _StatCardData('Total Fuel', '${_fmtNum(summary['totalFuelQuantity'])} L', Icons.local_gas_station, Colors.blue),
          _StatCardData('Fill-Ups', '${summary['totalFillUps'] ?? 0}', Icons.local_shipping, Colors.teal),
          _StatCardData('Avg Daily Cost', '₹${_fmtNum(summary['avgDailyCost'])}', Icons.calendar_today, Colors.orange),
          _StatCardData('Avg Daily Use', '${_fmtNum(summary['avgDailyConsumption'])} L', Icons.speed, Colors.purple),
          _StatCardData('Projected Month Spend', '₹${_fmtNum(summary['projectedMonthEndCost'])}', Icons.trending_up, Colors.pink),
        ]),
        const SizedBox(height: 24),
        _sectionTitle('Total Fleet Spend Over Time'),
        const Text('Combined daily fuel expenses across all vehicles.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),
        SizedBox(height: 220, child: _buildFuelDailyTrendChart(dailyTrend)),
        const SizedBox(height: 24),
        _sectionTitle('Bus-Wise Fuel Consumption'),
        const Text('Amount spent, liters consumed, and total fill-ups per vehicle.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),
        SizedBox(height: 260, child: _buildBusWiseFuelChart(busWise)),
        if (paymentModeBreakdown.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionTitle('Payment Modes (₹)'),
          const SizedBox(height: 12),
          SizedBox(height: 220, child: _buildPaymentModesChart(paymentModeBreakdown)),
        ],
        if (mileageBreakdown.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionTitle('Fleet Mileage Performance'),
          const Text('Kilometers per litre (km/L) breakdown by bus.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          SizedBox(height: 220, child: _buildMileageChart(mileageBreakdown)),
        ],
        if (topFuelStations.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionTitle('Top Fuel Stations'),
          const SizedBox(height: 12),
          _buildTopFuelStationsList(topFuelStations),
        ],
      ],
    );
  }

  Widget _buildFuelDailyTrendChart(List dailyTrend) {
    if (dailyTrend.isEmpty) return const Center(child: Text('No fuel trend data for this period.'));
    final spots = <FlSpot>[];
    final labels = <String>[];
    for (var i = 0; i < dailyTrend.length; i++) {
      final entry = dailyTrend[i];
      final amount = (entry['totalAmountSpent'] as num?)?.toDouble() ?? 0;
      spots.add(FlSpot(i.toDouble(), amount));
      labels.add(_formatChartDate(entry['date']));
    }
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, m) => _axisLabel(v, labels))),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: Colors.red.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }

  /// Matches the web's "Bus-Wise Fuel Consumption" — three metrics per bus
  /// (amount spent / quantity / fill-ups) as a grouped bar chart. Amount and
  /// quantity share the left axis scale here for simplicity (fl_chart's dual
  /// left/right axis scaling per-series isn't trivial); fill-ups are usually
  /// a much smaller number so they'll render as thin bars near zero — good
  /// enough to see fill-up count relative position, not exact value at a
  /// glance. Tap-to-see-value via BarTooltipData covers the rest.
  Widget _buildBusWiseFuelChart(List busWise) {
    if (busWise.isEmpty) return const Center(child: Text('No fuel activity for this period.'));

    final labels = <String>[];
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < busWise.length; i++) {
      final b = busWise[i];
      final amount = (b['totalAmountSpent'] as num?)?.toDouble() ?? 0;
      final quantity = (b['totalFuelQuantity'] as num?)?.toDouble() ?? 0;
      final fillUps = (b['totalFillUps'] as num?)?.toDouble() ?? 0;
      labels.add(b['registrationNo']?.toString() ?? b['busNumber']?.toString() ?? 'Bus');

      groups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(toY: amount, color: const Color(0xFF2ECC71), width: 12, borderRadius: BorderRadius.circular(3)),
          BarChartRodData(toY: quantity, color: const Color(0xFF3B82F6), width: 12, borderRadius: BorderRadius.circular(3)),
          BarChartRodData(toY: fillUps, color: const Color(0xFFF59E0B), width: 12, borderRadius: BorderRadius.circular(3)),
        ],
        barsSpace: 4,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 16, children: const [
          _LegendDot(color: Color(0xFF2ECC71), label: 'Amount Spent (₹)'),
          _LegendDot(color: Color(0xFF3B82F6), label: 'Quantity (L)'),
          _LegendDot(color: Color(0xFFF59E0B), label: 'Fill Ups'),
        ]),
        const SizedBox(height: 8),
        Expanded(
          child: BarChart(
            BarChartData(
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, m) => _axisLabel(v, labels))),
              ),
              borderData: FlBorderData(show: false),
              barGroups: groups,
            ),
          ),
        ),
      ],
    );
  }

  /// GUESSED shape: `paymentModeBreakdown: [{ mode: 'Cash', amount: 40000 }, ...]`
  Widget _buildPaymentModesChart(List paymentModeBreakdown) {
    final colors = [Colors.teal, Colors.indigo, Colors.orange, Colors.pink, Colors.purple];
    final sections = <PieChartSectionData>[];
    final legend = <Widget>[];

    for (var i = 0; i < paymentModeBreakdown.length; i++) {
      final p = paymentModeBreakdown[i];
      final amount = (p['amount'] as num?)?.toDouble() ?? 0;
      final mode = p['mode']?.toString() ?? p['paymentMode']?.toString() ?? 'Unknown';
      final color = colors[i % colors.length];
      sections.add(PieChartSectionData(value: amount, color: color, title: '', radius: 40));
      legend.add(_LegendDot(color: color, label: mode));
    }

    return Column(
      children: [
        Expanded(child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 50, sectionsSpace: 2))),
        const SizedBox(height: 8),
        Wrap(spacing: 16, children: legend),
      ],
    );
  }

  /// GUESSED shape: `mileageBreakdown: [{ busId, busNumber, registrationNo, kmPerLiter }]`
  Widget _buildMileageChart(List mileageBreakdown) {
    final bars = <BarChartGroupData>[];
    final labels = <String>[];
    for (var i = 0; i < mileageBreakdown.length; i++) {
      final m = mileageBreakdown[i];
      final kmPerLiter = (m['kmPerLiter'] as num?)?.toDouble() ?? 0;
      bars.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: kmPerLiter, color: Colors.deepPurple, width: 28, borderRadius: BorderRadius.circular(4)),
      ]));
      labels.add(m['registrationNo']?.toString() ?? m['busNumber']?.toString() ?? 'Bus');
    }
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, m) => _axisLabel(v, labels))),
        ),
        borderData: FlBorderData(show: false),
        barGroups: bars,
      ),
    );
  }

  /// GUESSED shape: `topFuelStations: [{ stationName, fillUps, amountSpent }]`
  Widget _buildTopFuelStationsList(List topFuelStations) {
    return Column(
      children: topFuelStations.map((s) {
        final name = s['stationName']?.toString() ?? s['fuelStation']?.toString() ?? 'Station';
        final fillUps = s['fillUps'] ?? s['totalFillUps'] ?? 0;
        final amount = s['amountSpent'] ?? s['totalAmountSpent'] ?? 0;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.local_gas_station, size: 18)),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('$fillUps Fill Ups'),
            trailing: Text('₹$amount', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------
  // Shared UI helpers
  // ---------------------------------------------------------------------

  Widget _sectionTitle(String title) => Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18));

  Widget _axisLabel(double value, List<String> labels) {
    final i = value.toInt();
    if (i < 0 || i >= labels.length) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(top: 4), child: Text(labels[i], style: const TextStyle(fontSize: 10)));
  }

  String _formatChartDate(dynamic raw) {
    final s = raw?.toString() ?? '';
    try {
      return _chartDateFmt.format(DateTime.parse(s));
    } catch (_) {
      return s;
    }
  }

  /// Auto-sizing stat card grid — FIXES the overflow bug.
  ///
  /// Previously used GridView.count(childAspectRatio: 1.8), which forces a
  /// fixed card height. Once a label wrapped ("PROJECTED MONTH-END") or the
  /// device's text scale was bumped up, the content no longer fit inside
  /// that fixed height and Flutter threw the yellow/black overflow stripes.
  ///
  /// Fix: lay cards out two-per-row using IntrinsicHeight (so both cards in
  /// a row match each other's height, whichever is taller) with NO fixed
  /// height constraint on the row itself — so the row simply grows to fit
  /// its tallest card's actual content. The value text is also wrapped in a
  /// FittedBox so long numbers shrink to fit instead of overflowing
  /// horizontally.
  Widget _buildStatGrid(List<_StatCardData> stats) {
    final rows = <Widget>[];
    for (var i = 0; i < stats.length; i += 2) {
      final left = stats[i];
      final right = i + 1 < stats.length ? stats[i + 1] : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _statCard(left)),
              const SizedBox(width: 12),
              Expanded(child: right != null ? _statCard(right) : const SizedBox.shrink()),
            ],
          ),
        ),
      );
      if (i + 2 < stats.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }

  Widget _statCard(_StatCardData s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 16, backgroundColor: s.color.withOpacity(0.15), child: Icon(s.icon, size: 16, color: s.color)),
            const SizedBox(height: 10),
            Text(
              s.label.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 0.3),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(s.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtNum(dynamic n) {
    if (n == null) return '-';
    final d = (n as num).toDouble();
    return d.toStringAsFixed(d.truncateToDouble() == d ? 0 : 2);
  }
}

class _StatCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _StatCardData(this.label, this.value, this.icon, this.color);
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
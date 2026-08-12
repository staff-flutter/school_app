import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:school_app/controllers/transport_controller.dart';

import '../controllers/auth_controller.dart';
import '../controllers/school_controller.dart';

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

  // App Theme Palette (Matching Dashboard: Blue, Yellow/Amber, Green, White)
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color lightBlueBg = Color(0xFFEFF6FF);
  static const Color primaryYellow = Color(0xFFF59E0B);
  static const Color lightYellowBg = Color(0xFFFEF3C7);
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color lightGreenBg = Color(0xFFD1FAE5);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);

  static const List<Color> _busColors = [
    Color(0xFF2563EB), // Blue
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Yellow/Orange
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
  ];

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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              surface: cardBg,
            ),
          ),
          child: child!,
        );
      },
    );
    if (range != null) {
      setState(() {
        _customFrom = range.start;
        _customTo = range.end;
        _range = _RangeType.custom;
      });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Transportation Analytics',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  _buildTabButton('Daily Trips', Icons.alt_route, _AnalyticsTab.dailyTrips),
                  _buildTabButton('Fuel Logs', Icons.local_gas_station, _AnalyticsTab.fuelLogs),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : schoolId == null
          ? const Center(child: Text('No school selected.', style: TextStyle(color: textMuted)))
          : RefreshIndicator(
        color: primaryBlue,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildRangeSelector(),
            const SizedBox(height: 20),
            if (_tab == _AnalyticsTab.dailyTrips) _buildDailyTripsTab() else _buildFuelLogsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, IconData icon, _AnalyticsTab tab) {
    final isSelected = _tab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            setState(() => _tab = tab);
            _load();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : textMuted),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : textMuted,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRangeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final r in [_RangeType.today, _RangeType.week, _RangeType.month, _RangeType.year])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(r.name[0].toUpperCase() + r.name.substring(1)),
                selected: _range == r,
                selectedColor: lightBlueBg,
                backgroundColor: cardBg,
                labelStyle: TextStyle(
                  color: _range == r ? primaryBlue : textMuted,
                  fontWeight: _range == r ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: _range == r ? primaryBlue : const Color(0xFFE2E8F0),
                  ),
                ),
                showCheckmark: false,
                onSelected: (_) {
                  setState(() => _range = r);
                  _load();
                },
              ),
            ),
          ActionChip(
            onPressed: _pickCustomRange,
            avatar: Icon(Icons.date_range, size: 16, color: _range == _RangeType.custom ? primaryBlue : textMuted),
            label: Text(
              _customFrom != null && _customTo != null
                  ? '${_apiDateFmt.format(_customFrom!)} - ${_apiDateFmt.format(_customTo!)}'
                  : 'Custom',
            ),
            backgroundColor: _range == _RangeType.custom ? lightBlueBg : cardBg,
            labelStyle: TextStyle(
              color: _range == _RangeType.custom ? primaryBlue : textMuted,
              fontWeight: _range == _RangeType.custom ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: _range == _RangeType.custom ? primaryBlue : const Color(0xFFE2E8F0),
              ),
            ),
          ),
        ],
      ),
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
          _StatCardData('Total Distance', '${summary['totalKmRun'] ?? 0} km', Icons.map_outlined, primaryBlue, lightBlueBg),
          _StatCardData('Total Trips', '${summary['totalTrips'] ?? 0}', Icons.alt_route, primaryGreen, lightGreenBg),
          _StatCardData('Avg KM / Trip', '${_fmtNum(summary['avgKmPerTrip'])} km', Icons.speed, primaryYellow, lightYellowBg),
          _StatCardData('Max KM in a Day', '${summary['maxKmInADay'] ?? 0} km', Icons.event, const Color(0xFFEC4899), const Color(0xFFFCE7F3)),
        ]),
        const SizedBox(height: 20),
        _buildChartCard('Daily Distance Trend', 'Kilometers covered across all fleet vehicles per day.', _buildFleetDailyTrendChart(dailyTrend)),
        const SizedBox(height: 16),
        _buildChartCard('Individual Bus Trends', 'Daily distance covered by each vehicle.', _buildBusDailyTrendChart(busDailyTrend)),
        const SizedBox(height: 16),
        _buildChartCard('Fleet Utilization', 'Total distance driven segmented by individual buses.', _buildFleetUtilizationChart(busWise)),
        const SizedBox(height: 16),
        _buildIdleVehiclesCard(idleBuses),
      ],
    );
  }

  Widget _buildChartCard(String title, String subtitle, Widget chartWidget) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: textMuted)),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: chartWidget),
        ],
      ),
    );
  }

  Widget _buildFleetDailyTrendChart(List dailyTrend) {
    if (dailyTrend.isEmpty) return const Center(child: Text('No trend data for this period.', style: TextStyle(color: textMuted)));

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
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1)),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, m) => _axisLabelText(v.toInt().toString()))),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (v, m) => _axisLabel(v, labels))),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: primaryBlue,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [primaryBlue.withOpacity(0.2), primaryBlue.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusDailyTrendChart(List busDailyTrend) {
    if (busDailyTrend.isEmpty) return const Center(child: Text('No per-bus trend data for this period.', style: TextStyle(color: textMuted)));

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
      }).toList()..sort((a, b) => a.x.compareTo(b.x));

      lines.add(LineChartBarData(spots: spots, isCurved: true, color: color, barWidth: 2.5, dotData: const FlDotData(show: false)));
      legend.add(_LegendDot(color: color, label: label));
    }

    final labels = allDates.map(_formatChartDate).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 12, runSpacing: 4, children: legend),
        const SizedBox(height: 12),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1)),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, m) => _axisLabelText(v.toInt().toString()))),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (v, m) => _axisLabel(v, labels))),
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
    if (busWise.isEmpty) return const Center(child: Text('No bus activity for this period.', style: TextStyle(color: textMuted)));

    final bars = <BarChartGroupData>[];
    final labels = <String>[];
    for (var i = 0; i < busWise.length; i++) {
      final b = busWise[i];
      final km = (b['totalKmRun'] as num?)?.toDouble() ?? 0;
      bars.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(
          toY: km,
          color: _busColors[i % _busColors.length],
          width: 20,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
        ),
      ]));
      labels.add(b['registrationNo']?.toString() ?? b['busNumber']?.toString() ?? 'Bus');
    }

    return BarChart(
      BarChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1)),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, m) => _axisLabelText(v.toInt().toString()))),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (v, m) => _axisLabel(v, labels))),
        ),
        borderData: FlBorderData(show: false),
        barGroups: bars,
      ),
    );
  }

  Widget _buildIdleVehiclesCard(List idleBuses) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: lightYellowBg, shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: primaryYellow, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Idle Vehicles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: lightYellowBg, borderRadius: BorderRadius.circular(12)),
                child: Text('${idleBuses.length} Inactive', style: const TextStyle(fontSize: 12, color: primaryYellow, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (idleBuses.isEmpty)
            const Text('All buses had activity during this period.', style: TextStyle(color: textMuted, fontSize: 13))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: idleBuses
                  .map((b) => Chip(
                elevation: 0,
                backgroundColor: const Color(0xFFF8FAFC),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                avatar: const Icon(Icons.directions_bus, size: 16, color: primaryBlue),
                label: Text(b['registrationNo']?.toString() ?? b['busNumber']?.toString() ?? 'Bus', style: const TextStyle(color: textDark, fontSize: 12)),
              ))
                  .toList(),
            ),
        ],
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
    final paymentModeBreakdown = (_fuelAnalytics!['paymentModeBreakdown'] as List?) ?? [];
    final mileageBreakdown = (_fuelAnalytics!['mileageBreakdown'] as List?) ?? [];
    final topFuelStations = (_fuelAnalytics!['topFuelStations'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Fuel Log Analytics'),
        const SizedBox(height: 12),
        _buildStatGrid([
          _StatCardData('Total Spent', '₹${summary['totalAmountSpent'] ?? 0}', Icons.currency_rupee, primaryYellow, lightYellowBg),
          _StatCardData('Total Fuel', '${_fmtNum(summary['totalFuelQuantity'])} L', Icons.local_gas_station, primaryBlue, lightBlueBg),
          _StatCardData('Fill-Ups', '${summary['totalFillUps'] ?? 0}', Icons.local_shipping, primaryGreen, lightGreenBg),
          _StatCardData('Avg Daily Cost', '₹${_fmtNum(summary['avgDailyCost'])}', Icons.calendar_today, const Color(0xFF6366F1), const Color(0xFFEEF2FF)),
          _StatCardData('Avg Daily Use', '${_fmtNum(summary['avgDailyConsumption'])} L', Icons.speed, const Color(0xFF8B5CF6), const Color(0xFFF3E8FF)),
          _StatCardData('Projected Spend', '₹${_fmtNum(summary['projectedMonthEndCost'])}', Icons.trending_up, const Color(0xFFEC4899), const Color(0xFFFCE7F3)),
        ]),
        const SizedBox(height: 20),
        _buildChartCard('Total Fleet Spend Over Time', 'Combined daily fuel expenses across all vehicles.', _buildFuelDailyTrendChart(dailyTrend)),
        const SizedBox(height: 16),
        _buildChartCard('Bus-Wise Fuel Consumption', 'Amount spent, liters consumed, and total fill-ups per vehicle.', _buildBusWiseFuelChart(busWise)),
        if (paymentModeBreakdown.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildChartCard('Payment Modes (₹)', 'Distribution of payment methods', _buildPaymentModesChart(paymentModeBreakdown)),
        ],
        if (mileageBreakdown.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildChartCard('Fleet Mileage Performance', 'Kilometers per litre (km/L) breakdown by bus.', _buildMileageChart(mileageBreakdown)),
        ],
        if (topFuelStations.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionTitle('Top Fuel Stations'),
          const SizedBox(height: 12),
          _buildTopFuelStationsList(topFuelStations),
        ],
      ],
    );
  }

  Widget _buildFuelDailyTrendChart(List dailyTrend) {
    if (dailyTrend.isEmpty) return const Center(child: Text('No fuel trend data for this period.', style: TextStyle(color: textMuted)));
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
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1)),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, m) => _axisLabelText('₹${v.toInt()}'))),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (v, m) => _axisLabel(v, labels))),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: primaryYellow,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [primaryYellow.withOpacity(0.2), primaryYellow.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusWiseFuelChart(List busWise) {
    if (busWise.isEmpty) return const Center(child: Text('No fuel activity for this period.', style: TextStyle(color: textMuted)));

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
          BarChartRodData(toY: amount, color: primaryGreen, width: 8, borderRadius: BorderRadius.circular(2)),
          BarChartRodData(toY: quantity, color: primaryBlue, width: 8, borderRadius: BorderRadius.circular(2)),
          BarChartRodData(toY: fillUps, color: primaryYellow, width: 8, borderRadius: BorderRadius.circular(2)),
        ],
        barsSpace: 4,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 16, children: const [
          _LegendDot(color: primaryGreen, label: 'Amount Spent (₹)'),
          _LegendDot(color: primaryBlue, label: 'Quantity (L)'),
          _LegendDot(color: primaryYellow, label: 'Fill Ups'),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: BarChart(
            BarChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1)),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, m) => _axisLabelText(v.toInt().toString()))),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (v, m) => _axisLabel(v, labels))),
              ),
              borderData: FlBorderData(show: false),
              barGroups: groups,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentModesChart(List paymentModeBreakdown) {
    final colors = [primaryBlue, primaryGreen, primaryYellow, const Color(0xFF8B5CF6), const Color(0xFFEC4899)];
    final sections = <PieChartSectionData>[];
    final legend = <Widget>[];

    for (var i = 0; i < paymentModeBreakdown.length; i++) {
      final p = paymentModeBreakdown[i];
      final amount = (p['amount'] as num?)?.toDouble() ?? 0;
      final mode = p['mode']?.toString() ?? p['paymentMode']?.toString() ?? 'Unknown';
      final color = colors[i % colors.length];
      sections.add(PieChartSectionData(value: amount, color: color, title: '', radius: 32));
      legend.add(_LegendDot(color: color, label: mode));
    }

    return Column(
      children: [
        Expanded(child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 40, sectionsSpace: 3))),
        const SizedBox(height: 8),
        Wrap(spacing: 16, children: legend),
      ],
    );
  }

  Widget _buildMileageChart(List mileageBreakdown) {
    final bars = <BarChartGroupData>[];
    final labels = <String>[];
    for (var i = 0; i < mileageBreakdown.length; i++) {
      final m = mileageBreakdown[i];
      final kmPerLiter = (m['kmPerLiter'] as num?)?.toDouble() ?? 0;
      bars.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: kmPerLiter, color: primaryGreen, width: 20, borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6))),
      ]));
      labels.add(m['registrationNo']?.toString() ?? m['busNumber']?.toString() ?? 'Bus');
    }
    return BarChart(
      BarChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1)),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (v, m) => _axisLabelText(v.toInt().toString()))),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (v, m) => _axisLabel(v, labels))),
        ),
        borderData: FlBorderData(show: false),
        barGroups: bars,
      ),
    );
  }

  Widget _buildTopFuelStationsList(List topFuelStations) {
    return Column(
      children: topFuelStations.map((s) {
        final name = s['stationName']?.toString() ?? s['fuelStation']?.toString() ?? 'Station';
        final fillUps = s['fillUps'] ?? s['totalFillUps'] ?? 0;
        final amount = s['amountSpent'] ?? s['totalAmountSpent'] ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: lightBlueBg, shape: BoxShape.circle),
              child: const Icon(Icons.local_gas_station, size: 18, color: primaryBlue),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: textDark, fontSize: 14)),
            subtitle: Text('$fillUps Fill Ups', style: const TextStyle(color: textMuted, fontSize: 12)),
            trailing: Text('₹$amount', style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 14)),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------
  // Shared UI helpers
  // ---------------------------------------------------------------------

  Widget _sectionTitle(String title) => Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textDark));

  Widget _axisLabelText(String text) => Text(text, style: const TextStyle(fontSize: 10, color: textMuted));

  Widget _axisLabel(double value, List<String> labels) {
    final i = value.toInt();
    if (i < 0 || i >= labels.length) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(top: 4), child: Text(labels[i], style: const TextStyle(fontSize: 10, color: textMuted)));
  }

  String _formatChartDate(dynamic raw) {
    final s = raw?.toString() ?? '';
    try {
      return _chartDateFmt.format(DateTime.parse(s));
    } catch (_) {
      return s;
    }
  }

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
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: s.bgColor, shape: BoxShape.circle),
              child: Icon(s.icon, size: 18, color: s.color),
            ),
            const SizedBox(height: 12),
            Text(
              s.label.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.3),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(s.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textDark)),
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
  final Color bgColor;
  _StatCardData(this.label, this.value, this.icon, this.color, this.bgColor);
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
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: _TransportationAnalyticsScreenState.textMuted)),
      ],
    );
  }
}
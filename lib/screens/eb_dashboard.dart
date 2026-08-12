import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/eb_controller.dart';
import 'package:school_app/controllers/school_controller.dart';

/// Mobile "Electricity Dashboard" screen transformed to match application theme.
class EBDashboardScreen extends StatefulWidget {
  const EBDashboardScreen({super.key});

  @override
  State<EBDashboardScreen> createState() => _EBDashboardScreenState();
}

class _EBDashboardScreenState extends State<EBDashboardScreen> {
  final EBController ebController = Get.find();
  final AuthController _authController = Get.find<AuthController>();
  bool _loadingInFlight = false;
  SchoolController? get _school =>
      Get.isRegistered<SchoolController>() ? Get.find<SchoolController>() : null;

  String get role => _authController.user.value?.role?.toLowerCase() ?? '';

  String get schoolId {
    if (role == 'correspondent') {
      return _school?.selectedSchool.value?.id ?? '';
    }
    return _authController.user.value?.schoolId ?? '';
  }

  // Theme Constants
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color lightBlueBg = Color(0xFFEFF6FF);
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color lightGreenBg = Color(0xFFD1FAE5);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);

  // ---------------- Premises Charge Analytics ----------------
  String _chargeView = 'monthly'; // monthly | yearly
  int _chargeYear = DateTime.now().year;
  int _chargeFromYear = DateTime.now().year - 2;
  int _chargeToYear = DateTime.now().year;
  String? _selectedChargePremisesId;

  static const List<Color> _palette = [
    Color(0xFF2563EB), // Primary Blue
    Color(0xFF10B981), // Emerald Green
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEF4444), // Red
    Color(0xFF06B6D4), // Cyan
  ];

  String _period = 'month'; // today | week | month | year
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    if (schoolId.isEmpty || _loadingInFlight) return;
    _loadingInFlight = true;
    setState(() => _loading = true);
    await Future.wait([
      ebController.getDashboardAnalytics(schoolId),
      ebController.getBillKpi(schoolId),
      ebController.getPremisesAnalytics(schoolId),
      ebController.getConsumptionLineChart(schoolId: schoolId, period: _period),
    ], eagerError: false);

    final premises = ebController.premisesAnalytics;
    if (_selectedChargePremisesId == null && premises.isNotEmpty) {
      _selectedChargePremisesId = (premises.first['premisesId'] ?? premises.first['_id'])?.toString();
    }
    if (_selectedChargePremisesId != null) {
      await _loadChargeAnalytics();
    }

    _loadingInFlight = false;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _changePeriod(String period) async {
    setState(() => _period = period);
    await ebController.getConsumptionLineChart(schoolId: schoolId, period: _period);
  }

  Map<String, List<_ChartPoint>> _parseSeries(Map<String, dynamic>? raw) {
    final result = <String, List<_ChartPoint>>{};
    if (raw == null) return result;
    final premisesList = raw['premises'];
    if (premisesList is! List) return result;

    for (final p in premisesList) {
      if (p is! Map) continue;
      final name = (p['premisesName'] ?? p['name'] ?? 'Premises').toString();
      final points = p['data'] ?? p['points'] ?? p['series'] ?? p['values'] ?? [];
      if (points is! List) continue;

      final series = <_ChartPoint>[];
      for (final pt in points) {
        if (pt is! Map) continue;
        final label = (pt['date'] ?? pt['label'] ?? pt['x'] ?? '').toString();
        final value = pt['value'] ?? pt['consumption'] ?? pt['kwUsed'] ?? pt['y'] ?? 0;
        series.add(_ChartPoint(label, (value is num) ? value.toDouble() : 0));
      }
      if (series.isNotEmpty) result[name] = series;
    }
    return result;
  }

  List<_ChartPoint> _parseChargeSeries(Map<String, dynamic>? raw) {
    if (raw == null) return [];
    final points = raw['data'] ?? raw['breakdown'] ?? raw['charges'] ?? raw['points'] ?? [];
    if (points is! List) return [];

    return points.map((pt) {
      if (pt is! Map) return _ChartPoint('', 0);
      final label = (pt['month'] ?? pt['year'] ?? pt['label'] ?? pt['period'] ?? '').toString();
      final value = pt['charge'] ?? pt['amount'] ?? pt['cost'] ?? pt['value'] ?? 0;
      return _ChartPoint(label, (value is num) ? value.toDouble() : 0);
    }).toList();
  }

  List<_DonutSlice> _donutSlices() {
    final analytics = ebController.premisesAnalytics;
    final slices = <_DonutSlice>[];
    for (var i = 0; i < analytics.length; i++) {
      final a = analytics[i];
      final total = a['totalConsumption'];
      final value = (total is num) ? total.toDouble() : 0.0;
      if (value <= 0) continue;
      slices.add(_DonutSlice(
        label: (a['premisesName'] ?? 'Premises').toString(),
        value: value,
        color: _palette[i % _palette.length],
      ));
    }
    return slices;
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Electricity Dashboard',
              style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Monitor campus-wide power consumption and trends',
              style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          if (_loading && ebController.dashboardAnalytics.value == null) {
            return const Center(child: CircularProgressIndicator(color: primaryBlue));
          }
          final dashboard = ebController.dashboardAnalytics.value ?? {};
          final billKpi = ebController.billKpi.value ?? {};
          final series = _parseSeries(ebController.consumptionLineChart.value);
          final donutSlices = _donutSlices();
          final recentLogs = (dashboard['recentLogs'] as List?)?.cast<Map>() ?? [];
          final premisesAnalytics = ebController.premisesAnalytics;

          return RefreshIndicator(
            color: primaryBlue,
            onRefresh: _loadAll,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ---------------- KPI cards ----------------
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.2,
                  children: [
                    _KpiCard(
                      icon: Icons.bolt,
                      label: 'YDAY USAGE',
                      value: '${dashboard['totalConsumptionYesterday'] ?? 0} kWh',
                      caption: 'All reported premises',
                    ),
                    _KpiCard(
                      icon: Icons.apartment,
                      label: 'REPORTED',
                      value: '${dashboard['premisesReportedYesterday'] ?? 0}/${dashboard['totalPremises'] ?? 0}',
                      caption: 'Premises logged yday',
                    ),
                    _KpiCard(
                      icon: Icons.assignment_outlined,
                      label: 'RECENT LOGS',
                      value: '${recentLogs.length} logs',
                      caption: 'Latest recorded entries',
                    ),
                    _KpiCard(
                      icon: Icons.description_outlined,
                      label: 'PROJ. BILL (MO)',
                      value: '₹${billKpi['monthlyProjectedBill'] ?? 'N/A'}',
                      caption: 'Est. total this month',
                    ),
                    _KpiCard(
                      icon: Icons.calendar_today_outlined,
                      label: 'DAILY COST (EST)',
                      value: '₹${billKpi['estimatedDailyEBCost'] ?? 'N/A'}',
                      caption: 'MTD average cost',
                    ),
                    _KpiCard(
                      icon: Icons.speed_outlined,
                      label: 'PROJ. UNITS (MO)',
                      value: '${billKpi['projectedUnitsThisMonth'] ?? 'N/A'} kWh',
                      caption: 'Est. month-end usage',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ---------------- Consumption Over Time ----------------
                _SectionCard(
                  icon: Icons.show_chart,
                  title: 'Consumption Over Time',
                  trailing: _PeriodTabs(selected: _period, onChanged: _changePeriod),
                  child: series.isEmpty
                      ? _EmptyChartPlaceholder()
                      : _MultiLineChart(series: series, palette: _palette, unit: 'kWh'),
                ),
                const SizedBox(height: 14),

                // ---------------- Total Consumption Share ----------------
                _SectionCard(
                  icon: Icons.pie_chart_outline,
                  title: 'Total Consumption Share',
                  child: donutSlices.isEmpty
                      ? _EmptyChartPlaceholder()
                      : _DonutChartWithLegend(slices: donutSlices, unit: 'kWh'),
                ),
                const SizedBox(height: 14),

                // ---------------- Estimated Billing Cost Over Time ----------------
                _SectionCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'Estimated Billing Cost Over Time',
                  subtitle: 'Approximate — derived from consumption trend and daily cost KPI',
                  child: series.isEmpty
                      ? _EmptyChartPlaceholder()
                      : _MultiLineChart(
                    series: _estimateCostSeries(series, billKpi),
                    palette: _palette,
                    unit: '₹',
                  ),
                ),
                const SizedBox(height: 14),

                // ---------------- Recent Log Entries ----------------
                _SectionCard(
                  icon: Icons.history,
                  title: 'Recent Log Entries',
                  child: recentLogs.isEmpty
                      ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('No recent logs available', style: TextStyle(color: textMuted, fontSize: 12)),
                  )
                      : Column(
                    children: recentLogs
                        .map((log) => _RecentLogRow(log: Map<String, dynamic>.from(log)))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // ---------------- Premises Consumption Analytics ----------------
                const Text(
                  'Premises Consumption Analytics',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
                ),
                const SizedBox(height: 10),
                if (premisesAnalytics.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('No premises analytics available', style: TextStyle(color: textMuted, fontSize: 12)),
                  )
                else
                  ...premisesAnalytics.asMap().entries.map((entry) {
                    final i = entry.key;
                    final a = Map<String, dynamic>.from(entry.value);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PremisesAnalyticsCard(data: a, color: _palette[i % _palette.length]),
                    );
                  }),
                const SizedBox(height: 14),

                // ---------------- Premises Charge Analytics ----------------
                _SectionCard(
                  icon: Icons.currency_rupee,
                  title: 'Premises Charge Analytics',
                  subtitle: 'Monthly or yearly cost breakdown per premises',
                  trailing: _ChargeViewTabs(selected: _chargeView, onChanged: _changeChargeView),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (premisesAnalytics.isNotEmpty)
                        _PremisesDropdown(
                          premises: premisesAnalytics,
                          selectedId: _selectedChargePremisesId,
                          onChanged: _changeChargePremises,
                        ),
                      const SizedBox(height: 12),
                      Builder(builder: (context) {
                        final chargeData = _parseChargeSeries(ebController.premisesCharge.value);
                        if (chargeData.isEmpty) return _EmptyChartPlaceholder();
                        return _ChargeBarChart(points: chargeData);
                      }),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Map<String, List<_ChartPoint>> _estimateCostSeries(
      Map<String, List<_ChartPoint>> consumption, Map<String, dynamic> billKpi) {
    final dailyCost = (billKpi['estimatedDailyEBCost'] is num) ? (billKpi['estimatedDailyEBCost'] as num).toDouble() : null;
    if (dailyCost == null) return consumption;

    final allValues = consumption.values.expand((s) => s.map((p) => p.value)).where((v) => v > 0);
    if (allValues.isEmpty) return consumption;
    final avg = allValues.reduce((a, b) => a + b) / allValues.length;
    if (avg <= 0) return consumption;
    final ratio = dailyCost / avg;

    return consumption.map((name, points) => MapEntry(
      name,
      points.map((p) => _ChartPoint(p.label, p.value * ratio)).toList(),
    ));
  }

  Future<void> _loadChargeAnalytics() async {
    if (schoolId.isEmpty || _selectedChargePremisesId == null) return;
    await ebController.getPremisesChargeAnalytics(
      schoolId: schoolId,
      premisesId: _selectedChargePremisesId!,
      view: _chargeView,
      year: _chargeView == 'monthly' ? _chargeYear : null,
      fromYear: _chargeView == 'yearly' ? _chargeFromYear : null,
      toYear: _chargeView == 'yearly' ? _chargeToYear : null,
    );
  }

  Future<void> _changeChargeView(String view) async {
    setState(() => _chargeView = view);
    await _loadChargeAnalytics();
  }

  Future<void> _changeChargePremises(String? premisesId) async {
    if (premisesId == null) return;
    setState(() => _selectedChargePremisesId = premisesId);
    await _loadChargeAnalytics();
  }
}

// ============================================================================
// Supporting UI Components
// ============================================================================

class _ChargeViewTabs extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _ChargeViewTabs({required this.selected, required this.onChanged});

  static const _options = ['monthly', 'yearly'];
  static const _labels = {'monthly': 'Monthly', 'yearly': 'Yearly'};

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _options.map((opt) {
        final active = opt == selected;
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: InkWell(
            onTap: () => onChanged(opt),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: active ? _EBDashboardScreenState.primaryBlue : _EBDashboardScreenState.lightBlueBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _labels[opt] ?? opt,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : _EBDashboardScreenState.primaryBlue,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PremisesDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> premises;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _PremisesDropdown({required this.premises, required this.selectedId, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _EBDashboardScreenState.cardBg,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedId,
          hint: const Text('Select premises', style: TextStyle(fontSize: 13, color: _EBDashboardScreenState.textMuted)),
          items: premises.map((p) {
            final id = (p['premisesId'] ?? p['_id'] ?? '').toString();
            final name = (p['premisesName'] ?? 'Premises').toString();
            return DropdownMenuItem(value: id, child: Text(name, style: const TextStyle(fontSize: 13, color: _EBDashboardScreenState.textDark)));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ChargeBarChart extends StatelessWidget {
  final List<_ChartPoint> points;
  const _ChargeBarChart({required this.points});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: CustomPaint(painter: _BarChartPainter(points: points)),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<_ChartPoint> points;
  _BarChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const bottomPad = 18.0;
    final chartHeight = size.height - bottomPad;
    final maxV = points.map((p) => p.value).fold<double>(0, max);
    final barWidth = size.width / (points.length * 1.6);
    final gap = barWidth * 0.6;

    final barPaint = Paint()..color = _EBDashboardScreenState.primaryBlue;

    for (var i = 0; i < points.length; i++) {
      final x = i * (barWidth + gap);
      final h = maxV <= 0 ? 0.0 : (points[i].value / maxV) * chartHeight;
      final rect = Rect.fromLTWH(x, chartHeight - h, barWidth, h);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), barPaint);

      final labelText = points[i].label.length > 6 ? points[i].label.substring(0, 6) : points[i].label;
      final painter = TextPainter(
        text: TextSpan(text: labelText, style: const TextStyle(fontSize: 9, color: _EBDashboardScreenState.textMuted)),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: barWidth + gap);
      painter.paint(canvas, Offset(x, chartHeight + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) => true;
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String caption;

  const _KpiCard({required this.icon, required this.label, required this.value, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _EBDashboardScreenState.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _EBDashboardScreenState.textMuted, letterSpacing: 0.3),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: _EBDashboardScreenState.lightBlueBg, shape: BoxShape.circle),
                child: Icon(icon, size: 14, color: _EBDashboardScreenState.primaryBlue),
              ),
            ],
          ),
         SizedBox(height: 4,),
         // const Spacer(),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _EBDashboardScreenState.textDark)),
          const SizedBox(height: 2),
          Text(caption, style: const TextStyle(fontSize: 10, color: _EBDashboardScreenState.textMuted)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _EBDashboardScreenState.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _EBDashboardScreenState.primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _EBDashboardScreenState.textDark),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: const TextStyle(fontSize: 11, color: _EBDashboardScreenState.textMuted)),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PeriodTabs({required this.selected, required this.onChanged});

  static const _options = ['today', 'week', 'month', 'year'];
  static const _labels = {'today': 'Day', 'week': 'Wk', 'month': 'Mo', 'year': 'Yr'};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _options.map((opt) {
          final active = opt == selected;
          return Padding(
            padding: const EdgeInsets.only(left: 4),
            child: InkWell(
              onTap: () => onChanged(opt),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? _EBDashboardScreenState.primaryBlue : _EBDashboardScreenState.lightBlueBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _labels[opt] ?? opt,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : _EBDashboardScreenState.primaryBlue,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyChartPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      alignment: Alignment.center,
      child: const Text('No data for this period', style: TextStyle(color: _EBDashboardScreenState.textMuted, fontSize: 12)),
    );
  }
}

class _ChartPoint {
  final String label;
  final double value;
  _ChartPoint(this.label, this.value);
}

class _MultiLineChart extends StatelessWidget {
  final Map<String, List<_ChartPoint>> series;
  final List<Color> palette;
  final String unit;

  const _MultiLineChart({required this.series, required this.palette, required this.unit});

  @override
  Widget build(BuildContext context) {
    final names = series.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: names.asMap().entries.map((e) {
            final color = palette[e.key % palette.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(e.value, style: const TextStyle(fontSize: 11, color: _EBDashboardScreenState.textDark)),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          width: double.infinity,
          child: CustomPaint(
            painter: _LineChartPainter(series: series, palette: palette),
          ),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final Map<String, List<_ChartPoint>> series;
  final List<Color> palette;

  _LineChartPainter({required this.series, required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 6.0;
    const bottomPad = 18.0;
    final chartWidth = size.width - leftPad;
    final chartHeight = size.height - bottomPad;

    final allValues = series.values.expand((s) => s.map((p) => p.value)).toList();
    if (allValues.isEmpty) return;
    double maxV = allValues.reduce(max);
    double minV = allValues.reduce(min);
    if (maxV == minV) {
      maxV += 1;
      minV = min(minV, 0);
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = chartHeight * i / 3;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
    }

    var colorIndex = 0;
    for (final entry in series.entries) {
      final points = entry.value;
      if (points.isEmpty) continue;
      final color = palette[colorIndex % palette.length];
      colorIndex++;

      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final dotPaint = Paint()..color = color;

      final path = Path();
      for (var i = 0; i < points.length; i++) {
        final x = points.length == 1 ? leftPad : leftPad + chartWidth * i / (points.length - 1);
        final normalized = (points[i].value - minV) / (maxV - minV);
        final y = chartHeight - (normalized * chartHeight);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
      }
      canvas.drawPath(path, linePaint);
    }

    final longest = series.values.reduce((a, b) => a.length >= b.length ? a : b);
    if (longest.isNotEmpty) {
      _drawLabel(canvas, longest.first.label, Offset(leftPad, chartHeight + 4));
      if (longest.length > 1) {
        _drawLabel(canvas, longest.last.label, Offset(size.width - 40, chartHeight + 4));
      }
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset offset) {
    final short = text.length > 8 ? text.substring(text.length - 8) : text;
    final painter = TextPainter(
      text: TextSpan(text: short, style: const TextStyle(fontSize: 9, color: _EBDashboardScreenState.textMuted)),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => true;
}

class _DonutSlice {
  final String label;
  final double value;
  final Color color;
  _DonutSlice({required this.label, required this.value, required this.color});
}

class _DonutChartWithLegend extends StatelessWidget {
  final List<_DonutSlice> slices;
  final String unit;

  const _DonutChartWithLegend({required this.slices, required this.unit});

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(size: const Size(110, 110), painter: _DonutPainter(slices: slices)),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    total.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _EBDashboardScreenState.textDark),
                  ),
                  Text(unit, style: const TextStyle(fontSize: 10, color: _EBDashboardScreenState.textMuted)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: slices
                .map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      s.label,
                      style: const TextStyle(fontSize: 12, color: _EBDashboardScreenState.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSlice> slices;
  _DonutPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const strokeWidth = 14.0;
    var startAngle = -pi / 2;

    for (final slice in slices) {
      final sweep = (slice.value / total) * 2 * pi;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect.deflate(strokeWidth / 2), startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}

class _RecentLogRow extends StatelessWidget {
  final Map<String, dynamic> log;
  const _RecentLogRow({required this.log});

  String _formatDate(dynamic raw) {
    if (raw == null) return 'N/A';
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final logNo = (log['ebLogNo'] ?? 'N/A').toString();
    final premisesRaw = log['premisesId'];
    final premisesName = premisesRaw is Map ? (premisesRaw['premisesName'] ?? 'N/A').toString() : 'N/A';
    final time = (log['time'] ?? '').toString();
    final reading = log['meterReading'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _EBDashboardScreenState.lightBlueBg, borderRadius: BorderRadius.circular(6)),
            child: Text(
              logNo,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _EBDashboardScreenState.primaryBlue),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(premisesName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _EBDashboardScreenState.textDark)),
                Text(
                  '${_formatDate(log['date'])}${time.isNotEmpty ? ' · $time' : ''}',
                  style: const TextStyle(fontSize: 10, color: _EBDashboardScreenState.textMuted),
                ),
              ],
            ),
          ),
          Text(
            reading == null ? 'N/A' : '$reading kWh',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _EBDashboardScreenState.textDark),
          ),
        ],
      ),
    );
  }
}

class _PremisesAnalyticsCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color color;

  const _PremisesAnalyticsCard({required this.data, required this.color});

  String _fmt(dynamic v, {String suffix = ''}) {
    if (v == null) return 'N/A';
    return '$v$suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _EBDashboardScreenState.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border(top: BorderSide(color: color, width: 3)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  (data['premisesName'] ?? 'Premises').toString(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _EBDashboardScreenState.textDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'ENERGY ANALYTICS',
            style: TextStyle(fontSize: 9, color: _EBDashboardScreenState.textMuted, letterSpacing: 0.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _MiniStat(label: 'YESTERDAY', value: _fmt(data['yesterdayConsumption'], suffix: ' kWh'))),
              Expanded(child: _MiniStat(label: '30-DAY AVG', value: _fmt(data['avg30DayConsumption'], suffix: ' kWh/d'))),
            ],
          ),
          const SizedBox(height: 8),
          _MiniStat(label: 'PROJ. MONTH', value: _fmt(data['projectedThisMonthConsumption'], suffix: ' kWh')),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: _EBDashboardScreenState.textMuted, letterSpacing: 0.3, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _EBDashboardScreenState.textDark),
        ),
      ],
    );
  }
}
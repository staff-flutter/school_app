import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/attendance_controller.dart';
import 'package:school_app/models/school_models.dart';
import 'package:school_app/core/utils/academic_year_utils.dart';

// ─── Design System (using the app's standard management palette) ──
class _DS {
  static const primary = Color(0xFF10B981);
  static const primaryDark = Color(0xFF0284C7);
  static const primarySoft = Color(0xFFE0F2FE);

  static const bg = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF1F5F9);

  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF94A3B8);

  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);

  static const border = Color(0xFFE2E8F0);
  static const shadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const radius = 16.0;
  static const radiusSm = 10.0;
  static const radiusXl = 32.0;

  static const spacingSm = 8.0;
  static const spacingMd = 12.0;
  static const spacingLg = 16.0;
  static const spacingXl = 24.0;
  static const spacingXxl = 32.0;

  static double get tablet => 900;
}

class _Responsive {
  static double padding(BuildContext context) =>
      MediaQuery.of(context).size.width < _DS.tablet ? _DS.spacingLg : _DS.spacingXl;

  static double fontSize(BuildContext context, {double mobile = 14, double tablet = 16}) =>
      MediaQuery.of(context).size.width < _DS.tablet ? mobile : tablet;

  static EdgeInsets pagePadding(BuildContext context) =>
      EdgeInsets.symmetric(horizontal: padding(context), vertical: _DS.spacingLg);
}

// ─── Local History Data Model ───
class _HistoryEntry {
  final String date;
  final int present;
  final int absent;
  final int total;

  _HistoryEntry({required this.date, required this.present, required this.absent, required this.total});

  factory _HistoryEntry.fromJson(Map<String, dynamic> json) {
    final records = (json['records'] as List?) ?? [];
    int present = json['presentCount'] ?? 0;
    int absent = json['absentCount'] ?? 0;
    if (records.isNotEmpty && json['presentCount'] == null) {
      present = records.where((r) => (r['status'] ?? '') == 'present').length;
      absent = records.where((r) => (r['status'] ?? '') == 'absent').length;
    }
    return _HistoryEntry(
      date: (json['date'] ?? '').toString(),
      present: present,
      absent: absent,
      total: (json['total'] ?? records.length) is int ? (json['total'] ?? records.length) : records.length,
    );
  }
}

// ─── Filter Selection Sheet Component ───
class _SelectorSheet extends StatefulWidget {
  final List<SchoolClass> classes;
  final List<Section> sections;
  final List<String> years;
  final SchoolClass? initialClass;
  final Section? initialSection;
  final String initialYear;
  final Future<void> Function(SchoolClass cls) onClassChanged;

  const _SelectorSheet({
    required this.classes,
    required this.sections,
    required this.years,
    required this.initialClass,
    required this.initialSection,
    required this.initialYear,
    required this.onClassChanged,
  });

  @override
  State<_SelectorSheet> createState() => _SelectorSheetState();
}

class _SelectorSheetState extends State<_SelectorSheet> {
  SchoolClass? _selectedClass;
  Section? _selectedSection;
  late String _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedClass = widget.initialClass;
    _selectedSection = widget.initialSection;
    _selectedYear = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(_DS.radiusXl)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: _DS.border, borderRadius: BorderRadius.circular(100)),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _Responsive.padding(context)),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: _DS.primarySoft, borderRadius: BorderRadius.circular(_DS.radiusSm)),
                    child: const Icon(Icons.analytics_rounded, color: _DS.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Filter History Metrics',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _DS.textPrimary)),
                        Text(
                          _selectedClass != null
                              ? (_selectedSection != null
                              ? '${_selectedClass!.name} · ${_selectedSection!.name} · $_selectedYear'
                              : '${_selectedClass!.name} · $_selectedYear')
                              : 'No class selected',
                          style: TextStyle(
                            fontSize: 12,
                            color: _selectedClass != null ? _DS.primary : _DS.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: _DS.surfaceAlt, borderRadius: BorderRadius.circular(100)),
                      child: const Icon(Icons.close_rounded, size: 16, color: _DS.textMuted),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(context, 'CLASS'),
                    const SizedBox(height: 10),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: _Responsive.padding(context)),
                      child: widget.classes.isEmpty
                          ? const Text('No classes available', style: TextStyle(fontSize: 13, color: _DS.textMuted))
                          : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.classes.map((cls) {
                          final isSelected = _selectedClass?.id == cls.id;
                          return GestureDetector(
                            onTap: () async {
                              setState(() {
                                _selectedClass = cls;
                                _selectedSection = null;
                              });
                              await widget.onClassChanged(cls);
                            },
                            child: _chip(cls.name, isSelected),
                          );
                        }).toList(),
                      ),
                    ),
                    if (_selectedClass != null) ...[
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: _DS.border),
                      const SizedBox(height: 16),
                      _label(context, 'SECTION'),
                      const SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: _Responsive.padding(context)),
                        child: widget.sections.isEmpty
                            ? Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: _DS.textMuted, size: 15),
                            const SizedBox(width: 8),
                            const Text('No sections available for this class',
                                style: TextStyle(fontSize: 12, color: _DS.textMuted)),
                          ],
                        )
                            : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _selectedSection = null),
                              child: _squareChip('All', _selectedSection == null),
                            ),
                            ...widget.sections.map((sec) {
                              final isSelected = _selectedSection?.id == sec.id;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedSection = sec),
                                child: _squareChip(sec.name, isSelected),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: _DS.border),
                    const SizedBox(height: 16),
                    _label(context, 'ACADEMIC YEAR'),
                    const SizedBox(height: 10),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: _Responsive.padding(context)),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.years.map((y) {
                          final isSelected = _selectedYear == y;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedYear = y),
                            child: _chip(y, isSelected),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: _DS.border),
            Padding(
              padding: EdgeInsets.fromLTRB(
                _Responsive.padding(context),
                16,
                _Responsive.padding(context),
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: ElevatedButton(
                onPressed: _selectedClass == null
                    ? null
                    : () => Navigator.of(context).pop((_selectedClass, _selectedSection, _selectedYear)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedClass != null ? _DS.primary : _DS.surfaceAlt,
                  foregroundColor: _selectedClass != null ? Colors.white : _DS.textMuted,
                  disabledBackgroundColor: _DS.surfaceAlt,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radius)),
                ),
                child: Text(_selectedClass == null ? 'Select a class' : 'Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _Responsive.padding(context)),
      child: Text(text,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _DS.textMuted, letterSpacing: 1.2)),
    );
  }

  Widget _chip(String label, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isSelected ? _DS.primary : _DS.surfaceAlt,
        borderRadius: BorderRadius.circular(_DS.radiusSm),
        border: Border.all(color: isSelected ? _DS.primary : _DS.border, width: isSelected ? 1.5 : 1),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : _DS.textPrimary)),
    );
  }

  Widget _squareChip(String label, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? _DS.primary : _DS.surfaceAlt,
        borderRadius: BorderRadius.circular(_DS.radiusSm),
        border: Border.all(color: isSelected ? _DS.primary : _DS.border, width: isSelected ? 1.5 : 1),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : _DS.textPrimary)),
    );
  }
}

// ─── MAIN DASHBOARD CONTENT PAGE ───
class AttendanceHistoryDashboardPage extends StatefulWidget {
  const AttendanceHistoryDashboardPage({super.key});

  @override
  State<AttendanceHistoryDashboardPage> createState() => _AttendanceHistoryDashboardPageState();
}

class _AttendanceHistoryDashboardPageState extends State<AttendanceHistoryDashboardPage> {
  final schoolController = Get.find<SchoolController>();
  final authController = Get.find<AuthController>();
  final attendanceController = Get.put(AttendanceController());

  SchoolClass? _selectedClass;
  Section? _selectedSection;
  String _selectedYear = AcademicYearUtils.getCurrentAcademicYear();

  static final _years = AcademicYearUtils.getRecentAcademicYears(3);

  List<_HistoryEntry> _history = [];
  bool _loadingHistory = false;
  int _historyPage = 1;
  bool _hasMoreHistory = true;

  int _totalPresents = 0;
  int _totalAbsents = 0;

  String get currentUserRole => authController.user.value?.role?.toLowerCase() ?? '';

  String get _schoolId {
    if (currentUserRole == 'correspondent') {
      return schoolController.selectedSchool.value?.id ?? authController.user.value?.schoolId ?? '';
    }
    return authController.user.value?.schoolId ?? '';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final schoolId = _schoolId;
      if (schoolId.isNotEmpty) {
        schoolController.getAllClasses(schoolId);
      }
    });
  }

  Future<void> _openSelectorSheet() async {
    final schoolId = _schoolId;
    if (schoolId.isEmpty) {
      Get.snackbar('Error', 'No school context found for your account',
          backgroundColor: _DS.danger, colorText: Colors.white);
      return;
    }

    if (schoolController.classes.isEmpty && !schoolController.isLoading.value) {
      schoolController.getAllClasses(schoolId);
    }

    final result = await showModalBottomSheet<(SchoolClass?, Section?, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, __) => Obx(
              () {
            // ─── THE CRITICAL FIX ───
            // We explicitly read the reactive observables (.value) here.
            // This tells GetX exactly what to listen to, preventing the crash!
            final activeClasses = schoolController.classes.toList();
            final activeSections = schoolController.sections.toList();
            final dummyListen = schoolController.isLoading.value;

            return _SelectorSheet(
              classes: activeClasses,
              sections: activeSections,
              years: _years,
              initialClass: _selectedClass,
              initialSection: _selectedSection,
              initialYear: _selectedYear,
              onClassChanged: (cls) async {
                await schoolController.getAllSections(classId: cls.id, schoolId: schoolId);
              },
            );
          },
        ),
      ),
    );

    if (result != null) {
      final (newClass, newSection, newYear) = result;
      setState(() {
        _selectedClass = newClass;
        _selectedSection = newSection;
        _selectedYear = newYear;
      });
      if (newClass != null) {
        _loadHistory(reset: true);
      }
    }
  }
  Future<void> _loadHistory({bool reset = false}) async {
    if (_selectedClass == null) return;
    if (reset) {
      _historyPage = 1;
      _hasMoreHistory = true;
      _history = [];
    }
    if (!_hasMoreHistory) return;

    setState(() => _loadingHistory = true);
    try {
      final result = await attendanceController.getAttendanceHistory(
        schoolId: _schoolId,
        classId: _selectedClass!.id,
        sectionId: _selectedSection?.id,
        academicYear: _selectedYear,
        page: _historyPage,
      );

      final entries = (result ?? []).map(_HistoryEntry.fromJson).toList();
      if (!mounted) return;
      setState(() {
        if (reset) {
          _history = entries;
        } else {
          _history.addAll(entries);
        }
        _hasMoreHistory = entries.isNotEmpty;
        if (entries.isNotEmpty) _historyPage++;

        // Calculate dynamic dashboard aggregates
        _totalPresents = _history.fold(0, (sum, item) => sum + item.present);
        _totalAbsents = _history.fold(0, (sum, item) => sum + item.absent);
      });
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleString = [_selectedClass?.name, _selectedSection?.name]
        .where((s) => s != null && s.isNotEmpty)
        .join(' - ');

    return Scaffold(
      backgroundColor: _DS.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _DS.textPrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Attendance Analysis Log',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _DS.textPrimary)),
            if (titleString.isNotEmpty)
              Text('$titleString (AY: $_selectedYear)', style: const TextStyle(fontSize: 11, color: _DS.textMuted)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openSelectorSheet,
            icon: const Icon(Icons.filter_list_rounded, color: Color(0xFF2563EB)),
          ),
          if (_selectedClass != null)
            IconButton(
              onPressed: () => _loadHistory(reset: true),
              icon: const Icon(Icons.refresh_rounded, color: _DS.textSecondary),
            )
        ],
      ),
      body: _selectedClass == null
          ? _buildStatePrompt(
        icon: Icons.class_rounded,
        title: 'No Selection Made',
        subtitle: 'Tap the button below or filter icon above to select a class matrix history log.',
        action: ElevatedButton.icon(
          onPressed: _openSelectorSheet,
          icon: const Icon(Icons.search_rounded),
          label: const Text('Choose Class Context'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _DS.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusSm)),
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: () => _loadHistory(reset: true),
        color: _DS.primary,
        child: ListView(
          padding: _Responsive.pagePadding(context),
          children: [
            // Realtime Counter Metric Cards
            Row(
              children: [
                Expanded(
                    child: _buildMetricCard('Total Presents', '$_totalPresents', _DS.primary, Icons.trending_up_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildMetricCard('Total Absents', '$_totalAbsents', _DS.danger, Icons.trending_down_rounded)),
              ],
            ),
            const SizedBox(height: 16),

            // Flow Distribution Bar Graph Matrix
            _buildFlowChartWidget(),
            const SizedBox(height: 24),

            const Text('Timeline History Logs',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _DS.textPrimary)),
            const SizedBox(height: 12),

            if (_history.isEmpty && _loadingHistory)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
              )
            else if (_history.isEmpty)
              _buildStatePrompt(
                icon: Icons.history_toggle_off_rounded,
                title: 'Logs Empty',
                subtitle: 'No attendance history profiles submitted for this class criteria.',
              )
            else ...[
                ..._history.map(_buildHistoryRowItem),
                if (_hasMoreHistory) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: _loadingHistory ? null : () => _loadHistory(),
                      icon: _loadingHistory
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.arrow_downward_rounded, size: 16),
                      label: Text(_loadingHistory ? 'Loading Context...' : 'Load Older Records'),
                      style: TextButton.styleFrom(foregroundColor: _DS.primary),
                    ),
                  ),
                ]
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.radius),
        border: Border.all(color: _DS.border),
        boxShadow: _DS.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: _DS.textSecondary, fontWeight: FontWeight.w500)),
              Icon(icon, size: 16, color: color.withOpacity(0.7)),
            ],
          ),
          const SizedBox(height: 8),
          Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildFlowChartWidget() {
    final double highMark = (_totalPresents > _totalAbsents ? _totalPresents : _totalAbsents).toDouble();
    final double presentBarHeight = highMark > 0 ? (_totalPresents / highMark) * 110 : 0.0;
    final double absentBarHeight = highMark > 0 ? (_totalAbsents / highMark) * 110 : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.radius),
        border: Border.all(color: _DS.border),
        boxShadow: _DS.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Attendance Flow Distribution',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _DS.textPrimary)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                children: [
                  Text('$_totalPresents', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _DS.primary)),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 45,
                    height: presentBarHeight.clamp(10.0, 110.0),
                    decoration: BoxDecoration(
                      color: _DS.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Presents', style: TextStyle(fontSize: 11, color: _DS.textSecondary)),
                ],
              ),
              Column(
                children: [
                  Text('$_totalAbsents', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _DS.danger)),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 45,
                    height: absentBarHeight.clamp(10.0, 110.0),
                    decoration: BoxDecoration(
                      color: _DS.danger,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Absents', style: TextStyle(fontSize: 11, color: _DS.textSecondary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryRowItem(_HistoryEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.radiusSm),
        border: Border.all(color: _DS.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.date.contains('T') ? entry.date.split('T').first : entry.date,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _DS.textPrimary)),
                const SizedBox(height: 2),
                Text('Total Roster Strength: ${entry.total}', style: const TextStyle(fontSize: 10, color: _DS.textMuted)),
              ],
            ),
          ),
          _buildLogChip('${entry.present} Present', _DS.primary),
          const SizedBox(width: 6),
          _buildLogChip('${entry.absent} Absent', _DS.danger),
        ],
      ),
    );
  }

  Widget _buildLogChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildStatePrompt({required IconData icon, required String title, required String subtitle, Widget? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_DS.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: _DS.primarySoft, shape: BoxShape.circle),
              child: Icon(icon, size: 28, color: _DS.primary),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _DS.textPrimary)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: _DS.textMuted)),
            if (action != null) ...[const SizedBox(height: 16), action],
          ],
        ),
      ),
    );
  }
}
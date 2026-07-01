// lib/screens/teacher_my_schedule_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/timetable_controller.dart';

class TeacherMySchedule extends StatefulWidget {
  const TeacherMySchedule({super.key});

  @override
  State<TeacherMySchedule> createState() => _TeacherMyScheduleState();
}

class _TeacherMyScheduleState extends State<TeacherMySchedule> {
  final authController = Get.find<AuthController>();
  final schoolController = Get.find<SchoolController>();
  final timetableController = Get.put(TimetableController());

  static const _primary = Color(0xFF2563EB);
  static const _primaryDark = Color(0xFF0284C7);
  static const _primarySoft = Color(0xFFE0F2FE);
  static const _bg = Color(0xFFF8FAFC);
  static const _surface = Color(0xFFFFFFFF);
  static const _surfaceAlt = Color(0xFFF1F5F9);
  static const _border = Color(0xFFE2E8F0);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF94A3B8);
  static const _success = Color(0xFF10B981);
  static const _successSoft = Color(0xFFD1FAE5);
  static const _warning = Color(0xFFF59E0B);
  static const _warningSoft = Color(0xFFFEF3C7);

  static const _dayColors = [
    Color(0xFFEDE9FE), Color(0xFFFCE7F3), Color(0xFFD1FAE5),
    Color(0xFFFEF3C7), Color(0xFFDBEAFE), Color(0xFFFFEDD5),
  ];
  static const _dayTextColors = [
    Color(0xFF6D28D9), Color(0xFFBE185D), Color(0xFF065F46),
    Color(0xFF92400E), Color(0xFF1D4ED8), Color(0xFFC2410C),
  ];

  bool _loading = false;
  String? _error;

  // ── School/teacher ID resolution ──────────────────────────────────────────
  String? get _resolvedSchoolId {
    final role = authController.user.value?.role?.toLowerCase() ?? '';
    if (role == 'correspondent') {
      return schoolController.selectedSchool.value?.id;
    }
    return authController.user.value?.schoolId;
  }

  // ⚠️ Verify this matches the actual field name on your User model.
  String? get _teacherId => authController.user.value?.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSchedule());
  }

  Future<void> _loadSchedule() async {
    final schoolId = _resolvedSchoolId;
    final teacherId = _teacherId;

    if (schoolId == null || teacherId == null) {
      setState(() => _error = 'Unable to resolve your account/school details.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await timetableController.getTeacherSchedule(
        schoolId: schoolId,
        teacherId: teacherId,
      );
    } catch (e) {
      setState(() => _error = 'Failed to load your schedule.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('My Schedule'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSchedule,
          color: _primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            child: _buildBody(context, isTablet),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isTablet) {
    if (_loading) {
      return SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    if (_error != null) {
      return _emptyState(
        icon: Icons.error_outline_rounded,
        title: 'Something went wrong',
        subtitle: _error!,
      );
    }

    return Obx(() {
      if (timetableController.teacherSchedule.isEmpty) {
        return _emptyState(
          icon: Icons.event_busy_rounded,
          title: 'No Schedule Found',
          subtitle: 'You don\'t have any periods assigned yet.',
        );
      }

      final schedule = timetableController.teacherSchedule.first;
      final weeklySchedule = schedule['weeklySchedule'] as List? ?? [];
      final addedDays = weeklySchedule.map((ws) => ws['day'] as String).toList();

      // Count today's periods + total periods this week, for the summary header.
      final todayName = _todayName();
      final todaySchedule = weeklySchedule.firstWhereOrNull((ws) => ws['day'] == todayName);
      int todayCount = 0;
      int weekCount = 0;
      if (todaySchedule != null) {
        final periods = (todaySchedule['periods'] as List? ?? [])
            .where((p) => (p['isYourPeriod'] ?? false) == true && (p['isBreak'] ?? false) != true);
        todayCount = periods.length;
      }
      for (final ws in weeklySchedule) {
        final periods = (ws['periods'] as List? ?? [])
            .where((p) => (p['isYourPeriod'] ?? false) == true && (p['isBreak'] ?? false) != true);
        weekCount += periods.length;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryRow(context, isTablet, todayCount, weekCount),
          const SizedBox(height: 16),
          _buildLegend(),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            padding: const EdgeInsets.all(12),
            child: _buildGrid(context, weeklySchedule, addedDays, isTablet),
          ),
        ],
      );
    });
  }

  Widget _buildSummaryRow(BuildContext context, bool isTablet, int todayCount, int weekCount) {
    return Row(
      children: [
        Expanded(child: _statCard('Today', '$todayCount', Icons.today_rounded, _success, _successSoft)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('This Week', '$weekCount', Icons.calendar_view_week_rounded, _primary, _primarySoft)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: fg, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textPrimary)),
              Text(label, style: const TextStyle(fontSize: 11, color: _textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _legendDot(_successSoft, _success, 'Your period'),
        const SizedBox(width: 14),
        _legendDot(_warningSoft, _warning, 'Break'),
        const SizedBox(width: 14),
        _legendDot(_surfaceAlt, _textMuted, 'Free period'),
      ],
    );
  }

  Widget _legendDot(Color bg, Color fg, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: Border.all(color: fg.withOpacity(0.5))),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: _textMuted, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _emptyState({required IconData icon, required String title, required String subtitle}) {
    return SizedBox(
      height: 320,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(color: _primarySoft, shape: BoxShape.circle),
                child: Icon(icon, size: 32, color: _primary),
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary)),
              const SizedBox(height: 6),
              Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: _textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  String _todayName() {
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[DateTime.now().weekday - 1];
  }

  // ── Grid rendering (teacher-personal version of _TimetableGrid) ───────────
  Widget _buildGrid(BuildContext context, List weeklySchedule, List<String> addedDays, bool isTablet) {
    final cellWidth = isTablet ? 140.0 : 108.0;
    final cellHeight = isTablet ? 72.0 : 62.0;
    final periodColWidth = isTablet ? 80.0 : 68.0;
    const totalPeriods = 8;
    final todayName = _todayName();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: periodColWidth, height: 40, alignment: Alignment.center,
                decoration: BoxDecoration(color: _primarySoft, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
                child: const Text('Period', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: _primaryDark)),
              ),
              const SizedBox(width: 6),
              ...List.generate(addedDays.length, (i) {
                final isToday = addedDays[i] == todayName;
                final dayColor = isToday ? _primary : _dayColors[i % _dayColors.length];
                final dayTextColor = isToday ? Colors.white : _dayTextColors[i % _dayTextColors.length];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    width: cellWidth, height: 40, alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: dayColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isToday ? _primary : dayTextColor.withOpacity(0.25)),
                    ),
                    child: Text(
                      addedDays[i].substring(0, addedDays[i].length > 3 ? 3 : addedDays[i].length).toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: dayTextColor, letterSpacing: 1.0),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 6),
          ...List.generate(totalPeriods, (periodIndex) {
            final periodNumber = periodIndex + 1;
            final isEven = periodIndex.isEven;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: periodColWidth, height: cellHeight, alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isEven ? _primarySoft : _surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isEven ? _primary.withOpacity(0.3) : _border),
                    ),
                    child: Text('P$periodNumber', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _primaryDark)),
                  ),
                  const SizedBox(width: 6),
                  ...List.generate(addedDays.length, (dayIndex) {
                    final day = addedDays[dayIndex];
                    final daySchedule = (weeklySchedule).firstWhereOrNull((ws) => ws['day'] == day);

                    String subject = '-';
                    bool isBreak = false;
                    bool isYourPeriod = false;
                    String startTime = '';
                    String endTime = '';

                    if (daySchedule != null) {
                      final periods = daySchedule['periods'] as List? ?? [];
                      final periodData = periods.firstWhereOrNull((p) => p['periodNumber'] == periodNumber);
                      if (periodData != null) {
                        isBreak = periodData['isBreak'] ?? false;
                        subject = periodData['subjectName'] ?? '-';
                        isYourPeriod = periodData['isYourPeriod'] ?? false;
                        startTime = periodData['startTime']?.toString() ?? '';
                        endTime = periodData['endTime']?.toString() ?? '';
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _scheduleCell(
                        subject: subject,
                        isBreak: isBreak,
                        isYourPeriod: isYourPeriod,
                        startTime: startTime,
                        endTime: endTime,
                        width: cellWidth,
                        height: cellHeight,
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _scheduleCell({
    required String subject,
    required bool isBreak,
    required bool isYourPeriod,
    required String startTime,
    required String endTime,
    required double width,
    required double height,
  }) {
    Color bg;
    Color fg;
    Color border;

    if (isBreak) {
      bg = _warningSoft;
      fg = _warning;
      border = _warning;
    } else if (isYourPeriod) {
      bg = _successSoft;
      fg = _success;
      border = _success;
    } else {
      bg = _surfaceAlt;
      fg = _textMuted;
      border = _border;
    }

    return Container(
      width: width,
      constraints: BoxConstraints(minHeight: height),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: isYourPeriod || isBreak ? 1.5 : 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isYourPeriod) Icon(Icons.person_pin_rounded, size: 12, color: fg.withOpacity(0.8)),
          Text(
            isBreak ? 'Break' : (subject == '-' ? '—' : subject),
            style: TextStyle(
              fontSize: 12,
              fontWeight: isYourPeriod ? FontWeight.w800 : FontWeight.w500,
              color: fg,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          if (isYourPeriod && startTime.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('$startTime–$endTime',
                style: TextStyle(fontSize: 9, color: fg.withOpacity(0.7), fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }
}
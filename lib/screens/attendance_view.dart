import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/parent_attendance_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class AttendanceView extends GetView<ParentAttendanceController> {
  const AttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final isParent = authController.user.value?.role == 'parent';

    return GetBuilder<ParentAttendanceController>(
      builder: (controller) {
        if (isParent && !controller.isSpecificStudentView.value) {
          return _buildParentCalendarView(context);
        }
        if (controller.isSpecificStudentView.value) {
          return Scaffold(body: _buildSpecificStudentAttendanceView(context));
        } else if (controller.isParent) {
          return Scaffold(body: _buildParentDateWiseAttendanceView(context));
        } else {
          return DefaultTabController(
            length: controller.canMark ? 2 : 1,
            child: Scaffold(
              backgroundColor: const Color(0xFFF0F5FF),
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                title: Text(
                  'Attendance ${_getPermissionLabel()}',
                  style: const TextStyle(
                      color: Color(0xFF1A2A3A),
                      fontSize: 15,
                      fontWeight: FontWeight.w700),
                ),
                bottom: TabBar(
                  labelColor: const Color(0xFF2563EB),
                  unselectedLabelColor: const Color(0xFF90A4BE),
                  indicatorColor: const Color(0xFF2563EB),
                  indicatorWeight: 2.5,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: [
                    if (controller.canMark)
                      const Tab(
                          icon: Icon(Icons.how_to_reg_rounded, size: 18),
                          text: 'Mark Daily'),
                    const Tab(
                        icon: Icon(Icons.history_rounded, size: 18),
                        text: 'History'),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  if (controller.canMark) _buildMarkDailyTab(context),
                  _buildHistoryTab(context),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PERMISSION LABEL
  // ─────────────────────────────────────────────────────────────────────────────

  String _getPermissionLabel() {
    switch (controller.permission) {
      case 'viewOnly':
        return '(View Only)';
      case 'markAndView':
        return '(Mark & View)';
      case 'ownChildrenOnly':
        return '(Own Children)';
      default:
        return '';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SPECIFIC STUDENT VIEW (parent calendar)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildSpecificStudentAttendanceView(BuildContext context) {
    final focusedDay = controller.selectedDate.value.obs;
    final selectedDay = Rxn<DateTime>();
    final calendarFormat = CalendarFormat.month.obs;
    final selectedYear = controller.selectedDate.value.year.obs;
    final selectedMonth = controller.selectedDate.value.month.obs;
    final activeTab = 'attendance'.obs;
    final filtersVisible = false.obs;

    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    final holidays = <Map<String, String>>[
      {'name': 'Republic Day', 'date': '26th January', 'day': 'Sunday'},
      {'name': 'Holi', 'date': '14th March', 'day': 'Friday'},
      {'name': 'Good Friday', 'date': '18th April', 'day': 'Friday'},
      {'name': 'Independence Day', 'date': '15th August', 'day': 'Friday'},
      {'name': 'Gandhi Jayanti', 'date': '2nd October', 'day': 'Thursday'},
      {'name': 'Diwali', 'date': '20th October', 'day': 'Monday'},
    ];

    return Scaffold(
      body: Column(
        children: [
          // ── Gradient header ──────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF4A6CF7), Colors.indigo.shade700],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 20),
                        ),
                        Expanded(
                          child: Obx(() => Text(
                                '${controller.studentNameForView.value}\'s Attendance',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              )),
                        ),
                        Obx(() => IconButton(
                              onPressed: () =>
                                  filtersVisible.value = !filtersVisible.value,
                              icon: Icon(
                                filtersVisible.value
                                    ? Icons.tune
                                    : Icons.tune_outlined,
                                color: Colors.white,
                              ),
                              tooltip: 'Filters',
                            )),
                        IconButton(
                          onPressed: controller.loadAttendance,
                          icon: const Icon(Icons.refresh,
                              color: Colors.white, size: 22),
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    child: Obx(() => Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _pillTab('ATTENDANCE', 'attendance', activeTab),
                              _pillTab('HOLIDAY', 'holiday', activeTab),
                            ],
                          ),
                        )),
                  ),
                ],
              ),
            ),
          ),

          // ── Collapsible filters ──────────────────────────────────────────────
          Obx(() => AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: filtersVisible.value
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: _buildCollapsibleFilters(
                    context, selectedYear, selectedMonth, focusedDay),
                secondChild: const SizedBox.shrink(),
              )),

          // ── Body ─────────────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (activeTab.value == 'holiday') {
                return _buildHolidayList(holidays);
              }
              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildCalendarCard(
                      context,
                      focusedDay,
                      selectedDay,
                      calendarFormat,
                      selectedYear,
                      selectedMonth,
                      isTablet,
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRows(context),
                    const SizedBox(height: 16),
                    _buildAnalyticsExpansion(context, isTablet),
                    const SizedBox(height: 16),
                    _buildYearlyAnalyticsExpansion(context, isTablet),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PILL TAB
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _pillTab(String label, String value, RxString activeTab) {
    final isActive = activeTab.value == value;
    return GestureDetector(
      onTap: () => activeTab.value = value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF4A6CF7) : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // COLLAPSIBLE YEAR / MONTH FILTER STRIP
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildCollapsibleFilters(
    BuildContext context,
    RxInt selectedYear,
    RxInt selectedMonth,
    Rx<DateTime> focusedDay,
  ) {
    final now = DateTime.now();
    final years = List.generate(5, (i) => now.year - 4 + i).reversed.toList();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(() => Row(
                  children: years.map((y) {
                    final isActive = selectedYear.value == y;
                    return GestureDetector(
                      onTap: () {
                        selectedYear.value = y;
                        final newDate = DateTime(y, selectedMonth.value, 1);
                        focusedDay.value = newDate;
                        controller.selectedDate.value = newDate;
                        controller.loadAttendance();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF4A6CF7)
                              : const Color(0xFFF0F5FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$y',
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF4A6CF7),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                )),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(() => Row(
                  children: List.generate(12, (i) {
                    final isActive = selectedMonth.value == i + 1;
                    return GestureDetector(
                      onTap: () {
                        selectedMonth.value = i + 1;
                        final newDate =
                            DateTime(selectedYear.value, i + 1, 1);
                        focusedDay.value = newDate;
                        controller.selectedDate.value = newDate;
                        controller.loadAttendance();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF4A6CF7)
                              : const Color(0xFFF0F5FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          months[i],
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF4A6CF7),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }),
                )),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // CALENDAR CARD
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildCalendarCard(
    BuildContext context,
    Rx<DateTime> focusedDay,
    Rxn<DateTime> selectedDay,
    Rx<CalendarFormat> calendarFormat,
    RxInt selectedYear,
    RxInt selectedMonth,
    bool isTablet,
  ) {
    return Obx(() {
      final events = controller.eventsForCalendar;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ],
        ),
        child: TableCalendar<String>(
          firstDay: DateTime(2020, 1, 1),
          lastDay: DateTime(2030, 12, 31),
          focusedDay: focusedDay.value,
          calendarFormat: calendarFormat.value,
          selectedDayPredicate: (day) => isSameDay(selectedDay.value, day),
          onDaySelected: (sel, focused) {
            selectedDay.value = sel;
            focusedDay.value = focused;
          },
          onFormatChanged: (fmt) => calendarFormat.value = fmt,
          onPageChanged: (focused) {
            focusedDay.value = focused;
            selectedYear.value = focused.year;
            selectedMonth.value = focused.month;
            controller.selectedDate.value = focused;
            controller.loadAttendance();
          },
          eventLoader: (day) {
            final key = DateTime(day.year, day.month, day.day);
            return events[key] ?? [];
          },
          headerStyle: const HeaderStyle(
            titleCentered: true,
            formatButtonVisible: true,
            formatButtonShowsNext: false,
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, evts) {
              if (evts.isEmpty) return const SizedBox.shrink();
              final isPresent = evts.first.toLowerCase() == 'present';
              return Positioned(
                bottom: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPresent
                        ? const Color(0xFF3B6D11)
                        : const Color(0xFFA32D2D),
                  ),
                ),
              );
            },
            defaultBuilder: (context, day, focused) {
              final key = DateTime(day.year, day.month, day.day);
              final evts = events[key];
              if (evts == null || evts.isEmpty) return null;
              final isPresent = evts.first.toLowerCase() == 'present';
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isPresent
                      ? const Color(0xFFEAF3DE)
                      : const Color(0xFFFCEBEB),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isPresent
                          ? const Color(0xFF3B6D11)
                          : const Color(0xFFA32D2D),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SUMMARY CHIPS ROW
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildSummaryRows(BuildContext context) {
    return Obx(() {
      final present = controller.presentCount;
      final absent = controller.absentCount;
      final pct = controller.attendancePercentage;
      final color = pct >= 75
          ? const Color(0xFF3B6D11)
          : pct >= 50
              ? const Color(0xFFB45309)
              : const Color(0xFFA32D2D);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _summaryChip(
                icon: Icons.check_circle_outline_rounded,
                label: 'Present',
                value: '$present',
                color: const Color(0xFF3B6D11),
                bg: const Color(0xFFEAF3DE)),
            const SizedBox(width: 10),
            _summaryChip(
                icon: Icons.cancel_outlined,
                label: 'Absent',
                value: '$absent',
                color: const Color(0xFFA32D2D),
                bg: const Color(0xFFFCEBEB)),
            const SizedBox(width: 10),
            _summaryChip(
                icon: Icons.percent_rounded,
                label: 'Rate',
                value: '${pct.toStringAsFixed(1)}%',
                color: color,
                bg: color.withOpacity(0.08)),
          ],
        ),
      );
    });
  }

  Widget _summaryChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFF90A4AE))),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MONTHLY ANALYTICS EXPANSION
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildAnalyticsExpansion(BuildContext context, bool isTablet) {
    return Obx(() {
      final present = controller.presentCount;
      final absent = controller.absentCount;
      final total = present + absent;
      final pct = controller.attendancePercentage;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: ExpansionTile(
          leading:
              const Icon(Icons.bar_chart_rounded, color: Color(0xFF4A6CF7)),
          title: const Text('Monthly Analytics',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _analyticsRow('Total Days', '$total'),
                  _analyticsRow('Present', '$present'),
                  _analyticsRow('Absent', '$absent'),
                  _analyticsRow('Attendance Rate',
                      '${pct.toStringAsFixed(1)}%',
                      highlight: true),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // YEARLY ANALYTICS EXPANSION
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildYearlyAnalyticsExpansion(BuildContext context, bool isTablet) {
    return Obx(() {
      final present = controller.yearlyPresentCount;
      final absent = controller.yearlyAbsentCount;
      final total = present + absent;
      final pct = controller.yearlyAttendancePercentage;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: ExpansionTile(
          leading: const Icon(Icons.calendar_month_rounded,
              color: Color(0xFF7C3AED)),
          title: const Text('Yearly Analytics',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          onExpansionChanged: (expanded) {
            if (expanded) controller.loadYearlyAttendance();
          },
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: controller.isLoading.value
                  ? const Center(
                      child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator()))
                  : Column(
                      children: [
                        _analyticsRow('Total Days (Year)', '$total'),
                        _analyticsRow('Present (Year)', '$present'),
                        _analyticsRow('Absent (Year)', '$absent'),
                        _analyticsRow('Yearly Rate',
                            '${pct.toStringAsFixed(1)}%',
                            highlight: true),
                      ],
                    ),
            ),
          ],
        ),
      );
    });
  }

  Widget _analyticsRow(String label, String value,
      {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: highlight
                      ? const Color(0xFF1A2A3A)
                      : const Color(0xFF6B7280),
                  fontWeight: highlight
                      ? FontWeight.w700
                      : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: highlight
                      ? const Color(0xFF4A6CF7)
                      : const Color(0xFF1A2A3A))),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // HOLIDAY LIST
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildHolidayList(List<Map<String, String>> holidays) {
    if (holidays.isEmpty) {
      return const Center(
        child: Text('No holidays listed',
            style: TextStyle(color: Color(0xFF90A4AE))),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: holidays.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final holiday = holidays[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8EDF2), width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.celebration_rounded,
                    color: Color(0xFF4A6CF7), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(holiday['name'] ?? '',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A2A3A))),
                    const SizedBox(height: 2),
                    Text(
                        '${holiday['date'] ?? ''} · ${holiday['day'] ?? ''}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF90A4AE))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PARENT CALENDAR VIEW (list of children)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildParentCalendarView(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Children\'s Attendance',
          style: TextStyle(
              color: Color(0xFF1A2A3A),
              fontSize: 15,
              fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: controller.loadAttendance,
            icon: const Icon(Icons.refresh, color: Color(0xFF2563EB)),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.myChildren.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.child_care, size: 64, color: Color(0xFFB0C4DE)),
                SizedBox(height: 16),
                Text('No children found',
                    style: TextStyle(
                        fontSize: 16, color: Color(0xFF90A4BE))),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.myChildren.length,
          itemBuilder: (context, index) {
            final child = controller.myChildren[index];
            final name = child['name'] ?? 'Unknown';
            final className = child['class'] ?? child['className'] ?? '';
            final section = child['section'] ?? '';
            final studentId =
                child['studentId'] ?? child['id'] ?? '';
            final percentage =
                (child['attendancePercentage'] ?? 0.0) as num;
            final present = (child['presentDays'] ?? 0) as num;
            final absent = (child['absentDays'] ?? 0) as num;
            final pct = percentage.toDouble();
            final color = pct >= 75
                ? const Color(0xFF3B6D11)
                : pct >= 50
                    ? const Color(0xFFB45309)
                    : const Color(0xFFA32D2D);
            final bgColor = pct >= 75
                ? const Color(0xFFEAF3DE)
                : pct >= 50
                    ? const Color(0xFFFFF7ED)
                    : const Color(0xFFFCEBEB);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 1,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => controller.selectChild(studentId),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFE6F1FB),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: Color(0xFF185FA5),
                              fontWeight: FontWeight.w700,
                              fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A2A3A))),
                            const SizedBox(height: 2),
                            Text('$className $section',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF90A4AE))),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                backgroundColor:
                                    const Color(0xFFE8EDF2),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                                '${present.toInt()} present · ${absent.toInt()} absent',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF90A4AE))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          '${pct.toStringAsFixed(0)}%',
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // TEACHER / ADMIN TABS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildMarkDailyTab(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildFilters(context),
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _markAllPresent,
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    label: const Text('Mark All Present'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                      foregroundColor: Colors.green.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showBulkMarkingDialog(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('Bulk Marking'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppTheme.primaryBlue.withOpacity(0.1),
                      foregroundColor: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildMarkingContent(context),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    return Column(
      children: [
        _buildFilters(context),
        _buildStatsCards(context),
        Expanded(child: _buildContent(context)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MARK ALL PRESENT
  // ─────────────────────────────────────────────────────────────────────────────

  void _markAllPresent() {
    for (final record in controller.attendanceRecords) {
      controller.markAttendance(record.studentId, 'Present');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BULK MARKING DIALOG
  // ─────────────────────────────────────────────────────────────────────────────

  void _showBulkMarkingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Bulk Marking',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: const Text(
            'Mark all students in the current class as present or absent?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              for (final record in controller.attendanceRecords) {
                controller.markAttendance(record.studentId, 'Absent');
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFCEBEB),
                foregroundColor: const Color(0xFFA32D2D)),
            child: const Text('All Absent'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              for (final record in controller.attendanceRecords) {
                controller.markAttendance(record.studentId, 'Present');
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A6CF7),
                foregroundColor: Colors.white),
            child: const Text('All Present'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // DATE PICKER
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF4A6CF7),
            onPrimary: Colors.white,
            onSurface: Color(0xFF1A2A3A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      controller.selectedDate.value = picked;
      controller.loadAttendance();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MARKING CONTENT
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildMarkingContent(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()));
      }
      if (controller.attendanceRecords.isEmpty) {
        return const SizedBox(
          height: 200,
          child: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.how_to_reg, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No students found for marking attendance'),
                  Text('Select class and section to load students'),
                ]),
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Column(
            children: [
              _buildMarkingTableHeader(),
              const Divider(height: 1),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.attendanceRecords.length,
                itemBuilder: (context, index) => _buildMarkingRow(
                    context,
                    controller.attendanceRecords[index],
                    index),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMarkingTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F5FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(children: [
        const SizedBox(width: 36),
        const SizedBox(width: 8),
        const Expanded(
            flex: 3,
            child: Text('Student',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xFF1A2A3A)))),
        const Expanded(
            flex: 2,
            child: Text('Roll / Class',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xFF1A2A3A)))),
        const SizedBox(
            width: 90,
            child: Text('Mark',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xFF1A2A3A)),
                textAlign: TextAlign.center)),
      ]),
    );
  }

  Widget _buildMarkingRow(
      BuildContext context, AttendanceRecord record, int index) {
    final isPresent = record.status == 'Present';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFEFF6FF),
          child: Text(
            record.studentName.isNotEmpty
                ? record.studentName[0].toUpperCase()
                : '?',
            style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w700,
                fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(record.studentName,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Color(0xFF1A2A3A)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          flex: 2,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.rollNumber,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF1A2A3A))),
                Text('${record.className} · ${record.section}',
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF90A4BE))),
              ]),
        ),
        SizedBox(
          width: 90,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => controller.markAttendance(
                      record.studentId, 'Present'),
                  child: Icon(Icons.check_circle_rounded,
                      color: isPresent
                          ? const Color(0xFF059669)
                          : Colors.grey.shade300,
                      size: 22),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => controller.markAttendance(
                      record.studentId, 'Absent'),
                  child: Icon(Icons.cancel_rounded,
                      color: !isPresent
                          ? const Color(0xFFEF4444)
                          : Colors.grey.shade300,
                      size: 22),
                ),
              ]),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PARENT DATE-WISE VIEW
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildParentDateWiseAttendanceView(BuildContext context) {
    return Column(
      children: [
        _buildParentHeader(context),
        Expanded(child: _buildParentSimpleAttendanceList(context)),
      ],
    );
  }

  Widget _buildParentHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Text("My Children's Attendance",
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
              onPressed: controller.loadAttendance,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh'),
        ],
      ),
    );
  }

  Widget _buildParentSimpleAttendanceList(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value)
        return const Center(child: CircularProgressIndicator());
      if (controller.myChildren.isEmpty) {
        return const Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              Icon(Icons.family_restroom, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No children found'),
            ]));
      }
      final allRecords = controller.getAllChildrenAttendance();
      if (allRecords.isEmpty) {
        return const Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              Icon(Icons.event_note, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No attendance records found'),
            ]));
      }
      allRecords.sort((a, b) => b['date'].compareTo(a['date']));
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: allRecords.length,
        itemBuilder: (context, index) {
          final record = allRecords[index];
          final child = controller.myChildren.firstWhere(
            (c) => c['id'] == record['studentId'],
            orElse: () => {'name': 'Unknown Child', 'class': 'N/A'},
          );
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    record['status'] == 'present' ? Colors.green : Colors.red,
                child: Icon(
                    record['status'] == 'present'
                        ? Icons.check
                        : Icons.close,
                    color: Colors.white),
              ),
              title: Text(child['name'] ?? 'Unknown Child'),
              subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Class: ${child['class'] ?? 'N/A'}'),
                    Text('Date: ${_formatDate(record['date'])}'),
                  ]),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: record['status'] == 'present'
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  record['status'].toUpperCase(),
                  style: TextStyle(
                    color: record['status'] == 'present'
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dateOnly = DateTime(date.year, date.month, date.day);
      if (dateOnly == today) return 'Today';
      if (dateOnly == today.subtract(const Duration(days: 1)))
        return 'Yesterday';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateString;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FILTERS (teacher/admin)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Obx(() => InkWell(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Text(controller.selectedDate.value
                                    .toString()
                                    .split(' ')[0]),
                              ]),
                            ),
                          )),
                    ]),
              ),
            ),
          ),
          const SizedBox(width: 16),
          if (controller.userRole != 'teacher')
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Class',
                            style:
                                TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: controller.selectedClass.value.isEmpty
                              ? null
                              : controller.selectedClass.value,
                          decoration: const InputDecoration(
                              hintText: 'Select Class',
                              border: OutlineInputBorder()),
                          items: [
                            'Class 1',
                            'Class 2',
                            'Class 3',
                            'Class 4',
                            'Class 5'
                          ]
                              .map((cls) => DropdownMenuItem(
                                  value: cls, child: Text(cls)))
                              .toList(),
                          onChanged: (v) =>
                              controller.selectClass(v ?? ''),
                        ),
                      ]),
                ),
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Section',
                          style:
                              TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: controller.selectedSection.value.isEmpty
                            ? null
                            : controller.selectedSection.value,
                        decoration: const InputDecoration(
                            hintText: 'Select Section',
                            border: OutlineInputBorder()),
                        items: ['Section A', 'Section B', 'Section C']
                            .map((sec) => DropdownMenuItem(
                                value: sec, child: Text(sec)))
                            .toList(),
                        onChanged: (v) =>
                            controller.selectSection(v ?? ''),
                      ),
                    ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(() => Row(
            children: [
              Expanded(
                  child: Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(children: [
                            const Icon(Icons.how_to_reg,
                                size: 40, color: Colors.green),
                            const SizedBox(height: 10),
                            const Text('Present',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text('${controller.presentCount}',
                                style: const TextStyle(
                                    fontSize: 24,
                                    color: Colors.green)),
                          ])))),
              Expanded(
                  child: Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(children: [
                            const Icon(Icons.person_off,
                                size: 40, color: Colors.red),
                            const SizedBox(height: 10),
                            const Text('Absent',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text('${controller.absentCount}',
                                style: const TextStyle(
                                    fontSize: 24, color: Colors.red)),
                          ])))),
              Expanded(
                  child: Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(children: [
                            const Icon(Icons.people,
                                size: 40,
                                color: AppTheme.primaryBlue),
                            const SizedBox(height: 10),
                            const Text('Total',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text('${controller.totalStudents}',
                                style: const TextStyle(
                                    fontSize: 24,
                                    color: AppTheme.primaryBlue)),
                          ])))),
              Expanded(
                  child: Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(children: [
                            const Icon(Icons.percent,
                                size: 40, color: Colors.orange),
                            const SizedBox(height: 10),
                            const Text('Percentage',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(
                                '${controller.attendancePercentage.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                    fontSize: 24,
                                    color: Colors.orange)),
                          ])))),
            ],
          )),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.attendanceRecords.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FB),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFE8EDF2), width: 0.5),
                ),
                child: const Icon(Icons.history_edu_outlined,
                    size: 28, color: Color(0xFF90A4AE)),
              ),
              const SizedBox(height: 16),
              const Text('No records found',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A2A3A))),
              const SizedBox(height: 6),
              const Text(
                'Select a class and section\nto view attendance records',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF90A4AE),
                    height: 1.5),
              ),
            ]),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
        itemCount: controller.attendanceRecords.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) =>
            _VPAttendanceCard(record: controller.attendanceRecords[i]),
      );
    });
  }
} // end AttendanceView

// ─────────────────────────────────────────────────────────────────────────────
// FILTERS CARD widget
// ─────────────────────────────────────────────────────────────────────────────

class _VPFiltersCard extends StatelessWidget {
  final ParentAttendanceController controller;
  const _VPFiltersCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EDF2), width: 0.5),
      ),
      child: Column(children: [
        Obx(() => GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: controller.selectedDate.value,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) controller.selectDate(picked);
              },
              child: _VPFilterBox(
                icon: Icons.calendar_today_outlined,
                label: DateFormat('dd MMM yyyy')
                    .format(controller.selectedDate.value),
                isActive: true,
              ),
            )),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: Obx(() => _VPDropdown<String>(
                  icon: Icons.school_outlined,
                  hint: 'Class',
                  value: controller.selectedClass.value.isEmpty
                      ? null
                      : controller.selectedClass.value,
                  items: const [
                    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
                    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
                  ],
                  onChanged: (v) => controller.selectClass(v ?? ''),
                )),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(() => _VPDropdown<String>(
                  icon: Icons.people_outline_rounded,
                  hint: 'Section',
                  value: controller.selectedSection.value.isEmpty
                      ? null
                      : controller.selectedSection.value,
                  items: const [
                    'Section A', 'Section B', 'Section C', 'Section D',
                  ],
                  onChanged: (v) => controller.selectSection(v ?? ''),
                )),
          ),
        ]),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _VPDateChip(
                label: 'Today',
                date: DateTime.now(),
                controller: controller),
            const SizedBox(width: 6),
            _VPDateChip(
                label: 'Yesterday',
                date: DateTime.now().subtract(const Duration(days: 1)),
                controller: controller),
            const SizedBox(width: 6),
            _VPDateChip(
                label: 'Last 7 days',
                date: DateTime.now().subtract(const Duration(days: 7)),
                controller: controller),
            const SizedBox(width: 6),
            _VPDateChip(
                label: 'This month',
                date: DateTime(DateTime.now().year, DateTime.now().month, 1),
                controller: controller),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small UI helpers
// ─────────────────────────────────────────────────────────────────────────────

class _VPFilterBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  const _VPFilterBox(
      {required this.icon, required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color:
            isActive ? const Color(0xFFE6F1FB) : const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
              ? const Color(0xFFB5D4F4)
              : const Color(0xFFE8EDF2),
          width: 0.5,
        ),
      ),
      child: Row(children: [
        Icon(icon,
            size: 14,
            color: isActive
                ? const Color(0xFF185FA5)
                : const Color(0xFF90A4AE)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? const Color(0xFF185FA5)
                    : const Color(0xFF1A2A3A),
              ),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}

class _VPDropdown<T> extends StatelessWidget {
  final IconData icon;
  final String hint;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  const _VPDropdown({
    required this.icon,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F1FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8EDF2), width: 0.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Row(children: [
            Icon(icon, size: 14, color: const Color(0xFF90A4AE)),
            const SizedBox(width: 6),
            Text(hint,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF90A4AE))),
          ]),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 16, color: Color(0xFF90A4AE)),
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A2A3A)),
          items: items
              .map((i) => DropdownMenuItem<T>(
                    value: i,
                    child: Text(i.toString()),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _VPDateChip extends StatelessWidget {
  final String label;
  final DateTime date;
  final ParentAttendanceController controller;
  const _VPDateChip({
    required this.label,
    required this.date,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.selectedDate.value = date;
          controller.loadAttendance();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F1FB),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: const Color(0xFFB5D4F4), width: 0.5),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF185FA5),
                fontWeight: FontWeight.w500)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ATTENDANCE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _VPAttendanceCard extends StatelessWidget {
  final AttendanceRecord record;
  const _VPAttendanceCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final isPresent = record.status == 'Present';
    final statusColor =
        isPresent ? const Color(0xFF3B6D11) : const Color(0xFFA32D2D);
    final statusBg =
        isPresent ? const Color(0xFFEAF3DE) : const Color(0xFFFCEBEB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EDF2), width: 0.5),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFE6F1FB),
          child: Text(
            record.studentName.isNotEmpty
                ? record.studentName[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: Color(0xFF185FA5),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.studentName,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2A3A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                    '${record.rollNumber} · ${record.className} ${record.section}',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF90A4AE))),
              ]),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isPresent ? 'Present' : 'Absent',
            style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w700),
          ),
        ),
      ]),
    );
  }
}
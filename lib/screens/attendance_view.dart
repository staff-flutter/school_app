import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:collection/collection.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/parent_attendance_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/widgets/permission_wrapper.dart';
import 'package:school_app/widgets/pie_chart_painter.dart';

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
  // MAIN REDESIGNED VIEW  (specific student / parent calendar)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildSpecificStudentAttendanceView(BuildContext context) {
    final focusedDay = controller.selectedDate.value.obs;
    final selectedDay = Rxn<DateTime>();
    final calendarFormat = CalendarFormat.month.obs;
    final selectedYear = controller.selectedDate.value.year.obs;
    final selectedMonth = controller.selectedDate.value.month.obs;
    final activeTab = 'attendance'.obs; // 'attendance' | 'holiday'
    final filtersVisible = false.obs;

    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    // ── sample holiday data – replace with real data from controller ──────────
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
                  // Back + title row
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
                        // Filter icon
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

                  // Pill toggle
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

          // ── Body scrollable ──────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (activeTab.value == 'holiday') {
                return _buildHolidayList(holidays);
              }
              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Calendar card
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

                    // Summary rows
                    _buildSummaryRows(context),

                    const SizedBox(height: 16),

                    // Monthly analytics (collapsible)
                    _buildAnalyticsExpansion(context, isTablet),

                    const SizedBox(height: 16),

                    // Yearly analytics (collapsible)
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
  // COLLAPSIBLE FILTERS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildCollapsibleFilters(
    BuildContext context,
    RxInt selectedYear,
    RxInt selectedMonth,
    Rx<DateTime> focusedDay,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          Obx(() => Row(
                children: [
                  Expanded(
                    child: _styledDropdown<int>(
                      label: 'Year',
                      value: selectedYear.value,
                      icon: Icons.calendar_today_outlined,
                      items: List.generate(
                              50, (i) => DateTime.now().year - 25 + i)
                          .map((y) => DropdownMenuItem(
                              value: y, child: Text(y.toString())))
                          .toList(),
                      onChanged: (y) {
                        if (y != null) {
                          selectedYear.value = y;
                          final d = DateTime(y, selectedMonth.value, 1);
                          controller.selectedDate.value = d;
                          focusedDay.value = d;
                          controller.loadAttendance();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _styledDropdown<int>(
                      label: 'Month',
                      value: selectedMonth.value,
                      icon: Icons.date_range_outlined,
                      items: List.generate(12, (i) => i + 1)
                          .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(DateFormat('MMMM')
                                  .format(DateTime(2024, m, 1)))))
                          .toList(),
                      onChanged: (m) {
                        if (m != null) {
                          selectedMonth.value = m;
                          final d = DateTime(selectedYear.value, m, 1);
                          controller.selectedDate.value = d;
                          focusedDay.value = d;
                          controller.loadAttendance();
                        }
                      },
                    ),
                  ),
                ],
              )),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _quickChip('Today', DateTime.now(), selectedYear, selectedMonth,
                    focusedDay),
                const SizedBox(width: 8),
                _quickChip('Yesterday',
                    DateTime.now().subtract(const Duration(days: 1)),
                    selectedYear, selectedMonth, focusedDay),
                const SizedBox(width: 8),
                _quickChip('Last Week',
                    DateTime.now().subtract(const Duration(days: 7)),
                    selectedYear, selectedMonth, focusedDay),
                const SizedBox(width: 8),
                _quickChip('Last Month',
                    DateTime.now().subtract(const Duration(days: 30)),
                    selectedYear, selectedMonth, focusedDay),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _styledDropdown<T>({
    required String label,
    required T value,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18, color: const Color(0xFF4A6CF7)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _quickChip(
    String label,
    DateTime date,
    RxInt selectedYear,
    RxInt selectedMonth,
    Rx<DateTime> focusedDay,
  ) {
    return ActionChip(
      label: Text(label,
          style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4A6CF7),
              fontWeight: FontWeight.w500)),
      backgroundColor: const Color(0xFF4A6CF7).withOpacity(0.08),
      side: BorderSide(color: const Color(0xFF4A6CF7).withOpacity(0.3)),
      onPressed: () {
        selectedYear.value = date.year;
        selectedMonth.value = date.month;
        final d = DateTime(date.year, date.month, date.day);
        controller.selectedDate.value = d;
        focusedDay.value = d;
        controller.loadAttendance();
      },
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Obx(() => TableCalendar(
              firstDay: DateTime(1990, 1, 1),
              lastDay: DateTime(3000, 12, 31),
              focusedDay: focusedDay.value,
              calendarFormat: calendarFormat.value,
              selectedDayPredicate: (day) =>
                  selectedDay.value != null &&
                  isSameDay(selectedDay.value!, day),
              onDaySelected: (sel, foc) {
                selectedDay.value = sel;
                focusedDay.value = foc;
                _showAttendanceDetails(context, sel);
              },
              onFormatChanged: (f) => calendarFormat.value = f,
              onPageChanged: (foc) {
                focusedDay.value = foc;
                controller.selectedDate.value = foc;
                selectedYear.value = foc.year;
                selectedMonth.value = foc.month;
                controller.loadAttendance();
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                cellMargin: const EdgeInsets.all(4),
                weekendTextStyle: TextStyle(
                    color: Colors.indigo.shade300,
                    fontWeight: FontWeight.w600),
                defaultTextStyle: const TextStyle(fontSize: 14),
                todayDecoration: const BoxDecoration(
                  color: Color(0xFF4A6CF7),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: const Color(0xFF4A6CF7).withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  color: Color(0xFF1A1F36),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                leftChevronIcon: Icon(Icons.chevron_left,
                    color: Color(0xFF4A6CF7)),
                rightChevronIcon: Icon(Icons.chevron_right,
                    color: Color(0xFF4A6CF7)),
                headerPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: const TextStyle(
                    color: Color(0xFF1A1F36),
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
                weekendStyle: TextStyle(
                    color: Colors.indigo.shade300,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: _calendarDayBuilder,
                todayBuilder: _calendarDayBuilder,
              ),
            )),
      ),
    );
  }

  Widget? _calendarDayBuilder(
      BuildContext context, DateTime day, DateTime focusedDay) {
    final status = _getAttendanceStatusForDay(day);
    final isToday = isSameDay(day, DateTime.now());
    final isWeekend = day.weekday == DateTime.saturday ||
        day.weekday == DateTime.sunday;

    Color? bgColor;
    Color textColor = isWeekend ? Colors.indigo.shade300 : const Color(0xFF1A1F36);

    if (status == 'present') {
      bgColor = AppTheme.successGreen;
      textColor = Colors.white;
    } else if (status == 'absent') {
      bgColor = AppTheme.errorRed;
      textColor = Colors.white;
    } else if (isToday) {
      bgColor = const Color(0xFF4A6CF7);
      textColor = Colors.white;
    }

    if (bgColor == null) return null;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: isToday && status != null
            ? Border.all(color: Colors.white, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SUMMARY ROWS (like the screenshot's Absent / Festival & Holidays pills)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildSummaryRows(BuildContext context) {
    return Obx(() {
      final presentCount = controller.presentCount;
      final absentCount = controller.absentCount;
      final totalDays = presentCount + absentCount;
      final pct = controller.attendancePercentage;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _summaryRow(
              icon: Icons.check_circle_outline,
              label: 'Present',
              count: presentCount,
              color: AppTheme.successGreen,
            ),
            const SizedBox(height: 10),
            _summaryRow(
              icon: Icons.cancel_outlined,
              label: 'Absent',
              count: absentCount,
              color: AppTheme.errorRed,
            ),
            const SizedBox(height: 10),
            _summaryRow(
              icon: Icons.percent,
              label: 'Attendance',
              count: null,
              label2: '${pct.toStringAsFixed(1)}%',
              color: pct >= 85
                  ? AppTheme.successGreen
                  : pct >= 75
                      ? Colors.orange
                      : AppTheme.errorRed,
            ),
          ],
        ),
      );
    });
  }

  Widget _summaryRow({
    required IconData icon,
    required String label,
    required int? count,
    String? label2,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1F36),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label2 ?? '${count?.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // HOLIDAY LIST
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildHolidayList(List<Map<String, String>> holidays) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend row
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppTheme.successGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text('Festival & Holiday',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1F36))),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'List of Holiday',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1F36)),
          ),
          const SizedBox(height: 12),
          ...holidays.map((h) => _holidayCard(h)).toList(),
        ],
      ),
    );
  }

  Widget _holidayCard(Map<String, String> holiday) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.successGreen,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holiday['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1F36),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  holiday['date'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AppTheme.successGreen.withOpacity(0.3)),
            ),
            child: Text(
              holiday['day'] ?? '',
              style: TextStyle(
                color: AppTheme.successGreen,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ANALYTICS EXPANSIONS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildAnalyticsExpansion(BuildContext context, bool isTablet) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A6CF7).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Monthly Analytics',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF1A1F36)),
        ),
        subtitle: Obx(() {
          final pct = controller.attendancePercentage;
          final month = DateFormat('MMMM yyyy')
              .format(controller.selectedDate.value);
          return Text(
            '$month • ${pct.toStringAsFixed(0)}% present',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          );
        }),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Obx(() => _buildPieRow(
                  controller.presentCount,
                  controller.absentCount,
                  controller.attendancePercentage,
                  AppTheme.successGreen,
                  AppTheme.errorRed,
                  AppTheme.primaryBlue,
                  isTablet,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyAnalyticsExpansion(BuildContext context, bool isTablet) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Yearly Analytics',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF1A1F36)),
        ),
        subtitle: Obx(() {
          final pct = controller.yearlyAttendancePercentage;
          final year = controller.selectedDate.value.year;
          return Text(
            '$year • ${pct.toStringAsFixed(0)}% present',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          );
        }),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Obx(() => _buildPieRow(
                  controller.yearlyPresentCount,
                  controller.yearlyAbsentCount,
                  controller.yearlyAttendancePercentage,
                  AppTheme.successGreen,
                  AppTheme.errorRed,
                  Colors.purple,
                  isTablet,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildPieRow(
    int presentCount,
    int absentCount,
    double presentPct,
    Color presentColor,
    Color absentColor,
    Color totalColor,
    bool isTablet,
  ) {
    final total = presentCount + absentCount;
    final absentPct = total > 0 ? 100 - presentPct : 0.0;

    if (total == 0) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No data available',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return Row(
      children: [
        SizedBox(
          width: isTablet ? 110 : 90,
          height: isTablet ? 110 : 90,
          child: CustomPaint(
            painter: PieChartPainter(
              presentPercentage: presentPct,
              absentPercentage: absentPct,
              presentColor: presentColor,
              absentColor: absentColor,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legendDot('Present: ${presentPct.toStringAsFixed(1)}%',
                  presentColor, isTablet),
              const SizedBox(height: 8),
              _legendDot('Absent: ${absentPct.toStringAsFixed(1)}%',
                  absentColor, isTablet),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                      'Present', '$presentCount', presentColor, isTablet),
                  _buildStatItem(
                      'Absent', '$absentCount', absentColor, isTablet),
                  _buildStatItem('Total', '$total', totalColor, isTablet),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendDot(String label, Color color, bool isTablet) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 14 : 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PARENT CALENDAR VIEW (unchanged structure, new header design)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildParentCalendarView(BuildContext context) {
    final focusedDay = DateTime.now().obs;
    final selectedDay = DateTime.now().obs;
    final calendarFormat = CalendarFormat.month.obs;
    final activeTab = 'attendance'.obs;

    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4A6CF7), Color(0xFF3730A3)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        const Text(
                          'Attendance',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: controller.loadAttendance,
                          icon: const Icon(Icons.refresh, color: Colors.white),
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
          Expanded(
            child: Obx(() => activeTab.value == 'holiday'
                ? _buildHolidayList([
                    {
                      'name': 'Republic Day',
                      'date': '26th January',
                      'day': 'Sunday'
                    },
                    {'name': 'Holi', 'date': '14th March', 'day': 'Friday'},
                    {
                      'name': 'Good Friday',
                      'date': '18th April',
                      'day': 'Friday'
                    },
                  ])
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildParentCalendarWidget(
                            context, focusedDay, selectedDay, calendarFormat),
                        const SizedBox(height: 16),
                        _buildSummaryRows(context),
                        const SizedBox(height: 16),
                        _buildParentLegend(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  )),
          ),
        ],
      ),
    );
  }

  Widget _buildParentCalendarWidget(
    BuildContext context,
    Rx<DateTime> focusedDay,
    Rx<DateTime> selectedDay,
    Rx<CalendarFormat> calendarFormat,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Obx(() => TableCalendar(
              firstDay: DateTime(1990, 1, 1),
              lastDay: DateTime(3000, 12, 31),
              focusedDay: focusedDay.value,
              calendarFormat: calendarFormat.value,
              selectedDayPredicate: (d) => isSameDay(selectedDay.value, d),
              onDaySelected: (sel, foc) {
                selectedDay.value = sel;
                focusedDay.value = foc;
              },
              onFormatChanged: (f) => calendarFormat.value = f,
              onPageChanged: (foc) => focusedDay.value = foc,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                cellMargin: const EdgeInsets.all(4),
                weekendTextStyle: TextStyle(
                    color: Colors.indigo.shade300,
                    fontWeight: FontWeight.w600),
                defaultTextStyle: const TextStyle(fontSize: 14),
                todayDecoration: const BoxDecoration(
                  color: Color(0xFF4A6CF7),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: const Color(0xFF4A6CF7).withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                    color: Color(0xFF1A1F36),
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
                leftChevronIcon:
                    Icon(Icons.chevron_left, color: Color(0xFF4A6CF7)),
                rightChevronIcon:
                    Icon(Icons.chevron_right, color: Color(0xFF4A6CF7)),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: const TextStyle(
                    color: Color(0xFF1A1F36),
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
                weekendStyle: TextStyle(
                    color: Colors.indigo.shade300,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (ctx, day, foc) {
                  final events = _getEventsForDay(day);
                  final isToday = isSameDay(day, DateTime.now());
                  if (events.isNotEmpty) {
                    final color = events.first == 'present'
                        ? AppTheme.successGreen
                        : AppTheme.errorRed;
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text('${day.day}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ),
                    );
                  }
                  if (isToday) {
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: Color(0xFF4A6CF7), shape: BoxShape.circle),
                      child: Center(
                        child: Text('${day.day}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ),
                    );
                  }
                  return null;
                },
              ),
            )),
      ),
    );
  }

  Widget _buildParentLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem('Present', AppTheme.successGreen),
          _buildLegendItem('Absent', AppTheme.errorRed),
          _buildLegendItem('Today', const Color(0xFF4A6CF7)),
          _buildLegendItem('Holiday', AppTheme.successGreen),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // TEACHER TABS (unchanged)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildMarkDailyTab(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildFilters(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _markAllPresent,
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('All Present'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showBulkMarkingDialog(context),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Bulk Mark'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
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
  // HELPER METHODS (all original helpers preserved)
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
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.how_to_reg, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No students found for marking attendance'),
              Text('Select class and section to load students'),
            ]),
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDE6F5)),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFDDE6F5).withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            children: [
              _buildMarkingTableHeader(),
              const Divider(height: 1, color: Color(0xFFDDE6F5)),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.attendanceRecords.length,
                itemBuilder: (context, index) =>
                    _buildMarkingRow(context, controller.attendanceRecords[index], index),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMarkingTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F5FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
      ),
      child: Row(children: [
        const SizedBox(width: 30),
        const SizedBox(width: 8),
        const Expanded(
            flex: 3,
            child: Text('Student',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11,
                    color: Color(0xFF1A2A3A)))),
        const Expanded(
            flex: 2,
            child: Text('Roll / Class',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11,
                    color: Color(0xFF1A2A3A)))),
        const SizedBox(
            width: 64,
            child: Text('Mark',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11,
                    color: Color(0xFF1A2A3A)),
                textAlign: TextAlign.center)),
      ]),
    );
  }

  Widget _buildMarkingRow(BuildContext context, AttendanceRecord record, int index) {
    final isPresent = record.status == 'Present';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF0F5FF)))),
      child: Row(children: [
        // Avatar initials
        CircleAvatar(
          radius: 15,
          backgroundColor: const Color(0xFFEFF6FF),
          child: Text(
            record.studentName.isNotEmpty ? record.studentName[0].toUpperCase() : '?',
            style: const TextStyle(
                color: Color(0xFF2563EB), fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ),
        const SizedBox(width: 8),
        // Name
        Expanded(
          flex: 3,
          child: Text(record.studentName,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF1A2A3A)),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        // Roll / Class
        Expanded(
          flex: 2,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(record.rollNumber,
                style: const TextStyle(fontSize: 10, color: Color(0xFF1A2A3A))),
            Text('${record.className} · ${record.section}',
                style: const TextStyle(fontSize: 9, color: Color(0xFF90A4BE))),
          ]),
        ),
        // Mark buttons — fixed narrow column
        SizedBox(
          width: 64,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            GestureDetector(
              onTap: () => controller.markAttendance(record.studentId, 'Present'),
              child: Icon(Icons.check_circle_rounded,
                  color: isPresent ? const Color(0xFF059669) : const Color(0xFFDDE6F5),
                  size: 20),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => controller.markAttendance(record.studentId, 'Absent'),
              child: Icon(Icons.cancel_rounded,
                  color: !isPresent ? const Color(0xFFEF4444) : const Color(0xFFDDE6F5),
                  size: 20),
            ),
          ]),
        ),
      ]),
    );
  }

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
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Text("My Children's Attendance",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(onPressed: controller.loadAttendance, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
        ],
      ),
    );
  }

  Widget _buildParentSimpleAttendanceList(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
      if (controller.myChildren.isEmpty) {
        return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.family_restroom, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No children found'),
        ]));
      }
      final allRecords = controller.getAllChildrenAttendance();
      if (allRecords.isEmpty) {
        return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
                backgroundColor: record['status'] == 'present' ? Colors.green : Colors.red,
                child: Icon(record['status'] == 'present' ? Icons.check : Icons.close, color: Colors.white),
              ),
              title: Text(child['name'] ?? 'Unknown Child'),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Class: ${child['class'] ?? 'N/A'}'),
                Text('Date: ${_formatDate(record['date'])}'),
              ]),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: record['status'] == 'present' ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  record['status'].toUpperCase(),
                  style: TextStyle(
                    color: record['status'] == 'present' ? Colors.green.shade800 : Colors.red.shade800,
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
      if (dateOnly == today.subtract(const Duration(days: 1))) return 'Yesterday';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateString;
    }
  }

  Widget _buildFilters(BuildContext context) {
    const inputDeco = InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      border: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFDDE6F5))),
      enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFDDE6F5))),
      focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF2563EB), width: 1.5)),
      filled: true,
      fillColor: Colors.white,
      hintStyle: TextStyle(fontSize: 12, color: Color(0xFF90A4BE)),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE6F5)),
      ),
      child: Row(children: [
        // Date picker
        Expanded(
          child: Obx(() => InkWell(
            onTap: () => _selectDate(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDDE6F5)),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 13, color: Color(0xFF2563EB)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    controller.selectedDate.value.toString().split(' ')[0],
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF1A2A3A)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
          )),
        ),
        if (controller.userRole != 'teacher') ...[
          const SizedBox(width: 8),
          // Class dropdown
          Expanded(
            child: Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedClass.value.isEmpty
                  ? null
                  : controller.selectedClass.value,
              decoration:
                  inputDeco.copyWith(hintText: 'Class'),
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF1A2A3A)),
              items: ['Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5']
                  .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c,
                          style: const TextStyle(fontSize: 12))))
                  .toList(),
              onChanged: (v) => controller.selectClass(v ?? ''),
              iconSize: 18,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF2563EB)),
            )),
          ),
        ],
        const SizedBox(width: 8),
        // Section dropdown
        Expanded(
          child: Obx(() => DropdownButtonFormField<String>(
            value: controller.selectedSection.value.isEmpty
                ? null
                : controller.selectedSection.value,
            decoration: inputDeco.copyWith(hintText: 'Section'),
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF1A2A3A)),
            items: ['Section A', 'Section B', 'Section C']
                .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s,
                        style: const TextStyle(fontSize: 12))))
                .toList(),
            onChanged: (v) => controller.selectSection(v ?? ''),
            iconSize: 18,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF2563EB)),
          )),
        ),
      ]),
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Obx(() {
        final present = controller.presentCount;
        final absent  = controller.absentCount;
        final total   = controller.totalStudents;
        final pct     = controller.attendancePercentage;
        return Row(children: [
          _statChip(Icons.check_circle_rounded, 'Present', '$present',
              const Color(0xFF059669)),
          const SizedBox(width: 7),
          _statChip(Icons.cancel_rounded, 'Absent', '$absent',
              const Color(0xFFEF4444)),
          const SizedBox(width: 7),
          _statChip(Icons.people_rounded, 'Total', '$total',
              const Color(0xFF2563EB)),
          const SizedBox(width: 7),
          _statChip(Icons.percent_rounded, 'Rate',
              '${pct.toStringAsFixed(0)}%', const Color(0xFF0891B2)),
        ]);
      }),
    );
  }

  Widget _statChip(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.20)),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFDDE6F5).withOpacity(0.5),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF90A4BE),
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.attendanceRecords.isEmpty) {
        return const Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.how_to_reg, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No attendance records found'),
          ]),
        );
      }
      return LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 520;
        if (isWide) {
          // ── Wide: compact table layout ────────────────────────────────────
          return Container(
            padding: const EdgeInsets.all(12),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200)),
              child: Column(children: [
                _buildTableHeader(),
                const Divider(height: 1),
                Expanded(child: ListView.builder(
                  itemCount: controller.attendanceRecords.length,
                  itemBuilder: (ctx, i) =>
                      _buildAttendanceRow(ctx, controller.attendanceRecords[i], i),
                )),
              ]),
            ),
          );
        } else {
          // ── Narrow: responsive card list ──────────────────────────────────
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            itemCount: controller.attendanceRecords.length,
            itemBuilder: (ctx, i) =>
                _buildAttendanceCard(ctx, controller.attendanceRecords[i]),
          );
        }
      });
    });
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(children: [
        const SizedBox(width: 36),
        const SizedBox(width: 8),
        const Expanded(
            flex: 3,
            child: Text('Student',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12,
                    color: Color(0xFF1A2A3A)))),
        const Expanded(
            flex: 2,
            child: Text('Roll / Class',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12,
                    color: Color(0xFF1A2A3A)))),
        const SizedBox(
            width: 70,
            child: Text('Status',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12,
                    color: Color(0xFF1A2A3A)),
                textAlign: TextAlign.center)),
        if (controller.canMark)
          const SizedBox(
              width: 80,
              child: Text('Mark',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12,
                      color: Color(0xFF1A2A3A)),
                  textAlign: TextAlign.center)),
      ]),
    );
  }

  Widget _buildAttendanceRow(BuildContext context, AttendanceRecord record, int index) {
    final isPresent = record.status == 'Present';
    final statusColor = isPresent ? const Color(0xFF059669) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(children: [
        // Avatar
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFEFF6FF),
          child: Text(
            record.studentName.isNotEmpty
                ? record.studentName[0].toUpperCase()
                : '?',
            style: const TextStyle(
                color: Color(0xFF2563EB), fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        // Name
        Expanded(
          flex: 3,
          child: Text(
            record.studentName,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF1A2A3A)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Roll / Class
        Expanded(
          flex: 2,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(record.rollNumber,
                style: const TextStyle(fontSize: 11, color: Color(0xFF1A2A3A))),
            Text('${record.className} · ${record.section}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF90A4BE))),
          ]),
        ),
        // Status badge
        SizedBox(
          width: 70,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isPresent ? 'Present' : 'Absent',
                style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        // Mark buttons
        if (controller.canMark)
          SizedBox(
            width: 80,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _markBtn(Icons.check_circle_rounded,
                  isPresent ? const Color(0xFF059669) : Colors.grey.shade300,
                  () => controller.markAttendance(record.studentId, 'Present')),
              const SizedBox(width: 4),
              _markBtn(Icons.cancel_rounded,
                  !isPresent ? const Color(0xFFEF4444) : Colors.grey.shade300,
                  () => controller.markAttendance(record.studentId, 'Absent')),
            ]),
          ),
      ]),
    );
  }

  /// Compact card shown in narrow/mobile layout
  Widget _buildAttendanceCard(BuildContext context, AttendanceRecord record) {
    final isPresent = record.status == 'Present';
    final statusColor = isPresent ? const Color(0xFF059669) : const Color(0xFFEF4444);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE6F5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        // Avatar
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFEFF6FF),
          child: Text(
            record.studentName.isNotEmpty
                ? record.studentName[0].toUpperCase()
                : '?',
            style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w700,
                fontSize: 15),
          ),
        ),
        const SizedBox(width: 10),
        // Info
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              record.studentName,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF1A2A3A)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(children: [
              Text('Roll: ${record.rollNumber}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF90A4BE))),
              const SizedBox(width: 8),
              Text('${record.className} · ${record.section}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF90A4BE))),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        // Status + mark buttons stacked vertically
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isPresent ? 'Present' : 'Absent',
              style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700),
            ),
          ),
          if (controller.canMark) ...[
            const SizedBox(height: 6),
            Row(children: [
              _markBtn(Icons.check_circle_rounded,
                  isPresent ? const Color(0xFF059669) : Colors.grey.shade300,
                  () => controller.markAttendance(record.studentId, 'Present')),
              const SizedBox(width: 4),
              _markBtn(Icons.cancel_rounded,
                  !isPresent ? const Color(0xFFEF4444) : Colors.grey.shade300,
                  () => controller.markAttendance(record.studentId, 'Absent')),
            ]),
          ],
        ]),
      ]),
    );
  }

  Widget _markBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 22),
    );
  }

  void _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) controller.selectDate(picked);
  }

  void _markAllPresent() {
    for (final r in controller.attendanceRecords) {
      controller.markAttendance(r.studentId, 'Present');
    }
    Get.snackbar('Success', 'All students marked present',
        backgroundColor: AppTheme.successGreen);
  }

  void _showBulkMarkingDialog(BuildContext context) {
    Get.dialog(AlertDialog(
      title: const Text('Bulk Attendance Marking'),
      content: SizedBox(
        width: 600,
        height: 400,
        child: Column(children: [
          const Text('Click on student names to toggle attendance:'),
          const SizedBox(height: 10),
          Expanded(child: ListView.builder(
            itemCount: controller.attendanceRecords.length,
            itemBuilder: (context, index) {
              final record = controller.attendanceRecords[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: record.status == 'Present' ? Colors.green : Colors.red,
                  child: Icon(record.status == 'Present' ? Icons.check : Icons.close, color: Colors.white),
                ),
                title: Text(record.studentName),
                subtitle: Text('${record.rollNumber} - ${record.className}'),
                trailing: Switch(
                  value: record.status == 'Present',
                  onChanged: (v) => controller.markAttendance(record.studentId, v ? 'Present' : 'Absent'),
                ),
                onTap: () => controller.markAttendance(
                    record.studentId, record.status == 'Present' ? 'Absent' : 'Present'),
              );
            },
          )),
        ]),
      ),
      actions: [TextButton(onPressed: () => Get.back(), child: const Text('Done'))],
    ));
  }

  String? _getAttendanceStatusForDay(DateTime day) {
    for (final record in controller.attendanceRecords) {
      try {
        final d = DateTime.parse(record.date);
        if (d.year == day.year && d.month == day.month && d.day == day.day) {
          return record.status.toLowerCase();
        }
      } catch (_) {}
    }
    return null;
  }

  void _showAttendanceDetails(BuildContext context, DateTime selectedDay) {
    AttendanceRecord? record;
    for (final r in controller.attendanceRecords) {
      try {
        final d = DateTime.parse(r.date);
        if (d.year == selectedDay.year &&
            d.month == selectedDay.month &&
            d.day == selectedDay.day) {
          record = r;
          break;
        }
      } catch (_) {}
    }
    Get.dialog(AlertDialog(
      title: Text(DateFormat('MMMM dd, yyyy').format(selectedDay)),
      content: record != null
          ? Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(
                  record.status == 'Present' ? Icons.check_circle : Icons.cancel,
                  color: record.status == 'Present' ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text('Status: ${record.status}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: record.status == 'Present' ? Colors.green : Colors.red)),
              ]),
              if (record.markedBy.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Marked by: ${record.markedBy}'),
              ],
              if (record.markedAt.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Marked at: ${_formatDate(record.markedAt)}'),
              ],
            ])
          : const Text('No attendance record for this date'),
      actions: [TextButton(onPressed: () => Get.back(), child: const Text('Close'))],
    ));
  }

  List<String> _getEventsForDay(DateTime day) {
    final events = <String>[];
    for (final record in controller.getAllChildrenAttendance()) {
      try {
        final d = DateTime.parse(record['date']);
        if (d.year == day.year && d.month == day.month && d.day == day.day) {
          events.add(record['status']);
        }
      } catch (_) {}
    }
    return events;
  }

  Widget _buildStatItem(String label, String value, Color color, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 12 : 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: isTablet ? 12 : 10,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label,
          style: TextStyle(
              color: const Color(0xFF1A1F36),
              fontSize: 12,
              fontWeight: FontWeight.w500)),
    ]);
  }

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
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:collection/collection.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/attendance_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/permission_wrapper.dart';
import '../widgets/pie_chart_painter.dart';

class AttendanceView extends GetView<ParentAttendanceController> {
  const AttendanceView({super.key});

  // Static observable variables for collapsible sections
  static final _isMonthlyExpanded = false.obs;
  static final _isYearlyExpanded = false.obs;

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final isParent = authController.user.value?.role == 'parent';

    return GetBuilder<ParentAttendanceController>(
      builder: (controller) {
        // For parents, show calendar view instead of the regular attendance view
        if (isParent && !controller.isSpecificStudentView.value) {
          return _buildParentCalendarView(context);
        }

        // Show different views based on context
        if (controller.isSpecificStudentView.value) {
          return Scaffold(

            body: _buildSpecificStudentAttendanceView(context),
          );
        } else if (controller.isParent) {
          return Scaffold(
            body: _buildParentDateWiseAttendanceView(context),
          );
        } else {
          // For teachers, administrators, principals, correspondents - show tabbed view
          
          return DefaultTabController(
            length: controller.canMark ? 2 : 1, // Show 2 tabs if can mark, 1 if view only
            child: Scaffold(
              appBar: AppBar(
                title: Text('Attendance ${_getPermissionLabel()}'),
                bottom: TabBar(
                  tabs: [
                    if (controller.canMark)
                      const Tab(icon: Icon(Icons.how_to_reg), text: 'Mark Daily'),
                    const Tab(icon: Icon(Icons.history), text: 'History'),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  if (controller.canMark)
                    _buildMarkDailyTab(context),
                  _buildHistoryTab(context),
                ],
              ),
            ),
          );
        }
      },
    );
  }

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
                    onPressed: () => _markAllPresent(),
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
                      backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
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

  Widget _buildMarkingContent(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        );
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
              ],
            ),
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
                itemBuilder: (context, index) {
                  final record = controller.attendanceRecords[index];
                  return _buildMarkingRow(context, record, index);
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMarkingTableHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text('Student', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text('Roll No', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text('Class', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text('Section', style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 120, child: Text('Mark Attendance', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildMarkingRow(BuildContext context, AttendanceRecord record, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(record.studentName, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(record.rollNumber)),
          Expanded(child: Text(record.className)),
          Expanded(child: Text(record.section)),
          SizedBox(
            width: 120,
            child: Row(
              children: [
                Radio<String>(
                  value: 'Present',
                  groupValue: record.status,
                  onChanged: (value) {
                    if (value != null) {
                      controller.markAttendance(record.studentId, value);
                    }
                  },
                  activeColor: AppTheme.successGreen,
                ),
                const Text('P', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                Radio<String>(
                  value: 'Absent',
                  groupValue: record.status,
                  onChanged: (value) {
                    if (value != null) {
                      controller.markAttendance(record.studentId, value);
                    }
                  },
                  activeColor: AppTheme.errorRed,
                ),
                const Text('A', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'My Children\'s Attendance',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: controller.loadAttendance,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificStudentAttendanceView(BuildContext context) {
    final now = DateTime.now();
    final _focusedDay = controller.selectedDate.value.obs;
    final _selectedDay = Rxn<DateTime>();
    final _calendarFormat = CalendarFormat.month.obs;
    
    // Filter variables
    final selectedYear = (controller.selectedDate.value.year).obs;
    final selectedMonth = (controller.selectedDate.value.month).obs;

    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryBlue, Colors.indigo.shade600],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.how_to_reg_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${controller.studentNameForView.value}\'s Attendance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'View attendance calendar',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isTablet ? 14 : 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: IconButton(
                  onPressed: controller.loadAttendance,
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 24,
                  ),
                  tooltip: 'Refresh',
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Filters Section
              Container(
                margin: EdgeInsets.all(isTablet ? 20 : 16),
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.8)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.filter_list, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Attendance Filters',
                          style: TextStyle(
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Year and Month Filters
                    Obx(() => Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
                            ),
                            child: DropdownButtonFormField<int>(
                              value: selectedYear.value,
                              decoration: InputDecoration(
                                labelText: 'Year',
                                prefixIcon: Icon(Icons.calendar_today, color: AppTheme.primaryBlue),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              items: List.generate(50, (index) => DateTime.now().year - 25 + index)
                                  .map((year) => DropdownMenuItem(
                                        value: year,
                                        child: Text(year.toString()),
                                      ))
                                  .toList(),
                              onChanged: (year) {
                                if (year != null) {
                                  selectedYear.value = year;
                                  final newDate = DateTime(year, selectedMonth.value, 1);
                                  controller.selectedDate.value = newDate;
                                  _focusedDay.value = newDate;
                                  controller.loadAttendance();
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 120), // Ensure minimum width for month names
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
                            ),
                            child: DropdownButtonFormField<int>(
                              value: selectedMonth.value,
                              isExpanded: true, // Make dropdown fill available width
                              decoration: InputDecoration(
                                labelText: 'Month',
                                prefixIcon: Icon(Icons.date_range, color: AppTheme.primaryBlue),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              items: List.generate(12, (index) => index + 1)
                                  .map((month) => DropdownMenuItem(
                                        value: month,
                                        child: Text(DateFormat('MMMM').format(DateTime(2024, month, 1))),
                                      ))
                                  .toList(),
                              onChanged: (month) {
                                if (month != null) {
                                  selectedMonth.value = month;
                                  final newDate = DateTime(selectedYear.value, month, 1);
                                  controller.selectedDate.value = newDate;
                                  _focusedDay.value = newDate;
                                  controller.loadAttendance();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    )),

                    const SizedBox(height: 16),

                    // Quick Date Selectors
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildQuickDateButton('Today', DateTime.now(), selectedYear, selectedMonth, _focusedDay, controller),
                          const SizedBox(width: 12),
                          _buildQuickDateButton('Yesterday', DateTime.now().subtract(const Duration(days: 1)), selectedYear, selectedMonth, _focusedDay, controller),
                          const SizedBox(width: 12),
                          _buildQuickDateButton('Last Week', DateTime.now().subtract(const Duration(days: 7)), selectedYear, selectedMonth, _focusedDay, controller),
                          const SizedBox(width: 12),
                          _buildQuickDateButton('Last Month', DateTime.now().subtract(const Duration(days: 30)), selectedYear, selectedMonth, _focusedDay, controller),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Monthly Attendance Percentage Card
              Container(
                margin: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, AppTheme.primaryBlue.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  title: Text(
                    'Monthly Attendance Analytics',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  subtitle: Obx(() {
                    final totalDays = controller.presentCount + controller.absentCount;
                    final presentPercentage = controller.attendancePercentage;
                    final absentPercentage = totalDays > 0 ? 100 - presentPercentage : 0.0;
                    return Text(
                      '${DateFormat('MMMM yyyy').format(controller.selectedDate.value)} • ${presentPercentage.toStringAsFixed(0)}% Present • ${absentPercentage.toStringAsFixed(0)}% Absent',
                      style: TextStyle(
                        fontSize: isTablet ? 12 : 10,
                        color: Colors.grey.shade600,
                      ),
                    );
                  }),

                  children: [

                     Padding(
                      padding: EdgeInsets.all(isTablet ? 20 : 16),
                      child: Obx(() {
                        final totalDays = controller.presentCount + controller.absentCount;
                        final presentPercentage = controller.attendancePercentage;
                        final absentPercentage = totalDays > 0 ? 100 - presentPercentage : 0.0;
                        
                        if (totalDays == 0) {
                          return const Text('No data available');
                        }
                        
                        return Row(
                          children: [
                            // Pie Chart without text inside
                            SizedBox(
                              width: isTablet ? 120 : 100,
                              height: isTablet ? 120 : 100,
                              child: CustomPaint(
                                painter: PieChartPainter(
                                  presentPercentage: presentPercentage,
                                  absentPercentage: absentPercentage,
                                  presentColor: AppTheme.successGreen,
                                  absentColor: AppTheme.errorRed,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Percentages beside chart
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: AppTheme.successGreen,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Present: ${presentPercentage.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: isTablet ? 16 : 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.successGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: AppTheme.errorRed,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Absent: ${absentPercentage.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: isTablet ? 16 : 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.errorRed,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildStatItem('Present', '${controller.presentCount}', AppTheme.successGreen, isTablet),
                                      _buildStatItem('Absent', '${controller.absentCount}', AppTheme.errorRed, isTablet),
                                      _buildStatItem('Total', '$totalDays', AppTheme.primaryBlue, isTablet),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Yearly Attendance Percentage Card
              Container(
                margin: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Colors.purple.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  title: Text(
                    'Yearly Attendance Analytics',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  subtitle: Obx(() {
                    final yearlyTotal = controller.yearlyPresentCount + controller.yearlyAbsentCount;
                    final yearlyPresentPercentage = controller.yearlyAttendancePercentage;
                    final yearlyAbsentPercentage = yearlyTotal > 0 ? 100 - yearlyPresentPercentage : 0.0;
                    return Text(
                      '${controller.selectedDate.value.year} • ${yearlyPresentPercentage.toStringAsFixed(0)}% Present • ${yearlyAbsentPercentage.toStringAsFixed(0)}% Absent',
                      style: TextStyle(
                        fontSize: isTablet ? 12 : 10,
                        color: Colors.grey.shade600,
                      ),
                    );
                  }),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(isTablet ? 20 : 16),
                      child: Obx(() {
                        final yearlyTotal = controller.yearlyPresentCount + controller.yearlyAbsentCount;
                        final yearlyPresentPercentage = controller.yearlyAttendancePercentage;
                        final yearlyAbsentPercentage = yearlyTotal > 0 ? 100 - yearlyPresentPercentage : 0.0;

                        if (yearlyTotal == 0) {
                          return const Text('No yearly data available');
                        }

                        return Row(
                          children: [
                            // Pie Chart without text inside
                            SizedBox(
                              width: isTablet ? 120 : 100,
                              height: isTablet ? 120 : 100,
                              child: CustomPaint(
                                painter: PieChartPainter(
                                  presentPercentage: yearlyPresentPercentage,
                                  absentPercentage: yearlyAbsentPercentage,
                                  presentColor: AppTheme.successGreen,
                                  absentColor: AppTheme.errorRed,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Percentages beside chart
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: AppTheme.successGreen,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Present: ${yearlyPresentPercentage.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: isTablet ? 16 : 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.successGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: AppTheme.errorRed,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Absent: ${yearlyAbsentPercentage.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: isTablet ? 16 : 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.errorRed,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildStatItem('Present', '${controller.yearlyPresentCount}', AppTheme.successGreen, isTablet),
                                      _buildStatItem('Absent', '${controller.yearlyAbsentCount}', AppTheme.errorRed, isTablet),
                                      _buildStatItem('Total', '$yearlyTotal', Colors.purple, isTablet),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );

                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Calendar Grid
              Container(
                margin: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Obx(() => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TableCalendar(
                        firstDay: DateTime(1990, 1, 1),
                        lastDay: DateTime(3000, 12, 31),
                        focusedDay: _focusedDay.value,
                        calendarFormat: _calendarFormat.value,
                        selectedDayPredicate: (day) {
                          return _selectedDay.value != null && isSameDay(_selectedDay.value!, day);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          _selectedDay.value = selectedDay;
                          _focusedDay.value = focusedDay;
                          _showAttendanceDetails(context, selectedDay);
                        },
                        onFormatChanged: (format) {
                          if (_calendarFormat.value != format) {
                            _calendarFormat.value = format;
                          }
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay.value = focusedDay;
                          controller.selectedDate.value = focusedDay;
                          selectedYear.value = focusedDay.year;
                          selectedMonth.value = focusedDay.month;
                          // Reload attendance when calendar page changes
                          controller.loadAttendance();
                        },
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          weekendTextStyle: TextStyle(color: AppTheme.errorRed),
                          outsideDaysVisible: false,
                          cellMargin: const EdgeInsets.all(2),
                          cellPadding: const EdgeInsets.all(8),
                          defaultTextStyle: const TextStyle(fontSize: 16),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          leftChevronIcon: Icon(Icons.chevron_left, color: AppTheme.primaryBlue),
                          rightChevronIcon: Icon(Icons.chevron_right, color: AppTheme.primaryBlue),
                          titleTextStyle: TextStyle(
                            color: AppTheme.primaryText,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                            color: AppTheme.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                          weekendStyle: TextStyle(
                            color: AppTheme.errorRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            final status = _getAttendanceStatusForDay(day);
                            final isToday = isSameDay(day, DateTime.now());

                            if (status != null) {
                              return Container(
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: status == 'present'
                                      ? AppTheme.successGreen
                                      : AppTheme.errorRed,
                                  shape: BoxShape.circle,
                                  border: isToday ? Border.all(color: Colors.white, width: 2) : null,
                                ),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            }

                            if (isToday) {
                              return Container(
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            }

                            return null;
                          },
                          todayBuilder: (context, day, focusedDay) {
                            final status = _getAttendanceStatusForDay(day);
                            if (status != null) {
                              return Container(
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: status == 'present'
                                      ? AppTheme.successGreen
                                      : AppTheme.errorRed,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  )),
                ),
              ),

              const SizedBox(height: 16),

              // Legend
              Container(
                margin: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem('Present', AppTheme.successGreen),
                    _buildLegendItem('Absent', AppTheme.errorRed),
                    _buildLegendItem('Today', AppTheme.primaryBlue),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  String? _getAttendanceStatusForDay(DateTime day) {
    for (var record in controller.attendanceRecords) {
      try {
        final recordDate = DateTime.parse(record.date);
        if (recordDate.year == day.year && 
            recordDate.month == day.month && 
            recordDate.day == day.day) {
          return record.status.toLowerCase();
        }
      } catch (e) {
        // Skip invalid dates
      }
    }
    return null;
  }
  
  void _showAttendanceDetails(BuildContext context, DateTime selectedDay) {
    // Find attendance record for selected day
    AttendanceRecord? record;
    for (var r in controller.attendanceRecords) {
      try {
        final recordDate = DateTime.parse(r.date);
        if (recordDate.year == selectedDay.year && 
            recordDate.month == selectedDay.month && 
            recordDate.day == selectedDay.day) {
          record = r;
          break;
        }
      } catch (e) {
        // Skip invalid dates
      }
    }
    
    Get.dialog(
      AlertDialog(
        title: Text(DateFormat('MMMM dd, yyyy').format(selectedDay)),
        content: record != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        record.status == 'Present' ? Icons.check_circle : Icons.cancel,
                        color: record.status == 'Present' ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Status: ${record.status}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: record.status == 'Present' ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  if (record.markedBy.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Marked by: ${record.markedBy}'),
                  ],
                  if (record.markedAt.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Marked at: ${_formatDate(record.markedAt)}'),
                  ],
                ],
              )
            : const Text('No attendance record for this date'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildParentSimpleAttendanceList(BuildContext context) {
    return Obx(() {

      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.myChildren.isEmpty) {
        
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.family_restroom, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No children found'),
            ],
          ),
        );
      }

      // Get all attendance records
      final allRecords = controller.getAllChildrenAttendance();

      if (allRecords.isEmpty) {
        
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_note, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No attendance records found'),
            ],
          ),
        );
      }

      // Sort by date (most recent first)
      allRecords.sort((a, b) => b['date'].compareTo(a['date']));

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: allRecords.length,
        itemBuilder: (context, index) {
          final record = allRecords[index];

          // Find child info for this record
          final child = controller.myChildren.firstWhere(
            (c) => c['id'] == record['studentId'],
            orElse: () => {'name': 'Unknown Child', 'class': 'N/A'},
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: record['status'] == 'present' ? Colors.green : Colors.red,
                child: Icon(
                  record['status'] == 'present' ? Icons.check : Icons.close,
                  color: Colors.white,
                ),
              ),
              title: Text(child['name'] ?? 'Unknown Child'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Class: ${child['class'] ?? 'N/A'}'),
                  Text('Date: ${_formatDate(record['date'])}'),
                ],
              ),
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

      if (dateOnly == today) {
        return 'Today';
      } else if (dateOnly == today.subtract(const Duration(days: 1))) {
        return 'Yesterday';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

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
                    const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Obx(() => InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(controller.selectedDate.value.toString().split(' ')[0]),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          if (controller.userRole != 'teacher') // Teachers see only their classes
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Class', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: controller.selectedClass.value.isEmpty ? null : controller.selectedClass.value,
                        decoration: const InputDecoration(
                          hintText: 'Select Class',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5']
                            .map((cls) => DropdownMenuItem(value: cls, child: Text(cls)))
                            .toList(),
                        onChanged: (value) => controller.selectClass(value ?? ''),
                      ),
                    ],
                  ),
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
                    const Text('Section', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: controller.selectedSection.value.isEmpty ? null : controller.selectedSection.value,
                      decoration: const InputDecoration(
                        hintText: 'Select Section',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Section A', 'Section B', 'Section C']
                          .map((sec) => DropdownMenuItem(value: sec, child: Text(sec)))
                          .toList(),
                      onChanged: (value) => controller.selectSection(value ?? ''),
                    ),
                  ],
                ),
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
                child: Column(
                  children: [
                    const Icon(Icons.how_to_reg, size: 40, color: Colors.green),
                    const SizedBox(height: 10),
                    const Text('Present', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${controller.presentCount}', style: const TextStyle(fontSize: 24, color: Colors.green)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.person_off, size: 40, color: Colors.red),
                    const SizedBox(height: 10),
                    const Text('Absent', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${controller.absentCount}', style: const TextStyle(fontSize: 24, color: Colors.red)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.people, size: 40, color: AppTheme.primaryBlue),
                    const SizedBox(height: 10),
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${controller.totalStudents}', style: const TextStyle(fontSize: 24, color: AppTheme.primaryBlue)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.percent, size: 40, color: Colors.orange),
                    const SizedBox(height: 10),
                    const Text('Percentage', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${controller.attendancePercentage.toStringAsFixed(1)}%', 
                         style: const TextStyle(fontSize: 24, color: Colors.orange)),
                  ],
                ),
              ),
            ),
          ),
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
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.how_to_reg, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No attendance records found'),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Column(
            children: [
              _buildTableHeader(),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.attendanceRecords.length,
                  itemBuilder: (context, index) {
                    final record = controller.attendanceRecords[index];
                    return _buildAttendanceRow(context, record, index);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          const Expanded(flex: 2, child: Text('Student', style: TextStyle(fontWeight: FontWeight.bold))),
          const Expanded(child: Text('Roll No', style: TextStyle(fontWeight: FontWeight.bold))),
          const Expanded(child: Text('Class', style: TextStyle(fontWeight: FontWeight.bold))),
          const Expanded(child: Text('Section', style: TextStyle(fontWeight: FontWeight.bold))),
          const Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
          if (controller.canMark)
            const SizedBox(width: 120, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildAttendanceRow(BuildContext context, AttendanceRecord record, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(record.studentName, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(record.rollNumber)),
          Expanded(child: Text(record.className)),
          Expanded(child: Text(record.section)),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: record.status == 'Present' ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                record.status,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (controller.canMark)
            SizedBox(
              width: 120,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => controller.markAttendance(record.studentId, 'Present'),
                    icon: Icon(
                      Icons.check_circle,
                      color: record.status == 'Present' ? Colors.green : Colors.grey,
                      size: 18,
                    ),
                    tooltip: 'Mark Present',
                  ),
                  IconButton(
                    onPressed: () => controller.markAttendance(record.studentId, 'Absent'),
                    icon: Icon(
                      Icons.cancel,
                      color: record.status == 'Absent' ? Colors.red : Colors.grey,
                      size: 18,
                    ),
                    tooltip: 'Mark Absent',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      controller.selectDate(picked);
    }
  }

  void _showMarkAttendanceDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Mark Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select attendance marking method:'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      _markAllPresent();
                    },
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    label: const Text('Mark All Present'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      _showBulkMarkingDialog(context);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Bulk Marking'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _markAllPresent() {
    for (final record in controller.attendanceRecords) {
      controller.markAttendance(record.studentId, 'Present');
    }
    Get.snackbar('Success', 'All students marked present', backgroundColor: AppTheme.successGreen);
  }

  void _showBulkMarkingDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Bulk Attendance Marking'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: Column(
            children: [
              const Text('Click on student names to toggle attendance:'),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.attendanceRecords.length,
                  itemBuilder: (context, index) {
                    final record = controller.attendanceRecords[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: record.status == 'Present' ? Colors.green : Colors.red,
                        child: Icon(
                          record.status == 'Present' ? Icons.check : Icons.close,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(record.studentName),
                      subtitle: Text('${record.rollNumber} - ${record.className}'),
                      trailing: Switch(
                        value: record.status == 'Present',
                        onChanged: (value) {
                          controller.markAttendance(record.studentId, value ? 'Present' : 'Absent');
                        },
                      ),
                      onTap: () {
                        final newStatus = record.status == 'Present' ? 'Absent' : 'Present';
                        controller.markAttendance(record.studentId, newStatus);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildParentCalendarView(BuildContext context) {
    final now = DateTime.now();
    final _focusedDay = now.obs;
    final _selectedDay = now.obs;
    final _calendarFormat = CalendarFormat.month.obs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Calendar'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Calendar
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Obx(() => TableCalendar(
                    firstDay: DateTime(1990, 1, 1),
                    lastDay: DateTime(3000, 12, 31),
                    focusedDay: _focusedDay.value,
                    calendarFormat: _calendarFormat.value,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay.value, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      if (!isSameDay(_selectedDay.value, selectedDay)) {
                        _selectedDay.value = selectedDay;
                        _focusedDay.value = focusedDay;
                      }
                    },
                    onFormatChanged: (format) {
                      if (_calendarFormat.value != format) {
                        _calendarFormat.value = format;
                      }
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay.value = focusedDay;
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      weekendTextStyle: TextStyle(color: AppTheme.errorRed),
                      outsideDaysVisible: false,
                      cellMargin: const EdgeInsets.all(2),
                      cellPadding: const EdgeInsets.all(8),
                      defaultTextStyle: const TextStyle(fontSize: 16),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      leftChevronIcon: Icon(Icons.chevron_left, color: AppTheme.primaryBlue),
                      rightChevronIcon: Icon(Icons.chevron_right, color: AppTheme.primaryBlue),
                      titleTextStyle: TextStyle(
                        color: AppTheme.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        color: AppTheme.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                      weekendStyle: TextStyle(
                        color: AppTheme.errorRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        final events = _getEventsForDay(day);
                        final isToday = isSameDay(day, DateTime.now());
                        
                        if (events.isNotEmpty) {
                          final status = events.first as String;
                          return Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: status == 'present' 
                                  ? AppTheme.successGreen
                                  : AppTheme.errorRed,
                              shape: BoxShape.circle,
                              border: isToday ? Border.all(color: Colors.white, width: 2) : null,
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        }
                        
                        if (isToday) {
                          return Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        }
                        
                        return null;
                      },
                      todayBuilder: (context, day, focusedDay) {
                        final events = _getEventsForDay(day);
                        if (events.isNotEmpty) {
                          final status = events.first as String;
                          return Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: status == 'present' 
                                  ? AppTheme.successGreen
                                  : AppTheme.errorRed,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        }
                        return Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )),
                ),
              ),
            ),

            // Analytics Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Analytics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    final totalDays = controller.presentCount + controller.absentCount;
                    return Row(
                      children: [
                        Expanded(
                          child: _buildAnalyticsItem(
                            'Total Working Days',
                            '$totalDays',
                            Icons.calendar_today,
                            AppTheme.primaryBlue,
                          ),
                        ),
                        Expanded(
                          child: _buildAnalyticsItem(
                            'Days Present',
                            '${controller.presentCount}',
                            Icons.check_circle,
                            AppTheme.successGreen,
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 12),
                  Obx(() => Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsItem(
                          'Days Absent',
                          '${controller.absentCount}',
                          Icons.cancel,
                          AppTheme.errorRed,
                        ),
                      ),
                      Expanded(
                        child: _buildAnalyticsItem(
                          'Attendance %',
                          '${controller.attendancePercentage.toStringAsFixed(1)}%',
                          Icons.percent,
                          controller.attendancePercentage >= 85 
                              ? AppTheme.successGreen 
                              : controller.attendancePercentage >= 75 
                                  ? Colors.orange 
                                  : AppTheme.errorRed,
                        ),
                      ),
                    ],
                  )),
                ],
              ),
            ),

            // Legend
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem('Present', AppTheme.successGreen),
                  _buildLegendItem('Absent', AppTheme.errorRed),
                  _buildLegendItem('Today', AppTheme.primaryBlue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 12 : 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: isTablet ? 12 : 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.primaryText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickDateButton(String label, DateTime date, RxInt selectedYear, RxInt selectedMonth, Rx<DateTime> focusedDay, ParentAttendanceController controller) {
    return SizedBox(
      width: 80, // Fixed width to prevent infinite width constraints
      child: ElevatedButton(
        onPressed: () {
          selectedYear.value = date.year;
          selectedMonth.value = date.month;
          final newDate = DateTime(date.year, date.month, date.day);
          controller.selectedDate.value = newDate;
          focusedDay.value = newDate;
          controller.loadAttendance();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryBlue,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.3)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          minimumSize: const Size(80, 36), // Ensure minimum size
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  List<String> _getEventsForDay(DateTime day) {
    final events = <String>[];
    final allRecords = controller.getAllChildrenAttendance();
    
    // Check if any child has attendance record for this day
    for (final record in allRecords) {
      try {
        final recordDate = DateTime.parse(record['date']);
        if (recordDate.year == day.year && 
            recordDate.month == day.month && 
            recordDate.day == day.day) {
          events.add(record['status']);
        }
      } catch (e) {
        // Skip invalid dates
      }
    }
    
    return events;
  }

  String _getPermissionLabel() {
    switch (controller.permission) {
      case 'viewOnly': return '(View Only)';
      case 'markAndView': return '(Mark & View)';
      case 'ownChildrenOnly': return '(Own Children)';
      default: return '';
    }
  }
}
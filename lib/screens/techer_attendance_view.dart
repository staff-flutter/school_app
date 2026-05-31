import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/parent_attendance_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/widgets/pie_chart_painter.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

/// Attendance page shown to TEACHERS.
/// Two tabs: "Mark Daily" and "History".
class TeacherAttendanceView extends GetView<ParentAttendanceController> {
  const TeacherAttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FB),
        appBar: _buildAppBar(context),
        body: TabBarView(
          children: [
            _MarkDailyTab(controller: controller),
            _HistoryTab(controller: controller),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      // leading: IconButton(
      //   icon: const Icon(Icons.arrow_back_ios_new,
      //       size: 18, color: Color(0xFF1A2A3A)),
      //   onPressed: () => Get.back(),
      // ),
      title: const Text(
        'Attendance',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A2A3A),
        ),
      ),
      actions: [
        IconButton(
          onPressed: controller.loadAttendance,
          icon: const Icon(Icons.refresh_rounded,
              color: Color(0xFF1A2A3A), size: 22),
          tooltip: 'Refresh',
        ),
      ],
      bottom: const TabBar(
        labelColor: Color(0xFF185FA5),
        unselectedLabelColor: Color(0xFF90A4AE),
        indicatorColor: Color(0xFF185FA5),
        indicatorWeight: 2.5,
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
        TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: [
          Tab(
            icon: Icon(Icons.how_to_reg_rounded, size: 18),
            text: 'Mark Daily',
            iconMargin: EdgeInsets.only(bottom: 2),
          ),
          Tab(
            icon: Icon(Icons.history_rounded, size: 18),
            text: 'History',
            iconMargin: EdgeInsets.only(bottom: 2),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK DAILY TAB
// ─────────────────────────────────────────────────────────────────────────────

class _MarkDailyTab extends StatelessWidget {
  final ParentAttendanceController controller;
  const _MarkDailyTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FiltersCard(controller: controller, showDatePickerbool: true),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Mark All Present',
                  color: const Color(0xFF3B6D11),
                  bgColor: const Color(0xFFEAF3DE),
                  onTap: () {
                    for (final r in controller.attendanceRecords) {
                      controller.markAttendance(r.studentId, 'Present');
                    }
                    Get.snackbar(
                      'Done',
                      'All students marked present',
                      backgroundColor: const Color(0xFFEAF3DE),
                      colorText: const Color(0xFF3B6D11),
                      snackPosition: SnackPosition.TOP,
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.edit_note_rounded,
                  label: 'Bulk Mark',
                  color: const Color(0xFF185FA5),
                  bgColor: const Color(0xFFE6F1FB),
                  onTap: () => _showBulkDialog(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: _MarkingList(controller: controller)),
      ],
    );
  }

  void _showBulkDialog(BuildContext context) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Bulk Attendance',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 500,
        height: 380,
        child: Obx(() => ListView.builder(
          itemCount: controller.attendanceRecords.length,
          itemBuilder: (_, i) {
            final r = controller.attendanceRecords[i];
            final isPresent = r.status == 'Present';
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor:
                isPresent ? const Color(0xFFEAF3DE) : const Color(0xFFFCEBEB),
                child: Text(
                  r.studentName.isNotEmpty
                      ? r.studentName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isPresent
                        ? const Color(0xFF3B6D11)
                        : const Color(0xFFA32D2D),
                  ),
                ),
              ),
              title: Text(r.studentName,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
              subtitle: Text('${r.rollNumber} · ${r.className}',
                  style: const TextStyle(fontSize: 11)),
              trailing: Switch.adaptive(
                value: isPresent,
                activeColor: const Color(0xFF3B6D11),
                onChanged: (v) => controller.markAttendance(
                    r.studentId, v ? 'Present' : 'Absent'),
              ),
              onTap: () => controller.markAttendance(
                  r.studentId,
                  r.status == 'Present' ? 'Absent' : 'Present'),
            );
          },
        )),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Done',
              style: TextStyle(color: Color(0xFF185FA5))),
        ),
      ],
    ));
  }
}

class _MarkingList extends StatelessWidget {
  final ParentAttendanceController controller;
  const _MarkingList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.attendanceRecords.isEmpty) {
        return const _EmptyState(
          icon: Icons.how_to_reg_outlined,
          title: 'No students loaded',
          subtitle: 'Select a class and section above to load students',
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
        itemCount: controller.attendanceRecords.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) =>
            _MarkingCard(record: controller.attendanceRecords[i],
                controller: controller),
      );
    });
  }
}

class _MarkingCard extends StatelessWidget {
  final AttendanceRecord record;
  final ParentAttendanceController controller;
  const _MarkingCard({required this.record, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isPresent = record.status == 'Present';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPresent
              ? const Color(0xFFC0DD97)
              : const Color(0xFFF7C1C1),
          width: 0.5,
        ),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isPresent
              ? const Color(0xFFEAF3DE)
              : const Color(0xFFFCEBEB),
          child: Text(
            record.studentName.isNotEmpty
                ? record.studentName[0].toUpperCase()
                : '?',
            style: TextStyle(
              color: isPresent
                  ? const Color(0xFF3B6D11)
                  : const Color(0xFFA32D2D),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(record.studentName,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2A3A)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('${record.rollNumber} · ${record.className} ${record.section}',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF90A4AE))),
          ]),
        ),
        const SizedBox(width: 10),
        Row(children: [
          _MarkButton(
            icon: Icons.check_circle_rounded,
            color: isPresent
                ? const Color(0xFF3B6D11)
                : const Color(0xFFD3D1C7),
            onTap: () =>
                controller.markAttendance(record.studentId, 'Present'),
          ),
          const SizedBox(width: 8),
          _MarkButton(
            icon: Icons.cancel_rounded,
            color: !isPresent
                ? const Color(0xFFA32D2D)
                : const Color(0xFFD3D1C7),
            onTap: () =>
                controller.markAttendance(record.studentId, 'Absent'),
          ),
        ]),
      ]),
    );
  }
}

class _MarkButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MarkButton(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 28),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HISTORY TAB  (shared between Teacher and Vice Principal)
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final ParentAttendanceController controller;
  final bool canMark;
  const _HistoryTab({required this.controller, this.canMark = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FiltersCard(controller: controller, showDatePickerbool: true),
        _StatsRow(controller: controller),
        const SizedBox(height: 8),
        Expanded(child: _AttendanceList(controller: controller, canMark: canMark)),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final ParentAttendanceController controller;
  const _StatsRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(children: [
        _StatCard(
          icon: Icons.person_outline_rounded,
          label: 'Present',
          value: '${controller.presentCount}',
          iconColor: const Color(0xFF3B6D11),
          bgColor: const Color(0xFFEAF3DE),
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: Icons.person_off_outlined,
          label: 'Absent',
          value: '${controller.absentCount}',
          iconColor: const Color(0xFFA32D2D),
          bgColor: const Color(0xFFFCEBEB),
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: Icons.groups_outlined,
          label: 'Total',
          value: '${controller.totalStudents}',
          iconColor: const Color(0xFF185FA5),
          bgColor: const Color(0xFFE6F1FB),
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: Icons.pie_chart_outline_rounded,
          label: 'Rate',
          value:
          '${controller.attendancePercentage.toStringAsFixed(0)}%',
          iconColor: const Color(0xFF854F0B),
          bgColor: const Color(0xFFFAEEDA),
        ),
      ]),
    ));
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color bgColor;
  const _StatCard(
      {required this.icon,
        required this.label,
        required this.value,
        required this.iconColor,
        required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8EDF2), width: 0.5),
        ),
        child: Column(children: [
          Container(
            width: 32,
            height: 32,
            decoration:
            BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: iconColor)),
          const SizedBox(height: 1),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF90A4AE),
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

class _AttendanceList extends StatelessWidget {
  final ParentAttendanceController controller;
  final bool canMark;
  const _AttendanceList(
      {required this.controller, required this.canMark});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.attendanceRecords.isEmpty) {
        return const _EmptyState(
          icon: Icons.history_edu_outlined,
          title: 'No records found',
          subtitle:
          'Select a class and section to view attendance records',
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
        itemCount: controller.attendanceRecords.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) => _AttendanceCard(
          record: controller.attendanceRecords[i],
          controller: controller,
          canMark: canMark,
        ),
      );
    });
  }
}

class _AttendanceCard extends StatelessWidget {
  final AttendanceRecord record;
  final ParentAttendanceController controller;
  final bool canMark;
  const _AttendanceCard(
      {required this.record,
        required this.controller,
        required this.canMark});

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
        const SizedBox(width: 10),
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
        if (canMark) ...[
          const SizedBox(width: 10),
          Row(children: [
            _MarkButton(
              icon: Icons.check_circle_rounded,
              color: isPresent
                  ? const Color(0xFF3B6D11)
                  : const Color(0xFFD3D1C7),
              onTap: () =>
                  controller.markAttendance(record.studentId, 'Present'),
            ),
            const SizedBox(width: 6),
            _MarkButton(
              icon: Icons.cancel_rounded,
              color: !isPresent
                  ? const Color(0xFFA32D2D)
                  : const Color(0xFFD3D1C7),
              onTap: () =>
                  controller.markAttendance(record.studentId, 'Absent'),
            ),
          ]),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _FiltersCard extends StatelessWidget {
  final ParentAttendanceController controller;
  final bool showDatePickerbool;
  const _FiltersCard(
      {required this.controller, this.showDatePickerbool = false});

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
        Row(children: [
          // Date picker
          Expanded(
            child: Obx(() => GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: controller.selectedDate.value,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) controller.selectDate(picked);
              },
              child: _FilterChip(
                icon: Icons.calendar_today_outlined,
                label: DateFormat('dd MMM yyyy')
                    .format(controller.selectedDate.value),
                isActive: true,
              ),
            )),
          ),
          const SizedBox(width: 8),
          // Class
          if (controller.userRole != 'teacher')
            Expanded(
              child: DropdownButtonHideUnderline(
                child: _FilterDropdown<String>(
                  icon: Icons.school_outlined,
                  hint: 'Class',
                  value: controller.selectedClass.value.isEmpty
                      ? null
                      : controller.selectedClass.value,
                  items: ['Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5'],
                  onChanged: (v) => controller.selectClass(v ?? ''),
                ),
              ),
            ),
          if (controller.userRole != 'teacher') const SizedBox(width: 8),
          // Section
          Expanded(
            child: _FilterDropdown<String>(
              icon: Icons.people_outline_rounded,
              hint: 'Section',
              value: controller.selectedSection.value.isEmpty
                  ? null
                  : controller.selectedSection.value,
              items: ['Section A', 'Section B', 'Section C'],
              onChanged: (v) => controller.selectSection(v ?? ''),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        // Quick chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _QuickChip(label: 'Today', date: DateTime.now(), controller: controller),
            const SizedBox(width: 6),
            _QuickChip(
                label: 'Yesterday',
                date: DateTime.now().subtract(const Duration(days: 1)),
                controller: controller),
            const SizedBox(width: 6),
            _QuickChip(
                label: 'Last 7 days',
                date: DateTime.now().subtract(const Duration(days: 7)),
                controller: controller),
            const SizedBox(width: 6),
            _QuickChip(
                label: 'This month',
                date: DateTime(DateTime.now().year, DateTime.now().month, 1),
                controller: controller),
          ]),
        ),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  const _FilterChip(
      {required this.icon, required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE6F1FB) : const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? const Color(0xFFB5D4F4) : const Color(0xFFE8EDF2),
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

class _FilterDropdown<T> extends StatelessWidget {
  final IconData icon;
  final String hint;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  const _FilterDropdown(
      {required this.icon,
        required this.hint,
        required this.value,
        required this.items,
        required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8EDF2), width: 0.5),
      ),
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
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            size: 16, color: Color(0xFF90A4AE)),
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A2A3A)),
        items: items
            .map((i) => DropdownMenuItem<T>(
            value: i, child: Text(i.toString())))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final DateTime date;
  final ParentAttendanceController controller;
  const _QuickChip(
      {required this.label,
        required this.date,
        required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        controller.selectedDate.value = date;
        controller.loadAttendance();
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon,
        required this.label,
        required this.color,
        required this.bgColor,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: color.withOpacity(0.25), width: 0.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState(
      {required this.icon,
        required this.title,
        required this.subtitle});

  @override
  Widget build(BuildContext context) {
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
              border:
              Border.all(color: const Color(0xFFE8EDF2), width: 0.5),
            ),
            child: Icon(icon, size: 28, color: const Color(0xFF90A4AE)),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2A3A))),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF90A4AE),
                  height: 1.5)),
        ]),
      ),
    );
  }
}
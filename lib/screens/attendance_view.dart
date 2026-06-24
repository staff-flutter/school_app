import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/parent_attendance_controller.dart';
import 'package:intl/intl.dart';

class AttendanceView extends GetView<ParentAttendanceController> {
  const AttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _VPFiltersCard(controller: controller),
          _VPStatsRow(controller: controller),
          const SizedBox(height: 8),
          Expanded(child: _VPAttendanceList(controller: controller)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTERS  — every reactive read is inside its own Obx
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

        // ── Date picker (already had Obx — keep it) ──────────────────────
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

        // ── Class + Section dropdowns — each wrapped in its own Obx ──────
        Row(children: [
          Expanded(
            // ✅ Obx wraps the dropdown so .value reads happen inside a
            //    reactive scope and rebuilds are scheduled safely.
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

        // ── Quick date chips ─────────────────────────────────────────────
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
                date: DateTime(
                    DateTime.now().year, DateTime.now().month, 1),
                controller: controller),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small UI helpers (unchanged)
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
        color: isActive ? const Color(0xFFE6F1FB) : const Color(0xFFF4F6FB),
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
        // ✅ Use WidgetsBinding so the observable assignment happens
        //    after the current build frame — prevents markNeedsBuild
        //    being called during build when a chip is tapped mid-frame.
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
          border: Border.all(color: const Color(0xFFB5D4F4), width: 0.5),
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
// STATS ROW (unchanged — already correctly wrapped in Obx)
// ─────────────────────────────────────────────────────────────────────────────

class _VPStatsRow extends StatelessWidget {
  final ParentAttendanceController controller;
  const _VPStatsRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pct = controller.attendancePercentage;
      final pctColor = pct >= 85
          ? const Color(0xFF3B6D11)
          : pct >= 75
          ? const Color(0xFF854F0B)
          : const Color(0xFFA32D2D);
      final pctBg = pct >= 85
          ? const Color(0xFFEAF3DE)
          : pct >= 75
          ? const Color(0xFFFAEEDA)
          : const Color(0xFFFCEBEB);

      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        child: Row(children: [
          _VPStatCard(
            icon: Icons.person_outline_rounded,
            label: 'Present',
            value: '${controller.presentCount}',
            iconColor: const Color(0xFF3B6D11),
            bgColor: const Color(0xFFEAF3DE),
          ),
          const SizedBox(width: 8),
          _VPStatCard(
            icon: Icons.person_off_outlined,
            label: 'Absent',
            value: '${controller.absentCount}',
            iconColor: const Color(0xFFA32D2D),
            bgColor: const Color(0xFFFCEBEB),
          ),
          const SizedBox(width: 8),
          _VPStatCard(
            icon: Icons.groups_outlined,
            label: 'Total',
            value: '${controller.totalStudents}',
            iconColor: const Color(0xFF185FA5),
            bgColor: const Color(0xFFE6F1FB),
          ),
          const SizedBox(width: 8),
          _VPStatCard(
            icon: Icons.pie_chart_outline_rounded,
            label: 'Rate',
            value: '${pct.toStringAsFixed(0)}%',
            iconColor: pctColor,
            bgColor: pctBg,
          ),
        ]),
      );
    });
  }
}

class _VPStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color bgColor;
  const _VPStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.bgColor,
  });

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

// ─────────────────────────────────────────────────────────────────────────────
// ATTENDANCE LIST (unchanged — already correctly wrapped in Obx)
// ─────────────────────────────────────────────────────────────────────────────

class _VPAttendanceList extends StatelessWidget {
  final ParentAttendanceController controller;
  const _VPAttendanceList({required this.controller});

  @override
  Widget build(BuildContext context) {
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
}

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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
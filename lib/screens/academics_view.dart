import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/academics_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/controllers/school_controller.dart';

class AcademicsView extends StatefulWidget {
  const AcademicsView({super.key});

  @override
  State<AcademicsView> createState() => _AcademicsViewState();
}

class _AcademicsViewState extends State<AcademicsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AcademicsController controller;
  late SchoolController schoolController;

  @override
  void initState() {
    super.initState();
    // 1. TabController first — needs vsync ready
    _tabController = TabController(length: 4, vsync: this);

    // 2. Lazily register AcademicsController if not already done
    if (!Get.isRegistered<AcademicsController>()) {
      Get.put(AcademicsController());
    }
    if (!Get.isRegistered<SchoolController>()) {
      Get.put(SchoolController());
    }
    controller = Get.find<AcademicsController>();

    // 3. SchoolController must already be registered by the sidebar
    schoolController = Get.find<SchoolController>();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academics'),
        bottom: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          controller: _tabController,
          labelStyle: const TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12.0),
          tabs: const [
            Tab(text: 'Subjects', icon: Icon(Icons.book)),
            Tab(text: 'Timetable', icon: Icon(Icons.schedule)),
            Tab(text: 'Exams', icon: Icon(Icons.quiz)),
            Tab(text: 'Results', icon: Icon(Icons.grade)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubjectsTab(context),
          _buildTimetableTab(context),
          _buildExamsTab(context),
          _buildResultsTab(context),
        ],
      ),
    );
  }

  // ── Subjects Tab ────────────────────────────────────────────────────────────

  Widget _buildSubjectsTab(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() {
                final school = schoolController.selectedSchool.value;
                return Text(
                  school?.name ?? 'No school selected',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                );
              }),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Expanded(
                    child: Text('Subjects', style: TextStyle(fontSize: 17)),
                  ),
                  SizedBox(
                    width: 140,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddSubjectDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'Add Subject',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.subjects.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.book, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No subjects found'),
                    SizedBox(height: 8),
                    Text(
                      'Add subjects to get started',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: controller.subjects.length,
              itemBuilder: (context, index) {
                final subject = controller.subjects[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.book, color: AppTheme.primaryBlue),
                    ),
                    title: Text(subject.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Code: ${subject.code}'),
                        Text('Teacher: ${subject.teacher}'),
                        Text('Class: ${subject.className}-${subject.section}'),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditSubjectDialog(context, subject);
                        } else if (value == 'delete') {
                          _showDeleteSubjectConfirmation(context, subject);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  // ── Timetable Tab ───────────────────────────────────────────────────────────

  Widget _buildTimetableTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final school = schoolController.selectedSchool.value;
            return Text(
              school != null ? '${school.name} — Timetable' : 'Timetable',
              style: const TextStyle(fontSize: 12,color: Colors.grey,),
            );
          }),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (controller.timetable.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No timetable found'),
                    ],
                  ),
                );
              }
              final grouped = <String, List<TimetableEntry>>{};
              for (final entry in controller.timetable) {
                grouped.putIfAbsent(entry.day, () => []).add(entry);
              }
              return ListView.builder(
                itemCount: grouped.keys.length,
                itemBuilder: (context, index) {
                  final day = grouped.keys.elementAt(index);
                  final entries = grouped[day]!;
                  return Card(
                    child: ExpansionTile(
                      title: Text(day,
                          style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                      children: entries
                          .map((e) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryBlue,
                          child: Text(e.period),
                        ),
                        title: Text(e.subject),
                        subtitle: Text('${e.time} | ${e.teacher}'),
                      ))
                          .toList(),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Exams Tab ───────────────────────────────────────────────────────────────

  Widget _buildExamsTab(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() {
                final school = schoolController.selectedSchool.value;
                return Text(
                  school?.name ?? 'No school selected',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                );
              }),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Expanded(
                    child: Text('Scheduled Exams',
                        style: TextStyle(fontSize: 17)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddExamDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Schedule Exam',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.exams.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.quiz, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No exams scheduled'),
                    SizedBox(height: 8),
                    Text('Schedule exams to get started',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: controller.exams.length,
              itemBuilder: (context, index) {
                final exam = controller.exams[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.mathOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.quiz, color: AppTheme.mathOrange),
                    ),
                    title: Text(exam.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Subject: ${exam.subject}'),
                        Text('Date: ${exam.date} at ${exam.time}'),
                        Text(
                            'Duration: ${exam.duration} | Marks: ${exam.totalMarks}'),
                        Text('Class: ${exam.className}-${exam.section}'),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditExamDialog(context, exam);
                        } else if (value == 'delete') {
                          _showDeleteExamConfirmation(context, exam);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  // ── Results Tab ─────────────────────────────────────────────────────────────

  Widget _buildResultsTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Exam Results', style: TextStyle(fontSize: 17)),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (controller.results.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.grade, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No results found'),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: controller.results.length,
                itemBuilder: (context, index) {
                  final result = controller.results[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getGradeColor(result.grade),
                        child: Text(
                          result.grade,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(result.studentName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Subject: ${result.subject}'),
                          Text(
                              'Marks: ${result.marksObtained}/${result.totalMarks}'),
                          Text(
                              'Percentage: ${result.percentage.toStringAsFixed(1)}%'),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getGradeColor(result.grade).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          result.grade,
                          style: TextStyle(
                            color: _getGradeColor(result.grade),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return AppTheme.successGreen;
      case 'B+':
      case 'B':
        return AppTheme.primaryBlue;
      case 'C+':
      case 'C':
        return AppTheme.warningYellow;
      default:
        return AppTheme.errorRed;
    }
  }

  // ── Subject Dialogs ─────────────────────────────────────────────────────────

  void _showAddSubjectDialog(BuildContext context) =>
      _showSubjectForm(context, null);

  void _showEditSubjectDialog(BuildContext context, Subject subject) =>
      _showSubjectForm(context, subject);

  void _showSubjectForm(BuildContext context, Subject? subject) {
    final nameCtrl = TextEditingController(text: subject?.name ?? '');
    final codeCtrl = TextEditingController(text: subject?.code ?? '');
    final teacherCtrl = TextEditingController(text: subject?.teacher ?? '');
    final selectedClassId = (subject?.className ?? '').obs;
    final selectedSection = (subject?.section ?? 'A').obs;

    Get.dialog(
      AlertDialog(
        title: Text(subject == null ? 'Add Subject' : 'Edit Subject'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Subject Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Subject Code'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: teacherCtrl,
                decoration: const InputDecoration(labelText: 'Teacher Name'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      final classes = schoolController.classes;
                      if (classes.isNotEmpty &&
                          !classes.any((c) => c.id == selectedClassId.value)) {
                        selectedClassId.value = classes.first.id;
                      }
                      return DropdownButtonFormField<String>(
                        value: classes.any(
                                (c) => c.id == selectedClassId.value)
                            ? selectedClassId.value
                            : null,
                        decoration:
                        const InputDecoration(labelText: 'Class'),
                        hint: const Text('Select Class'),
                        items: classes
                            .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) selectedClassId.value = v;
                        },
                      );
                    }),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(() => DropdownButtonFormField<String>(
                      value: selectedSection.value,
                      decoration:
                      const InputDecoration(labelText: 'Section'),
                      items: ['A', 'B', 'C', 'D']
                          .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text('Section $s'),
                      ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) selectedSection.value = v;
                      },
                    )),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newSubject = Subject(
                id: subject?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameCtrl.text,
                code: codeCtrl.text,
                teacher: teacherCtrl.text,
                className: selectedClassId.value,
                section: selectedSection.value,
              );
              if (subject == null) {
                controller.addSubject(newSubject);
              } else {
                controller.updateSubject(newSubject);
              }
              Get.back();
            },
            child: Text(subject == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSubjectConfirmation(BuildContext context, Subject subject) {
    Get.dialog(AlertDialog(
      title: const Text('Delete Subject'),
      content: Text('Are you sure you want to delete ${subject.name}?'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            controller.deleteSubject(subject.id);
            Get.back();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ));
  }

  // ── Exam Dialogs ────────────────────────────────────────────────────────────

  void _showAddExamDialog(BuildContext context) =>
      _showExamForm(context, null);

  void _showEditExamDialog(BuildContext context, Exam exam) =>
      _showExamForm(context, exam);

  void _showExamForm(BuildContext context, Exam? exam) {
    final nameCtrl = TextEditingController(text: exam?.name ?? '');
    final subjectCtrl = TextEditingController(text: exam?.subject ?? '');
    final dateCtrl = TextEditingController(text: exam?.date ?? '');
    final timeCtrl = TextEditingController(text: exam?.time ?? '');
    final durationCtrl = TextEditingController(text: exam?.duration ?? '');
    final marksCtrl =
    TextEditingController(text: exam?.totalMarks.toString() ?? '');
    final selectedClassId = (exam?.className ?? '').obs;
    final selectedSection = (exam?.section ?? 'A').obs;

    Get.dialog(
      AlertDialog(
        title: Text(exam == null ? 'Schedule Exam' : 'Edit Exam'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Exam Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: subjectCtrl,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dateCtrl,
                decoration:
                const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeCtrl,
                decoration: const InputDecoration(labelText: 'Time'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationCtrl,
                decoration: const InputDecoration(labelText: 'Duration'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: marksCtrl,
                decoration: const InputDecoration(labelText: 'Total Marks'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      final classes = schoolController.classes;
                      if (classes.isNotEmpty &&
                          !classes.any((c) => c.id == selectedClassId.value)) {
                        selectedClassId.value = classes.first.id;
                      }
                      return DropdownButtonFormField<String>(
                        value: classes.any(
                                (c) => c.id == selectedClassId.value)
                            ? selectedClassId.value
                            : null,
                        decoration:
                        const InputDecoration(labelText: 'Class'),
                        hint: const Text('Select Class'),
                        items: classes
                            .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) selectedClassId.value = v;
                        },
                      );
                    }),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(() => DropdownButtonFormField<String>(
                      value: selectedSection.value,
                      decoration:
                      const InputDecoration(labelText: 'Section'),
                      items: ['A', 'B', 'C', 'D']
                          .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text('Section $s'),
                      ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) selectedSection.value = v;
                      },
                    )),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newExam = Exam(
                id: exam?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameCtrl.text,
                subject: subjectCtrl.text,
                date: dateCtrl.text,
                time: timeCtrl.text,
                duration: durationCtrl.text,
                totalMarks: int.tryParse(marksCtrl.text) ?? 100,
                className: selectedClassId.value,
                section: selectedSection.value,
              );
              if (exam == null) {
                controller.addExam(newExam);
              } else {
                controller.updateExam(newExam);
              }
              Get.back();
            },
            child: Text(exam == null ? 'Schedule' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteExamConfirmation(BuildContext context, Exam exam) {
    Get.dialog(AlertDialog(
      title: const Text('Delete Exam'),
      content: Text('Are you sure you want to delete ${exam.name}?'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            controller.deleteExam(exam.id);
            Get.back();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ));
  }
}
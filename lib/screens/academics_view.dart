import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/academics_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';

class AcademicsView extends GetView<AcademicsController> {
  AcademicsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Block access for accountant role
    // if (!RolePermissions.canAccessModule('classes')) {
    //   return Scaffold(
    //     appBar: AppBar(title: const Text('Access Denied')),
    //     body: const Center(
    //       child: Column(
    //         mainAxisAlignment: MainAxisAlignment.center,
    //         children: [
    //           Icon(Icons.block, size: 64, color: Colors.red),
    //           SizedBox(height: 16),
    //           Text('You do not have permission to access this module.'),
    //         ],
    //       ),
    //     ),
    //   );
    // }
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Academics'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Subjects', icon: Icon(Icons.book)),
              Tab(text: 'Timetable', icon: Icon(Icons.schedule)),
              Tab(text: 'Exams', icon: Icon(Icons.quiz)),
              Tab(text: 'Results', icon: Icon(Icons.grade)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSubjectsTab(context),
            _buildTimetableTab(context),
            _buildExamsTab(context),
            _buildResultsTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsTab(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Subjects',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              SizedBox(
                width: 140,
                child: ElevatedButton.icon(
                  onPressed: ()=>_showAddSubjectDialog(context) ,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Subject'),
                ),
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
                    Text('Add subjects to get started', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }
            
            return ListView.builder(
            itemCount: controller.subjects.length,
            itemBuilder: (context, index) {
              final subject = controller.subjects[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                      switch (value) {
                        case 'edit':
                          _showEditSubjectDialog(context, subject);
                          break;
                        case 'delete':
                          _showDeleteSubjectConfirmation(context, subject);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      // if (RolePermissions.canEdit('class'))
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      // if (RolePermissions.canDelete('class'))
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ) ,
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

  Widget _buildTimetableTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Class 10-A Timetable',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              final groupedTimetable = <String, List<TimetableEntry>>{};
              for (var entry in controller.timetable) {
                if (!groupedTimetable.containsKey(entry.day)) {
                  groupedTimetable[entry.day] = [];
                }
                groupedTimetable[entry.day]!.add(entry);
              }

              return ListView.builder(
                itemCount: groupedTimetable.keys.length,
                itemBuilder: (context, index) {
                  final day = groupedTimetable.keys.elementAt(index);
                  final entries = groupedTimetable[day]!;
                  
                  return Card(
                    child: ExpansionTile(
                      title: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
                      children: entries.map((entry) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryBlue,
                          child: Text(entry.period),
                        ),
                        title: Text(entry.subject),
                        subtitle: Text('${entry.time} | ${entry.teacher}'),
                      )).toList(),
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

  Widget _buildExamsTab(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Scheduled Exams',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddExamDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Schedule Exam'),
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
                    Text('Schedule exams to get started', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }
            
            return ListView.builder(
            itemCount: controller.exams.length,
            itemBuilder: (context, index) {
              final exam = controller.exams[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                      Text('Duration: ${exam.duration} | Marks: ${exam.totalMarks}'),
                      Text('Class: ${exam.className}-${exam.section}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditExamDialog(context, exam);
                          break;
                        case 'delete':
                          _showDeleteExamConfirmation(context, exam);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );}),
        ),
      ],
    );
  }

  Widget _buildResultsTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exam Results',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() => ListView.builder(
              itemCount: controller.results.length,
              itemBuilder: (context, index) {
                final result = controller.results[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getGradeColor(result.grade),
                      child: Text(
                        result.grade,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(result.studentName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Subject: ${result.subject}'),
                        Text('Marks: ${result.marksObtained}/${result.totalMarks}'),
                        Text('Percentage: ${result.percentage.toStringAsFixed(1)}%'),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            )),
          ),
        ],
      ),
    );
  }

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

  void _showAddSubjectDialog(BuildContext context) {
    _showSubjectForm(context, null);
  }

  void _showEditSubjectDialog(BuildContext context, Subject subject) {
    _showSubjectForm(context, subject);
  }

  void _showSubjectForm(BuildContext context, Subject? subject) {
    final nameController = TextEditingController(text: subject?.name ?? '');
    final codeController = TextEditingController(text: subject?.code ?? '');
    final teacherController = TextEditingController(text: subject?.teacher ?? '');
    String selectedClass = subject?.className ?? '10';
    String selectedSection = subject?.section ?? 'A';

    Get.dialog(
      AlertDialog(
        title: Text(subject == null ? 'Add Subject' : 'Edit Subject'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Subject Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'Subject Code'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: teacherController,
              decoration: const InputDecoration(labelText: 'Teacher Name'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedClass,
                    decoration: const InputDecoration(labelText: 'Class'),
                    items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10']
                        .map((cls) => DropdownMenuItem(value: cls, child: Text('Class $cls')))
                        .toList(),
                    onChanged: (value) => selectedClass = value!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedSection,
                    decoration: const InputDecoration(labelText: 'Section'),
                    items: ['A', 'B', 'C', 'D']
                        .map((section) => DropdownMenuItem(value: section, child: Text('Section $section')))
                        .toList(),
                    onChanged: (value) => selectedSection = value!,
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
          ElevatedButton(
            onPressed: () {
              final newSubject = Subject(
                id: subject?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                code: codeController.text,
                teacher: teacherController.text,
                className: selectedClass,
                section: selectedSection,
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
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete ${subject.name}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteSubject(subject.id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddExamDialog(BuildContext context) {
    _showExamForm(context, null);
  }

  void _showEditExamDialog(BuildContext context, Exam exam) {
    _showExamForm(context, exam);
  }

  void _showExamForm(BuildContext context, Exam? exam) {
    final nameController = TextEditingController(text: exam?.name ?? '');
    final subjectController = TextEditingController(text: exam?.subject ?? '');
    final dateController = TextEditingController(text: exam?.date ?? '');
    final timeController = TextEditingController(text: exam?.time ?? '');
    final durationController = TextEditingController(text: exam?.duration ?? '');
    final marksController = TextEditingController(text: exam?.totalMarks.toString() ?? '');
    String selectedClass = exam?.className ?? '10';
    String selectedSection = exam?.section ?? 'A';

    Get.dialog(
      AlertDialog(
        title: Text(exam == null ? 'Schedule Exam' : 'Edit Exam'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Exam Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: 'Time'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(labelText: 'Duration'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: marksController,
                decoration: const InputDecoration(labelText: 'Total Marks'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedClass,
                      decoration: const InputDecoration(labelText: 'Class'),
                      items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10']
                          .map((cls) => DropdownMenuItem(value: cls, child: Text('Class $cls')))
                          .toList(),
                      onChanged: (value) => selectedClass = value!,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedSection,
                      decoration: const InputDecoration(labelText: 'Section'),
                      items: ['A', 'B', 'C', 'D']
                          .map((section) => DropdownMenuItem(value: section, child: Text('Section $section')))
                          .toList(),
                      onChanged: (value) => selectedSection = value!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newExam = Exam(
                id: exam?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                subject: subjectController.text,
                date: dateController.text,
                time: timeController.text,
                duration: durationController.text,
                totalMarks: int.tryParse(marksController.text) ?? 100,
                className: selectedClass,
                section: selectedSection,
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
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Exam'),
        content: Text('Are you sure you want to delete ${exam.name}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteExam(exam.id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
import 'package:get/get.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/services/api_service.dart';
import 'package:school_app/controllers/auth_controller.dart';

class AcademicsController extends GetxController {
  final ApiService _apiService = Get.find();
  final AuthController _authController = Get.find();

  final isLoading = false.obs;
  final subjects = <Subject>[].obs;
  final timetable = <TimetableEntry>[].obs;
  final exams = <Exam>[].obs;
  final results = <Result>[].obs;

  @override
  void onInit() {
    super.onInit();
    final schoolController = Get.find<SchoolController>();

    // React whenever the selected school changes
    ever(schoolController.selectedSchool, (school) {
      if (school != null) {
        loadSubjects(school.id);
        loadExams(school.id);
        loadTimetable(school.id);
        loadResults(school.id);
      } else {
        // Clear all data when no school is selected
        subjects.clear();
        timetable.clear();
        exams.clear();
        results.clear();
      }
    });

    // Initial load if a school is already selected
    final currentSchool = schoolController.selectedSchool.value;
    if (currentSchool != null) {
      loadSubjects(currentSchool.id);
      loadExams(currentSchool.id);
      loadTimetable(currentSchool.id);
      loadResults(currentSchool.id);
    }
  }

  // ── Subjects ────────────────────────────────────────────────────────────────

  Future<void> loadSubjects(String schoolId) async {
    try {
      isLoading.value = true;
      // TODO: replace with real API call, e.g.:
      // final response = await _apiService.get('/api/subjects', queryParameters: {'schoolId': schoolId});
      // subjects.value = (response.data['data'] as List).map((e) => Subject.fromJson(e)).toList();
      subjects.clear();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load subjects');
    } finally {
      isLoading.value = false;
    }
  }

  void addSubject(Subject subject) {
    subjects.add(subject);
    Get.snackbar('Success', 'Subject added successfully');
  }

  void updateSubject(Subject subject) {
    final index = subjects.indexWhere((s) => s.id == subject.id);
    if (index != -1) {
      subjects[index] = subject;
      Get.snackbar('Success', 'Subject updated successfully');
    }
  }

  void deleteSubject(String subjectId) {
    subjects.removeWhere((s) => s.id == subjectId);
    Get.snackbar('Success', 'Subject deleted successfully');
  }

  // ── Timetable ───────────────────────────────────────────────────────────────

  Future<void> loadTimetable(String schoolId) async {
    try {
      // TODO: replace with real API call
      // final response = await _apiService.get('/api/timetable', queryParameters: {'schoolId': schoolId});
      // timetable.value = (response.data['data'] as List).map((e) => TimetableEntry.fromJson(e)).toList();
      timetable.clear();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load timetable');
    }
  }

  // ── Exams ───────────────────────────────────────────────────────────────────

  Future<void> loadExams(String schoolId) async {
    try {
      // TODO: replace with real API call
      // final response = await _apiService.get('/api/exams', queryParameters: {'schoolId': schoolId});
      // exams.value = (response.data['data'] as List).map((e) => Exam.fromJson(e)).toList();
      exams.clear();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load exams');
    }
  }

  void addExam(Exam exam) {
    exams.add(exam);
    Get.snackbar('Success', 'Exam scheduled successfully');
  }

  void updateExam(Exam exam) {
    final index = exams.indexWhere((e) => e.id == exam.id);
    if (index != -1) {
      exams[index] = exam;
      Get.snackbar('Success', 'Exam updated successfully');
    }
  }

  void deleteExam(String examId) {
    exams.removeWhere((e) => e.id == examId);
    Get.snackbar('Success', 'Exam deleted successfully');
  }

  // ── Results ─────────────────────────────────────────────────────────────────

  Future<void> loadResults(String schoolId) async {
    try {
      // TODO: replace with real API call
      // final response = await _apiService.get('/api/results', queryParameters: {'schoolId': schoolId});
      // results.value = (response.data['data'] as List).map((e) => Result.fromJson(e)).toList();
      results.clear();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load results');
    }
  }
}

// ── Models ───────────────────────────────────────────────────────────────────

class Subject {
  final String id;
  final String name;
  final String code;
  final String teacher;
  final String className;
  final String section;

  Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.teacher,
    required this.className,
    required this.section,
  });
}

class TimetableEntry {
  final String day;
  final String period;
  final String time;
  final String subject;
  final String teacher;
  final String className;
  final String section;

  TimetableEntry({
    required this.day,
    required this.period,
    required this.time,
    required this.subject,
    required this.teacher,
    required this.className,
    required this.section,
  });
}

class Exam {
  final String id;
  final String name;
  final String subject;
  final String date;
  final String time;
  final String duration;
  final int totalMarks;
  final String className;
  final String section;

  Exam({
    required this.id,
    required this.name,
    required this.subject,
    required this.date,
    required this.time,
    required this.duration,
    required this.totalMarks,
    required this.className,
    required this.section,
  });
}

class Result {
  final String studentId;
  final String studentName;
  final String examId;
  final String subject;
  final int marksObtained;
  final int totalMarks;
  final String grade;

  Result({
    required this.studentId,
    required this.studentName,
    required this.examId,
    required this.subject,
    required this.marksObtained,
    required this.totalMarks,
    required this.grade,
  });

  double get percentage => (marksObtained / totalMarks) * 100;
}
import 'package:get/get.dart';
import '../../../data/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/controllers/auth_controller.dart';

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
    loadAcademicsData();
  }

  void loadAcademicsData() async {
    final schoolId = _authController.user.value?.schoolId;
    if (schoolId == null) {
      Get.snackbar('Error', 'School ID not found');
      return;
    }

    try {
      isLoading.value = true;
      
      // Load subjects, timetable, exams, and results from API
      // For now, show empty state until API integration
      subjects.clear();
      timetable.clear();
      exams.clear();
      results.clear();
      
      Get.snackbar('Info', 'No academic data found. Add subjects, exams, and timetables to get started.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to load academic data');
    } finally {
      isLoading.value = false;
    }
  }

  void addSubject(Subject subject) {
    subjects.add(subject);
    Get.snackbar('Success', 'Subject added successfully');
  }

  void updateSubject(Subject subject) {
    int index = subjects.indexWhere((s) => s.id == subject.id);
    if (index != -1) {
      subjects[index] = subject;
      Get.snackbar('Success', 'Subject updated successfully');
    }
  }

  void deleteSubject(String subjectId) {
    subjects.removeWhere((s) => s.id == subjectId);
    Get.snackbar('Success', 'Subject deleted successfully');
  }

  void addExam(Exam exam) {
    exams.add(exam);
    Get.snackbar('Success', 'Exam scheduled successfully');
  }

  void updateExam(Exam exam) {
    int index = exams.indexWhere((e) => e.id == exam.id);
    if (index != -1) {
      exams[index] = exam;
      Get.snackbar('Success', 'Exam updated successfully');
    }
  }

  void deleteExam(String examId) {
    exams.removeWhere((e) => e.id == examId);
    Get.snackbar('Success', 'Exam deleted successfully');
  }
}

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
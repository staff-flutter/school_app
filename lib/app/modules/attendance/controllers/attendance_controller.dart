import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../data/services/api_service.dart';

class ParentAttendanceController extends GetxController {
  ParentAttendanceController() {
    
  }

  AuthController? _authController;
  final ApiService _apiService = Get.find();
  final isLoading = false.obs;
  final attendanceRecords = <AttendanceRecord>[].obs;
  final selectedDate = DateTime.now().obs;
  final selectedClass = ''.obs;
  final selectedSection = ''.obs;
  final myChildren = <Map<String, dynamic>>[].obs;
  final selectedChildId = ''.obs;

  // For parent's specific child view
  final isSpecificStudentView = false.obs;
  final studentNameForView = ''.obs;
  final eventsForCalendar = <DateTime, List<String>>{}.obs;

  String get userRole {
    try {
      _authController ??= Get.find<AuthController>();
      return _authController?.user.value?.role?.toLowerCase() ?? '';
    } catch (e) {
      
      return '';
    }
  }
  
  bool get canMark {
    final result = ['teacher', 'correspondent'].contains(userRole);
    
    return result;
  }
  bool get canView {
    final result = ['teacher', 'correspondent', 'principal', 'administrator'].contains(userRole);
    
    return result;
  }
  bool get isParent => userRole == 'parent';
  bool get showClassSelection => !isParent; // Parents don't need class selection
  bool get showMarkAttendanceButton => canMark && !isParent;
  bool get isOwnChildrenOnly => isParent; // Parents see only their children
  String get permission => isParent ? 'ownChildrenOnly' : canMark ? 'markAndView' : 'viewOnly';

  @override
  void onInit() {
    super.onInit();

    // Reset state immediately to ensure clean slate
    _resetControllerState();

    // Handle navigation arguments after the widget tree is built
    // This ensures Get.arguments is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      
      _handleNavigationArguments();
    });
  }

  void _handleNavigationArguments() {

    // Check if navigating for a specific student (from MyChildrenView)
    if (Get.arguments is Map && Get.arguments['parentView'] == true) {
      
      final args = Get.arguments as Map<String, dynamic>;
      final studentId = args['studentId'] as String? ?? '';
      final studentName = args['studentName'] as String? ?? 'Unknown';
      final attendanceData = args['attendanceData'];

      if (studentId.isNotEmpty) {
        loadStudentAttendance(studentId, studentName, attendanceData: attendanceData);
      } else {
        
        isSpecificStudentView.value = false;
        _loadParentChildren();
      }
    } else if (isParent) {
      
      isSpecificStudentView.value = false;
      _loadParentChildren(); // Load all children and their attendance
    } else {
      
      isSpecificStudentView.value = false;
      loadAttendance(); // For teachers/admins
    }
  }

  // Method to handle navigation with new arguments
  void _processNavigationArguments(Map<String, dynamic> args) {
    // Reset state for new navigation
    _resetControllerState();

    // Check if navigating for a specific student
    if (args['parentView'] == true) {
      
      final studentId = args['studentId'] as String? ?? '';
      final studentName = args['studentName'] as String? ?? 'Unknown';
      final attendanceData = args['attendanceData'];

      loadStudentAttendance(studentId, studentName, attendanceData: attendanceData);
    }
  }

  void _resetControllerState() {
    
    attendanceRecords.clear();
    myChildren.clear();
    selectedChildId.value = '';
    selectedDate.value = DateTime.now();
    isLoading.value = false;
    isSpecificStudentView.value = false;
    studentNameForView.value = '';
  }

  void loadStudentAttendance(String studentId, String studentName, {List<dynamic>? attendanceData}) {

    // Reset state for new student
    _resetControllerState();

    // Set new student data
    isSpecificStudentView.value = true;
    selectedChildId.value = studentId;
    studentNameForView.value = studentName;

    // Always load from API to ensure correct month data
    
    loadAttendance();
  }

  void clearSpecificStudentView() {
    
    isSpecificStudentView.value = false;
    selectedChildId.value = '';
    studentNameForView.value = '';
    // Don't clear attendance records here as they might be used for parent overview
  }

  @override
  void onClose() {
    
    // Reset to parent overview mode when controller is disposed
    if (isParent) {
      isSpecificStudentView.value = false;
    }
    super.onClose();
  }

  void _parseAndLoadAttendance(dynamic data) {
    List<dynamic> logs = [];

    // Handle different data formats
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data') && data['data'] is List) {
        logs = data['data'];
      } else if (data.containsKey('attendance')) {
        logs = data['attendance'] ?? [];
      } else if (data.containsKey('logs')) {
        logs = data['logs'] ?? [];
      } else {
        
        return;
      }
    } else if (data is List) {
      logs = data;
    } else {
      
      return;
    }

    // Group by date and keep only the latest record for each date
    final Map<String, dynamic> latestByDate = {};
    for (var log in logs) {
      final date = log['date'] ?? '';
      if (date.isNotEmpty) {
        // Keep the latest record for each date (assuming logs are ordered)
        latestByDate[date] = log;
      }
    }

    final newRecords = latestByDate.values.map((log) {
      final studentName = data is Map ? (data['studentName'] ?? '') : 'Unknown';
      final className = data is Map ? (data['className'] ?? '') : 'Unknown';
      final section = data is Map ? (data['section'] ?? '') : 'Unknown';

      return AttendanceRecord(
        id: log['attendanceId'] ?? log['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        studentId: selectedChildId.value,
        studentName: studentName,
        rollNumber: log['rollNumber'] ?? '',
        className: className,
        section: section,
        date: log['date'] ?? '',
        status: log['status'] ?? 'Absent',
        markedBy: log['markedBy'] ?? '',
        markedAt: log['markedAt'] ?? '',
      );
    }).toList();
    
    newRecords.sort((a, b) => b.date.compareTo(a.date));
    attendanceRecords.value = newRecords;

    // Populate events for calendar
    final newEvents = <DateTime, List<String>>{};
    for (var record in newRecords) {
      try {
        final date = DateTime.parse(record.date).toLocal();
        final dayOnly = DateTime(date.year, date.month, date.day);
        newEvents[dayOnly] = [record.status];
      } catch (e) {
        
      }
    }
    eventsForCalendar.value = newEvents;

    update();
  }
  
  Future<void> _loadParentChildren() async {
    try {
      isLoading.value = true;
      final user = _authController?.user.value;
      if (user?.studentId != null && user!.studentId!.isNotEmpty) {
        final childrenList = <Map<String, dynamic>>[];

        for (var id in user.studentId!) {
          try {

            // First, try to get student basic info from a student API
            String studentName = 'Student $id';
            String studentClass = 'Unknown';

            try {
              final studentResponse = await _apiService.get('/api/student/get/$id');
              if (studentResponse.data['ok'] == true) {
                final studentData = studentResponse.data['data'];
                studentName = studentData['name'] ?? studentData['studentName'] ?? 'Student $id';
                studentClass = studentData['className'] ?? studentData['class'] ?? 'Unknown';
              }
            } catch (e) {
              
            }

            // Add child to list with basic info
            childrenList.add({
              'id': id,
              'name': studentName,
              'class': studentClass,
            });

            // Now get attendance data
            final response = await _apiService.get(
              '/api/attendance/student/$id',
              queryParameters: {
                'month': selectedDate.value.month,
                'year': selectedDate.value.year,
              },
            );

            if (response.data['ok'] == true) {
              final data = response.data['data'];

              // Parse attendance records for this child
              final records = _parseAttendanceData(data, id, studentName, studentClass);
              attendanceRecords.addAll(records);

            } else {
              
            }
          } catch (e) {
            
          }
        }

        myChildren.value = childrenList;

        update(['parent_attendance']); // Notify GetBuilder to rebuild
      }
    } catch (e) {
      
    } finally {
      isLoading.value = false;
    }
  }

  void selectChild(String childId) {
    selectedChildId.value = childId;
    loadAttendance();
  }

  Future<void> loadAttendance() async {
    isLoading.value = true;
    
    if (isParent || isSpecificStudentView.value) {
      if (selectedChildId.value.isNotEmpty) {
        await _loadChildrenAttendance();
      }
    } else {
      await _loadClassAttendance();
    }
    
    isLoading.value = false;
  }

  Future<void> _loadChildrenAttendance() async {

    // Clear previous data before loading new
    attendanceRecords.clear();
    
    try {

      final response = await _apiService.get(
        '/api/attendance/student/${selectedChildId.value}',
        queryParameters: {
          'month': selectedDate.value.month,
          'year': selectedDate.value.year,
        }
      );

      if (response.data['ok'] == true) {
        _parseAndLoadAttendance(response.data['data']);
      } else {
        
      }
      
      // Load yearly attendance
      await loadYearlyAttendance();
    } catch (e) {
      
      attendanceRecords.clear();
    }
  }

  Future<void> _loadClassAttendance() async {
    
    // TODO: Replace with actual API call to get class attendance
    // For now, clear the list until real API is implemented
    attendanceRecords.clear();
  }

  Future<void> markAttendance(String studentId, String status) async {
    if (!canMark) {
      // Use WidgetsBinding to avoid build-time snackbar calls
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar('Error', 'No permission to mark attendance');
      });
      return;
    }

    final index = attendanceRecords.indexWhere((r) => r.studentId == studentId);
    if (index != -1) {
      attendanceRecords[index] = attendanceRecords[index].copyWith(status: status);
      // Use WidgetsBinding to avoid build-time snackbar calls
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar('Success', 'Attendance marked successfully', backgroundColor: AppTheme.successGreen);
      });
    }
  }

  void changeMonth(int delta) {
    selectedDate.value = DateTime(selectedDate.value.year, selectedDate.value.month + delta, 1);
    if (isSpecificStudentView.value && selectedChildId.value.isNotEmpty) {
      // Reload attendance for specific student
      loadAttendance();
    } else {
      // Reload parent overview
      _loadParentChildren();
    }
  }

  void changeYear(int delta) {
    selectedDate.value = DateTime(selectedDate.value.year + delta, selectedDate.value.month, 1);
    if (isSpecificStudentView.value && selectedChildId.value.isNotEmpty) {
      // Reload attendance for specific student
      loadAttendance();
    } else {
      // Reload parent overview
      _loadParentChildren();
    }
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
    // Reload attendance when date changes
    loadAttendance();
  }

  void selectClass(String className) {
    selectedClass.value = className;
    loadAttendance();
  }

  void selectSection(String section) {
    selectedSection.value = section;
    loadAttendance();
  }

  int get presentCount => attendanceRecords.where((r) => r.status.toLowerCase() == 'present').length;
  int get absentCount => attendanceRecords.where((r) => r.status.toLowerCase() == 'absent').length;
  int get totalStudents => presentCount + absentCount;
  double get attendancePercentage {
    final total = presentCount + absentCount;
    return total > 0 ? (presentCount / total) * 100 : 0;
  }
  
  // Check if selected month is in the future
  bool get isSelectedMonthInFuture {
    final now = DateTime.now();
    final selected = selectedDate.value;
    return selected.year > now.year || (selected.year == now.year && selected.month > now.month);
  }

  // Yearly attendance calculation
  final yearlyAttendanceRecords = <AttendanceRecord>[].obs;
  
  int get yearlyPresentCount => yearlyAttendanceRecords.where((r) => r.status.toLowerCase() == 'present').length;
  int get yearlyAbsentCount => yearlyAttendanceRecords.where((r) => r.status.toLowerCase() == 'absent').length;
  double get yearlyAttendancePercentage {
    final total = yearlyPresentCount + yearlyAbsentCount;
    return total > 0 ? (yearlyPresentCount / total) * 100 : 0;
  }

  Future<void> loadYearlyAttendance() async {
    if (selectedChildId.value.isEmpty) return;
    
    // Clear previous yearly data
    yearlyAttendanceRecords.clear();
    
    try {

      final response = await _apiService.get(
        '/api/attendance/student/${selectedChildId.value}',
        queryParameters: {'year': selectedDate.value.year}
      );

      if (response.data['ok'] == true) {
        yearlyAttendanceRecords.value = _parseAttendanceDataToList(response.data['data'], selectedChildId.value);
        
      }
    } catch (e) {
      
      yearlyAttendanceRecords.clear();
    }
  }

  List<AttendanceRecord> _parseAttendanceDataToList(dynamic data, String studentId) {
    final List<AttendanceRecord> records = [];
    List<dynamic> logs = [];
    
    // Handle different response formats
    if (data is Map) {
      if (data.containsKey('data') && data['data'] is List) {
        logs = data['data'];
      } else if (data.containsKey('attendance') && data['attendance'] is List) {
        logs = data['attendance'];
      } else if (data.containsKey('logs') && data['logs'] is List) {
        logs = data['logs'];
      }
    } else if (data is List) {
      logs = data;
    }

    // Group by date and filter by selected year
    final Map<String, dynamic> latestByDate = {};
    for (var log in logs) {
      final dateStr = log['date'] ?? '';
      if (dateStr.isNotEmpty) {
        try {
          final date = DateTime.parse(dateStr);
          // Only include records from the selected year
          if (date.year == selectedDate.value.year) {
            latestByDate[dateStr] = log;
          }
        } catch (e) {
          
        }
      }
    }
    
    for (var log in latestByDate.values) {
      records.add(AttendanceRecord(
        id: log['attendanceId'] ?? log['_id'] ?? '',
        studentId: studentId,
        studentName: log['studentName'] ?? '',
        rollNumber: log['rollNumber'] ?? '',
        className: log['className'] ?? '',
        section: log['section'] ?? '',
        date: log['date'] ?? '',
        status: log['status'] ?? 'Present',
        markedBy: log['markedBy'] ?? '',
        markedAt: log['markedAt'] ?? '',
      ));
    }

    return records;
  }

  List<Map<String, dynamic>> getAttendanceForChild(String childId) {
    // For parent view - get attendance records for a specific child
    return attendanceRecords.where((record) => record.studentId == childId).map((record) {
      return {
        'studentId': record.studentId,
        'date': record.date,
        'status': record.status,
      };
    }).toList();
  }

  List<Map<String, dynamic>> getAllChildrenAttendance() {
    // Return all attendance records for parent view organized by date
    return attendanceRecords.map((record) {
      return {
        'studentId': record.studentId,
        'date': record.date,
        'status': record.status,
      };
    }).toList();
  }

  List<AttendanceRecord> _parseAttendanceData(dynamic data, String studentId, String studentName, String studentClass) {
    final List<AttendanceRecord> records = [];

    // Handle case where data is directly an array of attendance records
    List<dynamic> logs = [];
    if (data is List) {
      logs = data;
    } else if (data is Map && data.containsKey('attendance')) {
      final attendanceData = data['attendance'];
      if (attendanceData is List) {
        logs = attendanceData;
      }
    } else {
      
      return records;
    }

    for (var log in logs) {
      if (log is Map) {
        records.add(AttendanceRecord(
          id: log['attendanceId'] ?? log['id'] ?? '',
          studentId: studentId,
          studentName: studentName,
          rollNumber: log['rollNumber'] ?? '',
          className: studentClass,
          section: log['section'] ?? '',
          date: log['date'] ?? '',
          status: log['status'] ?? 'Present',
          markedBy: log['markedBy'] ?? '',
          markedAt: log['markedAt'] ?? '',
        ));
      }
    }

    return records;
  }
}

class AttendanceRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String className;
  final String section;
  final String date;
  final String status;
  final String markedBy;
  final String markedAt;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.className,
    required this.section,
    required this.date,
    required this.status,
    required this.markedBy,
    required this.markedAt,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['_id'] ?? json['id'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? json['student']?['name'] ?? '',
      rollNumber: json['rollNumber'] ?? json['student']?['rollNumber'] ?? '',
      className: json['className'] ?? json['class'] ?? '',
      section: json['section'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? 'Present',
      markedBy: json['markedBy'] ?? '',
      markedAt: json['markedAt'] ?? json['createdAt'] ?? '',
    );
  }

  AttendanceRecord copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? rollNumber,
    String? className,
    String? section,
    String? date,
    String? status,
    String? markedBy,
    String? markedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      rollNumber: rollNumber ?? this.rollNumber,
      className: className ?? this.className,
      section: section ?? this.section,
      date: date ?? this.date,
      status: status ?? this.status,
      markedBy: markedBy ?? this.markedBy,
      markedAt: markedAt ?? this.markedAt,
    );
  }
}
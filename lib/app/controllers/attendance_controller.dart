import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/constants/api_constants.dart';
import '../core/theme/app_theme.dart';
import '../data/services/api_service.dart';

class AttendanceController extends GetxController {
  final ApiService _apiService = Get.find();
  final isLoading = false.obs;
  final attendanceSheet = <Map<String, dynamic>>[].obs;
  final attendanceHistory = <Map<String, dynamic>>[].obs;

  void _showSnackbar(String title, String message, Color color) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isSnackbarOpen != true) {
        Get.snackbar(
          title,
          message,
          backgroundColor: color,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    });
  }

  // Fetch Attendance Sheet
  Future<List<Map<String, dynamic>>?> getAttendanceSheet({
    required String schoolId,
    required String classId,
    String? sectionId,
    required String date,
    required String academicYear,
  }) async {
    try {
      isLoading.value = true;
      
      final queryParams = {
        'schoolId': schoolId,
        'classId': classId,
        'date': date,
        'academicYear': academicYear,
        if (sectionId != null) 'sectionId': sectionId,
      };

      final response = await _apiService.get(
        ApiConstants.getAttendanceSheet,
        queryParameters: queryParams,
      );

      if (response.data['ok'] == true) {
        final data = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        attendanceSheet.value = data;
        return data;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load attendance sheet', AppTheme.errorRed);
        return null;
      }
    } catch (e) {
      _showSnackbar('Error', 'An error occurred while loading attendance sheet', AppTheme.errorRed);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Mark Attendance
  Future<bool> markAttendance({
    required String schoolId,
    required String classId,
    String? sectionId,
    required String academicYear,
    required String date,
    required List<Map<String, dynamic>> records,
  }) async {
    try {
      isLoading.value = true;

      final data = {
        'schoolId': schoolId,
        'classId': classId,
        'academicYear': academicYear,
        'date': date,
        'records': records,
        if (sectionId != null) 'sectionId': sectionId,
      };

      final response = await _apiService.post(ApiConstants.markAttendance, data: data);

      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Attendance marked successfully', AppTheme.successGreen);
        return true;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to mark attendance', AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      _showSnackbar('Error', 'An error occurred while marking attendance', AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get Attendance History
  Future<List<Map<String, dynamic>>?> getAttendanceHistory({
    required String schoolId,
    required String classId,
    String? sectionId,
    String? academicYear,
    int page = 1,
    int limit = 20,
    String? startDate,
    String? endDate,
  }) async {
    try {
      isLoading.value = true;
      
      final queryParams = {
        'schoolId': schoolId,
        'classId': classId,
        'page': page.toString(),
        'limit': limit.toString(),
        if (sectionId != null) 'sectionId': sectionId,
        if (academicYear != null) 'academicYear': academicYear,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };



      final response = await _apiService.get(
        ApiConstants.getClassAttendance,
        queryParameters: queryParams,
      );
      

      
      if (response.data['ok'] == true) {
        final data = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        attendanceHistory.value = data;
        return data;
      } else {

        return [];
      }
    } catch (e) {
       // Debug log
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  // Get Students for Attendance (when no sheet exists)
  Future<List<Map<String, dynamic>>?> getStudentsForAttendance({
    required String schoolId,
    required String classId,
    String? sectionId,
  }) async {
    try {
      final queryParams = {
        'schoolId': schoolId,
        'classId': classId,
        if (sectionId != null) 'sectionId': sectionId,
      };

      final response = await _apiService.get(
        '/api/student/getallstudents',
        queryParameters: queryParams,
      );

      if (response.data['ok'] == true) {
        final students = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        return students;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  Map<String, dynamic> createAttendanceRecord({
    required String studentId,
    required String studentName,
    required String status, // 'present' or 'absent'
    String? remark,
  }) {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'status': status,
      'remark': remark ?? '',
    };
  }

  // Helper method to validate attendance data
  bool validateAttendanceData({
    required String schoolId,
    required String classId,
    required String academicYear,
    required String date,
    required List<Map<String, dynamic>> records,
  }) {
    if (schoolId.isEmpty || classId.isEmpty || academicYear.isEmpty || date.isEmpty) {
      _showSnackbar('Error', 'Required fields are missing', AppTheme.errorRed);
      return false;
    }

    if (records.isEmpty) {
      _showSnackbar('Error', 'No attendance records provided', AppTheme.errorRed);
      return false;
    }

    for (final record in records) {
      if (record['studentId'] == null || 
          record['studentName'] == null || 
          record['status'] == null) {
        _showSnackbar('Error', 'Invalid attendance record format', AppTheme.errorRed);
        return false;
      }

      if (!['present', 'absent'].contains(record['status'])) {
        _showSnackbar('Error', 'Invalid attendance status. Use "present" or "absent"', AppTheme.errorRed);
        return false;
      }
    }

    return true;
  }

  // Helper method to format date
  String formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Clear attendance data
  void clearAttendanceData() {
    attendanceSheet.clear();
    attendanceHistory.clear();
  }
}
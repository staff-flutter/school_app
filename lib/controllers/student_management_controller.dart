import 'package:get/get.dart';
import 'package:school_app/core/utils/error_handler.dart';
import 'package:school_app/services/api_service.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/controllers/user_management_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/models/student_model.dart';

import 'package:flutter/material.dart';

class StudentManagementController extends GetxController {
  final ApiService _apiService = Get.find();
  final isLoading = false.obs;
  final studentsByClassSection = <Student>[].obs;

  // Assign student to parent
  Future<bool> assignStudentToParent(String parentId, String studentId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.put('/api/student/assignstudent', data: {
        'parentId': parentId,
        'studentId': studentId,
      });

      if (response.statusCode == 200 && response.data['ok'] == true) {
        ErrorHandler.showSuccess('Student assigned to parent successfully');
        return true;
      } else {
        ErrorHandler.showError(response.data, 'Failed to assign student to parent');
        return false;
      }
    } catch (e) {
      ErrorHandler.showError(e, 'Failed to assign student to parent');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get students by class and section
  Future<void> getStudentsByClassAndSection({
    required String schoolId,
    required String classId,
    required String sectionId,
  }) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get(
        '/api/student/getall',
        queryParameters: {
          'schoolId': schoolId,
          'classId': classId,
          'sectionId': sectionId,
        },
      );

      if (response.data != null && response.data['ok'] == true) {
        final studentsData = response.data['data'] as List? ?? [];
        studentsByClassSection.value = studentsData.map((studentData) {
          return Student.fromJson(studentData);
        }).toList();
      } else {
        studentsByClassSection.clear();
        ErrorHandler.showError(response.data, 'Failed to load students');
      }
    } catch (e) {
      
      studentsByClassSection.clear();
      ErrorHandler.showError(e, 'Failed to load students');
    } finally {
      isLoading.value = false;
    }
  }

  // Remove student from parent
  Future<bool> removeStudentFromParent(String parentId, String studentId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.put('/api/student/removestudent', data: {
        'parentId': parentId,
        'studentId': studentId,
      });

      if (response.statusCode == 200 && response.data['ok'] == true) {
        ErrorHandler.showSuccess('Student removed from parent successfully');
        return true;
      }
      ErrorHandler.showError(response.data, 'Failed to remove student from parent');
      return false;
    } catch (e) {
      ErrorHandler.showError(e, 'Failed to remove student from parent');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get student attendance
  // Future<Map<String, dynamic>?> getStudentAttendance(String studentId, {int? month, int? year}) async {
  //   try {
  //     isLoading.value = true;
  //     final queryParams = <String, dynamic>{};
  //     if (month != null) queryParams['month'] = month;
  //     if (year != null) queryParams['year'] = year;
  //
  //     final response = await _apiService.get('/api/attendance/student/$studentId', queryParameters: queryParams);
  //
  //     if (response.data['ok'] == true) {
  //       return response.data['data'];
  //     }
  //     return null;
  //   } catch (e) {
  //     Get.snackbar('Error', 'Failed to load attendance data',
  //       backgroundColor: AppTheme.errorRed, colorText: Colors.white);
  //     return null;
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  // Assign student to class/section
  // Future<bool> assignStudentToClass(Map<String, dynamic> data) async {
  //   try {
  //     isLoading.value = true;
  //     final response = await _apiService.put('/api/studentrecord/assign', data: data);
  //
  //     if (response.data['ok'] == true) {
  //       Get.snackbar('Success', 'Student assigned to class successfully',
  //         backgroundColor: AppTheme.successGreen, colorText: Colors.white);
  //       return true;
  //     }
  //     return false;
  //   } catch (e) {
  //     Get.snackbar('Error', 'Failed to assign student to class',
  //       backgroundColor: AppTheme.errorRed, colorText: Colors.white);
  //     return false;
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  // Remove student from class
  Future<bool> removeStudentFromClass(String schoolId, String studentId, String academicYear) async {
    try {
      isLoading.value = true;
      final response = await _apiService.put('/api/studentrecord/remove', data: {
        'schoolId': schoolId,
        'studentId': studentId,
        'academicYear': academicYear,
      });

      if (response.data['ok'] == true) {
        ErrorHandler.showSuccess('Student removed from class successfully');
        return true;
      } else {
        ErrorHandler.showError(response.data, 'Failed to remove student from class');
        return false;
      }
    } catch (e) {
      if (e.toString().contains('Action Blocked')) {
        final message = e.toString().contains('message:') 
            ? e.toString().split('message: ')[1].split(',')[0]
            : 'Cannot remove student - fees already paid';
        Get.snackbar('Action Blocked', message,
          backgroundColor: AppTheme.warningYellow, colorText: Colors.white, snackPosition: SnackPosition.TOP);
      } else {
        ErrorHandler.showError(e, 'Failed to remove student from class');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get student attendance
  Future<Map<String, dynamic>?> getStudentAttendance(String studentId, {int? month, int? year}) async {
    try {
      isLoading.value = true;
      final queryParams = <String, dynamic>{};
      if (month != null) queryParams['month'] = month;
      if (year != null) queryParams['year'] = year;

      final response = await _apiService.get('/api/attendance/student/$studentId', queryParameters: queryParams);

      if (response.data['ok'] == true) {
        // Return the entire response data including summary
        return {
          'data': response.data['data'] ?? [],
          'summary': response.data['summary'] ?? {},
          'totalDays': response.data['summary']?['totalDays'] ?? 0,
          'presentDays': response.data['summary']?['present'] ?? 0,
          'absentDays': response.data['summary']?['absent'] ?? 0,
          'percentage': response.data['summary']?['totalDays'] != null && response.data['summary']['totalDays'] > 0 
              ? ((response.data['summary']['present'] ?? 0) / response.data['summary']['totalDays'] * 100).round()
              : 0,
        };
      } else {
        
        Get.snackbar('Info', response.data['message'] ?? 'No attendance data available',
          backgroundColor: AppTheme.warningYellow, colorText: Colors.white, snackPosition: SnackPosition.TOP);
      }
      return null;
    } catch (e) {
      
      ErrorHandler.showError(e, 'Failed to load attendance data');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Get student's assigned parent from user management data
  Future<Map<String, dynamic>?> getStudentParent(String studentId) async {
    try {
      // Get user management controller and load all users first
      final userController = Get.find<UserManagementController>();
      
      // Load all users for the school to ensure we have parent data
      final authController = Get.find<AuthController>();
      final schoolId = authController.user.value?.schoolId;
      if (schoolId != null) {
        await userController.loadUsers(schoolId: schoolId, role: 'all');
      }
      
      // Find parent user that has this studentId in their studentId array
      final parentUser = userController.users.firstWhereOrNull((user) {
        if (user['role'] == 'parent' && user['studentId'] != null) {
          final studentIds = user['studentId'];
          if (studentIds is List) {
            return studentIds.contains(studentId);
          } else if (studentIds is String) {
            return studentIds == studentId;
          }
        }
        return false;
      });

      return parentUser;
    } catch (e) {
      
      return null;
    }
  }

  // Assign student to class/section (updated with all required fields)
  Future<bool> assignStudentToClass(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final response = await _apiService.put('/api/studentrecord/assign', data: data);

      if (response.statusCode == 200 && response.data['ok'] == true) {
        ErrorHandler.showSuccess('Student assigned to class successfully');
        return true;
      } else {
        ErrorHandler.showError(response.data, 'Failed to assign student to class');
        return false;
      }
    } catch (e) {
      ErrorHandler.showError(e, 'Failed to assign student to class');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh method to reload data
  Future<void> refreshData() async {
    // This method can be called to refresh any cached data
    studentsByClassSection.refresh();
  }
}
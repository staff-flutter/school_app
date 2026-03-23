import 'package:get/get.dart';
import 'package:school_app/services/api_service.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/core/utils/error_handler.dart';
import 'package:flutter/material.dart';

class SystemManagementController extends GetxController {
  final ApiService _apiService = Get.find();
  final isLoading = false.obs;
  final archivedItems = <Map<String, dynamic>>[].obs;
  final auditLogs = <Map<String, dynamic>>[].obs;
  final studentCache = <String, Map<String, dynamic>>{}.obs;

  // Get student name from existing student data if available
  String getStudentName(String studentId) {
    // Try to get from any existing student controller
    try {
      final userController = Get.find<dynamic>();
      if (userController.toString().contains('UserManagement')) {
        final students = userController.students as List?;
        if (students != null) {
          for (var student in students) {
            if (student.toString().contains(studentId)) {
              final match = RegExp(r'name: ([^,]+)').firstMatch(student.toString());
              if (match != null) {
                return match.group(1)?.trim() ?? 'Unknown Student';
              }
            }
          }
        }
      }
    } catch (e) {
      // Ignore if controller not found
    }
    return 'Unknown Student';
  }

  // Get student name by ID from API
  Future<String> getStudentNameById(String studentId) async {
    try {
      final response = await _apiService.get('/api/student/get/$studentId');
      if (response.data['ok'] == true) {
        return response.data['data']['name'] ?? 'Unknown Student';
      }
    } catch (e) {
      
    }
    return 'Unknown Student';
  }

  // Get teacher names by IDs
  String getTeacherNames(List<String> teacherIds) {
    final names = <String>[];
    for (final id in teacherIds) {
      // Try to get teacher name from API or cache
      names.add('Teacher ($id)');
    }
    return names.join(', ');
  }

  // Get all archived items
  Future<Map<String, dynamic>?> getAllArchivedItems({
    required String schoolId,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      isLoading.value = true;
      final queryParams = {
        'schoolId': schoolId,
        'page': page,
        'limit': limit,
      };
      
      if (category != null) queryParams['category'] = category;

      final response = await _apiService.get('/api/deletearchive/getall', queryParameters: queryParams);
      
      if (response.data['ok'] == true) {
        archivedItems.value = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        return response.data;
      }
      return null;
    } catch (e) {
      ErrorHandler.showError(e, 'Failed to load archived items');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Get single archived item
  Future<Map<String, dynamic>?> getArchivedItem(String id) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('/api/deletearchive/get/$id');
      
      if (response.data['ok'] == true) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      ErrorHandler.showError(e, 'Failed to load archived item');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Permanently delete archived item
  Future<bool> permanentlyDeleteItem(String id) async {
    try {
      isLoading.value = true;
      final response = await _apiService.delete('/api/deletearchive/delete/$id');
      
      if (response.data['ok'] == true) {
        ErrorHandler.showSuccess('Item permanently deleted');
        return true;
      }
      return false;
    } catch (e) {
      ErrorHandler.showError(e, 'Failed to delete item permanently');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get all audit logs
  Future<Map<String, dynamic>?> getAllAuditLogs({
    required String schoolId,
    String? module,
    String? action,
    String? role,
    String? userId,
    String? fromDate,
    String? toDate,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      isLoading.value = true;
      final queryParams = {
        'schoolId': schoolId,
        'page': page,
        'limit': limit,
      };
      
      if (module != null) queryParams['module'] = module;
      if (action != null) queryParams['action'] = action;
      if (role != null) queryParams['role'] = role;
      if (userId != null) queryParams['userId'] = userId;
      if (fromDate != null) queryParams['fromDate'] = fromDate;
      if (toDate != null) queryParams['toDate'] = toDate;

      final response = await _apiService.get('/api/audit/getall', queryParameters: queryParams);
      
      if (response.data['ok'] == true) {
        auditLogs.value = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        return response.data;
      }
      return null;
    } catch (e) {
      ErrorHandler.showError(e, 'Failed to load audit logs');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Get single audit log
  Future<Map<String, dynamic>?> getAuditLog(String id) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('/api/audit/get/$id');
      
      if (response.data['ok'] == true) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      ErrorHandler.showError(e, 'Failed to load audit log details');
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
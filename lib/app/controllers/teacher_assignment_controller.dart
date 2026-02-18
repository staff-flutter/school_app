import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../data/services/api_service.dart';
import '../core/constants/api_constants.dart';
import '../modules/auth/controllers/auth_controller.dart';

class TeacherAssignmentController extends GetxController {
  final ApiService _apiService = Get.find();
  final AuthController _authController = Get.find();
  
  final isLoading = false.obs;
  final teachers = <Map<String, dynamic>>[].obs;
  final assignments = <Map<String, dynamic>>[].obs;

  bool _hasPermission(List<String> allowedRoles) {
    final userRole = _authController.user.value?.role;
    return allowedRoles.contains(userRole);
  }

  // Manage teacher assignments (toggle-based API)
  Future<void> manageTeacherAssignments({
    required String teacherId,
    required List<Map<String, dynamic>> updates,
  }) async {
    if (!_hasPermission(['correspondent', 'principal', 'administrator'])) {
      Get.snackbar('Access Denied', 'You do not have permission to manage teacher assignments');
      return;
    }

    try {
      isLoading.value = true;
      
      final response = await _apiService.post(
        ApiConstants.manageTeacherAssignments,
        data: {
          'teacherId': teacherId,
          'updates': updates,
        },
      );

      if (response.data['ok'] == true) {
        Get.snackbar('Success', 'Teacher assignments updated successfully');
        // Refresh assignments
        await loadTeacherAssignments(teacherId);
      } else {
        Get.snackbar('Error', response.data['message'] ?? 'Failed to update assignments');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update teacher assignments');
      
    } finally {
      isLoading.value = false;
    }
  }

  // Load teacher assignments
  Future<void> loadTeacherAssignments(String teacherId) async {
    try {
      isLoading.value = true;
      
      // This would need to be implemented based on your API
      // For now, we'll use a placeholder
      assignments.clear();
      
    } catch (e) {
      Get.snackbar('Error', 'Failed to load teacher assignments');
      
    } finally {
      isLoading.value = false;
    }
  }

  // Helper methods for different scenarios
  
  // Scenario 1 & 2: Single checkbox (add/remove section)
  Future<void> toggleSectionAssignment(String teacherId, String classId, String sectionId) async {
    await manageTeacherAssignments(
      teacherId: teacherId,
      updates: [
        {'classId': classId, 'sectionId': sectionId}
      ],
    );
  }

  // Scenario 3 & 4: Select/Deselect all (bulk add/remove class)
  Future<void> toggleClassAssignment(String teacherId, String classId) async {
    await manageTeacherAssignments(
      teacherId: teacherId,
      updates: [
        {'classId': classId}
      ],
    );
  }

  // Scenario 5: Multi-select (save multiple changes)
  Future<void> saveMultipleAssignments(String teacherId, List<Map<String, dynamic>> changes) async {
    await manageTeacherAssignments(
      teacherId: teacherId,
      updates: changes,
    );
  }
}
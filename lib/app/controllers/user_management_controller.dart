import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;

import '../core/constants/api_constants.dart';
import '../data/services/api_service.dart';
import '../modules/auth/controllers/auth_controller.dart';
import '../../core/utils/error_handler.dart';
import '../core/theme/app_theme.dart';

class UserManagementController extends GetxController {
  final ApiService _apiService = Get.find();
  final AuthController _authController = Get.find();

  final isLoading = false.obs;
  final users = <Map<String, dynamic>>[].obs;
  final selectedRole = 'all'.obs;
  final currentSchoolId = ''.obs; // Track current school ID

  // Role-based access control
  bool _hasPermission(List<String> allowedRoles) {
    final userRole = _authController.user.value?.role;
    return allowedRoles.contains(userRole);
  }

  void _checkPermissionAndExecute(List<String> allowedRoles, Function action, String actionName) {
    if (_hasPermission(allowedRoles)) {
      action();
    } else {
      Get.snackbar('Access Denied', 'You do not have permission to $actionName',
        backgroundColor: AppTheme.errorRed, colorText: Colors.white, snackPosition: SnackPosition.TOP);
    }
  }

  Future<Map<String, dynamic>?> getTeacherById(String teacherId) async {
    try {
      final response =
      await _apiService.get('${ApiConstants.getUsersByRole}/$teacherId');

      if (response.data['ok'] == true) {
        
        return response.data['data'];
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load teacher details',
        backgroundColor: AppTheme.errorRed, colorText: Colors.white, snackPosition: SnackPosition.TOP);
    }
    return null;
  }

  Future<void> createUser({
    required String email,
    required String userName,
    required String password,
    required String phoneNo,
    required String schoolCode,
  }) async {

      try {
        isLoading.value = true;

        final requestData = <String, dynamic>{
          'email': email.trim(),
          'userName': userName.trim(),
          'password': password,
          'phoneNo': phoneNo.trim(),
          'schoolCode': schoolCode.trim(),
        };

        final response = await _apiService.post(
          ApiConstants.createUser,
          data: requestData,
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200 || response.statusCode == 201 || response.data['ok'] == true) {
          ErrorHandler.showSuccess(response.data['message'] ?? 'User created successfully');
          if (currentSchoolId.value.isNotEmpty) {
            await loadUsers(schoolId: currentSchoolId.value);
          }
          Navigator.pop(Get.context!);
        } else {
          final errorMsg = response.data['message'] ?? 'Failed to create user';
          Get.snackbar('Create Failed', errorMsg,
            backgroundColor: AppTheme.errorRed, colorText: Colors.white, snackPosition: SnackPosition.TOP);
        }
      } catch (e) {
        String userFriendlyError = 'Failed to create user';
        if (e is DioException && e.response?.data?['message'] != null) {
          userFriendlyError = e.response!.data['message'];
        }
        Get.snackbar('Error', userFriendlyError);
      } finally {
        isLoading.value = false;
      }

  }

  // Assign role to user
  Future<void> assignRole(String userId, String role) async {
    // Check if logged-in user has permission (administrator or correspondent)
    if (!_hasPermission(['correspondent', 'administrator'])) {
      Get.snackbar('Access Denied', 'You do not have permission to assign roles');
      return;
    }

    try {
      isLoading.value = true;

      final response = await _apiService.put(
        '${ApiConstants.assignRole}/$userId',
        data: {'role': role}, // Payload format: {"role": "selected_role"}
      );

      if (response.data['ok'] == true) {
        Get.snackbar('Success', response.data['message'] ?? 'Role assigned successfully');
        // Use stored school ID to preserve selection
        if (currentSchoolId.value.isNotEmpty) {
          await loadUsers(schoolId: currentSchoolId.value);
        }
      } else {
        final errorMsg = response.data['message'] ?? 'Failed to assign role';
        Get.snackbar('Assignment Failed', errorMsg);
      }
    } catch (e) {
      String userFriendlyError = 'Unable to assign role. Please try again.';
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          userFriendlyError = 'User not found or role assignment unavailable.';
        } else if (e.response?.statusCode == 403) {
          userFriendlyError = 'You do not have permission to assign roles.';
        } else if (e.response?.statusCode == 500) {
          userFriendlyError = 'Server error. Please contact administrator.';
        } else if (e.response?.data?['message'] != null) {
          userFriendlyError = e.response!.data['message'];
        }
      }
      Get.snackbar('Error', userFriendlyError);
      
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUser({required String userId, required String email,
    required String userName, required String phoneNo}) async {
    // Check permission first
    if (!_hasPermission(['correspondent', 'administrator', 'teacher', 'principal', 'viceprincipal'])) {
      throw Exception('You do not have permission to update users');
    }
    
    try {
      isLoading.value = true;
      
      final response = await _apiService.put('${ApiConstants.updateUser}/$userId', data: {
        'email': email,
        'userName': userName,
        'phoneNo': phoneNo,
      });
      
      if (response.data['ok'] == true || response.statusCode == 200 || response.statusCode == 201) {
        
        // Use stored school ID to preserve selection
        if (currentSchoolId.value.isNotEmpty) {
          await loadUsers(schoolId: currentSchoolId.value);
        }
      } else {
        final errorMsg = response.data['message'] ?? 'Failed to update user';
        
        throw Exception(errorMsg);
      }
    } catch (e) {
      
      String userFriendlyError = 'Unable to update user. Please try again.';
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          userFriendlyError = 'User not found or endpoint unavailable.';
        } else if (e.response?.statusCode == 403) {
          userFriendlyError = 'You do not have permission to update this user.';
        } else if (e.response?.data?['message'] != null) {
          userFriendlyError = e.response!.data['message'];
        }
      } else if (e is Exception) {
        userFriendlyError = e.toString().replaceAll('Exception: ', '');
      }
      throw Exception(userFriendlyError);
    } finally {
      isLoading.value = false;
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    _checkPermissionAndExecute(['correspondent'], () async {
      try {
        isLoading.value = true;

        final response = await _apiService.delete('${ApiConstants.deleteUser}/$userId');

        if (response.data['ok'] == true) {
          Get.snackbar('Success', response.data['message'] ?? 'User deleted successfully');
          // Use stored school ID to preserve selection
          if (currentSchoolId.value.isNotEmpty) {
            await loadUsers(schoolId: currentSchoolId.value);
          }
        } else {
          final errorMsg = response.data['message'] ?? 'Failed to delete user';
          Get.snackbar('Delete Failed', errorMsg);
        }
      } catch (e) {
        String userFriendlyError = 'Unable to delete user. Please try again.';
        if (e is DioException) {
          if (e.response?.statusCode == 404) {
            userFriendlyError = 'User not found or already deleted.';
          } else if (e.response?.statusCode == 403) {
            userFriendlyError = 'You do not have permission to delete users.';
          } else if (e.response?.data?['message'] != null) {
            userFriendlyError = e.response!.data['message'];
          }
        }
        Get.snackbar('Error', userFriendlyError);
      } finally {
        isLoading.value = false;
      }
    }, 'delete users');
  }

  // Load users by role
  Future<void> loadUsers({required String schoolId, String role = 'all'}) async {
    try {
      isLoading.value = true;

      if (schoolId.isEmpty) {
        Get.snackbar('Error', 'Please select a school first');
        users.clear();
        return;
      }

      // Store the current school ID
      currentSchoolId.value = schoolId;

      final response = await _apiService.get('${ApiConstants.getUsersByRole}/$role/$schoolId');

      if (response.data['ok'] == true) {
        final userList = response.data['data'] as List;
        users.value = userList.cast<Map<String, dynamic>>();
      } else {
        users.clear();
        Get.snackbar('Info', response.data['message'] ?? 'No users found for this school');
      }
    } catch (e) {
      users.clear();
      String userFriendlyError = 'Unable to load users. Please try again.';
      
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          userFriendlyError = 'School not found or no users available.';
        } else if (e.response?.statusCode == 403) {
          userFriendlyError = 'You do not have permission to view users.';
        } else if (e.response?.data?['message'] != null) {
          userFriendlyError = e.response!.data['message'];
        }
      }
      
      Get.snackbar('Load Failed', userFriendlyError);
    } finally {
      isLoading.value = false;
    }
  }
}

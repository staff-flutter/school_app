import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:get_storage/get_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'dart:convert';
import 'package:school_app/core/utils/error_handler.dart';
import 'package:school_app/models/user_model.dart';
import 'package:school_app/services/api_service.dart';
import 'package:school_app/services/subscription_service.dart';
import 'package:school_app/constants/api_constants.dart';
import 'package:school_app/core/permissions/permission_system.dart';
import 'package:school_app/routes/app_routes.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/my_children_controller.dart';

class AuthController extends GetxController {
  final ApiService _apiService = Get.find();
  final GetStorage storage = GetStorage();
  
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final user = Rxn<User>();
  final userSchool = Rxn<Map<String, dynamic>>();
  bool _isNavigating = false;

  @override
  void onInit() {
    super.onInit();
  }

  void clearError() => errorMessage('');

  void checkAuthStatus() async {
    final token = storage.read('token');
    final userData = storage.read('user');
    final schoolData = storage.read('userSchool');

    if (token != null && userData != null) {
      try {
        user.value = User.fromJson(userData);
        if (schoolData != null) {
          userSchool.value = Map<String, dynamic>.from(schoolData);
        }

        final userRole = user.value?.role?.toLowerCase();
        const restrictedRoles = ['accountant', 'parent'];

        if (restrictedRoles.contains(userRole)) {
          if (userRole == 'parent') {
            try {
              final myChildrenController = await Get.putAsync<MyChildrenController>(() async {
                final controller = MyChildrenController();
                await controller.loadMyChildren();
                return controller;
              }, permanent: true);
            } catch (e) {
              // Silent fail
            }
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigateBasedOnRole();
          });
          return;
        }

        final authResult = await isAuthenticated();

        if (authResult['ok'] == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigateBasedOnRole();
          });
        } else {
          logout();
        }
      } catch (e) {
        logout();
      }
    }
  }

  bool hasPermission(String permission) {
    if (user.value == null) return false;
    return RolePermissions.hasPermission(user.value!.role, permission);
  }

  bool get isCorrespondent => user.value?.role?.toLowerCase() == 'correspondent';
  bool get isPrincipal => user.value?.role?.toLowerCase() == 'principal';
  bool get isAccountant => user.value?.role?.toLowerCase() == 'accountant';
  bool get isTeacher => user.value?.role?.toLowerCase() == 'teacher';
  bool get requiresOTP => user.value != null ? RolePermissions.requiresOTP(user.value!.role) : true;

  Future<void> login(String identifier, String password) async {
    try {
      isLoading.value = true;
      errorMessage('');

      final response = await _apiService.post(
        ApiConstants.login,
        data: {
          'identifier': identifier,
          'password': password,
        },
      );

      if (response.data['ok'] == true) {
        final token = response.data['token'];
        final userData = response.data['user'];

        storage.write('token', token);
        _apiService.setToken(token);

        if (userData['schoolId'] is Map) {
          userSchool.value = userData['schoolId'];
          storage.write('userSchool', userData['schoolId']);
          userData['schoolId'] = userData['schoolId']['_id'] ?? userData['schoolId']['id'];
        }
        
        if (userData['schoolId'] == null && token != null) {
          try {
            final parts = token.split('.');
            if (parts.length == 3) {
              final payload = parts[1];
              final normalizedPayload = payload + '=' * (4 - payload.length % 4).toInt();
              final decoded = utf8.decode(base64Url.decode(normalizedPayload));
              final tokenData = json.decode(decoded);
              
              if (tokenData['schoolId'] != null) {
                userData['schoolId'] = tokenData['schoolId'];
              }
            }
          } catch (e) {
            // Silent fail
          }
        }
        
        storage.write('user', userData);
        user.value = User.fromJson(userData);

        if (userSchool.value == null) {
          await fetchUserSchoolInfo();
        }
        
        try {
          final subscriptionService = Get.find<SubscriptionService>();
          if (user.value!.schoolId != null) {
            await subscriptionService.forceReloadSubscription(user.value!.schoolId!);
          }
        } catch (e) {
          // Silent fail
        }

        if (user.value?.role?.toLowerCase() == 'parent') {
          try {
            final myChildrenController = await Get.putAsync<MyChildrenController>(() async {
              final controller = MyChildrenController();
              await controller.loadMyChildren();
              return controller;
            }, permanent: true);
          } catch (e) {
            // Silent fail
          }
        }

        Get.snackbar('Success', response.data['message']);
        navigateBasedOnRole();
      } else {
        final errorMsg = response.data['message'] ?? 'Login failed';
        errorMessage(errorMsg);
        Get.snackbar('Error', errorMsg);
      }
    } catch (e) {
      String errorMsg = 'Login failed';
      if (e is DioException && e.response != null) {
        errorMsg = e.response?.data['message'] ?? 'Login failed';
      } else {
        errorMsg = e.toString().replaceAll('Exception: ', '');
      }
      errorMessage(errorMsg);
      Get.snackbar('Error', errorMsg);
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> isAuthenticated() async {
    try {
      final response = await _apiService.get(ApiConstants.isAuthenticated);
      
      if (response.data['ok'] == true) {
        final userData = response.data['data'];
        
        if (userData['schoolId'] is Map) {
           userSchool.value = userData['schoolId'];
           storage.write('userSchool', userData['schoolId']);
           userData['schoolId'] = userData['schoolId']['_id'] ?? userData['schoolId']['id'];
        }

        user.value = User.fromJson(userData);
        storage.write('user', userData);
        
        try {
          final subscriptionService = Get.find<SubscriptionService>();
          await subscriptionService.reloadSubscriptionAfterAuth();
          if (user.value?.schoolId != null) {
            await subscriptionService.forceReloadSubscription(user.value!.schoolId!);
          }
        } catch (e) {
          // Silent fail
        }
        
        return {
          'ok': true,
          'message': response.data['message'] ?? 'User is authenticated',
          'data': userData,
        };
      } else {
        return {
          'ok': false,
          'message': response.data['message'] ?? 'User is not authenticated',
        };
      }
    } catch (e) {
      return {
        'ok': false,
        'message': 'Authentication check failed',
      };
    }
  }

  Future<void> refreshUserData() async {
    try {
      final authResult = await isAuthenticated();
      if (authResult['ok'] == true) {
        user.refresh();
      }
    } catch (e) {
      // Silent fail
    }
  }

  void navigateBasedOnRole() {
    if (_isNavigating || user.value == null) return;
    _isNavigating = true;
    
    final userRole = user.value!.role.toLowerCase();
    
    Future.delayed(Duration.zero, () {
      switch (userRole) {
        case 'correspondent':
        case 'accountant':
          Get.offAllNamed(AppRoutes.ACCOUNTING_DASHBOARD);
          break;
        case 'parent':
          Get.offAllNamed('/my-children');
          break;
        case 'principal':
        case 'administrator':
        case 'viceprincipal':
        case 'teacher':
        case 'student':
          Get.offAllNamed(AppRoutes.DASHBOARD);
          break;
        default:
          Get.offAllNamed(AppRoutes.DASHBOARD);
      }
      _isNavigating = false;
    });
  }

  Future<void> createSchool(String schoolName, String email, String phoneNo, String address, String currentAcademicYear, [File? logoFile]) async {
    try {
      isLoading.value = true;
      
      final formData = FormData.fromMap({
        'name': schoolName,
        'email': email.isNotEmpty ? email : null,
        'phoneNo': phoneNo.isNotEmpty ? phoneNo : null,
        'address': address.isNotEmpty ? address : null,
        'currentAcademicYear': currentAcademicYear.isNotEmpty ? currentAcademicYear : null,
      });
      
      if (logoFile != null) {
        await _compressImage(logoFile);
        formData.files.add(MapEntry(
          'file',
          await MultipartFile.fromFile(
            logoFile.path,
            filename: 'logo.${logoFile.path.split('.').last}',
          ),
        ));
      }
      
      final response = await _apiService.dio.post(
        ApiConstants.createSchool,
        data: formData,
      );
      
      _handleCreateSchoolResponse(response);
    } catch (e) {
      ErrorHandler.showError(e, 'Failed to create school');
    } finally {
      isLoading.value = false;
    }
  }
  
  void _handleCreateSchoolResponse(Response response) {
    if (response.data['ok'] == true) {
      if (Get.context != null) {
        Navigator.pop(Get.context!);
      } else {
        Get.back();
      }
      try {
        final schoolController = Get.find<SchoolController>();
        schoolController.getAllSchools();
      } catch (e) {
        // Silent fail
      }
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.snackbar('Success', 'School created successfully', 
            colorText: Colors.white, backgroundColor: Colors.green);
      });
    } else {
      Get.snackbar('Error', response.data['message'] ?? 'Failed to create school');
    }
  }

  Future<void> logout() async {
    if (_isNavigating) return;
    _isNavigating = true;
    
    try {
      await _apiService.post(ApiConstants.logout);
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      _apiService.clearToken();
      user.value = null;
      userSchool.value = null;
      errorMessage('');

      storage.remove('token');
      storage.remove('user');
      storage.remove('userSchool');

      Future.delayed(Duration.zero, () {
        Get.offAllNamed(AppRoutes.LOGIN);
        _isNavigating = false;
      });
    }
  }

  Future<void> forceRefreshAuth() async {
    await handleUserUpdateSuccess();
  }

  Future<void> updateUserProfile({
    String? userName,
    String? email,
    String? phoneNo,
  }) async {
    try {
      isLoading.value = true;

      final updateData = <String, dynamic>{};
      if (userName != null && userName.isNotEmpty) updateData['userName'] = userName;
      if (email != null && email.isNotEmpty) updateData['email'] = email;
      if (phoneNo != null && phoneNo.isNotEmpty) updateData['phoneNo'] = phoneNo;
      
      if (updateData.isEmpty) {
        throw Exception('No data to update');
      }
      
      final response = await _apiService.put(
        ApiConstants.updateUser,
        data: updateData,
      );

      if (response.data['ok'] == true) {
        await handleUserUpdateSuccess();
        Get.snackbar('Success', 'Profile updated successfully');
      } else {
        throw Exception(response.data['message'] ?? 'Update failed');
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        final errorMsg = e.response?.data['message'] ?? 'Update failed';
        Get.snackbar('Error', errorMsg);
      } else {
        Get.snackbar('Error', 'Update failed: ${e.toString()}');
      }
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<File> _compressImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length <= 200 * 1024) return file;
      if (bytes.length > 500 * 1024) throw Exception('Image too large');
      return file;
    } catch (e) {
      throw Exception('Image file is too large. Please select a smaller image.');
    }
  }

  Future<void> fetchUserSchoolInfo() async {
    try {
      if (user.value?.schoolId != null) {
        final response = await _apiService.get(
          '${ApiConstants.getSingleSchool}/${user.value!.schoolId}',
        );
        
        if (response.data['ok'] == true) {
          final schoolData = response.data['data'];
          userSchool.value = schoolData;
          storage.write('userSchool', schoolData);
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> handleUserUpdateSuccess() async {
    await refreshUserData();
    await fetchUserSchoolInfo();
  }
}
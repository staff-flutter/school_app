import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:get_storage/get_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'dart:convert';
import '../../../../core/utils/error_handler.dart';
import '../models/user_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/subscription_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/permissions/permission_system.dart';
import '../../../routes/app_routes.dart';
import '../../../controllers/school_controller.dart';
import '../../../controllers/my_children_controller.dart';

class AuthController extends GetxController {
  final ApiService _apiService = Get.find();
  final GetStorage storage = GetStorage();
  
  final isLoading = false.obs;
  final user = Rxn<User>();
  final userSchool = Rxn<Map<String, dynamic>>(); // Store full school info (logo, address, etc.)
  bool _isNavigating = false;

  @override
  void onInit() {
    super.onInit();
    // Authentication check is now handled by SplashView
  }

  void checkAuthStatus() async {

    final token = storage.read('token');
    final userData = storage.read('user');
    final schoolData = storage.read('userSchool'); // Restore school details

    if (token != null && userData != null) {
      try {
        
        user.value = User.fromJson(userData);
        if (schoolData != null) {
          userSchool.value = Map<String, dynamic>.from(schoolData);
        }

        final userRole = user.value?.role?.toLowerCase();

        // Roles that are NOT allowed to call isAuthenticated API
        const restrictedRoles = ['accountant', 'parent'];

        if (restrictedRoles.contains(userRole)) {

          // Initialize MyChildrenController for parent users
          if (userRole == 'parent') {
            try {
              // Import the MyChildrenController dynamically to avoid circular dependency
              final myChildrenController = await Get.putAsync<MyChildrenController>(() async {
                final controller = MyChildrenController();
                await controller.loadMyChildren(); // Load children data immediately
                return controller;
              }, permanent: true);
              
            } catch (e) {
              
            }
          }

          // For restricted roles, trust stored credentials and navigate directly
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigateBasedOnRole();
          });
          return;
        }

        // Verify authentication with server for allowed roles
        final authResult = await isAuthenticated();

        if (authResult['ok'] == true) {
          // Auto-navigate to appropriate dashboard if user is authenticated
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigateBasedOnRole();
          });
        } else {
          
          // Clear invalid session
          logout();
        }
      } catch (e) {
        
        logout();
      }
    } else {
      
    }
  }

  // Permission checking methods
  bool hasPermission(String permission) {
    if (user.value == null) return false;
    return RolePermissions.hasPermission(user.value!.role, permission);
  }

  bool get isCorrespondent => user.value?.role.toLowerCase() == 'correspondent';
  bool get isPrincipal => user.value?.role.toLowerCase() == 'principal';
  bool get isAccountant => user.value?.role.toLowerCase() == 'accountant';
  bool get isTeacher => user.value?.role.toLowerCase() == 'teacher';
  bool get requiresOTP => user.value != null ? RolePermissions.requiresOTP(user.value!.role) : true;

  Future<void> login(String identifier, String password) async {
    try {
      isLoading.value = true;

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

        // Ensure the API service also has the token
        _apiService.setToken(token);

        // --- FIX START: Handle School Object vs String ID ---
        // If schoolId is a Map (Object), save it separately and flatten user.schoolId to String
        if (userData['schoolId'] is Map) {
          // Save full school object to storage for ProfileView to use
          userSchool.value = userData['schoolId'];
          storage.write('userSchool', userData['schoolId']);
          
          // Replace object with just the ID string for the User model
          userData['schoolId'] = userData['schoolId']['_id'] ?? userData['schoolId']['id'];
        }
        // --- FIX END ---
        
        // Extract schoolId from JWT token if not in user data
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
            
          }
        }
        
        storage.write('user', userData);
        user.value = User.fromJson(userData);

        // Fetch and store school information if we don't have it yet
        if (userSchool.value == null) {
          await fetchUserSchoolInfo();
        }
        
        // Force load subscription data
        try {
          final subscriptionService = Get.find<SubscriptionService>();
          if (user.value!.schoolId != null) {
            await subscriptionService.forceReloadSubscription(user.value!.schoolId!);
          }
        } catch (e) {
          
        }

        // Initialize MyChildrenController for parent users
        if (user.value?.role?.toLowerCase() == 'parent') {
          try {
            // Import the MyChildrenController dynamically to avoid circular dependency
            final myChildrenController = await Get.putAsync<MyChildrenController>(() async {
              final controller = MyChildrenController();
              await controller.loadMyChildren(); // Load children data immediately
              return controller;
            }, permanent: true);
            
          } catch (e) {
            
          }
        }

        Get.snackbar('Success', response.data['message']);
        navigateBasedOnRole();
      } else {
        Get.snackbar('Error', response.data['message'] ?? 'Login failed');
      }
    } catch (e) {
      
      if (e is DioException && e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Login failed';
        Get.snackbar('Error', errorMessage);
      } else {
        Get.snackbar('Error', 'Login failed : Try to Login Again');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> isAuthenticated() async {
    try {
      final response = await _apiService.get(ApiConstants.isAuthenticated);
      
      if (response.data['ok'] == true) {
        final userData = response.data['data'];
        
        // 
        // Handle schoolId fix here as well if needed
        if (userData['schoolId'] is Map) {
           userSchool.value = userData['schoolId'];
           storage.write('userSchool', userData['schoolId']);
           userData['schoolId'] = userData['schoolId']['_id'] ?? userData['schoolId']['id'];
        }

        user.value = User.fromJson(userData);
        storage.write('user', userData);
        
        // Reload subscription data after user authentication
        try {
          final subscriptionService = Get.find<SubscriptionService>();
          await subscriptionService.reloadSubscriptionAfterAuth();
          // Force reload with current school ID
          if (user.value?.schoolId != null) {
            await subscriptionService.forceReloadSubscription(user.value!.schoolId!);
          }
        } catch (e) {
          
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

  // Add method to refresh user data after updates
  Future<void> refreshUserData() async {
    try {
      
      final authResult = await isAuthenticated();
      
      if (authResult['ok'] == true) {
        
        // Force UI update
        user.refresh();
      } else {
        
      }
    } catch (e) {
      
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
      
    } finally {
      _apiService.clearToken();
      user.value = null;
      userSchool.value = null; // Clear school data

      // Clear all stored authentication data
      storage.remove('token');
      storage.remove('user');
      storage.remove('userSchool');

      Future.delayed(Duration.zero, () {
        Get.offAllNamed(AppRoutes.LOGIN);
        _isNavigating = false;
      });
    }
  }

  // Method to force refresh authentication state
  Future<void> forceRefreshAuth() async {
    
    await handleUserUpdateSuccess();
  }

  // Method to update user profile
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
        
        // Refresh user data after successful update
        await handleUserUpdateSuccess();
        Get.snackbar('Success', 'Profile updated successfully');
      } else {
        throw Exception(response.data['message'] ?? 'Update failed');
      }
    } catch (e) {
      
      if (e is DioException && e.response != null) {
        final errorMessage = e.response?.data['message'] ?? 'Update failed';
        Get.snackbar('Error', errorMessage);
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
      
    }
  }

  // Method to handle post-update refresh
  Future<void> handleUserUpdateSuccess() async {
    
    await refreshUserData();
    await fetchUserSchoolInfo();
  }
}

// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart' hide Response, FormData, MultipartFile;
// import 'package:get_storage/get_storage.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'dart:io';
// import 'dart:convert';
// import '../models/user_model.dart';
// import '../../../data/services/api_service.dart';
// import '../../../core/constants/api_constants.dart';
// import '../../../core/permissions/permission_system.dart';
// import '../../../routes/app_routes.dart';
// import '../../../controllers/school_controller.dart';

// class AuthController extends GetxController {
//   final ApiService _apiService = Get.find();
//   final storage = GetStorage();
  
//   final isLoading = false.obs;
//   final user = Rxn<User>();
//   final userSchool = Rxn<Map<String, dynamic>>(); // Store school info
//   bool _isNavigating = false;

//   @override
//   void onInit() {
//     super.onInit();
//     checkAuthStatus();
//   }

//   void checkAuthStatus() async {
//     final token = storage.read('token');
//     final userData = storage.read('user');
//     final schoolData = storage.read('userSchool');
    
//     if (token != null && userData != null) {
//       user.value = User.fromJson(userData);
//       if (schoolData != null) {
//         userSchool.value = Map<String, dynamic>.from(schoolData);
//       }
      
//       // Verify authentication with server
//       final authResult = await isAuthenticated();
//       if (authResult['ok'] == true) {
//         // Auto-navigate to appropriate dashboard if user is authenticated
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           navigateBasedOnRole();
//         });
//       } else {
//         // Clear invalid session
//         logout();
//       }
//     }
//   }

//   // Permission checking methods
//   bool hasPermission(String permission) {
//     if (user.value == null) return false;
//     return RolePermissions.hasPermission(user.value!.role, permission);
//   }

//   bool get isCorrespondent => user.value?.role.toLowerCase() == 'correspondent';
//   bool get isPrincipal => user.value?.role.toLowerCase() == 'principal';
//   bool get isAccountant => user.value?.role.toLowerCase() == 'accountant';
//   bool get isTeacher => user.value?.role.toLowerCase() == 'teacher';
//   bool get requiresOTP => user.value != null ? RolePermissions.requiresOTP(user.value!.role) : true;

//   Future<void> login(String identifier, String password) async {
//     try {
//       isLoading.value = true;
//       
//       
      
//       final response = await _apiService.post(
//         ApiConstants.login,
//         data: {
//           'identifier': identifier,
//           'password': password,
//         },
//       );

//       
//       

//       if (response.data['ok'] == true) {
//         final token = response.data['token'];
//         final userData = response.data['user'];
        
//         
//         storage.write('token', token);
        
//         // Ensure the API service also has the token
//         _apiService.setToken(token);

//         // Fix: Handle case where schoolId is returned as a Map (Object) instead of String
//         if (userData['schoolId'] is Map) {
//           userData['schoolId'] = userData['schoolId']['_id'];
//         }
        
//         // Extract schoolId from JWT token if not in user data
//         if (userData['schoolId'] == null && token != null) {
//           try {
//             // Decode JWT token to extract schoolId
//             final parts = token.split('.');
//             if (parts.length == 3) {
//               final payload = parts[1];
//               // Add padding if needed
//               final normalizedPayload = payload + '=' * (4 - payload.length % 4).toInt();
//               final decoded = utf8.decode(base64Url.decode(normalizedPayload));
//               final tokenData = json.decode(decoded);
              
//               if (tokenData['schoolId'] != null) {
//                 userData['schoolId'] = tokenData['schoolId'];
//                 
//               }
//             }
//           } catch (e) {
//             
//           }
//         }
        
//         storage.write('user', userData);
//         user.value = User.fromJson(userData);
        
//         // Fetch and store school information
//         await fetchUserSchoolInfo();
        
//         
//         Get.snackbar('Success', response.data['message']);
//         navigateBasedOnRole();
//       } else {
//         
//         Get.snackbar('Error', response.data['message'] ?? 'Login failed');
//       }
//     } catch (e) {
//       
//       if (e is DioException && e.response != null) {
//         
//         final errorMessage = e.response?.data['message'] ?? 'Login failed';
//         Get.snackbar('Error', errorMessage);
//       } else {
//         Get.snackbar('Error', 'Login failed: ${e.toString()}');
//       }
//     } finally {
//       isLoading.value = false;
//       
//     }
//   }

//   Future<Map<String, dynamic>> isAuthenticated() async {
//     try {
//       final response = await _apiService.get(ApiConstants.isAuthenticated);
      
//       if (response.data['ok'] == true) {
//         final userData = response.data['data'];
//         user.value = User.fromJson(userData);
//         storage.write('user', userData);
//         return {
//           'ok': true,
//           'message': response.data['message'] ?? 'User is authenticated',
//           'data': userData,
//         };
//       } else {
//         return {
//           'ok': false,
//           'message': response.data['message'] ?? 'User is not authenticated',
//         };
//       }
//     } catch (e) {
//       
//       return {
//         'ok': false,
//         'message': 'Authentication check failed',
//       };
//     }
//   }

//   void navigateBasedOnRole() {
//     if (_isNavigating || user.value == null) return;
//     _isNavigating = true;
    
//     final userRole = user.value!.role.toLowerCase();
//     
    
//     Future.delayed(Duration.zero, () {
//       switch (userRole) {
//         case 'correspondent':
//         case 'accountant':
//           
//           Get.offAllNamed(AppRoutes.ACCOUNTING_DASHBOARD);
//           break;
//         case 'principal':
//         case 'administrator':
//         case 'viceprincipal':
//           
//           Get.offAllNamed(AppRoutes.DASHBOARD);
//           break;
//         case 'teacher':
//           
//           Get.offAllNamed(AppRoutes.DASHBOARD);
//           break;
//         case 'student':
//         case 'parent':
//           
//           Get.offAllNamed(AppRoutes.DASHBOARD);
//           break;
//         default:
//           
//           Get.offAllNamed(AppRoutes.DASHBOARD);
//       }
//       _isNavigating = false;
//     });
//   }

//   Future<void> createSchool(String schoolName, String email, String phoneNo, String address, String currentAcademicYear, [File? logoFile]) async {
//     try {
//       isLoading.value = true;
      
//       final formData = FormData.fromMap({
//         'name': schoolName,
//         'email': email.isNotEmpty ? email : null,
//         'phoneNo': phoneNo.isNotEmpty ? phoneNo : null,
//         'address': address.isNotEmpty ? address : null,
//         'currentAcademicYear': currentAcademicYear.isNotEmpty ? currentAcademicYear : null,
//       });
      
//       if (logoFile != null) {
//         // Validate image size
//         await _compressImage(logoFile);
        
//         formData.files.add(MapEntry(
//           'file',
//           await MultipartFile.fromFile(
//             logoFile.path,
//             filename: 'logo.${logoFile.path.split('.').last}',
//           ),
//         ));
//       }
      
//       
      
//       final response = await _apiService.dio.post(
//         ApiConstants.createSchool,
//         data: formData,
//       );
      
//       _handleCreateSchoolResponse(response);
//     } catch (e) {
//       
//       if (e.toString().contains('too large')) {
//         Get.snackbar('Error', 'Image file is too large. Please select an image smaller than 200KB.');
//       } else if (e is DioException && e.response != null) {
//         
//         if (e.response?.statusCode == 413) {
//           Get.snackbar('Error', 'Image file is too large. Please select a smaller image or try without logo.');
//         } else {
//           final errorMessage = e.response?.data is Map 
//               ? e.response?.data['message'] ?? 'Failed to create school'
//               : 'Failed to create school';
//           Get.snackbar('Error', errorMessage);
//         }
//       } else {
//         Get.snackbar('Error', 'Failed to create school: ${e.toString()}');
//       }
//     } finally {
//       isLoading.value = false;
//     }
//   }
  
//   void _handleCreateSchoolResponse(Response response) {
//     
//     if (response.data['ok'] == true) {
//       // Navigate back first
//       Get.back();
      
//       // Refresh school list if SchoolController exists
//       try {
//         final schoolController = Get.find<SchoolController>();
//         schoolController.getAllSchools();
//       } catch (e) {
//         
//       }
      
//       // Show success message with delay to avoid race condition
//       Future.delayed(const Duration(milliseconds: 100), () {
//         Get.snackbar('Success', 'School created successfully', 
//             colorText: Colors.white, backgroundColor: Colors.green);
//       });
//     } else {
//       Get.snackbar('Error', response.data['message'] ?? 'Failed to create school');
//     }
//   }

//   Future<void> logout() async {
//     if (_isNavigating) return;
//     _isNavigating = true;
    
//     try {
//       await _apiService.post(ApiConstants.logout);
//     } catch (e) {
//       // Continue with logout even if API call fails
//       
//     } finally {
//       _apiService.clearToken();
//       user.value = null;
//       userSchool.value = null;
//       Future.delayed(Duration.zero, () {
//         Get.offAllNamed(AppRoutes.LOGIN);
//         _isNavigating = false;
//       });
//     }
//   }
  
//   Future<File> _compressImage(File file) async {
//     try {
//       final bytes = await file.readAsBytes();
      
//       // If file is already small enough, return as is
//       if (bytes.length <= 200 * 1024) return file; // 200KB limit
      
//       // Simple size reduction by reading and writing with reduced quality
//       // This is a basic approach - just limit file size
//       if (bytes.length > 500 * 1024) {
//         // For very large files, show error
//         throw Exception('Image too large');
//       }
      
//       return file;
//     } catch (e) {
//       
//       throw Exception('Image file is too large. Please select a smaller image.');
//     }
//   }

//   Future<void> fetchUserSchoolInfo() async {
//     try {
//       if (user.value?.schoolId != null) {
//         
        
//         final response = await _apiService.get(
//           '${ApiConstants.getSingleSchool}/${user.value!.schoolId}',
//         );
        
//         if (response.data['ok'] == true) {
//           final schoolData = response.data['data'];
//           userSchool.value = schoolData;
//           storage.write('userSchool', schoolData);
//           
//         }
//       } else {
//         
//       }
//     } catch (e) {
//       
//       // Silent fail - users don't need to see this error
//     }
//   }
// }
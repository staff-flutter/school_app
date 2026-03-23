import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:school_app/constants/api_constants.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/models/school_models.dart';
import 'package:school_app/models/student_model.dart';
import 'package:school_app/services/api_service.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/controllers/subscription_controller.dart';

class SchoolController extends GetxController {
  final ApiService _apiService = Get.find();

  final isLoading = false.obs;
  final schools = <School>[].obs;
  final classes = <SchoolClass>[].obs;
  final sections = <Section>[].obs;
  final students = <Student>[].obs;
  final teachers = <Map<String, dynamic>>[].obs;
  final selectedSchool = Rxn<School>();
  bool _teachersLoaded = false;

  // Prevent concurrent getAllSchools calls
  bool _isLoadingSchools = false;
  bool _schoolsLoaded = false;

  // Check if user has permission to access all schools
  // API ALLOWED_ROLES: correspondent only
  bool get _canAccessAllSchools {
    try {
      final authController = Get.find<AuthController>();
      final userRole = authController.user.value?.role.toLowerCase();
      final isPlatformAdmin = authController.user.value?.isPlatformAdmin == true;

      // Only correspondent can access all schools (matching API ALLOWED_ROLES)
      final canAccess = userRole == 'correspondent' || isPlatformAdmin;

      return canAccess;
    } catch (e) {
      
      return false;
    }
  }

  // --- Helper for Snackbar ---
  void _showSnackbar(String title, String message, Color color) {
    // Use SchedulerBinding to avoid setState during build
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

  Future<void> devEnableAllModules(String schoolId) async {
    try {
      // API 77: PUT /api/subscription/update
      final response = await _apiService.put(
        '/api/subscription/update',
        data: {
          "schoolId": schoolId,
          "planName": "custom",
          "customModules": {
            "studentRecord": true,
            "attendance": true,
            "expense": true,
            "club": true,
            "announcement": true
          }
        },
      );
      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'All modules enabled for testing', AppTheme.successGreen);
        checkSubscription(schoolId); // Refresh local status
      }
    } catch (e) {
      
    }
  }
  // Inside school_controller.dart

// Observable map to store module status: {"club": true, "expense": false, ...}
  final enabledModules = <String, bool>{}.obs;

  // Role-based Module Visibility Config
  final Map<String, List<String>> roleModuleConfig = {
    'correspondent': [
      'dashboard', 'users', 'schools', 'classes', 'sections', 'teacherAssignments',
      'students', 'studentRecords', 'feeStructure', 'feeCollection', 'attendance',
      'expenses', 'announcements', 'clubs', 'clubVideos', 'financeLedger',
      'auditLogs', 'deleteArchive', 'subscription'
    ],
    'administrator': [
      'dashboard', 'users', 'classes', 'sections', 'teacherAssignments', 'students',
      'studentRecords', 'feeStructure', 'attendance', 'announcements', 'clubs',
      'clubVideos', 'auditLogs'
    ],
    'principal': [
      'dashboard', 'students', 'studentRecords', 'feeStructure', 'attendance',
      'expenses', 'announcements', 'clubs', 'clubVideos', 'financeLedger'
    ],
    'viceprincipal': [
      'dashboard', 'students', 'attendance', 'announcements', 'clubs', 'clubVideos'
    ],
    'teacher': [
      'dashboard', 'myClasses', 'mySections', 'students', 'attendance',
      'announcements', 'clubs', 'clubVideos'
    ],
    'accountant': [
      'dashboard', 'students', 'studentRecords', 'feeStructure', 'feeCollection',
      'expenses', 'financeLedger', 'clubs', 'clubVideos'
    ],
    'parent': [
      'dashboard', 'myChildren', 'attendance', 'announcements', 'clubs', 'clubVideos'
    ],
  };

  bool isModuleVisible(String module) {
    // 1. Check Subscription (School Level)
    if (enabledModules.isNotEmpty && enabledModules[module] == false) {
      return false;
    }

    // 2. Check Role (User Level)
    if (Get.isRegistered<AuthController>()) {
      final authController = Get.find<AuthController>();
      final role = authController.user.value?.role.toLowerCase();
      if (role == null) return false;

      final allowedModules = roleModuleConfig[role] ?? [];
      return allowedModules.contains(module);
    }
    return false;
  }

  Future<void> checkSubscription(String schoolId) async {
    try {
      final response = await _apiService.get(
        '/api/subscription/get',
        queryParameters: {'schoolId': schoolId},
      );

      if (response.data['ok'] == true) {
        final modules = response.data['data']['enabledModules'] as Map<String, dynamic>;
        enabledModules.value = modules.cast<String, bool>();
      }
    } catch (e) {
      enabledModules.value = {'studentRecord': true, 'club': false};
    }
  }

  bool hasModuleAccess2(String moduleName) {
    // studentRecord is always accessible during development
    if (moduleName == 'studentRecord') return true;
    return enabledModules[moduleName] ?? false;
  }

  // Force refresh schools (bypasses cache)
  Future<void> refreshSchools() async {
    _schoolsLoaded = false;
    await getAllSchools();
  }

  // Get all schools with debouncing and retry logic
  Future<void> getAllSchools({int retryCount = 0}) async {
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 1);

    if (!_canAccessAllSchools) {
      await _loadUserSchool();
      return;
    }

    if (_schoolsLoaded && !_isLoadingSchools && schools.isNotEmpty) {
      return;
    }

    if (_isLoadingSchools) {
      while (_isLoadingSchools) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_schoolsLoaded) return;
      if (retryCount == 0) {
        await Future.delayed(retryDelay);
        return getAllSchools(retryCount: retryCount + 1);
      }
      return;
    }

    _isLoadingSchools = true;

    try {
      isLoading.value = true;
      final response = await _apiService.get(ApiConstants.getAllSchools);

      if (response.data['ok'] == true) {
        final schoolList = response.data['data'] as List;
        schools.value = schoolList.map((json) => School.fromJson(json)).toList();
        _schoolsLoaded = true;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load schools', AppTheme.errorRed);
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.connectionError) {
        if (retryCount < maxRetries) {
          await Future.delayed(retryDelay);
          _isLoadingSchools = false;
          return getAllSchools(retryCount: retryCount + 1);
        } else {
          _showSnackbar('Network Error', 'Unable to connect to server. Please check your internet connection.', AppTheme.errorRed);
        }
      } else {
        if (e is DioException && e.response?.statusCode != 403) {
          _showSnackbar('Error', 'An error occurred while loading schools.', AppTheme.errorRed);
        }
      }
    } finally {
      isLoading.value = false;
      _isLoadingSchools = false;
    }
  }

  // Load user's own school using their schoolId
  Future<void> _loadUserSchool() async {
    try {
      final authController = Get.find<AuthController>();
      final schoolId = authController.user.value?.schoolId;

      if (schoolId != null) {
        try {
          final response = await _apiService.get('${ApiConstants.getSingleSchool}/$schoolId');
          if (response.data['ok'] == true) {
            final schoolData = response.data['data'];
            final school = School.fromJson(schoolData);
            
            selectedSchool.value = school;
            schools.value = [school];
            return;
          }
        } catch (e) {
          // Continue to fallback
        }
        
        final userSchool = authController.userSchool.value;
        if (userSchool != null && userSchool['name'] != null) {
          final school = School(
            id: schoolId,
            name: userSchool['name'] ?? schoolId,
            schoolCode: userSchool['schoolCode'],
            email: userSchool['email'] ?? '',
            phoneNo: userSchool['phoneNo'] ?? '',
            address: userSchool['address'] ?? '',
            currentAcademicYear: userSchool['currentAcademicYear'] ?? '',
            logo: userSchool['logo'],
          );

          selectedSchool.value = school;
          schools.value = [school];
        } else {
          selectedSchool.value = null;
          schools.value = [];
        }
      } else {
        selectedSchool.value = null;
        schools.value = [];
      }
    } catch (e) {
      selectedSchool.value = null;
      schools.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  // Get single school
  Future<void> getSchool(String schoolId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('${ApiConstants.getSingleSchool}/$schoolId');
      if (response.data['ok'] == true) {
        selectedSchool.value = School.fromJson(response.data['data']);
      } else {
         _showSnackbar('Error', response.data['message'] ?? 'Failed to load school', AppTheme.errorRed);
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final errorMessage = e.response!.data['message'] ?? 'An error occurred while loading the school.';
        _showSnackbar('Error', errorMessage, AppTheme.errorRed);
      } else {
        _showSnackbar('Error', 'An error occurred while loading the school.', AppTheme.errorRed);
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Update school
  Future<void> updateSchool(String schoolId, Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final response =
          await _apiService.put('${ApiConstants.updateSchool}/$schoolId', data: data);
      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'School updated successfully', AppTheme.successGreen);
        await getAllSchools();
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to update school', AppTheme.errorRed);
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final errorMessage = e.response!.data['message'] ?? 'An error occurred while updating the school.';
        _showSnackbar('Error', errorMessage, AppTheme.errorRed);
      } else {
        _showSnackbar('Error', 'An error occurred while updating the school.', AppTheme.errorRed);
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Update school logo with size validation
  Future<void> updateSchoolLogo(String schoolId, File logoFile) async {
    try {
      isLoading.value = true;
      
      // Validate image size
      await _compressImage(logoFile);
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          logoFile.path,
          filename: 'logo.${logoFile.path.split('.').last}',
        ),
      });
      
      final response = await _apiService.dio.put(
        '${ApiConstants.updateSchoolLogo}/$schoolId',
        data: formData,
      );
      
      if (response.statusCode == 200) {
        
        // Update the school object with new logo URL if provided
        if (response.data['data'] != null) {
          final updatedSchool = School.fromJson(response.data['data']);
          final index = schools.indexWhere((s) => s.id == schoolId);
          if (index != -1) {
            schools[index] = updatedSchool;
            
            // Force reactive update
            schools.refresh();
          }
        }

        _showSnackbar('Success', 'School logo updated successfully', AppTheme.successGreen);
      } else {
        
        _showSnackbar('Error', response.data['message'] ?? 'Failed to update logo', AppTheme.errorRed);
      }
    } catch (e) {
      if (e.toString().contains('too large')) {
        _showSnackbar('Error', 'Image file is too large. Please select an image smaller than 250KB.', AppTheme.errorRed);
      } else if (e is DioException && e.response?.statusCode == 413) {
        _showSnackbar('Error', 'Image file is too large. Please select a smaller image.', AppTheme.errorRed);
      } else if (e is DioException && e.response?.data != null) {
        final errorMessage = e.response!.data['message'] ?? 'An error occurred while updating the logo.';
        _showSnackbar('Error', errorMessage, AppTheme.errorRed);
      } else {
        _showSnackbar('Error', 'An error occurred while updating the logo.', AppTheme.errorRed);
      }
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<File> _compressImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      
      // If file is already small enough, return as is
      if (bytes.length <= 250 * 1024) return file; // 250KB limit
      
      // Simple size reduction by reading and writing with reduced quality
      // This is a basic approach - just limit file size
      if (bytes.length > 500 * 1024) {
        // For very large files, show error
        throw Exception('Image too large');
      }
      
      return file;
    } catch (e) {
      
      throw Exception('Image file is too large. Please select a smaller image.');
    }
  }
  // Helper to check access
  bool hasModuleAccess(String moduleName) {

    // Use the SubscriptionController instead of local subscription data
    if (Get.isRegistered<SubscriptionController>()) {
      
      final subscriptionController = Get.find<SubscriptionController>();
      final hasAccess = subscriptionController.hasModuleAccess(moduleName);
      
      return hasAccess;
    }

    return false;
  }

  // Show enhanced edit school dialog with all details and image management
  void showEditSchoolDialog(School school) {

    for (var s in schools) {
      if (s.id == school.id) {
        
      }
    }
    
    // Get the latest school data from the schools list
    final currentSchool = schools.firstWhere((s) => s.id == school.id, orElse: () => school);

    final nameController = TextEditingController(text: currentSchool.name);
    final emailController = TextEditingController(text: currentSchool.email);
    final phoneController = TextEditingController(text: currentSchool.phoneNo);
    final addressController = TextEditingController(text: currentSchool.address);
    final academicYearController = TextEditingController(text: currentSchool.currentAcademicYear);
    final schoolCodeController = TextEditingController(text: currentSchool.schoolCode);
    
    final selectedImage = Rx<File?>(null);
    final hasExistingLogo = currentSchool.logo != null && 
                           currentSchool.logo!['url'] != null && 
                           currentSchool.logo!['url']!.isNotEmpty;
    
    final logoUrl = RxString(currentSchool.logo?['url'] ?? '');
    
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final isTablet = screenWidth > 600;
            final isLandscape = screenWidth > screenHeight;
            
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 600 : screenWidth * 0.95,
                  maxHeight: screenHeight * 0.9,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, AppTheme.primaryBlue.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(isTablet ? 24 : 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.8)],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit School',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isTablet ? 22 : 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  currentSchool.name,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: isTablet ? 14 : 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Get.back(),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isTablet ? 24 : 20),
                        child: isLandscape && isTablet
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: _buildLogoSection(selectedImage, logoUrl, currentSchool, isTablet),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 2,
                                    child: _buildFormSection(
                                      nameController,
                                      emailController,
                                      phoneController,
                                      addressController,
                                      academicYearController,
                                      schoolCodeController,
                                      isTablet,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildLogoSection(selectedImage, logoUrl, currentSchool, isTablet),
                                  const SizedBox(height: 24),
                                  _buildFormSection(
                                    nameController,
                                    emailController,
                                    phoneController,
                                    addressController,
                                    academicYearController,
                                    schoolCodeController,
                                    isTablet,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    
                    // Actions
                    Container(
                      padding: EdgeInsets.all(isTablet ? 24 : 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Get.back(),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: isTablet ? 16 : 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: isTablet ? 16 : 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Obx(() => ElevatedButton(
                              onPressed: isLoading.value
                                  ? null
                                  : () async {
                                      if (nameController.text.trim().isEmpty) {
                                        _showSnackbar('Error', 'School name is required', AppTheme.errorRed);
                                        return;
                                      }
                                      
                                      // Update school details only (logo handled separately)
                                      await updateSchool(currentSchool.id, {
                                        'name': nameController.text.trim(),
                                        'email': emailController.text.trim(),
                                        'phoneNo': phoneController.text.trim(),
                                        'address': addressController.text.trim(),
                                        'currentAcademicYear': academicYearController.text.trim(),
                                      });
                                      
                                      Navigator.pop(Get.context!); // Close dialog after successful update
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: isTablet ? 16 : 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: isLoading.value
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Update School',
                                      style: TextStyle(
                                        fontSize: isTablet ? 16 : 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            )),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      barrierDismissible: false,
    );
  }
  
  Widget _buildLogoSection(Rx<File?> selectedImage, RxString logoUrl, School currentSchool, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'School Logo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 18 : 16,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Obx(() => Container(
            height: isTablet ? 160 : 140,
            width: isTablet ? 160 : 140,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: selectedImage.value != null
                ? GestureDetector(
                    onTap: () => _showFullScreenImage(selectedImage.value!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        selectedImage.value!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : logoUrl.value.isNotEmpty
                    ? GestureDetector(
                        onTap: () => _showNetworkImageFullScreen(logoUrl.value),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            logoUrl.value,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      size: isTablet ? 48 : 40,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Failed to load',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school,
                              size: isTablet ? 48 : 40,
                              color: AppTheme.primaryBlue.withOpacity(0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No Logo',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
          )),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 85,
                  );
                  if (pickedFile != null) {
                    selectedImage.value = File(pickedFile.path);
                  }
                },
                icon: Icon(
                  Icons.image,
                  size: isTablet ? 18 : 16,
                ),
                label: Obx(() => Text(
                  selectedImage.value != null ? 'Change' : 'Select Logo',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                  ),
                )),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: AppTheme.primaryBlue,
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 16 : 12,
                    vertical: isTablet ? 12 : 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Obx(() => selectedImage.value != null
                ? ElevatedButton(
                    onPressed: () async {
                      await updateSchoolLogo(currentSchool.id, selectedImage.value!);
                      // Update the logoUrl directly from the response
                      final updatedSchool = schools.firstWhere((s) => s.id == currentSchool.id);
                      logoUrl.value = updatedSchool.logo?['url'] ?? '';
                      selectedImage.value = null; // Clear after upload
                      
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 16 : 12,
                        vertical: isTablet ? 12 : 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Upload',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                      ),
                    ),
                  )
                : const SizedBox()),
          ],
        ),
        if (selectedImage.value != null || logoUrl.value.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: () {
                selectedImage.value = null;
                logoUrl.value = '';
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 16 : 12,
                  vertical: isTablet ? 8 : 6,
                ),
              ),
              child: Text(
                'Remove Logo',
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildFormSection(
    TextEditingController nameController,
    TextEditingController emailController,
    TextEditingController phoneController,
    TextEditingController addressController,
    TextEditingController academicYearController,
    TextEditingController schoolCodeController,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'School Information',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 18 : 16,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: nameController,
          label: 'School Name',
          icon: Icons.school,
          required: true,
          isTablet: isTablet,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: schoolCodeController,
          label: 'School Code',
          icon: Icons.code,
          enabled: false,
          isTablet: isTablet,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: emailController,
          label: 'Email Address',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          isTablet: isTablet,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: phoneController,
          label: 'Phone Number',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          isTablet: isTablet,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: addressController,
          label: 'Address',
          icon: Icons.location_on,
          maxLines: 3,
          isTablet: isTablet,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: academicYearController,
          label: 'Academic Year',
          icon: Icons.calendar_today,
          isTablet: isTablet,
        ),
      ],
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    required bool isTablet,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: isTablet ? 16 : 14,
        color: enabled ? AppTheme.primaryText : Colors.grey.shade500,
      ),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: enabled 
                ? AppTheme.primaryBlue.withOpacity(0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: enabled 
                ? AppTheme.primaryBlue
                : Colors.grey.shade400,
            size: isTablet ? 20 : 18,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 14,
          vertical: isTablet ? 16 : 14,
        ),
        labelStyle: TextStyle(
          color: enabled ? AppTheme.primaryText : Colors.grey.shade400,
          fontSize: isTablet ? 14 : 12,
        ),
      ),
    );
  }
  
  void _showNetworkImageFullScreen(String imageUrl) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image, color: Colors.white, size: 64),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> pickAndUploadLogo(String schoolId) async {
    // Request permissions first
    final picker = ImagePicker();
    
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        final logoFile = File(pickedFile.path);
        final bytes = await logoFile.readAsBytes();
        
        // Show image selection dialog
        _showImageSelectionDialog(schoolId, logoFile, bytes);
      }
    } catch (e) {
      if (e.toString().contains('permission')) {
        _showSnackbar('Permission Required', 'Please grant permission to access photos', AppTheme.warningYellow);
      } else {
        _showSnackbar('Error', 'Failed to pick image: ${e.toString()}', AppTheme.errorRed);
      }
    }
  }
  
  void _showImageSelectionDialog(String schoolId, File logoFile, Uint8List bytes) {
    final selectedImage = Rx<File?>(logoFile);
    
    Get.dialog(
      AlertDialog(
        title: const Text('Upload School Logo'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() => selectedImage.value != null
                  ? GestureDetector(
                      onTap: () => _showFullScreenImage(selectedImage.value!),
                      child: Container(
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            selectedImage.value!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('No image selected'),
                      ),
                    )),
              const SizedBox(height: 16),
              Text('File size: ${(bytes.length / 1024).round()}KB'),
              if (bytes.length > 250 * 1024)
                const Text(
                  'Warning: File size exceeds 250KB limit',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              const SizedBox(height: 8),
              const Text(
                'Tap image to view full size',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final newFile = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1024,
                        maxHeight: 1024,
                        imageQuality: 85,
                      );
                      if (newFile != null) {
                        selectedImage.value = File(newFile.path);
                      }
                    },
                    child: const Text('Choose Different'),
                  ),
                  TextButton(
                    onPressed: () {
                      selectedImage.value = null;
                    },
                    child: const Text('Remove'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(() => ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,

            ),
            onPressed: selectedImage.value != null && bytes.length <= 250 * 1024
                ? () {
                    Navigator.pop(Get.context!);
                    updateSchoolLogo(schoolId, selectedImage.value!);
                  }
                : null,
            child: const Text('Upload'),
          )),
        ],
      ),
    );
  }
  
  void _showFullScreenImage(File imageFile) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.file(
                  imageFile,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> deleteSchool(String schoolId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.delete('${ApiConstants.deleteSchool}/$schoolId');
      
      if (response.statusCode == 200 && (response.data['ok'] == true || response.data['message']?.contains('success') == true)) {
        _showSnackbar('Success', 'School deleted successfully', AppTheme.successGreen);
        
        // Remove from list and update UI
        schools.removeWhere((school) => school.id == schoolId);
        
        // Update selected school if needed
        if (selectedSchool.value?.id == schoolId) {
          selectedSchool.value = schools.isNotEmpty ? schools.first : null;
        }
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to delete school', AppTheme.errorRed);
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final errorMessage = e.response!.data['message'] ?? 'An error occurred while deleting the school.';
        _showSnackbar('Error', errorMessage, AppTheme.errorRed);
      } else {
        _showSnackbar('Error', 'An error occurred while deleting the school.', AppTheme.errorRed);
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Get all classes for a school
  Future<void> getAllClasses(String schoolId) async {
    try {
      
      isLoading.value = true;
      final response =
          await _apiService.get('${ApiConstants.getAllClasses}/$schoolId');
      
      
      
      if (response.data['ok'] == true) {
        final classList = response.data['data'] as List;
        
        final uniqueClasses = <SchoolClass>[];
        final seenIds = <String>{};
        
        for (var json in classList) {
          final schoolClass = SchoolClass.fromJson(json);
          if (!seenIds.contains(schoolClass.id)) {
            seenIds.add(schoolClass.id);
            uniqueClasses.add(schoolClass);
          }
        }
        
        // Sort classes using a custom comparator that handles both numeric and text-based class names
        uniqueClasses.sort((a, b) {
          // Since most classes have order 0 or 1, prioritize name-based sorting
          final result = _compareClassNames(a.name, b.name);
          return result;
        });
        
        classes.value = uniqueClasses;
        

        // Notify listeners that classes have been loaded
        update();
      } else {
        
         _showSnackbar('Error', response.data['message'] ?? 'Failed to load classes', AppTheme.errorRed);
      }
    } on DioException catch (e) {
      
      
      
      
      
      // Handle 403 (Forbidden) errors - show error message
      if (e.response?.statusCode == 403) {
        classes.value = []; // Clear classes list
        String errorMessage = 'You do not have permission to access classes';
        if (e.response?.data != null) {
          final errorData = e.response!.data;
          if (errorData is Map && errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        }
        
        _showSnackbar('Access Denied', errorMessage, AppTheme.errorRed);
        return;
      }
      
      _showSnackbar('Error', 'An error occurred while loading classes.', AppTheme.errorRed);
    } catch (e) {
      
      _showSnackbar('Error', 'An error occurred while loading classes.', AppTheme.errorRed);
    } finally {
      isLoading.value = false;
      
    }
  }

  // Create class
  Future<void> createClass(String schoolId, Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      
      final response = await _apiService
          .post('${ApiConstants.createClass}/$schoolId', data: data);

      // Check for both successful status codes and response structure
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['ok'] == true || response.data['message']?.contains('success') == true) {
          _showSnackbar('Success', 'Class created successfully', AppTheme.successGreen);
        } else {
          // Even if ok is not true, if status is 200/201, it might be successful
          
          _showSnackbar('Success', 'Class created successfully', AppTheme.successGreen);
        }
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to create class', AppTheme.errorRed);
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data != null) {
          final errorMessage = e.response!.data['message'] ?? 'An error occurred while creating the class.';
          _showSnackbar('Error', errorMessage, AppTheme.errorRed);
        } else {
          _showSnackbar('Error', 'An error occurred while creating the class.', AppTheme.errorRed);
        }
        // Don't show error immediately, refresh classes first to check if it was actually created
        await getAllClasses(schoolId);
        // If we have classes after refresh, it might have been created successfully
        if (classes.isNotEmpty) {
          _showSnackbar('Success', 'Class created successfully', AppTheme.successGreen);
        }
      } else {
        _showSnackbar('Error', 'An error occurred while creating the class.', AppTheme.errorRed);
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Update class
  Future<void> updateClass(String classId, Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final response =
          await _apiService.put('${ApiConstants.updateClass}/$classId', data: data);
      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Class updated successfully', AppTheme.successGreen);
        // Refresh classes list
        if (selectedSchool.value != null) {
          await getAllClasses(selectedSchool.value!.id);
        }
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to update class', AppTheme.errorRed);
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final errorMessage = e.response!.data['message'] ?? 'An error occurred while updating the class.';
        _showSnackbar('Error', errorMessage, AppTheme.errorRed);
      } else {
        _showSnackbar('Error', 'An error occurred while updating the class.', AppTheme.errorRed);
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Delete class
  Future<void> deleteClass(String classId) async {
    try {
      isLoading.value = true;
      final response =
          await _apiService.delete('${ApiConstants.deleteClass}/$classId');
      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Class deleted successfully', AppTheme.successGreen);
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to delete class', AppTheme.errorRed);
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final errorMessage = e.response!.data['message'] ?? 'An error occurred while deleting the class.';
        _showSnackbar('Error', errorMessage, AppTheme.errorRed);
      } else {
        _showSnackbar('Error', 'An error occurred while deleting the class.', AppTheme.errorRed);
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Get all sections
  Future<void> getAllSections({String? classId, String? schoolId}) async {
    try {
      
      String url = ApiConstants.getAllSections;
      Map<String, String> queryParams = {};

      if (classId != null) queryParams['classId'] = classId;
      if (schoolId != null) queryParams['schoolId'] = schoolId;

      final response = await _apiService.get(url, queryParameters: queryParams);
      
      

      if (response.data['ok'] == true) {
        final sectionList = response.data['data'] as List;
        
        final uniqueSections = <Section>[];
        final seenIds = <String>{};
        
        for (var json in sectionList) {
          final section = Section.fromJson(json);
          if (!seenIds.contains(section.id)) {
            seenIds.add(section.id);
            uniqueSections.add(section);
          }
        }
        
        sections.value = uniqueSections; // Set immediately
        

        update(); // Notify GetBuilder listeners
      } else {
        
        // Don't show error snackbar for missing sections, just log it
        WidgetsBinding.instance.addPostFrameCallback((_) {
          sections.value = [];
        });
      }
    } on DioException catch (e) {
      
      
      
      

      // Handle 403 (Forbidden) errors - show error message
      if (e.response?.statusCode == 403) {
        sections.value = []; // Clear sections list
        String errorMessage = 'You do not have permission to access sections';
        if (e.response?.data != null) {
          final errorData = e.response!.data;
          if (errorData is Map && errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        }
        
        _showSnackbar('Access Denied', errorMessage, AppTheme.errorRed);
        return;
      }
      // Only show error for non-404 errors (404 means no sections exist)
      if (e.response?.statusCode != 404) {
        _showSnackbar('Error', 'Failed to load sections for this class', AppTheme.errorRed);
      }
      // Set empty sections on error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        sections.value = [];
      });
    } catch (e) {
      
      _showSnackbar('Error', 'An error occurred while loading sections.', AppTheme.errorRed);
      // Set empty sections on error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        sections.value = [];
      });
    }
  }

  // Create section
  Future<void> createSection(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final response = await _apiService.post(ApiConstants.createSection, data: data);
      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Section created successfully', AppTheme.successGreen);
        await getAllSections(schoolId: data['schoolId']);
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to create section', AppTheme.errorRed);
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final errorMessage = e.response!.data['message'] ?? 'An error occurred while creating the section.';
        _showSnackbar('Error', errorMessage, AppTheme.errorRed);
      } else {
        _showSnackbar('Error', 'An error occurred while creating the section.', AppTheme.errorRed);
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Update section
  Future<void> updateSection(String sectionId, Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final response = await _apiService
          .put('${ApiConstants.updateSection}/$sectionId', data: data);
      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Section updated successfully', AppTheme.successGreen);
        // Refresh sections list
        if (selectedSchool.value != null) {
          await getAllSections(schoolId: selectedSchool.value!.id);
        }
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to update section', AppTheme.errorRed);
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final errorMessage = e.response!.data['message'] ?? 'An error occurred while updating the section.';
        _showSnackbar('Error', errorMessage, AppTheme.errorRed);
      } else {
        _showSnackbar('Error', 'An error occurred while updating the section.', AppTheme.errorRed);
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Delete section
  Future<void> deleteSection(String sectionId) async {
    try {
      isLoading.value = true;
      final response =
          await _apiService.delete('${ApiConstants.deleteSection}/$sectionId');
      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Section deleted successfully', AppTheme.successGreen);
      } else {
         _showSnackbar('Error', response.data['message'] ?? 'Failed to delete section', AppTheme.errorRed);
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final errorMessage = e.response!.data['message'] ?? 'An error occurred while deleting the section.';
        _showSnackbar('Error', errorMessage, AppTheme.errorRed);
      } else {
        _showSnackbar('Error', 'An error occurred while deleting the section.', AppTheme.errorRed);
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Get all students
  Future<void> getAllStudents({String? schoolId, String? classId, String? sectionId}) async {
    try {
      isLoading.value = true;
      
      print('🔍 getAllStudents called with: schoolId=$schoolId, classId=$classId, sectionId=$sectionId');
      
      // Build query parameters
      Map<String, String> queryParams = {};
      if (schoolId != null) queryParams['schoolId'] = schoolId;
      if (classId != null) queryParams['classId'] = classId;
      if (sectionId != null && sectionId.isNotEmpty) queryParams['sectionId'] = sectionId;
      queryParams['limit'] = '1000';

      print('📤 API Query Params: $queryParams');

      final response = await _apiService.get(ApiConstants.getAllStudents, queryParameters: queryParams);

      if (response.data['ok'] == true) {
        final studentList = response.data['data'] as List;
        print('📥 API returned ${studentList.length} students');
        
        students.value = studentList.map((json) {
          try {
            return Student.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            return null;
          }
        }).where((student) => student != null).cast<Student>().toList();
        
        print('✅ Final students count: ${students.length}');
      }
    } catch (e) {
      print('❌ Error loading students: $e');
      if (e is DioException && e.response?.data != null) {
        _showSnackbar('Error', e.response!.data['message'] ?? 'Failed to load students', AppTheme.errorRed);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadTeachers() async {
    
    
    
    if (selectedSchool.value == null) {
      
      return;
    }
    
    // Check if already loaded for THIS school
    if (_teachersLoaded && teachers.isNotEmpty) {
      
      return;
    }
    
    try {
      
      
      // Use the same endpoint as UserManagementController
      final response = await _apiService.get(
        '${ApiConstants.getUsersByRole}/teacher/${selectedSchool.value!.id}'
      );
      
      
      
      
      if (response.statusCode == 200 && response.data != null && response.data['ok'] == true) {
        final data = response.data['data'] as List? ?? [];
        
        
        teachers.value = data.map((teacher) => {
          '_id': teacher['_id'],
          'userName': teacher['userName'] ?? teacher['name'] ?? 'Unknown',
        }).toList()..sort((a, b) => 
          (a['userName'] as String).toLowerCase().compareTo((b['userName'] as String).toLowerCase()));
        
        _teachersLoaded = true;
        
        
      } else {
        
      }
    } catch (e) {
      
      if (e is DioException) {
        
        
        
        
      }
    }
  }
  
  // Reset teachers cache (call when school changes)
  void resetTeachers() {
    
    
    teachers.clear();
    _teachersLoaded = false;
    
  }

  // Create student
  Future<bool> createStudent(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final response = await _apiService.post(ApiConstants.createStudent, data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar(
          'Success', 
          'Student created successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        
        await getAllStudents(schoolId: data['schoolId']);
        return true;
      } else {
        Get.snackbar(
          'Error', 
          response.data['message'] ?? 'Failed to create student',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        
        Get.snackbar(
          'Error', 
          e.response?.data?['message'] ?? 'An error occurred',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
      } else {
        
        Get.snackbar(
          'Error', 
          'An unknown error occurred',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update student
  Future<bool> updateStudent(String studentId, Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      
      final response = await _apiService.put(
          '${ApiConstants.updateStudent}/$studentId',
          data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackbar('Success', 'Student updated successfully', AppTheme.successGreen);
        if (selectedSchool.value != null) {
          await getAllStudents(schoolId: selectedSchool.value!.id);
        }
        return true;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to update student', AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final errorMessage = e.response!.data['message'] ?? 'Failed to update student';
        _showSnackbar('Error', errorMessage, AppTheme.errorRed);
      } else {
        _showSnackbar('Error', 'Failed to update student: ${e.toString()}', AppTheme.errorRed);
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Delete student
  Future<void> deleteStudent(String studentId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.delete('${ApiConstants.deleteStudent}/$studentId');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackbar('Success', 'Student deleted successfully', AppTheme.successGreen);
        if (selectedSchool.value != null) {
          await getAllStudents(schoolId: selectedSchool.value!.id);
        }
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to delete student', AppTheme.errorRed);
      }
    } catch (e) {
      // Even if there's an error, refresh the list to check if deletion actually worked
      if (selectedSchool.value != null) {
        await getAllStudents(schoolId: selectedSchool.value!.id);
      }
      
      if (e is DioException) {
        if (e.response?.statusCode == 500) {
          _showSnackbar('Warning', 'Student may have been deleted. Please check the list.', AppTheme.warningYellow);
        } else if (e.response?.data != null) {
          final errorMessage = e.response!.data['message'] ?? 'An error occurred while deleting the student.';
          _showSnackbar('Error', errorMessage, AppTheme.errorRed);
        } else {
          _showSnackbar('Error', 'An error occurred while deleting the student.', AppTheme.errorRed);
        }
      } else {
        _showSnackbar('Error', 'An error occurred while deleting the student.', AppTheme.errorRed);
      }
    } finally {
      isLoading.value = false;
    }
  }
  // Update social media links
  Future<void> updateSocialMedia(String schoolId, String platform, String link) async {
    try {
      final response = await _apiService.put(
        '/api/school/update/socialplatform/$schoolId',
        data: {
          'socialPlatform': platform,
          'link': link,
        },
      );
      
      if (response.data['ok'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to update social media');
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final errorMessage = e.response!.data['message'] ?? 'Failed to update social media';
        throw Exception(errorMessage);
      } else {
        throw Exception('Failed to update $platform link');
      }
    }
  }

  // Get social media links
  Future<Map<String, String?>> getSocialMediaLinks(String schoolId) async {
    try {
      final response = await _apiService.get('/api/school/getschool/socialplatform/$schoolId');
      
      if (response.data['ok'] == true) {
        final socialPlatform = response.data['data']['socialPlatform'] as Map<String, dynamic>;
        return {
          'instagram': socialPlatform['instagram'],
          'facebook': socialPlatform['facebook'],
          'linkedin': socialPlatform['linkedin'],
          'youtube': socialPlatform['youtube'],
        };
      }

      return {'instagram': null, 'facebook': null, 'linkedin': null, 'youtube': null};
    } catch (e) {
      
      return {'instagram': null, 'facebook': null, 'linkedin': null, 'youtube': null};
    }
  }

  // Show social media dialog
  void showSocialMediaDialog(School school) {
    final instagramController = TextEditingController();
    final facebookController = TextEditingController();
    final linkedinController = TextEditingController();
    final youtubeController = TextEditingController();
    final isLoadingLinks = true.obs;

    // Load existing links
    getSocialMediaLinks(school.id).then((links) {
      instagramController.text = links['instagram'] ?? '';
      facebookController.text = links['facebook'] ?? '';
      linkedinController.text = links['linkedin'] ?? '';
      youtubeController.text = links['youtube'] ?? '';
      isLoadingLinks.value = false;
    });

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade50, Colors.blue.shade50, Colors.pink.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 25,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient and icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.blue.shade400, Colors.pink.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.share, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Social Media Links',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              school.name,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Content
                Obx(() => isLoadingLinks.value
                    ? Container(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade400),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Loading social media links...',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          _buildColorfulSocialField(
                            controller: instagramController,
                            label: 'Instagram URL',
                            icon: Icons.camera_alt,
                            color: Colors.pink,
                            gradient: [Colors.pink.shade400, Colors.purple.shade400],
                          ),
                          const SizedBox(height: 16),
                          _buildColorfulSocialField(
                            controller: facebookController,
                            label: 'Facebook URL',
                            icon: Icons.facebook,
                            color: Colors.blue,
                            gradient: [Colors.blue.shade400, Colors.indigo.shade400],
                          ),
                          const SizedBox(height: 16),
                          _buildColorfulSocialField(
                            controller: linkedinController,
                            label: 'LinkedIn URL',
                            icon: Icons.business,
                            color: Colors.indigo,
                            gradient: [Colors.indigo.shade400, Colors.blue.shade600],
                          ),
                          const SizedBox(height: 16),
                          _buildColorfulSocialField(
                            controller: youtubeController,
                            label: 'YouTube URL',
                            icon: Icons.play_circle,
                            color: Colors.red,
                            gradient: [Colors.red.shade400, Colors.orange.shade400],
                          ),
                        ],
                      )),
                
                const SizedBox(height: 28),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey.shade300, Colors.grey.shade400],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Get.back(),
                            child: const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.close, color: Colors.white, size: 20),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green.shade400, Colors.teal.shade400],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              final links = {
                                'instagram': instagramController.text.trim(),
                                'facebook': facebookController.text.trim(),
                                'linkedin': linkedinController.text.trim(),
                                'youtube': youtubeController.text.trim(),
                              };
                              
                              try {
                                for (final entry in links.entries) {
                                  await updateSocialMedia(school.id, entry.key, entry.value);
                                }
                                
                                // Safe navigation check
                                if (Get.isDialogOpen == true) {
                                  Get.back();
                                }
                                
                                // Delay snackbar to avoid navigation conflicts
                                await Future.delayed(const Duration(milliseconds: 100));
                                
                                if (Get.context != null) {
                                  Get.snackbar(
                                    'Success', 
                                    'Social media links updated successfully',
                                    backgroundColor: AppTheme.successGreen, 
                                    colorText: Colors.white,
                                  );
                                }
                              } catch (e) {
                                // Safe navigation check
                                if (Get.isDialogOpen == true) {
                                  Get.back();
                                }
                                
                                await Future.delayed(const Duration(milliseconds: 100));
                                
                                if (Get.context != null) {
                                  Get.snackbar(
                                    'Error', 
                                    e.toString().replaceAll('Exception: ', ''),
                                    backgroundColor: AppTheme.errorRed, 
                                    colorText: Colors.white,
                                  );
                                }
                              }
                            },
                            child: const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.save, color: Colors.white, size: 20),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Save',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorfulSocialField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: color, fontWeight: FontWeight.w500),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          hintText: 'Enter $label (leave blank to remove)',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 13,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: color, width: 2),
          ),
        ),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Filter students by class ID
  void getStudentsByClass(String classId) {
    if (selectedSchool.value == null) return;

    isLoading.value = true;
    students.clear();

    // Get all students for the school and filter by class
    getAllStudents(schoolId: selectedSchool.value!.id).then((_) {
      // Filter students by classId after loading
      final filteredStudents = students.where((student) {
        // Assuming student has a classId field - check if it matches
        final studentClassId = student.classId ?? '';
        return studentClassId == classId;
      }).toList();

      students.assignAll(filteredStudents);
      isLoading.value = false;
    }).catchError((e) {
      
      isLoading.value = false;
    });
  }

  // Custom class name comparator that handles both numeric and text-based class names
  int _compareClassNames(String a, String b) {
    final aLower = a.toLowerCase().trim();
    final bLower = b.toLowerCase().trim();
    
    // Define priority order for common class types
    final priorityOrder = {
      'lkg': 1,
      'ukg': 2,
      'i': 3,
      'ii': 4,
      'iii': 5,
      'iv': 6,
      'v': 7,
      'vi': 8,
      'vii': 9,
      'viii': 10,
      'ix': 11,
      'x': 12,
      'xi': 13,
      'xii': 14,
    };
    
    // Check if both are in priority list
    final aPriority = priorityOrder[aLower];
    final bPriority = priorityOrder[bLower];
    
    if (aPriority != null && bPriority != null) {
      return aPriority.compareTo(bPriority);
    }
    
    if (aPriority != null) return -1;
    if (bPriority != null) return 1;
    
    // Fallback to alphabetical
    return aLower.compareTo(bLower);
  }
}
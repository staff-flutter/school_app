import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:school_app/app/controllers/school_controller.dart';
import '../data/services/api_service.dart';
import '../data/services/subscription_service.dart';
import '../core/constants/api_constants.dart';
import '../modules/auth/controllers/auth_controller.dart';
import '../data/models/school_models.dart';
import '../core/permissions/permission_system.dart';
import '../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../controllers/my_children_controller.dart';

class AnnouncementController extends GetxController {
  final ApiService _apiService = Get.find();
  SubscriptionService? _subscriptionService;
  final AuthController _authController = Get.find();

  final isLoading = false.obs;
  final uploadProgress = 0.0.obs;
  final announcements = <Map<String, dynamic>>[].obs;
  final filteredAnnouncements = <Map<String, dynamic>>[].obs;
  final selectedAnnouncement = Rxn<Map<String, dynamic>>();
  final schools = <School>[].obs;
  final selectedSchool = Rxn<School>();
  final selectedFilter = 'all'.obs; // Filter for target audience

  @override
  void onInit() {
    super.onInit();
    // Try to get subscription service after initialization
    if (Get.isRegistered<SubscriptionService>()) {
      _subscriptionService = Get.find<SubscriptionService>();
      
    } else {
      
    }
    
    getAllSchools();

    // When the selected school changes, fetch new announcements
    ever(selectedSchool, (School? school) {
      if (school != null) {
        
        // Add a small delay to ensure subscription is loaded
        Future.delayed(const Duration(milliseconds: 500), () {
          getAllAnnouncements(school.id);
        });
      } else {
        
      }
    });
  }

  bool _hasPermission(List<String> allowedRoles) {
    final userRole = _authController.user.value?.role?.toLowerCase();
    return allowedRoles.map((r) => r.toLowerCase()).contains(userRole);
  }

  bool _hasSubscriptionAccess(String schoolId) {

    // Only check subscription for correspondent and principal roles
    final userRole = _authController.user.value?.role?.toLowerCase() ?? '';
    final requiresSubscriptionCheck = ['correspondent', 'principal'].contains(userRole);

    if (!requiresSubscriptionCheck) {
      
      return true;
    }

    if (_subscriptionService == null) {
      
      return false;
    }

    final hasAccess = _subscriptionService!.hasModuleAccess('announcement', schoolId);
    
    return hasAccess;
  }

  // Public method for UI access
  bool hasSubscriptionAccess(String schoolId) {
    return _hasSubscriptionAccess(schoolId);
  }

  // Permission checking methods
  bool get canCreateAnnouncements => _authController.hasPermission(Permission.NOTICES_CREATE);
  bool get canViewAnnouncements => _authController.hasPermission(Permission.NOTICES_VIEW);

  // Fetch all schools
  Future<void> getAllSchools() async {

    // Check if user has permission to access all schools (like correspondents)
    if (_canAccessAllSchools) {
      
      await _loadAllSchools();
    } else {
      
      // Since regular users have a schoolId, just load their school directly
      await _loadUserSchool();
    }

    if (selectedSchool.value != null) {
      
    } else {
      
    }
  }

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

  // Load all schools for users with permission
  Future<void> _loadAllSchools() async {
    try {
      isLoading.value = true;
      
      final response = await _apiService.get(ApiConstants.getAllSchools);

      if (response.data['ok'] == true) {
        final schoolList = response.data['data'] as List;
        schools.value =
            schoolList.map((json) => School.fromJson(json)).toList();

        // Auto-select first school if none selected
        if (schools.isNotEmpty && selectedSchool.value == null) {
          selectedSchool.value = schools.first;
          // Load announcements for the first school with delay
          Future.delayed(const Duration(milliseconds: 500), () {
            getAllAnnouncements(schools.first.id);
          });
        }
      } else {
        
        await _loadUserSchool();
      }
    } catch (e) {

      await _loadUserSchool();
    } finally {
      isLoading.value = false;
    }
  }

  // Force refresh schools (bypasses any caching)
  Future<void> refreshSchools() async {
    
    await _loadUserSchool();
    
  }

  // Load user's own school using their schoolId
  Future<void> _loadUserSchool() async {
    
    try {
      isLoading.value = true;
      final user = _authController.user.value;
      final schoolData = user?.schoolId;

      if (schoolData != null && user != null) {

        // Extract school information from the schoolId object in login response
        String schoolId, schoolName;
        
        if (schoolData is Map<String, dynamic>) {
          // schoolId is an object with school details
          schoolId = schoolData['_id'] ?? '';
          schoolName = schoolData['name'] ?? 'Unknown School';
          
          final school = School(
            id: schoolId,
            name: schoolName,
            schoolCode: schoolData['schoolCode'] ?? user.schoolCode ?? '',
            email: schoolData['email'] ?? '',
            phoneNo: schoolData['phoneNo'] ?? '',
            address: schoolData['address'] ?? '',
            currentAcademicYear: schoolData['currentAcademicYear'] ?? '',
            logo: schoolData['logo'],
          );

          schools.value = [school];
          selectedSchool.value = school;
          
        } else {
          // schoolId is just a string - fetch school details from API
          schoolId = schoolData.toString();
          
          try {
            // Try to get school data from SchoolController if available
            if (Get.isRegistered<SchoolController>()) {
              final schoolController = Get.find<SchoolController>();
              final existingSchool = schoolController.schools.firstWhereOrNull(
                (school) => school.id == schoolId
              );

              if (existingSchool != null) {
                
                schools.value = [existingSchool];
                selectedSchool.value = existingSchool;
                return;
              }
            }
            
            // Fetch school data from API
            final response = await _apiService.get('${ApiConstants.getSingleSchool}/$schoolId');

            if (response.data['ok'] == true) {
              final schoolDataFromApi = response.data['data'];
              final school = School(
                id: schoolDataFromApi['_id'] ?? schoolId,
                name: schoolDataFromApi['name'] ?? 'Unknown School',
                schoolCode: schoolDataFromApi['schoolCode'] ?? '',
                email: schoolDataFromApi['email'] ?? '',
                phoneNo: schoolDataFromApi['phoneNo'] ?? '',
                address: schoolDataFromApi['address'] ?? '',
                currentAcademicYear: schoolDataFromApi['currentAcademicYear'] ?? '',
                logo: schoolDataFromApi['logo'],
              );

              schools.value = [school];
              selectedSchool.value = school;
              
            } else {
              // Fallback: Create basic school object
              final school = School(
                id: schoolId,
                name: user.schoolName ?? user.schoolCode ?? 'School',
                schoolCode: user.schoolCode ?? '',
                email: '',
                phoneNo: '',
                address: '',
                currentAcademicYear: '',
                logo: null,
              );

              schools.value = [school];
              selectedSchool.value = school;
              
            }
          } catch (e) {
            
            // Fallback: Create basic school object
            final school = School(
              id: schoolId,
              name: user.schoolName ?? user.schoolCode ?? 'School',
              schoolCode: user.schoolCode ?? '',
              email: '',
              phoneNo: '',
              address: '',
              currentAcademicYear: '',
              logo: null,
            );

            schools.value = [school];
            selectedSchool.value = school;
            
          }
        }
      } else {
        
      }
    } catch (e) {
      
      schools.clear();
      selectedSchool.value = null;
    } finally {
      isLoading.value = false;
      
    }
  }

  // Create announcement
  Future<void> createAnnouncement({
    required String schoolId,
    required String academicYear,
    required String title,
    required String description,
    required String type,
    required String priority,
    required List<String> targetAudience,
    List<dynamic>? targetClasses,
    List<String>? attachmentPaths,
  }) async {
    if (!_hasPermission(['correspondent', 'principal', 'administrator'])) {
      Get.snackbar('Access Denied', 'You do not have permission to create announcements',
        backgroundColor: AppTheme.errorRed, colorText: Colors.white, snackPosition: SnackPosition.TOP);
      return;
    }

    if (!_hasSubscriptionAccess(schoolId)) {
      Get.snackbar('Subscription Required', 'Announcement module is not enabled for your school subscription');
      return;
    }

    try {
      isLoading.value = true;

      // Create FormData with proper array handling
      FormData formData = FormData();
      formData.fields.addAll([
        MapEntry('schoolId', schoolId),
        MapEntry('academicYear', academicYear),
        MapEntry('title', title),
        MapEntry('description', description),
        MapEntry('type', type),
        MapEntry('priority', priority),
      ]);
      
      // Add targetAudience as separate fields with array notation
      for (int i = 0; i < targetAudience.length; i++) {
        formData.fields.add(MapEntry('targetAudience[$i]', targetAudience[i]));
      }
      
      // Add targetClasses if provided
      if (targetClasses != null) {
        for (int i = 0; i < targetClasses.length; i++) {
          formData.fields.add(MapEntry('targetClasses[$i]', targetClasses[i].toString()));
        }
      }

      for (var field in formData.fields) {
        
      }

      if (attachmentPaths != null) {
        for (int i = 0; i < attachmentPaths.length; i++) {
          formData.files.add(MapEntry(
            'attachment',
            await MultipartFile.fromFile(attachmentPaths[i]),
          ));
        }
        // for (String p in attachmentPaths) {
        //   formData.files.add(MapEntry(
        //     'attachment',
        //     await MultipartFile.fromFile(p, filename: path.basename(p)),
        //   ));
        // }
      }

      final response = await _apiService.post(
        ApiConstants.createAnnouncement,
        data: formData,
      );

      if (response.statusCode == 201 || response.data['ok'] == true) {
        ErrorHandler.showSuccess('Announcement created successfully');

        // Refresh announcements first
        await getAllAnnouncements(schoolId);
        
        // Close dialog after refresh
        if (Get.isDialogOpen!) {
          Navigator.pop(Get.context!);
        }
      } else {
        
        ErrorHandler.showError(response.data, 'Failed to create announcement');
      }
    } catch (e) {

      // Try to get more detailed error information
      if (e is DioException) {

        ErrorHandler.showError(e, 'Failed to create announcement');
      } else {
        Get.snackbar('Error', 'Failed to create announcement');
      }
      
    } finally {
      isLoading.value = false;
    }
  }

  // Get all announcements
  Future<void> getAllAnnouncements(String schoolId, {int page = 1, int limit = 20, String? studentClassId}) async {
    if (!_hasPermission(['correspondent', 'principal', 'viceprincipal', 'teacher', 'parent', 'administrator'])) {
      Get.snackbar('Access Denied', 'You do not have permission to view announcements',
        backgroundColor: AppTheme.errorRed, colorText: Colors.white, snackPosition: SnackPosition.TOP);
      return;
    }

    if (!_hasSubscriptionAccess(schoolId)) {
      Get.snackbar('Subscription Required', 'Announcement module is not enabled for your school subscription',
        backgroundColor: AppTheme.errorRed, colorText: Colors.white, snackPosition: SnackPosition.TOP);
      return;
    }

    try {
      isLoading.value = true;

      final queryParams = {
        'schoolId': schoolId,
        'page': page,
        'limit': limit,
        if (studentClassId != null) 'studentClassId': studentClassId,
      };

      final response = await _apiService.get(
        ApiConstants.getAllAnnouncements,
        queryParameters: queryParams,
      );

      if (response.data['ok'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];

        // Log each announcement for debugging
        for (int i = 0; i < data.length; i++) {
          
        }
        
        announcements.value = data.cast<Map<String, dynamic>>();
        _applyFilter(); // Apply current filter after loading
      } else {
        
        Get.snackbar('Error', response.data['message'] ?? 'Failed to load announcements');
      }
    } catch (e) {
      
      if (e is DioException) {

      }
      Get.snackbar('Error', 'Failed to load announcements');
      
    } finally {
      isLoading.value = false;
      
    }
  }

  // Get single announcement
  Future<void> getAnnouncement(String id, {String? studentClassId}) async {
    if (!_hasPermission(['correspondent', 'administrator', 'viceprincipal', 'principal', 'teacher', 'parent'])) {
      Get.snackbar('Access Denied', 'You do not have permission to view this announcement');
      return;
    }

    try {
      isLoading.value = true;
      
      final response = await _apiService.get(
        '${ApiConstants.getAnnouncement}/$id',
        queryParameters: {
          if (studentClassId != null) 'studentClassId': studentClassId,
        },
      );

      if (response.data['ok'] == true) {
        selectedAnnouncement.value = response.data['data'];
      } else {
        Get.snackbar('Error', response.data['message'] ?? 'Failed to load announcement');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load announcement');
      
    } finally {
      isLoading.value = false;
    }
  }

  // Update announcement
  Future<bool> updateAnnouncement({
    required String id,
    required String academicYear,
    required String title,
    required String description,
    required String type,
    required String priority,
    required List<String> targetAudience,
    List<dynamic>? targetClasses,
  }) async {
    if (!_hasPermission(['correspondent', 'principal', 'administrator'])) {
      Get.snackbar('Access Denied', 'You do not have permission to update announcements', backgroundColor: AppTheme.errorRed, colorText: Colors.white);
      return false;
    }

    try {
      isLoading.value = true;

      // Create proper data structure for update
      final updateData = {
        'academicYear': academicYear,
        'title': title,
        'description': description,
        'type': type,
        'priority': priority,
      };
      
      // Add targetAudience as array fields
      for (int i = 0; i < targetAudience.length; i++) {
        updateData['targetAudience[$i]'] = targetAudience[i];
      }
      
      // Add targetClasses if provided
      if (targetClasses != null) {
        for (int i = 0; i < targetClasses.length; i++) {
          updateData['targetClasses[$i]'] = targetClasses[i].toString();
        }
      }

      final response = await _apiService.put(
        '${ApiConstants.updateAnnouncement}/$id',
        data: updateData,
      );

      if (response.data['ok'] == true) {
        Get.snackbar('Success', 'Announcement updated successfully', backgroundColor: AppTheme.successGreen, colorText: Colors.white);
        final schoolId = selectedSchool.value?.id;
        if (schoolId != null) {
          await getAllAnnouncements(schoolId);
        }
        return true;
      } else {
        Get.snackbar('Error', response.data['message'] ?? 'Failed to update announcement', backgroundColor: AppTheme.errorRed, colorText: Colors.white);
        return false;
      }
    } catch (e) {
      
      if (e is DioException) {
        
        if (e.response?.data != null) {
          final errorData = e.response!.data;
          if (errorData is Map && errorData.containsKey('message')) {
            Get.snackbar('Error', errorData['message'], backgroundColor: AppTheme.errorRed, colorText: Colors.white);
          } else {
            Get.snackbar('Error', 'Server error: ${e.response?.statusCode}', backgroundColor: AppTheme.errorRed, colorText: Colors.white);
          }
        } else {
          Get.snackbar('Error', 'Failed to update announcement', backgroundColor: AppTheme.errorRed, colorText: Colors.white);
        }
      } else {
        Get.snackbar('Error', 'Failed to update announcement', backgroundColor: AppTheme.errorRed, colorText: Colors.white);
      }
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Add attachment to announcement
  Future<bool> addAttachment(String id, List<String> attachmentPaths) async {
    if (!_hasPermission(['correspondent', 'principal', 'administrator'])) {
      Get.snackbar('Access Denied', 'You do not have permission to add attachments',);
      return false;
    }

    try {
      isLoading.value = true;
      uploadProgress.value = 0.0;

      FormData formData = FormData();
      // formData.fields.addAll([...]);
      for (String path in attachmentPaths) {
        formData.files.add(MapEntry(
          'attachment',
          await MultipartFile.fromFile(path),
        ));
      }

      final response = await _apiService.dio.put(
        '${ApiConstants.addAnnouncementAttachment}/$id',
        data: formData,
        onSendProgress: (sent, total) {
          if (total != -1) {
            uploadProgress.value = sent / total;
            
          }
        },
      );

      if (response.data['ok'] == true || response.statusCode == 201) {
        await getAnnouncement(id); // Refresh data
        Get.snackbar('Success', response.data['message'] ?? 'Attachments added successfully');
        return true;
      } else {
        Get.snackbar('Error', response.data['message'] ?? 'Failed to add attachments');
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add attachments');
      
      return false;
    } finally {
      isLoading.value = false;
      uploadProgress.value = 0.0;
    }
  }

  // Delete attachment from announcement
  Future<bool> deleteAttachment(String id, String fileId) async {
    if (!_hasPermission(['correspondent', 'principal', 'administrator'])) {
      Get.snackbar('Access Denied', 'You do not have permission to delete attachments');
      return false;
    }

    try {
      isLoading.value = true;

      final response = await _apiService.delete(
        '${ApiConstants.deleteAnnouncementAttachment}/$id/$fileId',
      );

      if (response.data['ok'] == true) {
        await getAnnouncement(id); // Refresh data
        return true;
      } else {
        Get.snackbar('Error', response.data['message'] ?? 'Failed to delete attachment');
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete attachment');
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Delete announcement
  Future<void> deleteAnnouncement(String id) async {
    if (!_hasPermission(['correspondent', 'principal', 'administrator'])) {
      Get.snackbar('Access Denied', 'You do not have permission to delete announcements');
      return;
    }

    try {
      isLoading.value = true;
      
      final response = await _apiService.delete(
        '${ApiConstants.deleteAnnouncement}/$id',
      );

      if (response.data['ok'] == true) {
        Navigator.pop(Get.context!);
        Get.snackbar('Success', 'Announcement deleted successfully');
        final schoolId = selectedSchool.value?.id;
        if (schoolId != null) {
          if (isLoading.value) {
            Get.dialog(
              const Center(child: CircularProgressIndicator()),
              barrierDismissible: false,
            );
          }
          await getAllAnnouncements(schoolId);
        }
      } else {
        Get.snackbar('Error', response.data['message'] ?? 'Failed to delete announcement');
      }
    } catch (e) {
      Navigator.pop(Get.context!);
      Get.snackbar('Error', 'Failed to delete announcement');

    } finally {
      isLoading.value = false;
    }
  }

  // Filter announcements by target audience
  void _applyFilter() {

    final userRole = _authController.user.value?.role?.toLowerCase();
    final isParent = userRole == 'parent';
    final isTeacher = userRole == 'teacher';
    
    // Get parent's children classes if parent role
    final parentChildrenClasses = <String>{};
    if (isParent) {
      try {
        if (Get.isRegistered<MyChildrenController>()) {
          final myChildrenController = Get.find<MyChildrenController>();
          for (var child in myChildrenController.children) {
            final className = child['className']?.toString();
            if (className != null && className.isNotEmpty) {
              parentChildrenClasses.add(className);
            }
          }
        }
      } catch (e) {
        
      }
    }
    
    // Log all announcements for debugging
    for (int i = 0; i < announcements.length; i++) {
      final announcement = announcements[i];
      
    }
    
    // Apply filtering based on role and filter selection
    filteredAnnouncements.value = announcements.where((announcement) {
      final targetAudience = announcement['targetAudience'] as List?;
      
      // For parent role
      if (isParent) {
        // If filter is 'all' or 'parent', show announcements with 'all' or 'parent' target
        if (selectedFilter.value == 'all' || selectedFilter.value == 'parent') {
          // Check if targetAudience contains 'all' or 'parent'
          if (targetAudience?.contains('all') == true || targetAudience?.contains('parent') == true) {
            return true;
          }
          
          // Check if targetAudience is 'specific_classes' and matches parent's children classes
          if (targetAudience?.contains('specific_classes') == true) {
            final targetClasses = announcement['targetClasses'] as List?;
            if (targetClasses != null && targetClasses.isNotEmpty) {
              // Check if any target class matches parent's children classes
              for (var targetClass in targetClasses) {
                final className = targetClass is Map ? targetClass['name']?.toString() : targetClass.toString();
                if (className != null && parentChildrenClasses.contains(className)) {
                  return true;
                }
              }
            }
          }
          return false;
        }
        // For other filters, use default logic
        return targetAudience?.contains(selectedFilter.value) == true ||
               targetAudience?.contains('all') == true;
      }
      
      // For teacher role
      if (isTeacher) {
        // If filter is 'all' or 'parent', show announcements with 'all' or 'parent' target
        if (selectedFilter.value == 'all' || selectedFilter.value == 'parent') {
          return targetAudience?.contains('all') == true || 
                 targetAudience?.contains('parent') == true;
        }
        // If filter is 'teacher', show announcements with 'all' or 'teacher' target
        if (selectedFilter.value == 'teacher') {
          return targetAudience?.contains('all') == true || 
                 targetAudience?.contains('teacher') == true;
        }
        // For other filters, use default logic
        return targetAudience?.contains(selectedFilter.value) == true ||
               targetAudience?.contains('all') == true;
      }
      
      // Default filtering logic for other roles
      if (selectedFilter.value == 'all') {
        return true;
      }
      final hasMatch = targetAudience?.contains(selectedFilter.value) == true ||
             targetAudience?.contains('all') == true;
      
      return hasMatch;
    }).toList();
    
  }

  // Filter by role - shows notifications for 'all' and specific role
  void filterByRole(String userRole) {

    final parentChildrenClasses = <String>{};
    if (userRole == 'parent') {
      try {
        if (Get.isRegistered<MyChildrenController>()) {
          final myChildrenController = Get.find<MyChildrenController>();
          for (var child in myChildrenController.children) {
            final className = child['className']?.toString();
            if (className != null && className.isNotEmpty) {
              parentChildrenClasses.add(className);
            }
          }
        }
      } catch (e) {
        
      }
    }
    
    filteredAnnouncements.value = announcements.where((announcement) {
      final targetAudience = announcement['targetAudience'] as List?;
      
      // Show if targeted to 'all'
      if (targetAudience?.contains('all') == true) {
        return true;
      }
      
      // Show if targeted to user's specific role
      if (targetAudience?.contains(userRole) == true) {
        return true;
      }
      
      // For parents, also check specific classes
      if (userRole == 'parent' && targetAudience?.contains('specific_classes') == true) {
        final targetClasses = announcement['targetClasses'] as List?;
        if (targetClasses != null && targetClasses.isNotEmpty) {
          for (var targetClass in targetClasses) {
            final className = targetClass is Map ? targetClass['name']?.toString() : targetClass.toString();
            if (className != null && parentChildrenClasses.contains(className)) {
              return true;
            }
          }
        }
      }
      
      return false;
    }).toList();

  }

  // Change filter
  void changeFilter(String filter) {
    selectedFilter.value = filter;
    _applyFilter();
  }
}
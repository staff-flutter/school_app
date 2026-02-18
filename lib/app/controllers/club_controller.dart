import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:school_app/app/controllers/school_controller.dart';
import 'dart:io';
import '../../core/utils/error_handler.dart';
import '../data/services/api_service.dart';
import '../data/services/subscription_service.dart';
import '../core/constants/api_constants.dart';
import '../modules/auth/controllers/auth_controller.dart';
import '../modules/clubs/controllers/clubs_controller.dart' hide Club;
import '../data/models/school_models.dart';
import '../data/models/student_model.dart';
import '../data/models/club_model.dart';

class ClubController extends GetxController {
  final ApiService _apiService = Get.find();
  final SubscriptionService _subscriptionService = Get.find();
  final AuthController _authController = Get.find();
  
  final isLoading = false.obs;
  final clubs = <Map<String, dynamic>>[].obs;
  final clubVideos = <Map<String, dynamic>>[].obs;
  final selectedClub = Rxn<Map<String, dynamic>>();
  final selectedVideo = Rxn<Map<String, dynamic>>();

  bool _hasPermission(List<String> allowedRoles) {
    final userRole = _authController.user.value?.role;
    return allowedRoles.contains(userRole);
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

    final hasAccess = _subscriptionService!.hasModuleAccess('club', schoolId);
    
    return hasAccess;
  }

  String _getSchoolId() {
    return _authController.user.value?.schoolId ?? '';
  }

  // Get all clubs
  Future<void> getAllClubs({String? schoolId, int page = 1, int limit = 20}) async {
    final targetSchoolId = schoolId ?? _getSchoolId();

    if (!_hasPermission(['correspondent', 'principal', 'teacher', 'parent', 'administrator', 'accountant', 'viceprincipal'])) {
      Get.snackbar('Access Denied', 'You do not have permission to view clubs');
      return;
    }

    if (!_hasSubscriptionAccess(targetSchoolId)) {
      Get.snackbar('Subscription Required', 'Club module is not enabled for your school subscription');
      return;
    }

    try {
      isLoading.value = true;
      
      final queryParams = {
        'schoolId': targetSchoolId,
        'page': page,
        'limit': limit,
      };

      final response = await _apiService.get(
        ApiConstants.getAllClubs,
        queryParameters: queryParams,
      );

      if (response.data['ok'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        clubs.value = data.cast<Map<String, dynamic>>();
        
      } else {
        
        Get.snackbar('Error', response.data['message'] ?? 'Failed to load clubs');
      }
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to load clubs');
    } finally {
      isLoading.value = false;
    }
  }

  // Get single club
  Future<void> getClub(String id) async {

    if (!_hasPermission(['correspondent', 'principal', 'teacher', 'parent', 'administrator', 'accountant', 'viceprincipal'])) {
      Get.snackbar('Access Denied', 'You do not have permission to view this club');
      return;
    }

    // Find the club in the existing clubs list to get its schoolId
    final club = clubs.firstWhere(
      (club) => club['_id'] == id,
      orElse: () => <String, dynamic>{},
    );

    final schoolId = club['schoolId'] ?? _getSchoolId();

    if (!_hasSubscriptionAccess(schoolId)) {
      Get.snackbar('Subscription Required', 'Club module is not enabled for your school subscription');
      return;
    }

    try {
      isLoading.value = true;
      
      final url = '${ApiConstants.getClub}/$id';
      final queryParams = {'schoolId': schoolId};

      final response = await _apiService.get(
        url,
        queryParameters: queryParams,
      );

      if (response.data['ok'] == true) {
        selectedClub.value = response.data['data'];
        
      } else {
        
        Get.snackbar('Error', response.data['message'] ?? 'Failed to load club');
      }
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to load club');
    } finally {
      isLoading.value = false;
    }
  }

  // Create club
  Future<void> createClub({
    required String name,
    required String description,
    required String schoolId,
    required String classId,
    String? thumbnailPath,
  }) async {

    if (!_hasPermission(['correspondent', 'administrator'])) {
      Get.snackbar('Access Denied', 'You do not have permission to create clubs');
      return;
    }

    if (!_hasSubscriptionAccess(schoolId)) {
      Get.snackbar('Subscription Required', 'Club module is not enabled for your school subscription');
      return;
    }

    try {
      isLoading.value = true;
      
      FormData formData = FormData.fromMap({
        'name': name,
        'description': description,
        'schoolId': schoolId,
        'classId': classId,
      });

      if (thumbnailPath != null) {
        formData.files.add(MapEntry(
          'thumbnail',
          await MultipartFile.fromFile(thumbnailPath),
        ));
      }

      final response = await _apiService.post(
        ApiConstants.createClub,
        data: formData,
      );

      if (response.data['ok'] == true) {
        
        Get.snackbar('Success', 'Club created successfully');
        await getAllClubs(schoolId: schoolId);
      } else {
        
        Get.snackbar('Error', response.data['message'] ?? 'Failed to create club');
      }
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to create club');
    } finally {
      isLoading.value = false;
    }
  }

  // Update club text details
  Future<void> updateClubText({
    required String id,
    required String name,
    required String description,
    required bool isActive,
    required String classId,
  }) async {

    if (!_hasPermission(['correspondent', 'administrator'])) {
      Get.snackbar('Access Denied', 'You do not have permission to update clubs');
      return;
    }

    final schoolId = _getSchoolId();

    if (!_hasSubscriptionAccess(schoolId)) {
      Get.snackbar('Subscription Required', 'Club module is not enabled for your school subscription');
      return;
    }

    try {
      isLoading.value = true;
      
      final url = '${ApiConstants.updateClubText}/$id';
      final data = {
        'name': name,
        'description': description,
        'isActive': isActive,
        'classId': classId,
      };

      final response = await _apiService.put(url, data: data);

      if (response.data['ok'] == true) {
        
        Get.snackbar('Success', 'Club updated successfully');
        await getClub(id);
      } else {
        
        Get.snackbar('Error', response.data['message'] ?? 'Failed to update club');
      }
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to update club');
    } finally {
      isLoading.value = false;
    }
  }

  // Update club thumbnail
  Future<void> updateClubThumbnail(String id, String thumbnailPath) async {

    if (!_hasPermission(['correspondent', 'administrator'])) {
      Get.snackbar('Access Denied', 'You do not have permission to update club thumbnails');
      return;
    }

    final schoolId = _getSchoolId();

    if (!_hasSubscriptionAccess(schoolId)) {
      Get.snackbar('Subscription Required', 'Club module is not enabled for your school subscription');
      return;
    }

    try {
      isLoading.value = true;
      
      FormData formData = FormData.fromMap({
        'thumbnail': await MultipartFile.fromFile(thumbnailPath),
      });

      final url = '${ApiConstants.updateClubThumbnail}/$id';

      final response = await _apiService.put(url, data: formData);

      if (response.data['ok'] == true) {
        
        Get.snackbar('Success', 'Club thumbnail updated successfully');
        await getClub(id);
      } else {
        
        Get.snackbar('Error', response.data['message'] ?? 'Failed to update thumbnail');
      }
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to update thumbnail');
    } finally {
      isLoading.value = false;
    }
  }

  // Delete club
  Future<void> deleteClub(String id) async {

    if (!_hasPermission(['correspondent', 'administrator'])) {
      Get.snackbar('Access Denied', 'You do not have permission to delete clubs');
      return;
    }

    final schoolId = _getSchoolId();

    if (!_hasSubscriptionAccess(schoolId)) {
      Get.snackbar('Subscription Required', 'Club module is not enabled for your school subscription');
      return;
    }

    try {
      isLoading.value = true;
      
      final url = '${ApiConstants.deleteClub}/$id';

      final response = await _apiService.delete(url);

      if (response.data['ok'] == true) {
        
        Get.snackbar('Success', 'Club deleted successfully');
        clubs.removeWhere((club) => club['_id'] == id);
      } else {
        
        Get.snackbar('Error', response.data['message'] ?? 'Failed to delete club');
      }
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to delete club');
    } finally {
      isLoading.value = false;
    }
  }

  // Get all club videos
  Future<void> getAllClubVideos({
    String? clubId,
    String? topic,
    String? level,
    int page = 1,
    int limit = 20,
  }) async {

    if (!_hasPermission(['correspondent', 'principal', 'teacher', 'parent', 'administrator', 'accountant', 'viceprincipal'])) {
      Get.snackbar('Access Denied', 'You do not have permission to view club videos');
      return;
    }

    final schoolId = _getSchoolId();

    if (!_hasSubscriptionAccess(schoolId)) {
      Get.snackbar('Subscription Required', 'Club module is not enabled for your school subscription');
      return;
    }

    try {
      isLoading.value = true;
      
      final queryParams = {
        'schoolId': schoolId,
        if (clubId != null) 'clubId': clubId,
        if (topic != null) 'topic': topic,
        if (level != null) 'level': level,
        'page': page,
        'limit': limit,
      };

      final response = await _apiService.get(
        ApiConstants.getAllClubVideos,
        queryParameters: queryParams,
      );

      if (response.data['ok'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        clubVideos.value = data.cast<Map<String, dynamic>>();

        // Auto-reload the clubs controller if it exists
        if (Get.isRegistered<ClubsController>()) {
          final clubsController = Get.find<ClubsController>();
          final videoList = data.map((videoData) => RecordedClass.fromJson(videoData)).toList();
          clubsController.recordedClasses.value = videoList;
          
        }
      } else {
        
        Get.snackbar('Error', response.data['message'] ?? 'Failed to load club videos');
      }
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to load club videos');
    } finally {
      isLoading.value = false;
    }
  }

  // Get single club video
  Future<void> getClubVideo(String id) async {

    if (!_hasPermission(['correspondent', 'principal', 'teacher', 'parent', 'administrator', 'accountant', 'viceprincipal'])) {
      Get.snackbar('Access Denied', 'You do not have permission to view this video');
      return;
    }

    final schoolId = _getSchoolId();

    if (!_hasSubscriptionAccess(schoolId)) {
      Get.snackbar('Subscription Required', 'Club module is not enabled for your school subscription');
      return;
    }

    try {
      isLoading.value = true;
      
      final url = '${ApiConstants.getClubVideo}/$id';
      final queryParams = {'schoolId': schoolId};

      final response = await _apiService.get(url, queryParameters: queryParams);

      if (response.data['ok'] == true) {
        selectedVideo.value = response.data['data'];
        
      } else {
        
        Get.snackbar('Error', response.data['message'] ?? 'Failed to load video');
      }
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to load video');
    } finally {
      isLoading.value = false;
    }
  }

  // Upload club video
  Future<void> uploadClubVideo({
    required String schoolId,
    required String clubId,
    required String title,
    required String topic,
    required String level,
    required String academicYear,
    required String videoPath,
  }) async {

    // 1. Role Permission Check (Only Correspondent and Administrator)
    final authController = Get.find<AuthController>();
    final userRole = authController.user.value?.role.toLowerCase();
    final bool hasPermission = ['correspondent', 'administrator'].contains(userRole);

    if (!hasPermission) {
      
      Get.snackbar('Access Denied', 'You do not have permission to upload videos');
      return;
    }

    // 2. Subscription Guard Check
    final schoolController = Get.find<SchoolController>();
    final clubController = Get.find<ClubsController>();
    if (!schoolController.hasModuleAccess('club')) {
      
      Get.snackbar('Subscription Required', 'Club module is not enabled for your school subscription');
      return;
    }

    // Validate file path
    if (videoPath.isEmpty) {
      
      Get.snackbar('Error', 'Video file path is empty');
      return;
    }

    try {
      isLoading.value = true;

      // Check if file exists
      final file = File(videoPath);
      final fileExists = await file.exists();
      final fileSize = fileExists ? await file.length() : 0;

      if (!fileExists) {
        Get.snackbar('Error', 'Selected video file no longer exists. Please select the file again.');
        return;
      }

      if (fileSize > 100 * 1024 * 1024) { // 100MB
        
      }

      // 3. Construct FormData (Matching Postman Payload)
      final fileName = videoPath.split('/').last;
      FormData formData = FormData.fromMap({
        'schoolId': schoolId,
        'clubId': clubId,
        'title': title,
        'topic': topic,
        'level': level.toLowerCase(), // Normalizing for backend compatibility
        'academicYear': academicYear,
        'video': await MultipartFile.fromFile(
          videoPath,
          filename: fileName, // Explicitly send filename
        ),
      });

      // Debug: Show exact payload being sent

       // Note: sending lowercase

      // Using dio instance directly to support progress tracking if needed later
      final response = await _apiService.dio.post(
        ApiConstants.uploadClubVideo,
        data: formData,
        onSendProgress: (sent, total) {
          if (total != -1) {
            double progress = sent / total;
            
          }
        },
      );

      // Note: Postman shows 201 Created for success
      if (response.statusCode == 200 || response.statusCode == 201) {
        
        Get.snackbar('Success', 'Video uploaded successfully', backgroundColor: Colors.green, colorText: Colors.white);

        // Refresh the specific club's video list
        await clubController.loadRecordedClasses(schoolId);
      } else {
        
        Get.snackbar('Error', response.data['message'] ?? 'Failed to upload video');
      }
    } catch (e) {
      
      if (e.toString().contains('PathNotFoundException')) {
        Get.snackbar('Error', 'Video file not found. Please select the file again.');
      } else if (e.toString().contains('SocketException') || e.toString().contains('Connection reset')) {
        Get.snackbar('Error', 'Upload failed due to network issue. Please check your connection.');
      } else if (e.toString().contains('timeout')) {
        Get.snackbar('Error', 'Upload timed out. Please try with a smaller video file.');
      } else {
        Get.snackbar('Error', 'Failed to upload video: ${e.toString()}');
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Update video details
  Future<void> updateVideoDetails({
    required String id,
    required String title,
    required String topic,
    required String level,
  }) async {

    if (!_hasPermission(['correspondent', 'administrator'])) {
      Get.snackbar('Access Denied', 'You do not have permission to update videos');
      return;
    }

    final schoolId = _getSchoolId();

    if (schoolId.isEmpty) {
      Get.snackbar('Error', 'School ID not found. Please login again.');
      return;
    }
    
    if (!_hasSubscriptionAccess(schoolId)) {
      Get.snackbar('Subscription Required', 'Club module is not enabled for your school subscription');
      return;
    }

    try {
      isLoading.value = true;
      
      final url = '${ApiConstants.updateClubVideoDetails}/$id?schoolId=$schoolId';
      final data = {
        'schoolId': schoolId,
        'title': title,
        'topic': topic,
        'level': level,
      };

      final response = await _apiService.put(url, data: data);

      if (response.data['ok'] == true) {
        
        Get.snackbar('Success', 'Video updated successfully');
        await getAllClubVideos();
      } else {
        
        Get.snackbar('Error', response.data['message'] ?? 'Failed to update video');
      }
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to update video');
    } finally {
      isLoading.value = false;
    }
  }

  // Update video file
  Future<void> updateVideoFile(String id, String videoPath) async {

    if (!_hasPermission(['correspondent', 'administrator'])) {
      Get.snackbar('Access Denied', 'You do not have permission to update video files');
      return;
    }

    final schoolId = _getSchoolId();

    if (schoolId.isEmpty) {
      Get.snackbar('Error', 'School ID not found. Please login again.');
      return;
    }
    
    if (!_hasSubscriptionAccess(schoolId)) {
      Get.snackbar('Subscription Required', 'Club module is not enabled for your school subscription');
      return;
    }

    // Validate file path
    if (videoPath.isEmpty) {
      Get.snackbar('Error', 'Video file path is empty');
      return;
    }

    try {
      isLoading.value = true;
      
      // Check if file exists
      final file = File(videoPath);
      final fileExists = await file.exists();
      final fileSize = fileExists ? await file.length() : 0;
      
      if (!fileExists) {
        Get.snackbar('Error', 'Selected video file no longer exists. Please select again.');
        return;
      }
      
      FormData formData = FormData.fromMap({
        'schoolId': schoolId,
        'video': await MultipartFile.fromFile(videoPath),
      });

      final url = '${ApiConstants.updateClubVideoFile}/$id?schoolId=$schoolId';

      final response = await _apiService.put(url, data: formData);

      if (response.data['ok'] == true) {
        
        Get.snackbar('Success', 'Video file updated successfully');
        await getClubVideo(id);
      } else {
        
        Get.snackbar('Error', response.data['message'] ?? 'Failed to update video file');
      }
    } catch (e) {
      
      if (e.toString().contains('PathNotFoundException')) {
        Get.snackbar('Error', 'Video file not found. Please select the file again.');
      } else if (e.toString().contains('SocketException') || e.toString().contains('Connection reset')) {
        Get.snackbar('Error', 'Upload failed due to network issue. The video file may be too large. Please try with a smaller file.');
      } else if (e.toString().contains('timeout')) {
        Get.snackbar('Error', 'Upload timed out. Please try with a smaller video file.');
      } else {
        Get.snackbar('Error', 'Failed to update video file');
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Delete club video
  Future<void> deleteClubVideo(String id) async {

    if (!_hasPermission(['correspondent', 'administrator'])) {
      Get.snackbar('Access Denied', 'You do not have permission to delete videos');
      return;
    }

    final schoolId = _getSchoolId();

    if (!_hasSubscriptionAccess(schoolId)) {
      Get.snackbar('Subscription Required', 'Club module is not enabled for your school subscription');
      return;
    }

    try {
      isLoading.value = true;
      
      final url = '${ApiConstants.deleteClubVideo}/$id?schoolId=$schoolId';

      final response = await _apiService.delete(url);

      if (response.data['ok'] == true) {
        
        Get.snackbar('Success', 'Video deleted successfully');
        clubVideos.removeWhere((video) => video['_id'] == id);
        await getAllClubVideos();
      } else {
        
        Get.snackbar('Error', response.data['message'] ?? 'Failed to delete video');
      }
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to delete video');
    } finally {
      isLoading.value = false;
    }
  }

  // Club membership management APIs (only for correspondent and administrator)
  Future<void> addStudentToClub(String? clubId, String? studentId) async {
    if (!_hasPermission(['correspondent', 'administrator'])) {
      throw Exception('Access denied: Insufficient permissions');
    }

    // Null checks for parameters
    if (studentId == null || studentId.isEmpty) {
      throw Exception('Student ID cannot be null or empty');
    }
    if (clubId == null || clubId.isEmpty) {
      throw Exception('Club ID cannot be null or empty');
    }

    try {
      final response = await _apiService.put(
        ApiConstants.addStudentToClub,
        data: {
          'studentId': studentId,
          'clubId': clubId,
        },
      );

      if (response.data['ok'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to add student to club');
      }
    } catch (e) {
      
      throw e;
    }
  }

  Future<void> removeStudentFromClub(String? clubId, String? studentId) async {
    if (!_hasPermission(['correspondent', 'administrator'])) {
      throw Exception('Access denied: Insufficient permissions');
    }

    // Null checks for parameters
    if (studentId == null || studentId.isEmpty) {
      throw Exception('Student ID cannot be null or empty');
    }
    if (clubId == null || clubId.isEmpty) {
      throw Exception('Club ID cannot be null or empty');
    }

    try {
      final response = await _apiService.put(
        ApiConstants.removeStudentFromClub,
        data: {
          'studentId': studentId,
          'clubId': clubId,
        },
      );

      if (response.data['ok'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to remove student from club');
      }
    } catch (e) {
      
      throw e;
    }
  }

  Future<void> toggleStudentsInClub(String? clubId, List<String>? studentIds, bool addToClub, {String? classId}) async {
    if (!_hasPermission(['correspondent', 'administrator'])) {
      throw Exception('Access denied: Insufficient permissions');
    }

    // Enhanced null checks for parameters
    if (clubId == null || clubId.isEmpty) {
      
      throw Exception('Club ID cannot be null or empty');
    }
    if (studentIds == null || studentIds.isEmpty) {
      
      throw Exception('Student IDs list cannot be null or empty');
    }

    // Additional validation to ensure clubId is a valid ObjectId format
    if (clubId.length != 24) {
      
      throw Exception('Invalid club ID format');
    }

    try {

      final requestData = {
        'clubId': clubId,
        'studentIds': studentIds,
        'addToClub': addToClub,
      };
      
      // Add classId if provided
      if (classId != null && classId.isNotEmpty) {
        requestData['classId'] = classId;
      }
      
      final response = await _apiService.put(
        ApiConstants.toggleStudentsInClub,
        data: requestData,
      );

      if (response.data['ok'] == true) {

        Get.snackbar('Success', response.data['message'] ?? 'Students updated successfully',
          backgroundColor: Colors.green, colorText: Colors.white);

      } else {
        throw Exception(response.data['message'] ?? 'Failed to update students in club');
      }
      
    } catch (e) {
      
      ErrorHandler.showError(e, 'Failed to update students in club');

      throw e;
    }
  }

  // Get student's clubs
  Future<List<Club>> getStudentClubs(String studentId) async {
    
    try {
      final url = '${ApiConstants.getStudentClubs}/$studentId';
      
      
      final response = await _apiService.get(url);
      
      

      if (response.data['ok'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        
        final clubs = data.map((clubData) => Club.fromJson(clubData)).toList();
        
        return clubs;
      } else {
        
        return [];
      }
    } catch (e) {
      
      return [];
    }
  }

  // Toggle student club membership
  Future<void> toggleStudentClub(String? studentId, String? clubId, bool addToClub) async {
    if (!_hasPermission(['correspondent', 'administrator'])) {
      throw Exception('Access denied: Insufficient permissions');
    }

    // Enhanced null checks for parameters
    if (studentId == null || studentId.isEmpty) {
      
      throw Exception('Student ID cannot be null or empty');
    }
    if (clubId == null || clubId.isEmpty) {
      
      throw Exception('Club ID cannot be null or empty');
    }

    // Additional validation to ensure IDs are valid ObjectId format
    if (clubId.length != 24) {
      
      throw Exception('Invalid club ID format');
    }
    if (studentId.length != 24) {
      
      throw Exception('Invalid student ID format');
    }

    try {

      final endpoint = addToClub ? ApiConstants.addStudentToClub : ApiConstants.removeStudentFromClub;
      final response = await _apiService.put(
        endpoint,
        data: {
          'clubId': clubId,
          'studentId': studentId,
        },
      );

      if (response.data['ok'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to update student club membership');
      }

    } catch (e) {
      
      ErrorHandler.showError(e, 'Failed to Toggle students in club');
      throw e;
    }
  }

  // Filter clubs by class ID
  Future<void> getClubsByClass(String classId) async {
    try {
      isLoading.value = true;

      // Get all clubs and filter by classId
      final response = await _apiService.get('/api/club/getall');

      if (response.data['ok'] == true) {
        final allClubs = List<Map<String, dynamic>>.from(response.data['data'] ?? []);

        // Filter clubs that have the specified classId
        final filteredClubs = allClubs.where((club) {
          final clubClassId = club['classId'];
          return clubClassId != null && clubClassId == classId;
        }).toList();

        clubs.assignAll(filteredClubs);
        
      } else {
        clubs.clear();
        
      }
    } catch (e) {
      
      clubs.clear();
    } finally {
      isLoading.value = false;
    }
  }
}
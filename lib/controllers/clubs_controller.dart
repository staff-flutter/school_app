import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:school_app/core/permissions/feature_flag_service.dart';
import 'package:school_app/core/permissions/module_visibility.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/club_controller.dart';
import 'package:school_app/models/school_models.dart';
import 'package:school_app/models/club_model.dart';
import 'package:school_app/services/api_service.dart';
import 'package:school_app/constants/api_constants.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/core/api_guard.dart';

import 'package:school_app/controllers/auth_controller.dart';

class ClubsController extends GetxController {
  final ApiService _apiService = Get.find();
  final isLoading = false.obs;
  final clubs = <Club>[].obs;
  final activities = <Activity>[].obs;
  final events = <Event>[].obs;
  final memberships = <Membership>[].obs;
  final recordedClasses = <RecordedClass>[].obs;
  final schools = <School>[].obs;
  final selectedSchool = Rxn<School>();

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

  @override
  void onInit() {
    super.onInit();
    
    loadSchools().then((_) => loadClubsData());
  }

  // Method to load classes for the selected school
  Future<void> loadClassesForSelectedSchool() async {
    // Prevent multiple concurrent calls
    if (_isLoadingClasses) return;
    _isLoadingClasses = true;

    try {
      final schoolController = Get.find<SchoolController>();
      if (selectedSchool.value != null) {
        await schoolController.getAllClasses(selectedSchool.value!.id);
      }
    } finally {
      _isLoadingClasses = false;
    }
  }

  bool _isLoadingClasses = false;

  Future<void> loadSchools() async {
    
    try {
      final authController = Get.find<AuthController>();

      final schoolId = authController.user.value?.schoolId;

      if (schoolId != null) {

        // Create school object with user's schoolId
        final school = School(
          id: schoolId,
          name: schoolId, // Show the actual schoolId
          schoolCode: '',
          email: '',
          phoneNo: '',
          address: '',
          currentAcademicYear: '',
          logo: null,
        );

        schools.value = [school];
        selectedSchool.value = school;

      } else {
        
      }
    } catch (e) {
      
      _showSnackbar('Error', 'Failed to load school', AppTheme.errorRed);
    }
    
  }

  void onSchoolSelected(School? school) {
    if (school != null) {
      selectedSchool.value = school;
      loadClubsData();
      // Load classes when school is selected
      loadClassesForSelectedSchool();
    }
  }

  // void loadClubsData() async {
  //   final schoolId = selectedSchool.value?.id;
  //   if (schoolId == null) {
  //     return;
  //   }
  //
  //   try {
  //     isLoading.value = true;
  //     await loadClubs(schoolId);
  //     await loadRecordedClasses(schoolId);
  //   } catch (e) {
  //     _showSnackbar('Error', 'Failed to load clubs data', AppTheme.errorRed);
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  Future<void> loadClubs(String schoolId) async {
    try {
      final response = await _apiService.get(ApiConstants.getAllClubs, queryParameters: {
        'schoolId': schoolId,
        'page': 1,
        'limit': 50,
      });

      if (response.data['ok'] == true) {
        final clubList = response.data['data'] as List;
        
        clubs.value = clubList.map((clubData) {
          
          return Club.fromJson(clubData);
        }).toList();
        
      } else {
        clubs.clear();
        _showSnackbar('Info', 'No clubs found', AppTheme.warningYellow);
      }
    } catch (e) {
      clubs.clear();
      _showSnackbar('Info', 'No clubs available. Create clubs to get started.', AppTheme.warningYellow);
    }
  }

  Future<void> loadRecordedClasses(String schoolId) async {
    try {
      final response = await _apiService.get(ApiConstants.getAllClubVideos, queryParameters: {
        'schoolId': schoolId,
        'page': 1,
        'limit': 50,
      });

      if (response.data['ok'] == true) {
        final videoList = response.data['data'] as List;
        recordedClasses.value = videoList.map((videoData) => RecordedClass.fromJson(videoData)).toList();
      } else {
        recordedClasses.clear();
        _showSnackbar('Info', 'No recorded classes found', AppTheme.warningYellow);
      }
    } catch (e) {
      recordedClasses.clear();
      _showSnackbar('Info', 'No recorded classes available.', AppTheme.warningYellow);
    }
  }

  Future<void> loadClubsData() async {
    final schoolId = selectedSchool.value?.id;
    if (schoolId == null) return;

    try {
      isLoading.value = true;
      await loadClubs(schoolId);
      await loadRecordedClasses(schoolId);

      // Also trigger the ClubController to load videos
      if (Get.isRegistered<ClubController>()) {
        final clubController = Get.find<ClubController>();
        await clubController.getAllClubVideos();
      }
    } catch (e) {
      _showSnackbar('Error', 'Failed to load clubs data', AppTheme.errorRed);
    } finally {
      isLoading.value = false;
    }
  }

// Check Role Permissions using new system
  bool canManageClubs() {
    return FeatureFlagService.canCreateClubs();
  }

  bool canViewClubs() {
    final authController = Get.find<AuthController>();
    final role = authController.user.value?.role.toLowerCase() ?? '';
    return ModuleVisibility.isModuleVisible(role, 'clubs');
  }

  bool canViewClubVideos() {
    final authController = Get.find<AuthController>();
    final role = authController.user.value?.role.toLowerCase() ?? '';
    return ModuleVisibility.isModuleVisible(role, 'clubVideos');
  }

  List<RecordedClass> getRecordedClassesByCategory(String category) {
    if (category == 'All') return recordedClasses;
    return recordedClasses.where((cls) => cls.category == category).toList();
  }

  List<RecordedClass> getRecordedClassesByLevel(String level) {
    if (level == 'All') return recordedClasses;
    return recordedClasses.where((cls) => cls.level == level).toList();
  }

  Future<void> addClub(Club club, {String? thumbnailPath, String? classId}) async {
    try {
      isLoading.value = true;

      final clubController = Get.find<ClubController>();

      await clubController.createClub(
        name: club.name,
        description: club.description,
        schoolId: club.schoolId,
        classId: classId ?? '',
        thumbnailPath: thumbnailPath,
      );

      // Refresh the clubs list
      await loadClubs(club.schoolId);

      _showSnackbar('Success', 'Club created successfully', AppTheme.successGreen);
    } catch (e) {
      
      _showSnackbar('Error', 'Failed to create club', AppTheme.errorRed);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateClub(Club club, {String? classId}) async {
    try {
      isLoading.value = true;

      final clubController = Get.find<ClubController>();

      await clubController.updateClubText(
        id: club.id,
        name: club.name,
        description: club.description,
        isActive: club.isActive,
        classId: classId ?? '',
      );

      // Reload clubs from API to get updated data
      final schoolId = selectedSchool.value?.id;
      if (schoolId != null) {
        await loadClubs(schoolId);
        
      }

      _showSnackbar('Success', 'Club updated successfully', AppTheme.successGreen);
    } catch (e) {
      
      _showSnackbar('Error', 'Failed to update club', AppTheme.errorRed);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  void deleteClub(String clubId) async {
    try {
      isLoading.value = true;

      final response = await _apiService.delete('${ApiConstants.deleteClub}/$clubId');

      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Club deleted successfully', AppTheme.successGreen);
        // Auto reload clubs data
        final schoolId = selectedSchool.value?.id;
        if (schoolId != null) await loadClubs(schoolId);
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to delete club', AppTheme.errorRed);
      }
    } catch (e) {
      _showSnackbar('Error', 'Failed to delete club', AppTheme.errorRed);
    } finally {
      isLoading.value = false;
    }
  }

  void addActivity(Activity activity) {
    activities.add(activity);
    Get.snackbar('Success', 'Activity scheduled successfully');
  }

  void updateActivity(Activity activity) {
    int index = activities.indexWhere((a) => a.id == activity.id);
    if (index != -1) {
      activities[index] = activity;
      Get.snackbar('Success', 'Activity updated successfully');
    }
  }

  void deleteActivity(String activityId) {
    activities.removeWhere((a) => a.id == activityId);
    Get.snackbar('Success', 'Activity deleted successfully');
  }

  void addEvent(Event event) {
    events.add(event);
    Get.snackbar('Success', 'Event created successfully');
  }

  void updateEvent(Event event) {
    int index = events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      events[index] = event;
      Get.snackbar('Success', 'Event updated successfully');
    }
  }

  void deleteEvent(String eventId) {
    events.removeWhere((e) => e.id == eventId);
    Get.snackbar('Success', 'Event deleted successfully');
  }

  void joinClub(String studentId, String studentName, String clubId) {
    final club = clubs.firstWhere((c) => c.id == clubId);
    if (club.memberCount < club.maxMembers) {
      final membership = Membership(
        studentId: studentId,
        studentName: studentName,
        clubId: clubId,
        clubName: club.name,
        joinDate: DateTime.now().toString().split(' ')[0],
        role: 'Member',
      );
      memberships.add(membership);

      // Update club member count
      int clubIndex = clubs.indexWhere((c) => c.id == clubId);
      clubs[clubIndex] = club.copyWith(memberCount: club.memberCount + 1);

      Get.snackbar('Success', 'Successfully joined ${club.name}');
    } else {
      Get.snackbar('Error', 'Club is full');
    }
  }

  void uploadVideo({
    required String title,
    required String topic,
    required String level,
    required String clubId,
  }) async {
    try {
      isLoading.value = true;
      final schoolId = selectedSchool.value?.id;

      final response = await _apiService.post(ApiConstants.uploadClubVideo, data: {
        'schoolId': schoolId,
        'clubId': clubId,
        'title': title,
        'topic': topic,
        'level': level,
        'academicYear': '2025-2026',
      });

      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Video uploaded successfully', AppTheme.successGreen);
        if (schoolId != null) loadRecordedClasses(schoolId);
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to upload video', AppTheme.errorRed);
      }
    } catch (e) {
      _showSnackbar('Error', 'Failed to upload video', AppTheme.errorRed);
    } finally {
      isLoading.value = false;
    }
  }

  void updateVideoDetails({
    required String videoId,
    required String title,
    required String topic,
    required String level,
  }) async {
    try {
      isLoading.value = true;

      final response = await _apiService.put('${ApiConstants.updateClubVideoDetails}/$videoId', data: {
        'title': title,
        'topic': topic,
        'level': level,
        'academicYear': '2025-2026',
      });

      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Video updated successfully', AppTheme.successGreen);
        final schoolId = selectedSchool.value?.id;
        if (schoolId != null) loadRecordedClasses(schoolId);
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to update video', AppTheme.errorRed);
      }
    } catch (e) {
      _showSnackbar('Error', 'Failed to update video', AppTheme.errorRed);
    } finally {
      isLoading.value = false;
    }
  }

  void deleteVideo(String videoId) async {
    try {
      isLoading.value = true;

      final response = await _apiService.delete('${ApiConstants.deleteClubVideo}/$videoId');

      if (response.data['ok'] == true) {
        recordedClasses.removeWhere((v) => v.id == videoId);
        _showSnackbar('Success', 'Video deleted successfully', AppTheme.successGreen);
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to delete video', AppTheme.errorRed);
      }
    } catch (e) {
      _showSnackbar('Error', 'Failed to delete video', AppTheme.errorRed);
    } finally {
      isLoading.value = false;
    }
  }

  List<Activity> getActivitiesByStatus(String status) {
    if (status == 'All') return activities;
    return activities.where((activity) => activity.status == status).toList();
  }

  // Club management methods
  Future<void> toggleStudentsInClub(String classId, String clubId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.put('/api/club/toggleclub/student', data: {
        'classId': classId,
        'clubId': clubId,
      });

      if (response.data['ok'] == true) {
        final mode = response.data['mode'];
        final count = response.data['count'];
        _showSnackbar('Success', response.data['message'], AppTheme.successGreen);
        // Auto reload clubs data
        final schoolId = selectedSchool.value?.id;
        if (schoolId != null) await loadClubs(schoolId);
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to toggle students', AppTheme.errorRed);
      }
    } catch (e) {
      _showSnackbar('Error', 'Failed to toggle students in club', AppTheme.errorRed);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addStudentToClub(String studentId, String clubId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.put('/api/club/addtoclub', data: {
        'studentId': studentId,
        'clubId': clubId,
      });

      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Student added to club successfully', AppTheme.successGreen);
        // Auto reload clubs data
        final schoolId = selectedSchool.value?.id;
        if (schoolId != null) await loadClubs(schoolId);
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to add student', AppTheme.errorRed);
      }
    } catch (e) {
      _showSnackbar('Error', 'Failed to add student to club', AppTheme.errorRed);
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<String>> getStudentClubs(String studentId) async {
    // Since the getStudentClubs API doesn't exist, we'll get this info from the student data
    // when we load students. For now, return empty list and rely on student.clubs field
    return [];
  }

  Future<void> removeStudentFromClub(String studentId, String clubId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.put('/api/club/removefromclub', data: {
        'studentId': studentId,
        'clubId': clubId,
      });

      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Student removed from club successfully', AppTheme.successGreen);
        // Auto reload clubs data
        final schoolId = selectedSchool.value?.id;
        if (schoolId != null) await loadClubs(schoolId);
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to remove student', AppTheme.errorRed);
      }
    } catch (e) {
      _showSnackbar('Error', 'Failed to remove student from club', AppTheme.errorRed);
    } finally {
      isLoading.value = false;
    }
  }

  // Add missing methods that are called in the view
  List<Club> getClubsByCategory(String category) {
    if (category == 'All') return clubs;
    return clubs.where((club) => club.category == category).toList();
  }

  List<Club> getClubsByClass(String classId) {

    if (classId.isEmpty) {
      
      return clubs;
    }

    final filtered = clubs.where((club) {
      
      return club.classId == classId;
    }).toList();

    for (var club in filtered) {
      
    }

    return filtered;
  }
}

class Activity {
  final String id;
  final String title;
  final String description;
  final String clubId;
  final String clubName;
  final String date;
  final String time;
  final String location;
  final String status;
  final int participantCount;

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.clubId,
    required this.clubName,
    required this.date,
    required this.time,
    required this.location,
    required this.status,
    required this.participantCount,
  });
}

class Event {
  final String id;
  final String title;
  final String description;
  final String date;
  final String time;
  final String location;
  final String organizer;
  final String category;
  final bool registrationRequired;
  final int maxParticipants;
  final int currentParticipants;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.organizer,
    required this.category,
    required this.registrationRequired,
    required this.maxParticipants,
    required this.currentParticipants,
  });

  bool get isFull => currentParticipants >= maxParticipants;
  double get registrationRate => maxParticipants > 0 ? currentParticipants / maxParticipants : 0;
}

class Membership {
  final String studentId;
  final String studentName;
  final String clubId;
  final String clubName;
  final String joinDate;
  final String role;

  Membership({
    required this.studentId,
    required this.studentName,
    required this.clubId,
    required this.clubName,
    required this.joinDate,
    required this.role,
  });
}

class RecordedClass {
  final String id;
  final String title;
  final String description;
  final String clubName;
  final String clubId;
  final String category;
  final String level;
  final String? academicYear;
  final String? videoUrl;
  final String thumbnailUrl;
  final String instructor;
  final String uploadDate;
  final int viewCount;

  RecordedClass({
    required this.id,
    required this.title,
    required this.description,
    required this.clubName,
    required this.clubId,
    required this.category,
    required this.level,
    this.academicYear,
    this.videoUrl,
    required this.thumbnailUrl,
    required this.instructor,
    required this.uploadDate,
    required this.viewCount,
  });

  factory RecordedClass.fromJson(Map<String, dynamic> json) {
    final videoUrl = json['video']?['url'];

    return RecordedClass(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Untitled',
      description: json['description'] ?? 'No description',
      clubName: json['clubId']?['name'] ?? 'Unknown Club',
      clubId: json['clubId']?['_id'] ?? '',
      category: json['topic'] ?? 'General',
      level: json['level'] ?? 'Beginner',
      academicYear: json['academicYear'],
      videoUrl: videoUrl,
      thumbnailUrl: json['thumbnail']?['url'] ?? '',
      instructor: 'Instructor',
      uploadDate: json['createdAt']?.split('T')[0] ?? 'Unknown',
      viewCount: 0,
    );
  }
}

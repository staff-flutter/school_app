import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:school_app/services/api_service.dart';

class TimetableController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  
  final isLoading = false.obs;
  final timetables = <Map<String, dynamic>>[].obs;
  final teacherSchedule = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
  }

  // 1. Add day to timetable (POST /api/timetable/addday)
  Future<bool> addDay({
    required String schoolId,
    required String classId,
    String? sectionId,
    required String day,
  }) async {
    try {
      isLoading.value = true;
      
      
      
      final data = {
        'schoolId': schoolId,
        'classId': classId,
        'day': day,
      };
      if (sectionId != null && sectionId.isNotEmpty) {
        data['sectionId'] = sectionId;
      }
      
      final response = await _apiService.post('/api/timetable/addday', data: data);
      
      
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(Get.context!);
        Get.snackbar('Success', 'Day added to timetable successfully');
        // Reload timetables after adding day
        await getAllTimetables(schoolId: schoolId, classId: classId, sectionId: sectionId);
        return true;
      }
      return false;
    } catch (e) {
      
      if (e is DioException) {
        
        
        final errorMsg = e.response?.data?['message'] ?? 'Failed to add day';
        Navigator.pop(Get.context!);
        Get.snackbar('Error', errorMsg);
      } else {
        Navigator.pop(Get.context!);
        Get.snackbar('Error', 'Failed to add day');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 2. Update day name (PUT /api/timetable/updateday)
  Future<bool> updateDay({
    required String schoolId,
    required String weeklyScheduleId,
    required String day,
  }) async {
    try {
      isLoading.value = true;
      
      
      
      final response = await _apiService.put('/api/timetable/updateday', data: {
        'schoolId': schoolId,
        'weeklyScheduleId': weeklyScheduleId,
        'day': day,
      });
      
      
      
      if (response.statusCode == 200) {
        Navigator.pop(Get.context!);
        Get.snackbar('Success', 'Day updated successfully');
        return true;
      }
      return false;
    } catch (e) {
      
      if (e is DioException) {
        
        
        final errorMsg = e.response?.data?['message'] ?? 'Failed to update day';
        Navigator.pop(Get.context!);
        Get.snackbar('Error', errorMsg);
      } else {
        Navigator.pop(Get.context!);
        Get.snackbar('Error', 'Failed to Update day');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 3. Delete entire day (DELETE /api/timetable/deleteday)
  Future<bool> deleteDay({
    required String schoolId,
    required String classId,
    String? sectionId,
    required String weeklyScheduleId,
  }) async {
    try {
      isLoading.value = true;
      
      
      
      final response = await _apiService.delete('/api/timetable/deleteday', queryParameters: {
        'schoolId': schoolId,
        'classId': classId,
        if (sectionId != null) 'sectionId': sectionId,
        'weeklyScheduleId': weeklyScheduleId,
      });
      
      
      
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Day deleted successfully');
        return true;
      }
      return false;
    } catch (e) {
      
      if (e is DioException) {
        
        
        final errorMsg = e.response?.data?['message'] ?? 'Failed to delete day';
        Navigator.pop(Get.context!);
        Get.snackbar('Error', errorMsg);
      } else {
        Navigator.pop(Get.context!);
        Get.snackbar('Error', 'Failed to Delete day');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 4. Add/Update period (PUT /api/timetable/updateperiod)
  Future<bool> updatePeriod({
    required String schoolId,
    required String classId,
    String? sectionId,
    required String weeklyScheduleId,
    required String day,
    required Map<String, dynamic> periodData,
  }) async {
    try {
      isLoading.value = true;
      
      
      
      
      final response = await _apiService.put('/api/timetable/updateperiod', data: {
        'schoolId': schoolId,
        'classId': classId,
        if (sectionId != null) 'sectionId': sectionId,
        'weeklyScheduleId': weeklyScheduleId,
        'day': day,
        'periodData': periodData,
      });
      
      
      
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Period updated successfully');
        return true;
      }
      return false;
    } catch (e) {
      
      if (e is DioException) {
        
        
        final errorMsg = e.response?.data?['message'] ?? 'Failed to update period';
        Navigator.pop(Get.context!);
        Get.snackbar('Error', errorMsg);
      } else {
        Navigator.pop(Get.context!);
        Get.snackbar('Error', 'Failed to update period');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 5. Delete period (DELETE /api/timetable/deleteperiod)
  Future<bool> deletePeriod({
    required String schoolId,
    required String classId,
    String? sectionId,
    required String weeklyScheduleId,
    required String periodId,
  }) async {
    try {
      isLoading.value = true;
      
      
      
      final response = await _apiService.delete('/api/timetable/deleteperiod', queryParameters: {
        'schoolId': schoolId,
        'classId': classId,
        if (sectionId != null) 'sectionId': sectionId,
        'weeklyScheduleId': weeklyScheduleId,
        'periodId': periodId,
      });
      
      
      
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Period deleted successfully');
        return true;
      }
      return false;
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to delete period: ${e.toString()}');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 6. Get timetables (GET /api/timetable/getall)
  Future<void> getAllTimetables({
    String? weeklyScheduleId,
    String? schoolId,
    String? classId,
    String? sectionId,
    String? day,
  }) async {
    try {
      
      
      isLoading.value = true;
      
      final queryParams = <String, dynamic>{};
      if (weeklyScheduleId != null) {
        queryParams['weeklyScheduleId'] = weeklyScheduleId;
      } else {
        if (schoolId != null) queryParams['schoolId'] = schoolId;
        if (classId != null) queryParams['classId'] = classId;
        if (sectionId != null) queryParams['sectionId'] = sectionId;
        if (day != null) queryParams['day'] = day;
      }
      
      
      final response = await _apiService.get('/api/timetable/getall', queryParameters: queryParams);
      
      
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data['timetables'] is List) {
          timetables.value = List<Map<String, dynamic>>.from(data['timetables']);
          
        } else if (data is Map && data['data'] is List) {
          timetables.value = List<Map<String, dynamic>>.from(data['data']);
          
        }
      }
    } catch (e) {
      
      if (e is DioException) {
        
        
        if (e.response?.statusCode == 403) {
          
          Get.snackbar('Access Denied', 'You do not have permission to view timetables');
        } else {
          Get.snackbar('Error', 'Failed to fetch timetables: ${e.toString()}');
        }
      } else {
        Get.snackbar('Error', 'Failed to fetch timetables: ${e.toString()}');
      }
    } finally {
      isLoading.value = false;
      
    }
  }

  // 7. Get teacher schedule (GET /api/timetable/teacherschedule)
  Future<void> getTeacherSchedule({
    required String schoolId,
    required String teacherId,
  }) async {
    try {
      isLoading.value = true;
      
      
      
      final response = await _apiService.get(
        '/api/timetable/teacherschedule',
        queryParameters: {
          'schoolId': schoolId,
          'teacherId': teacherId,
        },
      );
      
      
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data['data'] is List) {
          teacherSchedule.value = List<Map<String, dynamic>>.from(data['data']);
          
          
        }
      }
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to fetch teacher schedule: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // 8. Assign/Remove teacher (PUT /api/timetable/assignteacher)
  Future<bool> assignTeacher({
    required String mode, // 'add' or 'remove'
    required String schoolId,
    required String classId,
    String? sectionId,
    required String weeklyScheduleId,
    required int periodNumber,
    required String teacherId,
  }) async {
    try {
      isLoading.value = true;
      
      
      
      final response = await _apiService.put(
        '/api/timetable/assignteacher?mode=$mode',
        data: {
          'schoolId': schoolId,
          'classId': classId,
          if (sectionId != null) 'sectionId': sectionId,
          'weeklyScheduleId': weeklyScheduleId,
          'periodNumber': periodNumber,
          'teacherId': teacherId,
        },
      );
      
      
      
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Teacher ${mode == "add" ? "assigned" : "removed"} successfully');
        return true;
      }
      return false;
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to assign teacher: ${e.toString()}');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 9. Delete entire timetable (DELETE /api/timetable/delete/:id)
  Future<bool> deleteTimetable(String timetableId) async {
    try {
      isLoading.value = true;
      
      
      
      final response = await _apiService.delete('/api/timetable/delete/$timetableId');
      
      
      
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Timetable deleted successfully');
        return true;
      }
      return false;
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to delete timetable: ${e.toString()}');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    timetables.clear();
    teacherSchedule.clear();
    super.onClose();
  }
}
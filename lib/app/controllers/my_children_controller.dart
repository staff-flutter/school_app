import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/app/core/constants/api_constants.dart';
import '../data/services/api_service.dart';
import '../modules/auth/controllers/auth_controller.dart';
import '../data/models/school_models.dart';

class MyChildrenController extends GetxController {
  final ApiService _apiService = Get.find();
  final AuthController _authController = Get.find();
  
  final isLoading = false.obs;
  final children = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadMyChildren();
  }

  Future<void> loadMyChildren() async {
    try {
      isLoading.value = true;
      final user = _authController.user.value;
      
      if (user?.id == null) {
        
        return;
      }

      // Check if user has studentId array from login
      if (user?.studentId != null && user!.studentId!.isNotEmpty) {
        
        await loadChildrenByIds(user.studentId!);
        return;
      }

      // Use WidgetsBinding to avoid build-time errors
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Information', 
          'No children linked. Please contact school administration.',
          duration: const Duration(seconds: 5),
        );
      });
      
    } catch (e) {
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar('Error', 'Failed to load children data');
      });
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> loadChildrenByIds(List<String> studentIds) async {
    final childrenData = <Map<String, dynamic>>[];

    for (String studentId in studentIds) {
      try {

        // First, get student details
        Map<String, dynamic> studentDetails = {};
        try {
          
          final studentResponse = await _apiService.get('/api/student/get/$studentId');

          if (studentResponse.data['ok'] == true) {
            studentDetails = studentResponse.data['data'] ?? {};
            
          } else {
            
          }
        } catch (e) {
          
        }

        // Get class teacher details
        Map<String, dynamic> teacherDetails = {};
        StudentRecord? studentRecord;
        try {

          // Get student record to get class and section information
          final recordResponse = await _apiService.get('/api/studentrecord/getrecord/${_authController.user.value?.schoolId}/$studentId');

          if (recordResponse.data['ok'] == true) {
            final recordData = recordResponse.data['data'];

            // Parse the student record to extract proper IDs and names
            studentRecord = StudentRecord.fromJson(recordData);

            // Use the parsed data directly without additional API calls
            teacherDetails = {
              'sectionName': studentRecord.sectionName ?? 'Unknown Section',
              'className': studentRecord.className ?? 'Unknown Class',
              'rollNumber': studentRecord.rollNumber ?? studentDetails['nonMandatory']?['rollNumber']?.toString() ?? 'N/A',
              'teachers': [], // No teacher data available from this endpoint
            };

          } else {
            
          }
        } catch (e) {
          
        }

        // Then, get recent attendance data
        Map<String, dynamic> attendanceInfo = {};
        try {
          
          final attendanceResponse = await _apiService.get(
            '/api/attendance/student/$studentId',
            queryParameters: {
              'month': DateTime.now().month,
              'year': DateTime.now().year,
            },
          );

          if (attendanceResponse.data['ok'] == true) {
            final attendanceData = attendanceResponse.data['data'];
            attendanceInfo = {
              'data': attendanceData,
              'summary': attendanceResponse.data['summary'] ?? {},
            };
            
          } else {
            
          }
        } catch (e) {
          
        }

        // Combine student details, attendance, and teacher details
        final childData = {
          '_id': studentId,
          'studentName': studentDetails['name'] ?? studentDetails['studentName'] ?? 'Unknown Student',
          'studentImage': studentDetails['studentImage'],
          'classId': studentRecord?.classId ?? '', // Store the actual MongoDB ObjectId
          'className': teacherDetails['className'] ?? 'Unknown Class',
          'rollNumber': teacherDetails['rollNumber'] ?? studentDetails['nonMandatory']?['rollNumber']?.toString() ?? 'N/A',
          'email': studentDetails['email'] ?? '',
          'phone': studentDetails['phone'] ?? '',
          'attendanceData': attendanceInfo,
          'studentDetails': studentDetails,
          'teacherDetails': teacherDetails,
          'sectionName': teacherDetails['sectionName'] ?? 'Unknown Section',
          'teachers': teacherDetails['teachers'] ?? [],
          'mandatory': studentDetails['mandatory'] ?? {},
          'nonMandatory': studentDetails['nonMandatory'] ?? {},
          'clubs': studentDetails['clubs'] ?? [],
        };

        // Debug teacher details
        if (childData['teachers'].isNotEmpty) {
          for (int i = 0; i < childData['teachers'].length; i++) {
            final teacher = childData['teachers'][i];
            
          }
        }

        childrenData.add(childData);

      } catch (e) {
        
        // Add with minimal info if APIs fail
        childrenData.add({
          '_id': studentId,
          'studentName': 'Student $studentId',
          'className': 'Unknown',
          'rollNumber': 'N/A',
          'attendanceData': {},
          'studentDetails': {},
        });
      }
    }

    children.value = childrenData;

  }

  Future<void> viewChildAttendance(String studentId, String studentName) async {
    try {

      // Get student attendance using the parent-accessible endpoint
      final attendanceResponse = await _apiService.get(
        '/api/attendance/student/$studentId',
        queryParameters: {
          'month': DateTime.now().month,
          'year': DateTime.now().year,
        },
      );

      if (attendanceResponse.data['ok'] == true) {
        final attendanceData = attendanceResponse.data['data'];

        // Navigate to specific student attendance view
        final arguments = {
          'studentId': studentId,
          'studentName': studentName,
          'attendanceData': attendanceData,
          'parentView': true,
        };

        Get.toNamed('/attendance/student', arguments: arguments);
      } else {
        Get.snackbar('Error', 'Failed to load attendance data');
      }
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to load attendance data');
    }
  }
}
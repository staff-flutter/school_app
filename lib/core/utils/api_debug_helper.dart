import 'package:get/get.dart';
import 'package:school_app/services/api_service.dart';
import 'package:school_app/constants/api_constants.dart';
// first git commit

class ApiDebugHelper {
  static final ApiService _apiService = Get.find<ApiService>();

  /// Test basic connectivity to the server
  static Future<void> testServerConnection() async {
    try {
      
      final response = await _apiService.get('/api/user/isauthenticated');

    } catch (e) {
      
    }
  }

  /// Test student endpoints with proper parameters
  static Future<void> testStudentEndpoints(String schoolId) async {
    try {

      // Test basic student fetch
      final response = await _apiService.get(
        ApiConstants.getAllStudents,
        queryParameters: {'schoolId': schoolId},
      );

      if (response.data['ok'] == true) {
        final students = response.data['data'] as List;
        
      }
    } catch (e) {
      
    }
  }

  /// Test class and section endpoints
  static Future<void> testClassSectionEndpoints(String schoolId) async {
    try {

      // Test classes
      final classResponse = await _apiService.get('${ApiConstants.getAllClasses}/$schoolId');

      if (classResponse.data['ok'] == true) {
        final classes = classResponse.data['data'] as List;

        if (classes.isNotEmpty) {
          final firstClass = classes.first;
          final classId = firstClass['_id'];

          // Test sections for first class
          final sectionResponse = await _apiService.get(
            ApiConstants.getAllSections,
            queryParameters: {'classId': classId, 'schoolId': schoolId},
          );

        }
      }
    } catch (e) {
      
    }
  }

  /// Run all debug tests
  static Future<void> runAllTests(String schoolId) async {
    await testServerConnection();
    await testStudentEndpoints(schoolId);
    await testClassSectionEndpoints(schoolId);
    
  }
}
import 'package:get/get.dart';
import '../data/services/api_service.dart';

class TeacherController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  
  final teachers = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  bool _teachersLoaded = false;

  Future<void> loadTeachers(String schoolId) async {
    try {
      
      final response = await _apiService.get('/api/teacher/getall/class/section', queryParameters: {'schoolId': schoolId});
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as List;
        final teachersMap = <String, Map<String, dynamic>>{};
        for (var classData in data) {
          final sections = classData['sections'] as List? ?? [];
          for (var section in sections) {
            final teacher = section['teacher'];
            if (teacher != null && teacher['_id'] != null) {
              teachersMap[teacher['_id']] = {
                '_id': teacher['_id'],
                'userName': teacher['userName'] ?? teacher['name'] ?? 'Unknown',
              };
            }
          }
        }
        teachers.value = teachersMap.values.toList()..sort((a, b) => 
          (a['userName'] as String).toLowerCase().compareTo((b['userName'] as String).toLowerCase()));
        _teachersLoaded = true;
        
      }
    } catch (e) {
      
    }
  }

  Future<List<Map<String, dynamic>>> getAllClassSectionAssignments(String schoolId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('/api/teacher/getall/class/section', queryParameters: {'schoolId': schoolId});
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as List;
        // Extract unique teachers from all class sections
        final teachersMap = <String, Map<String, dynamic>>{};
        for (var classData in data) {
          final sections = classData['sections'] as List? ?? [];
          for (var section in sections) {
            final teacher = section['teacher'];
            if (teacher != null && teacher['_id'] != null) {
              teachersMap[teacher['_id']] = {
                '_id': teacher['_id'],
                'userName': teacher['userName'] ?? teacher['name'] ?? 'Unknown',
              };
            }
          }
        }
        teachers.value = teachersMap.values.toList()..sort((a, b) => 
          (a['userName'] as String).toLowerCase().compareTo((b['userName'] as String).toLowerCase()));
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
      return [];
    } catch (e) {
      
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> manageTeacherAssignments({
    required String teacherId,
    required List<Map<String, dynamic>> updates,
    required String schoolId,
  }) async {
    try {
      isLoading.value = true;
      final response = await _apiService.post('/api/teacher/assignments/manage', data: {
        'teacherId': teacherId,
        'updates': updates,
        'schoolId': schoolId,
      });
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Assignment updated successfully');
      }
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to update assignment');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    teachers.clear();
    super.onClose();
  }
}

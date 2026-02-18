import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../data/services/api_service.dart';

class HomeworkController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  
  final isLoading = false.obs;
  final homeworkList = <Map<String, dynamic>>[].obs;
  final currentHomework = Rxn<Map<String, dynamic>>();
  
  // Pagination
  final currentPage = 1.obs;
  final totalPages = 1.obs;
  final limit = 10.obs;

  // Create homework for a specific date and subject (API 93)
  Future<bool> createHomework({
    required String schoolId,
    required String academicYear,
    required String classId,
    String? sectionId,
    required String homeworkDate,
    required String subjectName,
    required String description,
    List<PlatformFile>? files,
  }) async {
    try {
      isLoading.value = true;
      
      
      
      
      
      
      
      
      
      
      
      final response = await _apiService.post('/api/homework/create', data: {
        'schoolId': schoolId,
        'academicYear': academicYear,
        'classId': classId,
        if (sectionId != null) 'sectionId': sectionId,
        'homeworkDate': homeworkDate,
        'subjectName': subjectName,
        'description': description,
        'files': [],
      });
      
      
      
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // If files exist, upload them using addattachments API
        if (files != null && files.isNotEmpty && response.data != null) {
          
          final homeworkData = response.data['homework'] ?? response.data['data'];
          
          if (homeworkData != null) {
            final homeworkId = homeworkData['_id'];
            final subjects = homeworkData['subjects'] as List?;
            
            if (subjects != null && subjects.isNotEmpty) {
              // Use the last subject which is the newly created one
              final newSubject = subjects.last;
              final subjectId = newSubject['_id'];
              
              final attachSuccess = await addAttachments(
                homeworkId: homeworkId,
                subjectId: subjectId,
                files: files,
              );
              
            }
          }
        } else {
          
        }
        
        Get.snackbar('Success', 'Homework created successfully');
        await getAllHomework(schoolId: schoolId, classId: classId, sectionId: sectionId);
        return true;
      }
      return false;
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to create homework: ${e.toString()}');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Add attachments to homework (API 95)
  Future<bool> addAttachments({
    required String homeworkId,
    required String subjectId,
    required List<PlatformFile> files,
  }) async {
    try {
      
      
      
      
      
      final formData = FormData();
      formData.fields.add(MapEntry('homeworkId', homeworkId));
      formData.fields.add(MapEntry('subjectId', subjectId));
      
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        
        
        if (file.bytes != null) {
          
          formData.files.add(MapEntry(
            'files',
            MultipartFile.fromBytes(
              file.bytes!,
              filename: file.name,
            ),
          ));
        } else if (file.path != null) {
          
          formData.files.add(MapEntry(
            'files',
            await MultipartFile.fromFile(
              file.path!,
              filename: file.name,
            ),
          ));
        } else {
          
        }
      }
      
      
      
      
      if (formData.files.isEmpty) {
        Get.snackbar('Error', 'No valid files to upload');
        return false;
      }
      
      final response = await _apiService.dio.put(
        '/api/homework/addattachments',
        data: formData,
      );
      
      
      
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['data'] != null) {
          final homework = responseData['data'];
          final subjects = homework['subjects'] as List?;
          if (subjects != null) {
            final subject = subjects.firstWhereOrNull((s) => s['_id'] == subjectId);
            final attachments = subject?['attachments'] as List?;
            if (attachments != null && attachments.isNotEmpty) {
              Get.snackbar('Success', 'Attachments added successfully');
              return true;
            } else {
              
              Get.snackbar('Warning', 'Files uploaded but not visible yet. Please refresh.');
              return true;
            }
          }
        }
        Get.snackbar('Success', 'Attachments added successfully');
        return true;
      }
      return false;
    } on DioException catch (e) {
      
      
      
      
      
      
      String errorMsg = 'Failed to add attachments';
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          errorMsg = data['message'];
        } else if (data is String) {
          errorMsg = data;
        }
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMsg = 'Upload timeout - file may be too large';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMsg = 'Connection timeout - check your internet';
      } else if (e.response?.statusCode == 502) {
        errorMsg = 'Server error (502) - file may be too large or server is down';
      }
      
      Get.snackbar('Error', errorMsg);
      return false;
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to add attachments: ${e.toString()}');
      return false;
    }
  }

  // Get homework list with pagination (API 98)
  Future<void> getAllHomework({
    required String schoolId,
    required String classId,
    String? sectionId,
    int? page,
    int? pageLimit,
  }) async {
    try {
      
      
      
      
      
      isLoading.value = true;
      
      final queryParams = <String, dynamic>{
        'schoolId': schoolId,
        'classId': classId,
        if (sectionId != null) 'sectionId': sectionId,
        'page': (page ?? currentPage.value).toString(),
        'limit': (pageLimit ?? limit.value).toString(),
      };
      
      
      
      final response = await _apiService.get('/api/homework/getall', queryParameters: queryParams);
      
      
      
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map) {
          // Handle pagination info
          if (data['pagination'] != null) {
            currentPage.value = data['pagination']['currentPage'] ?? 1;
            totalPages.value = data['pagination']['totalPages'] ?? 1;
            
          }
          
          // Handle homework list
          final homeworkData = data['homework'] ?? data['data'];
          if (homeworkData is List) {
            homeworkList.value = List<Map<String, dynamic>>.from(homeworkData);
            
          }
        }
      }
    } catch (e) {
      
      if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
        
        Get.snackbar('Access Denied', 'You do not have permission to view homework');
      } else {
        Get.snackbar('Error', 'Failed to fetch homework: ${e.toString()}');
      }
    } finally {
      isLoading.value = false;
      
    }
  }

  // Delete entire day's homework record (API 100)
  Future<bool> deleteEntireDay(String homeworkId) async {
    try {
      isLoading.value = true;
      
      final response = await _apiService.dio.delete(
        '/api/homework/deleteentireday',
        data: {'homeworkId': homeworkId},
      );
      
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Homework deleted successfully');
        homeworkList.removeWhere((h) => h['_id'] == homeworkId);
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete homework: ${e.toString()}');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Delete attachment from homework (API 96)
  Future<bool> deleteAttachment({
    required String homeworkId,
    required String subjectId,
    required String attachmentId,
  }) async {
    try {
      
      
      
      
      
      final response = await _apiService.dio.delete(
        '/api/homework/deleteattachment',
        data: {
          'homeworkId': homeworkId,
          'subjectId': subjectId,
          'attachmentId': attachmentId,
        },
      );
      
      
      
      
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Attachment deleted successfully');
        return true;
      }
      return false;
    } on DioException catch (e) {
      
      
      
      
      
      String errorMsg = 'Failed to delete attachment';
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          errorMsg = data['message'];
        }
      }
      Get.snackbar('Error', errorMsg);
      return false;
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to delete attachment: ${e.toString()}');
      return false;
    }
  }

  // Delete subject from homework (API 99)
  Future<bool> deleteSubject({
    required String homeworkId,
    required String subjectId,
  }) async {
    try {
      
      
      
      
      final response = await _apiService.dio.delete(
        '/api/homework/deletesubject',
        data: {
          'homeworkId': homeworkId,
          'subjectId': subjectId,
        },
      );
      
      
      
      
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Subject deleted successfully');
        return true;
      }
      return false;
    } on DioException catch (e) {
      
      
      
      
      String errorMsg = 'Failed to delete subject';
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          errorMsg = data['message'];
        }
      }
      Get.snackbar('Error', errorMsg);
      return false;
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to delete subject: ${e.toString()}');
      return false;
    }
  }

  // Helper methods for pagination
  void nextPage() {
    if (currentPage.value < totalPages.value) {
      currentPage.value++;
    }
  }

  void previousPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages.value) {
      currentPage.value = page;
    }
  }

  // Helper method to refresh homework list
  Future<void> refreshHomework({
    required String schoolId,
    required String classId,
    String? sectionId,
  }) async {
    currentPage.value = 1;
    await getAllHomework(
      schoolId: schoolId,
      classId: classId,
      sectionId: sectionId,
    );
  }

  @override
  void onClose() {
    homeworkList.clear();
    currentHomework.value = null;
    super.onClose();
  }
}
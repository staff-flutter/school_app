import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:school_app/constants/api_constants.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/services/api_service.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'dart:typed_data';
class StudentRecordController extends GetxController {
  final ApiService _apiService = Get.find();
  final isLoading = false.obs;
  final studentRecords = <Map<String, dynamic>>[].obs;
  final currentStudentRecord = Rxn<Map<String, dynamic>>();
  final studentDues = Rxn<Map<String, dynamic>>();

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

  // Apply Concession
  Future<bool> applyConcession({
    required String schoolId,
    required String studentId,
    required String? studentName,
    required String classId,
    required String sectionId,
    required String concessionType,
    required double concessionValue,
    required String remark,
    File? proofFile,
    String? busPoint,
    bool? isBusApplicable,
    required String newOld,
  }) async {
    try {
      isLoading.value = true;
      
      final formData = FormData.fromMap({
        'schoolId': schoolId,
        'studentId': studentId,
        'classId': classId,
        'sectionId': sectionId,
        'concessionType': concessionType,
        'concessionValue': concessionValue,
        'remark': remark,
        'newOld': newOld, // Required parameter
        if (studentName != null) 'studentName': studentName,
        if (busPoint != null) 'busPoint': busPoint,
        if (isBusApplicable != null) 'isBusApplicable': isBusApplicable,
      });

      // Add proof file if provided
      if (proofFile != null) {
        try {
          // Extract original filename and extension
          final originalFileName = path.basename(proofFile.path);
          final fileExtension = path.extension(proofFile.path).toLowerCase().replaceFirst('.', '');

          // Determine MIME type
          final mimeType = fileExtension == 'pdf' ? 'application/pdf' :
                          fileExtension == 'jpg' || fileExtension == 'jpeg' ? 'image/jpeg' :
                          fileExtension == 'png' ? 'image/png' : 'application/octet-stream';

          formData.files.add(MapEntry(
            'file',
            await MultipartFile.fromFile(
              proofFile.path,
              filename: originalFileName, // Use original filename instead of generic 'proof.ext'
              contentType: DioMediaType.parse(mimeType),
            ),
          ));
        } catch (e) {
          _showSnackbar('Error', 'Failed to process proof file', AppTheme.errorRed);
          return false;
        }
      }

      // Debug: Print formData contents
      
      formData.fields.forEach((field) {
        
      });
      
      formData.files.forEach((file) {
        
      });

      final response = await _apiService.dio.post(
        ApiConstants.applyConcession,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {

        // Check if response contains success indicators
        if (response.data is Map && response.data['ok'] == true) {
          
          _showSnackbar('Success', response.data['message'] ?? 'Concession applied successfully', AppTheme.successGreen);
          return true;
        } else if (response.data is String && !response.data.contains('<html>')) {
          // Plain text success response
          
          _showSnackbar('Success', 'Concession applied successfully', AppTheme.successGreen);
          return true;
        } else {
          
          _showSnackbar('Warning', 'Concession may have been applied. Please check student record.', AppTheme.warningYellow);
          return true; // Assume success for 200 status
        }
      } else {
        // Handle error responses
        String errorMessage = 'Failed to apply concession';
        if (response.data is Map && response.data['message'] != null) {
          errorMessage = response.data['message'];
        }
        
        _showSnackbar('Error', errorMessage, AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      
      if (e is DioException) {

        String errorMessage = 'An error occurred while applying concession';
        if (e.response?.data != null) {
          final responseData = e.response!.data;

          // Handle JSON response with message field
          if (responseData is Map && responseData['message'] != null) {
            errorMessage = responseData['message'];
          }
          // Handle plain string response
          else if (responseData is String) {
            // Check if it's an HTML error page
            if (responseData.contains('<html>') || responseData.contains('<!DOCTYPE html>')) {
              // Extract error message from HTML or provide generic message
              if (responseData.contains('Internal Server Error')) {
                errorMessage = 'Server error occurred. Please try again later.';
              } else {
                errorMessage = 'An unexpected error occurred. Please contact support.';
              }
            } else {
              errorMessage = responseData;
            }
          }
        } else if (e.message != null) {
          errorMessage = e.message!;
        }

        _showSnackbar('Error', errorMessage, AppTheme.errorRed);
      } else {
        _showSnackbar('Error', 'An error occurred while applying concession', AppTheme.errorRed);
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Collect Fee
  Future<bool> collectFee({
    required String schoolId,
    required String studentId,
    required String classId,
    required String sectionId,
    required double amount,
    required String paymentMode,
    bool? manualDueAllocation,
    Map<String, dynamic>? paidHeads,
    List<Map<String, dynamic>>? cashDenominations,
    String? referenceNumber,
    String? bankName,
    String? chequeDate,
    bool? isBusApplicable,
    String? busPoint,
    String? remarks,
    String? newOld,
  }) async {
    try {
      isLoading.value = true;

      final data = {
        'schoolId': schoolId,
        'studentId': studentId,
        'classId': classId,
        'sectionId': sectionId,
        'amount': amount,
        'paymentMode': paymentMode,
        if (manualDueAllocation != null) 'manualDueAllocation': manualDueAllocation,
        if (paidHeads != null) 'paidHeads': paidHeads,
        if (cashDenominations != null) 'cashDenominations': cashDenominations,
        if (referenceNumber != null) 'referenceNumber': referenceNumber,
        if (bankName != null) 'bankName': bankName,
        if (chequeDate != null) 'chequeDate': chequeDate,
        if (isBusApplicable != null) 'isBusApplicable': isBusApplicable,
        if (busPoint != null) 'busPoint': busPoint,
        if (remarks != null) 'remarks': remarks,
        if (newOld != null) 'newOld': newOld,
      };

      final response = await _apiService.post(ApiConstants.collectFee, data: data);

      if (response.data['ok'] == true) {
        _showSnackbar('Success', 'Fee collected successfully', AppTheme.successGreen);
        return true;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to collect fee', AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      _showSnackbar('Error', 'An error occurred while collecting fee', AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get student records with filters
  Future<Map<String, dynamic>?> getStudentRecords({
    required String schoolId,
    String? classId,
    String? sectionId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      isLoading.value = true;
      
      final queryParams = {
        'schoolId': schoolId,
        'page': page,
        'limit': limit,
      };
      
      if (classId != null) queryParams['classId'] = classId;
      if (sectionId != null) queryParams['sectionId'] = sectionId;
      
      final response = await _apiService.get(
        '/api/studentrecord/getall',
        queryParameters: queryParams,
      );

      if (response.data['ok'] == true) {
        return response.data;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load student records', AppTheme.errorRed);
        return null;
      }
    } catch (e) {
      _showSnackbar('Error', 'Failed to load student records', AppTheme.errorRed);
      
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Get Student Record
  Future<Map<String, dynamic>?> getStudentRecord(String schoolId, String studentId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('${ApiConstants.getStudentRecord}/$schoolId/$studentId');
      
      if (response.data['ok'] == true) {
        currentStudentRecord.value = response.data['data'];
        return response.data['data'];
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load student record', AppTheme.errorRed);
        return null;
      }
    } catch (e) {
      _showSnackbar('Error', 'An error occurred while loading student record', AppTheme.errorRed);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Delete Student Record
  Future<bool> deleteStudentRecord(String recordId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.delete('${ApiConstants.deleteStudentRecord}/$recordId');
      
      if (response.statusCode == 200) {
        _showSnackbar('Success', response.data['message'] ?? 'Student record deleted successfully', AppTheme.successGreen);
        return true;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to delete student record', AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      _showSnackbar('Error', 'An error occurred while deleting student record', AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Toggle Student Status
  Future<bool> toggleStudentStatus(String recordId, bool isActive) async {
    try {
      isLoading.value = true;
      final response = await _apiService.patch(
        '${ApiConstants.toggleStudentStatus}/$recordId',
        data: {'isActive': isActive},
      );

      if (response.statusCode == 200) {
        
        _showSnackbar('Success', response.data['message'] ?? 'Student status updated successfully', AppTheme.successGreen);
        return true;
      } else {

        _showSnackbar('Error', response.data['message'] ?? 'Failed to update student status', AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      
      _showSnackbar('Error', 'An error occurred while updating student status', AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update Concession Value
  Future<bool> updateConcessionValue({
    required String schoolId,
    required String studentId,
    required String classId,
    required String sectionId,
    required String concessionType,
    required double concessionValue,
  }) async {
    try {
      isLoading.value = true;

      final formData = {
        'schoolId': schoolId,
        'studentRecordId': studentId,
        'classId': classId,
        'sectionId': sectionId,
        'concessionType': concessionType,
        'concessionValue': concessionValue,
      };

      final response = await _apiService.put(ApiConstants.updateConcessionValue, data: formData);

      if (response.data['ok'] == true) {
        _showSnackbar('Success', response.data['message'] ?? 'Concession value updated successfully', AppTheme.successGreen);
        return true;
      } else {
        final errorMessage = response.data['message'] ?? 'Failed to update concession value';

        // Check if this is a business logic warning (fees already paid) rather than a technical error
        final isBusinessLogicWarning = errorMessage.contains('Fees already paid') ||
                                       errorMessage.contains('Cannot update concession');

        if (isBusinessLogicWarning) {
          _showSnackbar('Warning', errorMessage, AppTheme.warningYellow);
        } else {
          _showSnackbar('Error', errorMessage, AppTheme.errorRed);
        }
        return false;
      }
    } catch (e) {
      String displayMessage = 'An error occurred while updating concession value';

      if (e is DioException) {
        // If we have a response from the API, use the actual API error message
        if (e.response?.data?['message'] != null) {
          displayMessage = e.response!.data!['message'];
        } else if (e.message != null) {
          displayMessage = e.message!;
        }
      }

      // Check if this is a business logic warning even in the catch block
      final isBusinessLogicWarning = displayMessage.contains('Fees already paid') ||
                                     displayMessage.contains('Cannot update concession');

      if (isBusinessLogicWarning) {
        _showSnackbar('Warning', displayMessage, AppTheme.warningYellow);
      } else {
        _showSnackbar('Error', displayMessage, AppTheme.errorRed);
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update Concession ProofEnsure this is imported
  //
  // Future<bool> updateConcessionProof({
  //   required String schoolId,
  //   required String studentId,
  //   required String classId,
  //   required String sectionId,
  //   required File file,
  // }) async {
  //   try {
  //     isLoading.value = true;
  //
  //     // Read the file as raw binary
  //     final bytes = await file.readAsBytes();
  //     
  //     // Send PUT request with binary payload
  //     final response = await _apiService.dio.put(
  //       ApiConstants.updateConcessionProof,
  //       data: bytes, // Raw binary data in body
  //       queryParameters: {
  //         'schoolId': schoolId,
  //         'studentId': studentId,
  //         'classId': classId,
  //         'sectionId': sectionId,
  //       },
  //       options: Options(
  //         headers: {
  //           'Content-Type': 'application/octet-stream', // Binary stream header
  //           'File-Name': path.basename(file.path),
  //         },
  //       ),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       _showSnackbar('Success', 'Proof uploaded successfully', AppTheme.successGreen);
  //       return true;
  //     }
  //     return false;
  //   } catch (e) {
  //     if (e is DioException && e.response?.statusCode == 413) {
  //       
  //       _showSnackbar('Server Error', 'File is too large for the server. Increase Nginx limit.', AppTheme.errorRed);
  //     } else {
  //       
  //       _showSnackbar('Error', 'An error occurred during upload', AppTheme.errorRed);
  //     }
  //     return false;
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }
  final uploadProgress = 0.0.obs; // Added for progress bar
  // final isLoading = false.obs;
  Future<bool> updateConcessionProof({
    required String recordId,
    required File file,
  }) async {
    try {
      isLoading.value = true;
      uploadProgress.value = 0.0;

      // Get schoolId from auth controller
      final authController = Get.find<AuthController>();
      final schoolId = authController.user.value?.schoolId;

      if (schoolId == null) {
        _showSnackbar('Error', 'School ID not found. Please login again.', AppTheme.errorRed);
        return false;
      }

      final formData = FormData.fromMap({
        'schoolId': schoolId,
        'studentRecordId': recordId,
        'file': await MultipartFile.fromFile(
          file.path,
          filename: path.basename(file.path),
        ),
      });

      final response = await _apiService.dio.put(
        ApiConstants.updateConcessionProof,
        data: formData,
        onSendProgress: (sent, total) {
          if (total != -1) {
            uploadProgress.value = sent / total;
          }
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackbar('Success', response.data['message'] ?? 'Proof uploaded successfully', AppTheme.successGreen);
        return true;
      }
      return false;
    } catch (e) {
      String errorMessage = e.toString();
      String displayMessage = 'Upload failed';

      if (e is DioException) {
        // If we have a response from the API, use the actual API error message
        if (e.response?.data?['message'] != null) {
          displayMessage = e.response!.data!['message'];
        } else if (e.message != null) {
          displayMessage = e.message!;
        }
      }

      _showSnackbar('Error', displayMessage, AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
      uploadProgress.value = 0.0;
    }
  }

  // Revert Receipt
  Future<bool> revertReceipt({
    required String receiptId,
    required String status, // 'cancelled' or 'bounced'
    String? reason,
  }) async {
    try {
      isLoading.value = true;

      final data = {
        'receiptId': receiptId,
        'status': status,
        if (reason != null) 'reason': reason,
      };

      final response = await _apiService.put(ApiConstants.revertReceipt, data: data);

      if (response.data['ok'] == true) {
        _showSnackbar('Success', response.data['message'] ?? 'Receipt reverted successfully', AppTheme.successGreen);
        return true;
      } else {
        
        _showSnackbar('Error', response.data['message'] ?? 'Failed to revert receipt', AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 500) {
        _showSnackbar('Info', 'This receipt has already been reverted.', AppTheme.warningYellow);
        return false;
      }
      
      _showSnackbar('Error', 'An error occurred while reverting receipt', AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get Dues
  Future<Map<String, dynamic>?> getDues({
    required String schoolId,
    required String studentId,
    required String classId,
    required String sectionId,
  }) async {
    try {
      isLoading.value = true;
      
      final queryParams = {
        'schoolId': schoolId,
        'studentId': studentId,
        'classId': classId,
        'sectionId': sectionId,
      };

      final response = await _apiService.get(ApiConstants.getDues, queryParameters: queryParams);
      
      if (response.data['ok'] == true) {
        studentDues.value = response.data['data'];
        return response.data['data'];
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load dues', AppTheme.errorRed);
        return null;
      }
    } catch (e) {
      _showSnackbar('Error', 'An error occurred while loading dues', AppTheme.errorRed);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Load Student Records for a School
  Future<void> loadStudentRecords({required String schoolId}) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('${ApiConstants.getAllStudents}?schoolId=$schoolId');
      
      if (response.data['ok'] == true) {
        studentRecords.value = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      } else {
        
        _showSnackbar('Info', 'No student records found for this school', AppTheme.warningYellow);
      }
    } catch (e) {
      
      _showSnackbar('Info', 'No students found. Please add students first.', AppTheme.warningYellow);
    } finally {
      isLoading.value = false;
    }
  }

  // Get Student by ID
  Future<Map<String, dynamic>?> getStudentById(String studentId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('${ApiConstants.getStudent}/$studentId');
      
      if (response.data['ok'] == true) {
        return response.data['data'];
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Student not found', AppTheme.errorRed);
        return null;
      }
    } catch (e) {
      _showSnackbar('Error', 'An error occurred while fetching student', AppTheme.errorRed);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Get Students by Class
  Future<List<Map<String, dynamic>>> getStudentsByClass(String classId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('${ApiConstants.getStudentsByClass}/$classId');
      
      if (response.data['ok'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load students', AppTheme.errorRed);
        return [];
      }
    } catch (e) {
      _showSnackbar('Error', 'An error occurred while loading students', AppTheme.errorRed);
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  // Update Student Record
  Future<bool> updateStudentRecord(String studentId, Map<String, dynamic> updatedData) async {
    try {
      isLoading.value = true;
      final response = await _apiService.put('${ApiConstants.updateStudent}/$studentId', data: updatedData);
      
      if (response.data['ok'] == true) {
        _showSnackbar('Success', response.data['message'] ?? 'Student record updated successfully', AppTheme.successGreen);
        return true;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to update student', AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      _showSnackbar('Error', 'An error occurred while updating student', AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Create Student Record
  Future<bool> createStudentRecord(Map<String, dynamic> studentData) async {
    try {
      isLoading.value = true;
      final response = await _apiService.post(ApiConstants.createStudent, data: studentData);
      
      if (response.data['ok'] == true) {
        _showSnackbar('Success', response.data['message'] ?? 'Student record created successfully', AppTheme.successGreen);
        return true;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to create student', AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      _showSnackbar('Error', 'An error occurred while creating student', AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get Transaction History
  Future<List<Map<String, dynamic>>> getTransactionHistory({
    required String schoolId,
    String? studentId,
    String? classId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      isLoading.value = true;
      final queryParams = {
        'schoolId': schoolId,
        'page': page.toString(),
        'limit': limit.toString(),
        if (studentId != null) 'studentId': studentId,
        if (classId != null) 'classId': classId,
      };
      
      final response = await _apiService.get(ApiConstants.getTransactionHistory, queryParameters: queryParams);
      
      if (response.data['ok'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load transaction history', AppTheme.errorRed);
        return [];
      }
    } catch (e) {
      _showSnackbar('Error', 'An error occurred while loading transaction history', AppTheme.errorRed);
      return [];
    } finally {
      isLoading.value = false;
    }
  }
}

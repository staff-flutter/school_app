import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:school_app/constants/api_constants.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/services/api_service.dart';

class BillAdmissionController extends GetxController {
  final ApiService _apiService = Get.find();

  final isLoading = false.obs;

  // Bill Book
  final billBooks = <Map<String, dynamic>>[].obs;
  final currentBillBook = Rxn<Map<String, dynamic>>();

  // Admission Book
  final admissionBooks = <Map<String, dynamic>>[].obs;
  final currentAdmissionBook = Rxn<Map<String, dynamic>>();

  // Admission Form
  final admissionForms = <Map<String, dynamic>>[].obs;
  final currentAdmissionForm = Rxn<Map<String, dynamic>>();
  final admissionFormDropdown = <Map<String, dynamic>>[].obs;

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

  String _extractErrorMessage(Object e, String fallback) {
    if (e is DioException) {
      final responseData = e.response?.data;
      if (responseData is Map && responseData['message'] != null) {
        return responseData['message'].toString();
      } else if (responseData is String &&
          !responseData.contains('<html>') &&
          !responseData.contains('<!DOCTYPE html>')) {
        return responseData;
      } else if (e.message != null) {
        return e.message!;
      }
    }
    return fallback;
  }

  // ---------------------------------------------------------------------
  // Bill Book Endpoints
  // ---------------------------------------------------------------------

  // api no: 162 - Create New Bill Book
  Future<bool> createNewBillBook({
    required String schoolId,
    required Map<String, dynamic> billBookData,
  }) async {
    try {
      isLoading.value = true;

      final data = {
        'schoolId': schoolId,
        ...billBookData,
      };

      final response = await _apiService.post(ApiConstants.createNewBillBook, data: data);

      if (response.data['ok'] == true) {
        _showSnackbar('Success', response.data['message'] ?? 'Bill book created successfully', AppTheme.successGreen);
        return true;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to create bill book', AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      _showSnackbar('Error', _extractErrorMessage(e, 'An error occurred while creating bill book'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // api no: 163 - Get All Bill Books
  Future<List<Map<String, dynamic>>> getAllBillBooks({required String schoolId}) async {
    try {
      isLoading.value = true;

      final response = await _apiService.get(
        ApiConstants.getAllBillBooks,
        queryParameters: {'schoolId': schoolId},
      );

      if (response.data['ok'] == true) {
        final list = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        billBooks.value = list;
        return list;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load bill books', AppTheme.errorRed);
        return [];
      }
    } catch (e) {
      _showSnackbar('Error', _extractErrorMessage(e, 'An error occurred while loading bill books'), AppTheme.errorRed);
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  // api no: 164 - Update Bill Book
  Future<bool> updateBillBook({
    required String billBookId,
    required Map<String, dynamic> updatedData,
  }) async {
    try {
      isLoading.value = true;

      final response = await _apiService.put(
        ApiConstants.updateBillBook,
        queryParameters: {'BillBookId': billBookId},
        data: updatedData,
      );

      if (response.data['ok'] == true) {
        _showSnackbar('Success', response.data['message'] ?? 'Bill book updated successfully', AppTheme.successGreen);
        return true;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to update bill book', AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      _showSnackbar('Error', _extractErrorMessage(e, 'An error occurred while updating bill book'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // api no: 165 - Manually Update Bill Number (sequence)
  Future<bool> manuallyUpdateBillNumber({
    required String billBookId,
    required int newSequence,
  }) async {
    try {
      isLoading.value = true;

      final url = ApiConstants.manuallyUpdateBillNumber.replaceFirst(':id', billBookId);

      final response = await _apiService.put(
        url,
        queryParameters: {'BillBookId': billBookId},
        data: {'sequence': newSequence},
      );

      if (response.data['ok'] == true) {
        _showSnackbar('Success', response.data['message'] ?? 'Bill number updated successfully', AppTheme.successGreen);
        return true;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to update bill number', AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      _showSnackbar('Error', _extractErrorMessage(e, 'An error occurred while updating bill number'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // api no: 166 - Delete Inactive Bill Book
  Future<bool> deleteInactiveBillBook({required String billBookId}) async {
    try {
      isLoading.value = true;

      final response = await _apiService.delete(
        ApiConstants.deleteInactiveBillBook,
        queryParameters: {'BillBookId': billBookId},
      );

      if (response.statusCode == 200 && (response.data['ok'] == true)) {
        _showSnackbar('Success', response.data['message'] ?? 'Bill book deleted successfully', AppTheme.successGreen);
        return true;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to delete bill book', AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      _showSnackbar('Error', _extractErrorMessage(e, 'An error occurred while deleting bill book'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------
  // Admission Book Endpoints
  // ---------------------------------------------------------------------

  // api no: 167 - Create New Admission Book
  Future<bool> createNewAdmissionBook({
    required String schoolId,
    required Map<String, dynamic> admissionBookData,
  }) async {
    try {
      isLoading.value = true;

      final data = {
        'schoolId': schoolId,
        ...admissionBookData,
      };

      final response = await _apiService.post(ApiConstants.createNewBookAdmissionForSchool, data: data);

      if (response.data['ok'] == true) {
        _showSnackbar('Success', response.data['message'] ?? 'Admission book created successfully', AppTheme.successGreen);
        return true;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to create admission book', AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      _showSnackbar('Error', _extractErrorMessage(e, 'An error occurred while creating admission book'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // api no: 168 - Get All Admission Books
  Future<List<Map<String, dynamic>>> getAllAdmissionBooks({required String schoolId}) async {
    try {
      isLoading.value = true;

      final response = await _apiService.get(
        ApiConstants.getAllAdmissionBooks,
        queryParameters: {'schoolId': schoolId},
      );

      if (response.data['ok'] == true) {
        final list = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        admissionBooks.value = list;
        return list;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load admission books', AppTheme.errorRed);
        return [];
      }
    } catch (e) {
      _showSnackbar('Error', _extractErrorMessage(e, 'An error occurred while loading admission books'), AppTheme.errorRed);
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  // api no: 169 - Update Admission Book
  Future<bool> updateAdmissionBook({
    required String admissionBookId,
    required Map<String, dynamic> updatedData,
  }) async {
    try {
      isLoading.value = true;

      final response = await _apiService.put(
        ApiConstants.updateAdmissionBook,
        queryParameters: {'AdmissionBookId': admissionBookId},
        data: updatedData,
      );

      if (response.data['ok'] == true) {
        _showSnackbar('Success', response.data['message'] ?? 'Admission book updated successfully', AppTheme.successGreen);
        return true;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to update admission book', AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      _showSnackbar('Error', _extractErrorMessage(e, 'An error occurred while updating admission book'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // api no: 170 - Manually Update Admission Form Number (sequence)
  Future<bool> manuallyUpdateAdmissionFormNumber({
    required String admissionBookId,
    required int newSequence,
  }) async {
    try {
      isLoading.value = true;
      final queryParams = {
        'AdmissionBookId': admissionBookId
      };
      final url = ApiConstants.manuallyUpdateAdmissionFormNumber.replaceFirst(':id', admissionBookId);

      final response = await _apiService.put(
        url,
        queryParameters: queryParams,
        data: {'sequence': newSequence},
      );

      if (response.data['ok'] == true) {
        _showSnackbar('Success', response.data['message'] ?? 'Admission form number updated successfully', AppTheme.successGreen);
        return true;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to update admission form number', AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      _showSnackbar('Error', _extractErrorMessage(e, 'An error occurred while updating admission form number'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // api no: 171 - Delete Inactive Admission Book
  Future<bool> deleteInactiveAdmissionBook({required String admissionBookId}) async {
    try {
      isLoading.value = true;

      final response = await _apiService.delete(
        ApiConstants.deleteInactiveAdmissionBook,
        queryParameters: {'AdmissionBookId': admissionBookId},
      );

      if (response.statusCode == 200 && (response.data['ok'] == true)) {
        _showSnackbar('Success', response.data['message'] ?? 'Admission book deleted successfully', AppTheme.successGreen);
        return true;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to delete admission book', AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      _showSnackbar('Error', _extractErrorMessage(e, 'An error occurred while deleting admission book'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------
  // Admission Form Endpoints
  // ---------------------------------------------------------------------

  // api no: 172 - Generate New Admission Form Link
  Future<Map<String, dynamic>?> generateNewAdmissionFormLink({
    required Map<String, dynamic> linkData,
  }) async {
    try {
      isLoading.value = true;

      final response = await _apiService.post(ApiConstants.generateNewAdmissionFormLink, data: linkData);

      if (response.data['ok'] == true) {
        _showSnackbar('Success', response.data['message'] ?? 'Admission form link generated successfully', AppTheme.successGreen);
        return response.data['data'];
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to generate admission form link', AppTheme.errorRed);
        return null;
      }
    } catch (e) {
      _showSnackbar('Error', _extractErrorMessage(e, 'An error occurred while generating admission form link'), AppTheme.errorRed);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // api no: 173 - Submit Admission Form
  Future<bool> submitAdmissionForm({
    required String admissionFormId,
    required Map<String, dynamic> formData,
  }) async {
    try {
      isLoading.value = true;

      final response = await _apiService.post(
        ApiConstants.submitAdmissionForm,
        queryParameters: {'AdmissionFormId': admissionFormId},
        data: formData,
      );

      if (response.data['ok'] == true) {
        _showSnackbar('Success', response.data['message'] ?? 'Admission form submitted successfully', AppTheme.successGreen);
        return true;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to submit admission form', AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      _showSnackbar('Error', _extractErrorMessage(e, 'An error occurred while submitting admission form'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // api no: 174 - Get Admission Form Dropdown
  Future<List<Map<String, dynamic>>> getAdmissionForm({
    required String admissionFormId,
    required String academicYear,
    String? search,
  }) async {
    try {
      isLoading.value = true;

      final queryParams = {
        'AdmissionFormId': admissionFormId,
        'academicYear': academicYear,
        if (search != null) 'search': search,
      };

      final response = await _apiService.get(ApiConstants.getAdmissionForm, queryParameters: queryParams);

      if (response.data['ok'] == true) {
        final list = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        admissionFormDropdown.value = list;
        return list;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load admission form dropdown', AppTheme.errorRed);
        return [];
      }
    } catch (e) {
      _showSnackbar('Error', _extractErrorMessage(e, 'An error occurred while loading admission form dropdown'), AppTheme.errorRed);
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  // api no: 175 - Get Single Admission Form
  Future<Map<String, dynamic>?> getSingleAdmissionForm({
    String? admissionFormId,
    String? studentId,
  }) async {
    try {
      isLoading.value = true;

      final queryParams = {
        if (admissionFormId != null) 'AdmissionFormId': admissionFormId,
        if (studentId != null) 'studentId': studentId,
      };

      final response = await _apiService.get(ApiConstants.getSingleAdmissionForm, queryParameters: queryParams);

      if (response.data['ok'] == true) {
        currentAdmissionForm.value = response.data['data'];
        return response.data['data'];
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load admission form', AppTheme.errorRed);
        return null;
      }
    } catch (e) {
      _showSnackbar('Error', _extractErrorMessage(e, 'An error occurred while loading admission form'), AppTheme.errorRed);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // api no: 176 - Get All Admission Forms
  Future<List<Map<String, dynamic>>> getAllAdmissionForms({
    required String schoolId,
    String? academicYear,
    String? status,
    String? search,
    String? startDate,
    String? endDate,
    int? page,
    int? limit,
  }) async {
    try {
      isLoading.value = true;

      final queryParams = {
        'SchoolId': schoolId,
        if (academicYear != null) 'academicYear': academicYear,
        if (status != null) 'status': status,
        if (search != null) 'search': search,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (page != null) 'page': page.toString(),
        if (limit != null) 'limit': limit.toString(),
      };

      final response = await _apiService.get(ApiConstants.getAllAdmissionForms, queryParameters: queryParams);

      if (response.data['ok'] == true) {
        final list = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        admissionForms.value = list;
        return list;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load admission forms', AppTheme.errorRed);
        return [];
      }
    } catch (e) {
      _showSnackbar('Error', _extractErrorMessage(e, 'An error occurred while loading admission forms'), AppTheme.errorRed);
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  // api no: 177 - Delete Admission Form
  Future<bool> deleteAdmissionForm({required String admissionFormId}) async {
    try {
      isLoading.value = true;

      final response = await _apiService.delete(
        ApiConstants.deleteAdmissionForm,
        queryParameters: {'AdmissionFormId': admissionFormId},
      );

      if (response.statusCode == 200 && (response.data['ok'] == true)) {
        _showSnackbar('Success', response.data['message'] ?? 'Admission form deleted successfully', AppTheme.successGreen);
        return true;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to delete admission form', AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      _showSnackbar('Error', _extractErrorMessage(e, 'An error occurred while deleting admission form'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // api no: 179 - Update Admission Form Status
  Future<bool> updateAdmissionFormStatus({
    required String admissionFormId,
    required String status,
  }) async {
    try {
      isLoading.value = true;

      final response = await _apiService.put(
        ApiConstants.updateAdmissionFormStatus,
        queryParameters: {'AdmissionFormId': admissionFormId},
        data: {'status': status},
      );

      if (response.data['ok'] == true) {
        _showSnackbar('Success', response.data['message'] ?? 'Admission form status updated successfully', AppTheme.successGreen);
        return true;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to update admission form status', AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      _showSnackbar('Error', _extractErrorMessage(e, 'An error occurred while updating admission form status'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // api no: 180 - Update Admission Form After Submission
  // Either admissionFormId or studentId must be provided.
  Future<bool> updateAdmissionFormAfterSubmission({
    String? admissionFormId,
    String? studentId,
    required Map<String, dynamic> updatedData,
  }) async {
    assert(admissionFormId != null || studentId != null,
    'Either admissionFormId or studentId must be provided');

    try {
      isLoading.value = true;

      final queryParams = {
        if (admissionFormId != null) 'AdmissionFormId': admissionFormId,
        if (studentId != null) 'StudentId': studentId,
      };

      final response = await _apiService.put(
        ApiConstants.updateAdmissionFormAfterSubmission,
        queryParameters: queryParams,
        data: updatedData,
      );

      if (response.data['ok'] == true) {
        _showSnackbar('Success', response.data['message'] ?? 'Admission form updated successfully', AppTheme.successGreen);
        return true;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to update admission form', AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      _showSnackbar('Error', _extractErrorMessage(e, 'An error occurred while updating admission form'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // api no: 181 - Link Admission Form To Student
  Future<bool> linkAdmissionFormToStudent({
    required String admissionFormId,
    required String studentId,
  }) async {
    try {
      isLoading.value = true;

      final url = ApiConstants.linkAdmissionFormToStudent.replaceFirst(':id', admissionFormId);

      final response = await _apiService.put(
        url,
        queryParameters: {'AdmissionFormId': admissionFormId},
        data: {'studentId': studentId},
      );

      if (response.data['ok'] == true) {
        _showSnackbar('Success', response.data['message'] ?? 'Admission form linked to student successfully', AppTheme.successGreen);
        return true;
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to link admission form to student', AppTheme.errorRed);
        return false;
      }
    } catch (e) {
      _showSnackbar('Error', _extractErrorMessage(e, 'An error occurred while linking admission form to student'), AppTheme.errorRed);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
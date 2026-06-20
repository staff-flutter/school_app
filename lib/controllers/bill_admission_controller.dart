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

  // api no: 162 - POST /api/school-config/bill-book/
  // Creates the bill book as active; automatically deactivates other
  // active bill books for the same school + academic year.
  Future<bool> createNewBillBook({
    required String schoolId,
    required String bookName,
    required int billNumber,
  }) async {
    try {
      isLoading.value = true;

      final response = await _apiService.post(
        ApiConstants.createNewBillBook,
        data: {
          'schoolId': schoolId,
          'bookName': bookName,
          'billNumber': billNumber,
        },
      );

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

  // api no: 163 - GET /api/school-config/bill-book/:schoolId
  Future<List<Map<String, dynamic>>> getAllBillBooks({required String schoolId}) async {
    try {
      isLoading.value = true;

      final response = await _apiService.get('${ApiConstants.getAllBillBooks}/$schoolId');

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

  // api no: 164 - PATCH /api/school-config/bill-book/:id
  // Activating a book auto-deactivates others; cannot deactivate the only active book.
  Future<bool> updateBillBook({
    required String billBookId,
    String? bookName,
    bool? isActive,
  }) async {
    try {
      isLoading.value = true;

      final data = {
        if (bookName != null) 'bookName': bookName,
        if (isActive != null) 'isActive': isActive,
      };

      final response = await _apiService.patch('${ApiConstants.updateBillBook}/$billBookId', data: data);

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

  // api no: 165 - PATCH /api/school-config/bill-book/:id/sequence
  Future<bool> manuallyUpdateBillNumber({
    required String billBookId,
    required int newBillNumber,
  }) async {
    try {
      isLoading.value = true;

      final url = ApiConstants.manuallyUpdateBillNumber.replaceFirst(':id', billBookId);

      final response = await _apiService.patch(url, data: {'newBillNumber': newBillNumber});

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

  // api no: 166 - DELETE /api/school-config/bill-book/:id
  // Active bill books cannot be deleted.
  Future<bool> deleteInactiveBillBook({required String billBookId}) async {
    try {
      isLoading.value = true;

      final response = await _apiService.delete('${ApiConstants.deleteInactiveBillBook}/$billBookId');

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

  // api no: 167 - POST /api/school-config/admission-book/
  // startingFormNumber is a formatted string, e.g. "ADM-001".
  Future<bool> createNewAdmissionBook({
    required String schoolId,
    required String bookName,
    required String startingFormNumber,
  }) async {
    try {
      isLoading.value = true;

      final response = await _apiService.post(
        ApiConstants.createNewBookAdmissionForSchool,
        data: {
          'schoolId': schoolId,
          'bookName': bookName,
          'startingFormNumber': startingFormNumber,
        },
      );

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

  // api no: 168 - GET /api/school-config/admission-book/:schoolId
  Future<List<Map<String, dynamic>>> getAllAdmissionBooks({required String schoolId}) async {
    try {
      isLoading.value = true;

      final response = await _apiService.get('${ApiConstants.getAllAdmissionBooks}/$schoolId');
      print('schoolId:$schoolId');

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

  // api no: 169 - PATCH /api/school-config/admission-book/:id
  Future<bool> updateAdmissionBook({
    required String admissionBookId,
    String? bookName,
    bool? isActive,
  }) async {
    try {
      isLoading.value = true;

      final data = {
        if (bookName != null) 'bookName': bookName,
        if (isActive != null) 'isActive': isActive,
      };

      final response = await _apiService.patch('${ApiConstants.updateAdmissionBook}/$admissionBookId', data: data);

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

  // api no: 170 - PATCH /api/school-config/admission-book/:id/sequence
  // newFormNumber is a formatted string, e.g. "ADM-100".
  Future<bool> manuallyUpdateAdmissionFormNumber({
    required String admissionBookId,
    required String newFormNumber,
  }) async {
    try {
      isLoading.value = true;

      final url = ApiConstants.manuallyUpdateAdmissionFormNumber.replaceFirst(':id', admissionBookId);

      final response = await _apiService.patch(url, data: {'newFormNumber': newFormNumber});

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

  // api no: 171 - DELETE /api/school-config/admission-book/:id
  Future<bool> deleteInactiveAdmissionBook({required String admissionBookId}) async {
    try {
      isLoading.value = true;

      final response = await _apiService.delete('${ApiConstants.deleteInactiveAdmissionBook}/$admissionBookId');

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

  // api no: 172 - POST /api/school/admission-form/generate-link
  // Body is just schoolId. Returns the new admission form id + assigned form number.
  Future<Map<String, dynamic>?> generateNewAdmissionFormLink({required String schoolId}) async {
    try {
      isLoading.value = true;

      final response = await _apiService.post(
        ApiConstants.generateNewAdmissionFormLink,
        data: {'schoolId': schoolId},
      );

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

  // api no: 173 - PUT /api/school/admission-form/admissions/submit/:id
  // Public endpoint - no auth header is required by the backend, but calling
  // it through the authenticated ApiService is fine for staff-entered forms.
  // formData keys should match the IAdmissionForm schema, e.g.:
  // academicYear, studentName, mobileNumber, dob, age, gender, motherTongue,
  // religion, community, emisNumber, currentAddress, permanentAddress,
  // fatherName, fatherEducation, fatherOccupation, motherName,
  // motherEducation, motherOccupation, examinationPassed, admissionSoughtFor.
  Future<bool> submitAdmissionForm({
    required String admissionFormId,
    required Map<String, dynamic> formData,
  }) async {
    try {
      isLoading.value = true;

      final response = await _apiService.put(
        '${ApiConstants.submitAdmissionForm}/$admissionFormId',
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

  // api no: 174 - GET /api/school/admission-form/dropdown
  Future<List<Map<String, dynamic>>> getAdmissionFormDropdown({
    required String schoolId,
    required String academicYear,
    String? search,
  }) async {
    try {
      isLoading.value = true;

      final queryParams = {
        'schoolId': schoolId,
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

  // api no: 175 - GET /api/school/admission-form/form
  // Either id or studentId must be provided.
  Future<Map<String, dynamic>?> getSingleAdmissionForm({
    String? admissionFormId,
    String? studentId,
  }) async {
    try {
      isLoading.value = true;

      final queryParams = {
        if (admissionFormId != null) 'id': admissionFormId,
        if (studentId != null) 'studentId': studentId,
      };
         print('studentId:$studentId');
      print('admissionFormId:$admissionFormId');

      final response = await _apiService.get(ApiConstants.getSingleAdmissionForm, queryParameters: queryParams);

      if (response.data['ok'] == true) {
        currentAdmissionForm.value = response.data['data'];
        return response.data['data'];
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load admission form', AppTheme.errorRed);
        return null;
      }
    } catch (e) {
      print("DEBUG ERROR: $e");
      //_showSnackbar('Error', _extractErrorMessage(e, 'An error occurred while loading admission form'), AppTheme.errorRed);
      _showSnackbar('Error', e.toString(), AppTheme.errorRed);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // api no: 176 - GET /api/school/admission-form/:schoolId
  // Returns paginated forms with total count / total pages / hasNextPage.
  Future<Map<String, dynamic>> getAllAdmissionForms({
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
        if (academicYear != null) 'academicYear': academicYear,
        if (status != null) 'status': status,
        if (search != null) 'search': search,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (page != null) 'page': page.toString(),
        if (limit != null) 'limit': limit.toString(),
      };

      final response = await _apiService.get(
        '${ApiConstants.getAllAdmissionForms}/$schoolId',
        queryParameters: queryParams,
      );
      print("ACTUAL BACKEND DATA: ${response.data['data']}");
       print('getAllAdmissionForms schoolId :$schoolId');
      if (response.data['ok'] == true) {
        final backendData = response.data['data'] ?? {};
        final list = List<Map<String, dynamic>>.from(backendData['forms'] ?? []);
        admissionForms.value = list;
        return {
          'data': list,
          'totalCount': backendData['totalForms'],
          'totalPages': response.data['totalPages'],
          'hasNextPage': response.data['hasNextPage'],
        };
      } else {
        _showSnackbar('Error', response.data['message'] ?? 'Failed to load admission forms', AppTheme.errorRed);
        return {'data': <Map<String, dynamic>>[]};
      }
    } catch (e) {

      print("DEBUG ERROR: $e");
      _showSnackbar('Error', _extractErrorMessage(e, 'An error occurred while loading admission forms'), AppTheme.errorRed);
      return {'data': <Map<String, dynamic>>[]};
    } finally {
      isLoading.value = false;
    }
  }

  // api no: 177 - DELETE /api/school/admission-form/:id
  Future<bool> deleteAdmissionForm({required String admissionFormId}) async {
    try {
      isLoading.value = true;

      final response = await _apiService.delete('${ApiConstants.deleteAdmissionForm}/$admissionFormId');

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

  // api no: 179 - PATCH /api/school/admission-form/status
  // Either admissionFormId or studentId must be provided.
  // status must be exactly 'Pending', 'Approved', or 'Rejected'.
  Future<bool> updateAdmissionFormStatus({
    String? admissionFormId,
    String? studentId,
    required String status,
  }) async {
    assert(admissionFormId != null || studentId != null,
    'Either admissionFormId or studentId must be provided');

    try {
      isLoading.value = true;

      final queryParams = {
        if (admissionFormId != null) 'id': admissionFormId,
        if (studentId != null) 'studentId': studentId,
      };

      final response = await _apiService.patch(
        ApiConstants.updateAdmissionFormStatus,
        queryParameters: queryParams,
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

  // api no: 180 - PUT /api/school/admission-form/details
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
        if (admissionFormId != null) 'id': admissionFormId,
        if (studentId != null) 'studentId': studentId,
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

  // api no: 181 - PATCH /api/school/admission-form/:id/linkstudent
  Future<bool> linkAdmissionFormToStudent({
    required String admissionFormId,
    required String studentId,
  }) async {
    try {
      isLoading.value = true;

      final url = ApiConstants.linkAdmissionFormToStudent.replaceFirst(':id', admissionFormId);

      final response = await _apiService.patch(url, data: {'studentId': studentId});

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
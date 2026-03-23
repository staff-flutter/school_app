import 'dart:convert';
import 'package:get/get.dart';
import 'package:school_app/services/api_service.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class FinanceLedgerController extends GetxController {
  final ApiService _apiService = Get.find();
  final isLoading = false.obs;
  final transactions = <Map<String, dynamic>>[].obs;
  final stats = Rxn<Map<String, dynamic>>();
  final timelineData = <Map<String, dynamic>>[].obs;

  // Filter state variables
  final selectedAcademicYear = Rxn<String>();
  final selectedTransactionType = Rxn<String>();
  final selectedAccountType = Rxn<String>();
  final selectedStatus = Rxn<String>();
  final selectedPaymentMode = Rxn<String>();
  final selectedSection = Rxn<String>();
  final fromDate = Rxn<DateTime>();
  final toDate = Rxn<DateTime>();
  final currentPage = 1.obs;
  final totalPages = 1.obs;

  // Get all finance ledger transactions
  Future<Map<String, dynamic>?> getAllTransactions({
    required String schoolId,
    String? academicYear,
    String? transactionType,
    String? accountType,
    String? status,
    String? paymentMode,
    String? section,
    String? fromDate,
    String? toDate,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      isLoading.value = true;
      final queryParams = {
        'schoolId': schoolId,
        'page': page,
        'limit': limit,
      };
      
      if (academicYear != null) queryParams['academicYear'] = academicYear;
      if (transactionType != null) queryParams['transactionType'] = transactionType;
      if (accountType != null) queryParams['accountType'] = accountType;
      if (status != null) queryParams['status'] = status;
      if (paymentMode != null) queryParams['paymentMode'] = paymentMode;
      if (section != null) queryParams['section'] = section;
      if (fromDate != null) queryParams['fromDate'] = fromDate;
      if (toDate != null) queryParams['toDate'] = toDate;

      final response = await _apiService.get('/api/financeledger/getall', queryParameters: queryParams);
      
      if (response.data['ok'] == true) {
        transactions.value = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        return response.data;
      }
      return null;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load transactions',
        backgroundColor: AppTheme.errorRed, colorText: Colors.white);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Clear all filters
  void clearFilters() {
    selectedAcademicYear.value = null;
    selectedTransactionType.value = null;
    selectedAccountType.value = null;
    selectedStatus.value = null;
    selectedPaymentMode.value = null;
    selectedSection.value = null;
    fromDate.value = null;
    toDate.value = null;
    currentPage.value = 1;
  }

  // Apply filters and reload transactions
  Future<void> applyFilters(String schoolId) async {
    final result = await getAllTransactions(
      schoolId: schoolId,
      academicYear: selectedAcademicYear.value,
      transactionType: selectedTransactionType.value,
      accountType: selectedAccountType.value,
      status: selectedStatus.value,
      paymentMode: selectedPaymentMode.value,
      section: selectedSection.value,
      fromDate: fromDate.value?.toIso8601String().split('T').first,
      toDate: toDate.value?.toIso8601String().split('T').first,
      page: currentPage.value,
      limit: 20,
    );

    if (result != null) {
      totalPages.value = (result['pagination']?['totalPages'] ?? 1);
    }
  }

  // Get single transaction

  // Get finance stats
  Future<void> getFinanceStats({
    required String schoolId,
    required String range,
    String? startDate,
    String? endDate,
    String? section,
  }) async {
    try {
      isLoading.value = true;
      final queryParams = {
        'schoolId': schoolId,
        'range': range,
      };
      
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (section != null) queryParams['section'] = section;

      final response = await _apiService.get('/api/financeledger/stats', queryParameters: queryParams);
      
      if (response.data != null && response.data['data'] != null) {
        stats.value = response.data['data'];
        
        update(); // Trigger GetBuilder rebuild
      } else {
        
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load finance stats',
        backgroundColor: AppTheme.errorRed, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // Get single transaction details
  final Rx<Map<String, dynamic>?> selectedTransaction = Rx<Map<String, dynamic>?>(null);
  final Rx<Map<String, dynamic>?> studentDetails = Rx<Map<String, dynamic>?>(null);

  Future<Map<String, dynamic>?> getTransaction(String transactionId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get('/api/financeledger/get/$transactionId');
      
      if (response.data['ok'] == true) {
        selectedTransaction.value = response.data['data'];

        // Fetch student details if studentRecordId exists
        final transaction = response.data['data'];
        if (transaction['studentRecordId'] != null && transaction['studentRecordId']['studentId'] != null) {
          await getStudentDetails(
            transaction['schoolId'], 
            transaction['studentRecordId']['studentId']
          );
        }
        
        return response.data['data'];
      }
      return null;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load transaction details',
        backgroundColor: AppTheme.errorRed, colorText: Colors.white);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Get student details using studentId
  Future<Map<String, dynamic>?> getStudentDetails(String schoolId, String studentId) async {
    try {
      final response = await _apiService.get('/api/studentrecord/getrecord/$schoolId/$studentId');
      
      if (response.data['ok'] == true) {
        studentDetails.value = response.data['data'];
        return response.data['data'];
      }
      return null;
    } catch (e) {
      
      return null;
    }
  }

  // Get student name from studentDetails or return studentId as fallback
  String getStudentDisplayName() {
    if (studentDetails.value != null) {
      return studentDetails.value!['studentName'] ?? 
             studentDetails.value!['studentId']?['studentName'] ?? 'Unknown Student';
    }
    return 'Unknown Student';
  }

  // Get timeline data
  Future<void> getTimelineData({
    required String schoolId,
    required String range,
    String? startDate,
    String? endDate,
    String? section,
  }) async {
    try {
      isLoading.value = true;
      final queryParams = {
        'schoolId': schoolId,
        'range': range,
      };
      
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (section != null) queryParams['section'] = section;

      final response = await _apiService.get('/api/financeledger/timeline', queryParameters: queryParams);
      
      if (response.data['ok'] == true) {
        timelineData.value = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load timeline data',
        backgroundColor: AppTheme.errorRed, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/accounting_models.dart';
import '../../../data/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/permissions/permission_system.dart';
import '../views/receipt_detail_view.dart';
import '../../../controllers/club_controller.dart';
import '../../communications/controllers/communications_controller.dart';
import '../../../routes/app_routes.dart';

class AccountingController extends GetxController {
  final ApiService _apiService = Get.find();
  final AuthController _authController = Get.find();
  
  final isLoading = false.obs;
  final dashboardKPI = Rxn<DashboardKPI>();
  final studentDues = <StudentDue>[].obs;
  final expenses = <Expense>[].obs;
  
  final selectedPaymentMode = 'cash'.obs;
  final paymentAmount = 0.0.obs;
  final selectedStudent = Rxn<Map<String, dynamic>>();
  final studentRecord = Rxn<Map<String, dynamic>>();
  final students = <Map<String, dynamic>>[].obs;
  final cashDenominations = <String, int>{}.obs;
  final selectedFiles = <PlatformFile>[].obs;

  // For ReportsView
  final selectedReportType = 'fee_pending'.obs;
  final selectedDateRange = 'this_month'.obs;

  double get totalCashAmount {
    double total = 0;
    cashDenominations.forEach((denom, count) {
      total += (double.parse(denom) * count);
    });
    return total;
  }

  void updateCashDenomination(String denomination, int count) {
    if (count > 0) {
      cashDenominations[denomination] = count;
    } else {
      cashDenominations.remove(denomination);
    }
  }

  // Permission checking methods
  bool get canAddExpense => Get.find<AuthController>().hasPermission(Permission.EXPENSE_ADD);
  bool get canViewExpenses => Get.find<AuthController>().hasPermission(Permission.EXPENSE_VIEW);
  bool get canVerifyExpenses => Get.find<AuthController>().hasPermission(Permission.EXPENSE_VERIFY);
  bool get canDeleteExpenses => Get.find<AuthController>().hasPermission(Permission.EXPENSE_DELETE);
  bool get canCollectFees => Get.find<AuthController>().hasPermission(Permission.FEES_COLLECT);

  // Add hasPermission method to AccountingController
  bool hasPermission(String permission) {
    return Get.find<AuthController>().hasPermission(permission);
  }

  @override
  void onInit() {
    super.onInit();
    if (canViewExpenses) {
      loadExpenses();
    }
    loadDashboardData();
    _loadSchoolBasedData();
  }

  void _loadSchoolBasedData() {
    final schoolId = _authController.user.value?.schoolId;
    if (schoolId != null && schoolId.isNotEmpty) {
      // Load school-specific data for clubs and communications
      try {
        if (Get.isRegistered<ClubController>()) {
          final clubController = Get.find<ClubController>();
          clubController.getAllClubs(schoolId: schoolId);
        }
      } catch (e) {
        
      }
      
      try {
        if (Get.isRegistered<CommunicationsController>()) {
          final commController = Get.find<CommunicationsController>();
          commController.loadCommunicationsData();
        }
      } catch (e) {
        
      }
    }
  }

  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;

      final schoolId = _authController.user.value?.schoolId;
      final userRole = _authController.user.value?.role?.toLowerCase();
      
      if (schoolId == null) {
        
        return;
      }
      
      // Build API endpoint based on role
      String endpoint;
      switch (userRole) {
        case 'correspondent':
        case 'accountant':
          endpoint = '${ApiConstants.accountingDashboard}?schoolId=$schoolId&role=financial';
          break;
        case 'principal':
        case 'administrator':
          endpoint = '${ApiConstants.accountingDashboard}?schoolId=$schoolId&role=academic';
          break;
        case 'teacher':
          endpoint = '${ApiConstants.accountingDashboard}?schoolId=$schoolId&role=teacher&userId=${_authController.user.value?.id}';
          break;
        case 'student':
        case 'parent':
          endpoint = '${ApiConstants.accountingDashboard}?schoolId=$schoolId&role=student&userId=${_authController.user.value?.id}';
          break;
        default:
          endpoint = '${ApiConstants.accountingDashboard}?schoolId=$schoolId';
      }
      
      final response = await _apiService.get(endpoint);

      if (response.data != null && response.data['ok'] == true) {
        dashboardKPI.value = DashboardKPI.fromJson(response.data);
        
      }
    } catch (e) {
      
      // Don't show error snackbar for dashboard - it's optional
      
    } finally {
      isLoading.value = false;
      
    }
  }

  Future<void> loadStudentDues(String studentId) async {
    try {
      isLoading.value = true;
      
      final response = await _apiService.get(
        '${ApiConstants.getDues}?student_id=$studentId',
      );
      
      if (response.data != null && response.data is List) {
        studentDues.value = (response.data as List)
            .map((json) => StudentDue.fromJson(json))
            .toList();
      }
      
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to load student dues');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> collectFee({
    required String studentId,
    required String classId,
    required String sectionId,
    required double amount,
    required String paymentMode,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      isLoading.value = true;
      
      // Use schoolId from additionalData if provided, otherwise fallback to auth
      final schoolId = additionalData?['schoolId'] ?? _authController.user.value?.schoolId;

      if (schoolId == null || schoolId.isEmpty) {
        Get.snackbar('Error', 'School ID not found');
        return;
      }

      // Create FormData for multipart request
      final formData = FormData();
      
      // Add basic fields
      formData.fields.addAll([
        MapEntry('schoolId', schoolId),
        MapEntry('studentId', studentId),
        MapEntry('classId', classId),
        MapEntry('sectionId', sectionId),
        MapEntry('amount', amount.toString()),
        MapEntry('paymentMode', paymentMode),
        MapEntry('studentName', additionalData?['studentName'] ?? ''),
        MapEntry('newOld', additionalData?['newOld'] ?? 'old'),
        MapEntry('manualDueAllocation', (additionalData?['manualDueAllocation'] ?? false).toString()),
        MapEntry('paidHeads', '{}'), // Empty JSON object
        MapEntry('referenceNumber', additionalData?['referenceNumber'] ?? ''),
        MapEntry('remarks', additionalData?['remarks'] ?? ''),
        MapEntry('isBusApplicable', (additionalData?['isBusApplicable'] ?? false).toString()),
        MapEntry('busPoint', additionalData?['busPoint'] ?? ''),
      ]);

      // Add payment mode specific fields
      if (paymentMode == 'cash') {
        final cashDenoms = _buildCashDenominationsList();
        formData.fields.add(MapEntry('cashDenominations', jsonEncode(cashDenoms)));
      } else if (paymentMode == 'cheque') {
        formData.fields.addAll([
          MapEntry('chequeNumber', additionalData?['chequeNumber'] ?? ''),
          MapEntry('bankName', additionalData?['bankName'] ?? ''),
          MapEntry('chequeDate', additionalData?['chequeDate'] ?? ''),
        ]);
      } else if (paymentMode == 'upi') {
        formData.fields.add(MapEntry('upiReference', additionalData?['upiReference'] ?? ''));
      }
      
      // Add files if any
      if (selectedFiles.isNotEmpty) {
        for (final file in selectedFiles) {
          formData.files.add(MapEntry(
            'files',
            await MultipartFile.fromFile(
              file.path!,
              filename: file.name,
            ),
          ));
        }
      }

      final response = await _apiService.post(
        ApiConstants.collectFee,
        data: formData,
      );

      if (response.data['ok'] == true) {
        Get.snackbar('Success', response.data['message'] ?? 'Fee collected successfully', backgroundColor: Colors.green, colorText: Colors.white);
        // Clear form and reset state
        selectedStudent.value = null;
        cashDenominations.clear();
        selectedFiles.clear();
        // Refresh the page or navigate back
        Navigator.pop(Get.context!);
      } else {
        
        Get.snackbar('Error', response.data['message'] ?? 'Fee collection failed',backgroundColor: Colors.red,colorText: Colors.white);
      }
    } on DioException catch (dioError) {

      String errorMessage = 'Fee collection failed';
      if (dioError.response?.data != null) {
        final errorData = dioError.response!.data;
        if (errorData is Map && errorData['message'] != null) {
          errorMessage = errorData['message'];
        } else if (errorData is String) {
          errorMessage = errorData;
        }
      }
      
      Get.snackbar('Error', errorMessage,backgroundColor: Colors.red,colorText: Colors.white);
    } catch (e) {
      
      Get.snackbar('Error', 'Fee collection failed: ${e.toString()}',backgroundColor: Colors.red,colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addExpense({
    required String schoolId,
    required String category,
    required double amount,
    required String paymentMode,
    required DateTime date,
    required String academicYear,
    String? remarks,
    required List<PlatformFile> billFiles,
    List<PlatformFile>? workPhotoFiles,
    String? chequeNumber,
    String? bankName,
  }) async {
    try {
      isLoading.value = true;

      if (schoolId.isEmpty) {
        Get.snackbar('Error', 'School ID is required. Please select a school.',
          backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      if (billFiles.isEmpty) {
        Get.snackbar('Error', 'At least one bill/invoice file is required.',
          backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      // Create FormData for multipart/form-data upload
      final formData = FormData.fromMap({
        'schoolId': schoolId,
        'amount': amount,
        'category': category,
        'paymentMode': paymentMode,
        'date': DateFormat('yyyy-MM-dd').format(date),
        'academicYear': academicYear,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
        if (chequeNumber != null && chequeNumber.isNotEmpty) 'chequeNumber': chequeNumber,
        if (bankName != null && bankName.isNotEmpty) 'bankName': bankName,
      });

      // Add bill files as billProof
      for (var file in billFiles) {
        if (file.path != null) {
          formData.files.add(MapEntry(
            'billProof',
            await MultipartFile.fromFile(
              file.path!,
              filename: file.name,
            ),
          ));
        } else if (file.bytes != null) {
          formData.files.add(MapEntry(
            'billProof',
            MultipartFile.fromBytes(
              file.bytes!,
              filename: file.name,
            ),
          ));
        }
      }

      // Add work photo files as workProof (optional)
      if (workPhotoFiles != null && workPhotoFiles.isNotEmpty) {
        for (var file in workPhotoFiles) {
          if (file.path != null) {
            formData.files.add(MapEntry(
              'workProof',
              await MultipartFile.fromFile(
                file.path!,
                filename: file.name,
              ),
            ));
          } else if (file.bytes != null) {
            formData.files.add(MapEntry(
              'workProof',
              MultipartFile.fromBytes(
                file.bytes!,
                filename: file.name,
              ),
            ));
          }
        }
      }

      // Use dio directly for FormData - Dio will automatically set Content-Type with boundary
      final response = await _apiService.dio.post(
        ApiConstants.addExpense,
        data: formData,
      );

      if (response.data['ok'] == true) {
        Get.snackbar('Success', response.data['message'] ?? 'Expense added successfully',
          backgroundColor: Colors.green, colorText: Colors.white);
        loadExpenses(); // Refresh the expenses list
        Navigator.pop(Get.context!); // Return to previous screen
      } else {
        Get.snackbar('Error', response.data['message'] ?? 'Failed to add expense',
          backgroundColor: Colors.red, colorText: Colors.white);
      }
    } on DioException catch (dioError) {
      
      String errorMessage = 'Failed to add expense';
      if (dioError.response?.data != null) {
        final errorData = dioError.response!.data;
        if (errorData is Map && errorData['message'] != null) {
          errorMessage = errorData['message'];
        }
      }
      Get.snackbar('Error', errorMessage,
        backgroundColor: Colors.red, colorText: Colors.white);
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to add expense: ${e.toString()}',
        backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  void showReceiptDetail(Map<String, dynamic> receiptData) {
    
    try {
      if (receiptData == null || receiptData.isEmpty) {
        Get.snackbar('Error', 'Receipt data is missing', backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
      Get.toNamed(AppRoutes.receiptDetail, arguments: receiptData);
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to open receipt details: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void testReceiptDetail() {
    final testData = {
      'feeStructure': {
        'admissionFee': 2000,
        'firstTermAmt': 6000,
        'secondTermAmt': 6000,
        'busFirstTermAmt': 0,
        'busSecondTermAmt': 0
      },
      'feePaid': {
        'admissionFee': 2000,
        'firstTermAmt': 6000,
        'secondTermAmt': 6000,
        'busFirstTermAmt': 0,
        'busSecondTermAmt': 0
      },
      'concession': {
        'isApplied': false,
        'type': null,
        'value': 0,
        'inAmount': 0,
        'proof': null
      },
      'dues': {
        'admissionDues': 0,
        'firstTermDues': 0,
        'secondTermDues': 0,
        'busfirstTermDues': 0,
        'busSecondTermDues': 0
      },
      'studentId': {
        'studentName': 'stu12',
        'srId': 'SR-009'
      },
      'academicYear': '2024-2025',
      'className': 'Class 8',
      'sectionName': 'Section B',
      'newOld': 'New',
      'rollNumber': null,
      'isActive': true,
      'isBusApplicable': false,
      'isFullyPaid': true,
      'busPoint': null
    };
    showReceiptDetail(testData);
  }

  Future<Map<String, dynamic>?> getStudentRecord(String schoolId, String studentId) async {
    try {
      isLoading.value = true;

      final response = await _apiService.get(
        '/api/studentrecord/getrecord/$schoolId/$studentId',
      );

      if (response.data != null && response.data['ok'] == true) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to load student record');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadExpenses({String? schoolId}) async {
    try {
      isLoading.value = true;
      final targetSchoolId = schoolId ?? _authController.user.value?.schoolId;
      if (targetSchoolId == null) {
        
        Get.snackbar('Error', 'School ID not found');
        return;
      }

      final response = await _apiService.get(
        '${ApiConstants.getAllExpenses}?schoolId=$targetSchoolId',
      );

      if (response.data != null && response.data['ok'] == true) {
        final expensesList = response.data['data'] as List;

        expenses.value = expensesList
            .map((json) {
              try {
                return Expense.fromJson(json);
              } catch (e) {

                return null;
              }
            })
            .where((expense) => expense != null)
            .cast<Expense>()
            .toList();

      } else {
        
        Get.snackbar('Error', response.data?['message'] ?? 'Failed to load expenses');
      }
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to load expenses: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Expense?> getExpenseById(String expenseId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.get(
        '${ApiConstants.getSingleExpenseById}/$expenseId',
      );

      if (response.data['ok'] == true) {
        return Expense.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load expense details');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateExpense({
    required String expenseId,
    required String category,
    required double amount,
    required String paymentMode,
  }) async {
    try {
      isLoading.value = true;
      // Store current school ID before update
      final currentSchoolId = expenses.isNotEmpty ? expenses.first.schoolId : null;
      
      final response = await _apiService.put(
        '${ApiConstants.updateExpense}/$expenseId',
        data: {
          'category': category,
          'amount': amount,
          'paymentMode': paymentMode,
        },
      );

      if (response.data['ok'] == true) {
        Get.snackbar('Success', response.data['message'] ?? 'Expense updated successfully');
        // Refresh with the same school filter
        if (currentSchoolId != null) {
          loadExpenses(schoolId: currentSchoolId);
        } else {
          loadExpenses();
        }
      } else {
        Get.snackbar('Error', response.data['message'] ?? 'Failed to update expense');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update expense');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateExpenseStatus(String expenseId, String status) async {
    try {
      isLoading.value = true;

      final response = await _apiService.put(
        '${ApiConstants.updateExpenseStatus}/$expenseId',
        data: {'verificationStatus': status},
      );

      if (response.data['ok'] == true) {
        Get.snackbar('Success', response.data['message'] ?? 'Expense status updated successfully');
        // Refresh with current school filter
        final currentSchoolId = expenses.isNotEmpty ? expenses.first.schoolId : null;
        if (currentSchoolId != null) {
          loadExpenses(schoolId: currentSchoolId);
        } else {
          loadExpenses();
        }
      } else {
        Get.snackbar('Error', response.data['message'] ?? 'Failed to update status');
        
      }
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to update expense status: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      isLoading.value = true;
      // Store current school ID before deletion
      final currentSchoolId = expenses.isNotEmpty ? expenses.first.schoolId : null;
      
      final response = await _apiService.delete(
        '${ApiConstants.deleteExpense}/$expenseId',
      );

      if (response.data['ok'] == true) {
        Get.snackbar('Success', response.data['message'] ?? 'Expense deleted successfully');
        // Refresh with the same school filter
        if (currentSchoolId != null) {
          loadExpenses(schoolId: currentSchoolId);
        } else {
          loadExpenses();
        }
      } else {
        Get.snackbar('Error', response.data['message'] ?? 'Failed to delete expense');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete expense');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteExpenseProof(String expenseId, String fileId) async {
    try {
      isLoading.value = true;
      final response = await _apiService.delete(
        '${ApiConstants.deleteExpenseProof}/$expenseId/$fileId',
      );

      if (response.data['ok'] == true) {
        Get.snackbar('Success', response.data['message'] ?? 'Proof deleted successfully');
        loadExpenses(); // Refresh list
      } else {
        Get.snackbar('Error', response.data['message'] ?? 'Failed to delete proof');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete proof');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> applyConcession({
    required String studentId,
    required String classId,
    required String sectionId,
    required String concessionType,
    required double concessionValue,
    required String remark,
    String? proofFileUrl,
  }) async {
    try {
      isLoading.value = true;
      
      final schoolId = _authController.user.value?.schoolId;
      if (schoolId == null) {
        Get.snackbar('Error', 'School ID not found');
        return false;
      }

      final requestData = {
        'schoolId': schoolId,
        'studentId': studentId,
        'classId': classId,
        'sectionId': sectionId,
        'concessionType': concessionType,
        'concessionValue': concessionValue,
        'remark': remark,
        'newOld': 'New',
        'busPoint': '',
        'isBusApplicable': false,
        if (proofFileUrl != null) 'file': proofFileUrl,
      };

      final response = await _apiService.post(
        ApiConstants.applyConcession,
        data: requestData,
      );

      if (response.data['ok'] == true) {
        Get.snackbar(
          'Success', 
          response.data['message'] ?? 'Concession applied successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        return true;
      } else {
        Get.snackbar(
          'Error', 
          response.data['message'] ?? 'Failed to apply concession',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        return false;
      }
    } catch (e) {
      
      Get.snackbar(
        'Error', 
        'Failed to apply concession: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadStudentsForSchool(String schoolId) async {
    try {

      final response = await _apiService.get(
        '${ApiConstants.getAllStudents}?schoolId=$schoolId',
      );

      if (response.data['ok'] == true) {
        final studentList = response.data['data'] as List;
        students.value = studentList.cast<Map<String, dynamic>>();
        
        if (students.isEmpty) {
          Get.snackbar('Info', 'No students found in this school');
          return;
        }
        
        // Show student selection dialog
        Get.dialog(
          AlertDialog(
            title: const Text('Select Student'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return ListTile(
                    title: Text(student['studentName'] ?? 'Unknown'),
                    subtitle: Text('Roll: ${student['rollNumber'] ?? 'N/A'}'),
                    onTap: () {
                      selectedStudent.value = {
                        'studentId': student['_id'],
                        'studentName': student['studentName'],
                        'classId': student['currentClassId'],
                        'sectionId': student['currentSectionId'],
                      };
                      Navigator.pop(Get.context!);
                      // Load dues for selected student
                      loadStudentDues(student['_id']);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      } else {
        Get.snackbar('Error', 'Failed to load students');
      }
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to load students: ${e.toString()}');
    }
  }

  String get userRole => _authController.user.value?.role ?? '';
  bool get isCorrespondent => userRole == 'correspondent';
  bool get isAccountant => userRole == 'accountant';

  // Future<Map<String, dynamic>?> getStudentRecord(String schoolId, String studentId) async {
  //   try {
  //     isLoading.value = true;
  //     
  //
  //     final response = await _apiService.get(
  //       '${ApiConstants.getStudentRecord}/$schoolId/$studentId',
  //     );
  //
  //     
  //
  //     if (response.data['ok'] == true) {
  //       return response.data['data'];
  //     } else {
  //       Get.snackbar('Error', response.data['message'] ?? 'Failed to load student record');
  //       return null;
  //     }
  //   } catch (e) {
  //     
  //     Get.snackbar('Error', 'Failed to load student record');
  //     return null;
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  List<Map<String, dynamic>> _buildCashDenominationsList() {
    return cashDenominations.entries.map((entry) => {
      'label': entry.key,
      'count': entry.value,
    }).toList();
  }

  Future<void> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
        allowedExtensions: null,
      );
      
      if (result != null) {
        selectedFiles.addAll(result.files);
        Get.snackbar('Success', '${result.files.length} file(s) selected');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick files: ${e.toString()}');
    }
  }

  void removeFile(int index) {
    if (index >= 0 && index < selectedFiles.length) {
      selectedFiles.removeAt(index);
    }
  }

  // Test other student record APIs
  Future<void> testStudentRecordAPIs(String schoolId, String studentId) async {
    try {

      // Test get all student records
      final allRecords = await _apiService.get('/api/studentrecord/getall?schoolId=$schoolId');

      // Test get student record with receipts
      final recordWithReceipts = await _apiService.get('/api/studentrecord/getrecord/$schoolId/$studentId');

      // Test get dues
      final dues = await _apiService.get('/api/studentrecord/getdues?schoolId=$schoolId&studentId=$studentId');

    } catch (e) {
      
    }
  }
}

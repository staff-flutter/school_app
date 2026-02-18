import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/app/modules/accounting/views/fee_structure_view.dart';
import 'package:school_app/app/routes/app_routes.dart';
import 'dart:io';
import '../../../controllers/student_record_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/accounting_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/api_rbac_wrapper.dart';
import '../../../core/rbac/api_rbac.dart';
import '../../../widgets/student_record_integration.dart';
import '../../../controllers/school_controller.dart';
import '../../../controllers/fee_structure_controller.dart';
import '../../../data/models/school_models.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/services/api_service.dart';

class FeeCollectionTabbedView extends StatelessWidget {
  FeeCollectionTabbedView({super.key});
  
  final AuthController _authController = Get.find();

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(
          child: Column(
            children: [
              // Modern Header
              _buildModernHeader(context, isTablet),
              
              // Modern Tab Bar
              _buildModernTabBar(context),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  children: [
                    _FeeCollectionTab(),
                    _FeeStructureViewTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryBlue, Colors.indigo.shade600],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fee Management',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Collect fees and manage records',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: isTablet ? 16 : 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTabBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: AppTheme.primaryBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'Collect Fee', icon: Icon(Icons.payment, size: 20)),
          Tab(text: 'Fee Structure', icon: Icon(Icons.receipt_long, size: 20)),
        ],
      ),
    );
  }
}

class _FeeCollectionTab extends StatelessWidget {
  final controller = Get.put(AccountingController());
  final schoolController = Get.put(SchoolController());
  final _amountController = TextEditingController();
  final _chequeNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _chequeDateController = TextEditingController();
  final _upiReferenceController = TextEditingController();
  final _remarksController = TextEditingController();
  final _referenceNumberController = TextEditingController();
  final _busPointController = TextEditingController();
  final isBusApplicable = false.obs;
  final manualDueAllocation = false.obs;
  final _formKey = GlobalKey<FormState>();
  final AuthController _authController = Get.find();
  final _studentSearchController = TextEditingController();
  final selectedSchool = Rxn<School>();
  final filteredStudents = <Map<String, dynamic>>[].obs;
  final showPaymentDetails = false.obs;
  final showReceipts = false.obs;
  final isStudentSelectorCollapsed = false.obs;
  final selectedStudentType = 'old'.obs; // 'old' or 'new'

  _FeeCollectionTab() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      schoolController.getAllSchools();
      // Note: Students will be loaded when school is selected
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.indigo.shade50],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // School Selection
                _buildSchoolSelector(context, isTablet),
                
                const SizedBox(height: 16),
                
                // Collapsible Student Selection
                _buildCollapsibleStudentSelector(context, isTablet, isLandscape),
                
                const SizedBox(height: 16),
                
                // Student Receipts
                Obx(() => showReceipts.value && controller.selectedStudent.value != null
                    ? _buildStudentReceipts(context, isTablet)
                    : const SizedBox()),
                
                const SizedBox(height: 16),
                
                // Payment Details
                Obx(() => showPaymentDetails.value
                    ? _buildPaymentDetails(context, isTablet, isLandscape)
                    : const SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentTypeSelectorInPayment(BuildContext context, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Student Type',
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Obx(() => DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: 'Select student type',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.category, color: AppTheme.primaryBlue, size: 20),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            dropdownColor: Colors.white,
            menuMaxHeight: 200,
            borderRadius: BorderRadius.circular(12),
            icon: Container(
              margin: const EdgeInsets.only(right: 12),
              child: Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryBlue),
            ),
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            value: selectedStudentType.value,
            items: const [
              DropdownMenuItem<String>(
                value: 'old',
                child: Row(
                  children: [
                    Icon(Icons.school, color: Colors.blue, size: 20),
                    SizedBox(width: 12),
                    Text('Old Student', style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              DropdownMenuItem<String>(
                value: 'new',
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.green, size: 20),
                    SizedBox(width: 12),
                    Text('New Student', style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                selectedStudentType.value = value;
              }
            },
          )),
        ),
      ],
    );
  }

  Widget _buildSchoolSelector(BuildContext context, bool isTablet) {
    final userRole = _authController.user.value?.role?.toLowerCase() ?? '';
    final isCorrespondent = userRole == 'correspondent';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.school, color: AppTheme.primaryBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Select School',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (isCorrespondent) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.blue.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: DropdownButtonFormField<School>(
                    decoration: InputDecoration(
                      hintText: 'Choose School',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.school, color: AppTheme.primaryBlue, size: 20),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    dropdownColor: Colors.white,
                    menuMaxHeight: 300,
                    borderRadius: BorderRadius.circular(12),
                    icon: Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryBlue),
                    ),
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    value: selectedSchool.value,
                    selectedItemBuilder: (context) {
                      return schoolController.schools.map((school) {
                        return Text(
                          school.name,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      }).toList();
                    },
                    items: schoolController.schools.map((school) {
                      return DropdownMenuItem<School>(
                        value: school,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(Icons.school, color: AppTheme.primaryBlue, size: 16),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  school.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (school) {
                      selectedSchool.value = school;
                      controller.selectedStudent.value = null;
                      showPaymentDetails.value = false;
                      showReceipts.value = false;
                      isStudentSelectorCollapsed.value = false;
                      if (school != null) {
                        _loadStudentsForSchool(school.id);
                      }
                    },
                  ),
                );
              } else {
                // Readonly for non-correspondent
                final userSchoolId = _authController.user.value?.schoolId;
                final userSchool = schoolController.schools.firstWhereOrNull(
                  (school) => school.id == userSchoolId,
                );
                
                // Auto-select user's school
                if (userSchool != null && selectedSchool.value == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    selectedSchool.value = userSchool;
                    _loadStudentsForSchool(userSchool.id);
                  });
                }

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.school, color: AppTheme.primaryBlue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          userSchool?.name ?? 'Loading...',
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleStudentSelector(BuildContext context, bool isTablet, bool isLandscape) {
    return Obx(() {
      final hasStudent = controller.selectedStudent.value != null;
      
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: isStudentSelectorCollapsed.value && hasStudent ? 60 : null,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isStudentSelectorCollapsed.value && hasStudent
            ? _buildCompactStudentSelector(context, isTablet)
            : _buildFullStudentSelector(context, isTablet, isLandscape),
      );
    });
  }

  Widget _buildCompactStudentSelector(BuildContext context, bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.person, color: AppTheme.primaryBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.selectedStudent.value?['studentName'] ?? 'Unknown Student',
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => isStudentSelectorCollapsed.value = false,
            icon: const Icon(Icons.edit, size: 18),
            tooltip: 'Change Student',
          ),
        ],
      ),
    );
  }

  Widget _buildFullStudentSelector(BuildContext context, bool isTablet, bool isLandscape) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person, color: AppTheme.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Select Student',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _studentSearchController,
            decoration: InputDecoration(
              hintText: 'Search student by name or roll number',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: _filterStudents,
          ),
          const SizedBox(height: 16),
          Obx(() => controller.isLoading.value
              ? Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading students...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              : Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: filteredStudents.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('No students found', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = filteredStudents[index];
                            final isSelected = controller.selectedStudent.value?['studentId'] == student['_id'];
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade200,
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
                                  child: Text(
                                    (student['studentName'] ?? 'U').substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  student['studentName'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text('Roll: ${student['rollNumber'] ?? 'N/A'}'),
                                onTap: () => _selectStudent(student),
                              ),
                            );
                          },
                        ),
                )),
          const SizedBox(height: 16),
          // Action Buttons
          Obx(() => controller.selectedStudent.value != null
              ? isLandscape && isTablet
                  ? Row(
                      children: [
                        Expanded(child: _buildViewReceiptsButton()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildCollectFeeButton()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildViewReceiptsButton(),
                        const SizedBox(height: 12),
                        _buildCollectFeeButton(),
                      ],
                    )
              : const SizedBox()),
        ],
      ),
    );
  }

  Widget _buildViewReceiptsButton() {
    return ApiRbacWrapper(
      apiEndpoint: 'GET /api/studentrecord/getrecord',
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showReceipts,
          icon: const Icon(Icons.receipt, size: 18),
          label: const Text('View Receipts'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollectFeeButton() {
    return ApiRbacWrapper(
      apiEndpoint: 'POST /api/studentrecord/collectfee',
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            showPaymentDetails.value = true;
            showReceipts.value = false;
            isStudentSelectorCollapsed.value = true;
          },
          icon: const Icon(Icons.payment, size: 18),
          label: const Text('Collect Fee'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentReceipts(BuildContext context, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Student Fee Record & Receipts',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              final record = controller.studentRecord.value;
              if (record == null) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final receipts = record['receipts'] as List? ?? [];
              if (receipts.isEmpty) {
                return _buildEmptyReceipts();
              }

              return Column(
                children: receipts.map<Widget>((receipt) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt, color: Colors.green, size: 20),
                      ),
                      title: Text(
                        'Receipt #${receipt['receiptNo'] ?? 'N/A'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Date: ${receipt['paymentDate'] ?? 'N/A'} • Mode: ${receipt['paymentMode'] ?? 'N/A'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${receipt['amountPaid']?.toStringAsFixed(0) ?? '0'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      onTap: () => controller.showReceiptDetail(record),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyReceipts() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const Column(
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No receipts found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'No payment receipts found for this student',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalFields(BuildContext context, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reference Number (for all payment modes)
        TextFormField(
          controller: _referenceNumberController,
          decoration: InputDecoration(
            labelText: 'Reference Number (Optional)',
            prefixIcon: const Icon(Icons.tag),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        const SizedBox(height: 16),

        // Remarks
        TextFormField(
          controller: _remarksController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Remarks (Optional)',
            prefixIcon: const Icon(Icons.notes),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        const SizedBox(height: 16),

        // Bus Applicable Toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    fit: FlexFit.loose,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions_bus, color: AppTheme.primaryBlue),
                        const SizedBox(width: 12),
                        Text(
                          'Bus Fee Applicable',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Obx(() => Switch(
                    value: isBusApplicable.value,
                    onChanged: (value) => isBusApplicable.value = value,
                    activeColor: AppTheme.primaryBlue,
                  )),
                ],
              ),
              const SizedBox(height: 12),
              Obx(() => isBusApplicable.value
                  ? TextFormField(
                      controller: _busPointController,
                      decoration: InputDecoration(
                        labelText: 'Bus Stop/Point',
                        hintText: 'Enter bus stop name',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      validator: (value) {
                        if (isBusApplicable.value && (value == null || value.isEmpty)) {
                          return 'Please enter bus stop name';
                        }
                        return null;
                      },
                    )
                  : const SizedBox()),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Manual Due Allocation Toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calculate, color: AppTheme.primaryBlue),
                  const SizedBox(width: 12),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Text(
                      'Manual Due Allocation',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              Obx(() => Switch(
                value: manualDueAllocation.value,
                onChanged: (value) => manualDueAllocation.value = value,
                activeColor: AppTheme.primaryBlue,
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadSection(BuildContext context, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Payment Proof (Optional)',
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // Upload Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.pickFiles,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Select Images'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                    foregroundColor: AppTheme.primaryBlue,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Selected Files List
              Obx(() => controller.selectedFiles.isEmpty
                  ? Text(
                      'No files selected',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: controller.selectedFiles.asMap().entries.map((entry) {
                        final index = entry.key;
                        final file = entry.value;
                        return GestureDetector(
                          onTap: () => _showFullImage(file.path!),
                          child: Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(file.path!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => 
                                        Icon(Icons.image, color: Colors.grey),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => controller.removeFile(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetails(BuildContext context, bool isTablet, bool isLandscape) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.payment, color: AppTheme.primaryBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Payment Details',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Amount Field
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.green.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: TextStyle(color: Colors.green.shade700),
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.currency_rupee, color: Colors.green),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter valid amount';
                  }
                  return null;
                },
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Payment Mode Selection
            Text(
              'Payment Mode',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['cash', 'upi', 'cheque', 'bank'].map((mode) {
                final isSelected = controller.selectedPaymentMode.value == mode;
                return Container(
                  decoration: BoxDecoration(
                    gradient: isSelected 
                        ? LinearGradient(
                            colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.8)],
                          )
                        : LinearGradient(
                            colors: [Colors.grey.shade100, Colors.grey.shade50],
                          ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
                    ),
                  ),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPaymentModeIcon(mode),
                          size: 16,
                          color: isSelected ? Colors.green : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          mode.toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.green : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    backgroundColor: Colors.transparent,
                    selectedColor: Colors.transparent,
                    checkmarkColor: Colors.transparent,
                    onSelected: (selected) {
                      if (selected) controller.selectedPaymentMode.value = mode;
                    },
                  ),
                );
              }).toList(),
            )),
            
            const SizedBox(height: 20),
            
            // Conditional Fields based on Payment Mode
            Obx(() => _buildPaymentModeFields(context, isTablet            )),

            const SizedBox(height: 20),

            // Student Type Selection (Old/New)
            _buildStudentTypeSelectorInPayment(context, isTablet),

            const SizedBox(height: 20),

            // Additional Fields
            _buildAdditionalFields(context, isTablet),

            const SizedBox(height: 20),

            // File Upload Section
            _buildFileUploadSection(context, isTablet),
            
            const SizedBox(height: 24),
            
            // Final Collect Button
            ApiRbacWrapper(
              apiEndpoint: 'POST /api/studentrecord/collectfee',
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryBlue, Colors.indigo.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Obx(() => ElevatedButton.icon(
                  onPressed: controller.isLoading.value ? null : _collectFee,
                  icon: controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.payment, color: Colors.white),
                  label: Text(
                    controller.isLoading.value ? 'Processing...' : 'Process Payment',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPaymentModeIcon(String mode) {
    switch (mode) {
      case 'cash':
        return Icons.money;
      case 'upi':
        return Icons.qr_code;
      case 'cheque':
        return Icons.receipt;
      case 'bank':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  Widget _buildPaymentModeFields(BuildContext context, bool isTablet) {
    final paymentMode = controller.selectedPaymentMode.value;
    
    switch (paymentMode) {
      case 'cash':
        return _buildCashDenominationFields(context, isTablet);
      case 'cheque':
        return _buildChequeFields(context, isTablet);
      case 'upi':
        return _buildUPIFields(context, isTablet);
      default:
        return const SizedBox();
    }
  }

  Widget _buildCashDenominationFields(BuildContext context, bool isTablet) {
    final denominations = [2000, 500, 200, 100, 50, 20, 10, 5, 2, 1];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cash Denomination Tally',
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter denomination count to verify cash amount',
          style: TextStyle(
            fontSize: isTablet ? 14 : 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: denominations.map((denom) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Container(
                  constraints: BoxConstraints(maxWidth: isTablet ? 400 : 350),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text('₹$denom:', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                      const SizedBox(width: 8),
                      Flexible(
                      flex: 2,
                        fit: FlexFit.loose,
                        child: SizedBox(
                          width: isTablet ? 120 : 100,
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) {
                          final count = int.tryParse(value) ?? 0;
                          controller.updateCashDenomination(denom.toString(), count);
                        },
                          ),
                      ),
                    ),
                    const SizedBox(width: 8),
                      Flexible(
                      flex: 1,
                        fit: FlexFit.loose,
                        child: SizedBox(
                          width: isTablet ? 80 : 70,
                      child: Obx(() {
                        final count = controller.cashDenominations[denom.toString()] ?? 0;
                        final total = denom * count;
                        return Text(
                          '₹$total',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        );
                      }),
                        ),
                    ),
                  ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final totalCash = controller.totalCashAmount;
          final enteredAmount = double.tryParse(_amountController.text) ?? 0;
          final isMatching = totalCash == enteredAmount;
          
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isMatching ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isMatching ? Colors.green : Colors.red,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Cash: ₹$totalCash',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isMatching ? Colors.green : Colors.red,
                  ),
                ),
                Icon(
                  isMatching ? Icons.check_circle : Icons.error,
                  color: isMatching ? Colors.green : Colors.red,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildChequeFields(BuildContext context, bool isTablet) {
    return Column(
      children: [
        TextFormField(
          controller: _chequeNumberController,
          decoration: InputDecoration(
            labelText: 'Cheque Number',
            prefixIcon: const Icon(Icons.receipt),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter cheque number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bankNameController,
          decoration: InputDecoration(
            labelText: 'Bank Name',
            prefixIcon: const Icon(Icons.account_balance),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter bank name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _chequeDateController,
          decoration: InputDecoration(
            labelText: 'Cheque Date',
            hintText: '2025-12-25',
            prefixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter cheque date';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildUPIFields(BuildContext context, bool isTablet) {
    return TextFormField(
      controller: _upiReferenceController,
      decoration: InputDecoration(
        labelText: 'UPI Reference (Optional)',
        prefixIcon: const Icon(Icons.qr_code),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  void _showFullImage(String imagePath) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // All the existing methods remain the same
  void _loadStudentsForSchool(String schoolId) async {
    try {
      controller.isLoading.value = true;
      final response = await Get.find<ApiService>().get(
        '${ApiConstants.getAllStudents}?schoolId=$schoolId',
      );
      
      if (response.data['ok'] == true) {
        final studentList = response.data['data'] as List;
        controller.students.value = studentList.cast<Map<String, dynamic>>();
        filteredStudents.value = controller.students;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load students');
    } finally {
      controller.isLoading.value = false;
    }
  }

  void _filterStudents(String query) {
    if (query.isEmpty) {
      filteredStudents.value = controller.students;
      return;
    }
    
    filteredStudents.value = controller.students.where((student) {
      final name = (student['studentName'] ?? '').toLowerCase();
      final roll = (student['rollNumber'] ?? '').toLowerCase();
      final searchQuery = query.toLowerCase();
      return name.contains(searchQuery) || roll.contains(searchQuery);
    }).toList();
  }

  void _selectStudent(Map<String, dynamic> student) {
    String classId = '';
    String sectionId = '';
    
    if (selectedSchool.value != null) {
      final schoolController = Get.find<SchoolController>();
      
      if (schoolController.classes.isEmpty) {
        schoolController.getAllClasses(selectedSchool.value!.id).then((_) {
          if (schoolController.classes.isNotEmpty) {
            classId = schoolController.classes.first.id;
            schoolController.getAllSections(schoolId: selectedSchool.value!.id).then((_) {
              if (schoolController.sections.isNotEmpty) {
                sectionId = schoolController.sections.first.id;
              }
              _updateSelectedStudent(student, classId, sectionId);
            });
          }
        });
        return;
      } else {
        classId = schoolController.classes.first.id;
        if (schoolController.sections.isEmpty) {
          schoolController.getAllSections(schoolId: selectedSchool.value!.id).then((_) {
            if (schoolController.sections.isNotEmpty) {
              sectionId = schoolController.sections.first.id;
            }
            _updateSelectedStudent(student, classId, sectionId);
          });
          return;
        } else {
          sectionId = schoolController.sections.first.id;
        }
      }
    }
    
    _updateSelectedStudent(student, classId, sectionId);
  }
  
  void _updateSelectedStudent(Map<String, dynamic> student, String classId, String sectionId) {
    controller.selectedStudent.value = {
      'studentId': student['_id'],
      'studentName': student['studentName'],
      'classId': classId,
      'sectionId': sectionId,
    };
  }

  void _showReceipts() async {
    final student = controller.selectedStudent.value;
    if (student == null) {
      Get.snackbar('Error', 'No student selected');
      return;
    }
    
    final studentId = student['studentId'];
    final schoolId = selectedSchool.value?.id;
    
    if (studentId == null || schoolId == null) {
      Get.snackbar('Error', 'Student or School ID not found');
      return;
    }
    
    showReceipts.value = true;
    showPaymentDetails.value = false;
    isStudentSelectorCollapsed.value = true;
    
    final record = await controller.getStudentRecord(schoolId, studentId);
    if (record != null) {
      controller.studentRecord.value = record;
    }
  }

  void _collectFee() {
    if (_formKey.currentState!.validate()) {
      final student = controller.selectedStudent.value!;
      final amount = double.parse(_amountController.text);
      
      final studentId = student['studentId']?.toString() ?? '';
      final classId = student['classId']?.toString() ?? '';
      final sectionId = student['sectionId']?.toString() ?? '';
      final schoolId = selectedSchool.value?.id ?? '';
      
      if (studentId.isEmpty || schoolId.isEmpty || classId.isEmpty || sectionId.isEmpty) {
        Get.snackbar('Error', 'Missing required information');
        return;
      }
      
      final additionalData = {
        'schoolId': schoolId,
        'studentId': studentId,
        'classId': classId,
        'sectionId': sectionId,
        'amount': amount,
        'paymentMode': controller.selectedPaymentMode.value,
        'studentName': student['studentName'] ?? '',
        'newOld': selectedStudentType.value, // 'old' or 'new'
        'manualDueAllocation': manualDueAllocation.value,
        'paidHeads': {}, // Empty object as default, can be populated if needed
        'remarks': _remarksController.text,
        'isBusApplicable': isBusApplicable.value,
        'busPoint': _busPointController.text,
        if (_referenceNumberController.text.isNotEmpty)
          'referenceNumber': _referenceNumberController.text,
        if (controller.selectedPaymentMode.value == 'cheque') ...{
          'chequeNumber': _chequeNumberController.text,
          'bankName': _bankNameController.text,
          'chequeDate': _chequeDateController.text,
        },
        if (controller.selectedPaymentMode.value == 'upi')
          'upiReference': _upiReferenceController.text,
      };
      
      controller.collectFee(
        studentId: studentId,
        classId: classId,
        sectionId: sectionId,
        amount: amount,
        paymentMode: controller.selectedPaymentMode.value,
        additionalData: additionalData,
      ).then((_) {
        // Clear form fields after successful submission
        _amountController.clear();
        _remarksController.clear();
        _referenceNumberController.clear();
        _chequeNumberController.clear();
        _bankNameController.clear();
        _chequeDateController.clear();
        _upiReferenceController.clear();
        _busPointController.clear();
        showPaymentDetails.value = false;
        isStudentSelectorCollapsed.value = false;
      });
    }
  }
}

class _FeeStructureViewTab extends StatefulWidget {
  @override
  State<_FeeStructureViewTab> createState() => _FeeStructureViewTabState();
}

class _FeeStructureViewTabState extends State<_FeeStructureViewTab> {
  final schoolController = Get.find<SchoolController>();
  final feeController = Get.put(FeeStructureController());

  final selectedSchool = Rxn<School>();
  final selectedClass = Rxn<SchoolClass>();
  final isSelectorsExpanded = ValueNotifier<bool>(true);
  final isOldStructureExpanded = ValueNotifier<bool>(true);
  final isNewStructureExpanded = ValueNotifier<bool>(true);

  final oldFeeStructure = Rxn<Map<String, dynamic>>();
  final newFeeStructure = Rxn<Map<String, dynamic>>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      schoolController.getAllSchools();
    });
  }

  Future<void> _loadFeeStructures() async {
    if (selectedSchool.value == null || selectedClass.value == null) return;

    final schoolId = selectedSchool.value!.id;
    final classId = selectedClass.value!.id;

    // Show loading state
    feeController.isLoading.value = true;

    try {
      // Load old fee structure
      final oldStructure = await feeController.getFeeStructureByClass(schoolId, classId, type: 'old');
      oldFeeStructure.value = oldStructure;

      // Load new fee structure
      final newStructure = await feeController.getFeeStructureByClass(schoolId, classId, type: 'new');
      newFeeStructure.value = newStructure;
    } finally {
      feeController.isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.indigo.shade50],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Collapsible School and Class Selectors
              ValueListenableBuilder<bool>(
                valueListenable: isSelectorsExpanded,
                builder: (context, isExpanded, child) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: isExpanded ? null : 60,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isExpanded
                          ? _buildExpandedSelectors(isTablet, isLandscape)
                          : _buildCompactSelectors(isTablet),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Old Fee Structure
              _buildFeeStructureContainer(
                title: 'Old Students Fee Structure',
                icon: Icons.school,
                color: Colors.blue,
                feeStructure: oldFeeStructure,
                isExpanded: isOldStructureExpanded,
                isTablet: isTablet,
              ),

              const SizedBox(height: 16),

              // New Fee Structure
              _buildFeeStructureContainer(
                title: 'New Students Fee Structure',
                icon: Icons.person_add,
                color: Colors.green,
                feeStructure: newFeeStructure,
                isExpanded: isNewStructureExpanded,
                isTablet: isTablet,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSelectors(bool isTablet) {
    return InkWell(
      onTap: () => isSelectorsExpanded.value = true,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.school, color: AppTheme.primaryBlue, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedSchool.value != null && selectedClass.value != null
                    ? '${selectedSchool.value!.name} - ${selectedClass.value!.name}'
                    : 'Select School & Class',
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: () => isSelectorsExpanded.value = true,
              icon: const Icon(Icons.edit, size: 18),
              tooltip: 'Change Selection',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedSelectors(bool isTablet, bool isLandscape) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.filter_list, color: AppTheme.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Select School & Class',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => isSelectorsExpanded.value = false,
                icon: const Icon(Icons.expand_less, size: 20),
                tooltip: 'Collapse',
              ),
            ],
          ),
          const SizedBox(height: 16),
          isLandscape && isTablet
              ? Row(
                  children: [
                    Expanded(child: _buildSchoolDropdown()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildClassDropdown()),
                  ],
                )
              : Column(
                  children: [
                    _buildSchoolDropdown(),
                    const SizedBox(height: 12),
                    _buildClassDropdown(),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildSchoolDropdown() {
    final authController = Get.find<AuthController>();
    final userRole = authController.user.value?.role?.toLowerCase() ?? '';
    final isCorrespondent = userRole == 'correspondent';

    return Obx(() {
      if (isCorrespondent) {
        return DropdownButtonFormField<School>(
          decoration: InputDecoration(
            labelText: 'Select School',
            prefixIcon: Icon(Icons.school, color: AppTheme.primaryBlue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          value: selectedSchool.value,
          items: schoolController.schools.map((school) {
            return DropdownMenuItem<School>(
              value: school,
              child: Text(school.name),
            );
          }).toList(),
          onChanged: (school) {
            selectedSchool.value = school;
            selectedClass.value = null;
            oldFeeStructure.value = null;
            newFeeStructure.value = null;
            if (school != null) {
              schoolController.getAllClasses(school.id);
            }
          },
        );
      } else {
        // Readonly for non-correspondent
        final userSchoolId = authController.user.value?.schoolId;
        final userSchool = schoolController.schools.firstWhereOrNull(
          (school) => school.id == userSchoolId,
        );
        
        // Auto-select user's school
        if (userSchool != null && selectedSchool.value == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            selectedSchool.value = userSchool;
            schoolController.getAllClasses(userSchool.id);
          });
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.school, color: AppTheme.primaryBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  userSchool?.name ?? 'Loading...',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    });
  }

  Widget _buildClassDropdown() {
    return Obx(() => DropdownButtonFormField<SchoolClass>(
      decoration: InputDecoration(
        labelText: 'Select Class',
        prefixIcon: Icon(Icons.class_, color: AppTheme.primaryBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      value: selectedClass.value,
      selectedItemBuilder: (context) {
        return schoolController.classes.map((cls) {
          return Text(cls.name);
        }).toList();
      },
      items: schoolController.classes.map((cls) {
        return DropdownMenuItem<SchoolClass>(
          value: cls,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.class_, color: AppTheme.primaryBlue, size: 16),
              ),
              const SizedBox(width: 12),
              Text(cls.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (cls) {
        selectedClass.value = cls;
        if (cls != null && selectedSchool.value != null) {
          _loadFeeStructures();
        }
      },
    ));
  }

  Widget _buildFeeStructureContainer({
    required String title,
    required IconData icon,
    required Color color,
    required Rxn<Map<String, dynamic>> feeStructure,
    required ValueNotifier<bool> isExpanded,
    required bool isTablet,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: isExpanded,
      builder: (context, expanded, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: expanded ? null : 60,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: expanded
                ? _buildExpandedFeeStructure(title, icon, color, feeStructure, isExpanded, isTablet)
                : _buildCompactFeeStructure(title, icon, color, feeStructure, isExpanded, isTablet),
          ),
        );
      },
    );
  }

  Widget _buildCompactFeeStructure(
    String title,
    IconData icon,
    Color color,
    Rxn<Map<String, dynamic>> feeStructure,
    ValueNotifier<bool> isExpanded,
    bool isTablet,
  ) {
    return InkWell(
      onTap: () => isExpanded.value = true,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                feeStructure.value != null ? '$title (Loaded)' : title,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: () => isExpanded.value = true,
              icon: const Icon(Icons.expand_more, size: 18),
              tooltip: 'View Details',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedFeeStructure(
    String title,
    IconData icon,
    Color color,
    Rxn<Map<String, dynamic>> feeStructure,
    ValueNotifier<bool> isExpanded,
    bool isTablet,
  ) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => isExpanded.value = false,
                icon: const Icon(Icons.expand_less, size: 20),
                tooltip: 'Collapse',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (feeController.isLoading.value) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading fee structure...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (feeStructure.value == null) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No fee structure found',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select school and class to load fee structure',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final feeHead = feeStructure.value!['feeHead'] as Map<String, dynamic>? ??
                           feeStructure.value!['data']?['feeHead'] as Map<String, dynamic>? ?? {};

            return Column(
              children: [
                _buildFeeItem('Admission Fee', feeHead['admissionFee'], color, isTablet),
                _buildFeeItem('First Term Amount', feeHead['firstTermAmt'], color, isTablet),
                _buildFeeItem('Second Term Amount', feeHead['secondTermAmt'], color, isTablet),
                _buildFeeItem('Bus First Term', feeHead['busFirstTermAmt'], color, isTablet),
                _buildFeeItem('Bus Second Term', feeHead['busSecondTermAmt'], color, isTablet),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFeeItem(String label, dynamic amount, Color color, bool isTablet) {
    final amountValue = amount?.toString() ?? '0';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isTablet ? 12 : 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? 14 : 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            '₹$amountValue',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeStructureTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FeeStructureView();
  }
}

class _StudentRecordsTab extends StatelessWidget {
  final controller = Get.find<AccountingController>();
  final recordController = Get.put(StudentRecordController());

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade50, Colors.teal.shade50],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.history, color: Colors.green, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Transaction Records',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: ElevatedButton.icon(
                            onPressed: _loadTransactions,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Refresh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      if (recordController.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (recordController.studentRecords.isEmpty) {
                        return _buildEmptyTransactions();
                      }
                      return Column(
                        children: recordController.studentRecords.map((record) {
                          return _buildTransactionItem(
                            record['studentName'] ?? 'Unknown Student',
                            '₹${record['amount'] ?? 0}',
                            record['paymentMode'] ?? 'Unknown',
                            record['date'] ?? 'Unknown Date',
                            record['_id'] ?? '',
                            record['status'] == 'paid',
                          );
                        }).toList(),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: const Column(
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No transaction records found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Collect some fees to see records here',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _loadTransactions() async {
    final schoolId = Get.find<AuthController>().user.value?.schoolId;
    if (schoolId != null) {
      Get.snackbar('Info', 'Loading transaction records from database...');
    } else {
      Get.snackbar('Error', 'School ID not found');
    }
  }

  Widget _buildTransactionItem(
    String student,
    String amount,
    String mode,
    String date,
    String transactionId,
    bool isPaid,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isPaid ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPaid ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPaid ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPaid ? Icons.check_circle : Icons.pending,
              color: isPaid ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '$mode • $date',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                if (transactionId.isNotEmpty)
                  Text(
                    'ID: $transactionId',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPaid ? 'PAID' : 'PENDING',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
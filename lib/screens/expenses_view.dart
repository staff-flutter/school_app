import 'dart:core';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:intl/intl.dart';
import 'package:school_app/screens/subscription_management_view.dart';
import 'package:collection/collection.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/widgets/responsive_wrapper.dart';
import 'package:school_app/core/extensions/widget_extensions.dart';
import 'package:school_app/controllers/accounting_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/subscription_controller.dart';
import 'package:school_app/models/school_models.dart';
import 'package:school_app/models/accounting_models.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/core/permissions/permission_system.dart';

class ExpensesView extends GetView<AccountingController> {
  ExpensesView({super.key});

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  final _chequeNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final selectedCategory = 'Salary'.obs;
  final selectedPaymentMode = 'cash'.obs;
  final billFiles = <PlatformFile>[].obs; // Store actual files
  final workPhotoFiles = <PlatformFile>[].obs; // Store actual files
  final selectedSchool = Rxn<School>();
  final selectedDate = DateTime.now().obs;
  final schoolController = Get.find<SchoolController>();

  void _initializeSchoolForUser() {
    final authController = Get.find<AuthController>();
    final userRole = authController.user.value?.role?.toLowerCase() ?? '';
    final userSchoolId = authController.user.value?.schoolId;
    
    if (!['correspondent'].contains(userRole) && userSchoolId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final userSchool = schoolController.schools.firstWhereOrNull(
          (school) => school.id == userSchoolId,
        );
        if (userSchool != null) {
          selectedSchool.value = userSchool;
        } else {
          schoolController.getAllSchools().then((_) {
            final school = schoolController.schools.firstWhereOrNull(
              (s) => s.id == userSchoolId,
            );
            if (school != null) {
              selectedSchool.value = school;
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    if (!authController.hasPermission(Permission.EXPENSE_ADD)) {
      return Scaffold(
        backgroundColor: AppTheme.appBackground,
        body: SafeArea(
          child: Center(
            child: Container(
              margin: EdgeInsets.all(isTablet ? 48 : 32),
              padding: EdgeInsets.all(isTablet ? 48 : 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppTheme.errorGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Access Denied',
                    style: TextStyle(
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You do not have permission to add expenses',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.mutedText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      schoolController.getAllSchools();
      _initializeSchoolForUser();
    });

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildModernAppBar(context, isTablet),
            SliverPadding(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSchoolSelection(isTablet),
                  const SizedBox(height: 20),
                  _buildContentArea(context, isTablet),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context, bool isTablet) {
    return SliverAppBar(
      expandedHeight: isTablet ? 200 : 160,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
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
                              'Expenses',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 24 : 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Track and manage school expenses',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: isTablet ? 16 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => _showExpensesList(context),
                          icon: const Icon(Icons.history, color: Colors.white),
                          tooltip: 'View History',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      backgroundColor: AppTheme.primaryBlue,
    );
  }

  Widget _buildSchoolSelection(bool isTablet) {
    final authController = Get.find<AuthController>();
    final userRole = authController.user.value?.role?.toLowerCase() ?? '';
    final isReadOnly = !['correspondent'].contains(userRole);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.successGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  isReadOnly ? 'Your School' : 'Select School',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isReadOnly)
              Obx(() {
                final userSchoolId = authController.user.value?.schoolId;
                final userSchool = schoolController.schools.firstWhereOrNull(
                  (school) => school.id == userSchoolId,
                );
                final schoolName = selectedSchool.value?.name ?? userSchool?.name ?? 'Loading...';
                
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryBlue.withOpacity(0.05), AppTheme.primaryBlue.withOpacity(0.02)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.business, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          schoolName,
                          style: TextStyle(
                            color: AppTheme.primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              })
            else
              Obx(() => Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonFormField<School>(
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    hintText: 'Choose a school',
                  ),
                  value: schoolController.schools.contains(selectedSchool.value) 
                      ? selectedSchool.value 
                      : null,
                  items: schoolController.schools.map((school) {
                    return DropdownMenuItem<School>(
                      value: school,
                      child: Text(school.name),
                    );
                  }).toList(),
                  onChanged: (school) {
                    selectedSchool.value = school;
                    if (school != null) {
                      if (Get.isRegistered<SubscriptionController>()) {
                        final subscriptionController = Get.find<SubscriptionController>();
                        subscriptionController.loadSubscription(school.id);
                      }
                    }
                  },
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildContentArea(BuildContext context, bool isTablet) {
    return Obx(() {
      if (selectedSchool.value == null) {
        return _buildEmptyStateWidget(context, isTablet, 'Please select a school', Icons.school);
      }
      
      final subscriptionController = Get.isRegistered<SubscriptionController>() 
          ? Get.find<SubscriptionController>() 
          : null;
      
      if (subscriptionController?.isLoading.value == true) {
        return const Center(child: CircularProgressIndicator());
      }
      
      // Only check subscription for correspondent and principal roles
      final userRole = Get.find<AuthController>().user.value?.role?.toLowerCase() ?? '';
      final requiresSubscriptionCheck = ['correspondent', 'principal'].contains(userRole);

      if (requiresSubscriptionCheck) {
        final hasAccess = subscriptionController?.hasModuleAccess('expense') ?? false;

        if (!hasAccess) {
          return _buildUpgradeRequiredWidget(context, 'Expense', isTablet);
        }
      }
      
      return _buildExpenseForm(isTablet);
    });
  }

  Widget _buildEmptyStateWidget(BuildContext context, bool isTablet, String message, IconData icon) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 48 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: isTablet ? 64 : 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeRequiredWidget(BuildContext context, String featureName, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 48 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.warningGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Upgrade Required',
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your current plan does not include the $featureName module. Please contact your correspondent to upgrade.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (_)=>SubscriptionManagementView()));},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'View Plans',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseForm(bool isTablet) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExpenseDetailsCard(isTablet),
            const SizedBox(height: 20),
            _buildEvidenceCard(isTablet),
            const SizedBox(height: 20),
            _buildSaveButton(isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseDetailsCard(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.biologyGreen.withOpacity(0.39),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  'Expense Details',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildAmountField(isTablet),
            const SizedBox(height: 20),
            _buildCategoryDropdown(isTablet),
            const SizedBox(height: 20),
            _buildDateField(isTablet),
            const SizedBox(height: 20),
            _buildRemarksField(isTablet),
            const SizedBox(height: 20),
            _buildPaymentModeSelector(isTablet),
            const SizedBox(height: 20),
            _buildConditionalFields(isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceCard(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.chemistryYellow.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.errorGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.security, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Evidence Section',
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      Text(
                        'Upload proof',
                        style: TextStyle(
                          color: AppTheme.errorRed,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildFileUploadSection(
              'Bill/Invoice Upload',
              'Upload bill or invoice',
              billFiles,
              true, // Mandatory
              isTablet,
              true, // isBillFile
            ),
            const SizedBox(height: 20),
            _buildFileUploadSection(
              'Photo of Work/Item',
              'Upload photo of actual work done or item purchased (Optional)',
              workPhotoFiles,
              false, // Optional
              isTablet,
              false, // isWorkPhoto
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isTablet) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.successGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successGreen.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Obx(() => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: controller.isLoading.value ? null : _saveExpense,
          child: Center(
            child: controller.isLoading.value
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Save Expense',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      )),
    );
  }

  Widget _buildAmountField(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: _amountController,
        decoration: const InputDecoration(
          labelText: 'Amount *',
          prefixText: '₹ ',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter amount';
          }
          if (double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCategoryDropdown(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category *',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isTablet ? 16 : 14,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            value: selectedCategory.value,
            items: ['Salary', 'EB', 'Fuel', 'Operations', 'Maintenance']
                .map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) selectedCategory.value = value;
            },
          ),
        )),
      ],
    );
  }

  Widget _buildPaymentModeSelector(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Mode *',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isTablet ? 16 : 14,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ['cash', 'upi', 'cheque', 'bank'].map((mode) {
            final isSelected = selectedPaymentMode.value == mode;
            return Container(
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.primaryGradient : null,
                color: isSelected ? null : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey.shade300,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => selectedPaymentMode.value = mode,
                  borderRadius: BorderRadius.circular(25),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Text(
                      mode.toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.primaryText,
                        fontWeight: FontWeight.w600,
                        fontSize: isTablet ? 14 : 12,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        )),
      ],
    );
  }

  Widget _buildConditionalFields(bool isTablet) {
    return Obx(() => selectedPaymentMode.value == 'cheque'
        ? Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextFormField(
                  controller: _chequeNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Cheque Number *',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (value) {
                    if (selectedPaymentMode.value == 'cheque' &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter cheque number';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextFormField(
                  controller: _bankNameController,
                  decoration: const InputDecoration(
                    labelText: 'Bank Name *',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (value) {
                    if (selectedPaymentMode.value == 'cheque' &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter bank name';
                    }
                    return null;
                  },
                ),
              ),
            ],
          )
        : const SizedBox());
  }

  Widget _buildDateField(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date *',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isTablet ? 16 : 14,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: Get.context!,
              initialDate: selectedDate.value,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              selectedDate.value = picked;
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 12),
                Text(
                  DateFormat('yyyy-MM-dd').format(selectedDate.value),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildRemarksField(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: _remarksController,
        decoration: const InputDecoration(
          labelText: 'Remarks',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        maxLines: 3,
      ),
    );
  }

  Widget _buildFileUploadSection(
    String title,
    String subtitle,
    RxList<PlatformFile> files,
    bool isMandatory,
    bool isTablet,
    bool isBillFile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isTablet ? 16 : 14,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.mutedText,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: files.isEmpty && isMandatory
                  ? AppTheme.errorRed
                  : Colors.grey.shade200,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _pickFile(isBillFile),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: files.isEmpty
                    ? Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient.scale(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.cloud_upload,
                              size: 32,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to upload file${isMandatory ? " *" : ""}',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.mutedText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'JPG, PNG, PDF (Multiple files allowed)',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.mutedText,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.successGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.check_circle, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${files.length} file(s) selected',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.successGreen,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  onPressed: () => files.clear(),
                                  icon: Icon(Icons.close, color: AppTheme.mutedText),
                                  iconSize: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...files.map((file) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.insert_drive_file, size: 16, color: AppTheme.primaryBlue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    file.name,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
              ),
            ),
          ),
        )),
      ],
    );
  }

  void _pickFile(bool isBillFile) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      allowMultiple: true, // Allow multiple files
    );

    if (result != null && result.files.isNotEmpty) {
      if (isBillFile) {
        billFiles.value = result.files;
        Get.snackbar('Success', '${result.files.length} bill file(s) selected');
      } else {
        workPhotoFiles.value = result.files;
        Get.snackbar('Success', '${result.files.length} work photo(s) selected');
      }
    }
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      // Validate bill files are uploaded (mandatory)
      if (billFiles.isEmpty) {
        Get.snackbar('Error', 'Please upload at least one bill/invoice file', 
          backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      // Get academic year from school or use current year
      final school = selectedSchool.value;
      final academicYear = school?.currentAcademicYear ?? 
        '${DateTime.now().year}-${DateTime.now().year + 1}';

      controller.addExpense(
        schoolId: selectedSchool.value?.id ?? '',
        category: selectedCategory.value,
        amount: double.parse(_amountController.text),
        paymentMode: selectedPaymentMode.value,
        date: selectedDate.value,
        academicYear: academicYear,
        remarks: _remarksController.text,
        billFiles: billFiles,
        workPhotoFiles: workPhotoFiles,
        chequeNumber: selectedPaymentMode.value == 'cheque' ? _chequeNumberController.text : null,
        bankName: selectedPaymentMode.value == 'cheque' ? _bankNameController.text : null,
      );
    }
  }

  void _showExpensesList(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    if (selectedSchool.value != null) {
      controller.loadExpenses(schoolId: selectedSchool.value!.id);
    }

    Get.bottomSheet(
      Container(
        height: Get.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expenses History',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          selectedSchool.value?.name ?? "All Schools",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() => controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : controller.expenses.isEmpty
                      ? _buildEmptyState(context, isTablet)
                      : ListView.builder(
                          padding: EdgeInsets.all(isTablet ? 24 : 16),
                          itemCount: controller.expenses.length,
                          itemBuilder: (context, index) {
                            final expense = controller.expenses[index];
                            return _buildExpenseCard(context, expense, index, isTablet);
                          },
                        )),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isTablet) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: isTablet ? 64 : 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No expenses recorded',
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first expense to get started',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, Expense expense, int index, bool isTablet) {
    final statusColor = expense.status == 'verified' 
        ? AppTheme.successGreen
        : expense.status == 'rejected'
            ? AppTheme.errorRed
            : AppTheme.warningYellow;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.lightGreen.withOpacity(0.19),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showExpenseDetails(expense),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient.scale(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(expense.category),
                        color: AppTheme.primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.category,
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.mutedText.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'EXP-${expense.expenseNo ?? "N/A"}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.mutedText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${expense.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            expense.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildDetailChip(Icons.payment, expense.paymentMode.toUpperCase(), isTablet),
                    const SizedBox(width: 12),
                    _buildDetailChip(Icons.calendar_today, expense.date, isTablet),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text, bool isTablet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.mutedText),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: isTablet ? 12 : 11,
              color: AppTheme.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'salary': return Icons.person;
      case 'eb': return Icons.electrical_services;
      case 'fuel': return Icons.local_gas_station;
      case 'operations': return Icons.business;
      case 'maintenance': return Icons.build;
      default: return Icons.receipt;
    }
  }

  void _showExpenseDetails(Expense expense) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.blueGrey,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.mathGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(expense.category),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Expense Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Category', expense.category),
              _buildDetailRow('Amount', '₹${expense.amount.toStringAsFixed(2)}'),
              _buildDetailRow('Payment Mode', expense.paymentMode.toUpperCase()),
              _buildDetailRow('Date', expense.date),
              _buildDetailRow('Status', expense.status.toUpperCase()),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton(
                  onPressed: () => Get.back(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
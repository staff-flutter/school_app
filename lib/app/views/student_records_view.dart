import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:school_app/app/views/record_details_view.dart';
import 'package:school_app/app/views/subscription_management_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:collection/collection.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

import '../controllers/student_record_controller.dart';
import '../controllers/school_controller.dart';
import '../controllers/subscription_controller.dart';
import '../data/models/school_models.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/api_rbac_wrapper.dart';
import '../core/rbac/api_rbac.dart';
import '../data/models/student_model.dart';
import '../modules/auth/controllers/auth_controller.dart';
import 'concession_detail_view.dart';
import 'student_receipts_view.dart';

class StudentRecordsView extends StatefulWidget {
  const StudentRecordsView({Key? key}) : super(key: key);

  @override
  State<StudentRecordsView> createState() => _StudentRecordsViewState();
}

class _StudentRecordsViewState extends State<StudentRecordsView> {
  final recordController = Get.put(StudentRecordController());
  final schoolController = Get.find<SchoolController>();
  final authController = Get.find<AuthController>();
  
  final studentRecords = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  
  final selectedSchool = Rxn<School>();
  final selectedClass = Rxn<SchoolClass>();
  final selectedSection = Rxn<Section>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      schoolController.getAllSchools();
      _initializeSchoolForUser();
    });
  }

  void _initializeSchoolForUser() {
    final userRole = authController.user.value?.role?.toLowerCase() ?? '';
    final userSchoolId = authController.user.value?.schoolId;
    
    if (userRole != 'correspondent' && userSchoolId != null) {
      // For non-correspondent users, find and set their school
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final userSchool = schoolController.schools.firstWhereOrNull(
          (school) => school.id == userSchoolId,
        );
        if (userSchool != null) {
          selectedSchool.value = userSchool;
          // Load classes for the selected school
          schoolController.getAllClasses(userSchool.id);
        } else {
          // If school not found in list, fetch it
          schoolController.getAllSchools().then((_) {
            final school = schoolController.schools.firstWhereOrNull(
              (s) => s.id == userSchoolId,
            );
            if (school != null) {
              selectedSchool.value = school;
              // Load classes for the selected school
              schoolController.getAllClasses(school.id);
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
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
                  _buildSchoolSelectionCard(context, isTablet),
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
                          Icons.school,
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
                              'Student Records',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 24 : 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Manage student fees and concessions',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: isTablet ? 16 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          authController.user.value?.role?.toUpperCase() ?? 'USER',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
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

  Widget _buildSchoolSelectionCard(BuildContext context, bool isTablet) {
    final authController = Get.find<AuthController>();
    final userRole = authController.user.value?.role?.toLowerCase() ?? '';
    final isReadOnly = userRole != 'correspondent';
    
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
              // Show readonly school name for non-correspondent users
              Obx(() => Container(
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
                        selectedSchool.value?.name ?? 'Loading...',
                        style: TextStyle(
                          color: AppTheme.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
            else
              // Show modern dropdown for correspondent
              Obx(() => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<School>(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    hintText: 'Choose a school',
                    hintStyle: TextStyle(color: AppTheme.mutedText, fontSize: 16),
                    prefixIcon: Container(
                      margin: const EdgeInsets.only(left: 12, right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                    ),
                  ),
                  value: schoolController.schools.contains(selectedSchool.value) 
                      ? selectedSchool.value 
                      : null,
                  items: schoolController.schools.map((school) {
                    return DropdownMenuItem<School>(
                      value: school,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.school, color: Colors.white, size: 14),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    school.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryText,
                                    ),
                                  ),
                                  Text(
                                    'School ID: ${school.id.substring(0, 8)}...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (school) {
                    selectedSchool.value = school;
                    selectedClass.value = null;
                    selectedSection.value = null;
                    if (school != null) {
                      schoolController.classes.clear();
                      schoolController.sections.clear();

                      if (Get.isRegistered<SubscriptionController>()) {
                        final subscriptionController = Get.find<SubscriptionController>();
                        subscriptionController.loadSubscription(school.id);
                      }
                      schoolController.getAllClasses(school.id);
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
        return _buildEmptyState(context, isTablet, 'Please select a school', Icons.school);
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
        final hasAccess = subscriptionController?.hasModuleAccess('studentRecord') ?? false;

        if (!hasAccess) {
          return _buildUpgradeRequiredWidget(context, isTablet, 'Student Record');
        }
      }

      return Column(
        children: [
          _buildFiltersCard(context, isTablet),
          const SizedBox(height: 20),
          _buildTabsSection(context, isTablet),
        ],
      );
    });
  }

  Widget _buildFiltersCard(BuildContext context, bool isTablet) {
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
                    gradient: AppTheme.warningGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.filter_list, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Obx(() {
              final isClassesLoading = schoolController.isLoading.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isClassesLoading
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        child: Row(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.class_, color: Colors.white, size: 16),
                            ),
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Loading classes...',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.mutedText,
                              ),
                            ),
                          ],
                        ),
                      )
                    : DropdownButtonFormField<SchoolClass>(
                        decoration: InputDecoration(
                          labelText: 'Select Class',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          labelStyle: TextStyle(color: AppTheme.mutedText, fontSize: 16),
                          prefixIcon: Container(
                            margin: const EdgeInsets.only(left: 12, right: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.class_, color: Colors.white, size: 16),
                          ),
                        ),
                        value: schoolController.classes.contains(selectedClass.value)
                            ? selectedClass.value
                            : null,
                        items: schoolController.classes.map((cls) {
                          return DropdownMenuItem<SchoolClass>(
                            value: cls,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  cls.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.primaryText,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: selectedSchool.value == null ? null : (cls) {
                          selectedClass.value = cls;
                          selectedSection.value = null;
                          if (cls != null) {
                            schoolController.getAllSections(classId: cls.id, schoolId: selectedSchool.value!.id);
                          }
                        },
                      ),
              );
            }),
            const SizedBox(height: 16),
            Obx(() {
              final isSectionsLoading = schoolController.isLoading.value && selectedClass.value != null;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<Section>(
                  decoration: InputDecoration(
                    labelText: schoolController.sections.isEmpty && selectedClass.value != null
                        ? 'No sections found'
                        : 'Select Section',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    labelStyle: TextStyle(color: AppTheme.mutedText, fontSize: 16),
                    prefixIcon: Container(
                      margin: const EdgeInsets.only(left: 12, right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.warningGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.group, color: Colors.white, size: 16),
                    ),
                  ),
                  value: schoolController.sections.contains(selectedSection.value)
                      ? selectedSection.value
                      : null,
                  items: schoolController.sections.isEmpty
                      ? []
                      : schoolController.sections.map((section) {
                          return DropdownMenuItem<Section>(
                            value: section,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.warningGradient,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  section.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.primaryText,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  onChanged: selectedClass.value == null || schoolController.sections.isEmpty ? null : (section) {
                    selectedSection.value = section;
                  },
                ),
              );
            }),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _applyFilter,
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Apply Filter',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabsSection(BuildContext context, bool isTablet) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(6),
              child: TabBar(
                indicator: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.mutedText,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isTablet ? 16 : 14,
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: isTablet ? 16 : 14,
                ),
                tabs: [
                  Tab(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: isTablet ? 20 : 18),
                        const SizedBox(width: 8),
                        Text('Records'),
                      ],
                    ),
                  ),
                  Tab(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_offer, size: isTablet ? 20 : 18),
                        const SizedBox(width: 8),
                        Text('Concessions'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: TabBarView(
              children: [
                _RecordsTab(records: studentRecords, parent: this),
                _ConcessionsTab(records: studentRecords, parent: this),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isTablet, String message, IconData icon) {
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

  Widget _buildUpgradeRequiredWidget(BuildContext context, bool isTablet, String featureName) {
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

  void _applyFilter() async {
    if (selectedSchool.value == null) {
      
      Get.snackbar('Error', 'Please select a school');
      return;
    }

    try {
      isLoading.value = true;
      final response = await recordController.getStudentRecords(
        schoolId: selectedSchool.value!.id,
        classId: selectedClass.value?.id,
        sectionId: selectedSection.value?.id,
      );

      if (response != null) {
        final records = List<Map<String, dynamic>>.from(response['data'] ?? []);
        studentRecords.value = records;
      } else {
        final message = response?['message'] ?? 'Failed to load student records';
        Get.snackbar('Error', message);
        studentRecords.value = [];
      }
    } catch (e) {
      
      Get.snackbar('Error', 'Failed to load student records: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void _showApplyConcessionDialog() {
    if (selectedSchool.value == null) {
      Get.snackbar('Error', 'Please select a school first.');
      return;
    }
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: ApplyConcessionForm(schoolId: selectedSchool.value!.id, onSuccess: _applyFilter),
        ),
      ),
      barrierDismissible: true,
    );
  }
}

class _RecordsTab extends StatelessWidget {
  final RxList<Map<String, dynamic>> records;
  final _StudentRecordsViewState parent;
  const _RecordsTab({required this.records, required this.parent});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Obx(() {
      if (records.isEmpty) {
        return Container(
          padding: EdgeInsets.all(isTablet ? 48 : 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient.scale(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long,
                  size: isTablet ? 64 : 48,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Records Found',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Apply filters above to load student records',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.mutedText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 8 : 4,
          vertical: 8,
        ),
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          return _buildRecordCard(record, context, isTablet);
        },
      );
    });
  }

  Widget _buildRecordCard(Map<String, dynamic> record, BuildContext context, bool isTablet) {
    final student = record['studentId'] ?? {};
    final feeStructure = record['feeStructure'] ?? {};
    final feePaid = record['feePaid'] ?? {};
    final dues = record['dues'] ?? {};

    final totalFees = (feeStructure['admissionFee'] ?? 0) +
                     (feeStructure['firstTermAmt'] ?? 0) +
                     (feeStructure['secondTermAmt'] ?? 0) +
                     (feeStructure['busFirstTermAmt'] ?? 0) +
                     (feeStructure['busSecondTermAmt'] ?? 0);

    final totalPaid = (feePaid['admissionFee'] ?? 0) +
                     (feePaid['firstTermAmt'] ?? 0) +
                     (feePaid['secondTermAmt'] ?? 0) +
                     (feePaid['busFirstTermAmt'] ?? 0) +
                     (feePaid['busSecondTermAmt'] ?? 0);

    final totalDues = (dues['admissionDues'] ?? 0) +
                     (dues['firstTermDues'] ?? 0) +
                     (dues['secondTermDues'] ?? 0) +
                     (dues['busfirstTermDues'] ?? 0) +
                     (dues['busSecondTermDues'] ?? 0);

    final isPaid = record['isFullyPaid'] == true;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 8 : 4,
        vertical: 8,
      ),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Get.to(() => StudentReceiptsView(studentRecord: record)),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: isPaid ? AppTheme.successGradient : AppTheme.warningGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isPaid ? AppTheme.successGreen : AppTheme.warningYellow).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: isTablet ? 32 : 28,
                        backgroundColor: Colors.transparent,
                        backgroundImage: student['studentImage']?['url'] != null
                            ? NetworkImage(student['studentImage']['url'])
                            : null,
                        child: student['studentImage']?['url'] == null
                            ? Text(
                                student['studentName']?.toString().substring(0, 1).toUpperCase() ?? 'S',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student['studentName'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: isTablet ? 20 : 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'SR ID: ${student['srId'] ?? 'N/A'}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryBlue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Class: ${record['className']} - ${record['sectionName']}',
                            style: TextStyle(
                              color: AppTheme.mutedText,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: isPaid ? AppTheme.successGradient : AppTheme.warningGradient,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (isPaid ? AppTheme.successGreen : AppTheme.warningYellow).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            isPaid ? 'PAID' : 'PENDING',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: AppTheme.mutedText),
                            onSelected: (value) => _handleRecordAction(value, record, context),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility, size: 18),
                                    SizedBox(width: 8),
                                    Text('View Details'),
                                  ],
                                ),
                              ),
                              if (ApiPermissions.hasApiAccess(Get.find<AuthController>().user.value?.role?.toLowerCase() ?? '', 'PATCH /api/studentrecord/togglestatus'))
                                const PopupMenuItem(
                                  value: 'toggle',
                                  child: Row(
                                    children: [
                                      Icon(Icons.toggle_on, size: 18),
                                      SizedBox(width: 8),
                                      Text('Toggle Status'),
                                    ],
                                  ),
                                ),
                              if (ApiPermissions.hasApiAccess(Get.find<AuthController>().user.value?.role?.toLowerCase() ?? '', 'DELETE /api/studentrecord/deleterecord'))
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 18, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete Record', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient.scale(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildSummaryItem('Total Fees', '₹$totalFees', AppTheme.primaryBlue, isTablet)),
                      Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                      Expanded(child: _buildSummaryItem('Paid', '₹$totalPaid', AppTheme.successGreen, isTablet)),
                      Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                      Expanded(child: _buildSummaryItem('Dues', '₹$totalDues', AppTheme.errorRed, isTablet)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    expansionTileTheme: ExpansionTileThemeData(
                      backgroundColor: Colors.grey.shade50,
                      collapsedBackgroundColor: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  child: ExpansionTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.warningGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      'Fee Breakdown',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildFeeRow('Admission Fee', feeStructure['admissionFee'], feePaid['admissionFee'], isTablet),
                            _buildFeeRow('First Term', feeStructure['firstTermAmt'], feePaid['firstTermAmt'], isTablet),
                            _buildFeeRow('Second Term', feeStructure['secondTermAmt'], feePaid['secondTermAmt'], isTablet),
                            _buildFeeRow('Bus First Term', feeStructure['busFirstTermAmt'], feePaid['busFirstTermAmt'], isTablet),
                            _buildFeeRow('Bus Second Term', feeStructure['busSecondTermAmt'], feePaid['busSecondTermAmt'], isTablet),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, bool isTablet) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 14 : 12,
            color: AppTheme.mutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFeeRow(String label, dynamic total, dynamic paid, bool isTablet) {
    final totalAmount = total ?? 0;
    final paidAmount = paid ?? 0;
    final dueAmount = totalAmount - paidAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isTablet ? 16 : 14,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFeeDetail('Total', '₹$totalAmount', AppTheme.primaryBlue, isTablet),
              ),
              Expanded(
                child: _buildFeeDetail('Paid', '₹$paidAmount', AppTheme.successGreen, isTablet),
              ),
              Expanded(
                child: _buildFeeDetail('Due', '₹$dueAmount', AppTheme.errorRed, isTablet),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeeDetail(String label, String value, Color color, bool isTablet) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 16 : 14,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 12 : 11,
            color: AppTheme.mutedText,
          ),
        ),
      ],
    );
  }

  void _handleRecordAction(String action, Map<String, dynamic> record, BuildContext context) async {
    final controller = Get.find<StudentRecordController>();

    switch (action) {
      case 'view':
        Get.to(() => StudentRecordDetailsPage(
          schoolId: record['schoolId'],
          studentId: record['studentId']?['_id'],
        ));
        break;

      case 'toggle':
        await controller.toggleStudentStatus(record['_id'],!record['isActive']);
        parent._applyFilter();
        break;
      case 'delete':
        await controller.deleteStudentRecord(record['_id']);
        parent._applyFilter();
        break;
    }
  }
}

class _ConcessionsTab extends StatelessWidget {
  final RxList<Map<String, dynamic>> records;
  final _StudentRecordsViewState parent;

  const _ConcessionsTab({required this.records, required this.parent});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() {
        final concessionsRecords = records.where((record) =>
          record['concession']?['isApplied'] == true
        ).toList();

        if (concessionsRecords.isEmpty) {
          return Container(
            padding: EdgeInsets.all(isTablet ? 48 : 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.warningGradient.scale(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_offer,
                    size: isTablet ? 64 : 48,
                    color: AppTheme.warningYellow,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Concessions Found',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Apply filters above to load concession records',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.mutedText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 8 : 4,
            vertical: 8,
          ),
          itemCount: concessionsRecords.length,
          itemBuilder: (context, index) {
            final record = concessionsRecords[index];
            return _buildConcessionCard(record, isTablet);
          },
        );
      }),
      floatingActionButton: ApiRbacWrapper(
        apiEndpoint: 'POST /api/studentrecord/applyconcession',
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: parent._showApplyConcessionDialog,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
            tooltip: 'Apply Concession',
          ),
        ),
      ),
    );
  }

  Widget _buildConcessionCard(Map<String, dynamic> record, bool isTablet) {
    final student = record['studentId'] ?? {};
    final concession = record['concession'] ?? {};
    final isApproved = concession['approvedBy'] != null;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 8 : 4,
        vertical: 8,
      ),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Get.to(() => ConcessionDetailView(concessionData: record)),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: isApproved ? AppTheme.successGradient : AppTheme.warningGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isApproved ? AppTheme.successGreen : AppTheme.warningYellow).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: isTablet ? 28 : 24,
                        backgroundColor: Colors.transparent,
                        backgroundImage: student['studentImage']?['url'] != null
                            ? NetworkImage(student['studentImage']['url'])
                            : null,
                        child: student['studentImage']?['url'] == null
                            ? Text(
                                student['studentName']?.toString().substring(0, 1).toUpperCase() ?? 'S',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student['studentName'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${record['className']} - ${record['sectionName']}',
                            style: TextStyle(
                              color: AppTheme.mutedText,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: isApproved ? AppTheme.successGradient : AppTheme.warningGradient,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (isApproved ? AppTheme.successGreen : AppTheme.warningYellow).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            isApproved ? 'APPROVED' : 'PENDING',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: AppTheme.mutedText),
                            onSelected: (value) => _handleConcessionAction(value, record),
                            itemBuilder: (context) => [
                              if (ApiPermissions.hasApiAccess(Get.find<AuthController>().user.value?.role?.toLowerCase() ?? '', 'PUT /api/studentrecord/updatevalue'))
                                const PopupMenuItem(
                                  value: 'update_value',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 18),
                                      SizedBox(width: 8),
                                      Text('Update Value'),
                                    ],
                                  ),
                                ),
                              if (ApiPermissions.hasApiAccess(Get.find<AuthController>().user.value?.role?.toLowerCase() ?? '', 'PUT /api/studentrecord/update/proof'))
                                const PopupMenuItem(
                                  value: 'update_proof',
                                  child: Row(
                                    children: [
                                      Icon(Icons.upload_file, size: 18),
                                      SizedBox(width: 8),
                                      Text('Update Proof'),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'view_details',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility, size: 18),
                                    SizedBox(width: 8),
                                    Text('View Details'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.warningGradient.scale(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: _buildConcessionDetail('Type', concession['type']?.toString().toUpperCase() ?? 'N/A', isTablet),
                          ),
                          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                          Flexible(
                            child: _buildConcessionDetail('Value', '${concession['value'] ?? 0}${concession['type'] == 'percentage' ? '%' : ''}', isTablet),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Flexible(
                            child: _buildConcessionDetail('Amount', '₹${concession['inAmount'] ?? 0}', isTablet),
                          ),
                          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                          Flexible(
                            child: _buildConcessionDetail('Status', isApproved ? 'Approved' : 'Pending', isTablet),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (concession['proof'] != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.attachment, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Proof Document',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryText,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                concession['proof']['originalName'] ?? 'Document attached',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton(
                            onPressed: () => _viewProof(concession['proof']),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: const Text('View', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConcessionDetail(String label, String value, bool isTablet) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 14 : 12,
            color: AppTheme.mutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _viewProof(Map<String, dynamic> proof) async {
    final url = proof['url'];
    if (url == null) return;

    final uri = Uri.parse(url);
    final fileExtension = path.extension(url).toLowerCase();

    if (['.jpg', '.jpeg', '.png'].contains(fileExtension)) {
      Get.dialog(
        Dialog(
          child: PhotoView(
            imageProvider: NetworkImage(url),
          ),
        ),
      );
    } else {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        Get.snackbar('Error', 'Could not open document');
      }
    }
  }

  void _handleConcessionAction(String action, Map<String, dynamic> record) async {
    switch (action) {
      case 'update_value':
        _showUpdateConcessionValueDialog(record, parent._applyFilter);
        break;
      case 'update_proof':
        _showUpdateConcessionProofDialog(record, parent._applyFilter);
        break;
      case 'view_details':
        Get.to(() => ConcessionDetailView(concessionData: record));
        break;
    }
  }

  void _showUpdateConcessionValueDialog(Map<String, dynamic> record, VoidCallback onSuccess) {
    final valueController = TextEditingController(text: record['concession']?['value']?.toString());
    String concessionType = record['concession']?['type'] ?? 'percentage';

    Get.dialog(
      Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Update Concession Value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Concession Type'),
                value: concessionType,
                items: ['percentage', 'amount'].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) => concessionType = value!,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(labelText: 'Concession Value'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final controller = Get.find<StudentRecordController>();
                        final success = await controller.updateConcessionValue(
                          schoolId: record['schoolId'],
                          studentId: record['_id'],
                          classId: record['classId'],
                          sectionId: record['sectionId'],
                          concessionType: concessionType,
                          concessionValue: double.tryParse(valueController.text) ?? 0,
                        );
                        Get.back();
                        if (success) {
                          onSuccess();
                        }
                      },
                      child: const Text('Update'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
// Add this for byte operations

// ... inside your _ConcessionsTab or State class ...

  void _showUpdateConcessionProofDialog(Map<String, dynamic> record, VoidCallback onSuccess) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      final String extension = path.extension(file.path).toLowerCase();
      const int targetLimit = 250 * 1024; // 250 KB

      // Show Loading Dialog with Progress Percentage
      Get.dialog(
        Obx(() {
          final progress = Get.find<StudentRecordController>().uploadProgress.value;
          return Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(value: progress > 0 ? progress : null),
                    const SizedBox(height: 16),
                    Text(progress > 0
                        ? "Uploading: ${(progress * 100).toStringAsFixed(0)}%"
                        : "Processing & Compressing..."),
                  ],
                ),
              ),
            ),
          );
        }),
        barrierDismissible: false,
      );

      try {
        if (['.jpg', '.jpeg', '.png'].contains(extension)) {
          if (await file.length() > targetLimit) {
            final Directory tempDir = await getTemporaryDirectory();
            // FIX: Ensure targetPath is different from file.path
            final String targetPath = path.join(
                tempDir.path,
                "compressed_${DateTime.now().millisecondsSinceEpoch}.jpg"
            );

            XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
              file.absolute.path,
              targetPath,
              quality: 50, // High compression for 250KB limit
              minWidth: 1024,
              minHeight: 1024,
            );

            if (compressedXFile != null) {
              file = File(compressedXFile.path);
            }
          }
        }

        final success = await Get.find<StudentRecordController>().updateConcessionProof(
          recordId: record['_id'],
          file: file,
        );

        Get.back(); // Close Loading Dialog
        if (success) onSuccess();

      } catch (e) {
        if (e is DioException && e.response?.statusCode == 413 ){
          Get.back();
          Get.snackbar('Error', 'File size exceeds the limit of 250KB');
        } else {
          Get.back();
          Get.snackbar('Error', 'Processing failed');
        }
      }
    }
  }
}

class ApplyConcessionForm extends StatefulWidget {
  final String schoolId;
  final VoidCallback onSuccess;
  const ApplyConcessionForm({Key? key, required this.schoolId, required this.onSuccess}) : super(key: key);

  @override
  State<ApplyConcessionForm> createState() => _ApplyConcessionFormState();
}

class _ApplyConcessionFormState extends State<ApplyConcessionForm> {
  final _formKey = GlobalKey<FormState>();
  final recordController = Get.find<StudentRecordController>();
  final schoolController = Get.find<SchoolController>();

  SchoolClass? selectedClass;
  Section? selectedSection;
  Student? selectedStudent;
  String concessionType = 'percentage';
  String newOld = 'new'; // Add newOld variable
  final concessionValueController = TextEditingController();
  final remarkController = TextEditingController();
  File? proofFile;
  bool isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight = screenHeight - keyboardHeight - 150; // Leave padding for dialog
    
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: availableHeight > 400 ? availableHeight : 400,
        maxWidth: isTablet ? 600 : double.infinity,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: keyboardHeight > 0 ? 20 : 0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    child: const Icon(Icons.local_offer, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Apply Concession',
                    style: TextStyle(
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Obx(() {
                final isClassesLoading = schoolController.isLoading.value;
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade50, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isClassesLoading
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          child: Row(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.class_, color: Colors.white, size: 16),
                              ),
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Loading classes...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.mutedText,
                                ),
                              ),
                            ],
                          ),
                        )
                      : DropdownButtonFormField<SchoolClass>(
                          decoration: InputDecoration(
                            labelText: 'Select Class',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            labelStyle: TextStyle(color: AppTheme.mutedText, fontSize: 16),
                            prefixIcon: Container(
                              margin: const EdgeInsets.only(left: 12, right: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.class_, color: Colors.white, size: 16),
                            ),
                          ),
                          value: selectedClass,
                          items: schoolController.classes.map((cls) {
                            return DropdownMenuItem(
                              value: cls,
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    cls.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.primaryText,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (cls) {
                            setState(() {
                              selectedClass = cls;
                              selectedSection = null;
                              selectedStudent = null;
                            });
                            if (cls != null) {
                              
                              schoolController.getAllSections(classId: cls.id, schoolId: widget.schoolId);
                            }
                          },
                          validator: (value) => value == null ? 'Please select a class' : null,
                        ),
                );
              }),
              const SizedBox(height: 16),
              Obx(() {
                final isSectionsLoading = schoolController.isLoading.value && selectedClass != null;
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade50, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSectionsLoading
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          child: Row(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.warningGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.group, color: Colors.white, size: 16),
                              ),
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Loading sections...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.mutedText,
                                ),
                              ),
                            ],
                          ),
                        )
                      : DropdownButtonFormField<Section>(
                          decoration: InputDecoration(
                            labelText: schoolController.sections.isEmpty && selectedClass != null
                                ? 'No sections found'
                                : 'Select Section',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            labelStyle: TextStyle(
                              color: schoolController.sections.isEmpty && selectedClass != null
                                  ? AppTheme.errorRed
                                  : AppTheme.mutedText,
                              fontSize: 16
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.only(left: 12, right: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: schoolController.sections.isEmpty && selectedClass != null
                                    ? AppTheme.errorGradient
                                    : AppTheme.warningGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                schoolController.sections.isEmpty && selectedClass != null
                                    ? Icons.warning
                                    : Icons.group,
                                color: Colors.white,
                                size: 16
                              ),
                            ),
                          ),
                          value: selectedSection,
                          items: schoolController.sections.isEmpty
                              ? []
                              : schoolController.sections.map((section) {
                                  return DropdownMenuItem(
                                    value: section,
                                    child: Text(section.name),
                                  );
                                }).toList(),
                          onChanged: selectedClass == null || schoolController.sections.isEmpty ? null : (section) {
                            setState(() {
                              selectedSection = section;
                              selectedStudent = null;
                            });
                            if (selectedClass != null && section != null) {
                              
                              schoolController.getAllStudents(
                                schoolId: widget.schoolId,
                                classId: selectedClass!.id,
                                sectionId: section.id
                              );
                            }
                          },
                          validator: (value) => value == null ? 'Please select a section' : null,
                        ),
                );
              }),
              const SizedBox(height: 16),
              Obx(() {
                final isStudentsLoading = schoolController.isLoading.value && selectedSection != null;
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade50, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isStudentsLoading
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          child: Row(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.successGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.person, color: Colors.white, size: 16),
                              ),
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Loading students...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.mutedText,
                                ),
                              ),
                            ],
                          ),
                        )
                      : DropdownButtonFormField<Student>(
                          decoration: InputDecoration(
                            labelText: 'Select Student',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            labelStyle: TextStyle(color: AppTheme.mutedText, fontSize: 16),
                            prefixIcon: Container(
                              margin: const EdgeInsets.only(left: 12, right: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppTheme.successGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.person, color: Colors.white, size: 16),
                            ),
                          ),
                          value: selectedStudent,
                          items: schoolController.students.map((student) {
                            return DropdownMenuItem(
                              value: student,
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.successGradient,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    student.name ?? 'Unknown Student',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.primaryText,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (student) => setState(() => selectedStudent = student),
                          validator: (value) => value == null ? 'Please select a student' : null,
                        ),
                );
              }),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Concession Type',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    labelStyle: TextStyle(color: AppTheme.mutedText, fontSize: 16),
                    prefixIcon: Container(
                      margin: const EdgeInsets.only(left: 12, right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.warningGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.local_offer, color: Colors.white, size: 16),
                    ),
                  ),
                  value: concessionType,
                  items: ['percentage', 'amount'].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: type == 'percentage' ? AppTheme.warningGradient : AppTheme.successGradient,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            type.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryText,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => concessionType = value!),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Student Type',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    labelStyle: TextStyle(color: AppTheme.mutedText, fontSize: 16),
                    prefixIcon: Container(
                      margin: const EdgeInsets.only(left: 12, right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_outline, color: Colors.white, size: 16),
                    ),
                  ),
                  value: newOld,
                  items: ['new', 'old'].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: type == 'new' ? AppTheme.successGradient : AppTheme.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            type.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryText,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => newOld = value!),
                  validator: (value) => value == null ? 'Please select student type' : null,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: concessionValueController,
                  decoration: InputDecoration(
                    labelText: 'Concession Value',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    labelStyle: TextStyle(color: AppTheme.mutedText, fontSize: 16),
                    prefixIcon: Container(
                      margin: const EdgeInsets.only(left: 12, right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calculate, color: Colors.white, size: 16),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryText,
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a value' : null,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: remarkController,
                  decoration: InputDecoration(
                    labelText: 'Remarks',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    labelStyle: TextStyle(color: AppTheme.mutedText, fontSize: 16),
                    prefixIcon: Container(
                      margin: const EdgeInsets.only(left: 12, right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.warningGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.note_add, color: Colors.white, size: 16),
                    ),
                  ),
                  maxLines: 3,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryText,
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter remarks' : null,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickProof,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.upload_file, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Upload Proof',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryText,
                                  ),
                                ),
                                if (proofFile != null)
                                  Text(
                                    'Selected: ${path.basename(proofFile!.path)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.successGreen,
                                    ),
                                  )
                                else
                                  Text(
                                    'Tap to select document',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.mutedText,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            proofFile != null ? Icons.check_circle : Icons.add_circle_outline,
                            color: proofFile != null ? AppTheme.successGreen : AppTheme.mutedText,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSubmitting
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Flexible(
                                    child: Text(
                                      'Applying...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Apply Concession',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                        ),
                      ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickProof() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null) {
      setState(() {
        proofFile = File(result.files.single.path!);
      });
    }
  }

  void _submitForm() async {
    // Check if proof file is uploaded
    if (proofFile == null) {
      Get.snackbar(
        'Proof Required',
        'Please upload a proof document before applying concession',
        backgroundColor: AppTheme.warningYellow,
        colorText: Colors.black,
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        isSubmitting = true;
      });

      try {
        final success = await recordController.applyConcession(
          schoolId: widget.schoolId,
          studentId: selectedStudent!.id,
          studentName: selectedStudent!.name,
          classId: selectedClass!.id,
          sectionId: selectedSection!.id,
          concessionType: concessionType,
          concessionValue: double.parse(concessionValueController.text),
          remark: remarkController.text,
          proofFile: proofFile,
          newOld: newOld,
        );

        if(success) {
          widget.onSuccess();
        }
      } finally {
        if (mounted) {
          setState(() {
            isSubmitting = false;
          });
        }
      }
    }
  }
}

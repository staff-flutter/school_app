import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:school_app/constants/api_constants.dart';
import 'package:school_app/screens/record_details_view.dart';
import 'package:school_app/screens/subscription_management_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:collection/collection.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:school_app/controllers/student_record_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/subscription_controller.dart';
import 'package:school_app/models/school_models.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/widgets/api_rbac_wrapper.dart';
import 'package:school_app/core/rbac/api_rbac.dart';
import 'package:school_app/models/student_model.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/screens/concession_detail_view.dart';
import 'package:school_app/screens/student_receipts_view.dart';

import '../core/utils/academic_year_utils.dart';

const _kPrimary = Color(0xFF2563EB);

class StudentRecordsView extends StatefulWidget {
  const StudentRecordsView({Key? key}) : super(key: key);

  @override
  State<StudentRecordsView> createState() => _StudentRecordsViewState();
}

class _StudentRecordsViewState extends State<StudentRecordsView> {
  final recordController = Get.put(StudentRecordController());
  final schoolController = Get.find<SchoolController>();
  final authController = Get.find<AuthController>();
  final _academicYearController =
  TextEditingController(text: AcademicYearUtils.getCurrentAcademicYear());

  final studentRecords = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  final selectedSchool = Rxn<School>();
  final selectedClass = Rxn<SchoolClass>();
  final selectedSection = Rxn<Section>();

  Worker? _schoolWorker;

  final selectedAcademicYear = AcademicYearUtils.getCurrentAcademicYear().obs;

  List<String> _recentAcademicYears() {
    final current = AcademicYearUtils.getCurrentAcademicYear();
    final startYear = int.parse(current.split('-')[0]);
    return List.generate(6, (i) {
      final y = startYear - i;
      return '$y-${y + 1}';
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      schoolController.getAllSchools();
      _initializeSchoolForUser();
    });

    // Correspondents pick their school globally (e.g. from the sidebar). If
    // they switch schools while this page is open, keep this page's local
    // `selectedSchool` in sync instead of leaving it pointed at the old
    // (or no) school.
    final userRole = authController.user.value?.role?.toLowerCase() ?? '';
    if (userRole == 'correspondent') {
      _schoolWorker = ever(schoolController.selectedSchool, (School? school) {
        if (!mounted || school == null) return;
        selectedSchool.value = school;
        selectedClass.value = null;
        selectedSection.value = null;
        schoolController.classes.clear();
        schoolController.sections.clear();
        schoolController.getAllClasses(school.id);
        if (Get.isRegistered<SubscriptionController>()) {
          Get.find<SubscriptionController>().loadSubscription(school.id);
        }
      });
    }
  }

  @override
  void dispose() {
    _schoolWorker?.dispose();
    super.dispose();
  }

  void _initializeSchoolForUser() {
    final userRole = authController.user.value?.role?.toLowerCase() ?? '';

    if (userRole == 'correspondent') {
      // This page previously only let a correspondent set a school by
      // picking one from the dropdown below — even if they'd already
      // selected a school elsewhere in the app (sidebar / other pages).
      // That left `selectedSchool` null on first load, which made the page
      // look blank ("Please select a school") every single time. Reuse the
      // globally selected school here if one already exists.
      final globallySelected = schoolController.selectedSchool.value;
      if (globallySelected != null) {
        selectedSchool.value = globallySelected;
        schoolController.getAllClasses(globallySelected.id);
        if (Get.isRegistered<SubscriptionController>()) {
          Get.find<SubscriptionController>().loadSubscription(globallySelected.id);
        }
      }
      return;
    }

    final userSchoolId = authController.user.value?.schoolId;
    if (userSchoolId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final userSchool = schoolController.schools.firstWhereOrNull(
              (school) => school.id == userSchoolId,
        );
        if (userSchool != null) {
          selectedSchool.value = userSchool;
          schoolController.getAllClasses(userSchool.id);
        } else {
          schoolController.getAllSchools().then((_) {
            final school = schoolController.schools.firstWhereOrNull(
                  (s) => s.id == userSchoolId,
            );
            if (school != null) {
              selectedSchool.value = school;
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
      backgroundColor: const Color(0xFFF0F5FF),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildModernAppBar(context, isTablet),
            SliverPadding(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                //  if(authController.user.value?.role?.toLowerCase()=='correspondent')
                 //   _buildSchoolSelectionCard(context, isTablet),
               //   const SizedBox(height: 20),
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
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDE6F5), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDDE6F5).withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.folder_shared_rounded,
                color: _kPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Student Record',
                    style: TextStyle(
                      color: Color(0xFF1A2A3A),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Manage student fees and concessions',
                    style: TextStyle(
                      color: Color(0xFF90A4BE),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                authController.user.value?.role?.toUpperCase() ?? 'USER',
                style: const TextStyle(
                  color: _kPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
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
                  child: const Icon(Icons.school, color: Colors.white, size: 12),
                ),
                const SizedBox(width: 16),
                Text(
                  isReadOnly ? 'Your School' : 'Select School',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isReadOnly)
              Obx(() => Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kPrimary.withOpacity(0.2), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.business, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedSchool.value?.name ?? 'Loading...',
                        style: TextStyle(
                          color: AppTheme.primaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
            else
              Obx(() => Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                ),
                child: DropdownButtonFormField<School>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    hintText: 'Choose a school',
                    hintStyle: TextStyle(color: AppTheme.mutedText, fontSize: 16),
                    prefixIcon: Container(
                      margin: const EdgeInsets.only(left: 12, right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _kPrimary,
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
                                color: _kPrimary,
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
          const SizedBox(height: 16),
          _buildTabsSection(context, isTablet),
        ],
      );
    });
  }

  Widget _buildFiltersCard(BuildContext context, bool isTablet) {
    return Obx(() => Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _filterChip(
          icon: Icons.class_rounded,
          label: selectedClass.value?.name ?? 'All Classes',
          active: selectedClass.value != null,
          onTap: () => _showClassFilterSheet(context),
        ),
        _filterChip(
          icon: Icons.group_rounded,
          label: selectedSection.value?.name ?? 'All Sections',
          active: selectedSection.value != null,
          onTap: () => _showSectionFilterSheet(context),
        ),
        _filterChip(
          icon: Icons.calendar_today_rounded,
          label: selectedAcademicYear.value,
          active: true,
          onTap: () => _showAcademicYearFilterSheet(context),
        ),
        if (selectedClass.value != null || selectedSection.value != null)
          GestureDetector(
            onTap: () {
              selectedClass.value = null;
              selectedSection.value = null;
              _applyFilter();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.close_rounded, size: 13, color: Colors.red.shade600),
                const SizedBox(width: 4),
                Text('Clear',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade600)),
              ]),
            ),
          ),
        if (isLoading.value)
          const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
          ),
      ],
    ));
  }

  Widget _filterChip({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: active ? _kPrimary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: active ? _kPrimary : const Color(0xFFDDE6F5),
            width: active ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: active ? _kPrimary : const Color(0xFF90A4BE)),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? _kPrimary : const Color(0xFF64748B),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded,
              size: 14, color: active ? _kPrimary : const Color(0xFF90A4BE)),
        ]),
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
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withOpacity(0.3),
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
                    height: 35,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: isTablet ? 20 : 14),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text('Records',
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    height: 35,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_offer, size: isTablet ? 20 : 14),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text('Concessions',
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
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
            child: Icon(icon, size: isTablet ? 64 : 48, color: Colors.grey.shade400),
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
            child: const Icon(Icons.lock_outline, size: 48, color: Colors.white),
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
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionManagementView())); },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View Plans', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
        academicYear: selectedAcademicYear.value,
      );
      if (response != null) {
        final records = List<Map<String, dynamic>>.from(response['data'] ?? []);
        if (records.isNotEmpty) {
        }
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
          padding: const EdgeInsets.all(20),
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

  void _showClassFilterSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE6F5),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(children: [
              const Text('Select Class',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A2A3A))),
              const Spacer(),
              GestureDetector(
                onTap: () => Get.back(),
                child: const Icon(Icons.close_rounded, color: Color(0xFF90A4BE), size: 22),
              ),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFEAF0FB)),
          ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: selectedClass.value == null ? _kPrimary.withOpacity(0.1) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.all_inclusive_rounded, size: 18,
                  color: selectedClass.value == null ? _kPrimary : const Color(0xFF90A4BE)),
            ),
            title: const Text('All Classes',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A2A3A))),
            trailing: selectedClass.value == null
                ? const Icon(Icons.check_circle_rounded, color: _kPrimary, size: 20) : null,
            onTap: () {
              selectedClass.value = null;
              selectedSection.value = null;
              Get.back();
              _applyFilter();
            },
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: Obx(() => ListView.builder(
              shrinkWrap: true,
              itemCount: schoolController.classes.length,
              itemBuilder: (_, i) {
                final c = schoolController.classes[i];
                final isSelected = selectedClass.value?.id == c.id;
                return ListTile(
                  leading: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: isSelected ? _kPrimary.withOpacity(0.1) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.class_rounded, size: 18,
                        color: isSelected ? _kPrimary : const Color(0xFF90A4BE)),
                  ),
                  title: Text(c.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                        color: isSelected ? _kPrimary : const Color(0xFF1A2A3A),
                      )),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: _kPrimary, size: 20) : null,
                  onTap: () {
                    selectedClass.value = c;
                    selectedSection.value = null;
                    schoolController.getAllSections(classId: c.id, schoolId: selectedSchool.value!.id);
                    Get.back();
                    _applyFilter();
                  },
                );
              },
            )),
          ),
          const SizedBox(height: 20),
        ]),
      ),
      isScrollControlled: true,
    );
  }

  void _showSectionFilterSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE6F5),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(children: [
              const Text('Select Section',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A2A3A))),
              const Spacer(),
              GestureDetector(
                onTap: () => Get.back(),
                child: const Icon(Icons.close_rounded, color: Color(0xFF90A4BE), size: 22),
              ),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFEAF0FB)),
          ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: selectedSection.value == null ? _kPrimary.withOpacity(0.1) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.all_inclusive_rounded, size: 18,
                  color: selectedSection.value == null ? _kPrimary : const Color(0xFF90A4BE)),
            ),
            title: const Text('All Sections',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A2A3A))),
            trailing: selectedSection.value == null
                ? const Icon(Icons.check_circle_rounded, color: _kPrimary, size: 20) : null,
            onTap: () {
              selectedSection.value = null;
              Get.back();
              _applyFilter();
            },
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: Obx(() {
              if (schoolController.sections.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    selectedClass.value == null ? 'Select a class first' : 'No sections found',
                    style: const TextStyle(color: Color(0xFF90A4BE), fontSize: 13),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: schoolController.sections.length,
                itemBuilder: (_, i) {
                  final s = schoolController.sections[i];
                  final isSelected = selectedSection.value?.id == s.id;
                  return ListTile(
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: isSelected ? _kPrimary.withOpacity(0.1) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.group_rounded, size: 18,
                          color: isSelected ? _kPrimary : const Color(0xFF90A4BE)),
                    ),
                    title: Text(s.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14,
                          color: isSelected ? _kPrimary : const Color(0xFF1A2A3A),
                        )),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: _kPrimary, size: 20) : null,
                    onTap: () {
                      selectedSection.value = s;
                      Get.back();
                      _applyFilter();
                    },
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 20),
        ]),
      ),
      isScrollControlled: true,
    );
  }

  void _showAcademicYearFilterSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('Select Academic Year',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
          ..._recentAcademicYears().map((year) => ListTile(
            leading: Icon(Icons.calendar_today_rounded,
                color: selectedAcademicYear.value == year ? _kPrimary : const Color(0xFF90A4BE)),
            title: Text(year, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: selectedAcademicYear.value == year
                ? const Icon(Icons.check_circle_rounded, color: _kPrimary) : null,
            onTap: () {
              selectedAcademicYear.value = year;
              Get.back();
              _applyFilter();
            },
          )),
          const SizedBox(height: 20),
        ]),
      ),
      isScrollControlled: true,
    );
  }

  void _openStudentDetails(Map<String, dynamic> record) async {
    if (selectedSchool.value == null) return;
    final studentId = record['_id'];
    if (studentId == null) {
      Get.snackbar('Error', 'Missing student ID for this record');
      return;
    }
    final fullRecord = await recordController.getStudentRecord(
      selectedSchool.value!.id,
      studentId,
      academicYear: selectedAcademicYear.value,
    );
    if (fullRecord != null) {
      Get.to(() => StudentReceiptsView(studentRecord: fullRecord));
    } else {
      Get.snackbar('Error', 'Could not load student record details');
    }
  }
}

// ─── Records Tab ────────────────────────────────────────────────────────────

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
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 48 : 24, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.receipt_long, size: isTablet ? 48 : 36, color: _kPrimary),
              ),
              const SizedBox(height: 16),
              Text(
                'No Records Found',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Apply filters above to load student records',
                style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 4, vertical: 8),
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          return _buildRecordCard(record, context, isTablet);
        },
      );
    });
  }

  Widget _buildRecordCard(Map<String, dynamic> record, BuildContext context, bool isTablet) {
    final studentName = record['studentName'] ?? 'Unknown';
    final srId = record['srId'] ?? 'N/A';
    final isPaid = record['isFullyPaid'] == true;
    final feeStatus = (record['feeStatus'] ?? 'unpaid').toString();
    final hasConcession = record['hasConcession'] == true;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 4, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => parent._openStudentDetails(record),   // see step 2
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: isTablet ? 26 : 18,
                      backgroundColor: isPaid ? AppTheme.successGreen.withOpacity(0.15) : _kPrimary.withOpacity(0.12),
                      backgroundImage: record['studentImage']?['url'] != null
                          ? NetworkImage(record['studentImage']['url'])
                          : null,
                      child: record['studentImage']?['url'] == null
                          ? Text(
                        studentName.toString().substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: isPaid ? AppTheme.successGreen : _kPrimary,
                          fontSize: isTablet ? 16 : 13,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(studentName, style: TextStyle(
                              fontSize: isTablet ? 18 : 13, fontWeight: FontWeight.bold, color: AppTheme.primaryText)),
                          const SizedBox(height: 3),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: _kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text('SR: $srId', style: const TextStyle(fontWeight: FontWeight.w600, color: _kPrimary, fontSize: 11)),
                            ),
                            const SizedBox(width: 6),
                            Flexible(child: Text('${record['className']} - ${record['sectionName']}', style: TextStyle(color: AppTheme.mutedText, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,)),
                          ]),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: isPaid ? AppTheme.successGreen : _kPrimary, borderRadius: BorderRadius.circular(20)),
                          child: Text(isPaid ? 'PAID' : feeStatus.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                        if (hasConcession) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(20)),
                            child: Text('CONCESSION', style: TextStyle(color: Colors.orange.shade800, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                        ],
                        const SizedBox(height: 6),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                          icon: Icon(Icons.more_vert, color: AppTheme.mutedText),
                          onSelected: (value) => _handleRecordAction(value, record, context),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility, size: 18), SizedBox(width: 8), Text('View Details')])),
                            if (ApiPermissions.hasApiAccess(Get.find<AuthController>().user.value?.role?.toLowerCase() ?? '', 'PATCH /api/studentrecord/togglestatus'))
                              const PopupMenuItem(value: 'toggle', child: Row(children: [Icon(Icons.toggle_on, size: 18), SizedBox(width: 8), Text('Toggle Status')])),
                            if (ApiPermissions.hasApiAccess(Get.find<AuthController>().user.value?.role?.toLowerCase() ?? '', 'DELETE /api/studentrecord/deleterecord'))
                              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete Record', style: TextStyle(color: Colors.red))])),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Icon(Icons.info_outline, size: 13, color: AppTheme.mutedText),
                  const SizedBox(width: 6),
                  Text('Tap for full fee breakdown', style: TextStyle(fontSize: 11, color: AppTheme.mutedText, fontStyle: FontStyle.italic)),
                ]),
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
            fontSize: isTablet ? 16 : 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 12 : 10,
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: isTablet ? 14 : 12, color: AppTheme.primaryText),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _buildFeeDetail('Total', '₹$totalAmount', AppTheme.primaryBlue, isTablet)),
              Expanded(child: _buildFeeDetail('Paid', '₹$paidAmount', AppTheme.successGreen, isTablet)),
              Expanded(child: _buildFeeDetail('Due', '₹$dueAmount', AppTheme.errorRed, isTablet)),
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
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: isTablet ? 14 : 12, color: color),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: isTablet ? 11 : 10, color: AppTheme.mutedText)),
      ],
    );
  }

  void _handleRecordAction(String action, Map<String, dynamic> record, BuildContext context) async {
    final controller = Get.find<StudentRecordController>();
    final recordId = record['recordId'];   // student-record document id, not student id
    switch (action) {
      case 'view':
        parent._openStudentDetails(record);
        break;
      case 'toggle':
        await controller.toggleStudentStatus(recordId, !(record['isActive'] == true));
        parent._applyFilter();
        break;
      case 'delete':
        await controller.deleteStudentRecord(recordId);
        parent._applyFilter();
        break;
    }
  }
}

// ─── Concessions Tab ────────────────────────────────────────────────────────

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
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 48 : 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.local_offer, size: isTablet ? 48 : 36, color: Colors.orange.shade600),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Concessions Found',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Apply filters above to load concession records',
                  style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 4, vertical: 8),
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
            color: _kPrimary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: parent._showApplyConcessionDialog,
            backgroundColor: Colors.transparent,
            elevation: 0,
            tooltip: 'Apply Concession',
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildConcessionCard(Map<String, dynamic> record, bool isTablet) {
    final student = record['studentId'] ?? {};
    final concession = record['concession'] ?? {};
    final isApproved = concession['approvedBy'] != null;
    final role = Get.find<AuthController>().user.value?.role?.toLowerCase() ?? '';
    final canReview = ['correspondent', 'administrator'].contains(role);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 4, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Get.to(() => ConcessionDetailView(concessionData: record)),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: isTablet ? 24 : 18,
                      backgroundColor: isApproved
                          ? AppTheme.successGreen.withOpacity(0.12)
                          : _kPrimary.withOpacity(0.12),
                      backgroundImage: student['studentImage']?['url'] != null
                          ? NetworkImage(student['studentImage']['url'])
                          : null,
                      child: student['studentImage']?['url'] == null
                          ? Text(
                        student['studentName']?.toString().substring(0, 1).toUpperCase() ?? 'S',
                        style: TextStyle(
                          color: isApproved ? AppTheme.successGreen : _kPrimary,
                          fontSize: isTablet ? 16 : 13,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student['studentName'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${record['className']} - ${record['sectionName']}',
                            style: TextStyle(color: AppTheme.mutedText, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isApproved ? AppTheme.successGreen : _kPrimary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isApproved ? 'APPROVED' : 'PENDING',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 6),
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
                                  child: Row(children: [
                                    Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Update Value'),
                                  ]),
                                ),
                              if (ApiPermissions.hasApiAccess(Get.find<AuthController>().user.value?.role?.toLowerCase() ?? '', 'PUT /api/studentrecord/update/proof'))
                                const PopupMenuItem(
                                  value: 'update_proof',
                                  child: Row(children: [
                                    Icon(Icons.upload_file, size: 18), SizedBox(width: 8), Text('Update Proof'),
                                  ]),
                                ),
                              const PopupMenuItem(
                                value: 'view_details',
                                child: Row(children: [
                                  Icon(Icons.visibility, size: 18), SizedBox(width: 8), Text('View Details'),
                                ]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.15)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Flexible(child: _buildConcessionDetail('Type', concession['type']?.toString().toUpperCase() ?? 'N/A', isTablet)),
                          Container(width: 1, height: 32, color: Colors.orange.withOpacity(0.2)),
                          Flexible(child: _buildConcessionDetail('Value', '${concession['value'] ?? 0}${concession['type'] == 'percentage' ? '%' : ''}', isTablet)),
                          Container(width: 1, height: 32, color: Colors.orange.withOpacity(0.2)),
                          Flexible(child: _buildConcessionDetail('Amount', '₹${concession['inAmount'] ?? 0}', isTablet)),
                          Container(width: 1, height: 32, color: Colors.orange.withOpacity(0.2)),
                          Flexible(child: _buildConcessionDetail('Status', isApproved ? 'Approved' : 'Pending', isTablet)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (concession['proof'] != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: _kPrimary.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kPrimary.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _kPrimary,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(Icons.attachment, color: Colors.white, size: 13),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Proof Document',
                                style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryText, fontSize: 11),
                              ),
                              Text(concession['proof']['originalName'] ?? 'Document attached',
                                style: TextStyle(fontSize: 10, color: AppTheme.mutedText),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _viewProof(concession['proof']),
                          style: TextButton.styleFrom(
                            foregroundColor: _kPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
                if (canReview && !isApproved) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _reviewConcession(record, approve: false),
                          icon: Icon(Icons.close_rounded, size: 16, color: Colors.red.shade600),
                          label: Text('Reject',
                              style: TextStyle(color: Colors.red.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red.shade200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _reviewConcession(record, approve: true),
                          icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                          label: const Text('Approve',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Approve/reject a pending concession request.
  // NOTE: this hits the "verify-concession" endpoint (api no. 141) using a
  // best-effort payload shape ({studentId, schoolId, approved, remark?}).
  // Double check the exact field names your backend expects for this route
  // and adjust below if it differs — the endpoint's request body wasn't
  // included in what was shared here.
  void _reviewConcession(Map<String, dynamic> record, {required bool approve}) async {
    String remark = '';
    if (!approve) {
      final reasonController = TextEditingController();
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Reject concession', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          content: TextField(
            controller: reasonController,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Reason for rejection (optional)'),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Get.back(result: true),
              child: const Text('Reject', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      remark = reasonController.text.trim();
    }

    // 1. Properly extract target student ID
    final studentId = record['studentId'] is Map ? record['studentId']['_id'] : record['studentId'];

    // 2. Fetch the current academic year for URL query injection
    final year = AcademicYearUtils.getCurrentAcademicYear().toString();

    // 3. Construct URL with the required academicYear query parameter
    final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.patchApproveStudentConcessionRequest}/$studentId?academicYear=$year'
    );

    final token = Get.find<AuthController>().storage.read('token');

    // 4. Clean body payload (academicYear removed since it's now in the URL path)
    final Map<String, dynamic> requestBody = {
      'status': approve ? 'Approved' : 'Rejected',
    };

    if (!approve && remark.isNotEmpty) {
      requestBody['remark'] = remark;
    }

    try {
      final res = await http.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      final decoded = jsonDecode(res.body);

      if (res.statusCode == 200 && decoded['ok'] == true) {
        Get.snackbar(
            'Success',
            approve ? 'Concession approved' : 'Concession rejected',
            backgroundColor: AppTheme.successGreen,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM
        );
        parent._applyFilter();
      } else {
        Get.snackbar(
            'Error',
            decoded['message'] ?? 'Failed to update concession',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM
        );
      }
    } catch (e) {
      Get.snackbar(
          'Error',
          'Failed to update concession',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM
      );
    }
  }


  Widget _buildConcessionDetail(String label, String value, bool isTablet) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: isTablet ? 14 : 11, fontWeight: FontWeight.bold, color: AppTheme.primaryText),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: isTablet ? 12 : 10, color: AppTheme.mutedText, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _viewProof(Map<String, dynamic> proof) async {
    final url = proof['url'];
    if (url == null) return;
    final uri = Uri.parse(url);
    final fileExtension = path.extension(url).toLowerCase();
    if (['.jpg', '.jpeg', '.png'].contains(fileExtension)) {
      Get.dialog(Dialog(child: PhotoView(imageProvider: NetworkImage(url))));
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Update Concession Value',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Concession Type'),
                value: concessionType,
                items: ['percentage', 'amount'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.toUpperCase()));
                }).toList(),
                onChanged: (value) => concessionType = value!,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(labelText: 'Concession Value'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Get.back(), child: const Text('Cancel'))),
                  const SizedBox(width: 12),
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
                          academicYear:  record['academicYear'] ?? AcademicYearUtils.getCurrentAcademicYear(),
                        );
                        Get.back();
                        if (success) onSuccess();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
                      child: const Text('Update', style: TextStyle(color: Colors.white)),
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

  void _showUpdateConcessionProofDialog(Map<String, dynamic> record, VoidCallback onSuccess) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      final String extension = path.extension(file.path).toLowerCase();
      const int targetLimit = 250 * 1024;

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
            final String targetPath = path.join(
              tempDir.path,
              "compressed_${DateTime.now().millisecondsSinceEpoch}.jpg",
            );
            XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
              file.absolute.path,
              targetPath,
              quality: 50,
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

        Get.back();
        if (success) onSuccess();
      } catch (e) {
        if (e is DioException && e.response?.statusCode == 413) {
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

// ─── Apply Concession Form ───────────────────────────────────────────────────

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
  String newOld = 'new';
  final concessionValueController = TextEditingController();
  final remarkController = TextEditingController();
  File? proofFile;
  bool isSubmitting = false;

  // Compact input decoration shared across all fields
  InputDecoration _inputDecor(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      labelStyle: TextStyle(color: AppTheme.mutedText, fontSize: 13),
      hintStyle: TextStyle(color: AppTheme.mutedText, fontSize: 13),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 10, right: 6),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    );
  }

  BoxDecoration _fieldBox() => BoxDecoration(
    color: Colors.grey.shade50,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey.shade200, width: 1.5),
  );

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight = screenHeight - keyboardHeight - 150;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: availableHeight > 400 ? availableHeight : 400,
        maxWidth: isTablet ? 600 : double.infinity,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: keyboardHeight > 0 ? 16 : 0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _kPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_offer, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Apply Concession',
                    style: TextStyle(
                      fontSize: isTablet ? 17 : 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Class
              Obx(() {
                final isClassesLoading = schoolController.isLoading.value;
                return Container(
                  decoration: _fieldBox(),
                  child: isClassesLoading
                      ? _loadingRow('Loading classes...')
                      : DropdownButtonFormField<SchoolClass>(
                    decoration: _inputDecor('Select Class', Icons.class_),
                    value: selectedClass,
                    items: schoolController.classes.map((cls) {
                      return DropdownMenuItem(value: cls, child: Text(cls.name, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (cls) {
                      setState(() { selectedClass = cls; selectedSection = null; selectedStudent = null; });
                      if (cls != null) {
                        schoolController.getAllSections(classId: cls.id, schoolId: widget.schoolId).then((_) {
                          if (schoolController.sections.isEmpty) {
                            // No sections configured for this class — load students directly
                            schoolController.getAllStudents(
                              schoolId: widget.schoolId,
                              classId: cls.id,
                              sectionId: null,
                            );
                          }
                        });
                      }
                    },
                    validator: (v) {
                      if (schoolController.sections.isNotEmpty && v == null) {
                        return 'Please select a section';
                      }
                      return null;
                    },                  ),
                );
              }),
              const SizedBox(height: 10),

              // Section
              Obx(() {
                final isSectionsLoading = schoolController.isLoading.value && selectedClass != null;
                return Container(
                  decoration: _fieldBox(),
                  child: isSectionsLoading
                      ? _loadingRow('Loading sections...')
                      : DropdownButtonFormField<Section>(
                    decoration: _inputDecor(
                      schoolController.sections.isEmpty && selectedClass != null
                          ? 'No sections found'
                          : 'Select Section',
                      schoolController.sections.isEmpty && selectedClass != null
                          ? Icons.info_outline
                          : Icons.group,
                    ),
                    value: selectedSection,
                    items: schoolController.sections.isEmpty
                        ? []
                        : schoolController.sections.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s.name, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: selectedClass == null || schoolController.sections.isEmpty ? null : (section) {
                      setState(() { selectedSection = section; selectedStudent = null; });
                      if (selectedClass != null && section != null) {
                        schoolController.getAllStudents(
                          schoolId: widget.schoolId,
                          classId: selectedClass!.id,
                          sectionId: section.id,
                        );
                      }
                    },
                    validator: (v) {
                      if (schoolController.sections.isNotEmpty && v == null) {
                        return 'Please select a section';
                      }
                      return null;
                    },
                  ),
                );
              }),
              const SizedBox(height: 10),

              // Student
              Obx(() {
                final isStudentsLoading = schoolController.isLoading.value && selectedSection != null;
                return Container(
                  decoration: _fieldBox(),
                  child: isStudentsLoading
                      ? _loadingRow('Loading students...')
                      : DropdownButtonFormField<Student>(
                    decoration: _inputDecor('Select Student', Icons.person),
                    value: selectedStudent,
                    items: schoolController.students.map((student) {
                      return DropdownMenuItem(
                        value: student,
                        child: Text(student.name ?? 'Unknown Student', style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (s) => setState(() => selectedStudent = s),
                    validator: (v) => v == null ? 'Please select a student' : null,
                  ),
                );
              }),
              const SizedBox(height: 10),

              // Concession Type
              Container(
                decoration: _fieldBox(),
                child: DropdownButtonFormField<String>(
                  decoration: _inputDecor('Concession Type', Icons.local_offer),
                  value: concessionType,
                  items: ['percentage', 'amount'].map((type) {
                    return DropdownMenuItem(value: type, child: Text(type.toUpperCase(), style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (v) => setState(() => concessionType = v!),
                ),
              ),
              const SizedBox(height: 10),

              // Student Type
              Container(
                decoration: _fieldBox(),
                child: DropdownButtonFormField<String>(
                  decoration: _inputDecor('Student Type', Icons.person_outline),
                  value: newOld,
                  items: ['new', 'old'].map((type) {
                    return DropdownMenuItem(value: type, child: Text(type.toUpperCase(), style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (v) => setState(() => newOld = v!),
                  validator: (v) => v == null ? 'Please select student type' : null,
                ),
              ),
              const SizedBox(height: 10),

              // Concession Value
              Container(
                decoration: _fieldBox(),
                child: TextFormField(
                  controller: concessionValueController,
                  decoration: _inputDecor('Concession Value', Icons.calculate),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  validator: (v) => v == null || v.isEmpty ? 'Please enter a value' : null,
                ),
              ),
              const SizedBox(height: 10),

              // Remarks
              Container(
                decoration: _fieldBox(),
                child: TextFormField(
                  controller: remarkController,
                  decoration: _inputDecor('Remarks', Icons.note_add),
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  validator: (v) => v == null || v.isEmpty ? 'Please enter remarks' : null,
                ),
              ),
              const SizedBox(height: 10),

              // Upload Proof
              Container(
                decoration: _fieldBox(),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickProof,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(7)),
                            child: const Icon(Icons.upload_file, color: Colors.white, size: 14),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Upload Proof',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryText, fontSize: 13)),
                                if (proofFile != null)
                                  Text('Selected: ${path.basename(proofFile!.path)}',
                                      style: TextStyle(fontSize: 10, color: AppTheme.successGreen))
                                else
                                  Text('Tap to select document',
                                      style: TextStyle(fontSize: 10, color: AppTheme.mutedText)),
                              ],
                            ),
                          ),
                          Icon(
                            proofFile != null ? Icons.check_circle : Icons.add_circle_outline,
                            color: proofFile != null ? AppTheme.successGreen : AppTheme.mutedText,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Text('Apply',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
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

  Widget _loadingRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          const SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
          ),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 13, color: AppTheme.mutedText)),
        ],
      ),
    );
  }

  void _pickProof() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result != null) {
      setState(() { proofFile = File(result.files.single.path!); });
    }
  }

  void _submitForm() async {
    if (proofFile == null) {
      Get.snackbar('Proof Required', 'Please upload a proof document before applying concession',
          backgroundColor: AppTheme.warningYellow, colorText: Colors.black);
      return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() { isSubmitting = true; });
      try {
        final success = await recordController.applyConcession(
          schoolId: widget.schoolId,
          studentId: selectedStudent!.id,
          studentName: selectedStudent!.name,
          classId: selectedClass!.id,
          sectionId: selectedSection?.id ?? '',
          concessionType: concessionType,
          concessionValue: double.parse(concessionValueController.text),
          remark: remarkController.text,
          proofFile: proofFile,
          newOld: newOld,
          academicYear:AcademicYearUtils.getCurrentAcademicYear(),
        );
        if (success) widget.onSuccess();
      } finally {
        if (mounted) setState(() { isSubmitting = false; });
      }
    }
  }
}
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:school_app/core/utils/academic_year_utils.dart';
import 'package:school_app/widgets/admin_sidebar.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:school_app/controllers/announcement_controller.dart';
import 'package:school_app/controllers/subscription_controller.dart';
import 'package:school_app/models/school_models.dart';
import 'package:school_app/screens/subscription_management_view.dart';
import 'package:school_app/controllers/communications_controller.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/widgets/responsive_wrapper.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/screens/announcement_detail_view.dart';

import '../controllers/school_controller.dart';

class CommunicationsView extends StatefulWidget {
  CommunicationsView({super.key});

  @override
  State<CommunicationsView> createState() => _CommunicationsViewState();
}
class _CommunicationsViewState extends State<CommunicationsView> {
  late CommunicationsController controller;
  late AnnouncementController announcementController;
  Worker? _schoolWatcher;

  @override
  void initState() {
    super.initState();

    controller = Get.find<CommunicationsController>();

    announcementController = Get.isRegistered<AnnouncementController>()
        ? Get.find<AnnouncementController>()
        : Get.put(AnnouncementController());

    final authController = Get.find<AuthController>();
    final userRole = authController.user.value?.role?.toLowerCase() ?? '';
    final userSchoolId = authController.user.value?.schoolId;
    final isParent = authController.user.value?.role == 'parent';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load schools first
      if (announcementController.schools.isEmpty) {
        await announcementController.getAllSchools();
      }

      // Auto-select school for non-correspondent
      if (userRole != 'correspondent' && userSchoolId != null) {
        final userSchool = announcementController.schools.firstWhereOrNull(
              (school) => school.id == userSchoolId,
        );
        if (userSchool != null) {
          announcementController.selectedSchool.value = userSchool;
          await announcementController.getAllAnnouncements(userSchool.id);
          if (isParent) announcementController.changeFilter('parent');
        }
      }
    });

    // 👇 Watch sidebar school changes for correspondent
    try {
      final schoolController = Get.find<SchoolController>();

      // Trigger immediately if school already selected
      final current = schoolController.selectedSchool.value;
      if (current != null && userRole == 'correspondent') {
        announcementController.selectedSchool.value = current;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          announcementController.getAllAnnouncements(current.id);
        });
      }

      // 👇 Watch for future changes
      _schoolWatcher = ever(schoolController.selectedSchool, (school) {
        if (school == null) return;
        if (userRole == 'correspondent') {
          announcementController.selectedSchool.value = school;
          announcementController.getAllAnnouncements(school.id);
        }
      });
    } catch (_) {}
  }
  @override
  void dispose() {
    _schoolWatcher?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    late AnnouncementController announcementController;
    if (Get.isRegistered<AnnouncementController>()) {
      announcementController = Get.find<AnnouncementController>();
    } else {
      announcementController = Get.put(AnnouncementController());
    }
    
    final authController = Get.find<AuthController>();
    final isParent = authController.user.value?.role == 'parent';
    final userRole = authController.user.value?.role?.toLowerCase() ?? '';
    final userSchoolId = authController.user.value?.schoolId;

    if (announcementController.schools.isEmpty && !announcementController.isLoading.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        announcementController.getAllSchools().then((_) {

          if (announcementController.schools.isNotEmpty) {
            final firstSchool = announcementController.schools.first;
            print('School name: ${firstSchool.name}');
            print('Logo map: ${firstSchool.logo}');
          }
          // Auto-select school for non-correspondent users
          if (userRole != 'correspondent' && userSchoolId != null) {
            final userSchool = announcementController.schools.firstWhereOrNull(
              (school) => school.id == userSchoolId,
            );
            if (userSchool != null) {
              announcementController.selectedSchool.value = userSchool;
            }
          }
        });
      });
    }

    if (announcementController.selectedSchool.value != null &&
        announcementController.announcements.isEmpty &&
        !announcementController.isLoading.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        announcementController.getAllAnnouncements(announcementController.selectedSchool.value!.id);
        // For parents, filter to only parent announcements
        if (isParent) {
          announcementController.changeFilter('parent');
        }
      });
    }
    try {
      final schoolController = Get.find<SchoolController>();
      ever(schoolController.selectedSchool, (school) {
        if (school != null && userRole == 'correspondent') {
          announcementController.selectedSchool.value = school;
          announcementController.getAllAnnouncements(school.id);
        }
      });
    } catch (_) {}

    return Scaffold(
        backgroundColor: const Color(0xFFF0F5FF),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 20,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.campaign_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Communications',
                style: TextStyle(color: Color(0xFF1A2A3A), fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: const Color(0xFFE2E8F0)),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: IconButton(
                onPressed: () {
                  if (announcementController.selectedSchool.value != null) {
                    announcementController.getAllAnnouncements(announcementController.selectedSchool.value!.id);
                  } else if (announcementController.schools.isNotEmpty) {
                    announcementController.selectedSchool.value = announcementController.schools.first;
                  } else {
                    announcementController.refreshSchools();
                  }
                },
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF8A9FC0)),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // if (userRole == 'correspondent')
                //   Obx(() => Container(
                //     margin: EdgeInsets.all(AppTheme.getResponsivePadding(context)),
                //     child: announcementController.schools.isNotEmpty
                //         ? _buildSchoolSelector(context, announcementController)
                //         : _buildLoadingCard(context),
                //   )),
                //
                SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: Obx(() {
                    final selectedSchool = announcementController.selectedSchool.value;
                    if (selectedSchool == null) {
                      return _buildSelectSchoolPrompt(context);
                    }
                    
                    // Check subscription for correspondent and principal roles
                    final userRole = authController.user.value?.role?.toLowerCase() ?? '';
                    final requiresSubscriptionCheck = ['correspondent', 'principal'].contains(userRole);
                    
                    if (requiresSubscriptionCheck) {
                      final hasAccess = announcementController.hasSubscriptionAccess(selectedSchool.id);
                      if (!hasAccess) {
                        return _buildUpgradeRequiredWidget(context, 'Communications');
                      }
                    }
                    
                    return Column(
                      children: [
                        if (!isParent)
                          const SizedBox(height: 16),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: AppTheme.getResponsivePadding(context)),
                            child: _buildFilterSection(context, announcementController),
                          ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _AnnouncementsList(controller: announcementController),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: _buildFAB(context, announcementController, authController),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );

  }


  Widget _buildSchoolSelector(BuildContext context, AnnouncementController controller) {
    final authController = Get.find<AuthController>();
    final userRole = authController.user.value?.role?.toLowerCase() ?? '';
    final isReadOnly = userRole != 'correspondent';
    
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 15),
                ),
                const SizedBox(width: 12),
                Text(
                  'School',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                    fontSize: 12
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isReadOnly)
              // Show readonly school name for non-correspondent users
              Container(
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
                        gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.business, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        controller.selectedSchool.value?.name ?? 'Loading...',
                        style: TextStyle(
                          color: AppTheme.primaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              // Show modern dropdown for correspondent
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.dividerColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<School>(
                    isExpanded: true,
                    value: controller.selectedSchool.value,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      hintText: 'Choose your school',
                      hintStyle: TextStyle(color: AppTheme.mutedText, fontSize: 16),
                    prefixIcon: Container(
                      margin: const EdgeInsets.only(left: 12, right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                    ),
                  ),
                  items: controller.schools.map((school) {
                    return DropdownMenuItem<School>(
                      value: school,
                      child: Text(
                        school.name.isNotEmpty ? school.name : 'School ${school.id.substring(0, 8)}...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryText,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedSchool.value = value;
                      if (Get.isRegistered<SubscriptionController>()) {
                        final subscriptionController = Get.find<SubscriptionController>();
                        subscriptionController.loadSubscription(value.id);
                      }
                    }
                  },
              ),
              )],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppTheme.primaryBlue),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Loading schools...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectSchoolPrompt(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(AppTheme.getResponsivePadding(context)),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school_outlined, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a School',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please choose a school from the dropdown above to view communications',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context, AnnouncementController controller) {
    final filters = [
      {'label': 'All', 'value': 'all', 'icon': Icons.groups_rounded},
      {'label': 'Students', 'value': 'student', 'icon': Icons.school_rounded},
      {'label': 'Parents', 'value': 'parent', 'icon': Icons.family_restroom_rounded},
      {'label': 'Teachers', 'value': 'teacher', 'icon': Icons.person_rounded},
    ];

    void showFilterSheet() {
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
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(children: [
                const Text('Filter by Audience',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A))),
                const Spacer(),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.close_rounded,
                      color: Color(0xFF94A3B8), size: 22),
                ),
              ]),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            ...filters.map((f) => Obx(() {
              final isSelected =
                  controller.selectedFilter.value == f['value'];
              return ListTile(
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(f['icon'] as IconData,
                      size: 18,
                      color: isSelected
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF94A3B8)),
                ),
                title: Text(f['label'] as String,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 14,
                      color: isSelected
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF0F172A),
                    )),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF3B82F6), size: 20)
                    : null,
                onTap: () {
                  controller.changeFilter(f['value'] as String);
                  Get.back();
                },
              );
            })),
            const SizedBox(height: 20),
          ]),
        ),
        isScrollControlled: true,
      );
    }

    return Obx(() {
      final current = filters.firstWhere(
              (f) => f['value'] == controller.selectedFilter.value,
          orElse: () => filters.first);
      final isFiltered = controller.selectedFilter.value != 'all';

      return Row(children: [
        GestureDetector(
          onTap: showFilterSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isFiltered
                  ? const Color(0xFFEFF6FF)
                  : Colors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isFiltered
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFE2E8F0),
                width: isFiltered ? 1.5 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 4,
                    offset: Offset(0, 1)),
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(current['icon'] as IconData,
                  size: 14,
                  color: isFiltered
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text(
                current['label'] as String,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isFiltered
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: isFiltered
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF94A3B8)),
            ]),
          ),
        ),
        const Spacer(),
        // Announcement count
        Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            '${controller.filteredAnnouncements.length} posts',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        )),
      ]);
    });
  }
  Widget _buildFilterChip(String label, String value, IconData icon, AnnouncementController controller) {
    return Obx(() {
      final isSelected = controller.selectedFilter.value == value;
      return GestureDetector(
        onTap: () => controller.changeFilter(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : null,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? Colors.transparent : AppTheme.dividerColor,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.mutedText,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.primaryText,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget? _buildFAB(BuildContext context, AnnouncementController announcementController, AuthController authController) {
    final userRole = authController.user.value?.role;
    if (!['correspondent', 'principal', 'administrator'].contains(userRole)) {
      return null;
    }
    
    return Obx(() {
      final selectedSchool = announcementController.selectedSchool.value;
      if (selectedSchool == null) {
        return const SizedBox.shrink();
      }
      
      final hasAccess = announcementController.hasSubscriptionAccess(selectedSchool.id);
      if (!hasAccess) {
        return const SizedBox.shrink();
      }
      
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showCreateDialog(context, announcementController, authController),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'New Post',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildUpgradeRequiredWidget(BuildContext context, String featureName) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(AppTheme.getResponsivePadding(context)),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.warningGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'Upgrade Required',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your current plan does not include the $featureName module. Please contact your correspondent to upgrade.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.mutedText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: 'View Plans',
              gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              icon: Icons.upgrade,
              onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (_)=>SubscriptionManagementView()));},
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, AnnouncementController controller, AuthController authController) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'general';
    String selectedPriority = 'normal';
    final selectedAudiences = <String>['all'].obs;
    final selectedFiles = <File>[].obs;
    
    if (controller.schools.isNotEmpty && controller.selectedSchool.value == null) {
      controller.selectedSchool.value = controller.schools.first;
    }
    
    Get.dialog(
      AlertDialog(
        title: const Text('Create Announcement'),
        content: SingleChildScrollView(
          child: Obx(() => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.isLoading.value)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Loading schools...'),
                    ],
                  ),
                ),
              
              if (controller.schools.isNotEmpty)
                DropdownButtonFormField<School>(
                  value: controller.selectedSchool.value,
                  decoration: const InputDecoration(labelText: 'School'),
                  hint: const Text('Select School'),
                  items: controller.schools.toSet().map((school) {
                    return DropdownMenuItem<School>(
                      value: school,
                      child: Text(school.name,style: TextStyle(fontSize: 13),),
                    );
                  }).toList(),
                  onChanged: (value) => controller.selectedSchool.value = value,
                ),
              const SizedBox(height: 16),

              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: ['general', 'urgent', 'event', 'holiday'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.toUpperCase()));
                }).toList(),
                onChanged: (value) => selectedType = value ?? 'general',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: ['low', 'normal', 'high', 'urgent'].map((priority) {
                  return DropdownMenuItem(value: priority, child: Text(priority.toUpperCase()));
                }).toList(),
                onChanged: (value) => selectedPriority = value ?? 'normal',
              ),
              const SizedBox(height: 16),
              
              // Target Audience
              Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Target Audience:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: selectedAudiences.contains('all'),
                        onSelected: (selected) {
                          if (selected) {
                            selectedAudiences.clear();
                            selectedAudiences.add('all');
                          }
                        },
                      ),
                      FilterChip(
                        label: const Text('Students'),
                        selected: selectedAudiences.contains('student'),
                        onSelected: (selected) {
                          selectedAudiences.remove('all');
                          if (selected) {
                            selectedAudiences.add('student');
                          } else {
                            selectedAudiences.remove('student');
                          }
                          if (selectedAudiences.isEmpty) selectedAudiences.add('all');
                        },
                      ),
                      FilterChip(
                        label: const Text('Parents'),
                        selected: selectedAudiences.contains('parent'),
                        onSelected: (selected) {
                          selectedAudiences.remove('all');
                          if (selected) {
                            selectedAudiences.add('parent');
                          } else {
                            selectedAudiences.remove('parent');
                          }
                          if (selectedAudiences.isEmpty) selectedAudiences.add('all');
                        },
                      ),
                      FilterChip(
                        label: const Text('Teachers'),
                        selected: selectedAudiences.contains('teacher'),
                        onSelected: (selected) {
                          selectedAudiences.remove('all');
                          if (selected) {
                            selectedAudiences.add('teacher');
                          } else {
                            selectedAudiences.remove('teacher');
                          }
                          if (selectedAudiences.isEmpty) selectedAudiences.add('all');
                        },
                      ),
                    ],
                  ),
                ],
              )),
              const Divider(),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Attachments', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),

              // Image Preview Grid
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...selectedFiles.map((file) => Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _viewImage(file: file),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(file, width: 70, height: 70, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: -10,
                        right: -10,
                        child: IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                          onPressed: () => selectedFiles.remove(file),
                        ),
                      ),
                    ],
                  )),
                  // Pick Image Button
                  InkWell(
                    onTap: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        allowMultiple: true,
                      );
                      if (result != null) {
                        selectedFiles.addAll(result.paths.whereType<String>().map((p) => File(p)));
                      }
                    },
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_a_photo, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          )),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) {
                Get.snackbar('Error', 'Please enter a title.');
                return;
              }
              if (descriptionController.text.trim().isEmpty) {
                Get.snackbar('Error', 'Please enter a description.');
                return;
              }
              
              final school = controller.selectedSchool.value;
              if (school == null) {
                Get.snackbar('Error', 'Please select a school.');
                return;
              }
              
              controller.createAnnouncement(
                schoolId: school.id,
                academicYear: AcademicYearUtils.getCurrentAcademicYear(),
                title: titleController.text.trim(),
                description: descriptionController.text.trim(),
                type: selectedType,
                priority: selectedPriority,
                targetAudience: selectedAudiences.toList(),
                attachmentPaths: selectedFiles.map((f) => f.path).toList(),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _viewImage({File? file, String? url}) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PhotoView(
              imageProvider: file != null ? FileImage(file) : NetworkImage(url!) as ImageProvider,
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Get.back(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementsList extends StatelessWidget {
  final AnnouncementController controller;

  const _AnnouncementsList({required this.controller});

  bool get isParent => Get.find<AuthController>().user.value?.role == 'parent';

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    
    return Obx(() {
      if (controller.isLoading.value && controller.filteredAnnouncements.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (controller.filteredAnnouncements.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.announcement_outlined, 
                size: 64, 
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
              ),
              const SizedBox(height: 16),
              Text(
                controller.selectedFilter.value == 'all' 
                  ? 'No announcements found'
                  : 'No announcements for ${controller.selectedFilter.value}s',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.getResponsivePadding(context),
          vertical: 8,
        ),
        itemCount: controller.filteredAnnouncements.length,
        itemBuilder: (context, index) {
          final announcement = controller.filteredAnnouncements[index];
          return // Replace the Container(...) card inside ListView.builder with:
            GestureDetector(
              onTap: () {
                controller.getAnnouncement(announcement['_id']).then((_) {
                  final fresh =
                      controller.selectedAnnouncement.value ?? announcement;
                  Get.to(() => AnnouncementDetailView(announcement: fresh));
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 4,
                        offset: Offset(0, 1)),
                    BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 12,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Coloured type band ──────────────────────────────────
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                        decoration: BoxDecoration(
                          color: _typeAccent(announcement['type']).withOpacity(0.25),
                          borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Row(children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: _typeAccent(announcement['type']).withOpacity(0.19),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(_typeIcon(announcement['type']),
                                size: 16,
                                color: _typeAccent(announcement['type'])),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              announcement['title'] ?? 'No Title',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isParent)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_horiz_rounded,
                                  color: Color(0xFF94A3B8), size: 20),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                    value: 'view',
                                    child: Row(children: [
                                      Icon(Icons.visibility_rounded, size: 16),
                                      SizedBox(width: 8),
                                      Text('View'),
                                    ])),
                                if (_canEdit(
                                    Get.find<AuthController>().user.value?.role))
                                  const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(children: [
                                        Icon(Icons.edit_rounded, size: 16),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ])),
                                if (_canDelete(
                                    Get.find<AuthController>().user.value?.role))
                                  const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(children: [
                                        Icon(Icons.delete_rounded,
                                            size: 16, color: Color(0xFFDC2626)),
                                        SizedBox(width: 8),
                                        Text('Delete',
                                            style:
                                            TextStyle(color: Color(0xFFDC2626))),
                                      ])),
                              ],
                              onSelected: (value) {
                                final id = announcement['_id'];
                                if (value == 'view') {
                                  controller.getAnnouncement(id).then((_) {
                                    final fresh =
                                        controller.selectedAnnouncement.value ??
                                            announcement;
                                    Get.to(
                                            () => AnnouncementDetailView(
                                            announcement: fresh));
                                  });
                                } else if (value == 'edit') {
                                  _showEditDialog(
                                      Get.context!, controller, announcement);
                                } else if (value == 'delete') {
                                  _showDeleteConfirmation(
                                      Get.context!, controller, id);
                                }
                              },
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 14, color: Color(0xFF94A3B8)),
                              onPressed: () {
                                controller
                                    .getAnnouncement(announcement['_id'])
                                    .then((_) {
                                  final fresh =
                                      controller.selectedAnnouncement.value ??
                                          announcement;
                                  Get.to(
                                          () => AnnouncementDetailView(
                                          announcement: fresh));
                                });
                              },
                            ),
                        ]),
                      ),

                      // ── Body ────────────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                announcement['description'] ?? 'No Description',
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF475569), height: 1.5),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Row(children: [
                                _typeBadge(announcement['type']),
                                const SizedBox(width: 6),
                                _priorityBadge(announcement['priority']),
                                const Spacer(),
                                if (announcement['createdAt'] != null)
                                  Text(
                                    _formatDate(announcement['createdAt']),
                                    style: const TextStyle(
                                        fontSize: 10, color: Color(0xFF94A3B8)),
                                  ),
                              ]),
                            ]),
                      ),
                    ]),
              ),
            );
        },
      );
    });
  }
  Color _typeAccent(String? type) {
    switch (type?.toLowerCase()) {
      case 'urgent':   return const Color(0xFFDC2626);
      case 'event':    return const Color(0xFF3B82F6);
      case 'holiday':  return const Color(0xFF059669);
      default:         return const Color(0xFF1D4ED8);
    }
  }

  IconData _typeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'urgent':   return Icons.warning_amber_rounded;
      case 'event':    return Icons.event_rounded;
      case 'holiday':  return Icons.celebration_rounded;
      default:         return Icons.campaign_rounded;
    }
  }

  Widget _typeBadge(String? type) {
    final color = _typeAccent(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        (type ?? 'general').toUpperCase(),
        style: TextStyle(
            fontSize: 9, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _priorityBadge(String? priority) {
    Color color;
    switch (priority?.toLowerCase()) {
      case 'urgent': color = const Color(0xFFDC2626); break;
      case 'high':   color = const Color(0xFFD97706); break;
      case 'low':    color = const Color(0xFF059669); break;
      default:       color = const Color(0xFF64748B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        (priority ?? 'normal').toUpperCase(),
        style: TextStyle(
            fontSize: 9, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  String _formatDate(dynamic raw) {
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
  Gradient _getTypeGradient(String? type) {
    switch (type) {
      case 'urgent': return AppTheme.errorGradient;
      case 'event': return const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case 'holiday': return AppTheme.successGradient;
      default: return const LinearGradient(
        colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  Gradient _getCardGradient(String? type) {
    switch (type) {
      case 'urgent': return AppTheme.errorGradient;
      case 'event': return const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case 'holiday': return AppTheme.successGradient;
      default: return const LinearGradient(
        colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }
  
  Gradient _getPriorityGradient(String? priority) {
    switch (priority) {
      case 'urgent': return AppTheme.errorGradient;
      case 'high': return AppTheme.warningGradient;
      case 'low': return AppTheme.successGradient;
      default: return const LinearGradient(
        colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }
  
  bool _canEdit(String? role) {
    return ['correspondent', 'principal', 'administrator'].contains(role);
  }
  
  bool _canDelete(String? role) {
    return ['correspondent', 'principal', 'administrator'].contains(role);
  }

  void _showEditDialog(BuildContext context, AnnouncementController controller, Map<String, dynamic> announcement) {
    final titleController = TextEditingController(text: announcement['title']);
    final descriptionController = TextEditingController(text: announcement['description']);
    final String announcementId = announcement['_id'];

    final availableTypes = ['general', 'urgent', 'event', 'holiday'];
    String selectedType = announcement['type']?.toString().toLowerCase() == 'annoucement'
        ? 'general'
        : (announcement['type'] ?? 'general');

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Announcement'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.7,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 16),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
              const SizedBox(height: 16),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Attachments', style: TextStyle(fontWeight: FontWeight.bold))
              ),
              const SizedBox(height: 8),

              Obx(() {
                final currentAnn = controller.announcements.firstWhere(
                        (a) => a['_id'] == announcementId,
                    orElse: () => announcement
                );
                final attachments = currentAnn['attachments'] as List? ?? [];

                if (attachments.isEmpty) {
                  return const Text('No images attached', style: TextStyle(color: Colors.grey, fontSize: 12));
                }

                return SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: attachments.length,
                    itemBuilder: (context, index) {
                      final attr = attachments[index];
                      final isPdf = attr['type'] == 'pdf' || attr['url'].toString().endsWith('.pdf');

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            onTap: () => isPdf ? _openPdf(attr['url']) : _viewFullImage(url: attr['url']),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: isPdf
                                    ? const Icon(Icons.picture_as_pdf, size: 40, color: Colors.red)
                                    : Image.network(attr['url'], fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          Positioned(
                            top: -10,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red, size: 24),
                              onPressed: () async {
                                final confirmed = await Get.dialog<bool>(
                                  AlertDialog(
                                    title: const Text('Delete Attachment'),
                                    content: Text('Are you sure you want to delete "${attr['originalName'] ?? 'this attachment'}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Get.back(result: false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Get.back(result: true),
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  Get.dialog(
                                    AlertDialog(
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircularProgressIndicator(),
                                          const SizedBox(height: 16),
                                          const Text('Deleting attachment...'),
                                        ],
                                      ),
                                    ),
                                    barrierDismissible: false,
                                  );

                                  try {
                                    final success = await controller.deleteAttachment(announcementId, attr['_id']);
                                    Navigator.pop(Get.context!);

                                    if (success) {
                                      Navigator.pop(Get.context!);
                                      Get.snackbar('Success', 'Attachment deleted successfully',backgroundColor: AppTheme.successGreen,colorText: Colors.white);

                                    }
                                  } catch (e) {
                                    Navigator.pop(Get.context!);
                                    Get.snackbar('Error', 'Failed to delete attachment',backgroundColor: AppTheme.errorRed,colorText: Colors.white);
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              }),

              const SizedBox(height: 16),
              Obx(() => ElevatedButton.icon(
                onPressed: controller.isLoading.value ? null : () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null && result.files.single.path != null) {
                    Get.dialog(
                      Obx(() {
                        final progress = controller.uploadProgress.value;
                        return AlertDialog(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(value: progress > 0 ? progress : null),
                              const SizedBox(height: 16),
                              Text(progress > 0
                                  ? 'Uploading: ${(progress * 100).toStringAsFixed(0)}%'
                                  : 'Preparing upload...'),
                            ],
                          ),
                        );
                      }),
                      barrierDismissible: false,
                    );

                    try {
                      final success = await controller.addAttachment(announcementId, [result.files.single.path!]);
                      
                      if (Get.isDialogOpen == true) {
                        Navigator.pop(Get.context!);
                      }
                      
                      if (success) {
                        await Future.delayed(const Duration(milliseconds: 100));
                        if (Get.isDialogOpen == true) {
                          Navigator.pop(Get.context!);
                        }
                      }
                    } catch (e) {
                      if (Get.isDialogOpen == true) {
                        Navigator.pop(Get.context!);
                      }
                      Get.snackbar('Error', 'Failed to upload attachment');
                    }
                  }
                },
                icon: controller.isLoading.value
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add_a_photo),
                label: Text(controller.isLoading.value ? 'Uploading...' : 'Add Image'),
              )),
            ],
          ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final success = await controller.updateAnnouncement(
                id: announcementId,
                academicYear: announcement['academicYear'] ?? AcademicYearUtils.getCurrentAcademicYear(),
                title: titleController.text.trim(),
                description: descriptionController.text.trim(),
                type: selectedType,
                priority: announcement['priority'] ?? 'normal',
                targetAudience: List<String>.from(announcement['targetAudience'] ?? ['all']),
              );
              if (success) {
                Navigator.pop(Get.overlayContext!);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AnnouncementController controller, String id) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text('Are you sure you want to delete this announcement?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteAnnouncement(id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPdf(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('Notice', 'No application found to open this PDF.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not open the document.');
    }
  }

  void _viewFullImage({String? url, File? file}) {
    Get.dialog(
      Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: PhotoView(
                imageProvider: file != null ? FileImage(file) : NetworkImage(url!) as ImageProvider,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Get.back(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
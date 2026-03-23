import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:collection/collection.dart';
import 'package:school_app/controllers/clubs_controller.dart';
import 'package:school_app/widgets/clubs_dialogue_in_students_tab.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/student_record_controller.dart';
import 'package:school_app/controllers/user_management_controller.dart';
import 'package:school_app/controllers/student_management_controller.dart';
import 'package:school_app/controllers/attendance_controller.dart' as old_attendance;
import 'package:school_app/controllers/fee_structure_controller.dart';
import 'package:school_app/controllers/club_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/widgets/responsive_wrapper.dart';
import 'package:school_app/widgets/gradient_card.dart';
import 'package:school_app/widgets/api_rbac_wrapper.dart';
import 'package:school_app/widgets/school_logo_helper.dart';
import 'package:school_app/core/utils/class_utils.dart';
import 'package:school_app/core/rbac/api_rbac.dart';
import 'package:school_app/core/extensions/widget_extensions.dart';
import 'package:school_app/models/school_models.dart';
import 'package:school_app/models/student_model.dart';
import 'package:school_app/models/club_model.dart';

import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/widgets/fee_structure_widgets.dart';
import 'package:school_app/screens/student_form_page.dart';
import 'package:school_app/screens/student_individual_detail_view.dart';
import 'package:school_app/screens/user_detail_view.dart';

import 'package:school_app/screens/teacher_assignment_view.dart';

class SchoolManagementView extends GetView<SchoolController> {
  SchoolManagementView({super.key});
  final userController = Get.put(UserManagementController());

  void _initializeSchoolForUser() {
    final authController = Get.find<AuthController>();
    final userRole = authController.user.value?.role?.toLowerCase() ?? '';
    final userSchoolId = authController.user.value?.schoolId;

    if (userSchoolId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final userSchool = controller.schools.firstWhereOrNull(
              (school) => school.id == userSchoolId,
        );
        if (userSchool != null) {
          controller.selectedSchool.value = userSchool;
        } else {
          controller.getAllSchools().then((_) {
            final school = controller.schools.firstWhereOrNull(
                  (s) => s.id == userSchoolId,
            );
            if (school != null) {
              controller.selectedSchool.value = school;
            }
          });
        }
      });
    }
  }

  // User permissions
  bool canCreateUser(String role) => role == 'correspondent';
  bool canDeleteUser(String role) => role == 'correspondent';
  bool canEditUser(String role) => [
    'correspondent', 'teacher', 'principal', 'administrator', 'viceprincipal'
  ].contains(role);
  bool canAssignRole(String role) => ['correspondent', 'administrator'].contains(role);

  // School permissions
  bool canCreateSchool(String role) => role == 'correspondent';
  bool canEditSchool(String role) => role == 'correspondent';
  bool canDeleteSchool(String role) => role == 'correspondent';
  bool canUpdateSchoolLogo(String role) => role == 'correspondent';

  // Class permissions
  bool canCreateClass(String role) => ['correspondent', 'administrator'].contains(role);
  bool canEditClass(String role) => ['correspondent', 'administrator'].contains(role);
  bool canDeleteClass(String role) => ['correspondent', 'administrator'].contains(role);

  // Section permissions
  bool canCreateSection(String role) => ['correspondent', 'administrator'].contains(role);
  bool canEditSection(String role) => ['correspondent', 'administrator'].contains(role);
  bool canDeleteSection(String role) => role == 'correspondent';

  // Student permissions
  bool canCreateStudent(String role) => ['correspondent', 'administrator', 'accountant'].contains(role);
  bool canEditStudent(String role) => ['correspondent', 'administrator', 'accountant'].contains(role);
  bool canDeleteStudent(String role) => role == 'correspondent';

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'correspondent':
        return Icons.admin_panel_settings;
      case 'teacher':
        return Icons.school;
      case 'principal':
        return Icons.account_balance;
      case 'viceprincipal':
        return Icons.supervisor_account;
      case 'administrator':
        return Icons.settings;
      case 'accountant':
        return Icons.calculate;
      case 'parent':
        return Icons.family_restroom;
      default:
        return Icons.person;
    }
  }

  int get initialTab {
    final tabParam = Get.parameters['initialTab'] ?? Get.arguments?['initialTab'];
    if (tabParam == null) return 0;

    // Handle named tabs - convert to lowercase for comparison
    final tabName = tabParam.toString().toLowerCase();
    final tabs = availableTabs;
    
    // Find tab by name (case-insensitive)
    final tabIndex = tabs.indexWhere((tab) => 
      (tab['title'] as String).toLowerCase() == tabName
    );
    
    if (tabIndex >= 0) return tabIndex;

    // Fallback: Handle numeric tabs
    return int.tryParse(tabParam.toString()) ?? 0;
  }

  // Get the adjusted initial tab index based on available tabs
  int getAdjustedInitialTab(List<Map<String, dynamic>> tabs) {
    if (tabs.isEmpty) return 0;

    // If no specific tab requested, return 0
    if (initialTab == 0) return 0;

    // Try to find the requested tab in available tabs
    // For now, just ensure the index is within bounds
    return initialTab < tabs.length ? initialTab : 0;
  }

  // Define tab configurations with their permission requirements
  List<Map<String, dynamic>> get availableTabs {
    final authController = Get.find<AuthController>();
    final currentUserRole = authController.user.value?.role?.toLowerCase() ?? '';

    final allTabs = [
      // Schools tab - API-based permission check
      if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/school/create') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/school/update') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/school/delete') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/school/updatelogo'))
        {'title': 'Schools', 'icon': Icons.school, 'builder': _buildSchoolsTab},

      // Classes tab - API-based permission check
      if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/class/create') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/class/update') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/class/delete'))
        {'title': 'Classes', 'icon': Icons.class_, 'builder': _buildClassesTab},

      // Sections tab - API-based permission check
      if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/section/create') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/section/update') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/section/delete'))
        {'title': 'Sections', 'icon': Icons.group, 'builder': _buildSectionsTab},

      // Students tab - API-based permission check
      if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/student/create') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/student/update') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/student/delete'))
        {'title': 'Students', 'icon': Icons.people, 'builder': _buildStudentsTab},

      // Users tab - Make visible for everyone who can create users
      if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/user/create'))
        {'title': 'Users', 'icon': Icons.person, 'builder': _buildUsersTab},

      // Teacher Assign tab - API-based permission check
      if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/teacher/assignments/manage'))
        {'title': 'Teachers', 'icon': Icons.assignment_ind, 'builder': _buildTeacherAssignmentTab},

      // Fee Structure tab - API-based permission check (show if user can view or save fee structure)
      if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/feestructure/set') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/feestructure/getbyclass'))
        {'title': 'Fees', 'icon': Icons.payment, 'builder': _buildFeeStructureTab},

      // Attendance tab - API-based permission check
      if (ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/attendance/sheet') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/attendance/mark') ||
          ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/attendance/getallclass'))
        {'title': 'Attendance', 'icon': Icons.how_to_reg, 'builder': _buildAttendanceTab},
    ];

    return allTabs;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getAllSchools();
      _initializeSchoolForUser();
    });

    final tabs = availableTabs;

    // If no tabs available, show a message
    if (tabs.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Management Access',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No management options available for your role',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.8),
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

    final adjustedInitialTab = getAdjustedInitialTab(tabs);

    return DefaultTabController(
      length: tabs.length,
      initialIndex: adjustedInitialTab,
      child: Scaffold(
        backgroundColor: AppTheme.appBackground,
        body: SafeArea(
          child: Column(
            children: [
              // Custom App Bar with Gradient
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.dividerColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Obx(() {
                            final school = controller.selectedSchool.value;
                            if (school?.logo != null && school!.logo!['url'] != null) {
                              return CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: NetworkImage(school.logo!['url']),
                                onBackgroundImageError: (_, __) {},
                                child: school.logo == null
                                    ? const Icon(Icons.school, color: Colors.white)
                                    : null,
                              );
                            }
                            return const Icon(
                              Icons.school,
                              color: AppTheme.primaryBlue,
                              size: 28,
                            );
                          }),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Obx(() {
                                  final school = controller.selectedSchool.value;
                                  return Text(
                                    school?.name ?? 'School Management',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: AppTheme.primaryText,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }),

                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Custom Tab Bar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.appBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TabBar(
                        isScrollable: true,
                        indicator: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelColor: AppTheme.titleOnGradient,
                        unselectedLabelColor: AppTheme.mutedText,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        tabs: tabs.map((tab) => Tab(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(tab['icon'] as IconData, size: 18),
                                const SizedBox(width: 8),
                                Text(tab['title'] as String,style: TextStyle(color:Colors.black)),
                              ],
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              // Tab Content
              Expanded(
                child: ResponsiveWrapper(
                  child: TabBarView(
                    children: tabs.map((tab) => (tab['builder'] as Widget Function())()).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildFeeStructureTab() {
    final authController = Get.find<AuthController>();
    final currentUserRole = authController.user.value?.role?.toLowerCase() ?? '';
    final canSetFeeStructure = ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/feestructure/set');

    return DefaultTabController(
      length: canSetFeeStructure ? 2 : 1,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payment, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Fee Structure Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Tab Bar - conditional based on permissions
              if (canSetFeeStructure)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.appBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.mutedText,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 18),
                            SizedBox(width: 8),
                            Text('Set Fee Structure'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.list, size: 18),
                            SizedBox(width: 8),
                            Text('All Fee Structures'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              // Tab Content
              SizedBox(
                height: 600,
                child: canSetFeeStructure
                    ? TabBarView(
                  children: [
                    _FeeStructureTab(),
                    AllFeeStructuresTab(),
                  ],
                )
                    : AllFeeStructuresTab(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return SingleChildScrollView(
      child: _AttendanceTab(),
    );
  }

  Widget _buildSchoolsTab() {
    final authController = Get.find<AuthController>();
    final currentUserRole = authController.user.value?.role?.toLowerCase() ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshSchools,
          color: const Color(0xFF667eea),
          child: controller.schools.isEmpty
              ? _buildEmptyState(
            icon: Icons.school,
            title: 'No Schools Found',
            subtitle: 'Create your first school to get started',
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.schools.length,
            itemBuilder: (context, index) {
              final school = controller.schools[index];
              return _buildSchoolCard(school, currentUserRole, index);
            },
          ),
        );
      }),
      floatingActionButton: ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/school/create')
          ? _buildFloatingActionButton(
        onPressed: () => Get.toNamed('/create-school'),
        icon: Icons.add,
        label: 'Add School',
      )
          : null,
    );
  }

  Widget _buildSchoolCard(School school, String currentUserRole, int index) {
    final softGradients = [
      AppTheme.geographySoftGradient,
      AppTheme.mathSoftGradient,
      AppTheme.biologySoftGradient,
      AppTheme.chemistrySoftGradient,
    ];

    final accentColors = [
      AppTheme.geographyBlue,
      AppTheme.mathOrange,
      AppTheme.biologyGreen,
      AppTheme.chemistryYellow,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: softGradients[index % 4],
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: [
          BoxShadow(
            color: accentColors[index % 4].withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: () => controller.getSchool(school.id),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: accentColors[index % 4].withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: school.logo != null && school.logo!['url'] != null && school.logo!['url']!.isNotEmpty
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          school.logo!['url']!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.school,
                              color: accentColors[index % 4],
                              size: 32,
                            );
                          },
                        ),
                      )
                          : Icon(
                        Icons.school,
                        color: accentColors[index % 4],
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            school.name,
                            style: const TextStyle(
                              color: AppTheme.titleOnWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (school.schoolCode != null)
                            Text(
                              'Code: ${school.schoolCode}',
                              style: const TextStyle(
                                color: AppTheme.subtitleOnWhite,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: accentColors[index % 4]),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      itemBuilder: (context) => [
                        if (ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/school/update'))
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                        if (ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/school/updatelogo'))
                          const PopupMenuItem(
                            value: 'logo',
                            child: Row(
                              children: [
                                Icon(Icons.image, size: 18),
                                SizedBox(width: 8),
                                Text('Update Logo'),
                              ],
                            ),
                          ),
                        if (ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/school/delete'))
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          controller.showEditSchoolDialog(school);
                        } else if (value == 'logo') {
                          controller.pickAndUploadLogo(school.id);
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(school);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSchoolInfoGrid(school),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolInfoGrid(School school) {
    final infoItems = [
      if (school.email != null) {'icon': Icons.email, 'label': 'Email', 'value': school.email!},
      if (school.phoneNo != null) {'icon': Icons.phone, 'label': 'Phone', 'value': school.phoneNo!},
      if (school.currentAcademicYear != null) {'icon': Icons.calendar_today, 'label': 'Academic Year', 'value': school.currentAcademicYear!},
      if (school.address != null) {'icon': Icons.location_on, 'label': 'Address', 'value': school.address!},
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: infoItems.map((item) => _buildInfoChip(
        item['icon'] as IconData,
        item['label'] as String,
        item['value'] as String,
      )).toList(),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryBlue),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.subtitleOnWhite,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: AppTheme.primaryBlue,
      foregroundColor: AppTheme.titleOnGradient,
      elevation: 4,
      icon: Icon(icon),
      label: Text(label),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildClassesTab() {
    final authController = Get.find<AuthController>();
    final currentUserRole = authController.user.value?.role?.toLowerCase() ?? '';
    final isCorrespondent = currentUserRole == 'correspondent';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.schools.isEmpty) {
        controller.getAllSchools();
      }
      if (controller.selectedSchool.value != null) {
        controller.getAllClasses(controller.selectedSchool.value!.id);
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // School Selector
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
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
            child: Obx(() {
              if (controller.schools.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final selectedSchool = controller.schools.contains(controller.selectedSchool.value)
                  ? controller.selectedSchool.value
                  : null;

              // Show dropdown only for correspondent, readonly for others
              if (isCorrespondent) {
                return DropdownButtonFormField<School>(
                  isExpanded: true,
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
                  value: selectedSchool,
                  selectedItemBuilder: (context) {
                    return controller.schools.map((school) {
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
                  items: controller.schools.map((school) {
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
                            Expanded(
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
                  onChanged: (School? school) {
                    controller.selectedSchool.value = school;
                    if (school != null) {
                      controller.getAllClasses(school.id);
                    } else {
                      controller.classes.clear();
                    }
                  },
                );
              } else {
                // Readonly display for non-correspondent users - auto-load classes
                if (controller.selectedSchool.value != null && controller.classes.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    controller.getAllClasses(controller.selectedSchool.value!.id);
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
                          controller.selectedSchool.value?.name ?? 'Loading...',
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
          ),

          // Add Class Button
          if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/class/create'))
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showCreateClassDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Class'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          // Classes List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.classes.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.class_,
                  title: 'No Classes Found',
                  subtitle: 'Add classes to organize your students',
                );
              }

              // Sort classes using ClassUtils
              final sortedClasses = ClassUtils.sortClasses(controller.classes);
              
              

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sortedClasses.length,
                itemBuilder: (context, index) {
                  final schoolClass = sortedClasses[index];
                  return _buildClassCard(schoolClass, currentUserRole, index);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(SchoolClass schoolClass, String currentUserRole, int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Handle class tap
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors[index % 4].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.class_,
                    color: colors[index % 4],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schoolClass.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                    ],
                  ),
                ),

                if (schoolClass.hasSections)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Has Sections',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (context) => [
                    if (ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/class/update'))
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    if (ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/class/delete'))
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditClassDialog(schoolClass);
                    } else if (value == 'delete') {
                      controller.deleteClass(schoolClass.id).then((_) {
                        if (controller.selectedSchool.value != null) {
                          controller.getAllClasses(controller.selectedSchool.value!.id);
                        }
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionsTab() {
    final authController = Get.find<AuthController>();
    final currentUserRole = authController.user.value?.role?.toLowerCase() ?? '';
    final isCorrespondent = currentUserRole == 'correspondent';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.schools.isEmpty) {
        controller.getAllSchools();
      }
      if (controller.selectedSchool.value != null) {
        controller.getAllSections(schoolId: controller.selectedSchool.value!.id);
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // School selector
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
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
            child: Obx(() {
              if (controller.schools.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (isCorrespondent) {
                return DropdownButtonFormField<School>(
                  isExpanded: true,
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
                  value: controller.selectedSchool.value,
                  selectedItemBuilder: (context) {
                    return controller.schools.map((school) {
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
                  items: controller.schools.isEmpty ? [] : controller.schools.map<DropdownMenuItem<School>>((school) {
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
                            Text(
                              school.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (School? school) {
                    controller.selectedSchool.value = school;
                    if (school != null) {
                      controller.getAllSections(schoolId: school.id);
                    }
                  },
                );
              } else {
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
                          controller.selectedSchool.value?.name ?? 'Loading...',
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
          ),

          // Add Section Button
          if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/section/create'))
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCreateSectionDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Section'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          // Sections list with modern cards
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF667eea)));
              }

              if (controller.sections.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.group,
                  title: 'No Sections Found',
                  subtitle: 'Add sections to organize classes better',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.sections.length,
                itemBuilder: (context, index) {
                  final section = controller.sections[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showSectionDetailsDialog(context, section),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.chemistryYellow.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.group, color: AppTheme.chemistryYellow, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      section.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Class: ${section.className ?? "N/A"}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Room: ${section.roomNumber ?? "N/A"}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (section.classTeachers != null && section.classTeachers!.isNotEmpty)
                                      Text(
                                        'Teachers: ${section.classTeachers!.map((t) => t['userName'] ?? 'Unknown').join(', ')}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                  if (ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/section/update'))
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 18),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                  if (ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/section/delete'))
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 18, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                ],
                                onSelected: (value) {
                                  if (value == 'view') {
                                    _showSectionDetailsDialog(context, section);
                                  } else if (value == 'edit') {
                                    _showEditSectionDialog(section);
                                  } else if (value == 'delete') {
                                    controller.deleteSection(section.id).then((_) {
                                      if (controller.selectedSchool.value != null) {
                                        controller.getAllSections(schoolId: controller.selectedSchool.value!.id);
                                      }
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsTab() {
    final authController = Get.find<AuthController>();
    final currentUserRole = authController.user.value?.role?.toLowerCase() ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.selectedSchool.value != null) {
        controller.getAllStudents(schoolId: controller.selectedSchool.value!.id);
      }
    });

    final selectedClass = Rxn<SchoolClass>();
    final selectedSection = Rxn<Section>();
    final isFiltersExpanded = true.obs;
    final clubsController = Get.put(ClubController());
    final clubController = Get.put(ClubsController());

    final canManageClubs = ['correspondent', 'administrator'].contains(currentUserRole);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Collapsible Filters Container
          Obx(() {
            final hasSelections = controller.selectedSchool.value != null;
            final isExpanded = !hasSelections || isFiltersExpanded.value;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isExpanded ? null : 60,
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
              child: isExpanded
                  ? _buildFullStudentFilters(selectedClass, selectedSection, isFiltersExpanded)
                  : _buildCompactStudentFilters(selectedClass, selectedSection, isFiltersExpanded),
            );
          }),

          // Add Student Button
          if (ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/student/create'))
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCreateStudentDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Student'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          // Bulk club button
          if (canManageClubs)
            Obx(() {
              final students = controller.students;
              // Show button when there are students, regardless of class selection
              return students.isNotEmpty
                  ? Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: () {
                    final studentsToShow = students.toList();
                    if (studentsToShow.isEmpty) return;

                    // Group students by class for bulk assignment
                    final studentsByClass = <String, List<Student>>{};
                    for (final student in studentsToShow) {
                      final classId = student.classId ?? '';
                      if (classId.isNotEmpty) {
                        studentsByClass.putIfAbsent(classId, () => []).add(student);
                      }
                    }

                    if (studentsByClass.isEmpty) {
                      Get.snackbar('Error', 'No students with valid class information');
                      return;
                    }

                    // If multiple classes, show selection dialog
                    if (studentsByClass.length > 1) {
                      _showClassSelectionForBulkClub(studentsByClass);
                    } else {
                      // Single class - proceed directly
                      final classId = studentsByClass.keys.first;
                      final classObj = controller.classes.firstWhereOrNull((c) => c.id == classId);
                      if (classObj != null) {
                        _showBulkClubDialog(studentsByClass[classId]!, classObj);
                      }
                    }
                  },
                  icon: const Icon(Icons.group_add, size: 18),
                  label: Text('Add ${students.length} students to clubs'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              )
                  : const SizedBox.shrink();
            }),


          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF667eea)),
                );
              }

              // Show students regardless of class selection
              final studentsToShow = controller.students;
              

              if (studentsToShow.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.people,
                  title: 'No Students Found',
                  subtitle: controller.selectedSchool.value == null
                      ? 'Please select a school to view students'
                      : 'No students found',
                );
              }

              // Sort students alphabetically by name
              final sortedStudents = List<Student>.from(studentsToShow);
              sortedStudents.sort((a, b) {
                final aName = (a.name ?? '').toLowerCase();
                final bName = (b.name ?? '').toLowerCase();
                return aName.compareTo(bName);
              });

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: sortedStudents.length,
                itemBuilder: (context, index) {
                  final student = sortedStudents[index];
                  final className = selectedClass.value?.name ?? 'N/A';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.person,
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
                                      student.name ?? 'N/A',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      (student.rollNumber == null || student.rollNumber!.trim().isEmpty)
                                          ? 'N/A'
                                          : student.rollNumber!,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // + Club button - only show for correspondent/administrator
                              if (canManageClubs)
                                SizedBox(
                                  width: 80,
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // Use student's classId to find the class object
                                        final studentClassId = student.classId;
                                        if (studentClassId == null || studentClassId.isEmpty) {
                                          Get.snackbar('Error', 'Student has no class assigned');
                                          return;
                                        }
                                        final studentClass = controller.classes.firstWhereOrNull(
                                                (c) => c.id == studentClassId
                                        );
                                        if (studentClass == null) {
                                          Get.snackbar('Error', 'Student class not found');
                                          return;
                                        }
                                        _showStudentClubDialog(student, studentClass);
                                      },

                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('+ Club', style: TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'details',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility, size: 18),
                                        SizedBox(width: 8),
                                        Text('View Details'),
                                      ],
                                    ),
                                  ),
                                  if (ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/student/update'))
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 18),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                  // else if (value == 'assignClub') {
                                  // //                                   _showAssignClubToStudentDialog(student);
                                  // //                                 } else if (value == 'removeClub') {
                                  // //                                   _showRemoveClubFromStudentDialog(student);
                                  // //                                 }
                                  if(ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/club/addtoclub'))
                                    const PopupMenuItem(
                                        value: 'assignClub',
                                        child: Row(
                                            children:[
                                              Icon(Icons.add,size:18,color:Colors.green),
                                              SizedBox(width:8),
                                              Text('Assign Club')
                                            ]
                                        )
                                    ),
                                  if(ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/club/removefromclub'))
                                    const PopupMenuItem(
                                        value: 'removeClub',
                                        child: Row(
                                            children:[
                                              Icon(Icons.remove_circle,size:18,color:Colors.red),
                                              SizedBox(width:8),
                                              Text('Remove Club')
                                            ]
                                        )
                                    ),
                                  if (ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/student/delete'))
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 18, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                ],
                                onSelected: (value) {
                                  if (value == 'details') {
                                    Get.to(() => StudentIndividualDetailView(
                                      student: student,
                                      schoolId: controller.selectedSchool.value!.id,
                                    ))?.then((_) {
                                      if (controller.selectedSchool.value != null) {
                                        controller.getAllStudents(schoolId: controller.selectedSchool.value!.id);
                                      }
                                    });
                                  }
                                  else if (value == 'assignClub') {
                                    _showAssignClubToStudentDialog(student);
                                  } else if (value == 'removeClub') {
                                    _showRemoveClubFromStudentDialog(student);
                                  }
                                  else if (value == 'edit') {
                                    _showEditStudentDialog(student);
                                  } else if (value == 'delete') {
                                    _showDeleteStudentConfirmation(student);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }


  Widget _buildCompactStudentFilters(Rxn<SchoolClass> selectedClass, Rxn<Section> selectedSection, RxBool isFiltersExpanded) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.school, color: AppTheme.primaryBlue, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              controller.selectedSchool.value?.name ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (selectedClass.value != null) ...[
            const SizedBox(width: 12),
            Icon(Icons.class_, color: AppTheme.primaryBlue, size: 18),
            const SizedBox(width: 6),
            Text(
              selectedClass.value!.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
          if (selectedSection.value != null) ...[
            const SizedBox(width: 12),
            Icon(Icons.group, color: AppTheme.primaryBlue, size: 18),
            const SizedBox(width: 6),
            Text(
              selectedSection.value!.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
          const Spacer(),
          IconButton(
            onPressed: () => isFiltersExpanded.value = true,
            icon: const Icon(Icons.expand_more, size: 18),
            tooltip: 'Expand Filters',
          ),
        ],
      ),
    );
  }

  void _showClassSelectionForBulkClub(Map<String, List<Student>> studentsByClass) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: studentsByClass.entries.map((entry) {
            final classId = entry.key;
            final students = entry.value;
            final classObj = controller.classes.firstWhereOrNull((c) => c.id == classId);
            final className = classObj?.name ?? 'Unknown Class';

            return ListTile(
              title: Text(className),
              subtitle: Text('${students.length} students'),
              onTap: () {
                Get.back();
                if (classObj != null) {
                  _showBulkClubDialog(students, classObj);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showStudentClubDialog(Student student, SchoolClass? selectedClass) {
    if (selectedClass == null) {
      Get.snackbar('Error', 'Please select a class first');
      return;
    }

    final clubController = Get.find<ClubController>();
    final clubsController = Get.put(ClubsController());

    final availableClubs = <Club>[].obs;
    final dialogLoading = false.obs;

    availableClubs.value = clubsController.getClubsByClass(selectedClass.id);

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GradientDialog(
          header: dialogHeader(
            title: 'Club Management',
            subtitle: '${student.name ?? 'N/A'} • ${selectedClass.name}',
            icon: Icons.sports_soccer,
          ),

          // ---------- BODY ----------
          body: Obx(() {
            if (availableClubs.isEmpty) {
              return const Center(
                child: Text(
                  'No clubs available for this class',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: availableClubs.length,
              itemBuilder: (_, index) {
                final club = availableClubs[index];
                final isSelected =
                    student.clubs?.contains(club.id) ?? false;

                return clubTile(
                  name: club.name,
                  description: club.description,
                  selected: isSelected,
                  onTap: dialogLoading.value
                      ? () {}
                      : () async {
                    try {
                      dialogLoading.value = true;

                      if (!isSelected) {
                        await clubController.addStudentToClub(
                            club.id, student.id);
                        student.clubs ??= [];
                        student.clubs!.add(club.id);
                      } else {
                        await clubController.removeStudentFromClub(
                            club.id, student.id);
                        student.clubs?.remove(club.id);
                      }

                      availableClubs.refresh();
                    } catch (e) {
                      Get.snackbar(
                        'Error',
                        'Failed to update club',
                        backgroundColor: Colors.red.shade400,
                        colorText: Colors.white,
                      );
                      
                    } finally {
                      dialogLoading.value = false;
                    }
                  },
                );
              },
            );
          }),

          // ---------- FOOTER ----------
          footer: Obx(() => dialogFooter(
            loading: dialogLoading.value,
            onCancel: () => Get.back(),
            onSave: () async {
              Get.back();
              Get.snackbar(
                'Success',
                'Club assignments updated',
                backgroundColor: const Color(0xFF38EF7D),
                colorText: Colors.white,
              );

              if (controller.selectedSchool.value != null) {
                await controller.getAllStudents(
                  schoolId: controller.selectedSchool.value!.id,
                );
              }
            },
          )),
        ),
      ),
      barrierDismissible: false,
    );
  }
  void _showBulkClubDialog(List<Student> students, SchoolClass selectedClass) {
    final clubController = Get.find<ClubController>();

    final availableClubs = <Map<String, dynamic>>[].obs;
    final isLoading = true.obs;
    final dialogLoading = false.obs;

    clubController.getClubsByClass(selectedClass.id).then((_) {
      availableClubs.assignAll(clubController.clubs);
      isLoading.value = false;
    }).catchError((_) {
      isLoading.value = false;
    });

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GradientDialog(
          header: dialogHeader(
            title: 'Bulk Club Assignment',
            subtitle:
            '${selectedClass.name} • ${students.length} students',
            icon: Icons.group_add,
          ),

          // ---------- BODY ----------
          body: Obx(() {
            if (isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (availableClubs.isEmpty) {
              return const Center(
                child: Text(
                  'No clubs available',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: availableClubs.length,
              itemBuilder: (_, index) {
                final club = availableClubs[index];
                final clubId = club['_id']; // Fixed: use '_id' instead of 'id'

                final allStudentsInClub = students.every(
                      (s) => s.clubs?.contains(clubId) ?? false,
                );

                return clubTile(
                  name: club['name'],
                  description: club['description'] ?? '',
                  selected: allStudentsInClub,
                  onTap: dialogLoading.value
                      ? () {}
                      : () async {
                    try {
                      dialogLoading.value = true;

                      final studentIds =
                      students.map((s) => s.id).toList();

                      await clubController.toggleStudentsInClub(
                        clubId,
                        studentIds,
                        !allStudentsInClub,
                        classId: selectedClass.id,
                      );

                      for (final student in students) {
                        student.clubs ??= [];
                        if (!allStudentsInClub) {
                          student.clubs!.add(clubId);
                        } else {
                          student.clubs!.remove(clubId);
                        }
                      }

                      availableClubs.refresh();
                    } catch (e) {
                      Get.snackbar(
                        'Error',
                        'Failed to update clubs',
                        backgroundColor: Colors.red.shade400,
                        colorText: Colors.white,
                      );
                      
                    } finally {

                      dialogLoading.value = false;
                    }
                  },
                );
              },
            );
          }),

          // ---------- FOOTER ----------
          footer: Obx(() => dialogFooter(
            loading: dialogLoading.value,
            onCancel: () => Get.back(),
            onSave: () async {
              Navigator.pop(Get.context!);
              Get.snackbar(
                'Success',
                'Bulk club assignment completed',
                backgroundColor: const Color(0xFF38EF7D),
                colorText: Colors.white,
              );

              if (controller.selectedSchool.value != null) {
                await controller.getAllStudents(
                  schoolId: controller.selectedSchool.value!.id,
                );
              }
            },
          )),
        ),
      ),
      barrierDismissible: false,
    );
  }


  Widget _buildFullStudentFilters(Rxn<SchoolClass> selectedClass, Rxn<Section> selectedSection, RxBool isFiltersExpanded) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header with collapse button
          Row(
            children: [
              Icon(Icons.filter_list, color: AppTheme.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Filters',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const Spacer(),
              if (controller.selectedSchool.value != null)
                IconButton(
                  onPressed: () => isFiltersExpanded.value = false,
                  icon: const Icon(Icons.expand_less, size: 20),
                  tooltip: 'Collapse Filters',
                ),
            ],
          ),
          const SizedBox(height: 16),

          // School Dropdown
          Obx(() {
            final authController = Get.find<AuthController>();
            final currentUserRole = authController.user.value?.role?.toLowerCase() ?? '';
            final isCorrespondent = currentUserRole == 'correspondent';

            if (isCorrespondent) {
              return DropdownButtonFormField<School>(
                isExpanded: true,
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
                value: controller.selectedSchool.value,
                selectedItemBuilder: (context) {
                  return controller.schools.map((school) {
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
                items: controller.schools.map((school) {
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
                          Expanded(
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
                onChanged: (School? school) {
                  controller.selectedSchool.value = school;
                  selectedClass.value = null;
                  selectedSection.value = null;
                  if (school != null) {
                    controller.getAllClasses(school.id);
                  }
                },
              );
            } else {
              // Readonly display for non-correspondent users - auto-load sections
              if (controller.selectedSchool.value != null && controller.sections.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.getAllSections(schoolId: controller.selectedSchool.value!.id);
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
                        controller.selectedSchool.value?.name ?? 'Loading...',
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

          const SizedBox(height: 12),

          // Class Dropdown
          Obx(() {
            final sortedClasses = ClassUtils.sortClasses(controller.classes);
            final uniqueClasses = <SchoolClass>[];
            final seenIds = <String>{};
            for (final cls in sortedClasses) {
              if (!seenIds.contains(cls.id)) {
                seenIds.add(cls.id);
                uniqueClasses.add(cls);
              }
            }
            
            return DropdownButtonFormField<SchoolClass>(
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Choose Class (Optional)',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.class_, color: AppTheme.primaryBlue, size: 20),
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
              value: selectedClass.value,
              selectedItemBuilder: (context) {
                return [
                  Row(
                    children: [
                      Icon(Icons.all_inclusive, size: 16, color: AppTheme.primaryBlue),
                      const SizedBox(width: 8),
                      const Text('All Classes'),
                    ],
                  ),
                  ...uniqueClasses.map((cls) {
                    return Row(
                      children: [
                        Icon(ClassUtils.getClassIcon(cls.name), size: 16, color: AppTheme.primaryBlue),
                        const SizedBox(width: 8),
                        Text(
                          cls.name,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  }),
                ];
              },
              items: [
                DropdownMenuItem<SchoolClass>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.all_inclusive, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'All Classes',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                ...uniqueClasses.map((cls) {
                  return DropdownMenuItem<SchoolClass>(
                    value: cls,
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
                            child: Icon(ClassUtils.getClassIcon(cls.name), color: AppTheme.primaryBlue, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              cls.name,
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
                }),
              ],
              onChanged: (SchoolClass? cls) {
                selectedClass.value = cls;
                selectedSection.value = null;
                if (cls != null && controller.selectedSchool.value != null) {
                  controller.getAllSections(classId: cls.id, schoolId: controller.selectedSchool.value!.id);
                }
                _loadStudentsByFilters(selectedClass.value, selectedSection.value);
              },
            );
          }),

          const SizedBox(height: 12),

          // Section Dropdown
          Obx(() => DropdownButtonFormField<Section>(
            isExpanded: true,
            decoration: InputDecoration(
              hintText: 'Choose Section (Optional)',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.group, color: AppTheme.primaryBlue, size: 20),
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
            value: selectedSection.value,
            selectedItemBuilder: (context) {
              return [
                Text(
                  'All Sections',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ...controller.sections.map((section) {
                  return Text(
                    section.name,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  );
                }),
              ];
            },
            items: [
              DropdownMenuItem<Section>(
                value: null,
                child: Text(
                  'All Sections',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              ...controller.sections.map((section) {
                return DropdownMenuItem<Section>(
                  value: section,
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
                          child: Icon(Icons.group, color: AppTheme.primaryBlue, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            section.name,
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
              }),
            ],
            onChanged: (Section? section) {
              selectedSection.value = section;
              _loadStudentsByFilters(selectedClass.value, selectedSection.value);
            },
          )),
        ],
      ),
    );
  }

  void _loadStudentsByFilters(SchoolClass? selectedClass, Section? selectedSection) {
    if (controller.selectedSchool.value == null) return;

    print('\n========== FILTER CHANGE ==========');
    print('🏫 School: ${controller.selectedSchool.value!.name}');
    print('📚 Selected Class: ${selectedClass?.name ?? "All Classes"}');
    print('👥 Selected Section: ${selectedSection?.name ?? "All Sections"}');
    print('===================================\n');

    controller.getAllStudents(
      schoolId: controller.selectedSchool.value!.id,
      classId: selectedClass?.id,
      sectionId: selectedSection?.id,
    ).then((_) {
      print('📋 Students loaded: ${controller.students.length}');
    });
  }

  Widget _buildUsersTab() {
    final authController = Get.find<AuthController>();
    final currentUserRole = authController.user.value?.role?.toLowerCase() ?? '';
    final isReadOnly = !['correspondent'].contains(currentUserRole);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // School selector - readonly for non-correspondent users
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 16),
                if (isReadOnly)
                // Show readonly school name for non-correspondent users
                  Obx(() {
                    final userSchoolId = authController.user.value?.schoolId;
                    final userSchool = controller.schools.firstWhereOrNull(
                          (school) => school.id == userSchoolId,
                    );
                    final schoolName = controller.selectedSchool.value?.name ?? userSchool?.name ?? 'Loading...';

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
                // Show dropdown for correspondent users
                  Obx(() => DropdownButtonFormField<School>(
                    isExpanded: true,
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
                    value: controller.selectedSchool.value,
                    selectedItemBuilder: (context) {
                      return controller.schools.map((school) {
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
                    items: controller.schools
                        .map((school) => DropdownMenuItem<School>(
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
                            Text(
                              school.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ))
                        .toList(),
                    onChanged: (school) {
                      controller.selectedSchool.value = school;
                      if (school != null) {
                        userController.loadUsers(
                          schoolId: school.id,
                          role: userController.selectedRole.value,
                        );
                      }
                    },
                  )),
              ],
            ),
          ),

          // Role filter
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(16),
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
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Filter by Role',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.filter_list, color: AppTheme.primaryBlue, size: 20),
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
              value: userController.selectedRole.value,
              selectedItemBuilder: (context) {
                return const [
                  'all',
                  'correspondent',
                  'teacher',
                  'principal',
                  'viceprincipal',
                  'administrator',
                  'accountant',
                  'parent'
                ].map((r) {
                  return Text(
                    r.toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  );
                }).toList();
              },
              items: const [
                'all',
                'correspondent',
                'teacher',
                'principal',
                'viceprincipal',
                'administrator',
                'accountant',
                'parent'
              ].map((r) {
                return DropdownMenuItem<String>(
                  value: r,
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
                          child: Icon(_getRoleIcon(r), color: AppTheme.primaryBlue, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          r.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (role) {
                if (role != null) {
                  userController.selectedRole.value = role;
                  final schoolId = controller.selectedSchool.value?.id ??
                      authController.user.value?.schoolId;
                  if (schoolId != null) {
                    userController.loadUsers(
                      schoolId: schoolId,
                      role: role,
                    );
                  }
                }
              },
            ),
          ),

          // User list
          Expanded(
            child: Obx(() {
              if (userController.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF667eea)));
              }

              if (userController.users.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.person,
                  title: 'No Users Found',
                  subtitle: 'Add users to manage your school',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: userController.users.length,
                itemBuilder: (context, index) {
                  final user = userController.users[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Get.to(() => UserDetailView(user: user));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getRoleIcon(user['role'] ?? 'person'),
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['userName'] ?? 'Unknown',
                                      style: const TextStyle(
                                        color: AppTheme.titleOnWhite,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Role: ${user['role'] ?? 'No Role'}',
                                      style: const TextStyle(color: AppTheme.subtitleOnWhite, fontSize: 14),
                                    ),
                                    Text(
                                      'Email: ${user['email'] ?? 'N/A'}',
                                      style: const TextStyle(color: AppTheme.mutedText, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              // Assign role button - only show for correspondent and administrator
                              if (user['role'] == null &&
                                  ['correspondent', 'administrator'].contains(currentUserRole) &&
                                  ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/user/assignrole'))
                                SizedBox(
                                  width: 100,
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: ElevatedButton(
                                      onPressed: () => _showAssignRoleDialog(user),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryBlue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Assign Role', style: TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                ),
                              // Menu
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: AppTheme.primaryText),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                itemBuilder: (context) => [
                                  if (ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/user/update') && currentUserRole != 'teacher')
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 18),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                  if (ApiPermissions.hasApiAccess(currentUserRole, 'PUT /api/user/assignrole') &&
                                      ['correspondent', 'administrator'].contains(currentUserRole))
                                    const PopupMenuItem(
                                      value: 'role',
                                      child: Row(
                                        children: [
                                          Icon(Icons.admin_panel_settings, size: 18),
                                          SizedBox(width: 8),
                                          Text('Change Role'),
                                        ],
                                      ),
                                    ),
                                  if (ApiPermissions.hasApiAccess(currentUserRole, 'DELETE /api/user/delete'))
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 18, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditUserDialog(user);
                                  } else if (value == 'role') {
                                    _showAssignRoleDialog(user);
                                  } else if (value == 'delete') {
                                    _showDeleteUserDialog(user);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/user/create')
          ? _buildFloatingActionButton(
        onPressed: _showCreateUserDialog,
        icon: Icons.person_add,
        label: 'Add User',
      )
          : null,
    );
  }

  Widget _buildTeacherAssignmentTab() {
    // Load teachers when tab is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.selectedSchool.value != null) {
        print('🏫 Loading teachers for school: ${controller.selectedSchool.value!.name}');
        print('📚 Getting classes assigned for teachers...');
        controller.loadTeachers();
      } else {
        print('⚠️ No school selected for teacher assignment');
      }
    });

    return TeacherAssignmentView();
  }

  Widget _buildAttendanceCard(String title, String percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            percentage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonTab(String title, IconData icon) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF667eea).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: const Color(0xFF667eea),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '$title Management',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF667eea),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enhanced UI coming soon...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog methods remain the same but with improved styling
  void _showDeleteConfirmation(School school) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete School'),
          ],
        ),
        content: Text('Are you sure you want to delete ${school.name}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteSchool(school.id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateClassDialog() {
    if (controller.selectedSchool.value == null) {
      Get.snackbar(
        'Error',
        'Please select a school first',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    final nameController = TextEditingController();
    final orderController = TextEditingController();
    bool hasSections = false;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Create Class'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Class Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Has Sections'),
                  value: hasSections,
                  onChanged: (value) {
                    setState(() {
                      hasSections = value ?? false;
                    });
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.createClass(controller.selectedSchool.value!.id, {
                'name': nameController.text,
                'order': int.tryParse(orderController.text) ?? 0,
                'hasSections': hasSections,
              });
              Get.back();
              if (controller.selectedSchool.value != null) {
                controller.getAllClasses(controller.selectedSchool.value!.id);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditClassDialog(SchoolClass schoolClass) {
    final nameController = TextEditingController(text: schoolClass.name);
    final orderController = TextEditingController(text: schoolClass.order.toString());
    bool hasSections = schoolClass.hasSections;
    final isLoading = false.obs;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Class'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Class Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: orderController,
                  decoration: InputDecoration(
                    labelText: 'Order',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Has Sections'),
                  value: hasSections,
                  onChanged: (value) {
                    setState(() {
                      hasSections = value ?? false;
                    });
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(() => ElevatedButton(
            onPressed: isLoading.value ? null : () async {

              isLoading.value = true;
              try {
                await controller.updateClass(schoolClass.id, {
                  'name': nameController.text,
                  'order': int.tryParse(orderController.text) ?? 0,
                  'hasSections': hasSections,
                });

                Get.back();
                if (controller.selectedSchool.value != null) {
                  controller.getAllClasses(controller.selectedSchool.value!.id);
                }
              } catch (e) {

              } finally {
                isLoading.value = false;
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: isLoading.value
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Text('Update'),
          )),
        ],
      ),
    );
  }

  void _showCreateSectionDialog() {
    if (controller.selectedSchool.value == null) {
      Get.snackbar('Error', 'Please select a school first');
      return;
    }

    final nameController = TextEditingController();
    final roomController = TextEditingController();
    final capacityController = TextEditingController();
    SchoolClass? selectedClass;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Create Section'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<SchoolClass>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Choose Class',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.class_, color: AppTheme.primaryBlue, size: 20),
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
                  value: selectedClass,
                  selectedItemBuilder: (context) {
                    return controller.classes.map((cls) {
                      return Text(
                        cls.name,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      );
                    }).toList();
                  },
                  items: controller.classes.map<DropdownMenuItem<SchoolClass>>((cls) {
                    return DropdownMenuItem<SchoolClass>(
                      value: cls,
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
                              child: Icon(Icons.class_, color: AppTheme.primaryBlue, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              cls.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (SchoolClass? value) {
                    setState(() {
                      selectedClass = value;
                    });
                    if (value != null) {
                      controller.getAllSections(classId: value.id, schoolId: controller.selectedSchool.value!.id);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Section Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: roomController,
                  decoration: InputDecoration(
                    labelText: 'Room Number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: capacityController,
                  decoration: InputDecoration(
                    labelText: 'Capacity',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedClass != null) {
                controller.createSection({
                  'schoolId': controller.selectedSchool.value!.id,
                  'classId': selectedClass!.id,
                  'name': nameController.text,
                  'roomNumber': roomController.text,
                  'capacity': int.tryParse(capacityController.text),
                });
                Get.back();
                controller.getAllSections(schoolId: controller.selectedSchool.value!.id);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditSectionDialog(Section section) {
    final nameController = TextEditingController(text: section.name);
    final roomController = TextEditingController(text: section.roomNumber);
    final capacityController = TextEditingController(text: section.capacity?.toString());
    final isLoading = false.obs;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Section'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Section Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: roomController,
              decoration: InputDecoration(
                labelText: 'Room Number',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: capacityController,
              decoration: InputDecoration(
                labelText: 'Capacity',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(() => ElevatedButton(
            onPressed: isLoading.value ? null : () async {

              isLoading.value = true;
              try {
                await controller.updateSection(section.id, {
                  'name': nameController.text,
                  'roomNumber': roomController.text,
                  'capacity': int.tryParse(capacityController.text),
                });

                Get.back();
                if (controller.selectedSchool.value != null) {
                  controller.getAllSections(schoolId: controller.selectedSchool.value!.id);
                }
              } catch (e) {

              } finally {
                isLoading.value = false;
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: isLoading.value
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Text('Update'),
          )),
        ],
      ),
    );
  }

  void _showCreateStudentDialog() {
    if (controller.selectedSchool.value == null) {
      Get.snackbar('Error', 'Please select a school first');
      return;
    }
    Get.to(() => StudentFormPage(
      schoolId: controller.selectedSchool.value!.id,
      isEdit: false,
    ));
  }

  void _showEditStudentDialog(Student student) {
    Get.to(() => StudentFormPage(
      student: student,
      schoolId: student.schoolId ?? controller.selectedSchool.value!.id,
      isEdit: true,
    ));
  }

  void _showDeleteStudentConfirmation(Student student) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.name ?? 'this student'}?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.deleteStudent(student.id);
              Get.back();
              if (controller.selectedSchool.value != null) {
                controller.getAllStudents(schoolId: controller.selectedSchool.value!.id);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateUserDialog() {
    final authController = Get.find<AuthController>();
    final currentUserRole = authController.user.value?.role?.toLowerCase() ?? '';
    final isCorrespondent = currentUserRole == 'correspondent';

    final emailController = TextEditingController();
    final userNameController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    String? selectedSchoolCode;

    // Load schools only once
    controller.getAllSchools();

    // For non-correspondent users, selectedSchoolCode will be set automatically in StatefulBuilder
    if (!isCorrespondent) {
      // Trigger schools loading
      controller.getAllSchools();
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Create User'),

        content: StatefulBuilder(
          builder: (context, setState) {
            // For non-correspondent users, auto-select their school when schools load
            if (!isCorrespondent && selectedSchoolCode == null && controller.schools.isNotEmpty) {
              final userSchoolId = authController.user.value?.schoolId;
              final userSchool = controller.schools.firstWhereOrNull(
                    (school) => school.id == userSchoolId,
              );
              if (userSchool != null && userSchool.schoolCode != null) {
                selectedSchoolCode = userSchool.schoolCode;
              }
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Email
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User Name
                  TextField(
                    controller: userNameController,
                    decoration: InputDecoration(
                      labelText: 'User Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // School Selection - Dropdown for correspondent, readonly for others
                  if (isCorrespondent)
                  // School Dropdown for correspondent
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      isDense: true,
                      value: selectedSchoolCode,
                      decoration: InputDecoration(
                        hintText: 'Choose School',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        prefixIcon: Icon(
                          Icons.school,
                          color: AppTheme.primaryBlue,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppTheme.primaryBlue,
                      ),
                      dropdownColor: Colors.white,
                      menuMaxHeight: 300,
                      selectedItemBuilder: (context) {
                        return controller.schools.map((school) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${school.name} (${school.schoolCode})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList();
                      },
                      items: controller.schools.map((school) {
                        return DropdownMenuItem<String>(
                          value: school.schoolCode,
                          child: Row(
                            children: [
                              Icon(
                                Icons.school,
                                size: 16,
                                color: AppTheme.primaryBlue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${school.name} (${school.schoolCode})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedSchoolCode = value);
                      },
                    )
                  else
                  // Readonly school display for non-correspondent users
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.school,
                            color: AppTheme.primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              controller.schools.firstWhereOrNull(
                                    (school) => school.schoolCode == selectedSchoolCode,
                              )?.name ?? 'Loading...',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),

        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),

          Obx(
                () => ElevatedButton(
              onPressed: userController.isLoading.value
                  ? null
                  : () async {
                if (selectedSchoolCode == null) {
                  Get.snackbar(
                    'Error',
                    'Please select a school',
                  );
                  return;
                }

                await userController.createUser(
                  email: emailController.text,
                  userName: userNameController.text,
                  password: passwordController.text,
                  phoneNo: phoneController.text,
                  schoolCode: selectedSchoolCode!,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: userController.isLoading.value
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Create'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignRoleDialog(Map<String, dynamic> user) {
    String selectedRole = user['role'] ?? 'correspondent';
    final validRoles = ['correspondent', 'teacher', 'principal', 'viceprincipal', 'administrator', 'parent', 'accountant'];

    if (!validRoles.contains(selectedRole)) {
      selectedRole = 'correspondent';
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Assign Role to ${user['userName']}'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Choose Role',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.admin_panel_settings, color: AppTheme.primaryBlue, size: 20),
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
              value: validRoles.contains(selectedRole) ? selectedRole : 'correspondent',
              selectedItemBuilder: (context) {
                return validRoles.map((role) {
                  return Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  );
                }).toList();
              },
              items: validRoles.map((role) {
                return DropdownMenuItem<String>(
                  value: role,
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
                          child: Icon(_getRoleIcon(role), color: AppTheme.primaryBlue, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            role.toUpperCase(),
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
              onChanged: (role) {
                if (role != null) setState(() => selectedRole = role);
              },
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              userController.assignRole(user['_id'], selectedRole);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final emailController = TextEditingController(text: user['email']);
    final userNameController = TextEditingController(text: user['userName']);
    final phoneController = TextEditingController(text: user['phoneNo']);
    final isLoading = false.obs;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit User: ${user['userName']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: userNameController,
                decoration: InputDecoration(
                  labelText: 'User Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          Obx(() => ElevatedButton(
            onPressed: isLoading.value ? null : () async {

              isLoading.value = true;
              try {
                await userController.updateUser(
                  userId: user['_id'],
                  email: emailController.text,
                  userName: userNameController.text,
                  phoneNo: phoneController.text,
                );

                // Close dialog first
                Get.back();

                // Show success message
                Get.snackbar(
                  'Success',
                  'User updated successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                  snackPosition: SnackPosition.TOP,
                );

                // Refresh the user list
                final schoolId = controller.selectedSchool.value?.id ?? Get.find<AuthController>().user.value?.schoolId;
                if (schoolId != null) {
                  await userController.loadUsers(schoolId: schoolId, role: userController.selectedRole.value);
                }

                // If the updated user is the current user, refresh auth data
                final currentUserId = Get.find<AuthController>().user.value?.id;
                if (currentUserId == user['_id']) {
                  await Get.find<AuthController>().handleUserUpdateSuccess();
                }

              } catch (e) {

                Get.back();
                Get.snackbar(
                  'Error',
                  'Failed to update user}',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                  snackPosition: SnackPosition.TOP,
                );
              } finally {
                isLoading.value = false;
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: isLoading.value
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Text('Update'),
          )),
        ],
      ),
    );
  }

  void _showDeleteUserDialog(Map<String, dynamic> user) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user['userName']}?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          Obx(() => ElevatedButton(
            onPressed: userController.isLoading.value ? null : () async {
              await userController.deleteUser(user['_id']);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: userController.isLoading.value
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Text('Delete'),
          )),
        ],
      ),
    );
  }

  void _showSectionDetailsDialog(BuildContext context, Section section) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Section Details - ${section.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Name', section.name),
              _buildDetailRow('Class', section.className ?? 'N/A'),
              _buildDetailRow('Room Number', section.roomNumber ?? 'N/A'),
              _buildDetailRow('Capacity', section.capacity?.toString() ?? 'N/A'),
              if (section.classTeachers != null && section.classTeachers!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Class Teachers:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...section.classTeachers!.map((teacher) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          teacher['userName'] ?? 'Unknown Teacher',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }



  void _showFeeStructureDialog(SchoolClass schoolClass) {
    final feeController = Get.put(FeeStructureController());
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Fee Structure - ${schoolClass.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Fee Amount',
                prefixText: '₹',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isNotEmpty) {
                await feeController.setFeeStructure(
                  schoolId: controller.selectedSchool.value!.id,
                  classId: schoolClass.id,
                  feeHead: {
                    'amount': double.tryParse(amountController.text) ?? 0,
                    'description': descriptionController.text,
                  },
                );
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAssignClubToStudentDialog(Student student) {
    
    
    
    
    

    final clubController = Get.put(ClubController());
    final selectedClubs = <String>[].obs;
    final availableClubs = <Map<String, dynamic>>[].obs;
    final alreadyInClubs = <String>[].obs;
    final isLoading = false.obs;

    void loadClubs() async {
      
      isLoading.value = true;
      try {
        await clubController.getClubsByClass(student.classId ?? '');
        availableClubs.value = clubController.clubs;
        alreadyInClubs.value = List<String>.from(student.clubs ?? []);
        selectedClubs.value = List<String>.from(student.clubs ?? []);
        
        
      } catch (e) {
        
        Get.snackbar('Error', 'Failed to load clubs');
      } finally {
        isLoading.value = false;
      }
    }

    loadClubs();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade50, Colors.purple.shade50],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.purple.shade600],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_circle, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Assign to Club',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            student.name ?? '',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (isLoading.value) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.blue.shade600),
                          const SizedBox(height: 16),
                          Text(
                            'Loading clubs...',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }

                  if (availableClubs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.groups_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No clubs available',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No clubs found for this class',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: availableClubs.length,
                    itemBuilder: (context, index) {
                      final club = availableClubs[index];
                      final clubId = club['_id'] as String;
                      final isAlreadyMember = alreadyInClubs.contains(clubId);

                      return Obx(() {
                        final isSelected = selectedClubs.contains(clubId);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isAlreadyMember
                                  ? Colors.green.shade400
                                  : (isSelected ? Colors.blue.shade400 : Colors.grey.shade200),
                              width: isAlreadyMember || isSelected ? 2 : 1,
                            ),
                            boxShadow: isAlreadyMember || isSelected
                                ? [
                              BoxShadow(
                                color: isAlreadyMember ? Colors.green.shade200 : Colors.blue.shade200,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                                : [],
                          ),
                          child: CheckboxListTile(
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    club['name'] ?? 'Unknown Club',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isAlreadyMember
                                          ? Colors.green.shade700
                                          : (isSelected ? Colors.blue.shade700 : Colors.grey.shade800),
                                    ),
                                  ),
                                ),
                                if (isAlreadyMember)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Member',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: club['description'] != null
                                ? Text(
                              club['description'],
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            )
                                : null,
                            value: isSelected,
                            activeColor: isAlreadyMember ? Colors.green.shade600 : Colors.blue.shade600,
                            checkColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            onChanged: (bool? value) {
                              if (value == true) {
                                selectedClubs.add(clubId);
                              } else {
                                selectedClubs.remove(clubId);
                              }
                            },
                          ),
                        );
                      });
                    },
                  );
                }),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final clubsToAdd = selectedClubs.where((id) => !alreadyInClubs.contains(id)).toList();

                            for (String clubId in clubsToAdd) {
                              await clubController.toggleStudentClub(student.id, clubId, true);
                            }

                            Get.back();
                            controller.getAllStudents(schoolId: controller.selectedSchool.value!.id);
                            Get.snackbar(
                              'Success',
                              'Clubs assigned successfully',
                              backgroundColor: Colors.green.shade600,
                              colorText: Colors.white,
                              icon: const Icon(Icons.check_circle, color: Colors.white),
                            );
                          } catch (e) {
                            Get.snackbar(
                              'Error',
                              'Failed to assign clubs',
                              backgroundColor: Colors.red.shade600,
                              colorText: Colors.white,
                              icon: const Icon(Icons.error, color: Colors.white),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Assign Clubs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRemoveClubFromStudentDialog(Student student) {
    
    
    
    

    final clubController = Get.put(ClubController());
    final selectedClubs = <String>[].obs;
    final studentClubs = <Club>[].obs;
    final isLoading = false.obs;

    void loadStudentClubs() async {
      
      isLoading.value = true;
      try {
        // Get all clubs and filter by student's club IDs
        await clubController.getAllClubs(schoolId: controller.selectedSchool.value!.id);
        final allClubs = clubController.clubs;
        

        final studentClubIds = student.clubs ?? [];
        

        // Filter clubs that the student is a member of
        final filteredClubs = allClubs.where((clubMap) {
          return studentClubIds.contains(clubMap['_id']);
        }).toList();

        
        
        

        // Convert to Club objects
        studentClubs.value = filteredClubs.map((clubMap) => Club.fromJson(clubMap)).toList();
        
      } catch (e) {
        
        Get.snackbar('Error', 'Failed to load student clubs');
      } finally {
        isLoading.value = false;
      }
    }

    loadStudentClubs();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.orange.shade50, Colors.red.shade50],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade600, Colors.red.shade600],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.remove_circle, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Remove from Club',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            student.name ?? '',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (isLoading.value) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.orange.shade600),
                          const SizedBox(height: 16),
                          Text(
                            'Loading clubs...',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }

                  if (studentClubs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.groups_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No clubs found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Student is not in any clubs',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: studentClubs.length,
                    itemBuilder: (context, index) {
                      final club = studentClubs[index];
                      final clubId = club.id;

                      return Obx(() {
                        final isSelected = selectedClubs.contains(clubId);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? Colors.red.shade400 : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: Colors.red.shade200,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                                : [],
                          ),
                          child: CheckboxListTile(
                            title: Text(
                              club.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.red.shade700 : Colors.grey.shade800,
                              ),
                            ),
                            subtitle: club.description.isNotEmpty
                                ? Text(
                              club.description,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            )
                                : null,
                            value: isSelected,
                            activeColor: Colors.red.shade600,
                            checkColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            onChanged: (bool? value) {
                              if (value == true) {
                                selectedClubs.add(clubId);
                              } else {
                                selectedClubs.remove(clubId);
                              }
                            },
                          ),
                        );
                      });
                    },
                  );
                }),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            for (String clubId in selectedClubs) {
                              await clubController.toggleStudentClub(student.id, clubId, false);
                            }

                            Get.back();
                            controller.getAllStudents(schoolId: controller.selectedSchool.value!.id);
                            Get.snackbar(
                              'Success',
                              'Clubs removed successfully',
                              backgroundColor: Colors.green.shade600,
                              colorText: Colors.white,
                              icon: const Icon(Icons.check_circle, color: Colors.white),
                            );
                          } catch (e) {
                            Get.snackbar(
                              'Error',
                              'Failed to remove clubs',
                              backgroundColor: Colors.red.shade600,
                              colorText: Colors.white,
                              icon: const Icon(Icons.error, color: Colors.white),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Remove Clubs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceTab extends StatefulWidget {
  @override
  State<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<_AttendanceTab> {
  final attendanceController = Get.put(old_attendance.AttendanceController());
  final schoolController = Get.find<SchoolController>();
  final authController = Get.find<AuthController>();

  // Permission-based properties
  bool get canMarkAttendance => ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/attendance/mark');
  bool get canViewAttendance => ApiPermissions.hasApiAccess(currentUserRole, 'GET /api/attendance/sheet');
  String get currentUserRole => authController.user.value?.role?.toLowerCase() ?? '';

  bool isHistoryMode = false;
  bool _isFiltersExpanded = true;
  DateTime selectedDate = DateTime.now();
  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now();

  final TextEditingController _startYearController = TextEditingController(text: "2025");
  final TextEditingController _endYearController = TextEditingController(text: "2026");

  List<Map<String, dynamic>> attendanceRecords = [];
  List<Map<String, dynamic>> historyRecords = [];
  SchoolClass? selectedClass;

  String get academicYear => "${_startYearController.text}-${_endYearController.text}";

  @override
  void initState() {
    super.initState();
    // Set initial mode based on permissions
    // If user can mark attendance, start with Mark Daily mode
    // If user can only view, start with History mode
    isHistoryMode = !canMarkAttendance;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final school = schoolController.selectedSchool.value;
      if (school != null) {
        _onSchoolChanged(school);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple.shade50, Colors.indigo.shade50],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          child: Column(
            children: [
              // Header
              _buildHeader(isTablet),
              const SizedBox(height: 16),

              // Mode Toggle
              _buildModeToggle(),
              const SizedBox(height: 16),

              // Collapsible Selectors
              _buildAttendanceSelectors(isLandscape, isTablet),
              const SizedBox(height: 16),

              // Summary Cards (for daily mode)
              if (!isHistoryMode && attendanceRecords.isNotEmpty)
                _buildCollapsibleSummary(isLandscape, isTablet),

              const SizedBox(height: 16),

              // Content Area
              SizedBox(
                height: 400,
                child: _buildContentArea(isTablet),
              ),

              const SizedBox(height: 16),

              // Action Button - only show for users who can mark attendance
              if (!isHistoryMode && attendanceRecords.isNotEmpty && canMarkAttendance)
                _buildSaveButton(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade600, Colors.indigo.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.how_to_reg,
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
                  'Attendance Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Track and manage student attendance',
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
    );
  }

  Widget _buildModeToggle() {
    // If user can only view attendance (not mark), show only History tab
    if (!canMarkAttendance && canViewAttendance) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.history,
                color: Colors.purple.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Attendance History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple.shade600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'View Only',
                  style: TextStyle(
                    color: Colors.purple.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If user can mark attendance, show both tabs
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Mark Daily'),
              icon: Icon(Icons.today, size: 18),
            ),
            ButtonSegment(
              value: true,
              label: Text('History'),
              icon: Icon(Icons.history, size: 18),
            ),
          ],
          selected: {isHistoryMode},
          onSelectionChanged: (v) {
            if (mounted) {
              setState(() => isHistoryMode = v.first);
              _onFilterChanged();
            }
          },
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: Colors.purple.shade100,
            selectedForegroundColor: Colors.purple.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceSelectors(bool isLandscape, bool isTablet) {
    return Obx(() {
      final hasSelections = schoolController.selectedSchool.value != null && selectedClass != null;
      final isExpanded = !hasSelections || _isFiltersExpanded;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: isExpanded ? null : 60,
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
            ? _buildFullAttendanceSelectors(isLandscape, isTablet)
            : _buildCompactAttendanceSelectors(),
      );
    });
  }

  Widget _buildCompactAttendanceSelectors() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.school, color: Colors.purple.shade600, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              schoolController.selectedSchool.value?.name ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.class_, color: Colors.purple.shade600, size: 18),
          const SizedBox(width: 6),
          Text(
            selectedClass?.name ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              if (mounted) {
                setState(() {
                  _isFiltersExpanded = true;
                });
              }
            },
            icon: const Icon(Icons.expand_more, size: 18),
            tooltip: 'Expand Filters',
          ),
        ],
      ),
    );
  }

  Widget _buildFullAttendanceSelectors(bool isLandscape, bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Column(
        children: [
          // Header with collapse button
          Row(
            children: [
              Icon(Icons.filter_list, color: Colors.purple.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Filters',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 18 : 16,
                  color: Colors.purple.shade600,
                ),
              ),
              const Spacer(),
              if (schoolController.selectedSchool.value != null && selectedClass != null)
                IconButton(
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        _isFiltersExpanded = false;
                      });
                    }
                  },
                  icon: const Icon(Icons.expand_less, size: 20),
                  tooltip: 'Collapse Filters',
                ),
            ],
          ),
          const SizedBox(height: 16),

          // School and Class Selection
          isLandscape && isTablet
              ? Row(
            children: [
              Expanded(child: _buildSchoolSelector()),
              const SizedBox(width: 16),
              Expanded(child: _buildClassSelector()),
            ],
          )
              : Column(
            children: [
              _buildSchoolSelector(),
              const SizedBox(height: 12),
              _buildClassSelector(),
            ],
          ),
          const SizedBox(height: 16),

          // Academic Year
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _startYearController,
                  decoration: InputDecoration(
                    labelText: 'Start Year',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 16 : 12,
                      vertical: isTablet ? 16 : 12,
                    ),
                  ),
                  onChanged: (_) => _onFilterChanged(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('-', style: TextStyle(fontSize: isTablet ? 20 : 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: TextFormField(
                  controller: _endYearController,
                  decoration: InputDecoration(
                    labelText: 'End Year',
                    prefixIcon: const Icon(Icons.event),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 16 : 12,
                      vertical: isTablet ? 16 : 12,
                    ),
                  ),
                  onChanged: (_) => _onFilterChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date Selection
          isHistoryMode ? _buildDateRangeSelector() : _buildSingleDateSelector(),
        ],
      ),
    );
  }

  Widget _buildSchoolSelector() {
    return Obx(() {
      final schools = schoolController.schools;
      final selectedId = schoolController.selectedSchool.value?.id;

      return DropdownButtonFormField<School>(
        isExpanded: true,
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
        value: selectedId == null ? null : schools.firstWhereOrNull((s) => s.id == selectedId),
        selectedItemBuilder: (context) {
          return schools.map((s) {
            return Text(
              s.name,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            );
          }).toList();
        },
        items: schools.map((s) {
          return DropdownMenuItem<School>(
            value: s,
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
                  Expanded(
                    child: Text(
                      s.name,
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
        onChanged: _onSchoolChanged,
      );
    });
  }

  Widget _buildClassSelector() {
    return Obx(() {
      final classes = schoolController.classes;
      final selectedId = selectedClass?.id;

      return DropdownButtonFormField<SchoolClass>(
        isExpanded: true,
        decoration: InputDecoration(
          hintText: 'Choose Class',
          hintStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.class_, color: AppTheme.primaryBlue, size: 20),
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
        value: selectedId == null ? null : classes.firstWhereOrNull((c) => c.id == selectedId),
        selectedItemBuilder: (context) {
          return classes.map((c) {
            return Text(
              c.name,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            );
          }).toList();
        },
        items: classes.map((c) {
          return DropdownMenuItem<SchoolClass>(
            value: c,
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
                    child: Icon(Icons.class_, color: AppTheme.primaryBlue, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      c.name,
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
        onChanged: (c) {
          if (mounted) {
            setState(() => selectedClass = c);
            _onFilterChanged();
          }
        },
      );
    });
  }

  Widget _buildSingleDateSelector() {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (d != null && mounted) {
          setState(() => selectedDate = d);
          _onFilterChanged();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.purple.shade600),
            const SizedBox(width: 12),
            Text(
              'Date: ${selectedDate.toString().split(' ')[0]}',
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: startDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null && mounted) {
                setState(() => startDate = d);
                _onFilterChanged();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('From', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  Text(startDate.toString().split(' ')[0]),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: endDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null && mounted) {
                setState(() => endDate = d);
                _onFilterChanged();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('To', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  Text(endDate.toString().split(' ')[0]),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsibleSummary(bool isLandscape, bool isTablet) {
    final screenSize = MediaQuery.of(context).size;
    final total = attendanceRecords.length;
    final present = attendanceRecords.where((r) => r['status'] == 'present').length;
    final absent = total - present;
    final isExpanded = total > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isExpanded ? null : 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        child: isExpanded
            ? Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.purple.shade600, size: isTablet ? 20 : 18),
                SizedBox(width: isTablet ? 8 : 6),
                Text('Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isTablet ? 16 : 14)),
                const Spacer(),
                Text('$present/$total Present', style: TextStyle(fontSize: isTablet ? 14 : 12, color: Colors.green)),
              ],
            ),
            SizedBox(height: isTablet ? 12 : 8),
            isLandscape && isTablet
                ? Row(
              children: [
                Expanded(child: _buildSummaryCard('Total', total.toString(), Colors.blue, isTablet)),
                SizedBox(width: isTablet ? 8 : 6),
                Expanded(child: _buildSummaryCard('Present', present.toString(), Colors.green, isTablet)),
                SizedBox(width: isTablet ? 8 : 6),
                Expanded(child: _buildSummaryCard('Absent', absent.toString(), Colors.red, isTablet)),
              ],
            )
                : Wrap(
              spacing: isTablet ? 8 : 6,
              runSpacing: isTablet ? 8 : 6,
              children: [
                SizedBox(
                  width: (screenSize.width - (isTablet ? 80 : 60)) / 3,
                  child: _buildSummaryCard('Total', total.toString(), Colors.blue, isTablet),
                ),
                SizedBox(
                  width: (screenSize.width - (isTablet ? 80 : 60)) / 3,
                  child: _buildSummaryCard('Present', present.toString(), Colors.green, isTablet),
                ),
                SizedBox(
                  width: (screenSize.width - (isTablet ? 80 : 60)) / 3,
                  child: _buildSummaryCard('Absent', absent.toString(), Colors.red, isTablet),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _bulkUpdateStatus('present'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade100,
                      foregroundColor: Colors.green.shade700,
                      padding: EdgeInsets.symmetric(vertical: isTablet ? 12 : 8),
                    ),
                    child: Text('All Present', style: TextStyle(fontSize: isTablet ? 14 : 12)),
                  ),
                ),
                SizedBox(width: isTablet ? 8 : 6),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _bulkUpdateStatus('absent'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red.shade700,
                      padding: EdgeInsets.symmetric(vertical: isTablet ? 12 : 8),
                    ),
                    child: Text('All Absent', style: TextStyle(fontSize: isTablet ? 14 : 12)),
                  ),
                ),
              ],
            ),
          ],
        )
            : Row(
          children: [
            Icon(Icons.analytics, color: Colors.purple.shade600, size: 18),
            const SizedBox(width: 8),
            Text('Summary: $present/$total Present', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 12 : 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: isTablet ? 12 : 10,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea(bool isTablet) {
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
      child: isHistoryMode ? _buildHistoryList() : _buildDailyList(),
    );
  }

  Widget _buildDailyList() {
    if (attendanceRecords.isEmpty) {
      return const Center(
        child: Text(
          'No students found',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: attendanceRecords.length,
      itemBuilder: (_, i) {
        final r = attendanceRecords[i];
        final isPresent = _normalizeStatus(r['status']) == 'present';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isPresent ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPresent ? Colors.green.shade200 : Colors.red.shade200,
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isPresent ? Colors.green : Colors.red,
              child: Text(
                r['rollNumber']?.toString() ?? '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              r['studentName'] ?? 'Unknown Student',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<String>(
                  value: 'present',
                  groupValue: _normalizeStatus(r['status']),
                  onChanged: canMarkAttendance ? (v) {
                    if (mounted && v != null) {
                      setState(() {
                        attendanceRecords[i]['status'] = v;
                      });
                    }
                  } : null,
                  activeColor: Colors.green,
                ),
                const Text('P', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                Radio<String>(
                  value: 'absent',
                  groupValue: _normalizeStatus(r['status']),
                  onChanged: canMarkAttendance ? (v) {
                    if (mounted && v != null) {
                      setState(() {
                        attendanceRecords[i]['status'] = v;
                      });
                    }
                  } : null,
                  activeColor: Colors.red,
                ),
                const Text('A', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryList() {
    if (historyRecords.isEmpty) {
      return const Center(
        child: Text(
          'No history found',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: historyRecords.length,
      itemBuilder: (_, i) {
        final item = historyRecords[i];
        final records = item['records'] ?? [];
        final present = records.where((r) => r['status'] == 'present').length;
        final absent = records.where((r) => r['status'] == 'absent').length;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ExpansionTile(
            title: Text(
              item['date']?.toString().split('T')[0] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('By: ${item['takenBy']?['userName'] ?? 'Unknown'}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statusChip('Present', present, Colors.green),
                        _statusChip('Absent', absent, Colors.red),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...records.map<Widget>((s) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: s['status'] == 'present' ? Colors.green : Colors.red,
                        child: Text(
                          s['rollNumber']?.toString() ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      title: Text(s['studentName'] ?? ''),
                      dense: true,
                    )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saveAttendance,
        icon: const Icon(Icons.save),
        label: const Text('Save Attendance'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Helper methods
  String _normalizeStatus(String? status) {
    final v = status?.toLowerCase();
    return (v == 'present' || v == 'absent') ? v! : 'present';
  }

  void _onSchoolChanged(School? school) {
    schoolController.selectedSchool.value = school;

    if (mounted) {
      setState(() {
        selectedClass = null;
        attendanceRecords.clear();
        historyRecords.clear();
      });
    }

    if (school != null) {
      schoolController.getAllClasses(school.id).then((_) {
        if (schoolController.classes.isNotEmpty && mounted) {
          setState(() {
            selectedClass = schoolController.classes.first;
          });
          _onFilterChanged();
        }
      });
    }
  }

  void _onFilterChanged() {
    if (schoolController.selectedSchool.value == null || selectedClass == null) return;

    if (isHistoryMode) {
      _loadAttendanceHistory();
    } else {
      _loadAttendanceSheet();
    }
  }

  Future<void> _loadAttendanceSheet() async {
    final sheet = await attendanceController.getAttendanceSheet(
      schoolId: schoolController.selectedSchool.value!.id,
      classId: selectedClass!.id,
      date: selectedDate.toString().split(' ')[0],
      academicYear: academicYear,
    );

    if (sheet != null && mounted) {
      setState(() {
        attendanceRecords = List<Map<String, dynamic>>.from(sheet).map((r) {
          r['status'] = _normalizeStatus(r['status']);
          return r;
        }).toList();
      });
    } else {
      // If no sheet found, try to get students for the class
      final students = await attendanceController.getStudentsForAttendance(
        schoolId: schoolController.selectedSchool.value!.id,
        classId: selectedClass!.id,
      );

      if (students != null && mounted) {
        setState(() {
          attendanceRecords = List<Map<String, dynamic>>.from(students).map((student) {
            return {
              'studentId': student['_id'] ?? student['id'],
              'studentName': student['name'] ?? 'Unknown',
              'rollNumber': student['rollNumber'] ?? '',
              'status': 'present', // Default status
            };
          }).toList();
        });
      }
    }
  }

  Future<void> _loadAttendanceHistory() async {
    final response = await attendanceController.getAttendanceHistory(
      schoolId: schoolController.selectedSchool.value!.id,
      classId: selectedClass!.id,
      academicYear: academicYear,
      startDate: startDate.toString().split(' ')[0],
      endDate: endDate.toString().split(' ')[0],
    );

    if (response != null && response is List && mounted) {
      setState(() {
        historyRecords = List<Map<String, dynamic>>.from(response);
      });
    }
  }

  void _saveAttendance() {
    attendanceController.markAttendance(
      schoolId: schoolController.selectedSchool.value!.id,
      classId: selectedClass!.id,
      date: selectedDate.toString().split(' ')[0],
      academicYear: academicYear,
      records: attendanceRecords,
    );
  }

  void _bulkUpdateStatus(String status) {
    if (mounted) {
      setState(() {
        for (final r in attendanceRecords) {
          r['status'] = status;
        }
      });
    }
  }
}

class _FeeStructureTab extends StatefulWidget {
  @override
  State<_FeeStructureTab> createState() => _FeeStructureTabState();
}

class _FeeStructureTabState extends State<_FeeStructureTab> {
  final feeController = Get.put(FeeStructureController());
  final schoolController = Get.find<SchoolController>();

  final admissionFeeController = TextEditingController();
  final firstTermController = TextEditingController();
  final secondTermController = TextEditingController();
  final busFirstTermController = TextEditingController();
  final busSecondTermController = TextEditingController();

  final selectedClass = ValueNotifier<SchoolClass?>(null);
  final selectedStudentType = ValueNotifier<String>('old'); // 'old' or 'new'
  final isStudentTypeExpanded = ValueNotifier<bool>(true); // Track if student type selector is expanded

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.indigo.shade50],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryBlue, Colors.indigo.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.payment,
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
                              'Fee Structure Management',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 24 : 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Configure fees for different classes',
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

                const SizedBox(height: 20),

                // Selection Cards - Collapsible
                _buildCollapsibleSelectors(),

                const SizedBox(height: 16),

                // Student Type Selector
                _buildStudentTypeSelector(),

                const SizedBox(height: 20),

                // Fee Structure Form
                Container(
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
                    children: [
                      // Form Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              color: AppTheme.primaryBlue,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Fee Details',
                              style: TextStyle(
                                fontSize: isTablet ? 20 : 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Form Content - Now part of the overall scroll
                      Padding(
                        padding: EdgeInsets.all(isTablet ? 24 : 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            isLandscape && isTablet
                                ? _buildLandscapeForm()
                                : _buildPortraitForm(),
                            const SizedBox(height: 20),
                            // Save Button
                            _buildSaveButton(),
                            const SizedBox(height: 20),
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

  Widget _buildStudentTypeSelector() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return ValueListenableBuilder<bool>(
      valueListenable: isStudentTypeExpanded,
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
                ? _buildExpandedStudentTypeSelector(isTablet)
                : _buildCompactStudentTypeSelector(isTablet),
          ),
        );
      },
    );
  }

  Widget _buildCompactStudentTypeSelector(bool isTablet) {
    return ValueListenableBuilder<String>(
      valueListenable: selectedStudentType,
      builder: (context, studentType, child) {
        return InkWell(
          onTap: () => isStudentTypeExpanded.value = true,
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
                  child: Icon(
                      studentType == 'old' ? Icons.school : Icons.person_add,
                      color: AppTheme.primaryBlue,
                      size: 18
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Student Type: ${studentType == 'old' ? 'Old Students' : 'New Students'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => isStudentTypeExpanded.value = true,
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: 'Change Student Type',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandedStudentTypeSelector(bool isTablet) {
    return ValueListenableBuilder<String>(
      valueListenable: selectedStudentType,
      builder: (context, studentType, child) {
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
                    child: Icon(
                        studentType == 'old' ? Icons.school : Icons.person_add,
                        color: AppTheme.primaryBlue,
                        size: 20
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Student Type',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => isStudentTypeExpanded.value = false,
                    icon: const Icon(Icons.expand_less, size: 20),
                    tooltip: 'Collapse',
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
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
                          Text('Old Students', style: TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: 'new',
                      child: Row(
                        children: [
                          Icon(Icons.person_add, color: Colors.green, size: 20),
                          SizedBox(width: 12),
                          Text('New Students', style: TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      selectedStudentType.value = value;
                      // Reload fee structure when student type changes
                      if (schoolController.selectedSchool.value != null && selectedClass.value != null) {
                        _loadFeeStructure(schoolController.selectedSchool.value!.id, selectedClass.value!.id);
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCollapsibleSelectors() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;

    return Obx(() {
      final hasSelections = schoolController.selectedSchool.value != null && selectedClass.value != null;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: hasSelections ? 60 : null,
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
          child: hasSelections
              ? _buildCompactSelectors()
              : _buildFullSelectors(isLandscape, isTablet),
        ),
      );
    });
  }

  Widget _buildCompactSelectors() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.school, color: AppTheme.primaryBlue, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              schoolController.selectedSchool.value?.name ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Icon(Icons.class_, color: AppTheme.primaryBlue, size: 20),
          const SizedBox(width: 8),
          Text(
            selectedClass.value?.name ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              setState(() {
                schoolController.selectedSchool.value = null;
                selectedClass.value = null;
                _clearForm();
              });
            },
            icon: const Icon(Icons.edit, size: 20),
            tooltip: 'Change Selection',
          ),
        ],
      ),
    );
  }

  Widget _buildFullSelectors(bool isLandscape, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: isLandscape && isTablet
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
          const SizedBox(height: 16),
          _buildClassDropdown(),
        ],
      ),
    );
  }

  Widget _buildSchoolDropdown() {
    return Obx(() => DropdownButtonFormField<School>(
      isExpanded: true,
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
      value: schoolController.selectedSchool.value,
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
                Text(
                  school.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
      onChanged: (school) {
        setState(() {
          schoolController.selectedSchool.value = school;
          selectedClass.value = null;
          _clearForm();
        });
        if (school != null) {
          schoolController.getAllClasses(school.id);
        }
      },
    ));
  }

  Widget _buildClassDropdown() {
    return ValueListenableBuilder<SchoolClass?>(
      valueListenable: selectedClass,
      builder: (context, value, child) {
        return DropdownButtonFormField<SchoolClass>(
          isExpanded: true,
          decoration: InputDecoration(
            hintText: 'Choose Class',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.class_, color: AppTheme.primaryBlue, size: 20),
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
          value: schoolController.classes.contains(value) ? value : null,
          selectedItemBuilder: (context) {
            return schoolController.classes.map((cls) {
              return Text(
                cls.name,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              );
            }).toList();
          },
          items: schoolController.classes.map((cls) {
            return DropdownMenuItem<SchoolClass>(
              value: cls,
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
                      child: Icon(Icons.class_, color: AppTheme.primaryBlue, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      cls.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (cls) {
            setState(() {
              selectedClass.value = cls;
            });
            if (cls != null && schoolController.selectedSchool.value != null) {
              _loadFeeStructure(schoolController.selectedSchool.value!.id, cls.id);
            }
          },
        );
      },
    );
  }

  Widget _buildPortraitForm() {
    return Column(
      children: [
        _buildFeeCard('Admission Fee', admissionFeeController, Icons.login, Colors.green),
        const SizedBox(height: 16),
        _buildFeeCard('First Term Amount', firstTermController, Icons.looks_one, Colors.blue),
        const SizedBox(height: 16),
        _buildFeeCard('Second Term Amount', secondTermController, Icons.looks_two, Colors.orange),
        const SizedBox(height: 16),
        _buildFeeCard('Bus First Term', busFirstTermController, Icons.directions_bus, Colors.teal),
        const SizedBox(height: 16),
        _buildFeeCard('Bus Second Term', busSecondTermController, Icons.directions_bus_filled, Colors.indigo),
      ],
    );
  }

  Widget _buildLandscapeForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildFeeCard('Admission Fee', admissionFeeController, Icons.login, Colors.green)),
            const SizedBox(width: 16),
            Expanded(child: _buildFeeCard('First Term Amount', firstTermController, Icons.looks_one, Colors.blue)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildFeeCard('Second Term Amount', secondTermController, Icons.looks_two, Colors.orange)),
            const SizedBox(width: 16),
            Expanded(child: _buildFeeCard('Bus First Term', busFirstTermController, Icons.directions_bus, Colors.teal)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Container()), // Empty space for balance
            const SizedBox(width: 16),
            Expanded(child: _buildFeeCard('Bus Second Term', busSecondTermController, Icons.directions_bus_filled, Colors.indigo)),
          ],
        ),
      ],
    );
  }

  Widget _buildFeeCard(String label, TextEditingController controller, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                prefixText: '₹ ',
                hintText: 'Enter amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: color.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: color, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    // Check if user has permission to save fee structure
    final authController = Get.find<AuthController>();
    final currentUserRole = authController.user.value?.role?.toLowerCase() ?? '';
    final canSave = ApiPermissions.hasApiAccess(currentUserRole, 'POST /api/feestructure/set');

    // Don't show save button if user doesn't have permission
    if (!canSave) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: Obx(() => ElevatedButton(
        onPressed: feeController.isLoading.value ? null : _saveFeeStructure,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: feeController.isLoading.value
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save, size: 20),
            SizedBox(width: 8),
            Text(
              'Save Fee Structure',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      )),
    );
  }

  void _clearForm() {
    admissionFeeController.clear();
    firstTermController.clear();
    secondTermController.clear();
    busFirstTermController.clear();
    busSecondTermController.clear();
  }

  void _loadFeeStructure(String schoolId, String classId) async {
    final studentType = selectedStudentType.value;
    final feeStructure = await feeController.getFeeStructureByClass(schoolId, classId, type: studentType);
    if (feeStructure != null) {
      // Handle both direct feeHead and nested data.feeHead formats
      final feeHead = feeStructure['feeHead'] ?? feeStructure['data']?['feeHead'] ?? {};
      admissionFeeController.text = feeHead['admissionFee']?.toString() ?? '';
      firstTermController.text = feeHead['firstTermAmt']?.toString() ?? '';
      secondTermController.text = feeHead['secondTermAmt']?.toString() ?? '';
      busFirstTermController.text = feeHead['busFirstTermAmt']?.toString() ?? '';
      busSecondTermController.text = feeHead['busSecondTermAmt']?.toString() ?? '';
    } else {
      // Clear form if no fee structure found for this student type
      _clearForm();
    }
  }

  void _saveFeeStructure() {
    if (schoolController.selectedSchool.value == null) {
      Get.snackbar(
        'Error',
        'Please select a school first',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    final selectedClass = this.selectedClass.value;
    if (selectedClass == null) {
      Get.snackbar(
        'Error',
        'Please select a class',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    feeController.setFeeStructure(
      schoolId: schoolController.selectedSchool.value!.id,
      classId: selectedClass.id,
      type: selectedStudentType.value,
      feeHead: {
        'admissionFee': double.tryParse(admissionFeeController.text) ?? 0,
        'firstTermAmt': double.tryParse(firstTermController.text) ?? 0,
        'secondTermAmt': double.tryParse(secondTermController.text) ?? 0,
        'busFirstTermAmt': double.tryParse(busFirstTermController.text) ?? 0,
        'busSecondTermAmt': double.tryParse(busSecondTermController.text) ?? 0,
      },
    );
  }
}
void _showSectionDetailsDialog(BuildContext context, Section section) {
  final screenSize = MediaQuery.of(context).size;
  final isTablet = screenSize.width > 600;
  final isLandscape = screenSize.width > screenSize.height;

  Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: isTablet ? (isLandscape ? 600 : 500) : screenSize.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.8,
          maxWidth: isTablet ? 600 : screenSize.width * 0.95,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, AppTheme.primaryBlue.withOpacity(0.02)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, Colors.indigo.shade600],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.group, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Section ${section.name}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 24 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Class ${section.className ?? "N/A"}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: isTablet ? 16 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Info Cards
                    isLandscape && isTablet
                        ? Row(
                      children: [
                        Expanded(child: _buildInfoCard('Section Name', section.name, Icons.label, Colors.blue)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildInfoCard('Class', section.className ?? 'N/A', Icons.class_, Colors.green)),
                      ],
                    )
                        : Column(
                      children: [
                        _buildInfoCard('Section Name', section.name, Icons.label, Colors.blue),
                        const SizedBox(height: 12),
                        _buildInfoCard('Class', section.className ?? 'N/A', Icons.class_, Colors.green),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Room & Capacity
                    isLandscape && isTablet
                        ? Row(
                      children: [
                        Expanded(child: _buildInfoCard('Room Number', section.roomNumber ?? 'Not Assigned', Icons.room, Colors.orange)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildInfoCard('Capacity', section.capacity?.toString() ?? 'Not Set', Icons.people, Colors.purple)),
                      ],
                    )
                        : Column(
                      children: [
                        _buildInfoCard('Room Number', section.roomNumber ?? 'Not Assigned', Icons.room, Colors.orange),
                        const SizedBox(height: 12),
                        _buildInfoCard('Capacity', section.capacity?.toString() ?? 'Not Set', Icons.people, Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Teachers Section
                    if (section.classTeachers != null && section.classTeachers!.isNotEmpty) ...[
                      Text(
                        'Class Teachers',
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...section.classTeachers!.map((teacher) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.teal.shade50, Colors.teal.shade100],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.teal,
                              radius: 20,
                              child: Text(
                                (teacher['userName'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    teacher['userName'] ?? 'Unknown',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  if (teacher['email'] != null)
                                    Text(
                                      teacher['email'],
                                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                    ),
                                  if (teacher['phoneNo'] != null)
                                    Text(
                                      teacher['phoneNo'],
                                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.teal,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Teacher',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey[600]),
                            const SizedBox(width: 12),
                            Text(
                              'No teachers assigned ',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Metadata

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
// void _showSectionDetailsDialog(BuildContext context, Section section) {
//   Get.dialog(
//     AlertDialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       title: Text('Section Details - ${section.name}'),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Class: ${section.className ?? "N/A"}'),
//           const SizedBox(height: 8),
//           Text('Room: ${section.roomNumber ?? "N/A"}'),
//           const SizedBox(height: 8),
//           Text('Capacity: ${section.capacity ?? "N/A"}'),
//           if (section.classTeachers != null && section.classTeachers!.isNotEmpty) ...[
//             const SizedBox(height: 8),
//             Text('Teachers: ${section.classTeachers!.map((t) => t['userName'] ?? 'Unknown').join(', ')}'),
//           ],
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Get.back(),
//           child: const Text('Close'),
//         ),
//       ],
//     ),
//   );
// }
// void _loadFeeStructure(String schoolId, String classId) {
//   // Implementation for loading fee structure
// }
//
// void _clearForm() {
//   // Implementation for clearing form
// }

Widget _buildLandscapeForm() {
  return Row(
    children: [
      Expanded(child: _buildPortraitForm()),
    ],
  );
}

Widget _buildPortraitForm() {
  return Column(
    children: [
      Text('Fee structure form would go here'),
    ],
  );
}

Widget _buildSaveButton() {
  return ElevatedButton(
    onPressed: () {
      // Save implementation
    },
    child: Text('Save Fee Structure'),
  );
}

Widget _buildSchoolDropdown() {
  return Container(
    child: Text('School dropdown'),
  );
}

Widget _buildFullSelectors(bool isLandscape, bool isTablet) {
  return Column(
    children: [
      _buildSchoolDropdown(),
    ],
  );
}




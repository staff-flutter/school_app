import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../../../core/rbac/api_rbac.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../controllers/announcement_controller.dart';
import '../../communications/views/announcement_detail_view.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isTablet = screenSize.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: SafeArea(
        child: ResponsiveWrapper(
          child: isTablet && !isLandscape
              ? Row(
                  children: [
                    SizedBox(
                      width: screenSize.width * 0.25,
                      child: _buildSidebar(context),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          _buildTopBar(context),
                          Expanded(
                            child: _buildModuleContent(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildTopBar(context),
                    Expanded(
                      child: Column(
                        children: [
                          if (!isLandscape) _buildMobileSidebar(context),
                          Expanded(
                            child: _buildModuleContent(context),
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

  Widget _buildSidebar(BuildContext context) {
    return Container(
      color: AppTheme.primaryBlue,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _showAnnouncementsDialog(context),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications,
                      size: 30,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  controller.userName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  controller.userRole.toUpperCase(),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          Expanded(
            child: Obx(() => ListView.builder(
              itemCount: controller.getNavigationItems().length,
              itemBuilder: (context, index) {
                final item = controller.getNavigationItems()[index];
                return _buildNavItem(item);
              },
            )),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
            onTap: () => Get.find<AuthController>().logout(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(NavigationItem item) {
    return Obx(() => ListTile(
      leading: Icon(
        _getIconData(item.icon),
        color: controller.selectedModule.value == item.id ? Colors.white : Colors.white70,
      ),
      title: Text(
        item.title,
        style: TextStyle(
          color: controller.selectedModule.value == item.id ? Colors.white : Colors.white70,
          fontWeight: controller.selectedModule.value == item.id ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: controller.selectedModule.value == item.id,
      selectedTileColor: Colors.white24,
      onTap: () => controller.selectModule(item.id),
    ));
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Obx(() => Text(
            _getModuleTitle(controller.selectedModule.value),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          )),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleContent(BuildContext context) {
    switch (controller.selectedModule.value) {
      case 'dashboard':
        return _buildDashboardContent();
      case 'users':
        return _buildUsersContent();
      case 'schools':
        return _buildSchoolsContent();
      case 'students':
        return _buildStudentsContent();
      case 'attendance':
        return _buildAttendanceContent();
      case 'announcements':
        return _buildAnnouncementsContent();
      case 'clubs':
        return _buildClubsContent();
      default:
        return _buildComingSoonContent();
    }
  }

  Widget _buildDashboardContent() {
    // Get navigation items but filter based on role permissions
    final authController = Get.find<AuthController>();
    final userRole = authController.user.value?.role?.toLowerCase() ?? '';
    final navigationItems = controller.getNavigationItems().where((item) => item.id != 'dashboard');

    // Filter out announcements module for roles that cannot create announcements
    final filteredItems = navigationItems.where((item) {
      // Hide announcements module if user cannot create announcements
      if (item.id == 'announcements') {
        return ApiPermissions.canCreateAnnouncement(userRole);
      }
      // For accountant, only show modules they should have UI access to
      if (userRole == 'accountant') {
        return _isAccountantModuleAllowed(item.id);
      }
      return true;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${controller.userName}!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              children: filteredItems.map((item) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: _getModuleGradient(item.id),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: _getModuleGradient(item.id).colors.first.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () => controller.selectModule(item.id),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_getIconData(item.icon), size: 40, color: Colors.white),
                          const SizedBox(height: 10),
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Check if a module should be visible to accountant role
  bool _isAccountantModuleAllowed(String moduleId) {
    const allowedModules = {
      'students',
      'studentRecords',
      'feeCollection',
      'expenses',
      'financeLedger',
      'clubs',
      'clubVideos',
    };
    return allowedModules.contains(moduleId);
  }

  Widget _buildUsersContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Users Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (controller.hasFeature('allowRoleAssignment'))
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Add User'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                        if (controller.hasFeature('allowDeleteButtons'))
                          SizedBox(width: 100, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(child: Text('User ${index + 1}')),
                                Expanded(child: Text('Teacher')),
                                Expanded(child: Text('user${index + 1}@school.com')),
                                if (controller.hasFeature('allowDeleteButtons'))
                                  SizedBox(
                                    width: 100,
                                    child: Row(
                                      children: [
                                        IconButton(
                                          onPressed: () {},
                                          icon: const Icon(Icons.edit, size: 16),
                                        ),
                                        IconButton(
                                          onPressed: () {},
                                          icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolsContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Schools Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (controller.hasFeature('allowEditSchool'))
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Add School'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.2,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.school, color: AppTheme.primaryBlue),
                            const Spacer(),
                            if (controller.hasFeature('allowEditSchool'))
                              PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  if (controller.hasFeature('allowDeleteButtons'))
                                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('School ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text('Code: SCH00${index + 1}', style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 5),
                        Text('Students: ${(index + 1) * 150}', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsContent() {
    final permission = controller.getModulePermission('students');
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Students ${_getPermissionLabel(permission)}', 
                   style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (permission == 'full')
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Add Student'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text('Class', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text('Roll No', style: TextStyle(fontWeight: FontWeight.bold))),
                        if (permission == 'financeView')
                          Expanded(child: Text('Fee Status', style: TextStyle(fontWeight: FontWeight.bold))),
                        if (permission == 'full')
                          SizedBox(width: 100, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: 10,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(child: Text('Student ${index + 1}')),
                                Expanded(child: Text('Class ${(index % 5) + 1}')),
                                Expanded(child: Text('${index + 1}'.padLeft(3, '0'))),
                                if (permission == 'financeView')
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: index % 2 == 0 ? Colors.green : Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        index % 2 == 0 ? 'Paid' : 'Due',
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                if (permission == 'full')
                                  SizedBox(
                                    width: 100,
                                    child: Row(
                                      children: [
                                        IconButton(
                                          onPressed: () {},
                                          icon: const Icon(Icons.edit, size: 16),
                                        ),
                                        if (controller.hasFeature('allowDeleteButtons'))
                                          IconButton(
                                            onPressed: () {},
                                            icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceContent() {
    final permission = controller.getModulePermission('attendance');
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Attendance ${_getPermissionLabel(permission)}', 
                   style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (controller.hasFeature('allowAttendanceMarking'))
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.how_to_reg),
                  label: const Text('Mark Attendance'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (permission == 'markAndView' || permission == 'full')
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.how_to_reg, size: 40, color: Colors.green),
                          const SizedBox(height: 10),
                          const Text('Present Today', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Text('245', style: TextStyle(fontSize: 24, color: Colors.green)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.person_off, size: 40, color: Colors.red),
                          const SizedBox(height: 10),
                          const Text('Absent Today', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Text('15', style: TextStyle(fontSize: 24, color: Colors.red)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.percent, size: 40, color: AppTheme.primaryBlue),
                          const SizedBox(height: 10),
                          const Text('Attendance Rate', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Text('94.2%', style: TextStyle(fontSize: 24, color: AppTheme.primaryBlue)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recent Attendance', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: 8,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: index % 3 == 0 ? Colors.red : Colors.green,
                              child: Icon(
                                index % 3 == 0 ? Icons.close : Icons.check,
                                color: Colors.white,
                              ),
                            ),
                            title: Text('Student ${index + 1}'),
                            subtitle: Text('Class ${(index % 5) + 1} - ${DateTime.now().toString().split(' ')[0]}'),
                            trailing: Text(index % 3 == 0 ? 'Absent' : 'Present'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsContent() {
    final permission = controller.getModulePermission('announcements');
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Announcements ${_getPermissionLabel(permission)}', 
                   style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (permission == 'full')
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('New Announcement'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Announcement ${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            if (permission == 'full')
                              PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  if (controller.hasFeature('allowDeleteButtons'))
                                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('This is the content of announcement ${index + 1}. It contains important information for students and parents.'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: index % 2 == 0 ? Colors.red : Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                index % 2 == 0 ? 'HIGH' : 'MEDIUM',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '2024-01-${(index + 10).toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubsContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Clubs & Activities', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (controller.userRole == 'correspondent' || controller.userRole == 'administrator')
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Add Club'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.2,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                final clubs = ['Science Club', 'Drama Club', 'Sports Club', 'Art Club', 'Music Club', 'Debate Club'];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.groups, color: AppTheme.primaryBlue),
                            const Spacer(),
                            if (controller.userRole == 'correspondent' || controller.userRole == 'administrator')
                              PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  if (controller.hasFeature('allowDeleteButtons'))
                                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(clubs[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text('Members: ${(index + 1) * 15}', style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 5),
                        Text('Active', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Coming Soon', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('This module is under development'),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'dashboard': return Icons.dashboard;
      case 'people': return Icons.people;
      case 'school': return Icons.school;
      case 'class': return Icons.class_;
      case 'group': return Icons.group;
      case 'assignment_ind': return Icons.assignment_ind;
      case 'person': return Icons.person;
      case 'child_care': return Icons.child_care;
      case 'folder': return Icons.folder;
      case 'account_balance': return Icons.account_balance;
      case 'payment': return Icons.payment;
      case 'how_to_reg': return Icons.how_to_reg;
      case 'receipt': return Icons.receipt;
      case 'announcement': return Icons.announcement;
      case 'groups': return Icons.groups;
      case 'video_library': return Icons.video_library;
      case 'account_balance_wallet': return Icons.account_balance_wallet;
      case 'history': return Icons.history;
      case 'delete_forever': return Icons.delete_forever;
      case 'card_membership': return Icons.card_membership;
      default: return Icons.help;
    }
  }

  String _getModuleTitle(String module) {
    switch (module) {
      case 'dashboard': return 'Dashboard';
      case 'users': return 'Users Management';
      case 'schools': return 'Schools Management';
      case 'classes': return 'Classes';
      case 'sections': return 'Sections';
      case 'teacherAssignments': return 'Teacher Assignments';
      case 'students': return 'Students';
      case 'myChildren': return 'My Children';
      case 'myClasses': return 'My Classes';
      case 'mySections': return 'My Sections';
      case 'studentRecords': return 'Student Records';
      case 'feeStructure': return 'Fee Structure';
      case 'feeCollection': return 'Fee Collection';
      case 'attendance': return 'Attendance';
      case 'expenses': return 'Expenses';
      case 'announcements': return 'Announcements';
      case 'clubs': return 'Clubs';
      case 'clubVideos': return 'Club Videos';
      case 'financeLedger': return 'Finance Ledger';
      case 'auditLogs': return 'Audit Logs';
      case 'deleteArchive': return 'Delete Archive';
      case 'subscription': return 'Subscription';
      default: return 'Unknown Module';
    }
  }

  String _getPermissionLabel(String permission) {
    switch (permission) {
      case 'readOnly': return '(Read Only)';
      case 'viewOnly': return '(View Only)';
      case 'reportsOnly': return '(Reports Only)';
      case 'classScopedReadOnly': return '(Class Scoped)';
      case 'financeView': return '(Finance View)';
      case 'markAndView': return '(Mark & View)';
      case 'ownChildrenOnly': return '(Own Children)';
      case 'readOnlyExceptAssign': return '(Read Only + Assign)';
      case 'viewAndRevert': return '(View & Revert)';
      case 'fullFinance': return '(Full Finance)';
      default: return '';
    }
  }

  LinearGradient _getModuleGradient(String moduleId) {
    switch (moduleId) {
      case 'users':
        return const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'students':
        return const LinearGradient(
          colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'teachers':
        return const LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'classes':
        return const LinearGradient(
          colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'subjects':
        return const LinearGradient(
          colors: [Color(0xFFA8EDEA), Color(0xFFFED6E3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'attendance':
        return const LinearGradient(
          colors: [Color(0xFFD299C2), Color(0xFFFEF9D7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'fee':
        return const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'reports':
        return const LinearGradient(
          colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'clubs':
        return const LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'communications':
        return const LinearGradient(
          colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Widget _buildMobileSidebar(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Container(
      height: 60,
      color: AppTheme.primaryBlue,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildSidebarItem(context, 'Dashboard', Icons.dashboard, '/dashboard'),
            const SizedBox(width: 16),
            _buildSidebarItem(context, 'Users', Icons.people, '/school-management?initialTab=4'),
            const SizedBox(width: 16),
            _buildSidebarItem(context, 'Students', Icons.school, '/school-management?initialTab=3'),
            const SizedBox(width: 16),
            _buildSidebarItem(context, 'Attendance', Icons.check_circle, '/school-management?initialTab=7'),
            const SizedBox(width: 16),
            _buildSidebarItem(context, 'Finance', Icons.account_balance, '/accounting-dashboard'),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, String title, IconData icon, String route) {
    return InkWell(
      onTap: () => Get.toNamed(route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnnouncementsDialog(BuildContext context) async {
    final authController = Get.find<AuthController>();
    final isParent = authController.user.value?.role == 'parent';

    // Show loading dialog
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // Get announcements controller
      late final AnnouncementController announcementController;
      if (Get.isRegistered<AnnouncementController>()) {
        announcementController = Get.find<AnnouncementController>();
      } else {
        announcementController = Get.put(AnnouncementController());
      }

      // Load announcements based on role
      if (isParent) {
        announcementController.changeFilter('parent');
      } else {
        announcementController.changeFilter('all');
      }

      // Wait for announcements to load
      await Future.delayed(const Duration(milliseconds: 500));

      Get.back(); // Close loading dialog

      // Show announcements dialog
      Get.dialog(
        Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isParent ? 'Parent Announcements' : 'All Announcements',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Obx(() {
                    if (announcementController.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final announcements = isParent
                        ? announcementController.filteredAnnouncements.where((a) =>
                            (a['targetAudience'] as List?)?.contains('parent') ?? false).toList()
                        : announcementController.filteredAnnouncements;

                    if (announcements.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No announcements found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: announcements.length,
                      itemBuilder: (context, index) {
                        final announcement = announcements[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            gradient: _getAnnouncementCardGradient(announcement['type']),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              announcement['title'] ?? 'No Title',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  announcement['description'] ?? 'No Description',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(announcement['createdAt']),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.person,
                                      size: 14,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        announcement['createdBy']?['userName'] ?? 'System',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.visibility,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                Get.back(); // Close dialog
                                announcementController.getAnnouncement(announcement['_id']).then((_) {
                                  final freshAnnouncement = announcementController.selectedAnnouncement.value ?? announcement;
                                  Get.to(() => AnnouncementDetailView(announcement: freshAnnouncement));
                                });
                              },
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        barrierColor: Colors.black.withOpacity(0.5),
      );
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'Failed to load announcements',
        backgroundColor: AppTheme.errorRed,
        colorText: Colors.white,
      );
    }
  }

  Gradient _getAnnouncementCardGradient(String? type) {
    switch (type) {
      case 'urgent':
        return AppTheme.errorGradient;
      case 'event':
        return AppTheme.primaryGradient;
      case 'holiday':
        return AppTheme.successGradient;
      default:
        return const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}
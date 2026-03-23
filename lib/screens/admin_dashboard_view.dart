import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/widgets/responsive_wrapper.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/screens/student_management_view.dart';
import 'package:school_app/screens/finance_dashboard_view.dart';
import 'package:school_app/screens/system_management_view.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final screenSize = MediaQuery
        .of(context)
        .size;
    final isTablet = screenSize.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: SafeArea(
        child: ResponsiveWrapper(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            size: 48,
                            color: Colors.white,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Admin Dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Get.back(),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.all(screenSize.width * 0.04),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isTablet ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildDashboardCard(
                      context,
                      'User Management',
                      Icons.people,
                      'Manage users, roles, and permissions',
                          () => Get.toNamed('/school-management?initialTab=4'),
                    ),
                    _buildDashboardCard(
                      context,
                      'Student Management',
                      Icons.school,
                      'Manage students and academic records',
                          () => Get.toNamed('/school-management?initialTab=3'),
                    ),
                    _buildDashboardCard(
                      context,
                      'Finance Dashboard',
                      Icons.account_balance,
                      'Financial reports and management',
                          () => Get.to(() =>  FinanceDashboardView()),
                    ),
                    _buildDashboardCard(
                      context,
                      'System Management',
                      Icons.settings_system_daydream,
                      'System settings and configuration',
                          () => Get.to(() =>  SystemManagementView()),
                    ),
                    _buildDashboardCard(
                      context,
                      'Attendance Overview',
                      Icons.check_circle,
                      'Monitor attendance across all classes',
                          () => Get.toNamed('/school-management?initialTab=7'),
                    ),
                    _buildDashboardCard(
                      context,
                      'Reports & Analytics',
                      Icons.analytics,
                      'Generate comprehensive reports',
                          () => Get.toNamed('/accounting-dashboard'),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context,
      String title,
      IconData icon,
      String description,
      VoidCallback onTap,) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

  Widget _buildWelcomeCard(AuthController authController) {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              authController.user.value?.userName ?? 'Admin',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Role: ${authController.user.value?.role ?? 'Unknown'}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            if (authController.userSchool.value != null) ...[
              const SizedBox(height: 4),
              Text(
                'School: ${authController.userSchool.value!['name'] ?? 'Unknown School'}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Overview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return isWide 
              ? Row(
                  children: [
                    Expanded(child: _buildStatCard('Active Students', '1,234', Icons.school, Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Total Revenue', '₹12.5L', Icons.currency_rupee, Colors.green)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Pending Fees', '₹2.3L', Icons.pending, Colors.orange)),
                  ],
                )
              : Column(
                  children: [
                    _buildStatCard('Active Students', '1,234', Icons.school, Colors.blue),
                    const SizedBox(height: 12),
                    _buildStatCard('Total Revenue', '₹12.5L', Icons.currency_rupee, Colors.green),
                    const SizedBox(height: 12),
                    _buildStatCard('Pending Fees', '₹2.3L', Icons.pending, Colors.orange),
                  ],
                );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementSections(BuildContext context) {
    final authController = Get.find<AuthController>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Management Modules',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            final crossAxisCount = isWide ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
            
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                if (_hasPermission(authController, ['correspondent', 'administrator']))
                  _buildModuleCard(
                    'Student Management',
                    'Manage parent assignments, class assignments, and view attendance',
                    Icons.people,
                    Colors.blue,
                    () => Get.to(() => StudentManagementView()),
                  ),
                if (_hasPermission(authController, ['correspondent', 'accountant', 'principal']))
                  _buildModuleCard(
                    'Finance Dashboard',
                    'View financial stats, charts, and transaction history',
                    Icons.analytics,
                    Colors.green,
                    () => Get.to(() => FinanceDashboardView()),
                  ),
                if (_hasPermission(authController, ['correspondent', 'accountant', 'principal', 'viceprincipal', 'administrator']))
                  _buildModuleCard(
                    'System Management',
                    'Manage deleted items archive and view audit logs',
                    Icons.settings,
                    Colors.purple,
                    () => Get.to(() => SystemManagementView()),
                  ),
                _buildModuleCard(
                  'Student Records',
                  'View and manage student fee records and receipts',
                  Icons.receipt,
                  Colors.orange,
                  () => Get.snackbar('Info', 'Navigate to student records from main menu'),
                ),
                _buildModuleCard(
                  'Reports',
                  'Generate various reports and analytics',
                  Icons.bar_chart,
                  Colors.teal,
                  () => Get.snackbar('Info', 'Reports module coming soon'),
                ),
                _buildModuleCard(
                  'Settings',
                  'Configure school settings and preferences',
                  Icons.tune,
                  Colors.indigo,
                  () => Get.snackbar('Info', 'Settings module coming soon'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildModuleCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.arrow_forward, color: color, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasPermission(AuthController authController, List<String> allowedRoles) {
    final userRole = authController.user.value?.role.toLowerCase();
    return userRole != null && allowedRoles.map((r) => r.toLowerCase()).contains(userRole);
  }

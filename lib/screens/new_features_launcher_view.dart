import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/screens/admin_dashboard_view.dart';
import 'package:school_app/screens/student_management_view.dart';
import 'package:school_app/screens/finance_dashboard_view.dart';
import 'package:school_app/screens/system_management_view.dart';

class NewFeaturesLauncherView extends StatelessWidget {
  const NewFeaturesLauncherView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Features Demo'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'New API Features Implemented',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'This demo showcases the newly implemented APIs:\n'
                        '• Student-Parent Assignment APIs\n'
                        '• Student Attendance APIs\n'
                        '• Class/Section Assignment APIs\n'
                        '• Finance Ledger APIs (Stats & Timeline)\n'
                        '• Delete Archive Management APIs\n'
                        '• Audit Log APIs\n\n'
                        'All features include proper role-based access control.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Available Features',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                'Admin Dashboard',
                'Comprehensive dashboard with overview of all new features',
                Icons.dashboard,
                Colors.indigo,
                () => Get.to(() => const AdminDashboardView()),
                ['All Roles'],
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                'Student Management',
                'Parent assignment, class assignment, and attendance viewing',
                Icons.people,
                Colors.blue,
                () => Get.to(() => StudentManagementView()),
                ['Correspondent', 'Administrator', 'Principal', 'Teacher', 'Parent'],
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                'Finance Dashboard',
                'Financial stats, timeline charts, and transaction management',
                Icons.analytics,
                Colors.green,
                () => Get.to(() => FinanceDashboardView()),
                ['Correspondent', 'Accountant', 'Principal'],
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                'System Management',
                'Delete archive management and audit log viewing',
                Icons.settings,
                Colors.purple,
                () => Get.to(() => SystemManagementView()),
                ['Correspondent', 'Accountant', 'Principal', 'Vice Principal', 'Administrator'],
              ),
              const SizedBox(height: 24),
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text(
                            'Current User Info',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Name: ${authController.user.value?.userName ?? 'Unknown'}'),
                      Text('Role: ${authController.user.value?.role ?? 'Unknown'}'),
                      Text('School: ${authController.userSchool.value?['name'] ?? 'Unknown'}'),
                      const SizedBox(height: 8),
                      const Text(
                        'Note: Some features may be restricted based on your role.',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
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

  Widget _buildFeatureCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
    List<String> allowedRoles,
  ) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
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
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: allowedRoles.map((role) => Chip(
                        label: Text(
                          role,
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor: color.withOpacity(0.1),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
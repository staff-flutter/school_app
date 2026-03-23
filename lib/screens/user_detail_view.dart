import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/widgets/responsive_wrapper.dart';

class UserDetailView extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserDetailView({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final schoolController = Get.find<SchoolController>();
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: SafeArea(
        child: ResponsiveWrapper(
          child: CustomScrollView(
            slivers: [
              // App Bar with Back Button
              SliverAppBar(
                expandedHeight: isLandscape ? 120 : 200,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: _getRoleGradient(user['role']),
                    ),
                    child: Stack(
                      children: [
                        // Background Pattern
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.1,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    Colors.white.withOpacity(0.5),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Content
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 20,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Avatar
                              Hero(
                                tag: 'user-avatar-${user['userName']}',
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: isLandscape ? 35 : 50,
                                    backgroundColor: _getRoleColor(user['role']),
                                    child: Text(
                                      (user['userName'] ?? 'U').substring(0, 1).toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isLandscape ? 28 : 36,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              // User Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      user['userName'] ?? 'Unknown User',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isLandscape ? 24 : 28,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        user['role']?.toString().toUpperCase() ?? 'NO ROLE',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
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
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                ),
              ),

              // User Details Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(screenSize.width * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information Card
                      _buildInfoCard(
                        context,
                        'Basic Information',
                        Icons.person_outline,
                        [
                          _buildInfoRow('Full Name', user['userName'] ?? 'N/A'),
                          _buildInfoRow('Email', user['email'] ?? 'N/A'),
                          _buildInfoRow('Phone', user['phoneNo'] ?? 'N/A'),
                          _buildInfoRow('Role', user['role']?.toString().toUpperCase() ?? 'N/A'),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // School Information Card
                      Obx(() {
                        // Get school info from controller
                        final schoolController = Get.find<SchoolController>();
                        final schoolId = user['schoolId'];
                        final school = schoolController.schools.firstWhereOrNull((s) => s.id == schoolId);
                        
                        return _buildInfoCard(
                          context,
                          'School Information',
                          Icons.school_outlined,
                          [
                            _buildInfoRow('School Name', school?.name ?? 'N/A'),
                            _buildInfoRow('School Code', school?.schoolCode ?? 'N/A'),
                            _buildInfoRow('School ID', user['schoolId'] ?? 'N/A'),
                          ],
                        );
                      }),

                      // Connected Students (for parents only)
                      if (user['role'] == 'parent' && user['studentId'] != null) ...[
                        const SizedBox(height: 20),
                        _buildStudentsCard(context, schoolController),
                      ],

                      // Account Status
                      const SizedBox(height: 20),
                      _buildStatusCard(context),

                      // Bottom spacing
                      SizedBox(height: screenSize.height * 0.1),
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

  Widget _buildInfoCard(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTheme.primaryBlue, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsCard(BuildContext context, SchoolController schoolController) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.family_restroom, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Connected Students',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getStudentDetails(user['studentId'], schoolController),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No students connected',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.map((student) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Text(
                            (student['name'] ?? 'S').substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          student['name'] ?? 'Unknown Student',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('Roll: ${student['rollNumber'] ?? 'N/A'}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () {
                          // Navigate to student detail if needed
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final isActive = user['isActive'] ?? true;

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
                    color: isActive ? Colors.green : Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Account Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isActive ? Icons.check_circle : Icons.cancel,
                    color: isActive ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isActive ? 'Active Account' : 'Inactive Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.green[800] : Colors.red[800],
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

  LinearGradient _getRoleGradient(String? role) {
    switch (role?.toLowerCase()) {
      case 'administrator':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
        );
      case 'principal':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        );
      case 'teacher':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        );
      case 'parent':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF059669), Color(0xFF047857)],
        );
      case 'correspondent':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
        );
    }
  }

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'administrator':
        return const Color(0xFFDC2626);
      case 'principal':
        return const Color(0xFF8B5CF6);
      case 'teacher':
        return const Color(0xFF2563EB);
      case 'parent':
        return const Color(0xFF059669);
      case 'correspondent':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Future<List<Map<String, dynamic>>> _getStudentDetails(dynamic studentIds, SchoolController schoolController) async {
    if (studentIds == null) return [];

    List<String> ids = [];
    if (studentIds is List) {
      ids = studentIds.map((id) => id.toString()).toList();
    } else if (studentIds is String) {
      ids = [studentIds];
    }

    List<Map<String, dynamic>> students = [];

    // Get student details from the controller's students list
    for (String id in ids) {
      final student = schoolController.students.firstWhereOrNull((s) => s.id == id);
      if (student != null) {
        students.add({
          'name': student.name,
          'rollNumber': student.rollNumber,
          'id': student.id,
        });
      }
    }

    return students;
  }
}
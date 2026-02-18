import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/subscription_controller.dart';
import '../controllers/school_controller.dart';
import '../data/services/subscription_service.dart';
import '../core/widgets/api_rbac_wrapper.dart';
import '../core/rbac/api_rbac.dart';
import '../modules/auth/controllers/auth_controller.dart';
import '../core/theme/app_theme.dart';
import '../data/models/school_models.dart';

class SubscriptionManagementView extends GetView<SubscriptionController> {
  const SubscriptionManagementView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(context, isTablet),
            Expanded(
              child: _buildSubscriptionTab(context, isTablet),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
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
                Icons.subscriptions,
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
                    'Subscription Management',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Manage plans and attendance tracking',
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

  // Widget _buildTabBar(BuildContext context) {
  //   return Container(
  //     margin: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(16),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.05),
  //           blurRadius: 10,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: TabBar(
  //       indicator: BoxDecoration(
  //         color: AppTheme.primaryBlue,
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       labelColor: Colors.white,
  //       unselectedLabelColor: Colors.grey[600],
  //       labelStyle: const TextStyle(fontWeight: FontWeight.w600),
  //       tabs: const [
  //         Tab(text: 'Subscription', icon: Icon(Icons.card_membership, size: 20)),
  //         // Tab(text: 'Attendance', icon: Icon(Icons.access_time, size: 20)),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSubscriptionTab(BuildContext context, bool isTablet) {
    final authController = Get.find<AuthController>();
    final schoolController = Get.put(SchoolController());
    final isCorrespondent = authController.user.value?.role?.toLowerCase() == 'correspondent';
    final selectedSchool = Rxn<School>();
    
    // Initialize school
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isCorrespondent) {
        
        
        
        schoolController.getAllSchools().then((_) {
          
          
          
          if (schoolController.schools.isNotEmpty) {
            selectedSchool.value = schoolController.schools.first;
            controller.loadSubscription(selectedSchool.value!.id);
          }
        });
      } else {
        final schoolId = authController.user.value?.schoolId;
        if (schoolId != null) {
          controller.loadSubscription(schoolId);
        }
      }
    });
    
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryBlue),
              const SizedBox(height: 16),
              Text('Loading subscription...', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        );
      }

      return SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: Column(
          children: [
            if (isCorrespondent) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 20),
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
                  
                  return DropdownButtonFormField<School>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Select School',
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.school, color: AppTheme.primaryBlue, size: 20),
                    ),
                    border: InputBorder.none,
                  ),
                  value: selectedSchool.value,
                  items: schoolController.schools.map((school) {
                    return DropdownMenuItem<School>(
                      value: school,
                      child: Text(school.name),
                    );
                  }).toList(),
                  onChanged: (School? school) {
                    if (school != null) {
                      selectedSchool.value = school;
                      controller.loadSubscription(school.id);
                    }
                  },
                );
                }),
              ),
            ],
            _buildCurrentSubscriptionCard(context, isTablet),
            const SizedBox(height: 20),
            _buildAvailablePlansSection(context, isTablet, selectedSchool.value?.id ?? authController.user.value?.schoolId),
          ],
        ),
      );
    });
  }

  Widget _buildCurrentSubscriptionCard(BuildContext context, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.TealColor.withOpacity(0.3),
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
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.star, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Current Subscription',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSubscriptionStatus(isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionStatus(bool isTablet) {
    return Obx(() {
      final status = controller.getSubscriptionStatus();
      final modules = status['modules'] as Map<String, dynamic>;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Plan: ${status['plan'].toString().toUpperCase()}',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Enabled Modules:',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: modules.entries.map((entry) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: entry.value ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: entry.value ? Colors.white.withOpacity(0.5) : Colors.white.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    entry.value ? Icons.check_circle : Icons.cancel,
                    color: entry.value ? Colors.white : Colors.white.withOpacity(0.5),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatModuleName(entry.key),
                    style: TextStyle(
                      fontSize: 12,
                      color: entry.value ? Colors.white : Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      );
    });
  }

  Widget _buildAvailablePlansSection(BuildContext context, bool isTablet, String? schoolId) {
    return ApiRbacWrapper(
      apiEndpoint: 'PUT /api/subscription/update',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Plans',
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          _buildPlanCards(isTablet, schoolId),
          const SizedBox(height: 20),
          _buildCustomPlanCard(isTablet, schoolId),
        ],
      ),
      fallback: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.orange.shade600, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Only correspondents can manage subscriptions.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCards(bool isTablet, String? schoolId) {
    final plans = ['basic', 'standard', 'premium'];
    final gradients = [AppTheme.successGradient, AppTheme.warningGradient, AppTheme.primaryGradient];

    return Column(
      children: plans.asMap().entries.map((entry) {
        final index = entry.key;
        final plan = entry.value;
        final modules = SubscriptionService.packages[plan]!;
        final gradient = gradients[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan.toUpperCase(),
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(
                      width: isTablet ? 120 : 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () => _updateToPlan(plan, schoolId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            controller.getCurrentPlan() == plan ? 'Current' : 'Select',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: modules.entries.map((entry) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          entry.value ? Icons.check : Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatModuleName(entry.key),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomPlanCard(bool isTablet, String? schoolId) {
    final modules = ['studentRecord', 'attendance', 'expense', 'club', 'announcement'];
    final customModules = <String, bool>{}.obs;

    final currentModules = controller.getEnabledModules();
    for (final module in modules) {
      customModules[module] = currentModules[module] ?? false;
    }

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
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  'Custom Plan',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...modules.map((module) => Obx(() => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: customModules[module] == true ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: customModules[module] == true ? AppTheme.primaryBlue.withOpacity(0.3) : Colors.grey.shade200,
                ),
              ),
              child: CheckboxListTile(
                title: Text(
                  _formatModuleName(module),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: customModules[module] == true ? AppTheme.primaryBlue : AppTheme.primaryText,
                  ),
                ),
                value: customModules[module] ?? false,
                activeColor: AppTheme.TealColor,
                onChanged: (value) {
                  customModules[module] = value ?? false;
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ))).toList(),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _updateToCustomPlan(customModules, schoolId),
                  child: const Center(
                    child: Text(
                      'Apply Custom Plan',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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

  Widget _buildAttendanceTab(BuildContext context, bool isTablet) {
    final selectedFilter = 'All'.obs;
    final searchQuery = ''.obs;

    return SafeArea(
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.all(isTablet ? 20 : 16),
            padding: EdgeInsets.all(isTablet ? 24 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, AppTheme.successGreen.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.successGreen.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.successGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.access_time, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Attendance Tracking',
                        style: TextStyle(
                          fontSize: isTablet ? 24 : 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppTheme.successGreen.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search students...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.search, color: AppTheme.successGreen),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onChanged: (value) => searchQuery.value = value,
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Present', 'Absent', 'Late'].map((filter) {
                      final isSelected = selectedFilter.value == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppTheme.successGradient : null,
                            color: isSelected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : AppTheme.successGreen.withOpacity(0.3),
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: AppTheme.successGreen.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ] : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(25),
                              onTap: () => selectedFilter.value = filter,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                child: Text(
                                  filter,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppTheme.successGreen,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )),
              ],
            ),
          ),
          Expanded(
            child: _buildAttendanceList(context, isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(BuildContext context, bool isTablet) {
    final attendanceData = [
      {'name': 'John Doe', 'status': 'Present', 'time': '09:00 AM', 'date': 'Today', 'avatar': 'JD'},
      {'name': 'Jane Smith', 'status': 'Absent', 'time': '-', 'date': 'Today', 'avatar': 'JS'},
      {'name': 'Mike Johnson', 'status': 'Late', 'time': '09:15 AM', 'date': 'Today', 'avatar': 'MJ'},
      {'name': 'Sarah Wilson', 'status': 'Present', 'time': '08:55 AM', 'date': 'Today', 'avatar': 'SW'},
      {'name': 'Alex Brown', 'status': 'Present', 'time': '08:45 AM', 'date': 'Today', 'avatar': 'AB'},
      {'name': 'Emma Davis', 'status': 'Late', 'time': '09:20 AM', 'date': 'Today', 'avatar': 'ED'},
    ];

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
      itemCount: attendanceData.length,
      itemBuilder: (context, index) {
        final student = attendanceData[index];
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
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: Row(
              children: [
                Container(
                  width: isTablet ? 56 : 48,
                  height: isTablet ? 56 : 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getStatusColor(student['status']!),
                        _getStatusColor(student['status']!).withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor(student['status']!).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      student['avatar']!,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 18 : 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name']!,
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${student['date']} • ${student['time']}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(student['status']!).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(student['status']!).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getStatusColor(student['status']!),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        student['status']!,
                        style: TextStyle(
                          color: _getStatusColor(student['status']!),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return AppTheme.successGreen;
      case 'Absent':
        return AppTheme.errorRed;
      case 'Late':
        return AppTheme.warningYellow;
      default:
        return AppTheme.primaryBlue;
    }
  }

  void _updateToPlan(String planName, String? schoolId) async {
    if (schoolId == null) {
      Get.snackbar('Error', 'Please select a school');
      return;
    }
    
    final success = await controller.updateSubscription(
      schoolId: schoolId,
      planName: planName,
    );
    
    if (success) {
      Get.snackbar('Success', 'Subscription updated to $planName plan');
    }
  }

  void _updateToCustomPlan(RxMap<String, bool> customModules, String? schoolId) async {
    if (schoolId == null) {
      Get.snackbar('Error', 'Please select a school');
      return;
    }
    
    final success = await controller.updateSubscription(
      schoolId: schoolId,
      planName: 'custom',
      customModules: Map<String, bool>.from(customModules),
    );
    
    if (success) {
      Get.snackbar('Success', 'Custom subscription plan applied');
    }
  }

  String _formatModuleName(String moduleName) {
    return moduleName
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .toUpperCase()
        .trim();
  }
}
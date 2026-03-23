import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/subscription_controller.dart';
import 'package:school_app/controllers/clubs_controller.dart';
import 'package:school_app/models/school_models.dart';

class ClubsActivitiesViewModern extends GetView<ClubsController> {
  const ClubsActivitiesViewModern({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final schoolController = Get.find<SchoolController>();
    final subscriptionController = Get.isRegistered<SubscriptionController>()
        ? Get.find<SubscriptionController>()
        : null;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.indigo.shade50, Colors.purple.shade50],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              // Modern Header
              _buildModernHeader(isTablet),
              
              // School Selection
              _buildSchoolSelector(schoolController, isTablet),
              
              // Main Content
              Expanded(
                child: Obx(() {
                  final selectedSchool = schoolController.selectedSchool.value;
                  if (selectedSchool == null) {
                    return _buildSelectSchoolPrompt();
                  }

                  final hasAccess = subscriptionController?.hasModuleAccess('club') ?? false;
                  if (!hasAccess) {
                    return _buildUpgradePrompt();
                  }

                  return _buildTabContent(isTablet);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.purple.shade600],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
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
              Icons.groups,
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
                  'Clubs & Activities',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manage school clubs and student activities',
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

  Widget _buildSchoolSelector(SchoolController schoolController, bool isTablet) {
    return Container(
      margin: EdgeInsets.all(isTablet ? 20 : 16),
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
        child: Obx(() {
          if (schoolController.isLoading.value && schoolController.schools.isEmpty) {
            return const LinearProgressIndicator();
          }

          return DropdownButtonFormField<School>(
            decoration: InputDecoration(
              labelText: 'Select School',
              prefixIcon: Icon(Icons.school, color: Colors.indigo.shade600),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            value: schoolController.selectedSchool.value,
            items: schoolController.schools.map((school) {
              return DropdownMenuItem<School>(
                value: school,
                child: Text(school.name),
              );
            }).toList(),
            onChanged: (School? school) {
              if (school != null) {
                schoolController.selectedSchool.value = school;
                controller.onSchoolSelected(school);
              }
            },
          );
        }),
      ),
    );
  }

  Widget _buildSelectSchoolPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.indigo.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school,
              size: 64,
              color: Colors.indigo.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Select a School',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a school to view clubs and activities',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradePrompt() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade100, Colors.amber.shade100],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.2),
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
                color: Colors.orange.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 48,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Upgrade Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your current plan does not include the Club module. Please contact your correspondent to upgrade.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.upgrade),
              label: const Text('View Plans'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isTablet) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
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
            child: TabBar(
              isScrollable: true,
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade400, Colors.purple.shade400],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: [
                Tab(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.groups, size: 18),
                        SizedBox(width: 8),
                        Text('Clubs'),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_circle, size: 18),
                        SizedBox(width: 8),
                        Text('Classes'),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_note, size: 18),
                        SizedBox(width: 8),
                        Text('Activities'),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people, size: 18),
                        SizedBox(width: 8),
                        Text('Members'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              children: [
                _buildClubsTab(isTablet),
                _buildClassesTab(isTablet),
                _buildActivitiesTab(isTablet),
                _buildMembersTab(isTablet),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubsTab(bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.clubs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.groups,
            title: 'No Clubs Found',
            subtitle: 'Create your first club to get started',
            buttonText: 'Create Club',
            onPressed: () {},
          );
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 2 : 1,
            childAspectRatio: isTablet ? 1.2 : 1.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: controller.clubs.length,
          itemBuilder: (context, index) {
            final club = controller.clubs[index];
            return _buildClubCard(club, isTablet);
          },
        );
      }),
    );
  }

  Widget _buildClubCard(club, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        gradient: _getCategoryGradient(club.category),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getCategoryGradient(club.category).colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                      child: Icon(
                        _getCategoryIcon(club.category),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        club.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  club.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  club.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      '${club.memberCount}/${club.maxMembers}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Join',
                        style: TextStyle(
                          color: _getCategoryGradient(club.category).colors.first,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildClassesTab(bool isTablet) {
    return _buildEmptyState(
      icon: Icons.play_circle,
      title: 'No Classes Found',
      subtitle: 'Upload video classes to get started',
      buttonText: 'Upload Video',
      onPressed: () {},
    );
  }

  Widget _buildActivitiesTab(bool isTablet) {
    return _buildEmptyState(
      icon: Icons.event_note,
      title: 'No Activities Found',
      subtitle: 'Create activities to engage students',
      buttonText: 'Create Activity',
      onPressed: () {},
    );
  }

  Widget _buildMembersTab(bool isTablet) {
    return _buildEmptyState(
      icon: Icons.people,
      title: 'No Members Found',
      subtitle: 'Students will appear here when they join clubs',
      buttonText: null,
      onPressed: null,
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
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
              icon,
              size: 64,
              color: Colors.grey.shade400,
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
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          if (buttonText != null && onPressed != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  LinearGradient _getCategoryGradient(String category) {
    switch (category) {
      case 'Academic':
        return LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        );
      case 'Arts':
        return LinearGradient(
          colors: [Colors.pink.shade400, Colors.purple.shade600],
        );
      case 'Sports':
        return LinearGradient(
          colors: [Colors.green.shade400, Colors.teal.shade600],
        );
      case 'Social':
        return LinearGradient(
          colors: [Colors.orange.shade400, Colors.red.shade600],
        );
      default:
        return LinearGradient(
          colors: [Colors.indigo.shade400, Colors.purple.shade600],
        );
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Academic':
        return Icons.school;
      case 'Arts':
        return Icons.palette;
      case 'Sports':
        return Icons.sports;
      case 'Social':
        return Icons.people;
      default:
        return Icons.group;
    }
  }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/widgets/responsive_wrapper.dart';
import 'package:school_app/controllers/clubs_controller.dart';
import 'package:school_app/controllers/school_controller.dart';
import 'package:school_app/controllers/subscription_controller.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/widgets/permission_wrapper.dart';
import 'package:school_app/models/school_models.dart';

class ClubsActivitiesView extends GetView<ClubsController> {
  const ClubsActivitiesView({super.key});

  @override
  Widget build(BuildContext context) {
    final schoolController = Get.find<SchoolController>();
    final subscriptionController = Get.isRegistered<SubscriptionController>() 
        ? Get.find<SubscriptionController>() 
        : null;
        
    if (schoolController.schools.isEmpty && !schoolController.isLoading.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        schoolController.getAllSchools();
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clubs & Activities'),
      ),
      body: SafeArea(
        child: ResponsiveWrapper(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Obx(() {
                  if (schoolController.isLoading.value && schoolController.schools.isEmpty) {
                    return const Center(child: LinearProgressIndicator());
                  }

                  if (schoolController.schools.isEmpty) {
                    return const Text("No schools available");
                  }

                  return DropdownButtonFormField<School>(
                    value: schoolController.schools.contains(schoolController.selectedSchool.value)
                        ? schoolController.selectedSchool.value
                        : null,
                    hint: const Text('Select School'),
                    items: schoolController.schools.map((school) {
                      return DropdownMenuItem<School>(
                        value: school,
                        child: Text(school.name),
                      );
                    }).toList(),
                    onChanged: (School? school) {
                      if (school != null) {
                        schoolController.selectedSchool.value = school;
                        subscriptionController?.loadSubscription(school.id);
                        controller.onSchoolSelected(school);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select School',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.school),
                    ),
                  );
                }),
              ),
              Expanded(
                child: Obx(() {
                  final selectedSchool = schoolController.selectedSchool.value;
                  if (selectedSchool == null) {
                    return const Center(child: Text('Please select a school'));
                  }
                  
                  final hasAccess = subscriptionController?.hasModuleAccess('club') ?? true;
                  if (!hasAccess) {
                    return _buildUpgradeRequiredWidget(context, 'Club');
                  }
                  
                  return DefaultTabController(
                    length: 5,
                    child: Column(
                      children: [
                        const TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          tabs: [
                            Tab(text: 'Clubs', icon: Icon(Icons.groups, size: 20)),
                            Tab(text: 'Classes', icon: Icon(Icons.play_circle, size: 20)),
                            Tab(text: 'Activities', icon: Icon(Icons.event_note, size: 20)),
                            Tab(text: 'Events', icon: Icon(Icons.event, size: 20)),
                            Tab(text: 'Members', icon: Icon(Icons.people, size: 20)),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildClubsTab(context),
                              _buildRecordedClassesTab(context),
                              _buildActivitiesTab(context),
                              _buildEventsTab(context),
                              _buildMembershipsTab(context),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClubsTab(BuildContext context) {
    final selectedCategory = 'All'.obs;
    
    return Column(
      children: [
        ResponsiveCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'School Clubs',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  PermissionWrapper(
                    permission: 'CREATE_CLUBS',
                    child: SizedBox(
                      width: 140,
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddClubDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Club'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Obx(() => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Academic', 'Arts', 'Sports', 'Social'].map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category),
                            selected: selectedCategory.value == category,
                            selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
                            checkmarkColor: AppTheme.primaryBlue,
                            onSelected: (selected) {
                              if (selected) selectedCategory.value = category;
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  )),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final filteredClubs = controller.getClubsByCategory(selectedCategory.value);

            if (filteredClubs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.groups, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                    const SizedBox(height: 16),
                    const Text('No clubs found'),
                    const SizedBox(height: 8),
                    Text('Create clubs to get started', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredClubs.length,
              itemBuilder: (context, index) {
                final club = filteredClubs[index];
                return _buildClubCard(context, club);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildClubCard(BuildContext context, club) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.groups,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                ),
                const Spacer(),
                PermissionWrapper(
                  permission: 'CREATE_CLUBS',
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditClubDialog(context, club);
                          break;
                        case 'delete':
                          _showDeleteClubConfirmation(context, club);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              club.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              club.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordedClassesTab(BuildContext context) {
    return const Center(child: Text('Recorded Classes'));
  }

  Widget _buildActivitiesTab(BuildContext context) {
    return const Center(child: Text('Activities'));
  }

  Widget _buildEventsTab(BuildContext context) {
    return const Center(child: Text('Events'));
  }

  Widget _buildMembershipsTab(BuildContext context) {
    return const Center(child: Text('Memberships'));
  }

  Widget _buildUpgradeRequiredWidget(BuildContext context, String featureName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 80, color: Colors.orange.shade300),
            const SizedBox(height: 24),
            Text(
              'Upgrade Required',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Your current plan does not include the $featureName module.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddClubDialog(BuildContext context) {
    Get.snackbar('Info', 'Add Club dialog would be implemented here');
  }

  void _showEditClubDialog(BuildContext context, club) {
    Get.snackbar('Info', 'Edit Club dialog would be implemented here');
  }

  void _showDeleteClubConfirmation(BuildContext context, club) {
    Get.snackbar('Info', 'Delete Club dialog would be implemented here');
  }
}
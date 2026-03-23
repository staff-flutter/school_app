import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/core/utils/responsive_layout.dart';
import 'package:school_app/widgets/base_responsive_view.dart';
import 'package:school_app/widgets/responsive_widgets.dart';
import 'package:school_app/controllers/clubs_controller.dart';

import 'package:school_app/widgets/permission_wrapper.dart';

import 'package:school_app/core/theme/app_theme.dart';

class ResponsiveClubsView extends BaseResponsiveView {
  const ResponsiveClubsView({super.key});

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Clubs & Activities'),
      elevation: ResponsiveHelper.isDesktop(context) ? 0 : 4,
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return GetBuilder<ClubsController>(
      builder: (controller) {
        return ResponsiveBuilder(
          builder: (context, constraints, deviceType) {
            return Column(
              children: [
                _buildHeader(context, controller),
                SizedBox(height: ResponsiveHelper.getResponsivePadding(context)),
                Expanded(
                  child: _buildContent(context, controller, deviceType),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ClubsController controller) {
    return ResponsiveCard(
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
                child: ElevatedButton.icon(
                  onPressed: () => _showAddClubDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Club'),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsivePadding(context)),
          _buildCategoryFilters(context),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(BuildContext context) {
    final selectedCategory = 'All'.obs;
    
    return Obx(() => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['All', 'Academic', 'Arts', 'Sports', 'Social'].map((category) {
        return FilterChip(
          label: Text(category),
          selected: selectedCategory.value == category,
          selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
          checkmarkColor: AppTheme.primaryBlue,
          onSelected: (selected) {
            if (selected) selectedCategory.value = category;
          },
        );
      }).toList(),
    ));
  }

  Widget _buildContent(BuildContext context, ClubsController controller, DeviceType deviceType) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.clubs.isEmpty) {
        return _buildEmptyState(context);
      }

      return _buildClubsList(context, controller, deviceType);
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups,
            size: ResponsiveHelper.isMobile(context) ? 64 : 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          SizedBox(height: ResponsiveHelper.getResponsivePadding(context)),
          Text(
            'No clubs found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Create clubs to get started',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: ResponsiveHelper.getResponsivePadding(context)),
          PermissionWrapper(
            permission: 'CREATE_CLUBS',
            child: ElevatedButton.icon(
              onPressed: () => _showAddClubDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create First Club'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubsList(BuildContext context, ClubsController controller, DeviceType deviceType) {
    if (deviceType == DeviceType.mobile) {
      return ListView.builder(
        itemCount: controller.clubs.length,
        itemBuilder: (context, index) {
          return _buildClubCard(context, controller.clubs[index]);
        },
      );
    } else {
      return ResponsiveGrid(
        children: controller.clubs.map((club) => _buildClubCard(context, club)).toList(),
        childAspectRatio: 1.2,
      );
    }
  }

  Widget _buildClubCard(BuildContext context, club) {
    return ResponsiveCard(
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
                child: Icon(
                  Icons.groups,
                  color: AppTheme.primaryBlue,
                  size: ResponsiveHelper.isMobile(context) ? 20 : 24,
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
                        _showDeleteClubDialog(context, club);
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
          SizedBox(height: ResponsiveHelper.getResponsivePadding(context)),
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: ResponsiveHelper.getResponsivePadding(context)),
          Row(
            children: [
              Icon(Icons.people, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text('${club.memberCount}/${club.maxMembers} members'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  club.category,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddClubDialog(BuildContext context) {
    // Implementation for add club dialog
    Get.snackbar('Info', 'Add Club dialog would be implemented here');
  }

  void _showEditClubDialog(BuildContext context, club) {
    // Implementation for edit club dialog
    Get.snackbar('Info', 'Edit Club dialog would be implemented here');
  }

  void _showDeleteClubDialog(BuildContext context, club) {
    // Implementation for delete club dialog
    Get.snackbar('Info', 'Delete Club dialog would be implemented here');
  }
}
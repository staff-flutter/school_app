import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
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

class CommunicationsView extends GetView<CommunicationsController> {
  CommunicationsView({super.key});

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
          final school = userSchoolId != null
              ? announcementController.schools.firstWhereOrNull((s) => s.id == userSchoolId)
              : announcementController.schools.isNotEmpty ? announcementController.schools.first : null;
          if (school != null) {
            announcementController.selectedSchool.value = school;
          }
        });
      });
    }

    if (announcementController.selectedSchool.value != null &&
        announcementController.announcements.isEmpty &&
        !announcementController.isLoading.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        announcementController.getAllAnnouncements(announcementController.selectedSchool.value!.id);
        if (isParent) {
          announcementController.changeFilter('parent');
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F5FF),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.campaign_rounded, color: Color(0xFF2563EB), size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Communications',
              style: TextStyle(color: Color(0xFF1A2A3A), fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
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
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF8A9FC0), size: 20),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height - 110,
                child: Obx(() {
                  final selectedSchool = announcementController.selectedSchool.value;
                  if (selectedSchool == null) {
                    return _buildSelectSchoolPrompt(context);
                  }
                  
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
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: AppTheme.getResponsivePadding(context)),
                          child: _buildFilterSection(context, announcementController),
                        ),
                      const SizedBox(height: 12),
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
        borderRadius: BorderRadius.circular(AppTheme.radius - 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  'School',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isReadOnly)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryBlue.withOpacity(0.05), AppTheme.primaryBlue.withOpacity(0.02)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.business, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        controller.selectedSchool.value?.name ?? 'Loading...',
                        style: TextStyle(
                          color: AppTheme.primaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.dividerColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<School>(
                    isExpanded: true,
                    value: controller.selectedSchool.value,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      hintText: 'Choose your school',
                      hintStyle: TextStyle(color: AppTheme.mutedText, fontSize: 14),
                      prefixIcon: Container(
                        margin: const EdgeInsets.only(left: 10, right: 6),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                      ),
                    ),
                    items: controller.schools.map((school) {
                      return DropdownMenuItem<School>(
                        value: school,
                        child: Text(
                          school.name.isNotEmpty ? school.name : 'School ${school.id.substring(0, 8)}...',
                          style: TextStyle(
                            fontSize: 14,
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
        borderRadius: BorderRadius.circular(AppTheme.radius - 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppTheme.primaryBlue),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Loading schools...',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
        margin: EdgeInsets.all(AppTheme.getResponsivePadding(context) - 4),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(AppTheme.radius - 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school_outlined, size: 28, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              'Select a School',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Please choose a school from the dropdown above to view communications',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context, AnnouncementController controller) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radius - 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: AppTheme.successGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.filter_list, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  'Filter by Audience',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildFilterChip('All', 'all', Icons.groups, controller),
                _buildFilterChip('Students', 'student', Icons.school, controller),
                _buildFilterChip('Parents', 'parent', Icons.family_restroom, controller),
                _buildFilterChip('Teachers', 'teacher', Icons.person, controller),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon, AnnouncementController controller) {
    return Obx(() {
      final isSelected = controller.selectedFilter.value == value;
      return GestureDetector(
        onTap: () => controller.changeFilter(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : null,
            borderRadius: BorderRadius.circular(20),
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
                size: 14,
                color: isSelected ? Colors.white : AppTheme.mutedText,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.primaryText,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
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
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showCreateDialog(context, announcementController, authController),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add, color: Colors.white, size: 20),
          label: const Text(
            'New Post',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildUpgradeRequiredWidget(BuildContext context, String featureName) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(AppTheme.getResponsivePadding(context) - 4),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(AppTheme.radius - 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.warningGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 18),
            Text(
              'Upgrade Required',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your current plan does not include the $featureName module. Please contact your correspondent to upgrade.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
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
        title: const Text('Create Announcement', style: TextStyle(fontSize: 16)),
        content: SingleChildScrollView(
          child: Obx(() => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.isLoading.value)
                const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 6),
                      Text('Loading schools...', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              
              if (controller.schools.isNotEmpty)
                DropdownButtonFormField<School>(
                  value: controller.selectedSchool.value,
                  decoration: const InputDecoration(labelText: 'School', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  hint: const Text('Select School', style: TextStyle(fontSize: 13)),
                  items: controller.schools.toSet().map((school) {
                    return DropdownMenuItem<School>(
                      value: school,
                      child: Text(school.name, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (value) => controller.selectedSchool.value = value,
                ),
              const SizedBox(height: 12),

              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Type', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: ['general', 'urgent', 'event', 'holiday'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.toUpperCase(), style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: (value) => selectedType = value ?? 'general',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: ['low', 'normal', 'high', 'urgent'].map((priority) {
                  return DropdownMenuItem(value: priority, child: Text(priority.toUpperCase(), style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: (value) => selectedPriority = value ?? 'normal',
              ),
              const SizedBox(height: 12),
              
              Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Target Audience:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      FilterChip(
                        label: const Text('All', style: TextStyle(fontSize: 12)),
                        selected: selectedAudiences.contains('all'),
                        onSelected: (selected) {
                          if (selected) {
                            selectedAudiences.clear();
                            selectedAudiences.add('all');
                          }
                        },
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      FilterChip(
                        label: const Text('Students', style: TextStyle(fontSize: 12)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      FilterChip(
                        label: const Text('Parents', style: TextStyle(fontSize: 12)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      FilterChip(
                        label: const Text('Teachers', style: TextStyle(fontSize: 12)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                    ],
                  ),
                ],
              )),
              const Divider(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Attachments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(height: 6),

              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...selectedFiles.map((file) => Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _viewImage(file: file),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(file, width: 60, height: 60, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                          onPressed: () => selectedFiles.remove(file),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  )),
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
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.add_a_photo, color: Colors.grey, size: 20),
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
            child: const Text('Cancel', style: TextStyle(fontSize: 13)),
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
                academicYear: '2024-25',
                title: titleController.text.trim(),
                description: descriptionController.text.trim(),
                type: selectedType,
                priority: selectedPriority,
                targetAudience: selectedAudiences.toList(),
                attachmentPaths: selectedFiles.map((f) => f.path).toList(),
              );
            },
            child: const Text('Create', style: TextStyle(fontSize: 13)),
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
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
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
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      }
      
      if (controller.filteredAnnouncements.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.announcement_outlined, 
                size: 56, 
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
              ),
              const SizedBox(height: 12),
              Text(
                controller.selectedFilter.value == 'all' 
                  ? 'No announcements found'
                  : 'No announcements for ${controller.selectedFilter.value}s',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.getResponsivePadding(context) - 4,
          vertical: 6,
        ),
        itemCount: controller.filteredAnnouncements.length,
        itemBuilder: (context, index) {
          final announcement = controller.filteredAnnouncements[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: _getCardGradient(announcement['type']),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        announcement['title'] ?? 'No Title',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (!isParent)
                      PopupMenuButton<String>(
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'view', child: Text('View', style: TextStyle(fontSize: 13))),
                          if (_canEdit(authController.user.value?.role))
                            const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(fontSize: 13))),
                          if (_canDelete(authController.user.value?.role))
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(fontSize: 13))),
                        ],
                        onSelected: (value) {
                          final id = announcement['_id'];
                          if (value == 'view') {
                            controller.getAnnouncement(announcement['_id']).then((_) {
                              final freshAnnouncement = controller.selectedAnnouncement.value ?? announcement;
                              Get.to(() => AnnouncementDetailView(announcement: freshAnnouncement));
                            });
                          } else if (value == 'edit') {
                            _showEditDialog(context, controller, announcement);
                          } else if (value == 'delete') {
                            _showDeleteConfirmation(context, controller, id);
                          }
                        },
                        icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.white, size: 18),
                          onPressed: () {
                            controller.getAnnouncement(announcement['_id']).then((_) {
                              final freshAnnouncement = controller.selectedAnnouncement.value ?? announcement;
                              Get.to(() => AnnouncementDetailView(announcement: freshAnnouncement));
                            });
                          },
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  announcement['description'] ?? 'No Description',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: _getTypeGradient(announcement['type']),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        announcement['type']?.toString().toUpperCase() ?? 'GENERAL',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: _getPriorityGradient(announcement['priority']),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        announcement['priority']?.toString().toUpperCase() ?? 'NORMAL',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
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
        title: const Text('Edit Announcement', style: TextStyle(fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.65,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextField(
                controller: titleController, 
                decoration: const InputDecoration(labelText: 'Title', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController, 
                decoration: const InputDecoration(labelText: 'Description', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)), 
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Attachments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))
              ),
              const SizedBox(height: 6),

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
                  height: 90,
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
                              margin: const EdgeInsets.only(right: 10),
                              width: 90,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: isPdf
                                    ? const Icon(Icons.picture_as_pdf, size: 32, color: Colors.red)
                                    : Image.network(attr['url'], fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          Positioned(
                            top: -8,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                              onPressed: () async {
                                final confirmed = await Get.dialog<bool>(
                                  AlertDialog(
                                    title: const Text('Delete Attachment', style: TextStyle(fontSize: 14)),
                                    content: Text('Are you sure you want to delete "${attr['originalName'] ?? 'this attachment'}"?', style: const TextStyle(fontSize: 13)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Get.back(result: false),
                                        child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                                      ),
                                      TextButton(
                                        onPressed: () => Get.back(result: true),
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text('Delete', style: TextStyle(fontSize: 12)),
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
                                          const CircularProgressIndicator(strokeWidth: 2),
                                          const SizedBox(height: 12),
                                          const Text('Deleting attachment...', style: TextStyle(fontSize: 13)),
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
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              }),

              const SizedBox(height: 12),
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
                              const CircularProgressIndicator(value: null, strokeWidth: 2),
                              const SizedBox(height: 12),
                              Text(progress > 0
                                  ? 'Uploading: ${(progress * 100).toStringAsFixed(0)}%'
                                  : 'Preparing upload...', style: const TextStyle(fontSize: 13)),
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
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add_a_photo, size: 18),
                label: Text(controller.isLoading.value ? 'Uploading...' : 'Add Image', style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              )),
            ],
          ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel', style: TextStyle(fontSize: 13))),
          ElevatedButton(
            onPressed: () async {
              final success = await controller.updateAnnouncement(
                id: announcementId,
                academicYear: announcement['academicYear'] ?? '2025-2026',
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
            child: const Text('Update', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AnnouncementController controller, String id) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Announcement', style: TextStyle(fontSize: 15)),
        content: const Text('Are you sure you want to delete this announcement?', style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteAnnouncement(id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete', style: TextStyle(fontSize: 13)),
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
              top: 32,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                radius: 18,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => Get.back(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
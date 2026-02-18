import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/announcement_controller.dart';
import '../../../data/models/school_models.dart';
import '../controllers/communications_controller.dart';
import '../../../modules/auth/controllers/auth_controller.dart';

class EnhancedCommunicationsView extends GetView<CommunicationsController> {
  const EnhancedCommunicationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final announcementController = Get.find<AnnouncementController>();
    final authController = Get.find<AuthController>();
    
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Communications'),
          actions: [
            IconButton(
              onPressed: () => _refreshData(announcementController),
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.announcement), text: 'Announcements'),
              Tab(icon: Icon(Icons.message), text: 'Messages'),
              Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
              Tab(icon: Icon(Icons.email), text: 'Email'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAnnouncementsTab(announcementController, authController),
            _buildMessagesTab(context),
            _buildNotificationsTab(context),
            _buildEmailTab(context),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(context, announcementController, authController),
      ),
    );
  }

  Widget _buildAnnouncementsTab(AnnouncementController announcementController, AuthController authController) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Obx(() => announcementController.schools.isNotEmpty
                  ? Row(
                      children: [
                        const Text('School: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: DropdownButton<School>(
                            value: announcementController.selectedSchool.value,
                            isExpanded: true,
                            items: announcementController.schools.map((school) {
                              return DropdownMenuItem<School>(
                                value: school,
                                child: Text('${school.name} (${school.schoolCode})'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                announcementController.selectedSchool.value = value;
                              }
                            },
                          ),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator()),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: announcementController.selectedFilter.value == 'all',
                    onSelected: (_) => announcementController.changeFilter('all'),
                  ),
                  FilterChip(
                    label: const Text('Students'),
                    selected: announcementController.selectedFilter.value == 'student',
                    onSelected: (_) => announcementController.changeFilter('student'),
                  ),
                  FilterChip(
                    label: const Text('Parents'),
                    selected: announcementController.selectedFilter.value == 'parent',
                    onSelected: (_) => announcementController.changeFilter('parent'),
                  ),
                  FilterChip(
                    label: const Text('Teachers'),
                    selected: announcementController.selectedFilter.value == 'teacher',
                    onSelected: (_) => announcementController.changeFilter('teacher'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (announcementController.isLoading.value && announcementController.filteredAnnouncements.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (announcementController.filteredAnnouncements.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.announcement_outlined, size: 64, color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.4)),
                    const SizedBox(height: 16),
                    Text(
                      announcementController.selectedFilter.value == 'all' 
                        ? 'No announcements found'
                        : 'No announcements for ${announcementController.selectedFilter.value}s',
                      style: Theme.of(Get.context!).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: announcementController.filteredAnnouncements.length,
              itemBuilder: (context, index) {
                final announcement = announcementController.filteredAnnouncements[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(announcement['title'] ?? 'No Title'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(announcement['description'] ?? 'No Description'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Chip(
                              label: Text(announcement['type']?.toString().toUpperCase() ?? 'GENERAL'),
                              backgroundColor: _getTypeColor(announcement['type']),
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(announcement['priority']?.toString().toUpperCase() ?? 'NORMAL'),
                              backgroundColor: _getPriorityColor(announcement['priority']),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'view', child: Text('View')),
                        if (_canEdit(authController.user.value?.role))
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        if (_canDelete(authController.user.value?.role))
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                      onSelected: (value) {
                        final id = announcement['_id'];
                        if (value == 'view') {
                          _showViewAnnouncementDialog(context, announcementController, announcement);
                        } else if (value == 'edit') {
                          _showEditAnnouncementDialog(context, announcementController, announcement);
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(context, announcementController, id);
                        }
                      },
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMessagesTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Direct Messages',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showComposeMessageDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('New Message'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('U${index + 1}'),
                    ),
                    title: Text('Message from User ${index + 1}'),
                    subtitle: Text('This is a sample message content...'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('10:${30 + index} AM'),
                        if (index < 2)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                      ],
                    ),
                    onTap: () => _openMessageThread(context, index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Mark All Read'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 8,
              itemBuilder: (context, index) {
                final isRead = index > 2;
                return Card(
                  color: isRead ? null : Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  child: ListTile(
                    leading: Icon(
                      _getNotificationIcon(index),
                      color: isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      _getNotificationTitle(index),
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(_getNotificationSubtitle(index)),
                    trailing: Text(
                      '${index + 1}h ago',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    onTap: () => _markNotificationAsRead(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Email Communications',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showComposeEmailDialog(context),
                icon: const Icon(Icons.email),
                label: const Text('Compose'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilterChip(
                  label: const Text('Inbox'),
                  selected: true,
                  onSelected: (selected) {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilterChip(
                  label: const Text('Sent'),
                  selected: false,
                  onSelected: (selected) {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilterChip(
                  label: const Text('Drafts'),
                  selected: false,
                  onSelected: (selected) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 6,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.email),
                    title: Text('Email Subject ${index + 1}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('From: sender${index + 1}@school.edu'),
                        Text('Preview of email content...'),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Dec ${20 + index}'),
                        if (index < 3)
                          const Icon(Icons.attach_file, size: 16),
                      ],
                    ),
                    onTap: () => _openEmail(context, index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context, AnnouncementController announcementController, AuthController authController) {
    final userRole = authController.user.value?.role;
    if (['correspondent', 'principal', 'administrator'].contains(userRole)) {
      return FloatingActionButton(
        onPressed: () => _showCreateAnnouncementDialog(context, announcementController, authController),
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  void _refreshData(AnnouncementController controller) {
    if (controller.selectedSchool.value != null) {
      controller.getAllAnnouncements(controller.selectedSchool.value!.id);
    } else if (controller.schools.isNotEmpty) {
      controller.selectedSchool.value = controller.schools.first;
    } else {
      controller.getAllSchools();
    }
  }

  void _showCreateAnnouncementDialog(BuildContext context, AnnouncementController controller, AuthController authController) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'general';
    String selectedPriority = 'normal';
    final selectedAudiences = <String>['all'].obs;
    
    if (controller.schools.isNotEmpty && controller.selectedSchool.value == null) {
      controller.selectedSchool.value = controller.schools.first;
    }
    
    Get.dialog(
      AlertDialog(
        title: const Text('Create Announcement'),
        content: SingleChildScrollView(
          child: Obx(() => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.schools.isNotEmpty)
                DropdownButtonFormField<School>(
                  value: controller.selectedSchool.value,
                  decoration: const InputDecoration(labelText: 'School'),
                  items: controller.schools.map((school) {
                    return DropdownMenuItem<School>(
                      value: school,
                      child: Text(school.name),
                    );
                  }).toList(),
                  onChanged: (value) => controller.selectedSchool.value = value,
                ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: ['general', 'urgent', 'event', 'holiday'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.toUpperCase()));
                }).toList(),
                onChanged: (value) => selectedType = value ?? 'general',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: ['low', 'normal', 'high', 'urgent'].map((priority) {
                  return DropdownMenuItem(value: priority, child: Text(priority.toUpperCase()));
                }).toList(),
                onChanged: (value) => selectedPriority = value ?? 'normal',
              ),
            ],
          )),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty || descriptionController.text.trim().isEmpty) {
                Get.snackbar('Error', 'Please fill all required fields.');
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
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showComposeMessageDialog(BuildContext context) {
    final recipientController = TextEditingController();
    final messageController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Compose Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: recipientController,
              decoration: const InputDecoration(labelText: 'Recipient'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(labelText: 'Message'),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Success', 'Message sent successfully');
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showComposeEmailDialog(BuildContext context) {
    final toController = TextEditingController();
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Compose Email'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: toController,
                decoration: const InputDecoration(labelText: 'To'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(labelText: 'Body'),
                maxLines: 6,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Info', 'Email saved as draft');
            },
            child: const Text('Save Draft'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Success', 'Email sent successfully');
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _openMessageThread(BuildContext context, int index) {
    Get.snackbar('Info', 'Opening message thread ${index + 1}');
  }

  void _openEmail(BuildContext context, int index) {
    Get.snackbar('Info', 'Opening email ${index + 1}');
  }

  void _markNotificationAsRead(int index) {
    Get.snackbar('Info', 'Notification ${index + 1} marked as read');
  }

  IconData _getNotificationIcon(int index) {
    final icons = [
      Icons.announcement,
      Icons.event,
      Icons.assignment,
      Icons.payment,
      Icons.school,
      Icons.group,
      Icons.warning,
      Icons.info,
    ];
    return icons[index % icons.length];
  }

  String _getNotificationTitle(int index) {
    final titles = [
      'New Announcement Posted',
      'Upcoming Event Reminder',
      'Assignment Due Tomorrow',
      'Fee Payment Reminder',
      'Class Schedule Updated',
      'Club Meeting Today',
      'System Maintenance Notice',
      'New Feature Available',
    ];
    return titles[index % titles.length];
  }

  String _getNotificationSubtitle(int index) {
    final subtitles = [
      'Check the latest school announcement',
      'Annual sports day is tomorrow',
      'Math assignment submission deadline',
      'Monthly fee payment is due',
      'Updated timetable available',
      'Drama club meeting at 3 PM',
      'System will be down for 2 hours',
      'New communication features added',
    ];
    return subtitles[index % subtitles.length];
  }

  Color _getTypeColor(String? type) {
    final context = Get.context!;
    switch (type) {
      case 'urgent': return context.theme.colorScheme.error.withOpacity(0.1);
      case 'event': return context.theme.colorScheme.primary.withOpacity(0.1);
      case 'holiday': return context.theme.colorScheme.secondary.withOpacity(0.1);
      default: return context.theme.colorScheme.surface.withOpacity(0.1);
    }
  }
  
  Color _getPriorityColor(String? priority) {
    final context = Get.context!;
    switch (priority) {
      case 'urgent': return context.theme.colorScheme.error.withOpacity(0.2);
      case 'high': return context.theme.colorScheme.tertiary.withOpacity(0.2);
      case 'low': return context.theme.colorScheme.secondary.withOpacity(0.2);
      default: return context.theme.colorScheme.surface.withOpacity(0.2);
    }
  }
  
  bool _canEdit(String? role) {
    return ['correspondent', 'principal', 'administrator'].contains(role);
  }
  
  bool _canDelete(String? role) {
    return ['correspondent', 'principal', 'administrator'].contains(role);
  }

  void _showViewAnnouncementDialog(BuildContext context, AnnouncementController controller, Map<String, dynamic> announcement) {
    Get.dialog(
      AlertDialog(
        title: Text(announcement['title'] ?? 'Announcement'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(announcement['description'] ?? ''),
              const SizedBox(height: 16),
              Text('Type: ${announcement['type']?.toString().toUpperCase() ?? 'GENERAL'}'),
              Text('Priority: ${announcement['priority']?.toString().toUpperCase() ?? 'NORMAL'}'),
              Text('Target Audience: ${announcement['targetAudience']?.join(', ') ?? 'All'}'),
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

  void _showEditAnnouncementDialog(BuildContext context, AnnouncementController controller, Map<String, dynamic> announcement) {
    final titleController = TextEditingController(text: announcement['title']);
    final descriptionController = TextEditingController(text: announcement['description']);
    
    final availableTypes = ['general', 'urgent', 'event', 'holiday'];
    final availablePriorities = ['low', 'normal', 'high', 'urgent'];
    
    String selectedType = announcement['type'] ?? 'general';
    String selectedPriority = announcement['priority'] ?? 'normal';
    
    if (!availableTypes.contains(selectedType)) {
      selectedType = 'general';
    }
    if (!availablePriorities.contains(selectedPriority)) {
      selectedPriority = 'normal';
    }
    
    Get.dialog(
      AlertDialog(
        title: const Text('Edit Announcement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: availableTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.toUpperCase()));
                }).toList(),
                onChanged: (value) => selectedType = value ?? 'general',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: availablePriorities.map((priority) {
                  return DropdownMenuItem(value: priority, child: Text(priority.toUpperCase()));
                }).toList(),
                onChanged: (value) => selectedPriority = value ?? 'normal',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty || descriptionController.text.trim().isEmpty) {
                Get.snackbar('Error', 'Please fill all fields');
                return;
              }
              
              controller.updateAnnouncement(
                id: announcement['_id'],
                academicYear: announcement['academicYear'] ?? '2024-25',
                title: titleController.text.trim(),
                description: descriptionController.text.trim(),
                type: selectedType,
                priority: selectedPriority,
                targetAudience: List<String>.from(announcement['targetAudience'] ?? ['all']),
              );
              Get.back();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AnnouncementController controller, String id) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text('Are you sure you want to delete this announcement?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteAnnouncement(id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
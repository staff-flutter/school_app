import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/communications_controller.dart';
import '../models/communication_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/permission_wrapper.dart';
import '../../../core/permissions/permission_system.dart';

class SimpleCommunicationsView extends GetView<CommunicationsController> {
  const SimpleCommunicationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Communications'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.announcement), text: 'Announcements'),
              Tab(icon: Icon(Icons.message), text: 'Messages'),
              Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: controller.loadCommunicationsData,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _AnnouncementsTab(),
            _MessagesTab(),
            _NotificationsTab(),
          ],
        ),
        floatingActionButton: PermissionWrapper(
          permission: Permission.NOTICES_CREATE,
          child: FloatingActionButton(
            onPressed: () => _showCreateAnnouncementDialog(context),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Widget _AnnouncementsTab() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.announcements.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.announcement_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No announcements found'),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.announcements.length,
        itemBuilder: (context, index) {
          final announcement = controller.announcements[index];
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
                          announcement.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (controller.canCreateAnnouncements)
                        PopupMenuButton<String>(
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditAnnouncementDialog(context, announcement);
                            } else if (value == 'delete') {
                              _showDeleteConfirmation(context, announcement.id);
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    announcement.content,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(announcement.priority),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          announcement.priority.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'By ${announcement.author}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      Text(
                        announcement.date,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _MessagesTab() {
    return Obx(() {
      if (controller.messages.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.message_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No messages found'),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.messages.length,
        itemBuilder: (context, index) {
          final message = controller.messages[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: message.isRead ? Colors.grey : AppTheme.primaryBlue,
                child: Icon(
                  _getMessageIcon(message.type),
                  color: Colors.white,
                ),
              ),
              title: Text(
                message.subject,
                style: TextStyle(
                  fontWeight: message.isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.content),
                  const SizedBox(height: 4),
                  Text(
                    'From: ${message.sender} • ${message.date}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              onTap: () {
                if (!message.isRead) {
                  controller.markMessageAsRead(message.id);
                }
              },
            ),
          );
        },
      );
    });
  }

  Widget _NotificationsTab() {
    return Obx(() {
      if (controller.notifications.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No notifications found'),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.notifications.length,
        itemBuilder: (context, index) {
          final notification = controller.notifications[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: notification.isRead ? Colors.grey : AppTheme.primaryBlue,
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: Colors.white,
                ),
              ),
              title: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.content),
                  const SizedBox(height: 4),
                  Text(
                    notification.date,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              onTap: () {
                if (!notification.isRead) {
                  controller.markNotificationAsRead(notification.id);
                }
              },
            ),
          );
        },
      );
    });
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData _getMessageIcon(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return Icons.assignment;
      case 'fee':
        return Icons.payment;
      case 'achievement':
        return Icons.star;
      default:
        return Icons.message;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'announcement':
        return Icons.announcement;
      case 'fee':
        return Icons.payment;
      case 'exam':
        return Icons.quiz;
      default:
        return Icons.notifications;
    }
  }

  void _showCreateAnnouncementDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedPriority = 'Medium';
    String selectedAudience = 'All Students';

    Get.dialog(
      AlertDialog(
        title: const Text('Create Announcement'),
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
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: ['Low', 'Medium', 'High'].map((priority) {
                  return DropdownMenuItem(value: priority, child: Text(priority));
                }).toList(),
                onChanged: (value) => selectedPriority = value ?? 'Medium',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedAudience,
                decoration: const InputDecoration(labelText: 'Target Audience'),
                items: ['All Students', 'Parents', 'Teachers', 'Staff'].map((audience) {
                  return DropdownMenuItem(value: audience, child: Text(audience));
                }).toList(),
                onChanged: (value) => selectedAudience = value ?? 'All Students',
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
              if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                Get.snackbar('Error', 'Please fill all fields');
                return;
              }

              final announcement = Announcement(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: titleController.text.trim(),
                content: contentController.text.trim(),
                author: 'Current User', // This should come from auth
                date: DateTime.now().toString().split(' ')[0],
                priority: selectedPriority,
                targetAudience: selectedAudience,
              );

              controller.addAnnouncement(announcement);
              Get.back();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditAnnouncementDialog(BuildContext context, Announcement announcement) {
    final titleController = TextEditingController(text: announcement.title);
    final contentController = TextEditingController(text: announcement.content);
    String selectedPriority = announcement.priority;
    String selectedAudience = announcement.targetAudience;

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
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: ['Low', 'Medium', 'High'].map((priority) {
                  return DropdownMenuItem(value: priority, child: Text(priority));
                }).toList(),
                onChanged: (value) => selectedPriority = value ?? 'Medium',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedAudience,
                decoration: const InputDecoration(labelText: 'Target Audience'),
                items: ['All Students', 'Parents', 'Teachers', 'Staff'].map((audience) {
                  return DropdownMenuItem(value: audience, child: Text(audience));
                }).toList(),
                onChanged: (value) => selectedAudience = value ?? 'All Students',
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
              if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                Get.snackbar('Error', 'Please fill all fields');
                return;
              }

              final updatedAnnouncement = Announcement(
                id: announcement.id,
                title: titleController.text.trim(),
                content: contentController.text.trim(),
                author: announcement.author,
                date: announcement.date,
                priority: selectedPriority,
                targetAudience: selectedAudience,
              );

              controller.updateAnnouncement(updatedAnnouncement);
              Get.back();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String announcementId) {
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
              controller.deleteAnnouncement(announcementId);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
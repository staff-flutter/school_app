import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/controllers/communications_controller.dart';
import 'package:school_app/models/communication_models.dart';
import 'package:school_app/widgets/permission_wrapper.dart';
import 'package:school_app/core/permissions/permission_system.dart';

// ─── Design tokens (no purple) ───────────────────────────────────────────────
const _kBlue       = Color(0xFF2563EB);
const _kBlueSoft   = Color(0xFFEFF6FF);
const _kTextDark   = Color(0xFF1A2A3A);
const _kMuted      = Color(0xFF8A9FC0);
const _kBorder     = Color(0xFFE2E8F0);
const _kBg         = Color(0xFFF5F7FA);

class SimpleCommunicationsView extends GetView<CommunicationsController> {
  const SimpleCommunicationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 20,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kBlueSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.campaign_rounded,
                    color: _kBlue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Communications',
                style: TextStyle(
                  color: _kTextDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: controller.loadCommunicationsData,
              icon: const Icon(Icons.refresh_rounded, color: _kMuted),
              tooltip: 'Refresh',
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: _kBorder, width: 1),
                ),
              ),
              child: TabBar(
                indicatorColor: _kBlue,
                indicatorWeight: 3,
                labelColor: _kBlue,
                unselectedLabelColor: _kMuted,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.announcement_outlined, size: 16),
                        SizedBox(width: 6),
                        Text('Announcements'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.message_outlined, size: 16),
                        SizedBox(width: 6),
                        Text('Messages'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_outlined, size: 16),
                        SizedBox(width: 6),
                        Text('Notifications'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _AnnouncementsTab(controller: controller),
            _MessagesTab(controller: controller),
            _NotificationsTab(controller: controller),
          ],
        ),
        floatingActionButton: PermissionWrapper(
          permission: Permission.NOTICES_CREATE,
          child: FloatingActionButton(
            onPressed: () => _showCreateAnnouncementDialog(context),
            backgroundColor: _kBlue,
            foregroundColor: Colors.white,
            elevation: 2,
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  // ─── Announcement Tab ───────────────────────────────────────────────────────

  Widget _AnnouncementsTab({required CommunicationsController controller}) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
            child: CircularProgressIndicator(color: _kBlue));
      }

      if (controller.announcements.isEmpty) {
        return _EmptyState(
          icon: Icons.announcement_outlined,
          label: 'No announcements yet',
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return ListView.builder(
            padding: EdgeInsets.all(isWide ? 24 : 16),
            itemCount: controller.announcements.length,
            itemBuilder: (context, index) {
              final a = controller.announcements[index];
              return _AnnouncementCard(
                announcement: a,
                canEdit: controller.canCreateAnnouncements,
                onEdit: () => _showEditAnnouncementDialog(context, a),
                onDelete: () =>
                    _showDeleteConfirmation(context, a.id),
              );
            },
          );
        },
      );
    });
  }

  // ─── Messages Tab ───────────────────────────────────────────────────────────

  Widget _MessagesTab({required CommunicationsController controller}) {
    return Obx(() {
      if (controller.messages.isEmpty) {
        return _EmptyState(
          icon: Icons.message_outlined,
          label: 'No messages found',
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return ListView.builder(
            padding: EdgeInsets.all(isWide ? 24 : 16),
            itemCount: controller.messages.length,
            itemBuilder: (context, index) {
              final message = controller.messages[index];
              return _MessageCard(
                message: message,
                onTap: () {
                  if (!message.isRead) {
                    controller.markMessageAsRead(message.id);
                  }
                },
              );
            },
          );
        },
      );
    });
  }

  // ─── Notifications Tab ──────────────────────────────────────────────────────

  Widget _NotificationsTab({required CommunicationsController controller}) {
    return Obx(() {
      if (controller.notifications.isEmpty) {
        return _EmptyState(
          icon: Icons.notifications_outlined,
          label: 'No notifications found',
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return ListView.builder(
            padding: EdgeInsets.all(isWide ? 24 : 16),
            itemCount: controller.notifications.length,
            itemBuilder: (context, index) {
              final n = controller.notifications[index];
              return _NotificationCard(
                notification: n,
                onTap: () {
                  if (!n.isRead) {
                    controller.markNotificationAsRead(n.id);
                  }
                },
              );
            },
          );
        },
      );
    });
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFDC2626);
      case 'medium':
        return const Color(0xFFD97706);
      case 'low':
        return const Color(0xFF16A34A);
      default:
        return _kBlue;
    }
  }

  IconData _getMessageIcon(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return Icons.assignment_outlined;
      case 'fee':
        return Icons.payment_outlined;
      case 'achievement':
        return Icons.star_outline;
      default:
        return Icons.message_outlined;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'announcement':
        return Icons.announcement_outlined;
      case 'fee':
        return Icons.payment_outlined;
      case 'exam':
        return Icons.quiz_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  // ─── Dialogs ────────────────────────────────────────────────────────────────

  void _showCreateAnnouncementDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedPriority = 'Medium';
    String selectedAudience = 'All Students';

    Get.dialog(
      _AnnouncementDialog(
        title: 'Create Announcement',
        titleController: titleController,
        contentController: contentController,
        selectedPriority: selectedPriority,
        selectedAudience: selectedAudience,
        onSave: (priority, audience) {
          if (titleController.text.trim().isEmpty ||
              contentController.text.trim().isEmpty) {
            Get.snackbar('Error', 'Please fill all fields');
            return;
          }
          final announcement = Announcement(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: titleController.text.trim(),
            content: contentController.text.trim(),
            author: 'Current User',
            date: DateTime.now().toString().split(' ')[0],
            priority: priority,
            targetAudience: audience,
          );
          controller.addAnnouncement(announcement);
          Get.back();
        },
      ),
    );
  }

  void _showEditAnnouncementDialog(
      BuildContext context, Announcement announcement) {
    final titleController =
        TextEditingController(text: announcement.title);
    final contentController =
        TextEditingController(text: announcement.content);

    Get.dialog(
      _AnnouncementDialog(
        title: 'Edit Announcement',
        titleController: titleController,
        contentController: contentController,
        selectedPriority: announcement.priority,
        selectedAudience: announcement.targetAudience,
        saveLabel: 'Update',
        onSave: (priority, audience) {
          if (titleController.text.trim().isEmpty ||
              contentController.text.trim().isEmpty) {
            Get.snackbar('Error', 'Please fill all fields');
            return;
          }
          final updated = Announcement(
            id: announcement.id,
            title: titleController.text.trim(),
            content: contentController.text.trim(),
            author: announcement.author,
            date: announcement.date,
            priority: priority,
            targetAudience: audience,
          );
          controller.updateAnnouncement(updated);
          Get.back();
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String id) {
    Get.dialog(AlertDialog(
      title: const Text('Delete Announcement'),
      content:
          const Text('Are you sure you want to delete this announcement?'),
      actions: [
        TextButton(
            onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            controller.deleteAnnouncement(id);
            Get.back();
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white),
          child: const Text('Delete'),
        ),
      ],
    ));
  }
}

// ─── Card Widgets ─────────────────────────────────────────────────────────────

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AnnouncementCard({
    required this.announcement,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high':
        return const Color(0xFFDC2626);
      case 'medium':
        return const Color(0xFFD97706);
      case 'low':
        return const Color(0xFF16A34A);
      default:
        return _kBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                Expanded(
                  child: Text(
                    announcement.title,
                    style: const TextStyle(
                      color: _kTextDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (canEdit)
                  PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                          value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete',
                              style:
                                  TextStyle(color: Color(0xFFDC2626)))),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    icon: const Icon(Icons.more_vert_rounded,
                        color: _kMuted, size: 20),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              announcement.content,
              style: const TextStyle(
                  color: Color(0xFF4A5568), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _priorityColor(announcement.priority)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    announcement.priority.toUpperCase(),
                    style: TextStyle(
                      color: _priorityColor(announcement.priority),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('By ${announcement.author}',
                    style: const TextStyle(
                        color: _kMuted, fontSize: 12)),
                const Spacer(),
                Text(announcement.date,
                    style: const TextStyle(
                        color: _kMuted, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final dynamic message;
  final VoidCallback onTap;

  const _MessageCard({required this.message, required this.onTap});

  IconData _icon(String type) {
    switch (type.toLowerCase()) {
      case 'assignment':
        return Icons.assignment_outlined;
      case 'fee':
        return Icons.payment_outlined;
      case 'achievement':
        return Icons.star_outline;
      default:
        return Icons.message_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: message.isRead ? _kBorder : _kBlue.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: message.isRead
                    ? const Color(0xFFF1F5F9)
                    : _kBlueSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _icon(message.type),
                color: message.isRead ? _kMuted : _kBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.subject,
                    style: TextStyle(
                      color: _kTextDark,
                      fontSize: 14,
                      fontWeight: message.isRead
                          ? FontWeight.w500
                          : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.content,
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'From: ${message.sender} · ${message.date}',
                    style: const TextStyle(
                        color: _kMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (!message.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                    color: _kBlue, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final dynamic notification;
  final VoidCallback onTap;

  const _NotificationCard(
      {required this.notification, required this.onTap});

  IconData _icon(String type) {
    switch (type.toLowerCase()) {
      case 'announcement':
        return Icons.announcement_outlined;
      case 'fee':
        return Icons.payment_outlined;
      case 'exam':
        return Icons.quiz_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: notification.isRead
                  ? _kBorder
                  : _kBlue.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: notification.isRead
                    ? const Color(0xFFF1F5F9)
                    : _kBlueSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _icon(notification.type),
                color: notification.isRead ? _kMuted : _kBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      color: _kTextDark,
                      fontSize: 14,
                      fontWeight: notification.isRead
                          ? FontWeight.w500
                          : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.content,
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.date,
                    style: const TextStyle(
                        color: _kMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                    color: _kBlue, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;

  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kBlueSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: _kBlue),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
                color: _kMuted,
                fontSize: 15,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ─── Announcement Dialog ──────────────────────────────────────────────────────

class _AnnouncementDialog extends StatefulWidget {
  final String title;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final String selectedPriority;
  final String selectedAudience;
  final String saveLabel;
  final void Function(String priority, String audience) onSave;

  const _AnnouncementDialog({
    required this.title,
    required this.titleController,
    required this.contentController,
    required this.selectedPriority,
    required this.selectedAudience,
    required this.onSave,
    this.saveLabel = 'Create',
  });

  @override
  State<_AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<_AnnouncementDialog> {
  late String _priority;
  late String _audience;

  @override
  void initState() {
    super.initState();
    _priority = widget.selectedPriority;
    _audience = widget.selectedAudience;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: widget.titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: ['Low', 'Medium', 'High']
                  .map((p) =>
                      DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _priority = v ?? 'Medium'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _audience,
              decoration:
                  const InputDecoration(labelText: 'Target Audience'),
              items: ['All Students', 'Parents', 'Teachers', 'Staff']
                  .map((a) =>
                      DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _audience = v ?? 'All Students'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => widget.onSave(_priority, _audience),
          style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue, foregroundColor: Colors.white),
          child: Text(widget.saveLabel),
        ),
      ],
    );
  }
}
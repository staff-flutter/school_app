import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/announcement_controller.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';
import 'announcement_detail_page.dart';
// ══════════════════════════════════════════════════════════════════════════
// BELL ICON — drop this into any AppBar's actions list
// ══════════════════════════════════════════════════════════════════════════
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController());

    return Obx(() {
      final count = controller.unreadCount.value;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,color: Colors.white,),
            onPressed: () {
              Get.to(() => const NotificationPage());
            },
          ),
          if (count > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

// ══════════════════════════════════════════════════════════════════════════
// FULL NOTIFICATION LIST PAGE
// ══════════════════════════════════════════════════════════════════════════
class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Notifications',
            style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          Obx(() => controller.unreadCount.value > 0
              ? TextButton(
            onPressed: controller.markAllRead,
            child: const Text('Mark all read',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          )
              : const SizedBox.shrink()),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: Obx(() {
          if (controller.isLoading.value && controller.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.notifications.isEmpty) {
            return LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_off_outlined,
                              size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('No notifications yet',
                              style: TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: controller.notifications.length,
            itemBuilder: (context, index) {
              final n = controller.notifications[index];
              return Dismissible(
                key: ValueKey(n.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: const Color(0xFFDC2626),
                  child: const Icon(Icons.delete_rounded, color: Colors.white),
                ),
                onDismissed: (_) => controller.deleteNotification(n.id),
                child: _NotificationTile(
                  notification: n,
                  onTap: () async {
                    if (!n.isRead) await controller.markRead(n.id);

                    // Only navigate to the announcement detail if this notification
                    // actually references an announcement
                    if (n.referenceModel?.toLowerCase() == 'announcement' &&
                        n.referenceId != null &&
                        n.referenceId!.isNotEmpty) {
                      final annController = Get.isRegistered<AnnouncementController>()
                          ? Get.find<AnnouncementController>()
                          : Get.put(AnnouncementController());

                      await annController.getAnnouncement(n.referenceId!);
                      final fresh = annController.selectedAnnouncement.value;

                      if (fresh != null) {
                        Get.to(() => AnnouncementDetailPage(notice: fresh));
                      } else {
                        Get.snackbar('Error', 'Could not load announcement details');
                      }
                    } else if (n.path != null && n.path!.isNotEmpty) {
                      Get.toNamed(n.path!); // fallback for other notification types
                    }
                  },
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  Color get _accent {
    switch (notification.type.toLowerCase()) {
      case 'urgent':
        return const Color(0xFFDC2626);
      case 'event':
        return const Color(0xFF3B82F6);
      case 'holiday':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF1D4ED8);
    }
  }

  IconData get _icon {
    switch (notification.type.toLowerCase()) {
      case 'urgent':
        return Icons.warning_amber_rounded;
      case 'event':
        return Icons.event_rounded;
      case 'holiday':
        return Icons.celebration_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  String get _relativeTime {
    final diff = DateTime.now().difference(notification.createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${notification.createdAt.day}/${notification.createdAt.month}/${notification.createdAt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnread ? _accent.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnread ? _accent.withOpacity(0.25) : const Color(0xFFE2E8F0),
            width: isUnread ? 1.2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, size: 18, color: _accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _relativeTime,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
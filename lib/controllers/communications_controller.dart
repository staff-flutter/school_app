import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:school_app/core/theme/app_theme.dart';
import 'package:school_app/services/api_service.dart';
import 'package:school_app/constants/api_constants.dart';
import 'package:school_app/controllers/auth_controller.dart';
import 'package:school_app/models/communication_models.dart';

class CommunicationsController extends GetxController {
  final ApiService _apiService = Get.find();
  final AuthController _authController = Get.find();
  
  final isLoading = false.obs;
  final announcements = <Announcement>[].obs;
  final messages = <Message>[].obs;
  final notifications = <NotificationItem>[].obs;

  String get _userRole => _authController.user.value?.role?.toLowerCase() ?? 'parent';
  String? get _schoolId => _authController.user.value?.schoolId;

  void _showSnackbar(String title, String message, Color color) {
    Get.snackbar(title, message, backgroundColor: color, colorText: Colors.white);
  }

  @override
  void onInit() {
    super.onInit();
    loadCommunicationsData();
  }

  Future<void> loadCommunicationsData() async {
    await Future.wait([
      loadAnnouncements(),
      loadMessages(),
      loadNotifications(),
    ]);
  }

  Future<void> loadAnnouncements() async {
    if (_schoolId == null) {
      
      return;
    }
    
    try {
      isLoading.value = true;

      final response = await _apiService.get(
        '/api/announcement/getall',
        queryParameters: {'schoolId': _schoolId},
      );

      if (response.data['ok'] == true) {
        final announcementList = response.data['data'] as List;
        announcements.value = announcementList.map((json) => 
          Announcement.fromJson(json)
        ).toList();
        
      } else {
        
        _loadDummyAnnouncements(); // Fallback to dummy data
      }
    } catch (e) {
      
      _loadDummyAnnouncements(); // Fallback to dummy data
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMessages() async {
    _loadDummyMessages();
  }

  Future<void> loadNotifications() async {
    _loadDummyNotifications();
  }

  void _loadDummyAnnouncements() {
    announcements.value = [
      Announcement(
        id: '1',
        title: 'School Reopening Notice',
        content: 'School will reopen on Monday, January 15th, 2024.',
        author: 'Principal',
        date: '2024-01-10',
        priority: 'High',
        targetAudience: 'All Students',
      ),
      Announcement(
        id: '2',
        title: 'Parent-Teacher Meeting',
        content: 'Parent-Teacher meeting is scheduled for January 20th, 2024.',
        author: 'Vice Principal',
        date: '2024-01-08',
        priority: 'Medium',
        targetAudience: 'Parents',
      ),
    ];
  }

  void _loadDummyMessages() {
    messages.value = [
      Message(
        id: '1',
        subject: 'Assignment Reminder',
        content: 'Please submit your assignment.',
        sender: 'Teacher',
        recipient: 'Student',
        date: '2024-01-12',
        isRead: false,
        type: 'Assignment',
      ),
    ];
  }

  void _loadDummyNotifications() {
    notifications.value = [
      NotificationItem(
        id: '1',
        title: 'New Announcement',
        content: 'A new announcement has been posted.',
        date: '2024-01-10',
        isRead: false,
        type: 'Announcement',
      ),
    ];
  }

  Future<void> addAnnouncement(Announcement announcement) async {
    announcements.add(announcement);
    _showSnackbar('Success', 'Announcement posted', AppTheme.successGreen);
  }

  Future<void> updateAnnouncement(Announcement announcement) async {
    final index = announcements.indexWhere((a) => a.id == announcement.id);
    if (index != -1) {
      announcements[index] = announcement;
      _showSnackbar('Success', 'Announcement updated', AppTheme.successGreen);
    }
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    announcements.removeWhere((a) => a.id == announcementId);
    _showSnackbar('Success', 'Announcement deleted', AppTheme.successGreen);
  }

  void markMessageAsRead(String messageId) {
    int index = messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      messages[index] = Message(
        id: messages[index].id,
        subject: messages[index].subject,
        content: messages[index].content,
        sender: messages[index].sender,
        recipient: messages[index].recipient,
        date: messages[index].date,
        isRead: true,
        type: messages[index].type,
      );
    }
  }

  void markNotificationAsRead(String notificationId) {
    int index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      notifications[index] = NotificationItem(
        id: notifications[index].id,
        title: notifications[index].title,
        content: notifications[index].content,
        date: notifications[index].date,
        isRead: true,
        type: notifications[index].type,
      );
    }
  }

  bool get canCreateAnnouncements => true;
  bool get canViewAnnouncements => true;
  bool get isReadOnlyRole => ['parent', 'student'].contains(_userRole);
  bool get canSendMessages => !isReadOnlyRole;
  
  int get unreadMessagesCount => messages.where((m) => !m.isRead).length;
  int get unreadNotificationsCount => notifications.where((n) => !n.isRead).length;
}

class Message {
  final String id;
  final String subject;
  final String content;
  final String sender;
  final String recipient;
  final String date;
  final bool isRead;
  final String type;

  Message({
    required this.id,
    required this.subject,
    required this.content,
    required this.sender,
    required this.recipient,
    required this.date,
    required this.isRead,
    required this.type,
  });
}

class NotificationItem {
  final String id;
  final String title;
  final String content;
  final String date;
  final bool isRead;
  final String type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.isRead,
    required this.type,
  });
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'auth_controller.dart';
import '../models/notification_model.dart'; // adjust path if you place the model elsewhere

class NotificationController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();

  final RxList<AppNotification> notifications = <AppNotification>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;

  String get _token => _authController.storage.read('token') ?? '';

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Accept': 'application/json',
  };

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
    fetchUnreadCount();
  }

  // ------------------------------- FETCH ALL -------------------------------

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/notifications/');
      final res = await http.get(uri, headers: _headers);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List<dynamic> list = body['data'] ?? [];
        notifications.value =
            list.map((e) => AppNotification.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('🔴 fetchNotifications error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ----------------------------- UNREAD COUNT -------------------------------

  Future<void> fetchUnreadCount() async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/notifications/unread-count');
      final res = await http.get(uri, headers: _headers);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        unreadCount.value = (body['data']?['count'] ?? 0) as int;
      }
    } catch (e) {
      debugPrint('🔴 fetchUnreadCount error: $e');
    }
  }

  // --------------------------- GET ONE (marks read) -------------------------

  Future<AppNotification?> getNotification(String id) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/notifications/$id');
      final res = await http.get(uri, headers: _headers);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final notif = AppNotification.fromJson(body['data']);

        // Reflect the read state locally without a full refetch
        final index = notifications.indexWhere((n) => n.id == id);
        if (index != -1 && !notifications[index].isRead) {
          notifications[index] = AppNotification.fromJson({
            ...body['data'],
            'isRead': true,
          });
          if (unreadCount.value > 0) unreadCount.value--;
        }
        return notif;
      }
    } catch (e) {
      debugPrint('🔴 getNotification error: $e');
    }
    return null;
  }

  // ------------------------------- MARK READ --------------------------------

  Future<void> markRead(String id) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/notifications/mark-read/$id');
      final res = await http.patch(uri, headers: _headers);

      if (res.statusCode == 200) {
        final index = notifications.indexWhere((n) => n.id == id);
        if (index != -1 && !notifications[index].isRead) {
          final n = notifications[index];
          notifications[index] = AppNotification(
            id: n.id, schoolId: n.schoolId, type: n.type, title: n.title,
            message: n.message, referenceId: n.referenceId, referenceModel: n.referenceModel,
            path: n.path, targetAudience: n.targetAudience, targetClasses: n.targetClasses,
            targetSections: n.targetSections, targetStudents: n.targetStudents,
            academicYear: n.academicYear, createdBy: n.createdBy, createdAt: n.createdAt,
            updatedAt: n.updatedAt, isRead: true,
          );
          if (unreadCount.value > 0) unreadCount.value--;
        }
      }
    } catch (e) {
      debugPrint('🔴 markRead error: $e');
    }
  }

  // ----------------------------- MARK ALL READ -------------------------------

  Future<void> markAllRead() async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/notifications/mark-allread');
      final res = await http.patch(uri, headers: _headers);

      if (res.statusCode == 200) {
        notifications.value = notifications
            .map((n) => AppNotification(
          id: n.id, schoolId: n.schoolId, type: n.type, title: n.title,
          message: n.message, referenceId: n.referenceId, referenceModel: n.referenceModel,
          path: n.path, targetAudience: n.targetAudience, targetClasses: n.targetClasses,
          targetSections: n.targetSections, targetStudents: n.targetStudents,
          academicYear: n.academicYear, createdBy: n.createdBy, createdAt: n.createdAt,
          updatedAt: n.updatedAt, isRead: true,
        ))
            .toList();
        unreadCount.value = 0;
        Get.snackbar('Done', 'All notifications marked as read',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      debugPrint('🔴 markAllRead error: $e');
    }
  }

  // -------------------------------- DELETE -----------------------------------

  Future<void> deleteNotification(String id) async {
    // Optimistic removal — restore on failure
    final removedIndex = notifications.indexWhere((n) => n.id == id);
    if (removedIndex == -1) return;
    final removed = notifications[removedIndex];
    final wasUnread = !removed.isRead;
    notifications.removeAt(removedIndex);
    if (wasUnread && unreadCount.value > 0) unreadCount.value--;

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/notifications/$id');
      final res = await http.delete(uri, headers: _headers);

      if (res.statusCode != 200) {
        // restore on failure
        notifications.insert(removedIndex, removed);
        if (wasUnread) unreadCount.value++;
        Get.snackbar('Error', 'Failed to delete notification',
            backgroundColor: Colors.red, colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      notifications.insert(removedIndex, removed);
      if (wasUnread) unreadCount.value++;
      debugPrint('🔴 deleteNotification error: $e');
    }
  }

  Future<void> refresh() async {
    await fetchNotifications();
    await fetchUnreadCount();
  }
}
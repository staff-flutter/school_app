import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../controllers/auth_controller.dart';
import '../controllers/announcement_controller.dart';
import '../controllers/notification_controller.dart';
import '../screens/announcement_detail_page.dart';

/// Must be a TOP-LEVEL function (not inside a class) — this is how FCM
/// wakes the app to handle a push while it's fully killed/backgrounded.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No UI work here — Android shows the system notification automatically
  // for messages that include a "notification" block. This handler exists
  // so FCM can silently process "data" payloads even when the app isn't running.
  print('🔔 Background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Ask permission (iOS requires this explicitly; Android 13+ too)
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // 2. Set up local notifications for FOREGROUND display
    // (Android/iOS auto-display system notifications only when app is
    // backgrounded/killed — while the app is open, we must show it ourselves)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          _handleTapPayload(jsonDecode(response.payload!));
        }
      },
    );

    // 3. Get and register the device token with your backend
    final token = await _fcm.getToken();
    if (token != null) await _registerToken(token);
    _fcm.onTokenRefresh.listen(_registerToken);

    // 4. Foreground messages — app is open, so show a local notification manually
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
      // Also bump the bell badge immediately since a new notice just arrived
      if (Get.isRegistered<NotificationController>()) {
        Get.find<NotificationController>().refresh();
      }
    });

    // 5. User tapped a notification while app was backgrounded (not killed)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleTapPayload(message.data);
    });

    // 6. App was fully killed and opened via tapping a notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleTapPayload(initialMessage.data);
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'school_app_notices', // channel id
      'School Notices',     // channel name
      channelDescription: 'Announcements and notices from your school',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data), // carries notificationId, referenceId, path, etc.
    );
  }

  // ── TAP HANDLING ────────────────────────────────────────────────────────
  // This is the piece that decides what happens when the parent taps the push.
  // We prefer opening AnnouncementDetailPage directly (using referenceId),
  // since that's the actual screen your notice board flow uses — falling
  // back to a plain named route only if referenceId isn't present.
  Future<void> _handleTapPayload(Map<String, dynamic> data) async {
    final notificationId = data['notificationId'] ?? data['_id'];
    final referenceId = data['referenceId']; // the announcement's _id
    final referenceModel = data['referenceModel']; // e.g. "Announcement"
    final path = data['path'];

    // Mark the notification itself as read (fire-and-forget)
    if (notificationId != null) {
      _markReadOnOpen(notificationId);
      if (Get.isRegistered<NotificationController>()) {
        Get.find<NotificationController>().refresh();
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Preferred path: fetch the full announcement and open its detail page,
      // exactly like tapping a card in NoticeBoardScreenUi does.
      if (referenceId != null &&
          referenceId.toString().isNotEmpty &&
          (referenceModel == null || referenceModel.toString().toLowerCase().contains('announce'))) {
        try {
          final announcementController = Get.isRegistered<AnnouncementController>()
              ? Get.find<AnnouncementController>()
              : Get.put(AnnouncementController());

          await announcementController.getAnnouncement(referenceId.toString());
          final notice = announcementController.selectedAnnouncement.value;

          if (notice != null) {
            Get.to(() => AnnouncementDetailPage(notice: notice));
            return;
          }
        } catch (e) {
          debugPrint('⚠️ Failed to open announcement from push: $e');
        }
      }

      // Fallback: deep-link by path if referenceId lookup wasn't available
      if (path != null && path.toString().isNotEmpty) {
        Get.toNamed(path);
      }
    });
  }

  Future<void> _markReadOnOpen(String notificationId) async {
    try {
      final auth = Get.find<AuthController>();
      final token = auth.storage.read('token');
      await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/notifications/$notificationId'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
    } catch (_) {}
  }

  Future<void> _registerToken(String token) async {
    try {
      final auth = Get.find<AuthController>();
      final authToken = auth.storage.read('token');
      if (authToken == null) return; // not logged in yet — register after login instead

      final uri = Uri.parse('${ApiConstants.baseUrl}/api/user/register-fcm-token');
      final res = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'fcmToken': token}),
      );

      if (res.statusCode == 200) {
        debugPrint('✅ FCM token registered successfully');
      } else {
        debugPrint('⚠️ FCM token registration failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to register FCM token: $e');
    }
  }
}
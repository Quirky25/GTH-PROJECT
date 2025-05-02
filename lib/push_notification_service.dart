import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:collection';

// Message class to store notification data
class NotificationMessage {
  final String title;
  final String body;
  final DateTime timestamp;

  NotificationMessage(this.title, this.body) : timestamp = DateTime.now();
}

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // Keep track of notifications
  static final Queue<NotificationMessage> _messageHistory = Queue<NotificationMessage>();
  static const int _maxMessageHistory = 5; // Keep last 5 messages
  static const String _groupKey = 'com.gasalert.messages';
  static final int _notificationId = 0;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'gas_alert_channel', // Unique ID
    'Gas Alerts', // Channel Name
    description: 'Notifications for gas level alerts',
    importance: Importance.high,
    playSound: true,
    showBadge: true,
    enableVibration: true,
    enableLights: true,
  );

  // 🔹 Initialize push notifications
  static Future<void> initialize() async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Request permission for iOS & Android 13+
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint("Push notifications are denied.");
      return;
    }

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // Handle notification taps
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Clear all notifications when tapped
        if (response.payload == 'group_notification') {
          _messageHistory.clear();
          _flutterLocalNotificationsPlugin.cancelAll();
        }
      },
    );

    // Handle messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showNotification(message.notification?.title ?? "Alert", message.notification?.body ?? "Check gas levels!");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Push notification opened: ${message.notification?.title}");
      // Clear notifications when opened from background
      _messageHistory.clear();
      _flutterLocalNotificationsPlugin.cancelAll();
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // 🔹 Background message handler
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    debugPrint("Push notification received in background: ${message.notification?.title}");
  }

  // ✅ Public method to send a notification manually
  static Future<void> showNotification(String title, String body) async {
    // Cancel any existing notifications first
    await _flutterLocalNotificationsPlugin.cancelAll();

    // Add new message to history
    final message = NotificationMessage(title, body);
    _messageHistory.addFirst(message);
    
    // Keep only last N messages
    while (_messageHistory.length > _maxMessageHistory) {
      _messageHistory.removeLast();
    }

    final List<NotificationMessage> messages = _messageHistory.toList();
    
    // Create inbox style for stacked notifications
    final InboxStyleInformation inboxStyle = InboxStyleInformation(
      messages.map((msg) => '${msg.title}: ${msg.body}').toList(),
      contentTitle: messages.length > 1 ? '${messages.length} Gas Alerts' : 'Gas Alert',
      summaryText: messages.length > 1 ? 'Tap to view all alerts' : null,
    );

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'gas_alert_channel',
      'Gas Alerts',
      channelDescription: 'Notifications for gas level alerts',
      importance: Importance.high,
      priority: Priority.high,
      groupKey: _groupKey,
      setAsGroupSummary: true,
      styleInformation: inboxStyle,
      playSound: true,
      enableLights: true,
      enableVibration: true,
      fullScreenIntent: true,
      autoCancel: true,
      groupAlertBehavior: GroupAlertBehavior.summary,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Show single notification that contains all messages
    await _flutterLocalNotificationsPlugin.show(
      0, // Fixed ID for the group notification
      messages.length > 1 ? '${messages.length} new alerts' : title,
      messages.length > 1 ? 'Tap to view all alerts' : body,
      platformChannelSpecifics,
      payload: 'group_notification',
    );
  }
}

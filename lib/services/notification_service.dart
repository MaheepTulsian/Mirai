import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/notification_data.dart';
import 'notification_navigator.dart';

/// Comprehensive Firebase Cloud Messaging notification service
///
/// Handles:
/// - FCM token management and Firestore storage
/// - Notification permissions (iOS & Android 13+)
/// - Foreground local notifications
/// - Background and terminated message handling
/// - Deep link navigation from notifications
/// - Android notification channels
class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Notification channel configuration
  static const String _channelId = 'default';
  static const String _channelName = 'Default Notifications';
  static const String _channelDescription =
      'Receive updates about jobs, internships, and more';

  /// Global navigator key for navigation from anywhere
  late GlobalKey<NavigatorState> navigatorKey;

  /// Initialize the notification service
  ///
  /// Call this in main.dart after Firebase initialization
  Future<void> initialize(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;

    try {
      // Step 1: Request permissions
      await _requestPermissions();

      // Step 2: Setup local notifications (for foreground)
      await _setupLocalNotifications();

      // Step 3: Setup notification channels (Android)
      await _setupAndroidNotificationChannel();

      // Step 4: Get and save FCM token to Firestore
      await _initializeFCMToken();

      // Step 5: Setup message handlers
      await _setupMessageHandlers();

      // Step 6: Handle notification that opened the app (from terminated state)
      await _handleInitialMessage();

      debugPrint('NotificationService: Initialization complete');
    } catch (e) {
      debugPrint('NotificationService: Error during initialization: $e');
    }
  }

  /// Request notification permissions (iOS & Android 13+)
  Future<void> _requestPermissions() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('NotificationService: Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('NotificationService: User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('NotificationService: User granted provisional permission');
      } else {
        debugPrint('NotificationService: User declined or has not accepted permission');
      }
    } catch (e) {
      debugPrint('NotificationService: Error requesting permission: $e');
    }
  }

  /// Setup local notifications for foreground display
  Future<void> _setupLocalNotifications() async {
    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize with callback for notification taps
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    debugPrint('NotificationService: Local notifications initialized');
  }

  /// Setup Android notification channel
  Future<void> _setupAndroidNotificationChannel() async {
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      debugPrint('NotificationService: Android notification channel created');
    }
  }

  /// Get FCM token and save to Firestore
  Future<void> _initializeFCMToken() async {
    try {
      // Get the token
      final token = await _fcm.getToken();
      if (token != null) {
        debugPrint('NotificationService: FCM Token: $token');
        await _saveFCMTokenToFirestore(token);
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        debugPrint('NotificationService: Token refreshed: $newToken');
        _saveFCMTokenToFirestore(newToken);
      });
    } catch (e) {
      debugPrint('NotificationService: Error initializing FCM token: $e');
    }
  }

  /// Save FCM token to Firestore users/{uid}/fcmToken field
  Future<void> _saveFCMTokenToFirestore(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('NotificationService: No authenticated user, cannot save token');
        return;
      }

      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('NotificationService: FCM token saved to Firestore for user ${user.uid}');
    } catch (e) {
      debugPrint('NotificationService: Error saving FCM token to Firestore: $e');
    }
  }

  /// Setup message handlers for different app states
  Future<void> _setupMessageHandlers() async {
    // FOREGROUND: When app is open and in use
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // BACKGROUND: When app is in background and user taps notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    debugPrint('NotificationService: Message handlers setup complete');
  }

  /// Handle foreground messages - display local notification
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('NotificationService: Foreground message received');
    debugPrint('  Message ID: ${message.messageId}');
    debugPrint('  Title: ${message.notification?.title}');
    debugPrint('  Body: ${message.notification?.body}');
    debugPrint('  Data: ${message.data}');

    // Display local notification
    await _showLocalNotification(message);
  }

  /// Handle notification tap (background or foreground)
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    debugPrint('NotificationService: Notification tapped');
    debugPrint('  Data: ${message.data}');

    // Parse notification data and navigate
    if (message.data.isNotEmpty) {
      await _navigateFromNotification(message.data);
    }
  }

  /// Handle notification that opened the app from terminated state
  Future<void> _handleInitialMessage() async {
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('NotificationService: App opened from terminated state via notification');
      debugPrint('  Data: ${initialMessage.data}');

      // Navigate after a short delay to ensure app is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        if (initialMessage.data.isNotEmpty) {
          _navigateFromNotification(initialMessage.data);
        }
      });
    }
  }

  /// Display local notification (for foreground messages)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    try {
      // Android notification details
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show notification with data payload
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        details,
        payload: message.data.toString(),
      );

      debugPrint('NotificationService: Local notification displayed');
    } catch (e) {
      debugPrint('NotificationService: Error showing local notification: $e');
    }
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('NotificationService: Local notification tapped');
    debugPrint('  Payload: ${response.payload}');

    // Parse payload and navigate
    // Note: payload is stored as string, need to parse it back to Map
    // For now, we'll handle this in a future enhancement
    // TODO: Properly serialize/deserialize notification data for local notifications
  }

  /// Navigate based on notification data
  Future<void> _navigateFromNotification(Map<String, dynamic> data) async {
    try {
      final notificationData = NotificationData.fromMap(data);
      debugPrint('NotificationService: Navigating to ${notificationData.screen}');

      // Get current context from navigator key
      final context = navigatorKey.currentContext;
      if (context != null) {
        await NotificationNavigator.navigate(context, notificationData);
      } else {
        debugPrint('NotificationService: No context available for navigation');
      }
    } catch (e) {
      debugPrint('NotificationService: Error navigating from notification: $e');
    }
  }

  /// Public method: Get current FCM token
  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('NotificationService: Error getting token: $e');
      return null;
    }
  }

  /// Public method: Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      debugPrint('NotificationService: Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('NotificationService: Error subscribing to topic: $e');
    }
  }

  /// Public method: Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      debugPrint('NotificationService: Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('NotificationService: Error unsubscribing from topic: $e');
    }
  }

  /// Public method: Manually save FCM token (call after login)
  Future<void> saveFCMToken() async {
    final token = await getToken();
    if (token != null) {
      await _saveFCMTokenToFirestore(token);
    }
  }
}

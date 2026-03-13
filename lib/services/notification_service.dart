import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

const AndroidNotificationChannel _ayeyoNotificationChannel =
    AndroidNotificationChannel(
      'ayeyo_notifications',
      'Ayeyo Notifications',
      description: 'Notifications for menu updates and order activity.',
      importance: Importance.high,
    );

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class InAppNotification {
  const InAppNotification({
    required this.title,
    required this.body,
    this.route,
    this.receivedAt,
  });

  final String title;
  final String body;
  final String? route;
  final DateTime? receivedAt;
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ValueNotifier<InAppNotification?> currentNotification =
      ValueNotifier<InAppNotification?>(null);

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_ayeyoNotificationChannel);

    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_publishFromRemoteMessage);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _publishFromRemoteMessage(initialMessage);
    }

    _messaging.onTokenRefresh.listen((token) async {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        return;
      }
      await syncUserToken(userId);
    });

    _initialized = true;
  }

  Future<void> syncUserToken(String userId) async {
    final settings = await _messaging.getNotificationSettings();
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'lastNotificationToken': token,
      'notificationPermissionStatus': settings.authorizationStatus.name,
      'notificationsUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void clearNotification() {
    currentNotification.value = null;
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _publishFromRemoteMessage(message);

    final notification = message.notification;
    if (notification == null) {
      return;
    }

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _ayeyoNotificationChannel.id,
          _ayeyoNotificationChannel.name,
          channelDescription: _ayeyoNotificationChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  void _publishFromRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    final title =
        notification?.title ??
        message.data['title'] as String? ??
        'Ayeyo update';
    final body =
        notification?.body ??
        message.data['body'] as String? ??
        'You have a new notification.';

    currentNotification.value = InAppNotification(
      title: title,
      body: body,
      route: message.data['route'] as String?,
      receivedAt: DateTime.now(),
    );
  }
}

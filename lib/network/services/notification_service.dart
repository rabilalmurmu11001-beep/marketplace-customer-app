import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';
import '../../routing/app_router.dart';
import '../../security/secureStorage.dart';

/// Top-level background message handler for FCM.
///
/// MUST be annotated with `@pragma('vm:entry-point')` so Flutter can invoke it
/// from an isolated background isolate when the app is in background or terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("Handling background FCM message ID: ${message.messageId}");
  debugPrint("Background data payload: ${message.data}");
}

/// Service class managing push notification lifecycle, channels, permissions,
/// foreground banner display, and navigation.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important push notifications.',
    importance: Importance.max,
    playSound: true,
  );

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  bool _isInitialized = false;

  /// Initializes permissions, notification channels, and listeners.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Request Notification Permissions (iOS & Android 13+)
    await _requestPermissions();

    // 2. Setup Local Notifications (Foreground heads-up banners on Android)
    await _setupLocalNotifications();

    // 3. Configure Foreground notification presentation options for iOS
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Retrieve & Persist FCM Device Token
    await _fetchAndPersistToken();

    // 5. Listen for Token Refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      _fcmToken = newToken;
      debugPrint('FCM Token Refreshed: $newToken');
      await TokenRepository().persistFcmToken(newToken);
    });

    // 6. Setup Message Listeners (Foreground, Background tap, Terminated tap)
    _setupMessageHandlers();
  }

  /// Request permissions for iOS and Android 13+
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint(
      'Notification permission authorization status: ${settings.authorizationStatus}',
    );
  }

  /// Initialize flutter_local_notifications plugin and create Android channel
  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final Map<String, dynamic> data =
                jsonDecode(response.payload!) as Map<String, dynamic>;
            _handleNotificationRouting(data);
          } catch (e) {
            debugPrint('Error parsing notification payload: $e');
          }
        }
      },
    );

    // Create High Importance channel on Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  /// Fetch FCM Device Token
  Future<String?> _fetchAndPersistToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('====================================');
      debugPrint('FCM Device Token: $_fcmToken');
      debugPrint('====================================');
      if (_fcmToken != null) {
        await TokenRepository().persistFcmToken(_fcmToken!);
      }
      return _fcmToken;
    } catch (e) {
      debugPrint('Error fetching FCM Token: $e');
      return null;
    }
  }

  /// Setup listeners for foreground messages and notification clicks
  void _setupMessageHandlers() {
    // 1. App is in the FOREGROUND
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground FCM message received: ${message.messageId}');
      debugPrint('Notification Title: ${message.notification?.title}');
      debugPrint('Notification Body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');

      final notification = message.notification;
      final android = message.notification?.android;

      // When in foreground, show heads-up banner via flutter_local_notifications
      if (notification != null && !kIsWeb) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // 2. App opened from BACKGROUND by user tapping notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened from notification in background state');
      _handleNotificationRouting(message.data);
    });

    // 3. App opened from TERMINATED state by user tapping notification
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App opened from notification in terminated state');
        _handleNotificationRouting(message.data);
      }
    });
  }

  /// Route user based on notification data payload
  void _handleNotificationRouting(Map<String, dynamic> data) {
    if (data.isEmpty) {
      // Default to notifications screen if tapped with no specific payload
      Future.delayed(const Duration(milliseconds: 600), () {
        appRouter.push('/notifications');
      });
      return;
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      // 1. Check if direct route was provided
      if (data.containsKey('route') && data['route'] is String) {
        final route = data['route'] as String;
        if (route.isNotEmpty) {
          appRouter.push(route);
          return;
        }
      }

      // 2. Booking notification
      final bookingId = data['booking_id'] ?? data['bookingId'] ?? data['id'];
      if (data['type'] == 'booking' && bookingId != null) {
        appRouter.push('/booking-detail?booking_id=$bookingId');
        return;
      }

      // 3. Chat notification
      final roomId = data['roomId'] ?? data['room_id'];
      if (data['type'] == 'chat' && roomId != null) {
        final recipientName = data['recipientName'] ?? data['senderName'] ?? '';
        appRouter.push('/chat?roomId=$roomId&recipientName=$recipientName');
        return;
      }

      // 4. General fallback to notifications screen
      appRouter.push('/notifications');
    });
  }
}

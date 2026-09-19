import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';
import '../../routing/app_router.dart';
import '../../security/secureStorage.dart';
import '../api.dart';

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
      await syncTokenWithBackend();
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
        await syncTokenWithBackend();
      }
      return _fcmToken;
    } catch (e) {
      debugPrint('Error fetching FCM Token: $e');
      return null;
    }
  }

  /// Sync the FCM token with the backend API
  Future<void> syncTokenWithBackend() async {
    try {
      final jwtToken = await TokenRepository().readToken();
      if (jwtToken == null || jwtToken.isEmpty) {
        debugPrint('Customer not logged in, skipping FCM token sync with backend');
        return;
      }
      final token = _fcmToken ?? await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      final dio = Dio(
        BaseOptions(
          baseUrl: '$host/api/v1',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken',
          },
        ),
      );
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );

      final response = await dio.post('/users/fcm-token', data: {'fcmToken': token});
      debugPrint('Customer FCM Token successfully synced with backend: ${response.statusCode}');
    } catch (e) {
      debugPrint('Failed to sync Customer FCM Token with backend: $e');
    }
  }

  /// Clear the FCM token on the backend upon logout
  Future<void> deleteTokenFromBackend() async {
    try {
      final jwtToken = await TokenRepository().readToken();
      if (jwtToken == null || jwtToken.isEmpty) return;

      final dio = Dio(
        BaseOptions(
          baseUrl: '$host/api/v1',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken',
          },
        ),
      );
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );

      await dio.delete('/users/fcm-token');
      debugPrint('Customer FCM Token successfully cleared from backend');
    } catch (e) {
      debugPrint('Failed to clear Customer FCM Token from backend: $e');
    }
  }

  /// Fetch in-app notification history from backend
  Future<List<Map<String, dynamic>>> getUserNotifications({int page = 1, int limit = 20}) async {
    try {
      final jwtToken = await TokenRepository().readToken();
      if (jwtToken == null || jwtToken.isEmpty) return [];

      final dio = Dio(
        BaseOptions(
          baseUrl: '$host/api/v1',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken',
          },
        ),
      );
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );

      final response = await dio.get(
        '/notifications',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data['notifications'] ?? [];
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching notifications from backend: $e');
      return [];
    }
  }

  /// Mark single notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final jwtToken = await TokenRepository().readToken();
      if (jwtToken == null || jwtToken.isEmpty) return false;

      final dio = Dio(
        BaseOptions(
          baseUrl: '$host/api/v1',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken',
          },
        ),
      );
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );

      final response = await dio.patch('/notifications/$notificationId/read');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking notification read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final jwtToken = await TokenRepository().readToken();
      if (jwtToken == null || jwtToken.isEmpty) return false;

      final dio = Dio(
        BaseOptions(
          baseUrl: '$host/api/v1',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken',
          },
        ),
      );
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );

      final response = await dio.patch('/notifications/read-all');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking all notifications read: $e');
      return false;
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

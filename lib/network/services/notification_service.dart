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

  // If message contains data payload but no system notification payload, show local notification
  if (message.notification == null && message.data.isNotEmpty) {
    final title = message.data['title'] ?? 'New Notification';
    final body = message.data['body'] ?? message.data['message'] ?? '';
    if (body.isNotEmpty) {
      final localNotifications = FlutterLocalNotificationsPlugin();
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      await localNotifications.initialize(settings: const InitializationSettings(android: androidSettings));
      await localNotifications.show(
        id: message.messageId.hashCode,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important push notifications.',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }
}

/// Service class managing push notification lifecycle, channels, permissions,
/// foreground banner display, and navigation.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  late final FirebaseMessaging _messaging = FirebaseMessaging.instance;
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
  bool isAppReady = false;
  String? _pendingInitialRoute;

  /// Consumes and returns any pending route queued while the app was starting from terminated state
  String? consumePendingInitialRoute() {
    final route = _pendingInitialRoute;
    _pendingInitialRoute = null;
    return route;
  }

  /// Initializes permissions, notification channels, and listeners.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Setup Local Notifications (Foreground heads-up banners on Android)
    await _setupLocalNotifications();

    // 2. Request Notification Permissions (iOS & Android 13+)
    await _requestPermissions();

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

    // Request Android 13+ (API 33+) notification runtime permission explicitly
    if (!kIsWeb && Platform.isAndroid) {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidImplementation?.requestNotificationsPermission();
      debugPrint('Android 13+ Notification permission prompt result: $granted');
    }
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
            _handleNotificationRouting(data, isInitial: false);
          } catch (e) {
            debugPrint('Error parsing notification payload: $e');
          }
        } else {
          _handleNotificationRouting({}, isInitial: false);
        }
      },
    );

    // Create High Importance channel on Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Check if app was launched from terminated state via local notification
    try {
      final launchDetails =
          await _localNotifications.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        final payload = launchDetails.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          final Map<String, dynamic> data =
              jsonDecode(payload) as Map<String, dynamic>;
          debugPrint('Customer app launched via local notification tap: $data');
          _handleNotificationRouting(data, isInitial: true);
        }
      }
    } catch (e) {
      debugPrint('Error checking local notification launch details: $e');
    }
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
      final title = notification?.title ?? message.data['title'] ?? 'ProtoServe';
      final body = notification?.body ??
          message.data['body'] ??
          message.data['message'];

      // When in foreground, show heads-up banner via flutter_local_notifications
      if ((notification != null || body != null) && !kIsWeb) {
        _localNotifications.show(
          id: message.messageId.hashCode,
          title: title,
          body: body ?? '',
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
      debugPrint('App opened from notification in background state: ${message.messageId}');
      _handleNotificationRouting(message.data, isInitial: false);
    });

    // 3. App opened from TERMINATED state by user tapping notification
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App opened from notification in terminated state: ${message.messageId}');
        _handleNotificationRouting(message.data, isInitial: true);
      }
    });
  }

  /// Determines the destination screen route based on notification data payload or notification type
  static String resolveRoute(Map<String, dynamic>? data, {String? type}) {
    if (data == null || data.isEmpty) {
      if (type != null) {
        return _routeForTypeCustomer(type);
      }
      return '/notifications';
    }

    final notifType = (data['type']?.toString() ?? type ?? '').toLowerCase();

    // 1. Direct route parameter
    if (data.containsKey('route') && data['route'] is String) {
      final route = (data['route'] as String).trim();
      if (route.isNotEmpty && route.startsWith('/')) {
        return route;
      }
    }

    // 2. Booking notification
    final bookingId = data['booking_id'] ??
        data['bookingId'] ??
        data['id'] ??
        data['bookingID'];
    if (notifType == 'booking' ||
        notifType == 'dispatch' ||
        notifType == 'order' ||
        (bookingId != null && notifType != 'chat')) {
      if (bookingId != null && bookingId.toString().isNotEmpty) {
        return '/booking-detail?booking_id=$bookingId';
      }
      return '/bookings';
    }

    // 3. Chat notification
    final roomId = data['roomId'] ??
        data['room_id'] ??
        data['chatId'] ??
        data['chat_id'];
    if (notifType == 'chat' || notifType == 'message' || roomId != null) {
      final recipientName = Uri.encodeComponent(
        (data['recipientName'] ?? data['senderName'] ?? '').toString(),
      );
      final recipientId = Uri.encodeComponent(
        (data['recipientId'] ?? data['senderId'] ?? '').toString(),
      );
      final recipientPhoto = Uri.encodeComponent(
        (data['recipientPhoto'] ?? data['senderPhoto'] ?? '').toString(),
      );
      if (roomId != null && roomId.toString().isNotEmpty) {
        return '/chat?roomId=$roomId&recipientName=$recipientName&recipientId=$recipientId&recipientPhoto=$recipientPhoto';
      }
      return '/home';
    }

    // 4. Call notification
    if (notifType == 'call') {
      if (bookingId != null && bookingId.toString().isNotEmpty) {
        return '/booking-detail?booking_id=$bookingId';
      }
      return '/home';
    }

    final serviceId = data['service_id'] ?? data['serviceId'];

    // 5. Review / Rating notification
    if (notifType == 'review' || notifType == 'rating') {
      if (serviceId != null && serviceId.toString().isNotEmpty) {
        return '/reviews?service_id=$serviceId';
      }
      return '/bookings';
    }

    // 6. Service / Catalog notification
    if (notifType == 'service' || serviceId != null) {
      if (serviceId != null && serviceId.toString().isNotEmpty) {
        return '/service-detail?service_id=$serviceId';
      }
      return '/search';
    }

    // 7. Category notification
    final category = data['category'] ?? data['category_name'];
    if (notifType == 'category') {
      if (category != null && category.toString().isNotEmpty) {
        return '/search?category=${Uri.encodeComponent(category.toString())}';
      }
      return '/categories';
    }

    // 8. Promo / Offer
    if (notifType == 'promo' ||
        notifType == 'offer' ||
        notifType == 'discount') {
      return '/home';
    }

    // 9. Address notification
    if (notifType == 'address' || notifType == 'location') {
      return '/addresses';
    }

    // 10. Profile notification
    if (notifType == 'profile' || notifType == 'account') {
      return '/profile';
    }

    // Fallback
    return '/notifications';
  }

  static String _routeForTypeCustomer(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
      case 'dispatch':
      case 'order':
        return '/bookings';
      case 'chat':
      case 'message':
        return '/home';
      case 'service':
        return '/search';
      case 'category':
        return '/categories';
      case 'review':
      case 'rating':
        return '/bookings';
      case 'promo':
      case 'offer':
        return '/home';
      case 'address':
      case 'location':
        return '/addresses';
      case 'profile':
      case 'account':
        return '/profile';
      default:
        return '/notifications';
    }
  }

  /// Route user based on notification data payload
  void _handleNotificationRouting(Map<String, dynamic> data, {bool isInitial = false}) {
    final targetRoute = resolveRoute(data);
    debugPrint('Customer Notification routing target: $targetRoute (isInitial: $isInitial, isAppReady: $isAppReady)');

    if (isInitial && !isAppReady) {
      _pendingInitialRoute = targetRoute;
      return;
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (targetRoute.isNotEmpty) {
        appRouter.push(targetRoute);
      }
    });
  }
}

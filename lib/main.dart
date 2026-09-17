import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'network/services/notification_service.dart';
import 'state/app_state.dart';
import 'theme/brand_theme.dart';
import 'routing/app_router.dart';

/// Overrides certificate verification in debug mode so development servers
/// with local IPs (e.g. https://192.168.x.x) or self-signed certificates work.
class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = DevHttpOverrides();

  try {
    // 1. Initialize Firebase with platform-specific options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. Set the background messaging handler early before runApp
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 3. Initialize the Push Notification Service (Permissions, Channels, Listeners)
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Firebase/Notification initialization error: $e');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState(),
      builder: (context, _) {
        final appState = AppState();
        return MaterialApp.router(
          title: 'ProtoServe',
          theme: BrandTheme.lightTheme,
          darkTheme: BrandTheme.darkTheme,
          themeMode: appState.currentThemeMode,
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

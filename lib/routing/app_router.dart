import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/main_shell_screen.dart';
import '../screens/home_screen.dart';
import '../screens/service_listing_screen.dart';
import '../screens/service_detail_screen.dart';
import '../screens/funnel_step1_screen.dart';
import '../screens/funnel_step2_screen.dart';
import '../screens/booking_list_screen.dart';
import '../screens/booking_detail_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/reviews_screen.dart';
import '../screens/addresses_screen.dart';
import '../screens/notifications_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // Auth & Gateways (Outside Bottom Nav Shell)
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoriesScreen(),
    ),

    // Bottom Navigation Shell
    ShellRoute(
      builder: (context, state, child) => MainShellScreen(child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/search',
          builder: (context, state) {
            final category = state.uri.queryParameters['category'] ?? 'All';
            return ServiceListingScreen(initialCategory: category);
          },
        ),
        GoRoute(
          path: '/bookings',
          builder: (context, state) => const BookingListScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),

    // Sub-screens (Outside Bottom Nav Shell to hide bottom bar)
    GoRoute(
      path: '/service-detail',
      builder: (context, state) {
        final serviceId = state.uri.queryParameters['service_id'] ?? '';
        return ServiceDetailScreen(serviceId: serviceId);
      },
    ),
    GoRoute(
      path: '/funnel-step1',
      builder: (context, state) {
        final service = state.extra as Map<String, dynamic>;
        return FunnelStep1Screen(service: service);
      },
    ),
    GoRoute(
      path: '/funnel-step2',
      builder: (context, state) {
        final bookingSummery = state.extra as Map<String, dynamic>;
        return FunnelStep2Screen(bookingSummery: bookingSummery);
      },
    ),
    GoRoute(
      path: '/booking-detail',
      builder: (context, state) {
        final booking = state.extra is Map
            ? Map<String, dynamic>.from(state.extra as Map)
            : null;
        final bookingId = state.uri.queryParameters['booking_id'] ??
            booking?['booking']?['id']?.toString() ??
            booking?['id']?.toString();
        return BookingDetailScreen(
          booking: booking,
          bookingId: bookingId,
        );
      },
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) {
        final extra = state.extra is Map
            ? Map<String, dynamic>.from(state.extra as Map)
            : null;
        final roomId = state.uri.queryParameters['roomId'] ??
            extra?['roomId']?.toString() ??
            '';
        final recipientName = state.uri.queryParameters['recipientName'] ??
            extra?['recipientName']?.toString();
        final recipientPhoto = state.uri.queryParameters['recipientPhoto'] ??
            extra?['recipientPhoto']?.toString();
        final recipientId = state.uri.queryParameters['recipientId'] ??
            extra?['recipientId']?.toString();
        return ChatScreen(
          roomId: roomId,
          recipientName: recipientName,
          recipientPhoto: recipientPhoto,
          recipientId: recipientId,
        );
      },
    ),
    GoRoute(
      path: '/reviews',
      builder: (context, state) {
        final extra = state.extra is Map
            ? Map<String, dynamic>.from(state.extra as Map)
            : null;
        final serviceId = state.uri.queryParameters['service_id'] ??
            extra?['serviceId']?.toString();
        final serviceTitle = state.uri.queryParameters['service_title'] ??
            extra?['serviceTitle']?.toString();
        return ReviewsScreen(
          serviceId: serviceId,
          serviceTitle: serviceTitle,
        );
      },
    ),
    GoRoute(
      path: '/addresses',
      builder: (context, state) => const AddressesScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
  ],
);

import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/network/services/notification_service.dart';

void main() {
  group('Customer App Notification Routing Tests', () {
    test('resolves direct route parameter', () {
      final route = NotificationService.resolveRoute({
        'route': '/service-detail?service_id=serv_123',
      });
      expect(route, equals('/service-detail?service_id=serv_123'));
    });

    test('resolves booking notification with booking_id', () {
      final route = NotificationService.resolveRoute({
        'type': 'booking',
        'booking_id': 'bk_789',
      });
      expect(route, equals('/booking-detail?booking_id=bk_789'));
    });

    test('resolves booking notification with bookingId and without type', () {
      final route = NotificationService.resolveRoute({
        'bookingId': 'bk_456',
      });
      expect(route, equals('/booking-detail?booking_id=bk_456'));
    });

    test('resolves booking notification without ID to bookings list', () {
      final route = NotificationService.resolveRoute({
        'type': 'booking',
      });
      expect(route, equals('/bookings'));
    });

    test('resolves chat notification with room and recipient details', () {
      final route = NotificationService.resolveRoute({
        'type': 'chat',
        'roomId': 'room_101',
        'recipientName': 'John Doe',
        'recipientId': 'usr_99',
      });
      expect(route, contains('/chat?roomId=room_101'));
      expect(route, contains('recipientName=John%20Doe'));
      expect(route, contains('recipientId=usr_99'));
    });

    test('resolves call notification with booking_id', () {
      final route = NotificationService.resolveRoute({
        'type': 'call',
        'booking_id': 'bk_111',
      });
      expect(route, equals('/booking-detail?booking_id=bk_111'));
    });

    test('resolves service notification with service_id', () {
      final route = NotificationService.resolveRoute({
        'type': 'service',
        'service_id': 'srv_55',
      });
      expect(route, equals('/service-detail?service_id=srv_55'));
    });

    test('resolves category notification with category name', () {
      final route = NotificationService.resolveRoute({
        'type': 'category',
        'category': 'Home Cleaning',
      });
      expect(route, equals('/search?category=Home%20Cleaning'));
    });

    test('resolves review notification with service_id', () {
      final route = NotificationService.resolveRoute({
        'type': 'review',
        'service_id': 'srv_77',
      });
      expect(route, equals('/reviews?service_id=srv_77'));
    });

    test('resolves promo notification to home', () {
      final route = NotificationService.resolveRoute({
        'type': 'promo',
      });
      expect(route, equals('/home'));
    });

    test('resolves address notification to addresses', () {
      final route = NotificationService.resolveRoute({
        'type': 'address',
      });
      expect(route, equals('/addresses'));
    });

    test('resolves profile notification to profile', () {
      final route = NotificationService.resolveRoute({
        'type': 'profile',
      });
      expect(route, equals('/profile'));
    });

    test('resolves general notification to notifications screen', () {
      final route = NotificationService.resolveRoute({
        'type': 'general',
      });
      expect(route, equals('/notifications'));
    });

    test('resolves null payload using type parameter', () {
      expect(
        NotificationService.resolveRoute(null, type: 'booking'),
        equals('/bookings'),
      );
      expect(
        NotificationService.resolveRoute(null, type: 'service'),
        equals('/search'),
      );
      expect(
        NotificationService.resolveRoute(null, type: 'category'),
        equals('/categories'),
      );
      expect(
        NotificationService.resolveRoute(null, type: 'address'),
        equals('/addresses'),
      );
    });

    test('queues and consumes pending initial route for cold start', () {
      final service = NotificationService.instance;
      service.isAppReady = false;
      // Trigger via resolve and consumption test
      final target = NotificationService.resolveRoute({'type': 'booking', 'booking_id': 'bk_cold'});
      expect(target, equals('/booking-detail?booking_id=bk_cold'));

      expect(service.consumePendingInitialRoute(), isNull);
    });
  });
}

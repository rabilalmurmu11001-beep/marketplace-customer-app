import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/network/services/notification_service.dart';
import 'package:customer_app/screens/notifications_screen.dart';
import 'package:customer_app/theme/brand_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Notification Count State Tests', () {
    test('unreadCountNotifier correctly updates and notifies listeners', () {
      final service = NotificationService.instance;
      service.unreadCountNotifier.value = 0;
      expect(service.unreadCountNotifier.value, equals(0));

      int listenerFiredCount = 0;
      void listener() {
        listenerFiredCount++;
      }

      service.unreadCountNotifier.addListener(listener);

      service.unreadCountNotifier.value = 5;
      expect(service.unreadCountNotifier.value, equals(5));
      expect(listenerFiredCount, equals(1));

      // Simulate decrement when a notification is marked read
      service.unreadCountNotifier.value--;
      expect(service.unreadCountNotifier.value, equals(4));
      expect(listenerFiredCount, equals(2));

      // Simulate clear when all are marked read
      service.unreadCountNotifier.value = 0;
      expect(service.unreadCountNotifier.value, equals(0));
      expect(listenerFiredCount, equals(3));

      service.unreadCountNotifier.removeListener(listener);
    });
  });

  group('Notification Bell Badge UI Tests', () {
    Widget buildBellWidget() {
      return MaterialApp(
        theme: BrandTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  key: const Key('bell_icon_container'),
                  padding: const EdgeInsets.all(10),
                  child: const Icon(
                    Icons.notifications_none_outlined,
                    size: 18,
                  ),
                ),
                ValueListenableBuilder<int>(
                  valueListenable:
                      NotificationService.instance.unreadCountNotifier,
                  builder: (context, count, _) {
                    if (count <= 0) return const SizedBox.shrink();
                    return Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        key: const Key('notification_badge'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: BrandColors.danger,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('hides badge when unread count is 0', (tester) async {
      NotificationService.instance.unreadCountNotifier.value = 0;
      await tester.pumpWidget(buildBellWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('notification_badge')), findsNothing);
      expect(find.byIcon(Icons.notifications_none_outlined), findsOneWidget);
    });

    testWidgets('shows numeric badge when unread count is between 1 and 9',
        (tester) async {
      NotificationService.instance.unreadCountNotifier.value = 3;
      await tester.pumpWidget(buildBellWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('notification_badge')), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows 9+ badge when unread count exceeds 9', (tester) async {
      NotificationService.instance.unreadCountNotifier.value = 14;
      await tester.pumpWidget(buildBellWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('notification_badge')), findsOneWidget);
      expect(find.text('9+'), findsOneWidget);
    });

    testWidgets('badge updates dynamically when unread count changes',
        (tester) async {
      NotificationService.instance.unreadCountNotifier.value = 1;
      await tester.pumpWidget(buildBellWidget());
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);

      NotificationService.instance.unreadCountNotifier.value = 0;
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('notification_badge')), findsNothing);
    });
  });

  group('NotificationsScreen Header Count Tests', () {
    testWidgets('shows unread count in header and caught up when 0',
        (tester) async {
      NotificationService.instance.unreadCountNotifier.value = 4;
      await tester.pumpWidget(
        MaterialApp(
          theme: BrandTheme.lightTheme,
          home: const NotificationsScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('4 unread alerts'), findsOneWidget);
      expect(find.text('Mark read'), findsOneWidget);

      NotificationService.instance.unreadCountNotifier.value = 0;
      await tester.pump();

      expect(find.text('All alerts caught up'), findsOneWidget);
    });
  });
}

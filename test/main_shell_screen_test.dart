import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/screens/main_shell_screen.dart';

void main() {
  testWidgets('MainShellScreen bottom navigation bar includes SafeArea', (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            return MainShellScreen(child: child);
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const Text('Home Screen Content'),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home Screen Content'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Bookings'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);

    // Verify SafeArea exists in the bottomNavigationBar
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.bottomNavigationBar, isNotNull);

    final safeAreaFinder = find.descendant(
      of: find.byWidget(scaffold.bottomNavigationBar!),
      matching: find.byType(SafeArea),
    );
    expect(safeAreaFinder, findsOneWidget);

    final safeArea = tester.widget<SafeArea>(safeAreaFinder);
    expect(safeArea.top, isFalse);
    expect(safeArea.bottom, isTrue);
  });
}

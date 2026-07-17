import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/main.dart';

void main() {
  testWidgets('App starts with Splash Screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that our Splash Screen is shown with the brand name.
    expect(find.text('ProtoServe'), findsOneWidget);
    expect(find.text('Initialize Experience'), findsOneWidget);
  });
}

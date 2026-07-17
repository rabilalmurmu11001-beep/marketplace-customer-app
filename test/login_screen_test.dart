import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/screens/login_screen.dart';

void main() {
  Widget buildTestableWidget() {
    return const MaterialApp(
      home: LoginScreen(),
    );
  }

  testWidgets('LoginScreen initial layout smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget());

    // Check title
    expect(find.text('Welcome Guest ✨'), findsOneWidget);
    expect(find.text('IDENTIFIER ENDPOINT'), findsOneWidget);
    expect(find.text('SECURITY CREDENTIAL TYPE'), findsOneWidget);

    // Initial fields should show Email Address and Security Password
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('ACCOUNT EMAIL ENDPOINT'), findsOneWidget);
    expect(find.text('PASSWORD SECURITY TOKEN'), findsOneWidget);
  });

  testWidgets('Switching toggles displays correct form fields', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget());

    // Switch to Mobile Number
    await tester.tap(find.text('Mobile Number'));
    await tester.pumpAndSettle();

    expect(find.text('MOBILE SECURE NUMBER'), findsOneWidget);
    expect(find.text('ACCOUNT EMAIL ENDPOINT'), findsNothing);

    // Switch to One-Time Passcode
    await tester.tap(find.text('One-Time Passcode'));
    await tester.pumpAndSettle();

    expect(find.text('ONE-TIME PASSCODE (OTP)'), findsOneWidget);
    expect(find.text('PASSWORD SECURITY TOKEN'), findsNothing);
  });

  testWidgets('OTP send flow shows feedback message', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget());

    // Switch to OTP
    await tester.tap(find.text('One-Time Passcode'));
    await tester.pumpAndSettle();

    // Verify "Send Code" button exists
    expect(find.text('Send Code'), findsOneWidget);

    // Click "Send Code"
    await tester.tap(find.text('Send Code'));
    await tester.pump(); // Start timer / animation

    // Verify snackbar feedback
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Security code sent'), findsOneWidget);
  });
}

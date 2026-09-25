import 'package:customer_app/network/services/userService.dart';
import 'package:customer_app/screens/profile_screen.dart';
import 'package:customer_app/store/use_app_store.dart';
import 'package:customer_app/theme/brand_theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUserService extends UserService {
  FakeUserService() : super(Dio());

  @override
  Future<Response> getUserProfile() async {
    return Response(
      requestOptions: RequestOptions(path: '/users/profile/me'),
      data: {
        'success': true,
        'user': {
          'id': 'cust-1',
          'username': 'Alice Customer',
          'email': 'alice@example.com',
          'mobile': '9876543210',
          'isEmailVerified': true,
          'isPhoneVerified': true,
          'role': 'customer',
          'address': '221B Baker St',
        },
      },
    );
  }

  @override
  Future<Response> requestEmailUpdateOtp(String email) async {
    return Response(
      requestOptions: RequestOptions(path: '/users/request-email-otp'),
      data: {'success': true, 'message': 'Verification code sent'},
    );
  }

  @override
  Future<Response> verifyEmailUpdateOtp(String email, String otp) async {
    return Response(
      requestOptions: RequestOptions(path: '/users/verify-email-otp'),
      data: {
        'success': true,
        'user': {
          'id': 'cust-1',
          'username': 'Alice Customer',
          'email': email,
          'isEmailVerified': true,
          'isPhoneVerified': true,
          'role': 'customer',
        },
      },
    );
  }

  @override
  Future<Response> requestMobileUpdateOtp(String mobile) async {
    return Response(
      requestOptions: RequestOptions(path: '/users/request-mobile-otp'),
      data: {'success': true, 'message': 'Verification code sent'},
    );
  }

  @override
  Future<Response> verifyMobileUpdateOtp(String mobile, String otp) async {
    return Response(
      requestOptions: RequestOptions(path: '/users/verify-mobile-otp'),
      data: {
        'success': true,
        'user': {
          'id': 'cust-1',
          'username': 'Alice Customer',
          'mobile': mobile,
          'isEmailVerified': true,
          'isPhoneVerified': true,
          'role': 'customer',
        },
      },
    );
  }

  @override
  Future<Response> updateUserProfile(Map<String, dynamic> updatedData) async {
    return Response(
      requestOptions: RequestOptions(path: '/users/update/me'),
      data: {
        'success': true,
        'user': {
          'id': 'cust-1',
          'username': updatedData['username'] ?? 'Alice Customer',
          'address': updatedData['address'] ?? '221B Baker St',
          'gender': updatedData['gender'],
          'age': updatedData['age'],
          'isEmailVerified': true,
          'isPhoneVerified': true,
        },
      },
    );
  }
}

class MockCustomerProfileNotifier extends CustomerProfileNotifier {
  final Map<String, dynamic>? initialProfile;
  MockCustomerProfileNotifier(this.initialProfile);

  @override
  Map<String, dynamic>? build() => initialProfile;
}

void main() {
  Widget createProfileScreen({
    required Map<String, dynamic> userProfileData,
    UserService? userService,
  }) {
    return ProviderScope(
      overrides: [
        customerProfileProvider.overrideWith(
          () => MockCustomerProfileNotifier(userProfileData),
        ),
        userServiceProvider.overrideWithValue(userService ?? FakeUserService()),
      ],
      child: MaterialApp(
        theme: BrandTheme.lightTheme,
        darkTheme: BrandTheme.darkTheme,
        home: const ProfileScreen(),
      ),
    );
  }

  testWidgets(
      'ProfileScreen displays Verified status when email and phone are verified',
      (WidgetTester tester) async {
    final mockUser = {
      'id': 'cust-1',
      'username': 'Alice Customer',
      'email': 'alice@example.com',
      'mobile': '9876543210',
      'isEmailVerified': true,
      'isPhoneVerified': true,
      'role': 'customer',
      'address': '221B Baker St',
    };

    await tester.pumpWidget(createProfileScreen(userProfileData: mockUser));
    await tester.pumpAndSettle();

    expect(find.text('Alice Customer'), findsWidgets);
    expect(find.text('alice@example.com'), findsOneWidget);
    expect(find.text('9876543210'), findsOneWidget);

    // Both should display 'Verified' badges
    expect(find.text('Verified'), findsNWidgets(2));
    expect(find.text('Verify'), findsNothing);
  });

  testWidgets(
      'ProfileScreen displays Pending status and Verify button when unverified',
      (WidgetTester tester) async {
    final mockUser = {
      'id': 'cust-1',
      'username': 'Alice Customer',
      'email': 'alice@example.com',
      'mobile': '9876543210',
      'isEmailVerified': false,
      'isPhoneVerified': false,
      'role': 'customer',
      'address': '221B Baker St',
    };

    await tester.pumpWidget(createProfileScreen(userProfileData: mockUser));
    await tester.pumpAndSettle();

    // Both should display 'Pending' badges and 'Verify' buttons
    expect(find.text('Pending'), findsNWidgets(2));
    expect(find.text('Verify'), findsNWidgets(2));
  });

  testWidgets(
      'Opening edit profile modal renders email & mobile fields with OTP triggers',
      (WidgetTester tester) async {
    final mockUser = {
      'id': 'cust-1',
      'username': 'Alice Customer',
      'email': 'alice@example.com',
      'mobile': '9876543210',
      'isEmailVerified': true,
      'isPhoneVerified': true,
      'role': 'customer',
      'address': '221B Baker St',
    };

    await tester.pumpWidget(createProfileScreen(userProfileData: mockUser));
    await tester.pumpAndSettle();

    // Tap on 'Edit Info'
    final editInfoButton = find.text('Edit Info');
    expect(editInfoButton, findsOneWidget);
    await tester.tap(editInfoButton);
    await tester.pumpAndSettle();

    // Verify modal elements
    expect(find.text('Edit Customer Profile'), findsOneWidget);
    expect(find.text('FULL NAME / DISPLAY NAME'), findsOneWidget);
    expect(find.text('EMAIL ADDRESS'), findsOneWidget);
    expect(find.text('CONTACT MOBILE NUMBER'), findsOneWidget);
    expect(find.text('PRIMARY DELIVERY / BILLING ADDRESS'), findsOneWidget);

    // Initial state: both are verified
    expect(find.text('Verified'), findsWidgets);

    // Now change the email address field to something new
    final emailField = find.widgetWithText(TextFormField, 'alice@example.com');
    expect(emailField, findsOneWidget);
    await tester.enterText(emailField, 'newemail@example.com');
    await tester.pumpAndSettle();

    // After modifying email, it should show 'Requires OTP' and 'Verify with OTP'
    expect(find.text('Requires OTP'), findsOneWidget);
    expect(find.text('Verify with OTP'), findsOneWidget);
  });

  testWidgets(
      'Profile email OTP flow does not show a loading spinner while requesting or verifying the code',
      (WidgetTester tester) async {
    final mockUser = {
      'id': 'cust-1',
      'username': 'Alice Customer',
      'email': 'alice@example.com',
      'mobile': '9876543210',
      'isEmailVerified': true,
      'isPhoneVerified': true,
      'role': 'customer',
      'address': '221B Baker St',
    };

    await tester.pumpWidget(createProfileScreen(userProfileData: mockUser));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit Info'));
    await tester.pumpAndSettle();

    final emailField = find.widgetWithText(TextFormField, 'alice@example.com');
    await tester.enterText(emailField, 'newemail@example.com');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Verify with OTP'));
    await tester.pump();

    // No blocking CircularProgressIndicator while requesting/opening OTP
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Verify Email Address'), findsOneWidget);
  });

  testWidgets(
      'Entering 6-digit OTP verifies email and updates modal state',
      (WidgetTester tester) async {
    final mockUser = {
      'id': 'cust-1',
      'username': 'Alice Customer',
      'email': 'alice@example.com',
      'mobile': '9876543210',
      'isEmailVerified': true,
      'isPhoneVerified': true,
      'role': 'customer',
      'address': '221B Baker St',
    };

    await tester.pumpWidget(createProfileScreen(userProfileData: mockUser));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit Info'));
    await tester.pumpAndSettle();

    final emailField = find.widgetWithText(TextFormField, 'alice@example.com');
    await tester.enterText(emailField, 'newemail@example.com');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Verify with OTP'));
    await tester.pumpAndSettle();

    expect(find.text('Verify Email Address'), findsOneWidget);

    // Enter 6-digit code into OTP text field
    final otpInput = find.byType(TextField).last;
    await tester.enterText(otpInput, '123456');
    await tester.pumpAndSettle();

    // Verification sheet pops and returns true; modal now shows 'Verified'
    expect(find.text('Verify Email Address'), findsNothing);
    expect(find.text('✓ Email verified successfully!'), findsOneWidget);
  });

  testWidgets(
      'Updating username and address saves profile and updates screen',
      (WidgetTester tester) async {
    final mockUser = {
      'id': 'cust-1',
      'username': 'Alice Customer',
      'email': 'alice@example.com',
      'mobile': '9876543210',
      'isEmailVerified': true,
      'isPhoneVerified': true,
      'role': 'customer',
      'address': '221B Baker St',
    };

    await tester.pumpWidget(createProfileScreen(userProfileData: mockUser));
    await tester.pumpAndSettle();

    // Tap on Edit Profile button
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();

    // Change display name and address
    final nameField = find.widgetWithText(TextFormField, 'Alice Customer');
    await tester.enterText(nameField, 'Alice Wonderland');
    await tester.pumpAndSettle();

    final addressField = find.widgetWithText(TextFormField, '221B Baker St');
    await tester.enterText(addressField, '42 Wallaby Way');
    await tester.pumpAndSettle();

    // Tap Save Changes
    final saveButton = find.text('Save Changes');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Modal closes and screen updates with new values
    expect(find.text('Edit Customer Profile'), findsNothing);
    expect(find.text('✓ Customer profile updated successfully!'), findsOneWidget);
    expect(find.text('Alice Wonderland'), findsWidgets);
    expect(find.text('42 Wallaby Way'), findsOneWidget);
  });

  testWidgets(
      'Modifying contact mobile number triggers mobile OTP verification sheet',
      (WidgetTester tester) async {
    final mockUser = {
      'id': 'cust-1',
      'username': 'Alice Customer',
      'email': 'alice@example.com',
      'mobile': '9876543210',
      'isEmailVerified': true,
      'isPhoneVerified': true,
      'role': 'customer',
      'address': '221B Baker St',
    };

    await tester.pumpWidget(createProfileScreen(userProfileData: mockUser));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit Info'));
    await tester.pumpAndSettle();

    // Change mobile number
    final mobileField = find.widgetWithText(TextFormField, '9876543210');
    await tester.enterText(mobileField, '9998887776');
    await tester.pumpAndSettle();

    // Tap Verify with OTP for mobile
    final verifyButtons = find.text('Verify with OTP');
    expect(verifyButtons, findsOneWidget);
    await tester.tap(verifyButtons);
    await tester.pumpAndSettle();

    expect(find.text('Verify Mobile Number'), findsOneWidget);
    expect(find.text('9998887776'), findsWidgets);

    // Enter 6-digit OTP
    final otpInput = find.byType(TextField).last;
    await tester.enterText(otpInput, '654321');
    await tester.pumpAndSettle();

    // Verification sheet pops and shows success
    expect(find.text('Verify Mobile Number'), findsNothing);
    expect(find.text('✓ Mobile number verified successfully!'), findsOneWidget);
  });
}

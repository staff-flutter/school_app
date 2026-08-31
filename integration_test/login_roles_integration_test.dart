import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:get/get.dart';
import 'package:school_app/main.dart' as app;

/// -----------------------------------------------------------------------
/// 1. Define test data for each role as a simple model.
///    Keep credentials OUT of source control — load from a separate
///    config file (test_config.dart, gitignored) or environment variables.
/// -----------------------------------------------------------------------
class TestUser {
  final String role;
  final String email;
  final String password;
  final String logoutKey; // 'admin_logout_button' or 'parent_logout_button'

  const TestUser({
    required this.role,
    required this.email,
    required this.password,
    required this.logoutKey,
  });
}

// Replace passwords with real staging test-account credentials.
// Better: move this list to a separate test_config.dart file that is
// gitignored, so no real passwords sit in a file that gets committed.
//
// logoutKey: 'admin_logout_button' for all school-staff roles (they share
// AdminScaffold), 'parent_logout_button' for the parent role (different screen).
final List<TestUser> testUsers = [
  TestUser(role: 'correspondent', email: 'correspondent@gmail.com', password: 'correspondent@123', logoutKey: 'admin_logout_button'),
  TestUser(role: 'accountant',    email: 'accountant5@gmail.com',    password: 'accountant5@123', logoutKey: 'admin_logout_button'),
  TestUser(role: 'administrator', email: 'administrator5@gmail.com', password: 'administrator5@123', logoutKey: 'admin_logout_button'),
  TestUser(role: 'principal',     email: 'principal5@gmail.com',     password: 'principal5@123', logoutKey: 'admin_logout_button'),
  TestUser(role: 'viceprincipal', email: 'viceprincipal5@gmail.com', password: 'viceprincipal5@123', logoutKey: 'admin_logout_button'),
  TestUser(role: 'teacher',       email: 'kamalateacher@gmail.com',       password: 'kamalateacher@123', logoutKey: 'admin_logout_button'),
  TestUser(role: 'parent',        email: 'parentofkiran@gmail.com',              password: 'parentofkiran@123', logoutKey: 'parent_logout_button'),
];
/// -----------------------------------------------------------------------
/// 2. Reusable login helper — avoids repeating the same steps 7 times.
/// -----------------------------------------------------------------------

/// Repeatedly pumps until [finder] matches something, instead of a single
/// fixed-duration wait. This matters because the login screen may still be
/// doing async startup work (session checks etc.) when pumpAndSettle first
/// returns — a fixed wait can fire before the widget actually exists.
Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
      Duration timeout = const Duration(seconds: 15),
    }) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 250));
  }
  throw Exception('Timed out waiting for widget: $finder');
}

/// Dismisses the first-launch onboarding carousel ("Welcome to Daily
/// Grades... Skip / Next") that shows before the login screen on a fresh
/// install. Every test run installs a fresh APK, so this always appears
/// first. Some carousels need more than one tap (Skip jumping to a final
/// page that still has its own "Get Started" button), so this loops
/// through whatever dismiss-style button it finds until the login screen
/// appears or it runs out of attempts.
Future<void> dismissOnboardingIfPresent(WidgetTester tester) async {
  const dismissLabels = ['Skip', 'Get Started', 'Continue', 'Done', 'Login', 'Log In'];

  for (int attempt = 0; attempt < 6; attempt++) {
    if (find.byKey(const Key('email_field')).evaluate().isNotEmpty) return;

    Finder? buttonToTap;
    for (final label in dismissLabels) {
      final finder = find.text(label);
      if (finder.evaluate().isNotEmpty) {
        buttonToTap = finder.first;
        break;
      }
    }

    if (buttonToTap == null) {
      // Nothing recognizable left to dismiss — try "Next" as a fallback,
      // in case it's a multi-page carousel without a working Skip button.
      final nextButton = find.text('Next');
      if (nextButton.evaluate().isNotEmpty) {
        buttonToTap = nextButton.first;
      } else {
        return; // nothing more we can do here
      }
    }

    await tester.tap(buttonToTap);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }
}

/// Real devices keep real storage between runs (unlike emulators, which
/// reset). If you tested the app manually before, a saved session/token
/// might make the app skip straight to a home screen instead of showing
/// the login screen. This checks for that and logs out first if needed.
Future<void> ensureAtLoginScreen(WidgetTester tester) async {
  await dismissOnboardingIfPresent(tester);

  if (find.byKey(const Key('email_field')).evaluate().isNotEmpty) return;

  for (final key in ['admin_logout_button', 'parent_logout_button']) {
    final button = find.byKey(Key(key));
    if (button.evaluate().isNotEmpty) {
      await tester.tap(button);
      await tester.pumpAndSettle();

      final confirmButton = find.byKey(const Key('confirm_logout_button'));
      if (confirmButton.evaluate().isNotEmpty) {
        await tester.tap(confirmButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      return;
    }
  }
}

Future<void> performLogin(WidgetTester tester, TestUser user) async {
  await ensureAtLoginScreen(tester);

  await waitFor(tester, find.byKey(const Key('email_field')));
  await tester.enterText(find.byKey(const Key('email_field')), user.email);

  await waitFor(tester, find.byKey(const Key('password_field')));
  await tester.enterText(find.byKey(const Key('password_field')), user.password);

  await waitFor(tester, find.byKey(const Key('login_button')));
  await tester.tap(find.byKey(const Key('login_button')));

  // Wait for the API call + GetX navigation to complete
  await tester.pumpAndSettle(const Duration(seconds: 3));

  // Parent only: login lands on a student-picker screen, then a home grid —
  // the logout button only appears after both steps are done.
  if (user.role == 'parent') {
    await completeParentPostLoginSteps(tester);
  }
}

/// Parent-specific: pick the first child, then tap the "Parent Profile"
/// tile on the home grid to reach the screen with the logout button.
Future<void> completeParentPostLoginSteps(WidgetTester tester) async {
  await waitFor(tester, find.byKey(const Key('student_tile_0')), timeout: const Duration(seconds: 15));
  await tester.tap(find.byKey(const Key('student_tile_0')));
  await tester.pumpAndSettle(const Duration(seconds: 2));

  await waitFor(tester, find.byKey(const Key('parent_profile_home_button')), timeout: const Duration(seconds: 15));
  await tester.tap(find.byKey(const Key('parent_profile_home_button')));
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // The logout button lives inside the "My Children" ExpansionTile, which
  // starts collapsed — its children (including the logout row) aren't even
  // built into the widget tree until it's expanded.
  await waitFor(tester, find.text('My Children'), timeout: const Duration(seconds: 10));
  await tester.tap(find.text('My Children'));
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

/// Logs the current user out via their role's logout button, then confirms
/// the "Are you sure?" dialog — both admin and parent screens show one.
Future<void> performLogout(WidgetTester tester, String logoutKey) async {
  final logoutButton = find.byKey(Key(logoutKey));
  expect(logoutButton, findsOneWidget, reason: 'Logout button not found — was login successful?');

  await tester.tap(logoutButton);
  await tester.pumpAndSettle();

  final confirmButton = find.byKey(const Key('confirm_logout_button'));
  await tester.tap(confirmButton);
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Back at the login screen
  expect(find.byKey(const Key('email_field')), findsOneWidget);
}

/// -----------------------------------------------------------------------
/// 3. Main test — loops through every role automatically.
/// -----------------------------------------------------------------------
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Required for GetX navigation (Get.offNamed etc.) to work inside tests —
  // without this you get "contextless navigation" errors after login.
  Get.testMode = true;

  // Clears GetX's singleton controllers before each test so the previous
  // role's session/state doesn't leak into the next role's test.
  setUp(() {
    Get.reset();
  });

  group('DIAGNOSTIC - what screen does the app actually show?', () {
    testWidgets('dump the widget tree after startup', (tester) async {
      app.main();

      // Give it a generous, explicit window to finish any splash /
      // session-check logic, well beyond what pumpAndSettle alone gives.
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }

      // ignore: avoid_print
      print('=== BEFORE dismissing onboarding ===');
      // ignore: avoid_print
      print('=== CURRENT ROUTE: ${Get.currentRoute} ===');
      for (final element in find.byType(Text).evaluate()) {
        final widget = element.widget as Text;
        if (widget.data != null && widget.data!.trim().isNotEmpty) {
          // ignore: avoid_print
          print('  "${widget.data}"');
        }
      }

      await dismissOnboardingIfPresent(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ignore: avoid_print
      print('=== AFTER dismissing onboarding ===');
      // ignore: avoid_print
      print('=== CURRENT ROUTE: ${Get.currentRoute} ===');
      // ignore: avoid_print
      print('=== TEXT WIDGETS ON SCREEN ===');
      for (final element in find.byType(Text).evaluate()) {
        final widget = element.widget as Text;
        if (widget.data != null && widget.data!.trim().isNotEmpty) {
          // ignore: avoid_print
          print('  "${widget.data}"');
        }
      }
      // ignore: avoid_print
      print('=== END DUMP ===');
    });
  });

  group('Login flow - all roles', () {
    for (final user in testUsers) {
      testWidgets('${user.role} can log in and log out successfully', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await performLogin(tester, user);

        // Confirms login worked: the role's logout button only exists once
        // AdminScaffold (staff) or ParentProfile (parent) has loaded.
        expect(find.byKey(Key(user.logoutKey)), findsOneWidget,
            reason: '${user.role} did not reach their home screen after login');

        // Clean logout so the next test starts from a fresh login screen.
        await performLogout(tester, user.logoutKey);
      });
    }

    testWidgets('Invalid credentials show error message', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await ensureAtLoginScreen(tester);

      await waitFor(tester, find.byKey(const Key('email_field')));
      await tester.enterText(find.byKey(const Key('email_field')), 'corres@gmail.com');

      await waitFor(tester, find.byKey(const Key('password_field')));
      await tester.enterText(find.byKey(const Key('password_field')), 'correspo@1234');

      await waitFor(tester, find.byKey(const Key('login_button')));
      await tester.tap(find.byKey(const Key('login_button')));

      // Poll with small pumps so we don't blow past the SnackBar's
      // auto-dismiss window the way a single pumpAndSettle would.
      final expectedFinder = find.text('Invalid credentials');
      bool found = false;
      for (int i = 0; i < 40; i++) { // ~10s total, 250ms steps
        await tester.pump(const Duration(milliseconds: 250));
        if (expectedFinder.evaluate().isNotEmpty) {
          found = true;
          break;
        }
      }

      if (!found) {
        // ignore: avoid_print
        print('=== "Invalid credentials" not found. Actual text on screen: ===');
        for (final element in find.byType(Text).evaluate()) {
          final widget = element.widget as Text;
          if (widget.data != null && widget.data!.trim().isNotEmpty) {
            // ignore: avoid_print
            print('  "${widget.data}"');
          }
        }
      }

      // Assert BEFORE letting the ticker run out, so the failure message is
      // still about the missing text, not a teardown crash.
      expect(found, isTrue, reason: 'Snackbar with "Invalid credentials" never appeared');

      // Now that we've captured what we need, let the snackbar's animation
      // (entrance + its own auto-dismiss) finish completely before the test
      // ends, so its AnimationController disposes cleanly instead of getting
      // torn down mid-flight.
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });
}
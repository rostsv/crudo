import 'package:checks/checks.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/local_user.dart';
import 'package:crudo/data/repositories/in_memory_profile_repository.dart';
import 'package:crudo/domain/profile/user_profile.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/features/profile/views/logout_confirm_sheet.dart';
import 'package:crudo/ui/features/profile/views/paywall_sheet.dart';
import 'package:crudo/ui/features/profile/view_models/profile_controller.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  Widget app() {
    container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(
          InMemoryProfileRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: crudoTheme,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, child) {
              ref.watch(profileProvider);
              return Builder(
                builder: (context) => Column(
                  children: [
                    TextButton(
                      onPressed: () => showLogoutConfirmSheet(context),
                      child: const Text('open logout'),
                    ),
                    TextButton(
                      onPressed: () => showPaywallSheet(context),
                      child: const Text('open paywall'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  group('LogoutConfirmSheet', () {
    testWidgets('tap Sign out resets profile and shows toast', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      // Precondition: set a display name
      await container
          .read(profileControllerProvider.notifier)
          .setDisplayName('Mark');
      await tester.pumpAndSettle();

      var profile = await container.read(profileRepositoryProvider).get();
      check(profile.displayName).equals('Mark');

      await tester.tap(find.text('open logout'));
      await tester.pumpAndSettle();

      expect(find.text('Sign out?'), findsOneWidget);
      expect(
        find.text(
          'You can sign back in anytime. Your local data stays on this device.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);

      // Tap Sign out
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      // Sheet should be dismissed
      expect(find.text('Sign out?'), findsNothing);

      // Profile should be reset
      profile = await container.read(profileRepositoryProvider).get();
      check(profile).equals(const UserProfile(id: localUserId));

      // Toast should be shown
      expect(find.text('Signed out'), findsOneWidget);

      // Dismiss toast to clean up timer
      await tester.tap(find.byKey(const ValueKey('toast-dismiss')));
      await tester.pumpAndSettle();
    });

    testWidgets('tap Cancel just pops', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await container
          .read(profileControllerProvider.notifier)
          .setDisplayName('Mark');
      await tester.pumpAndSettle();

      await tester.tap(find.text('open logout'));
      await tester.pumpAndSettle();

      expect(find.text('Sign out?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Sheet should be dismissed
      expect(find.text('Sign out?'), findsNothing);

      // Profile should remain unchanged
      final profile = await container.read(profileRepositoryProvider).get();
      check(profile.displayName).equals('Mark');
    });
  });

  group('PaywallSheet', () {
    testWidgets('renders both plan tiles + prices + CTA', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.text('open paywall'));
      await tester.pumpAndSettle();

      expect(find.text('CRUDO PREMIUM'), findsOneWidget);
      expect(find.text('Keep your streak alive'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('€6.99/mo'), findsOneWidget);
      expect(find.text('Annual'), findsOneWidget);
      expect(find.text('€39.99/yr'), findsOneWidget);
      expect(find.text('· €3.33/mo'), findsOneWidget);
      expect(find.text('BEST VALUE'), findsOneWidget);
      expect(find.text('7-day free trial'), findsOneWidget);
      expect(find.text('Start free trial'), findsOneWidget);
    });

    testWidgets('CTA pops sheet', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.text('open paywall'));
      await tester.pumpAndSettle();

      expect(find.text('Keep your streak alive'), findsOneWidget);

      await tester.tap(find.text('Start free trial'));
      await tester.pumpAndSettle();

      expect(find.text('Keep your streak alive'), findsNothing);
    });
  });
}

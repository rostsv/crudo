import 'package:crudo/config/di.dart';
import 'package:crudo/data/local_user.dart';
import 'package:crudo/data/repositories/in_memory_profile_repository.dart';
import 'package:crudo/data/repositories/in_memory_streak_repository.dart';
import 'package:crudo/domain/profile/prefs.dart';
import 'package:crudo/domain/profile/user_profile.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/streak/streak.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/settings_section.dart';
import 'package:crudo/ui/features/history/view_models/history_providers.dart';
import 'package:crudo/ui/features/profile/views/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late InMemoryProfileRepository profileRepo;
  late InMemoryStreakRepository streakRepo;

  Future<void> seedData() async {
    await profileRepo.save(
      const UserProfile(
        id: localUserId,
        displayName: 'Mark Kovac',
        prefs: Prefs(
          units: Unit.oz,
          streakThreshold: 90,
          goal: Goal.maintain,
          dailyKcalTarget: 2200,
        ),
      ),
    );
    await streakRepo.save(const Streak(current: 7, personalBest: 30));
  }

  Widget app() {
    profileRepo = InMemoryProfileRepository();
    streakRepo = InMemoryStreakRepository();

    container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(profileRepo),
        streakRepositoryProvider.overrideWithValue(streakRepo),
        streakProvider.overrideWith(
          (ref) => Stream.value(const Streak(current: 7, personalBest: 30)),
        ),
      ],
    );
    addTearDown(container.dispose);

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: crudoTheme,
        home: const Scaffold(body: ProfileScreen()),
      ),
    );
  }

  testWidgets('renders profile header, settings, badges, sign out', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final w = app();
    await seedData();
    await tester.pumpWidget(w);
    await tester.pumpAndSettle();

    // Header
    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Avatar + name
    expect(find.text('Mark Kovac'), findsOneWidget);
    expect(find.text('MK'), findsOneWidget);

    // Settings rows
    final unitsRow = find.widgetWithText(SettingsRow, 'Units');
    expect(unitsRow, findsOneWidget);
    expect(find.text('Ounces'), findsOneWidget);
    expect(find.text('Maintain · 2200 kcal/day'), findsOneWidget);
    expect(find.text('90% of planned calories'), findsOneWidget);

    // Badges
    expect(find.text('7'), findsNWidgets(2));
    expect(find.text('30'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);

    // Sign out
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('tapping Units row opens the units sheet', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final w = app();
    await seedData();
    await tester.pumpWidget(w);
    await tester.pumpAndSettle();

    final unitsRow = find.widgetWithText(SettingsRow, 'Units');
    expect(unitsRow, findsOneWidget);

    await tester.tap(unitsRow);
    await tester.pumpAndSettle();

    // Sheet opens with Grams option
    expect(find.text('Grams'), findsOneWidget);
  });
}

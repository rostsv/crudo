// test/ui/features/profile/profile_controller_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/local_user.dart';
import 'package:crudo/data/repositories/in_memory_profile_repository.dart';
import 'package:crudo/domain/profile/prefs.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/ui/features/profile/view_models/profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(
          InMemoryProfileRepository(),
        ),
      ],
    );
  }

  group('ProfileController', () {
    test('setUnits(Unit.oz) changes units, leaves other fields', () async {
      final c = createContainer();
      addTearDown(c.dispose);

      // Precondition: default units are g
      var profile = await c.read(profileRepositoryProvider).get();
      check(profile.prefs.units).equals(Unit.g);

      await c.read(profileControllerProvider.notifier).setUnits(Unit.oz);

      profile = await c.read(profileRepositoryProvider).get();
      check(profile.prefs.units).equals(Unit.oz);
      check(profile.prefs.goal).equals(Goal.maintain); // unchanged
      check(profile.prefs.streakThreshold).equals(80); // unchanged
    });

    test('setThreshold(90) changes streakThreshold', () async {
      final c = createContainer();
      addTearDown(c.dispose);

      await c.read(profileControllerProvider.notifier).setThreshold(90);

      final profile = await c.read(profileRepositoryProvider).get();
      check(profile.prefs.streakThreshold).equals(90);
      check(profile.prefs.units).equals(Unit.g); // unchanged
    });

    test('setGoal(Goal.bulk, kcalTarget: 2200) sets both', () async {
      final c = createContainer();
      addTearDown(c.dispose);

      await c
          .read(profileControllerProvider.notifier)
          .setGoal(Goal.bulk, kcalTarget: 2200);

      final profile = await c.read(profileRepositoryProvider).get();
      check(profile.prefs.goal).equals(Goal.bulk);
      check(profile.prefs.dailyKcalTarget).equals(2200);
    });

    test('setGoal(Goal.cut) clears dailyKcalTarget', () async {
      final c = createContainer();
      addTearDown(c.dispose);

      // First set with target
      await c
          .read(profileControllerProvider.notifier)
          .setGoal(Goal.bulk, kcalTarget: 2200);
      // Then set without target
      await c.read(profileControllerProvider.notifier).setGoal(Goal.cut);

      final profile = await c.read(profileRepositoryProvider).get();
      check(profile.prefs.goal).equals(Goal.cut);
      check(profile.prefs.dailyKcalTarget).isNull();
    });

    test('setNotifToggle(pre: false) only changes preOn', () async {
      final c = createContainer();
      addTearDown(c.dispose);

      await c
          .read(profileControllerProvider.notifier)
          .setNotifToggle(pre: false);

      final profile = await c.read(profileRepositoryProvider).get();
      check(profile.prefs.preOn).isFalse();
      check(profile.prefs.atOn).isTrue(); // default
      check(profile.prefs.eodOn).isTrue(); // default
      check(profile.prefs.riskOn).isTrue(); // default
    });

    test('setPreMin(25) changes preMin', () async {
      final c = createContainer();
      addTearDown(c.dispose);

      await c.read(profileControllerProvider.notifier).setPreMin(25);

      final profile = await c.read(profileRepositoryProvider).get();
      check(profile.prefs.preMin).equals(25);
    });

    test('setDisplayName saves display name', () async {
      final c = createContainer();
      addTearDown(c.dispose);

      await c.read(profileControllerProvider.notifier).setDisplayName('Mark');

      final profile = await c.read(profileRepositoryProvider).get();
      check(profile.displayName).equals('Mark');
    });

    test('signOut resets profile to defaults', () async {
      final c = createContainer();
      addTearDown(c.dispose);

      // First mutate something
      await c.read(profileControllerProvider.notifier).setDisplayName('Mark');
      var profile = await c.read(profileRepositoryProvider).get();
      check(profile.displayName).equals('Mark');

      await c.read(profileControllerProvider.notifier).signOut();

      profile = await c.read(profileRepositoryProvider).get();
      check(profile.id).equals(localUserId);
      check(profile.displayName).isNull();
      check(profile.prefs).equals(const Prefs());
    });
  });
}

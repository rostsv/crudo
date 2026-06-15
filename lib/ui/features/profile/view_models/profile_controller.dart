import 'package:crudo/config/di.dart';
import 'package:crudo/data/local_user.dart';
import 'package:crudo/domain/profile/prefs.dart';
import 'package:crudo/domain/profile/user_profile.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_controller.g.dart';

/// Stateless command controller (S15). The screen reads profileProvider for
/// display; this only mutates. Each method reads the current profile, copyWith
/// one field, saves — ProfileRepository.save re-emits through watch().
@riverpod
class ProfileController extends _$ProfileController {
  @override
  void build() {}

  Future<void> _mutate(Prefs Function(Prefs) f) async {
    final repo = ref.read(profileRepositoryProvider);
    final p = await repo.get();
    await repo.save(p.copyWith(prefs: f(p.prefs)));
  }

  Future<void> setUnits(Unit units) => _mutate((p) => p.copyWith(units: units));

  Future<void> setGoal(Goal goal, {int? kcalTarget}) =>
      _mutate((p) => p.copyWith(goal: goal, dailyKcalTarget: kcalTarget));

  Future<void> setThreshold(int threshold) =>
      _mutate((p) => p.copyWith(streakThreshold: threshold));

  Future<void> setPreMin(int minutes) =>
      _mutate((p) => p.copyWith(preMin: minutes));

  Future<void> setNotifToggle({bool? pre, bool? at, bool? eod, bool? risk}) =>
      _mutate(
        (p) => p.copyWith(
          preOn: pre ?? p.preOn,
          atOn: at ?? p.atOn,
          eodOn: eod ?? p.eodOn,
          riskOn: risk ?? p.riskOn,
        ),
      );

  Future<void> setDisplayName(String name) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.save((await repo.get()).copyWith(displayName: name));
  }

  /// Local stub — real session teardown is S22.
  Future<void> signOut() => ref
      .read(profileRepositoryProvider)
      .save(const UserProfile(id: localUserId));
}

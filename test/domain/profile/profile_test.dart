// test/domain/profile/profile_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/profile/prefs.dart';
import 'package:crudo/domain/profile/user_profile.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prefs defaults match spec', () {
    const p = Prefs();
    check(p.goal).equals(Goal.maintain);
    check(p.units).equals(Unit.g);
    check(p.dailyKcalTarget).isNull();
    check(p.streakThreshold).equals(80);
    check(p.reminderMode).equals(ReminderMode.fixed);
    check(p.preOn).isTrue();
    check(p.atOn).isTrue();
    check(p.eodOn).isTrue();
    check(p.riskOn).isTrue();
    check(p.preMin).equals(30);
  });

  test('prefs asserts preMin >= 0', () {
    check(() => Prefs(preMin: -1)).throws<AssertionError>();
  });

  test('profile defaults prefs, allows display name', () {
    const u = UserProfile(id: 'u1');
    check(u.prefs).equals(const Prefs());
    check(u.displayName).isNull();
    check(u.copyWith(displayName: 'Rost').displayName).equals('Rost');
  });
}

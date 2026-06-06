import 'package:crudo/domain/shared/macros.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'intake_freeze.g.dart';

/// Holds the consumed-macros snapshot shown by the intake hero while a meal
/// sheet is open (S06.1): freeze on open, clear on close. Null = render the
/// live value. Persistence is NOT deferred — only the hero's rendering.
@riverpod
class IntakeFreeze extends _$IntakeFreeze {
  @override
  Macros? build() => null;

  void freeze(Macros consumed) => state = consumed;

  void clear() => state = null;
}

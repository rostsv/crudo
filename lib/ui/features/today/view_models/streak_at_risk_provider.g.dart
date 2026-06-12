// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_at_risk_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(streakAtRisk)
final streakAtRiskProvider = StreakAtRiskProvider._();

final class StreakAtRiskProvider
    extends
        $FunctionalProvider<
          AsyncValue<StreakRisk?>,
          StreakRisk?,
          FutureOr<StreakRisk?>
        >
    with $FutureModifier<StreakRisk?>, $FutureProvider<StreakRisk?> {
  StreakAtRiskProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'streakAtRiskProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$streakAtRiskHash();

  @$internal
  @override
  $FutureProviderElement<StreakRisk?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<StreakRisk?> create(Ref ref) {
    return streakAtRisk(ref);
  }
}

String _$streakAtRiskHash() => r'3859443dd9c4dc0a673af06a162a90a9cecd3716';

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intake_freeze.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the consumed-macros snapshot shown by the intake hero while a meal
/// sheet is open (S06.1): freeze on open, clear on close. Null = render the
/// live value. Persistence is NOT deferred — only the hero's rendering.

@ProviderFor(IntakeFreeze)
final intakeFreezeProvider = IntakeFreezeProvider._();

/// Holds the consumed-macros snapshot shown by the intake hero while a meal
/// sheet is open (S06.1): freeze on open, clear on close. Null = render the
/// live value. Persistence is NOT deferred — only the hero's rendering.
final class IntakeFreezeProvider
    extends $NotifierProvider<IntakeFreeze, Macros?> {
  /// Holds the consumed-macros snapshot shown by the intake hero while a meal
  /// sheet is open (S06.1): freeze on open, clear on close. Null = render the
  /// live value. Persistence is NOT deferred — only the hero's rendering.
  IntakeFreezeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'intakeFreezeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$intakeFreezeHash();

  @$internal
  @override
  IntakeFreeze create() => IntakeFreeze();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Macros? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Macros?>(value),
    );
  }
}

String _$intakeFreezeHash() => r'fee772aab85543d0e45b58ea4674ea298b6e473a';

/// Holds the consumed-macros snapshot shown by the intake hero while a meal
/// sheet is open (S06.1): freeze on open, clear on close. Null = render the
/// live value. Persistence is NOT deferred — only the hero's rendering.

abstract class _$IntakeFreeze extends $Notifier<Macros?> {
  Macros? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Macros?, Macros?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Macros?, Macros?>,
              Macros?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

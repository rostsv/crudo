// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stateless command controller (S15). The screen reads profileProvider for
/// display; this only mutates. Each method reads the current profile, copyWith
/// one field, saves — ProfileRepository.save re-emits through watch().

@ProviderFor(ProfileController)
final profileControllerProvider = ProfileControllerProvider._();

/// Stateless command controller (S15). The screen reads profileProvider for
/// display; this only mutates. Each method reads the current profile, copyWith
/// one field, saves — ProfileRepository.save re-emits through watch().
final class ProfileControllerProvider
    extends $NotifierProvider<ProfileController, void> {
  /// Stateless command controller (S15). The screen reads profileProvider for
  /// display; this only mutates. Each method reads the current profile, copyWith
  /// one field, saves — ProfileRepository.save re-emits through watch().
  ProfileControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileControllerHash();

  @$internal
  @override
  ProfileController create() => ProfileController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$profileControllerHash() => r'415a11233d61e0dd726cf743b8da63b3e84d40b6';

/// Stateless command controller (S15). The screen reads profileProvider for
/// display; this only mutates. Each method reads the current profile, copyWith
/// one field, saves — ProfileRepository.save re-emits through watch().

abstract class _$ProfileController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

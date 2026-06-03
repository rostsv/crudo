import 'package:freezed_annotation/freezed_annotation.dart';

import 'prefs.dart';

part 'user_profile.freezed.dart';

/// The per-user root that scopes repositories (S03). Auth/identity fields
/// arrive with S22 — for now an id, optional display name, and settings.
@freezed
abstract class UserProfile with _$UserProfile {
  const UserProfile._();

  const factory UserProfile({
    required String id,
    String? displayName,
    @Default(Prefs()) Prefs prefs,
  }) = _UserProfile;
}

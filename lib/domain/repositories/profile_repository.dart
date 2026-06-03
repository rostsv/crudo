import '../profile/user_profile.dart';

/// Single source of truth for the local user profile.
/// [watch] emits the current profile immediately on listen, then on every change.
/// [get] auto-seeds a default [UserProfile] with [id] = local user id.
abstract class ProfileRepository {
  Stream<UserProfile> watch();
  Future<UserProfile> get();
  Future<void> save(UserProfile profile);
}

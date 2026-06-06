import 'dart:async';

import 'package:crudo/domain/profile/user_profile.dart';
import 'package:crudo/domain/repositories/profile_repository.dart';

import '../local_user.dart';

class InMemoryProfileRepository implements ProfileRepository {
  UserProfile _profile = const UserProfile(id: localUserId);
  final _changes = StreamController<UserProfile>.broadcast();

  @override
  Stream<UserProfile> watch() {
    late StreamController<UserProfile> controller;
    late StreamSubscription<UserProfile> sub;
    controller = StreamController<UserProfile>(
      onListen: () {
        controller.add(_profile);
        sub = _changes.stream.listen(controller.add);
      },
      onCancel: () {
        sub.cancel();
        controller.close();
      },
    );
    return controller.stream;
  }

  @override
  Future<UserProfile> get() async => _profile;

  @override
  Future<void> save(UserProfile profile) async {
    _profile = profile;
    _changes.add(profile);
  }
}

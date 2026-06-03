import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// App-side id generation: uuid v7 (time-ordered — B-tree friendly at S19,
/// client-creatable for offline-first). Override the provider in tests for
/// deterministic ids.
class IdGenerator {
  const IdGenerator();

  String newId() => const Uuid().v7();
}

final idGeneratorProvider = Provider<IdGenerator>((ref) => const IdGenerator());

import 'dart:async';

/// Reactive in-memory store shared by the template-library repositories.
/// Streams emit the current snapshot immediately on listen, then after every
/// mutation — mirroring Supabase realtime-with-initial-fetch (S20).
class InMemoryCrud<T> {
  InMemoryCrud(this._idOf, [Iterable<T> seed = const []]) {
    for (final entity in seed) {
      _store[_idOf(entity)] = entity;
    }
  }

  final String Function(T) _idOf;
  final _store = <String, T>{};
  final _changes = StreamController<void>.broadcast();

  List<T> get _snapshot => List.unmodifiable(_store.values);

  Stream<List<T>> watchAll() {
    late StreamController<List<T>> controller;
    late StreamSubscription<void> sub;
    controller = StreamController<List<T>>(
      onListen: () {
        controller.add(_snapshot);
        sub = _changes.stream.listen((_) => controller.add(_snapshot));
      },
      onCancel: () {
        sub.cancel();
        controller.close();
      },
    );
    return controller.stream;
  }

  Future<List<T>> getAll() async => _snapshot;

  Future<T?> getById(String id) async => _store[id];

  Future<void> save(T entity) async {
    _store[_idOf(entity)] = entity;
    _changes.add(null);
  }

  Future<void> delete(String id) async {
    _store.remove(id);
    _changes.add(null);
  }
}

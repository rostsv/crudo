import 'package:checks/checks.dart';
import 'package:crudo/data/local_user.dart';
import 'package:crudo/data/repositories/in_memory_day_repository.dart';
import 'package:crudo/data/repositories/in_memory_product_repository.dart';
import 'package:crudo/data/repositories/in_memory_profile_repository.dart';
import 'package:crudo/data/repositories/in_memory_streak_repository.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/product/product.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:flutter_test/flutter_test.dart';

const _chicken = Product(
  id: 'p1',
  name: 'Chicken',
  category: ProductCategory.meat,
  protein: 31,
  carbs: 0,
  fats: 3.6,
);

void main() {
  test('crud: save/get/upsert/delete round-trip', () async {
    final repo = InMemoryProductRepository();
    await repo.save(_chicken);
    check(await repo.getById('p1')).equals(_chicken);
    await repo.save(_chicken.copyWith(name: 'Chicken breast'));
    check((await repo.getById('p1'))!.name).equals('Chicken breast');
    check((await repo.getAll()).length).equals(1); // upsert, not duplicate
    await repo.delete('p1');
    check(await repo.getById('p1')).isNull();
    check(await repo.getAll()).isEmpty();
  });

  test('seeded products are present and overlay with user saves', () async {
    final repo = InMemoryProductRepository(seed: const [_chicken]);
    check((await repo.getAll()).length).equals(1);
    await repo.save(_chicken.copyWith(id: 'p2', isCustom: true));
    check((await repo.getAll()).length).equals(2);
  });

  test('watchAll emits current state on listen, then on mutations', () async {
    final repo = InMemoryProductRepository(seed: const [_chicken]);
    final emissions = <int>[];
    final sub = repo.watchAll().listen((list) => emissions.add(list.length));
    await Future<void>.delayed(Duration.zero); // initial emission
    await repo.save(_chicken.copyWith(id: 'p2'));
    await repo.delete('p1');
    await Future<void>.delayed(Duration.zero);
    check(emissions).deepEquals([1, 2, 1]);
    await sub.cancel();
  });

  test('day repo: keyed by date label; range inclusive + sorted', () async {
    final repo = InMemoryDayRepository();
    final d1 = Day(date: DateTime.utc(2026, 6, 1));
    final d2 = Day(date: DateTime.utc(2026, 6, 2));
    final d3 = Day(date: DateTime.utc(2026, 6, 5));
    await repo.save(d3);
    await repo.save(d1);
    await repo.save(d2);
    check(await repo.getByDate(DateTime.utc(2026, 6, 2))).equals(d2);
    check(await repo.getByDate(DateTime.utc(2026, 6, 3))).isNull();
    final range = await repo.getRange(
      DateTime.utc(2026, 6, 1),
      DateTime.utc(2026, 6, 2),
    );
    check(range).deepEquals([d1, d2]); // inclusive + sorted
  });

  test('day repo: watchByDate emits null, then the saved day', () async {
    final repo = InMemoryDayRepository();
    final date = DateTime.utc(2026, 6, 3);
    final emissions = <Day?>[];
    final sub = repo.watchByDate(date).listen(emissions.add);
    await Future<void>.delayed(Duration.zero);
    final day = Day(date: date);
    await repo.save(day);
    await Future<void>.delayed(Duration.zero);
    check(emissions.length).equals(2);
    check(emissions.first).isNull();
    check(emissions.last).equals(day);
    await sub.cancel();
  });

  test('profile auto-seeds local user; streak defaults', () async {
    final profile = await InMemoryProfileRepository().get();
    check(profile.id).equals(localUserId);
    final streak = await InMemoryStreakRepository().get();
    check(streak.current).equals(0);
  });
}

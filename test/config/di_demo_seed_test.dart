import 'package:checks/checks.dart';
import 'package:crudo/config/app_config.dart';
import 'package:crudo/config/di.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _container(Flavor flavor) {
  final c = ProviderContainer(
    overrides: [appConfigProvider.overrideWithValue(AppConfig(flavor: flavor))],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('dev flavor seeds 4 demo meals + 1 everyday plan', () async {
    final c = _container(Flavor.dev);
    final meals = await c.read(mealTemplateRepositoryProvider).getAll();
    final plans = await c.read(planTemplateRepositoryProvider).getAll();
    check(meals.length).equals(4);
    check(plans.length).equals(1);
    check(plans.single.days).deepEquals([0, 1, 2, 3, 4, 5, 6]);
    check(plans.single.slots.length).equals(4);
  });

  test('prod flavor stays unseeded', () async {
    final c = _container(Flavor.prod);
    check(await c.read(mealTemplateRepositoryProvider).getAll()).isEmpty();
    check(await c.read(planTemplateRepositoryProvider).getAll()).isEmpty();
  });
}

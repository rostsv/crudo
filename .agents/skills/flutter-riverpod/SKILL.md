---
name: flutter-riverpod-arch
description: Riverpod 3.x state management patterns for this Flutter app. Use when adding or modifying state, providers, or async logic.
---

# Flutter Riverpod Architecture Skill

## When to use this skill

Use this skill whenever you:

- Add or update state for a feature or screen.
- Introduce new async flows (API calls, Supabase queries, stream listeners).
- Refactor existing state management from setState/Bloc/Provider to Riverpod.
- Add tests for stateful logic.

Keywords that should activate this skill: **riverpod**, **provider**, **state**, **AsyncNotifier**, **Notifier**, **StateNotifier**, **ref.watch**, **ref.read**, **ProviderScope**.

---

## Global setup

- The app must be wrapped in a `ProviderScope` at the root:

```dart
void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

- Prefer **Riverpod 3.x annotation-based APIs** (`@riverpod`, `Notifier`, `AsyncNotifier`) instead of legacy `StateNotifierProvider` where possible. New code should follow the modern patterns.
- All Riverpod dependencies are added via `pubspec.yaml` (flutter_riverpod, riverpod_annotation, riverpod_generator, build_runner, riverpod_lint).

---

## Folder & file conventions

For each feature under `lib/features/<feature_name>/`:

- `application/`
    - Riverpod providers, controllers, and use cases.
    - Example files:
        - `application/providers.dart`
        - `application/<entity>_controller.dart`

- `presentation/`
    - Widgets/screens that **consume** providers but do not implement business logic.
    - Widgets read state via `ref.watch` and call controller methods via `ref.read`.

- `infrastructure/`
    - Repositories and data sources that providers call.
    - No direct widget imports here.

---

## Provider types and when to use them

Choose the smallest tool that works:

- `Provider`
    - Immutable values, configuration, DI (e.g., repository instances).

- `Notifier` (via `NotifierProvider` / `@riverpod` class extending `_$Name`)
    - Complex synchronous state with business logic (forms, filters, local lists).

- `AsyncNotifier`
    - Async state that needs loading/error handling (API calls, Supabase queries).

- `FutureProvider` / `StreamProvider`
    - Simple one-off async reads or streams where you don’t need methods on a controller.

Prefer `Notifier` / `AsyncNotifier` for new business logic, because they provide a clear home for methods and make testing easier.

---

## Recommended patterns

### 1. Async controller with `AsyncNotifier` + codegen

Use this for data that has explicit loading/error states and may be refreshed:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'todos_controller.g.dart';

@riverpod
class TodosController extends _$TodosController {
  @override
  FutureOr<List<Todo>> build() async {
    final repo = ref.read(todoRepositoryProvider);
    return repo.fetchTodos();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(todoRepositoryProvider);
      return repo.fetchTodos();
    });
  }

  Future<void> addTodo(Todo newTodo) async {
    final repo = ref.read(todoRepositoryProvider);
    await repo.addTodo(newTodo);
    await refresh();
  }
}
```

Usage in widgets:

```dart
class TodosScreen extends ConsumerWidget {
  const TodosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosState = ref.watch(todosControllerProvider);

    return todosState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Error: $err')),
      data: (todos) => ListView.builder(
        itemCount: todos.length,
        itemBuilder: (context, index) => Text(todos[index].title),
      ),
    );
  }
}
```

### 2. Simple synchronous controller with `Notifier`

Use for local UI state (filters, step index, toggles):

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'filter_controller.g.dart';

@riverpod
class FilterController extends _$FilterController {
  @override
  FilterState build() => const FilterState.initial();

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void toggleOnlyFavorites() {
    state = state.copyWith(onlyFavorites: !state.onlyFavorites);
  }
}
```

---

## Do / Don’t rules

**Do**

- Keep all business logic inside Notifier/AsyncNotifier classes, not in widgets.
- Use `AsyncValue.guard` to wrap async operations so errors propagate into state.
- Use `.select` for fine-grained rebuilds on large state objects.
- Co-locate providers with their feature under `application/` for discoverability.
- Write unit tests for controllers without involving Flutter widgets.

**Don’t**

- Don’t mix Riverpod with random `setState` for the same piece of state.
- Don’t perform HTTP/Supabase calls in widgets; call repositories from controllers.
- Don’t keep navigation logic inside providers; prefer routing helpers or callbacks in the UI.
- Don’t use deprecated 2.x patterns (`StateNotifierProvider` with mutable state) for new code unless you are explicitly migrating old code.

---

## Testing guidelines

- Controllers (Notifiers/AsyncNotifiers) should have dedicated unit tests using `ProviderContainer`.
- Test async flows by overriding repository providers with fakes or mocks.
- Widget tests should verify that widgets react correctly to provider states (loading, error, data).

---

## Procedure for new stateful feature

When the user asks for a new feature that requires state, follow this sequence:

1. **Design state**
    - Define the data model and what transitions (methods) are needed.
2. **Create controller**
    - Implement a `Notifier` or `AsyncNotifier` in `application/`.
3. **Wire dependencies**
    - Read repositories/services using `ref.read` inside the controller.
4. **Expose provider**
    - Use the generated `...Provider` in widgets.
5. **Update UI**
    - In widgets, use `ref.watch` for read, `ref.read` for method calls.
6. **Add tests**
    - Controller unit tests + basic widget tests for loading/error/data states.
# S08 Swap Sheet Refinements — Tag Grouping + Sticky Search

> **Worker:** single-file UI change to `swap_sheet.dart`. Spec: `docs/specs/2026-06-07-s08-meal-editor.md` (S08 swap sheet contract extends this plan). Read the `.agents/skills/flutter-riverpod-arch` before starting.

**Goal:** Two refinements to the swap-from-library sheet — tag-based grouping ("Same type" first, "All meals" below) and a sticky search field that flattens sections. Pure UI, no domain/controller/route changes.

**Before:** flat `ListView` of all templates under `SheetScaffold`. **After:** inline sheet layout (mirrors `SheetScaffold`), partitioned + searchable list.

## Decisions (all settled in brainstorm)

| Decision | Choice |
|----------|--------|
| Tag matching | OR — any tag match qualifies (`t.tags.any(currentTags.contains)`) |
| No-tag current meal | Skip grouping entirely, flat list with no section headers |
| Empty "Same type" section (zero matching templates) | Hide the section, show only "All meals" section |
| Search + sections interaction | Search flattens to one filtered list (no headers). Clear → sections return |
| Section header labels | `"SAME TYPE"` / `"OTHER MEALS"` — both uppercase, `CrudoText.label`. 2nd section = remainder (non-matching), so `"OTHER MEALS"` not `"ALL MEALS"` (honest label, no duplicate rows) |
| Search field position | Sticky between title and list (never scrolls away) |
| Search UX | Standard text field with search icon prefix + `"Filter meals…"` hint |
| Sheet layout | Inline `Container` mirroring `SheetScaffold`'s exact style (grabber/label/title) — needed for `Expanded` child support |
| Conversion | `ConsumerWidget` → `ConsumerStatefulWidget` |

## File changes

| File | Change |
|------|--------|
| `lib/ui/features/meals/views/swap_sheet.dart` | Rewrite: ConsumerStatefulWidget, inline layout, partitioning, search. **New imports:** `../../../core/themes/input_decoration.dart` (`softInputDecoration`), `../../../../domain/shared/enums.dart` (`MealTag`), `package:collection/collection.dart` (`firstOrNull`) |
| `test/ui/features/meals/views/meal_detail_screen_test.dart` | Add 5 test cases (use existing `open()` harness) |

## Task 1: Swap sheet — tag grouping + sticky search

**Role:** ui (Flutter UI engineer).

**Goal:** see top-of-doc Goal — two refinements to the swap-from-library sheet (tag-based grouping + sticky search), pure UI.

**Files:**
- Rewrite: `lib/ui/features/meals/views/swap_sheet.dart` (new imports: `../../../core/themes/input_decoration.dart`, `../../../../domain/shared/enums.dart`, `package:collection/collection.dart`)
- Extend: `test/ui/features/meals/views/meal_detail_screen_test.dart` (5 new cases via existing `open()` harness)

**Contract:** the three "Contract —" sections below (sheet layout / partitioning / section header) are the verbatim contract — match named types/signatures exactly. Honor the **Unchanged** list (`_swap`, `_summary`, `_SwapRow`, empty state).

**Steps:** execute the "Steps (TDD — single task)" section below in order. No codegen (no `@freezed`/`@riverpod` touched → no `build_runner`).

**Skills:** `.agents/skills/flutter-riverpod-arch`, `.agents/skills/flutter-add-widget-test`, `.agents/skills/flutter-expert`.

**Out of scope:** the "Out of scope" section below.

## Contract — sheet layout (inline, mirrors SheetScaffold)

```dart
class SwapSheet extends ConsumerStatefulWidget {
  const SwapSheet({required this.date, required this.mealId, super.key});
  final DateTime date;
  final String mealId;
  @override
  ConsumerState<SwapSheet> createState() => _SwapSheetState();
}

class _SwapSheetState extends ConsumerState<SwapSheet> {
  late final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final templates = ref.watch(mealTemplatesProvider).value ?? const [];
    final foods = ref.watch(foodsProvider).value ?? const [];
    final day = ref.watch(dayControllerProvider(widget.date)).value;
    final meal = day?.meals.where((m) => m.id == widget.mealId).firstOrNull;
    final currentTags = meal?.meal.tags ?? const [];

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Radii.lg),
        ),
        boxShadow: Shadows.cloud,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(Spacing.md),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grabber
            Center(
              child: Container(
                width: 40,
                height: Spacing.xs,
                decoration: BoxDecoration(
                  color: colors.surfaceHighest,
                  borderRadius: Radii.all(Radii.full),
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
            // Label
            const Text('FROM YOUR LIBRARY', style: CrudoText.label),
            const SizedBox(height: Spacing.xs),
            // Title
            const Text('Swap meal', style: CrudoText.headline),
            const SizedBox(height: Spacing.md),
            // Search (sticky)
            TextField(
              key: const ValueKey('swap-search'),
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              style: CrudoText.body,
              decoration: softInputDecoration(
                colors,
                hint: 'Filter meals…',
                prefixIcon: Icon(
                  Icons.search,
                  size: IconSizes.md,
                  color: colors.onSurfaceMut,
                ),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            // List
            Expanded(
              child: templates.isEmpty
                  ? Center(
                      child: Text(
                        'No meals in your library yet.',
                        key: const ValueKey('swap-empty'),
                        style: CrudoText.body.copyWith(
                          color: colors.onSurfaceMut,
                        ),
                      ),
                    )
                  : ListView(
                      children: _buildSections(
                        templates, foods, currentTags, colors,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
```

## Contract — partitioning

```dart
List<Widget> _buildSections(
  List<MealTemplate> templates,
  List<Food> foods,
  List<MealTag> currentTags,
  CrudoColors colors,
) {
  // Searching: flat filtered list, no headers
  if (_query.isNotEmpty) {
    return [
      for (final t in templates)
        if (t.name.toLowerCase().contains(_query))
          _buildRow(t, foods, colors),
    ];
  }

  // No tags → flat list, no sections
  if (currentTags.isEmpty) {
    return [for (final t in templates) _buildRow(t, foods, colors)];
  }

  // Partition: OR match — template matches any of currentTags.
  final matching = <MealTemplate>[];
  final others = <MealTemplate>[];
  for (final t in templates) {
    if (t.tags.any((tag) => currentTags.contains(tag))) {
      matching.add(t);
    } else {
      others.add(t);
    }
  }

  final result = <Widget>[];
  if (matching.isNotEmpty) {
    result.add(const _SectionHeader(label: 'SAME TYPE'));
    for (final t in matching) result.add(_buildRow(t, foods, colors));
  }
  result.add(const _SectionHeader(label: 'OTHER MEALS'));
  for (final t in others) result.add(_buildRow(t, foods, colors));
  return result;
}

Widget _buildRow(MealTemplate t, List<Food> foods, CrudoColors colors) {
  final enabled = mealSnapshotFromTemplate(t, foods).items.isNotEmpty;
  return _SwapRow(
    key: ValueKey('swap-${t.id}'),
    name: t.name,
    summary: _summary(t, foods),
    enabled: enabled,
    colors: colors,
    onTap: () => _swap(t, foods),
  );
}
```

## Contract — section header

```dart
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.sm),
      child: Text(label, style: CrudoText.label),
    );
  }
}
```

> No `colors` param — `CrudoText.label` carries its own color (`onSurfaceMut`); an unused field would trip the `unused_field` lint and fail step-4 analyze.

## Unchanged

- **`_swap` method** — same `replaceMeal` + detach pre-check + guard toast + `Navigator.pop()`
- **`_summary` method** — same `mealSnapshotFromTemplate → mealSnapshotMacros → tag join`
- **`_SwapRow`** — same widget (name, summary, swap icon, opacity-disabled, GestureDetector)
- **Empty state** — same "No meals in your library yet." when templates.isEmpty

## Test plan

5 new tests in `meal_detail_screen_test.dart`, using existing `open()` harness:

**Before writing assertions: verify the `open()` harness seed fixtures.** The cases below assume specific seeded templates/tags (sm-0 [breakfast], sm-2 [snack] = only snack-tagged template, a template whose name contains "chicken"). Confirm these exist in the fixture and adjust IDs/names/tags/query strings to match before asserting — do not hardcode blind.

| # | Test | Verifies |
|---|------|----------|
| 1 | **Tag grouping visible** | sm-0 [breakfast] → "SAME TYPE" + "OTHER MEALS" headers, breakfast row in Same type |
| 2 | **No same-type matches** | sm-2 [snack] (only meal with tag) → "SAME TYPE" absent, "OTHER MEALS" present |
| 3 | **No-tag meal → flat** | covered by code review (pure data path) or skip |
| 4 | **Search flattens** | type "chicken" → sections gone, only matching row; clear → sections return |
| 5 | **Search zero matches** | type "xyzzy" → no rows, search field still present |

All existing tests must remain green (swap tile opens, guard toast, detach toast, empty repo, etc).

## Steps (TDD — single task)

1. **Add 5 tests** to `meal_detail_screen_test.dart`. Run → 5 new FAIL, old PASS.
2. **Rewrite `swap_sheet.dart`** per contract. No codegen (no providers).
3. **Run:** `flutter test --timeout=90s test/ui/features/meals/views/meal_detail_screen_test.dart` → all PASS. `flutter test --timeout=90s` → full suite green.
4. **Format + analyze:** `dart format .` clean · `flutter analyze` clean.

## Out of scope

- `SheetScaffold` modification
- Any domain, controller, route changes
- Template-editing, library management
- Sorting within sections
- Search persistence across sheet opens

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import 'food_library_list.dart';

/// S07: food library — appbar (back + title + add button) wraps the reusable
/// [FoodLibraryList] for the search+list body. Seed rows inert; custom rows
/// navigate to the edit form.
class FoodLibraryScreen extends ConsumerWidget {
  const FoodLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appbar row: optional back, title, add.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.md,
                Spacing.sm,
                Spacing.md,
                0,
              ),
              child: Row(
                children: [
                  if (context.canPop())
                    IconButton(
                      onPressed: context.pop,
                      icon: Icon(
                        Icons.arrow_back,
                        size: IconSizes.lg,
                        color: colors.onSurface,
                      ),
                    ),
                  const Expanded(
                    child: Text('Food library', style: CrudoText.headline),
                  ),
                  IconButton(
                    key: const ValueKey('add-food'),
                    onPressed: () => context.push('/foods/new'),
                    icon: Icon(
                      Icons.add,
                      size: IconSizes.lg,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            // Search + list body (FoodLibraryList). onPick is null →
            // library mode: custom rows navigate to edit, seed rows inert.
            const Expanded(child: FoodLibraryList()),
          ],
        ),
      ),
    );
  }
}

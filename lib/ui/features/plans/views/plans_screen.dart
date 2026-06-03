import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/themes/typography.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/widgets/primary_cta.dart';
import '../../../core/widgets/selection_card.dart';
import '../../../core/widgets/pill.dart';
import '../../../core/widgets/sheet.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          const Text('Plans', style: CrudoText.headline),
          const SizedBox(height: Spacing.lg),
          SelectionCard(
            title: 'Cut plan',
            subtitle: '5 meals',
            selected: true,
            onTap: () {},
          ),
          const SizedBox(height: Spacing.md),
          SelectionCard(
            title: 'Bulk plan',
            subtitle: '6 meals',
            selected: false,
            onTap: () {},
          ),
          const SizedBox(height: Spacing.lg),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              for (final (label, selected) in [
                ('Mon', true),
                ('Tue', false),
                ('Wed', true),
                ('Thu', false),
                ('Fri', false),
                ('Sat', false),
                ('Sun', false),
              ])
                Pill(label: label, selected: selected, onTap: () {}),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          PrimaryCta(
            label: 'New plan',
            onPressed: () => showCrudoSheet<void>(
              context,
              builder: (_) => const SheetScaffold(
                title: 'Demo Sheet',
                body: Center(child: Text('This is a demo sheet')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

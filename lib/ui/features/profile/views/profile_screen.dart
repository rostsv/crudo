import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/themes/typography.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/widgets/primary_cta.dart';
import '../../../core/widgets/selection_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          const Text('Profile', style: CrudoText.headline),
          const SizedBox(height: Spacing.lg),
          SelectionCard(
            title: 'Units',
            subtitle: 'Metric',
            selected: false,
            onTap: () {},
          ),
          const SizedBox(height: Spacing.md),
          SelectionCard(
            title: 'Goal',
            subtitle: 'Maintain',
            selected: false,
            onTap: () {},
          ),
          const SizedBox(height: Spacing.md),
          SelectionCard(
            title: 'Reminders',
            subtitle: 'Fixed time',
            selected: false,
            onTap: () {},
          ),
          const SizedBox(height: Spacing.lg),
          const PrimaryCta(label: 'Sign out', onPressed: null, enabled: false),
        ],
      ),
    );
  }
}

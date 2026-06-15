import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/profile/prefs.dart';
import '../../../../domain/shared/enums.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/settings_section.dart';
import '../../history/view_models/history_providers.dart';
import '../../today/view_models/today_providers.dart';
import 'display_name_sheet.dart';
import 'goal_sheet.dart';
import 'logout_confirm_sheet.dart';
import 'paywall_sheet.dart';
import 'reminders_sheet.dart';
import 'threshold_sheet.dart';
import 'units_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _badgeValues = [7, 30, 100];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final streak = ref.watch(streakProvider);
    final colors = Theme.of(context).extension<CrudoColors>()!;

    return SafeArea(
      child: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (p) => ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            // 1. Header
            const Text('ACCOUNT', style: CrudoText.label),
            const SizedBox(height: Spacing.xs),
            const Text('Profile', style: CrudoText.headline),
            const SizedBox(height: Spacing.lg),

            // 2. Avatar block
            _AvatarBlock(
              displayName: p.displayName,
              streakCurrent: streak.value?.current ?? 0,
              onTap: () => showDisplayNameSheet(context),
            ),
            const SizedBox(height: Spacing.lg),

            // 3. Subscription banner
            _SubscriptionBanner(onTap: () => showPaywallSheet(context)),
            const SizedBox(height: Spacing.lg),

            // 4. Settings
            SettingsSection(
              title: 'Settings',
              children: [
                SettingsRow(
                  label: 'Notifications',
                  subtitle: 'Pre-meal pings, end-of-day summary',
                  onTap: () => showRemindersSheet(context),
                ),
                const SizedBox(height: Spacing.sm),
                SettingsRow(
                  label: 'Goal',
                  subtitle: _goalSubtitle(p.prefs),
                  onTap: () => showGoalSheet(context),
                ),
                const SizedBox(height: Spacing.sm),
                SettingsRow(
                  label: 'Units',
                  subtitle: p.prefs.units == Unit.g ? 'Grams' : 'Ounces',
                  onTap: () => showUnitsSheet(context),
                ),
                const SizedBox(height: Spacing.sm),
                SettingsRow(
                  label: 'Streak threshold',
                  subtitle: '${p.prefs.streakThreshold}% of planned calories',
                  onTap: () => showThresholdSheet(context),
                ),
              ],
            ),
            const SizedBox(height: Spacing.lg),

            // 5. Badges
            _BadgesSection(personalBest: streak.value?.personalBest ?? 0),
            const SizedBox(height: Spacing.lg),

            // 6. Sign out
            GestureDetector(
              onTap: () => showLogoutConfirmSheet(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceLow,
                  borderRadius: Radii.all(Radii.full),
                ),
                child: Text(
                  'Sign out',
                  textAlign: TextAlign.center,
                  style: CrudoText.title.copyWith(color: colors.onSurface),
                ),
              ),
            ),
            const SizedBox(height: Spacing.md), // padding for nav
          ],
        ),
      ),
    );
  }

  static String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static String _goalSubtitle(Prefs p) {
    final label = p.goal.name[0].toUpperCase() + p.goal.name.substring(1);
    if (p.dailyKcalTarget != null) {
      return '$label · ${p.dailyKcalTarget} kcal/day';
    }
    return label;
  }
}

class _AvatarBlock extends StatelessWidget {
  const _AvatarBlock({
    required this.displayName,
    required this.streakCurrent,
    this.onTap,
  });

  final String? displayName;
  final int streakCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final initials = ProfileScreen._initials(displayName);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar circle with streak badge
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.surfaceHigh,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: CrudoText.headlineSm.copyWith(color: colors.onSurface),
                ),
              ),
              // Small gold streak badge
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.gold,
                    borderRadius: Radii.all(Radii.full),
                  ),
                  child: Text(
                    '$streakCurrent',
                    style: CrudoText.labelMd.copyWith(color: colors.onSurface),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          // Name
          Text(
            displayName ?? 'User',
            style: CrudoText.title.copyWith(color: colors.onSurface),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionBanner extends StatelessWidget {
  const _SubscriptionBanner({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceLowest,
          borderRadius: Radii.all(Radii.lg),
          boxShadow: Shadows.cloud,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('FREE TRIAL', style: CrudoText.label),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    'Upgrade to keep your streak.',
                    style: CrudoText.bodyLg.copyWith(color: colors.onSurface),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Icon(
              Icons.workspace_premium,
              size: IconSizes.lg,
              color: colors.gold,
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgesSection extends StatelessWidget {
  const _BadgesSection({required this.personalBest});

  final int personalBest;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Badges',
      children: [
        Row(
          children: [
            for (final value in ProfileScreen._badgeValues)
              Expanded(
                child: _BadgeTile(value: value, earned: personalBest >= value),
              ),
          ],
        ),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.value, required this.earned});

  final int value;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.xs),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: earned ? colors.goldSoft : colors.surfaceLow,
        borderRadius: Radii.all(Radii.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events,
            size: IconSizes.lg,
            color: earned ? colors.gold : colors.onSurfaceMut,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            '$value',
            style: CrudoText.bodyLg.copyWith(
              color: earned ? colors.onSurface : colors.onSurfaceMut,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

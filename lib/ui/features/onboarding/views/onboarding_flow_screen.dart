import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/themes/dimensions.dart' as dim;
import '../../../core/widgets/toast.dart';
import '../view_models/onboarding_controller.dart';
import 'pages/awareness_page.dart';
import 'pages/heard_about_page.dart';
import 'pages/structure_page.dart';
import 'pages/transformation_page.dart';
import 'pages/tried_apps_page.dart';
import 'pages/video_demo_page.dart';
import 'pages/welcome_page.dart';

/// Hosts the seven onboarding pages in a button-driven [PageView] bound to
/// [OnboardingController]. The [PageView] follows controller state and never
/// free-swipes.
class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _back(OnboardingController c, OnboardingState st) {
    if (st.pageIndex == 0) {
      Navigator.of(context).pop();
    } else {
      c.back();
    }
  }

  void _finish() {
    showCrudoToast(
      context,
      'Plan setup comes next',
      body: 'Building your first plan is the next step.',
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(onboardingControllerProvider);
    final c = ref.read(onboardingControllerProvider.notifier);

    ref.listen<int>(onboardingControllerProvider.select((s) => s.pageIndex), (
      _,
      next,
    ) {
      _controller.animateToPage(
        next,
        duration: dim.Durations.base,
        curve: Curves.easeInOut,
      );
    });

    return PageView(
      controller: _controller,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        WelcomePage(
          onSetUp: c.next,
          onSignIn: () => showCrudoToast(
            context,
            'Sign-in coming soon',
            body: 'Accounts arrive in a later update.',
          ),
        ),
        AwarenessPage(onContinue: c.next, onBack: () => _back(c, st)),
        StructurePage(onContinue: c.next, onBack: () => _back(c, st)),
        VideoDemoPage(
          onPlay: () => showCrudoToast(context, 'Demo video coming soon'),
          onContinue: c.next,
          onBack: () => _back(c, st),
        ),
        TransformationPage(onContinue: c.next, onBack: () => _back(c, st)),
        HeardAboutPage(
          selected: st.source,
          onSelect: c.setSource,
          onContinue: c.next,
          onBack: () => _back(c, st),
        ),
        TriedAppsPage(
          selected: st.tried,
          onSelect: c.setTried,
          onContinue: _finish,
          onBack: () => _back(c, st),
        ),
      ],
    );
  }
}

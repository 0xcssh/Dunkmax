import 'package:flutter/material.dart';

import '../../core/models/onboarding_profile.dart';
import '../../core/program_catalog.dart';
import '../../services/jump_log_store.dart';
import '../../services/workout_session_store.dart';
import '../../theme/app_theme.dart';
import '../analyze/analyze_flow.dart';
import 'tabs/home_tab.dart';
import 'tabs/placeholder_tab.dart';
import 'tabs/progress_tab.dart';
import 'tabs/train_tab.dart';

/// The signed-in app: a five-tab shell matching the reference (Home, Analyze,
/// Train, Feed, Progress). Train is the functional centrepiece.
class RootShell extends StatefulWidget {
  final OnboardingProfile profile;
  final WorkoutSessionStore sessionStore;
  final JumpLogStore jumpLogStore;

  const RootShell({
    super.key,
    required this.profile,
    required this.sessionStore,
    required this.jumpLogStore,
  });

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  // Default to Train — that's the tab with real content and the app's core job.
  int _index = 2;

  static const _tabs = [
    (Icons.home_rounded, 'HOME'),
    (Icons.monitor_heart_outlined, 'ANALYZE'),
    (Icons.fitness_center, 'TRAIN'),
    (Icons.groups_outlined, 'FEED'),
    (Icons.show_chart, 'PROGRESS'),
  ];

  @override
  Widget build(BuildContext context) {
    final program = ProgramCatalog.recommend(widget.profile);

    final pages = [
      HomeTab(
        profile: widget.profile,
        program: program,
        onStartTraining: () => setState(() => _index = 2),
      ),
      AnalyzeFlow(profile: widget.profile, jumpLogStore: widget.jumpLogStore),
      TrainTab(program: program, sessionStore: widget.sessionStore),
      const PlaceholderTab(
        title: 'Feed',
        icon: Icons.groups_outlined,
        message: 'See what other athletes are hitting. Coming soon.',
      ),
      ProgressTab(
        program: program,
        sessionStore: widget.sessionStore,
        jumpLogStore: widget.jumpLogStore,
        onGoToAnalyze: () => setState(() => _index = 1),
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: _BottomBar(
        index: _index,
        tabs: _tabs,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int index;
  final List<(IconData, String)> tabs;
  final ValueChanged<int> onTap;

  const _BottomBar({
    required this.index,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DunkColors.surface,
        border: Border(top: BorderSide(color: DunkColors.stroke)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < tabs.length; i++)
                _BarItem(
                  icon: tabs[i].$1,
                  label: tabs[i].$2,
                  active: i == index,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _BarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? DunkColors.primary : DunkColors.textTertiary;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

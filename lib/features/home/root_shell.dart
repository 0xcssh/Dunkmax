import 'package:flutter/material.dart';

import '../../core/models/onboarding_profile.dart';
import '../../core/program_catalog.dart';
import '../../services/athlete_profile_store.dart';
import '../../services/jump_log_store.dart';
import '../../services/leaderboard_service.dart';
import '../../services/workout_session_store.dart';
import '../../theme/app_theme.dart';
import '../analyze/analyze_flow.dart';
import '../feed/display_name_dialog.dart';
import '../feed/feed_tab.dart';
import 'standing_reach_dialog.dart';
import 'tabs/home_tab.dart';
import 'tabs/progress_tab.dart';
import 'tabs/train_tab.dart';

/// The signed-in app: a five-tab shell matching the reference (Home, Analyze,
/// Train, Feed, Progress). Train is the functional centrepiece.
class RootShell extends StatefulWidget {
  final OnboardingProfile profile;
  final WorkoutSessionStore sessionStore;
  final JumpLogStore jumpLogStore;
  final AthleteProfileStore athleteProfileStore;
  final LeaderboardService leaderboardService;
  final VoidCallback onRestartOnboarding;

  /// Persists an edit to a single onboarding answer (currently standing reach)
  /// and pushes the updated profile back down through this widget.
  final ValueChanged<OnboardingProfile> onProfileChanged;

  const RootShell({
    super.key,
    required this.profile,
    required this.sessionStore,
    required this.jumpLogStore,
    required this.athleteProfileStore,
    required this.leaderboardService,
    required this.onRestartOnboarding,
    required this.onProfileChanged,
  });

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  // Default to Train — that's the tab with real content and the app's core job.
  int _index = 2;

  /// Mirrored in state so changing it (here or from the Feed) rebuilds the
  /// Feed tab, which reloads the global board with the new name.
  late String _displayName = widget.athleteProfileStore.displayName;

  void _syncDisplayName() {
    final stored = widget.athleteProfileStore.displayName;
    if (stored != _displayName) setState(() => _displayName = stored);
  }

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
        sessionStore: widget.sessionStore,
        jumpLogStore: widget.jumpLogStore,
        onStartTraining: () => setState(() => _index = 2),
        onOpenSettings: () => _openSettings(context),
      ),
      AnalyzeFlow(profile: widget.profile, jumpLogStore: widget.jumpLogStore),
      TrainTab(program: program, sessionStore: widget.sessionStore),
      FeedTab(
        jumpLogStore: widget.jumpLogStore,
        athleteProfileStore: widget.athleteProfileStore,
        leaderboardService: widget.leaderboardService,
        heightInches: widget.profile.heightInches,
        displayName: _displayName,
        onDisplayNameChanged: _syncDisplayName,
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

  Future<void> _openSettings(BuildContext context) async {
    final reach = widget.profile.standingReachInches;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: DunkColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: DunkColors.stroke,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'SETTINGS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsRow(
                  icon: Icons.badge_outlined,
                  label: 'Leaderboard name',
                  // Honest about the consent gate: no name, nothing published.
                  value: _displayName.isEmpty ? 'Not set' : _displayName,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _editDisplayName(context);
                  },
                ),
                const SizedBox(height: 10),
                _SettingsRow(
                  icon: Icons.straighten,
                  label: 'Standing reach',
                  // Honest about which number the dunk target rests on: until
                  // it's measured, everything downstream uses an estimate.
                  value: reach == null ? 'Not set' : '$reach"',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _editStandingReach(context);
                  },
                ),
                const SizedBox(height: 10),
                _SettingsRow(
                  icon: Icons.refresh,
                  label: 'Retake onboarding',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _confirmRestartOnboarding(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Lets the athlete choose (or change) the name shown on the global board.
  Future<void> _editDisplayName(BuildContext context) async {
    final chosen = await showDisplayNameDialog(
      context,
      initialName: _displayName,
    );
    if (chosen == null) return;
    await widget.athleteProfileStore.setDisplayName(chosen);
    if (!mounted) return;
    _syncDisplayName();
  }

  /// Sets or corrects the standing reach — the one number every "inches to
  /// dunk" claim in the app is built on.
  Future<void> _editStandingReach(BuildContext context) async {
    final chosen = await showStandingReachDialog(
      context,
      heightInches: widget.profile.heightInches,
      currentReachInches: widget.profile.standingReachInches,
    );
    if (chosen == null) return;
    widget.onProfileChanged(
      widget.profile.copyWith(standingReachInches: chosen),
    );
  }

  Future<void> _confirmRestartOnboarding(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DunkColors.surface,
        title: const Text('Retake onboarding?', style: TextStyle(color: Colors.white)),
        content: const Text(
          "This clears your current profile and takes you back through the quiz from the start.",
          style: TextStyle(color: DunkColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: DunkColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Retake', style: TextStyle(color: DunkColors.primary)),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onRestartOnboarding();
  }
}

/// One row of the settings sheet: icon · label · optional current value.
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DunkColors.surfaceRaised,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: DunkColors.textSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: DunkColors.textTertiary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: DunkColors.textTertiary,
                size: 18,
              ),
            ],
          ),
        ),
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Container(
          decoration: BoxDecoration(
            color: DunkColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: DunkColors.stroke),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
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
    final color = active ? Colors.white : DunkColors.textTertiary;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? DunkColors.primary : Colors.transparent,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: active ? DunkColors.primary : DunkColors.textTertiary,
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

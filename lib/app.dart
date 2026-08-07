import 'package:flutter/material.dart';

import 'core/models/onboarding_profile.dart';
import 'features/analyze/analyze_flow.dart';
import 'features/home/root_shell.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/paywall/paywall_screen.dart';
import 'services/athlete_profile_store.dart';
import 'services/jump_log_store.dart';
import 'services/leaderboard_service.dart';
import 'services/onboarding_store.dart';
import 'services/workout_session_store.dart';
import 'theme/app_theme.dart';

/// Top-level phase machine: onboarding → free analysis → paywall → app
/// shell. On a returning launch (onboarding already complete) it jumps
/// straight to the shell. The paywall is a hard gate — the only way past it
/// is starting the free trial (see PaywallScreen); free analysis, right
/// before it, is the one thing an athlete can try before that gate.
enum _Phase { onboarding, freeAnalysis, paywall, app }

class DunkMaxApp extends StatefulWidget {
  final OnboardingStore store;
  final WorkoutSessionStore sessionStore;
  final JumpLogStore jumpLogStore;
  final AthleteProfileStore athleteProfileStore;
  final LeaderboardService leaderboardService;

  const DunkMaxApp({
    super.key,
    required this.store,
    required this.sessionStore,
    required this.jumpLogStore,
    required this.athleteProfileStore,
    required this.leaderboardService,
  });

  @override
  State<DunkMaxApp> createState() => _DunkMaxAppState();
}

class _DunkMaxAppState extends State<DunkMaxApp> {
  late _Phase _phase;
  OnboardingProfile? _profile;

  @override
  void initState() {
    super.initState();
    if (widget.store.hasCompletedOnboarding && widget.store.profile != null) {
      _profile = widget.store.profile;
      _phase = _Phase.app;
    } else {
      _phase = _Phase.onboarding;
    }
  }

  Future<void> _onOnboardingCompleted(OnboardingProfile profile) async {
    await widget.store.complete(profile);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _phase = _Phase.freeAnalysis;
    });
  }

  /// Persists an edit to a single onboarding answer (e.g. standing reach, set
  /// from the Settings sheet) and rebuilds everything reading the profile, so
  /// the dunk target on Home, Analyze and Progress can't disagree.
  Future<void> _onProfileChanged(OnboardingProfile profile) async {
    await widget.store.saveProfile(profile);
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  void _goToPaywall() => setState(() => _phase = _Phase.paywall);

  void _enterApp() => setState(() => _phase = _Phase.app);

  Future<void> _restartOnboarding() async {
    await widget.store.reset();
    if (!mounted) return;
    setState(() {
      _profile = null;
      _phase = _Phase.onboarding;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DunkMax',
      debugShowCheckedModeBanner: false,
      theme: DunkTheme.build(),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    switch (_phase) {
      case _Phase.onboarding:
        return OnboardingFlow(onCompleted: _onOnboardingCompleted);
      case _Phase.freeAnalysis:
        // AnalyzeFlow's screens (Source/Processing/JumpResult/MarkJump) have
        // no Scaffold of their own -- they're built to live inside
        // RootShell's Scaffold when used as the Analyze tab. Used here as a
        // standalone pre-paywall step, they need their own Material
        // ancestor or text rendering misbehaves (this was the intermittent
        // "yellow underline" report -- same screen, different context).
        return Scaffold(
          backgroundColor: DunkColors.background,
          body: AnalyzeFlow(
            profile: _profile!,
            jumpLogStore: widget.jumpLogStore,
            onSkip: _goToPaywall,
            onFirstResult: _goToPaywall,
          ),
        );
      case _Phase.paywall:
        return PaywallScreen(
          profile: _profile!,
          onContinue: _enterApp,
          onBack: () => setState(() => _phase = _Phase.freeAnalysis),
        );
      case _Phase.app:
        return RootShell(
          profile: _profile!,
          sessionStore: widget.sessionStore,
          jumpLogStore: widget.jumpLogStore,
          athleteProfileStore: widget.athleteProfileStore,
          leaderboardService: widget.leaderboardService,
          onRestartOnboarding: _restartOnboarding,
          onProfileChanged: _onProfileChanged,
        );
    }
  }
}

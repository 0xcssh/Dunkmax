import 'package:flutter/material.dart';

import 'core/models/onboarding_profile.dart';
import 'features/analyze/analyze_flow.dart';
import 'features/home/root_shell.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/paywall/paywall_screen.dart';
import 'features/shared/unit_scope.dart';
import 'l10n/app_localizations.dart';
import 'services/athlete_profile_store.dart';
import 'services/jump_log_store.dart';
import 'services/leaderboard_service.dart';
import 'services/onboarding_store.dart';
import 'services/subscription_service.dart';
import 'services/workout_session_store.dart';
import 'theme/app_theme.dart';

/// Top-level phase machine: onboarding → free analysis → paywall → app
/// shell. On a returning launch (onboarding already complete) it jumps
/// straight to the shell — but only for an athlete who is actually entitled.
/// The paywall is a hard gate, and the gate is the *entitlement*, not a tap:
/// a returning subscriber never sees it, and one whose subscription lapsed is
/// sent back to it mid-session. Free analysis, right before it, is the one
/// thing an athlete can try before that gate.
enum _Phase { onboarding, freeAnalysis, paywall, app }

class DunkMaxApp extends StatefulWidget {
  final OnboardingStore store;
  final WorkoutSessionStore sessionStore;
  final JumpLogStore jumpLogStore;
  final AthleteProfileStore athleteProfileStore;
  final LeaderboardService leaderboardService;
  final SubscriptionService subscriptionService;

  /// Metric or imperial, decided by the device's region (see
  /// [UnitScope.resolveFromPlatform]). Null resolves it at build time; tests
  /// pass one explicitly to force either system.
  final UnitSystem? unitSystem;

  const DunkMaxApp({
    super.key,
    required this.store,
    required this.sessionStore,
    required this.jumpLogStore,
    required this.athleteProfileStore,
    required this.leaderboardService,
    required this.subscriptionService,
    this.unitSystem,
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
      // Onboarding is done, so the only remaining question is entitlement.
      _phase = _hasAccess ? _Phase.app : _Phase.paywall;
    } else {
      _phase = _Phase.onboarding;
    }
    widget.subscriptionService.isSubscribed.addListener(_onEntitlementChanged);
  }

  @override
  void dispose() {
    widget.subscriptionService.isSubscribed
        .removeListener(_onEntitlementChanged);
    super.dispose();
  }

  /// True when the athlete holds the entitlement — or when this is an
  /// unconfigured non-release build, which is the deliberate dev/CI escape
  /// hatch. See [SubscriptionService.allowsUnconfiguredAccess]: a signed
  /// release with no API key fails closed rather than opening the app.
  bool get _hasAccess => widget.subscriptionService.hasAccess;

  /// RevenueCat can change entitlement state at any moment (a renewal, a
  /// refund, an expiry, a restore on another device). Access follows it both
  /// ways, so the paywall can't be walked past and a paying athlete can't be
  /// stranded behind it.
  void _onEntitlementChanged() {
    if (!mounted) return;
    final entitled = _hasAccess;
    if (entitled && _phase == _Phase.paywall) {
      setState(() => _phase = _Phase.app);
    } else if (!entitled && _phase == _Phase.app) {
      setState(() => _phase = _Phase.paywall);
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

  /// Leaves free analysis for the paywall — unless the athlete already holds
  /// the entitlement (a subscriber retaking onboarding, or one whose purchase
  /// was restored while they were still in the quiz), who must never be asked
  /// to buy again. Deliberately reads `isSubscribed`, not [_hasAccess]: an
  /// unconfigured dev build has access without a purchase and should still
  /// see the paywall it exists to exercise.
  void _goToPaywall() {
    final subscribed = widget.subscriptionService.isSubscribed.value;
    setState(() => _phase = subscribed ? _Phase.app : _Phase.paywall);
  }

  /// Called by the paywall once it believes the athlete is through. It is
  /// still the entitlement that decides — a tap alone never opens the gate.
  void _enterApp() {
    if (!_hasAccess) return;
    setState(() => _phase = _Phase.app);
  }

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
      // The wordmark, not a translated string — the app is called the same
      // thing in every locale.
      title: 'DunkMax',
      debugShowCheckedModeBanner: false,
      theme: DunkTheme.build(),
      // No `locale:` override — the device language decides, falling back to
      // English for anything we don't ship. Adding a locale later is a
      // data-only change: drop an `app_xx.arb` next to the two existing ones.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Above the Navigator, so dialogs and sheets see the same unit system
      // as the screens that open them.
      builder: (context, child) => UnitScope(
        system: widget.unitSystem ?? UnitScope.resolveFromPlatform(),
        child: child!,
      ),
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
          subscriptionService: widget.subscriptionService,
          onUnlocked: _enterApp,
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

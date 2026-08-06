import 'package:flutter/material.dart';

import '../../core/models/onboarding_profile.dart';
import '../../core/program_catalog.dart';
import '../../theme/app_theme.dart';

enum _Plan { yearly, weekly }

/// Presentation-only paywall. Real StoreKit/RevenueCat wiring is a follow-up
/// (see CLAUDE.md). Still a hard gate — "Start Free Trial" is the only way
/// into the app itself — but [onBack] lets the athlete step back to the
/// free-analysis screen (product decision: no dead end, but no way to reach
/// the app without starting the trial either). Pricing shown is a
/// placeholder mockup, not tied to real App Store Connect products yet.
///
/// Deliberately does NOT show a star-rating/review-count badge like the
/// reference app's — this is a brand-new, unpublished app with zero real
/// ratings, and shipping a fabricated "4.8 · 675+ ratings" would be exactly
/// the kind of fake social proof this app's own conventions refuse to show
/// elsewhere (the onboarding sell flow sells the measurement method for the
/// same reason — see features/onboarding/screens/how_it_works_screen.dart).
/// No badge is better than a fake one.
class PaywallScreen extends StatefulWidget {
  final OnboardingProfile profile;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const PaywallScreen({
    super.key,
    required this.profile,
    required this.onContinue,
    required this.onBack,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  _Plan _plan = _Plan.yearly;
  bool _showOtherPlans = false;

  static const _benefits = [
    ('Your Vert, Measured', 'Full jump breakdown — vert estimate, gap to your goal & coaching', Icons.monitor_heart_outlined),
    ('Week 1, Ready Now', 'Your personalized plan starts the moment you unlock', Icons.directions_run),
    ('Every Inch Tracked', 'Watch your progress toward your goal, week over week', Icons.show_chart),
  ];

  @override
  Widget build(BuildContext context) {
    final program = ProgramCatalog.recommend(widget.profile);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.2,
            colors: [Color(0xFF241109), DunkColors.background],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: widget.onBack,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.chevron_left,
                        color: Colors.white, size: 28),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      const _Wordmark(),
                      const SizedBox(height: 20),
                      const Text(
                        'GET YOUR\nFIRST DUNK.',
                        style: TextStyle(
                          fontSize: 32,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your ${program.sessionsPerWeek}-day plan is built. '
                        '3 days free. Cancel anytime.',
                        style: const TextStyle(
                          color: DunkColors.textSecondary,
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 24),
                      for (final (title, subtitle, icon) in _benefits) ...[
                        _BenefitRow(title: title, subtitle: subtitle, icon: icon),
                        const SizedBox(height: 16),
                      ],
                      const SizedBox(height: 8),
                      _PlanCard(
                        badge: 'BEST VALUE',
                        title: 'YEARLY',
                        priceLine: '\$1.15/week',
                        subLine: 'Billed \$59.99/year',
                        trialLine: '3-day free trial',
                        savePercent: 'Save 83%',
                        selected: _plan == _Plan.yearly,
                        onTap: () => setState(() => _plan = _Plan.yearly),
                      ),
                      if (!_showOtherPlans) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: () => setState(() => _showOtherPlans = true),
                            child: const Text(
                              'View other plans',
                              style: TextStyle(
                                color: DunkColors.textSecondary,
                                decoration: TextDecoration.underline,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (_showOtherPlans) ...[
                        const SizedBox(height: 12),
                        _PlanCard(
                          badge: null,
                          title: 'WEEKLY',
                          priceLine: '\$6.99/week',
                          subLine: null,
                          trialLine: '3-day free trial',
                          savePercent: null,
                          selected: _plan == _Plan.weekly,
                          onTap: () => setState(() => _plan = _Plan.weekly),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: widget.onContinue,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: DunkColors.primaryGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: DunkColors.primary.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'START FREE TRIAL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'No commitment required. Cancel anytime.',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _plan == _Plan.yearly
                      ? 'Free for 3 days, then \$59.99/year. Cancel anytime before '
                          'trial ends. Subscriptions auto-renew.'
                      : 'Free for 3 days, then \$6.99/week. Cancel anytime before '
                          'trial ends. Subscriptions auto-renew.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: DunkColors.textTertiary, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegalLink(label: 'Restore Purchases', onTap: () {}),
                    const _LegalDot(),
                    _LegalLink(label: 'Privacy', onTap: () {}),
                    const _LegalDot(),
                    _LegalLink(label: 'Terms', onTap: () {}),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'DUNK',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
          TextSpan(
            text: 'IT',
            style: TextStyle(
              color: DunkColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _BenefitRow({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: DunkColors.primary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: DunkColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: DunkColors.textSecondary,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String? badge;
  final String title;
  final String priceLine;
  final String? subLine;
  final String trialLine;
  final String? savePercent;
  final bool selected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.badge,
    required this.title,
    required this.priceLine,
    required this.subLine,
    required this.trialLine,
    required this.savePercent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DunkColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? DunkColors.primary : DunkColors.stroke,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (badge != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: DunkColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      title,
                      style: const TextStyle(
                        color: DunkColors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      priceLine,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subLine != null)
                      Text(
                        subLine!,
                        style: const TextStyle(color: DunkColors.textTertiary, fontSize: 12),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      trialLine,
                      style: const TextStyle(
                        color: DunkColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (savePercent != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: DunkColors.accentGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    savePercent!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? DunkColors.primary : Colors.transparent,
                    border: Border.all(
                      color: selected ? DunkColors.primary : DunkColors.stroke,
                      width: 1.6,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LegalLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: DunkColors.textTertiary,
          fontSize: 11,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

class _LegalDot extends StatelessWidget {
  const _LegalDot();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text('·', style: TextStyle(color: DunkColors.textTertiary, fontSize: 11)),
    );
  }
}

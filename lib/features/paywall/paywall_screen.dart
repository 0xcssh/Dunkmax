import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/legal_urls.dart';
import '../../core/models/onboarding_profile.dart';
import '../../core/program_catalog.dart';
import '../../core/subscription_offer.dart';
import '../../l10n/app_localizations.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_theme.dart';

/// The paywall. A hard gate — the app itself is only reachable by holding the
/// entitlement (see `app.dart`) — but [onBack] lets the athlete step back to
/// the free-analysis screen (product decision: no dead end, but no way to
/// reach the app without subscribing either).
///
/// **Every number on this screen comes from the store.** Prices, the billing
/// period, the trial length and the savings badge are derived from the
/// RevenueCat offering by `core/subscription_offer.dart`; each derivation
/// returns null rather than a guess, and the corresponding line simply
/// disappears. The screen used to print "\$1.15/week", "Billed \$59.99/year"
/// and "Save 83%" as literals — the last of those was invented outright.
///
/// With no `REVENUECAT_API_KEY` (CI, tests, the web preview, any plain
/// `flutter run`) there is no offering at all, and the screen says purchases
/// are unavailable rather than pretending to sell something.
///
/// Deliberately does NOT show a star-rating/review-count badge like the
/// reference app's — this is a brand-new, unpublished app with zero real
/// ratings, and shipping a fabricated "4.8 · 675+ ratings" would be exactly
/// the kind of fake social proof this app's own conventions refuse to show
/// elsewhere (the onboarding sell flow sells the measurement method for the
/// same reason — see features/onboarding/screens/how_it_works_screen.dart).
/// No badge is better than a fake one.
/// The palette has no error colour (nothing else in the app reports failure
/// in-line), so this one lives here rather than being invented into the theme.
const Color _errorColor = Color(0xFFE5484D);

class PaywallScreen extends StatefulWidget {
  final OnboardingProfile profile;
  final SubscriptionService subscriptionService;

  /// Called once the athlete is entitled (purchased or restored) — or, in an
  /// unconfigured debug build, once they tap through the dev continue.
  final VoidCallback onUnlocked;
  final VoidCallback onBack;

  const PaywallScreen({
    super.key,
    required this.profile,
    required this.subscriptionService,
    required this.onUnlocked,
    required this.onBack,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  SubscriptionOffer? _offer;
  String? _selectedPackageId;
  bool _loading = true;
  bool _busy = false;
  bool _showOtherPlans = false;
  String? _message;

  List<(String, String, IconData)> _benefits(AppLocalizations l10n) => [
        (
          l10n.paywallBenefit1Title,
          l10n.paywallBenefit1Body,
          Icons.monitor_heart_outlined
        ),
        (
          l10n.paywallBenefit2Title,
          l10n.paywallBenefit2Body,
          Icons.directions_run
        ),
        (l10n.paywallBenefit3Title, l10n.paywallBenefit3Body, Icons.show_chart),
      ];

  @override
  void initState() {
    super.initState();
    _loadOffer();
  }

  /// The "Try again" action: reset to the loading state, then re-fetch.
  void _retryLoad() {
    if (_loading) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    _loadOffer();
  }

  /// Fetches the offering. Called straight from [initState] (where the state
  /// is already `_loading`, so it must not call setState before its await).
  Future<void> _loadOffer() async {
    // Never throws and is bounded by its own timeout — see
    // SubscriptionService. Unconfigured builds get null immediately.
    final offer = await widget.subscriptionService.fetchOffer();
    if (!mounted) return;
    setState(() {
      _offer = offer;
      _loading = false;
      _selectedPackageId =
          (offer == null || offer.isEmpty) ? null : _defaultSelection(offer);
    });
  }

  String _defaultSelection(SubscriptionOffer offer) =>
      (offer.bestValue ?? offer.ordered.first).packageId;

  List<SubscriptionPlan> get _plans => _offer?.ordered ?? const [];

  SubscriptionPlan? get _selected {
    final id = _selectedPackageId;
    if (id == null) return null;
    for (final plan in _plans) {
      if (plan.packageId == id) return plan;
    }
    return null;
  }

  Future<void> _purchase() async {
    final plan = _selected;
    if (plan == null || _busy) return;
    // Resolved before the await so no lookup happens across the async gap.
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _message = null;
    });
    final outcome = await widget.subscriptionService.purchaseById(plan.packageId);
    if (!mounted) return;
    setState(() => _busy = false);

    if (outcome == PurchaseOutcome.success) {
      widget.onUnlocked();
    } else if (outcome == PurchaseOutcome.cancelled) {
      // The athlete backed out on purpose. Stay put, say nothing.
    } else if (outcome == PurchaseOutcome.notEntitled) {
      setState(() => _message = l10n.paywallErrorNotEntitled);
    } else if (outcome == PurchaseOutcome.unavailable) {
      setState(() => _message = l10n.paywallErrorUnavailable);
    } else {
      setState(() => _message = l10n.paywallErrorFailed);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _message = null;
    });
    final restored = await widget.subscriptionService.restore();
    if (!mounted) return;
    setState(() => _busy = false);
    if (restored) {
      widget.onUnlocked();
    } else {
      setState(() => _message = l10n.paywallErrorNothingToRestore);
    }
  }

  /// Opens a legal page in the browser.
  ///
  /// App Review taps these links and expects a working page, so this has to
  /// actually leave the app rather than display the address. An unpublished
  /// page is the one case where it must not: sending a reviewer to a dead URL
  /// is worse than telling them plainly that it is not up yet.
  Future<void> _openLegal({
    required String title,
    required String url,
    required bool published,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (published) {
      final uri = Uri.tryParse(url);
      final opened = uri != null &&
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened || !mounted) return;
      // Falling through means the device had nothing to open it with.
      setState(() => _message = l10n.paywallCouldNotOpenLegal(title, url));
      return;
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DunkColors.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(
          l10n.paywallPageNotPublished,
          style: const TextStyle(color: DunkColors.textTertiary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonClose,
                style: const TextStyle(color: DunkColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final program = ProgramCatalog.recommend(widget.profile);
    final offer = _offer;
    final plans = _plans;
    final selected = _selected;
    final service = widget.subscriptionService;

    final canPurchase = selected != null && !_busy;
    final canSkip = plans.isEmpty && service.allowsUnconfiguredAccess && !_busy;
    final ctaEnabled = canPurchase || canSkip;

    VoidCallback? ctaTap;
    if (canPurchase) {
      ctaTap = () {
        _purchase();
      };
    } else if (canSkip) {
      ctaTap = widget.onUnlocked;
    }

    // The trial length is whatever the store reported; only the sentence
    // around it is translated.
    final trial = selected?.freeTrial;
    final subheadline = trial == null
        ? l10n.paywallPlanBuilt(program.sessionsPerWeek)
        : l10n.paywallPlanBuiltWithTrial(
            program.sessionsPerWeek,
            _capitalize(trial.label),
          );

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
                    onPressed: _busy ? null : widget.onBack,
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
                      Text(
                        l10n.paywallHeadline,
                        style: const TextStyle(
                          fontSize: 32,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subheadline,
                        style: const TextStyle(
                          color: DunkColors.textSecondary,
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 24),
                      for (final (title, subtitle, icon) in _benefits(l10n)) ...[
                        _BenefitRow(title: title, subtitle: subtitle, icon: icon),
                        const SizedBox(height: 16),
                      ],
                      const SizedBox(height: 8),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: DunkColors.primary,
                              ),
                            ),
                          ),
                        )
                      else if (plans.isEmpty)
                        _UnavailableCard(
                          configured: service.isConfigured,
                          onRetry: service.isConfigured ? _retryLoad : null,
                        )
                      else
                        ..._buildPlanCards(l10n, offer!, plans),
                    ],
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _errorColor,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                _Cta(
                  enabled: ctaEnabled,
                  busy: _busy,
                  label: _ctaLabel(l10n, selected, canSkip),
                  subLabel: _ctaSubLabel(l10n, selected, canSkip),
                  onTap: ctaTap,
                ),
                const SizedBox(height: 12),
                Text(
                  _disclosure(l10n, selected, canSkip, service.isConfigured),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: DunkColors.textTertiary, fontSize: 11, height: 1.3),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegalLink(
                      label: l10n.paywallRestorePurchases,
                      onTap: _busy ? null : _restore,
                    ),
                    const _LegalDot(),
                    _LegalLink(
                      label: l10n.paywallPrivacy,
                      onTap: () => _openLegal(
                        title: l10n.paywallPrivacyPolicyTitle,
                        url: LegalUrls.privacyPolicy,
                        published: LegalUrls.privacyPolicyPublished,
                      ),
                    ),
                    const _LegalDot(),
                    _LegalLink(
                      label: l10n.paywallTerms,
                      onTap: () => _openLegal(
                        title: l10n.paywallTermsOfUseTitle,
                        url: LegalUrls.termsOfUse,
                        published: LegalUrls.termsOfUsePublished,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPlanCards(
    AppLocalizations l10n,
    SubscriptionOffer offer,
    List<SubscriptionPlan> plans,
  ) {
    final bestValueId = offer.bestValue?.packageId;
    final headline = plans.first;
    final rest = plans.skip(1).toList();

    Widget card(SubscriptionPlan plan) {
      final savings = offer.savingsPercentFor(plan);
      return _PlanCard(
        badge: plan.packageId == bestValueId ? l10n.paywallBestValue : null,
        // The plan title and every price line are built by
        // core/subscription_offer.dart from the store's own strings, and are
        // not translated here — see CLAUDE.md.
        title: plan.title,
        priceLine: plan.headlineLine,
        subLine: plan.billedLine,
        trialLine: plan.trialLine,
        savePercent:
            savings == null ? null : l10n.paywallSavePercent(savings),
        selected: plan.packageId == _selectedPackageId,
        onTap: _busy
            ? null
            : () => setState(() => _selectedPackageId = plan.packageId),
      );
    }

    return [
      card(headline),
      if (rest.isNotEmpty && !_showOtherPlans) ...[
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _showOtherPlans = true),
            child: Text(
              l10n.paywallViewOtherPlans,
              style: const TextStyle(
                color: DunkColors.textSecondary,
                decoration: TextDecoration.underline,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      if (_showOtherPlans)
        for (final plan in rest) ...[
          const SizedBox(height: 12),
          card(plan),
        ],
    ];
  }

  String _ctaLabel(
      AppLocalizations l10n, SubscriptionPlan? selected, bool canSkip) {
    // `selected.ctaLabel` comes from core/subscription_offer.dart and is not
    // translated yet.
    if (selected != null) return selected.ctaLabel;
    if (canSkip) return l10n.paywallCtaContinueWithoutPurchase;
    return l10n.paywallCtaUnavailable;
  }

  String _ctaSubLabel(
      AppLocalizations l10n, SubscriptionPlan? selected, bool canSkip) {
    if (selected != null) {
      return selected.freeTrial == null
          ? l10n.paywallCancelAnytime
          : l10n.paywallNoCommitment;
    }
    if (canSkip) {
      return SubscriptionService.previewUnlock
          ? l10n.paywallPreviewBuildNote
          : l10n.paywallDebugBuildNote;
    }
    return l10n.paywallNoPurchasesInBuild;
  }

  String _disclosure(
    AppLocalizations l10n,
    SubscriptionPlan? selected,
    bool canSkip,
    bool configured,
  ) {
    // The Apple-required disclosure: what is bought, at what price, over what
    // period, and that it auto-renews — all read off the fetched product, and
    // assembled (untranslated for now) in core/subscription_offer.dart.
    if (selected != null) return selected.renewalDisclosure;
    if (canSkip) return l10n.paywallDisclosureNoConfig;
    return configured
        ? l10n.paywallDisclosureLoadFailed
        : l10n.paywallDisclosureUnavailable;
  }

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}

class _Cta extends StatelessWidget {
  final bool enabled;
  final bool busy;
  final String label;
  final String subLabel;
  final VoidCallback? onTap;

  const _Cta({
    required this.enabled,
    required this.busy,
    required this.label,
    required this.subLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled ? onTap : null,
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
            child: busy
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        subLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Shown instead of plan cards when there is nothing real to sell: either the
/// build has no RevenueCat key at all, or the offering could not be fetched.
/// Placeholder prices are never shown in their place.
class _UnavailableCard extends StatelessWidget {
  final bool configured;
  final VoidCallback? onRetry;

  const _UnavailableCard({required this.configured, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline,
                  color: DunkColors.textTertiary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  configured
                      ? l10n.paywallPlansUnavailableTitle
                      : l10n.paywallPurchasesUnavailableTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            configured
                ? l10n.paywallPlansUnavailableBody
                : l10n.paywallPurchasesUnavailableBody,
            style: const TextStyle(
              color: DunkColors.textSecondary,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(l10n.paywallTryAgain,
                    style: const TextStyle(
                        color: DunkColors.primary, fontSize: 13)),
              ),
            ),
          ],
        ],
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
  final String? trialLine;
  final String? savePercent;
  final bool selected;
  final VoidCallback? onTap;

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
                    if (trialLine != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        trialLine!,
                        style: const TextStyle(
                          color: DunkColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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
  final VoidCallback? onTap;

  const _LegalLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: onTap == null
              ? DunkColors.textTertiary.withValues(alpha: 0.5)
              : DunkColors.textTertiary,
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

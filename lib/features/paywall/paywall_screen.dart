import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/legal_urls.dart';
import '../../core/models/onboarding_profile.dart';
import '../../core/subscription_offer.dart';
import '../../core/vert_assessment.dart';
import '../../l10n/app_localizations.dart';
import '../../services/analytics.dart';
import '../../services/subscription_service.dart';
import '../../theme/app_theme.dart';
import '../shared/layout_density.dart';
import '../shared/unit_scope.dart';
import '../shared/widgets/fit_or_scroll.dart';

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
/// elsewhere (the onboarding sell flow carries no ratings or testimonials
/// either).
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
    Analytics.track(
        AnalyticsEvent.paywallShown, {'plans': offer?.ordered.length ?? 0});
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
    Analytics.track(AnalyticsEvent.purchaseStarted, {'plan': plan.packageId});
    final outcome = await widget.subscriptionService.purchaseById(plan.packageId);
    Analytics.track(AnalyticsEvent.purchaseResult,
        {'plan': plan.packageId, 'result': outcome.name});
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
    Analytics.track(AnalyticsEvent.restoreResult,
        {'result': restored ? 'restored' : 'nothing'});
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

    final density = LayoutDensity.of(context);
    final heroHeight = MediaQuery.sizeOf(context).height * 0.42;
    return Scaffold(
      body: Stack(
        children: [
          // The dunker from the app icon, faded into the page: the brand's
          // own art where the reference app puts a stock photo.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.transparent],
                stops: [0.45, 1],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: Opacity(
                opacity: 0.42,
                child: Image.asset(
                  'assets/paywall/dunker.png',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.4),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, density.pick(10, 6)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      onPressed: _busy ? null : widget.onBack,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      icon: const Icon(Icons.chevron_left,
                          color: Colors.white, size: 28),
                    ),
                  ),
                  Expanded(
                    child: FitOrScrollColumn(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: density.pick(14, 4)),
                        const _Wordmark(),
                        SizedBox(height: density.pick(6, 4)),
                        Text(
                          l10n.paywallTagline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: DunkColors.textSecondary,
                            fontSize: density.pick(17, 15),
                          ),
                        ),
                        SizedBox(height: density.pick(16, 10)),
                        Center(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final line in [
                                l10n.paywallCheck1,
                                l10n.paywallCheck2,
                                l10n.paywallCheck3,
                              ]) ...[
                                _CheckRow(text: line),
                                SizedBox(height: density.pick(9, 6)),
                              ],
                            ],
                          ),
                        ),
                        // Gives its room to the plans once all of them are
                        // open, so both cards fit without a scroll.
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          alignment: Alignment.topCenter,
                          child: _showOtherPlans
                              ? const SizedBox(width: double.infinity)
                              : Padding(
                                  padding: EdgeInsets.only(
                                    top: density.pick(4, 2),
                                    bottom: density.pick(16, 10),
                                  ),
                                  child: _GapStat(profile: widget.profile),
                                ),
                        ),
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
                    subLabel: canSkip ? _skipNote(l10n) : null,
                    onTap: ctaTap,
                  ),
                  SizedBox(height: density.pick(10, 8)),
                  Text(
                    _disclosure(l10n, selected, canSkip, service.isConfigured),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: DunkColors.textTertiary,
                        fontSize: 12,
                        height: 1.3),
                  ),
                  SizedBox(height: density.pick(8, 6)),
                  // Scaled down as one unit only when the links are wider than
                  // the screen (longer French labels on a narrow phone).
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.paywallAlreadyPurchased,
                          style: const TextStyle(
                              color: DunkColors.textTertiary, fontSize: 12),
                        ),
                        const SizedBox(width: 4),
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The trial in whole days, when the store reports it in days or weeks
  /// (the configured 3-day trial). Anything else falls back to core's label.
  static int? _trialDays(SubscriptionPlan plan) {
    final trial = plan.freeTrial;
    if (trial == null) return null;
    if (trial.unit == BillingUnit.day) return trial.count;
    if (trial.unit == BillingUnit.week) return trial.count * 7;
    return null;
  }

  /// The ICU select key for a one-unit billing period ("year", "week"…).
  static String _periodKey(SubscriptionPlan plan) {
    final p = plan.period;
    return p != null && p.count == 1 ? p.unit.name : 'other';
  }

  List<Widget> _buildPlanCards(
    AppLocalizations l10n,
    SubscriptionOffer offer,
    List<SubscriptionPlan> plans,
  ) {
    final bestValueId = offer.bestValue?.packageId;
    // The best-value plan leads, as on the reference paywall: one card and a
    // "see all plans" link; the others unfold under it.
    final headline = plans.firstWhere((p) => p.packageId == bestValueId,
        orElse: () => plans.first);
    final rest = plans.where((p) => p != headline).toList();

    Widget card(SubscriptionPlan plan) {
      final period = _periodKey(plan);
      final days = _trialDays(plan);
      final weekly = plan.weeklyPriceString;
      return _PlanCard(
        badge: plan.packageId == bestValueId && plans.length > 1
            ? l10n.paywallBestValue
            : null,
        title: l10n.paywallPlanName(period),
        trialLine: days != null ? l10n.paywallTrialDays(days) : plan.trialLine,
        detailLine: plan.freeTrial != null
            ? l10n.paywallThenPrice(plan.priceString, period)
            : l10n.paywallBilledEvery(period),
        price: weekly == null ? plan.priceString : l10n.paywallPerWeek(weekly),
        selected: plan.packageId == _selectedPackageId,
        onTap: _busy
            ? null
            : () => setState(() => _selectedPackageId = plan.packageId),
      );
    }

    return [
      card(headline),
      if (rest.isNotEmpty && !_showOtherPlans)
        Center(
          child: TextButton(
            onPressed: () => setState(() => _showOtherPlans = true),
            child: Text(
              l10n.paywallViewOtherPlans,
              style: const TextStyle(
                color: DunkColors.textSecondary,
                decoration: TextDecoration.underline,
                decorationColor: DunkColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ),
        ),
      if (_showOtherPlans)
        for (final plan in rest) ...[
          const SizedBox(height: 12),
          card(plan),
        ],
    ];
  }

  String _ctaLabel(
      AppLocalizations l10n, SubscriptionPlan? selected, bool canSkip) {
    if (selected != null) {
      return selected.freeTrial == null
          ? l10n.paywallCtaSubscribe
          : l10n.paywallCtaTryFree;
    }
    if (canSkip) return l10n.paywallCtaContinueWithoutPurchase;
    return l10n.paywallCtaUnavailable;
  }

  String _skipNote(AppLocalizations l10n) => SubscriptionService.previewUnlock
      ? l10n.paywallPreviewBuildNote
      : l10n.paywallDebugBuildNote;

  String _disclosure(
    AppLocalizations l10n,
    SubscriptionPlan? selected,
    bool canSkip,
    bool configured,
  ) {
    // The Apple-required disclosure: price, period, auto-renewal — all read
    // off the fetched product.
    if (selected != null) {
      if (selected.period == null) return selected.renewalDisclosure;
      final period = _periodKey(selected);
      final days = _trialDays(selected);
      if (days != null) {
        return l10n.paywallFooterTrial(days, selected.priceString, period);
      }
      if (selected.freeTrial != null) return selected.renewalDisclosure;
      return l10n.paywallFooterNoTrial(selected.priceString, period);
    }
    if (canSkip) return l10n.paywallDisclosureNoConfig;
    return configured
        ? l10n.paywallDisclosureLoadFailed
        : l10n.paywallDisclosureUnavailable;
  }
}

class _Cta extends StatelessWidget {
  final bool enabled;
  final bool busy;
  final String label;
  final String? subLabel;
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
                      if (subLabel != null)
                        Text(
                          subLabel!,
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
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 46,
          letterSpacing: -1,
          height: 1,
        ),
        children: [
          TextSpan(text: 'DUNK', style: TextStyle(color: Colors.white)),
          TextSpan(text: 'IT', style: TextStyle(color: DunkColors.primary)),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String text;

  const _CheckRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: DunkColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 17),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Where the reference app shows "4.8 ★ · 37,000+ dunkers", a number that is
/// true about this athlete: their own estimated gap to a dunk, from the same
/// VertAssessment the onboarding gap screen uses. Hidden when there is no gap
/// to show — no made-up figure ever takes its place.
class _GapStat extends StatelessWidget {
  final OnboardingProfile profile;

  const _GapStat({required this.profile});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final units = UnitScope.of(context);
    final gap = VertAssessment(
      heightInches: profile.heightInches,
      ageYears: profile.ageYears,
      hops: profile.hopsLevel,
      measuredStandingReach: profile.standingReachInches,
      dunkHand: profile.dunkHand,
    ).gapInches;
    if (gap <= 0) return const SizedBox.shrink();
    return Column(
      children: [
        Text(
          l10n.length(units.name, units.lengthValue(gap)),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 44,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.paywallGapLabel,
          style: const TextStyle(
            color: DunkColors.primary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.paywallGapNote,
          style: const TextStyle(color: DunkColors.textTertiary, fontSize: 12),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String? badge;
  final String title;
  final String? trialLine;
  final String detailLine;
  final String price;
  final bool selected;
  final VoidCallback? onTap;

  const _PlanCard({
    required this.badge,
    required this.title,
    required this.trialLine,
    required this.detailLine,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: DunkColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? DunkColors.primary : DunkColors.stroke,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (trialLine != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        trialLine!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      detailLine,
                      style: const TextStyle(
                          color: DunkColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                price,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (badge == null) return card;
    // The tab sits on the card's top edge, as on the reference paywall. Its
    // word is BEST VALUE — derived from the prices — never "most popular",
    // which would be a claim about other customers this app cannot make.
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: const BoxDecoration(
            color: DunkColors.primary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Text(
            badge!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        card,
      ],
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

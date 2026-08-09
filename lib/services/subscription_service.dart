import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/subscription_offer.dart';

/// In-app purchases via RevenueCat.
///
/// Same two rules as `leaderboard_service.dart`, for the same reasons:
///
/// 1. **No API key, no problem.** The key comes from `--dart-define` at build
///    time. CI, `flutter test`, the web preview and every plain
///    `flutter run` have none, so [isConfigured] is false, StoreKit is never
///    touched, `Purchases.configure` is never called, and nothing here can
///    hang startup or throw. The athlete is simply treated as unsubscribed
///    and the paywall says purchases are unavailable rather than pretending
///    to sell something.
/// 2. **Nothing throws at the UI.** Every call is wrapped and timed out;
///    failure degrades to "unavailable"/"not entitled", never an exception.
///
/// A cancelled purchase is a normal outcome ([PurchaseOutcome.cancelled]),
/// not a failure — the athlete chose it, so the paywall stays quiet.
class SubscriptionService {
  /// Build-time RevenueCat public SDK key. **Never commit one**; it is passed
  /// as `--dart-define=REVENUECAT_API_KEY=...` from a repo secret (see
  /// `docs/revenuecat-setup.md`). iOS keys start with `appl_`.
  static const String apiKey = String.fromEnvironment('REVENUECAT_API_KEY');

  /// The single entitlement that unlocks the app.
  ///
  /// **This exact string must exist as an entitlement in the RevenueCat
  /// dashboard, with both subscription products attached to it.** If the
  /// dashboard uses a different identifier, a real purchase will succeed and
  /// still leave the athlete locked out — see [PurchaseOutcome.notEntitled].
  static const String entitlementId = 'pro';

  static const Duration _initTimeout = Duration(seconds: 10);
  static const Duration _storeTimeout = Duration(seconds: 20);

  /// Deliberately long: the store sheet is a *user* interaction — Face ID, an
  /// Apple ID password, a bank's SCA prompt — and can legitimately sit open
  /// for minutes. Timing it out at the usual few seconds would abort real
  /// purchases. This bound exists only so a wedged native call can't hang the
  /// button forever.
  static const Duration _purchaseTimeout = Duration(minutes: 5);

  bool _initialized = false;
  bool _initFailed = false;

  /// Packages from the current offering, by identifier, so the UI can work in
  /// pure [SubscriptionPlan] terms and never hold a plugin object.
  final Map<String, Package> _packages = <String, Package>{};

  /// Whether the athlete currently holds [entitlementId]. Observable so the
  /// phase machine in `app.dart` can gate on entitlement rather than on a tap
  /// — including when RevenueCat pushes an update mid-session (a renewal, a
  /// refund, an expiry).
  final ValueNotifier<bool> isSubscribed = ValueNotifier<bool>(false);

  /// Whether this build was given an API key.
  bool get isConfigured => apiKey.isNotEmpty;

  /// Whether purchases are actually usable right now.
  bool get isAvailable => isConfigured && _initialized && !_initFailed;

  /// The dev/CI escape hatch, and the only one.
  ///
  /// With no API key nobody can ever be entitled, so gating strictly on
  /// entitlement would lock every developer, test and web-preview build out
  /// of the app entirely. Access is therefore granted when purchases are
  /// *unconfigured* **and** this is not a release build.
  ///
  /// The `!kReleaseMode` half is what stops this shipping as a bypass: a
  /// signed release build with no key does **not** get in — it fails closed,
  /// showing an unavailable paywall with no way past. That is loud and
  /// obviously broken, which is exactly what a release built without its
  /// secret should be.
  /// A release build may additionally opt in with
  /// `--dart-define=PREVIEW_UNLOCK=true`. This exists for one reason: a
  /// TestFlight build made before the RevenueCat key exists would otherwise
  /// be a signed release with no key — locked out of its own app, which is
  /// useless for testing everything that is not the paywall.
  ///
  /// It is deliberately self-cancelling. It only applies while purchases are
  /// unconfigured, so the moment the real key is passed the flag goes inert
  /// on its own and cannot be left on by accident. The paywall says plainly
  /// when a build is running on it, and `docs/revenuecat-setup.md` lists
  /// removing it from the workflow as a submission step.
  static const bool previewUnlock =
      bool.fromEnvironment('PREVIEW_UNLOCK');

  bool get allowsUnconfiguredAccess =>
      !isConfigured && (!kReleaseMode || previewUnlock);

  /// The single question `app.dart` asks: may this athlete use the app?
  bool get hasAccess => isSubscribed.value || allowsUnconfiguredAccess;

  /// Boots RevenueCat. A no-op when unconfigured, and bounded by a timeout so
  /// a dead network can never hold up app startup.
  Future<void> initialize() async {
    if (!isConfigured || _initialized || _initFailed) return;
    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);
      await Purchases.configure(PurchasesConfiguration(apiKey))
          .timeout(_initTimeout);
      _initialized = true;
    } catch (_) {
      _initFailed = true;
      return;
    }

    // Configured. Entitlement state is a separate, non-fatal concern: if it
    // can't be read now the athlete is treated as unsubscribed and the
    // listener (or Restore Purchases) will correct it.
    try {
      Purchases.addCustomerInfoUpdateListener(_applyCustomerInfo);
      final info = await Purchases.getCustomerInfo().timeout(_storeTimeout);
      _applyCustomerInfo(info);
    } catch (_) {
      // Swallowed on purpose.
    }
  }

  /// Re-reads entitlement state from RevenueCat (cached, cheap). Used on
  /// resume-ish moments; safe to call when unconfigured.
  Future<void> refreshEntitlement() async {
    if (!isAvailable) return;
    try {
      final info = await Purchases.getCustomerInfo().timeout(_storeTimeout);
      _applyCustomerInfo(info);
    } catch (_) {
      // Leave the last known state alone rather than guessing.
    }
  }

  /// The current offering's plans, with the store's own localised prices.
  ///
  /// Returns null when purchases are unavailable, when the offering is empty,
  /// or when the fetch failed — the paywall then shows an honest unavailable
  /// state instead of placeholder pricing.
  Future<SubscriptionOffer?> fetchOffer() async {
    if (!isAvailable) return null;
    try {
      final offerings = await Purchases.getOfferings().timeout(_storeTimeout);
      final current = offerings.current;
      if (current == null || current.availablePackages.isEmpty) return null;

      _packages
        ..clear()
        ..addEntries(
          current.availablePackages.map((p) => MapEntry(p.identifier, p)),
        );

      final plans = current.availablePackages.map(_toPlan).toList();
      return SubscriptionOffer(plans);
    } catch (_) {
      return null;
    }
  }

  /// The plugin object behind a [SubscriptionPlan.packageId], if still known.
  Package? packageFor(String packageId) => _packages[packageId];

  /// Convenience for the UI, which only ever holds pure core types.
  Future<PurchaseOutcome> purchaseById(String packageId) async {
    final package = _packages[packageId];
    if (package == null) return PurchaseOutcome.unavailable;
    return purchase(package);
  }

  /// Buys [package] and reports how it ended.
  Future<PurchaseOutcome> purchase(Package package) async {
    if (!isAvailable) return PurchaseOutcome.unavailable;
    try {
      final info =
          await Purchases.purchasePackage(package).timeout(_purchaseTimeout);
      _applyCustomerInfo(info);
      return _isEntitled(info)
          ? PurchaseOutcome.success
          : PurchaseOutcome.notEntitled;
    } on PlatformException catch (e) {
      // Backing out of the store sheet is an ordinary outcome, not an error.
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseOutcome.cancelled;
      }
      return PurchaseOutcome.failed;
    } catch (_) {
      return PurchaseOutcome.failed;
    }
  }

  /// Restores a subscription bought on another device or after a reinstall.
  /// Returns whether the athlete holds [entitlementId] afterwards.
  Future<bool> restore() async {
    if (!isAvailable) return false;
    try {
      final info = await Purchases.restorePurchases().timeout(_storeTimeout);
      _applyCustomerInfo(info);
      return _isEntitled(info);
    } catch (_) {
      return false;
    }
  }

  void dispose() => isSubscribed.dispose();

  // ---------------------------------------------------------------- mapping

  void _applyCustomerInfo(CustomerInfo info) {
    final entitled = _isEntitled(info);
    if (isSubscribed.value != entitled) isSubscribed.value = entitled;
  }

  bool _isEntitled(CustomerInfo info) =>
      info.entitlements.active.containsKey(entitlementId);

  SubscriptionPlan _toPlan(Package package) {
    final product = package.storeProduct;
    return SubscriptionPlan(
      packageId: package.identifier,
      priceString: product.priceString,
      price: product.price,
      currencyCode: product.currencyCode,
      period: BillingPeriod.parseIso8601(product.subscriptionPeriod),
      freeTrial: _freeTrialOf(product),
    );
  }

  /// The product's introductory period, but only when it is actually free.
  /// A discounted-but-paid intro offer is not a trial and must never be
  /// labelled as one.
  BillingPeriod? _freeTrialOf(StoreProduct product) {
    final intro = product.introductoryPrice;
    if (intro == null || intro.price > 0) return null;
    final parsed = BillingPeriod.parseIso8601(intro.period);
    if (parsed != null) return parsed;
    // Fallback: the same duration in already-split form.
    final count = intro.periodNumberOfUnits;
    if (count <= 0) return null;
    switch (intro.periodUnit) {
      case PeriodUnit.day:
        return BillingPeriod(BillingUnit.day, count);
      case PeriodUnit.week:
        return BillingPeriod(BillingUnit.week, count);
      case PeriodUnit.month:
        return BillingPeriod(BillingUnit.month, count);
      case PeriodUnit.year:
        return BillingPeriod(BillingUnit.year, count);
      case PeriodUnit.unknown:
        return null;
    }
  }
}

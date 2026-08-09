import 'dart:math' as math;

/// Pure model of what the store is actually selling.
///
/// The paywall used to hardcode "\$1.15/week", "Billed \$59.99/year" and
/// "Save 83%". Two of those were formatting, one was invented. Everything in
/// this file is *derived* from the real, localised numbers RevenueCat hands
/// back from the App Store — and every derivation returns null rather than a
/// guess when the product doesn't carry enough information to make the claim.
///
/// No Flutter, no plugin types: `services/subscription_service.dart` maps
/// RevenueCat's `Package`/`StoreProduct` onto these, so the maths and the copy
/// stay unit-testable without a store, a device or a network.

/// The unit of a billing or trial period.
enum BillingUnit { day, week, month, year }

/// A billing period such as "1 year" or "3 days".
class BillingPeriod {
  final BillingUnit unit;
  final int count;

  const BillingPeriod(this.unit, this.count);

  // Average lengths, so a yearly plan's per-week price is right rather than
  // tidy: 365.25 days keeps leap years from biasing the comparison.
  static const double _weeksPerMonth = 365.25 / 12 / 7;
  static const double _weeksPerYear = 365.25 / 7;

  /// How many weeks this period covers. Used to put plans of different
  /// lengths on one comparable axis.
  double get weeks {
    switch (unit) {
      case BillingUnit.day:
        return count / 7;
      case BillingUnit.week:
        return count.toDouble();
      case BillingUnit.month:
        return count * _weeksPerMonth;
      case BillingUnit.year:
        return count * _weeksPerYear;
    }
  }

  String get _unitName => unit.name;

  /// "year", "3 months" — reads naturally after "per" or "then".
  String get label => count == 1 ? _unitName : '$count ${_unitName}s';

  /// "3-day", "1-week" — reads naturally before "free trial".
  String get hyphenatedLabel => '$count-$_unitName';

  /// Parses the ISO-8601 duration StoreKit/RevenueCat report
  /// (`StoreProduct.subscriptionPeriod`, `IntroductoryPrice.period`):
  /// "P1W", "P3D", "P6M", "P1Y". Anything else — a compound duration, an
  /// empty string, null — returns null, and the caller drops the claim.
  static BillingPeriod? parseIso8601(String? raw) {
    if (raw == null) return null;
    final match =
        RegExp(r'^P(\d+)([DWMY])$', caseSensitive: false).firstMatch(raw.trim());
    if (match == null) return null;
    final count = int.tryParse(match.group(1)!);
    if (count == null || count <= 0) return null;
    switch (match.group(2)!.toUpperCase()) {
      case 'D':
        return BillingPeriod(BillingUnit.day, count);
      case 'W':
        return BillingPeriod(BillingUnit.week, count);
      case 'M':
        return BillingPeriod(BillingUnit.month, count);
      case 'Y':
        return BillingPeriod(BillingUnit.year, count);
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is BillingPeriod && other.unit == unit && other.count == count;

  @override
  int get hashCode => Object.hash(unit, count);

  @override
  String toString() => 'BillingPeriod($label)';
}

/// Rewrites the amount inside a store-formatted price string, keeping the
/// store's own currency symbol, its placement and its separators.
///
/// Why not format the currency ourselves: we'd have to guess whether the
/// symbol leads or trails, whether the decimal separator is `.` or `,`, and
/// whether the currency even has minor units — per locale, per store front.
/// The store already answered all of that in [priceString]; the only thing we
/// change is the digits.
///
/// `formatLikePrice('\$59.99', 59.99, 1.1497)` → `'\$1.15'`
/// `formatLikePrice('59,99 €', 59.99, 1.1497)` → `'1,15 €'`
///
/// Returns null when the numeric run can't be located, or when its digits
/// can't be reconciled with [referenceAmount] (so we never edit a string we
/// misread).
String? formatLikePrice(
  String priceString,
  double referenceAmount,
  double newAmount,
) {
  if (referenceAmount <= 0 || newAmount < 0 || !newAmount.isFinite) return null;

  // Separators seen in store price strings: '.', ',', NBSP, narrow NBSP and
  // (de-CH) the apostrophe.
  const separators = ".,\u00A0\u202F'";
  final match = RegExp('[0-9][0-9$separators]*[0-9]|[0-9]').firstMatch(priceString);
  if (match == null) return null;
  final raw = match.group(0)!;

  final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitsOnly.isEmpty || digitsOnly.length > 15) return null;
  final digits = int.tryParse(digitsOnly);
  if (digits == null) return null;

  // How many of those digits are minor units? The reference amount — which
  // the store gave us as a plain double alongside the string — decides,
  // instead of us guessing whether a ',' is a decimal or a group separator.
  int? decimals;
  for (var candidate = 0; candidate <= 3; candidate++) {
    final scale = math.pow(10, candidate).toDouble();
    if ((digits / scale - referenceAmount).abs() <= 0.5 / scale) {
      decimals = candidate;
      break;
    }
  }
  if (decimals == null) return null;
  if (decimals > 0 && raw.length < decimals + 1) return null;

  final decimalSeparator =
      decimals > 0 ? raw[raw.length - decimals - 1] : null;
  if (decimalSeparator != null && !separators.contains(decimalSeparator)) {
    return null;
  }
  String? groupSeparator;
  for (final ch in raw.split('')) {
    if (separators.contains(ch) && ch != decimalSeparator) {
      groupSeparator = ch;
      break;
    }
  }

  final factor = math.pow(10, decimals).toInt();
  final scaled = (newAmount * factor).round();
  var integerPart = (scaled ~/ factor).toString();
  if (groupSeparator != null && integerPart.length > 3) {
    final buffer = StringBuffer();
    for (var i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) buffer.write(groupSeparator);
      buffer.write(integerPart[i]);
    }
    integerPart = buffer.toString();
  }
  final rendered = decimals == 0
      ? integerPart
      : '$integerPart$decimalSeparator'
          '${(scaled % factor).toString().padLeft(decimals, '0')}';

  return priceString.replaceRange(match.start, match.end, rendered);
}

/// One purchasable plan, as the paywall needs to render it.
class SubscriptionPlan {
  /// RevenueCat package identifier — the handle the service purchases by, so
  /// the UI never has to hold a plugin object.
  final String packageId;

  /// The store's own localised price, e.g. "\$59.99" or "59,99 €".
  final String priceString;

  /// The same amount as a number, in [currencyCode].
  final double price;

  final String currencyCode;

  /// How long one billing cycle lasts. Null when the store didn't report a
  /// subscription period (a non-subscription product, or a field we couldn't
  /// parse) — every period-derived line below then disappears.
  final BillingPeriod? period;

  /// The introductory *free* period, when the product has one. A paid
  /// introductory offer is deliberately not represented as a trial.
  final BillingPeriod? freeTrial;

  const SubscriptionPlan({
    required this.packageId,
    required this.priceString,
    required this.price,
    required this.currencyCode,
    this.period,
    this.freeTrial,
  });

  /// "YEARLY", "WEEKLY", "3 MONTHS" — the plan's own name, upper-cased for
  /// the card. Falls back to the package identifier when the period is
  /// unknown, so the card is never blank.
  String get title {
    final p = period;
    if (p == null) return packageId.toUpperCase();
    if (p.count != 1) return p.label.toUpperCase();
    switch (p.unit) {
      case BillingUnit.day:
        return 'DAILY';
      case BillingUnit.week:
        return 'WEEKLY';
      case BillingUnit.month:
        return 'MONTHLY';
      case BillingUnit.year:
        return 'YEARLY';
    }
  }

  /// This plan's price normalised to one week, as a number.
  double? get weeklyPrice {
    final p = period;
    if (p == null) return null;
    final weeks = p.weeks;
    if (weeks <= 0) return null;
    return price / weeks;
  }

  /// The same, in the store's currency format. Null when it can't be derived.
  String? get weeklyPriceString {
    final p = period;
    final perWeek = weeklyPrice;
    if (p == null || perWeek == null) return null;
    if ((p.weeks - 1).abs() < 0.001) return priceString;
    return formatLikePrice(priceString, price, perWeek);
  }

  /// The headline on the plan card: "\$1.15/week", or just the raw price when
  /// there's no period to normalise by.
  String get headlineLine {
    final weekly = weeklyPriceString;
    return weekly == null ? priceString : '$weekly/week';
  }

  /// "Billed \$59.99/year". Null for a plan that's already billed weekly (the
  /// headline already says it) or whose period is unknown.
  String? get billedLine {
    final p = period;
    if (p == null) return null;
    if ((p.weeks - 1).abs() < 0.001) return null;
    return 'Billed $priceString/${p.label}';
  }

  /// "3-day free trial". Null when the product carries no free trial — the
  /// card then shows nothing rather than promising one.
  String? get trialLine {
    final trial = freeTrial;
    return trial == null ? null : '${trial.hyphenatedLabel} free trial';
  }

  /// The CTA. Only promises a trial when the product actually has one.
  String get ctaLabel => freeTrial == null ? 'SUBSCRIBE' : 'START FREE TRIAL';

  /// The disclosure Apple requires next to the purchase button: what is
  /// bought, at what price, over what period, and that it renews.
  ///
  /// With no known period it says nothing about renewal — a claim we can't
  /// support from the product is not made.
  String get renewalDisclosure {
    final p = period;
    if (p == null) {
      return '$priceString. Manage or cancel in your App Store settings.';
    }
    final core = '$priceString per ${p.label}, auto-renews until cancelled';
    final trial = freeTrial;
    if (trial == null) {
      return '$core. Cancel anytime in your App Store settings.';
    }
    return 'Free for ${trial.label}, then $core. Cancel anytime before the '
        'trial ends in your App Store settings.';
  }
}

/// The set of plans the current RevenueCat offering exposes.
class SubscriptionOffer {
  final List<SubscriptionPlan> plans;

  const SubscriptionOffer(this.plans);

  bool get isEmpty => plans.isEmpty;
  bool get isNotEmpty => plans.isNotEmpty;

  /// Longest commitment first (yearly above weekly), matching the paywall's
  /// existing hierarchy. Plans with no known period sort last, keeping their
  /// relative order.
  List<SubscriptionPlan> get ordered {
    final sorted = List<SubscriptionPlan>.from(plans);
    sorted.sort((a, b) {
      final aw = a.period?.weeks;
      final bw = b.period?.weeks;
      if (aw == null && bw == null) return 0;
      if (aw == null) return 1;
      if (bw == null) return -1;
      return bw.compareTo(aw);
    });
    return sorted;
  }

  /// The cheapest plan per week — the one that earns "BEST VALUE". Null when
  /// fewer than two plans can be compared, because "best" is meaningless
  /// against nothing.
  SubscriptionPlan? get bestValue {
    final comparable = plans.where((p) => p.weeklyPrice != null).toList();
    if (comparable.length < 2) return null;
    comparable.sort((a, b) => a.weeklyPrice!.compareTo(b.weeklyPrice!));
    final best = comparable.first;
    // A tie is not a best value.
    if (comparable[1].weeklyPrice! <= best.weeklyPrice!) return null;
    return best;
  }

  /// Whole-percent saving of [plan] against the most expensive comparable
  /// plan in this offer — the replacement for the old hardcoded "Save 83%".
  ///
  /// Null when there's nothing to compare against, when the periods aren't
  /// known, when the currencies differ (comparing across currencies would be
  /// a fabricated number), or when the saving rounds to nothing.
  int? savingsPercentFor(SubscriptionPlan plan) {
    final own = plan.weeklyPrice;
    if (own == null || own <= 0) return null;
    double? reference;
    for (final other in plans) {
      if (identical(other, plan) || other.packageId == plan.packageId) continue;
      if (other.currencyCode != plan.currencyCode) continue;
      final weekly = other.weeklyPrice;
      if (weekly == null) continue;
      if (reference == null || weekly > reference) reference = weekly;
    }
    if (reference == null || reference <= own) return null;
    final percent = ((reference - own) / reference * 100).round();
    return percent >= 1 ? percent : null;
  }
}

/// How a purchase attempt ended.
///
/// Cancelling is a first-class, expected outcome — not a failure — so the
/// paywall can stay quiet instead of showing an error the athlete caused on
/// purpose.
enum PurchaseOutcome {
  /// Paid (or trial started) and the entitlement is now active.
  success,

  /// The athlete backed out of the store sheet.
  cancelled,

  /// The purchase went through but granted no entitlement — a configuration
  /// problem in RevenueCat, not something the athlete can fix.
  notEntitled,

  /// Anything else: network, store, declined payment.
  failed,

  /// Purchases aren't available in this build at all (no API key).
  unavailable,
}

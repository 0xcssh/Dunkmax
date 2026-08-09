import 'package:dunkmax/core/subscription_offer.dart';
import 'package:flutter_test/flutter_test.dart';

SubscriptionPlan _yearly({
  String priceString = '\$59.99',
  double price = 59.99,
  String currency = 'USD',
  BillingPeriod? trial = const BillingPeriod(BillingUnit.day, 3),
}) {
  return SubscriptionPlan(
    packageId: '\$rc_annual',
    priceString: priceString,
    price: price,
    currencyCode: currency,
    period: const BillingPeriod(BillingUnit.year, 1),
    freeTrial: trial,
  );
}

SubscriptionPlan _weekly({
  String priceString = '\$6.99',
  double price = 6.99,
  String currency = 'USD',
}) {
  return SubscriptionPlan(
    packageId: '\$rc_weekly',
    priceString: priceString,
    price: price,
    currencyCode: currency,
    period: const BillingPeriod(BillingUnit.week, 1),
    freeTrial: const BillingPeriod(BillingUnit.day, 3),
  );
}

void main() {
  group('BillingPeriod.parseIso8601', () {
    test('parses the four units the stores report', () {
      expect(BillingPeriod.parseIso8601('P3D'),
          const BillingPeriod(BillingUnit.day, 3));
      expect(BillingPeriod.parseIso8601('P1W'),
          const BillingPeriod(BillingUnit.week, 1));
      expect(BillingPeriod.parseIso8601('P6M'),
          const BillingPeriod(BillingUnit.month, 6));
      expect(BillingPeriod.parseIso8601('P1Y'),
          const BillingPeriod(BillingUnit.year, 1));
    });

    test('rejects anything it cannot read rather than guessing', () {
      expect(BillingPeriod.parseIso8601(null), isNull);
      expect(BillingPeriod.parseIso8601(''), isNull);
      expect(BillingPeriod.parseIso8601('P1Y6M'), isNull);
      expect(BillingPeriod.parseIso8601('P0D'), isNull);
      expect(BillingPeriod.parseIso8601('1Y'), isNull);
      expect(BillingPeriod.parseIso8601('PT1H'), isNull);
    });

    test('weeks put unequal periods on one axis', () {
      expect(const BillingPeriod(BillingUnit.week, 1).weeks, 1);
      expect(const BillingPeriod(BillingUnit.day, 7).weeks, 1);
      expect(const BillingPeriod(BillingUnit.year, 1).weeks,
          closeTo(52.1786, 0.001));
      expect(const BillingPeriod(BillingUnit.month, 1).weeks,
          closeTo(4.348, 0.001));
    });

    test('labels read naturally in copy', () {
      expect(const BillingPeriod(BillingUnit.year, 1).label, 'year');
      expect(const BillingPeriod(BillingUnit.month, 3).label, '3 months');
      expect(const BillingPeriod(BillingUnit.day, 3).hyphenatedLabel, '3-day');
    });
  });

  group('formatLikePrice', () {
    test('keeps a leading symbol and a dot decimal', () {
      expect(formatLikePrice('\$59.99', 59.99, 1.1497), '\$1.15');
    });

    test('keeps a trailing symbol and a comma decimal', () {
      expect(formatLikePrice('59,99 €', 59.99, 1.1497), '1,15 €');
    });

    test('keeps a multi-character symbol', () {
      expect(formatLikePrice('US\$59.99', 59.99, 1.1497), 'US\$1.15');
    });

    test('handles a zero-decimal currency without inventing minor units', () {
      expect(formatLikePrice('¥1,200', 1200, 22.998), '¥23');
    });

    test('re-groups a large derived amount with the string own separator', () {
      expect(formatLikePrice('\$1,200.00', 1200, 11000), '\$11,000.00');
    });

    test('returns null when there is no number to rewrite', () {
      expect(formatLikePrice('Free', 59.99, 1.15), isNull);
    });

    test('returns null when the digits do not match the reference amount', () {
      // Never edit a string we misread.
      expect(formatLikePrice('\$59.99', 12.34, 1.15), isNull);
    });

    test('rejects a non-positive reference', () {
      expect(formatLikePrice('\$0.00', 0, 1.15), isNull);
    });
  });

  group('SubscriptionPlan copy', () {
    test('derives the weekly headline and the billed line for a yearly plan',
        () {
      final plan = _yearly();
      expect(plan.title, 'YEARLY');
      expect(plan.headlineLine, '\$1.15/week');
      expect(plan.billedLine, 'Billed \$59.99/year');
      expect(plan.trialLine, '3-day free trial');
      expect(plan.ctaLabel, 'START FREE TRIAL');
    });

    test('a weekly plan shows no redundant billed line', () {
      final plan = _weekly();
      expect(plan.headlineLine, '\$6.99/week');
      expect(plan.billedLine, isNull);
    });

    test('the disclosure states price, period, trial and auto-renewal', () {
      final disclosure = _yearly().renewalDisclosure;
      expect(disclosure, contains('Free for 3 days'));
      expect(disclosure, contains('\$59.99 per year'));
      expect(disclosure, contains('auto-renews'));
    });

    test('no trial means no trial promise anywhere', () {
      final plan = _yearly(trial: null);
      expect(plan.trialLine, isNull);
      expect(plan.ctaLabel, 'SUBSCRIBE');
      expect(plan.renewalDisclosure, isNot(contains('Free for')));
      expect(plan.renewalDisclosure, contains('auto-renews'));
    });

    test('an unknown period claims neither a per-week price nor renewal', () {
      const plan = SubscriptionPlan(
        packageId: 'lifetime',
        priceString: '\$99.99',
        price: 99.99,
        currencyCode: 'USD',
      );
      expect(plan.title, 'LIFETIME');
      expect(plan.weeklyPrice, isNull);
      expect(plan.headlineLine, '\$99.99');
      expect(plan.billedLine, isNull);
      expect(plan.renewalDisclosure, isNot(contains('auto-renews')));
    });
  });

  group('SubscriptionOffer', () {
    test('orders the longest commitment first', () {
      final offer = SubscriptionOffer([_weekly(), _yearly()]);
      expect(offer.ordered.first.packageId, '\$rc_annual');
    });

    test('derives the saving instead of asserting a hardcoded one', () {
      final yearly = _yearly();
      final offer = SubscriptionOffer([yearly, _weekly()]);
      // 59.99/year is 1.1497/week against 6.99/week — 84%, not the 83% the
      // presentation-only paywall used to print.
      expect(offer.savingsPercentFor(yearly), 84);
    });

    test('the reference plan itself saves nothing', () {
      final weekly = _weekly();
      final offer = SubscriptionOffer([_yearly(), weekly]);
      expect(offer.savingsPercentFor(weekly), isNull);
    });

    test('a lone plan has no best value and no saving', () {
      final yearly = _yearly();
      final offer = SubscriptionOffer([yearly]);
      expect(offer.bestValue, isNull);
      expect(offer.savingsPercentFor(yearly), isNull);
    });

    test('never compares across currencies', () {
      final yearly = _yearly();
      final offer = SubscriptionOffer([
        yearly,
        _weekly(priceString: '6,99 €', price: 6.99, currency: 'EUR'),
      ]);
      expect(offer.savingsPercentFor(yearly), isNull);
    });

    test('the cheapest per week wins BEST VALUE', () {
      final offer = SubscriptionOffer([_weekly(), _yearly()]);
      expect(offer.bestValue?.packageId, '\$rc_annual');
    });

    test('an empty offer is empty', () {
      const offer = SubscriptionOffer([]);
      expect(offer.isEmpty, isTrue);
      expect(offer.bestValue, isNull);
      expect(offer.ordered, isEmpty);
    });
  });
}

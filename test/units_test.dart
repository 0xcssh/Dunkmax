import 'package:dunkmax/core/standing_reach.dart';
import 'package:dunkmax/core/units.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitSystem.forRegion', () {
    test('the three imperial countries keep feet, inches and pounds', () {
      for (final country in ['US', 'LR', 'MM']) {
        expect(UnitSystem.forRegion(country, 'en'), UnitSystem.imperial,
            reason: country);
      }
    });

    test('country wins over language', () {
      // A Spanish speaker in the US: imperial.
      expect(UnitSystem.forRegion('US', 'es'), UnitSystem.imperial);
      // An English speaker anywhere else: metric.
      for (final country in ['GB', 'CA', 'AU', 'IE', 'NZ', 'FR', 'DE', 'JP']) {
        expect(UnitSystem.forRegion(country, 'en'), UnitSystem.metric,
            reason: country);
      }
      expect(UnitSystem.forRegion('FR', 'fr'), UnitSystem.metric);
    });

    test('case and whitespace in the country code do not matter', () {
      expect(UnitSystem.forRegion('us', 'en'), UnitSystem.imperial);
      expect(UnitSystem.forRegion(' Us ', 'fr'), UnitSystem.imperial);
      expect(UnitSystem.forRegion('fr', 'en'), UnitSystem.metric);
    });

    test('no country: English falls back to imperial, anything else metric',
        () {
      expect(UnitSystem.forRegion(null, 'en'), UnitSystem.imperial);
      expect(UnitSystem.forRegion('', 'en'), UnitSystem.imperial);
      expect(UnitSystem.forRegion(null, 'EN'), UnitSystem.imperial);
      expect(UnitSystem.forRegion(null, 'fr'), UnitSystem.metric);
      expect(UnitSystem.forRegion('', 'de'), UnitSystem.metric);
      expect(UnitSystem.forRegion(null, 'es'), UnitSystem.metric);
    });
  });

  group('UnitConversions', () {
    test('inches to whole centimetres', () {
      expect(UnitConversions.inchesToCm(1), 3); // 2.54 rounds up
      expect(UnitConversions.inchesToCm(29), 74); // 73.66
      expect(UnitConversions.inchesToCm(73), 185); // 185.42
      expect(UnitConversions.inchesToCm(97), 246); // 246.38
      expect(UnitConversions.inchesToCm(0), 0);
    });

    test('centimetres to whole inches', () {
      expect(UnitConversions.cmToInches(185), 73); // 72.83
      expect(UnitConversions.cmToInches(180), 71); // 70.87
      expect(UnitConversions.cmToInches(140), 55); // 55.12
      expect(UnitConversions.cmToInches(220), 87); // 86.61
    });

    test('pounds to whole kilograms and back', () {
      expect(UnitConversions.lbsToKg(180), 82); // 81.65
      expect(UnitConversions.lbsToKg(75), 34); // 34.02
      expect(UnitConversions.lbsToKg(300), 136); // 136.08
      expect(UnitConversions.kgToLbs(80), 176); // 176.37
      expect(UnitConversions.kgToLbs(35), 77); // 77.16
      expect(UnitConversions.kgToLbs(150), 331); // 330.69
    });

    test('a kilogram pick survives the round trip through pounds', () {
      // 1 kg is 2.2 lb, so rounding to a whole pound never moves the kilogram
      // the athlete chose. (Centimetres are finer than inches, so the same
      // is not promised for heights — 1" is 2.54 cm.)
      for (var kg = UnitInputRanges.minWeightKg;
          kg <= UnitInputRanges.maxWeightKg;
          kg++) {
        expect(UnitConversions.lbsToKg(UnitConversions.kgToLbs(kg)), kg,
            reason: '$kg kg');
      }
    });

    test('a logged load keeps its decimals', () {
      expect(UnitConversions.kgToLbsExact(62.5), closeTo(137.79, 0.01));
      expect(UnitConversions.lbsToKgExact(137.79), closeTo(62.5, 0.01));
    });
  });

  group('UnitSystemDisplay', () {
    const metric = UnitSystem.metric;
    const imperial = UnitSystem.imperial;

    test('lengths come back as (value, unit) pairs', () {
      expect(imperial.length(29), (value: 29, unit: LengthUnit.inches));
      expect(metric.length(29), (value: 74, unit: LengthUnit.cm));
      expect(imperial.lengthValue(6), 6);
      expect(metric.lengthValue(6), 15);
    });

    test('a signed delta keeps its sign', () {
      expect(metric.lengthValue(-3), -8);
      expect(imperial.lengthValue(-3), -3);
    });

    test('weights come back as (value, unit) pairs', () {
      expect(imperial.weight(180), (value: 180, unit: WeightUnit.lbs));
      expect(metric.weight(180), (value: 82, unit: WeightUnit.kg));
    });

    test('heights split into feet/inches or collapse to centimetres', () {
      final i = imperial.height(73);
      expect((i.feet, i.inches, i.cm, i.isMetric), (6, 1, 0, false));
      final m = metric.height(73);
      expect((m.feet, m.inches, m.cm, m.isMetric), (0, 0, 185, true));
      final neg = imperial.height(-5);
      expect((neg.feet, neg.inches), (0, 0));
    });

    test('inputs convert back to the stored units', () {
      expect(metric.inchesFromLength(185), 73);
      expect(imperial.inchesFromLength(73), 73);
      expect(metric.lbsFromWeight(80), 176);
      expect(imperial.lbsFromWeight(180), 180);
      expect(metric.lbsFromLoad(62.5), closeTo(137.79, 0.01));
      expect(imperial.lbsFromLoad(135), 135);
      expect(metric.loadValue(137.79), closeTo(62.5, 0.01));
    });

    test('untranslated core prose formats the unit itself', () {
      expect(imperial.formatLength(29), '29"');
      expect(metric.formatLength(29), '74 cm');
    });
  });

  group('input ranges', () {
    test('the metric height wheel never stores an implausible inch value', () {
      final low = UnitConversions.cmToInches(UnitInputRanges.minHeightCm);
      final high = UnitConversions.cmToInches(UnitInputRanges.maxHeightCm);
      expect(low, greaterThanOrEqualTo(UnitInputRanges.minHeightFeet * 12));
      expect(high, lessThan((UnitInputRanges.maxHeightFeet + 1) * 12));
    });

    test('the metric reach wheel stays inside the inch bounds', () {
      expect(StandingReach.isPlausible(
          UnitConversions.cmToInches(StandingReach.minCm)), isTrue);
      expect(StandingReach.isPlausible(
          UnitConversions.cmToInches(StandingReach.maxCm)), isTrue);
      expect(StandingReach.clampCm(100), StandingReach.minCm);
      expect(StandingReach.clampCm(300), StandingReach.maxCm);
      expect(StandingReach.clampCm(246), 246);
      expect(StandingReach.isPlausibleCm(139), isFalse);
      expect(StandingReach.isPlausibleCm(279), isTrue);
    });
  });
}

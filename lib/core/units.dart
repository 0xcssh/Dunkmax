/// Unit systems: which one a region uses, and the conversions between the
/// app's storage units and what the athlete sees.
///
/// Everything the app stores is imperial — heights, reaches and verticals in
/// whole inches, body weight in whole pounds, a logged set's load in pounds
/// (`OnboardingProfile`, `JumpLogEntry`, `LeaderboardAthlete`, `LoggedSet`).
/// That never changes: one storage unit means the maths, the persisted
/// payloads and the leaderboard rows are the same for every athlete. Only
/// *input* and *display* convert, at the edge, through this file.
///
/// Rounding is to whole units in both directions. A vertical is an integer
/// number of inches already, and 1" ≈ 2.5 cm, so a metric vertical is shown
/// in whole centimetres with no decimals — the inch rounding underneath is
/// coarser than a centimetre anyway.
///
/// Pure Dart, no Flutter imports.
enum UnitSystem {
  /// Centimetres and kilograms.
  metric,

  /// Feet/inches and pounds.
  imperial;

  /// The ISO 3166-1 alpha-2 regions that still measure people in feet, inches
  /// and pounds: the United States, Liberia and Myanmar. Everyone else is
  /// metric.
  static const Set<String> imperialRegions = {'US', 'LR', 'MM'};

  /// The unit system for an athlete whose device reports [countryCode] (ISO
  /// 3166-1 alpha-2, any case) and [languageCode].
  ///
  /// The country decides. When the platform gives no country at all — a
  /// locale like plain `en` — the language is the only hint left: English
  /// falls back to imperial (most English-only devices without a region are
  /// US-configured), every other language to metric.
  static UnitSystem forRegion(String? countryCode, String languageCode) {
    final country = countryCode?.trim().toUpperCase();
    if (country != null && country.isNotEmpty) {
      return imperialRegions.contains(country)
          ? UnitSystem.imperial
          : UnitSystem.metric;
    }
    return languageCode.trim().toLowerCase() == 'en'
        ? UnitSystem.imperial
        : UnitSystem.metric;
  }

  bool get isMetric => this == UnitSystem.metric;
  bool get isImperial => this == UnitSystem.imperial;
}

/// Exact conversion factors and the whole-unit conversions built on them.
abstract class UnitConversions {
  /// One inch, in centimetres — exact by definition since 1959.
  static const double cmPerInch = 2.54;

  /// One pound, in kilograms — exact by definition since 1959.
  static const double kgPerLb = 0.45359237;

  static int inchesToCm(int inches) => (inches * cmPerInch).round();

  static int cmToInches(int cm) => (cm / cmPerInch).round();

  static int lbsToKg(int lbs) => (lbs * kgPerLb).round();

  static int kgToLbs(int kg) => (kg / kgPerLb).round();

  /// A logged load keeps its decimals (62.5 kg is a real barbell), so the
  /// double conversions do not round.
  static double lbsToKgExact(double lbs) => lbs * kgPerLb;

  static double kgToLbsExact(double kg) => kg / kgPerLb;
}

/// The unit a displayed length is in.
enum LengthUnit { inches, cm }

/// The unit a displayed weight is in.
enum WeightUnit { lbs, kg }

/// A length ready for display: a whole number plus the unit it is in.
typedef DisplayLength = ({int value, LengthUnit unit});

/// A weight ready for display: a whole number plus the unit it is in.
typedef DisplayWeight = ({int value, WeightUnit unit});

/// A height ready for display. Imperial heights are two numbers (feet and
/// inches); a metric height is one (centimetres). Exactly one of the two
/// shapes is populated, which [isMetric] says.
class DisplayHeight {
  final UnitSystem system;
  final int feet;
  final int inches;
  final int cm;

  const DisplayHeight._({
    required this.system,
    required this.feet,
    required this.inches,
    required this.cm,
  });

  bool get isMetric => system.isMetric;
}

/// Converts between the stored imperial values and the numbers shown or
/// entered in a given unit system.
extension UnitSystemDisplay on UnitSystem {
  LengthUnit get lengthUnit => isMetric ? LengthUnit.cm : LengthUnit.inches;

  WeightUnit get weightUnit => isMetric ? WeightUnit.kg : WeightUnit.lbs;

  /// A stored length in inches (a vertical, a reach, a gap), as displayed.
  DisplayLength length(int inches) => (
        value: isMetric ? UnitConversions.inchesToCm(inches) : inches,
        unit: lengthUnit,
      );

  /// A length as the athlete typed or picked it, back to stored inches.
  int inchesFromLength(int value) =>
      isMetric ? UnitConversions.cmToInches(value) : value;

  /// Convenience for a signed delta: keeps the sign, converts the magnitude.
  int lengthValue(int inches) => length(inches).value;

  /// A stored body weight in pounds, as displayed.
  DisplayWeight weight(int lbs) => (
        value: isMetric ? UnitConversions.lbsToKg(lbs) : lbs,
        unit: weightUnit,
      );

  /// A body weight as the athlete picked it, back to stored pounds.
  int lbsFromWeight(int value) =>
      isMetric ? UnitConversions.kgToLbs(value) : value;

  /// A logged load in pounds, as displayed, with its decimals kept.
  double loadValue(double lbs) =>
      isMetric ? UnitConversions.lbsToKgExact(lbs) : lbs;

  /// A logged load as typed, back to stored pounds.
  double lbsFromLoad(double value) =>
      isMetric ? UnitConversions.kgToLbsExact(value) : value;

  /// A stored height in inches, as displayed: `feet`/`inches` for imperial,
  /// `cm` for metric (the unused shape holds zeros).
  DisplayHeight height(int inches) {
    final safe = inches < 0 ? 0 : inches;
    if (isMetric) {
      return DisplayHeight._(
        system: this,
        feet: 0,
        inches: 0,
        cm: UnitConversions.inchesToCm(safe),
      );
    }
    return DisplayHeight._(
      system: this,
      feet: safe ~/ 12,
      inches: safe % 12,
      cm: 0,
    );
  }

  /// Formats a stored length for text that is not translated (the English
  /// coaching prose authored in `core/`): `29"` or `74 cm`.
  String formatLength(int inches) {
    final l = length(inches);
    return l.unit == LengthUnit.cm ? '${l.value} cm' : '${l.value}"';
  }
}

/// The ranges the input pickers offer, per unit system. Each pair brackets
/// the same population: the metric bounds are the imperial ones converted
/// and rounded to a round figure, so switching region never clips a value.
abstract class UnitInputRanges {
  /// Height wheels: imperial offers 4'0"–7'11", metric 140–220 cm.
  static const int minHeightFeet = 4;
  static const int maxHeightFeet = 7;
  static const int minHeightCm = 140;
  static const int maxHeightCm = 220;

  /// Body-weight slider: imperial 75–300 lbs, metric 35–150 kg.
  static const int minWeightLbs = 75;
  static const int maxWeightLbs = 300;
  static const int minWeightKg = 35;
  static const int maxWeightKg = 150;
}

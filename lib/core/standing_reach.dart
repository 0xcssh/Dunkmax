/// Sanity bounds and formatting for a self-reported standing reach — the
/// fingertip height of one arm overhead, flat-footed, in inches.
///
/// The number itself is consumed by `VertAssessment`; this only decides which
/// values a human could plausibly have measured, so a fat-fingered picker or a
/// corrupt stored payload can never turn the dunk target into nonsense.
///
/// Bounds are deliberately wide: the shortest realistic athlete this app will
/// see reaches somewhere around 55", and the tallest ever recorded reaches
/// nowhere near 110". Anything outside that was not a measurement.
///
/// Pure Dart, no Flutter imports.
abstract class StandingReach {
  /// Lowest reach the app will accept, in inches.
  static const int minInches = 55;

  /// Highest reach the app will accept, in inches.
  static const int maxInches = 110;

  /// The same bounds for a metric picker, in whole centimetres — the inch
  /// bounds converted and rounded (55" = 139.7 cm, 110" = 279.4 cm). A value
  /// picked in this range always converts back inside [minInches]..
  /// [maxInches], so the metric wheel can never store an implausible reach.
  static const int minCm = 140;
  static const int maxCm = 279;

  static bool isPlausibleCm(int cm) => cm >= minCm && cm <= maxCm;

  /// Pulls [cm] into the plausible metric range.
  static int clampCm(int cm) {
    if (cm < minCm) return minCm;
    if (cm > maxCm) return maxCm;
    return cm;
  }

  static bool isPlausible(int inches) =>
      inches >= minInches && inches <= maxInches;

  /// Pulls [inches] into the plausible range.
  static int clampInches(int inches) {
    if (inches < minInches) return minInches;
    if (inches > maxInches) return maxInches;
    return inches;
  }

  /// Normalises a value that may be absent or out of range: null stays null,
  /// and an implausible number becomes null too, so callers fall back to the
  /// height estimate instead of trusting garbage.
  static int? sanitize(int? inches) {
    if (inches == null) return null;
    return isPlausible(inches) ? inches : null;
  }

  /// Feet-and-inches label, e.g. 97 → `8'1"`.
  static String label(int inches) => "${inches ~/ 12}'${inches % 12}\"";
}

/// Pure physics for the Analyze tab's headline number: the flight-time
/// method. A jumper's airborne height only depends on how long they were in
/// the air — `h = g·t²/8` — so no pixel→inch camera calibration is needed,
/// just an accurate takeoff/landing timestamp pair. This is how most real
/// vertical-jump apps measure a jump from video.
///
/// No Flutter imports — fully unit-tested.
abstract class FlightTime {
  /// Standard gravity, in inches per second squared (9.81 m/s²).
  static const double gravityInchesPerSecSq = 386.09;

  /// Shortest airborne time worth treating as a real jump (rules out a
  /// mis-mark where takeoff/landing land on the same frame).
  static const double minAirborneSeconds = 0.15;

  /// Longest airborne time that's physically plausible for a standing
  /// vertical leap. 0.98s corresponds to ~46" — above the tracked NBA
  /// vertical-leap record and every realistic recreational or pro athlete's
  /// jump. (The old 1.3s ceiling corresponded to ~81", which is nonsensical
  /// for a human and let a real bug — the detector locking onto the wrong
  /// window — produce a "50 inch" reading instead of being caught here.)
  static const double maxAirborneSeconds = 0.98;

  /// Airborne height in inches for a hang time of [airborneSeconds].
  /// Returns 0 for non-positive input.
  static double heightInches(double airborneSeconds) {
    if (airborneSeconds <= 0) return 0;
    return gravityInchesPerSecSq * airborneSeconds * airborneSeconds / 8;
  }

  /// Whether [airborneSeconds] falls in a plausible range for a real
  /// standing vertical jump (as opposed to a mis-marked takeoff/landing).
  static bool isPlausible(double airborneSeconds) =>
      airborneSeconds >= minAirborneSeconds &&
      airborneSeconds <= maxAirborneSeconds;
}

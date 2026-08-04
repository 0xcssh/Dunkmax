import '../flight_time.dart';

/// A single jump captured from video: the athlete (or, later, on-device
/// motion detection) marks the takeoff and landing instants on the clip's
/// timeline. Everything else — airborne time, validity, estimated vertical —
/// is derived. No Flutter imports.
class JumpMeasurement {
  final Duration takeoff;
  final Duration landing;

  const JumpMeasurement({required this.takeoff, required this.landing});

  Duration get airborne => landing - takeoff;

  double get airborneSeconds =>
      airborne.inMicroseconds / Duration.microsecondsPerSecond;

  /// False if the marks are out of order or outside a plausible jump range —
  /// the UI should ask the athlete to re-mark rather than show a bogus vert.
  bool get isValid =>
      landing > takeoff && FlightTime.isPlausible(airborneSeconds);

  /// Estimated vertical leap, in inches (0 if [isValid] is false).
  int get verticalInches =>
      isValid ? FlightTime.heightInches(airborneSeconds).round() : 0;
}

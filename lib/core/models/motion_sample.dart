/// One sampled instant of a jump clip: how much the image changed since the
/// previous sample. Low energy ~= the body moving smoothly through the air
/// (airborne); high energy ~= the jump drive or the landing impact.
class MotionSample {
  final Duration timestamp;
  final double energy;

  const MotionSample({required this.timestamp, required this.energy});
}

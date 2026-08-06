import 'dart:math' as math;

/// Least-squares fit of a body point's flight to the parabola gravity forces
/// it to follow, and the jump height that falls out of it.
///
/// ## Why this replaces hunting for takeoff and landing frames
///
/// The flight-time formula `h = g·T²/8` is exact, so every bit of error lives
/// in `T` — and `T` was previously read off the two frames where the feet
/// appeared to cross a threshold. That is the fragile part, and it is fragile
/// for everyone: the validation study of MyJump (the research-grade reference
/// app) recommends **240 fps** and still reports that "detection of the frames
/// representing take-off and landing is problematic" depending on the phone,
/// the subject and the lighting. Sampling a clip on a phone at ~10 frames per
/// second and then asking two of them to pin an instant to the millisecond was
/// never going to work, and no threshold value fixes that.
///
/// A free body's vertical position is a parabola in time. So instead of
/// looking for the boundary frames, fit the parabola to *every* airborne
/// sample and solve for where it meets the ground:
///
///   y(t) = A·t² + B·t + C          (image coordinates, y grows downward)
///
/// The feet are at ground level `yGround` at exactly the takeoff and landing
/// instants, so those are the roots of `A·t² + B·t + (C − yGround) = 0`, and
///
///   T = √(B² − 4A(C − yGround)) / A
///
/// Nothing here needs a sample near either end of the flight. Six points from
/// the middle of the arc determine the whole parabola, and the ends are
/// extrapolated analytically. Sample-rate quantisation, threshold bias and the
/// parabola correction that used to compensate for it all disappear.
///
/// ## Gravity also calibrates the camera
///
/// `2A` is gravity expressed in pixels per second squared, which makes the
/// scale of the scene a free by-product:
///
///   pixelsPerMetre = 2A / 9.81
///
/// This is the same trick the literature calls gravity-based self-calibration
/// (Bieler et al., ICCV 2019, reporting ~3.9 cm mean absolute error on jumps
/// with no camera or ground-plane calibration). It gives an independent way to
/// sanity-check a fit: the athlete's height in pixels, divided by this scale,
/// must come out near the height they entered during onboarding. A fit that
/// implies a nine-foot athlete is a bad fit, and we would rather know.
///
/// (Deriving the height from the apex rise instead of from `T` is algebraically
/// the same number — `D·g/(8A²)` either way — so it is a restatement, not a
/// second opinion. The scale check above is the real independent one.)
///
/// No Flutter imports; fully unit tested.
class BallisticFit {
  /// Quadratic coefficient, in px/s². Positive for a real jump, because image
  /// y grows downward and the feet accelerate back toward the ground.
  final double a;
  final double b;
  final double c;

  /// Root-mean-square vertical residual, in pixels. How well the samples
  /// actually lie on a parabola — the natural confidence measure, since bad
  /// tracking shows up here immediately.
  final double rmsResidualPixels;

  /// Number of airborne samples the fit was built from.
  final int sampleCount;

  const BallisticFit({
    required this.a,
    required this.b,
    required this.c,
    required this.rmsResidualPixels,
    required this.sampleCount,
  });

  /// Gravity as this clip measures it, in px/s².
  double get gravityPixelsPerSecSq => 2 * a;

  /// Scene scale implied by gravity alone, in pixels per metre.
  double get pixelsPerMetre => gravityPixelsPerSecSq / 9.81;

  /// Instant of the arc's apex, in seconds on the fit's own time axis.
  double get apexSeconds => -b / (2 * a);

  /// Fitted y at the apex, in pixels (the smallest y, since y grows downward).
  double get apexY => c - (b * b) / (4 * a);

  /// Airborne time implied by this parabola meeting [groundY], in seconds.
  /// Null when the arc never reaches ground level — a fit that describes
  /// something other than a completed jump.
  double? airborneSeconds(double groundY) {
    if (a <= 0) return null;
    final discriminant = b * b - 4 * a * (c - groundY);
    if (discriminant <= 0) return null;
    return math.sqrt(discriminant) / a;
  }

  /// Fits `y = A·t² + B·t + C` to [samples] by ordinary least squares.
  ///
  /// Times are re-centred on the mean before solving. That is not cosmetic: on
  /// a clip several seconds in, raw timestamps make the normal equations
  /// severely ill-conditioned (t⁴ terms in the tens of thousands against a
  /// nearly-constant column), and the fit degrades for no reason. Centring
  /// removes that, and the coefficients are shifted back afterwards so callers
  /// still work in the clip's own timeline.
  ///
  /// Returns null if there are fewer than 4 samples (3 determine a parabola
  /// exactly, leaving no residual to judge it by) or the system is degenerate.
  static BallisticFit? fit(List<({double seconds, double y})> samples) {
    if (samples.length < 4) return null;

    final meanT =
        samples.map((s) => s.seconds).reduce((x, y) => x + y) / samples.length;

    var s0 = 0.0, s1 = 0.0, s2 = 0.0, s3 = 0.0, s4 = 0.0;
    var ty0 = 0.0, ty1 = 0.0, ty2 = 0.0;
    for (final sample in samples) {
      final t = sample.seconds - meanT;
      final t2 = t * t;
      s0 += 1;
      s1 += t;
      s2 += t2;
      s3 += t2 * t;
      s4 += t2 * t2;
      ty0 += sample.y;
      ty1 += t * sample.y;
      ty2 += t2 * sample.y;
    }

    // Solve the 3x3 normal equations by Cramer's rule.
    final m = [
      [s4, s3, s2],
      [s3, s2, s1],
      [s2, s1, s0],
    ];
    final rhs = [ty2, ty1, ty0];
    final det = _det3(m);
    if (det.abs() < 1e-12) return null;

    final aC = _det3(_replaceColumn(m, 0, rhs)) / det;
    final bC = _det3(_replaceColumn(m, 1, rhs)) / det;
    final cC = _det3(_replaceColumn(m, 2, rhs)) / det;

    // Undo the centring: y = aC(t−m)² + bC(t−m) + cC.
    final a = aC;
    final b = bC - 2 * aC * meanT;
    final c = cC - bC * meanT + aC * meanT * meanT;

    var squared = 0.0;
    for (final sample in samples) {
      final t = sample.seconds;
      final predicted = a * t * t + b * t + c;
      final residual = sample.y - predicted;
      squared += residual * residual;
    }

    return BallisticFit(
      a: a,
      b: b,
      c: c,
      rmsResidualPixels: math.sqrt(squared / samples.length),
      sampleCount: samples.length,
    );
  }

  static double _det3(List<List<double>> m) =>
      m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) -
      m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0]) +
      m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]);

  static List<List<double>> _replaceColumn(
    List<List<double>> m,
    int column,
    List<double> values,
  ) =>
      [
        for (var row = 0; row < 3; row++)
          [
            for (var col = 0; col < 3; col++)
              col == column ? values[row] : m[row][col],
          ],
      ];
}

import 'dart:math' as math;

import 'models/jump_measurement.dart';
import 'vert_assessment.dart';

/// A measured jump interpreted against the athlete's dunk goal — the same
/// [VertAssessment] math the onboarding "gap" screen uses, so the Analyze
/// result reads consistently with the rest of the app. Where onboarding's
/// `estimatedCurrentVert` is a self-reported guess, this is a real
/// video-measured number.
class JumpResult {
  final JumpMeasurement measurement;
  final VertAssessment assessment;

  JumpResult({required this.measurement, required this.assessment});

  int get verticalInches => measurement.verticalInches;

  int get requiredVert => assessment.requiredVert;

  /// Inches still missing to dunk (0 if this jump already clears it).
  int get gapInches => math.max(0, requiredVert - verticalInches);

  bool get clearsDunk =>
      requiredVert > 0 ? verticalInches >= requiredVert : false;

  /// 0–1 (can exceed 1 if the jump beats the requirement) progress toward
  /// the dunk target, for a progress bar.
  double get progressToGoal {
    if (requiredVert <= 0) return 1;
    return verticalInches / requiredVert;
  }
}

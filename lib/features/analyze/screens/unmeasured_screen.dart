import 'package:flutter/material.dart';

import '../../../core/models/video_attempt_type.dart';
import '../../../core/pose_jump_detector.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';
import '../widgets/detection_details_card.dart';
import 'processing_screen.dart';

/// Shown when body tracking looked at the clip and declined to measure it.
///
/// This replaces asking the athlete to scrub the video and tap the takeoff
/// and landing frames themselves. That fallback always worked, but it is a
/// fiddly job handed over at the exact moment the app failed at its one
/// headline feature, and it was measurably worse than the automatic path:
/// the flight-time literature that this app's method comes from reports that
/// identifying those two frames by eye is the dominant source of error even
/// for trained users at 240 fps.
///
/// So instead of a task, the athlete gets the reason and the fix. Every line
/// here is derived from what the detector actually reported — there is no
/// generic "something went wrong".
class UnmeasuredScreen extends StatelessWidget {
  final PoseDetectionRejection rejection;

  /// Everything both passes saw. Shown here, collapsed, for the same reason
  /// it is shown on the result screen — except it matters more here: this is
  /// the screen a bug report is written from, and the first version of it
  /// left the numbers unreachable at exactly the moment somebody needs them.
  final JumpAnalysis analysis;
  final VideoAttemptType attemptType;

  /// Re-open the trim step on the same clip: most rejections are fixed by
  /// tightening the range to the single jump.
  final VoidCallback onRetrim;

  /// Start over with a different clip.
  final VoidCallback onNewClip;

  const UnmeasuredScreen({
    super.key,
    required this.rejection,
    required this.analysis,
    required this.attemptType,
    required this.onRetrim,
    required this.onNewClip,
  });

  /// What the athlete can actually do about each verdict.
  ///
  /// Keyed on the detector's own reason so the advice is never generic. Where
  /// trimming genuinely helps, it is named first, because that is the cheapest
  /// fix and the one most likely to work.
  (String, List<String>) _diagnosis(AppLocalizations l10n) {
    switch (rejection) {
      case PoseDetectionRejection.noAirborneWindow:
        return (
          l10n.unmeasuredNoWindowHeadline,
          [
            l10n.unmeasuredNoWindowFix1,
            l10n.unmeasuredNoWindowFix2,
            l10n.unmeasuredNoWindowFix3,
          ],
        );
      case PoseDetectionRejection.tooManyMissing:
      case PoseDetectionRejection.noScaleReference:
        return (
          l10n.unmeasuredLostTrackHeadline,
          [
            l10n.unmeasuredLostTrackFix1,
            l10n.unmeasuredLostTrackFix2,
            l10n.unmeasuredLostTrackFix3,
          ],
        );
      case PoseDetectionRejection.gappyWindow:
        return (
          l10n.unmeasuredGappyHeadline,
          [
            l10n.unmeasuredGappyFix1,
            l10n.unmeasuredGappyFix2,
            l10n.unmeasuredGappyFix3,
          ],
        );
      case PoseDetectionRejection.liftTooSmall:
        return (
          l10n.unmeasuredSmallJumpHeadline,
          [
            l10n.unmeasuredSmallJumpFix1,
            l10n.unmeasuredSmallJumpFix2,
          ],
        );
      case PoseDetectionRejection.implausibleDuration:
        return (
          l10n.unmeasuredImplausibleHeadline,
          [
            l10n.unmeasuredImplausibleFix1,
            l10n.unmeasuredImplausibleFix2,
          ],
        );
      case PoseDetectionRejection.tooFewSamples:
        return (
          l10n.unmeasuredTooShortHeadline,
          [l10n.unmeasuredTooShortFix1],
        );
      case PoseDetectionRejection.none:
        return (
          l10n.unmeasuredGenericHeadline,
          [l10n.unmeasuredGenericFix1],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (headline, fixes) = _diagnosis(l10n);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              l10n.unmeasuredTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.unmeasuredSubtitle,
              style: DunkTheme.onboardingSubtitle,
            ),
            const SizedBox(height: 28),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: DunkColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: DunkColors.stroke),
              ),
              child: const Icon(Icons.search_off_outlined,
                  color: DunkColors.primary, size: 40),
            ),
            const SizedBox(height: 22),
            Text(
              headline,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            for (final fix in fixes) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.arrow_right_alt,
                          color: DunkColors.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fix,
                        style: const TextStyle(
                          color: DunkColors.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            PrimaryButton(
              label: l10n.unmeasuredRetrimCta,
              trailingIcon: Icons.content_cut,
              onPressed: onRetrim,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: onNewClip,
                child: Text(
                  l10n.unmeasuredNewClip,
                  style: const TextStyle(
                    color: DunkColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
              if (analysis.hasAnyData) ...[
                const SizedBox(height: 16),
                DetectionDetailsCard(
                  analysis: analysis,
                  method: JumpDetectionMethod.pose,
                  attemptType: attemptType,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/pose_jump_detector.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';

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

  /// Re-open the trim step on the same clip: most rejections are fixed by
  /// tightening the range to the single jump.
  final VoidCallback onRetrim;

  /// Start over with a different clip.
  final VoidCallback onNewClip;

  const UnmeasuredScreen({
    super.key,
    required this.rejection,
    required this.onRetrim,
    required this.onNewClip,
  });

  /// What the athlete can actually do about each verdict.
  ///
  /// Keyed on the detector's own reason so the advice is never generic. Where
  /// trimming genuinely helps, it is named first, because that is the cheapest
  /// fix and the one most likely to work.
  (String, List<String>) get _diagnosis {
    switch (rejection) {
      case PoseDetectionRejection.noAirborneWindow:
        return (
          "We tracked you, but your feet never clearly left the floor.",
          [
            'Trim the clip so it holds the jump and a moment either side.',
            'Keep your feet in frame the whole time — they are what we time.',
            'Film from the side or straight on, not from above.',
          ],
        );
      case PoseDetectionRejection.tooManyMissing:
      case PoseDetectionRejection.noScaleReference:
        return (
          "We couldn't keep track of your body through the clip.",
          [
            'Get your whole body in frame, head to feet.',
            'More light helps — tracking struggles in a dim gym.',
            'Avoid a busy background directly behind you.',
          ],
        );
      case PoseDetectionRejection.gappyWindow:
        return (
          'We lost you in the middle of the jump itself.',
          [
            'Step back so your whole body stays in frame at the top.',
            'Hold the phone still — panning up with the jump loses you.',
            'Brighter light reduces the motion blur at takeoff.',
          ],
        );
      case PoseDetectionRejection.liftTooSmall:
        return (
          'The jump in this clip is too small to time reliably.',
          [
            'Trim to your best attempt if the clip holds several.',
            'Film a full-effort jump — a warm-up hop is below what we can time.',
          ],
        );
      case PoseDetectionRejection.implausibleDuration:
        return (
          'The flight time we measured is outside what a real jump can be.',
          [
            'Trim tightly around a single jump.',
            'Make sure the clip plays at normal speed — slow motion breaks the '
                'timing.',
          ],
        );
      case PoseDetectionRejection.tooFewSamples:
        return (
          'The clip is too short to read.',
          [
            'Include a moment before the jump and after the landing.',
          ],
        );
      case PoseDetectionRejection.none:
        return (
          "We couldn't measure this clip.",
          ['Trim tightly around a single jump and try again.'],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (headline, fixes) = _diagnosis;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NO MEASUREMENT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "We'd rather tell you than guess a number.",
              style: DunkTheme.onboardingSubtitle,
            ),
            const Spacer(),
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
            const Spacer(),
            PrimaryButton(
              label: 'TRIM AND TRY AGAIN',
              trailingIcon: Icons.content_cut,
              onPressed: onRetrim,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: onNewClip,
                child: const Text(
                  'Use a different clip',
                  style: TextStyle(
                    color: DunkColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

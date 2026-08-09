import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// A hand-built phone frame for the intro carousel.
///
/// What goes inside it is a live Flutter widget, never a screenshot: nothing
/// in this repo can take one (no Mac, no device in the loop), and a bundled
/// PNG would go stale the moment the real screen changed. The mocks are drawn
/// in the app's own [DunkColors] language instead, so they age with it.
class PhoneMockup extends StatelessWidget {
  /// The coordinate space every mock surface is authored in. The frame scales
  /// that design to whatever room the carousel gives it.
  static const Size designSize = Size(210, 440);

  final Widget child;

  const PhoneMockup({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: designSize.width / designSize.height,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFF141417),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: const Color(0xFF33333A), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
            // A trace of the app's own orange bouncing off the frame.
            BoxShadow(
              color: DunkColors.primary.withValues(alpha: 0.12),
              blurRadius: 60,
              spreadRadius: -12,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(31),
          child: ColoredBox(
            color: DunkColors.background,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox.fromSize(size: designSize, child: child),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 52,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

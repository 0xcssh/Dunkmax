import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';
import '../widgets/mock_app_screens.dart';
import '../widgets/phone_mockup.dart';
import '../widgets/staggered_entrance.dart';

/// The opening hook: three swipeable panels — measure, train, progress — each
/// showing the product itself inside a phone frame, then a single CTA into the
/// quiz.
///
/// This replaced the old single welcome screen: two full-screen hooks with two
/// CTAs before the first question is one hook too many, and its headline
/// ("TRAIN WITH A REAL PLAN") carries on as the second panel.
///
/// There is deliberately **no rating badge and no athlete count** here. The
/// reference app opens with "4.8 · 675+ ratings"; this app has no ratings and
/// no community, and invented social proof has already been removed from
/// onboarding twice. Sample numbers inside the phone are fine — that is a
/// picture of the product. Claims about other people are not.
class IntroCarouselScreen extends StatefulWidget {
  final VoidCallback onStart;

  const IntroCarouselScreen({super.key, required this.onStart});

  @override
  State<IntroCarouselScreen> createState() => _IntroCarouselScreenState();
}

class _IntroCarouselScreenState extends State<IntroCarouselScreen> {
  final _controller = PageController();

  static const _panels = <_Panel>[
    _Panel(
      headline: 'SEE YOUR REAL\nVERTICAL',
      support:
          'Film one jump. We time your flight frame by frame and turn it into '
          'inches — no tape measure, no guessing.',
      mock: AnalysisMock(),
    ),
    _Panel(
      headline: 'TRAIN WITH A\nREAL PLAN',
      support:
          'A week-by-week program matched to your level, your schedule and the '
          'gear you actually have.',
      mock: PlanMock(),
    ),
    _Panel(
      headline: 'WATCH THE\nINCHES ADD UP',
      support:
          'Every jump you film and every session you finish is logged, so '
          'progress is a number instead of a feeling.',
      mock: ProgressMock(),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The live scroll position, in pages. Reading [PageController.page] is only
  /// safe once the view has been laid out, hence the guard.
  double get _page {
    if (!_controller.hasClients) return 0;
    if (!_controller.position.hasContentDimensions) return 0;
    return _controller.page ?? 0;
  }

  /// Which dot is lit. Clamped explicitly so a rubber-band overscroll past
  /// either end never indexes outside the panel list.
  int get _currentPanel {
    final rounded = _page.round();
    if (rounded < 0) return 0;
    if (rounded > _panels.length - 1) return _panels.length - 1;
    return rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _panels.length,
                  // Rebuilds the dots; the panels animate off the controller
                  // directly.
                  onPageChanged: (_) => setState(() {}),
                  itemBuilder: (context, index) => AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => _PanelView(
                      panel: _panels[index],
                      offset: _page - index,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              StaggerItem(
                index: 2,
                child: _Dots(count: _panels.length, current: _currentPanel),
              ),
              const SizedBox(height: 22),
              StaggerItem(
                index: 3,
                child: PrimaryButton(
                  label: "LET'S START",
                  onPressed: widget.onStart,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel {
  final String headline;
  final String support;
  final Widget mock;

  const _Panel({
    required this.headline,
    required this.support,
    required this.mock,
  });
}

class _PanelView extends StatelessWidget {
  final _Panel panel;

  /// Distance from centre, in pages: 0 when this panel fills the screen.
  final double offset;

  const _PanelView({required this.panel, required this.offset});

  @override
  Widget build(BuildContext context) {
    final distance = offset.abs().clamp(0.0, 1.0).toDouble();
    // The phone drifts a little slower than the page and shrinks as it leaves,
    // so the panels read as depth rather than as a filmstrip.
    final scale = 1 - 0.08 * distance;
    final copyOpacity = 1 - distance;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Transform.translate(
              offset: Offset(offset * 26, 0),
              child: Transform.scale(
                scale: scale,
                child: StaggerItem(
                  index: 0,
                  child: PhoneMockup(child: panel.mock),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),
        Opacity(
          opacity: copyOpacity,
          child: StaggerItem(
            index: 1,
            child: Column(
              children: [
                Text(
                  panel.headline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    height: 1.06,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  panel.support,
                  textAlign: TextAlign.center,
                  style: DunkTheme.onboardingSubtitle,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int current;

  const _Dots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: 7,
            width: i == current ? 24 : 7,
            decoration: BoxDecoration(
              gradient: i == current ? DunkColors.primaryGradient : null,
              color: i == current ? null : DunkColors.surfaceRaised,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          if (i < count - 1) const SizedBox(width: 7),
        ],
      ],
    );
  }
}

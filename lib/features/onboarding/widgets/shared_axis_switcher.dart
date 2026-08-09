import 'package:flutter/material.dart';

/// A direction-aware page switch: the outgoing page slides and fades out one
/// way while the incoming page slides and fades in from the other — Material's
/// shared-axis motion, hand-rolled so we take no animation dependency.
///
/// Why not [AnimatedSwitcher]: it drives the outgoing child by *reversing* the
/// same transition it entered with, so a page always leaves the way it
/// arrived. That reads identically going forward and going back, which is
/// exactly the thing this replaces.
///
/// [child] must carry a [Key] — that key is what identifies a page, both for
/// deciding a transition is due and for keeping each page's state while the
/// two of them swap places in the stack.
class SharedAxisSwitcher extends StatefulWidget {
  final Widget child;

  /// True when the athlete is going *back*: the axis then runs the other way.
  final bool reverse;

  final Duration duration;

  const SharedAxisSwitcher({
    super.key,
    required this.child,
    this.reverse = false,
    this.duration = const Duration(milliseconds: 320),
  });

  @override
  State<SharedAxisSwitcher> createState() => _SharedAxisSwitcherState();
}

class _SharedAxisSwitcherState extends State<SharedAxisSwitcher>
    with SingleTickerProviderStateMixin {
  /// Starts settled at 1 so the very first page is already in place.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  )..addStatusListener(_onStatus);

  Widget? _outgoing;
  bool _reverse = false;

  @override
  void initState() {
    super.initState();
    assert(
      widget.child.key != null,
      'SharedAxisSwitcher needs a keyed child to tell pages apart.',
    );
  }

  @override
  void didUpdateWidget(covariant SharedAxisSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (oldWidget.child.key == widget.child.key) return;

    // No setState needed: a rebuild always follows didUpdateWidget.
    _outgoing = oldWidget.child;
    _reverse = widget.reverse;
    _controller.forward(from: 0);
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _outgoing == null) return;
    setState(() => _outgoing = null);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outgoing = _outgoing;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Both slots are the same widget type, keyed by their page, so the
        // page that becomes the outgoing one keeps its element (and its state)
        // as it moves position in this list.
        if (outgoing != null)
          _SharedAxisPage(
            key: outgoing.key,
            animation: _controller,
            reverse: _reverse,
            incoming: false,
            child: outgoing,
          ),
        _SharedAxisPage(
          key: widget.child.key,
          animation: _controller,
          reverse: _reverse,
          incoming: true,
          child: widget.child,
        ),
      ],
    );
  }
}

class _SharedAxisPage extends StatelessWidget {
  final Animation<double> animation;
  final bool incoming;
  final bool reverse;
  final Widget child;

  const _SharedAxisPage({
    super.key,
    required this.animation,
    required this.incoming,
    required this.reverse,
    required this.child,
  });

  /// Travel, as a fraction of the page width. Small on purpose: the fade does
  /// most of the work and a long slide just feels slow.
  static const double _shift = 0.13;

  @override
  Widget build(BuildContext context) {
    final direction = reverse ? -1.0 : 1.0;

    // Driven with `drive` rather than CurvedAnimation: these are rebuilt
    // whenever the switcher rebuilds, and drive() attaches no listener to the
    // controller, so there is nothing left behind to dispose.
    final slide = incoming
        ? animation.drive(
            Tween<Offset>(
              begin: Offset(_shift * direction, 0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
          )
        : animation.drive(
            Tween<Offset>(
              begin: Offset.zero,
              end: Offset(-_shift * direction, 0),
            ).chain(CurveTween(curve: Curves.easeInCubic)),
          );

    // Fade-through timing: the old page is gone before the new one is fully
    // in, so the two never muddy each other.
    final opacity = incoming
        ? animation.drive(
            Tween<double>(begin: 0, end: 1).chain(
              CurveTween(curve: const Interval(0.3, 1, curve: Curves.easeOut)),
            ),
          )
        : animation.drive(
            Tween<double>(begin: 1, end: 0).chain(
              CurveTween(curve: const Interval(0, 0.35, curve: Curves.easeIn)),
            ),
          );

    return IgnorePointer(
      // Only the page on its way out stops taking taps; the incoming page is
      // live from its first frame, so an animation never delays input.
      ignoring: !incoming,
      child: SlideTransition(
        position: slide,
        child: FadeTransition(opacity: opacity, child: child),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Plays a short arrival for one onboarding step: each [StaggerItem] beneath
/// it fades and lifts into place a beat after the one before it.
///
/// One controller for the whole step (not one per item), and it runs once, on
/// entry — a rebuild caused by the athlete tapping an option does not replay
/// it, because the state lives here and the step is re-keyed only when the
/// step itself changes.
class StaggeredEntrance extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const StaggeredEntrance({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 620),
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _StaggerScope(animation: _controller, child: widget.child);
  }
}

class _StaggerScope extends InheritedWidget {
  final Animation<double> animation;

  const _StaggerScope({required this.animation, required super.child});

  @override
  bool updateShouldNotify(_StaggerScope oldWidget) =>
      oldWidget.animation != animation;
}

/// One element of a [StaggeredEntrance]; lower [index] arrives first.
///
/// Outside a [StaggeredEntrance] it renders its child untouched, so any screen
/// using it still works on its own. It only ever changes opacity and offset —
/// it never gates hit testing, so a tap always lands even mid-arrival.
class StaggerItem extends StatelessWidget {
  final int index;
  final Widget child;

  const StaggerItem({super.key, required this.index, required this.child});

  /// Gap between two consecutive items, as a fraction of the whole run.
  static const double _step = 0.07;

  /// How much of the run a single item takes to arrive.
  static const double _span = 0.45;

  /// How far an item travels up into place.
  static const double _lift = 14;

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_StaggerScope>();
    if (scope == null) return child;

    final start = (index * _step).clamp(0.0, 1.0 - _span).toDouble();
    final interval = Interval(start, start + _span, curve: Curves.easeOutCubic);

    return AnimatedBuilder(
      animation: scope.animation,
      child: child,
      builder: (context, child) {
        final t = interval.transform(
          scope.animation.value.clamp(0.0, 1.0).toDouble(),
        );
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, _lift * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

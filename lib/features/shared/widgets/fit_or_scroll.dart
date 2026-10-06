import 'package:flutter/material.dart';

/// A column that takes exactly the height it is given when its content fits,
/// and becomes scrollable only when it does not.
///
/// This is the one layout primitive behind the "every screen on one page"
/// rule. On a phone where the content fits, nothing scrolls, bounces or shows
/// a scrollbar; on a shorter phone, a longer locale or a larger text setting
/// the athlete can still reach everything.
///
/// Two modes:
///
/// * default — children keep their natural heights from the top, and the
///   column is padded out to the viewport height;
/// * [FitOrScrollColumn.fill] — children may be `Expanded` / `Flexible` /
///   `Spacer`, and **grow into the spare height** of a tall screen, so a page
///   uses the whole screen instead of ending two thirds of the way down.
///   When the content does not fit, every flexible child falls back to its
///   natural (intrinsic) height and the column scrolls. Because that
///   fallback is measured with intrinsic sizes, children of a `fill` column
///   must support them: no `LayoutBuilder` (or anything else that cannot
///   report an intrinsic height) inside it. A flexible child that should
///   never collapse — a chart, a picker — states its floor with a
///   `ConstrainedBox(minHeight: …)`.
class FitOrScrollColumn extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final bool _fill;

  const FitOrScrollColumn({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.physics,
    this.controller,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
  }) : _fill = false;

  /// Flexible children share the spare height; see the class comment.
  const FitOrScrollColumn.fill({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.physics,
    this.controller,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
  }) : _fill = true;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      children: children,
    );
    if (_fill) {
      // SliverFillRemaining sizes its child to the larger of the viewport's
      // remaining height and the child's intrinsic height — exactly "fill
      // when it fits, natural and scrollable when it does not".
      return CustomScrollView(
        physics: physics,
        controller: controller,
        keyboardDismissBehavior: keyboardDismissBehavior,
        slivers: [
          // The padding goes inside the fill sliver, not around it: a
          // SliverPadding's trailing inset is added after the "remaining"
          // extent and would make every page scroll by exactly that much.
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(padding: padding, child: column),
          ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final inset = padding.resolve(Directionality.of(context));
        return SingleChildScrollView(
          padding: padding,
          physics: physics,
          controller: controller,
          keyboardDismissBehavior: keyboardDismissBehavior,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.hasBoundedHeight
                  ? (constraints.maxHeight - inset.vertical)
                      .clamp(0.0, double.infinity)
                  : 0,
            ),
            child: column,
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

/// A column that takes exactly the height it is given when its content fits,
/// and becomes scrollable only when it does not.
///
/// This is the one layout primitive behind the "every screen on one page"
/// rule. Screens size their content to fit the target phones; this widget is
/// the safety net for a longer locale, a larger text setting or an older,
/// shorter phone — the athlete can still reach everything, and on a phone
/// where it fits nothing scrolls, bounces or shows a scrollbar.
///
/// [spaceBetween] stretches the gaps so the last child (typically a CTA)
/// sits at the bottom when there is room to spare; otherwise children keep
/// their natural spacing from the top.
class FitOrScrollColumn extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  const FitOrScrollColumn({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.physics,
    this.controller,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
  });

  @override
  Widget build(BuildContext context) {
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
            child: Column(
              crossAxisAlignment: crossAxisAlignment,
              mainAxisAlignment: mainAxisAlignment,
              children: children,
            ),
          ),
        );
      },
    );
  }
}

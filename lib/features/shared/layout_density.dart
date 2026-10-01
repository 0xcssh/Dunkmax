import 'package:flutter/widgets.dart';

/// How much vertical room a screen has to work with.
///
/// Every screen is laid out to fit one page without scrolling on the 844 pt
/// class of phones (iPhone 12–15). Shorter phones — the 667 pt iPhone SE, the
/// 736 pt Plus models — get the same content with tighter spacing and slightly
/// smaller display type, chosen from [compact] metrics. The threshold is the
/// logical height of the whole window, insets included, so it does not move
/// when the keyboard opens.
enum LayoutDensity {
  regular,
  compact;

  static const double _compactBelow = 760;

  static LayoutDensity of(BuildContext context) =>
      MediaQuery.sizeOf(context).height < _compactBelow ? compact : regular;

  bool get isCompact => this == compact;

  /// Picks [regular] or [compact] in one expression.
  T pick<T>(T regular, T compact) => isCompact ? compact : regular;
}

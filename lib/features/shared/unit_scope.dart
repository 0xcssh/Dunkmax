import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';

import '../../core/units.dart';

// Every widget that asks for the scope also needs the conversions the enum's
// extension provides, so they travel together.
export '../../core/units.dart';

/// Makes the athlete's unit system available to every widget below it.
///
/// The system is decided **once, at startup, from the platform locale**
/// ([resolveFromPlatform]) — not from `Localizations.localeOf(context)`,
/// which is the locale `MaterialApp` *resolved* against the ones we ship and
/// so has usually lost its region (`fr_CA` becomes `fr`; `en_GB` becomes
/// `en`). The platform locale still carries the country, and the country is
/// what decides inches versus centimetres (see [UnitSystem.forRegion]).
///
/// Widget tests force either system by wrapping the tree in a [UnitScope].
/// A widget rendered with no scope above it (older tests, a stray preview)
/// falls back to the locale it is being rendered in, so a French tree reads
/// metric and an English one imperial without any test having to say so.
class UnitScope extends InheritedWidget {
  final UnitSystem system;

  const UnitScope({super.key, required this.system, required super.child});

  /// The unit system in force for [context].
  static UnitSystem of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<UnitScope>();
    if (scope != null) return scope.system;
    final locale = Localizations.maybeLocaleOf(context);
    if (locale == null) return UnitSystem.imperial;
    return UnitSystem.forRegion(locale.countryCode, locale.languageCode);
  }

  /// The unit system for this device, from the platform's own locale (the
  /// one with the region in it). Call it once at startup and hand the result
  /// to the app root.
  static UnitSystem resolveFromPlatform() {
    final locale = PlatformDispatcher.instance.locale;
    return UnitSystem.forRegion(locale.countryCode, locale.languageCode);
  }

  @override
  bool updateShouldNotify(UnitScope oldWidget) => system != oldWidget.system;
}

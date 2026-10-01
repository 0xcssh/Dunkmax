// The unit system reaches the screens: the same profile renders in
// centimetres and kilograms under a metric scope and in feet, inches and
// pounds under an imperial one — in either language, since the unit follows
// the region, not the locale.
import 'package:dunkmax/core/models/commitment_level.dart';
import 'package:dunkmax/core/models/court_position.dart';
import 'package:dunkmax/core/models/dunk_goal.dart';
import 'package:dunkmax/core/models/dunk_hand.dart';
import 'package:dunkmax/core/models/experience_level.dart';
import 'package:dunkmax/core/models/hops_level.dart';
import 'package:dunkmax/core/models/onboarding_profile.dart';
import 'package:dunkmax/core/models/training_location.dart';
import 'package:dunkmax/features/home/standing_reach_dialog.dart';
import 'package:dunkmax/features/onboarding/screens/gap_screen.dart';
import 'package:dunkmax/features/onboarding/screens/height_screen.dart';
import 'package:dunkmax/features/onboarding/screens/weight_screen.dart';
import 'package:dunkmax/features/onboarding/widgets/staggered_entrance.dart';
import 'package:dunkmax/features/shared/unit_scope.dart';
import 'package:dunkmax/l10n/app_localizations.dart';
import 'package:dunkmax/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 6'1", 180 lbs — 185 cm, 82 kg. Touch-the-rim hops: ~23" today, 29" to
// dunk — 58 cm and 74 cm.
const _profile = OnboardingProfile(
  goals: {DunkGoal.firstDunk},
  experience: ExperienceLevel.intermediate,
  position: CourtPosition.shootingGuard,
  daysPerWeek: 3,
  trainingLocation: TrainingLocation.both,
  hopsLevel: HopsLevel.touchRim,
  heightInches: 73,
  weightLbs: 180,
  ageYears: 22,
  dunkHand: DunkHand.right,
  commitment: CommitmentLevel.very,
);

Widget _host(Widget child, {required UnitSystem units, Locale? locale}) {
  return MaterialApp(
    theme: DunkTheme.build(),
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => UnitScope(system: units, child: child!),
    home: Scaffold(body: child),
  );
}

/// The onboarding backdrop animates forever, so pump fixed durations rather
/// than settling (see app_smoke_test.dart).
Future<void> _pump(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

void _noop() {}

void main() {
  setUp(() {
    // Enough room for the gap screen's whole page.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('gap screen', () {
    Widget screen() => const StaggeredEntrance(
          child: GapScreen(profile: _profile, onBack: _noop, onContinue: _noop),
        );

    testWidgets('imperial: inches and pounds', (tester) async {
      await _pump(tester, _host(screen(), units: UnitSystem.imperial));
      expect(find.textContaining("6'1\""), findsWidgets);
      expect(find.text('180 lbs'), findsOneWidget);
      expect(find.text('29"'), findsOneWidget); // dunk target row
      expect(find.text('~23"'), findsOneWidget); // meter: today
      expect(find.textContaining('cm'), findsNothing);
    });

    testWidgets('metric: centimetres and kilograms', (tester) async {
      await _pump(tester, _host(screen(), units: UnitSystem.metric));
      expect(find.textContaining('185 cm'), findsWidgets);
      expect(find.text('82 kg'), findsOneWidget);
      expect(find.text('74 cm'), findsOneWidget); // dunk target row
      expect(find.text('~58 cm'), findsOneWidget); // meter: today
      expect(find.textContaining('"'), findsNothing);
      expect(find.textContaining('lbs'), findsNothing);
    });

    testWidgets('metric French: the region decides, not the language',
        (tester) async {
      await _pump(
        tester,
        _host(screen(), units: UnitSystem.metric, locale: const Locale('fr')),
      );
      expect(find.text('82 kg'), findsOneWidget);
      expect(find.text('74 cm'), findsOneWidget);
      expect(find.textContaining(RegExp(r'\d po\b')), findsNothing);
      expect(find.textContaining(' lb'), findsNothing);
    });

    testWidgets('imperial French: inches spelt the French way',
        (tester) async {
      await _pump(
        tester,
        _host(screen(),
            units: UnitSystem.imperial, locale: const Locale('fr')),
      );
      expect(find.text('29 po'), findsOneWidget);
      expect(find.text('180 lb'), findsOneWidget);
      expect(find.textContaining('cm'), findsNothing);
    });
  });

  group('height screen', () {
    int? reported;
    Widget screen() => StaggeredEntrance(
          child: HeightScreen(
            step: 7,
            totalSteps: 11,
            heightInches: 73,
            onChanged: (v) => reported = v,
            onBack: _noop,
            onContinue: _noop,
          ),
        );

    testWidgets('imperial: feet and inches wheels', (tester) async {
      reported = null;
      await _pump(tester, _host(screen(), units: UnitSystem.imperial));
      expect(find.text("6' 1\""), findsOneWidget);
      expect(find.text('FEET & INCHES'), findsOneWidget);
      expect(find.text('6 ft'), findsOneWidget);
      expect(find.textContaining('cm'), findsNothing);
      // Two wheels.
      expect(find.byType(ListWheelScrollView), findsNWidgets(2));
    });

    testWidgets('metric: one centimetre wheel, reported in inches',
        (tester) async {
      reported = null;
      await _pump(tester, _host(screen(), units: UnitSystem.metric));
      expect(find.text('185 cm'), findsWidgets);
      expect(find.text('CENTIMETRES'), findsOneWidget);
      expect(find.textContaining('ft'), findsNothing);
      expect(find.textContaining('"'), findsNothing);
      expect(find.byType(ListWheelScrollView), findsOneWidget);

      // Scroll the wheel one notch (one centimetre) and check the value the
      // screen reports upward is still inches.
      await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -44));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(reported, isNotNull);
      expect(reported, UnitConversions.cmToInches(186));
    });
  });

  group('weight screen', () {
    int? reported;
    Widget screen() => StaggeredEntrance(
          child: WeightScreen(
            step: 8,
            totalSteps: 11,
            weightLbs: 180,
            onChanged: (v) => reported = v,
            onBack: _noop,
            onContinue: _noop,
          ),
        );

    testWidgets('imperial: a 75–300 lbs slider', (tester) async {
      reported = null;
      await _pump(tester, _host(screen(), units: UnitSystem.imperial));
      expect(find.text('180'), findsOneWidget);
      expect(find.text('LBS'), findsOneWidget);
      expect(find.text('75'), findsOneWidget);
      expect(find.text('300'), findsOneWidget);
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 180);
    });

    testWidgets('metric: a 35–150 kg slider that stores pounds',
        (tester) async {
      reported = null;
      await _pump(tester, _host(screen(), units: UnitSystem.metric));
      expect(find.text('82'), findsOneWidget);
      expect(find.text('KG'), findsOneWidget);
      expect(find.text('35'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
      expect(find.text('LBS'), findsNothing);
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 82);
      slider.onChanged!(90);
      expect(reported, UnitConversions.kgToLbs(90));
    });
  });

  group('standing-reach dialog', () {
    Future<int?> open(WidgetTester tester, UnitSystem units) async {
      int? result;
      await _pump(
        tester,
        _host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showStandingReachDialog(
                  context,
                  heightInches: 73,
                  currentReachInches: null,
                );
              },
              child: const Text('open'),
            ),
          ),
          units: units,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('imperial shows feet-and-inches plus inches, saves inches',
        (tester) async {
      final saved = await open(tester, UnitSystem.imperial);
      // 73" × 1.33 = 97" = 8'1".
      expect(saved, 97);
    });

    testWidgets('metric shows centimetres, still saves inches',
        (tester) async {
      int? result;
      await _pump(
        tester,
        _host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showStandingReachDialog(
                  context,
                  heightInches: 73,
                  currentReachInches: null,
                );
              },
              child: const Text('open'),
            ),
          ),
          units: UnitSystem.metric,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('246 cm'), findsWidgets);
      expect(find.textContaining(' in'), findsNothing);
      expect(find.textContaining("'"), findsNothing);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(result, UnitConversions.cmToInches(246));
    });
  });
}

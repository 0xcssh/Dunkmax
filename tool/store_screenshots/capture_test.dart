// Raw App Store captures: the real screens, rendered by the real widgets.
//
// Not part of the suite — it only runs when STORE_SHOTS_DIR is set:
//
//   STORE_SHOTS_DIR=<dir> flutter test tool/store_screenshots/capture_test.dart
//
// Writes <dir>/<device>/<locale>/<screen>.png at the store's native pixel
// sizes (iPhone 6.9" 1320x2868, iPad 13" 2064x2752). The marketing frames
// (caption, background, device) are composed on top of these by
// tool/store_screenshots/compose.py, so every pixel of UI in the listing is
// what the app actually draws.
//
// The athlete is a demo profile with demo history — a picture of the product,
// not a claim about anyone. Nothing here is a rating, a user count or another
// athlete's result.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dunkmax/core/jump_analysis_pipeline.dart';
import 'package:dunkmax/core/jump_form_scores.dart';
import 'package:dunkmax/core/jump_result.dart';
import 'package:dunkmax/core/jump_trend.dart';
import 'package:dunkmax/core/models/commitment_level.dart';
import 'package:dunkmax/core/models/court_position.dart';
import 'package:dunkmax/core/models/dunk_goal.dart';
import 'package:dunkmax/core/models/dunk_hand.dart';
import 'package:dunkmax/core/models/experience_level.dart';
import 'package:dunkmax/core/models/hops_level.dart';
import 'package:dunkmax/core/models/jump_log_entry.dart';
import 'package:dunkmax/core/models/jump_measurement.dart';
import 'package:dunkmax/core/models/onboarding_profile.dart';
import 'package:dunkmax/core/models/training_location.dart';
import 'package:dunkmax/core/models/video_attempt_type.dart';
import 'package:dunkmax/core/models/workout_session.dart';
import 'package:dunkmax/core/pose_jump_detector.dart';
import 'package:dunkmax/core/program_catalog.dart';
import 'package:dunkmax/core/training_schedule.dart';
import 'package:dunkmax/core/vert_assessment.dart';
import 'package:dunkmax/features/analyze/screens/jump_result_screen.dart';
import 'package:dunkmax/features/analyze/screens/processing_screen.dart';
import 'package:dunkmax/features/analyze/screens/source_screen.dart';
import 'package:dunkmax/features/home/root_shell.dart';
import 'package:dunkmax/features/onboarding/screens/gap_screen.dart';
import 'package:dunkmax/features/onboarding/screens/plan_reveal_screen.dart';
import 'package:dunkmax/features/onboarding/screens/potential_screen.dart';
import 'package:dunkmax/features/onboarding/widgets/staggered_entrance.dart';
import 'package:dunkmax/features/shared/unit_scope.dart';
import 'package:dunkmax/features/train/screens/exercise_detail_screen.dart';
import 'package:dunkmax/features/train/screens/log_exercise_screen.dart';
import 'package:dunkmax/l10n/app_localizations.dart';
import 'package:dunkmax/services/athlete_profile_store.dart';
import 'package:dunkmax/services/jump_log_store.dart';
import 'package:dunkmax/services/leaderboard_service.dart';
import 'package:dunkmax/services/workout_session_store.dart';
import 'package:dunkmax/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test/fixtures/run_up_away_capture.dart';

final String? _outDir = Platform.environment['STORE_SHOTS_DIR'];

class _Device {
  final String name;
  final Size logical;
  final double dpr;
  final double top;
  final double bottom;
  const _Device(this.name, this.logical, this.dpr,
      {required this.top, required this.bottom});
}

const _devices = [
  // iPhone 16/17 Pro Max: 440x956 pt @3x = 1320x2868, the 6.9" store size.
  _Device('iphone69', Size(440, 956), 3, top: 62, bottom: 34),
  // iPad Pro 13": 1032x1376 pt @2x = 2064x2752, the 13" store size.
  _Device('ipad13', Size(1032, 1376), 2, top: 24, bottom: 20),
];

/// One capture set per UI language × unit system. The store locales map onto
/// these in compose.py: en-US → en-US; every other English or untranslated
/// store (GB, CA, AU, es, de, it, pt-BR) → en-metric; fr-* → fr.
const _variants = [
  (Locale('en'), UnitSystem.imperial, 'en-US'),
  (Locale('en'), UnitSystem.metric, 'en-metric'),
  (Locale('fr'), UnitSystem.metric, 'fr'),
];

const _profile = OnboardingProfile(
  goals: {DunkGoal.firstDunk, DunkGoal.dunkInGames},
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

final _program = ProgramCatalog.recommend(_profile);

DateTime _daysAgo(int days, [int hour = 18]) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - days, hour);
}

/// A believable six-week arc: 22" → 27".
final _jumpEntries = [
  for (final (days, inches) in [(40, 22), (30, 23), (21, 25), (12, 26), (1, 27)])
    JumpLogEntry(
      verticalInches: inches,
      recordedAt: _daysAgo(days, 10),
      attemptType: VideoAttemptType.jumpAttempt,
    ),
];

/// 0.748 s in the air = 27.0" by h = g·t²/8.
const _measurement = JumpMeasurement(
  takeoff: Duration(milliseconds: 1000),
  landing: Duration(milliseconds: 1748),
);

final _scores = JumpFormScores(
  bounce: FormScore.measured('Bounce', 78, '0.21 s on the floor before takeoff'),
  power: FormScore.measured(
      'Power', 74, 'dip 0.31× torso, driving up at 9.4× torso/s'),
  control: FormScore.measured(
      'Control', 86, 'hips 0.04× torso off level · torso 6° off vertical'),
  form: FormScore.measured(
      'Form', 91, 'arm swing 2.10× torso, peaking right at takeoff'),
  takeoffType: TakeoffType.twoFoot,
);

Future<List<PoseSample>> _sampleCapture(List<Duration> timestamps) async {
  final frames = runUpAwayCapture();
  return [
    for (final t in timestamps)
      () {
        final f = frames.firstWhere((f) => f.timestamp >= t,
            orElse: () => frames.last);
        return PoseSample(
          timestamp: t,
          foot: f.foot,
          footY: f.footY,
          torsoPixels: f.torsoPixels,
          leftAnkle: f.leftAnkle,
          rightAnkle: f.rightAnkle,
          leftKnee: f.leftKnee,
          rightKnee: f.rightKnee,
          leftHip: f.leftHip,
          rightHip: f.rightHip,
          leftShoulder: f.leftShoulder,
          rightShoulder: f.rightShoulder,
          leftWrist: f.leftWrist,
          rightWrist: f.rightWrist,
        );
      }(),
  ];
}

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ??
      Directory(Platform.resolvedExecutable)
          .parent
          .parent
          .parent
          .parent
          .parent
          .parent
          .path;
  final fonts = '$root/bin/cache/artifacts/material_fonts';
  // 'FlutterTest' is the harness's default family: a RichText (which does not
  // inherit the theme's text style) would otherwise draw 1-em boxes.
  for (final family in ['Roboto', 'FlutterTest']) {
    final loader = FontLoader(family);
    for (final f in [
      'test/fonts/roboto-regular.ttf',
      'test/fonts/roboto-medium.ttf',
      'test/fonts/roboto-bold.ttf',
      'test/fonts/roboto-black.ttf',
    ]) {
      final file =
          File(f).existsSync() ? File(f) : File('$fonts/${f.split('/').last}');
      if (file.existsSync()) {
        loader
            .addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
      }
    }
    await loader.load();
  }
  final icons = File('$fonts/materialicons-regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(icons.readAsBytesSync().buffer.asByteData()));
    await loader.load();
  } else {
    // ignore: avoid_print
    print('capture: MaterialIcons not found under $fonts — icons will be boxes');
  }
}

Widget _host(Widget child, Locale locale, UnitSystem units,
    {bool scaffold = true}) {
  final theme = DunkTheme.build();
  final app = MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme.copyWith(
      textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
      primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Roboto'),
    ),
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: scaffold ? Scaffold(body: child) : child,
  );
  return UnitScope(system: units, child: app);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

Future<void> _shoot(
  WidgetTester tester,
  String name,
  Widget Function(Locale locale) build, {
  bool scaffold = true,
  Future<void> Function(WidgetTester tester, _Device device)? after,
}) async {
  for (final device in _devices) {
    for (final (locale, units, tag) in _variants) {
      tester.view.physicalSize = device.logical * device.dpr;
      tester.view.devicePixelRatio = device.dpr;
      tester.view.padding = FakeViewPadding(
        top: device.top * device.dpr,
        bottom: device.bottom * device.dpr,
      );
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: _host(build(locale), locale, units, scaffold: scaffold),
      ));
      await _settle(tester);
      if (after != null) {
        await after(tester, device);
        await _settle(tester);
      }
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: device.dpr);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final dir = Directory('$_outDir/${device.name}/$tag')
          ..createSync(recursive: true);
        File('${dir.path}/$name.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }
  }
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
  tester.view.resetPadding();
}

void main() {
  final skip = _outDir == null || _outDir!.isEmpty;
  late JumpAnalysis analysis;

  setUpAll(() async {
    if (skip) return;
    await _loadFonts();
    const clip = Duration(milliseconds: 4035);
    final pose = await JumpAnalysisPipeline.run(
      rangeStart: Duration.zero,
      rangeEnd: clip,
      clipDuration: clip,
      sample: _sampleCapture,
    );
    analysis = JumpAnalysis(pose: pose, scores: _scores);
  });

  void noop() {}

  testWidgets('store captures', skip: skip, (tester) async {
    final result = JumpResult(
      measurement: _measurement,
      assessment: VertAssessment(
        heightInches: _profile.heightInches,
        ageYears: _profile.ageYears,
        hops: _profile.hopsLevel,
        measuredStandingReach: _profile.standingReachInches,
        dunkHand: _profile.dunkHand,
      ),
    );
    await _shoot(
      tester,
      'result',
      (_) => JumpResultScreen(
        result: result,
        trend: JumpTrendCalculator.compute(_jumpEntries),
        analysis: analysis,
        attemptType: VideoAttemptType.jumpAttempt,
        onAnalyzeAnother: noop,
      ),
    );
    await _shoot(tester, 'source',
        (_) => SourceScreen(onVideoSelected: (_, __) {}, onSkip: noop));
    await _shoot(
        tester,
        'gap',
        (_) => StaggeredEntrance(
            child: GapScreen(profile: _profile, onBack: noop, onContinue: noop)));
    await _shoot(
        tester,
        'potential',
        (_) => StaggeredEntrance(
            child: PotentialScreen(
                profile: _profile, onBack: noop, onContinue: noop)));
    await _shoot(
        tester,
        'plan',
        (_) => StaggeredEntrance(
            child: PlanRevealScreen(
                profile: _profile, onBack: noop, onContinue: noop)));
    final day = TrainingSchedule(_program).prescriptionForSession(4);
    await _shoot(
      tester,
      'log',
      (_) => LogExerciseScreen(
        exercise: day.exercises.first,
        exerciseIndex: 0,
        totalExercises: day.exercises.length,
        onLogged: (_) {},
        onClose: noop,
      ),
    );
    await _shoot(tester, 'exercise',
        (_) => ExerciseDetailScreen(exercise: day.exercises.first),
        scaffold: false);

    // A test helper by design; this file is a test run by `flutter test`.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    final sessionStore = await WorkoutSessionStore.load();
    for (var i = 0; i < 4; i++) {
      final when = _daysAgo([6, 3, 2, 1][i]);
      await sessionStore.addSession(WorkoutSession(
        programId: _program.id,
        sessionNumber: i + 1,
        completedAt: when,
        exercises: const [
          LoggedExercise(exerciseId: 'x', exerciseName: 'Depth Jumps', sets: [
            LoggedSet(setNumber: 1, reps: 6),
            LoggedSet(setNumber: 2, reps: 6),
          ]),
        ],
      ));
    }
    final jumpLogStore = await JumpLogStore.load();
    for (final e in _jumpEntries) {
      await jumpLogStore.addEntry(e);
    }
    final athleteProfileStore = await AthleteProfileStore.load();
    await athleteProfileStore.setDisplayName('Marcus');
    final leaderboardService = LeaderboardService();
    await leaderboardService.initialize();

    Widget shell(Locale _) => RootShell(
          profile: _profile,
          sessionStore: sessionStore,
          jumpLogStore: jumpLogStore,
          athleteProfileStore: athleteProfileStore,
          leaderboardService: leaderboardService,
          onRestartOnboarding: noop,
          onProfileChanged: (_) {},
        );

    Future<void> Function(WidgetTester, _Device) tapTab(int index) =>
        (tester, device) async {
          final size = device.logical;
          await tester.tapAt(Offset(
            size.width * (index + 0.5) / 5,
            size.height - device.bottom - 24,
          ));
        };

    for (final (i, name) in [
      (0, 'home'),
      (1, 'analyze'),
      (2, 'train'),
      (3, 'feed'),
      (4, 'progress'),
    ]) {
      await _shoot(tester, 'tab_$name', shell,
          scaffold: false, after: tapTab(i));
    }
  });
}

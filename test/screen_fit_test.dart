// Every screen on one page.
//
// Pumps each screen of the app at the two target phone sizes, in both
// locales, with realistic data, and checks two things: (a) nothing overflows
// its RenderFlex, anywhere; (b) at 390x844 (iPhone 12-15, the primary
// target) no vertical scrollable has content past its viewport — except the
// screens listed in [_mayScroll], whose content is legitimately longer than a
// page. The 375x667 iPhone SE is probed and reported, not asserted: fitting
// it is best effort and must never cost the primary layout.
//
// Text metrics matter here, so the SDK's Roboto is loaded instead of the test
// harness's box font (every glyph 1 em wide, which wraps every line early).
// If the font cannot be found the assertions are skipped and the run only
// reports, so a bare CI cache cannot fail the suite for the wrong reason.
//
// Set DUNKMAX_SCREENSHOTS=<dir> to also get one PNG per screen/size/locale.
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
import 'package:dunkmax/features/analyze/screens/trim_screen.dart';
import 'package:dunkmax/features/analyze/screens/unmeasured_screen.dart';
import 'package:dunkmax/features/analyze/analyze_flow.dart';
import 'package:dunkmax/features/feed/feed_tab.dart';
import 'package:dunkmax/features/home/root_shell.dart';
import 'package:dunkmax/features/home/tabs/home_tab.dart';
import 'package:dunkmax/features/home/tabs/progress_tab.dart';
import 'package:dunkmax/features/home/tabs/train_tab.dart';
import 'package:dunkmax/features/onboarding/screens/age_screen.dart';
import 'package:dunkmax/features/onboarding/screens/building_plan_screen.dart';
import 'package:dunkmax/features/onboarding/screens/commitment_screen.dart';
import 'package:dunkmax/features/onboarding/screens/days_per_week_screen.dart';
import 'package:dunkmax/features/onboarding/screens/dunk_hand_screen.dart';
import 'package:dunkmax/features/onboarding/screens/experience_screen.dart';
import 'package:dunkmax/features/onboarding/screens/gap_screen.dart';
import 'package:dunkmax/features/onboarding/screens/goal_screen.dart';
import 'package:dunkmax/features/onboarding/screens/height_screen.dart';
import 'package:dunkmax/features/onboarding/screens/hops_screen.dart';
import 'package:dunkmax/features/onboarding/screens/intro_carousel_screen.dart';
import 'package:dunkmax/features/onboarding/screens/plan_reveal_screen.dart';
import 'package:dunkmax/features/onboarding/screens/position_screen.dart';
import 'package:dunkmax/features/onboarding/screens/potential_screen.dart';
import 'package:dunkmax/features/onboarding/screens/training_location_screen.dart';
import 'package:dunkmax/features/onboarding/screens/weight_screen.dart';
import 'package:dunkmax/features/onboarding/widgets/staggered_entrance.dart';
import 'package:dunkmax/features/paywall/paywall_screen.dart';
import 'package:dunkmax/features/shared/widgets/primary_button.dart';
import 'package:dunkmax/features/progress/jump_history_screen.dart';
import 'package:dunkmax/features/progress/jump_video_screen.dart';
import 'package:dunkmax/features/train/screens/exercise_detail_screen.dart';
import 'package:dunkmax/features/train/screens/log_exercise_screen.dart';
import 'package:dunkmax/features/train/screens/session_complete_screen.dart';
import 'package:dunkmax/features/train/screens/warmup_screen.dart';
import 'package:dunkmax/l10n/app_localizations.dart';
import 'package:dunkmax/services/athlete_profile_store.dart';
import 'package:dunkmax/services/jump_log_store.dart';
import 'package:dunkmax/services/leaderboard_service.dart';
import 'package:dunkmax/services/subscription_service.dart';
import 'package:dunkmax/services/workout_session_store.dart';
import 'package:dunkmax/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/run_up_away_capture.dart';

/// Logical size plus the real safe-area insets of each device — the status
/// bar / Dynamic Island above and the home indicator below both eat into the
/// height a screen actually gets.
class _Device {
  final Size size;
  final double top;
  final double bottom;
  const _Device(this.size, {required this.top, required this.bottom});
}

const _primaryDevice = 'iPhone15';

const _sizes = {
  _primaryDevice: _Device(Size(390, 844), top: 59, bottom: 34),
  'iPhoneSE': _Device(Size(375, 667), top: 20, bottom: 0),
};

/// Screens whose content is legitimately longer than a page; they are
/// allowed a vertical scroll on the primary device. Everything else must fit.
const _mayScroll = {
  // Four score cards, the written breakdown, the detection details.
  'Result',
  // The full authored guide: steps, mistakes, muscles, equipment.
  'ExerciseDetail',
};

/// Whether the real font loaded. Without it the verdicts are pessimistic
/// (see the file comment) and are only reported, never asserted.
bool _assertionsOn = false;

/// The test harness's default font draws every glyph as a 1 em box, which is
/// nearly twice as wide as real text and makes every line wrap early. Load
/// Roboto from the SDK's material_fonts cache instead — close enough to SF
/// Pro's metrics to make the wrap and overflow verdicts meaningful.
Future<void> _loadRealFont() async {
  Directory? root;
  // Checked in under test/fonts (Apache-2.0, see the LICENSE beside them), so
  // the verdicts are the same on every machine: a CI runner without the SDK's
  // material_fonts cache used to fall back to the box font, and three rows
  // that fit on a phone "overflowed" there.
  final bundled = Directory('test/fonts');
  if (bundled.existsSync()) root = bundled;
  // flutter_tester lives at <sdk>/bin/cache/artifacts/engine/<platform>/.
  var dir = Directory(Platform.resolvedExecutable).parent;
  for (var i = 0; root == null && i < 8; i++) {
    final candidate =
        Directory('${dir.path}/bin/cache/artifacts/material_fonts');
    if (candidate.existsSync()) {
      root = candidate;
      break;
    }
    dir = dir.parent;
  }
  if (root == null) {
    final env = Platform.environment['FLUTTER_ROOT'];
    if (env != null) {
      root = Directory('$env/bin/cache/artifacts/material_fonts');
    }
  }
  if (root == null || !root.existsSync()) {
    // ignore: avoid_print
    print('screen_fit: Roboto not found under the SDK cache; '
        'reporting only, not asserting');
    return;
  }
  final loader = FontLoader('Roboto');
  var added = 0;
  for (final file in [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-black.ttf',
  ]) {
    final f = File('${root.path}/$file');
    if (!f.existsSync()) continue;
    final bytes = f.readAsBytesSync();
    loader.addFont(Future.value(bytes.buffer.asByteData()));
    added++;
  }
  if (added == 0) return;
  await loader.load();
  _assertionsOn = true;
}

const _locales = [Locale('en'), Locale('fr')];

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

final _jumpEntries = [
  JumpLogEntry(
    verticalInches: 24,
    recordedAt: DateTime(2026, 9, 1, 10),
    attemptType: VideoAttemptType.jumpAttempt,
  ),
  JumpLogEntry(
    verticalInches: 27,
    recordedAt: DateTime(2026, 9, 15, 10),
    attemptType: VideoAttemptType.dunkAttempt,
  ),
  JumpLogEntry(
    verticalInches: 29,
    recordedAt: DateTime(2026, 9, 28, 10),
    attemptType: VideoAttemptType.dunkAttempt,
  ),
];

Future<List<PoseSample>> _sampleCapture(List<Duration> timestamps) async {
  final frames = runUpAwayCapture();
  return [
    for (final t in timestamps)
      () {
        final f = frames.firstWhere(
          (f) => f.timestamp >= t,
          orElse: () => frames.last,
        );
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

/// The real capture fixture run through the real pipeline, so the result
/// screen shows the scores and breakdown a real clip produces.
Future<JumpAnalysis> _realAnalysis() async {
  const clip = Duration(milliseconds: 4035);
  final pose = await JumpAnalysisPipeline.run(
    rangeStart: Duration.zero,
    rangeEnd: clip,
    clipDuration: clip,
    sample: _sampleCapture,
  );
  return JumpAnalysis(
      pose: pose, scores: JumpFormScoring.fromDiagnostics(pose));
}

/// Collected per probe: every line is one finding.
final List<String> _report = [];

/// The findings that fail the test; drained by [_expectAllFit] at the end of
/// each test so every screen in the group is still probed and reported.
final List<String> _failures = [];

void _expectAllFit() {
  final failures = [..._failures];
  _failures.clear();
  expect(failures, isEmpty,
      reason: 'Screens that must fit one page do not:\n${failures.join('\n')}');
}

/// Set `DUNKMAX_SCREENSHOTS=<dir>` to also write one PNG per screen, size
/// and locale — a way to eyeball a layout without a device.
final String? _screenshotDir = () {
  final dir = Platform.environment['DUNKMAX_SCREENSHOTS'];
  if (dir == null || dir.isEmpty) return null;
  Directory(dir).createSync(recursive: true);
  return dir;
}();

/// Wraps [child] like the app does: theme, locales, a Scaffold for screens
/// that have none of their own.
Widget _host(Widget child, Locale locale, {bool scaffold = true}) {
  final theme = DunkTheme.build();
  return MaterialApp(
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
}

Future<void> _pumpFixed(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

/// Pumps [build] at every size and locale and records the verdict.
Future<void> _probe(
  WidgetTester tester,
  String name,
  Widget Function(Locale locale, String device) build, {
  bool scaffold = true,
  Future<void> Function(WidgetTester tester)? after,
  _Anchor? fillAnchor,
}) async {
  for (final size in _sizes.entries) {
    for (final locale in _locales) {
      tester.view.physicalSize = size.value.size;
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = FakeViewPadding(
        top: size.value.top,
        bottom: size.value.bottom,
      );
      final overflows = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        final text = details.exceptionAsString();
        if (text.contains('overflowed')) {
          overflows.add(text.split('\n').first);
        } else {
          previous?.call(details);
        }
      };
      final boundaryKey = GlobalKey();
      try {
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: _host(build(locale, size.key), locale, scaffold: scaffold),
          ),
        );
        await _pumpFixed(tester);
        if (after != null) {
          await after(tester);
          await _pumpFixed(tester);
        }
      } finally {
        FlutterError.onError = previous;
      }
      if (_screenshotDir != null) {
        await tester.runAsync(() async {
          final boundary = boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final safeName = name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
          File('$_screenshotDir/${safeName}_${size.key}_${locale.languageCode}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
      final scrolls = <String>[];
      for (final state
          in tester.stateList<ScrollableState>(find.byType(Scrollable))) {
        final pos = state.position;
        if (!pos.hasContentDimensions || !pos.hasViewportDimension) continue;
        if (pos.axis != Axis.vertical) continue;
        if (pos.maxScrollExtent <= 0.5) continue;
        final isWheel = state.context
                .findAncestorWidgetOfExactType<ListWheelScrollView>() !=
            null;
        if (isWheel) continue;
        scrolls.add('${pos.maxScrollExtent.toStringAsFixed(0)}px over '
            '${pos.viewportDimension.toStringAsFixed(0)}px');
      }
      final tag = '$name @${size.key}/${locale.languageCode}';
      if (fillAnchor != null && size.key == _primaryDevice) {
        final anchorY = fillAnchor(tester, size.value);
        final bottom = _contentBottomAbove(tester, anchorY);
        final gap = anchorY - bottom;
        final line = '${gap <= _maxFillGap ? 'FILLS   ' : 'PROBLEM '} $tag '
            'gap ${gap.toStringAsFixed(0)}px above the '
            '${fillAnchor == _tabBarAnchor ? 'tab bar' : 'CTA'}';
        _report.add(line);
        if (_assertionsOn && gap > _maxFillGap) _failures.add(line);
      }
      final scrollAllowed = _mayScroll.contains(name);
      if (overflows.isEmpty && scrolls.isEmpty) {
        _report.add('FIT      $tag');
      } else if (overflows.isEmpty && scrollAllowed) {
        _report.add('SCROLLS  $tag (allowed) ${scrolls.join(', ')}');
      } else {
        final line = 'PROBLEM  $tag'
            '${overflows.isEmpty ? '' : ' OVERFLOW: ${overflows.toSet().join(' | ')}'}'
            '${scrolls.isEmpty ? '' : ' SCROLL: ${scrolls.join(', ')}'}';
        _report.add(line);
        // Overflow fails everywhere; a scroll fails only on the primary
        // device (the SE is best effort, see the file comment).
        if (_assertionsOn &&
            (overflows.isNotEmpty || size.key == _primaryDevice)) {
          _failures.add(line);
        }
      }
      // Tear the tree down so controllers/tickers from this run are gone
      // before the next size.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }
  }
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
  tester.view.resetPadding();
}

Widget _onboarding(Widget screen) => StaggeredEntrance(child: screen);

/// Where a page's content is expected to reach, in global y: the top of the
/// pinned CTA, or the top of the tab bar.
typedef _Anchor = double Function(WidgetTester tester, _Device device);

/// "Uses the whole screen": the last painted content above the anchor must
/// end within this many pixels of it on the primary device. The owner's
/// complaint was pages that ended at ~70 % of the height with an empty band
/// above the tab bar — that is a gap of 150 px+, not a margin.
const double _maxFillGap = 48;

double _ctaAnchor(WidgetTester tester, _Device device) =>
    tester.getRect(find.byType(PrimaryButton).last).top;

/// Height of RootShell's floating tab bar, measured from the real shell per
/// device by the tab test; the tab screens are pumped above a spacer of it.
final Map<Size, double> _tabBarHeights = {};

double _tabBarAnchor(WidgetTester tester, _Device device) =>
    device.size.height - _tabBarHeights[device.size]!;

/// The lowest bottom edge of anything painted that ends above [anchorY]:
/// text, icons, images, decorated boxes, custom paint. Full-screen layers
/// (the court backdrop, the Scaffold) end below the anchor and so never
/// count; a picker wheel counts as its viewport, not its off-screen rows.
double _contentBottomAbove(WidgetTester tester, double anchorY) {
  var lowest = 0.0;
  void visit(RenderObject node) {
    if (node is RenderBox && node.hasSize && node.attached) {
      final painted = node is RenderParagraph ||
          node is RenderImage ||
          node is RenderEditable ||
          node is RenderListWheelViewport ||
          (node is RenderDecoratedBox &&
              node.decoration is BoxDecoration &&
              ((node.decoration as BoxDecoration).color != null ||
                  (node.decoration as BoxDecoration).gradient != null ||
                  (node.decoration as BoxDecoration).border != null)) ||
          (node is RenderCustomPaint && node.painter != null);
      if (painted && node.size.height > 0) {
        final rect = MatrixUtils.transformRect(
            node.getTransformTo(null), Offset.zero & node.size);
        if (rect.bottom <= anchorY + 0.5 && rect.bottom > lowest) {
          lowest = rect.bottom;
        }
      }
      if (node is RenderListWheelViewport) return;
    }
    node.visitChildren(visit);
  }

  visit(tester.binding.renderViews.first);
  return lowest;
}

void main() {
  late JumpAnalysis analysis;
  late JumpResult result;

  setUpAll(() async {
    await _loadRealFont();
    analysis = await _realAnalysis();
    result = JumpResult(
      measurement: analysis.measurement!,
      assessment: VertAssessment(
        heightInches: _profile.heightInches,
        ageYears: _profile.ageYears,
        hops: _profile.hopsLevel,
        measuredStandingReach: _profile.standingReachInches,
        dunkHand: _profile.dunkHand,
      ),
    );
  });

  // The per-screen verdicts, printed once so a CI log shows the whole
  // picture (including the best-effort SE lines, which never fail).
  tearDownAll(() {
    final buffer = StringBuffer('\n===== SCREEN FIT REPORT '
        '(${_assertionsOn ? 'asserted' : 'report only: no Roboto'}) =====\n');
    for (final line in _report) {
      buffer.writeln(line);
    }
    buffer.writeln('===== END =====');
    // ignore: avoid_print
    print(buffer);
  });

  void noop() {}

  testWidgets('onboarding screens', (tester) async {
    await _probe(tester, 'Intro',
        (_, __) => _onboarding(IntroCarouselScreen(onStart: noop)));
    await _probe(
        tester,
        'Goal',
        (_, __) => _onboarding(GoalScreen(
              step: 1,
              totalSteps: 11,
              selected: const {DunkGoal.firstDunk},
              onToggle: (_) {},
              onBack: noop,
              onContinue: noop,
            )),
        fillAnchor: _ctaAnchor);
    await _probe(
        tester,
        'Experience',
        (_, __) => _onboarding(ExperienceScreen(
              step: 2,
              totalSteps: 11,
              selected: ExperienceLevel.intermediate,
              onSelect: (_) {},
              onBack: noop,
              onContinue: noop,
            )),
        fillAnchor: _ctaAnchor);
    await _probe(
        tester,
        'Position',
        (_, __) => _onboarding(PositionScreen(
              step: 3,
              totalSteps: 11,
              selected: CourtPosition.shootingGuard,
              onSelect: (_) {},
              onBack: noop,
              onContinue: noop,
            )),
        fillAnchor: _ctaAnchor);
    await _probe(
        tester,
        'Days',
        (_, __) => _onboarding(DaysPerWeekScreen(
              step: 4,
              totalSteps: 11,
              selected: 3,
              onSelect: (_) {},
              onBack: noop,
              onContinue: noop,
            )),
        fillAnchor: _ctaAnchor);
    await _probe(
        tester,
        'Location',
        (_, __) => _onboarding(TrainingLocationScreen(
              step: 5,
              totalSteps: 11,
              selected: TrainingLocation.both,
              onSelect: (_) {},
              onBack: noop,
              onContinue: noop,
            )),
        fillAnchor: _ctaAnchor);
    await _probe(
        tester,
        'Hops',
        (_, __) => _onboarding(HopsScreen(
              step: 6,
              totalSteps: 11,
              selected: HopsLevel.touchRim,
              onSelect: (_) {},
              onBack: noop,
              onContinue: noop,
            )),
        fillAnchor: _ctaAnchor);
    await _probe(
        tester,
        'Height',
        (_, __) => _onboarding(HeightScreen(
              step: 7,
              totalSteps: 11,
              heightInches: 73,
              onChanged: (_) {},
              onBack: noop,
              onContinue: noop,
            )),
        fillAnchor: _ctaAnchor);
    await _probe(
        tester,
        'Weight',
        (_, __) => _onboarding(WeightScreen(
              step: 8,
              totalSteps: 11,
              weightLbs: 180,
              onChanged: (_) {},
              onBack: noop,
              onContinue: noop,
            )),
        fillAnchor: _ctaAnchor);
    await _probe(
        tester,
        'Age',
        (_, __) => _onboarding(AgeScreen(
              step: 9,
              totalSteps: 11,
              ageYears: 22,
              onChanged: (_) {},
              onBack: noop,
              onContinue: noop,
            )),
        fillAnchor: _ctaAnchor);
    await _probe(
        tester,
        'DunkHand',
        (_, __) => _onboarding(DunkHandScreen(
              step: 10,
              totalSteps: 11,
              selected: DunkHand.right,
              onSelect: (_) {},
              onBack: noop,
              onContinue: noop,
            )),
        fillAnchor: _ctaAnchor);
    await _probe(
        tester,
        'Commitment',
        (_, __) => _onboarding(CommitmentScreen(
              step: 11,
              totalSteps: 11,
              selected: CommitmentLevel.very,
              onSelect: (_) {},
              onBack: noop,
              onContinue: noop,
            )),
        fillAnchor: _ctaAnchor);
    await _probe(
        tester,
        'Gap',
        (_, __) => _onboarding(
            GapScreen(profile: _profile, onBack: noop, onContinue: noop)),
        fillAnchor: _ctaAnchor);
    await _probe(
        tester,
        'Potential',
        (_, __) => _onboarding(
            PotentialScreen(profile: _profile, onBack: noop, onContinue: noop)),
        fillAnchor: _ctaAnchor);
    await _probe(
        tester,
        'Building',
        (_, __) =>
            _onboarding(BuildingPlanScreen(program: _program, onDone: noop)));
    await _probe(
        tester,
        'PlanReveal',
        (_, __) => _onboarding(PlanRevealScreen(
            profile: _profile, onBack: noop, onContinue: noop)),
        fillAnchor: _ctaAnchor);
    _expectAllFit();
  });

  testWidgets('paywall', (tester) async {
    final service = SubscriptionService();
    await service.initialize();
    await _probe(
      tester,
      'Paywall',
      (_, __) => PaywallScreen(
        profile: _profile,
        subscriptionService: service,
        onUnlocked: noop,
        onBack: noop,
      ),
      scaffold: false,
    );
    _expectAllFit();
  });

  testWidgets('app shell tabs', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sessionStore = await WorkoutSessionStore.load();
    await sessionStore.addSession(WorkoutSession(
      programId: _program.id,
      sessionNumber: 1,
      completedAt: DateTime(2026, 9, 28, 18),
      exercises: const [
        LoggedExercise(exerciseId: 'x', exerciseName: 'Depth Jumps', sets: [
          LoggedSet(setNumber: 1, reps: 8),
          LoggedSet(setNumber: 2, reps: 8),
        ]),
      ],
    ));
    final jumpLogStore = await JumpLogStore.load();
    for (final e in _jumpEntries) {
      await jumpLogStore.addEntry(e);
    }
    final athleteProfileStore = await AthleteProfileStore.load();
    await athleteProfileStore.setDisplayName('Marcus');
    final leaderboardService = LeaderboardService();
    await leaderboardService.initialize();

    Widget shell() => RootShell(
          profile: _profile,
          sessionStore: sessionStore,
          jumpLogStore: jumpLogStore,
          athleteProfileStore: athleteProfileStore,
          leaderboardService: leaderboardService,
          onRestartOnboarding: noop,
          onProfileChanged: (_) {},
        );

    // RootShell's IndexedStack lays out all five tabs at once, so overflows
    // and scrollables could not be attributed to one tab. Measure the bottom
    // bar's height from the real shell per device, then pump each tab alone
    // above a spacer of that height.
    final barHeight = <String, double>{};
    for (final size in _sizes.entries) {
      tester.view.physicalSize = size.value.size;
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = FakeViewPadding(
        top: size.value.top,
        bottom: size.value.bottom,
      );
      await tester
          .pumpWidget(_host(shell(), const Locale('fr'), scaffold: false));
      await _pumpFixed(tester);
      _tabBarHeights[size.value.size] = barHeight[size.key] =
          size.value.size.height -
              tester.getSize(find.byType(IndexedStack)).height;
      await tester.pumpWidget(const SizedBox());
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.view.resetPadding();

    final program = _program;
    Widget tab(Widget child, String device) => Scaffold(
          body: child,
          bottomNavigationBar: SizedBox(height: barHeight[device]),
        );

    await _probe(
      tester,
      'HomeTab',
      (_, device) => tab(
        HomeTab(
          profile: _profile,
          program: program,
          sessionStore: sessionStore,
          jumpLogStore: jumpLogStore,
          onStartTraining: noop,
          onOpenSettings: noop,
        ),
        device,
      ),
      scaffold: false,
      fillAnchor: _tabBarAnchor,
    );
    await _probe(
      tester,
      'TrainTab',
      (_, device) =>
          tab(TrainTab(program: program, sessionStore: sessionStore), device),
      scaffold: false,
      fillAnchor: _tabBarAnchor,
    );
    await _probe(
      tester,
      'FeedTab',
      (_, device) => tab(
        FeedTab(
          jumpLogStore: jumpLogStore,
          athleteProfileStore: athleteProfileStore,
          leaderboardService: leaderboardService,
          heightInches: _profile.heightInches,
          displayName: 'Marcus',
          onDisplayNameChanged: noop,
        ),
        device,
      ),
      scaffold: false,
    );
    await _probe(
      tester,
      'ProgressTab',
      (_, device) => tab(
        ProgressTab(
          program: program,
          sessionStore: sessionStore,
          jumpLogStore: jumpLogStore,
          onGoToAnalyze: noop,
        ),
        device,
      ),
      scaffold: false,
      fillAnchor: _tabBarAnchor,
    );
    await _probe(
      tester,
      'AnalyzeTab(source)',
      (_, device) => tab(
        AnalyzeFlow(profile: _profile, jumpLogStore: jumpLogStore),
        device,
      ),
      scaffold: false,
    );
    _expectAllFit();
  });

  testWidgets('session flow screens', (tester) async {
    final schedule = TrainingSchedule(_program);
    final day = schedule.prescriptionForSession(1);
    await _probe(
      tester,
      'Warmup',
      (_, __) => WarmupScreen(
        focus: day.focus,
        warmUp: day.warmUp,
        weekLabel: 'WEEK 1 · DAY 1 OF 3',
        isDeload: false,
        onStart: noop,
        onCancel: noop,
      ),
    );
    // The exercise with the most sets is the tallest log screen.
    final exercise = [...day.exercises]
      ..sort((a, b) => b.sets.compareTo(a.sets));
    await _probe(
      tester,
      'LogExercise(${exercise.first.sets} sets)',
      (_, __) => LogExerciseScreen(
        exercise: exercise.first,
        exerciseIndex: 0,
        totalExercises: day.exercises.length,
        onLogged: (_) {},
        onClose: noop,
      ),
    );
    await _probe(
      tester,
      'SessionComplete',
      (_, __) => SessionCompleteScreen(
        loggedExercises: [
          for (final e in day.exercises)
            LoggedExercise(
              exerciseId: e.id,
              exerciseName: e.name,
              sets: [
                for (var i = 1; i <= e.sets; i++)
                  LoggedSet(setNumber: i, reps: 8, weightLbs: 45),
              ],
            ),
        ],
        onFinish: noop,
      ),
    );
    await _probe(
      tester,
      'ExerciseDetail',
      (_, __) => ExerciseDetailScreen(exercise: day.exercises.first),
      scaffold: false,
    );
    _expectAllFit();
  });

  testWidgets('analyze screens', (tester) async {
    await _probe(tester, 'Source(standalone)',
        (_, __) => SourceScreen(onVideoSelected: (_, __) {}, onSkip: noop));
    await _probe(
      tester,
      'Trim',
      (_, __) => TrimScreen(
        video: File('nonexistent.mp4'),
        onConfirmed: (_) {},
        onCancel: noop,
      ),
    );
    await _probe(
      tester,
      'Unmeasured',
      (_, __) => UnmeasuredScreen(
        rejection: PoseDetectionRejection.noAirborneWindow,
        analysis: analysis,
        attemptType: VideoAttemptType.jumpAttempt,
        onRetrim: noop,
        onNewClip: noop,
      ),
    );
    await _probe(
      tester,
      'Result',
      (_, __) => JumpResultScreen(
        result: result,
        trend: JumpTrendCalculator.compute(_jumpEntries),
        analysis: analysis,
        attemptType: VideoAttemptType.jumpAttempt,
        onAnalyzeAnother: noop,
      ),
    );
    _expectAllFit();
  });

  testWidgets('progress screens', (tester) async {
    await _probe(
      tester,
      'JumpHistory',
      (_, __) => JumpHistoryScreen(entries: _jumpEntries),
      scaffold: false,
    );
    await _probe(
      tester,
      'JumpVideo',
      (_, __) => JumpVideoScreen(
        videoFile: File('nonexistent.mp4'),
        verticalInches: 29,
        recordedAt: DateTime(2026, 9, 28, 10),
      ),
      scaffold: false,
    );
    _expectAllFit();
  });
}

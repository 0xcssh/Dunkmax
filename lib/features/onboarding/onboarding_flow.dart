import 'package:flutter/material.dart';

import '../../core/models/commitment_level.dart';
import '../../core/models/court_position.dart';
import '../../core/models/dunk_goal.dart';
import '../../core/models/dunk_hand.dart';
import '../../core/models/experience_level.dart';
import '../../core/models/hops_level.dart';
import '../../core/models/onboarding_profile.dart';
import '../../core/models/training_location.dart';
import '../../core/program_catalog.dart';
import 'screens/age_screen.dart';
import 'screens/building_plan_screen.dart';
import 'screens/commitment_screen.dart';
import 'screens/days_per_week_screen.dart';
import 'screens/dunk_hand_screen.dart';
import 'screens/experience_screen.dart';
import 'screens/gap_screen.dart';
import 'screens/goal_screen.dart';
import 'screens/height_screen.dart';
import 'screens/hops_screen.dart';
import 'screens/how_it_works_screen.dart';
import 'screens/intro_carousel_screen.dart';
import 'screens/plan_reveal_screen.dart';
import 'screens/position_screen.dart';
import 'screens/potential_screen.dart';
import 'screens/training_location_screen.dart';
import 'screens/weight_screen.dart';
import 'widgets/court_backdrop.dart';
import 'widgets/shared_axis_switcher.dart';
import 'widgets/staggered_entrance.dart';

/// Declared in flow order — [_go] reads the ordering to work out whether the
/// athlete advanced or went back, which is what points the transition.
enum _Step {
  intro,
  goal,
  experience,
  position,
  days,
  location,
  hops,
  height,
  weight,
  age,
  dunkHand,
  commitment,
  gap,
  potential,
  howItWorks,
  building,
  planReveal,
}

/// Drives the full onboarding sequence: a swipeable intro carousel, an
/// 11-question quiz (with progress bar), then the sell screens (gap →
/// potential → how it works → plan reveal), before handing the completed
/// [OnboardingProfile] to [onCompleted].
///
/// Presentation lives here rather than in the steps: the painted [CourtBackdrop]
/// sits behind all of them, and [SharedAxisSwitcher] moves between them.
class OnboardingFlow extends StatefulWidget {
  final ValueChanged<OnboardingProfile> onCompleted;

  const OnboardingFlow({super.key, required this.onCompleted});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  _Step _step = _Step.intro;

  /// Which way the last move went. The step enum is declared in flow order, so
  /// [_go] can derive this itself and no call site has to say.
  bool _movingBack = false;

  final Set<DunkGoal> _goals = {};
  ExperienceLevel? _experience;
  CourtPosition? _position;
  int? _daysPerWeek;
  TrainingLocation? _location;
  HopsLevel? _hops;
  int _heightInches = 70; // 5'10"

  /// Null until the athlete supplies a real measurement — the reach question
  /// is skippable, and null is what tells VertAssessment to fall back to the
  /// height estimate (and the sell screens to say so).
  /// Never set during onboarding — measuring a standing reach against a wall
  /// is too much friction to put in front of a first-run athlete, and a quiz
  /// step they skip is a step that should not exist. It is set from Settings
  /// instead, and prompted for on the Analyze result where an estimated reach
  /// is actually costing the athlete an accurate dunk target.
  int? _standingReachInches;

  int _weightLbs = 180;
  int _ageYears = 25;

  /// Null until answered; VertAssessment reads null as a one-hand target.
  DunkHand? _dunkHand;

  CommitmentLevel? _commitment;

  static const _totalQuizSteps = 11;

  void _go(_Step step) => setState(() {
        _movingBack = step.index < _step.index;
        _step = step;
      });

  OnboardingProfile get _draftProfile => OnboardingProfile(
        goals: _goals,
        experience: _experience ?? ExperienceLevel.beginner,
        position: _position ?? CourtPosition.pointGuard,
        daysPerWeek: _daysPerWeek ?? 3,
        trainingLocation: _location ?? TrainingLocation.both,
        hopsLevel: _hops ?? HopsLevel.touchRim,
        heightInches: _heightInches,
        standingReachInches: _standingReachInches,
        weightLbs: _weightLbs,
        ageYears: _ageYears,
        dunkHand: _dunkHand,
        commitment: _commitment ?? CommitmentLevel.very,
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Painted once for the whole flow rather than per screen: the steps
        // then never have to know about it, and the court does not restart
        // behind every transition.
        CourtBackdrop(animate: !MediaQuery.disableAnimationsOf(context)),
        // Every step is a Scaffold, and the theme paints those opaque. Making
        // them transparent here is what lets the court through without any
        // screen changing its own layout.
        Theme(
          data: Theme.of(context)
              .copyWith(scaffoldBackgroundColor: Colors.transparent),
          child: SharedAxisSwitcher(
            reverse: _movingBack,
            // Re-keying per step is what both triggers the transition and
            // gives the step a fresh arrival stagger.
            child: StaggeredEntrance(
              key: ValueKey(_step),
              child: _buildStep(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.intro:
        return IntroCarouselScreen(onStart: () => _go(_Step.goal));

      case _Step.goal:
        return GoalScreen(
          step: 1,
          totalSteps: _totalQuizSteps,
          selected: _goals,
          onToggle: (g) => setState(() {
            if (_goals.contains(g)) {
              _goals.remove(g);
            } else {
              _goals.add(g);
            }
          }),
          onBack: () => _go(_Step.intro),
          onContinue: () => _go(_Step.experience),
        );

      case _Step.experience:
        return ExperienceScreen(
          step: 2,
          totalSteps: _totalQuizSteps,
          selected: _experience,
          onSelect: (v) => setState(() => _experience = v),
          onBack: () => _go(_Step.goal),
          onContinue: () => _go(_Step.position),
        );

      case _Step.position:
        return PositionScreen(
          step: 3,
          totalSteps: _totalQuizSteps,
          selected: _position,
          onSelect: (v) => setState(() => _position = v),
          onBack: () => _go(_Step.experience),
          onContinue: () => _go(_Step.days),
        );

      case _Step.days:
        return DaysPerWeekScreen(
          step: 4,
          totalSteps: _totalQuizSteps,
          selected: _daysPerWeek,
          onSelect: (v) => setState(() => _daysPerWeek = v),
          onBack: () => _go(_Step.position),
          onContinue: () => _go(_Step.location),
        );

      case _Step.location:
        return TrainingLocationScreen(
          step: 5,
          totalSteps: _totalQuizSteps,
          selected: _location,
          onSelect: (v) => setState(() => _location = v),
          onBack: () => _go(_Step.days),
          onContinue: () => _go(_Step.hops),
        );

      case _Step.hops:
        return HopsScreen(
          step: 6,
          totalSteps: _totalQuizSteps,
          selected: _hops,
          onSelect: (v) => setState(() => _hops = v),
          onBack: () => _go(_Step.location),
          onContinue: () => _go(_Step.height),
        );

      case _Step.height:
        return HeightScreen(
          step: 7,
          totalSteps: _totalQuizSteps,
          heightInches: _heightInches,
          onChanged: (v) => _heightInches = v,
          onBack: () => _go(_Step.hops),
          onContinue: () => _go(_Step.weight),
        );

      case _Step.weight:
        return WeightScreen(
          step: 8,
          totalSteps: _totalQuizSteps,
          weightLbs: _weightLbs,
          onChanged: (v) => setState(() => _weightLbs = v),
          onBack: () => _go(_Step.height),
          onContinue: () => _go(_Step.age),
        );

      case _Step.age:
        return AgeScreen(
          step: 9,
          totalSteps: _totalQuizSteps,
          ageYears: _ageYears,
          onChanged: (v) => _ageYears = v,
          onBack: () => _go(_Step.weight),
          onContinue: () => _go(_Step.dunkHand),
        );

      case _Step.dunkHand:
        return DunkHandScreen(
          step: 10,
          totalSteps: _totalQuizSteps,
          selected: _dunkHand,
          onSelect: (v) => setState(() => _dunkHand = v),
          onBack: () => _go(_Step.age),
          onContinue: () => _go(_Step.commitment),
        );

      case _Step.commitment:
        return CommitmentScreen(
          step: 11,
          totalSteps: _totalQuizSteps,
          selected: _commitment,
          onSelect: (v) => setState(() => _commitment = v),
          onBack: () => _go(_Step.dunkHand),
          onContinue: () => _go(_Step.gap),
        );

      case _Step.gap:
        return GapScreen(
          profile: _draftProfile,
          onBack: () => _go(_Step.commitment),
          onContinue: () => _go(_Step.potential),
        );

      case _Step.potential:
        return PotentialScreen(
          profile: _draftProfile,
          onBack: () => _go(_Step.gap),
          onContinue: () => _go(_Step.howItWorks),
        );

      case _Step.howItWorks:
        return HowItWorksScreen(
          onBack: () => _go(_Step.potential),
          onContinue: () => _go(_Step.building),
        );

      case _Step.building:
        return BuildingPlanScreen(
          program: ProgramCatalog.recommend(_draftProfile),
          onDone: () => _go(_Step.planReveal),
        );

      case _Step.planReveal:
        return PlanRevealScreen(
          profile: _draftProfile,
          onBack: () => _go(_Step.howItWorks),
          onContinue: () => widget.onCompleted(_draftProfile),
        );
    }
  }
}

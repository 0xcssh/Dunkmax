import 'package:flutter/material.dart';

import '../../core/models/commitment_level.dart';
import '../../core/models/court_position.dart';
import '../../core/models/dunk_goal.dart';
import '../../core/models/experience_level.dart';
import '../../core/models/hops_level.dart';
import '../../core/models/onboarding_profile.dart';
import '../../core/models/training_location.dart';
import '../../core/program_catalog.dart';
import 'screens/age_screen.dart';
import 'screens/building_plan_screen.dart';
import 'screens/commitment_screen.dart';
import 'screens/days_per_week_screen.dart';
import 'screens/experience_screen.dart';
import 'screens/gap_screen.dart';
import 'screens/goal_screen.dart';
import 'screens/height_screen.dart';
import 'screens/hops_screen.dart';
import 'screens/how_it_works_screen.dart';
import 'screens/plan_reveal_screen.dart';
import 'screens/position_screen.dart';
import 'screens/potential_screen.dart';
import 'screens/standing_reach_screen.dart';
import 'screens/training_location_screen.dart';
import 'screens/weight_screen.dart';
import 'screens/welcome_screen.dart';

enum _Step {
  welcome,
  goal,
  experience,
  position,
  days,
  location,
  hops,
  height,
  standingReach,
  weight,
  age,
  commitment,
  gap,
  potential,
  howItWorks,
  building,
  planReveal,
}

/// Drives the full onboarding sequence: an 11-question quiz (with progress bar)
/// followed by the sell screens (gap → potential → how it works → plan
/// reveal), then hands the completed [OnboardingProfile] to [onCompleted].
class OnboardingFlow extends StatefulWidget {
  final ValueChanged<OnboardingProfile> onCompleted;

  const OnboardingFlow({super.key, required this.onCompleted});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  _Step _step = _Step.welcome;

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
  int? _standingReachInches;

  int _weightLbs = 180;
  int _ageYears = 25;
  CommitmentLevel? _commitment;

  static const _totalQuizSteps = 11;

  void _go(_Step step) => setState(() => _step = step);

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
        commitment: _commitment ?? CommitmentLevel.very,
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(key: ValueKey(_step), child: _buildStep()),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.welcome:
        return WelcomeScreen(onStart: () => _go(_Step.goal));

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
          onBack: () => _go(_Step.welcome),
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
          onContinue: () => _go(_Step.standingReach),
        );

      case _Step.standingReach:
        return StandingReachScreen(
          step: 8,
          totalSteps: _totalQuizSteps,
          heightInches: _heightInches,
          standingReachInches: _standingReachInches,
          onChanged: (v) => _standingReachInches = v,
          onSkip: () {
            // Explicitly clear it: the screen pre-fills the wheel with the
            // height estimate, and an unmeasured reach must stay unmeasured.
            _standingReachInches = null;
            _go(_Step.weight);
          },
          onBack: () => _go(_Step.height),
          onContinue: () => _go(_Step.weight),
        );

      case _Step.weight:
        return WeightScreen(
          step: 9,
          totalSteps: _totalQuizSteps,
          weightLbs: _weightLbs,
          onChanged: (v) => setState(() => _weightLbs = v),
          onBack: () => _go(_Step.standingReach),
          onContinue: () => _go(_Step.age),
        );

      case _Step.age:
        return AgeScreen(
          step: 10,
          totalSteps: _totalQuizSteps,
          ageYears: _ageYears,
          onChanged: (v) => _ageYears = v,
          onBack: () => _go(_Step.weight),
          onContinue: () => _go(_Step.commitment),
        );

      case _Step.commitment:
        return CommitmentScreen(
          step: 11,
          totalSteps: _totalQuizSteps,
          selected: _commitment,
          onSelect: (v) => setState(() => _commitment = v),
          onBack: () => _go(_Step.age),
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

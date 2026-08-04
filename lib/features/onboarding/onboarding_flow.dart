import 'package:flutter/material.dart';

import '../../core/models/court_position.dart';
import '../../core/models/dunk_goal.dart';
import '../../core/models/experience_level.dart';
import '../../core/models/onboarding_profile.dart';
import '../../core/program_catalog.dart';
import 'screens/building_plan_screen.dart';
import 'screens/days_per_week_screen.dart';
import 'screens/experience_screen.dart';
import 'screens/goal_screen.dart';
import 'screens/position_screen.dart';
import 'screens/welcome_screen.dart';

enum _Step { welcome, goal, experience, position, days, building }

/// Drives the whole onboarding sequence, holding the draft selections until
/// they form a complete [OnboardingProfile], then handing it to [onCompleted].
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

  // The four quiz questions drive the progress bar (welcome/building excluded).
  static const _totalQuizSteps = 4;

  void _go(_Step step) => setState(() => _step = step);

  OnboardingProfile get _draftProfile => OnboardingProfile(
        goals: _goals,
        experience: _experience!,
        position: _position!,
        daysPerWeek: _daysPerWeek!,
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: KeyedSubtree(
        key: ValueKey(_step),
        child: _buildStep(),
      ),
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
          onToggle: (goal) => setState(() {
            if (_goals.contains(goal)) {
              _goals.remove(goal);
            } else {
              _goals.add(goal);
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
          onSelect: (level) => setState(() => _experience = level),
          onBack: () => _go(_Step.goal),
          onContinue: () => _go(_Step.position),
        );

      case _Step.position:
        return PositionScreen(
          step: 3,
          totalSteps: _totalQuizSteps,
          selected: _position,
          onSelect: (position) => setState(() => _position = position),
          onBack: () => _go(_Step.experience),
          onContinue: () => _go(_Step.days),
        );

      case _Step.days:
        return DaysPerWeekScreen(
          step: 4,
          totalSteps: _totalQuizSteps,
          selected: _daysPerWeek,
          onSelect: (days) => setState(() => _daysPerWeek = days),
          onBack: () => _go(_Step.position),
          onContinue: () => _go(_Step.building),
        );

      case _Step.building:
        return BuildingPlanScreen(
          program: ProgramCatalog.recommend(_draftProfile),
          onDone: () => widget.onCompleted(_draftProfile),
        );
    }
  }
}

import 'package:flutter/material.dart';

import '../../../core/exercise_library.dart';
import '../../../core/models/exercise.dart';
import '../../../core/models/workout_session.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';
import 'exercise_detail_screen.dart';

/// Logs actual reps/weight for a single exercise's sets. One instance of
/// this screen is shown per exercise in [SessionFlow]; [onLogged] advances
/// to the next exercise (or to the completion summary on the last one).
///
/// Every set must be explicitly validated (checked off) before the athlete
/// can advance — prefilled numbers alone are not proof the set was done.
class LogExerciseScreen extends StatefulWidget {
  final Exercise exercise;
  final int exerciseIndex;
  final int totalExercises;
  final ValueChanged<LoggedExercise> onLogged;

  const LogExerciseScreen({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.totalExercises,
    required this.onLogged,
  });

  @override
  State<LogExerciseScreen> createState() => _LogExerciseScreenState();
}

class _LogExerciseScreenState extends State<LogExerciseScreen> {
  late final List<TextEditingController> _repsControllers;
  late final List<TextEditingController> _weightControllers;
  late final List<bool> _validated;

  @override
  void initState() {
    super.initState();
    final prefillReps =
        RegExp(r'\d+').firstMatch(widget.exercise.repsLabel)?.group(0) ?? '';
    _repsControllers = List.generate(
      widget.exercise.sets,
      (_) => TextEditingController(text: prefillReps),
    );
    _weightControllers = List.generate(
      widget.exercise.sets,
      (_) => TextEditingController(),
    );
    _validated = List.generate(widget.exercise.sets, (_) => false);
  }

  @override
  void dispose() {
    for (final c in _repsControllers) {
      c.dispose();
    }
    for (final c in _weightControllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _allValidated => !_validated.contains(false);

  void _toggleValidated(int index) {
    setState(() {
      _validated[index] = !_validated[index];
    });
  }

  void _submit() {
    final sets = <LoggedSet>[
      for (var i = 0; i < widget.exercise.sets; i++)
        LoggedSet(
          setNumber: i + 1,
          reps: int.tryParse(_repsControllers[i].text) ?? 0,
          weightLbs: double.tryParse(_weightControllers[i].text),
        ),
    ];
    widget.onLogged(LoggedExercise(
      exerciseId: widget.exercise.id,
      exerciseName: widget.exercise.name,
      sets: sets,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLast = widget.exerciseIndex + 1 == widget.totalExercises;
    final canAdvance = _allValidated;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.logExerciseCounter(
                  widget.exerciseIndex + 1, widget.totalExercises),
              style: const TextStyle(
                color: DunkColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            _ExerciseTitle(
              exercise: widget.exercise,
              onTap: () =>
                  ExerciseDetailScreen.open(context, widget.exercise),
            ),
            const SizedBox(height: 6),
            Text(widget.exercise.volumeLabel, style: DunkTheme.onboardingSubtitle),
            const SizedBox(height: 16),
            _GuideCard(
              exercise: widget.exercise,
              onTap: () =>
                  ExerciseDetailScreen.open(context, widget.exercise),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: widget.exercise.sets,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _SetRow(
                  setNumber: i + 1,
                  repsController: _repsControllers[i],
                  weightController: _weightControllers[i],
                  validated: _validated[i],
                  onToggleValidated: () => _toggleValidated(i),
                ),
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: isLast
                  ? l10n.logCtaFinishSession
                  : l10n.logCtaNextExercise,
              onPressed: canAdvance ? _submit : null,
            ),
            if (!canAdvance) ...[
              const SizedBox(height: 10),
              Text(
                l10n.logValidateEverySet,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: DunkColors.textSecondary, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The exercise name, tappable to open its full guide. The affordance is an
/// explicit orange info icon — without it the name reads as a plain heading
/// and nobody would think to tap it.
class _ExerciseTitle extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;

  const _ExerciseTitle({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(exercise.name, style: DunkTheme.onboardingTitle),
              ),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(Icons.info_outline,
                    size: 20, color: DunkColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row above the set list that opens the drill's coaching guide.
///
/// It replaces the old demo-video placeholder: no clip is filmed for any
/// exercise yet, and a card whose only message is "coming soon" is worth less
/// than one that opens the written execution steps.
class _GuideCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;

  const _GuideCard({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final guide = ExerciseLibrary.guideForExercise(exercise);
    final subtitle = guide == null
        ? l10n.logGuideNone
        : l10n.logGuideSubtitle(guide.steps.length);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DunkColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DunkColors.stroke),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: DunkColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_book_outlined,
                        color: DunkColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.logGuideTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: DunkColors.textSecondary,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: DunkColors.textTertiary, size: 20),
                ],
              ),
              if (exercise.isSubstitution) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.swap_horiz,
                        size: 14, color: DunkColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _swapNote(l10n, exercise),
                        style: const TextStyle(
                          color: DunkColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// One whole sentence per case rather than a stem plus a suffix: a
  /// fragment joined onto another fragment does not survive translation.
  static String _swapNote(AppLocalizations l10n, Exercise exercise) {
    final id = exercise.substitutedForId;
    final replaced = id == null ? null : ExerciseLibrary.guideFor(id);
    if (replaced == null) return l10n.logSwappedForHome;
    // The replaced drill's name comes from the untranslated exercise library.
    return l10n.logSwappedForHomeReplaces(replaced.name);
  }
}

class _SetRow extends StatelessWidget {
  final int setNumber;
  final TextEditingController repsController;
  final TextEditingController weightController;
  final bool validated;
  final VoidCallback onToggleValidated;

  const _SetRow({
    required this.setNumber,
    required this.repsController,
    required this.weightController,
    required this.validated,
    required this.onToggleValidated,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: validated ? DunkColors.primary : DunkColors.stroke,
          width: validated ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.logSetNumber(setNumber),
                  style: const TextStyle(
                    color: DunkColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              _ValidateToggle(validated: validated, onTap: onToggleValidated),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  controller: repsController,
                  hintText: l10n.logRepsHint,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumberField(
                  controller: weightController,
                  hintText: l10n.logWeightHint,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tap target that marks a set as done. Filled orange + check when
/// validated, outlined when not. Re-tappable so an athlete can un-validate
/// to fix a number before locking it back in.
class _ValidateToggle extends StatelessWidget {
  final bool validated;
  final VoidCallback onTap;

  const _ValidateToggle({required this.validated, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: validated ? DunkColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: validated ? DunkColors.primary : DunkColors.stroke,
              width: 1.4,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                validated ? Icons.check_circle : Icons.circle_outlined,
                size: 16,
                color: validated ? Colors.black : DunkColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                validated
                    ? AppLocalizations.of(context).logValidated
                    : AppLocalizations.of(context).logValidate,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: validated ? Colors.black : DunkColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;

  const _NumberField({
    required this.controller,
    required this.hintText,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        isDense: true,
        hintText: hintText,
        hintStyle: const TextStyle(color: DunkColors.textTertiary),
        filled: true,
        fillColor: DunkColors.surfaceRaised,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: DunkColors.stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: DunkColors.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: DunkColors.primary),
        ),
      ),
    );
  }
}

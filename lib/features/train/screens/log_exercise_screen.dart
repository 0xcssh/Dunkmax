import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/models/exercise.dart';
import '../../../core/models/workout_session.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';

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
    final isLast = widget.exerciseIndex + 1 == widget.totalExercises;
    final canAdvance = _allValidated;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EXERCISE ${widget.exerciseIndex + 1}/${widget.totalExercises}',
              style: const TextStyle(
                color: DunkColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.exercise.name, style: DunkTheme.onboardingTitle),
            const SizedBox(height: 6),
            Text(widget.exercise.volumeLabel, style: DunkTheme.onboardingSubtitle),
            const SizedBox(height: 16),
            _VideoSection(videoUrl: widget.exercise.videoUrl),
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
              label: isLast ? 'FINISH SESSION' : 'NEXT EXERCISE',
              onPressed: canAdvance ? _submit : null,
            ),
            if (!canAdvance) ...[
              const SizedBox(height: 10),
              const Text(
                'Validate every set to continue',
                textAlign: TextAlign.center,
                style: TextStyle(color: DunkColors.textSecondary, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Demo-clip card shown above the set list. Plays the exercise's video when
/// [videoUrl] is set; otherwise shows an honest "coming soon" placeholder —
/// no real clips are authored for any exercise yet (see [Exercise.videoUrl]).
class _VideoSection extends StatefulWidget {
  final String? videoUrl;
  const _VideoSection({required this.videoUrl});

  @override
  State<_VideoSection> createState() => _VideoSectionState();
}

class _VideoSectionState extends State<_VideoSection> {
  VideoPlayerController? _controller;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    final url = widget.videoUrl;
    if (url != null) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _controller = controller;
      controller.initialize().then((_) {
        if (!mounted) return;
        setState(() => _videoReady = true);
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null || !_videoReady) return;
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoUrl == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DunkColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DunkColors.stroke),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, color: DunkColors.textTertiary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'DEMO VIDEO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Demo video coming soon.',
                    style: TextStyle(color: DunkColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final controller = _controller;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: DunkColors.surface,
          border: Border.all(color: DunkColors.stroke),
          borderRadius: BorderRadius.circular(16),
        ),
        child: AspectRatio(
          aspectRatio: _videoReady && controller != null
              ? controller.value.aspectRatio
              : 16 / 9,
          child: !_videoReady || controller == null
              ? const Center(
                  child: CircularProgressIndicator(color: DunkColors.primary),
                )
              : GestureDetector(
                  onTap: _togglePlayback,
                  child: Stack(
                    alignment: Alignment.center,
                    fit: StackFit.expand,
                    children: [
                      VideoPlayer(controller),
                      AnimatedOpacity(
                        opacity: controller.value.isPlaying ? 0 : 1,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          color: Colors.black26,
                          child: const Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 56,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
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
                  'SET $setNumber',
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
                  hintText: 'reps',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumberField(
                  controller: weightController,
                  hintText: 'lbs (optional)',
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
                validated ? 'DONE' : 'VALIDATE',
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

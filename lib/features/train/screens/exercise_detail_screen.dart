import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/exercise_library.dart';
import '../../../core/models/exercise.dart';
import '../../../theme/app_theme.dart';

/// Full coaching detail for one drill: what it trains, how to execute it,
/// what usually goes wrong, what it works, and what it needs.
///
/// Opened from the exercise name on the set-logging screen. Everything shown
/// here comes from [ExerciseLibrary] — the screen invents nothing, and when a
/// drill has no authored guide it says so rather than filling the space.
class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  /// Convenience push used by the logging screen.
  static Future<void> open(BuildContext context, Exercise exercise) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExerciseDetailScreen(exercise: exercise),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guide = ExerciseLibrary.guideForExercise(exercise);
    final replaced = exercise.substitutedForId == null
        ? null
        : ExerciseLibrary.guideFor(exercise.substitutedForId!);

    return Scaffold(
      backgroundColor: DunkColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
                const Spacer(),
                const Text(
                  'EXERCISE GUIDE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  Text(exercise.name, style: DunkTheme.onboardingTitle),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Badge(
                        icon: exercise.equipment == Equipment.none
                            ? Icons.accessibility_new
                            : Icons.fitness_center,
                        label: exercise.equipment.label,
                      ),
                      _Badge(
                        icon: Icons.repeat,
                        label: exercise.volumeLabel.toUpperCase(),
                      ),
                    ],
                  ),
                  if (exercise.isSubstitution) ...[
                    const SizedBox(height: 16),
                    _SubstitutionNote(replacedName: replaced?.name),
                  ],
                  const SizedBox(height: 20),
                  _DemoMedia(
                    videoAsset: guide?.demoVideoAsset,
                    frames: guide?.demoFrames ?? const [],
                  ),
                  if (guide == null) ...[
                    const SizedBox(height: 20),
                    const _EmptyGuideNote(),
                  ] else ...[
                    const SizedBox(height: 20),
                    _Section(
                      title: 'WHY IT MATTERS',
                      child: Text(
                        guide.summary,
                        style: const TextStyle(
                          color: DunkColors.textSecondary,
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _Section(
                      title: 'HOW TO DO IT',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < guide.steps.length; i++) ...[
                            if (i > 0) const SizedBox(height: 14),
                            _Step(number: i + 1, text: guide.steps[i]),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _Section(
                      title: 'COMMON MISTAKES',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0;
                              i < guide.commonMistakes.length;
                              i++) ...[
                            if (i > 0) const SizedBox(height: 12),
                            _Mistake(text: guide.commonMistakes[i]),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _Section(
                      title: 'WHAT IT TRAINS',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final quality in guide.trains)
                            _Chip(label: quality),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small outlined pill for equipment / volume facts.
class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: DunkColors.textTertiary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: DunkColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Says plainly that this drill is not the one the program authored, and why.
class _SubstitutionNote extends StatelessWidget {
  /// Name of the drill this one replaced. Null when the original has no
  /// authored guide — the note then stays generic rather than guessing.
  final String? replacedName;

  const _SubstitutionNote({required this.replacedName});

  @override
  Widget build(BuildContext context) {
    final replaced = replacedName;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DunkColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DunkColors.primary.withValues(alpha: 0.40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.swap_horiz, size: 16, color: DunkColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SWAPPED FOR YOUR HOME SETUP',
                  style: TextStyle(
                    color: DunkColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  replaced == null
                      ? 'The authored drill needs equipment you told us you '
                          'do not train with. This one trains the same '
                          'quality with nothing but the floor.'
                      : 'Replaces $replaced, which needs equipment you told '
                          'us you do not train with. This one trains the same '
                          'quality with nothing but the floor.',
                  style: const TextStyle(
                    color: DunkColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when a drill has no authored guide yet — honest, not padded out.
class _EmptyGuideNote extends StatelessWidget {
  const _EmptyGuideNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.menu_book_outlined,
              size: 18, color: DunkColors.textTertiary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No coaching notes are written for this drill yet.',
              style: TextStyle(
                color: DunkColors.textSecondary,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The demonstration slot.
///
/// Plays [videoAsset] when one exists, shows the still frames otherwise, and
/// otherwise renders a deliberate empty state: no clip has been filmed for
/// any drill yet and the app ships no stand-in that could be mistaken for a
/// demonstration. The written steps below carry the screen.
class _DemoMedia extends StatefulWidget {
  /// Bundled looping clip, or null while none has been sourced for this drill.
  final String? videoAsset;

  /// Start and end positions of the movement. Two stills read better than one
  /// here: a single frame of a jump is ambiguous, the pair shows the travel.
  final List<String> frames;

  const _DemoMedia({required this.videoAsset, required this.frames});

  @override
  State<_DemoMedia> createState() => _DemoMediaState();
}

class _DemoMediaState extends State<_DemoMedia> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final asset = widget.videoAsset;
    if (asset == null) return;
    final controller = VideoPlayerController.asset(asset);
    _controller = controller;
    controller.initialize().then((_) {
      if (!mounted) return;
      // A demonstration should behave like an animation, not like media the
      // athlete has to operate: loop it, silence it, start it.
      controller.setLooping(true);
      controller.setVolume(0);
      controller.play();
      setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null || !_ready) return;
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: _ready ? controller.value.aspectRatio : 16 / 9,
          child: !_ready
              ? const ColoredBox(
                  color: DunkColors.surface,
                  child: Center(
                    child: CircularProgressIndicator(color: DunkColors.primary),
                  ),
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
      );
    }

    final frames = widget.frames;
    if (frames.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Two positions cross-faded on a loop. It is not footage, but a
          // still of a jump is ambiguous — start and finish alternating reads
          // as the movement, which is the thing being taught. Costs nothing:
          // both frames already ship.
          if (frames.length >= 2)
            _FrameLoop(frames: frames)
          else
            _Frame(asset: frames.first, label: 'POSITION'),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < frames.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _Frame(
                    asset: frames[i],
                    label: i == 0 ? 'START' : 'FINISH',
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Reference photos, not a recording of your own jump.',
            style: TextStyle(color: DunkColors.textTertiary, fontSize: 11),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: DunkColors.surfaceRaised,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.videocam_off_outlined,
                size: 20, color: DunkColors.textTertiary),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NO DEMO CLIP YET',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Nothing has been filmed for this drill. The steps below '
                  'are the full instruction.',
                  style: TextStyle(
                    color: DunkColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A titled block of content.
class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: DunkColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DunkColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DunkColors.stroke),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String text;

  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: DunkColors.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: DunkColors.primary.withValues(alpha: 0.35)),
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: DunkColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Mistake extends StatelessWidget {
  final String text;

  const _Mistake({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.error_outline, size: 17, color: DunkColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: DunkColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: DunkColors.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// One demonstration still, captioned with the phase it shows.
///
/// The photo is scaled to fit rather than cropped: these are wide reference
/// shots of a whole body, and cropping them to a tile cuts the feet off —
/// which on a jumping drill removes the part that matters.
/// Cross-fades between the start and finish positions on a loop, so the pair
/// reads as a movement rather than as two photographs.
///
/// Honours the platform's reduce-motion setting: with animations disabled it
/// simply holds the start position, and the still pair below it carries the
/// same information either way.
class _FrameLoop extends StatefulWidget {
  final List<String> frames;

  const _FrameLoop({required this.frames});

  @override
  State<_FrameLoop> createState() => _FrameLoopState();
}

class _FrameLoopState extends State<_FrameLoop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// Eased rather than linear, and held at each end, so the movement lands in
  /// a position instead of sliding continuously between two.
  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.25, 0.75, curve: Curves.easeInOut),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 3 / 2,
        child: ColoredBox(
          color: DunkColors.surface,
          child: AnimatedBuilder(
            animation: _t,
            builder: (context, _) => Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(widget.frames[0], fit: BoxFit.cover),
                Opacity(
                  opacity: _t.value,
                  child: Image.asset(widget.frames[1], fit: BoxFit.cover),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  final String asset;
  final String label;

  const _Frame({required this.asset, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: ColoredBox(
              color: DunkColors.surface,
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                // A missing asset must not crash a session mid-workout.
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.image_not_supported_outlined,
                      color: DunkColors.textTertiary, size: 22),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: DunkColors.textTertiary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

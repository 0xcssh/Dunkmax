import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/trim_range.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';

/// Narrow the clip down to the single jump before it is analysed.
///
/// This is not a cosmetic step. Both frame samplers spend a *fixed* budget of
/// frames across whatever range they are given, so trimming to one jump buys
/// temporal resolution exactly where the measurement needs it — inside the
/// flight — and removes the double-jump case that the pose detector otherwise
/// (correctly) refuses to answer. Nothing is re-encoded: the chosen
/// [TrimRange] is passed forward as a range, and the original file is still
/// what gets saved to the jump log.
class TrimScreen extends StatefulWidget {
  final File video;
  final ValueChanged<TrimRange> onConfirmed;

  /// Back to the source step — used by both CANCEL and Retake.
  final VoidCallback onCancel;

  const TrimScreen({
    super.key,
    required this.video,
    required this.onConfirmed,
    required this.onCancel,
  });

  @override
  State<TrimScreen> createState() => _TrimScreenState();
}

class _TrimScreenState extends State<TrimScreen> {
  late final VideoPlayerController _controller;
  TrimRange _range = TrimRange.full(Duration.zero);
  bool _ready = false;
  bool _looping = false;

  /// A flag rather than a message: it is set from an [initState] callback,
  /// where a localisation lookup is not allowed. Worded in [build].
  bool _failedToLoad = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.video);
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _range = TrimRange.full(_controller.value.duration);
        _ready = true;
      });
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _failedToLoad = true);
    });
    _controller.addListener(_onTick);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  /// Playback loops inside the selection, so the preview shows exactly what
  /// will be analysed.
  void _onTick() {
    if (!mounted) return;
    final value = _controller.value;
    if (value.isPlaying && !_looping && value.position >= _range.end) {
      _looping = true;
      _controller.seekTo(_range.start).whenComplete(() {
        _looping = false;
      });
    }
    setState(() {});
  }

  Future<void> _togglePlay() async {
    if (_controller.value.isPlaying) {
      await _controller.pause();
      return;
    }
    if (!_range.contains(_controller.value.position)) {
      await _controller.seekTo(_range.start);
    }
    if (!mounted) return;
    await _controller.play();
  }

  /// Applies a handle drag and parks the preview on the frame that handle now
  /// sits on, so the athlete sees what they are cutting to.
  void _onHandleDragged(_Handle handle, Duration position) {
    final next = handle == _Handle.start
        ? _range.movingStartTo(position)
        : _range.movingEndTo(position);
    if (next == _range) return;
    setState(() => _range = next);
    if (_controller.value.isPlaying) _controller.pause();
    _controller.seekTo(handle == _Handle.start ? next.start : next.end);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_failedToLoad) {
      return _ErrorState(message: l10n.trimLoadError, onBack: widget.onCancel);
    }
    if (!_ready) {
      return const Center(
        child: CircularProgressIndicator(color: DunkColors.primary),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
            child: Row(
              children: [
                Text(
                  l10n.trimTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: widget.onCancel,
                  child: Text(
                    l10n.trimCancel,
                    style: const TextStyle(
                      color: DunkColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: DunkColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: DunkColors.stroke),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                    _PlayToggle(
                      isPlaying: _controller.value.isPlaying,
                      onTap: _togglePlay,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.trimHintDrag,
                  style: const TextStyle(
                    color: DunkColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                Text(
                  l10n.trimHintRange,
                  style: const TextStyle(
                    color: DunkColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TimeReadout(
                        label: l10n.trimStartLabel, value: _range.start),
                    _TimeReadout(label: l10n.trimEndLabel, value: _range.end),
                  ],
                ),
                const SizedBox(height: 12),
                _TrimTimeline(range: _range, onHandleDragged: _onHandleDragged),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
            child: Column(
              children: [
                PrimaryButton(
                  label: l10n.trimAnalyzeCta,
                  trailingIcon: Icons.auto_graph,
                  onPressed: () => widget.onConfirmed(_range),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: widget.onCancel,
                  child: Text(
                    l10n.trimRetake,
                    style: const TextStyle(
                      color: DunkColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
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

/// The big translucent-orange play/pause disc floating over the preview.
class _PlayToggle extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _PlayToggle({required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: DunkColors.primary.withValues(alpha: 0.82),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 44,
        ),
      ),
    );
  }
}

class _TimeReadout extends StatelessWidget {
  final String label;
  final Duration value;

  const _TimeReadout({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: DunkColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          TrimRange.formatTimecode(value),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

enum _Handle { start, end }

const double _timelineHeight = 56;
const double _bandHeight = 44;
const double _handleWidth = 22;
const double _handleHeight = 52;

/// The trim bar: a full-clip band with the excluded spans dimmed, the kept
/// span tinted, and a draggable orange handle at each edge.
///
/// Hand-built with gestures and plain boxes — no slider package, no new
/// dependency. All the clamping lives in [TrimRange]; this widget only turns
/// pixels into a position.
class _TrimTimeline extends StatefulWidget {
  final TrimRange range;
  final void Function(_Handle handle, Duration position) onHandleDragged;

  const _TrimTimeline({required this.range, required this.onHandleDragged});

  @override
  State<_TrimTimeline> createState() => _TrimTimelineState();
}

class _TrimTimelineState extends State<_TrimTimeline> {
  _Handle? _active;

  void _emit(double dx, double usable) {
    final handle = _active;
    if (handle == null) return;
    final fraction = (dx - _handleWidth) / usable;
    widget.onHandleDragged(handle, widget.range.positionAt(fraction));
  }

  /// One of the two excluded spans, darkened so the kept span reads first.
  Widget _dim({
    required double left,
    required double width,
    required double top,
    required BorderRadius radius,
  }) {
    return Positioned(
      left: left,
      width: width < 0 ? 0 : width,
      top: top,
      height: _bandHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DunkColors.background.withValues(alpha: 0.72),
          borderRadius: radius,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final usable = width - _handleWidth * 2;
        if (usable <= 0) return const SizedBox(height: _timelineHeight);

        final range = widget.range;
        // Handles sit *outside* the span they mark, so the selection edge is
        // the handle's inner edge — which is what these two x's are.
        final leftX = _handleWidth + range.fractionOf(range.start) * usable;
        final rightX = _handleWidth + range.fractionOf(range.end) * usable;
        const bandTop = (_timelineHeight - _bandHeight) / 2;
        const handleTop = (_timelineHeight - _handleHeight) / 2;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) {
            final dx = details.localPosition.dx;
            setState(() {
              _active = (dx - leftX).abs() <= (dx - rightX).abs()
                  ? _Handle.start
                  : _Handle.end;
            });
            _emit(dx, usable);
          },
          onHorizontalDragUpdate: (details) =>
              _emit(details.localPosition.dx, usable),
          onHorizontalDragEnd: (_) => setState(() => _active = null),
          onHorizontalDragCancel: () => setState(() => _active = null),
          child: SizedBox(
            height: _timelineHeight,
            width: width,
            child: Stack(
              children: [
                // The whole clip.
                Positioned(
                  left: _handleWidth,
                  width: usable,
                  top: bandTop,
                  height: _bandHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: DunkColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                // The kept span.
                Positioned(
                  left: leftX,
                  width: rightX - leftX,
                  top: bandTop,
                  height: _bandHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: DunkColors.primary.withValues(alpha: 0.20),
                      border: const Border.symmetric(
                        horizontal: BorderSide(color: DunkColors.primary, width: 2),
                      ),
                    ),
                  ),
                ),
                // The excluded spans, dimmed back.
                _dim(
                  left: _handleWidth,
                  width: leftX - _handleWidth,
                  top: bandTop,
                  radius: const BorderRadius.horizontal(left: Radius.circular(8)),
                ),
                _dim(
                  left: rightX,
                  width: width - _handleWidth - rightX,
                  top: bandTop,
                  radius: const BorderRadius.horizontal(right: Radius.circular(8)),
                ),
                Positioned(
                  left: leftX - _handleWidth,
                  width: _handleWidth,
                  top: handleTop,
                  height: _handleHeight,
                  child: _Grip(active: _active == _Handle.start),
                ),
                Positioned(
                  left: rightX,
                  width: _handleWidth,
                  top: handleTop,
                  height: _handleHeight,
                  child: _Grip(active: _active == _Handle.end),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A trim handle: a rounded orange bar with a two-line grip texture.
class _Grip extends StatelessWidget {
  final bool active;

  const _Grip({required this.active});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: DunkColors.primaryGradient,
        borderRadius: BorderRadius.circular(7),
        boxShadow: active
            ? [
                BoxShadow(
                  color: DunkColors.primary.withValues(alpha: 0.45),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _gripLine(),
          const SizedBox(width: 4),
          _gripLine(),
        ],
      ),
    );
  }

  Widget _gripLine() => Container(
        width: 2,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(1),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onBack;

  const _ErrorState({required this.message, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: DunkColors.primary, size: 40),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: DunkTheme.onboardingSubtitle,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                  label: AppLocalizations.of(context).trimTryAgain,
                  onPressed: onBack),
            ],
          ),
        ),
      ),
    );
  }
}

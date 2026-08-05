import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/models/jump_measurement.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';

/// Scrub the clip and mark the exact instant the athlete leaves the ground
/// (takeoff) and lands (landing). The gap between those two timestamps is
/// the whole measurement — see core/flight_time.dart.
class MarkJumpScreen extends StatefulWidget {
  final File video;
  final ValueChanged<JumpMeasurement> onMarked;
  final VoidCallback onCancel;
  final bool isFallback;

  const MarkJumpScreen({
    super.key,
    required this.video,
    required this.onMarked,
    required this.onCancel,
    this.isFallback = false,
  });

  @override
  State<MarkJumpScreen> createState() => _MarkJumpScreenState();
}

class _MarkJumpScreenState extends State<MarkJumpScreen> {
  late final VideoPlayerController _controller;
  Duration? _takeoff;
  Duration? _landing;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.video);
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _error = "Couldn't load that clip.");
    });
    _controller.addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  JumpMeasurement? get _measurement {
    final takeoff = _takeoff;
    final landing = _landing;
    if (takeoff == null || landing == null) return null;
    return JumpMeasurement(takeoff: takeoff, landing: landing);
  }

  void _markTakeoff() => setState(() {
        _takeoff = _controller.value.position;
        final landing = _landing;
        if (landing != null && landing <= _takeoff!) _landing = null;
      });

  void _markLanding() {
    if (_takeoff == null) return;
    setState(() => _landing = _controller.value.position);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorState(message: _error!, onBack: widget.onCancel);
    }
    if (!_ready) {
      return const Center(
        child: CircularProgressIndicator(color: DunkColors.primary),
      );
    }

    final measurement = _measurement;
    final duration = _controller.value.duration;
    final position = _controller.value.position;
    final maxMs = duration.inMilliseconds > 0
        ? duration.inMilliseconds.toDouble()
        : 1.0;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
                const Spacer(),
                const Text(
                  'MARK YOUR JUMP',
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
          ),
          if (widget.isFallback)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: DunkColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DunkColors.stroke),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: DunkColors.textSecondary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "We couldn't auto-detect your jump — mark takeoff and landing manually.",
                        style: TextStyle(color: DunkColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                Slider(
                  activeColor: DunkColors.primary,
                  inactiveColor: DunkColors.stroke,
                  min: 0,
                  max: maxMs,
                  value: position.inMilliseconds.toDouble().clamp(0, maxMs).toDouble(),
                  onChanged: (v) =>
                      _controller.seekTo(Duration(milliseconds: v.round())),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play(),
                      icon: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        color: DunkColors.primary,
                        size: 40,
                      ),
                    ),
                    _MarkChip(
                      label: 'TAKEOFF',
                      value: _takeoff,
                      onTap: _markTakeoff,
                    ),
                    _MarkChip(
                      label: 'LANDING',
                      value: _landing,
                      onTap: _takeoff == null ? null : _markLanding,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                if (measurement != null && !measurement.isValid)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      "That gap doesn't look like a real jump — re-mark takeoff and landing.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                PrimaryButton(
                  label: 'ANALYZE JUMP',
                  onPressed: (measurement != null && measurement.isValid)
                      ? () => widget.onMarked(measurement)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkChip extends StatelessWidget {
  final String label;
  final Duration? value;
  final VoidCallback? onTap;

  const _MarkChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final set = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: set ? DunkColors.primary : DunkColors.surface,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: set ? DunkColors.primary : DunkColors.stroke),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: set ? Colors.white : DunkColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                set ? _formatTime(value!) : 'Tap to mark',
                style: TextStyle(
                  color: set ? Colors.white : DunkColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(Duration d) {
    final tenths = (d.inMilliseconds % 1000) ~/ 100;
    final seconds = d.inSeconds % 60;
    return '$seconds.${tenths}s';
  }
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
              PrimaryButton(label: 'TRY AGAIN', onPressed: onBack),
            ],
          ),
        ),
      ),
    );
  }
}

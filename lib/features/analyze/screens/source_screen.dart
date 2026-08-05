import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/video_attempt_type.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';

/// Entry point of the Analyze flow: film a jump or import an existing clip.
class SourceScreen extends StatefulWidget {
  final void Function(File video, VideoAttemptType attemptType) onVideoSelected;

  /// Set only for the pre-paywall "try it free" run — shows an "I'll do
  /// this later" skip link. Null in the normal Analyze-tab usage.
  final VoidCallback? onSkip;

  const SourceScreen({super.key, required this.onVideoSelected, this.onSkip});

  @override
  State<SourceScreen> createState() => _SourceScreenState();
}

class _SourceScreenState extends State<SourceScreen> {
  final _picker = ImagePicker();
  bool _busy = false;
  String? _error;
  VideoAttemptType _attemptType = VideoAttemptType.jumpAttempt;

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 10),
      );
      if (file != null) {
        widget.onVideoSelected(File(file.path), _attemptType);
      }
    } catch (_) {
      setState(() => _error = "Couldn't access the camera or library.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: DunkColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.monitor_heart_outlined,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ANALYZE',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Film your jump straight-on, full body in frame. We measure '
              'hang time to estimate your vertical — no calibration needed.',
              style: DunkTheme.onboardingSubtitle,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _AttemptTypeChip(
                    type: VideoAttemptType.dunkAttempt,
                    selected: _attemptType == VideoAttemptType.dunkAttempt,
                    onTap: () =>
                        setState(() => _attemptType = VideoAttemptType.dunkAttempt),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AttemptTypeChip(
                    type: VideoAttemptType.jumpAttempt,
                    selected: _attemptType == VideoAttemptType.jumpAttempt,
                    onTap: () =>
                        setState(() => _attemptType = VideoAttemptType.jumpAttempt),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: DunkColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: DunkColors.stroke),
                ),
                child: const Icon(Icons.videocam_outlined,
                    color: DunkColors.primary, size: 56),
              ),
            ),
            const Spacer(),
            if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
              const SizedBox(height: 12),
            ],
            PrimaryButton(
              label: _busy ? 'ONE SEC…' : 'RECORD A JUMP',
              trailingIcon: Icons.videocam,
              onPressed: _busy ? null : () => _pick(ImageSource.camera),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                child: const Text(
                  'Choose from library',
                  style: TextStyle(
                    color: DunkColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (widget.onSkip != null) ...[
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: _busy ? null : widget.onSkip,
                  child: const Column(
                    children: [
                      Text(
                        "I'll do this later",
                        style: TextStyle(
                          color: DunkColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'You can analyze anytime from the app.',
                        style: TextStyle(color: DunkColors.textTertiary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttemptTypeChip extends StatelessWidget {
  final VideoAttemptType type;
  final bool selected;
  final VoidCallback onTap;

  const _AttemptTypeChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? DunkColors.primary.withValues(alpha: 0.12) : DunkColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? DunkColors.primary : DunkColors.stroke,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type.title.toUpperCase(),
                style: TextStyle(
                  color: selected ? DunkColors.primary : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                type.subtitle,
                style: const TextStyle(color: DunkColors.textTertiary, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

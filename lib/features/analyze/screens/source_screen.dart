import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/video_attempt_type.dart';
import '../../../l10n/app_localizations.dart';
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

  /// A flag rather than a message, so the wording is resolved in [build].
  bool _failed = false;
  VideoAttemptType _attemptType = VideoAttemptType.jumpAttempt;

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _busy = true;
      _failed = false;
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
      setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                Text(
                  l10n.analyzeTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.analyzeIntro,
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
            if (_failed) ...[
              Text(
                l10n.analyzePickError,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
              const SizedBox(height: 12),
            ],
            PrimaryButton(
              label: _busy ? l10n.analyzeBusyCta : l10n.analyzeRecordCta,
              trailingIcon: Icons.videocam,
              onPressed: _busy ? null : () => _pick(ImageSource.camera),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                child: Text(
                  l10n.analyzeChooseLibrary,
                  style: const TextStyle(
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
                  child: Column(
                    children: [
                      Text(
                        l10n.analyzeSkip,
                        style: const TextStyle(
                          color: DunkColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.analyzeSkipSubtitle,
                        style: const TextStyle(
                            color: DunkColors.textTertiary, fontSize: 11),
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

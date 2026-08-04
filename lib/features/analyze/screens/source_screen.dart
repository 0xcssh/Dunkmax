import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';

/// Entry point of the Analyze flow: film a jump or import an existing clip.
class SourceScreen extends StatefulWidget {
  final ValueChanged<File> onVideoSelected;

  const SourceScreen({super.key, required this.onVideoSelected});

  @override
  State<SourceScreen> createState() => _SourceScreenState();
}

class _SourceScreenState extends State<SourceScreen> {
  final _picker = ImagePicker();
  bool _busy = false;
  String? _error;

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
        widget.onVideoSelected(File(file.path));
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
          ],
        ),
      ),
    );
  }
}

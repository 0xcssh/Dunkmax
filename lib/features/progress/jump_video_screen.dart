import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../theme/app_theme.dart';

/// Full-screen playback of a persisted jump clip, reached from Progress's
/// recent-analyses row, the full jump-history list or the Feed's own board.
/// A Share button hands off to the native share sheet — the user can save it
/// to Photos, AirDrop it, etc. from there, without this app needing separate
/// photo-library write permissions.
///
/// The clip arrives as an already-resolved [File], not as the string the jump
/// log stored: resolving a stored name against the current documents directory
/// is the caller's job (`services/media_file_resolver.dart`), and a jump whose
/// file is gone must never be given a play affordance in the first place.
class JumpVideoScreen extends StatefulWidget {
  final File videoFile;
  final int verticalInches;
  final DateTime recordedAt;

  const JumpVideoScreen({
    super.key,
    required this.videoFile,
    required this.verticalInches,
    required this.recordedAt,
  });

  @override
  State<JumpVideoScreen> createState() => _JumpVideoScreenState();
}

class _JumpVideoScreenState extends State<JumpVideoScreen> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  String? _error;

  /// The clip is normally there — the caller only offers playback for a file
  /// it resolved — but it can be deleted between the tap and this screen, so
  /// the Share action is only offered when the file is actually present.
  /// Offering it and failing on tap is exactly the silent no-op this screen
  /// used to produce.
  bool _canShare = false;
  bool _sharing = false;

  /// Anchors the iOS share sheet. iPadOS *requires* an origin rect for a
  /// popover and throws without one; deriving it from the button's own
  /// RenderBox puts the popover where the user tapped.
  final GlobalKey _shareButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _canShare = _fileExists();
    _controller = VideoPlayerController.file(widget.videoFile);
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _controller.play();
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _error = "Couldn't load this clip.");
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _fileExists() {
    try {
      return widget.videoFile.existsSync();
    } on FileSystemException {
      return false;
    }
  }

  Rect? _shareOrigin() {
    final box = _shareButtonKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DunkColors.surfaceRaised,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Awaited and guarded. Left fire-and-forget, a throw from the plugin (a
  /// missing file, a missing iPad anchor, a platform error) surfaced as
  /// nothing at all — the reported "Share does nothing".
  Future<void> _share() async {
    if (_sharing) return;
    if (!_fileExists()) {
      setState(() => _canShare = false);
      _showMessage('This clip is no longer on your device.');
      return;
    }
    setState(() => _sharing = true);
    try {
      await Share.shareXFiles(
        [XFile(widget.videoFile.path)],
        text: '${widget.verticalInches}" vertical — Dunk It',
        sharePositionOrigin: _shareOrigin(),
      );
    } catch (_) {
      _showMessage("Couldn't open the share sheet. Please try again.");
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DunkColors.background,
      appBar: AppBar(
        backgroundColor: DunkColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${widget.verticalInches}" · ${widget.recordedAt.month}/${widget.recordedAt.day}/${widget.recordedAt.year}',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_canShare)
            IconButton(
              key: _shareButtonKey,
              onPressed: _sharing ? null : _share,
              icon: const Icon(Icons.ios_share, color: Colors.white),
            ),
        ],
      ),
      body: SafeArea(
        child: _error != null
            ? Center(
                child: Text(_error!, style: DunkTheme.onboardingSubtitle),
              )
            : !_ready
                ? const Center(
                    child: CircularProgressIndicator(color: DunkColors.primary),
                  )
                : Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _controller.value.isPlaying ? _controller.pause() : _controller.play();
                        }),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(_controller),
                            if (!_controller.value.isPlaying)
                              const Icon(Icons.play_circle_fill, color: Colors.white70, size: 64),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}

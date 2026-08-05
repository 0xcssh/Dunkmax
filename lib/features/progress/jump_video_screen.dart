import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../theme/app_theme.dart';

/// Full-screen playback of a persisted jump clip, reached from Progress's
/// recent-analyses row or the full jump-history list. A Share button hands
/// off to the native share sheet — the user can save it to Photos, AirDrop
/// it, etc. from there, without this app needing separate photo-library
/// write permissions.
class JumpVideoScreen extends StatefulWidget {
  final String videoPath;
  final int verticalInches;
  final DateTime recordedAt;

  const JumpVideoScreen({
    super.key,
    required this.videoPath,
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

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath));
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

  void _share() {
    Share.shareXFiles(
      [XFile(widget.videoPath)],
      text: '${widget.verticalInches}" vertical — Dunk It',
    );
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
          IconButton(
            onPressed: _share,
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

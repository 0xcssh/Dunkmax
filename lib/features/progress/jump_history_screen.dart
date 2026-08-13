import 'package:flutter/material.dart';

import '../../core/models/jump_log_entry.dart';
import '../../l10n/app_localizations.dart';
import '../../services/media_file_resolver.dart';
import '../../theme/app_theme.dart';
import 'jump_video_screen.dart';

/// Full history of every logged jump, newest first — pushed from Progress's
/// "View All" on the recent-analyses row.
class JumpHistoryScreen extends StatelessWidget {
  final List<JumpLogEntry> entries;
  const JumpHistoryScreen({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sorted = [...entries]..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return Scaffold(
      appBar: AppBar(
        backgroundColor: DunkColors.background,
        title: Text(l10n.jumpHistoryTitle,
            style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: sorted.isEmpty
            ? Center(
                child: Text(l10n.jumpHistoryEmpty,
                    style: DunkTheme.onboardingSubtitle),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: sorted.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final entry = sorted[i];
                  // Stored names (or legacy absolute paths) are resolved
                  // against the CURRENT documents directory — see
                  // services/media_file_resolver.dart. A jump whose file is
                  // gone gets no play affordance rather than a dead tap.
                  final resolver = MediaFileResolver.instance;
                  final video = resolver.resolve(entry.videoPath);
                  final thumbnail = resolver.resolve(entry.thumbnailPath);
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: video == null
                        ? null
                        : () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => JumpVideoScreen(
                                videoFile: video,
                                verticalInches: entry.verticalInches,
                                recordedAt: entry.recordedAt,
                              ),
                            )),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DunkColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: DunkColors.stroke),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 64,
                              height: 64,
                              child: thumbnail != null
                                  ? Image.file(
                                      thumbnail,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: DunkColors.surfaceRaised,
                                        child: const Icon(Icons.videocam_off_outlined, color: DunkColors.textTertiary),
                                      ),
                                    )
                                  : Container(
                                      color: DunkColors.surfaceRaised,
                                      child: const Icon(Icons.videocam_off_outlined, color: DunkColors.textTertiary),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.inches(entry.verticalInches),
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.jumpDateFull(entry.recordedAt),
                                  style: const TextStyle(color: DunkColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

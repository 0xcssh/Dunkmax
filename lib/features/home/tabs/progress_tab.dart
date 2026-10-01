import 'package:flutter/material.dart';

import '../../../core/jump_trend.dart';
import '../../../core/models/jump_log_entry.dart';
import '../../../core/models/training_program.dart';
import '../../../core/program_progress.dart';
import '../../../core/workout_streak.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/jump_log_store.dart';
import '../../../services/media_file_resolver.dart';
import '../../../services/workout_session_store.dart';
import '../../../theme/app_theme.dart';
import '../../shared/layout_density.dart';
import '../../shared/unit_scope.dart';
import '../../shared/widgets/fit_or_scroll.dart';
import '../../progress/jump_history_screen.dart';
import '../../progress/jump_video_screen.dart';
import 'widgets/jump_trend_chart.dart';

/// PROGRESS tab: real numbers pulled from the persisted session + jump-log
/// stores, run through the pure core calculators (`ProgramProgress`,
/// `WorkoutStreak`, `JumpTrendCalculator`) so nothing here fabricates data.
class ProgressTab extends StatelessWidget {
  final TrainingProgram program;
  final WorkoutSessionStore sessionStore;
  final JumpLogStore jumpLogStore;
  final VoidCallback onGoToAnalyze;

  const ProgressTab({
    super.key,
    required this.program,
    required this.sessionStore,
    required this.jumpLogStore,
    required this.onGoToAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    final programSessions = sessionStore.sessions
        .where((s) => s.programId == program.id)
        .toList();
    final progress = ProgramProgress(
      totalSessions: program.totalSessions,
      completedSessions: programSessions.length,
    );
    // Streak counts ALL completed sessions regardless of program — it's a
    // training-habit metric, not scoped to whichever program is currently
    // recommended (the recommendation can change if the athlete's profile
    // changes, but their streak shouldn't reset because of that).
    final streak = WorkoutStreak.currentStreak(
      sessionStore.sessions.map((s) => s.completedAt).toList(),
    );
    final allJumpEntries = jumpLogStore.entries;
    final trend = JumpTrendCalculator.compute(allJumpEntries);
    final recentEntries = [...allJumpEntries]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final recentToShow = recentEntries.length > 5
        ? recentEntries.sublist(0, 5)
        : recentEntries;

    // Five blocks on one page above the tab bar: the headline vertical, the
    // trend chart, workouts and streak side by side, and the recent clips.
    // Nothing scrolls on the phones this is laid out for; a shorter phone
    // degrades to a scroll rather than a clip.
    final density = LayoutDensity.of(context);
    final gap = density.pick(10.0, 8.0);
    return SafeArea(
      child: FitOrScrollColumn(
        padding: EdgeInsets.fromLTRB(20, density.pick(12, 8), 20, 12),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context).progressTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: density.pick(12, 8)),
          _VerticalCard(trend: trend, onGoToAnalyze: onGoToAnalyze),
          SizedBox(height: gap),
          _TrendChartCard(entries: allJumpEntries),
          SizedBox(height: gap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: _WorkoutsCard(progress: progress)),
                SizedBox(width: gap),
                Expanded(flex: 2, child: _StreakCard(streak: streak)),
              ],
            ),
          ),
          if (allJumpEntries.isNotEmpty) ...[
            SizedBox(height: density.pick(14, 10)),
            _RecentAnalysesSection(
              allEntries: allJumpEntries,
              recentEntries: recentToShow,
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendChartCard extends StatelessWidget {
  final List<JumpLogEntry> entries;

  const _TrendChartCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final density = LayoutDensity.of(context);
    return Container(
      padding: EdgeInsets.all(density.pick(14, 10)),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: DunkColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).progressTrendTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: density.pick(10, 8)),
          JumpTrendChart(entries: entries, height: density.pick(120, 84)),
        ],
      ),
    );
  }
}

class _RecentAnalysesSection extends StatelessWidget {
  final List<JumpLogEntry> allEntries;
  final List<JumpLogEntry> recentEntries;

  const _RecentAnalysesSection({
    required this.allEntries,
    required this.recentEntries,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.videocam_outlined, color: DunkColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).progressRecentAnalyses,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => JumpHistoryScreen(entries: allEntries),
                  ),
                );
              },
              child: Text(
                AppLocalizations.of(context).progressViewAll,
                style: const TextStyle(
                  color: DunkColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: _RecentAnalysisThumb.height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recentEntries.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _RecentAnalysisThumb(entry: recentEntries[i]),
          ),
        ),
      ],
    );
  }
}

class _RecentAnalysisThumb extends StatelessWidget {
  final JumpLogEntry entry;

  const _RecentAnalysisThumb({required this.entry});

  static const double _thumbWidth = 96;
  static const double _thumbHeight = 62;

  /// Still plus its date line, so the strip can be sized without guessing.
  static const double height = _thumbHeight + 6 + 16;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final units = UnitScope.of(context);
    final date = entry.recordedAt;
    // What the entry stored is a file name (legacy entries: an absolute path),
    // resolved here against the current documents directory — the container
    // the app writes into is not stable across reinstalls on iOS. A jump whose
    // file no longer resolves is not tappable.
    final resolver = MediaFileResolver.instance;
    final video = resolver.resolve(entry.videoPath);
    final thumbnail = resolver.resolve(entry.thumbnailPath);
    return SizedBox(
      width: _thumbWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: video == null
                ? null
                : () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => JumpVideoScreen(
                        videoFile: video,
                        verticalInches: entry.verticalInches,
                        recordedAt: entry.recordedAt,
                      ),
                    )),
            child: SizedBox(
              width: _thumbWidth,
              height: _thumbHeight,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: _thumbWidth,
                      height: _thumbHeight,
                      child: thumbnail != null
                          ? Image.file(
                              thumbnail,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: DunkColors.surfaceRaised,
                                child: const Icon(
                                  Icons.videocam_off_outlined,
                                  color: DunkColors.textTertiary,
                                ),
                              ),
                            )
                          : Container(
                              color: DunkColors.surfaceRaised,
                              child: const Icon(
                                Icons.videocam_off_outlined,
                                color: DunkColors.textTertiary,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: DunkColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.length(units.name,
                            units.lengthValue(entry.verticalInches)),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.jumpDateShort(date),
            maxLines: 1,
            style: const TextStyle(
              color: DunkColors.textSecondary,
              fontSize: 11,
              height: 16 / 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalCard extends StatelessWidget {
  final JumpTrend? trend;
  final VoidCallback onGoToAnalyze;

  const _VerticalCard({required this.trend, required this.onGoToAnalyze});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final units = UnitScope.of(context);
    final trend = this.trend;
    final compact = LayoutDensity.of(context).isCompact;
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        gradient: DunkColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            l10n.progressCurrentVertical,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: trend == null
                      ? '—'
                      : l10n.length(units.name,
                          units.lengthValue(trend.latestVerticalInches)),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 40 : 46,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                if (trend == null)
                  TextSpan(
                    text: l10n.progressVertUnitSuffix(units.name),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (trend == null) ...[
            Text(
              l10n.progressLogFirstJump,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onGoToAnalyze,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: Text(
                l10n.progressGoToAnalyze,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ] else
            Text(
              trend.deltaFromFirstInches > 0
                  ? l10n.progressSinceFirstGain(units.name,
                      units.lengthValue(trend.deltaFromFirstInches))
                  : trend.deltaFromFirstInches < 0
                      ? l10n.progressSinceFirstLoss(units.name,
                          units.lengthValue(trend.deltaFromFirstInches))
                      : l10n.progressSinceFirstNoChange,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}

class _WorkoutsCard extends StatelessWidget {
  final ProgramProgress progress;

  const _WorkoutsCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = LayoutDensity.of(context).isCompact;
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center,
                  color: DunkColors.primary, size: 16),
              const SizedBox(width: 6),
              // Scaled down rather than cut: the French "JOURS D'AFFILÉE"
              // is wider than the narrow card.
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.progressWorkouts,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          // Three figures on one line: done · remaining · percent. They sit
          // where a row of three stat columns used to, so the streak can
          // share the row with this card.
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${progress.completedSessions}',
                style: const TextStyle(
                  color: DunkColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  l10n.progressCompleted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DunkColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            l10n.progressRemainingAndPercent(
              progress.remaining,
              progress.percentComplete,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DunkColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.fraction,
              minHeight: 6,
              backgroundColor: DunkColors.surfaceRaised,
              valueColor: const AlwaysStoppedAnimation(DunkColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streak;

  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = LayoutDensity.of(context).isCompact;
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: DunkColors.primary, size: 16),
              const SizedBox(width: 6),
              // Scaled down rather than cut: the French "JOURS D'AFFILÉE"
              // is wider than the narrow card.
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.progressDayStreak,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          // Scaled down rather than wrapped: the number and its unit are one
          // figure, and the card is narrow.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$streak',
                    style: const TextStyle(
                      color: DunkColors.primary,
                      fontSize: 34,
                      height: 1.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text: l10n.progressStreakDaysSuffix,
                    style: const TextStyle(
                      color: DunkColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/jump_trend.dart';
import '../../../core/models/jump_log_entry.dart';
import '../../../core/models/training_program.dart';
import '../../../core/program_progress.dart';
import '../../../core/workout_streak.dart';
import '../../../services/jump_log_store.dart';
import '../../../services/workout_session_store.dart';
import '../../../theme/app_theme.dart';
import '../../progress/jump_history_screen.dart';
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

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const Text(
            'PROGRESS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          _VerticalCard(trend: trend, onGoToAnalyze: onGoToAnalyze),
          const SizedBox(height: 16),
          _TrendChartCard(entries: allJumpEntries),
          const SizedBox(height: 16),
          _WorkoutsCard(progress: progress),
          const SizedBox(height: 16),
          _StreakCard(streak: streak),
          if (allJumpEntries.isNotEmpty) ...[
            const SizedBox(height: 24),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart, color: DunkColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'VERTICAL JUMP TREND',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          JumpTrendChart(entries: entries),
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
            const Text(
              'RECENT ANALYSES',
              style: TextStyle(
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
              child: const Text(
                'View All',
                style: TextStyle(
                  color: DunkColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
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

  @override
  Widget build(BuildContext context) {
    final date = entry.recordedAt;
    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            height: 90,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 110,
                    height: 90,
                    child: entry.thumbnailPath != null
                        ? Image.file(
                            File(entry.thumbnailPath!),
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
                      '${entry.verticalInches}"',
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
          const SizedBox(height: 6),
          Text(
            '${date.month}/${date.day}',
            style: const TextStyle(color: DunkColors.textSecondary, fontSize: 11),
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
    final trend = this.trend;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: DunkColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'CURRENT VERTICAL',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: trend == null ? '—' : '${trend.latestVerticalInches}"',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                if (trend == null)
                  const TextSpan(
                    text: '  in',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (trend == null) ...[
            const Text(
              'Log your first jump test to start tracking',
              style: TextStyle(color: Colors.white70, fontSize: 13),
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
              child: const Text(
                'Go to Analyze',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ] else
            Text(
              trend.deltaFromFirstInches > 0
                  ? '+${trend.deltaFromFirstInches}" since your first test'
                  : trend.deltaFromFirstInches < 0
                      ? '${trend.deltaFromFirstInches}" since your first test'
                      : 'No change since your first test',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fitness_center, color: DunkColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'WORKOUTS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(
                value: '${progress.completedSessions}',
                label: 'COMPLETED',
                color: DunkColors.primary,
              ),
              _Stat(
                value: '${progress.remaining}',
                label: 'REMAINING',
                color: Colors.white,
              ),
              _Stat(
                value: '${progress.percentComplete}%',
                label: 'COMPLETE',
                color: DunkColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.fraction,
              minHeight: 8,
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_fire_department, color: DunkColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'DAY STREAK',
                style: TextStyle(
                  color: DunkColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$streak',
                  style: const TextStyle(
                    color: DunkColors.primary,
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const TextSpan(
                  text: '  days',
                  style: TextStyle(
                    color: DunkColors.textSecondary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
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

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _Stat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: DunkColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

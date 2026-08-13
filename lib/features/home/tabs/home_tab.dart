import 'package:flutter/material.dart';

import '../../../core/jump_trend.dart';
import '../../../core/models/onboarding_profile.dart';
import '../../../core/models/training_program.dart';
import '../../../core/training_schedule.dart';
import '../../../core/workout_streak.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/jump_log_store.dart';
import '../../../services/workout_session_store.dart';
import '../../../theme/app_theme.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Landing tab: a DunkMax-style home dashboard — brand header, a 5-day
/// training strip, today's session hero card, and a quick-glance stats row.
/// Every number here comes from the real stores (or a pure calculator over
/// them); nothing is fabricated.
class HomeTab extends StatelessWidget {
  final OnboardingProfile profile;
  final TrainingProgram program;
  final WorkoutSessionStore sessionStore;
  final JumpLogStore jumpLogStore;
  final VoidCallback onStartTraining;
  final VoidCallback onOpenSettings;

  const HomeTab({
    super.key,
    required this.profile,
    required this.program,
    required this.sessionStore,
    required this.jumpLogStore,
    required this.onStartTraining,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final completedForProgram = sessionStore.sessions
        .where((s) => s.programId == program.id)
        .length;
    final currentSessionNumber =
        (completedForProgram + 1).clamp(1, program.totalSessions);
    final isProgramComplete = completedForProgram >= program.totalSessions;
    // Progressed, not the authored base — otherwise Home would advertise
    // week 1's set counts while the Train tab hands out week 4's.
    final schedule = TrainingSchedule(program);
    final today = schedule.prescriptionForSession(currentSessionNumber);
    final streak = WorkoutStreak.currentStreak(
      sessionStore.sessions.map((s) => s.completedAt).toList(),
    );
    final trend = JumpTrendCalculator.compute(jumpLogStore.entries);
    final weekNumber = schedule.weekOfSession(currentSessionNumber);
    final completedDaySet = sessionStore.sessions
        .map((s) => _dateOnly(s.completedAt))
        .toSet();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          _HeaderRow(streak: streak, onOpenSettings: onOpenSettings),
          const SizedBox(height: 20),
          _DayStrip(
            currentSessionNumber: currentSessionNumber,
            totalSessions: program.totalSessions,
            completedDaySet: completedDaySet,
            isProgramComplete: isProgramComplete,
          ),
          const SizedBox(height: 16),
          _HeroCard(
            today: today,
            weekNumber: weekNumber,
            currentSessionNumber: currentSessionNumber,
            totalSessions: program.totalSessions,
            isProgramComplete: isProgramComplete,
            onStartTraining: onStartTraining,
          ),
          const SizedBox(height: 16),
          _StatsRow(trend: trend, streak: streak),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final int streak;
  final VoidCallback onOpenSettings;

  const _HeaderRow({required this.streak, required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: DunkColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.sports_basketball, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'DUNK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 0.5,
                ),
              ),
              TextSpan(
                text: 'IT',
                style: TextStyle(
                  color: DunkColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: DunkColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DunkColors.stroke),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_fire_department, color: DunkColors.primary, size: 16),
              const SizedBox(width: 4),
              Text(
                '$streak',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: DunkColors.surface,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onOpenSettings,
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.settings_outlined, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

class _DayStrip extends StatelessWidget {
  final int currentSessionNumber;
  final int totalSessions;
  final Set<DateTime> completedDaySet;
  final bool isProgramComplete;

  const _DayStrip({
    required this.currentSessionNumber,
    required this.totalSessions,
    required this.completedDaySet,
    required this.isProgramComplete,
  });

  @override
  Widget build(BuildContext context) {
    final todayDate = _dateOnly(DateTime.now());
    final dates = List.generate(
      5,
      (i) => todayDate.add(Duration(days: i - 2)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)
                  .homeDayCounter(currentSessionNumber, totalSessions),
              style: const TextStyle(
                color: DunkColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: DunkColors.accentGreen.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                AppLocalizations.of(context).homeTodayBadge,
                style: const TextStyle(
                  color: DunkColors.accentGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final date in dates)
              _DayCard(
                date: date,
                isToday: date == todayDate,
                isPast: date.isBefore(todayDate),
                wasCompleted: completedDaySet.contains(date),
                isProgramComplete: isProgramComplete,
              ),
          ],
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final bool isPast;
  final bool wasCompleted;
  final bool isProgramComplete;

  const _DayCard({
    required this.date,
    required this.isToday,
    required this.isPast,
    required this.wasCompleted,
    required this.isProgramComplete,
  });

  @override
  Widget build(BuildContext context) {
    // Seven comma-separated single letters, Monday first — matches
    // DateTime.weekday, which is 1 = Monday.
    final weekdayInitials =
        AppLocalizations.of(context).weekdayInitials.split(',');
    late final Color bg;
    late final Widget statusIcon;
    Border? border;

    if (isToday) {
      statusIcon = Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(
          isProgramComplete ? Icons.nightlight_round : Icons.bolt,
          color: DunkColors.primaryDeep,
          size: 14,
        ),
      );
    } else if (isPast) {
      if (wasCompleted) {
        bg = DunkColors.surface;
        statusIcon = const Icon(Icons.check_circle, color: DunkColors.accentGreen, size: 22);
      } else {
        bg = Colors.red.withValues(alpha: 0.12);
        statusIcon = Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, color: Colors.redAccent, size: 14),
        );
      }
    } else {
      bg = DunkColors.surface;
      statusIcon = const Icon(Icons.nightlight_round, color: DunkColors.textTertiary, size: 20);
    }

    if (!isToday) {
      border = Border.all(color: DunkColors.stroke);
    }

    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: isToday ? DunkColors.primaryGradient : null,
        color: isToday ? null : bg,
        borderRadius: BorderRadius.circular(14),
        border: border,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            date.weekday - 1 < weekdayInitials.length
                ? weekdayInitials[date.weekday - 1]
                : '',
            style: TextStyle(
              color: isToday ? Colors.white70 : DunkColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          statusIcon,
          const SizedBox(height: 8),
          Text(
            '${date.day}',
            style: TextStyle(
              color: isToday ? Colors.white : DunkColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final ProgramDay today;
  final int weekNumber;
  final int currentSessionNumber;
  final int totalSessions;
  final bool isProgramComplete;
  final VoidCallback onStartTraining;

  const _HeroCard({
    required this.today,
    required this.weekNumber,
    required this.currentSessionNumber,
    required this.totalSessions,
    required this.isProgramComplete,
    required this.onStartTraining,
  });

  IconData get _focusIcon {
    switch (today.focus.toLowerCase()) {
      case 'power':
        return Icons.bolt;
      case 'strength':
        return Icons.fitness_center;
      case 'speed':
        return Icons.speed;
      default:
        return Icons.sports_basketball;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // `today.focus` comes from the untranslated program catalog.
    final headline = isProgramComplete
        ? l10n.homeProgramComplete
        : l10n.homeFocusDay(today.focus.toUpperCase());
    final ctaLabel = isProgramComplete
        ? l10n.homeCtaViewTrain
        : l10n.homeCtaStartSession;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: DunkColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isProgramComplete ? Icons.emoji_events : _focusIcon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w900,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isProgramComplete
                ? l10n.homeProgramCompleteBody
                : l10n.homeWeekSession(
                    weekNumber, currentSessionNumber, totalSessions),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (!isProgramComplete) ...[
            const SizedBox(height: 6),
            Text(
              today.warmUp,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onStartTraining,
              child: Container(
                height: 52,
                width: double.infinity,
                alignment: Alignment.center,
                child: Text(
                  ctaLabel,
                  style: const TextStyle(
                    color: DunkColors.primaryDeep,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final JumpTrend? trend;
  final int streak;

  const _StatsRow({required this.trend, required this.streak});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.straighten,
            value: trend == null ? '—' : l10n.inches(trend!.latestVerticalInches),
            label: l10n.homeLatestVert,
            trailing: trend != null && trend!.isImproving
                ? _GreenDelta(
                    text: l10n.inchesPlus(trend!.deltaFromFirstInches))
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department,
            value: '$streak',
            label: l10n.homeDayStreak,
          ),
        ),
      ],
    );
  }
}

class _GreenDelta extends StatelessWidget {
  final String text;

  const _GreenDelta({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: DunkColors.accentGreen.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: DunkColors.accentGreen,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Widget? trailing;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.trailing,
  });

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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: DunkColors.surfaceRaised,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: DunkColors.primary, size: 17),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: DunkColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

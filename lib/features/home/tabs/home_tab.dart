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
import '../../shared/layout_density.dart';
import '../../shared/unit_scope.dart';
import '../../shared/widgets/fit_or_scroll.dart';

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
    this.now,
  });

  /// The clock, for tests; null means [DateTime.now].
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    final programSessions =
        sessionStore.sessions.where((s) => s.programId == program.id).toList();
    final completedForProgram = programSessions.length;
    final currentSessionNumber =
        (completedForProgram + 1).clamp(1, program.totalSessions);
    final isProgramComplete = completedForProgram >= program.totalSessions;
    final todayDate = _dateOnly((now ?? DateTime.now)());
    // The same call, fed the same "already trained today?" fact, as the Train
    // tab — so the two can't disagree. Without it Home kept offering a full
    // START SESSION hero right after a session while Train showed a rest day.
    // The prescription it resolves is the progressed one, not the authored
    // base — otherwise Home would advertise week 1's set counts while the
    // Train tab hands out week 4's.
    final schedule = TrainingSchedule(program);
    final plan = schedule.today(
      completedSessions: completedForProgram,
      restToday:
          programSessions.any((s) => _dateOnly(s.completedAt) == todayDate),
    );
    final today = plan.day;
    final streak = WorkoutStreak.currentStreak(
      sessionStore.sessions.map((s) => s.completedAt).toList(),
    );
    final trend = JumpTrendCalculator.compute(jumpLogStore.entries);
    final weekNumber = schedule.weekOfSession(currentSessionNumber);
    final completedDaySet =
        sessionStore.sessions.map((s) => _dateOnly(s.completedAt)).toSet();
    // The day the athlete started training. A day before it was never
    // "missed" — there was nothing to miss yet.
    final firstLoggedDay = completedDaySet.isEmpty
        ? null
        : completedDaySet.reduce((a, b) => a.isBefore(b) ? a : b);

    // One page, all of it: header and the 5-day strip at their natural
    // height, then today's hero card and the two stat tiles share whatever
    // is left above the tab bar between the strip and the stat tiles, so a
    // tall phone gets a bigger hero rather than an empty band. A phone too
    // short for the natural heights scrolls instead. (One flexible child on
    // purpose: a Flex reports its intrinsic height by scaling every flexible
    // child to the largest height-per-flex among them, so two flexible
    // blocks in the wrong ratio make the page scroll on a phone it fits.)
    final density = LayoutDensity.of(context);
    return SafeArea(
      child: FitOrScrollColumn.fill(
        padding: EdgeInsets.fromLTRB(20, density.pick(12, 8), 20, 12),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderRow(streak: streak, onOpenSettings: onOpenSettings),
          SizedBox(height: density.pick(16, 12)),
          _DayStrip(
            currentSessionNumber: currentSessionNumber,
            totalSessions: program.totalSessions,
            todayDate: todayDate,
            completedDaySet: completedDaySet,
            firstLoggedDay: firstLoggedDay,
            trainingWeekdays: schedule.trainingWeekdays.toSet(),
            isProgramComplete: isProgramComplete,
          ),
          SizedBox(height: density.pick(14, 10)),
          Expanded(
            child: _HeroCard(
              today: today,
              weekNumber: weekNumber,
              currentSessionNumber: currentSessionNumber,
              totalSessions: program.totalSessions,
              isProgramComplete: isProgramComplete,
              isRestDay: plan.isRestDay,
              onStartTraining: onStartTraining,
            ),
          ),
          SizedBox(height: density.pick(14, 10)),
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
          child: const Icon(Icons.sports_basketball,
              color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        const Text.rich(
          TextSpan(
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
              const Icon(Icons.local_fire_department,
                  color: DunkColors.primary, size: 16),
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
              child:
                  Icon(Icons.settings_outlined, color: Colors.white, size: 20),
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
  final DateTime todayDate;
  final Set<DateTime> completedDaySet;

  /// Date of the first session ever logged, or null before any.
  final DateTime? firstLoggedDay;

  /// The weekdays the program trains on — the same placement the Train tab's
  /// week strip draws (TrainingSchedule.trainingWeekdays).
  final Set<int> trainingWeekdays;
  final bool isProgramComplete;

  const _DayStrip({
    required this.currentSessionNumber,
    required this.totalSessions,
    required this.todayDate,
    required this.completedDaySet,
    required this.firstLoggedDay,
    required this.trainingWeekdays,
    required this.isProgramComplete,
  });

  @override
  Widget build(BuildContext context) {
    // Calendar arithmetic rather than `add(Duration(days: n))`: across a
    // daylight-saving change a day is 23 or 25 hours, so a Duration step
    // leaves midnight and the date stops matching `completedDaySet` (or
    // repeats / skips a day). The constructor normalises out-of-range days.
    final dates = List.generate(
      5,
      (i) => DateTime(todayDate.year, todayDate.month, todayDate.day + i - 2),
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
        // Flexed, not fixed-width: five 60pt cards overflowed a 320pt screen.
        Row(
          children: [
            for (var i = 0; i < dates.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _DayCard(
                  date: dates[i],
                  status: HomeDayStatus.of(
                    date: dates[i],
                    today: todayDate,
                    completedDays: completedDaySet,
                    firstLoggedDay: firstLoggedDay,
                    trainingWeekdays: trainingWeekdays,
                  ),
                  isProgramComplete: isProgramComplete,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// What one card of Home's 5-day strip says about its date.
enum HomeDayStatus {
  /// The date is today.
  today,

  /// A session was logged that day.
  completed,

  /// A past day the schedule had a session on, on or after the athlete's
  /// first logged session, with nothing logged. The only status drawn red.
  missed,

  /// A past training day from before the first logged session: there was
  /// nothing to miss yet.
  beforeStart,

  /// A day the schedule does not train on, past or future.
  rest,

  /// A future day the schedule trains on.
  upcoming;

  /// The strip's verdict for [date].
  ///
  /// Rest days come from the same weekday placement the Train tab's week
  /// strip draws ([trainingWeekdays], i.e. TrainingSchedule.trainingWeekdays),
  /// so a scheduled rest day can never be drawn as missed — which is what
  /// Home used to do to every untrained past day, rest day or not.
  static HomeDayStatus of({
    required DateTime date,
    required DateTime today,
    required Set<DateTime> completedDays,
    required DateTime? firstLoggedDay,
    required Set<int> trainingWeekdays,
  }) {
    if (date == today) return HomeDayStatus.today;
    if (completedDays.contains(date)) return HomeDayStatus.completed;
    if (!trainingWeekdays.contains(date.weekday)) return HomeDayStatus.rest;
    if (date.isAfter(today)) return HomeDayStatus.upcoming;
    if (firstLoggedDay == null || date.isBefore(firstLoggedDay)) {
      return HomeDayStatus.beforeStart;
    }
    return HomeDayStatus.missed;
  }
}

class _DayCard extends StatelessWidget {
  final DateTime date;
  final HomeDayStatus status;
  final bool isProgramComplete;

  const _DayCard({
    required this.date,
    required this.status,
    required this.isProgramComplete,
  });

  @override
  Widget build(BuildContext context) {
    // Seven comma-separated single letters, Monday first — matches
    // DateTime.weekday, which is 1 = Monday.
    final weekdayInitials =
        AppLocalizations.of(context).weekdayInitials.split(',');
    final isToday = status == HomeDayStatus.today;
    var bg = DunkColors.surface;
    final Widget statusIcon;
    Border? border;

    switch (status) {
      case HomeDayStatus.today:
        statusIcon = Container(
          width: 22,
          height: 22,
          decoration:
              const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Icon(
            isProgramComplete ? Icons.nightlight_round : Icons.bolt,
            color: DunkColors.primaryDeep,
            size: 14,
          ),
        );
      case HomeDayStatus.completed:
        statusIcon = const Icon(Icons.check_circle,
            key: ValueKey('home-day-completed'),
            color: DunkColors.accentGreen,
            size: 22);
      case HomeDayStatus.missed:
        bg = Colors.red.withValues(alpha: 0.12);
        statusIcon = Container(
          key: const ValueKey('home-day-missed'),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, color: Colors.redAccent, size: 14),
        );
      case HomeDayStatus.beforeStart:
        statusIcon =
            const Icon(Icons.remove, color: DunkColors.textTertiary, size: 20);
      case HomeDayStatus.rest:
        statusIcon = const Icon(Icons.nightlight_round,
            key: ValueKey('home-day-rest'),
            color: DunkColors.textTertiary,
            size: 20);
      case HomeDayStatus.upcoming:
        statusIcon = const Icon(Icons.fitness_center,
            color: DunkColors.textSecondary, size: 18);
    }

    if (!isToday) {
      border = Border.all(color: DunkColors.stroke);
    }

    final compact = LayoutDensity.of(context).isCompact;
    return Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 7 : 9),
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
          SizedBox(height: compact ? 5 : 7),
          statusIcon,
          SizedBox(height: compact ? 5 : 7),
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

  /// A session was already logged today: the card goes muted and recommends
  /// recovery, exactly as the Train tab does. [today] is then the *next*
  /// session, still reachable through TRAIN ANYWAY.
  final bool isRestDay;
  final VoidCallback onStartTraining;

  const _HeroCard({
    required this.today,
    required this.weekNumber,
    required this.currentSessionNumber,
    required this.totalSessions,
    required this.isProgramComplete,
    required this.isRestDay,
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
    // A finished program outranks the rest state (the schedule never flags a
    // rest day once the program is complete, this just keeps it explicit).
    final resting = isRestDay && !isProgramComplete;
    final String headline;
    final String body;
    final String ctaLabel;
    if (isProgramComplete) {
      headline = l10n.homeProgramComplete;
      body = l10n.homeProgramCompleteBody;
      ctaLabel = l10n.homeCtaViewTrain;
    } else if (resting) {
      // The Train tab's own rest-day strings, so both tabs say the same thing.
      headline = l10n.trainRestDayTitle;
      body = l10n.trainRestDaySubtitle;
      ctaLabel = l10n.trainCtaTrainAnyway;
    } else {
      headline = l10n.homeFocusDay(today.focus.toUpperCase());
      body =
          l10n.homeWeekSession(weekNumber, currentSessionNumber, totalSessions);
      ctaLabel = l10n.homeCtaStartSession;
    }
    final secondary = resting ? DunkColors.textSecondary : Colors.white70;

    final compact = LayoutDensity.of(context).isCompact;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        gradient: resting ? null : DunkColors.primaryGradient,
        color: resting ? DunkColors.surface : null,
        borderRadius: BorderRadius.circular(24),
        border: resting ? Border.all(color: DunkColors.stroke) : null,
      ),
      child: Column(
        children: [
          // The page hands this card whatever height is spare: the message
          // centres in it and the button stays at its foot. With no spare
          // height both spacers are zero.
          const Spacer(),
          Container(
            width: compact ? 44 : 56,
            height: compact ? 44 : 56,
            decoration: BoxDecoration(
              color: resting
                  ? DunkColors.surfaceRaised
                  : Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isProgramComplete
                  ? Icons.emoji_events
                  : (resting ? Icons.nightlight_round : _focusIcon),
              color: resting ? DunkColors.primary : Colors.white,
              size: compact ? 24 : 28,
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 22 : 26,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(color: secondary, fontSize: 14),
          ),
          if (!isProgramComplete) ...[
            const SizedBox(height: 6),
            Text(
              resting
                  ? l10n.trainUpNext(today.focus.toUpperCase())
                  : today.warmUp,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: secondary, fontSize: 13),
            ),
          ],
          const Spacer(),
          SizedBox(height: compact ? 12 : 16),
          Material(
            color: resting ? Colors.transparent : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              // Muted like Train's TRAIN ANYWAY: recovery is recommended,
              // not enforced, so the button stays but stops shouting.
              side: resting
                  ? BorderSide(color: DunkColors.primary.withValues(alpha: 0.5))
                  : BorderSide.none,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onStartTraining,
              child: Container(
                height: compact ? 46 : 52,
                width: double.infinity,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    ctaLabel,
                    maxLines: 1,
                    style: TextStyle(
                      color:
                          resting ? DunkColors.primary : DunkColors.primaryDeep,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
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
    final units = UnitScope.of(context);
    // Both tiles as tall as the taller one.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.straighten,
              value: trend == null
                  ? '—'
                  : l10n.length(units.name,
                      units.lengthValue(trend!.latestVerticalInches)),
              label: l10n.homeLatestVert,
              trailing: trend != null && trend!.isImproving
                  ? _GreenDelta(
                      text: l10n.lengthPlus(units.name,
                          units.lengthValue(trend!.deltaFromFirstInches)))
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
      ),
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
    final compact = LayoutDensity.of(context).isCompact;
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: DunkColors.surfaceRaised,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: DunkColors.primary, size: 16),
          ),
          // Icon at the top, figure at the foot, whatever height the tile
          // is given.
          const Spacer(),
          SizedBox(height: compact ? 8 : 10),
          // One figure: scaled down as a unit rather than overflowing when a
          // long unit and the delta pill share a narrow tile.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 24 : 30,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
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

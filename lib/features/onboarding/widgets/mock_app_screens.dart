import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// Simplified, recognisable versions of three of the app's own surfaces,
/// drawn to fit [PhoneMockup.designSize] (210 × 440) and scaled from there.
///
/// The numbers in them are illustrative — they are obviously a picture of the
/// product, the way a product shot always is. What they must never do is claim
/// anything about *other people*: no rating, no ranking, no user count, no
/// "top N%" badge. This app has no user base yet, and invented social proof
/// has already been stripped out of onboarding twice (see CLAUDE.md).

/// The Analyze result: the measured vertical, the gap to a dunk, and the four
/// form scores.
class AnalysisMock extends StatelessWidget {
  const AnalysisMock({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MockScreen(
      children: [
        _MockLabel('JUMP ANALYSIS'),
        SizedBox(height: 8),
        _MockCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MockLabel('EST. VERT'),
              SizedBox(height: 2),
              Text(
                '29"',
                style: TextStyle(
                  fontSize: 44,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.trending_up, size: 11, color: DunkColors.primary),
                  SizedBox(width: 4),
                  Text(
                    '6" TO DUNK',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: DunkColors.primaryBright,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        _MockLabel('FORM SCORES'),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _ScoreTile(label: 'BOUNCE', value: 82)),
            SizedBox(width: 8),
            Expanded(child: _ScoreTile(label: 'POWER', value: 74)),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _ScoreTile(label: 'CONTROL', value: 68)),
            SizedBox(width: 8),
            Expanded(child: _ScoreTile(label: 'FORM', value: 77)),
          ],
        ),
        SizedBox(height: 12),
        _MockCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MockLabel('JUMP BREAKDOWN'),
              SizedBox(height: 8),
              _TextLine(widthFactor: 1),
              SizedBox(height: 5),
              _TextLine(widthFactor: 0.92),
              SizedBox(height: 5),
              _TextLine(widthFactor: 0.6),
            ],
          ),
        ),
        Spacer(),
      ],
    );
  }
}

/// The Train tab: the recommended program, where the week sits, and today's
/// prescription.
class PlanMock extends StatelessWidget {
  const PlanMock({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MockScreen(
      children: [
        _MockLabel('WEEK 2 · DAY 2 OF 3'),
        SizedBox(height: 8),
        _ProgramCard(),
        SizedBox(height: 12),
        _WeekStrip(),
        SizedBox(height: 14),
        _MockLabel('TODAY · POWER'),
        SizedBox(height: 8),
        _ExerciseRow(name: 'Depth Jumps', sets: '4 × 5'),
        SizedBox(height: 8),
        _ExerciseRow(name: 'Trap Bar Deadlift', sets: '4 × 5'),
        SizedBox(height: 8),
        _ExerciseRow(name: 'Pogo Hops', sets: '3 × 20'),
        Spacer(),
      ],
    );
  }
}

/// The Progress tab: the current vertical, how it moved, and the habit
/// metrics behind it.
class ProgressMock extends StatelessWidget {
  const ProgressMock({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MockScreen(
      children: [
        _MockLabel('PROGRESS'),
        SizedBox(height: 8),
        _MockCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MockLabel('CURRENT VERTICAL'),
              SizedBox(height: 2),
              Text(
                '31"',
                style: TextStyle(
                  fontSize: 38,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '+4" SINCE FIRST TEST',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: DunkColors.accentGreen,
                ),
              ),
              SizedBox(height: 12),
              _TrendBars(),
            ],
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatTile(label: 'WORKOUTS', value: '14/24')),
            SizedBox(width: 8),
            Expanded(child: _StatTile(label: 'DAY STREAK', value: '6')),
          ],
        ),
        Spacer(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared mock furniture. All sizes are in the 210-wide design space.
// ---------------------------------------------------------------------------

class _MockScreen extends StatelessWidget {
  final List<Widget> children;

  const _MockScreen({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Top inset clears the frame's notch.
      padding: const EdgeInsets.fromLTRB(12, 30, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _MockLabel extends StatelessWidget {
  final String text;

  const _MockLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: DunkColors.textTertiary,
      ),
    );
  }
}

class _MockCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _MockCard({
    required this.child,
    this.padding = const EdgeInsets.all(10),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: child,
    );
  }
}

class _ScoreTile extends StatelessWidget {
  final String label;
  final int value;

  const _ScoreTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return _MockCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MockLabel(label),
          const SizedBox(height: 3),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 3,
              child: Row(
                children: [
                  Expanded(
                    flex: value,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: DunkColors.primaryGradient,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 100 - value,
                    child: const ColoredBox(color: DunkColors.surfaceRaised),
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

class _TextLine extends StatelessWidget {
  final double widthFactor;

  const _TextLine({required this.widthFactor});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: 4,
          decoration: BoxDecoration(
            color: DunkColors.surfaceRaised,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: DunkColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VERTICAL FOUNDATION',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 7),
          Row(
            children: [
              _MiniBadge('3 DAYS'),
              SizedBox(width: 5),
              _MiniBadge('GYM'),
              SizedBox(width: 5),
              _MiniBadge('8 WEEKS'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String text;

  const _MiniBadge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 7,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip();

  // Mon/Wed/Fri, the 3-days-a-week layout the schedule actually produces.
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _training = [true, false, true, false, true, false, false];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _days.length; i++) ...[
          Expanded(
            child: Container(
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _training[i]
                    ? DunkColors.primary.withValues(alpha: 0.18)
                    : DunkColors.surface,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: _training[i] ? DunkColors.primary : DunkColors.stroke,
                ),
              ),
              child: Text(
                _days[i],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: _training[i]
                      ? DunkColors.primaryBright
                      : DunkColors.textTertiary,
                ),
              ),
            ),
          ),
          if (i < _days.length - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final String name;
  final String sets;

  const _ExerciseRow({required this.name, required this.sets});

  @override
  Widget build(BuildContext context) {
    return _MockCard(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.bolt, size: 12, color: DunkColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            sets,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: DunkColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendBars extends StatelessWidget {
  const _TrendBars();

  static const _heights = [16.0, 21.0, 19.0, 27.0, 31.0, 38.0];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < _heights.length; i++) ...[
            Expanded(
              child: Container(
                height: _heights[i],
                decoration: BoxDecoration(
                  gradient: i == _heights.length - 1
                      ? DunkColors.primaryGradient
                      : null,
                  color: i == _heights.length - 1
                      ? null
                      : DunkColors.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            if (i < _heights.length - 1) const SizedBox(width: 5),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return _MockCard(
      padding: const EdgeInsets.all(9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MockLabel(label),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

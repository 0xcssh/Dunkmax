import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../widgets/onboarding_scaffold.dart';

class DaysPerWeekScreen extends StatelessWidget {
  final int? selected;
  final ValueChanged<int> onSelect;
  final VoidCallback? onContinue;
  final VoidCallback onBack;
  final int step;
  final int totalSteps;

  const DaysPerWeekScreen({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onContinue,
    required this.onBack,
    required this.step,
    required this.totalSteps,
  });

  // Value paired with the label shown ("5+" maps to 5).
  static const _options = [(2, '2'), (3, '3'), (4, '4'), (5, '5+')];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OnboardingScaffold(
      step: step,
      totalSteps: totalSteps,
      title: l10n.daysTitle,
      subtitle: l10n.daysSubtitle,
      onBack: onBack,
      onContinue: selected == null ? null : onContinue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _MotivationBanner(),
          const SizedBox(height: 16),
          Expanded(
            child: _DayGrid(
              selected: selected,
              onSelect: onSelect,
            ),
          ),
        ],
      ),
    );
  }
}

/// The four choices, laid out to use the height the step has.
///
/// With room for it — any 844 pt phone, and the SE — they are a 2x2 grid of
/// big tiles that fills the body down to the CTA. Only when the body is too
/// short for two rows of [_minGridTile] do they fall back to the single row
/// of narrow chips.
class _DayGrid extends StatelessWidget {
  final int? selected;
  final ValueChanged<int> onSelect;

  const _DayGrid({required this.selected, required this.onSelect});

  static const double _gap = 12;
  static const double _minGridTile = 96;

  /// A tile taller than this stops looking like a button.
  static const double _maxGridTile = 200;

  Widget _chip(int value, String label) => _DayChip(
        label: label,
        selected: selected == value,
        onTap: () => onSelect(value),
      );

  @override
  Widget build(BuildContext context) {
    const options = DaysPerWeekScreen._options;
    return LayoutBuilder(
      builder: (context, constraints) {
        final tile =
            ((constraints.maxHeight - _gap) / 2).clamp(0.0, _maxGridTile);
        if (tile < _minGridTile) {
          return Align(
            alignment: Alignment.topCenter,
            child: Row(
              children: [
                for (final (value, label) in options) ...[
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 0.82,
                      child: _chip(value, label),
                    ),
                  ),
                  if (value != options.last.$1) const SizedBox(width: _gap),
                ],
              ],
            ),
          );
        }
        Widget row(int from) => SizedBox(
              height: tile,
              child: Row(
                children: [
                  Expanded(child: _chip(options[from].$1, options[from].$2)),
                  const SizedBox(width: _gap),
                  Expanded(
                    child: _chip(options[from + 1].$1, options[from + 1].$2),
                  ),
                ],
              ),
            );
        return Column(
          children: [row(0), const SizedBox(height: _gap), row(2)],
        );
      },
    );
  }
}

class _MotivationBanner extends StatelessWidget {
  const _MotivationBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: DunkColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DunkColors.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department,
              color: DunkColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            // "Athletes who train 4+ days see results 2x faster" used to sit
            // here. There is no study behind that number and no user base to
            // draw it from — it was invented to make a nudge sound
            // authoritative, which is the same rule the fake ratings and
            // testimonials were removed under. What replaces it is true of
            // any training programme and claims no measurement.
            child: Text(
              AppLocalizations.of(context).daysBanner,
              style: const TextStyle(
                color: DunkColors.primaryBright,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox.expand(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: DunkColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? DunkColors.primary : DunkColors.stroke,
                width: selected ? 1.6 : 1,
              ),
            ),
            // Scaled down as one unit if the chip is ever shorter than its
            // three rows (a narrow phone makes the square small, and the
            // number used to overflow it by a hair).
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    // Sized for the big grid tile; the FittedBox above scales
                    // it down in the narrow single-row chips.
                    style: TextStyle(
                      fontSize: 44,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: selected ? DunkColors.primary : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context).daysChipUnit,
                    style: const TextStyle(
                        color: DunkColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  if (selected)
                    const Icon(Icons.check_circle,
                        color: DunkColors.primary, size: 22)
                  else
                    const SizedBox(height: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

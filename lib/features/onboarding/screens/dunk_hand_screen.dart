import 'package:flutter/material.dart';

import '../../../core/models/dunk_hand.dart';
import '../../../core/vert_assessment.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/staggered_entrance.dart';

/// "Which hand do you dunk with?" — two square cards (left / right) with a
/// wider both-hands card beneath, matching the reference layout.
///
/// The copy deliberately does not promise an "approach angle analysis" the way
/// the reference app does: nothing here analyses approach angle. What the
/// answer really changes is how far above the rim the finish has to get, and
/// therefore the vertical target — see [VertAssessment.dunkClearanceFor].
class DunkHandScreen extends StatelessWidget {
  final DunkHand? selected;
  final ValueChanged<DunkHand> onSelect;
  final VoidCallback? onContinue;
  final VoidCallback onBack;
  final int step;
  final int totalSteps;

  const DunkHandScreen({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onContinue,
    required this.onBack,
    required this.step,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OnboardingScaffold(
      step: step,
      totalSteps: totalSteps,
      title: l10n.dunkHandTitle,
      subtitle: l10n.dunkHandSubtitle,
      onBack: onBack,
      onContinue: selected == null ? null : onContinue,
      staggerBody: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: StaggerItem(
                    index: OnboardingScaffold.bodyStaggerIndex,
                    child: _HandCard(
                      hand: DunkHand.left,
                      selected: selected == DunkHand.left,
                      onTap: () => onSelect(DunkHand.left),
                      square: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StaggerItem(
                    index: OnboardingScaffold.bodyStaggerIndex + 1,
                    child: _HandCard(
                      hand: DunkHand.right,
                      selected: selected == DunkHand.right,
                      onTap: () => onSelect(DunkHand.right),
                      square: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StaggerItem(
              index: OnboardingScaffold.bodyStaggerIndex + 2,
              child: _HandCard(
                hand: DunkHand.both,
                selected: selected == DunkHand.both,
                onTap: () => onSelect(DunkHand.both),
                square: false,
              ),
            ),
            const SizedBox(height: 16),
            StaggerItem(
              index: OnboardingScaffold.bodyStaggerIndex + 3,
              child: const _ClearanceNote(),
            ),
          ],
        ),
      ),
    );
  }
}

/// One option. The square variant is the side-by-side left/right card (icon
/// above the label); the wide variant is the both-hands card beneath it, which
/// lays out like the selectable cards used elsewhere in the quiz.
class _HandCard extends StatelessWidget {
  final DunkHand hand;
  final bool selected;
  final VoidCallback onTap;
  final bool square;

  const _HandCard({
    required this.hand,
    required this.selected,
    required this.onTap,
    required this.square,
  });

  @override
  Widget build(BuildContext context) {
    final border = BorderRadius.circular(16);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: border,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            color: DunkColors.surface,
            borderRadius: border,
            border: Border.all(
              color: selected ? DunkColors.primary : DunkColors.stroke,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: square ? _squareBody() : _wideBody(),
        ),
      ),
    );
  }

  Widget _squareBody() {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HandGlyph(hand: hand, selected: selected),
                const SizedBox(height: 16),
                Text(hand.title, style: DunkTheme.cardTitle),
                const SizedBox(height: 2),
                // One line only: the square card has a fixed height and the
                // one-hand caption is short enough not to need wrapping.
                Text(
                  hand.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: DunkColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: _Check(selected: selected),
          ),
        ],
      ),
    );
  }

  Widget _wideBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        children: [
          _HandGlyph(hand: hand, selected: selected),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(hand.title, style: DunkTheme.cardTitle),
                const SizedBox(height: 2),
                Text(hand.subtitle, style: DunkTheme.cardSubtitle),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _Check(selected: selected),
        ],
      ),
    );
  }
}

/// The icon badge. One hand for a one-hand finish, two for a two-hand one —
/// mirrored so the left card genuinely reads as a left hand. Material icons
/// only; the reference screenshot uses emoji hands and this app does not.
class _HandGlyph extends StatelessWidget {
  final DunkHand hand;
  final bool selected;

  const _HandGlyph({required this.hand, required this.selected});

  @override
  Widget build(BuildContext context) {
    final tint = selected ? DunkColors.primary : DunkColors.accentPurple;
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: hand.isTwoHanded
          ? Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 4,
                  child: _Palm(tint: tint, mirrored: true, size: 20),
                ),
                Positioned(
                  right: 4,
                  child: _Palm(tint: tint, mirrored: false, size: 20),
                ),
              ],
            )
          : _Palm(
              tint: tint,
              mirrored: hand == DunkHand.left,
              size: 24,
            ),
    );
  }
}

class _Palm extends StatelessWidget {
  final Color tint;
  final bool mirrored;
  final double size;

  const _Palm({required this.tint, required this.mirrored, required this.size});

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.back_hand, color: tint, size: size);
    if (!mirrored) return icon;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(-1, 1, 1),
      child: icon,
    );
  }
}

class _Check extends StatelessWidget {
  final bool selected;
  const _Check({required this.selected});

  @override
  Widget build(BuildContext context) {
    if (!selected) {
      return const SizedBox(width: 26, height: 26);
    }
    return Container(
      width: 26,
      height: 26,
      decoration: const BoxDecoration(
        color: DunkColors.primary,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, size: 17, color: Colors.black),
    );
  }
}

/// States the actual consequence, with the real number rather than a vague
/// "this personalises your plan".
class _ClearanceNote extends StatelessWidget {
  const _ClearanceNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.straighten, color: DunkColors.textTertiary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            AppLocalizations.of(context)
                .dunkHandClearanceNote(VertAssessment.twoHandExtraClearance),
            style: const TextStyle(
              color: DunkColors.textTertiary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

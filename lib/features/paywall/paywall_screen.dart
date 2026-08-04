import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../shared/widgets/primary_button.dart';

/// Presentation-only paywall. Real StoreKit/RevenueCat wiring is a follow-up
/// (see DUNKMAX.md) — for now the CTA and the close button both continue into
/// the app so the flow is fully walkable on device.
class PaywallScreen extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onContinue;

  const PaywallScreen({
    super.key,
    required this.onClose,
    required this.onContinue,
  });

  static const _benefits = [
    ('Personalized week-by-week program', Icons.calendar_month),
    ('Guided plyometric & strength drills', Icons.fitness_center),
    ('Track your vertical over time', Icons.trending_up),
    ('Position-tailored exercise picks', Icons.sports_basketball),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.2,
            colors: [Color(0xFF241109), DunkColors.background],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close,
                        color: DunkColors.textSecondary, size: 26),
                  ),
                ),
                const Spacer(),
                const Text(
                  'UNLOCK YOUR\nFULL PROGRAM',
                  style: TextStyle(
                    fontSize: 34,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                for (final (label, icon) in _benefits) ...[
                  _BenefitRow(label: label, icon: icon),
                  const SizedBox(height: 14),
                ],
                const Spacer(),
                const Text(
                  '3-day free trial, then 2,99 €/week. Cancel anytime.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: DunkColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'START FREE TRIAL',
                  trailingIcon: null,
                  onPressed: onContinue,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onClose,
                  child: const Text(
                    'Maybe later',
                    style: TextStyle(color: DunkColors.textTertiary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String label;
  final IconData icon;

  const _BenefitRow({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: DunkColors.primary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: DunkColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

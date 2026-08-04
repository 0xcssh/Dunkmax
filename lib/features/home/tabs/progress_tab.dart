import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// PROGRESS tab: a lightweight overview. Real jump-height logging is a
/// follow-up (see DUNKMAX.md); for now it frames the metric the app is about.
class ProgressTab extends StatelessWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context) {
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
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: DunkColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: DunkColors.stroke),
            ),
            child: Column(
              children: [
                const Text(
                  'CURRENT VERTICAL',
                  style: TextStyle(
                    color: DunkColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: '—',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(
                        text: '  in',
                        style: TextStyle(
                          color: DunkColors.textSecondary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Log your first jump test to start tracking',
                  style: TextStyle(color: DunkColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

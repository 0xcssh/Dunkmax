import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';

/// Social-proof screen.
///
/// ⚠️ PLACEHOLDER CONTENT — the rating figure and the testimonials below are
/// stand-ins to lock the layout. Before App Store submission they MUST be
/// replaced with genuine data: a real aggregate rating (or removed) and real
/// user testimonials. Shipping a fabricated "4.8 · N App Store ratings" on a
/// brand-new app is misleading and violates App Store Review guidelines.
/// Swap [_ratingValue], [_ratingCount] and [_testimonials] once real reviews
/// exist.
class SocialProofScreen extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const SocialProofScreen({
    super.key,
    required this.onContinue,
    required this.onBack,
  });

  // TODO(before-submission): replace with the real App Store rating or remove.
  static const _ratingValue = '4.8';
  static const _ratingCount = 'Early access';

  // TODO(before-submission): replace with real, attributable testimonials.
  static const _testimonials = <(String, String)>[
    ("Great vert analysis and actionable tips.", 'I\'m Getting Bouncy'),
    ('Vert estimate was accurate. Doing the 8-week beginner plan.', 'Solid Tips'),
    ('Best vert trainer I\'ve used.', 'Helped My Vert'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: onBack,
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const Text('RATED BY HOOPERS\nLIKE YOU', style: DunkTheme.onboardingTitle),
                    const SizedBox(height: 18),
                    _RatingBadge(value: _ratingValue, count: _ratingCount),
                    const SizedBox(height: 20),
                    for (final (quote, author) in _testimonials) ...[
                      _ReviewCard(quote: quote, author: author),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(label: 'START MY PLAN', onPressed: onContinue),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final String value;
  final String count;
  const _RatingBadge({required this.value, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: DunkColors.primary, size: 20),
              Icon(Icons.star, color: DunkColors.primary, size: 20),
              Icon(Icons.star, color: DunkColors.primary, size: 20),
              Icon(Icons.star, color: DunkColors.primary, size: 20),
              Icon(Icons.star, color: DunkColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(count,
              style: const TextStyle(color: DunkColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String quote;
  final String author;
  const _ReviewCard({required this.quote, required this.author});

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
              Icon(Icons.star, color: DunkColors.primary, size: 15),
              Icon(Icons.star, color: DunkColors.primary, size: 15),
              Icon(Icons.star, color: DunkColors.primary, size: 15),
              Icon(Icons.star, color: DunkColors.primary, size: 15),
              Icon(Icons.star, color: DunkColors.primary, size: 15),
            ],
          ),
          const SizedBox(height: 8),
          Text('"$quote"',
              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.3)),
          const SizedBox(height: 6),
          Text('— $author',
              style: const TextStyle(color: DunkColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

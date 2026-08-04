import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// Shared "coming soon" state for tabs not yet built out (Analyze, Feed).
class PlaceholderTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;

  const PlaceholderTab({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: DunkColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: DunkColors.primary, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: DunkTheme.onboardingSubtitle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

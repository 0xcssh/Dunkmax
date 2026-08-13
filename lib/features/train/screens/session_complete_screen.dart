import 'package:flutter/material.dart';

import '../../../core/models/workout_session.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';

/// Final step of [SessionFlow]: a summary of what was logged, then saves
/// the session and hands control back to the TRAIN tab.
class SessionCompleteScreen extends StatelessWidget {
  final List<LoggedExercise> loggedExercises;
  final VoidCallback onFinish;

  const SessionCompleteScreen({
    super.key,
    required this.loggedExercises,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Center(
              child: Icon(Icons.check_circle, color: DunkColors.primary, size: 64),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(l10n.sessionCompleteTitle,
                  style: DunkTheme.onboardingTitle),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                l10n.sessionCompleteSubtitle,
                style: DunkTheme.onboardingSubtitle,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DunkColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DunkColors.stroke),
                ),
                child: ListView.separated(
                  itemCount: loggedExercises.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: DunkColors.stroke, height: 20),
                  itemBuilder: (context, i) {
                    final e = loggedExercises[i];
                    return Text(
                      // The drill name comes from the untranslated exercise
                      // library.
                      l10n.sessionCompleteRow(
                          e.exerciseName, e.sets.length, e.totalReps),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: l10n.sessionCompleteCta, onPressed: onFinish),
          ],
        ),
      ),
    );
  }
}

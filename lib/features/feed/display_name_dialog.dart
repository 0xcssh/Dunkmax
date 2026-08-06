import 'package:flutter/material.dart';

import '../../core/models/leaderboard_athlete.dart';
import '../../theme/app_theme.dart';

/// Asks the athlete for the name they want on the global board.
///
/// Returns the sanitised name, or null if they backed out. The name is the
/// consent gate for the leaderboard: until one exists, nothing about this
/// athlete is ever sent to the backend.
Future<String?> showDisplayNameDialog(
  BuildContext context, {
  required String initialName,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _DisplayNameDialog(initialName: initialName),
  );
}

class _DisplayNameDialog extends StatefulWidget {
  final String initialName;

  const _DisplayNameDialog({required this.initialName});

  @override
  State<_DisplayNameDialog> createState() => _DisplayNameDialogState();
}

class _DisplayNameDialogState extends State<_DisplayNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName);
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _isValid =
        LeaderboardAthlete.sanitizeDisplayName(widget.initialName) != null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final sanitized =
        LeaderboardAthlete.sanitizeDisplayName(_controller.text);
    if (sanitized == null) return;
    Navigator.of(context).pop(sanitized);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DunkColors.surface,
      title: const Text(
        'Your board name',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This is the only thing other athletes see. Your clips never '
            'leave this phone.',
            style: TextStyle(color: DunkColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: LeaderboardAthlete.maxDisplayNameLength,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            cursorColor: DunkColors.primary,
            onChanged: (value) {
              final valid =
                  LeaderboardAthlete.sanitizeDisplayName(value) != null;
              if (valid != _isValid) setState(() => _isValid = valid);
            },
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'e.g. Marcus',
              hintStyle: const TextStyle(color: DunkColors.textTertiary),
              counterStyle: const TextStyle(color: DunkColors.textTertiary),
              filled: true,
              fillColor: DunkColors.surfaceRaised,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: DunkColors.stroke),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: DunkColors.primary),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: DunkColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: _isValid ? _submit : null,
          child: Text(
            'Save',
            style: TextStyle(
              color: _isValid ? DunkColors.primary : DunkColors.textTertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

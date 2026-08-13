import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the ARB catalogues themselves.
///
/// `flutter gen-l10n` will happily emit a locale that silently falls back to
/// the template for every key it is missing, so a half-translated French
/// catalogue compiles and ships. These tests fail instead — which is the whole
/// point of shipping only locales that were actually authored (CLAUDE.md: no
/// machine translations passed off as authored ones).
Map<String, dynamic> _load(String locale) {
  final file = File('lib/l10n/app_$locale.arb');
  expect(file.existsSync(), isTrue, reason: '${file.path} is missing');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

/// Placeholder names as they appear in an ICU message, including the count
/// variable of a plural (`{count, plural, ...}`).
Set<String> _placeholders(String message) =>
    RegExp(r'\{(\w+)[,}]').allMatches(message).map((m) => m.group(1)!).toSet();

void main() {
  final en = _load('en');
  final fr = _load('fr');
  final keys = en.keys.where((k) => !k.startsWith('@')).toList();

  test('the template catalogue is not empty', () {
    expect(keys, isNotEmpty);
  });

  test('every message carries a description for the next translator', () {
    final undocumented = [
      for (final key in keys)
        if ((en['@$key'] as Map<String, dynamic>?)?['description'] == null) key,
    ];
    expect(undocumented, isEmpty,
        reason: 'add "@$undocumented": {"description": ...} to app_en.arb');
  });

  test('French covers the template exactly — no gaps, no orphans', () {
    final frKeys = fr.keys.where((k) => !k.startsWith('@')).toSet();
    expect(keys.where((k) => !frKeys.contains(k)), isEmpty,
        reason: 'untranslated keys would silently fall back to English');
    expect(frKeys.difference(keys.toSet()), isEmpty,
        reason: 'these French keys no longer exist in the template');
  });

  test('translations keep the placeholders their message needs', () {
    for (final key in keys) {
      final source = en[key] as String;
      final target = fr[key] as String?;
      if (target == null) continue;
      expect(_placeholders(target), _placeholders(source),
          reason: 'placeholder mismatch on "$key"');
    }
  });

  test('declared placeholders match the ones the message actually uses', () {
    for (final key in keys) {
      final meta = en['@$key'] as Map<String, dynamic>?;
      final declared =
          ((meta?['placeholders'] as Map<String, dynamic>?) ?? const {})
              .keys
              .toSet();
      expect(declared, _placeholders(en[key] as String),
          reason: 'undeclared placeholders become Object parameters on "$key"');
    }
  });
}

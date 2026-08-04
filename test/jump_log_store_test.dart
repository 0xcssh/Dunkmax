import 'package:dunkmax/core/models/jump_log_entry.dart';
import 'package:dunkmax/services/jump_log_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  JumpLogEntry entry(int inches) => JumpLogEntry(
        verticalInches: inches,
        recordedAt: DateTime(2026, 1, inches),
      );

  test('fresh store has no entries', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await JumpLogStore.load();

    expect(store.entries, isEmpty);
  });

  test('added entry survives a simulated app restart', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await JumpLogStore.load();

    await store.addEntry(entry(24));

    final restarted = await JumpLogStore.load();
    expect(restarted.entries, hasLength(1));
    expect(restarted.entries.first.verticalInches, 24);
  });

  test('multiple entries accumulate in order', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await JumpLogStore.load();

    await store.addEntry(entry(20));
    await store.addEntry(entry(22));
    await store.addEntry(entry(25));

    expect(store.entries.map((e) => e.verticalInches).toList(), [20, 22, 25]);
  });

  test('reset clears the list back to empty', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await JumpLogStore.load();

    await store.addEntry(entry(24));
    expect(store.entries, isNotEmpty);

    await store.reset();
    expect(store.entries, isEmpty);
  });
}

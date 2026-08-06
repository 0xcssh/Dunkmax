import 'package:dunkmax/services/athlete_profile_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults to no name, so nothing is ever published by accident',
      () async {
    final store = await AthleteProfileStore.load();

    expect(store.displayName, '');
    expect(store.hasDisplayName, isFalse);
  });

  test('stores a sanitised name', () async {
    final store = await AthleteProfileStore.load();
    await store.setDisplayName('  Big   Mike  ');

    expect(store.displayName, 'Big Mike');
    expect(store.hasDisplayName, isTrue);
  });

  test('a blank name clears the stored value instead of persisting junk',
      () async {
    final store = await AthleteProfileStore.load();
    await store.setDisplayName('Marcus');
    await store.setDisplayName('   ');

    expect(store.displayName, '');
    expect(store.hasDisplayName, isFalse);
  });

  test('reset removes the name', () async {
    final store = await AthleteProfileStore.load();
    await store.setDisplayName('Marcus');
    await store.reset();

    expect(store.hasDisplayName, isFalse);
  });
}

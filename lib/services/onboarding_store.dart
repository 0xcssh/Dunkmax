import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/onboarding_profile.dart';

/// Thin persistence wrapper around shared_preferences. All the shape/parsing
/// logic lives in [OnboardingProfile]; this only reads and writes strings.
class OnboardingStore {
  static const _completedKey = 'onboarding_completed_v1';
  static const _profileKey = 'onboarding_profile_v1';

  final SharedPreferences _prefs;

  OnboardingStore(this._prefs);

  static Future<OnboardingStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    return OnboardingStore(prefs);
  }

  bool get hasCompletedOnboarding => _prefs.getBool(_completedKey) ?? false;

  OnboardingProfile? get profile {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return null;
    return OnboardingProfile.fromJson(raw);
  }

  Future<void> complete(OnboardingProfile profile) async {
    await _prefs.setString(_profileKey, profile.toJson());
    await _prefs.setBool(_completedKey, true);
  }

  Future<void> reset() async {
    await _prefs.remove(_completedKey);
    await _prefs.remove(_profileKey);
  }
}

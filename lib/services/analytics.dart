import 'package:flutter/foundation.dart';
import 'package:telemetrydecksdk/telemetrydecksdk.dart';

/// Product analytics through TelemetryDeck: anonymous counts only — no user
/// identifier, no ATT prompt, nothing that could be linked to a person (the
/// same rules as RepLock's). Every signal goes through this class, so the SDK
/// is referenced in exactly one file and the whole event vocabulary lives in
/// [AnalyticsEvent].
///
/// App Store privacy answers must declare "Product Interaction" as collected,
/// NOT linked to identity, NOT used for tracking; the privacy policy
/// (0xcssh/dunkit-legal) names TelemetryDeck.
///
/// Inert — every call a no-op — while [appID] is empty, on the web preview
/// (the plugin has no web implementation) and in tests (no platform channel).
/// A failure inside the SDK is swallowed: analytics must never cost a frame
/// or a crash.
abstract final class Analytics {
  /// TelemetryDeck App ID (dashboard → app → Settings). Like the RevenueCat
  /// public key it ships in the binary by design: it only allows sending.
  static const appID = '853467F7-BB94-4365-AAA4-D05CBC69165A';

  static bool _started = false;

  static bool get _enabled => appID.isNotEmpty && !kIsWeb;

  /// Call once, as early as possible in the app's life.
  static Future<void> start() async {
    if (!_enabled || _started) return;
    try {
      await Telemetrydecksdk.start(const TelemetryManagerConfiguration(
        appID: appID,
        // Debug builds land in TelemetryDeck's test-mode bucket, so local
        // runs never pollute the real numbers.
        testMode: kDebugMode,
      ));
      _started = true;
    } catch (_) {
      // No SDK, no analytics; the app is unaffected.
    }
  }

  static void track(AnalyticsEvent event,
      [Map<String, Object?> parameters = const {}]) {
    if (!_started) return;
    final payload = {
      for (final e in parameters.entries)
        if (e.value != null) e.key: '${e.value}',
    };
    Telemetrydecksdk.send(event.signal, additionalPayload: payload)
        .catchError((Object _) {});
  }
}

/// The whole vocabulary. Dotted names group in the dashboard; the comment on
/// each is the parameter set it carries — keep both in step.
enum AnalyticsEvent {
  // Lifecycle
  appLaunched('App.launched'), // pro

  // Onboarding funnel: one signal per step shown, then completion.
  onboardingStep('Onboarding.step'), // step
  onboardingCompleted('Onboarding.completed'), // experience, daysPerWeek, location, hops, dunkHand

  // Monetisation
  paywallShown('Paywall.shown'), // plans (0 = offering did not load)
  purchaseStarted('Purchase.started'), // plan
  purchaseResult('Purchase.result'), // plan, result
  restoreResult('Purchase.restore'), // result

  // Core loop: jump analysis
  analysisClipSelected('Analysis.clipSelected'), // attempt
  analysisResult('Analysis.result'), // result: measured|implausible|unmeasured, reason, vertBucket

  // Core loop: training
  sessionStarted('Session.started'), // focus, week
  sessionCompleted('Session.completed'), // focus, week, exercises
  sessionDiscarded('Session.discarded'); // focus, week, logged

  final String signal;
  const AnalyticsEvent(this.signal);
}

/// A vertical in 4-inch buckets ("24-27"), so a distribution can be read
/// without sending anyone's exact number.
String vertBucket(int inches) {
  final low = (inches ~/ 4) * 4;
  return '$low-${low + 3}';
}

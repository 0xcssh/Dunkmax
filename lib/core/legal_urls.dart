/// The legal URLs a subscription app must expose.
///
/// App Review requires a working Privacy Policy link and a Terms of Use
/// (EULA) link on any screen that sells a subscription. They live here — one
/// obvious place — so publishing them is a one-line change rather than a hunt
/// through the paywall widget tree.
///
/// **TODO(owner): publish a privacy policy and put its real URL in
/// [privacyPolicy], then flip [privacyPolicyPublished] to true.**
/// It must be a public page (no login, no redirect chain) that describes what
/// DunkIt collects. Today that is: the onboarding answers and workout/jump
/// history, which stay on the device; a display name and a vertical-jump
/// number, published to the leaderboard only when the athlete opts in; and
/// nothing else — jump videos and thumbnails never leave the phone. The same
/// URL must also go in App Store Connect's Privacy Policy URL field.
///
/// The placeholder deliberately uses the `.invalid` TLD, which RFC 2606
/// reserves so it can never resolve: a link that obviously does not work is
/// safer than one that plausibly points at somebody else's domain. While
/// [privacyPolicyPublished] is false the paywall says so instead of opening
/// it — a reviewer meeting a dead link is worse than one told it is pending.
abstract class LegalUrls {
  /// Apple's own standard EULA. Apple explicitly allows an app to use this as
  /// its Terms of Use instead of authoring custom terms, so — unlike the
  /// privacy policy — this one is real and usable as-is. Replace it only if
  /// custom terms are ever written (they must then also be entered in App
  /// Store Connect's Licence Agreement field).
  static const String appleStandardEula =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  /// Not published yet — see the TODO above.
  static const String privacyPolicy = 'https://dunkit.invalid/privacy';

  /// Whether [privacyPolicy] points at something real. While false the UI
  /// says the policy is not published yet instead of offering a dead link.
  static const bool privacyPolicyPublished = false;

  static const String termsOfUse = appleStandardEula;

  static const bool termsOfUsePublished = true;
}

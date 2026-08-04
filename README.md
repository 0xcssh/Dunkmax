# DunkMax

A Flutter clone of **DunkMax — Vertical Jump Trainer**
([App Store](https://apps.apple.com/fr/app/dunkmax-vertical-jump-trainer/id6757568089)):
a dark, orange-accented basketball jump-training coach. Sales-focused
onboarding quiz → recommended multi-week program → daily guided sessions.

Built with the same **no-Mac, CI-first** discipline as PodRadar/RepLock:
development happens on Windows, iOS builds run on GitHub Actions macOS
runners, and as much logic as possible lives in a **pure, unit-tested Dart
core** so the cheap CI path (analyze + test on Ubuntu) validates behaviour
without a device.

## Architecture

```
dunkmax/
  lib/
    main.dart                 Bootstraps SharedPreferences store, runs the app
    app.dart                  Top-level phase machine: onboarding → paywall → shell
    theme/app_theme.dart      DunkColors palette + text styles (dark + orange)
    core/                     PURE Dart, no Flutter imports — fully CI-tested
      models/                 DunkGoal, ExperienceLevel, CourtPosition,
                              Exercise, TrainingProgram, OnboardingProfile
      program_catalog.dart    Profile → recommended TrainingProgram (deterministic)
      program_progress.dart   completed / remaining / % math (the progress card)
    services/
      onboarding_store.dart   Thin shared_preferences wrapper (persist + reset)
    features/
      onboarding/             Welcome hook + 4-question quiz + "building plan"
      paywall/                Presentation-only paywall (IAP is a follow-up)
      home/                   5-tab shell (Home, Analyze, Train, Feed, Progress);
                              Train is the functional centrepiece
      shared/widgets/         PrimaryButton (gradient CTA), SelectableCard
  test/                       Core unit tests + a widget smoke test
```

**Keep logic in `core/` and persistence/UI thin** — same rule as PodRadar's
`Core/` vs `Services/` split. `core/` has zero Flutter imports, so it is
trivially testable and the untestable surface stays small.

## Dev loop (Windows, no Xcode)

There is no local Flutter/macOS here. The generated platform folders
(`ios/`, `android/`, …) are **gitignored** and regenerated in CI with
`flutter create` on every run, so nothing platform-specific needs to be
authored by hand.

- **Every push** to the feature branch → `analyze-test` job runs
  `flutter analyze` + `flutter test` on Ubuntu (fast, free).
- **On demand** (`workflow_dispatch`) → `ios-build` job runs
  `flutter build ios --no-codesign` on macOS to validate the real iOS
  toolchain compiles. Manual to spare the shared macOS-runner minutes.

```bash
# Run tests the same way CI does (once Flutter is available):
flutter pub get
flutter analyze --no-fatal-infos
flutter test
```

## Follow-ups (not in this first cut)

- **Signing + IPA export.** Add the Apple certs / ASC key as repo secrets and
  a signed-export step (mirror PodRadar's `ios.yml`). Needs a real bundle id
  registered in the Apple Developer portal — the CI build currently uses the
  default `com.example.dunkmax`.
- **In-app purchases.** The paywall is presentation-only. Wire RevenueCat
  (same account/pattern as PodRadar) and gate premium content once ASC
  products exist.
- **Localization.** Strings are inline English for now. Externalize to
  `flutter_localizations` + ARB before submission (en, fr, es, de, it, pt-BR).
- **Real tracking.** Jump-height logging (Progress tab) and video form
  analysis (Analyze tab) are stubbed empty states.
- **App icon & fonts.** Placeholder emblem + system font; swap for real
  artwork and a condensed display face before submission.

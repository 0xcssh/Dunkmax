# CLAUDE.md

DunkMax is a **Flutter** clone of **DunkMax — Vertical Jump Trainer**
([App Store](https://apps.apple.com/fr/app/dunkmax-vertical-jump-trainer/id6757568089)):
a dark, orange-accented basketball jump-training coach. Sales-focused
onboarding quiz → recommended multi-week program → daily guided sessions,
with a signature **AI jump-analysis** feature (film a jump → estimated
vertical + scores + coaching).

Same builder as the **PodRadar** and **RepLock/Loopa** apps — reuse their
CI-first, no-Mac dev strategy. The user develops on **Windows** and reports
in **French**; code/comments/commits are in **English**.

## The constraint that shapes everything: NO MAC

Development is 100% from Windows (now via VS Code + local Flutter). **No
local Xcode, no local iOS build.** Never suggest opening Xcode or running
xcodebuild. The loop for iOS:

edit Dart → push → **GitHub Actions (macOS runner) builds the signed IPA** →
user installs over USB on their iPhone → user tests and reports back.

Because a device round-trip is slow, **push as much logic as possible into
the pure, unit-tested Dart core (`lib/core/`)** — CI tests (analyze + test
on Ubuntu) are the cheap iteration path. Two things that can NEVER be fully
validated in CI: real device UI feel, and (later) CoreML/camera jump
analysis — those need the device.

### Fast visual iteration without a device
- **Flutter Web preview** (real compiled app) auto-deploys to GitHub Pages
  on every push to `main` → **https://0xcssh.github.io/Dunkmax/**
  ⚠️ Pages must be enabled once: repo **Settings → Pages → Build and
  deployment → Source = "GitHub Actions"**. Until then the `web-preview`
  workflow fails at "configure-pages" (`Get Pages site failed: Not Found`);
  the Actions token cannot enable Pages itself.
- Locally: `flutter run -d chrome` (web) or a device/emulator.

## Build, test, run

```bash
flutter pub get
flutter analyze --no-fatal-infos   # matches CI
flutter test                       # core unit tests + a widget smoke test
flutter run -d chrome              # live web preview locally
```

CI is `.github/workflows/ci.yml`: analyze + test on Ubuntu on every push;
an **unsigned** iOS compile check on macOS via `workflow_dispatch` only
(to spare shared macOS-runner minutes). `.github/workflows/web-preview.yml`
builds web and deploys to Pages.

**Generated platform folders (`ios/`, `android/`, `web/`, …) are
gitignored** and regenerated in CI with `flutter create --platforms=… .`
(there is no local macOS to author them). CI then removes the template
`test/widget_test.dart` it generates (it references a default `MyApp` we
replaced). If you add real `ios/`/`android/` config later (e.g. for
signing), un-ignore just those files.

## iOS on device (still no Mac) — TODO not yet wired

Signing isn't set up on this repo yet. To get a signed IPA on the iPhone:
1. Register bundle id **`com.awdia.dunkmax`** in the Apple Developer portal.
2. Add signing secrets to THIS repo (they don't carry across repos):
   `CERT_P12_BASE64`, `CERT_DIST_P12_BASE64`, `CERT_P12_PASSWORD`, `ASC_*`,
   plus the `APPLE_TEAM_ID` variable (`8L8G4P4Z9X`, shared with
   RepLock/PodRadar). Local signing material lives in
   `C:\Users\awdia\replock-signing\`.
3. Add a signed archive/export step to the macOS job (mirror PodRadar's
   `ios.yml`).
4. Install over USB (Python 3.12, iPhone unlocked & plugged in):
   ```
   py -3.12 -m pymobiledevice3 apps install DunkMax.ipa
   ```
   Gotchas (field-tested on RepLock): if the device isn't detected, restart
   the Windows Apple stack ("Appareils Apple") and replug; if install hangs,
   reboot the iPhone; never run two installs at once.
   Or use **TestFlight** for OTA (needs the ASC app record).

## Architecture

```
lib/
  main.dart              Bootstraps SharedPreferences store, runs the app
  app.dart               Phase machine: onboarding → paywall → app shell
  theme/app_theme.dart   DunkColors palette (near-black + orange) + text styles
  core/                  PURE Dart, NO Flutter imports — fully CI-tested.
    models/              DunkGoal, ExperienceLevel, CourtPosition, Exercise,
                         TrainingProgram, HopsLevel, TrainingLocation,
                         CommitmentLevel, OnboardingProfile
    program_catalog.dart Profile → recommended TrainingProgram (deterministic)
    program_progress.dart completed / remaining / % math (Train progress card)
    vert_assessment.dart  Height+age+hops → reach, vert-to-dunk, gap, projection
  services/
    onboarding_store.dart shared_preferences wrapper (persist profile + flag)
  features/
    onboarding/          Welcome hook + 10-question quiz + sell screens
    paywall/             Presentation-only paywall (IAP is a follow-up)
    home/                5-tab shell (Home, Analyze, Train, Feed, Progress);
                         Train is functional, others are placeholders
    shared/widgets/      PrimaryButton (gradient CTA), SelectableCard
test/                    Core unit tests + app smoke test
```

**Rule (same as PodRadar's Core vs Services split): all device/jump/program
logic goes in `core/` (pure, tested); UI and side effects stay thin.**
`core/` has zero Flutter imports.

## The signature feature: AI jump analysis (decided, not yet built)

Filming a jump → estimated vertical + scores + coaching is the app's whole
differentiator. Decision (fiabilité + rapidité, ≤10–20 s of processing):

- **Vertical (headline number) = flight-time method.** Physics: airborne
  height `h = g·t²/8` (g = 9.81). Detect takeoff and landing frames in the
  (trimmed) clip → `t = frames / fps` → `h`. Fast (a few seconds) and
  robust: it measures *time*, so NO pixel→inch calibration needed. This is
  how most real vert apps work. The app trims the video to one jump exactly
  to keep this short.
- **The 4 scores + coaching (Bounce/Power/Control/Form) = pose detection,
  added later.** Run an on-device pose model (Google ML Kit Pose Detection
  Flutter plugin, or MediaPipe BlazePose) on the trimmed clip → 33 body
  landmarks → derive knee-bend depth, arm-swing amplitude/timing, symmetry,
  torso lean. This is what produces the "your arm swing is late" style
  feedback. Needs a scale reference (the user's height — that's why
  onboarding asks it) and more calibration; heavier, so it's phase 2.

Put the physics in `core/` (pure, tested); keep the camera/plugin glue thin
in `services/`.

## Vert math (`core/vert_assessment.dart`) — calibrated to the reference

- Rim = 120". Dunk needs reach ≥ 126" (rim + 6" clearance).
- Standing reach ≈ `height × 1.33`.
- `requiredVert = 126 − standingReach`.
- `estimatedCurrentVert` from the self-reported hops level, rim-relative
  (touch-the-rim ⇒ reach == 120).
- `gapInches = requiredVert − currentVert`.
- Projection: diminishing-returns curve `maxGain × (1 − e^(−week/5))`, with
  `maxGain` biased by age (younger = more upside).

Calibrated so a 6'1" (73") "touch the rim" athlete → reach 97", dunk 29",
today 23", gap 6" — exactly matching the reference screenshots. Pinned by
`test/vert_assessment_test.dart`. Height + age also drive program
adaptation (see `program_catalog.dart`).

## Onboarding flow (built) — order

Welcome → **quiz (progress bar, 10 Q):** dunk goal (multi) · experience ·
position · days/week · training location · hops level · height (wheel) ·
weight (slider) · age (wheel) · commitment → **sell screens:** gap analysis
("Here's the gap") → jump-potential projection → social proof → building
loader → plan reveal → **paywall** → app shell.

## What's built vs TODO

Built & CI-green:
- Full onboarding (13 screens) wired to the tested core.
- Tested core: program catalog, program progress, vert/gap/projection math.
- App shell (5 tabs); **Train** tab functional (enrolled program, today's
  exercises, live progress card, "complete session" increments progress).
- Presentation-only paywall.
- CI (analyze+test, unsigned iOS build) + web-preview workflow.

TODO (rough priority):
- [ ] **Analyze tab** — the differentiator: record/import video → trim → AI
      processing screen → results dashboard (EST. VERT + Bounce/Power/
      Control/Form + coaching + potential + share). Start with flight-time.
- [ ] **Train** — real multi-week programs; per-exercise workout sessions
      with warm-up + set/reps/lbs logging + "complete workout".
- [ ] **Progress** — current vertical, day streak, workouts X/56, vert trend.
- [ ] **Feed** (social) and **Coach** (AI chat).
- [ ] **iOS signing** → IPA on device (see above).
- [ ] **IAP via RevenueCat** (real paywall + 3-day trial; same account
      pattern as PodRadar). Two products for the trial/no-trial cascade.
- [ ] **Localization** — externalize strings to flutter_localizations + ARB
      (en, fr, es, de, it, pt-BR). Biggest ASO edge; don't defer to the end.
- [ ] Real **app icon** + a condensed display font (currently system font).

## Conventions

- Commit style: imperative subject + short "why" paragraph.
- Code, comments, commits in **English**; the user reports in **French**.
- **No fabricated social proof.** The onboarding social-proof screen ships
  with clearly-marked PLACEHOLDER rating + testimonials
  (`features/onboarding/screens/social_proof_screen.dart`). Before App Store
  submission they MUST be replaced with real testimonials and a real (or
  removed) rating — a fake "4.8 · N App Store ratings" on a new app is
  misleading and violates App Store Review guidelines.
- **Localization is the plan** — avoid hardcoding user-facing copy long-term;
  English literals are placeholders until the ARB catalog lands.
- Icons: Material/Cupertino icons only, no emoji in UI. Design must never
  look cheap.
- Keep the repo **public** during dev (free unlimited macOS Actions minutes,
  shared quota with PodRadar/RepLock). Flip **private** before submission:
  `gh repo edit 0xcssh/dunkmax --visibility private`.

## Repo notes / gotchas

- Canonical name is **`0xcssh/Dunkmax`** (capital D); `dunkmax` redirects.
- The reference screenshots (~45) are in the user's Google Drive folder
  `dunkmax` (id `1Pgn79pu4uI_FPPlBlAVq3EOm3Rz9w_AL`). Key screens: onboarding
  gap/potential/plan-reveal, the Analyze dashboard (EST. VERT 29", 4 score
  cards), workout logging, Progress, Coach chat.
- An early copy of this app once lived on a `claude/dunkmax-flutter-mobile-*`
  branch inside the unrelated **podradar** repo — that was a scratch branch;
  this dedicated repo is the source of truth. The podradar branch can be
  deleted.
- There's also a standalone interactive HTML mock of the flow (built as a
  Claude artifact) — a design reference only, not the real app.

## Apple / store config (mostly TODO)

| Item | Value |
|---|---|
| Bundle ID | `com.awdia.dunkmax` (not yet registered) |
| Team ID | `8L8G4P4Z9X` (shared; GitHub var `APPLE_TEAM_ID`) |
| Signing secrets | Not yet added to this repo (see iOS section) |
| RevenueCat | Not set up yet (mirror PodRadar's pattern) |
| Subscriptions | Reference app used an annual + trial; price TBD |
| Permissions (later) | Camera + Photo Library (video jump analysis) |

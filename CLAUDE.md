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
    workout_streak.dart   Consecutive-day streak from completion timestamps
    jump_trend.dart       Latest vertical + delta-from-first-test, from jump log
  services/
    onboarding_store.dart shared_preferences wrapper (persist profile + flag)
    workout_session_store.dart  Persists completed WorkoutSessions (one JSON
                         string per entry, so one corrupt entry can't sink
                         the rest)
    jump_log_store.dart  Persists JumpLogEntry history (fed by Analyze),
                         same one-entry-per-string pattern
  features/
    onboarding/          Welcome hook + 10-question quiz + sell screens
    paywall/             Presentation-only paywall (IAP is a follow-up)
    home/                5-tab shell (Home, Analyze, Train, Feed, Progress) —
                         all five functional
    feed/                Leaderboards: the athlete's OWN jumps ranked
                         (core/leaderboard.dart); the community board is
                         honestly locked (no backend, no accounts)
    analyze/             Source (record/pick video) → mark takeoff/landing →
                         processing beat → result dashboard (flight-time vert);
                         a valid result is persisted to JumpLogStore
    train/               SessionFlow: warm-up → per-exercise set/reps/lbs
                         logging (one screen per exercise) → summary, then
                         persists a WorkoutSession via WorkoutSessionStore
    shared/widgets/      PrimaryButton (gradient CTA), SelectableCard
test/                    Core unit tests + app smoke test
```

**Rule (same as PodRadar's Core vs Services split): all device/jump/program
logic goes in `core/` (pure, tested); UI and side effects stay thin.**
`core/` has zero Flutter imports.

## The signature feature: AI jump analysis (v1 flight-time built; pose TODO)

Filming a jump → estimated vertical + scores + coaching is the app's whole
differentiator.

- **Vertical (headline number) = flight-time method — BUILT.** Physics:
  airborne height `h = g·t²/8` (g = 9.81 m/s² ≈ 386.09 in/s²), pure and
  tested in `core/flight_time.dart`. `core/models/jump_measurement.dart`
  turns a takeoff/landing timestamp pair into airborne time + validity
  (rejects implausible marks); `core/jump_result.dart` folds that into the
  same `VertAssessment` dunk-gap math the onboarding screens use, so the
  Analyze result reads consistently with the rest of the app.
  **v1 marks takeoff/landing manually** — the athlete scrubs the clip in
  `features/analyze/screens/mark_jump_screen.dart` (`video_player`) and taps
  "Mark takeoff" / "Mark landing" — rather than automatic frame detection
  (that needs real motion analysis on decoded frames, unproven without a
  device to test on; manual marking ships a real, reliable measurement now).
  Video capture/import is `image_picker` (`features/analyze/screens/
  source_screen.dart`, camera or gallery, max 10s).
- **SETTLED (measured, not guessed): whole-frame motion energy cannot
  isolate a subject that occupies a small part of the frame.** A real clip
  was traced frame by frame with ffmpeg: takeoff 0.558s, landing ~1.32s →
  0.77s hang → **28–29"**, which is exactly what the reference app reported
  and what our detector missed entirely. On that clip the athlete's own
  motion measured 0.013 while UI transitions in the same footage hit 0.30 —
  the jump was *quieter than the noise*. Raising the sampling resolution
  from 32px to 96px changed the athlete's energy from 0.012 to 0.012:
  frame-difference energy is a ratio of moving area to total area, so it is
  **scale-invariant** and more pixels buy nothing. There is no threshold
  tweak that fixes this class of clip — only tracking the body does, i.e.
  the pose detection already planned below. Stop tuning the heuristic.
- **Open question: where the flight window really starts and ends.** The
  physics is exact; the error is entirely in the takeoff/landing instants.
  Motion energy during flight tracks the body's vertical speed — max at
  takeoff, ~zero at the apex, max again at landing — so the signal traces a
  **V**, and how wide you call that V moves the answer by several inches.
  Three defensible readings exist (`core/jump_auto_detector.dart`,
  `JumpEstimates`): the **outer bound** (samples just outside the quiet run —
  what currently feeds the reported number), the **interpolated threshold
  crossing** (kills sample-step quantisation, worth several inches on its
  own, but inherits whatever bias the threshold has), and **apex symmetry**
  (twice apex→landing, using only the sharp landing impact and the fact that
  flight is symmetric about the apex). All three are computed and shown in
  the result screen's DETECTION DETAILS card, in seconds *and* inches.
  **Do not blind-tune this again** — an earlier blind two-pass "refinement"
  turned a 20" reading into a bogus 50" and had to be reverted. Pick the
  winner from a real clip whose true vertical is known, then promote it.
- **The 4 scores + coaching (Bounce/Power/Control/Form) = pose detection,
  NOT built.** Shown as a locked "coming soon" card on the result screen
  (`features/analyze/screens/jump_result_screen.dart`) rather than faked —
  same no-fabricated-data rule as the onboarding social-proof screen. Plan:
  run an on-device pose model (Google ML Kit Pose Detection Flutter plugin,
  or MediaPipe BlazePose) on the clip → 33 body landmarks → derive knee-bend
  depth, arm-swing amplitude/timing, symmetry, torso lean. Needs a scale
  reference (the user's height — that's why onboarding asks it); heavier,
  so still phase 2. Automatic takeoff/landing detection (replacing the
  manual marks) could piggyback on the same pose pass.
- **Not yet wired: Camera + Photo Library Info.plist permission strings.**
  `ios/` is gitignored and regenerated by `flutter create` in CI (see
  above), so there's nowhere to commit `NSCameraUsageDescription` /
  `NSPhotoLibraryUsageDescription` yet. Add them (a CI patch step, or
  un-ignore `ios/Runner/Info.plist` once real iOS config lands) before
  testing Analyze on a real device — without them iOS kills the app on
  camera/library access instead of showing a permission prompt.

Physics lives in `core/` (pure, tested); camera/video-player glue stays thin
in `features/analyze/`.

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
("Here's the gap") → jump-potential projection → how it works (the
measurement method — replaced the old placeholder social-proof screen) →
building loader → plan reveal → **free analysis** → **paywall** → app shell.

## What's built vs TODO

Built & CI-green:
- Full onboarding (13 screens) wired to the tested core.
- Tested core: program catalog, program progress, vert/gap/projection math,
  workout session/streak, jump trend.
- App shell (5 tabs); **Train** tab functional: 3-day program rotations
  (Power/Strength/Speed split, per program), warm-up → per-exercise
  set/reps/lbs logging → summary flow, persisted via `WorkoutSessionStore`.
- **Analyze** tab functional (flight-time vert measurement, see below);
  results persist to `JumpLogStore`.
- **Progress** tab functional: workouts completed (X/total), day streak
  (`WorkoutStreak`, counts across all programs — a habit metric, not
  program-scoped), current vertical + trend since first test
  (`JumpTrendCalculator`, honest "—" empty state if no jump logged yet).
- Presentation-only paywall.
- CI (analyze+test, unsigned iOS build) + web-preview workflow.

TODO (rough priority):
- [x] **Analyze tab v1** — record/import video → mark takeoff/landing →
      processing beat → results (EST. VERT via flight-time, gap-to-dunk,
      locked score cards). Still TODO: automatic frame detection (no manual
      marking), pose-based Bounce/Power/Control/Form scores + coaching,
      potential projection on the result screen, share, camera/library
      Info.plist permissions (see above).
- [x] **Train v2.5** — `core/training_schedule.dart` (pure, 30 tests) wraps
      the authored 3-day rotation with real periodisation: **rest days**
      (the i-th of n weekly sessions lands on weekday `1 + (i*7)~/n`, so
      3/wk = Mon/Wed/Fri), **progressive overload** (+1 set per build week,
      each completed block opens higher, capped at +3 / 8 sets absolute —
      *sets only*: the catalog's rep labels are free-form strings like
      "8 reps/leg" and "30 sec", so progressing them would mean guessing
      units), and **deload** every 4th week, except a program's final week
      is never a deload (that's the re-test week). Train shows
      `WEEK 2 · DAY 2 OF 3`, a 7-day week strip, a DELOAD pill, and a rest-
      day state whose CTA is a muted TRAIN ANYWAY — recovery is recommended,
      not enforced. Home reads the same progressed prescription so the two
      tabs can't disagree. Still TODO: no per-set edit/undo after logging;
      the rest-day trigger is "already trained today", not a start-date-
      anchored calendar.
- [x] **Progress v2** — workouts X/total, day streak, current vertical +
      trend, all real/persisted. Still TODO: no vertical-trend chart (just
      the latest number + delta), no workout history list/detail view.
- [x] **Feed v1** — Leaderboards over the athlete's own logged jumps
      (medal ranks, thumbnails, tap to replay). The community board the
      reference app has needs accounts + a server + video hosting +
      moderation; none of that exists, so it ships visibly locked instead of
      seeded with invented athletes. Real community leaderboards are the
      follow-up, and they are a backend project, not a UI one.
- [ ] **Coach** (AI chat).
- [ ] **iOS signing** → IPA on device (see above).
- [ ] **IAP via RevenueCat** (real paywall + 3-day trial; same account
      pattern as PodRadar). Two products for the trial/no-trial cascade.
- [ ] **Localization** — externalize strings to flutter_localizations + ARB
      (en, fr, es, de, it, pt-BR). Biggest ASO edge; don't defer to the end.
- [ ] Real **app icon** + a condensed display font (currently system font).

## Conventions

- Commit style: imperative subject + short "why" paragraph.
- Code, comments, commits in **English**; the user reports in **French**.
- **No fabricated social proof.** A new app has no reviews and no community,
  so nothing in the UI may imply otherwise. The onboarding sell flow used to
  hold a placeholder rating + invented testimonials; that screen is gone,
  replaced by `features/onboarding/screens/how_it_works_screen.dart`, which
  sells the measurement method (all claims true today). The paywall ships
  with no rating badge, and the Feed's community board is honestly locked
  rather than filled with made-up athletes. When real reviews exist they get
  *added*; they never come back as placeholders.
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
| Permissions | Camera + Photo Library — code (`image_picker`) is wired, but the Info.plist usage-description strings aren't committed yet (see Analyze section above) |

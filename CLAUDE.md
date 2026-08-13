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
  app.dart               Phase machine: onboarding → free analysis → paywall →
                         app shell. The paywall gate is the ENTITLEMENT, not a
                         tap: it listens to SubscriptionService.isSubscribed
  theme/app_theme.dart   DunkColors palette (near-black + orange) + text styles
  l10n/                  app_en.arb (the template — every message carries an
                         @description) + app_fr.arb, and the gen-l10n output
                         (app_localizations*.dart). The generated Dart is
                         **checked in on purpose**: there is no Flutter SDK on
                         the dev machine to run the generator, and CI has to
                         compile from a plain checkout. `flutter pub get`
                         regenerates it in place (pubspec sets `generate: true`,
                         config in `l10n.yaml`), so a stale copy self-heals.
                         Call sites read `AppLocalizations.of(context).key` —
                         non-null, because `nullable-getter: false`
  core/                  PURE Dart, NO Flutter imports — fully CI-tested.
    models/              DunkGoal, ExperienceLevel, CourtPosition, Exercise,
                         TrainingProgram, HopsLevel, TrainingLocation,
                         CommitmentLevel, OnboardingProfile
    program_catalog.dart Profile → recommended TrainingProgram (deterministic).
                         Experience picks the template, daysPerWeek the volume,
                         and **trainingLocation actually shapes the plan**: a
                         `home` athlete's equipment drills are swapped for
                         their bodyweight substitutes (see exercise_library)
    exercise_library.dart Authored coaching content per exercise id — summary,
                         execution steps, common mistakes, muscles/quality,
                         `Equipment` requirement and the home substitute.
                         `Exercise.equipment` is **required** at every
                         authoring site so nothing silently claims to need no
                         kit; `test/exercise_library_test.dart` pins that every
                         id the catalog prescribes has a guide, so the two
                         files cannot drift
    program_progress.dart completed / remaining / % math (Train progress card)
    vert_assessment.dart  Height+age+hops → reach, vert-to-dunk, gap, projection
    workout_streak.dart   Consecutive-day streak from completion timestamps
    jump_trend.dart       Latest vertical + delta-from-first-test, from jump log
    jump_form_scores.dart Bounce/Power/Control/Form 0-100 + takeoff type, from
                          the pose landmark series; each score nullable
    jump_feedback.dart   The written JUMP BREAKDOWN: headline + trend note,
                          plus best/worst *measured* form aspect and two tips
                          mapped to that weakness (nothing named when < 2
                          scores were measured)
    trim_range.dart       Analyze's trim selection: handle clamping (0.6 s
                          minimum span), clip<->fraction mapping, 0:00.0 format
    media_path.dart       basename / isAbsolute / join for the jump-media
                          paths — pure string work, both separators (see
                          "Jump media on disk" below)
    subscription_offer.dart  BillingPeriod (ISO-8601 "P1Y"), SubscriptionPlan
                          (per-week price, billed line, trial line, Apple
                          renewal disclosure), SubscriptionOffer (BEST VALUE +
                          derived Save N%), PurchaseOutcome. `formatLikePrice`
                          rewrites the digits inside the store's own localised
                          price string, so we never guess a currency format
    legal_urls.dart       Privacy / Terms URLs in one place (see TODO inside)
  services/
    onboarding_store.dart shared_preferences wrapper (persist profile + flag)
    subscription_service.dart  RevenueCat glue: guarded configure, offering
                          fetch → SubscriptionPlan, purchase / restore,
                          ValueNotifier<bool> isSubscribed. Inert with no
                          --dart-define key
    workout_session_store.dart  Persists completed WorkoutSessions (one JSON
                         string per entry, so one corrupt entry can't sink
                         the rest)
    jump_log_store.dart  Persists JumpLogEntry history (fed by Analyze),
                         same one-entry-per-string pattern
    media_file_resolver.dart  Caches the documents directory once at startup
                         (main.dart) so a stored clip/thumbnail name resolves
                         to a File *synchronously*, inside build methods
  features/
    onboarding/          Intro carousel (3 swipeable panels, live in-app
                         mockups) + 11-question quiz + sell screens. The whole
                         flow shares a painted `widgets/court_backdrop.dart`
                         and a direction-aware `widgets/shared_axis_switcher`
    paywall/             Real paywall: renders the live RevenueCat offering
                         (store prices, trial length, derived savings), buys,
                         restores; honest unavailable state with no API key
    home/                5-tab shell (Home, Analyze, Train, Feed, Progress) —
                         all five functional
    feed/                Leaderboards: the athlete's OWN jumps ranked
                         (core/leaderboard.dart); the community board is
                         honestly locked (no backend, no accounts)
    analyze/             Source (record/pick video) → trim to one jump →
                         processing beat → result dashboard (flight-time vert);
                         when nothing can be measured the athlete gets the
                         detector's reason and how to fix the clip — never a
                         request to mark the frames by hand (screens/
                         unmeasured_screen.dart); a valid result is persisted
                         to JumpLogStore.
                         The trim range (core/trim_range.dart, pure + tested)
                         is a *range selection*, never a re-encode: it is
                         passed into both frame samplers, which spend a fixed
                         frame budget, so a narrower range = more samples
                         inside the flight (and no multi-jump case)
    train/               SessionFlow: warm-up → per-exercise set/reps/lbs
                         logging (one screen per exercise) → summary, then
                         persists a WorkoutSession via WorkoutSessionStore.
                         The exercise name (and a HOW TO DO IT card) opens
                         exercise_detail_screen: steps, common mistakes,
                         muscles, equipment, and the "swapped for your home
                         setup" note. No demo clip is filmed for any drill, so
                         the media slot renders an honest empty state and a
                         real url/asset drops into ExerciseGuide when one
                         exists
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
- **Pose tracking is now the primary detector** (`core/pose_jump_detector.dart`,
  pure + tested; `features/analyze/pose_extraction.dart` is the ML Kit glue).
  It samples frames, runs `google_mlkit_pose_detection`, and finds takeoff
  and landing from where the **feet** actually are: a ground baseline (75th
  percentile of foot y — robust to one snapped landmark, unlike a min/max),
  crossed at a threshold expressed in **torso lengths** so it survives the
  camera moving nearer or further. Crossings are interpolated between
  samples. Because a threshold sitting above the ground clips the window
  short at both ends, the raw duration is corrected via the flight parabola
  (`T = T_raw / √(1 − L/H)`, with lift `L` chosen and apex lift `H`
  observed) — which is also why the exact threshold value isn't critical.
  Falls back to the motion-energy detector, then to manual marking; it
  returns null rather than guess when too many frames have no pose, when two
  comparable airborne windows exist (a double jump), or when the window is
  implausible. **Requires iOS 15.5** — the CI workflows pin the deployment
  target via `tool/set_ios_deployment_target.py` because `ios/` is
  regenerated by `flutter create` and CocoaPods otherwise fails on an
  incompatible platform.
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
- **The 4 scores (Bounce/Power/Control/Form) = BUILT**, in
  `core/jump_form_scores.dart` (pure, tested). `PoseSample` now also carries
  the individual ankle/knee/hip/shoulder/wrist landmarks (as `PosePoint`,
  each null when ML Kit wasn't confident — same gate, same "never a zero"
  rule), so the scores come off the *same* pass that timed the jump: no
  extra decode, no extra inference. What each measures:
  **Bounce** = ground-contact time between the last plant and takeoff;
  **Power** = countermovement depth (hip drop) + hip rise rate out of it;
  **Control** = ankle/hip height symmetry + torso lean off vertical;
  **Form** = arm-swing amplitude and how close its peak is to takeoff.
  Also derived: **one-foot vs two-foot takeoff**, from how far apart the two
  ankles cross the ground threshold.
  Two rules hold the whole file together. (1) Every distance is in **torso
  lengths**, so nothing moves when the athlete stands nearer the camera —
  pinned by a test that halves (and quadruples) every pixel coordinate and
  demands identical scores. (2) The measurements are observations but the
  **0–100 bands are documented coaching heuristics, not validated norms** —
  each one is a named constant with a doc comment saying what range it calls
  good and that it is a judgement call. No citations, because there are none.
  A score whose inputs are missing (wrists never detected, no approach step
  to time a contact against, hips lost during the dip) comes back **null with
  a plain reason shown on the card** — never a default, an average, or a
  number derived from the vertical. On a one-foot takeoff the ankle-symmetry
  term is *dropped* rather than penalised, since scissoring is the technique.
  Deliberately **not** shown: any "top N % for your height" badge — that
  needs a real user base.
  Still TODO here: knee-angle metrics (the knee landmarks are captured but
  nothing reads them yet).
- **The written JUMP BREAKDOWN reads off those scores**
  (`core/jump_feedback.dart`, pure + tested). It opens on the physics
  (measured vert, gap, trend vs. past jumps — unchanged), then names the
  **best- and worst-scoring aspect**, each with the raw measurement behind it
  (`FormScore.detail`), and picks **two tips mapped to that weakness**:
  Bounce → reactive-strength / fast-plant work, Power → heavy strength then
  rate-of-force, Control → single-leg + anti-rotation trunk work, Form →
  swing range or (when the detail says the peak landed *after* takeoff)
  arm-timing first. Four rules keep it honest: every sentence traces to a
  measured number; **unavailable scores are never ranked as weaknesses** (a
  missing Bounce means no approach step to time, not a weak athlete); fewer
  than two measured scores — or a dead tie — names *nothing* rather than
  reaching, and the tips fall back to the general pool (which is also what a
  manually marked jump gets, since `scores` is optional); and there is no
  comparison to other athletes anywhere.
- **Not yet wired: Camera + Photo Library Info.plist permission strings.**
  `ios/` is gitignored and regenerated by `flutter create` in CI (see
  above), so there's nowhere to commit `NSCameraUsageDescription` /
  `NSPhotoLibraryUsageDescription` yet. Add them (a CI patch step, or
  un-ignore `ios/Runner/Info.plist` once real iOS config lands) before
  testing Analyze on a real device — without them iOS kills the app on
  camera/library access instead of showing a permission prompt.

Physics lives in `core/` (pure, tested); camera/video-player glue stays thin
in `features/analyze/`.

### Jump media on disk — store the NAME, never the path

`JumpLogEntry.videoPath` / `.thumbnailPath` hold the **file name** of a file in
the application documents directory. They are not absolute paths, and must not
become them again: on iOS the documents directory lives inside a container
whose UUID **changes on reinstall** and can change across updates, so an
absolute path captured at record time goes stale and the entry silently loses
its clip and its still — which is exactly why *old* jumps were the ones whose
Share button and playback did nothing.

The names are written by `analyze_flow.dart` (via
`MediaFileResolver.storageNameFor`) and read back through
`MediaFileResolver.instance.resolve(stored)`, which:
1. tries an **absolute** stored value as-is — legacy entries whose container
   has not moved keep working untouched, and nothing is migrated or rewritten;
2. otherwise (or if that file is gone) resolves the **basename** against the
   current documents directory — this is what recovers a legacy entry after
   the container moved;
3. returns `null` when neither exists.

`null` is a real answer: the thumbnail draws its empty state, the row is not
tappable, and the video screen hides Share entirely. **An affordance is never
offered for a file that isn't there** — a dead tap is indistinguishable from a
bug, which is how this was reported in the first place. Every read site goes
through the resolver (`feed_tab`, `progress_tab`, `jump_history_screen`,
`jump_video_screen`); none of them may construct a `File` from a stored value
directly. The pure half (`core/media_path.dart`, tested) does the string work;
the directory lookup is async and Flutter-bound, so it stays in `services/`
and is warmed once in `main.dart`. Uninitialized (widget tests) degrades to
"absolute paths only", never to a crash.

**Sharing a clip** (`jump_video_screen.dart`): `Share.shareXFiles` is awaited
and wrapped — a throw used to surface as nothing at all — and is handed a
`sharePositionOrigin` derived from the share button's own `RenderBox`, because
iPadOS *requires* an anchor rect for the popover and throws without one.
`share_plus` is pinned `^10.0.0`, where `Share.shareXFiles` is the current API;
`SharePlus.instance.share(ShareParams(...))` only exists from **11.0.0** and
does not resolve here. Verify the resolved version before touching this call —
a guessed share_plus API has broken CI on this repo before.

## Vert math (`core/vert_assessment.dart`) — calibrated to the reference

- Rim = 120". A **one-hand** dunk needs reach ≥ 126" (rim + 6" clearance); a
  **two-hand** finish has to get both forearms over the ring, so it adds
  `twoHandExtraClearance` (4", a coaching figure, documented as such) → 130".
  Which one applies comes from the onboarding dunk-hand question
  (`OnboardingProfile.dunkHand`, `core/models/dunk_hand.dart`); an unanswered
  or legacy-null hand keeps the one-hand target — better to under-state a
  target than to invent inches. The question is worded around exactly this
  ("how much room over the rim your finish needs"); the reference app claims it
  feeds an "approach angle analysis" and **nothing here analyses approach
  angle** — do not write that.
- Standing reach = the athlete's **measured** reach when they have one
  (`OnboardingProfile.standingReachInches`, set from the Home settings sheet —
  **deliberately not an onboarding question**: sending a first-run athlete to
  measure themselves against a wall is more friction than the answer is worth,
  and a quiz step most people skip should not exist), otherwise the estimate
  `height × 1.33`. Arm length varies by several inches at the same height, so
  the estimate is the weakest link in every "inches to dunk" claim: wherever a
  gap or dunk target is shown, `VertAssessment.reachIsMeasured` decides whether
  a short "this reach is estimated" caveat appears (gap screen + Analyze result
  vert card). Sanity bounds live in `core/standing_reach.dart` (pure, tested).
- `requiredVert = reachTarget − standingReach` (`reachTarget` = 126, or 130 for
  a two-hand finish).
- `estimatedCurrentVert` from the self-reported hops level, rim-relative
  (touch-the-rim ⇒ reach == 120).
- `gapInches = requiredVert − currentVert`.
- Projection: diminishing-returns curve `maxGain × (1 − e^(−week/5))`, with
  `maxGain` biased by age (younger = more upside).

Calibrated so a 6'1" (73") "touch the rim" athlete → reach 97", dunk 29",
today 23", gap 6" — exactly matching the reference screenshots. Pinned by
`test/vert_assessment_test.dart`.

**Height and age do NOT drive program adaptation** — this file claimed they
did, and they don't. `ProgramCatalog.recommend` reads exactly two fields:
`experience` (which of the three programs) and `daysPerWeek` (sessions per
week), plus `trainingLocation` since the home-substitution work. Onboarding
asks eleven questions; goals, court position, weight, age, height and
commitment are collected, persisted, shown back to the athlete — and never
reach the programming. Either make them count or stop asking: the current
state promises a personalisation that isn't there.

`hopsLevel`, `standingReachInches` and now `dunkHand` are the exception: they
feed `VertAssessment` and visibly move the numbers (`dunkHand` is passed at
every construction site — gap screen, potential screen, Analyze). A new quiz
question has to earn its place that way; that is why the dunk-hand question
exists at all.

## Onboarding flow (built) — order

Intro carousel → **quiz (progress bar, 11 Q):** dunk goal (multi) · experience ·
position · days/week · training location · hops level · height (wheel) ·
weight (slider) · age (wheel) · dunk hand (left/right/both) · commitment →
**sell screens:** gap analysis
("Here's the gap") → jump-potential projection → how it works (the
measurement method — replaced the old placeholder social-proof screen) →
building loader → plan reveal → **free analysis** → **paywall** → app shell.

### Presentation (owned by `onboarding_flow.dart`, not by the steps)

- **`widgets/court_backdrop.dart`** — the dark court behind every step, a
  `CustomPainter` and deliberately **not** a photo: no licence to track, no
  asset weight, and it can be tuned and animated for kilobytes. Four layers —
  dark vertical gradient, perspective floorboards converging on a vanishing
  point, a warm off-centre spotlight, a heavy vignette — all held at low alpha
  (boards ≤ 16%, spotlight ≈ 11%) because **legibility of the text on top wins
  over the illustration**. A 26 s eased loop drifts the vanishing point and
  breathes the spotlight; it honours `MediaQuery.disableAnimationsOf`. Applied
  once at flow level, with a `Theme` override making the steps' `Scaffold`s
  transparent, so no screen changed its own layout.
- **`widgets/shared_axis_switcher.dart`** — direction-aware step transitions
  (outgoing slides+fades one way, incoming from the other). `AnimatedSwitcher`
  can't do this: it reverses the entry transition, so a page always leaves the
  way it arrived. Direction is derived from the `_Step` enum's declaration
  order, so no call site has to say which way it is going. The outgoing page is
  wrapped in `IgnorePointer`; the incoming one is live from frame 1 — **an
  animation never delays a tap**.
- **`widgets/staggered_entrance.dart`** — one controller per step; `StaggerItem`
  fades/lifts title, subtitle, each option card and the CTA in sequence
  (`OnboardingScaffold` places them; card screens pass `staggerBody: false` and
  stagger their own cards from `OnboardingScaffold.bodyStaggerIndex`). It only
  changes opacity/offset, never hit testing.
- **`screens/intro_carousel_screen.dart`** — three swipeable panels (jump
  analysis · training plan · progress), each a **live widget mockup**
  (`widgets/phone_mockup.dart` + `widgets/mock_app_screens.dart`) rather than a
  screenshot: nothing here can take one, and a bundled PNG would go stale the
  moment a real screen changed. It **replaced** the old `welcome_screen.dart`
  (two full-screen hooks with two CTAs before the first question was one too
  many; its "TRAIN WITH A REAL PLAN" headline lives on as panel 2). The
  reference app's "4.8 · 675+ ratings" badge is deliberately absent — sample
  numbers *inside* the phone are a picture of the product, claims about other
  people are not.
- Because the backdrop animates continuously the tree never goes idle, so
  `test/app_smoke_test.dart` pumps fixed durations instead of `pumpAndSettle`
  (which would run to its timeout). Any future onboarding widget test must do
  the same.

## What's built vs TODO

Built & CI-green:
- Full onboarding (intro carousel + 16 screens) wired to the tested core, on a
  painted court backdrop with shared-axis step transitions (see below).
- Tested core: program catalog, program progress, vert/gap/projection math,
  workout session/streak, jump trend.
- App shell (5 tabs); **Train** tab functional: 3-day program rotations
  (Power/Strength/Speed split, per program), warm-up → per-exercise
  set/reps/lbs logging → summary flow, persisted via `WorkoutSessionStore`.
  Every drill has an authored guide (`core/exercise_library.dart`) reachable
  from its name, and the **training-location answer is honoured**: a home-only
  athlete is never prescribed a box, bench or loaded drill.
- **Analyze** tab functional (flight-time vert measurement, see below);
  results persist to `JumpLogStore`.
- **Progress** tab functional: workouts completed (X/total), day streak
  (`WorkoutStreak`, counts across all programs — a habit metric, not
  program-scoped), current vertical + trend since first test
  (`JumpTrendCalculator`, honest "—" empty state if no jump logged yet).
- **Paywall wired to RevenueCat** (`services/subscription_service.dart` +
  `core/subscription_offer.dart`, 30 tests). Prices, billing period, trial
  length and the savings badge are all derived from the fetched offering —
  each derivation returns null rather than a guess, so a claim the product
  can't support simply disappears (the old hardcoded "Save 83%" was invented;
  the real figure from the same prices is 84%). `app.dart` gates on the
  **entitlement**, not on a tap. Key comes from `--dart-define`
  (`REVENUECAT_API_KEY`); with none set the SDK is never configured and the
  paywall says purchases are unavailable. Owner setup:
  `docs/revenuecat-setup.md`.
- CI (analyze+test, unsigned iOS build) + web-preview workflow.

TODO (rough priority):
- [x] **Analyze tab v1** — record/import video → trim → automatic pose
      detection (manual marking only as the last fallback) → processing beat
      → results: EST. VERT via flight-time, gap-to-dunk, and **real
      Bounce/Power/Control/Form scores** from the same pose pass
      (`core/jump_form_scores.dart`), each absent-with-a-reason when the clip
      can't support it, plus a **written breakdown built off those scores**
      (`core/jump_feedback.dart`: strength, weakness, targeted tips). Still
      TODO: knee-angle metrics, potential projection on the result screen,
      share, camera/library Info.plist permissions (see above).
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
- [x] **Feed v2 — real global leaderboard** across all users, backed by
      Supabase (`services/leaderboard_service.dart`, anonymous auth, one
      upserted personal-best row per athlete). **Deliberately ranks numbers
      only — no user video is ever uploaded.** Publishing user media would
      make this a UGC app, which App Store Guideline 1.2 then requires to
      ship content filtering, in-app reporting, blocking and 24h takedown;
      ranking on numbers alone stays outside that entirely. Clips and
      thumbnails never leave the device. Credentials come from
      `--dart-define` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`); **with none set
      the app runs fully offline and the board shows an honest unavailable
      state**, which is what keeps CI, tests and the web preview secret-free.
      Setup SQL + RLS policies: `docs/supabase-setup.md`. The athlete's own
      board (medal ranks, thumbnails, tap to replay) remains below it.
- [ ] **Coach** (AI chat).
- [ ] **iOS signing** → IPA on device (see above).
- [x] **IAP via RevenueCat** — app-side done. `SubscriptionService` mirrors
      `LeaderboardService`: `isConfigured`, guarded `initialize()`, every call
      timed out and swallowed. Entitlement id is the single constant
      `SubscriptionService.entitlementId = 'pro'` and **must match the
      RevenueCat dashboard** or a real purchase unlocks nothing (the paywall
      detects and names that case). A cancelled purchase is
      `PurchaseOutcome.cancelled`, not a failure — the UI stays silent.
      **Dev/CI escape hatch:** nobody can be entitled without a key, so
      `allowsUnconfiguredAccess = !isConfigured && !kReleaseMode` lets
      unconfigured *non-release* builds through a clearly-labelled
      "CONTINUE WITHOUT PURCHASE" button. A *release* build with no key fails
      closed — no purchase, no way in — so this can never ship as a bypass.
      Still TODO (owner, see `docs/revenuecat-setup.md`): App Store Connect
      products + paid-apps agreement, the RevenueCat project, the
      `REVENUECAT_API_KEY` repo secret and the one-line `--dart-define` in
      `ios-release.yml`, and `url_launcher` so the Privacy/Terms links open a
      browser instead of a copy-the-URL dialog (URLs live in
      `core/legal_urls.dart`; the privacy one is a reserved `.invalid`
      placeholder until a real page is published).
- [x] **Localization (en + fr)** — `flutter_localizations` + `intl`,
      `l10n.yaml`, and a 375-message ARB catalogue in `lib/l10n/`. Every
      user-facing string under `lib/features/**` is extracted; both locales
      are **authored**, not machine-translated, which is why only two ship.
      Adding es/de/it/pt-BR is now a data-only change: drop an `app_xx.arb`
      beside the others and add the locale to `l10n.yaml`'s neighbours in
      `AppLocalizations.supportedLocales`. `test/l10n_catalog_test.dart`
      fails on a missing key, an orphan key or a placeholder mismatch, so a
      half-translated locale cannot ship silently falling back to English.
      Still English, deliberately: everything authored in `lib/core/**` —
      `exercise_library.dart`'s coaching content, `jump_feedback.dart`'s
      sentences, `jump_form_scores.dart`'s reasons and labels, the enum
      `title`/`subtitle` getters in `core/models/`, `subscription_offer.dart`'s
      price and disclosure lines, and `training_schedule.dart`'s
      `weekdayLabel`/`positionLabel`. `core/` may not import Flutter, and
      `AppLocalizations` is a Flutter dependency — translating that content
      means changing those contracts (returning ids, or taking a lookup), which
      is a separate job. Also left in English on purpose: the Analyze result's
      DETECTION DETAILS card, which is developer-facing.
- [ ] **App icon** — generation is wired: drop a square, opaque, ≥1024px
      `assets/icon/app_icon.png` and CI produces every iOS and Android size
      via `flutter_launcher_icons`, right after `flutter create` regenerates
      the platform folders. Nothing generated is committed. The build skips
      the step and keeps Flutter's default while the source is absent, so a
      missing icon never breaks a build — it just looks unset. Still TODO: a
      condensed display font (currently the system font).

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
- **No new hardcoded user-facing copy.** Every string a user reads lives in
  `lib/l10n/app_en.arb` with an `@description` saying *where it appears* (the
  next translator will not have the app open), and in `app_fr.arb`. Copy built
  by concatenation becomes one ARB entry with ICU placeholders, never joined
  fragments — fragment order does not survive translation. Anything counting
  uses a real `plural`. French is written as natural sporting French with
  *tutoiement*, not a gloss: "vertical" is *détente*, "hang time" is *temps de
  suspension*, "dunk" stays "dunk".
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
| RevenueCat | App-side wired; dashboard/account not created yet. Entitlement id `pro`; secret `REVENUECAT_API_KEY` → `--dart-define`. See `docs/revenuecat-setup.md` |
| Subscriptions | Yearly + weekly, each in a trial / no-trial pair (cascade); 3-day trial; price TBD. Not created in App Store Connect yet |
| Legal URLs | `lib/core/legal_urls.dart`. Terms = Apple's standard EULA (real). Privacy = `.invalid` placeholder, **must be published before submission** |
| Permissions | Camera + Photo Library — code (`image_picker`) is wired, but the Info.plist usage-description strings aren't committed yet (see Analyze section above) |

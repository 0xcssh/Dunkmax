# CLAUDE.md

**Dunk It** (internal/package name `dunkmax`) is a **Flutter** app modelled on
**DunkMax — Vertical Jump Trainer**
([App Store](https://apps.apple.com/fr/app/dunkmax-vertical-jump-trainer/id6757568089)):
a dark, orange-accented basketball jump-training coach. Sales-focused
onboarding quiz → recommended multi-week program → daily guided sessions,
with a signature **AI jump-analysis** feature (film a jump → estimated
vertical + scores + coaching).

Same builder as the **PodRadar** and **RepLock/Loopa** apps — reuse their
CI-first, no-Mac dev strategy. The user develops on **Windows** and reports
in **French**; code/comments/commits are in **English**.

## The constraint that shapes everything: NO MAC

Development is 100% from Windows (VS Code). **No local Xcode, no local iOS
build.** Never suggest opening Xcode or running xcodebuild. The loop for iOS:

edit Dart → run the tests locally → push → CI green → dispatch **iOS Release**
(macOS runner builds the signed IPA and uploads it to **TestFlight**) → user
installs from TestFlight, tests, reports back.

**There is no Flutter SDK on PATH on this machine.** Tests still run locally,
and running them before every push is what stopped the analysis bugs
ping-ponging through CI: clone the version CI pins into a SHORT path
(`git clone --depth 1 -b 3.47.1 https://github.com/flutter/flutter.git`, then
`git config core.longpaths true && git reset --hard HEAD` inside it) and call
`bin/flutter.bat` / `bin/dart.bat` by full path. Windows quirks: in a deep
path `flutter analyze` crashes listing the SDK's own folders — use
`dart.bat analyze lib test`; `flutter pub get` / `flutter test` add an
`exclude:` block to `analysis_options.yaml` — `git checkout --
analysis_options.yaml` before committing; `flutter gen-l10n` regenerates the
checked-in `lib/l10n/app_localizations*.dart`.

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
flutter analyze --no-fatal-infos   # matches CI (CI pins Flutter 3.47.1)
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

## iOS on device (still no Mac) — wired, via TestFlight

`.github/workflows/ios-release.yml` (manual `workflow_dispatch`) scaffolds
`ios/`, patches Info.plist, generates the icons, builds, signs and exports.
Input `export_method`:
- `app-store-connect` — uploads straight to **TestFlight** (what every device
  test so far has used): `gh workflow run "iOS Release" --ref main -f
  export_method=app-store-connect`. ~13 min, then a few more for Apple to
  process the build.
- `debugging` (the default) — a dev-signed IPA artifact for USB sideload:
  `py -3.12 -m pymobiledevice3 apps install DunkMax.ipa`. Gotchas
  (field-tested on RepLock): if the device isn't detected, restart the Windows
  Apple stack ("Appareils Apple") and replug; if install hangs, reboot the
  iPhone; never run two installs at once.

Signing secrets are in the repo (`CERT_P12_BASE64`, `CERT_DIST_P12_BASE64`,
`CERT_P12_PASSWORD`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_API_KEY_P8_BASE64`)
plus the `APPLE_TEAM_ID` variable. Local signing material lives in
`C:\Users\awdia\replock-signing\`.

**Not in the repo, so off in every device build:** `SUPABASE_URL`,
`SUPABASE_ANON_KEY` (global leaderboard shows its unavailable state) and
`REVENUECAT_API_KEY` (purchases unconfigured). The release workflow passes
`--dart-define=PREVIEW_UNLOCK=true`, which is the only reason a release build
can get past the paywall today. **The day the RevenueCat key is added that
flag goes inert**: if the offering then fails to load, the paywall has no way
through — check products and agreements before adding the key.

Launch the release build only when the owner asks for it, and only after the
push's CI run is green.

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
                         **checked in on purpose**: CI has to compile from a
                         plain checkout, and the dev machine has no SDK on
                         PATH (run `flutter gen-l10n` from the scratch clone
                         after editing an ARB). `flutter pub get`
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
    units.dart            UnitSystem (metric / imperial by REGION), exact
                          conversions, input ranges — see "Units" below
    athlete_track.dart    Where the athlete was last seen, for the crop retry
    jump_analysis_pipeline.dart  Which frames to look at; the one way a clip
                          becomes a measurement
    pose_jump_detector.dart  Takeoff/landing from the tracked feet
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
    feed/                Leaderboards: a global board backed by Supabase
                         (numbers only, never video; honest unavailable state
                         with no credentials) above the athlete's OWN jumps
                         ranked (core/leaderboard.dart)
    progress/            Jump history list + clip playback/share
    analyze/             Source (record/pick video) → trim to one jump →
                         processing (real frame-count progress) → result
                         dashboard (flight-time vert); when nothing can be
                         measured the athlete gets the detector's reason and
                         how to fix the clip — never a request to mark the
                         frames by hand (screens/unmeasured_screen.dart); a
                         valid result is persisted to JumpLogStore.
                         The trim range (core/trim_range.dart, pure + tested)
                         is a *range selection*, never a re-encode. It says
                         *which* jump; it no longer buys accuracy — the
                         measurement always comes from the same dense series
                         (core/jump_analysis_pipeline.dart)
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
    shared/              unit_scope.dart (unit system for the widget tree),
                         layout_density.dart (regular / compact spacing),
                         widgets/: PrimaryButton, SelectableCard,
                         fit_or_scroll (scrolls only when it must)
test/                    Core unit tests, app smoke test, screen_fit_test
                         (every screen at two phone sizes, both locales),
                         fixtures/ (a real clip's landmark series), fonts/
                         (Roboto, so layout verdicts match on every machine)
```

**Rule (same as PodRadar's Core vs Services split): all device/jump/program
logic goes in `core/` (pure, tested); UI and side effects stay thin.**
`core/` has zero Flutter imports.

## The signature feature: AI jump analysis (one pipeline: body tracking)

Filming a jump → estimated vertical + scores + coaching is the app's whole
differentiator.

- **Vertical (headline number) = flight-time method.** Physics: airborne
  height `h = g·t²/8` (g = 9.81 m/s² ≈ 386.09 in/s²), pure and tested in
  `core/flight_time.dart`. `core/models/jump_measurement.dart` turns a
  takeoff/landing timestamp pair into airborne time + validity;
  `core/jump_result.dart` folds that into the same `VertAssessment` dunk-gap
  math the onboarding screens use. Video capture/import is `image_picker`
  (`features/analyze/screens/source_screen.dart`, camera or gallery; the 10 s
  cap only binds the camera — a gallery clip can be any length).
- **There is ONE way a clip becomes a number**
  (`core/jump_analysis_pipeline.dart`, pure + tested with a synthetic
  athlete; `features/analyze/pose_extraction.dart` is the ML Kit glue, a
  `PoseFrameExtractor` that only turns timestamps into landmarks). No
  motion-energy fallback, no manual marking, no second opinion — when body
  tracking cannot measure the clip the athlete gets the reason
  (`unmeasured_screen.dart`).
  **The rule that shapes it: clip length must never reach the measurement.**
  The sampler used to spend a fixed *number* of frames across whatever range
  it was handed, so the step between samples was a function of clip length
  (30 ms on a 1 s trim, 130 ms on an 8 s clip) and every detector constant
  was implicitly tuned to one regime — each fix for long clips broke short
  ones and the reverse (that is the "too short errors, then too long errors"
  ping-pong of the two commits before this design). Now:
  1. a range ≤ ~3.3 s is sampled whole, one sample per 33 ms;
  2. a longer range gets a sparse **scan** (150 ms step, stretching to at
     most 240 ms on very long clips — never wider than a flight) whose only
     job is to say *where* the jump is: `JumpSamplingPlan.jumpCandidates`
     ranks samples by how far the feet stand above the **floor's envelope**
     (`PoseJumpDetector.groundEnvelope`, below — drift-proof, works off a
     single airborne sample), then a dense 33 ms pass over ~2.5 s around each
     candidate in turn is measured **on its own** until one measures. (Ranking
     against the median of a ±1.5 s neighbourhood was tried first; a run-up
     toward the camera out-scored the jump, because the frames at the top of a
     slope stand "above" a neighbourhood full of later, lower ones.)
  3. if the athlete's trim cannot be measured and the clip has more footage
     either side, one retry a second wider — a trim cut into the takeoff or
     landing is the commonest way to lose a good jump.
  A scan-only window is deliberately never reported as the answer (its
  crossings are interpolated across 150 ms+ gaps; a seeded sweep caught it
  0.6 s off on a flight of under a second). A clip whose frames cannot be decoded
  is `PoseDetectionRejection.unreadable`, with the plugin's error in DETECTION
  DETAILS — it used to surface as "clip too short", because a thrown
  extraction fell back to an empty diagnostics object whose default rejection
  was `tooFewSamples`.
  `test/jump_analysis_pipeline_test.dart` runs the same jump at 1.2 s–30 s and
  a seeded 300-clip sweep (length, athlete size, drift, noise). **Extend that
  sweep before touching any constant here** — it is the only thing standing
  between this code and the next ping-pong.
- **A far-away athlete is re-found in a crop** (`core/athlete_track.dart`,
  pure + tested; the crop itself is `PoseFrameExtractor._retryInCrop`). A pose
  model finds the person first, on the frame shrunk to ~224 px, and only then
  the joints. An athlete who runs five metres from the phone before jumping is
  ~170 px of a 1138 px frame — ~30 px to the person-finder — and is not found
  at all, *in exactly the frames that hold the jump* (65 of 121 on the clip
  that showed it). More input resolution does not help; that stage downsizes
  regardless. So a frame the whole-frame pass finds nobody in is cropped to a
  square around where the athlete was last seen (nearest sighting in time,
  ≤ 1 s old, 2.2x their landmark extent, ≥ 160 px), scaled to 512 px and run
  again; landmarks are mapped back into frame coordinates. Measured on that
  clip: 121 of 121 frames. **The whole-frame pass always goes first and is
  untouched**, so this can only turn a missing frame into a found one, and any
  exception in it leaves a plain missing detection. DETECTION DETAILS reports
  how many frames were recovered this way. Device-unverified at the time of
  writing: the crop uses `dart:ui` (decode → `drawImageRect` → PNG) and was
  validated off-device with MediaPipe's BlazePose, the same model family.
- **Reproducing a device failure without the device** — the recipe that found
  the two bugs above, worth more than another round of guessing: `ffmpeg`
  the clip to 640 px frames, run MediaPipe's `pose_landmarker_heavy` over them
  in a throwaway Python venv applying the app's own gate (likelihood ≥ 0.5,
  lowest heel/foot-index along the torso), dump `PoseSample` rows, and feed
  them to `JumpAnalysisPipeline.run` from a test.
  `test/fixtures/run_up_away_capture.dart` is one such clip, kept as a
  fixture; `test/run_up_capture_test.dart` shows the sampler shim.
- **The detector** (`core/pose_jump_detector.dart`, pure + tested) finds
  takeoff and landing from where the **feet** actually are: a ground
  baseline crossed at a threshold expressed in **torso lengths** so it
  survives the camera moving nearer or further. Crossings are interpolated
  between samples.
  **The baseline is local in time, in two passes.** Pass 1 classifies:
  the 75th percentile of foot height over a rolling window of the nearest 15
  samples, **widened until it also spans ±0.35 s**. Both halves of that rule
  were learnt from a failure: a span alone held four samples at a 130 ms
  step; a count alone sits entirely *inside* the flight at a fine step. That
  second one is physics, not tuning — gravity fixes how far a foot falls away
  from the apex in a given time, and 15 samples at 20 ms reach exactly one
  lift-threshold below it whatever the jump height, so the apex read as
  "ground" and a clean jump came back `liftTooSmall`. That percentile lags a
  floor that is moving, so it is capped by the **ground envelope**
  (`groundEnvelope`): feet cannot go below the floor, so the floor is the
  lower envelope of the foot trace — a morphological closing (rolling max then
  rolling min of descent, ±0.6 s) that fills in anything as brief as a flight
  or a stride and leaves a slope exactly where it is. It exists because of a
  run-up *along the camera axis*: on the pinned capture the floor slid 160 px
  in under a second against a 45 px jump, every stride of the run-up read as
  airborne, and the detector **timed the run-up and reported a vertical for
  it**. The envelope may only lower the percentile's estimate (it rides the
  noise crest, so on a still floor the percentile wins and nothing changes),
  and it declines within 0.6 s of either end of the series, where a clip that
  starts or ends mid-air would otherwise be read as ground. Pass 2 places the
  floor: a **straight line between the median of the 7 grounded samples
  before and the 7 after** (`_bridgedGround`). That is what the ground does
  under a jump — an athlete who takes off moving toward the camera lands
  nearer to it, so the floor under the landing is further down the frame (44 px
  on the pinned walk-in capture, half the jump). The previous rule (median of
  the nearest grounded samples, whichever side) made the floor a **step** in
  mid-flight, which is not a parabola and quietly corrupted the fit. A side
  with fewer than 3 grounded samples is ignored (one stray detection must not
  anchor a line). Known limit: within 0.6 s of the ends of the measured series
  only the percentile is available, which follows a drift of roughly
  `liftThreshold / 0.17 s`.
  Because a threshold sitting above the ground clips the window short at both
  ends, the raw duration is corrected via the flight parabola
  (`T = T_raw / √(1 − L/H)`), and `BallisticFit` fits the whole arc. **The fit
  is only reported where the corrected crossings agree with it within 12 %**:
  the crossings' error is bounded by the sample step, the fit extrapolates and
  is unbounded on a small hop (the sweep produced 0.58 s for a 0.35 s flight
  with a healthy-looking residual).
  It returns no measurement rather than guess when too few frames have a
  pose, when the athlete is lost inside the flight, or when the window is
  implausible; several jumps in one clip → the highest. **Requires
  iOS 15.5** — the CI workflows pin the deployment target via
  `tool/set_ios_deployment_target.py` because `ios/` is regenerated by
  `flutter create` and CocoaPods otherwise fails on an incompatible platform.
- **"Up" is the athlete's up, not the image's (`BodyAxis`).** A real camera
  clip with an obvious jump was rejected `noAirborneWindow`. `ffprobe`:
  `1920x1080, rotation=-90` — an iPhone portrait recording, **stored landscape
  with a rotation flag**. Players apply the flag; a frame extractor need not,
  so the pose model saw the athlete lying on his side and a vertical jump
  moved the feet almost entirely *horizontally* in image coordinates. Every
  phone-camera clip would fail this way; the screen recordings tested earlier
  were natively portrait, which is why it went unnoticed. **The fix is not to
  read the rotation flag** — that depends on how `video_thumbnail` and ML Kit
  each already handle orientation (unverifiable without a device) and still
  breaks on a tilted tripod. Instead the detector derives an **up-axis from
  the pose itself**: shoulder-midpoint minus hip-midpoint, componentwise
  median over the **grounded** frames (not per frame — the torso tilts in
  flight, and a per-frame axis would feed that tilt into the measurement it
  exists to stabilise), and projects the foot onto it. The baseline
  percentile, the torso-length threshold, the interpolated crossings and the
  parabola correction then all run on that scalar unchanged. Two passes,
  because grounded frames need a baseline and a baseline needs an axis: a
  provisional all-frame axis places a provisional baseline, then the axis is
  re-derived over the frames it calls grounded. `BodyAxis.image` (`(0, −1)`,
  since image y grows downward) is the fallback whenever the series carries no
  foot *points* or too few torsos, and its arithmetic is the **identity** —
  which is why nothing else had to change and every pre-existing test still
  passes untouched. `torsoPixels` is now the full **2-D** shoulder-to-hip
  distance; as a y-difference it collapsed to ~0 on a sideways frame and took
  the scale reference with it. `jump_form_scores.dart` takes the same axis
  (defaulting to `image`), so foot lift, hip dip, ankle/hip asymmetry and arm
  raise are all measured along it; one consequence stated honestly in the
  file: torso *lean* is then measured against how the athlete stands, since a
  permanently leaning athlete and a tilted camera are not distinguishable from
  pose alone. The axis and its tilt are in the result screen's DETECTION
  DETAILS. Pinned by tests that rotate a passing synthetic jump by 90°, 180°
  and 20° and demand the same flight time — plus one that strips the same
  rotated clip back to image y and shows it rejecting, i.e. the field bug.
- **SETTLED, and now deleted: whole-frame motion energy cannot isolate a
  subject that occupies a small part of the frame.** A real clip was traced
  frame by frame with ffmpeg (takeoff 0.558 s, landing ~1.32 s → 0.77 s →
  **28–29"**); on it the athlete's own motion measured 0.013 while UI
  transitions in the same footage hit 0.30, and sampling at 96 px instead of
  32 px moved that 0.012 → 0.012 — frame-difference energy is a ratio of
  moving area to total area, so it is **scale-invariant**. That detector
  (`jump_auto_detector.dart`, `motion_extraction.dart`, the `image`
  dependency) reported 8" for that jump and has been removed rather than kept
  as a fallback. Do not bring it back.
- **Do not blind-tune the timing.** An earlier two-pass "refinement" that
  re-derived its threshold from a window holding almost nothing but flight
  turned a 20" reading into 50". The dense pass is safe from that only because
  it carries ~1 s of ground either side of the flight; keep it that way.
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
  ankles cross the ground threshold. The three metrics that touch the ground
  (contact time, the plant Power's search hangs off, one-foot vs two-foot) are
  judged against the detector's **local baseline at the takeoff**, not its
  clip-wide one — on a walk-in clip the clip-wide figure is tens of pixels off
  the actual floor at that instant against a ~19 px threshold, which does not
  make the contact time slightly wrong, it makes it "no approach step" or a
  fabricated one-foot call.
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
- **Info.plist permission strings are patched in CI.** `ios/` is gitignored
  and regenerated by `flutter create`, so `ci.yml` and `ios-release.yml` add
  `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`,
  `NSPhotoLibraryUsageDescription` and `NSPhotoLibraryAddUsageDescription`
  with PlistBuddy after the scaffold step. A new permission means a new line
  in **both** workflows — without it iOS kills the app instead of prompting.

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
  (touch-the-rim ⇒ reach == 120; below-the-rim ⇒ `belowRimShortfall` = 8"
  under that — a stand-in for the whole beginner bucket, which is why it is
  deliberately far from "touch". Asking the athlete for the number was tried
  and dropped: someone who cannot touch the rim has no way to know).
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
reach the programming. The copy no longer pretends otherwise: each question's
subtitle now says what the answer actually feeds (often only "saved to your
athlete profile"), the hops question "sets your starting estimate" rather than
"calibrates your whole plan", and the gap screen lists every goal picked
instead of calling the first card tapped the "primary" one. **Still open, the
owner's call:** make goals / position / weight / commitment count in
`ProgramCatalog`, or drop them from the quiz. Do not write copy that promises
tailoring until one of those happens.

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
("Here's the gap") → jump-potential projection → building loader → plan
reveal → **free analysis** → **paywall** → app shell.

Coherence rules the sell screens now obey (each was a reported defect):
- the **gap** between hops answers is visible: "below the rim" is 8" under
  "touch", not 4";
- the **projection window** is the recommended program's own length
  (`ProgramCatalog.recommend(profile).weeks`), not a fixed 8 weeks;
- the **plan reveal** week strip is built from `TrainingSchedule(program)` —
  the real day focuses on the real weekdays — so it cannot contradict Home and
  Train the next morning;
- the first measured jump says on the result card that it **replaces the
  onboarding estimate**; an athlete estimated to dunk already gets a margin,
  not a "-0" gap.

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
- **Analyze** tab functional (one body-tracking pipeline, flight-time vert,
  see above); results persist to `JumpLogStore`.
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
      detection (no fallback method, no manual marking) → processing
      → results: EST. VERT via flight-time, gap-to-dunk, and **real
      Bounce/Power/Control/Form scores** from the same pose pass
      (`core/jump_form_scores.dart`), each absent-with-a-reason when the clip
      can't support it, plus a **written breakdown built off those scores**
      (`core/jump_feedback.dart`: strength, weakness, targeted tips). Still
      TODO: knee-angle metrics, potential projection on the result screen.
      **Device-unverified:** the crop retry (see above) has only been proven
      off-device; the first report from a phone decides whether it stays.
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
      tabs can't disagree (Home shows the same rest-day state as Train).
      Leaving a session past the warm-up asks before discarding it; logged
      weights are typed in the region's unit and accept a decimal comma.
      Still TODO: no per-set edit/undo after logging; a finished program has
      no "what next";
      the rest-day trigger is "already trained today", not a start-date-
      anchored calendar.
- [x] **Progress v2** — workouts X/total, day streak, current vertical +
      trend with a chart (`tabs/widgets/jump_trend_chart.dart`), jump history
      and clip replay, all real/persisted. Still TODO: no workout history
      list/detail view.
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
- [x] **iOS signing** → TestFlight (see "iOS on device" above).
- [ ] **Exercise demo clips** — the player is wired and a clip is a drop-in
      (`docs/exercise-media.md`, `tool/prepare_exercise_media.py`); what is
      missing is footage the owner holds the rights to. Plan agreed: the owner
      films the 20 drills himself (13 need no equipment), using THP Strength /
      PJF Performance videos as form references only — their footage cannot be
      bundled. `wall_sits` has no still either.
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
      Enum cards (hops, goals, experience, position, commitment, dunk hand,
      location, attempt type, takeoff type, program day focus) are rendered
      through `{x, select, …}` ARB messages keyed on the enum name; the core
      `title` getters remain for tests only.
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

## Product analytics (TelemetryDeck)

Anonymous counts only — no identifier, no ATT, nothing linkable to a person —
through `telemetrydecksdk`, **pinned to 4.0.0**: 5.x ships its iOS side as a
Swift package only (no podspec), which this CocoaPods build cannot use. Every
call goes through `lib/services/analytics.dart`; the event vocabulary is the
`AnalyticsEvent` enum there (add events there, never call the SDK directly).
`Analytics.appID` is the App ID from the TelemetryDeck dashboard (ships in the
binary by design, like RevenueCat's public key); while it is empty, and always
on the web preview and in tests, every call is a no-op. Debug builds send in
test mode. Instrumented: launch (pro flag), every onboarding step +
completion (experience, days, location, hops, hand), paywall shown (plan
count), purchase started/result, restore, clip selected (attempt type),
analysis result (measured / implausible / unmeasured + rejection reason,
vertical in 4-inch buckets — never the exact number), session
started/completed/discarded. The privacy policy (0xcssh/dunkit-legal) names
TelemetryDeck; App Store privacy answers must declare "Product Interaction"
collected, not linked to identity, not used for tracking.

## Units follow the REGION, not the language

`core/units.dart` (pure, tested): `UnitSystem.forRegion(country, language)` —
imperial for US / LR / MM, metric for every other country; with no country at
all, imperial for `en` and metric otherwise. Resolved once in `main.dart` from
the platform locale (which carries the region; `Localizations.localeOf` often
has only the language) and handed down by `features/shared/unit_scope.dart`.
**Storage is inches/lbs everywhere** (profiles, jump log, leaderboard); only
input (height wheel in cm, weight slider in kg, reach dialog in cm) and
display convert. Every length/weight string is a `{unit, select, …}` ARB
message. A cm height round-trips through whole inches (181 cm may redisplay as
180 cm) — known, accepted. Nothing language- or region-specific may be
hardcoded: the owner is adding locales as data files.

## One page, no scrolling

`test/screen_fit_test.dart` renders every screen at 390x844 and 375x667 in en
and fr with realistic data and **fails** on any overflow or on vertical scroll
at 390x844, except the Analyze result and the exercise detail, which hold more
than a page by design. Compact spacing lives in `features/shared/
layout_density.dart`; `widgets/fit_or_scroll.dart` scrolls only when it must.
Keep the test green when adding content; shorten before you scroll.

**…and fill it.** The first pass shrank everything to fit the SE and left a
band of empty screen above the tab bar on a normal phone — the owner's word
was "you overdid it". So the same test also fails when, at 390x844, the
content of Home, Train, Progress, every quiz step, Gap, Potential or Plan
reveal ends more than 48 px above its CTA / tab bar. `FitOrScrollColumn` has a
fill mode: one block per page grows into the spare height (Home's hero card,
Train's drill list, Progress's chart, the quiz option list), and on a short
screen falls back to natural height. Compact density is for genuinely short
screens only; it must not set the look on a normal one.

## Conventions

- Commit style: imperative subject + short "why" paragraph.
- Code, comments, commits in **English**; the user reports in **French**.
- **No fabricated social proof.** A new app has no reviews and no community,
  so nothing in the UI may imply otherwise. The onboarding sell flow used to
  hold a placeholder rating + invented testimonials; that screen is gone,
  and the paywall ships
  with no rating badge, and the Feed's community board is honestly locked
  rather than filled with made-up athletes. When real reviews exist they get
  *added*; they never come back as placeholders. (The "how it works" screen
  that replaced the fake social proof has since been removed too, at the
  owner's request: a fourth text-heavy sell screen in a row, and the Analyze
  source screen already explains the method where it is used.)
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
- **The product is called "Dunk It".** "DunkMax" is the reference app this
  one is modelled on and survives only as the internal name: the Dart package
  (`dunkmax`), the repo, the bundle id `com.awdia.dunkmax`, class names. Never
  put "DunkMax" in anything a user reads. The home-screen label is set to
  "Dunk It" by a PlistBuddy line in both iOS workflows (the scaffold would
  otherwise name it after the package); the in-app wordmark is "DUNKIT".
- All three workflows pin `flutter-version: 3.47.1`. Bump it deliberately,
  in all three, and re-run the suite — an unpinned `stable` can break a
  build with no code change.

## Apple / store config

| Item | Value |
|---|---|
| Bundle ID | `com.awdia.dunkmax` (registered; builds upload to TestFlight) |
| Team ID | `8L8G4P4Z9X` (shared; GitHub var `APPLE_TEAM_ID`) |
| Signing secrets | In the repo (see iOS section). Supabase and RevenueCat secrets are NOT |
| RevenueCat | App-side wired; dashboard/account not created yet. Entitlement id `pro`; secret `REVENUECAT_API_KEY` → `--dart-define`. See `docs/revenuecat-setup.md` |
| Subscriptions | Group "Dunk It Pro", 4 products (yearly / weekly × trial / no-trial cascade), 3-day free trial on the trial pair. 59.99 USD / 69.99 EUR a year, 7.99 USD / 8.99 EUR a week, other territories equalized. **Created** by `scripts/asc_subscriptions.py` (workflow "ASC subscriptions", idempotent). Still owner-side: review screenshot per product, RevenueCat project/offerings, `REVENUECAT_API_KEY` |
| Analytics | TelemetryDeck via `lib/services/analytics.dart` — see "Product analytics" |
| Listing | 11 locales + screenshots pushed by the "ASC listing" workflow — see `docs/app-store-listing.md` |
| Legal URLs | `lib/core/legal_urls.dart`. Terms = Apple's standard EULA (real). Privacy = `.invalid` placeholder, **must be published before submission** |
| Permissions | Camera, Microphone, Photo Library (read + add) — usage strings patched into Info.plist by both iOS workflows |

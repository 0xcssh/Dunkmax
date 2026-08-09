# Exercise demonstration media

## What ships today

`assets/exercises/<drill_id>/0.jpg` and `1.jpg` — the start and finish
positions of each movement, 850×567 JPEG, ~70 KB each. 19 of the 20 drills in
`lib/core/exercise_library.dart` have a pair; 2.2 MB bundled in total.

`wall_sits` has none. The source dataset has no entry that is actually a wall
sit, and illustrating one exercise with a photo of a different exercise is
worse than showing nothing, so it keeps the written-steps-only treatment. A
test pins that.

There are **no videos**. wger hosts 78, but they are raw phone uploads between
34 MB and 390 MB and none of them cover plyometrics, so there was nothing
worth pointing at.

## Where the photos came from

[free-exercise-db](https://github.com/yuhonas/free-exercise-db) — 873
exercises, 61 of them plyometrics, published under the **Unlicense** (public
domain).

## The licensing caveat — read this before submitting

The Unlicense declaration covers the *repository*. It does not establish who
took the photographs.

The dataset's README gives **no provenance for the images** and makes **no
warranty about the rights to them**. The data was inherited from an upstream
project ([wrkout/exercises.json](https://github.com/wrkout/exercises.json)),
which in turn sourced it elsewhere. Declaring a licence on a repository does
not transfer rights the publisher may not hold, and the photographs share a
single consistent studio style that suggests one commercial origin.

The App Store agreement requires the developer to hold the rights to
everything they distribute. "It was marked public domain on GitHub" is not a
defence if the original photographer objects.

**The owner was shown this and chose to proceed.** That decision is recorded
here rather than buried, so it can be revisited deliberately.

## The safe replacements, in order of effort

1. **Film them.** Twenty drills, a phone, an afternoon in a gym. The clips
   then belong to the app, match its art direction, and can show the coaching
   cues the written steps describe. This is the only option that is also an
   asset rather than a dependency.
2. **License a stock library** (Storyblocks and similar). Immediate,
   unambiguous, costs money.
3. **wger, strictly filtered.** wger records per-image `license`,
   `license_author` and `license_object_url`, which is the legally correct
   structure — but coverage is thinner (360 images) and many entries have the
   attribution fields empty. Usable only for images where all three are
   populated, and requires displaying the attribution in-app.

## Swapping the media out

Everything routes through `ExerciseGuide.demoFrames` / `demoVideoUrl` in
`lib/core/exercise_library.dart`. Replacing a drill's photos means dropping new
files into its `assets/exercises/<drill_id>/` folder; adding a clip means
setting `demoVideoUrl`, which the detail screen already prefers over the
stills. No screen code changes either way.

Note that `pubspec.yaml` must list **every** drill folder individually —
Flutter bundles files directly inside a listed directory but never its
subdirectories, so `assets/exercises/` alone silently ships nothing.

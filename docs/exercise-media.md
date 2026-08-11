# Exercise media

## What is in the app today

Two still frames per drill — start and finish — bundled under
`assets/exercises/<exercise_id>/`, shown on the exercise detail screen and as
the thumbnail in the session list.

They come from [free-exercise-db](https://github.com/yuhonas/free-exercise-db),
which declares itself Unlicense (public domain). **That claim is asserted, not
established**: the README gives no provenance for the photographs, makes no
warranty about rights to them, and the data was inherited from an upstream
repository. The owner reviewed this and accepted the risk. Replacing them with
footage whose licence is verifiable removes it.

`wall_sits` has no photo. No entry in the dataset is actually a wall sit, and
illustrating one exercise with a picture of another is worse than an icon.

## Adding a video demo

The plumbing is done. A drill shows a looping, muted clip as soon as one
exists, and falls back to the still pair otherwise. Three steps:

1. **Source a clip** (below), download the highest quality offered.
2. **Compress it**: put it at `tool/exercise_media_raw/<exercise_id>.mp4` and
   run `python3 tool/prepare_exercise_media.py`. Use `--start` to skip into
   the clip if the rep does not begin at zero. This cuts four seconds, scales
   to 480px wide, drops the audio and re-encodes — a 40 MB stock file lands
   around 400 KB, which is what makes bundling twenty of them possible.
3. **Register it**: the script prints the line to paste into that drill's
   guide in `lib/core/exercise_library.dart`, and add the folder to
   `pubspec.yaml`'s asset list if it is not already there (it will be, the
   photos live in the same folder).

Assets rather than URLs, deliberately: the rest of the app works with no
network, and a demonstration that only plays online would be the one thing in
a gym that doesn't.

## Where to source them

**Check the free libraries first.** Both allow commercial use with no
attribution and no account, so for anything they cover there is nothing to buy
and nothing to risk:

- [Mixkit — exercise](https://mixkit.co/free-stock-video/exercise/) ·
  [workout](https://mixkit.co/free-stock-video/workout/) ·
  [fitness](https://mixkit.co/free-stock-video/fitness/) ·
  [gym](https://mixkit.co/free-stock-video/gym/) ·
  [training](https://mixkit.co/free-stock-video/training/)
  — free, no attribution. **Check each clip's licence badge**: a minority carry
  a Restricted License that excludes commercial use.
- [Pexels — exercise](https://www.pexels.com/search/videos/exercise/) ·
  [gym](https://www.pexels.com/search/videos/gym/)
  — free for commercial use, no attribution.

**Paid, for the drills the free libraries do not cover.** Plyometrics are
thinner than general fitness, so expect to buy the specific ones:

- [Getty Images — plyometric exercises](https://www.gettyimages.com/videos/plyometric-exercises)
  (~12,000 clips) and [box jump](https://www.gettyimages.com/videos/box-jump)
  (~1,500 clips). Per-clip pricing; the most complete plyometrics catalogue.
- Storyblocks or Envato Elements — subscription rather than per-clip, which
  works out cheaper if more than a handful are needed.

Whatever the source, **keep the licence receipt**. App Store submission makes
you warrant you hold the rights to everything you distribute.

## Sourcing checklist

Likely covered free (common gym movements):

- [ ] `squat_jumps` · `calf_raises` · `reverse_lunges` · `split_squat_jumps`
- [ ] `box_jumps` · `box_step_ups` · `wall_sits`
- [ ] `single_leg_glute_bridges` · `weighted_squat_jumps`

Likely need buying (specialised plyometrics):

- [ ] `depth_jumps` · `tuck_jumps` · `pogo_hops`
- [ ] `bounds` · `alternating_bounds` · `lateral_bounds`
- [ ] `broad_jumps` · `single_leg_hops`
- [ ] `bulgarian_split_squat_jumps` · `weighted_box_jumps`
- [ ] `nordic_hamstring_curls`

A clip only has to show the movement clearly from the side or straight on. It
does not need to match the app's look — it is a demonstration, not a hero
shot — so the cheapest usable clip is the right one.

"""Turns downloaded stock clips into bundle-sized exercise demos.

Stock footage is 1080p or 4K and tens of megabytes a clip. Twenty of those
would add more to the app than the whole rest of it. A demonstration only has
to show the movement, so each clip is cut to a few seconds, scaled down,
stripped of audio and re-encoded — which lands around 300-600 KB.

Usage:

    # put the raw downloads in tool/exercise_media_raw/<exercise_id>.mp4
    python3 tool/prepare_exercise_media.py

    # or one at a time, with an explicit trim
    python3 tool/prepare_exercise_media.py squat_jumps raw.mp4 --start 2.5

Writes assets/exercises/<exercise_id>/demo.mp4, then prints the Dart line to
paste into the matching guide in lib/core/exercise_library.dart.

Requires ffmpeg on PATH.
"""
import argparse
import os
import subprocess
import sys

RAW_DIR = os.path.join("tool", "exercise_media_raw")
OUT_ROOT = os.path.join("assets", "exercises")

# Small enough to bundle twenty of, large enough to read on a phone.
WIDTH = 480
DURATION = 4.0
CRF = "30"


def convert(exercise_id, source, start):
    out_dir = os.path.join(OUT_ROOT, exercise_id)
    os.makedirs(out_dir, exist_ok=True)
    dest = os.path.join(out_dir, "demo.mp4")

    subprocess.run(
        [
            "ffmpeg", "-v", "error", "-y",
            "-ss", str(start),
            "-t", str(DURATION),
            "-i", source,
            # Even dimensions are required by H.264.
            "-vf", "scale={}:-2".format(WIDTH),
            "-an",
            "-c:v", "libx264",
            "-preset", "slow",
            "-crf", CRF,
            "-pix_fmt", "yuv420p",
            # Lets the player start without reading the whole file first.
            "-movflags", "+faststart",
            dest,
        ],
        check=True,
    )

    size_kb = os.path.getsize(dest) // 1024
    print("{:28s} -> {}  ({} KB)".format(exercise_id, dest, size_kb))
    print("    demoVideoAsset: '{}',".format(dest.replace(os.sep, "/")))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("exercise_id", nargs="?")
    parser.add_argument("source", nargs="?")
    parser.add_argument("--start", type=float, default=0.0,
                        help="seconds into the source where the rep begins")
    args = parser.parse_args()

    if args.exercise_id and args.source:
        convert(args.exercise_id, args.source, args.start)
        return

    if not os.path.isdir(RAW_DIR):
        sys.exit("Nothing to do: put downloads in {}/<exercise_id>.mp4".format(RAW_DIR))

    found = False
    for name in sorted(os.listdir(RAW_DIR)):
        stem, ext = os.path.splitext(name)
        if ext.lower() not in (".mp4", ".mov", ".webm", ".m4v"):
            continue
        convert(stem, os.path.join(RAW_DIR, name), args.start)
        found = True

    if not found:
        sys.exit("No clips found in {}".format(RAW_DIR))


if __name__ == "__main__":
    main()

# App icon

Put the source icon here as **`app_icon.png`**.

- **1024×1024 or larger, square.** 2048 is fine — everything is downscaled
  from it.
- **No transparency.** iOS rejects an icon with an alpha channel. The config
  flattens it anyway (`remove_alpha_ios`), but an opaque source is one less
  thing to go wrong.
- **No rounded corners, no shadow.** iOS applies its own mask; baking one in
  produces a double-rounded icon.
- **Nothing important in the outer ~10%.** The mask crops the corners, and
  Android's adaptive icon crops more than iOS does.

Every size is generated from this one file by `flutter_launcher_icons`,
configured in `pubspec.yaml` and run by CI immediately after `flutter create`
regenerates `ios/` and `android/`. Nothing generated is committed, because
those folders are gitignored — see CLAUDE.md.

**While this file is absent the build still succeeds**, keeping Flutter's
default icon. So a missing icon never blocks a build; it just looks like
nothing was set.

To check a change without a full release build, run the unsigned iOS job in
`ci.yml` via workflow_dispatch — it runs the same generation step.

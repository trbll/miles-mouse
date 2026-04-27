# MilesMouse

MilesMouse is a tiny macOS desktop companion prototype for Miles. Miles sits near the Dock, watches the cursor, barks on click, responds to petting, and can be intentionally pulled free and placed elsewhere on the screen.

## Current Behavior

- Miles launches as a floating transparent panel.
- He follows the mouse with directional sprites: up, down, left, right, diagonals, forward, and tilt.
- Left click triggers bark: sprite change plus a scale bounce.
- Short click-and-drag pets Miles. Petting starts easily, but frame changes require more movement and time.
- A longer intentional pull snaps Miles into move mode. Once move mode starts, Miles centers under the mouse and follows it until dropped.
- Right click opens a context menu:
  - Hide Miles
  - Size: XXS, XS, S, Default, L, XL, XXL
  - Position: Left, Center, Right
  - Quit Miles
- Custom dropped positions are saved. Miles can dip slightly into the Dock area to account for loose transparent sprite padding, but saved and dragged positions are clamped so he stays visible and reachable.
- Choosing Left, Center, or Right clears the custom position and returns Miles to the Dock area.
- A fresh app launch resets Miles to Default size, centered above the Dock. This keeps a bad saved position or oversized experiment from carrying across a hard quit.

## Assets

The app builds from alpha-cutout assets in:

```text
MilesMouse/MilesMouse/Assets.xcassets/miles_alpha_*.imageset
```

The source and working folders live at the repo root:

```text
raw-images/     source sprite crops before background removal
alpha-images/   background-removed working sprites generated from raw-images
ref-sprites/    reference sprite sheets
```

`alpha-images/` is useful for reviewing generated cutouts, but Xcode does not read it directly. After regenerating sprites, sync them into the `miles_alpha_*` asset catalog entries before building the app.

The older non-alpha `miles_*` assets are still in the asset catalog so we can switch back if needed.

`src-images/` is intentionally ignored and should stay local-only. It is for original Miles photo references, not for the public GitHub repo.

## Background Removal

Background removal is handled by the utility in:

```text
utilities/bg-removal/
```

Add a repo-root `.env` file with your Replicate token:

```sh
REPLICATE_API_TOKEN=<paste-your-token-here>
```

Then run the full refresh from `utilities/bg-removal`:

```sh
uv run python remove_backgrounds.py --overwrite --sync-xcode-assets
```

That command regenerates every file in `alpha-images/` from `raw-images/`, then copies those outputs into the Xcode asset catalog used by the app.

## Build

Open `MilesMouse/MilesMouse.xcodeproj` in Xcode and run the `MilesMouse` scheme, or build from the repo root:

```sh
xcodebuild -project MilesMouse/MilesMouse.xcodeproj -scheme MilesMouse -configuration Debug build
```

For a release app bundle in the repo-local build folder:

```sh
xcodebuild -project MilesMouse/MilesMouse.xcodeproj \
  -scheme MilesMouse \
  -configuration Release \
  -derivedDataPath build/DerivedData \
  build
```

The release app is written to:

```text
build/DerivedData/Build/Products/Release/MilesMouse.app
```

## Notes

- Panel positioning and selected size are stored while the app is running so hide/show and menu changes behave consistently.
- On a fresh launch, saved placement settings are cleared before Miles appears.
- The menu position choices are the quickest way to recover a known Dock-adjacent position.

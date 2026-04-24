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
- Custom dropped positions are saved. If a saved or dragged position would put Miles under the Dock, under the menu bar, or mostly offscreen, the app clamps him back into the usable screen area.
- Choosing Left, Center, or Right clears the custom position and returns Miles to the Dock area.
- A fresh app launch resets Miles to Default size, centered above the Dock. This keeps a bad saved position or oversized experiment from carrying across a hard quit.

## Assets

The app currently uses alpha-cutout assets in:

```text
MilesMouse/MilesMouse/Assets.xcassets/miles_alpha_*.imageset
```

Source folders are kept at the repo root:

```text
alpha-images/   background-removed working sprites
raw-images/     original generated sprite crops
ref-sprites/    reference sprite sheets
```

The older non-alpha `miles_*` assets are still in the asset catalog so we can switch back if needed.

`src-images/` is intentionally ignored and should stay local-only. It is for original Miles photo references, not for the public GitHub repo.

## Build

Open `MilesMouse/MilesMouse.xcodeproj` in Xcode and run the `MilesMouse` scheme, or build from the repo root:

```sh
xcodebuild -project MilesMouse/MilesMouse.xcodeproj -scheme MilesMouse -configuration Debug build
```

## Notes

- Panel positioning and selected size are stored while the app is running so hide/show and menu changes behave consistently.
- On a fresh launch, saved placement settings are cleared before Miles appears.
- The menu position choices are the quickest way to recover a known Dock-adjacent position.

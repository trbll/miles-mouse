# Background Removal Utility

This utility regenerates transparent sprite PNGs in `alpha-images/` from source files in `raw-images/` using Replicate's `bria/remove-background` model.

## Setup

Create a `.env` file at the repo root:

```sh
REPLICATE_API_TOKEN=<paste-your-token-here>
```

The repo `.gitignore` ignores `.env` files.

## Run With uv

From this directory:

```sh
uv sync
uv run python remove_backgrounds.py --dry-run
uv run python remove_backgrounds.py --limit 1 --overwrite
```

Recommended full refresh for the app:

```sh
uv run python remove_backgrounds.py --overwrite --sync-xcode-assets
```

Run all missing outputs:

```sh
uv run python remove_backgrounds.py
```

Regenerate everything:

```sh
uv run python remove_backgrounds.py --overwrite
```

## Run With pip

From this directory:

```sh
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
python remove_backgrounds.py --dry-run
python remove_backgrounds.py --limit 1 --overwrite
```

## Paths

Defaults are resolved from the repo root:

```text
raw-images/     input images
alpha-images/   output PNGs with backgrounds removed
```

Outputs use the same source stem with a `.png` extension. For example:

```text
raw-images/forward.png -> alpha-images/forward.png
raw-images/bark-1.jpg  -> alpha-images/bark-1.png
```

By default, existing outputs are skipped to avoid accidental Replicate runs. Use `--overwrite` when you want to replace them.

## Xcode Asset Sync

The app builds from `MilesMouse/MilesMouse/Assets.xcassets/miles_alpha_*.imageset`, not directly from `alpha-images/`. Use `--sync-xcode-assets` after generating alpha images so Xcode picks up the refreshed sprites on the next build or run.

The sync step copies the generated files into matching `miles_alpha_*` asset sets. Keep both `alpha-images/` and the asset catalog images committed when accepting a new background-removal pass.

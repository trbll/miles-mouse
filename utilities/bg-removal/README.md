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

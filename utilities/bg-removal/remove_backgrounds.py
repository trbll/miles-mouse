#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
from pathlib import Path
from typing import Iterable
from urllib.request import urlopen


DEFAULT_MODEL = "bria/remove-background"
SUPPORTED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}


def main() -> int:
    repo_root = Path(__file__).resolve().parents[2]
    args = parse_args(repo_root)

    input_dir = resolve_path(args.input_dir)
    output_dir = resolve_path(args.output_dir)
    image_paths = list(iter_images(input_dir))

    if args.limit is not None:
        image_paths = image_paths[: args.limit]

    if not image_paths:
        print(f"No source images found in {input_dir}")
        return 0

    output_dir.mkdir(parents=True, exist_ok=True)

    planned = [
        (image_path, output_dir / f"{image_path.stem}.png")
        for image_path in image_paths
    ]

    if args.dry_run:
        for image_path, output_path in planned:
            action = "overwrite" if output_path.exists() else "write"
            if output_path.exists() and not args.overwrite:
                action = "skip"
            print(f"{action}: {image_path} -> {output_path}")
        return 0

    load_env(repo_root)
    require_replicate_token()

    import replicate

    for image_path, output_path in planned:
        if output_path.exists() and not args.overwrite:
            print(f"skip: {output_path} already exists")
            continue

        print(f"remove background: {image_path.name} -> {output_path.name}")
        with image_path.open("rb") as image_file:
            output = replicate.run(
                args.model,
                input={"image": image_file},
            )

        write_output(output, output_path)

    return 0


def parse_args(repo_root: Path) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Remove sprite backgrounds from raw-images into alpha-images using Replicate."
    )
    parser.add_argument(
        "--input-dir",
        type=Path,
        default=repo_root / "raw-images",
        help="Directory containing source images. Defaults to repo-root/raw-images.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=repo_root / "alpha-images",
        help="Directory for transparent PNG outputs. Defaults to repo-root/alpha-images.",
    )
    parser.add_argument(
        "--model",
        default=DEFAULT_MODEL,
        help=f"Replicate model to run. Defaults to {DEFAULT_MODEL}.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Regenerate files even when the output PNG already exists.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Only process the first N source images, useful for testing.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print planned work without loading Replicate or making API calls.",
    )
    return parser.parse_args()


def resolve_path(path: Path) -> Path:
    path = path.expanduser()

    if path.is_absolute():
        return path

    return (Path.cwd() / path).resolve()


def iter_images(input_dir: Path) -> Iterable[Path]:
    if not input_dir.exists():
        raise SystemExit(f"Input directory not found: {input_dir}")

    for path in sorted(input_dir.iterdir()):
        if path.is_file() and path.suffix.lower() in SUPPORTED_EXTENSIONS:
            yield path


def load_env(repo_root: Path) -> None:
    env_path = repo_root / ".env"

    if not env_path.exists():
        return

    try:
        from dotenv import load_dotenv
    except ImportError as error:
        raise SystemExit(
            "python-dotenv is required to load .env. Install dependencies first."
        ) from error

    load_dotenv(env_path)


def require_replicate_token() -> None:
    if not os.environ.get("REPLICATE_API_TOKEN"):
        raise SystemExit(
            "Missing REPLICATE_API_TOKEN. Add it to the repo-root .env file or export it."
        )


def write_output(output: object, output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    data = read_output_bytes(output)
    temp_path = output_path.with_suffix(f"{output_path.suffix}.tmp")
    temp_path.write_bytes(data)
    temp_path.replace(output_path)
    print(f"wrote: {output_path}")


def read_output_bytes(output: object) -> bytes:
    if isinstance(output, (list, tuple)):
        if len(output) != 1:
            raise TypeError(f"Expected one output file, got {len(output)} outputs.")
        output = output[0]

    if hasattr(output, "read"):
        return output.read()

    if hasattr(output, "url"):
        output = output.url

    if isinstance(output, str):
        with urlopen(output) as response:
            return response.read()

    raise TypeError(f"Unsupported Replicate output type: {type(output)!r}")


if __name__ == "__main__":
    raise SystemExit(main())

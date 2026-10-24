#!/usr/bin/env python3
"""Maintain a size-bounded set of exercise preview images.

The source images live directly in ``media/exercises``. Generated previews are
written to ``media/exercises/shrunk`` as WebP files with the same filename stem
(the exercise slug). The generated directory is safe to recreate at any time.

Requires Pillow::

    python3 -m pip install Pillow

Typical usage::

    python3 media/maintain_shrunk_exercises.py
    python3 media/maintain_shrunk_exercises.py --check
    python3 media/maintain_shrunk_exercises.py --rebuild
"""

from __future__ import annotations

import argparse
import io
import os
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

try:
    from PIL import Image, ImageOps, UnidentifiedImageError
except ImportError as exc:  # pragma: no cover - depends on the local environment
    raise SystemExit(
        "Pillow is required. Install it with: python3 -m pip install Pillow"
    ) from exc


MEDIA_DIR = Path(__file__).resolve().parent
SOURCE_DIR = MEDIA_DIR / "exercises"
OUTPUT_DIR = SOURCE_DIR / "shrunk"

SOURCE_EXTENSIONS = {".jpeg", ".jpg", ".png", ".webp"}
OUTPUT_EXTENSION = ".webp"
DEFAULT_BUDGET_MB = 15.0

# WebP settings favor a useful ad-hoc mobile preview. The encoder lowers quality
# and then dimensions only when an image cannot fit its share of the total budget.
MAX_EDGE = 1024
MIN_EDGE = 160
MAX_QUALITY = 82
MIN_QUALITY = 30
WEBP_METHOD = 4


@dataclass(frozen=True)
class EncodedImage:
    data: bytes
    width: int
    height: int
    quality: int


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--budget-mb",
        type=float,
        default=DEFAULT_BUDGET_MB,
        help=(
            "maximum total size in decimal megabytes "
            f"(default: {DEFAULT_BUDGET_MB:g})"
        ),
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="report whether maintenance is needed without changing files",
    )
    parser.add_argument(
        "--rebuild",
        action="store_true",
        help="regenerate every preview, even when the existing file is current",
    )
    return parser.parse_args()


def discover_sources() -> dict[str, Path]:
    if not SOURCE_DIR.is_dir():
        raise SystemExit(f"Source directory does not exist: {SOURCE_DIR}")

    sources: dict[str, Path] = {}
    casefolded_slugs: dict[str, str] = {}

    for path in sorted(SOURCE_DIR.iterdir(), key=lambda item: item.name.casefold()):
        if not path.is_file() or path.suffix.lower() not in SOURCE_EXTENSIONS:
            continue

        slug = path.stem
        if not slug:
            raise SystemExit(f"Source image has an empty slug: {path}")
        if slug in sources:
            raise SystemExit(
                f"Duplicate slug {slug!r}: {sources[slug].name!r} and {path.name!r}"
            )

        folded = slug.casefold()
        if folded in casefolded_slugs:
            other = casefolded_slugs[folded]
            raise SystemExit(
                f"Slugs {other!r} and {slug!r} differ only by letter case; "
                "this is unsafe on mobile filesystems"
            )

        sources[slug] = path
        casefolded_slugs[folded] = slug

    if not sources:
        raise SystemExit(f"No source images found in {SOURCE_DIR}")

    return sources


def discover_outputs() -> dict[str, Path]:
    if not OUTPUT_DIR.exists():
        return {}
    if not OUTPUT_DIR.is_dir():
        raise SystemExit(f"Output path is not a directory: {OUTPUT_DIR}")

    unexpected = [
        path
        for path in OUTPUT_DIR.iterdir()
        if not path.is_file() or path.suffix.lower() != OUTPUT_EXTENSION
    ]
    if unexpected:
        names = ", ".join(sorted(path.name for path in unexpected))
        raise SystemExit(
            f"Unexpected entries in generated directory: {names}. "
            "Move them elsewhere before running this script."
        )

    return {path.stem: path for path in OUTPUT_DIR.iterdir()}


def is_valid_webp(path: Path) -> bool:
    try:
        with Image.open(path) as image:
            image.verify()
            return image.format == "WEBP"
    except (OSError, UnidentifiedImageError):
        return False


def encode_webp(image: Image.Image, max_edge: int, quality: int) -> EncodedImage:
    preview = image.copy()
    preview.thumbnail((max_edge, max_edge), Image.Resampling.LANCZOS)

    has_alpha = "A" in preview.getbands()
    target_mode = "RGBA" if has_alpha else "RGB"
    if preview.mode != target_mode:
        preview = preview.convert(target_mode)

    buffer = io.BytesIO()
    preview.save(
        buffer,
        format="WEBP",
        quality=quality,
        method=WEBP_METHOD,
        optimize=True,
    )
    return EncodedImage(buffer.getvalue(), preview.width, preview.height, quality)


def compress_to_budget(source: Path, byte_limit: int) -> EncodedImage:
    """Return the highest-quality preview found within ``byte_limit``."""
    with Image.open(source) as opened:
        opened.load()
        image = ImageOps.exif_transpose(opened)

        edge = min(MAX_EDGE, max(image.size))
        while edge >= MIN_EDGE:
            best = encode_webp(image, edge, MAX_QUALITY)
            if len(best.data) <= byte_limit:
                return best

            lowest = encode_webp(image, edge, MIN_QUALITY)
            if len(lowest.data) <= byte_limit:
                best = lowest
                low = MIN_QUALITY + 1
                high = MAX_QUALITY - 1
                while low <= high:
                    quality = (low + high) // 2
                    candidate = encode_webp(image, edge, quality)
                    if len(candidate.data) <= byte_limit:
                        best = candidate
                        low = quality + 1
                    else:
                        high = quality - 1
                return best

            # File size broadly follows pixel count. This estimate usually skips
            # directly to a dimension that fits, while 90% leaves encoder margin.
            ratio = (byte_limit / len(lowest.data)) ** 0.5
            next_edge = max(MIN_EDGE, int(edge * ratio * 0.90))
            if next_edge >= edge:
                next_edge = edge - 1
            edge = next_edge

        smallest = encode_webp(image, MIN_EDGE, MIN_QUALITY)
        if len(smallest.data) <= byte_limit:
            return smallest

    raise RuntimeError(
        f"Cannot compress {source.name!r} below {byte_limit:,} bytes; "
        "increase --budget-mb or reduce the number of source images"
    )


def write_atomically(destination: Path, data: bytes) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary_name: str | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="wb",
            prefix=f".{destination.stem}.",
            suffix=".tmp",
            dir=destination.parent,
            delete=False,
        ) as temporary:
            temporary.write(data)
            temporary.flush()
            os.fsync(temporary.fileno())
            temporary_name = temporary.name
        os.replace(temporary_name, destination)
    finally:
        if temporary_name is not None:
            Path(temporary_name).unlink(missing_ok=True)


def human_size(byte_count: int) -> str:
    return f"{byte_count / 1_000_000:.2f} MB"


def main() -> int:
    args = parse_args()
    if args.budget_mb <= 0:
        raise SystemExit("--budget-mb must be greater than zero")

    budget_bytes = int(args.budget_mb * 1_000_000)
    sources = discover_sources()
    outputs = discover_outputs()
    per_image_budget = budget_bytes // len(sources)
    if per_image_budget < 1_024:
        raise SystemExit(
            f"The {human_size(budget_bytes)} budget allows less than 1 KB per "
            f"image for {len(sources)} sources"
        )

    print(f"Source slugs ({len(sources)}):")
    for slug in sources:
        print(f"  {slug}")

    source_slugs = set(sources)
    output_slugs = set(outputs)
    missing = source_slugs - output_slugs
    orphaned = output_slugs - source_slugs
    stale: set[str] = set()
    oversized: set[str] = set()
    invalid: set[str] = set()

    for slug in source_slugs & output_slugs:
        source = sources[slug]
        output = outputs[slug]
        if output.stat().st_mtime_ns < source.stat().st_mtime_ns:
            stale.add(slug)
        if output.stat().st_size > per_image_budget:
            oversized.add(slug)
        if not is_valid_webp(output):
            invalid.add(slug)

    rebuild = set(sources) if args.rebuild else set()
    work = missing | stale | oversized | invalid | rebuild

    print(
        "Maintenance: "
        f"{len(missing)} missing, {len(stale)} stale, "
        f"{len(oversized)} over per-image budget, {len(invalid)} invalid, "
        f"{len(orphaned)} orphaned"
    )

    if args.check:
        if work or orphaned:
            print("Shrunk exercise images need maintenance.")
            return 1
        total = sum(path.stat().st_size for path in outputs.values())
        if total > budget_bytes:
            print(
                f"Generated images use {human_size(total)}, exceeding the "
                f"{human_size(budget_bytes)} budget."
            )
            return 1
        print(
            f"Shrunk exercise images are current: {len(outputs)} files, "
            f"{human_size(total)}."
        )
        return 0

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    for slug in sorted(orphaned):
        print(f"Removing orphan: {outputs[slug].name}")
        outputs[slug].unlink()

    for index, slug in enumerate(sorted(work), start=1):
        source = sources[slug]
        destination = OUTPUT_DIR / f"{slug}{OUTPUT_EXTENSION}"
        print(f"[{index}/{len(work)}] Compressing {source.name} ...", flush=True)
        encoded = compress_to_budget(source, per_image_budget)
        write_atomically(destination, encoded.data)
        print(
            f"  -> {destination.name}: {encoded.width}x{encoded.height}, "
            f"quality {encoded.quality}, {len(encoded.data):,} bytes"
        )

    final_outputs = discover_outputs()
    final_slugs = set(final_outputs)
    if final_slugs != source_slugs:
        missing_after = sorted(source_slugs - final_slugs)
        extra_after = sorted(final_slugs - source_slugs)
        raise RuntimeError(
            f"Generated slug mismatch; missing={missing_after}, extra={extra_after}"
        )

    total = sum(path.stat().st_size for path in final_outputs.values())
    if total > budget_bytes:
        raise RuntimeError(
            f"Generated images use {human_size(total)}, exceeding the "
            f"{human_size(budget_bytes)} budget"
        )

    print(
        f"Done: {len(final_outputs)} previews use {human_size(total)} of the "
        f"{human_size(budget_bytes)} budget."
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, UnidentifiedImageError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc

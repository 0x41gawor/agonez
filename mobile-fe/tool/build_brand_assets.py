#!/usr/bin/env python3
"""Build the Agonez launch and launcher-icon assets from the brand logo sheet.

The source is tile 1 of ``media/logo-mark.png`` (the emblem shown on the hero
image wall and in the app header). The tile is a 418 px raster, so it is
upscaled 4x, smoothed and traced to vectors with potrace; every output is then
derived from those vectors and stays sharp at any density.

Two emblem shapes are produced:

* ``ink``: the original drawing, for light backgrounds.
* ``relief``: the same drawing with its lighting preserved on dark
  backgrounds. Lit skin becomes the fill, while lines and shadows stay dark.
  Tinting the plain ink drawing light instead would make every shadow look
  lit, which reads as an inside-out face.

Outputs (paths relative to the repository root):

* ``media/brand/agonez-{emblem-ink,emblem-relief,wordmark}.svg``: masters.
* ``mobile-fe/android/.../drawable{,-night}/splash_emblem.xml``: system splash.
* ``mobile-fe/android/.../drawable/ic_launcher_foreground.xml`` and the legacy
  ``mipmap-*/ic_launcher.png`` icons.
* ``mobile-fe/android/.../drawable/ic_stat_agonez.xml``: notification icon.
* ``mobile-fe/assets/brand/boot/``: white alpha masks for the Flutter boot
  screen, tinted at runtime.

Requires numpy, scipy, Pillow, matplotlib and potracer::

    python -m pip install numpy scipy Pillow matplotlib potracer
    python mobile-fe/tool/build_brand_assets.py
"""

from __future__ import annotations

import io
from dataclasses import dataclass
from pathlib import Path

import matplotlib

matplotlib.use("Agg")

import numpy as np  # noqa: E402
import potrace  # noqa: E402
from matplotlib import pyplot as plt  # noqa: E402
from matplotlib.patches import PathPatch  # noqa: E402
from matplotlib.path import Path as MplPath  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402
from scipy import ndimage as ndi  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
SHEET = REPO / "media" / "logo-mark.png"
MASTERS = REPO / "media" / "brand"
ANDROID_RES = REPO / "mobile-fe" / "android" / "app" / "src" / "main" / "res"
BOOT_ASSETS = REPO / "mobile-fe" / "assets" / "brand" / "boot"

# Tile 1 of the 3x3 sheet: emblem and wordmark boxes with a small margin.
EMBLEM_BOX = (88, 41, 414, 384)
WORDMARK_BOX = (118, 381, 378, 431)
UPSCALE = 4
# Paper and ink levels of the scanned sheet.
PAPER, INK = 237.0, 38.0

# Android system splash: the icon is a 288 dp canvas whose content must fit
# a centred 192 dp circle. A small margin keeps antialiasing off the mask.
SPLASH_CANVAS_DP = 288.0
SPLASH_RADIUS_DP = 92.0
# Adaptive launcher icon: 108 dp canvas, 66 dp safe circle.
LAUNCHER_CANVAS_DP = 108.0
LAUNCHER_RADIUS_DP = 31.0
# Notification small icon: Android draws only its alpha, in the status bar.
# Its paths use a 10x viewport so one decimal keeps 0.01 dp precision.
NOTIFICATION_CANVAS_DP = 24.0
NOTIFICATION_RADIUS_DP = 11.5
NOTIFICATION_VIEWPORT = 240.0
# Legacy (pre-Android 8) icons are a full rounded square, so the emblem
# radius is a share of the icon size.
LEGACY_RADIUS_RATIO = 0.36
# The boot screen's wordmark width in dp; its height follows the artwork.
WORDMARK_WIDTH_DP = 120.0

# AAPT2 stores XML strings longer than 32,767 bytes as "STRING_TOO_LARGE",
# which breaks the drawable, so vector paths are split below this length.
MAX_PATH_DATA = 30_000

GOLD = (0xE2, 0xC6, 0x90)
GROUND_DARK = (0x0D, 0x0F, 0x12)


@dataclass(frozen=True)
class Shape:
    """Traced closed outlines in source pixel space (y grows downwards).

    ``filled[i]`` is True for an outer outline and False for a hole.
    """

    curves: list[list[tuple]]
    filled: list[bool]
    width: int
    height: int


def load_alpha(box: tuple[int, int, int, int]) -> np.ndarray:
    tile = Image.open(SHEET).convert("L").crop(box)
    up = tile.resize((tile.width * UPSCALE, tile.height * UPSCALE), Image.LANCZOS)
    smooth = ndi.gaussian_filter(np.asarray(up, dtype=np.float32), 1.0)
    return np.clip((PAPER - smooth) / (PAPER - INK), 0, 1)


def relief_from(ink: np.ndarray) -> np.ndarray:
    """Lit skin plus the ink that borders the background (contour and ring)."""
    closed = ndi.binary_dilation(ink, iterations=4)
    labels, _ = ndi.label(~closed)
    edge_labels = np.unique(
        np.r_[labels[0], labels[-1], labels[:, 0], labels[:, -1]]
    )
    outside = np.isin(labels, edge_labels[edge_labels != 0])
    background = ndi.binary_dilation(outside, iterations=4) & ~ink
    near_background = ndi.distance_transform_edt(~background) <= 5 * UPSCALE
    return (~background & ~ink) | (ink & near_background)


def trace(mask: np.ndarray) -> Shape:
    # potracer traces False pixels of the array it is given.
    path = potrace.Bitmap(~mask).trace(
        turdsize=6 * UPSCALE, alphamax=1.0, opticurve=True, opttolerance=0.5
    )
    curves, filled = [], []
    for curve in path:
        filled.append(bool(curve._path.sign))
        start = curve.start_point
        segments = [("M", (start.x, start.y))]
        for segment in curve:
            if segment.is_corner:
                segments.append(("L", (segment.c.x, segment.c.y)))
                segments.append(("L", (segment.end_point.x, segment.end_point.y)))
            else:
                segments.append(
                    (
                        "C",
                        (segment.c1.x, segment.c1.y),
                        (segment.c2.x, segment.c2.y),
                        (segment.end_point.x, segment.end_point.y),
                    )
                )
        curves.append(segments)
    return Shape(curves, filled, mask.shape[1], mask.shape[0])


def extent_radius(mask: np.ndarray) -> float:
    """Distance from the mask centre to its farthest filled pixel."""
    ys, xs = np.nonzero(mask)
    cy, cx = (mask.shape[0] - 1) / 2, (mask.shape[1] - 1) / 2
    return float(np.sqrt((xs - cx) ** 2 + (ys - cy) ** 2).max())


def fit(shape: Shape, radius_px: float, canvas: float, radius: float):
    """Transform that centres the shape on a canvas inside a circle."""
    scale = radius / radius_px
    dx = canvas / 2 - shape.width / 2 * scale
    dy = canvas / 2 - shape.height / 2 * scale
    return lambda x, y: (x * scale + dx, y * scale + dy)


def curve_data(curve: list[tuple], transform, digits: int) -> str:
    out = []
    for command, *points in curve:
        coords = " ".join(
            f"{px:.{digits}f},{py:.{digits}f}"
            for px, py in (transform(*point) for point in points)
        )
        out.append(f"{command}{coords}")
    out.append("Z")
    return "".join(out)


def _number(value: float, digits: int) -> str:
    text = f"{value:.{digits}f}".rstrip("0").rstrip(".")
    return "0" if text in ("-0", "") else text


def compact_curve_data(curve: list[tuple], transform, digits: int) -> str:
    """Relative commands between rounded points: much shorter path text.

    Offsets are taken between points that are already rounded, so rounding
    never accumulates along the outline.
    """
    def point(raw) -> tuple[float, float]:
        x, y = transform(*raw)
        return round(x, digits), round(y, digits)

    out, current = [], None
    for command, *points in curve:
        mapped = [point(raw) for raw in points]
        if command == "M":
            out.append(f"M{_number(mapped[0][0], digits)},{_number(mapped[0][1], digits)}")
        else:
            offsets = (
                f"{_number(x - current[0], digits)},{_number(y - current[1], digits)}"
                for x, y in mapped
            )
            out.append(command.lower() + " ".join(offsets))
        current = mapped[-1]
    out.append("z")
    return "".join(out)


def path_data(shape: Shape, transform, digits: int = 2) -> str:
    return "".join(curve_data(curve, transform, digits) for curve in shape.curves)


def outline_groups(shape: Shape) -> list[list[int]]:
    """Each outer outline with the holes directly inside it.

    A hole only cuts through an outline drawn in the same ``<path>``, so a
    drawable may be split between these groups but never inside one.
    """
    outlines = [i for i, filled in enumerate(shape.filled) if filled]
    geometry = {
        i: to_mpl_path([shape.curves[i]], lambda x, y: (x, y)) for i in outlines
    }
    area = {
        i: float(np.prod(np.ptp(geometry[i].vertices, axis=0))) for i in outlines
    }
    groups = {i: [i] for i in outlines}
    for hole, filled in enumerate(shape.filled):
        if filled:
            continue
        point = shape.curves[hole][0][1]
        owners = [i for i in outlines if geometry[i].contains_point(point)]
        if not owners:
            raise SystemExit(f"Hole {hole} lies outside every outline")
        groups[min(owners, key=area.__getitem__)].append(hole)
    return list(groups.values())


def packed_path_data(shape: Shape, transform, digits: int = 1) -> list[str]:
    """Compact path data in strings AAPT2 can store, one per ``<path>``."""
    chunks, current = [], ""
    for group in outline_groups(shape):
        data = "".join(
            compact_curve_data(shape.curves[i], transform, digits) for i in group
        )
        if len(data) > MAX_PATH_DATA:
            raise SystemExit("An outline with its holes exceeds MAX_PATH_DATA")
        if current and len(current) + len(data) > MAX_PATH_DATA:
            chunks.append(current)
            current = ""
        current += data
    if current:
        chunks.append(current)
    return chunks


def write_svg(shape: Shape, name: str) -> None:
    MASTERS.mkdir(parents=True, exist_ok=True)
    data = path_data(shape, lambda x, y: (x, y), digits=1)
    (MASTERS / name).write_text(
        '<svg xmlns="http://www.w3.org/2000/svg" '
        f'viewBox="0 0 {shape.width} {shape.height}">'
        f'<path fill-rule="evenodd" d="{data}"/></svg>\n',
        encoding="utf-8",
    )


def write_vector_drawable(
    path: Path,
    chunks: list[str],
    canvas: float,
    fill: str,
    comment: str,
    viewport: float | None = None,
) -> None:
    viewport = viewport or canvas
    path.parent.mkdir(parents=True, exist_ok=True)
    paths = "".join(
        "    <path\n"
        f'        android:fillColor="{fill}"\n'
        '        android:fillType="evenOdd"\n'
        f'        android:pathData="{data}" />\n'
        for data in chunks
    )
    path.write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        f"<!-- {comment} Generated by mobile-fe/tool/build_brand_assets.py. -->\n"
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
        f'    android:width="{canvas:g}dp"\n'
        f'    android:height="{canvas:g}dp"\n'
        f'    android:viewportWidth="{viewport:g}"\n'
        f'    android:viewportHeight="{viewport:g}">\n'
        f"{paths}"
        "</vector>\n",
        encoding="utf-8",
    )


def to_mpl_path(curves: list[list[tuple]], transform) -> MplPath:
    vertices, codes = [], []
    for curve in curves:
        for command, *points in curve:
            mapped = [transform(*point) for point in points]
            if command == "M":
                vertices.append(mapped[0])
                codes.append(MplPath.MOVETO)
            elif command == "L":
                vertices.append(mapped[0])
                codes.append(MplPath.LINETO)
            else:
                vertices.extend(mapped)
                codes.extend([MplPath.CURVE4] * 3)
        vertices.append(vertices[-1])
        codes.append(MplPath.CLOSEPOLY)
    return MplPath(vertices, codes)


def rasterize(shape: Shape, transform, width: int, height: int) -> np.ndarray:
    """Antialiased coverage (0..1) of the shape, rendered by matplotlib."""
    figure = plt.figure(figsize=(width / 100, height / 100), dpi=100)
    axes = figure.add_axes((0, 0, 1, 1))
    axes.set_xlim(0, width)
    axes.set_ylim(height, 0)
    axes.axis("off")
    axes.add_patch(
        PathPatch(
            to_mpl_path(shape.curves, transform),
            facecolor="black",
            edgecolor="none",
        )
    )
    buffer = io.BytesIO()
    figure.savefig(buffer, format="png", dpi=100, facecolor="white")
    plt.close(figure)
    rendered = Image.open(buffer).convert("L").resize((width, height))
    return 1 - np.asarray(rendered, dtype=np.float32) / 255


def save_mask(coverage: np.ndarray, path: Path) -> None:
    """White pixels whose alpha is the coverage, for tinting at runtime."""
    path.parent.mkdir(parents=True, exist_ok=True)
    alpha = (np.clip(coverage, 0, 1) * 255).round().astype(np.uint8)
    white = np.full_like(alpha, 255)
    Image.fromarray(np.dstack([white, white, white, alpha]), "RGBA").save(
        path, optimize=True
    )


def legacy_icon(shape: Shape, radius_px: float, size: int) -> Image.Image:
    """Pre-Android 8 launcher icon: gold relief on a rounded dark square."""
    scale = 4
    big = size * scale
    coverage = rasterize(
        shape,
        fit(shape, radius_px, big, big * LEGACY_RADIUS_RATIO),
        big,
        big,
    )
    icon = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    square = Image.new("L", (big, big), 0)
    ImageDraw.Draw(square).rounded_rectangle(
        (0, 0, big - 1, big - 1), radius=int(big * 0.22), fill=255
    )
    icon.paste(Image.new("RGBA", (big, big), GROUND_DARK + (255,)), mask=square)
    gold = Image.new("RGBA", (big, big), GOLD + (255,))
    emblem = Image.fromarray((coverage * 255).astype(np.uint8), "L")
    icon.paste(gold, mask=Image.fromarray(np.minimum(emblem, square)))
    return icon.resize((size, size), Image.LANCZOS)


def main() -> None:
    emblem_alpha = load_alpha(EMBLEM_BOX)
    ink = emblem_alpha > 0.5
    relief = relief_from(ink)
    word = load_alpha(WORDMARK_BOX) > 0.5

    print("Tracing...", flush=True)
    shapes = {"ink": trace(ink), "relief": trace(relief), "word": trace(word)}
    for key, shape in shapes.items():
        print(f"  {key}: {len(shape.curves)} outlines", flush=True)

    write_svg(shapes["ink"], "agonez-emblem-ink.svg")
    write_svg(shapes["relief"], "agonez-emblem-relief.svg")
    write_svg(shapes["word"], "agonez-wordmark.svg")

    # Both emblem variants share one scale so they overlay exactly.
    radius_px = max(extent_radius(ink), extent_radius(relief))
    splash = {
        variant: fit(shapes[variant], radius_px, SPLASH_CANVAS_DP, SPLASH_RADIUS_DP)
        for variant in ("ink", "relief")
    }
    write_vector_drawable(
        ANDROID_RES / "drawable" / "splash_emblem.xml",
        packed_path_data(shapes["ink"], splash["ink"]),
        SPLASH_CANVAS_DP,
        "@color/splash_emblem",
        "Agonez emblem for the light system splash.",
    )
    write_vector_drawable(
        ANDROID_RES / "drawable-night" / "splash_emblem.xml",
        packed_path_data(shapes["relief"], splash["relief"]),
        SPLASH_CANVAS_DP,
        "@color/splash_emblem",
        "Agonez emblem (relief) for the dark system splash.",
    )
    launcher = fit(
        shapes["relief"], radius_px, LAUNCHER_CANVAS_DP, LAUNCHER_RADIUS_DP
    )
    write_vector_drawable(
        ANDROID_RES / "drawable" / "ic_launcher_foreground.xml",
        packed_path_data(shapes["relief"], launcher),
        LAUNCHER_CANVAS_DP,
        "@color/ic_launcher_emblem",
        "Adaptive launcher icon foreground, also used as its monochrome layer.",
    )
    write_vector_drawable(
        ANDROID_RES / "drawable" / "ic_stat_agonez.xml",
        packed_path_data(
            shapes["relief"],
            fit(
                shapes["relief"],
                radius_px,
                NOTIFICATION_VIEWPORT,
                NOTIFICATION_VIEWPORT * NOTIFICATION_RADIUS_DP / NOTIFICATION_CANVAS_DP,
            ),
        ),
        NOTIFICATION_CANVAS_DP,
        "#FFFFFFFF",
        "Status bar icon for rest notifications.",
        viewport=NOTIFICATION_VIEWPORT,
    )
    for density, size in (
        ("mdpi", 48),
        ("hdpi", 72),
        ("xhdpi", 96),
        ("xxhdpi", 144),
        ("xxxhdpi", 192),
    ):
        legacy_icon(shapes["relief"], radius_px, size).save(
            ANDROID_RES / f"mipmap-{density}" / "ic_launcher.png", optimize=True
        )

    # Flutter boot screen: the same 288 dp canvas as the system splash, so the
    # first Flutter frame lands exactly on the native one.
    word_shape = shapes["word"]
    word_height_dp = WORDMARK_WIDTH_DP * word_shape.height / word_shape.width
    for ratio, folder in ((1, ""), (2, "2.0x"), (3, "3.0x")):
        target = BOOT_ASSETS / folder if folder else BOOT_ASSETS
        canvas = round(SPLASH_CANVAS_DP * ratio)
        for variant, name in (("ink", "emblem_ink.png"), ("relief", "emblem_relief.png")):
            transform = fit(
                shapes[variant], radius_px, canvas, SPLASH_RADIUS_DP * ratio
            )
            save_mask(rasterize(shapes[variant], transform, canvas, canvas), target / name)
        width = round(WORDMARK_WIDTH_DP * ratio)
        height = round(word_height_dp * ratio)
        scale = width / word_shape.width
        save_mask(
            rasterize(word_shape, lambda x, y: (x * scale, y * scale), width, height),
            target / "wordmark.png",
        )
    print(f"Wordmark: {WORDMARK_WIDTH_DP:g} x {word_height_dp:.1f} dp")
    print("Done.")


if __name__ == "__main__":
    main()

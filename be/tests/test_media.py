from pathlib import Path

import pytest

from agonez_api.core.media import MediaResolver


def test_media_resolver_returns_existing_slug_asset(tmp_path: Path) -> None:
    exercise_dir = tmp_path / "exercises"
    exercise_dir.mkdir()
    (exercise_dir / "dragon_flag.png").write_bytes(b"png")
    resolver = MediaResolver(root=tmp_path, url_prefix="/media")

    assert resolver.image_url("exercises", "dragon_flag") == (
        "/media/exercises/dragon_flag.png"
    )
    assert resolver.image_url("exercises", "not_installed") is None


def test_media_resolver_prefers_modern_extensions_and_builds_gallery(tmp_path: Path) -> None:
    muscle_dir = tmp_path / "muscles"
    gallery_dir = muscle_dir / "latissimus_dorsi"
    gallery_dir.mkdir(parents=True)
    (muscle_dir / "latissimus_dorsi.png").write_bytes(b"png")
    (muscle_dir / "latissimus_dorsi.webp").write_bytes(b"webp")
    (gallery_dir / "02-insertion.jpg").write_bytes(b"jpg")
    (gallery_dir / "01-origin.webp").write_bytes(b"webp")
    (gallery_dir / "notes.txt").write_text("ignored")
    resolver = MediaResolver(
        root=tmp_path,
        url_prefix="/media",
        public_base_url="https://cdn.example/agonez/",
    )

    assert resolver.image_url("muscles", "latissimus_dorsi") == (
        "https://cdn.example/agonez/muscles/latissimus_dorsi.webp"
    )
    assert resolver.gallery_urls("muscles", "latissimus_dorsi") == [
        "https://cdn.example/agonez/muscles/latissimus_dorsi/01-origin.webp",
        "https://cdn.example/agonez/muscles/latissimus_dorsi/02-insertion.jpg",
    ]


def test_media_resolver_rejects_path_traversal(tmp_path: Path) -> None:
    resolver = MediaResolver(root=tmp_path, url_prefix="/media")
    with pytest.raises(ValueError, match="Invalid media slug"):
        resolver.image_url("exercises", "../secret")

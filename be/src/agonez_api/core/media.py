import re
from pathlib import Path
from urllib.parse import quote

SUPPORTED_IMAGE_EXTENSIONS = (".avif", ".webp", ".png", ".jpg", ".jpeg")
SAFE_SLUG = re.compile(r"^[a-z0-9]+(?:_[a-z0-9]+)*$")


class MediaResolver:
    def __init__(
        self,
        *,
        root: Path,
        url_prefix: str,
        public_base_url: str | None = None,
    ) -> None:
        self._root = root.resolve()
        self._url_prefix = url_prefix.rstrip("/")
        self._public_base_url = public_base_url.rstrip("/") if public_base_url else None

    def image_url(self, collection: str, slug: str) -> str | None:
        self._validate(collection, slug)
        directory = self._root / collection
        for extension in SUPPORTED_IMAGE_EXTENSIONS:
            candidate = directory / f"{slug}{extension}"
            if candidate.is_file():
                return self._url(f"{collection}/{candidate.name}")
        return None

    def gallery_urls(self, collection: str, slug: str) -> list[str]:
        self._validate(collection, slug)
        directory = self._root / "galleries" / collection / slug
        if not directory.is_dir():
            return []

        return [
            self._url(f"galleries/{collection}/{slug}/{path.name}")
            for path in sorted(directory.iterdir(), key=lambda item: item.name.casefold())
            if path.is_file() and path.suffix.casefold() in SUPPORTED_IMAGE_EXTENSIONS
        ]

    def _url(self, relative_path: str) -> str:
        encoded_path = quote(relative_path, safe="/")
        if self._public_base_url:
            return f"{self._public_base_url}/{encoded_path}"
        return f"{self._url_prefix}/{encoded_path}"

    @staticmethod
    def _validate(collection: str, slug: str) -> None:
        if collection not in {"exercises", "muscles"}:
            raise ValueError("Unsupported media collection")
        if not SAFE_SLUG.fullmatch(slug):
            raise ValueError("Invalid media slug")

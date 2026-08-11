import re
from urllib.parse import parse_qs, urlparse

YOUTUBE_ID_PATTERN = re.compile(r"^[A-Za-z0-9_-]{11}$")
YOUTUBE_HOSTS = {
    "youtube.com",
    "www.youtube.com",
    "m.youtube.com",
    "music.youtube.com",
    "youtube-nocookie.com",
    "www.youtube-nocookie.com",
}


def youtube_video_id(value: str) -> str | None:
    parsed = urlparse(value.strip())
    if parsed.scheme not in {"http", "https"}:
        return None

    host = (parsed.hostname or "").lower()
    path_parts = [part for part in parsed.path.split("/") if part]
    video_id: str | None = None

    if host in {"youtu.be", "www.youtu.be"} and path_parts:
        video_id = path_parts[0]
    elif host in YOUTUBE_HOSTS:
        if parsed.path.rstrip("/") == "/watch":
            video_id = parse_qs(parsed.query).get("v", [None])[0]
        elif len(path_parts) >= 2 and path_parts[0] in {"embed", "live", "shorts"}:
            video_id = path_parts[1]

    return video_id if video_id and YOUTUBE_ID_PATTERN.fullmatch(video_id) else None


def normalize_youtube_url(value: str) -> str:
    video_id = youtube_video_id(value)
    if video_id is None:
        raise ValueError("Enter a valid YouTube video URL")
    return f"https://www.youtube.com/watch?v={video_id}"

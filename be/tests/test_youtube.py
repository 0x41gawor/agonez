import pytest

from agonez_api.modules.atlas.youtube import normalize_youtube_url, youtube_video_id


@pytest.mark.parametrize(
    ("url", "video_id"),
    [
        ("https://youtu.be/1Z-aEpjdphU?si=abc", "1Z-aEpjdphU"),
        ("https://www.youtube.com/watch?v=1Z-aEpjdphU", "1Z-aEpjdphU"),
        ("https://youtube.com/shorts/1Z-aEpjdphU", "1Z-aEpjdphU"),
        ("https://www.youtube-nocookie.com/embed/1Z-aEpjdphU", "1Z-aEpjdphU"),
    ],
)
def test_youtube_video_id_supports_common_urls(url: str, video_id: str) -> None:
    assert youtube_video_id(url) == video_id
    assert normalize_youtube_url(url) == f"https://www.youtube.com/watch?v={video_id}"


@pytest.mark.parametrize(
    "url",
    [
        "https://example.com/watch?v=1Z-aEpjdphU",
        "javascript:alert(1)",
        "https://youtu.be/not-an-id",
    ],
)
def test_normalize_youtube_url_rejects_unsupported_values(url: str) -> None:
    with pytest.raises(ValueError, match="valid YouTube"):
        normalize_youtube_url(url)

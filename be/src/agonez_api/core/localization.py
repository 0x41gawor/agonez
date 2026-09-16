from typing import Final

DEFAULT_CONTENT_LOCALE: Final = "en"
SUPPORTED_CONTENT_LOCALES: Final = ("en", "pl", "fr", "es", "de")


def normalize_content_locale(value: str | None) -> str | None:
    """Reduce a language tag to a supported base locale."""
    if not value:
        return None
    language = value.strip().lower().replace("_", "-").split("-", 1)[0]
    return language if language in SUPPORTED_CONTENT_LOCALES else None


def negotiate_content_locale(accept_language: str | None) -> str:
    """Choose the best supported locale from an RFC 9110 Accept-Language value."""
    if not accept_language:
        return DEFAULT_CONTENT_LOCALE

    candidates: list[tuple[float, int, str]] = []
    for position, raw_range in enumerate(accept_language.split(",")):
        parts = [part.strip() for part in raw_range.split(";")]
        language_range = parts[0]
        quality = 1.0
        for parameter in parts[1:]:
            name, separator, value = parameter.partition("=")
            if separator and name.strip().lower() == "q":
                try:
                    quality = float(value)
                except ValueError:
                    quality = 0.0
                break
        if not 0.0 < quality <= 1.0:
            continue

        locale = (
            DEFAULT_CONTENT_LOCALE
            if language_range == "*"
            else normalize_content_locale(language_range)
        )
        if locale is not None:
            candidates.append((quality, position, locale))

    if not candidates:
        return DEFAULT_CONTENT_LOCALE
    return sorted(candidates, key=lambda candidate: (-candidate[0], candidate[1]))[0][2]

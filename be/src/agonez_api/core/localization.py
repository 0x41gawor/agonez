from typing import Final

DEFAULT_CONTENT_LOCALE: Final = "en"
SUPPORTED_CONTENT_LOCALES: Final = ("en", "pl", "fr", "es", "de", "it", "nl", "sv", "pt-BR", "uk")

# "pt-br" -> "pt-BR", "en" -> "en", ...
_LOCALE_BY_TAG: Final = {locale.lower(): locale for locale in SUPPORTED_CONTENT_LOCALES}
# "pt" -> "pt-BR", "en" -> "en", ...
_LOCALE_BY_LANGUAGE: Final = {
    locale.split("-", 1)[0].lower(): locale for locale in SUPPORTED_CONTENT_LOCALES
}


def normalize_content_locale(value: str | None) -> str | None:
    """Map a language tag to a supported locale, preferring an exact match."""
    if not value:
        return None
    tag = value.strip().lower().replace("_", "-")
    if not tag:
        return None
    exact = _LOCALE_BY_TAG.get(tag)
    if exact is not None:
        return exact
    return _LOCALE_BY_LANGUAGE.get(tag.split("-", 1)[0])


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

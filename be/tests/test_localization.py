from agonez_api.core.localization import (
    DEFAULT_CONTENT_LOCALE,
    negotiate_content_locale,
    normalize_content_locale,
)


def test_normalizes_supported_regional_locales() -> None:
    assert normalize_content_locale("pl-PL") == "pl"
    assert normalize_content_locale("FR_ca") == "fr"
    assert normalize_content_locale("es-MX") == "es"
    assert normalize_content_locale("it-IT") == "it"
    assert normalize_content_locale("pt_br") == "pt-BR"
    assert normalize_content_locale("uk-UA") == "uk"


def test_negotiates_quality_and_header_order() -> None:
    assert negotiate_content_locale("de-DE,de;q=0.9,en;q=0.8") == "de"
    assert negotiate_content_locale("fr;q=0.5, es;q=0.9") == "es"
    assert negotiate_content_locale("pl;q=0.8, de;q=0.8") == "pl"


def test_negotiation_falls_back_to_canonical_english() -> None:
    assert negotiate_content_locale(None) == DEFAULT_CONTENT_LOCALE
    assert negotiate_content_locale("ja-JP, zh;q=0.8") == DEFAULT_CONTENT_LOCALE
    assert negotiate_content_locale("fr;q=0, *;q=0.5") == DEFAULT_CONTENT_LOCALE
    assert negotiate_content_locale("fr;q=invalid") == DEFAULT_CONTENT_LOCALE

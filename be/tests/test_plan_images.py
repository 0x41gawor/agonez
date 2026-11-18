import pytest

from agonez_api.modules.plans.exceptions import PlanDomainValidationError
from agonez_api.modules.plans.images import (
    MAX_IMAGE_BYTES,
    checksum,
    image_url,
    normalize_content_type,
    validate_image,
)

PNG = b"\x89PNG\r\n\x1a\n" + b"0" * 64
JPEG = b"\xff\xd8\xff\xe0" + b"0" * 64
WEBP = b"RIFF" + b"\x00\x00\x00\x00" + b"WEBP" + b"0" * 64


def test_each_supported_type_is_accepted_when_the_bytes_agree() -> None:
    assert validate_image("image/png", PNG) == "image/png"
    assert validate_image("image/jpeg", JPEG) == "image/jpeg"
    assert validate_image("image/webp", WEBP) == "image/webp"


def test_content_type_parameters_and_casing_are_tolerated() -> None:
    assert normalize_content_type("IMAGE/PNG; charset=binary") == "image/png"


def test_bytes_decide_the_type_not_the_declared_header() -> None:
    # A PNG renamed to .jpg would otherwise be stored and served under the wrong type.
    with pytest.raises(PlanDomainValidationError) as error:
        validate_image("image/jpeg", PNG)
    assert "declares 'image/jpeg'" in str(error.value)
    assert "'image/png'" in str(error.value)


def test_a_payload_that_is_not_an_image_is_refused() -> None:
    with pytest.raises(PlanDomainValidationError) as error:
        validate_image("image/png", b"<svg xmlns='http://www.w3.org/2000/svg'/>")
    assert "not a readable image" in str(error.value)


def test_missing_and_unsupported_content_types_are_refused() -> None:
    with pytest.raises(PlanDomainValidationError):
        validate_image(None, PNG)
    with pytest.raises(PlanDomainValidationError):
        validate_image("image/gif", PNG)


def test_empty_and_oversized_uploads_are_refused() -> None:
    with pytest.raises(PlanDomainValidationError) as empty:
        validate_image("image/png", b"")
    assert "empty" in str(empty.value)

    oversized = PNG + b"0" * MAX_IMAGE_BYTES
    with pytest.raises(PlanDomainValidationError) as large:
        validate_image("image/png", oversized)
    assert str(MAX_IMAGE_BYTES) in str(large.value)


def test_the_largest_allowed_upload_is_still_accepted() -> None:
    exact = PNG + b"0" * (MAX_IMAGE_BYTES - len(PNG))
    assert len(exact) == MAX_IMAGE_BYTES
    assert validate_image("image/png", exact) == "image/png"


def test_the_url_carries_the_checksum_so_a_replacement_is_seen_immediately() -> None:
    first = image_url(12, checksum(PNG))
    second = image_url(12, checksum(JPEG))
    assert first is not None and first.startswith("/api/plans/12/image?v=")
    assert first != second


def test_a_plan_without_an_image_has_no_url() -> None:
    assert image_url(12, None) is None


def test_a_draft_artifact_can_be_saved_back_unchanged() -> None:
    """GET /draft then PUT /draft must stay valid: the artifact's cover is ignored, not refused."""
    from agonez_api.modules.plans.schemas import PlanDraftArtifact, PlanDraftUpdate

    artifact = PlanDraftArtifact(
        id=6,
        revision_id=9,
        revision_no=1,
        lock_version=3,
        name="Round trip",
        description=None,
        accent="teal",  # type: ignore[arg-type]
        image_url="/api/plans/6/image?v=abc123",
        days=[],
    )
    update = PlanDraftUpdate.model_validate(artifact.model_dump())
    assert update.accent is not None and update.accent.value == "teal"

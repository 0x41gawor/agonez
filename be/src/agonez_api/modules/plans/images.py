"""Validation and addressing for plan cover images.

Cover images are stored in the database, not under ``MEDIA_ROOT``. That tree is the
curated Atlas library: it is mounted read-only and its files are named after exercise
and muscle slugs, while a cover image is plan data the API owns and the ordinary
database backup already carries.
"""

import hashlib

from agonez_api.modules.plans.exceptions import PlanDomainValidationError

# Kept below the proxy's 2 MB body limit so an oversized upload is refused here, with
# a readable message, instead of by nginx with a bare 413. The editor downscales
# before uploading, so real covers land two orders of magnitude under this.
MAX_IMAGE_BYTES = 1_500_000

SUPPORTED_IMAGE_TYPES: dict[str, tuple[str, ...]] = {
    "image/webp": ("webp",),
    "image/png": ("png",),
    "image/jpeg": ("jpeg", "jpg"),
}

_SUPPORTED_TYPE_LIST = ", ".join(sorted(SUPPORTED_IMAGE_TYPES))


def _sniff(data: bytes) -> str | None:
    """Return the content type the bytes actually are, or None when unrecognized."""
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return "image/png"
    if data.startswith(b"\xff\xd8\xff"):
        return "image/jpeg"
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "image/webp"
    return None


def normalize_content_type(raw: str | None) -> str:
    """Reduce a request Content-Type to a supported image type, or reject it."""
    if not raw:
        raise PlanDomainValidationError(
            f"A cover image upload must declare a Content-Type ({_SUPPORTED_TYPE_LIST})"
        )
    declared = raw.split(";", 1)[0].strip().lower()
    if declared not in SUPPORTED_IMAGE_TYPES:
        raise PlanDomainValidationError(
            f"Unsupported cover image type '{declared}'; expected one of {_SUPPORTED_TYPE_LIST}"
        )
    return declared


def validate_image(content_type: str | None, data: bytes) -> str:
    """Validate an uploaded cover image and return its confirmed content type.

    The declared type is only a hint: the bytes themselves decide, so a payload that
    is not the image it claims to be is refused rather than stored and served back.
    """
    declared = normalize_content_type(content_type)
    if not data:
        raise PlanDomainValidationError("The cover image upload was empty")
    if len(data) > MAX_IMAGE_BYTES:
        raise PlanDomainValidationError(
            f"The cover image is {len(data)} bytes; the limit is {MAX_IMAGE_BYTES}"
        )
    actual = _sniff(data)
    if actual is None:
        raise PlanDomainValidationError(
            f"The upload is not a readable image; expected one of {_SUPPORTED_TYPE_LIST}"
        )
    if actual != declared:
        raise PlanDomainValidationError(
            f"The upload declares '{declared}' but its content is '{actual}'"
        )
    return actual


def checksum(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def image_url(plan_id: int, checksum_value: str | None) -> str | None:
    """Address the plan's cover image, or None when it has none.

    The checksum rides along as a query parameter so a replaced image reaches clients
    immediately while the bytes themselves stay cacheable forever.
    """
    if not checksum_value:
        return None
    return f"/api/plans/{plan_id}/image?v={checksum_value[:16]}"

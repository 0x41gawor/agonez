import re
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


class APIModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class WaitlistSubmission(APIModel):
    email: str = Field(min_length=3, max_length=254)
    website: str = Field(default="", max_length=200)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: str) -> str:
        normalized = value.strip().casefold()
        if not EMAIL_PATTERN.fullmatch(normalized):
            raise ValueError("email must be a valid address")
        return normalized


class WaitlistSubmissionResponse(APIModel):
    accepted: Literal[True] = True

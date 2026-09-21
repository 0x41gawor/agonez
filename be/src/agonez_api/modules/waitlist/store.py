import fcntl
import json
import os
from datetime import datetime, timezone
from pathlib import Path


class WaitlistStore:
    """Persist unique addresses in a small, append-only JSON Lines file."""

    def __init__(self, path: Path) -> None:
        self.path = path

    def add(self, *, email: str, locale: str) -> bool:
        self.path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
        descriptor = os.open(self.path, os.O_CREAT | os.O_RDWR | os.O_APPEND, 0o600)

        with os.fdopen(descriptor, "a+", encoding="utf-8") as stream:
            fcntl.flock(stream.fileno(), fcntl.LOCK_EX)
            stream.seek(0)
            for line in stream:
                try:
                    record = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if str(record.get("email", "")).casefold() == email.casefold():
                    return False

            record = {
                "email": email,
                "locale": locale,
                "created_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
            }
            stream.write(json.dumps(record, ensure_ascii=False, separators=(",", ":")) + "\n")
            stream.flush()
            os.fsync(stream.fileno())
            return True

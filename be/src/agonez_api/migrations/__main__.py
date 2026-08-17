import asyncio

from agonez_api.core.config import get_settings
from agonez_api.migrations.runner import run_migrations


def main() -> None:
    asyncio.run(run_migrations(get_settings()))


if __name__ == "__main__":
    main()

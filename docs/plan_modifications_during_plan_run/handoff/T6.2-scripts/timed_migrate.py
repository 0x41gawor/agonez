"""Run the real migration runner (as the container's `python -m agonez_api.migrations` does) and time it."""
import asyncio, logging, time
import agonez_api
from agonez_api.core.config import get_settings
from agonez_api.migrations.runner import run_migrations

logging.basicConfig(level=logging.INFO, format="%(asctime)s.%(msecs)03d %(name)s %(message)s", datefmt="%H:%M:%S")
s = get_settings()
assert s.db_port not in (33327, 3421) and s.db_host == "127.0.0.1", "not the scratch DB"
print("code:", agonez_api.__file__, "db:", s.db_host, s.db_port, s.db_name)
t = time.perf_counter()
asyncio.run(run_migrations(s))
print(f"run_migrations: {(time.perf_counter() - t) * 1000:.0f} ms")

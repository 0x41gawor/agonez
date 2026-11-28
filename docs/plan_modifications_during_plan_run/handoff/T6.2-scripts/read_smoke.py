"""RB-07 desktop read smoke (+ mobile context): every read of every run must answer 200.

usage: python -I read_smoke.py <base_url> [run_id ...]   (default: every run of the run list)
"""
import json, sys, time, urllib.request, urllib.error

BASE = sys.argv[1]
DEVICE = {"X-Agonez-Device-Id": "00000000-0000-4000-8000-000000000062", "Accept-Language": "en"}

def get(path, headers=None):
    req = urllib.request.Request(BASE + path, headers=headers or {})
    t = time.perf_counter()
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status, json.loads(r.read() or b"null"), time.perf_counter() - t
    except urllib.error.HTTPError as e:
        raw = e.read()
        try:
            body = json.loads(raw or b"null")
        except ValueError:
            body = raw.decode(errors="replace")[:200]
        return e.code, body, time.perf_counter() - t

status, runs, _ = get("/api/v1/exec/plan-runs")
assert status == 200, (status, runs)
ids = [int(a) for a in sys.argv[2:]] or sorted(item["plan_run_id"] for item in runs["items"])
failures, total, slowest = [], 0, (0.0, "")
for run in ids:
    base = f"/api/v1/exec/plan-runs/{run}"
    reads = {}
    def read(path, headers=None):
        global total, slowest
        status, body, took = get(path, headers)
        total += 1
        slowest = max(slowest, (took, path))
        if status != 200:
            failures.append((path, status, body))
        return body
    for name in ("overview", "analysis/queue", "microcycles", "load-series", "calendar", "events", "workout-traces"):
        reads[name] = read(f"{base}/{name}")
    for item in (reads["workout-traces"] or {}).get("items", []):
        read(f"{base}/workout-traces/{item['workout_trace_id']}")
    traces = {e["exercise_trace_id"] for w in (reads["analysis/queue"] or {}).get("workouts", []) for e in w["exercises"]}
    for trace in sorted(traces):
        read(f"{base}/exercise-traces/{trace}")
        read(f"{base}/exercise-traces/{trace}/next")
    read(f"/api/v1/mobile/context?plan_run_id={run}", DEVICE)
    o = reads["overview"] if isinstance(reads["overview"], dict) else {}
    r = o.get("run", {})
    print(f"run {run}: plan {r.get('plan', {}).get('code')} initial r{r.get('initial_revision', {}).get('revision_no')} "
          f"{r.get('initial_revision', {}).get('status')}, {len(traces)} exercise traces, "
          f"{len((reads['microcycles'] or {}).get('microcycles', []))} microcycles, {len((reads['load-series'] or {}).get('series', (reads['load-series'] or {}).get('items', [])))} load series")
for path in ("/api/v1/mobile/plan-runs", "/api/v1/mobile/context"):
    status, body, _ = get(path, DEVICE); total += 1
    if status != 200:
        failures.append((path, status, body))
print(f"{total} reads, {len(failures)} not 200, slowest {slowest[0]*1000:.0f} ms {slowest[1]}")
for f in failures:
    print("FAIL", f[0], f[1], json.dumps(f[2])[:300])
sys.exit(1 if failures else 0)

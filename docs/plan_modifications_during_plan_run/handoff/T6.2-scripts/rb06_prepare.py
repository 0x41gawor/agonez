"""RB-06 preparation, as a coach does in the analysis queue: for every exercise trace of the given runs
whose /next is editable, save that next prescription (PUT .../exercise-prescriptions/<trace>) with the
default loads (previous prescription, else previous performance, else 20 kg).
usage: python -I rb06_prepare.py <base_url> <run_id> [...]"""
import json, sys, urllib.request, urllib.error
from collections import Counter

BASE = sys.argv[1]

def call(method, path, payload=None):
    req = urllib.request.Request(BASE + path, method=method, data=json.dumps(payload).encode() if payload is not None else None,
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status, json.loads(r.read() or b"null")
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read() or b"null")

for run in map(int, sys.argv[2:]):
    base = f"/api/v1/exec/plan-runs/{run}"
    status, queue = call("GET", f"{base}/analysis/queue"); assert status == 200, queue
    traces = sorted({e["exercise_trace_id"] for w in queue["workouts"] for e in w["exercises"]})
    states, saved, sessions = Counter(), Counter(), set()
    for trace in traces:
        status, nxt = call("GET", f"{base}/exercise-traces/{trace}/next"); assert status == 200, nxt
        states[nxt["state"]] += 1
        if nxt["state"] != "editable" or nxt["prescription"] is not None:
            continue
        d = nxt["defaults"]
        def load(i):
            for source in (d.get("from_previous_prescription"), d.get("from_previous_performance"), d.get("from_seed_run")):
                if source and i < len(source) and source[i] is not None:
                    return source[i]
            return 20.0
        payload = {"based_on_exercise_performance_id": (nxt["basis"] or {}).get("exercise_performance_id"),
                   "sets": [{"ordinal": s["ordinal"], "load_kg": load(i), "comment": None} for i, s in enumerate(nxt["plan_sets"])],
                   "prescription_comment": "T6.2 rehearsal", "expected_version": None}
        status, body = call("PUT", f"{base}/sessions/{nxt['target']['session_id']}/exercise-prescriptions/{trace}", payload)
        saved[status] += 1
        if status == 200:
            sessions.add((nxt["target"]["scheduled_date"], nxt["target"]["session_id"]))
        else:
            print("  PUT failed", run, trace, status, json.dumps(body)[:200])
    print(f"run {run}: {len(traces)} traces, next states {dict(states)}, PUT answers {dict(saved)}, "
          f"sessions prescribed {sorted(sessions)}")

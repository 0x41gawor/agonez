"""Destructive-but-self-cleaning PlanCreator API scenarios for a deployed test instance.

Run inside the API container so it can reach both localhost HTTP and the configured
PostgreSQL service. Every created plan is removed in a finally block.
"""

import copy
import json
import urllib.error
import urllib.request
from typing import Any

import psycopg

from agonez_api.core.config import Settings

BASE_URL = "http://127.0.0.1:8000"


def request(
    method: str,
    path: str,
    payload: dict[str, Any] | None = None,
) -> tuple[int, Any]:
    body = json.dumps(payload).encode() if payload is not None else None
    headers = {"Content-Type": "application/json"} if payload is not None else {}
    outgoing = urllib.request.Request(
        BASE_URL + path,
        data=body,
        headers=headers,
        method=method,
    )
    try:
        with urllib.request.urlopen(outgoing, timeout=10) as response:
            content = response.read()
            return response.status, json.loads(content) if content else None
    except urllib.error.HTTPError as exc:
        content = exc.read()
        return exc.code, json.loads(content) if content else None


def expect(
    method: str,
    path: str,
    status: int,
    payload: dict[str, Any] | None = None,
) -> Any:
    actual_status, response = request(method, path, payload)
    assert actual_status == status, (method, path, actual_status, response)
    return response


def find_catalog_slug(kind: str, preferred_slug: str, fallback_query: str) -> str:
    response = expect("GET", f"/api/atlas/{kind}?q={fallback_query}&per_page=100", 200)
    slugs = [item["slug"] for item in response["items"]]
    if preferred_slug in slugs:
        return preferred_slug
    assert slugs, f"No {kind} catalog row matched {fallback_query}"
    return slugs[0]


def populated_payload(
    draft: dict[str, Any],
    *,
    default_exercise: str,
    second_exercise: str,
    target_muscle: str,
) -> dict[str, Any]:
    payload = copy.deepcopy(draft)
    payload["name"] = "Codex PlanCreator validation"
    payload["description"] = "Temporary aggregate used by automated live checks"
    payload["days"] = [
        {
            "id": None,
            "ordinal": 0,
            "weekday": 1,
            "name": "Push A",
            "description": "Primary session",
            "workout_unit": {
                "id": None,
                "name": "Push A",
                "description": None,
                "warmup_notes": "General warm-up",
                "stretch_notes": None,
                "exercise_slots": [
                    {
                        "id": None,
                        "ordinal": 0,
                        "name": "Primary chest press",
                        "description": None,
                        "goal": "Main progressive chest stimulus",
                        "role": "PRIMARY_PROGRESSIVE",
                        "volume_axis": None,
                        "target_muscle_slugs": [target_muscle],
                        "variants": [
                            {
                                "id": None,
                                "ordinal": 0,
                                "variant_type": "DEFAULT",
                                "exercise_slug": default_exercise,
                                "sets": [
                                    {
                                        "id": None,
                                        "ordinal": 0,
                                        "reps": {"min": 5, "max": 7},
                                        "rir": 2,
                                        "min_volume_level": 0,
                                    },
                                    {
                                        "id": None,
                                        "ordinal": 1,
                                        "reps": {"min": 8, "max": 10},
                                        "rir": 1,
                                        "min_volume_level": 1,
                                    },
                                ],
                            }
                        ],
                    },
                    {
                        "id": None,
                        "ordinal": 1,
                        "name": "Secondary press",
                        "description": None,
                        "goal": None,
                        "role": "SECONDARY_PROGRESSIVE",
                        "volume_axis": None,
                        "target_muscle_slugs": [target_muscle],
                        "variants": [
                            {
                                "id": None,
                                "ordinal": 0,
                                "variant_type": "DEFAULT",
                                "exercise_slug": second_exercise,
                                "sets": [
                                    {
                                        "id": None,
                                        "ordinal": 0,
                                        "reps": {"min": 8, "max": 12},
                                        "rir": 2,
                                        "min_volume_level": 0,
                                    }
                                ],
                            }
                        ],
                    },
                ],
            },
        },
        {
            "id": None,
            "ordinal": 1,
            "weekday": 2,
            "name": "Rest",
            "description": None,
            "workout_unit": None,
        },
    ]
    return payload


def collect_ids(draft: dict[str, Any]) -> dict[str, list[int]]:
    ids: dict[str, list[int]] = {
        "plans.day_prescriptions": [],
        "plans.workout_unit_prescriptions": [],
        "plans.exercise_slots": [],
        "plans.exercise_variants": [],
        "plans.set_infra_prescriptions": [],
    }
    for day in draft["days"]:
        ids["plans.day_prescriptions"].append(day["id"])
        unit = day["workout_unit"]
        if unit is None:
            continue
        ids["plans.workout_unit_prescriptions"].append(unit["id"])
        for slot in unit["exercise_slots"]:
            ids["plans.exercise_slots"].append(slot["id"])
            for variant in slot["variants"]:
                ids["plans.exercise_variants"].append(variant["id"])
                ids["plans.set_infra_prescriptions"].extend(
                    item["id"] for item in variant["sets"]
                )
    return ids


def assert_rows_were_cascaded(ids: dict[str, list[int]]) -> None:
    with psycopg.connect(Settings().database_dsn) as connection:
        for table, row_ids in ids.items():
            if not row_ids:
                continue
            with connection.cursor() as cursor:
                cursor.execute(f"SELECT COUNT(*) FROM {table} WHERE id = ANY(%s)", (row_ids,))
                assert cursor.fetchone() == (0,), f"Rows remained in {table}"


def main() -> None:
    created_plan_ids: list[int] = []
    default_exercise = find_catalog_slug(
        "exercises", "barbell_bench_press", "barbell_bench_press"
    )
    fallback_exercise = find_catalog_slug(
        "exercises", "barbell_california_press", "barbell_california_press"
    )
    target_muscle = find_catalog_slug(
        "muscles", "pectoralis_major_sternal", "pectoralis"
    )

    try:
        created = expect(
            "POST",
            "/api/plans",
            201,
            {"name": "Codex PlanCreator validation", "description": None},
        )
        plan_id = created["id"]
        created_plan_ids.append(plan_id)
        assert created["revision_no"] == 1
        assert created["lock_version"] == 1
        assert created["days"] == []

        populated = populated_payload(
            created,
            default_exercise=default_exercise,
            second_exercise=fallback_exercise,
            target_muscle=target_muscle,
        )
        saved = expect("PUT", f"/api/plans/{plan_id}/draft", 200, populated)
        assert saved["lock_version"] == 2
        assert expect("GET", f"/api/plans/{plan_id}/draft", 200) == saved

        first_set_id = saved["days"][0]["workout_unit"]["exercise_slots"][0][
            "variants"
        ][0]["sets"][0]["id"]
        edited = copy.deepcopy(saved)
        edited["days"][0]["workout_unit"]["exercise_slots"][0]["variants"][0][
            "sets"
        ][0]["reps"] = {"min": 6, "max": 8}
        edited = expect("PUT", f"/api/plans/{plan_id}/draft", 200, edited)
        assert edited["lock_version"] == 3
        assert (
            edited["days"][0]["workout_unit"]["exercise_slots"][0]["variants"][0][
                "sets"
            ][0]["id"]
            == first_set_id
        )

        reordered = copy.deepcopy(edited)
        slots = reordered["days"][0]["workout_unit"]["exercise_slots"]
        slot_ids_before = {slot["id"] for slot in slots}
        slots.reverse()
        for ordinal, slot in enumerate(slots):
            slot["ordinal"] = ordinal
        reordered = expect("PUT", f"/api/plans/{plan_id}/draft", 200, reordered)
        slots = reordered["days"][0]["workout_unit"]["exercise_slots"]
        assert {slot["id"] for slot in slots} == slot_ids_before
        assert [slot["ordinal"] for slot in slots] == [0, 1]

        primary_slot = next(slot for slot in slots if slot["name"] == "Primary chest press")
        retained_set_id = primary_slot["variants"][0]["sets"][0]["id"]
        removed_set_id = primary_slot["variants"][0]["sets"][1]["id"]
        deleting = copy.deepcopy(reordered)
        primary_slot_input = next(
            slot
            for slot in deleting["days"][0]["workout_unit"]["exercise_slots"]
            if slot["name"] == "Primary chest press"
        )
        primary_slot_input["variants"][0]["sets"] = primary_slot_input["variants"][0][
            "sets"
        ][:1]
        deleting = expect("PUT", f"/api/plans/{plan_id}/draft", 200, deleting)
        primary_slot = next(
            slot
            for slot in deleting["days"][0]["workout_unit"]["exercise_slots"]
            if slot["name"] == "Primary chest press"
        )
        assert [item["id"] for item in primary_slot["variants"][0]["sets"]] == [
            retained_set_id
        ]
        assert removed_set_id != retained_set_id

        with_fallback = copy.deepcopy(deleting)
        primary_slot_input = next(
            slot
            for slot in with_fallback["days"][0]["workout_unit"]["exercise_slots"]
            if slot["name"] == "Primary chest press"
        )
        primary_slot_input["variants"].append(
            {
                "id": None,
                "ordinal": 1,
                "variant_type": "FALLBACK",
                "exercise_slug": fallback_exercise,
                "sets": [],
            }
        )
        with_fallback = expect("PUT", f"/api/plans/{plan_id}/draft", 200, with_fallback)
        assert with_fallback["lock_version"] == deleting["lock_version"] + 1

        invalid_slug = copy.deepcopy(with_fallback)
        invalid_slug["days"][0]["workout_unit"]["exercise_slots"][0]["variants"][0][
            "exercise_slug"
        ] = "exercise_that_does_not_exist"
        expect("PUT", f"/api/plans/{plan_id}/draft", 422, invalid_slug)
        assert expect("GET", f"/api/plans/{plan_id}/draft", 200)["lock_version"] == with_fallback[
            "lock_version"
        ]

        duplicate_default = copy.deepcopy(with_fallback)
        primary_slot_input = next(
            slot
            for slot in duplicate_default["days"][0]["workout_unit"]["exercise_slots"]
            if slot["name"] == "Primary chest press"
        )
        primary_slot_input["variants"][1]["variant_type"] = "DEFAULT"
        expect("PUT", f"/api/plans/{plan_id}/draft", 422, duplicate_default)

        expect("PUT", f"/api/plans/{plan_id}/draft", 409, deleting)

        other = expect(
            "POST",
            "/api/plans",
            201,
            {"name": "Codex PlanCreator foreign-id validation", "description": None},
        )
        other_id = other["id"]
        created_plan_ids.append(other_id)
        other_payload = copy.deepcopy(other)
        other_payload["days"] = [
            {
                "id": None,
                "ordinal": 0,
                "weekday": None,
                "name": "Foreign day",
                "description": None,
                "workout_unit": None,
            }
        ]
        other = expect("PUT", f"/api/plans/{other_id}/draft", 200, other_payload)
        injection = copy.deepcopy(with_fallback)
        injection["days"][0]["id"] = other["days"][0]["id"]
        expect("PUT", f"/api/plans/{plan_id}/draft", 422, injection)

        persisted_ids = collect_ids(with_fallback)
        expect("DELETE", f"/api/plans/{plan_id}", 204)
        created_plan_ids.remove(plan_id)
        expect("GET", f"/api/plans/{plan_id}", 404)
        assert_rows_were_cascaded(persisted_ids)
        print("PlanCreator live scenarios passed: 12/12")
    finally:
        for cleanup_id in created_plan_ids:
            request("DELETE", f"/api/plans/{cleanup_id}")


if __name__ == "__main__":
    main()

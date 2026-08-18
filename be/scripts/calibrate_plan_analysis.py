"""Read-only calibration report for the global Plan Analysis V1 velocities."""

from dataclasses import dataclass
from statistics import median

import psycopg

from agonez_api.core.config import Settings
from agonez_api.modules.plans.analysis.parameters import (
    JOINT_RECOVERY_VELOCITY_V1,
    MUSCLE_RECOVERY_VELOCITY_V1,
    RIR_RECOVERY_MULTIPLIER,
    cumulative_set_multiplier,
)


@dataclass(frozen=True)
class Band:
    name: str
    rirs: tuple[int, ...]
    target_hours: float
    target_range: str


@dataclass(frozen=True)
class MuscleAnchor:
    muscle_class: str
    exercise_slug: str
    muscle_slug: str


@dataclass(frozen=True)
class CalibrationRow:
    label: str
    band: str
    sets: int
    raw_cost: float
    normalized_cost: float
    target_hours: float
    candidate_velocity: float


BANDS = (
    Band("light", (2, 2, 2), 30.0, "24-36"),
    Band("standard", (2, 2, 1, 1, 2), 48.0, "36-54"),
    Band("high", (1, 1, 0, 1, 0, 1), 66.0, "60-72"),
)

MUSCLE_ANCHORS = (
    MuscleAnchor("chest", "barbell_bench_press", "pectoralis_major_sternal"),
    MuscleAnchor("back", "chest_supported_dumbbell_row", "latissimus_dorsi"),
    MuscleAnchor("quadriceps", "selectorized_leg_extension", "vastus_lateralis"),
    MuscleAnchor("arm", "standing_barbell_curl", "biceps_brachii"),
)


def session_cost(base_value: float, rirs: tuple[int, ...]) -> float:
    return sum(
        (5 - rir)
        * base_value
        * RIR_RECOVERY_MULTIPLIER[rir]
        * cumulative_set_multiplier(prior_count)
        for prior_count, rir in enumerate(rirs)
    )


def main() -> None:
    settings = Settings()
    muscle_rows: list[CalibrationRow] = []
    joint_rows: list[CalibrationRow] = []
    with psycopg.connect(settings.database_dsn, autocommit=True) as connection:
        with connection.cursor() as cursor:
            for anchor in MUSCLE_ANCHORS:
                cursor.execute(
                    """
                    SELECT
                        (engine.active_tension_exposure_vector ->> %s)::float8,
                        (engine.muscle_recovery_cost_modifier_vector ->> %s)::float8,
                        muscle.pcsa_projected_fcsa_cm2::float8
                    FROM engine.exercises AS engine
                    JOIN core.muscles AS muscle ON muscle.slug = %s
                    WHERE engine.slug = %s
                    """,
                    (
                        anchor.muscle_slug,
                        anchor.muscle_slug,
                        anchor.muscle_slug,
                        anchor.exercise_slug,
                    ),
                )
                row = cursor.fetchone()
                if row is None or any(value is None for value in row):
                    raise RuntimeError(f"Incomplete muscle anchor: {anchor}")
                active_tension, recovery_modifier, fcsa = map(float, row)
                for band in BANDS:
                    raw_mru = session_cost(
                        active_tension * recovery_modifier,
                        band.rirs,
                    )
                    density = raw_mru / fcsa
                    muscle_rows.append(
                        CalibrationRow(
                            label=(
                                f"{anchor.muscle_class}: {anchor.exercise_slug} / "
                                f"{anchor.muscle_slug}"
                            ),
                            band=band.name,
                            sets=len(band.rirs),
                            raw_cost=raw_mru,
                            normalized_cost=density,
                            target_hours=band.target_hours,
                            candidate_velocity=density / band.target_hours,
                        )
                    )

            cursor.execute(
                """
                SELECT (joint_load_exposure_vector ->> 'glenohumeral_joint')::float8
                FROM engine.exercises
                WHERE slug = 'barbell_bench_press'
                """
            )
            joint_row = cursor.fetchone()
            if joint_row is None or joint_row[0] is None:
                raise RuntimeError("Incomplete joint anchor: barbell bench press shoulder")
            joint_load = float(joint_row[0])
            for band in BANDS:
                raw_jru = session_cost(joint_load, band.rirs)
                joint_rows.append(
                    CalibrationRow(
                        label="barbell_bench_press / glenohumeral_joint",
                        band=band.name,
                        sets=len(band.rirs),
                        raw_cost=raw_jru,
                        normalized_cost=raw_jru,
                        target_hours=band.target_hours,
                        candidate_velocity=raw_jru / band.target_hours,
                    )
                )

    fitted_muscle_velocity = median(row.candidate_velocity for row in muscle_rows)
    fitted_joint_velocity = median(row.candidate_velocity for row in joint_rows)
    _print_report(
        "Muscle anchors",
        muscle_rows,
        fitted_muscle_velocity,
        MUSCLE_RECOVERY_VELOCITY_V1,
        "MRU/FCSA",
    )
    _print_report(
        "Joint anchors",
        joint_rows,
        fitted_joint_velocity,
        JOINT_RECOVERY_VELOCITY_V1,
        "JRU",
    )


def _print_report(
    title: str,
    rows: list[CalibrationRow],
    fitted_velocity: float,
    frozen_velocity: float,
    normalized_label: str,
) -> None:
    print(f"\n## {title}\n")
    print(
        f"Median fitted velocity: {fitted_velocity:.12f}; "
        f"frozen V1 velocity: {frozen_velocity:.12f}\n"
    )
    print(
        f"| Anchor | Band | Sets | Raw cost | {normalized_label} | Target h | "
        "Candidate velocity | Predicted h |"
    )
    print("|---|---:|---:|---:|---:|---:|---:|---:|")
    for row in rows:
        print(
            f"| {row.label} | {row.band} | {row.sets} | {row.raw_cost:.6f} | "
            f"{row.normalized_cost:.6f} | {row.target_hours:.1f} | "
            f"{row.candidate_velocity:.9f} | "
            f"{row.normalized_cost / frozen_velocity:.3f} |"
        )


if __name__ == "__main__":
    main()

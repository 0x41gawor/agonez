from typing import Final

MODEL_VERSION: Final = "plan-analysis-v1"
MICROCYCLE_HOURS: Final = 168.0

EFFECTIVE_REPS_BY_RIR: Final[dict[int, float]] = {
    0: 5.0,
    1: 4.0,
    2: 3.0,
    3: 2.0,
    4: 1.0,
}

RIR_RECOVERY_MULTIPLIER: Final[dict[int, float]] = {
    0: 1.15,
    1: 1.05,
    2: 1.00,
    3: 1.00,
    4: 1.00,
}

CUMULATIVE_SET_PENALTY_STEP: Final = 0.05
CUMULATIVE_SET_PENALTY_CAP: Final = 1.30
MEANINGFUL_CONTRIBUTION_EPSILON: Final = 1e-9
RECOVERY_CONVERGENCE_EPSILON_HOURS: Final = 1e-6
RECOVERY_MAX_CYCLES: Final = 256

# Calibrated from the real engine catalog by scripts/calibrate_plan_analysis.py.
# These are inspectable Agonez V1 engineering parameters, not physiological constants.
MUSCLE_RECOVERY_VELOCITY_V1: Final = 0.289425511
JOINT_RECOVERY_VELOCITY_V1: Final = 0.312


def cumulative_set_multiplier(prior_contributing_set_count: int) -> float:
    return min(
        1.0 + CUMULATIVE_SET_PENALTY_STEP * prior_contributing_set_count,
        CUMULATIVE_SET_PENALTY_CAP,
    )

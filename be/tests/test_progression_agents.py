from decimal import Decimal

from agonez_api.modules.execution.progression import (
    DEFAULT_AGENT,
    PerformedSet,
    PlannedSet,
    ProgressionRequest,
    RepeatLastExposureAgent,
    ResolvedLoad,
    agent_for,
    register_agent,
    resolve_loads,
)


def planned(count: int, role: str = "working") -> tuple[PlannedSet, ...]:
    return tuple(
        PlannedSet(ordinal=index, role=role, rep_min=5, rep_max=7, target_rir="RIR1")
        for index in range(count)
    )


def performed(*loads: str | None, role: str | None = "working") -> tuple[PerformedSet, ...]:
    return tuple(
        PerformedSet(
            ordinal=index,
            role=role,
            load_kg=None if value is None else Decimal(value),
            repetitions=7,
            rir=1,
        )
        for index, value in enumerate(loads)
    )


def test_each_set_inherits_the_load_of_the_same_set_last_time() -> None:
    resolved = resolve_loads(
        ProgressionRequest(
            progression_model_slug=None,
            planned_sets=planned(3),
            last_exposure=performed("60.0", "62.5", "65.0"),
        )
    )

    assert [item.load_kg for item in resolved] == [
        Decimal("60.0"),
        Decimal("62.5"),
        Decimal("65.0"),
    ]
    assert {item.source for item in resolved} == {"last_exposure"}


def test_extra_planned_sets_repeat_the_last_performed_set() -> None:
    resolved = resolve_loads(
        ProgressionRequest(
            progression_model_slug=None,
            planned_sets=planned(4),
            last_exposure=performed("60.0", "62.5"),
        )
    )

    assert [item.load_kg for item in resolved] == [Decimal("60.0")] + [Decimal("62.5")] * 3


def test_a_first_exposure_leaves_every_load_empty() -> None:
    resolved = resolve_loads(
        ProgressionRequest(
            progression_model_slug=None,
            planned_sets=planned(2),
            last_exposure=(),
        )
    )

    assert [item.load_kg for item in resolved] == [None, None]
    assert [item.source for item in resolved] == [None, None]


def test_sets_without_a_usable_load_never_carry_forward() -> None:
    """The repository filters by status; a set with no load is ignored here too."""
    resolved = resolve_loads(
        ProgressionRequest(
            progression_model_slug=None,
            planned_sets=planned(2),
            last_exposure=performed(None, "70.0"),
        )
    )

    assert [item.load_kg for item in resolved] == [Decimal("70.0"), Decimal("70.0")]


def test_loads_are_never_carried_across_a_set_role_boundary() -> None:
    plan = (
        PlannedSet(ordinal=0, role="rampup", rep_min=5, rep_max=5, target_rir="RIR4"),
        PlannedSet(ordinal=1, role="working", rep_min=5, rep_max=7, target_rir="RIR1"),
        PlannedSet(ordinal=2, role="working", rep_min=5, rep_max=7, target_rir="RIR1"),
    )
    exposure = (
        PerformedSet(ordinal=0, role="working", load_kg=Decimal("80"), repetitions=6, rir=1),
        PerformedSet(ordinal=1, role="working", load_kg=Decimal("80"), repetitions=5, rir=0),
    )

    resolved = resolve_loads(
        ProgressionRequest(
            progression_model_slug=None, planned_sets=plan, last_exposure=exposure
        )
    )

    assert [item.load_kg for item in resolved] == [None, Decimal("80"), Decimal("80")]
    assert [item.source for item in resolved] == [None, "last_exposure", "last_exposure"]


def test_unplanned_sets_without_a_role_are_ignored() -> None:
    exposure = (
        PerformedSet(ordinal=0, role=None, load_kg=Decimal("99"), repetitions=3, rir=0),
        PerformedSet(ordinal=1, role="working", load_kg=Decimal("55"), repetitions=8, rir=2),
    )

    resolved = resolve_loads(
        ProgressionRequest(
            progression_model_slug=None, planned_sets=planned(1), last_exposure=exposure
        )
    )

    assert [item.load_kg for item in resolved] == [Decimal("55")]


def test_the_default_agent_never_progresses_or_rounds_to_the_load_step() -> None:
    resolved = resolve_loads(
        ProgressionRequest(
            progression_model_slug="double_progression",
            planned_sets=planned(1),
            last_exposure=performed("62.5"),
            load_step_kg=Decimal("2.5"),
        )
    )

    assert resolved[0].load_kg == Decimal("62.5")


def test_every_progression_model_falls_back_to_the_repeat_agent_today() -> None:
    assert agent_for(None) is DEFAULT_AGENT
    assert agent_for("double_progression") is DEFAULT_AGENT
    assert isinstance(DEFAULT_AGENT, RepeatLastExposureAgent)


def test_a_model_aware_agent_takes_over_its_own_progression_model() -> None:
    class DoubleEverything:
        slug = "test_double"

        def resolve(self, request: ProgressionRequest) -> tuple[ResolvedLoad, ...]:
            return tuple(
                ResolvedLoad(item.ordinal, Decimal("100"), self.slug)
                for item in request.planned_sets
            )

    register_agent("test_double", DoubleEverything())
    try:
        resolved = resolve_loads(
            ProgressionRequest(
                progression_model_slug="test_double",
                planned_sets=planned(2),
                last_exposure=performed("60"),
            )
        )
        assert [item.load_kg for item in resolved] == [Decimal("100"), Decimal("100")]
        assert [item.source for item in resolved] == ["test_double", "test_double"]
        assert agent_for("single_progression") is DEFAULT_AGENT
    finally:
        from agonez_api.modules.execution.progression import _AGENTS

        _AGENTS.pop("test_double", None)

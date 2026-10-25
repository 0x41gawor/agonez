"""Progression agents: an automated coach the athlete can delegate progression to.

A *progression agent* makes the decision a coach makes when reviewing the last session:
given the plan's prescribed sets for an exercise and what the athlete actually performed,
what should each set weigh next time? Agonez already models *how* that decision should be
made — every exercise variant carries a ``progression_model_slug``. Until now that model
was documentation a human followed by hand in Post-Workout-Analysis; an agent executes it,
so the athlete can hand progression management over instead of steering it themselves.

Today the capability is deployed at one narrow point: plan-backed fallback preparation,
when the athlete starts a session whose analysis is incomplete. That is a workaround for a
real problem, not the purpose. Coaching after every finalized workout, model-aware agents,
and delegation as an explicit per-exercise choice are the destination; this contract is
shaped to reach it without changing.

Only :class:`RepeatLastExposureAgent` is registered so far. It is the default for every
progression model and repeats the last exposure's loads without progressing them. Future
model-aware agents (double progression, single progression, 2-for-2, …) register for their
own ``progression_model_slug``, which is why every agent already receives the performed
repetitions and RIR such a decision needs.

Agents are pure functions of their input: no database access, no clock, no randomness.
That keeps a decision explainable after the fact, keeps agents unit-testable, and lets the
preview and the write path share one answer.

See ``__docs__/execution/progression-agents.md`` for the capability, the contract, and the
rules that must not be broken.
"""

from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal
from typing import Protocol

REPEAT_LAST_EXPOSURE = "last_exposure"


@dataclass(frozen=True)
class PlannedSet:
    """A set as the plan prescribes it, before any load is decided."""

    ordinal: int
    role: str
    rep_min: int
    rep_max: int
    target_rir: str


@dataclass(frozen=True)
class PerformedSet:
    """A set as the athlete actually performed it at the last exposure."""

    ordinal: int
    role: str | None
    load_kg: Decimal | None
    repetitions: int | None
    rir: int | None

    @property
    def usable(self) -> bool:
        """Whether this set can carry a load forward.

        Only sets that were really performed with an explicit load qualify; skipped and
        not-performed sets never do. The repository filters by status, so a set that
        reaches an agent with a load was performed.
        """
        return self.load_kg is not None


@dataclass(frozen=True)
class ProgressionRequest:
    """Everything an agent may use to decide the loads of one exercise."""

    progression_model_slug: str | None
    planned_sets: tuple[PlannedSet, ...]
    last_exposure: tuple[PerformedSet, ...]
    load_step_kg: Decimal | None = None


@dataclass(frozen=True)
class ResolvedLoad:
    """One decided load and where it came from."""

    ordinal: int
    load_kg: Decimal | None
    source: str | None


class ProgressionAgent(Protocol):
    """Decides the loads of one exercise's prescribed sets."""

    slug: str

    def resolve(self, request: ProgressionRequest) -> tuple[ResolvedLoad, ...]: ...


class RepeatLastExposureAgent:
    """Repeat what was lifted last time. The default for every progression model.

    Matching is role-aware so a ramp-up never inherits a working-set load:

    1. Usable sets of the last exposure are grouped by the role they were prescribed
       under. Sets the athlete added outside the plan have no role and are ignored here.
    2. A planned set is the *k*-th set of its role; it takes the load of the *k*-th
       usable set of that same role.
    3. If that role has fewer usable sets, it takes the load of the last usable set of
       that role — a plan that grew from three working sets to four repeats the third.
    4. If that role has no usable set at all, the load stays ``None``. Loads are never
       carried across a role boundary, and ``None`` is the honest answer for a first
       exposure or a role the athlete skipped entirely.

    The agent never progresses, rounds, or applies ``load_step_kg``: it repeats what was
    actually lifted. Deciding to add weight is a model-aware agent's job.
    """

    slug = REPEAT_LAST_EXPOSURE

    def resolve(self, request: ProgressionRequest) -> tuple[ResolvedLoad, ...]:
        by_role: dict[str, list[PerformedSet]] = {}
        for performed in sorted(request.last_exposure, key=lambda item: item.ordinal):
            if performed.role is None or not performed.usable:
                continue
            by_role.setdefault(performed.role, []).append(performed)

        seen_per_role: dict[str, int] = {}
        resolved: list[ResolvedLoad] = []
        for planned in sorted(request.planned_sets, key=lambda item: item.ordinal):
            index = seen_per_role.get(planned.role, 0)
            seen_per_role[planned.role] = index + 1
            candidates = by_role.get(planned.role, [])
            if not candidates:
                resolved.append(ResolvedLoad(planned.ordinal, None, None))
                continue
            match = candidates[min(index, len(candidates) - 1)]
            resolved.append(ResolvedLoad(planned.ordinal, match.load_kg, self.slug))
        return tuple(resolved)


DEFAULT_AGENT: ProgressionAgent = RepeatLastExposureAgent()

#: Model-aware agents, keyed by ``progression_model_slug``. Empty today on purpose: a
#: future double-progression agent registers here and is picked up by ``agent_for``
#: without any change to the callers.
_AGENTS: dict[str, ProgressionAgent] = {}


def register_agent(progression_model_slug: str, agent: ProgressionAgent) -> None:
    """Register a model-aware agent, replacing any agent for the same model."""
    _AGENTS[progression_model_slug] = agent


def agent_for(progression_model_slug: str | None) -> ProgressionAgent:
    """Return the agent that decides loads for this progression model.

    Falls back to :data:`DEFAULT_AGENT` for an unset model and for any model that has no
    agent of its own yet, so an exercise always gets an answer.
    """
    if progression_model_slug is None:
        return DEFAULT_AGENT
    return _AGENTS.get(progression_model_slug, DEFAULT_AGENT)


def resolve_loads(request: ProgressionRequest) -> tuple[ResolvedLoad, ...]:
    """Decide the loads of one exercise through its registered progression agent."""
    return agent_for(request.progression_model_slug).resolve(request)

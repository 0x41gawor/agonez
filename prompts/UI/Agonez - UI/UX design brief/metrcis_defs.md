# Agonez Metric Definitions

These definitions describe the semantics of the biomechanical vectors used by the UI.

They are **model-derived analytical quantities**, not directly measured physiological signals such as EMG.

## ETU — Effective Training Units

`etu_vector`

ETU represents the modeled **training-stimulus exposure assigned to each muscle by an exercise**.

The vector has one scalar value per muscle:

```text
etu_vector[muscle] -> training stimulus exposure
```

A larger ETU value means that the exercise is modeled as providing a larger effective hypertrophic / training stimulus to that muscle.

ETU incorporates more than simple muscle participation. It is intended to represent **effective training stimulus**, accounting for the modeled mechanical demand and the conditions under which that demand is produced.

Important:

* ETU is **not EMG activation**
* ETU is **not a percentage of muscle activation**
* ETU is **not simply exercise load distributed between muscles**
* ETU values may be compared across muscles only with appropriate normalization

For anatomical heatmaps, normalize each muscle against its modeled force-producing capacity:

```text
normalized_etu[m] =
    etu_vector[m]
    / muscle[m].pcsa_projected_fcsa_cm2
```

The UI should therefore communicate **relative training exposure of the muscle**, rather than making anatomically larger muscles appear dominant simply because they can produce more force.

---

## Active Tension Exposure

`active_tension_exposure_vector`

Active Tension Exposure represents the modeled **cumulative active contractile demand imposed on each muscle by an exercise**.

Conceptually:

```text
active_tension_exposure_vector[muscle]
    -> amount of active muscular tension exposure
```

It is primarily a **mechanical exposure quantity**.

Unlike ETU, it should not be interpreted directly as training stimulus. A muscle can experience substantial active tension without that exposure necessarily translating one-to-one into hypertrophic stimulus.

For recovery analysis, Active Tension Exposure is modified by the muscle-specific recovery-cost model:

```text
recovery_exposure[m] =
    active_tension_exposure_vector[m]
    * muscle_recovery_cost_modifier[m]
```

This produces the muscle-side **recovery burden** used by the UI.

For anatomical visualization:

```text
normalized_recovery_exposure[m] =
    recovery_exposure[m]
    / muscle[m].pcsa_projected_fcsa_cm2
```

The resulting heatmap should be interpreted as:

> How large is the modeled recovery burden relative to the force-producing capacity of this muscle?

It is **not** a prediction of exact recovery time.

---

## Joint Load Exposure

`joint_load_exposure_vector`

Joint Load Exposure represents the modeled **relative mechanical exposure of each joint or joint complex during an exercise**.

The vector has one scalar value per modeled joint:

```text
joint_load_exposure_vector[joint]
    -> relative joint loading exposure
```

It is intended primarily for:

* comparing exercises
* identifying which joints are meaningfully exposed
* distinguishing exercises that may have similar muscular targets but different joint-loading profiles

Important:

* Joint Load Exposure is **not joint reaction force in Newtons**
* it is **not pressure in Pa**
* it is **not a direct injury-risk probability**
* it should not be presented as a medical safety score

It is a model-derived exposure index.

Joint values should use a visualization grammar separate from muscle heatmaps, for example:

* joint nodes
* rings
* halos
* localized markers

This allows muscle recovery exposure and joint exposure to be inspected simultaneously without implying that they are the same physical quantity.

---

## Visualization semantics

The three quantities answer different questions:

```text
ETU
→ Where does the modeled effective training stimulus go?

Active Tension Exposure × Recovery Cost Modifier
→ Which muscles incur the largest modeled recovery burden?

Joint Load Exposure
→ Which joints receive the largest modeled mechanical exposure?
```

Recommended visual distinction:

```text
ETU                  → green / emerald sequential heatmap
Recovery Exposure    → red / coral sequential heatmap
Joint Load Exposure  → amber / violet joint markers or halos
```

Use continuous intensity scales with a clear legend.

Values close to zero should visually recede into the neutral anatomical SVG.

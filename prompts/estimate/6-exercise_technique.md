You are provisioning the `technique` field for an exercise in the Agonez resistance-training exercise database.

Your task is to generate a precise, biomechanically coherent, exercise-specific technique document.

The output must describe **how this exact exercise variant should be performed**, not how to program it and not how effective it is.

---

# Input

You will receive at minimum:

- `slug`
- `name`
- `name_full`
- `resistance_source`
- `active_tension_exposure_vector`

You may also receive additional exercise metadata or biomechanical data. Use it when relevant, but do not repeat database fields unnecessarily inside `technique`.

---

# General principles

The technique description must:

1. Describe the **specific exercise variant named in the input**, not the generic exercise family.
2. Be biomechanically plausible and internally consistent.
3. Distinguish:
   - required technical constraints,
   - acceptable individual variation,
   - actual technical failure.
4. Prefer concrete anatomical and mechanical descriptions over vague fitness language.
5. Avoid unnecessary coaching clichés.
6. Avoid prescribing training volume, frequency, load, rep ranges, RPE, or rest periods.
7. Do not evaluate the exercise as "good", "bad", "optimal", "advanced", etc.
8. Do not duplicate ETU, muscle-allocation, recruitment-budget, joint-load, or other Agonez model outputs.
9. Do not invent arbitrary precision where no meaningful precision exists.
10. When a parameter legitimately varies between lifters, state the acceptable range or principle under `individualization` rather than pretending there is one universally correct setup.

If the name does not explicitly explain the variant use the `active_tension_exposure_vector` to choose the variant. It evaluates the muscle usage in exercise. Each value is expressed in muscle fcsa. The maximum of muscles fcsa values are presented below. Hence you can check "how much" of the muscle is used during the exercise.

When the variant was not expressed explicitly in the name in your opinion, describe which variant you choose. Provide this in the overview section.

slug                       |pcsa_projected_fcsa_cm2|
---------------------------+-----------------------+
gluteus_maximus            |                 143.08|
gluteus_medius             |                 113.75|
triceps_lateral_head       |                  36.10|
rotator_cuffs              |                 170.80|
adductor_longus_brevis     |                  66.55|
adductor_magnus            |                 105.22|
iliopsoas                  |                 102.23|
gluteus_minimus            |                  24.82|
soleus                     |                 217.92|
tibialis_anterior          |                  41.70|
deltoid_lateral            |                  45.73|
gastrocnemius              |                 183.54|
deltoid_posterior          |                  24.65|
biceps_femoris_long_head   |                  53.70|
transverse_abdominis       |                  21.97|
obliques                   |                  81.71|
trapezius_lower            |                  14.98|
triceps_medial_head        |                  15.59|
trapezius_middle           |                  26.18|
sternocleidomastoid        |                  13.83|
rectus_abdominis           |                  24.29|
serratus_anterior          |                  36.03|
rhomboids                  |                  28.25|
deep_neck_extensors        |                  84.88|
pronators_supinators       |                  60.88|
wrist_extensors            |                  53.67|
wrist_flexors              |                  54.40|
latissimus_dorsi           |                  43.85|
sartorius                  |                  10.22|
teres_major                |                   4.50|
biceps_femoris_short_head  |                  23.91|
semitendinosus             |                  25.59|
erector_spinae             |                 106.48|
rectus_femoris             |                  91.44|
vastus_intermedius         |                  70.35|
brachialis                 |                  44.05|
triceps_long_head          |                  43.55|
vastus_medialis            |                 117.38|
vastus_lateralis           |                 243.17|
biceps_brachii             |                  39.81|
deltoid_anterior           |                  30.46|
pectoralis_major_clavicular|                  13.52|
pectoralis_major_sternal   |                  53.48|
pectoralis_minor           |                  10.81|
semimembranosus            |                  88.78|
brachioradialis            |                  11.22|
trapezius_upper            |                  19.36|

---

# Output format

Return **exactly one executable PostgreSQL `UPDATE` statement and nothing else**.

The statement must update the `technique` field in `core.exercises` for the exercise identified by its `slug`.

Use this exact pattern:

```sql
UPDATE core.exercises
SET technique = $technique$
{
  "tldr": {
    "setup": "",
    "execution": "",
    "focus": "",
    "stop_when": ""
  },

  "overview": "",

  "plane_of_movement": "",
  "primary_joint_actions": "",

  "equipment_setup": "",
  "starting_position": "",
  "grip": "",
  "stance": "",
  "bracing": "",

  "concentric": "",
  "eccentric": "",
  "end_position": "",
  "range_of_motion": "",
  "tempo_notes": "",

  "internal_cues": "",
  "external_cues": "",

  "technical_failure": "",
  "rir_1_indicators": "",
  "rir_0_definition": "",

  "common_mistakes": [],
  "safety_notes": [],
  "individualization": ""
}
$technique$::jsonb
WHERE slug = '<INPUT_SLUG>';
```

Requirements:

- Replace `<INPUT_SLUG>` with the exact input `slug`.
- Do not modify any other column.
- Do not use `id`, `name`, or approximate matching in the `WHERE` clause.
- Preserve the exact JSON schema shown above.
- Do not add or remove JSON keys.
- The JSON must be valid JSON.
- Use JSON strings, arrays, and objects only; do not use PostgreSQL-specific syntax inside the JSON.
- Use `""` for an irrelevant optional text field.
- Use `[]` for an irrelevant optional array field.
- Never use `null`.
- Escape any characters required for valid JSON.
- Use the PostgreSQL dollar-quoted delimiter `$technique$` exactly as shown.
- Do not wrap the SQL in Markdown fences in the final response.
- Do not add explanations, comments, headings, or notes before or after the SQL statement.

---

# SQL safety and consistency

Before returning the statement, internally verify that:

1. The `WHERE` clause contains the exact supplied `slug`.
2. Only the `technique` column is modified.
3. The generated value casts successfully to `jsonb`.
4. All required JSON keys are present exactly once.
5. No extra JSON keys are present.
6. The TL;DR is consistent with the detailed technique.
7. Concentric and eccentric descriptions are mechanically compatible.
8. ROM agrees with starting and end positions.
9. Technical failure corresponds to the prescribed exercise technique.
10. Common mistakes do not contradict legitimate individualization.
11. No programming recommendations have been added.
12. No ETU, recruitment-budget, muscle-allocation, joint-load, or other Agonez model outputs are duplicated.

---

# Final response constraint

Your entire response must consist of one PostgreSQL statement beginning with:

`UPDATE core.exercises`

and ending with:

`WHERE slug = '<exact input slug>';`

Return no other text.

# 1. TL;DR

This section is intended to be read quickly during a workout.

It must contain only the highest-value execution information.

Each value should normally be **one short sentence**.

## `tldr.setup`

State the most important setup constraint.

Examples of the kind of information expected:

- body orientation,
- bench angle,
- pulley position,
- grip orientation,
- stance,
- key scapular or torso position.

Do not attempt to summarize the entire setup.

## `tldr.execution`

Describe the essential movement pattern in one concise instruction.

Focus on:

- what moves,
- in what direction,
- what should remain stable.

## `tldr.focus`

Give the single most useful cue or technical focus for maintaining the intended exercise mechanics.

Do not use vague statements such as:

- "maintain proper form",
- "feel the muscle",
- "control the movement".

## `tldr.stop_when`

State the clearest exercise-specific sign that the set has reached technical failure.

This should answer:

> What breakdown tells the lifter that another repetition would no longer represent this exercise correctly?

---

# 2. Overview

## `overview`

Give a concise description of the exercise and the defining characteristics of this exact variant. 

Include only information helpful for understanding the movement.

Usually 2–4 sentences.

Where relevant, distinguish the exercise from nearby variants.

Example distinctions:

- incline vs flat press,
- neutral-grip vs pronated pull-up,
- Bayesian curl vs conventional cable curl,
- forward-lean dip vs upright dip.

Do not discuss programming or exercise ranking.

---

# 3. Movement classification

## `plane_of_movement`

Describe the actual movement plane or combination of planes.

Do not force the exercise into an oversimplified single-plane classification when the movement is clearly hybrid.

Prefer descriptions such as:

> Primarily transverse-plane shoulder horizontal adduction with a smaller sagittal-plane component.

Avoid creating artificial taxonomy labels such as:

> sagittal_frontal_hybrid

unless such a label is explicitly provided by the input schema.

---

## `primary_joint_actions`

Describe the main joint actions occurring during the concentric phase.

Use anatomical terminology where appropriate.

Relevant structures may include:

- glenohumeral joint,
- scapulothoracic articulation,
- elbow,
- radioulnar joints,
- wrist,
- spine,
- hip,
- knee,
- ankle.

Distinguish actual joint motion from stabilization.

Example:

> Glenohumeral horizontal adduction with a minor flexion component; elbow extension; scapulae transition from controlled retraction toward mild protraction.

Do not quantify joint load here.

---

# 4. Setup

## `equipment_setup`

Describe only equipment configuration that materially changes execution.

Examples:

- bench angle,
- pulley height,
- cable attachment,
- pad height,
- seat height,
- safety position,
- machine alignment.

Use an empty string when no meaningful equipment setup exists.

Do not invent exact centimeter values unless genuinely justified.

---

## `starting_position`

Describe the lifter's body position immediately before starting the repetition.

Include relevant:

- torso orientation,
- pelvic position,
- scapular position,
- shoulder position,
- elbow position,
- limb alignment,
- contact points.

Do not duplicate equipment configuration unnecessarily.

---

## `grip`

Describe grip width and orientation when relevant.

Possible details include:

- pronated,
- supinated,
- neutral,
- semi-pronated,
- grip width,
- wrist alignment.

Explain functional positioning rather than relying only on labels.

Use an empty string if grip is irrelevant.

---

## `stance`

Describe foot, knee, kneeling, seated, or support position when it materially affects the exercise.

Examples:

- shoulder-width stance,
- staggered stance,
- split stance,
- half-kneeling,
- seated with both feet planted.

Use an empty string when irrelevant.

---

## `bracing`

Describe the stabilization strategy necessary to preserve the intended movement.

May include:

- abdominal bracing,
- ribcage-pelvis alignment,
- spinal neutrality,
- glute contraction,
- scapular control,
- avoidance of torso rotation.

Do not simply write "brace your core".

---

# 5. Execution

## `concentric`

Describe the lifting or shortening phase.

Include:

- intended direction of movement,
- relevant joint motion,
- trajectory of the implement,
- segments that should remain relatively stable.

The description must be specific enough that a technically competent lifter could reproduce the intended variant.

---

## `eccentric`

Describe the lowering or return phase.

State:

- how the load returns,
- what positions should remain controlled,
- whether the trajectory should mirror or intentionally differ from the concentric phase.

Do not prescribe excessively slow eccentrics unless this is inherently required by the exercise.

---

## `end_position`

Describe the intended terminal position of the concentric phase.

Explain what defines completion of the repetition.

Use an empty string if the end position is obvious and adds no useful information.

---

## `range_of_motion`

Define the intended usable ROM.

Describe ROM using anatomical or positional landmarks where possible.

Where appropriate, distinguish:

- full available ROM,
- exercise-defined ROM,
- ROM limited by equipment geometry,
- ROM limited by inability to maintain the intended mechanics.

Do not encourage forced ROM through pain or joint instability.

---

## `tempo_notes`

Include only tempo characteristics that are technically meaningful.

Examples:

- avoid bouncing,
- do not use stretch reflex intentionally,
- brief controlled pause may be useful,
- maintain continuous cable tension.

Do not prescribe arbitrary tempos such as `3-1-2-0` unless explicitly required by the exercise definition.

Use an empty string if no special tempo consideration exists.

---

# 6. Coaching cues

## `internal_cues`

Provide 1–3 concise cues focused on body movement or muscular action.

Examples:

- bring the upper arm toward the torso,
- keep the ribcage stacked over the pelvis,
- rotate through the shoulder rather than the trunk.

Avoid pseudoscientific cues or claiming that a lifter can completely isolate a muscle through thought alone.

Return the cues as a single concise string.

---

## `external_cues`

Provide 1–3 concise cues focused on the intended effect on the environment or implement.

Examples:

- drive the handles together,
- push the floor away,
- pull the elbow toward the hip,
- move the bar toward the upper chest.

Use an empty string if no useful external cue adds value.

---

# 7. Technical failure and RIR

The failure definitions must be based on **exercise-specific technical constraints**, not merely whether the load can still move.

## `technical_failure`

Define the point at which another repetition would materially change the mechanics of the intended exercise.

Identify observable breakdowns such as:

- torso momentum,
- excessive spinal movement,
- altered joint path,
- loss of prescribed ROM,
- major grip or elbow-position change,
- compensatory shrugging,
- rotation,
- bouncing,
- assistance from unintended body segments.

Be specific to the exercise.

---

## `rir_1_indicators`

Describe observable signs consistent with approximately one technically valid repetition remaining.

Usually include:

- substantial repetition-velocity reduction,
- increasing effort,
- minor but still acceptable technical drift,
- preservation of full intended ROM.

Do not claim that RIR 1 can be identified with perfect certainty.

Phrase this probabilistically where necessary.

---

## `rir_0_definition`

Define RIR 0 as failure to complete another repetition **within the technical standard defined for this exercise**.

Distinguish this from absolute inability to move the resistance by any compensatory strategy.

---

# 8. Common mistakes

## `common_mistakes`

Return an array of concrete, exercise-specific mistakes.

Usually provide 3–6 items.

Good examples:

- `"Excessive lumbar extension during the press."`
- `"Allowing the shoulder to shrug upward as the arm approaches shoulder height."`
- `"Using torso rotation to finish the final portion of the repetition."`

Bad examples:

- `"Bad form."`
- `"Using too much weight."`
- `"Not controlling the movement."`

Only include load selection when it directly causes a recognizable technical failure pattern.

---

# 9. Safety

## `safety_notes`

Return only exercise-specific safety information.

Examples:

- safe use of Smith-machine stops,
- avoiding forced shoulder extension,
- keeping the cervical spine neutral under load,
- avoiding uncontrolled knee collapse,
- ensuring cable attachments are securely positioned.

Do not add generic medical disclaimers.

Use an empty array if no meaningful exercise-specific safety note is required.

---

# 10. Individualization

## `individualization`

Describe parameters that may legitimately differ between lifters without changing the identity of the exercise.

Relevant factors may include:

- limb proportions,
- shoulder structure,
- hip anatomy,
- mobility,
- grip width,
- stance width,
- bench angle,
- foot placement,
- ROM tolerance.

Clearly distinguish individualization from technical errors.

Example:

> Grip width may vary moderately with humeral length and shoulder comfort, provided the forearms remain approximately vertical in the bottom position and the intended pressing path is preserved.

Use an empty string if no meaningful individualization is required.

---

# Quality requirements

Before returning the JSON, internally verify that:

- the TL;DR agrees with the detailed description;
- concentric and eccentric descriptions are mechanically compatible;
- ROM agrees with starting and end positions;
- the failure definition corresponds to the prescribed technique;
- common mistakes do not contradict individualization;
- cues do not introduce mechanics absent from the main description;
- no section describes a different exercise variant;
- no programming recommendations have been introduced.

---

# Style

Write in precise professional English.

Prefer:

- anatomical terminology,
- observable body positions,
- implement trajectories,
- explicit mechanical constraints.

Avoid:

- motivational language,
- bodybuilding folklore,
- generic filler,
- overconfident claims,
- unnecessary adjectives.

The output is intended for a structured exercise atlas and should read like a concise technical coaching specification rather than a fitness article.
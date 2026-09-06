# Steps

- core.exercises record creation

# core.exercises record creation

> those values can't be null so add all of them at once

```sql
INSERT INTO core.exercises (
    slug,
    name,
    name_full,
    resistance_source,
    body_part,
    target_category,
    mechanics_tier
)
VALUES
    -- CORE
    ('selectorized_abdominal_crunch',
     'Seated Abdominal Crunch',
     'Selectorized Seated Abdominal Crunch',
     'Selectorized_Machine',
     'Core',
     'Core',
     'Isolation'),
...
```

# engine.exercises record creation 

```sql
INSERT INTO engine.exercises (slug)
VALUES
    ('supine_straight_leg_raise'),
    ('bent_knee_dragon_flag'),
    ('straight_leg_dragon_flag');
```


# systemic-propulsive-fcsa-demand

## Prompt

## Input row

```
slug | name_full | resistance_source | load_capacity_kg
```

e.g.

```
single_arm_dumbbell_preacher_curl | Single-Arm Dumbbell Preacher Curl | Dumbbell | 28.00
```

# active-tension-exposure-vector and etu-vector

```sql
SELECT 
    c.slug,
    c.name_full,
    c.resistance_source,
    e.load_capacity_kg,
    e.systemic_propulsive_fcsa_demand,
    e.propulsive_fcsa_contribution_vector
FROM core.exercises c
INNER JOIN engine.exercises e 
    ON c.slug = e.slug
WHERE e.active_tension_exposure_vector IS NULL;
```

# 4 joint recovery exposure vector

```sql
SELECT
    c.slug,
    c.name_full,
    e.load_capacity_kg 
FROM core.exercises AS c 
LEFT JOIN engine.exercises AS e ON c.slug = e.slug
WHERE e.joint_load_exposure_vector  IS NULL 
   OR e.joint_load_exposure_vector  = '{}'::jsonb;
```

# 5 muscle recovery exposure vector

```sql

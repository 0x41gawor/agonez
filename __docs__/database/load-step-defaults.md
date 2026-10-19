# Default load steps by resistance source

Migration `0011_resistance_source_load_defaults.sql` adds the catalog-owned
`core.resistance_source_load_defaults` table. It contains one row for every value of
`core.resistance_source_enum` and supplies the initial `load_step_kg` for exercises in
that resistance family.

## Seed mapping

| Resistance source | Default step | Product rationale |
| --- | ---: | --- |
| `Bodyweight` | 2.50 kg | Conservative increment for externally added or assisted load |
| `Barbell` | 2.50 kg | Common bilateral increase using 1.25 kg per side |
| `Dumbbell` | 2.00 kg | Common per-dumbbell rack increment |
| `Kettlebell` | 4.00 kg | Common fixed-bell progression |
| `Cable` | 2.50 kg | Conservative cable-stack or add-on increment |
| `Selectorized_Machine` | 5.00 kg | Common metric stack increment |
| `Plate_Loaded_Machine` | 2.50 kg | Conservative total-load increment; machine setup may require an override |
| `Smith_Machine` | 2.50 kg | Barbell-style bilateral increase |
| `Resistance_Band` | 2.50 kg | Fallback when band resistance is recorded as an equivalent external load |
| `Suspension` | 2.50 kg | Fallback when an external-load equivalent is recorded |
| `Partner_Resistance` | 2.50 kg | Fallback when resistance is recorded in kilograms |
| `Other` | 2.50 kg | Neutral fallback for uncategorized equipment |

These are authoring defaults, not claims about every machine. Plate-loaded lever ratios,
available change plates, selectorized stack spacing, dumbbell racks, and how a coach records
bodyweight or elastic resistance all vary. For context, commercially available change plates
span 0.5–5 kg, while selectorized equipment commonly exposes 2.5–5 kg incremental options:

- [Rogue KG Change Plates](https://www.roguefitness.com/rogue-kg-change-plates)
- [Life Fitness Insignia stack options](https://support.lifefitness.com/hc/en-us/articles/4421250882327-Life-Fitness-Insignia-Strength-Customization-Options)
- [Technogym Personal Line specifications](https://www.technogym.com/land/wp-content/uploads/2018/02/PERSONAL_LINE_UK.pdf)

## Resolution and persistence

Atlas list, detail, and PlanCreator catalog responses expose
`default_load_step_kg`, resolved by joining the exercise's `resistance_source` to the mapping.
When a PlanCreator exercise is selected, this value initializes the exercise variant's
editable `load_step_kg`. A coach can replace it with the exact increment available in their
gym.

Execution resolves the effective step as:

1. `plans.exercise_variants.load_step_kg`, when explicitly stored;
2. the resistance-source default otherwise.

The effective value is copied to
`exec.exercise_unit_prescriptions.load_step_kg_snapshot` so historical prescriptions do not
change when catalog defaults are revised. Migration `0011` also fills existing null plan
values and execution snapshots from the mapping. The mobile prescription API reads that
snapshot (with the same catalog fallback for legacy rows) rather than using a hard-coded
increment.

To change a product default for newly authored or still-inheriting variants:

```sql
UPDATE core.resistance_source_load_defaults
SET default_load_step_kg = 5.00
WHERE resistance_source = 'Plate_Loaded_Machine';
```

Existing variants that already contain an explicit value remain unchanged by that update.

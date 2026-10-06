# Agonez Module

One of the:
- Atlas
- Plans
- Exec

Atlas data model is in the `core` and `engine` schemas. Plans in the `plans`

# Agonez-Atlas

One of the agonez-modules.

It stands as a database for the rest of the app.

# Agonez-Plans

One of the agonez-modules.

Here, the user can create the workout plans. The basic object of this module is a microcycle.

# Plan-Creator

A person (actor/role) that uses the "My plans" module the create a plan. In the real life it is propably the trainer that creates a plans for its clients. Or it can be a more advanced lifter that wants to verify or come up with its onw plan.

# Plan (Workout-Plan)

A workout plan modelled in Agonez. The time unit, time contraints modeled is a microcycle. The smallest repeatable unit. It can be a week or any other number of days. The days can have a weekdays mapping or not.

Plan has some metadata and a list of days. Day can have a **workout-unit** or be a rest day. 

# plan.revision

Actually, in the implementation. Each plan has a revision as a bridge between plan identity and the actual days with workout-units. 

Revision is a mechanism for a single plan to have multiple volume or target-muscles versions. Also this is the mechanism for a plan to change its content on the time axis (during the exec.plan_run or in general as an artifact).

# Day

Day modelled in a Workout-Plan. It can containt one or zero workout-units. A non workout day is called a rest-day.

# Prescription

This is to emphasize/distinguish that what athelete has prescribed to perform and what he performs are actually a two different things.

# plan.workout-unit

In real life, workout-unit is a single appearance on the gym. An ordered list of exercises that user performs. 

# plan.exercise-slot

Actually workout-unit contains an exercise-slot, instead of the bare exercises. Slot can express its goal and purpose and have multiple **exercises variants**. Ordered of course. In the 99% of cases only the first exercises would be used. 

# plan.exercise_variant

A single position in a list of exercises available to fullfill given exercise-slot. 

The variants are good when some machine/equipment is blocked or non-available in a new gym etc..

# plan.exercise-unit

This more like a conceptual/time/structural view, not the implem one. Exercise-unit is whithin the workout-unit and contains a list of sets with specific exercise defined.

# plan.set_infra_prescr

A set is a number of repetitions of a single exercise. It is a common gym term. One exercise-unit contains a list of sets.

Hence the plan knows nothing about the athelte, that will execute the plan, this is called infra_prescription.

It carries the "infrastructure" that later will be resolved in to the actual set_prescription.
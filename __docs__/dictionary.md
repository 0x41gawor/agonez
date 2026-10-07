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

# Plan (Workout-Plan, plan.plan)

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

# exec.plan_run

This is when the athlete "takes" one of the plans and introduces it into his life for a given period of time (usually several weeks e.g 8-20). 

In this case Agonez helps as:
- an exercise cheetshett/notebook (mobile app),
- a progress monitor/tracker (desktop app),
- a performance analysis tool (desktop app),
- motivation tool to actually lock-in,
- deload/reload/volume management tool.

Since the plan.plan answers "what is the training program, the exec.plan_run is a concrete attempt at following that plan"


The typical plan_run attributes:
- name, identity, user_id,
- a concrete starting plan.plan_revision (later modifications, create separate 'intra-plan_run' revision history)
- starting date
- number of microcycles / number of weeks (hence the ending_date)
- status (scheduled, active, cancelled, completed)

> The plan-run can't be paused. Athlete has to lock-in. Agonez enforces discipline. The pause will be reflected as a missed workout-units.

# exec.microcycle

The smallest repeatable unit of a plan.plan is a microcycle, so in the case of exec.plan_run we can measure the time progress of a plan_run with the current microcycle number. 

Mirocycle usually lasts a week. 

> Agonez has to assure elasticity here. All of the time-blocks have to be normalized either for weeks or microcycle with the possibility to switch between them in the UI.

When talking about a plan_run, we can ask user in which week he actually is.


# exec.workout-unit-prescr

This is the copy of the plan.workout-unit, BUT it contains the load information.

Since the exec.plan_run is coupled with a concrete athlete, the load can be "resolved" at this stage.

The prescription can be treated as a set of instructions written down on a sheet of paper for the athlete. These instructions need to cointain load information. Of course this load is a funtion of the previous load.

Additionaly each exercise-unit or even set can have a prescription comment.

# Performance, exposition and stimulus

In more scientific language the whole problem revolves around measuring the **performnace** of an athelete through a series of **expositions** for a derived **stimulus**. 

A following workout-unit is the next exposition, that can be given as an input for the engine. The engine has to check how athlete performed during this exposition and come up with a proper stimulus prescription for the next exposition.

# Post-Workout-Analysis

This is the term for an analysis that athlete/trainer does after the full microcycle of the training. He reads the performance data, reasons based on it, and finally comes up with a prescriptions for the next expositions.

# Comments

Exercise-unit has such lifecycle.
- plan.plan
- exec.prescr
- exec.performed

And on each stage a comment for exercise-unit can be issued. 
- plan - here the comment can be issuead as a "descpription", it provides specific information that goes beyond the exercise itself and rather places it in this concrete workout-plan. This can be some cues on what to focus etc.. e.g "Technique, place the feet a bit forward, which puts the more egagement on the quads (rather than glutes)", such comment can be result of the programme design, this exercise role is to deliver quad stimulus, and the glute stimulus will be delivered in some other exercise-unit
- prescr - this comment should be based on the **Post-Workout-Analysis** activity, the lifetime of a such comment is only "for the next workout-unit". This something practical e.g. "use both cables on the machine" or "remember to keep the elbow straight", "we will try the 70kg, check if the technique is ok"
- performed - this comment is entetered by the athlete during ther workout-unit. This is are the "field-data", a huge input for the Post-Workout-Analysis. It can be e.g. "I don't feel the proper tehcnique here" - a signal to lower down the load next time. E.g. "I've used two cables on the machine" - a cue how to preserve the repeatability of the exercise.

Exercise-Unit Comments can have two levels of "scope":
- global - pertaining the exercise-unit at all
- per-set - pertaining the one specific set (mostly used durig "performance")


# exec.workout-unit-under-performance

This is the moment when athlete enters the gym, runs the mobile app and performs the workout-unit. 

It propably won't be reflected with a different data-model in the system, but this is a keystone moment to be distinguished.

Athlete's mobile app is fed with the exec.workout-unit-prescr, and the athelete records the performance via:
- information about prescr/actual-performance deivergencies (other exercise-variant used, other load used etc, skipped/additional sets)
- performance information: the actual number of reps performed, the actual perceived RIR
- comments (both exercise-unit level and set level)

Or maybe this can be reflected in the system as an unfinished exec.workout-session-performed. It would be good to sync mobile app with the backend in the case of the user closes the app during workout.

# exec.workout-unit-performed

When athlete finishes the workout an artifact of performance should be sent to server. This is the data-model for it.

Basically it contains the copy of what was prescribed and the "actual" or "performed" field beside.

This field monitors the actual:
- load,
- rir,
- comment
for each set.


# exec.workout-session

Workout-unit is a straight stimulus model. Session is a wrapper for unit, that places it on the time axis. A session can be scheduled, cancelled, skipped, replaced with other session or performed (as planned). It occured at a specific dat and time etc...

# exec.plan_run_event

During a plan_run several event types can happen:
- ahtelete changed/added/deleted the exercise or modified sets from the plan (in other words, athlete modified the plan)
  - this can happen due to observation of field-data. e.g. recovery is bad or recovery is ok, so we can add volume, or the machine is missing on this gym etc..
  - yes, this creates a new plan revision
- athlete set a new personal record on some exercise
- athlete started a deload/reload week
- athelete is gone for a vacation/training-break
- athelete just wants to log out some comment/observation

# exec.plan_run_event_log

A timestamped series of plan_run_events.

# Repeatable unit

A repeatable unit is a thing that is a subject of repetition. The biggest repeatable unit is a microcycle. Second is the workout-unit, and the last is the exercise-unit.

Repeatable units are a subject to time analysis that can deliver answer if the progress is made or not. 

Each repetable unit has to be comparable. Has to have the same structure and a defined set of variables (e.g. load in exercise-unit).


# trace/history

In the Agonez context, this is the history or a trace of a repeatable unit. Each unit trace characterizes with the different set of attributes.

- Microcycle trace - its attributes evalueate the overall performance of the microcycle/week, what is the athlete attendace, what was the volume and some marker (called MARKER.X) that multiplies in some intelligent way a volume and a load
- Workout-unit trace - its attributes evalueate the performance of a specific workout-unit on the timeline, e.g. Monday-Push. MARKER.X would be the best characteristic here.
- exercise-unit trace - this is the most ground-based. Atrributes are simply performed loads, reps and sets.

# MARKER.X (name to be defined)

This is the marker/KPI (Performance Indicator, makes sense :D) that answers the question.

"Am I doing the progress or not?".

The progress in the gym can be measured only with the one metric.

"Under the same tranining program (number of sets, rep range, RIR intensity), am I able to perform exercises under more resistance over the course of weeks or not?".


--
-- PostgreSQL database dump
--

-- Dumped from database version 15.13 (Debian 15.13-1.pgdg120+1)
-- Dumped by pg_dump version 15.13 (Debian 15.13-1.pgdg120+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: core; Type: SCHEMA; Schema: -; Owner: kartezjusz
--

CREATE SCHEMA core;


ALTER SCHEMA core OWNER TO kartezjusz;

--
-- Name: engine; Type: SCHEMA; Schema: -; Owner: kartezjusz
--

CREATE SCHEMA engine;


ALTER SCHEMA engine OWNER TO kartezjusz;

--
-- Name: anatomical_reference_enum; Type: TYPE; Schema: core; Owner: kartezjusz
--

CREATE TYPE core.anatomical_reference_enum AS ENUM (
    'Bilateral',
    'Unilateral'
);


ALTER TYPE core.anatomical_reference_enum OWNER TO kartezjusz;

--
-- Name: body_part_enum; Type: TYPE; Schema: core; Owner: kartezjusz
--

CREATE TYPE core.body_part_enum AS ENUM (
    'Upper',
    'Lower',
    'Core',
    'Full'
);


ALTER TYPE core.body_part_enum OWNER TO kartezjusz;

--
-- Name: execution_pattern_enum; Type: TYPE; Schema: core; Owner: kartezjusz
--

CREATE TYPE core.execution_pattern_enum AS ENUM (
    'Bilateral',
    'Unilateral',
    'Alternating'
);


ALTER TYPE core.execution_pattern_enum OWNER TO kartezjusz;

--
-- Name: leverage_peak_enum; Type: TYPE; Schema: core; Owner: kartezjusz
--

CREATE TYPE core.leverage_peak_enum AS ENUM (
    'Lengthened_Range',
    'Mid_Range',
    'Shortened_Range',
    'Flat_Profile'
);


ALTER TYPE core.leverage_peak_enum OWNER TO kartezjusz;

--
-- Name: mechanics_tier_enum; Type: TYPE; Schema: core; Owner: kartezjusz
--

CREATE TYPE core.mechanics_tier_enum AS ENUM (
    'Heavy_Compound',
    'Secondary_Compound',
    'Isolation',
    'Stability_Isometric'
);


ALTER TYPE core.mechanics_tier_enum OWNER TO kartezjusz;

--
-- Name: muscle_architecture_enum; Type: TYPE; Schema: core; Owner: kartezjusz
--

CREATE TYPE core.muscle_architecture_enum AS ENUM (
    'Converged/Fan-shaped',
    'Flat/Convergent',
    'Multipenate',
    'Fusiform/Parallel-like',
    'Convergent/Pennate',
    'Parallel',
    'Parallel/Pennate',
    'Parallel/Fusiform',
    'Fusiform',
    'Pennate',
    'Fusiform/Pennate',
    'Fusiform/Quadrilateral',
    'Undefined',
    'Paralell-Convergent',
    'Parallel-Convergent',
    'Parallel/Convergent',
    'Parallel/Long-Fusiform',
    'Fusiform-Convergenttable ',
    'Fusiform-Convergent',
    'Fusiform/Convergent',
    'Fusiform/Parallel',
    'Serrated/Fan-shaped',
    'Parallel/Polygastric',
    'Broad Flat/Parallelc',
    'Broad Flat/Parallel',
    'Broad Tranverse',
    'Broad Transverse',
    'Coarse Multipennate',
    'Fan-shaped/Radiate',
    'Bipennate',
    'Unipennate/Multipennate',
    'Pennate/BI-directional',
    'Pennate/Bi-directional',
    'Fusiform/Unipennate',
    'Unipennate',
    'Fusiform/Long-table fibered',
    'Fusiform/Long-fibered',
    'Semi-membranous/Unipennate',
    'Multipennate/Triangular',
    'Fan-shaped/Triangular',
    'Strap/Parallel',
    'Pennate/Bipennate',
    'Multipennate',
    'Circumpennate/Fusiform'
);


ALTER TYPE core.muscle_architecture_enum OWNER TO kartezjusz;

--
-- Name: muscle_complex_enum; Type: TYPE; Schema: core; Owner: kartezjusz
--

CREATE TYPE core.muscle_complex_enum AS ENUM (
    'Neck',
    'Shoulder',
    'Chest',
    'Back',
    'Biceps',
    'Triceps',
    'Forearms',
    'Core',
    'Glutes',
    'Quads',
    'Hamstrings',
    'Hip_FA',
    'Calves',
    'Shin'
);


ALTER TYPE core.muscle_complex_enum OWNER TO kartezjusz;

--
-- Name: resistance_profile_enum; Type: TYPE; Schema: core; Owner: kartezjusz
--

CREATE TYPE core.resistance_profile_enum AS ENUM (
    'Lengthened-biased',
    'Mid-range-biased',
    'Shortened-biased'
);


ALTER TYPE core.resistance_profile_enum OWNER TO kartezjusz;

--
-- Name: resistance_source_enum; Type: TYPE; Schema: core; Owner: kartezjusz
--

CREATE TYPE core.resistance_source_enum AS ENUM (
    'Bodyweight',
    'Barbell',
    'Dumbbell',
    'Kettlebell',
    'Cable',
    'Selectorized_Machine',
    'Plate_Loaded_Machine',
    'Smith_Machine',
    'Resistance_Band',
    'Suspension',
    'Partner_Resistance',
    'Other'
);


ALTER TYPE core.resistance_source_enum OWNER TO kartezjusz;

--
-- Name: smh_factor_enum; Type: TYPE; Schema: core; Owner: kartezjusz
--

CREATE TYPE core.smh_factor_enum AS ENUM (
    'zero',
    'very_low',
    'low',
    'medium',
    'high',
    'very_high',
    'extreme_high'
);


ALTER TYPE core.smh_factor_enum OWNER TO kartezjusz;

--
-- Name: strength_curve_enum; Type: TYPE; Schema: core; Owner: kartezjusz
--

CREATE TYPE core.strength_curve_enum AS ENUM (
    'Ascending',
    'Descending',
    'Bell-shaped'
);


ALTER TYPE core.strength_curve_enum OWNER TO kartezjusz;

--
-- Name: target_category_enum; Type: TYPE; Schema: core; Owner: kartezjusz
--

CREATE TYPE core.target_category_enum AS ENUM (
    'Chest_Clav_AD',
    'Chest_Sternal',
    'Back_V',
    'Upper_Traps',
    'Serratus',
    'Back_3D',
    'Lateral_Delt',
    'Biceps',
    'Triceps',
    'Core',
    'Quads',
    'Glutes',
    'Hip_AF',
    'Hamstrings',
    'Lower_P',
    'Calves',
    'Tibialis',
    'Global_P',
    'Anterior_Delt',
    'Forearms',
    'Neck'
);


ALTER TYPE core.target_category_enum OWNER TO kartezjusz;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: exercises; Type: TABLE; Schema: core; Owner: kartezjusz
--

CREATE TABLE core.exercises (
    id integer NOT NULL,
    slug character varying(100) NOT NULL,
    name character varying(255) NOT NULL,
    name_full character varying(255) NOT NULL,
    body_part core.body_part_enum NOT NULL,
    target_category core.target_category_enum NOT NULL,
    mechanics_tier core.mechanics_tier_enum NOT NULL,
    resistance_source core.resistance_source_enum NOT NULL,
    load_capacity numeric(5,2) NOT NULL,
    systemic_propulsive_fcsa_demand numeric(6,2) NOT NULL,
    propulsive_fcsa_contribution_vector jsonb NOT NULL,
    technique jsonb NOT NULL,
    comments jsonb NOT NULL,
    video_links text[] DEFAULT '{}'::text[] NOT NULL,
    execution_pattern core.execution_pattern_enum DEFAULT 'Bilateral'::core.execution_pattern_enum NOT NULL,
    systemic_propulsvie_fcsa_eval_note jsonb,
    CONSTRAINT exercises_load_capacity_check CHECK ((load_capacity >= (0)::numeric))
);


ALTER TABLE core.exercises OWNER TO kartezjusz;

--
-- Name: exercises_id_seq; Type: SEQUENCE; Schema: core; Owner: kartezjusz
--

CREATE SEQUENCE core.exercises_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE core.exercises_id_seq OWNER TO kartezjusz;

--
-- Name: exercises_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: kartezjusz
--

ALTER SEQUENCE core.exercises_id_seq OWNED BY core.exercises.id;


--
-- Name: muscle_exercise_mappings; Type: TABLE; Schema: core; Owner: kartezjusz
--

CREATE TABLE core.muscle_exercise_mappings (
    muscle_id integer NOT NULL,
    exercise_id integer NOT NULL,
    complexity core.mechanics_tier_enum NOT NULL,
    resistance_profile core.resistance_profile_enum NOT NULL
);


ALTER TABLE core.muscle_exercise_mappings OWNER TO kartezjusz;

--
-- Name: muscles; Type: TABLE; Schema: core; Owner: kartezjusz
--

CREATE TABLE core.muscles (
    id integer NOT NULL,
    slug character varying(100) NOT NULL,
    name character varying(100) NOT NULL,
    body_part core.body_part_enum NOT NULL,
    complex core.muscle_complex_enum NOT NULL,
    mass_g numeric(8,2) NOT NULL,
    mv_cm3 numeric(8,2) NOT NULL,
    pcsa numeric(6,2) NOT NULL,
    architecture core.muscle_architecture_enum NOT NULL,
    fiber_bias_type_i numeric(4,3) NOT NULL,
    fiber_bias_type_ii numeric(4,3) NOT NULL,
    smh_factor core.smh_factor_enum NOT NULL,
    strength_curve core.strength_curve_enum DEFAULT 'Bell-shaped'::core.strength_curve_enum NOT NULL,
    leverage_peak core.leverage_peak_enum DEFAULT 'Mid_Range'::core.leverage_peak_enum NOT NULL,
    bible_markdown text DEFAULT ''::text NOT NULL,
    article_links text[] DEFAULT '{}'::text[] NOT NULL,
    video_links text[] DEFAULT '{}'::text[] NOT NULL,
    mass_reference core.anatomical_reference_enum DEFAULT 'Bilateral'::core.anatomical_reference_enum NOT NULL,
    optimal_fiber_length_cm numeric(5,2),
    pennation_angle_deg numeric(5,2),
    pennation_cos numeric(4,3),
    pcsa_fiber_cm2 numeric(5,2),
    pcsa_projected_fcsa_cm2 numeric(5,2),
    CONSTRAINT check_fiber_sum_100 CHECK ((abs(((fiber_bias_type_i + fiber_bias_type_ii) - 1.0)) < 0.001)),
    CONSTRAINT muscles_fiber_bias_type_i_check CHECK (((fiber_bias_type_i >= (0)::numeric) AND (fiber_bias_type_i <= 1.0))),
    CONSTRAINT muscles_fiber_bias_type_ii_check CHECK (((fiber_bias_type_ii >= (0)::numeric) AND (fiber_bias_type_ii <= 1.0))),
    CONSTRAINT muscles_mass_g_check CHECK ((mass_g > (0)::numeric)),
    CONSTRAINT muscles_mv_cm3_check CHECK ((mv_cm3 > (0)::numeric)),
    CONSTRAINT muscles_pcsa_check CHECK ((pcsa > (0)::numeric))
);


ALTER TABLE core.muscles OWNER TO kartezjusz;

--
-- Name: muscles_id_seq; Type: SEQUENCE; Schema: core; Owner: kartezjusz
--

CREATE SEQUENCE core.muscles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE core.muscles_id_seq OWNER TO kartezjusz;

--
-- Name: muscles_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: kartezjusz
--

ALTER SEQUENCE core.muscles_id_seq OWNED BY core.muscles.id;


--
-- Name: exercises; Type: TABLE; Schema: engine; Owner: kartezjusz
--

CREATE TABLE engine.exercises (
    slug character varying NOT NULL,
    load_capacity numeric(5,2),
    systemic_propulsive_fcsa_demand numeric(6,2),
    propulsive_fcsa_contribution_vector jsonb,
    active_tension_exposure_vector jsonb,
    active_tension_exposure_vector_eval_notes jsonb,
    etu_vector jsonb,
    etu_vector_eval_notes jsonb,
    muscle_recovery_cost_modifier_vector jsonb,
    muscle_recovery_cost_modifier_vector_eval_notes jsonb,
    joint_load_exposure_vector jsonb,
    joint_load_exposure_vector_eval_notes jsonb,
    CONSTRAINT engine_exercises_propulsive_fcsa_nonnegative CHECK (((systemic_propulsive_fcsa_demand IS NULL) OR (systemic_propulsive_fcsa_demand >= (0)::numeric))),
    CONSTRAINT engine_exercises_vectors_are_objects CHECK ((((propulsive_fcsa_contribution_vector IS NULL) OR (jsonb_typeof(propulsive_fcsa_contribution_vector) = 'object'::text)) AND ((active_tension_exposure_vector IS NULL) OR (jsonb_typeof(active_tension_exposure_vector) = 'object'::text)) AND ((active_tension_exposure_vector_eval_notes IS NULL) OR (jsonb_typeof(active_tension_exposure_vector_eval_notes) = 'object'::text)) AND ((etu_vector IS NULL) OR (jsonb_typeof(etu_vector) = 'object'::text)) AND ((etu_vector_eval_notes IS NULL) OR (jsonb_typeof(etu_vector_eval_notes) = 'object'::text))))
);


ALTER TABLE engine.exercises OWNER TO kartezjusz;

--
-- Name: exercises id; Type: DEFAULT; Schema: core; Owner: kartezjusz
--

ALTER TABLE ONLY core.exercises ALTER COLUMN id SET DEFAULT nextval('core.exercises_id_seq'::regclass);


--
-- Name: muscles id; Type: DEFAULT; Schema: core; Owner: kartezjusz
--

ALTER TABLE ONLY core.muscles ALTER COLUMN id SET DEFAULT nextval('core.muscles_id_seq'::regclass);


--
-- Data for Name: exercises; Type: TABLE DATA; Schema: core; Owner: kartezjusz
--

COPY core.exercises (id, slug, name, name_full, body_part, target_category, mechanics_tier, resistance_source, load_capacity, systemic_propulsive_fcsa_demand, propulsive_fcsa_contribution_vector, technique, comments, video_links, execution_pattern, systemic_propulsvie_fcsa_eval_note) FROM stdin;
20	selectorized_leg_extension	Leg Extension	Selectorized Seated Leg Extension	Lower	Quads	Isolation	Selectorized_Machine	60.00	215.82	{"rectus_femoris": 23.67, "vastus_medialis": 51.25, "vastus_lateralis": 108.04, "vastus_intermedius": 32.86}	{}	{}	{}	Bilateral	{"slug": "selectorized_leg_extension", "notes": ["The 173.75 Nm bilateral external knee moment corresponds to approximately 215.82 cm2 of utilized quadriceps FCSA under a representative capacity-weighted internal moment arm near 0.032 m.", "The displayed stack load is not treated as direct pad force because selectorized machines commonly alter force through cable routing and cam geometry.", "Sartorius is excluded because its small and mechanically secondary knee-extension role does not meaningfully contribute to the required net moment.", "The estimate is sensitive to the machine cam profile, pad distance, cable ratio, seat position, and the knee angle at which peak resistance occurs."], "limiting_phase": "Late-to-mid concentric knee extension at approximately 35-45 degrees of knee flexion, where the machine cam maintains substantial resistance while quadriceps internal leverage is beginning to decline.", "reconciliation": "PASS", "vector_sum_cm2": 215.82, "muscle_evaluation": [{"E_LT": 0.9200, "E_MA": 0.8800, "E_ND": 0.5600, "E_LoA": 0.9800, "E_mech": 0.4443, "muscle": "vastus_lateralis", "rationale": "The largest available knee extensor provides the greatest share of the required moment, with favorable length and direct task alignment but only partial capacity utilization at this load.", "maximum_fcsa_cm2": 243.17, "fcsa_contribution_cm2": 108.04}, {"E_LT": 0.9000, "E_MA": 0.9000, "E_ND": 0.5500, "E_LoA": 0.9800, "E_mech": 0.4366, "muscle": "vastus_medialis", "rationale": "Produces direct knee-extension torque with favorable patellar leverage and a substantial but smaller force contribution than vastus lateralis.", "maximum_fcsa_cm2": 117.38, "fcsa_contribution_cm2": 51.25}, {"E_LT": 0.9300, "E_MA": 0.8900, "E_ND": 0.5700, "E_LoA": 0.9900, "E_mech": 0.4671, "muscle": "vastus_intermedius", "rationale": "A monoarticular knee extensor with strong action alignment and favorable force availability throughout the limiting range.", "maximum_fcsa_cm2": 70.35, "fcsa_contribution_cm2": 32.86}, {"E_LT": 0.7800, "E_MA": 0.8200, "E_ND": 0.4400, "E_LoA": 0.9200, "E_mech": 0.2589, "muscle": "rectus_femoris", "rationale": "Contributes directly to knee extension, but seated hip flexion shortens the muscle proximally and reduces its mechanically available force relative to the monoarticular vasti.", "maximum_fcsa_cm2": 91.44, "fcsa_contribution_cm2": 23.67}], "effective_resistance": {"assumptions": ["A representative bilateral selectorized leg-extension machine with an effective cable-and-cam force ratio of approximately 0.82 is assumed.", "The lower-leg pad acts approximately 0.36 m from the bilateral knee axes at the limiting phase.", "The backrest and thigh restraint minimize hip and trunk movement, leaving knee extension as the primary task.", "The knees do not reach forceful terminal lockout and the repetition is performed without momentum."], "loaded_joints": [{"joint": "knee_bilateral", "estimated_external_moment_nm": 173.75}], "nominal_load_kg": 60.00, "estimated_effective_force_n": 482.65}, "systemic_fcsa_demand_cm2": 215.82, "top_down_fcsa_target_cm2": 215.82}
38	side_facing_reverse_pec_deck	Side-Facing Reverse Pec Deck	Single-Arm Side-Facing Reverse Pec Deck Fly	Upper	Back_3D	Isolation	Selectorized_Machine	20.00	108.17	{"obliques": 12.34, "rhomboids": 16.53, "brachialis": 4.63, "rotator_cuffs": 14.71, "biceps_brachii": 3.42, "erector_spinae": 6.28, "trapezius_lower": 7.19, "trapezius_upper": 3.71, "trapezius_middle": 16.90, "deltoid_posterior": 17.66, "serratus_anterior": 2.27, "transverse_abdominis": 2.53}	{}	{}	{}	Unilateral	{"slug": "side_facing_reverse_pec_deck", "notes": ["The unilateral-asymmetric reading established for the Pallof press was applied again here, and this is now the second exercise where the bilateral convention would produce a wrong answer. Mirroring 40 kg as two 20 kg loads would cancel the 42 N-m rotational moment and delete 21.15 cm2 of trunk contribution, converting this into an ordinary reverse pec deck. The laterality flag proposed earlier is no longer a nice-to-have: two exercises in the library now depend on an interpretation that the stated convention does not sanction.", "The side-facing orientation is what distinguishes this from a standard chest-supported reverse fly, and the entire difference sits in the trunk. Obliques at 12.34 cm2, erector spinae at 6.28 and transverse abdominis at 2.53 total 21.15 cm2 of anti-rotation work that a forward-facing pad would absorb completely. The shoulder and scapular allocation is otherwise close to what a supported version would produce.", "Deltoid_posterior reaches E_mech 0.7038 with perfect E_LoA, its highest value in the library, edging past the wide seated cable row at 0.6885 and the face pull at 0.6541. All three are horizontal abduction movements and the ordering tracks how cleanly each isolates that action: this variant does so most directly, with no elbow flexion or vertical pulling component competing for the demand.", "Rotator_cuffs at 14.71 cm2 is the second-highest cuff contribution in the library after the face pull at 9.09 in absolute terms but higher on E_mech at 0.0861 against 0.0532. As in the face pull, infraspinatus and teres minor are genuine agonists here rather than stabilisers, since horizontal abduction and external rotation are both required. This is now the third exercise where the aggregate rotator_cuffs slug has forced a low E_LoA to represent a group where only half the muscles act in the task direction.", "Total demand of 108.17 cm2 sits close to the straight-arm pulldown at 105.31 and the low-to-high cable fly at 105.44, and the structural similarity is real: all three are near-straight-arm single-joint movements with long external moment arms and modest effective loads. The pattern noted at the straight-arm pulldown now holds across four exercises.", "Machine lever ratio at 0.80 is the least certain input and is inherited from the high-to-low pec deck assumption. If the actual machine runs closer to 1:1, total demand would rise to roughly 130 cm2. A per-manufacturer lever ratio field remains the single highest-value addition to the input schema.", "A standard forward-facing chest-supported reverse pec deck must not inherit these values. The chest pad absorbs the entire rotational moment, removing 21.15 cm2 and permitting a heavier load, which would raise the shoulder and scapular allocation proportionally.", "A seated bent-over dumbbell reverse fly must not inherit these values either. Gravity acting vertically on a hinged torso produces a different resistance curve than a machine cam, and the hinged position introduces a lumbar extension demand this seated variant does not have.", "A bilateral side-facing variant is mechanically incoherent and should not exist in the library: working both arms from a side-facing seat would require two stacks on opposite sides, which is simply the standard forward-facing exercise."], "limiting_phase": "Concentric mid-range: working arm swept back to roughly 30 degrees of horizontal abduction from the start, humerus at shoulder height, elbow held at a fixed ~160 degrees, where the machine lever arm and the anti-rotation demand on the trunk are simultaneously greatest.", "reconciliation": "PASS", "vector_sum_cm2": 108.17, "muscle_evaluation": [{"E_LT": 0.9200, "E_MA": 0.8500, "E_ND": 0.9000, "E_LoA": 1.0000, "E_mech": 0.7038, "muscle": "deltoid_posterior", "rationale": "Prime mover with perfect task alignment: horizontal abduction at shoulder height is its primary and near-exclusive function. Highest engagement it receives anywhere in the library, marginally above the wide seated cable row.", "maximum_fcsa_cm2": 24.65, "fcsa_contribution_cm2": 17.66}, {"E_LT": 0.9000, "E_MA": 0.8500, "E_ND": 0.9000, "E_LoA": 0.9375, "E_mech": 0.6455, "muscle": "trapezius_middle", "rationale": "Its pure horizontal retraction vector closely matches the 38 N-m scapulothoracic moment required as the arm sweeps back, making it a co-prime mover rather than an assistant.", "maximum_fcsa_cm2": 26.18, "fcsa_contribution_cm2": 16.90}, {"E_LT": 0.9000, "E_MA": 0.8500, "E_ND": 0.9000, "E_LoA": 0.8500, "E_mech": 0.5852, "muscle": "rhomboids", "rationale": "Major contributor to scapular retraction, with its downward-rotation component slightly reducing alignment relative to middle trapezius at this shoulder-height arm position.", "maximum_fcsa_cm2": 28.25, "fcsa_contribution_cm2": 16.53}, {"E_LT": 0.8500, "E_MA": 0.5500, "E_ND": 0.7000, "E_LoA": 0.2580, "E_mech": 0.0861, "muscle": "rotator_cuffs", "rationale": "Included as a genuine contributor rather than purely a stabiliser: infraspinatus and teres minor produce horizontal abduction and external rotation directly, both required here. Second-highest cuff engagement in the library after the face pull, and for the same mechanical reason.", "maximum_fcsa_cm2": 170.80, "fcsa_contribution_cm2": 14.71}, {"E_LT": 0.9000, "E_MA": 0.8000, "E_ND": 0.8000, "E_LoA": 0.2620, "E_mech": 0.1510, "muscle": "obliques", "rationale": "Included as mechanically necessary rather than postural: the side-facing position means the 42 N-m rotational moment must be actively resisted for the working arm to have a stable base. Without this the torso simply rotates toward the machine and no shoulder work occurs.", "maximum_fcsa_cm2": 81.71, "fcsa_contribution_cm2": 12.34}, {"E_LT": 0.9000, "E_MA": 0.8000, "E_ND": 0.8500, "E_LoA": 0.7840, "E_mech": 0.4798, "muscle": "trapezius_lower", "rationale": "Contributes retraction and resists scapular elevation during the sweep, though its depression vector is only partly aligned with the predominantly horizontal scapular motion.", "maximum_fcsa_cm2": 14.98, "fcsa_contribution_cm2": 7.19}, {"E_LT": 0.9000, "E_MA": 0.8500, "E_ND": 0.5000, "E_LoA": 0.1543, "E_mech": 0.0590, "muscle": "erector_spinae", "rationale": "Included as a load-transmitting element: its deep rotatores and multifidus components assist the anti-rotation demand, and the superficial fibres hold the upright unsupported torso against the pull.", "maximum_fcsa_cm2": 106.48, "fcsa_contribution_cm2": 6.28}, {"E_LT": 0.8500, "E_MA": 0.4500, "E_ND": 0.5500, "E_LoA": 0.5000, "E_mech": 0.1052, "muscle": "brachialis", "rationale": "Included as a load-transmitting stabiliser: the fixed near-straight elbow must be held isometrically for force to reach the humerus. Poor leverage at 160 degrees and the demand is small relative to the shoulder moment.", "maximum_fcsa_cm2": 44.05, "fcsa_contribution_cm2": 4.63}, {"E_LT": 0.8500, "E_MA": 0.7500, "E_ND": 0.7500, "E_LoA": 0.4010, "E_mech": 0.1917, "muscle": "trapezius_upper", "rationale": "Its transverse fibres contribute a real retraction component at shoulder height, though its dominant elevation vector is largely irrelevant to the required horizontal scapular moment.", "maximum_fcsa_cm2": 19.36, "fcsa_contribution_cm2": 3.71}, {"E_LT": 0.8500, "E_MA": 0.4200, "E_ND": 0.5500, "E_LoA": 0.4380, "E_mech": 0.0860, "muscle": "biceps_brachii", "rationale": "Assists the isometric elbow hold alongside brachialis, with poor leverage at the near-extended elbow angle.", "maximum_fcsa_cm2": 39.81, "fcsa_contribution_cm2": 3.42}, {"E_LT": 0.9000, "E_MA": 0.6500, "E_ND": 0.6000, "E_LoA": 0.3280, "E_mech": 0.1151, "muscle": "transverse_abdominis", "rationale": "Generates the hoop tension and intra-abdominal pressure that stiffen the trunk cylinder against the rotational moment, the same mechanism as in the Pallof press at lower magnitude.", "maximum_fcsa_cm2": 21.97, "fcsa_contribution_cm2": 2.53}, {"E_LT": 0.8500, "E_MA": 0.7000, "E_ND": 0.4500, "E_LoA": 0.2350, "E_mech": 0.0629, "muscle": "serratus_anterior", "rationale": "Included on the narrow grounds that it stabilises the scapula against tipping off the thorax during retraction; its protraction vector directly opposes the required motion, which caps its alignment.", "maximum_fcsa_cm2": 36.03, "fcsa_contribution_cm2": 2.27}], "effective_resistance": {"assumptions": ["Representative commercial selectorized reverse pec deck with a cam-and-lever linkage; effective lever ratio ~0.80 at the handle, so 40 kg nominal resolves to ~32 kg of effective handle resistance, ~314 N.", "Side-facing setup: the athlete sits sideways on the seat rather than facing the pad, working one arm across the body, which is the defining feature of this variant.", "Read as unilateral-asymmetric following the Pallof press precedent: 40 kg is a single stack acting on one arm, not two mirrored 20 kg loads. Mirroring would cancel the anti-rotation demand that distinguishes this exercise from a standard reverse pec deck.", "Arm held near-straight at a fixed ~160 degree elbow; effective external moment arm from the glenohumeral axis to the handle force line ~0.40 m at the limiting phase.", "The required humeral action is horizontal abduction in the transverse plane at shoulder height, which is the posterior deltoid's primary function.", "Without the chest pad to brace against, the 314 N acting at ~0.135 m from the trunk axis generates a ~42 N-m rotational moment that must be actively resisted for the arm to have a stable base to pull from.", "Internal moment arms: posterior deltoid horizontal abduction ~0.045 m, scapular retractors ~0.055 m, oblique rotation ~0.055 m.", "The handle force acts largely perpendicular to the forearm, creating an elbow flexion-resisting demand; the elbow flexors work isometrically to hold the fixed angle and transmit load from hand to humerus.", "The seat and thigh contact anchor the pelvis, but the torso above the pelvis is unsupported in this orientation, so trunk anti-rotation is genuine load-bearing rather than posture.", "40 kg is a realistic 8-12 rep working load for a single arm on a machine with this lever ratio, where the long straight-arm moment arm makes the effective demand well above what the stack number suggests."], "loaded_joints": [{"joint": "glenohumeral_unilateral", "estimated_external_moment_nm": 63.00}, {"joint": "scapulothoracic_unilateral", "estimated_external_moment_nm": 38.00}, {"joint": "thoracolumbar_spine_rotation", "estimated_external_moment_nm": 42.00}, {"joint": "elbow_unilateral", "estimated_external_moment_nm": 7.10}], "nominal_load_kg": 40.00, "estimated_effective_force_n": 314.00}, "systemic_fcsa_demand_cm2": 108.17, "top_down_fcsa_target_cm2": 108.00}
45	seated_dumbbell_wrist_curl	Dumbbell Wrist Curl	Seated Palms-Up Dumbbell Wrist Curl	Upper	Forearms	Isolation	Dumbbell	24.00	50.70	{"wrist_flexors": 50.70}	{}	{}	{}	Unilateral	{"slug": "seated_dumbbell_wrist_curl", "notes": ["The wrist-flexor aggregate approaches its modeled maximum capacity; E_mech is therefore near the upper limit rather than representing moderate utilization.", "The estimated contribution generates approximately 15.3 Nm of bilateral wrist-flexion torque using a representative internal wrist-flexor moment arm near 0.0121 m.", "The supplied 24 kg bilateral load is at the high end of a plausible strict 8-12 repetition working load for the reference athlete and requires full forearm support and controlled technique.", "Wrist extensors and pronators-supinators are excluded because any co-contraction or rotational stabilization does not produce a meaningful share of the required net wrist-flexion moment."], "limiting_phase": "Concentric initiation from moderate wrist extension, with the forearms fully supported on the thighs or bench and the dumbbells held near the distal fingers before the external wrist moment arm shortens.", "reconciliation": "PASS", "vector_sum_cm2": 50.70, "muscle_evaluation": [{"E_LT": 0.9700, "E_MA": 0.9800, "E_ND": 0.9900, "E_LoA": 0.9900, "E_mech": 0.9319, "muscle": "wrist_flexors", "rationale": "The wrist-flexor aggregate directly produces nearly all required wrist-flexion torque and operates with favorable length and leverage from the extended starting position.", "maximum_fcsa_cm2": 54.40, "fcsa_contribution_cm2": 50.70}], "effective_resistance": {"assumptions": ["The 24 kg nominal load represents two 12 kg dumbbells.", "The forearms remain fully supported, so the dumbbells create negligible meaningful elbow or shoulder demand.", "The combined perpendicular distance from the wrist axes to the dumbbell centres of mass is approximately 0.065 m at the limiting phase.", "The grip remains palms-up and the dumbbells are controlled without assistance from elbow flexion or forearm lifting.", "The wrist_flexors aggregate includes the principal wrist and finger flexors required to maintain the dumbbell grip while producing wrist-flexion torque."], "loaded_joints": [{"joint": "wrist_flexion_bilateral", "estimated_external_moment_nm": 15.31}], "nominal_load_kg": 24.00, "estimated_effective_force_n": 235.44}, "systemic_fcsa_demand_cm2": 50.70, "top_down_fcsa_target_cm2": 50.70}
\.


-- Other exercises listed only by minimal info set
-- slug                                       |name                           |name_full                                        |body_part|target_category|mechanics_tier     |resistance_source   |load_capacity|systemic_propulsive_fcsa_demand|
-- -------------------------------------------+-------------------------------+-------------------------------------------------+---------+---------------+-------------------+--------------------+-------------+-------------------------------+
-- selectorized_leg_extension                 |Leg Extension                  |Selectorized Seated Leg Extension                |Lower    |Quads          |Isolation          |Selectorized_Machine|        60.00|                         215.82|
-- side_facing_reverse_pec_deck               |Side-Facing Reverse Pec Deck   |Single-Arm Side-Facing Reverse Pec Deck Fly      |Upper    |Back_3D        |Isolation          |Selectorized_Machine|        20.00|                         108.17|
-- selectorized_hip_adduction                 |Hip Adduction Machine          |Selectorized Seated Hip Adduction Machine        |Lower    |Hip_AF         |Isolation          |Selectorized_Machine|        70.00|                         118.34|
-- single_arm_bayesian_cable_curl             |Bayesian Cable Curl            |Single-Arm Bayesian Cable Curl                   |Upper    |Biceps         |Isolation          |Cable               |        30.00|                          85.10|
-- seated_dumbbell_overhead_press             |Dumbbell Overhead Press        |Seated Dumbbell Overhead Press                   |Upper    |Chest_Clav_AD  |Secondary_Compound |Dumbbell            |        48.00|                         130.65|
-- single_arm_dumbbell_preacher_curl          |Dumbbell Preacher Curl         |Single-Arm Dumbbell Preacher Curl                |Upper    |Biceps         |Isolation          |Dumbbell            |        28.00|                          68.68|
-- barbell_bench_press                        |Bench Press                    |Flat Bench Barbell Press                         |Upper    |Chest_Sternal  |Heavy_Compound     |Barbell             |        72.00|                         175.61|
-- neutral_grip_lat_pulldown                  |Neutral-Grip Lat Pulldown      |Selectorized Neutral-Grip Lat Pulldown           |Upper    |Back_V         |Secondary_Compound |Selectorized_Machine|        75.00|                         191.51|
-- plate_loaded_converging_incline_chest_press|Converging Incline Chest Press |Plate-Loaded Converging Incline Chest Press      |Upper    |Chest_Clav_AD  |Secondary_Compound |Plate_Loaded_Machine|        70.00|                         141.68|
-- single_arm_kneeling_wide_cable_row         |One-Arm Kneeling Cable Row     |Single-Arm Kneeling Wide-Elbow Cable Row         |Upper    |Back_3D        |Secondary_Compound |Cable               |        70.00|                         178.36|
-- selectorized_seated_leg_curl               |Seated Leg Curl                |Selectorized Seated Leg Curl                     |Lower    |Hamstrings     |Isolation          |Selectorized_Machine|        50.00|                         145.04|
-- single_arm_low_to_high_cable_fly           |Low-to-High Cable Fly          |Single-Arm Low-to-High Cable Fly                 |Upper    |Chest_Clav_AD  |Isolation          |Cable               |        36.00|                         105.44|
-- barbell_california_press                   |California Press               |Flat Bench Barbell California Press              |Upper    |Triceps        |Secondary_Compound |Barbell             |        50.00|                         139.44|
-- barbell_pendlay_row                        |Pendlay Row                    |Barbell Pendlay Row                              |Upper    |Back_3D        |Heavy_Compound     |Barbell             |        90.00|                         579.05|
-- plate_loaded_45_degree_leg_press           |45-Degree Leg Press            |Plate-Loaded 45-Degree Sled Leg Press            |Lower    |Quads          |Heavy_Compound     |Plate_Loaded_Machine|       200.00|                         546.14|
-- seated_dumbbell_wrist_extension            |Dumbbell Wrist Extension       |Seated Palms-Down Dumbbell Wrist Extension       |Upper    |Forearms       |Isolation          |Dumbbell            |        12.00|                          38.37|
-- wide_pronated_grip_pull_up                 |Wide-Grip Pull-Up              |Wide Pronated-Grip Pull-Up                       |Upper    |Back_V         |Heavy_Compound     |Bodyweight          |        85.00|                         190.75|
-- seated_dumbbell_arnold_press               |Arnold Press                   |Seated Dumbbell Arnold Press                     |Upper    |Chest_Clav_AD  |Secondary_Compound |Dumbbell            |        44.00|                         124.67|
-- kneeling_cable_crunch                      |Kneeling Cable Crunch          |Kneeling Rope Cable Crunch                       |Core     |Core           |Isolation          |Cable               |        60.00|                          45.59|
-- hanging_oblique_knee_raise                 |Hanging Oblique Knee Raise     |Alternating Hanging Oblique Knee Raise           |Core     |Core           |Secondary_Compound |Bodyweight          |        27.00|                         106.84|
-- dead_hang                                  |Dead Hang                      |Pronated-Grip Bar Dead Hang                      |Upper    |Forearms       |Stability_Isometric|Bodyweight          |        85.00|                          41.01|
-- bodyweight_neck_extension                  |Neck Extension                 |Prone Bench Bodyweight Neck Extension            |Upper    |Neck           |Isolation          |Bodyweight          |         5.00|                           8.49|
-- cable_face_pull                            |Face Pull                      |Rope Cable Face Pull                             |Upper    |Back_3D        |Isolation          |Cable               |        30.00|                          46.53|
-- straight_arm_cable_pulldown                |Straight-Arm Pulldown          |Standing Straight-Arm Cable Pulldown             |Upper    |Back_V         |Isolation          |Cable               |        40.00|                         105.31|
-- plate_loaded_seated_calf_raise             |Seated Calf Raise              |Plate-Loaded Seated Calf Raise                   |Lower    |Calves         |Isolation          |Plate_Loaded_Machine|        80.00|                         162.70|
-- plate_loaded_chest_press                   |Machine Chest Press            |Plate-Loaded Horizontal Chest Press              |Upper    |Chest_Sternal  |Heavy_Compound     |Plate_Loaded_Machine|        80.00|                         148.89|
-- bodyweight_crunch                          |Crunch                         |Floor Bodyweight Abdominal Crunch                |Core     |Core           |Isolation          |Bodyweight          |        22.00|                          36.40|
-- chest_supported_dumbbell_row               |Chest-Supported Dumbbell Row   |Incline Bench Chest-Supported Dumbbell Row       |Upper    |Back_3D        |Secondary_Compound |Dumbbell            |        60.00|                         175.19|
-- incline_dumbbell_curl                      |Incline Dumbbell Curl          |Seated Incline Bench Dumbbell Curl               |Upper    |Biceps         |Isolation          |Dumbbell            |        28.00|                          76.66|
-- weighted_neutral_grip_pull_up              |Weighted Neutral-Grip Pull-Up  |Weighted Neutral-Grip Pull-Up                    |Upper    |Back_V         |Heavy_Compound     |Bodyweight          |       100.00|                         245.71|
-- copenhagen_plank                           |Copenhagen Plank               |Bench-Supported Copenhagen Side Plank            |Core     |Hip_AF         |Stability_Isometric|Bodyweight          |        35.00|                         131.52|
-- dragon_flag                                |Dragon Flag                    |Flat Bench Dragon Flag                           |Core     |Core           |Secondary_Compound |Bodyweight          |        55.00|                         115.00|
-- smith_machine_incline_bench_press          |Smith Machine Incline Press    |Incline Bench Smith Machine Press                |Upper    |Chest_Clav_AD  |Secondary_Compound |Smith_Machine       |        80.00|                         157.13|
-- bodyweight_neck_curl                       |Neck Curl                      |Supine Bench Bodyweight Neck Curl                |Upper    |Neck           |Isolation          |Bodyweight          |         5.00|                           8.55|
-- cable_pull_through                         |Cable Pull-Through             |Rope Cable Pull-Through                          |Lower    |Glutes         |Secondary_Compound |Cable               |        60.00|                         203.16|
-- high_to_low_pec_deck_fly                   |High-to-Low Pec Deck Fly       |Selectorized High-to-Low Pec Deck Fly            |Upper    |Chest_Sternal  |Isolation          |Selectorized_Machine|        45.00|                          96.62|
-- overhead_rope_triceps_extension            |Overhead Rope Triceps Extension|Standing Cable Overhead Rope Triceps Extension   |Upper    |Triceps        |Isolation          |Cable               |        35.00|                          88.79|
-- wide_grip_seated_cable_row                 |Wide-Grip Seated Cable Row     |Wide-Grip Seated Cable Row                       |Upper    |Back_3D        |Secondary_Compound |Cable               |        80.00|                         178.24|
-- standing_dumbbell_shrug                    |Dumbbell Shrug                 |Standing Dumbbell Shrug                          |Upper    |Upper_Traps    |Isolation          |Dumbbell            |        80.00|                         111.06|
-- weighted_forward_lean_dip                  |Weighted Chest Dip             |Weighted Forward-Lean Parallel-Bar Dip           |Upper    |Chest_Sternal  |Heavy_Compound     |Bodyweight          |       110.00|                         193.52|
-- standing_cable_pallof_press                |Pallof Press                   |Standing Cable Pallof Press                      |Core     |Core           |Stability_Isometric|Cable               |        20.00|                          74.62|
-- smith_machine_standing_calf_raise          |Standing Calf Raise            |Smith Machine Standing Calf Raise                |Lower    |Calves         |Isolation          |Smith_Machine       |       120.00|                         240.70|
-- roman_chair_back_extension_isometric_hold  |Roman Chair Isometric Hold     |Roman Chair Back Extension Isometric Hold        |Lower    |Global_P       |Stability_Isometric|Bodyweight          |        45.00|                         182.92|
-- standing_barbell_curl                      |Barbell Curl                   |Standing Barbell Curl                            |Upper    |Biceps         |Isolation          |Barbell             |        40.00|                          87.35|
-- weighted_russian_twist                     |Weighted Russian Twist         |Seated Weighted Russian Twist                    |Core     |Core           |Secondary_Compound |Other               |        15.00|                          63.45|
-- hanging_leg_raise                          |Hanging Leg Raise              |Straight-Leg Hanging Leg Raise                   |Core     |Core           |Secondary_Compound |Bodyweight          |        32.00|                         131.62|
-- preacher_dumbbell_hammer_curl              |Preacher Hammer Curl           |Single-Arm Dumbbell Hammer Curl on Preacher Bench|Upper    |Biceps         |Isolation          |Dumbbell            |        16.00|                          47.31|
-- single_arm_cable_lateral_raise             |Cable Lateral Raise            |Single-Arm Cable Lateral Raise                   |Upper    |Lateral_Delt   |Isolation          |Cable               |        24.00|                          87.29|
-- seated_dumbbell_wrist_curl                 |Dumbbell Wrist Curl            |Seated Palms-Up Dumbbell Wrist Curl              |Upper    |Forearms       |Isolation          |Dumbbell            |        24.00|                          50.70|


--
-- Data for Name: muscle_exercise_mappings; Type: TABLE DATA; Schema: core; Owner: kartezjusz
--

COPY core.muscle_exercise_mappings (muscle_id, exercise_id, complexity, resistance_profile) FROM stdin;
\.


--
-- Data for Name: muscles; Type: TABLE DATA; Schema: core; Owner: kartezjusz
--

COPY core.muscles (id, slug, name, body_part, complex, mass_g, mv_cm3, pcsa, architecture, fiber_bias_type_i, fiber_bias_type_ii, smh_factor, strength_curve, leverage_peak, bible_markdown, article_links, video_links, mass_reference, optimal_fiber_length_cm, pennation_angle_deg, pennation_cos, pcsa_fiber_cm2, pcsa_projected_fcsa_cm2) FROM stdin;
9	rotator_cuffs	Musculus rotator cuffs	Upper	Shoulder	1065.00	1008.52	60.00	Undefined	0.750	0.250	zero	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	5.90	2.31	0.999	170.94	170.80
31	gluteus_medius	Musculus gluteus medius	Lower	Glutes	940.00	890.15	65.00	Fan-shaped/Radiate	0.550	0.450	high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	7.33	20.50	0.937	121.44	113.75
30	gluteus_maximus	Musculus gluteus maximus	Lower	Glutes	2555.00	2419.51	65.00	Coarse Multipennate	0.440	0.560	extreme_high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	15.69	21.90	0.928	154.21	143.08
20	triceps_lateral_head	Musculus triceps brachii caput laterale	Upper	Triceps	440.00	416.67	22.00	Pennate	0.250	0.750	low	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	11.40	9.00	0.988	36.55	36.10
43	adductor_longus_brevis	Musculus adductor longus, Musculus adductor brevis	Lower	Hip_FA	750.00	710.23	30.00	Fan-shaped/Triangular	0.495	0.505	extreme_high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	10.60	6.68	0.993	67.00	66.55
42	adductor_magnus	Musculus adductor magnus	Lower	Hip_FA	1665.00	1576.70	88.00	Multipennate/Triangular	0.425	0.575	extreme_high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	14.44	15.50	0.964	109.19	105.22
32	gluteus_minimus	Musculus gluteus minimus	Lower	Glutes	270.00	255.68	15.00	Fan-shaped/Radiate	0.575	0.425	high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	10.30	0.00	1.000	24.82	24.82
46	soleus	Musculus soleus	Lower	Calves	1150.00	1089.02	150.00	Multipennate	0.775	0.225	medium	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	4.40	28.30	0.880	247.50	217.92
41	iliopsoas	Musculus iliopsoas	Lower	Hip_FA	1230.00	1164.77	77.00	Fusiform/Parallel	0.475	0.525	high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	11.11	12.80	0.975	104.84	102.23
5	deltoid_lateral	Musculus Deltoid lateral	Upper	Shoulder	540.00	511.36	28.00	Multipenate	0.500	0.500	zero	Bell-shaped	Mid_Range	\n# Overview\n\n\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	10.80	15.00	0.966	47.35	45.73
47	tibialis_anterior	Musculus tibialis anterior	Lower	Shin	305.00	288.83	25.00	Circumpennate/Fusiform	0.600	0.400	extreme_high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	6.83	9.60	0.986	42.29	41.70
45	gastrocnemius	Musculus gastrocnemius	Lower	Calves	1055.00	999.05	62.00	Pennate/Bipennate	0.425	0.575	high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	5.35	10.62	0.983	186.74	183.54
37	biceps_femoris_long_head	Musculus biceps femoris caput longum	Lower	Hamstrings	565.00	535.04	35.00	Fusiform/Unipennate	0.400	0.600	extreme_high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	9.76	11.60	0.980	54.82	53.70
6	deltoid_posterior	Musculus Deltoid posterior	Upper	Shoulder	375.00	355.11	8.00	Fusiform/Parallel-like	0.650	0.350	high	Bell-shaped	Mid_Range	\n# Overview\n\n\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	13.70	18.00	0.951	25.92	24.65
21	triceps_medial_head	Musculus triceps brachii caput mediale	Upper	Triceps	190.00	179.92	20.00	Pennate	0.500	0.500	very_low	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	11.40	9.00	0.988	15.78	15.59
28	obliques	Musculus obliquus externus abdominis, Musculus obliquus internus abdominis	Core	Core	925.00	875.95	38.50	Broad Flat/Parallel	0.475	0.525	high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	10.72	0.00	1.000	81.71	81.71
27	rectus_abdominis	Musculus rectus abdominis	Core	Core	685.00	648.67	27.50	Parallel/Polygastric	0.445	0.555	high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	26.70	0.00	1.000	24.29	24.29
29	transverse_abdominis	Musculus transversus abdominis	Core	Core	225.00	213.07	28.00	Broad Transverse	0.725	0.275	zero	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	9.70	0.00	1.000	21.97	21.97
26	serratus_anterior	Musculus serratus anterior	Core	Core	525.00	497.16	20.00	Serrated/Fan-shaped	0.525	0.475	high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	13.80	0.00	1.000	36.03	36.03
14	trapezius_lower	Musculus Trapezius lower	Upper	Back	200.00	189.39	7.00	Parallel/Convergent	0.550	0.450	very_high	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	12.64	0.00	1.000	14.98	14.98
13	trapezius_middle	Musculus Trapezius middle	Upper	Back	230.00	217.80	11.00	Parallel	0.650	0.350	very_high	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	8.32	0.00	1.000	26.18	26.18
48	sternocleidomastoid	Musculus sternocleidomastoideus	Upper	Neck	175.00	165.72	8.00	Parallel/Fusiform	0.650	0.350	high	Bell-shaped	Mid_Range	¶# Overview¶¶# Anatomy¶- Origin¶- Insertion¶¶# Innervation¶¶# Function¶¶# Stretch-Mediated Hypertrophy¶¶# Training Notes¶¶# Interesting Facts¶¶	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	11.80	10.00	0.985	14.04	13.83
15	rhomboids	Musculus Rhomboideus	Upper	Back	215.00	203.60	12.00	Parallel	0.400	0.600	very_high	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	7.20	2.50	0.999	28.28	28.25
49	deep_neck_extensors	Musculi colli extensores	Upper	Neck	430.00	407.20	12.00	Parallel/Pennate	0.700	0.300	high	Bell-shaped	Mid_Range	¶# Overview¶¶To sa kilka mięśnie tak naprawdę (m.in. płatowaty, półkolcowy, wielodzielny).¶¶Na volume i PCSA wziąłem średnią.¶¶# Anatomy¶- Origin¶- Insertion¶¶# Innervation¶¶# Function¶¶# Stretch-Mediated Hypertrophy¶¶# Training Notes¶¶# Interesting Facts¶¶	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	4.79	3.18	0.998	85.01	84.88
23	wrist_flexors	Musculus flexor carpi ulnaris&radialis, flexor digitorum superficialis	Upper	Forearms	465.00	440.34	30.00	Fusiform/Pennate	0.550	0.450	high	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	8.07	4.46	0.997	54.57	54.40
24	wrist_extensors	Musculus extensor carpi radialis longus et brevis, 	Upper	Forearms	445.00	421.40	11.00	Pennate	0.650	0.350	high	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	7.78	7.72	0.991	54.16	53.67
25	pronators_supinators	Musculus pronator teres, Musculus pronator quadratus, Musculus supinator	Upper	Forearms	180.00	170.45	12.00	Fusiform/Quadrilateral	0.450	0.550	high	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	2.80	0.00	1.000	60.88	60.88
38	biceps_femoris_short_head	Musculus biceps femoris caput breve	Lower	Hamstrings	285.00	269.89	23.00	Unipennate	0.475	0.525	medium	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	11.03	12.30	0.977	24.47	23.91
44	sartorius	Musculus sartorius	Lower	Hip_FA	435.00	411.93	6.00	Strap/Parallel	0.450	0.550	high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	40.30	1.30	1.000	10.22	10.22
10	latissimus_dorsi	Musculus latissimus dorsi	Upper	Back	1260.00	1193.18	32.00	Parallel/Convergent	0.500	0.500	very_high	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	25.25	21.89	0.928	47.25	43.85
11	teres_major	Musculus Teres major	Upper	Back	80.00	75.76	14.00	Parallel	0.400	0.600	very_high	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	16.20	16.00	0.961	4.68	4.50
39	semitendinosus	Musculus semitendinosus	Lower	Hamstrings	535.00	506.63	18.00	Fusiform/Long-fibered	0.450	0.550	extreme_high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	19.30	12.90	0.975	26.25	25.59
16	erector_spinae	Thoracolumbar spinal extensor complex	Upper	Back	1375.00	1302.08	28.00	Parallel/Long-Fusiform	0.750	0.250	high	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	11.89	13.52	0.972	109.51	106.48
33	rectus_femoris	Musculus rectus femoris	Lower	Quads	755.00	714.96	27.00	Bipennate	0.400	0.600	extreme_high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	7.59	13.90	0.971	94.20	91.44
18	brachialis	Musculus brachialis	Upper	Biceps	400.00	378.79	23.00	Fusiform/Convergent	0.600	0.400	low	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	8.60	0.00	1.000	44.05	44.05
36	vastus_intermedius	Musculus vastus intermedius	Lower	Quads	740.00	700.76	48.50	Pennate	0.550	0.450	high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	9.93	4.50	0.997	70.57	70.35
17	biceps_brachii	Musculus biceps brachii	Upper	Biceps	515.00	487.69	22.00	Fusiform	0.350	0.650	very_high	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	12.25	0.00	1.000	39.81	39.81
22	triceps_long_head	Musculus triceps brachii caput longum	Upper	Triceps	630.00	596.59	26.00	Pennate	0.350	0.650	extreme_high	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	13.40	12.00	0.978	44.52	43.55
34	vastus_lateralis	Musculus vastus lateralis	Lower	Quads	2690.00	2547.35	70.00	Unipennate/Multipennate	0.475	0.525	high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	9.94	18.40	0.949	256.27	243.17
35	vastus_medialis	Musculus vastus medialis	Lower	Quads	1380.00	1306.82	51.50	Pennate/Bi-directional	0.540	0.460	high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	9.68	29.60	0.869	135.00	117.38
40	semimembranosus	Musculus semimembranosus	Lower	Hamstrings	670.00	634.47	97.00	Semi-membranous/Unipennate	0.445	0.555	extreme_high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	6.90	15.10	0.965	91.95	88.78
19	brachioradialis	Musculus brachioradialis	Upper	Biceps	205.00	194.13	13.00	Fusiform/Parallel	0.400	0.600	low	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	17.30	0.00	1.000	11.22	11.22
4	deltoid_anterior	Musculus Deltoid anterior	Upper	Shoulder	340.00	321.97	10.00	Multipenate	0.400	0.600	medium	Bell-shaped	Mid_Range	\n# Overview\n\n\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	9.80	22.00	0.927	32.85	30.46
1	pectoralis_major_clavicular	Musculus pectoralis major clavicular head	Upper	Chest	215.00	203.60	13.00	Converged/Fan-shaped	0.400	0.600	high	Bell-shaped	Mid_Range	\n# Overview\n\n\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	14.40	17.00	0.956	14.14	13.52
2	pectoralis_major_sternal	Musculus Pectoralis major sternal head	Upper	Chest	860.00	814.39	30.00	Converged/Fan-shaped	0.350	0.650	high	Bell-shaped	Mid_Range	\n# Overview\n\n\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	13.80	25.00	0.906	59.01	53.48
3	pectoralis_minor	Musculus Pectoralis minor	Upper	Chest	135.00	127.84	8.00	Flat/Convergent	0.550	0.450	zero	Bell-shaped	Mid_Range	\n# Overview\n\n\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	11.83	0.00	1.000	10.81	10.81
12	trapezius_upper	Musculus Trapezius upper	Upper	Back	230.00	217.80	8.00	Parallel	0.550	0.450	high	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}	Bilateral	11.25	0.00	1.000	19.36	19.36
\.


--
-- Data for Name: exercises; Type: TABLE DATA; Schema: engine; Owner: kartezjusz
--

COPY engine.exercises (slug, load_capacity, systemic_propulsive_fcsa_demand, propulsive_fcsa_contribution_vector, active_tension_exposure_vector, active_tension_exposure_vector_eval_notes, etu_vector, etu_vector_eval_notes, muscle_recovery_cost_modifier_vector, muscle_recovery_cost_modifier_vector_eval_notes, joint_load_exposure_vector, joint_load_exposure_vector_eval_notes) FROM stdin;
dragon_flag	55.00	115.00	{"obliques": 37.35, "iliopsoas": 27.97, "rectus_femoris": 15.93, "latissimus_dorsi": 11.36, "rectus_abdominis": 17.34, "triceps_long_head": 5.05}	{"obliques": 37.35, "iliopsoas": 27.97, "rotator_cuffs": 5.00, "wrist_flexors": 3.00, "erector_spinae": 1.50, "rectus_femoris": 15.93, "gluteus_maximus": 4.00, "trapezius_lower": 2.00, "wrist_extensors": 1.50, "latissimus_dorsi": 11.36, "rectus_abdominis": 17.34, "serratus_anterior": 2.50, "triceps_long_head": 5.05, "deep_neck_extensors": 1.00, "transverse_abdominis": 2.50}	{"slug": "dragon_flag", "notes": ["The supplied contribution vector sums exactly to the systemic propulsive FCSA demand.", "The supplied latissimus-dorsi and triceps-long-head entries were interpreted primarily as upper-body anchoring and load-transmission tension rather than visible movement-producing force.", "The abdominal, hip-flexor, and rectus-femoris entries already capture most of the rigid-body and long-lever demand and were not expanded mechanically a second time.", "Additional exposure was limited to hip-extension rigidity, deep abdominal and spinal co-contraction, bench grip, and mechanically specific shoulder-girdle and cervical stabilization.", "The repetition is modeled as a strict dragon flag without hip piking, momentum, or loss of the rigid trunk-to-leg line."], "added_muscles": ["rotator_cuffs", "gluteus_maximus", "wrist_flexors", "transverse_abdominis", "serratus_anterior", "trapezius_lower", "erector_spinae", "wrist_extensors", "deep_neck_extensors"], "reconciliation": "PASS", "muscle_evaluation": [{"muscle": "obliques", "rationale": "Produces substantial anti-extension and anti-rotation torque while maintaining rigid alignment between the ribcage and pelvis as the long body lever rises and lowers. The supplied contribution already combines its movement-producing, braking, and bracing force state.", "maximum_fcsa_cm2": 81.71, "mechanical_roles": ["propulsive", "trunk_bracing", "isometric_fixation", "eccentric_control", "multi_joint_control"], "tension_fraction": 0.4571, "propulsive_fcsa_cm2": 37.35, "contraction_character": ["isometric", "co_contractile", "dynamic_eccentric", "dynamic_concentric"], "active_tension_exposure_cm2": 37.35, "input_contribution_classification": "mixed_propulsive_and_stabilizing"}, {"muscle": "iliopsoas", "rationale": "Contributes hip-flexion torque and helps preserve the rigid trunk-to-leg relationship as the lower body moves relative to the anchored upper torso. The supplied value is retained as the complete dynamic and positional force state.", "maximum_fcsa_cm2": 102.23, "mechanical_roles": ["propulsive", "eccentric_control", "limb_position_maintenance", "multi_joint_control"], "tension_fraction": 0.2736, "propulsive_fcsa_cm2": 27.97, "contraction_character": ["dynamic_concentric", "dynamic_eccentric", "isometric"], "active_tension_exposure_cm2": 27.97, "input_contribution_classification": "primarily_propulsive"}, {"muscle": "rectus_abdominis", "rationale": "Maintains posterior pelvic tilt and resists lumbar extension under the long external moment arm while contributing to controlled trunk and pelvic motion. The supplied value already represents its high mixed dynamic and anti-extension demand.", "maximum_fcsa_cm2": 24.29, "mechanical_roles": ["propulsive", "trunk_bracing", "isometric_fixation", "eccentric_control"], "tension_fraction": 0.7139, "propulsive_fcsa_cm2": 17.34, "contraction_character": ["isometric", "co_contractile", "dynamic_eccentric", "dynamic_concentric"], "active_tension_exposure_cm2": 17.34, "input_contribution_classification": "mixed_propulsive_and_stabilizing"}, {"muscle": "rectus_femoris", "rationale": "Assists hip flexion while maintaining knee extension and a rigid lower-limb lever. The supplied value already combines its hip-flexor and knee-position roles.", "maximum_fcsa_cm2": 91.44, "mechanical_roles": ["propulsive", "limb_position_maintenance", "isometric_fixation", "multi_joint_control"], "tension_fraction": 0.1742, "propulsive_fcsa_cm2": 15.93, "contraction_character": ["isometric", "dynamic_concentric", "dynamic_eccentric"], "active_tension_exposure_cm2": 15.93, "input_contribution_classification": "mixed_propulsive_and_stabilizing"}, {"muscle": "latissimus_dorsi", "rationale": "Anchors the upper torso against the bench through shoulder-extension and adduction tension while transmitting the long-lever body load into the fixed arms. The supplied contribution is treated as the complete high-force fixation state.", "maximum_fcsa_cm2": 43.85, "mechanical_roles": ["isometric_fixation", "load_transmission", "joint_stabilization", "multi_joint_control"], "tension_fraction": 0.2591, "propulsive_fcsa_cm2": 11.36, "contraction_character": ["isometric", "co_contractile"], "active_tension_exposure_cm2": 11.36, "input_contribution_classification": "primarily_stabilizing_or_load_transmitting"}, {"muscle": "triceps_long_head", "rationale": "Helps anchor the elevated upper arms and maintain elbow position while force is transferred from the bench grip through the shoulder girdle. The supplied value is retained as the complete biarticular fixation demand.", "maximum_fcsa_cm2": 43.55, "mechanical_roles": ["isometric_fixation", "load_transmission", "joint_stabilization", "multi_joint_control"], "tension_fraction": 0.1160, "propulsive_fcsa_cm2": 5.05, "contraction_character": ["isometric", "co_contractile"], "active_tension_exposure_cm2": 5.05, "input_contribution_classification": "primarily_stabilizing_or_load_transmitting"}, {"muscle": "rotator_cuffs", "rationale": "Centres the humeral heads while the arms anchor the body against the bench and large shoulder moments are transmitted through the upper limbs.", "maximum_fcsa_cm2": 170.80, "mechanical_roles": ["joint_stabilization", "load_transmission", "isometric_fixation"], "tension_fraction": 0.0293, "propulsive_fcsa_cm2": 0.00, "contraction_character": ["isometric", "co_contractile"], "active_tension_exposure_cm2": 5.00, "input_contribution_classification": "primarily_stabilizing_or_load_transmitting"}, {"muscle": "gluteus_maximus", "rationale": "Maintains hip extension and a rigid pelvis-to-leg line, opposing excessive hip flexion from the long lower-body lever. The modest allocation reflects meaningful whole-body rigidity rather than primary movement production.", "maximum_fcsa_cm2": 143.08, "mechanical_roles": ["limb_position_maintenance", "isometric_fixation", "trunk_bracing", "multi_joint_control"], "tension_fraction": 0.0280, "propulsive_fcsa_cm2": 0.00, "contraction_character": ["isometric", "co_contractile"], "active_tension_exposure_cm2": 4.00, "input_contribution_classification": "primarily_stabilizing_or_load_transmitting"}, {"muscle": "wrist_flexors", "rationale": "Maintains the bench grip and transmits force from the anchored hands into the arms and shoulder girdle throughout the repetition.", "maximum_fcsa_cm2": 54.40, "mechanical_roles": ["grip_maintenance", "isometric_fixation", "load_transmission"], "tension_fraction": 0.0551, "propulsive_fcsa_cm2": 0.00, "contraction_character": ["isometric", "co_contractile"], "active_tension_exposure_cm2": 3.00, "input_contribution_classification": "primarily_stabilizing_or_load_transmitting"}, {"muscle": "transverse_abdominis", "rationale": "Provides circumferential abdominal stiffness and helps preserve lumbopelvic rigidity under the large anti-extension demand.", "maximum_fcsa_cm2": 21.97, "mechanical_roles": ["trunk_bracing", "isometric_fixation", "load_transmission"], "tension_fraction": 0.1138, "propulsive_fcsa_cm2": 0.00, "contraction_character": ["isometric", "co_contractile"], "active_tension_exposure_cm2": 2.50, "input_contribution_classification": "primarily_stabilizing_or_load_transmitting"}, {"muscle": "serratus_anterior", "rationale": "Maintains scapular contact with the thorax and stabilizes the shoulder girdle as force is transferred through the anchored arms.", "maximum_fcsa_cm2": 36.03, "mechanical_roles": ["scapular_control", "load_transmission", "isometric_fixation"], "tension_fraction": 0.0694, "propulsive_fcsa_cm2": 0.00, "contraction_character": ["isometric", "co_contractile"], "active_tension_exposure_cm2": 2.50, "input_contribution_classification": "primarily_stabilizing_or_load_transmitting"}, {"muscle": "trapezius_lower", "rationale": "Stabilizes scapular tilt and elevation while the upper body remains fixed against the bench under a large longitudinal load.", "maximum_fcsa_cm2": 14.98, "mechanical_roles": ["scapular_control", "load_transmission", "isometric_fixation"], "tension_fraction": 0.1335, "propulsive_fcsa_cm2": 0.00, "contraction_character": ["isometric", "co_contractile"], "active_tension_exposure_cm2": 2.00, "input_contribution_classification": "primarily_stabilizing_or_load_transmitting"}, {"muscle": "erector_spinae", "rationale": "Provides low-level spinal stiffness and segmental control in co-contraction with the abdominal wall without becoming a major extension prime mover.", "maximum_fcsa_cm2": 106.48, "mechanical_roles": ["antagonist_co_contraction", "trunk_bracing", "isometric_fixation"], "tension_fraction": 0.0141, "propulsive_fcsa_cm2": 0.00, "contraction_character": ["isometric", "co_contractile"], "active_tension_exposure_cm2": 1.50, "input_contribution_classification": "primarily_stabilizing_or_load_transmitting"}, {"muscle": "wrist_extensors", "rationale": "Co-contracts with the wrist flexors to maintain stable wrist alignment while gripping the bench.", "maximum_fcsa_cm2": 53.67, "mechanical_roles": ["grip_maintenance", "antagonist_co_contraction", "isometric_fixation"], "tension_fraction": 0.0279, "propulsive_fcsa_cm2": 0.00, "contraction_character": ["isometric", "co_contractile"], "active_tension_exposure_cm2": 1.50, "input_contribution_classification": "primarily_stabilizing_or_load_transmitting"}, {"muscle": "deep_neck_extensors", "rationale": "Maintains neutral cervical alignment while the upper thorax is supported and the body moves as a rigid lever.", "maximum_fcsa_cm2": 84.88, "mechanical_roles": ["isometric_fixation", "limb_position_maintenance"], "tension_fraction": 0.0118, "propulsive_fcsa_cm2": 0.00, "contraction_character": ["isometric", "co_contractile"], "active_tension_exposure_cm2": 1.00, "input_contribution_classification": "primarily_stabilizing_or_load_transmitting"}], "saturated_muscles": [], "standardized_repetition": {"tempo": "controlled conventional tempo", "execution_scope": "bilateral", "range_of_motion": "full intended ROM", "proximity_to_failure": "effective repetition"}, "tension_expansion_ratio": 1.2000, "propulsive_vector_sum_cm2": 115.00, "propulsive_fcsa_demand_cm2": 115.00, "active_tension_exposure_sum_cm2": 138.00}	{"obliques": 33.62, "iliopsoas": 26.57, "rotator_cuffs": 4.00, "wrist_flexors": 2.55, "erector_spinae": 1.20, "rectus_femoris": 14.34, "gluteus_maximus": 3.40, "trapezius_lower": 1.70, "wrist_extensors": 1.28, "latissimus_dorsi": 9.66, "rectus_abdominis": 16.47, "serratus_anterior": 2.13, "triceps_long_head": 4.29, "deep_neck_extensors": 0.80, "transverse_abdominis": 2.00}	{"slug": "dragon_flag", "notes": ["The iliopsoas and rectus abdominis receive the highest modifiers because they combine substantial tension with controlled dynamic and eccentric participation, although neither receives a bonus above the neutral reference.", "The obliques receive 0.90 because their force is unusually high and mechanically specific but remains predominantly isometric.", "Rectus femoris receives a reduced modifier because hip flexion and knee extension place it in a shortened biarticular configuration.", "Latissimus dorsi and triceps long head are loaded at useful or long muscle lengths, but their role is predominantly isometric anchoring rather than dynamic shoulder or elbow movement.", "Grip, cuff, scapular, deep-abdominal, spinal, gluteal, and cervical contributions receive reduced modifiers because they are primarily stabilizing, positional, or low-ROM.", "ETU values equal active tension exposure multiplied by the listed H_m values within rounding tolerance."], "etu_sum_cm2": 124.00, "reconciliation": "PASS", "muscle_evaluation": [{"H_m": 0.9000, "muscle": "obliques", "etu_cm2": 33.62, "rationale": "The exercise creates unusually high, sustained, and mechanically specific trunk tension, supporting a modifier above ordinary stabilization. Predominantly isometric function and limited direct shortening-lengthening ROM keep it below the dynamic reference.", "normalized_etu": 0.4114, "contraction_mode": ["isometric", "eccentric", "concentric"], "high_tension_rom": "limited", "maximum_fcsa_cm2": 81.71, "smh_interpretation": "The obliques sustain high anti-extension and anti-rotation force throughout the long-lever movement, but much of the tension occurs without large fibre-length excursion.", "active_tension_exposure_cm2": 37.35, "resistance_profile_alignment": "very_good", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "mixed"}, {"H_m": 0.9500, "muscle": "iliopsoas", "etu_cm2": 26.57, "rationale": "Meaningful dynamic hip-flexion and eccentric-control tension is present, but the mixed isometric component and limited lengthened-position emphasis make the exposure slightly below the neutral reference.", "normalized_etu": 0.2599, "contraction_mode": ["concentric", "eccentric", "isometric"], "high_tension_rom": "substantial", "maximum_fcsa_cm2": 102.23, "smh_interpretation": "The iliopsoas contributes dynamically as the rigid lower body moves relative to the torso, but the exercise also requires prolonged positional hip-flexor tension and may bias the muscle toward shorter lengths near the raised position.", "active_tension_exposure_cm2": 27.97, "resistance_profile_alignment": "good", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "mixed"}, {"H_m": 0.9500, "muscle": "rectus_abdominis", "etu_cm2": 16.47, "rationale": "The exercise provides high, sustained abdominal loading with controlled eccentric and concentric phases, but its rigid-body technique limits productive fibre excursion compared with dynamic spinal-flexion training.", "normalized_etu": 0.6781, "contraction_mode": ["isometric", "eccentric", "concentric"], "high_tension_rom": "limited", "maximum_fcsa_cm2": 24.29, "smh_interpretation": "The rectus abdominis sustains very high anti-extension and posterior-pelvic-tilt tension under a long external moment arm, but spinal and pelvic excursion should remain deliberately limited.", "active_tension_exposure_cm2": 17.34, "resistance_profile_alignment": "very_good", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "mixed"}, {"H_m": 0.9000, "muscle": "rectus_femoris", "etu_cm2": 14.34, "rationale": "Substantial tension is present, but the shortened biarticular configuration and large positional component reduce hypertrophic quality relative to neutral dynamic loading.", "normalized_etu": 0.1568, "contraction_mode": ["isometric", "concentric", "eccentric"], "high_tension_rom": "limited", "maximum_fcsa_cm2": 91.44, "smh_interpretation": "The muscle helps flex the hip and hold the knee extended, but hip flexion shortens it proximally while knee extension shortens it distally, creating a shortened biarticular profile.", "active_tension_exposure_cm2": 15.93, "resistance_profile_alignment": "moderate", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "shortened"}, {"H_m": 0.8500, "muscle": "latissimus_dorsi", "etu_cm2": 9.66, "rationale": "The tension is substantial and well aligned but predominantly isometric, so the favorable muscle length does not justify a dynamic-loading bonus.", "normalized_etu": 0.2203, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 43.85, "smh_interpretation": "The elevated-arm bench grip places the latissimus at a useful length while it sustains high shoulder-extension and adduction fixation, but there is negligible productive shoulder excursion.", "active_tension_exposure_cm2": 11.36, "resistance_profile_alignment": "good", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "moderately_lengthened"}, {"H_m": 0.8500, "muscle": "triceps_long_head", "etu_cm2": 4.29, "rationale": "The muscle is tensioned at a long length, but predominantly isometric fixation and negligible elbow-extension excursion keep hypertrophic quality below the dynamic reference.", "normalized_etu": 0.0985, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 43.55, "smh_interpretation": "Shoulder elevation lengthens the long head while it stabilizes the upper arm and elbow, but the joint positions remain nearly fixed.", "active_tension_exposure_cm2": 5.05, "resistance_profile_alignment": "good", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "substantially_lengthened"}, {"H_m": 0.8000, "muscle": "rotator_cuffs", "etu_cm2": 4.00, "rationale": "Predominantly co-contractile joint stabilization with negligible productive ROM warrants the lower calibration anchor.", "normalized_etu": 0.0234, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 170.80, "smh_interpretation": "The cuff centres the humeral heads under bench-anchoring force without directly resisted rotational excursion.", "active_tension_exposure_cm2": 5.00, "resistance_profile_alignment": "poor", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "mixed"}, {"H_m": 0.8500, "muscle": "gluteus_maximus", "etu_cm2": 3.40, "rationale": "Hip-extension tension is mechanically meaningful but predominantly positional, isometric, and accessory to the abdominal task.", "normalized_etu": 0.0238, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 143.08, "smh_interpretation": "The gluteus maximus maintains hip extension and body-line rigidity without moving through directly resisted hip-extension ROM.", "active_tension_exposure_cm2": 4.00, "resistance_profile_alignment": "moderate", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "mixed"}, {"H_m": 0.8500, "muscle": "wrist_flexors", "etu_cm2": 2.55, "rationale": "Grip tension is mechanically necessary but predominantly isometric and low-ROM.", "normalized_etu": 0.0469, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 54.40, "smh_interpretation": "The hands maintain a fixed bench grip without meaningful wrist or finger excursion.", "active_tension_exposure_cm2": 3.00, "resistance_profile_alignment": "moderate", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "mixed"}, {"H_m": 0.8500, "muscle": "serratus_anterior", "etu_cm2": 2.13, "rationale": "The exposure is sustained and mechanically specific but predominantly stabilizing and low-ROM.", "normalized_etu": 0.0591, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 36.03, "smh_interpretation": "The serratus stabilizes the scapula against the thorax without broad directly resisted protraction or upward-rotation excursion.", "active_tension_exposure_cm2": 2.50, "resistance_profile_alignment": "moderate", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "mixed"}, {"H_m": 0.8000, "muscle": "transverse_abdominis", "etu_cm2": 2.00, "rationale": "Low-ROM trunk bracing represents distinctly lower hypertrophic tension quality than dynamic resistance loading.", "normalized_etu": 0.0910, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 21.97, "smh_interpretation": "The muscle provides circumferential abdominal stiffness without meaningful shortening or lengthening.", "active_tension_exposure_cm2": 2.50, "resistance_profile_alignment": "poor", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "mixed"}, {"H_m": 0.8500, "muscle": "trapezius_lower", "etu_cm2": 1.70, "rationale": "Meaningful shoulder-girdle fixation remains predominantly isometric and low-ROM.", "normalized_etu": 0.1135, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 14.98, "smh_interpretation": "The lower trapezius stabilizes scapular position without broad dynamic depression or rotation.", "active_tension_exposure_cm2": 2.00, "resistance_profile_alignment": "moderate", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "mixed"}, {"H_m": 0.8500, "muscle": "wrist_extensors", "etu_cm2": 1.28, "rationale": "The exposure supports grip integrity but remains isometric and accessory.", "normalized_etu": 0.0238, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 53.67, "smh_interpretation": "The wrist extensors stabilize a nearly fixed wrist during the bench grip.", "active_tension_exposure_cm2": 1.50, "resistance_profile_alignment": "moderate", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "mixed"}, {"H_m": 0.8000, "muscle": "erector_spinae", "etu_cm2": 1.20, "rationale": "Low-level antagonist and postural co-contraction with negligible productive ROM warrants the lower calibration anchor.", "normalized_etu": 0.0113, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 106.48, "smh_interpretation": "The spinal extensors provide segmental stiffness without directly resisted spinal-extension excursion.", "active_tension_exposure_cm2": 1.50, "resistance_profile_alignment": "poor", "duration_of_meaningful_tension": "moderate", "muscle_length_under_high_tension": "mixed"}, {"H_m": 0.8000, "muscle": "deep_neck_extensors", "etu_cm2": 0.80, "rationale": "Low-level cervical-position maintenance with negligible productive ROM warrants the lower calibration anchor.", "normalized_etu": 0.0094, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 84.88, "smh_interpretation": "The cervical spine remains neutral without loaded extension excursion.", "active_tension_exposure_cm2": 1.00, "resistance_profile_alignment": "poor", "duration_of_meaningful_tension": "moderate", "muscle_length_under_high_tension": "mixed"}], "modifier_distribution": {"mode": 0.8500, "median": 0.8500, "maximum": 0.9500, "minimum": 0.8000, "unweighted_mean": 0.8567, "tension_weighted_mean": 0.8985}, "hypertrophic_quality_ratio": 0.8985, "active_tension_exposure_sum_cm2": 138.00}	{"obliques": 1.0500, "iliopsoas": 1.0000, "rotator_cuffs": 0.9500, "wrist_flexors": 0.9500, "erector_spinae": 0.9500, "rectus_femoris": 0.9500, "gluteus_maximus": 0.9500, "trapezius_lower": 0.9500, "wrist_extensors": 0.9500, "latissimus_dorsi": 1.0000, "rectus_abdominis": 1.1000, "serratus_anterior": 0.9500, "triceps_long_head": 0.9500, "deep_neck_extensors": 0.9500, "transverse_abdominis": 0.9500}	{"slug": "dragon_flag", "notes": ["The dragon flag is dominated by high-duty-cycle trunk anti-extension demand rather than eccentric-overload mechanics.", "Rectus abdominis receives the largest recovery-cost modifier because high relative active tension coincides with sustained near-continuous isometric demand across the long body lever.", "Obliques receive a smaller elevation because their substantial continuous trunk-stabilizing tension can plausibly produce residual local force impairment, although structural eccentric stress remains minimal.", "Most secondary muscles perform low-relative-load anchoring or whole-body stabilization and therefore receive slightly sub-reference persistent recovery-cost modifiers.", "No set-duration accumulation, RIR adjustment, novelty effect, hypertrophy-specific effect, joint cost, tendon cost, neural cost, or systemic fatigue was incorporated."], "reconciliation": "PASS", "muscle_evaluation": [{"R_m": 1.0500, "muscle": "obliques", "rationale": "The obliques sustain substantial active tension throughout the long-lever body position to resist lumbar extension and loss of trunk rigidity. The high duty cycle can plausibly leave modest residual local force impairment, but the absence of severe eccentric structural loading limits the modifier to a mild elevation.", "maximum_fcsa_cm2": 81.71, "tension_fraction": 0.4571, "perfusion_constraint": "moderate", "force_development_profile": "controlled", "relative_tension_severity": "substantial", "active_tension_exposure_cm2": 37.35, "eccentric_structural_stress": "minimal", "meaningful_tension_duration": "continuous", "sustained_isometric_tension": "sustained", "dominant_recovery_mechanisms": ["high_duty_cycle_anti_extension_isometry", "local_excitation_contraction_fatigue"], "high_force_lengthening_at_long_length": "none"}, {"R_m": 1.0000, "muscle": "iliopsoas", "rationale": "Iliopsoas tension is moderate and may persist for much of the repetition while controlling hip and pelvic position, but neither the relative tension nor the lengthening mechanics are exceptional. The neutral dynamic-reference modifier is therefore appropriate.", "maximum_fcsa_cm2": 102.23, "tension_fraction": 0.2736, "perfusion_constraint": "low", "force_development_profile": "controlled", "relative_tension_severity": "moderate", "active_tension_exposure_cm2": 27.97, "eccentric_structural_stress": "standard", "meaningful_tension_duration": "prolonged", "sustained_isometric_tension": "moderate", "dominant_recovery_mechanisms": ["hip_flexion_and_lumbopelvic_control", "conventional_contractile_fatigue"], "high_force_lengthening_at_long_length": "mild"}, {"R_m": 1.1000, "muscle": "rectus_abdominis", "rationale": "Rectus abdominis operates at high relative tension while maintaining near-continuous anti-extension and posterior-pelvic-control demand across the long body lever. The combination of high relative recruitment and sustained duty cycle plausibly produces residual local force impairment beyond ordinary dynamic loading, without the structural stress required for a larger modifier.", "maximum_fcsa_cm2": 24.29, "tension_fraction": 0.7139, "perfusion_constraint": "moderate", "force_development_profile": "controlled", "relative_tension_severity": "high", "active_tension_exposure_cm2": 17.34, "eccentric_structural_stress": "minimal", "meaningful_tension_duration": "continuous", "sustained_isometric_tension": "sustained", "dominant_recovery_mechanisms": ["high_relative_tension", "sustained_high_duty_cycle_anti_extension_isometry", "local_excitation_contraction_fatigue"], "high_force_lengthening_at_long_length": "none"}, {"R_m": 0.9500, "muscle": "rectus_femoris", "rationale": "Rectus femoris contributes mainly to maintaining a rigid extended lower limb and hip position at relatively low active tension. The predominantly stabilizing exposure lacks substantial eccentric structural stress, so persistent recovery cost per unit tension is slightly below the dynamic reference.", "maximum_fcsa_cm2": 91.44, "tension_fraction": 0.1742, "perfusion_constraint": "low", "force_development_profile": "controlled", "relative_tension_severity": "low", "active_tension_exposure_cm2": 15.93, "eccentric_structural_stress": "minimal", "meaningful_tension_duration": "continuous", "sustained_isometric_tension": "moderate", "dominant_recovery_mechanisms": ["knee_extension_and_hip_position_stabilization"], "high_force_lengthening_at_long_length": "none"}, {"R_m": 1.0000, "muscle": "latissimus_dorsi", "rationale": "The latissimus contributes meaningfully to shoulder-extension torque and upper-body anchoring against the bench while experiencing moderate relative tension. Its loading is prolonged but mechanically conventional, leaving no clear reason to move away from the neutral reference.", "maximum_fcsa_cm2": 43.85, "tension_fraction": 0.2591, "perfusion_constraint": "low", "force_development_profile": "controlled", "relative_tension_severity": "moderate", "active_tension_exposure_cm2": 11.36, "eccentric_structural_stress": "standard", "meaningful_tension_duration": "prolonged", "sustained_isometric_tension": "moderate", "dominant_recovery_mechanisms": ["shoulder_extension_anchoring", "conventional_contractile_fatigue"], "high_force_lengthening_at_long_length": "mild"}, {"R_m": 0.9500, "muscle": "triceps_long_head", "rationale": "Triceps-long-head exposure is low relative to available capacity and is primarily stabilizing around the shoulder and elbow. There is no pronounced loaded lengthening or high-force eccentric mechanism to support reference-or-higher persistent recovery cost.", "maximum_fcsa_cm2": 43.55, "tension_fraction": 0.1160, "perfusion_constraint": "low", "force_development_profile": "controlled", "relative_tension_severity": "low", "active_tension_exposure_cm2": 5.05, "eccentric_structural_stress": "minimal", "meaningful_tension_duration": "prolonged", "sustained_isometric_tension": "moderate", "dominant_recovery_mechanisms": ["shoulder_extension_and_elbow_position_stabilization"], "high_force_lengthening_at_long_length": "none"}, {"R_m": 0.9500, "muscle": "rotator_cuffs", "rationale": "Rotator-cuff involvement is very low relative to available FCSA and serves primarily to stabilize the humeral head while the athlete anchors to the bench. The tension lacks a structural mechanism for substantial persistent force impairment.", "maximum_fcsa_cm2": 170.80, "tension_fraction": 0.0293, "perfusion_constraint": "low", "force_development_profile": "controlled", "relative_tension_severity": "low", "active_tension_exposure_cm2": 5.00, "eccentric_structural_stress": "minimal", "meaningful_tension_duration": "prolonged", "sustained_isometric_tension": "intermittent", "dominant_recovery_mechanisms": ["glenohumeral_stabilization"], "high_force_lengthening_at_long_length": "none"}, {"R_m": 0.9500, "muscle": "gluteus_maximus", "rationale": "Gluteus-maximus exposure is very small relative to available capacity and consists mainly of isometric maintenance of hip extension and whole-body rigidity. Persistent recovery burden per unit tension is therefore slightly below conventional dynamic work.", "maximum_fcsa_cm2": 143.08, "tension_fraction": 0.0280, "perfusion_constraint": "low", "force_development_profile": "controlled", "relative_tension_severity": "low", "active_tension_exposure_cm2": 4.00, "eccentric_structural_stress": "minimal", "meaningful_tension_duration": "continuous", "sustained_isometric_tension": "moderate", "dominant_recovery_mechanisms": ["hip_extension_and_body_line_stabilization"], "high_force_lengthening_at_long_length": "none"}, {"R_m": 0.9500, "muscle": "wrist_flexors", "rationale": "Wrist-flexor activity is low-relative-load grip stabilization against the bench. It lacks substantial structural stress and is unlikely to produce reference-level persistent recovery burden per unit tension.", "maximum_fcsa_cm2": 54.40, "tension_fraction": 0.0551, "perfusion_constraint": "low", "force_development_profile": "controlled", "relative_tension_severity": "low", "active_tension_exposure_cm2": 3.00, "eccentric_structural_stress": "minimal", "meaningful_tension_duration": "prolonged", "sustained_isometric_tension": "intermittent", "dominant_recovery_mechanisms": ["bench_grip_stabilization"], "high_force_lengthening_at_long_length": "none"}, {"R_m": 0.9500, "muscle": "serratus_anterior", "rationale": "Serratus-anterior loading is low and primarily stabilizes scapular position against the bench and shoulder forces. No unusual eccentric or high-force mechanism is present.", "maximum_fcsa_cm2": 36.03, "tension_fraction": 0.0694, "perfusion_constraint": "low", "force_development_profile": "controlled", "relative_tension_severity": "low", "active_tension_exposure_cm2": 2.50, "eccentric_structural_stress": "minimal", "meaningful_tension_duration": "prolonged", "sustained_isometric_tension": "intermittent", "dominant_recovery_mechanisms": ["scapular_stabilization"], "high_force_lengthening_at_long_length": "none"}, {"R_m": 0.9500, "muscle": "transverse_abdominis", "rationale": "Transverse-abdominal activity is continuous but low relative to available capacity and primarily supports abdominal bracing. The duty cycle may contribute acute fatigue, but not enough persistent force deficit to justify the dynamic reference.", "maximum_fcsa_cm2": 21.97, "tension_fraction": 0.1138, "perfusion_constraint": "low", "force_development_profile": "controlled", "relative_tension_severity": "low", "active_tension_exposure_cm2": 2.50, "eccentric_structural_stress": "minimal", "meaningful_tension_duration": "continuous", "sustained_isometric_tension": "moderate", "dominant_recovery_mechanisms": ["abdominal_bracing"], "high_force_lengthening_at_long_length": "none"}, {"R_m": 0.9500, "muscle": "trapezius_lower", "rationale": "Lower-trapezius involvement is low and predominantly stabilizing, without severe loaded stretch, eccentric overload, or sustained high-force occlusion.", "maximum_fcsa_cm2": 14.98, "tension_fraction": 0.1335, "perfusion_constraint": "low", "force_development_profile": "controlled", "relative_tension_severity": "low", "active_tension_exposure_cm2": 2.00, "eccentric_structural_stress": "minimal", "meaningful_tension_duration": "prolonged", "sustained_isometric_tension": "intermittent", "dominant_recovery_mechanisms": ["scapular_stabilization"], "high_force_lengthening_at_long_length": "none"}, {"R_m": 0.9500, "muscle": "erector_spinae", "rationale": "Erector-spinae exposure is extremely low relative to available FCSA and represents postural stabilization rather than substantial dynamic spinal loading.", "maximum_fcsa_cm2": 106.48, "tension_fraction": 0.0141, "perfusion_constraint": "low", "force_development_profile": "controlled", "relative_tension_severity": "low", "active_tension_exposure_cm2": 1.50, "eccentric_structural_stress": "minimal", "meaningful_tension_duration": "continuous", "sustained_isometric_tension": "intermittent", "dominant_recovery_mechanisms": ["spinal_position_stabilization"], "high_force_lengthening_at_long_length": "none"}, {"R_m": 0.9500, "muscle": "wrist_extensors", "rationale": "Wrist-extensor tension is minimal and stabilizing, with no meaningful structural or high-force metabolic mechanism expected to leave persistent local force impairment.", "maximum_fcsa_cm2": 53.67, "tension_fraction": 0.0279, "perfusion_constraint": "low", "force_development_profile": "controlled", "relative_tension_severity": "low", "active_tension_exposure_cm2": 1.50, "eccentric_structural_stress": "minimal", "meaningful_tension_duration": "prolonged", "sustained_isometric_tension": "intermittent", "dominant_recovery_mechanisms": ["wrist_stabilization"], "high_force_lengthening_at_long_length": "none"}, {"R_m": 0.9500, "muscle": "deep_neck_extensors", "rationale": "Deep-neck-extensor exposure is negligible relative to available FCSA and reflects postural stabilization only. Persistent recovery burden per unit tension is therefore slightly below reference.", "maximum_fcsa_cm2": 84.88, "tension_fraction": 0.0118, "perfusion_constraint": "low", "force_development_profile": "controlled", "relative_tension_severity": "low", "active_tension_exposure_cm2": 1.00, "eccentric_structural_stress": "minimal", "meaningful_tension_duration": "continuous", "sustained_isometric_tension": "intermittent", "dominant_recovery_mechanisms": ["head_and_neck_position_stabilization"], "high_force_lengthening_at_long_length": "none"}], "modifier_distribution": {"mode": 0.9500, "median": 0.9500, "maximum": 1.1000, "minimum": 0.9500, "unweighted_mean": 0.9733, "tension_weighted_mean": 1.0102}, "standardized_repetition": {"tempo": "controlled conventional tempo", "range_of_motion": "full intended ROM", "proximity_to_failure": "effective repetition"}, "active_tension_exposure_sum_cm2": 138.00}	{"hip_joint": 0.5200, "elbow_joint": 0.1400, "lumbar_spine": 0.6800, "radiocarpal_joint": 0.1000, "glenohumeral_joint": 0.4600, "scapulothoracic_articulation": 0.3600}	{"slug": "dragon_flag", "notes": ["The 55 kg load capacity represents the effective unsupported body-segment mass contributing to the long lever rather than an external implement.", "The defining mechanical demand is anti-extension of the lumbopelvic region under a very long body lever, not repeated loaded lumbar flexion.", "Compared with hanging leg-raise variants, the dragon flag shifts relatively more demand toward trunk anti-extension and upper-body anchoring while reducing the importance of large dynamic hip-flexion ROM."], "loaded_joints": ["lumbar_spine", "hip_joint", "glenohumeral_joint", "scapulothoracic_articulation", "elbow_joint", "radiocarpal_joint"], "reconciliation": "PASS", "joint_evaluation": [{"joint": "lumbar_spine", "rationale": "The lumbar spine is a primary loaded region because the long body lever creates a large external extension moment that must be resisted by the abdominal wall and spinal stabilizers. Proper execution maintains the trunk relatively rigid rather than repeatedly flexing the lumbar spine, so exposure is dominated by anti-extension torque, high trunk co-contraction, compression, and shear control. Relative to conventional trunk exercises, the long unsupported lever produces substantial lumbar mechanical exposure despite the absence of large external weight.", "load_exposure": 0.6800, "loaded_joint_position": "favorable", "primary_loading_modes": ["net_joint_moment", "compression", "shear", "co_contraction", "stabilization"], "net_joint_moment_demand": "high", "stabilization_requirement": "high", "shear_translation_or_rotation": "moderate", "muscle_force_and_joint_reaction": "high"}, {"joint": "hip_joint", "rationale": "The hips transmit the moment generated by the long lower-body lever and require substantial hip-flexor and lumbopelvic muscular force to maintain body alignment and control the descent. Iliopsoas and other hip-crossing muscles contribute meaningful joint reaction and compression. Hip motion is usually limited compared with a leg raise, so exposure is substantial but below exercises dominated by large dynamic hip-flexion or extension moments.", "load_exposure": 0.5200, "loaded_joint_position": "mid_range", "primary_loading_modes": ["net_joint_moment", "compression", "muscle_force_transmission", "stabilization"], "net_joint_moment_demand": "moderate", "stabilization_requirement": "high", "shear_translation_or_rotation": "low", "muscle_force_and_joint_reaction": "high"}, {"joint": "glenohumeral_joint", "rationale": "The hands anchor the athlete to the bench while the shoulders transmit substantial counterforce needed to balance the body lever. The glenohumeral joints remain in an elevated and relatively constrained position while shoulder musculature and rotator cuffs stabilize the humeral heads against the large reaction forces generated by the trunk and lower limbs. Exposure is meaningful but remains below heavy pressing, pulling, or full bodyweight suspension patterns.", "load_exposure": 0.4600, "loaded_joint_position": "demanding", "primary_loading_modes": ["muscle_force_transmission", "stabilization", "translation"], "net_joint_moment_demand": "moderate", "stabilization_requirement": "high", "shear_translation_or_rotation": "moderate", "muscle_force_and_joint_reaction": "high"}, {"joint": "scapulothoracic_articulation", "rationale": "The scapulae must remain strongly fixed against the thorax while upper-limb anchoring forces counter the torque generated by the extended body. This creates meaningful functional scapulothoracic loading through fixation and force transmission, although scapular excursion itself is limited.", "load_exposure": 0.3600, "loaded_joint_position": "demanding", "primary_loading_modes": ["muscle_force_transmission", "stabilization"], "net_joint_moment_demand": "moderate", "stabilization_requirement": "high", "shear_translation_or_rotation": "low", "muscle_force_and_joint_reaction": "moderate"}, {"joint": "elbow_joint", "rationale": "The elbows are generally held in a relatively fixed flexed position while the arms anchor to the bench. They transmit meaningful force from the hands to the shoulders, but there is little intended dynamic elbow motion and only modest local flexion-extension moment.", "load_exposure": 0.1400, "loaded_joint_position": "favorable", "primary_loading_modes": ["muscle_force_transmission", "stabilization"], "net_joint_moment_demand": "low", "stabilization_requirement": "moderate", "shear_translation_or_rotation": "minimal", "muscle_force_and_joint_reaction": "moderate"}, {"joint": "radiocarpal_joint", "rationale": "The wrists mainly transmit gripping and anchoring forces while the hands hold the bench. Direct wrist flexion or extension torque is limited when the grip permits a near-neutral position, leaving radiocarpal exposure low.", "load_exposure": 0.1000, "loaded_joint_position": "favorable", "primary_loading_modes": ["muscle_force_transmission", "stabilization"], "net_joint_moment_demand": "minimal", "stabilization_requirement": "moderate", "shear_translation_or_rotation": "minimal", "muscle_force_and_joint_reaction": "low"}], "maximum_exposure_joint": "lumbar_spine", "standardized_repetition": {"tempo": "controlled conventional tempo", "range_of_motion": "full intended ROM", "proximity_to_failure": "effective repetition"}}
weighted_russian_twist	15.00	63.45	{"obliques": 42.52, "iliopsoas": 14.17, "rectus_abdominis": 6.76}	{"obliques": 42.52, "iliopsoas": 14.17, "erector_spinae": 3.00, "gluteus_medius": 2.00, "gluteus_maximus": 1.50, "rectus_abdominis": 6.76, "deep_neck_extensors": 0.80, "transverse_abdominis": 2.50, "adductor_longus_brevis": 1.50}	{"slug": "weighted_russian_twist", "notes": ["The supplied contribution vector sums exactly to the systemic propulsive FCSA demand.", "The obliques were treated as the principal dynamic rotators, while the iliopsoas and rectus abdominis were interpreted primarily as reclined-position and trunk-bracing contributors.", "The principal rotational and hip-flexor demands were already represented and were not expanded mechanically a second time.", "Additional exposure was limited to spinal co-contraction, deep abdominal stiffness, pelvic and femoral stabilization, and cervical-position maintenance.", "The exercise is modeled as controlled trunk rotation rather than merely moving the weight with the arms, and without ballistic rebound or excessive lumbar flexion."], "added_muscles": ["erector_spinae", "transverse_abdominis", "gluteus_medius", "adductor_longus_brevis", "gluteus_maximus", "deep_neck_extensors"], "reconciliation": "PASS", "muscle_evaluation": [{"muscle": "obliques", "rationale": "Produces the dominant alternating trunk-rotation torque, eccentrically controls reversal between sides, and maintains sufficient abdominal stiffness to preserve the reclined torso position. The supplied contribution already represents its complete dynamic and bracing force state.", "maximum_fcsa_cm2": 81.71, "mechanical_roles": ["propulsive", "eccentric_control", "trunk_bracing", "multi_joint_control"], "tension_fraction": 0.5204, "propulsive_fcsa_cm2": 42.52, "contraction_character": ["dynamic_concentric", "dynamic_eccentric", "isometric", "co_contractile"], "active_tension_exposure_cm2": 42.52, "input_contribution_classification": "primarily_propulsive"}, {"muscle": "iliopsoas", "rationale": "Maintains the reclined trunk-to-thigh angle and stabilizes the pelvis against the posterior gravitational moment. The supplied contribution is treated as the complete high-force hip-flexor holding demand rather than dynamic hip flexion.", "maximum_fcsa_cm2": 102.23, "mechanical_roles": ["limb_position_maintenance", "trunk_bracing", "isometric_fixation", "load_transmission"], "tension_fraction": 0.1386, "propulsive_fcsa_cm2": 14.17, "contraction_character": ["isometric", "co_contractile"], "active_tension_exposure_cm2": 14.17, "input_contribution_classification": "primarily_stabilizing_or_load_transmitting"}, {"muscle": "rectus_abdominis", "rationale": "Maintains the flexed or neutral ribcage-to-pelvis relationship and resists lumbar extension while permitting controlled transverse-plane motion. Any shortening and lengthening is secondary to its sustained bracing role, so the supplied value is retained unchanged.", "maximum_fcsa_cm2": 24.29, "mechanical_roles": ["trunk_bracing", "isometric_fixation", "load_transmission", "multi_joint_control"], "tension_fraction": 0.2783, "propulsive_fcsa_cm2": 6.76, "contraction_character": ["isometric", "co_contractile", "dynamic_concentric", "dynamic_eccentric"], "active_tension_exposure_cm2": 6.76, "input_contribution_classification": "mixed_propulsive_and_stabilizing"}, {"muscle": "erector_spinae", "rationale": "Co-contracts with the abdominal wall to preserve spinal length and prevent uncontrolled flexion while the trunk rotates in a reclined position.", "maximum_fcsa_cm2": 106.48, "mechanical_roles": ["trunk_bracing", "antagonist_co_contraction", "isometric_fixation", "multi_joint_control"], "tension_fraction": 0.0282, "propulsive_fcsa_cm2": 0.00, "contraction_character": ["isometric", "co_contractile", "dynamic_eccentric"], "active_tension_exposure_cm2": 3.00, "input_contribution_classification": "primarily_stabilizing_or_load_transmitting"}, {"muscle": "transverse_abdominis", "rationale": "Provides circumferential abdominal stiffness and helps transmit rotational force between the ribcage and pelvis without visible fibre excursion.", "maximum_fcsa_cm2": 21.97, "mechanical_roles": ["trunk_bracing", "isometric_fixation", "load_transmission", "multi_joint_control"], "tension_fraction": 0.1138, "propulsive_fcsa_cm2": 0.00, "contraction_character": ["isometric", "co_contractile"], "active_tension_exposure_cm2": 2.50, "input_contribution_classification": "primarily_stabilizing_or_load_transmitting"}, {"muscle": "gluteus_medius", "rationale": "Maintains pelvic and femoral alignment while the upper trunk rotates relative to a comparatively stable seated base.", "maximum_fcsa_cm2": 113.75, "mechanical_roles": ["joint_stabilization", "limb_position_maintenance", "isometric_fixation"], "tension_fraction": 0.0176, "propulsive_fcsa_cm2": 0.00, "contraction_character": ["isometric", "co_contractile"], "active_tension_exposure_cm2": 2.00, "input_contribution_classification": "primarily_stabilizing_or_load_transmitting"}, {"muscle": "adductor_longus_brevis", "rationale": "Helps maintain bilateral thigh and pelvic alignment and limits unwanted hip abduction or external rotation during alternating trunk rotation.", "maximum_fcsa_cm2": 66.55, "mechanical_roles": ["joint_stabilization", "limb_position_maintenance", "antagonist_co_contraction", "isometric_fixation"], "tension_fraction": 0.0225, "propulsive_fcsa_cm2": 0.00, "contraction_character": ["isometric", "co_contractile"], "active_tension_exposure_cm2": 1.50, "input_contribution_classification": "primarily_stabilizing_or_load_transmitting"}, {"muscle": "gluteus_maximus", "rationale": "Provides low-level posterior pelvic and hip stabilization while the seated base resists alternating rotational force.", "maximum_fcsa_cm2": 143.08, "mechanical_roles": ["joint_stabilization", "limb_position_maintenance", "isometric_fixation"], "tension_fraction": 0.0105, "propulsive_fcsa_cm2": 0.00, "contraction_character": ["isometric", "co_contractile"], "active_tension_exposure_cm2": 1.50, "input_contribution_classification": "primarily_stabilizing_or_load_transmitting"}, {"muscle": "deep_neck_extensors", "rationale": "Maintains neutral head and cervical alignment while the thorax rotates beneath the head and the weighted hands move from side to side.", "maximum_fcsa_cm2": 84.88, "mechanical_roles": ["isometric_fixation", "limb_position_maintenance", "multi_joint_control"], "tension_fraction": 0.0094, "propulsive_fcsa_cm2": 0.00, "contraction_character": ["isometric", "co_contractile"], "active_tension_exposure_cm2": 0.80, "input_contribution_classification": "primarily_stabilizing_or_load_transmitting"}], "saturated_muscles": [], "standardized_repetition": {"tempo": "controlled conventional tempo", "technique": "seated reclined torso with controlled alternating rotation and no ballistic arm swing", "execution_scope": "bilateral", "range_of_motion": "full intended controlled trunk-rotation ROM", "proximity_to_failure": "effective repetition"}, "tension_expansion_ratio": 1.1781, "propulsive_vector_sum_cm2": 63.45, "propulsive_fcsa_demand_cm2": 63.45, "active_tension_exposure_sum_cm2": 74.75}	{"obliques": 42.52, "iliopsoas": 12.04, "erector_spinae": 2.55, "gluteus_medius": 1.70, "gluteus_maximus": 1.28, "rectus_abdominis": 5.75, "deep_neck_extensors": 0.64, "transverse_abdominis": 2.00, "adductor_longus_brevis": 1.28}	{"slug": "weighted_russian_twist", "notes": ["The obliques remain at the neutral dynamic reference because they perform the principal concentric and eccentric rotational work through meaningful ROM while also sustaining continuous bracing.", "No positive modifier was applied because the movement does not provide a clear muscle-specific long-length loading advantage or externally enhanced eccentric overload.", "The iliopsoas, rectus abdominis, erector spinae, and pelvic stabilizers receive 0.85 because their exposure is substantial or mechanically relevant but predominantly isometric.", "The transverse abdominis and deep neck extensors receive the minimum modifier because their roles consist almost entirely of low-ROM bracing or positional stabilization.", "ETU values equal active tension exposure multiplied by the listed H_m values within rounding tolerance."], "etu_sum_cm2": 69.75, "reconciliation": "PASS", "muscle_evaluation": [{"H_m": 1.0000, "muscle": "obliques", "etu_cm2": 42.52, "rationale": "The obliques receive substantial, directly aligned concentric and eccentric rotational loading through meaningful ROM, balanced by a large isometric bracing component. This supports the neutral dynamic reference without an additional long-length bonus.", "normalized_etu": 0.5204, "contraction_mode": ["concentric", "eccentric", "isometric"], "high_tension_rom": "substantial", "maximum_fcsa_cm2": 81.71, "smh_interpretation": "Alternating trunk rotation produces repeated shortening and lengthening of opposing oblique systems while the reclined posture maintains continuous background abdominal tension.", "active_tension_exposure_cm2": 42.52, "resistance_profile_alignment": "good", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "mixed"}, {"H_m": 0.8500, "muscle": "iliopsoas", "etu_cm2": 12.04, "rationale": "The hip-flexor demand is substantial and sustained but predominantly isometric and positional.", "normalized_etu": 0.1178, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 102.23, "smh_interpretation": "The iliopsoas sustains the reclined torso-to-thigh angle but undergoes little deliberate hip-flexion excursion.", "active_tension_exposure_cm2": 14.17, "resistance_profile_alignment": "good", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "mixed"}, {"H_m": 0.8500, "muscle": "rectus_abdominis", "etu_cm2": 5.75, "rationale": "The muscle experiences meaningful abdominal tension, but its role remains predominantly isometric bracing rather than loaded spinal flexion through broad ROM.", "normalized_etu": 0.2367, "contraction_mode": ["isometric", "concentric", "eccentric"], "high_tension_rom": "limited", "maximum_fcsa_cm2": 24.29, "smh_interpretation": "The rectus abdominis maintains the reclined trunk position and limits lumbar extension, with only minor dynamic fibre excursion during rotation.", "active_tension_exposure_cm2": 6.76, "resistance_profile_alignment": "moderate", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "mixed"}, {"H_m": 0.8500, "muscle": "erector_spinae", "etu_cm2": 2.55, "rationale": "The exposure is sustained and mechanically relevant but predominantly co-contractile, isometric, and low-ROM.", "normalized_etu": 0.0239, "contraction_mode": ["isometric", "eccentric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 106.48, "smh_interpretation": "The spinal extensors preserve spinal length and regulate rotation without directly resisted extension through substantial ROM.", "active_tension_exposure_cm2": 3.00, "resistance_profile_alignment": "moderate", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "mixed"}, {"H_m": 0.8000, "muscle": "transverse_abdominis", "etu_cm2": 2.00, "rationale": "Deep low-ROM trunk bracing with negligible productive fibre excursion warrants the lower calibration anchor.", "normalized_etu": 0.0910, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 21.97, "smh_interpretation": "The muscle provides circumferential abdominal stiffness without meaningful shortening or lengthening.", "active_tension_exposure_cm2": 2.50, "resistance_profile_alignment": "poor", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "mixed"}, {"H_m": 0.8500, "muscle": "gluteus_medius", "etu_cm2": 1.70, "rationale": "The exposure is positional, isometric, and accessory to trunk rotation.", "normalized_etu": 0.0149, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 113.75, "smh_interpretation": "The muscle stabilizes the pelvis without directly resisted hip-abduction excursion.", "active_tension_exposure_cm2": 2.00, "resistance_profile_alignment": "moderate", "duration_of_meaningful_tension": "moderate", "muscle_length_under_high_tension": "mixed"}, {"H_m": 0.8500, "muscle": "adductor_longus_brevis", "etu_cm2": 1.28, "rationale": "The exposure is positional, stabilizing, and low-ROM.", "normalized_etu": 0.0192, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 66.55, "smh_interpretation": "The adductors maintain thigh and pelvic alignment without dynamic loaded adduction.", "active_tension_exposure_cm2": 1.50, "resistance_profile_alignment": "moderate", "duration_of_meaningful_tension": "moderate", "muscle_length_under_high_tension": "mixed"}, {"H_m": 0.8500, "muscle": "gluteus_maximus", "etu_cm2": 1.28, "rationale": "The exposure is low-level, positional, and isometric.", "normalized_etu": 0.0089, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 143.08, "smh_interpretation": "The muscle stabilizes the pelvis and hip without dynamic hip-extension excursion.", "active_tension_exposure_cm2": 1.50, "resistance_profile_alignment": "moderate", "duration_of_meaningful_tension": "moderate", "muscle_length_under_high_tension": "mixed"}, {"H_m": 0.8000, "muscle": "deep_neck_extensors", "etu_cm2": 0.64, "rationale": "Low-level cervical-position maintenance with negligible productive ROM warrants the lower calibration anchor.", "normalized_etu": 0.0075, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 84.88, "smh_interpretation": "The cervical spine remains neutral while the thorax rotates beneath the head.", "active_tension_exposure_cm2": 0.80, "resistance_profile_alignment": "poor", "duration_of_meaningful_tension": "moderate", "muscle_length_under_high_tension": "mixed"}], "modifier_distribution": {"mode": 0.8500, "median": 0.8500, "maximum": 1.0000, "minimum": 0.8000, "unweighted_mean": 0.8556, "tension_weighted_mean": 0.9331}, "hypertrophic_quality_ratio": 0.9331, "active_tension_exposure_sum_cm2": 74.75}	{"obliques": 1.0500, "iliopsoas": 0.9500, "erector_spinae": 0.9500, "gluteus_medius": 0.9500, "gluteus_maximus": 0.9500, "rectus_abdominis": 0.9500, "deep_neck_extensors": 0.9500, "transverse_abdominis": 0.9500, "adductor_longus_brevis": 0.9500}	{"slug": "weighted_russian_twist", "notes": ["The obliques are the only muscle group with a clear above-reference recovery-cost mechanism because substantial active tension is combined with repeated production and braking of loaded trunk rotation.", "The alternating rotational action creates conventional eccentric loading of the oblique complex, but not the severe long-length or eccentric-overload conditions required for a large modifier.", "Iliopsoas, rectus abdominis, transverse abdominis, spinal extensors, and hip stabilizers primarily maintain posture and pelvic position and therefore receive slightly sub-reference modifiers.", "No eccentric overload, exaggerated tempo, runtime volume effect, RIR effect, novelty effect, hypertrophy-specific factor, joint cost, tendon cost, systemic fatigue, or neural recovery cost was incorporated."], "reconciliation": "PASS", "muscle_evaluation": [{"R_m": 1.0500, "muscle": "obliques", "rationale": "The obliques bear substantial relative active tension while repeatedly producing and braking trunk rotation. Each rotational direction imposes controlled eccentric loading on the contralateral rotational musculature, but the loading remains conventional and does not involve severe long-length eccentric stress. A mild persistent recovery premium is therefore appropriate.", "maximum_fcsa_cm2": 81.71, "tension_fraction": 0.5204, "perfusion_constraint": "low", "force_development_profile": "controlled", "relative_tension_severity": "substantial", "active_tension_exposure_cm2": 42.52, "eccentric_structural_stress": "standard", "meaningful_tension_duration": "reference", "sustained_isometric_tension": "none", "dominant_recovery_mechanisms": ["substantial_relative_tension", "alternating_loaded_trunk_rotation", "controlled_eccentric_rotation"], "high_force_lengthening_at_long_length": "mild"}, {"R_m": 0.9500, "muscle": "iliopsoas", "rationale": "Iliopsoas tension is low relative to available FCSA and is predominantly used to maintain the flexed-hip seated position while the trunk rotates. This largely isometric exposure lacks meaningful eccentric structural stress and is expected to produce slightly less persistent recovery burden per unit tension than conventional dynamic loading.", "maximum_fcsa_cm2": 102.23, "tension_fraction": 0.1386, "perfusion_constraint": "low", "force_development_profile": "controlled", "relative_tension_severity": "low", "active_tension_exposure_cm2": 14.17, "eccentric_structural_stress": "minimal", "meaningful_tension_duration": "continuous", "sustained_isometric_tension": "moderate", "dominant_recovery_mechanisms": ["hip_flexion_and_pelvic_position_stabilization"], "high_force_lengthening_at_long_length": "none"}, {"R_m": 0.9500, "muscle": "rectus_abdominis", "rationale": "Rectus-abdominis involvement is primarily continuous stabilization of trunk inclination rather than substantial dynamic shortening and lengthening. Relative tension is moderate, but there is no strong mechanism for a persistent force deficit beyond the acute fatigue associated with sustained bracing.", "maximum_fcsa_cm2": 24.29, "tension_fraction": 0.2783, "perfusion_constraint": "low", "force_development_profile": "controlled", "relative_tension_severity": "moderate", "active_tension_exposure_cm2": 6.76, "eccentric_structural_stress": "minimal", "meaningful_tension_duration": "continuous", "sustained_isometric_tension": "moderate", "dominant_recovery_mechanisms": ["trunk_flexion_and_anti_extension_stabilization"], "high_force_lengthening_at_long_length": "none"}, {"R_m": 0.9500, "muscle": "erector_spinae", "rationale": "Erector-spinae exposure is very low relative to available capacity and serves primarily to stabilize spinal position during rotation. The tension lacks meaningful dynamic structural loading.", "maximum_fcsa_cm2": 106.48, "tension_fraction": 0.0282, "perfusion_constraint": "low", "force_development_profile": "controlled", "relative_tension_severity": "low", "active_tension_exposure_cm2": 3.00, "eccentric_structural_stress": "minimal", "meaningful_tension_duration": "continuous", "sustained_isometric_tension": "intermittent", "dominant_recovery_mechanisms": ["spinal_position_stabilization"], "high_force_lengthening_at_long_length": "none"}, {"R_m": 0.9500, "muscle": "transverse_abdominis", "rationale": "Transverse-abdominal activity is low-relative-load continuous bracing. The exposure may contribute to acute local fatigue but lacks a structural or high-force mechanism expected to create substantial persistent recovery burden.", "maximum_fcsa_cm2": 21.97, "tension_fraction": 0.1138, "perfusion_constraint": "low", "force_development_profile": "controlled", "relative_tension_severity": "low", "active_tension_exposure_cm2": 2.50, "eccentric_structural_stress": "minimal", "meaningful_tension_duration": "continuous", "sustained_isometric_tension": "moderate", "dominant_recovery_mechanisms": ["abdominal_bracing"], "high_force_lengthening_at_long_length": "none"}, {"R_m": 0.9500, "muscle": "gluteus_medius", "rationale": "Gluteus-medius exposure is negligible relative to available FCSA and consists of seated pelvic stabilization rather than meaningful dynamic hip loading.", "maximum_fcsa_cm2": 113.75, "tension_fraction": 0.0176, "perfusion_constraint": "low", "force_development_profile": "controlled", "relative_tension_severity": "low", "active_tension_exposure_cm2": 2.00, "eccentric_structural_stress": "minimal", "meaningful_tension_duration": "continuous", "sustained_isometric_tension": "intermittent", "dominant_recovery_mechanisms": ["pelvic_stabilization"], "high_force_lengthening_at_long_length": "none"}, {"R_m": 0.9500, "muscle": "gluteus_maximus", "rationale": "Gluteus-maximus involvement is minimal and stabilizing. There is no meaningful hip excursion, high relative tension, or loaded lengthening to support reference-level persistent recovery cost.", "maximum_fcsa_cm2": 143.08, "tension_fraction": 0.0105, "perfusion_constraint": "low", "force_development_profile": "controlled", "relative_tension_severity": "low", "active_tension_exposure_cm2": 1.50, "eccentric_structural_stress": "minimal", "meaningful_tension_duration": "continuous", "sustained_isometric_tension": "intermittent", "dominant_recovery_mechanisms": ["pelvic_and_hip_position_stabilization"], "high_force_lengthening_at_long_length": "none"}, {"R_m": 0.9500, "muscle": "adductor_longus_brevis", "rationale": "Adductor longus and brevis contribute very low-relative-load stabilization of the hips and pelvis. Their exposure lacks meaningful eccentric or high-force structural loading.", "maximum_fcsa_cm2": 66.55, "tension_fraction": 0.0225, "perfusion_constraint": "low", "force_development_profile": "controlled", "relative_tension_severity": "low", "active_tension_exposure_cm2": 1.50, "eccentric_structural_stress": "minimal", "meaningful_tension_duration": "continuous", "sustained_isometric_tension": "intermittent", "dominant_recovery_mechanisms": ["hip_and_pelvic_stabilization"], "high_force_lengthening_at_long_length": "none"}, {"R_m": 0.9500, "muscle": "deep_neck_extensors", "rationale": "Deep-neck-extensor exposure is negligible relative to available FCSA and reflects low-level postural stabilization only. No mechanism supports reference-or-higher persistent recovery cost.", "maximum_fcsa_cm2": 84.88, "tension_fraction": 0.0094, "perfusion_constraint": "low", "force_development_profile": "controlled", "relative_tension_severity": "low", "active_tension_exposure_cm2": 0.80, "eccentric_structural_stress": "minimal", "meaningful_tension_duration": "continuous", "sustained_isometric_tension": "intermittent", "dominant_recovery_mechanisms": ["head_and_neck_postural_stabilization"], "high_force_lengthening_at_long_length": "none"}], "modifier_distribution": {"mode": 0.9500, "median": 0.9500, "maximum": 1.0500, "minimum": 0.9500, "unweighted_mean": 0.9611, "tension_weighted_mean": 1.0069}, "standardized_repetition": {"tempo": "controlled conventional tempo", "range_of_motion": "full intended ROM", "proximity_to_failure": "effective repetition"}, "active_tension_exposure_sum_cm2": 74.75}	{"hip_joint": 0.2800, "lumbar_spine": 0.6200}	{"slug": "weighted_russian_twist", "notes": ["The defining mechanical demand is loaded trunk rotation performed from an unsupported reclined seated position.", "Lumbar exposure is driven by the interaction of axial rotation, rotational shear, abdominal and spinal co-contraction, and anti-extension stabilization rather than by pure sagittal-plane spinal flexion.", "Hip exposure remains secondary and primarily reflects maintenance of pelvic position and resistance to unwanted rotation."], "loaded_joints": ["lumbar_spine", "hip_joint"], "reconciliation": "PASS", "joint_evaluation": [{"joint": "lumbar_spine", "rationale": "The lumbar spine is the primary loaded region because the 15 kg external resistance is rotated across the body while the trunk is held in a reclined seated position. This creates a substantial axial-rotation moment superimposed on an anti-extension and trunk-flexion stabilization demand. The obliques, abdominal wall, and spinal stabilizers generate high force and co-contraction, producing meaningful compression and rotational shear while the spine is held away from a fully supported neutral posture. Relative to conventional trunk exercises, the combination of loaded rotation and unsupported reclined trunk position produces substantial lumbar mechanical exposure.", "load_exposure": 0.6200, "loaded_joint_position": "demanding", "primary_loading_modes": ["rotation", "shear", "compression", "co_contraction", "stabilization"], "net_joint_moment_demand": "high", "stabilization_requirement": "high", "shear_translation_or_rotation": "moderate", "muscle_force_and_joint_reaction": "high"}, {"joint": "hip_joint", "rationale": "The hips remain flexed while the pelvis provides a base for the rotating trunk. Hip flexors and pelvic stabilizers must maintain the reclined torso position and resist unwanted pelvic rotation, producing moderate joint reaction and stabilization demand. However, there is little large-amplitude dynamic hip motion or high direct hip torque, so exposure remains secondary to the lumbar spine.", "load_exposure": 0.2800, "loaded_joint_position": "demanding", "primary_loading_modes": ["stabilization", "rotation", "muscle_force_transmission"], "net_joint_moment_demand": "low", "stabilization_requirement": "high", "shear_translation_or_rotation": "low", "muscle_force_and_joint_reaction": "moderate"}], "maximum_exposure_joint": "lumbar_spine", "standardized_repetition": {"tempo": "controlled conventional tempo", "range_of_motion": "full intended ROM", "proximity_to_failure": "effective repetition"}}

--
-- Name: exercises_id_seq; Type: SEQUENCE SET; Schema: core; Owner: kartezjusz
--

SELECT pg_catalog.setval('core.exercises_id_seq', 49, true);


--
-- Name: muscles_id_seq; Type: SEQUENCE SET; Schema: core; Owner: kartezjusz
--

SELECT pg_catalog.setval('core.muscles_id_seq', 47, true);


--
-- Name: exercises exercises_name_full_key; Type: CONSTRAINT; Schema: core; Owner: kartezjusz
--

ALTER TABLE ONLY core.exercises
    ADD CONSTRAINT exercises_name_full_key UNIQUE (name_full);


--
-- Name: exercises exercises_name_key; Type: CONSTRAINT; Schema: core; Owner: kartezjusz
--

ALTER TABLE ONLY core.exercises
    ADD CONSTRAINT exercises_name_key UNIQUE (name);


--
-- Name: exercises exercises_pkey; Type: CONSTRAINT; Schema: core; Owner: kartezjusz
--

ALTER TABLE ONLY core.exercises
    ADD CONSTRAINT exercises_pkey PRIMARY KEY (id);


--
-- Name: exercises exercises_slug_key; Type: CONSTRAINT; Schema: core; Owner: kartezjusz
--

ALTER TABLE ONLY core.exercises
    ADD CONSTRAINT exercises_slug_key UNIQUE (slug);


--
-- Name: muscle_exercise_mappings muscle_exercise_mappings_pkey; Type: CONSTRAINT; Schema: core; Owner: kartezjusz
--

ALTER TABLE ONLY core.muscle_exercise_mappings
    ADD CONSTRAINT muscle_exercise_mappings_pkey PRIMARY KEY (muscle_id, exercise_id, resistance_profile, complexity);


--
-- Name: muscles muscles_name_key; Type: CONSTRAINT; Schema: core; Owner: kartezjusz
--

ALTER TABLE ONLY core.muscles
    ADD CONSTRAINT muscles_name_key UNIQUE (name);


--
-- Name: muscles muscles_pkey; Type: CONSTRAINT; Schema: core; Owner: kartezjusz
--

ALTER TABLE ONLY core.muscles
    ADD CONSTRAINT muscles_pkey PRIMARY KEY (id);


--
-- Name: muscles muscles_slug_key; Type: CONSTRAINT; Schema: core; Owner: kartezjusz
--

ALTER TABLE ONLY core.muscles
    ADD CONSTRAINT muscles_slug_key UNIQUE (slug);


--
-- Name: exercises exercises_pkey; Type: CONSTRAINT; Schema: engine; Owner: kartezjusz
--

ALTER TABLE ONLY engine.exercises
    ADD CONSTRAINT exercises_pkey PRIMARY KEY (slug);


--
-- Name: muscle_exercise_mappings muscle_exercise_mappings_muscle_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: kartezjusz
--

ALTER TABLE ONLY core.muscle_exercise_mappings
    ADD CONSTRAINT muscle_exercise_mappings_muscle_id_fkey FOREIGN KEY (muscle_id) REFERENCES core.muscles(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--
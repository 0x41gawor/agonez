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

--
-- Name: validate_muscle_allocation_sum(); Type: FUNCTION; Schema: core; Owner: kartezjusz
--

CREATE FUNCTION core.validate_muscle_allocation_sum() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    calculated_sum NUMERIC;
BEGIN
    -- muscle_allocation musi być obiektem JSON, np.
    -- {"anterior_deltoid": 0.45, "triceps_long_head": 0.25}
    IF jsonb_typeof(NEW.muscle_allocation) <> 'object' THEN
        RAISE EXCEPTION
            'muscle_allocation must be a JSON object, received JSON type: %',
            COALESCE(jsonb_typeof(NEW.muscle_allocation), 'null');
    END IF;

    -- Każda wartość musi być liczbą JSON, a nie stringiem, tablicą itd.
    IF EXISTS (
        SELECT 1
        FROM jsonb_each(NEW.muscle_allocation) AS allocation(muscle, allocation_value)
        WHERE jsonb_typeof(allocation_value) <> 'number'
    ) THEN
        RAISE EXCEPTION
            'muscle_allocation may contain only numeric JSON values: %',
            NEW.muscle_allocation;
    END IF;

    SELECT COALESCE(SUM(allocation_value::text::numeric), 0)
    INTO calculated_sum
    FROM jsonb_each(NEW.muscle_allocation)
        AS allocation(muscle, allocation_value);

    -- Dane przechowujemy z dokładnością do dwóch miejsc.
    IF ROUND(calculated_sum, 2) <> ROUND(NEW.recruitment_budget, 2) THEN
        RAISE EXCEPTION
            'Muscle allocation error: allocation sum (%) must equal recruitment_budget (%). Exercise slug: %',
            calculated_sum,
            NEW.recruitment_budget,
            NEW.slug;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION core.validate_muscle_allocation_sum() OWNER TO kartezjusz;

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
    recruitment_budget numeric(3,2) NOT NULL,
    muscle_allocation jsonb NOT NULL,
    technique jsonb NOT NULL,
    comments jsonb NOT NULL,
    video_links text[] DEFAULT '{}'::text[] NOT NULL,
    CONSTRAINT check_recruitment_budget_by_mechanics CHECK ((((mechanics_tier = 'Isolation'::core.mechanics_tier_enum) AND ((recruitment_budget >= 0.20) AND (recruitment_budget <= 1.50))) OR ((mechanics_tier = 'Secondary_Compound'::core.mechanics_tier_enum) AND ((recruitment_budget >= 0.70) AND (recruitment_budget <= 2.20))) OR ((mechanics_tier = 'Heavy_Compound'::core.mechanics_tier_enum) AND ((recruitment_budget >= 1.20) AND (recruitment_budget <= 3.00))) OR ((mechanics_tier = 'Stability_Isometric'::core.mechanics_tier_enum) AND ((recruitment_budget >= 0.20) AND (recruitment_budget <= 2.00))))),
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

COPY core.exercises (id, slug, name, name_full, body_part, target_category, mechanics_tier, resistance_source, load_capacity, recruitment_budget, muscle_allocation, technique, comments, video_links) FROM stdin;
1	barbell_bench_press	Bench Press	Flat Bench Barbell Press	Upper	Chest_Sternal	Heavy_Compound	Barbell	72.00	1.90	{"anterior_deltoid": 0.35, "pectoralis_minor": 0.05, "serratus_anterior": 0.07, "triceps_long_head": 0.20, "triceps_medial_head": 0.15, "triceps_lateral_head": 0.18, "pectoralis_major_sternal": 0.60, "pectoralis_major_clavicular": 0.30}	{}	{}	{}
2	plate_loaded_converging_incline_chest_press	Converging Incline Chest Press	Plate-Loaded Converging Incline Chest Press	Upper	Chest_Clav_AD	Secondary_Compound	Plate_Loaded_Machine	70.00	1.72	{"anterior_deltoid": 0.35, "serratus_anterior": 0.03, "triceps_long_head": 0.17, "triceps_medial_head": 0.11, "triceps_lateral_head": 0.14, "pectoralis_major_sternal": 0.30, "pectoralis_major_clavicular": 0.62}	{}	{}	{}
4	seated_dumbbell_overhead_press	Dumbbell Overhead Press	Seated Dumbbell Overhead Press	Upper	Chest_Clav_AD	Secondary_Compound	Dumbbell	48.00	1.85	{"lateral_deltoid": 0.42, "upper_trapezius": 0.05, "anterior_deltoid": 0.72, "serratus_anterior": 0.10, "triceps_long_head": 0.18, "triceps_medial_head": 0.18, "triceps_lateral_head": 0.20}	{}	{}	{}
11	neutral_grip_lat_pulldown	Neutral-Grip Lat Pulldown	Selectorized Neutral-Grip Lat Pulldown	Upper	Back_V	Secondary_Compound	Selectorized_Machine	75.00	1.75	{"rhomboids": 0.11, "brachialis": 0.13, "teres_major": 0.20, "wrist_flexors": 0.04, "biceps_brachii": 0.18, "erector_spinae": 0.04, "brachioradialis": 0.07, "lower_trapezius": 0.13, "latissimus_dorsi": 0.55, "middle_trapezius": 0.11, "pectoralis_minor": 0.04, "posterior_deltoid": 0.09, "pectoralis_major_sternal": 0.06}	{}	{}	{}
19	selectorized_seated_leg_curl	Seated Leg Curl	Selectorized Seated Leg Curl	Lower	Hamstrings	Isolation	Selectorized_Machine	50.00	1.25	{"gastrocnemius": 0.08, "semitendinosus": 0.28, "semimembranosus": 0.25, "biceps_femoris_long_head": 0.38, "biceps_femoris_short_head": 0.26}	{}	{}	{}
20	selectorized_leg_extension	Leg Extension	Selectorized Seated Leg Extension	Lower	Quads	Isolation	Selectorized_Machine	60.00	1.28	{"rectus_femoris": 0.24, "vastus_medialis": 0.34, "vastus_lateralis": 0.40, "vastus_intermedius": 0.30}	{}	{}	{}
22	selectorized_hip_adduction	Hip Adduction Machine	Selectorized Seated Hip Adduction Machine	Lower	Hip_AF	Isolation	Selectorized_Machine	70.00	1.10	{"obliques": 0.02, "adductor_magnus": 0.58, "adductor_longus_brevis": 0.50}	{}	{}	{}
25	plate_loaded_seated_calf_raise	Seated Calf Raise	Plate-Loaded Seated Calf Raise	Lower	Calves	Isolation	Plate_Loaded_Machine	80.00	1.15	{"soleus": 0.82, "gastrocnemius": 0.30, "tibialis_anterior": 0.03}	{}	{}	{}
27	plate_loaded_chest_press	Machine Chest Press	Plate-Loaded Horizontal Chest Press	Upper	Chest_Sternal	Heavy_Compound	Plate_Loaded_Machine	80.00	1.80	{"anterior_deltoid": 0.33, "pectoralis_minor": 0.04, "serratus_anterior": 0.06, "triceps_long_head": 0.18, "triceps_medial_head": 0.13, "triceps_lateral_head": 0.16, "pectoralis_major_sternal": 0.62, "pectoralis_major_clavicular": 0.28}	{}	{}	{}
34	dragon_flag	Dragon Flag	Flat Bench Dragon Flag	Core	Core	Secondary_Compound	Bodyweight	55.00	1.60	{"obliques": 0.28, "iliopsoas": 0.22, "teres_major": 0.05, "erector_spinae": 0.06, "rectus_femoris": 0.06, "gluteus_maximus": 0.06, "latissimus_dorsi": 0.10, "rectus_abdominis": 0.46, "triceps_long_head": 0.06, "transverse_abdominis": 0.14, "adductor_longus_brevis": 0.06, "pectoralis_major_sternal": 0.05}	{}	{}	{}
37	straight_arm_cable_pulldown	Straight-Arm Pulldown	Standing Straight-Arm Cable Pulldown	Upper	Back_V	Isolation	Cable	40.00	1.22	{"obliques": 0.02, "teres_major": 0.22, "lower_trapezius": 0.06, "latissimus_dorsi": 0.62, "rectus_abdominis": 0.06, "posterior_deltoid": 0.08, "triceps_long_head": 0.12, "pectoralis_major_sternal": 0.04}	{}	{}	{}
13	cable_face_pull	Face Pull	Rope Cable Face Pull	Upper	Back_3D	Isolation	Cable	30.00	0.98	{"rhomboids": 0.14, "brachialis": 0.03, "rotator_cuff": 0.08, "biceps_brachii": 0.05, "lower_trapezius": 0.10, "upper_trapezius": 0.05, "middle_trapezius": 0.19, "posterior_deltoid": 0.34}	{}	{}	{}
9	barbell_pendlay_row	Pendlay Row	Barbell Pendlay Row	Upper	Back_3D	Heavy_Compound	Barbell	90.00	2.10	{"rhomboids": 0.24, "brachialis": 0.09, "teres_major": 0.18, "biceps_brachii": 0.12, "erector_spinae": 0.24, "brachioradialis": 0.06, "gluteus_maximus": 0.03, "lower_trapezius": 0.12, "upper_trapezius": 0.07, "latissimus_dorsi": 0.45, "middle_trapezius": 0.28, "posterior_deltoid": 0.20, "biceps_femoris_long_head": 0.02}	{}	{}	{}
6	barbell_california_press	California Press	Flat Bench Barbell California Press	Upper	Triceps	Secondary_Compound	Barbell	50.00	1.68	{"anterior_deltoid": 0.20, "serratus_anterior": 0.02, "triceps_long_head": 0.40, "triceps_medial_head": 0.30, "triceps_lateral_head": 0.33, "pectoralis_major_sternal": 0.30, "pectoralis_major_clavicular": 0.13}	{}	{}	{}
8	dead_hang	Dead Hang	Pronated-Grip Bar Dead Hang	Upper	Forearms	Stability_Isometric	Bodyweight	85.00	1.15	{"obliques": 0.02, "rhomboids": 0.05, "teres_major": 0.04, "wrist_flexors": 0.45, "brachioradialis": 0.10, "lower_trapezius": 0.10, "upper_trapezius": 0.09, "wrist_extensors": 0.08, "latissimus_dorsi": 0.12, "middle_trapezius": 0.06, "rectus_abdominis": 0.04}	{}	{}	{}
10	weighted_neutral_grip_pull_up	Weighted Neutral-Grip Pull-Up	Weighted Neutral-Grip Pull-Up	Upper	Back_V	Heavy_Compound	Bodyweight	100.00	2.05	{"obliques": 0.05, "rhomboids": 0.12, "brachialis": 0.16, "teres_major": 0.22, "wrist_flexors": 0.05, "biceps_brachii": 0.22, "erector_spinae": 0.04, "brachioradialis": 0.08, "lower_trapezius": 0.14, "latissimus_dorsi": 0.55, "middle_trapezius": 0.12, "pectoralis_minor": 0.04, "rectus_abdominis": 0.08, "posterior_deltoid": 0.10, "pectoralis_major_sternal": 0.08}	{}	{}	{}
12	chest_supported_dumbbell_row	Chest-Supported Dumbbell Row	Incline Bench Chest-Supported Dumbbell Row	Upper	Back_3D	Secondary_Compound	Dumbbell	60.00	1.70	{"rhomboids": 0.24, "brachialis": 0.08, "teres_major": 0.16, "biceps_brachii": 0.11, "brachioradialis": 0.05, "lower_trapezius": 0.12, "upper_trapezius": 0.06, "latissimus_dorsi": 0.40, "middle_trapezius": 0.28, "posterior_deltoid": 0.20}	{}	{}	{}
16	hanging_leg_raise	Hanging Leg Raise	Straight-Leg Hanging Leg Raise	Core	Core	Secondary_Compound	Bodyweight	32.00	1.50	{"obliques": 0.22, "iliopsoas": 0.34, "sartorius": 0.04, "teres_major": 0.04, "wrist_flexors": 0.10, "rectus_femoris": 0.08, "lower_trapezius": 0.04, "latissimus_dorsi": 0.08, "rectus_abdominis": 0.42, "transverse_abdominis": 0.10, "adductor_longus_brevis": 0.04}	{}	{}	{}
18	plate_loaded_45_degree_leg_press	45-Degree Leg Press	Plate-Loaded 45-Degree Sled Leg Press	Lower	Quads	Heavy_Compound	Plate_Loaded_Machine	200.00	2.30	{"soleus": 0.05, "gastrocnemius": 0.03, "erector_spinae": 0.02, "rectus_femoris": 0.22, "semitendinosus": 0.05, "adductor_magnus": 0.24, "gluteus_maximus": 0.40, "semimembranosus": 0.05, "vastus_medialis": 0.38, "vastus_lateralis": 0.46, "vastus_intermedius": 0.34, "biceps_femoris_long_head": 0.06}	{}	{}	{}
21	cable_pull_through	Cable Pull-Through	Rope Cable Pull-Through	Lower	Glutes	Secondary_Compound	Cable	60.00	1.55	{"obliques": 0.03, "erector_spinae": 0.20, "gluteus_medius": 0.02, "semitendinosus": 0.18, "adductor_magnus": 0.16, "gluteus_maximus": 0.50, "semimembranosus": 0.18, "rectus_abdominis": 0.04, "biceps_femoris_long_head": 0.24}	{}	{}	{}
23	smith_machine_standing_calf_raise	Standing Calf Raise	Smith Machine Standing Calf Raise	Lower	Calves	Isolation	Smith_Machine	120.00	1.20	{"soleus": 0.44, "gastrocnemius": 0.66, "erector_spinae": 0.04, "upper_trapezius": 0.03, "tibialis_anterior": 0.03}	{}	{}	{}
24	roman_chair_back_extension_isometric_hold	Roman Chair Isometric Hold	Roman Chair Back Extension Isometric Hold	Lower	Global_P	Stability_Isometric	Bodyweight	45.00	1.30	{"erector_spinae": 0.52, "semitendinosus": 0.12, "adductor_magnus": 0.06, "gluteus_maximus": 0.28, "semimembranosus": 0.12, "transverse_abdominis": 0.04, "biceps_femoris_long_head": 0.16}	{}	{}	{}
26	smith_machine_incline_bench_press	Smith Machine Incline Press	Incline Bench Smith Machine Press	Upper	Chest_Clav_AD	Secondary_Compound	Smith_Machine	80.00	1.75	{"anterior_deltoid": 0.35, "triceps_long_head": 0.18, "triceps_medial_head": 0.12, "triceps_lateral_head": 0.15, "pectoralis_major_sternal": 0.30, "pectoralis_major_clavicular": 0.65}	{}	{}	{}
28	weighted_forward_lean_dip	Weighted Chest Dip	Weighted Forward-Lean Parallel-Bar Dip	Upper	Chest_Sternal	Heavy_Compound	Bodyweight	110.00	2.00	{"lower_trapezius": 0.05, "anterior_deltoid": 0.28, "latissimus_dorsi": 0.06, "pectoralis_minor": 0.08, "rectus_abdominis": 0.04, "serratus_anterior": 0.10, "triceps_long_head": 0.28, "triceps_medial_head": 0.20, "triceps_lateral_head": 0.24, "pectoralis_major_sternal": 0.55, "pectoralis_major_clavicular": 0.12}	{}	{}	{}
3	single_arm_low_to_high_cable_fly	Low-to-High Cable Fly	Single-Arm Low-to-High Cable Fly	Upper	Chest_Clav_AD	Isolation	Cable	18.00	0.78	{"anterior_deltoid": 0.08, "pectoralis_minor": 0.03, "serratus_anterior": 0.04, "pectoralis_major_sternal": 0.08, "pectoralis_major_clavicular": 0.55}	{}	{}	{}
7	bodyweight_neck_curl	Neck Curl	Supine Bench Bodyweight Neck Curl	Upper	Neck	Isolation	Bodyweight	5.00	0.28	{"sternocleidomastoid": 0.28}	{}	{}	{}
30	seated_dumbbell_arnold_press	Arnold Press	Seated Dumbbell Arnold Press	Upper	Chest_Clav_AD	Secondary_Compound	Dumbbell	44.00	1.82	{"rotator_cuff": 0.03, "lateral_deltoid": 0.34, "upper_trapezius": 0.13, "anterior_deltoid": 0.58, "serratus_anterior": 0.07, "triceps_long_head": 0.18, "triceps_medial_head": 0.13, "pronators_supinators": 0.08, "triceps_lateral_head": 0.15, "pectoralis_major_clavicular": 0.13}	{}	{}	{}
32	kneeling_cable_crunch	Kneeling Cable Crunch	Kneeling Rope Cable Crunch	Core	Core	Isolation	Cable	60.00	1.25	{"obliques": 0.28, "iliopsoas": 0.07, "latissimus_dorsi": 0.06, "rectus_abdominis": 0.72, "transverse_abdominis": 0.12}	{}	{}	{}
33	hanging_oblique_knee_raise	Hanging Oblique Knee Raise	Alternating Hanging Oblique Knee Raise	Core	Core	Secondary_Compound	Bodyweight	27.00	1.45	{"obliques": 0.40, "iliopsoas": 0.28, "sartorius": 0.03, "teres_major": 0.05, "wrist_flexors": 0.10, "rectus_femoris": 0.04, "lower_trapezius": 0.05, "latissimus_dorsi": 0.08, "rectus_abdominis": 0.32, "transverse_abdominis": 0.10}	{}	{}	{}
35	wide_pronated_grip_pull_up	Wide-Grip Pull-Up	Wide Pronated-Grip Pull-Up	Upper	Back_V	Heavy_Compound	Bodyweight	85.00	1.95	{"obliques": 0.04, "rhomboids": 0.12, "brachialis": 0.12, "teres_major": 0.24, "wrist_flexors": 0.05, "biceps_brachii": 0.16, "erector_spinae": 0.03, "brachioradialis": 0.07, "lower_trapezius": 0.14, "latissimus_dorsi": 0.58, "middle_trapezius": 0.12, "pectoralis_minor": 0.03, "rectus_abdominis": 0.07, "posterior_deltoid": 0.11, "pectoralis_major_sternal": 0.07}	{}	{}	{}
36	wide_grip_seated_cable_row	Wide-Grip Seated Cable Row	Wide-Grip Seated Cable Row	Upper	Back_3D	Secondary_Compound	Cable	80.00	1.72	{"rhomboids": 0.28, "brachialis": 0.07, "teres_major": 0.16, "biceps_brachii": 0.10, "erector_spinae": 0.04, "brachioradialis": 0.04, "lower_trapezius": 0.13, "upper_trapezius": 0.02, "latissimus_dorsi": 0.34, "middle_trapezius": 0.32, "posterior_deltoid": 0.22}	{}	{}	{}
39	single_arm_kneeling_wide_cable_row	One-Arm Kneeling Cable Row	Single-Arm Kneeling Wide-Elbow Cable Row	Upper	Back_3D	Secondary_Compound	Cable	35.00	1.55	{"obliques": 0.06, "rhomboids": 0.24, "brachialis": 0.06, "teres_major": 0.14, "biceps_brachii": 0.09, "erector_spinae": 0.04, "lower_trapezius": 0.11, "upper_trapezius": 0.03, "latissimus_dorsi": 0.24, "middle_trapezius": 0.28, "posterior_deltoid": 0.26}	{}	{}	{}
14	standing_barbell_curl	Barbell Curl	Standing Barbell Curl	Upper	Biceps	Isolation	Barbell	40.00	0.98	{"brachialis": 0.23, "wrist_flexors": 0.06, "biceps_brachii": 0.49, "erector_spinae": 0.03, "brachioradialis": 0.12, "anterior_deltoid": 0.02, "pronators_supinators": 0.03}	{}	{}	{}
17	standing_cable_pallof_press	Pallof Press	Standing Cable Pallof Press	Core	Core	Stability_Isometric	Cable	20.00	0.82	{"obliques": 0.33, "erector_spinae": 0.07, "gluteus_medius": 0.05, "gluteus_maximus": 0.04, "anterior_deltoid": 0.03, "rectus_abdominis": 0.11, "serratus_anterior": 0.02, "transverse_abdominis": 0.17}	{}	{}	{}
29	high_to_low_pec_deck_fly	High-to-Low Pec Deck Fly	Selectorized High-to-Low Pec Deck Fly	Upper	Chest_Sternal	Isolation	Selectorized_Machine	45.00	1.02	{"anterior_deltoid": 0.09, "pectoralis_minor": 0.06, "serratus_anterior": 0.05, "pectoralis_major_sternal": 0.66, "pectoralis_major_clavicular": 0.16}	{}	{}	{}
31	overhead_rope_triceps_extension	Overhead Rope Triceps Extension	Standing Cable Overhead Rope Triceps Extension	Upper	Triceps	Isolation	Cable	35.00	0.95	{"obliques": 0.02, "erector_spinae": 0.03, "rectus_abdominis": 0.03, "triceps_long_head": 0.43, "triceps_medial_head": 0.20, "triceps_lateral_head": 0.24}	{}	{}	{}
41	single_arm_bayesian_cable_curl	Bayesian Cable Curl	Single-Arm Bayesian Cable Curl	Upper	Biceps	Isolation	Cable	15.00	0.78	{"obliques": 0.01, "brachialis": 0.20, "wrist_flexors": 0.04, "biceps_brachii": 0.43, "brachioradialis": 0.08, "pronators_supinators": 0.02}	{}	{}	{}
40	single_arm_dumbbell_preacher_curl	Dumbbell Preacher Curl	Single-Arm Dumbbell Preacher Curl	Upper	Biceps	Isolation	Dumbbell	14.00	0.74	{"brachialis": 0.21, "wrist_flexors": 0.04, "biceps_brachii": 0.38, "brachioradialis": 0.08, "pronators_supinators": 0.03}	{}	{}	{}
38	side_facing_reverse_pec_deck	Side-Facing Reverse Pec Deck	Single-Arm Side-Facing Reverse Pec Deck Fly	Upper	Back_3D	Isolation	Selectorized_Machine	20.00	0.84	{"obliques": 0.01, "rhomboids": 0.13, "rotator_cuff": 0.04, "lower_trapezius": 0.07, "upper_trapezius": 0.02, "middle_trapezius": 0.17, "posterior_deltoid": 0.40}	{}	{}	{}
44	standing_dumbbell_shrug	Dumbbell Shrug	Standing Dumbbell Shrug	Upper	Upper_Traps	Isolation	Dumbbell	80.00	0.92	{"rhomboids": 0.06, "wrist_flexors": 0.08, "erector_spinae": 0.04, "lower_trapezius": 0.04, "upper_trapezius": 0.57, "middle_trapezius": 0.13}	{}	{}	{}
43	incline_dumbbell_curl	Incline Dumbbell Curl	Seated Incline Bench Dumbbell Curl	Upper	Biceps	Isolation	Dumbbell	28.00	0.92	{"brachialis": 0.22, "wrist_flexors": 0.05, "biceps_brachii": 0.50, "brachioradialis": 0.09, "anterior_deltoid": 0.03, "pronators_supinators": 0.03}	{}	{}	{}
5	single_arm_cable_lateral_raise	Cable Lateral Raise	Single-Arm Cable Lateral Raise	Upper	Lateral_Delt	Isolation	Cable	12.00	0.62	{"obliques": 0.02, "lateral_deltoid": 0.48, "upper_trapezius": 0.03, "anterior_deltoid": 0.06, "posterior_deltoid": 0.03}	{}	{}	{}
15	preacher_dumbbell_hammer_curl	Preacher Hammer Curl	Single-Arm Dumbbell Hammer Curl on Preacher Bench	Upper	Biceps	Isolation	Dumbbell	16.00	0.76	{"brachialis": 0.29, "wrist_flexors": 0.04, "biceps_brachii": 0.20, "brachioradialis": 0.19, "pronators_supinators": 0.04}	{}	{}	{}
42	bodyweight_neck_extension	Neck Extension	Prone Bench Bodyweight Neck Extension	Upper	Neck	Isolation	Bodyweight	5.00	0.30	{"upper_trapezius": 0.03, "deep_neck_extensors": 0.27}	{}	{}	{}
46	seated_dumbbell_wrist_extension	Dumbbell Wrist Extension	Seated Palms-Down Dumbbell Wrist Extension	Upper	Forearms	Isolation	Dumbbell	12.00	0.38	{"brachioradialis": 0.02, "wrist_extensors": 0.35, "pronators_supinators": 0.01}	{}	{}	{}
45	seated_dumbbell_wrist_curl	Dumbbell Wrist Curl	Seated Palms-Up Dumbbell Wrist Curl	Upper	Forearms	Isolation	Dumbbell	24.00	0.52	{"wrist_flexors": 0.48, "brachioradialis": 0.02, "pronators_supinators": 0.02}	{}	{}	{}
47	copenhagen_plank	Copenhagen Plank	Bench-Supported Copenhagen Side Plank	Core	Hip_AF	Stability_Isometric	Bodyweight	35.00	0.92	{"obliques": 0.17, "erector_spinae": 0.03, "gluteus_medius": 0.07, "adductor_magnus": 0.22, "lateral_deltoid": 0.01, "rectus_abdominis": 0.04, "transverse_abdominis": 0.07, "adductor_longus_brevis": 0.31}	{}	{}	{}
48	bodyweight_crunch	Crunch	Floor Bodyweight Abdominal Crunch	Core	Core	Isolation	Bodyweight	22.00	0.82	{"obliques": 0.16, "rectus_abdominis": 0.57, "sternocleidomastoid": 0.02, "transverse_abdominis": 0.07}	{}	{}	{}
49	weighted_russian_twist	Weighted Russian Twist	Seated Weighted Russian Twist	Core	Core	Secondary_Compound	Other	15.00	0.94	{"obliques": 0.40, "iliopsoas": 0.08, "erector_spinae": 0.06, "rectus_femoris": 0.02, "anterior_deltoid": 0.04, "latissimus_dorsi": 0.03, "rectus_abdominis": 0.20, "transverse_abdominis": 0.10, "adductor_longus_brevis": 0.01}	{}	{}	{}
\.


--
-- Data for Name: muscle_exercise_mappings; Type: TABLE DATA; Schema: core; Owner: kartezjusz
--

COPY core.muscle_exercise_mappings (muscle_id, exercise_id, complexity, resistance_profile) FROM stdin;
\.


--
-- Data for Name: muscles; Type: TABLE DATA; Schema: core; Owner: kartezjusz
--

COPY core.muscles (id, slug, name, body_part, complex, mass_g, mv_cm3, pcsa, architecture, fiber_bias_type_i, fiber_bias_type_ii, smh_factor, strength_curve, leverage_peak, bible_markdown, article_links, video_links) FROM stdin;
3	pectoralis_minor	Musculus Pectoralis minor	Upper	Chest	25.00	25.00	4.00	Flat/Convergent	0.550	0.450	zero	Bell-shaped	Mid_Range	\n# Overview\n\n\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
4	anterior_deltoid	Musculus Deltoid anterior	Upper	Shoulder	100.00	105.00	10.00	Multipenate	0.400	0.600	medium	Bell-shaped	Mid_Range	\n# Overview\n\n\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
5	lateral deltoid	Musculus Deltoid lateral	Upper	Shoulder	130.00	135.00	28.00	Multipenate	0.500	0.500	zero	Bell-shaped	Mid_Range	\n# Overview\n\n\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
6	posterior deltoid	Musculus Deltoid posterior	Upper	Shoulder	75.00	80.00	8.00	Fusiform/Parallel-like	0.650	0.350	high	Bell-shaped	Mid_Range	\n# Overview\n\n\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
9	rotator_cuffs	Musculus rotator cuffs	Upper	Shoulder	75.00	82.00	13.50	Undefined	0.750	0.250	zero	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
10	latimus_dorsi	Musculus latissimus dorsi	Upper	Back	280.00	290.00	32.00	Parallel/Convergent	0.500	0.500	very_high	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
11	teres_major	Musculus Teres major	Upper	Back	55.00	55.00	7.00	Parallel	0.400	0.600	very_high	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
1	pectoralis_major_clavicular	Musculus pectoralis major clavicular head	Upper	Chest	120.00	125.00	13.00	Converged/Fan-shaped	0.400	0.600	high	Bell-shaped	Mid_Range	\n# Overview\n\n\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
2	pectoralis_major_sternal	Musculus Pectoralis major sternal head	Upper	Chest	270.00	280.00	30.00	Converged/Fan-shaped	0.350	0.650	high	Bell-shaped	Mid_Range	\n# Overview\n\n\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
12	trapezius_upper	Musculus Trapezius upper	Upper	Back	70.00	73.00	8.00	Parallel	0.550	0.450	high	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
13	trapezius_middle	Musculus Trapezius middle	Upper	Back	75.00	79.00	11.00	Parallel	0.650	0.350	very_high	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
14	trapezius_lower	Musculus Trapezius lower	Upper	Back	85.00	89.00	7.00	Parallel/Convergent	0.550	0.450	very_high	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
15	rhomboids	Musculus Rhomboideus	Upper	Back	65.00	65.00	12.00	Parallel	0.400	0.600	very_high	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
16	erector_spinae	Musculus erector spinae	Upper	Back	250.00	260.00	28.00	Parallel/Long-Fusiform	0.750	0.250	high	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
17	bicep_brachii	Musculus biceps brachii	Upper	Biceps	160.00	170.00	22.00	Fusiform	0.350	0.650	very_high	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
18	brachialis	Musculus brachialis	Upper	Biceps	100.00	105.00	23.00	Fusiform/Convergent	0.600	0.400	low	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
19	brachioradialis	Musculus brachioradialis	Upper	Biceps	75.00	80.00	13.00	Fusiform/Parallel	0.400	0.600	low	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
20	tricep_lateral_head	Musculus triceps brachii caput laterale	Upper	Triceps	95.00	100.00	22.00	Pennate	0.250	0.750	low	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
21	tricep_medial_head	Musculus triceps brachii caput mediale	Upper	Triceps	85.00	90.00	20.00	Pennate	0.500	0.500	very_low	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
22	tricep_long_head	Musculus triceps brachii caput longum	Upper	Triceps	130.00	40.00	26.00	Pennate	0.350	0.650	extreme_high	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
23	wrist_flexors	Musculus flexor carpi ulnaris&radialis, flexor digitorum superficialis, flexor retinaculum	Upper	Forearms	130.00	135.00	30.00	Fusiform/Pennate	0.550	0.450	high	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
24	wrist_extensors	Musculus extensor carpi radialis longus et brevis, 	Upper	Forearms	65.00	70.00	11.00	Pennate	0.650	0.350	high	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
25	pronators_supinators	Musculus pronator teres, Musculus pronator quadratus, Musculus supinator	Upper	Forearms	45.00	48.00	12.00	Fusiform/Quadrilateral	0.450	0.550	high	Bell-shaped	Mid_Range	\n# Overview\n\nTo sa 4 mięśnie tak naprawdę.\n\nNa volume i PCSA wziąłem średnią.\n\n# Anatomy\n- Origin\n- Insertion\n\n\n# Innervation\n\n\n\n# Function\n\n\n\n# Stretch-Mediated Hypertrophy\n\n\n\n# Training Notes\n\n\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
26	serratus_anterior	Musculus serratus anterior	Core	Core	165.00	173.00	20.00	Serrated/Fan-shaped	0.525	0.475	high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
27	rectus_abdominis	Musculus rectus abdominis	Core	Core	310.00	320.00	27.50	Parallel/Polygastric	0.445	0.555	high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
28	obliques	Musculus obliquus externus abdominis, Musculus obliquus internus abdominis	Core	Core	350.00	363.00	38.50	Broad Flat/Parallel	0.475	0.525	high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
29	transverse_abdominis	Musculus transversus abdominis	Core	Core	155.00	163.00	28.00	Broad Transverse	0.725	0.275	zero	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
30	gluteus_maximus	Musculus gluteus maximus	Lower	Glutes	410.00	435.00	65.00	Coarse Multipennate	0.440	0.560	extreme_high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
31	gluteus_medius	Musculus gluteus medius	Lower	Glutes	153.00	165.00	32.50	Fan-shaped/Radiate	0.550	0.450	high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
32	gluteus_minimus	Musculus gluteus minimus	Lower	Glutes	35.00	37.00	8.00	Fan-shaped/Radiate	0.575	0.425	high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
33	rectus_femoris	Musculus rectus femoris	Lower	Quads	205.00	215.00	13.50	Bipennate	0.400	0.600	extreme_high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
34	vastus_lateralis	Musculus vastus lateralis	Lower	Quads	500.00	530.00	70.00	Unipennate/Multipennate	0.475	0.525	high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
35	vastus_medialis	Musculus vastus medialis	Lower	Quads	310.00	323.00	51.50	Pennate/Bi-directional	0.540	0.460	high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
36	vastus_intermedius	Musculus vastus intermedius	Lower	Quads	265.00	278.00	48.50	Pennate	0.550	0.450	high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
37	biceps_femoris_long_head	Musculus biceps femoris caput longum	Lower	Hamstrings	155.00	168.00	26.00	Fusiform/Unipennate	0.400	0.600	extreme_high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
38	biceps_femoris_short_head	Musculus biceps femoris caput breve	Lower	Hamstrings	80.00	85.00	11.50	Unipennate	0.475	0.525	medium	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
39	semitendinosus	Musculus semitendinosus	Lower	Hamstrings	123.00	133.00	11.50	Fusiform/Long-fibered	0.450	0.550	extreme_high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
40	semimembranosus	Musculus semimembranosus	Lower	Hamstrings	190.00	203.00	48.50	Semi-membranous/Unipennate	0.445	0.555	extreme_high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
41	iliopsoas	Musculus iliopsoas	Lower	Hip_FA	315.00	330.00	38.50	Fusiform/Parallel	0.475	0.525	high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
42	adductor_magnus	Musculus adductor magnus	Lower	Hip_FA	340.00	360.00	44.00	Multipennate/Triangular	0.425	0.575	extreme_high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
43	adductor_longus_brevis	Musculus adductor longus, Musculus adductor brevis	Lower	Hip_FA	113.00	119.00	20.00	Fan-shaped/Triangular	0.495	0.505	extreme_high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
44	sartorius	Musculus sartorius	Lower	Hip_FA	88.00	93.00	3.00	Strap/Parallel	0.450	0.550	high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
45	gastrocnemius	Musculus gastrocnemius	Lower	Calves	130.00	140.00	31.00	Pennate/Bipennate	0.425	0.575	high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
46	soleus	Musculus soleus	Lower	Calves	240.00	260.00	150.00	Multipennate	0.775	0.225	medium	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
47	tibialis_anterior	Musculus tibialis anterior	Lower	Shin	88.00	93.00	22.00	Circumpennate/Fusiform	0.600	0.400	extreme_high	Bell-shaped	Mid_Range	\n# Overview\n\n# Anatomy\n- Origin\n- Insertion\n\n# Innervation\n\n# Function\n\n# Stretch-Mediated Hypertrophy\n\n# Training Notes\n\n# Interesting Facts\n\n	{https://exrx.net/}	{https://youtu.be/...}
\.


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
-- Name: exercises trigger_validate_exercise_allocation; Type: TRIGGER; Schema: core; Owner: kartezjusz
--

CREATE TRIGGER trigger_validate_exercise_allocation BEFORE INSERT OR UPDATE OF muscle_allocation, recruitment_budget ON core.exercises FOR EACH ROW EXECUTE FUNCTION core.validate_muscle_allocation_sum();


--
-- Name: muscle_exercise_mappings muscle_exercise_mappings_muscle_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: kartezjusz
--

ALTER TABLE ONLY core.muscle_exercise_mappings
    ADD CONSTRAINT muscle_exercise_mappings_muscle_id_fkey FOREIGN KEY (muscle_id) REFERENCES core.muscles(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--


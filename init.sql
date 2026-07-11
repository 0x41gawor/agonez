-----------------------------------------------------------------------------------------------------------
------------------------------------------------ C  O  R  E -----------------------------------------------
-----------------------------------------------------------------------------------------------------------

-- Tworzenie dedykowanej schemy dla repozytorium wiedzy i atlasu
CREATE SCHEMA IF NOT EXISTS core;

------------------------------------------------ E N U M S ------------------------------------------------

-- Ogólny podział sekcji ciała
CREATE TYPE core.body_part_enum AS ENUM ('Upper', 'Lower', 'Core', 'Full');

-- Kompleksy mięśniowe 
CREATE TYPE core.muscle_complex_enum AS ENUM (
    'Neck', 'Shoulder', 'Chest', 'Back', 'Biceps', 'Triceps', 
    'Forearms', 'Core', 'Glutes', 'Quads', 'Hamstrings', 'Hip_FA', 'Calves', 'Shin'
);

-- Architektura strukturalna włókien
CREATE TYPE core.muscle_architecture_enum AS ENUM (
    'Converged/Fan-shaped', 'Flat/Convergent', 'Multipenate', 'Fusiform/Parallel-like', 
    'Convergent/Pennate', 'Parallel', 'Fusiform', 'Pennate', 'Fusiform/Pennate', 'Fusiform/Quadrilateral'
);

-- Podatność mięśnia na hipertrofię wywołaną rozciągnięciem
CREATE TYPE core.smh_factor_enum AS ENUM (
    'zero', 'very_low', 'low', 'medium', 'high', 'very_high', 'extreme_high'
);

-- Kategorie docelowe ćwiczeń (Autorski podział sylwetkowy)
CREATE TYPE core.target_category_enum AS ENUM (
    'Chest_Clav_AD', 'Chest_Sternal', 'Back_V', 'Upper_Traps', 'Serratus', 'Back_3D', 
    'Lateral_Delt', 'Biceps', 'Triceps', 'Core', 'Quads', 'Glutes', 'Hip_AF', 
    'Hamstrings', 'Lower_P', 'Calves', 'Tibialis', 'Global_P'
);

-- Klasyfikacja mechaniki i złożoności ruchu
CREATE TYPE core.mechanics_tier_enum AS ENUM (
    'Heavy_Compound', 'Secondary_Compound', 'Isolation', 'Stability_Isometric'
);



-- Typy krzywych siły (anatomiczna cecha możliwości skurczowych mięśnia)
CREATE TYPE core.strength_curve_enum AS ENUM ('Ascending', 'Descending', 'Bell-shaped');

-- Profile oporu / dociążenia (zwektoryzowana relacja ćwiczenia względem konkretnego mięśnia)
CREATE TYPE core.resistance_profile_enum AS ENUM ('Lengthened-biased', 'Mid-range-biased', 'Shortened-biased');

-- Szczyt wewnętrznej dźwigni mechanicznej (geometria przyczepu kostnego)
CREATE TYPE core.leverage_peak_enum AS ENUM ('Lengthened_Range', 'Mid_Range', 'Shortened_Range', 'Flat_Profile');

------------------------------------------------ T A B L E S ------------------------------------------------

-- 1. TABELA MIĘŚNI (Muscles Catalogue)
CREATE TABLE core.muscles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE, -- Klucz unikalny mapowany bezpośrednio na Twój MUSCLES_SET
    body_part core.body_part_enum NOT NULL,
    complex core.muscle_complex_enum NOT NULL,
    mass_g NUMERIC(8, 2) NOT NULL CHECK (mass_g > 0),
    mv_cm3 NUMERIC(8, 2) NOT NULL CHECK (mv_cm3 > 0),
    pcsa NUMERIC(6, 2) NOT NULL CHECK (pcsa > 0),
    architecture core.muscle_architecture_enum NOT NULL,
    fiber_bias_type_i NUMERIC(4, 3) NOT NULL CHECK (fiber_bias_type_i >= 0 AND fiber_bias_type_i <= 1.0),
    fiber_bias_type_ii NUMERIC(4, 3) NOT NULL CHECK (fiber_bias_type_ii >= 0 AND fiber_bias_type_ii <= 1.0),
    smh_factor core.smh_factor_enum NOT NULL,
    strength_curve core.strength_curve_enum NOT NULL DEFAULT 'Bell-shaped',
    leverage_peak core.leverage_peak_enum NOT NULL DEFAULT 'Mid_Range',


    -- Giga pole tekstowe na Twoją muscle-bible (Markdown)
    bible_markdown TEXT NOT NULL DEFAULT '',
    
    -- Zapewnienie, że suma typów włókien wynosi dokładnie 100% (1.0)
    CONSTRAINT check_fiber_sum_100 CHECK (ABS((fiber_bias_type_i + fiber_bias_type_ii) - 1.0) < 0.001)
);

-- 2. TABELA ĆWICZEŃ (Exercises Catalogue)
CREATE TABLE core.exercises (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    body_part core.body_part_enum NOT NULL,
    target_category core.target_category_enum NOT NULL,
    mechanics_tier core.mechanics_tier_enum NOT NULL,
    load_capacity NUMERIC(5, 2) NOT NULL CHECK (load_capacity >= 0),
    recruitment_budget NUMERIC(3, 2) NOT NULL CHECK (recruitment_budget >= 1.0 AND recruitment_budget <= 3.0),
    
    -- Walidacja unikalnych kluczy z MUSCLES_SET wewnątrz dynamicznego słownika JSONB
    -- Zawiera strukturę: {"anterior_deltoid": 0.25, "triceps_long_head": 0.15}
    muscle_allocation JSONB NOT NULL,
    
    -- Struktura techniczna spakowana w obiekt JSONB dla czystości modelu architektonicznego
    -- Zawiera klucze: plane_of_movement, starting_position, internal_cues, technical_failure, rir0_detection, common_mistakes
    technique JSONB NOT NULL,
    
    -- Tablica stringów przechowująca linki URL (np. YouTube)
    video_links TEXT[] NOT NULL DEFAULT '{}',
    
    -- Wymuszenie widełek budżetowych bezpośrednio w bazie dla ochrony danych przed błędami LLM
    CONSTRAINT check_budget_by_tier CHECK (
        (mechanics_tier = 'Isolation' AND recruitment_budget BETWEEN 1.0 AND 1.3) OR
        (mechanics_tier = 'Secondary_Compound' AND recruitment_budget BETWEEN 1.4 AND 2.0) OR
        (mechanics_tier = 'Heavy_Compound' AND recruitment_budget BETWEEN 1.6 AND 3.0) OR
        (mechanics_tier = 'Stability_Isometric' AND recruitment_budget BETWEEN 1.0 AND 3.0)
    )
);


-- Tabela asocjacyjna (Many-to-Many) dla mapowania ćwiczeń docelowych
-- Dzięki temu na page'u mięśnia możesz wskazać jakie ćwiczenia go aktywują i podzielić to na 4 grupy: Iloczyn biomechaniczny i złożoność ruchu
-- To trzeba przypisać ekspercką wiedzą domenowa, a nie wyliczać, bo nie wiadomo, który mięsień w danym ćwiczeniu jest lengthened, a który shortened. 

CREATE TABLE core.muscle_exercise_mappings (
    muscle_id INT REFERENCES core.muscles(id) ON DELETE CASCADE,
    exercise_id INT REFERENCES core.exercises(id) ON DELETE CASCADE,
    complexity core.mechanics_tier_enum NOT NULL,       -- Compound / Isolation
    resistance_profile core.resistance_profile_enum NOT NULL, -- Jak to ćwiczenie dociąża TEN konkretny mięsień
    
    -- Klucz złożony uniemożliwia zdublowanie tej samej roli
    PRIMARY KEY (muscle_id, exercise_id, resistance_profile, complexity)
);



------------------------------------------------ T R I G G E R S ------------------------------------------------

-- 3. TRIGGER DO WALIDACJI SUMY ALOKACJI MIĘŚNI (Muscle Allocation Sum Validation Trigger)

CREATE OR REPLACE FUNCTION core.validate_muscle_allocation_sum()
RETURNS TRIGGER AS $$
DECLARE
    calculated_sum NUMERIC(4,2);
BEGIN
    -- Sumowanie wszystkich wartości numerycznych ukrytych wewnątrz słownika JSONB
    SELECT COALESCE(SUM(value::text::numeric), 0)
    INTO calculated_sum
    FROM jsonb_each(NEW.muscle_allocation);

    -- Sprawdzenie, czy suma alokacji zgadza się z zadeklarowanym budżetem (z tolerancją na zaokrąglenia maszynowe)
    IF ABS(calculated_sum - NEW.recruitment_budget) > 0.01 THEN
        RAISE EXCEPTION 'Matematyczny błąd alokacji: suma składowych (%) musi być równa recruitment_budget (%)', 
            calculated_sum, NEW.recruitment_budget;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Przypisanie triggera do tabeli exercises wewnątrz schemy core
CREATE TRIGGER trigger_validate_exercise_allocation
    BEFORE INSERT OR UPDATE ON core.exercises
    FOR EACH ROW
    EXECUTE FUNCTION core.validate_muscle_allocation_sum();
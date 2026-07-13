INSERT INTO core.muscles (
    slug,
    name,

    body_part,
    complex,

    mass_g,
    mv_cm3,
    pcsa,

    architecture,

    fiber_bias_type_i,
    fiber_bias_type_ii,

    smh_factor,
    strength_curve,
    leverage_peak,

    bible_markdown,

    article_links,
    video_links
)
VALUES (
    'pectoralis_major',
    'Musculus pectoralis major',

    -- body_part_enum:
    -- Upper | Lower | Core | Full
    'Upper',

    -- muscle_complex_enum:
    -- Neck | Shoulder | Chest | Back | Biceps | Triceps |
    -- Forearms | Core | Glutes | Quads | Hamstrings |
    -- Hip_FA | Calves | Shin
    'Chest',

    0.00,      -- Muscle mass [g]
    0.00,      -- Muscle volume [cm³]
    0.00,      -- PCSA [cm²]

    -- muscle_architecture_enum:
    -- Converged/Fan-shaped
    -- Flat/Convergent
    -- Multipenate
    -- Fusiform/Parallel-like
    -- Convergent/Pennate
    -- Parallel
    -- Fusiform
    -- Pennate
    -- Fusiform/Pennate
    -- Fusiform/Quadrilateral
    'Converged/Fan-shaped',

    0.500,     -- Type I
    0.500,     -- Type II

    -- smh_factor_enum:
    -- zero
    -- very_low
    -- low
    -- medium
    -- high
    -- very_high
    -- extreme_high
    'medium',

    -- strength_curve_enum:
    -- Ascending
    -- Descending
    -- Bell-shaped
    'Bell-shaped',

    -- leverage_peak_enum:
    -- Lengthened_Range
    -- Mid_Range
    -- Shortened_Range
    -- Flat_Profile
    'Mid_Range',

$$
# Overview



# Anatomy
- Origin
- Insertion


# Innervation



# Function



# Stretch-Mediated Hypertrophy



# Training Notes



# Interesting Facts

$$,

    ARRAY[
        -- 'https://exrx.net/...'
    ],

    ARRAY[
        -- 'https://pubmed.ncbi.nlm.nih.gov/...'
    ],

    ARRAY[
        -- 'https://youtu.be/...'
    ]
);
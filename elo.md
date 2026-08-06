## Worked Example: Standing Cable Overhead Rope Triceps Extension

The `overhead_rope_triceps_extension` exercise provides a useful example of the complete transformation:

[
Propulsive\ FCSA
\rightarrow
Tension\ Exposure
\rightarrow
ETU
]

It has a clearly identifiable propulsive subsystem—the three heads of the triceps—but also requires additional isometric tension from the shoulder, scapular, and trunk stabilizers. The overhead position additionally creates a muscle-specific hypertrophic advantage for the biarticular long head of the triceps.

### 1. Original Mechanical Vector

The current mechanical evaluation produced:

```json
{
  "rotator_cuffs": 4.10,
  "deltoid_anterior": 6.14,
  "serratus_anterior": 1.98,
  "triceps_long_head": 37.94,
  "triceps_medial_head": 11.65,
  "triceps_lateral_head": 26.98
}
```

However, this vector already mixes two distinct mechanical roles:

* elbow-extension force directly opposing the cable resistance;
* shoulder and scapular stabilization required to maintain the overhead position.

For the ETU pipeline, the strictly propulsive baseline should therefore contain only the triceps heads:

```json
{
  "triceps_long_head": 37.94,
  "triceps_lateral_head": 26.98,
  "triceps_medial_head": 11.65
}
```

The total propulsive FCSA demand is:

[
P_{total}
=========

# 37.94+26.98+11.65

76.57\ cm^2
]

The remaining muscles from the original mechanical vector are not discarded. They become initial evidence for the construction of the broader Tension Exposure Vector.

---

### 2. Construction of the Tension Exposure Vector

The Tension Exposure Vector estimates the FCSA-equivalent amount of each muscle’s active contractile capacity exposed to meaningful tension during the repetition.

For a muscle already present in the propulsive vector:

[
T_m \geq P_m
]

For every muscle:

[
0 \leq T_m \leq FCSA_{max,m}
]

A muscle may be added even when its propulsive contribution is zero, provided that it experiences mechanically meaningful active tension through stabilization, load transmission, co-contraction, or isometric fixation.

An illustrative estimate is:

| Muscle                 | Maximum FCSA | Propulsive FCSA | Tension FCSA | Tension fraction | Reason for tension                                                                                   |
| ---------------------- | -----------: | --------------: | -----------: | ---------------: | ---------------------------------------------------------------------------------------------------- |
| `triceps_long_head`    |        43.55 |           37.94 |        41.00 |            0.941 | Elbow extension plus additional biarticular tension while maintaining the elevated shoulder position |
| `triceps_lateral_head` |        36.10 |           26.98 |        28.00 |            0.776 | Primary elbow-extension force                                                                        |
| `triceps_medial_head`  |        15.59 |           11.65 |        12.00 |            0.770 | Primary elbow-extension force                                                                        |
| `rotator_cuffs`        |       170.80 |            0.00 |         7.00 |            0.041 | Glenohumeral centring and stabilization under the overhead cable load                                |
| `deltoid_anterior`     |        30.46 |            0.00 |         7.00 |            0.230 | Isometric maintenance of shoulder elevation and humeral position                                     |
| `serratus_anterior`    |        36.03 |            0.00 |         4.00 |            0.111 | Scapular upward-rotation and thoracic fixation requirements                                          |
| `trapezius_upper`      |        19.36 |            0.00 |         1.50 |            0.077 | Scapular stabilization in elevation                                                                  |
| `trapezius_lower`      |        14.98 |            0.00 |         1.50 |            0.100 | Scapular stabilization and upward-rotation force coupling                                            |
| `rectus_abdominis`     |        24.29 |            0.00 |         2.50 |            0.103 | Prevention of excessive lumbar extension                                                             |
| `obliques`             |        81.71 |            0.00 |         2.00 |            0.024 | Trunk and rib-cage stabilization                                                                     |
| `transverse_abdominis` |        21.97 |            0.00 |         1.50 |            0.068 | Abdominal bracing and force transmission                                                             |

The resulting vector is:

```json
{
  "triceps_long_head": 41.00,
  "triceps_lateral_head": 28.00,
  "triceps_medial_head": 12.00,
  "rotator_cuffs": 7.00,
  "deltoid_anterior": 7.00,
  "serratus_anterior": 4.00,
  "trapezius_upper": 1.50,
  "trapezius_lower": 1.50,
  "rectus_abdominis": 2.50,
  "obliques": 2.00,
  "transverse_abdominis": 1.50
}
```

Its total value is:

[
T_{total}=108.00\ cm^2
]

The Tension Expansion Ratio is:

[
TensionExpansionRatio
=====================
{"slug": "side_facing_reverse_pec_deck", "notes": ["No muscle received the 0.80 floor. Every included muscle either performs dynamic work or carries meaningful sustained load, so none meets the description of incidental co-contraction or trivial postural fixation.", "Only deltoid_posterior exceeds 1.00, and only by one step, on the strength of the extended cross-body start position that the single-arm side-facing configuration allows.", "The scapular retractors are deliberately separated from the posterior deltoid at 0.95: they reach peak demand at their shortest length over a small excursion, which is the opposite length profile to the working humerus.", "Hypertrophic quality ratio of 0.9241 is below the global target of approximately 1.00, driven by the large number of low-excursion isometric entries the mechanical model required. The tension-weighted figure sits well above the unweighted mean of 0.8917 because the near-reference dynamic muscles carry most of the tension.", "Normalized ETU reaches 0.7521 for posterior deltoid and 0.6134 for middle trapezius, the only muscles approaching a substantial share of a full reference effective-repetition equivalent.", "Teres major shows a normalized ETU of 0.3000 despite the smallest absolute tension in the vector; this is an artefact of its very small maximum FCSA and should not be read as a large stimulus."], "etu_sum_cm2": 122.60, "reconciliation": "PASS", "muscle_evaluation": [{"H_m": 1.0500, "muscle": "deltoid_posterior", "etu_cm2": 18.54, "rationale": "The single-arm side-facing setup permits the arm to travel further across the body at the start than a chest-supported bilateral version, loading the posterior deltoid in a modestly lengthened position. Resistance is present from the first degrees of the arc rather than appearing only near retraction. Bonus limited to 1.05 because the cam still delivers appreciable torque demand at the shortened end and the arc is short in absolute terms.", "normalized_etu": 0.7521, "contraction_mode": ["concentric", "eccentric"], "high_tension_rom": "substantial", "maximum_fcsa_cm2": 24.65, "smh_interpretation": "No SMH factor supplied. The starting position places the humerus across the midline with the posterior deltoid at meaningful length under load, which supports a small bonus but not a large one.", "active_tension_exposure_cm2": 17.66, "resistance_profile_alignment": "good", "duration_of_meaningful_tension": "moderate", "muscle_length_under_high_tension": "moderately_lengthened"}, {"H_m": 0.9500, "muscle": "trapezius_middle", "etu_cm2": 16.06, "rationale": "Peak retraction demand coincides with maximum scapular adduction, the shortest position for this muscle, and total scapular excursion is small relative to the arm's arc. Reduced modestly to 0.95 for shortened bias with limited high-tension ROM; it stays near reference because the contraction is genuinely dynamic and well loaded.", "normalized_etu": 0.6134, "contraction_mode": ["concentric", "eccentric"], "high_tension_rom": "limited", "maximum_fcsa_cm2": 26.18, "smh_interpretation": "Scapular retractors are shortest exactly where the machine demands most torque, so no stretch-mediated case exists.", "active_tension_exposure_cm2": 16.90, "resistance_profile_alignment": "moderate", "duration_of_meaningful_tension": "moderate", "muscle_length_under_high_tension": "shortened"}, {"H_m": 0.9500, "muscle": "rhomboids", "etu_cm2": 15.70, "rationale": "Shares the retraction length profile: highest demand at end-range adduction where the muscle is shortest, over a small excursion. 0.95.", "normalized_etu": 0.5558, "contraction_mode": ["concentric", "eccentric"], "high_tension_rom": "limited", "maximum_fcsa_cm2": 28.25, "smh_interpretation": "Same shortened-at-peak profile as middle trapezius.", "active_tension_exposure_cm2": 16.53, "resistance_profile_alignment": "moderate", "duration_of_meaningful_tension": "moderate", "muscle_length_under_high_tension": "shortened"}, {"H_m": 0.9500, "muscle": "rotator_cuffs", "etu_cm2": 13.97, "rationale": "Placed above the pure stabilizer band because a genuine dynamic external rotation and horizontal abduction component exists, not merely positional fixation. Held below reference at 0.95 because a substantial share of the tension is centring isometry with little excursion.", "normalized_etu": 0.0818, "contraction_mode": ["concentric", "eccentric", "isometric"], "high_tension_rom": "substantial", "maximum_fcsa_cm2": 170.80, "smh_interpretation": "The external rotators shorten through the movement while the anterior cuff lengthens, giving no net length advantage across the group.", "active_tension_exposure_cm2": 14.71, "resistance_profile_alignment": "moderate", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "mixed"}, {"H_m": 0.8500, "muscle": "obliques", "etu_cm2": 10.49, "rationale": "The tension is meaningful and sustained rather than incidental, which places it above the floor, but it is isometric with essentially no muscle excursion. 0.85 per the standard treatment of meaningful low-ROM stabilization.", "normalized_etu": 0.1284, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 81.71, "smh_interpretation": "Anti-rotation work holds a fixed mid-range length; no lengthened loading.", "active_tension_exposure_cm2": 12.34, "resistance_profile_alignment": "poor", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "mid_range"}, {"H_m": 0.9500, "muscle": "deltoid_lateral", "etu_cm2": 7.60, "rationale": "Part dynamic contribution to horizontal abduction, part isometric support of the abducted arm. Slightly below reference because only the posterior portion of the head is meaningfully loaded and its excursion is small.", "normalized_etu": 0.1662, "contraction_mode": ["concentric", "eccentric", "isometric"], "high_tension_rom": "limited", "maximum_fcsa_cm2": 45.73, "smh_interpretation": "Held near mid-length at shoulder height throughout; no length advantage either way.", "active_tension_exposure_cm2": 8.00, "resistance_profile_alignment": "moderate", "duration_of_meaningful_tension": "moderate", "muscle_length_under_high_tension": "mid_range"}, {"H_m": 0.9000, "muscle": "trapezius_lower", "etu_cm2": 6.47, "rationale": "More isometric than middle trapezius, since much of its force opposes elevation rather than producing the retraction excursion, and its high-tension range is short and shortened-biased. 0.90.", "normalized_etu": 0.4319, "contraction_mode": ["concentric", "isometric"], "high_tension_rom": "limited", "maximum_fcsa_cm2": 14.98, "smh_interpretation": "Shortens as the scapula retracts and depresses; no stretch-mediated case.", "active_tension_exposure_cm2": 7.19, "resistance_profile_alignment": "moderate", "duration_of_meaningful_tension": "moderate", "muscle_length_under_high_tension": "shortened"}, {"H_m": 0.8500, "muscle": "erector_spinae", "etu_cm2": 5.34, "rationale": "Meaningful sustained anti-rotation and anti-flexion isometry with no excursion. 0.85.", "normalized_etu": 0.0501, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 106.48, "smh_interpretation": "Static spinal position; no length variation.", "active_tension_exposure_cm2": 6.28, "resistance_profile_alignment": "poor", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "mid_range"}, {"H_m": 0.9000, "muscle": "latissimus_dorsi", "etu_cm2": 4.50, "rationale": "Assists transverse extension over a short range at a length far from its productive lengthened position, with a poor moment arm at shoulder height. 0.90.", "normalized_etu": 0.1026, "contraction_mode": ["concentric", "isometric"], "high_tension_rom": "limited", "maximum_fcsa_cm2": 43.85, "smh_interpretation": "The lat's productive lengthened position requires shoulder flexion and elevation, which never occurs in this movement.", "active_tension_exposure_cm2": 5.00, "resistance_profile_alignment": "poor", "duration_of_meaningful_tension": "moderate", "muscle_length_under_high_tension": "shortened"}, {"H_m": 0.8500, "muscle": "wrist_flexors", "etu_cm2": 4.25, "rationale": "Sustained isometric grip, meaningful but with zero excursion. 0.85.", "normalized_etu": 0.0781, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 54.40, "smh_interpretation": "Static grip with no length change.", "active_tension_exposure_cm2": 5.00, "resistance_profile_alignment": "poor", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "mid_range"}, {"H_m": 0.8500, "muscle": "brachialis", "etu_cm2": 3.94, "rationale": "Held at a single mid-range length with no excursion for the whole set. Meaningful load transmission rather than incidental co-contraction, so 0.85 rather than the floor.", "normalized_etu": 0.0894, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 44.05, "smh_interpretation": "The elbow angle is fixed, so the muscle occupies one length for the entire repetition.", "active_tension_exposure_cm2": 4.63, "resistance_profile_alignment": "poor", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "mid_range"}, {"H_m": 0.8500, "muscle": "trapezius_upper", "etu_cm2": 3.15, "rationale": "Low-excursion isometric girdle support in a shortened position. 0.85.", "normalized_etu": 0.1627, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 19.36, "smh_interpretation": "Shortened positional support of the shoulder girdle throughout.", "active_tension_exposure_cm2": 3.71, "resistance_profile_alignment": "poor", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "shortened"}, {"H_m": 0.8500, "muscle": "biceps_brachii", "etu_cm2": 2.91, "rationale": "Isometric elbow fixation and humeral head restraint with no excursion at either joint it crosses. 0.85.", "normalized_etu": 0.0731, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 39.81, "smh_interpretation": "Fixed elbow and a shoulder that extends rather than flexes give no lengthened loading at either joint.", "active_tension_exposure_cm2": 3.42, "resistance_profile_alignment": "poor", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "mid_range"}, {"H_m": 0.8500, "muscle": "pronators_supinators", "etu_cm2": 2.55, "rationale": "Sustained low-ROM isometric control of forearm orientation. 0.85.", "normalized_etu": 0.0419, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 60.88, "smh_interpretation": "Forearm rotation is held constant; no length change.", "active_tension_exposure_cm2": 3.00, "resistance_profile_alignment": "poor", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "mid_range"}, {"H_m": 0.8500, "muscle": "transverse_abdominis", "etu_cm2": 2.15, "rationale": "Sustained bracing isometry without excursion. 0.85.", "normalized_etu": 0.0979, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 21.97, "smh_interpretation": "Pressure generation involves negligible length change.", "active_tension_exposure_cm2": 2.53, "resistance_profile_alignment": "poor", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "mid_range"}, {"H_m": 0.8500, "muscle": "serratus_anterior", "etu_cm2": 1.93, "rationale": "Antagonist co-contraction that occurs at a genuinely lengthened position, which lifts it off the floor value, but at a very small fraction of capacity. 0.85.", "normalized_etu": 0.0536, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 36.03, "smh_interpretation": "Scapular retraction does lengthen the serratus, but the co-contractile tension is far too low to convert that into a reference-quality stimulus.", "active_tension_exposure_cm2": 2.27, "resistance_profile_alignment": "poor", "duration_of_meaningful_tension": "moderate", "muscle_length_under_high_tension": "moderately_lengthened"}, {"H_m": 0.8500, "muscle": "rectus_abdominis", "etu_cm2": 1.70, "rationale": "Low-ROM isometric bracing. 0.85.", "normalized_etu": 0.0700, "contraction_mode": ["isometric"], "high_tension_rom": "brief", "maximum_fcsa_cm2": 24.29, "smh_interpretation": "Static trunk position throughout.", "active_tension_exposure_cm2": 2.00, "resistance_profile_alignment": "poor", "duration_of_meaningful_tension": "sustained", "muscle_length_under_high_tension": "mid_range"}, {"H_m": 0.9000, "muscle": "teres_major", "etu_cm2": 1.35, "rationale": "Small dynamic synergist working over a short range away from its productive length. 0.90, matching latissimus dorsi.", "normalized_etu": 0.3000, "contraction_mode": ["concentric", "isometric"], "high_tension_rom": "limited", "maximum_fcsa_cm2": 4.50, "smh_interpretation": "Like the lat, its lengthened position requires shoulder flexion, which does not occur here.", "active_tension_exposure_cm2": 1.50, "resistance_profile_alignment": "poor", "duration_of_meaningful_tension": "moderate", "muscle_length_under_high_tension": "shortened"}], "modifier_distribution": {"mode": 0.8500, "median": 0.8500, "maximum": 1.0500, "minimum": 0.8500, "unweighted_mean": 0.8917, "tension_weighted_mean": 0.9241}, "hypertrophic_quality_ratio": 0.9241, "active_tension_exposure_sum_cm2": 132.67
# \frac{108.00}{76.57}

1.410
]

This means that the total active tension exposure is estimated to be approximately 41% greater than the propulsive FCSA baseline after accounting for stabilizing and load-transmitting muscles.

This does not mean that stabilization added 41% more external force. It means that additional active muscle capacity was exposed to tension while the propulsive subsystem performed the external task.

---

### 3. Hypertrophic Tension Quality Modifiers

The ETU value is calculated by applying a muscle-specific Hypertrophic Tension Quality Modifier:

[
ETU_m=T_m\cdot H_m
]

The modifier evaluates the hypertrophic value of the tension already identified in the previous stage.

It must not reward a muscle merely for being a prime mover or stabilizer. Those roles have already affected the Tension Exposure Vector.

An illustrative calibration is:

| Muscle                 | Tension FCSA | (H_m) |   ETU | Main quality consideration                                           |
| ---------------------- | -----------: | ----: | ----: | -------------------------------------------------------------------- |
| `triceps_long_head`    |        41.00 |  1.20 | 49.20 | High tension at a substantially lengthened muscle position           |
| `triceps_lateral_head` |        28.00 |  1.00 | 28.00 | Conventional dynamic elbow-extension tension                         |
| `triceps_medial_head`  |        12.00 |  1.00 | 12.00 | Conventional dynamic elbow-extension tension                         |
| `rotator_cuffs`        |         7.00 |  0.80 |  5.60 | Low-amplitude isometric stabilization without productive dynamic ROM |
| `deltoid_anterior`     |         7.00 |  0.80 |  5.60 | Predominantly isometric shoulder-position maintenance                |
| `serratus_anterior`    |         4.00 |  0.85 |  3.40 | Isometric and low-ROM scapular force production                      |
| `trapezius_upper`      |         1.50 |  0.80 |  1.20 | Low-level scapular stabilization                                     |
| `trapezius_lower`      |         1.50 |  0.80 |  1.20 | Low-level scapular stabilization                                     |
| `rectus_abdominis`     |         2.50 |  0.80 |  2.00 | Low-level anti-extension isometry                                    |
| `obliques`             |         2.00 |  0.80 |  1.60 | Low-level trunk stabilization                                        |
| `transverse_abdominis` |         1.50 |  0.80 |  1.20 | Low-level abdominal bracing                                          |

The final ETU Vector is:

```json
{
  "triceps_long_head": 49.20,
  "triceps_lateral_head": 28.00,
  "triceps_medial_head": 12.00,
  "rotator_cuffs": 5.60,
  "deltoid_anterior": 5.60,
  "serratus_anterior": 3.40,
  "rectus_abdominis": 2.00,
  "obliques": 1.60,
  "trapezius_upper": 1.20,
  "trapezius_lower": 1.20,
  "transverse_abdominis": 1.20
}
```

The total ETU delivered by the standardized effective repetition is:

[
ETU_{total}=111.00\ cm^2
]

The Hypertrophic Quality Ratio is:

[
HypertrophicQualityRatio
========================

# \frac{111.00}{108.00}

1.028
]

The exercise therefore has an average hypertrophic tension-quality modifier of approximately `1.03`, but this average conceals substantial muscle-specific differences.

---

### 4. ETU May Exceed Maximum FCSA

The long head of the triceps has:

[
FCSA_{max}=43.55\ cm^2
]

Its Tension Exposure remains physiologically bounded:

[
T_{long}=41.00\leq43.55
]

However, after applying the hypertrophic quality modifier:

[
ETU_{long}
==========

# 41.00\cdot1.20

49.20
]

Therefore:

[
ETU_{long}>FCSA_{max,long}
]

This does not imply that more than 100% of the muscle was recruited or exposed to tension.

It means that tension applied to approximately 94% of the muscle’s reference force-generating capacity had a hypertrophic quality equivalent to 120% of the reference condition.

The normalized ETU is:

[
NormalizedETU_{long}
====================

# \frac{49.20}{43.55}

1.130
]

This represents approximately `1.13` reference effective repetitions for the long head, delivered by one standardized effective repetition of the exercise.

---

### 5. Final Interpretation

The complete transformation is:

```text
Propulsive FCSA Demand
76.57 cm²
        ↓
addition of stabilizing and load-transmitting tension
        ↓
Tension Exposure
108.00 cm²
        ↓
muscle-specific hypertrophic quality modifiers
        ↓
ETU
111.00 cm²
```

The three vectors answer different questions:

* **Propulsive FCSA Vector:** How much muscle-force capacity directly generated the required external movement?
* **Tension Exposure Vector:** How much active contractile capacity experienced meaningful tension for any mechanically necessary reason?
* **ETU Vector:** What was the hypertrophic stimulus-equivalent value of that tension?

The same muscle force must not be counted repeatedly because it simultaneously performs propulsion, stabilization, compression, or load transmission. Each muscle receives one total Tension Exposure value, followed by one hypertrophic quality modifier.

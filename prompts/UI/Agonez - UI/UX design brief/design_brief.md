# Agonez — UI/UX Design Brief

Design a high-fidelity application UI for **Agonez**, a data-driven strength-training and human-musculoskeletal knowledge system.

This is **not a marketing website** and should not look like a generic SaaS dashboard. It is a working analytical application / interactive atlas intended for users who care about anatomy, biomechanics, exercises, training programming and quantitative training analysis.

## Inputs provided

I am attaching:

1. **Interactive human-body SVG**

   * currently contains **front and rear views**
   * side view will be added in v2
   * anatomical elements have stable semantic identifiers / slugs
   * the SVG is intended to become an actual interactive UI component, not merely a decorative illustration

2. **Reduced SQL database dump**

   * contains real schema and representative data for exercises and muscles
   * treat it as the source of truth for fields, naming and realistic content
   * prefer using actual provided records in the mockups instead of inventing arbitrary fitness examples

3. **Written domain description**

4. **Agonez logo PNG**

Use these assets as the basis of the design.

---

# 1. Product direction

The current version of Agonez should primarily be an **Atlas** exposing two first-class entity types:

* Exercises
* Muscles

The application will later expand into:

* **Atlas**
* **My Plans** — workout-program construction and management
* **Dashboard / Progress** — tracking execution and progress of an active training plan

Think about the information architecture so that these future modules fit naturally into the product.

However, **only the Atlas needs to be designed in detail now**.

A possible future top navigation architecture is:

`Atlas | My Plans | Dashboard`

with Atlas active in the current design.

Do not over-design the future modules.

---

# 2. Visual direction

The desired aesthetic is:

* modern
* light
* sleek
* highly polished
* information-dense without feeling crowded
* scientific / analytical
* restrained
* premium
* somewhere in the design space of:

  * Notion
  * Obsidian
  * Linear
  * modern developer tools
  * modern scientific software

Do not literally clone any of them.

Avoid:

* bodybuilding-site aesthetics
* aggressive gym branding
* excessive gradients
* neon cyberpunk
* giant dashboard KPI cards everywhere
* excessive cardification
* unnecessary shadows
* oversized typography
* excessive empty space that reduces information density

Agonez should feel like a **serious knowledge and analytical instrument**.

Use the supplied logo to inform the brand language.

---

# 3. Themes

The entire design must support:

* Light theme
* Dark theme

Both should be first-class themes rather than one being an inverted afterthought.

The anatomical SVG, heatmaps, borders, typography, images and data visualizations must remain legible in both modes.

---

# 4. Atlas navigation

Within Atlas, provide clear navigation between:

* Exercises
* Muscles

These can be tabs, segmented navigation, secondary navigation, or another compact pattern consistent with the visual system.

Each entity index supports:

* search
* filtering
* sorting
* list view
* grid/card view

The current view mode should be easily switchable.

---

# 5. Exercises — Atlas index

Display **all exercises available in the provided data**.

Support filtering by:

* `body_part`
* `target_category`
* `mechanics_tier`
* `resistance_source`

Support sorting by:

* `name`
* `name_full`
* `load_capacity`
* `systemic_propulsive_fcsa_demand`

Sorting should support ascending / descending direction where applicable.

Provide:

### List view

A compact, highly scannable list suitable for browsing hundreds of exercises.

It should expose enough metadata to make the entries meaningfully distinguishable without becoming a database-table dump.

### Grid view

More visual cards containing:

* exercise name
* key metadata
* visual signature image
* useful compact quantitative information

Every exercise will eventually have its own image.

These images do not exist yet.

For now, create **clearly intentional visual placeholders / mock exercise imagery**. Do not make missing imagery look like a broken state.

---

# 6. Muscles — Atlas index

Display **all muscles available in the provided data**.

Support filtering by:

* `body_part`
* `complex`

Support sorting by:

* `name`
* `mass_g`
* `mv_cm3`
* `fiber_biases`
* `pcsa_fiber_cm2`
* `pcsa_projected_fcsa_cm2`

Provide both:

* compact list view
* visual grid/card view

Every muscle will eventually have its own visual signature image.

For now use a coherent mock-image system.

---

# 7. Persistent anatomical SVG integration

The human-body SVG is one of the core visual elements of Agonez.

Use it heavily wherever it genuinely improves comprehension.

On Exercise and Muscle index screens, consider a layout where the SVG has a **persistent / sticky place in the browsing interface** rather than appearing only on detail pages.

Possible interaction model:

### Muscle Atlas

When hovering or selecting a muscle in the list/grid:

* highlight that muscle on the SVG
* deemphasize unrelated anatomy
* preserve anatomical context

When applying filters, the SVG may subtly indicate matching anatomical regions.

### Exercise Atlas

When hovering or selecting an exercise:

* visualize its muscular involvement on the SVG
* allow the body visualization to act as a preview before opening the exercise

The SVG should behave like part of the data interface.

It should not feel like a static illustration placed beside a table.

---

# 8. Muscle detail page

Design a rich single-muscle view.

It should include:

## Identity / header

* muscle name
* visual signature image
* slug where appropriate
* key classification
* concise high-value metadata

## Anatomical SVG

Show the human figure with the selected muscle clearly highlighted.

Allow switching between available anatomical views where useful:

* front
* rear

Side view does not exist yet.

The component architecture should allow it to be added later.

## Structured database information

Provide a clean structured presentation of textual and numerical fields from the database.

Do not simply reproduce a raw SQL row.

Use good hierarchy, grouping, units and formatting.

Relevant values may include anatomical properties such as:

* mass
* volume
* fiber characteristics
* PCSA
* projected FCSA
* classifications
* other fields actually present in the attached database

## Image gallery

Gallery of images related to the muscle.

The images do not exist yet, therefore use polished placeholders.

## Video gallery

Embedded YouTube videos using URLs available in the data when present.

Design this as a useful educational section, not an oversized entertainment feed.

## Articles / references

Gallery or list of relevant articles/resources.

Use real attached data where available and mock the missing integration where necessary.

## Related exercises

Provide a section showing exercises targeting this muscle.

The final backend endpoint does not exist yet.

Design the component and use realistic mocked data.

It should be obvious how a user can jump from:

`Muscle → Exercises targeting this muscle`

## Bible Markdown

At the bottom of the page render the long-form `bible_markdown` content stored in the database.

This section can be substantial.

Treat it as an actual knowledge-base / technical article:

* excellent typography
* headings
* tables
* callouts where appropriate
* formulas if necessary
* good readable line length
* proper spacing

Do not present it as an unstyled raw markdown dump.

---

# 9. Exercise detail page

Design a rich single-exercise view.

## Identity / header

Show:

* exercise name
* full name
* visual signature image
* major classifications
* important quantitative properties from the database

## Structured database information

Present the available exercise metadata in a readable structured format.

Prefer semantic groups rather than one enormous generic table.

## Interactive anatomical load visualization

This is one of the most important parts of the product.

Use the supplied interactive SVG to visualize several selectable vectors associated with an exercise.

The user should be able to switch between visualization modes.

At minimum:

### Mode A — ETU

`etu_vector`

ETU represents the training-stimulus exposure allocated to individual muscles by an exercise.

Conceptually:

* each muscle has a scalar ETU exposure
* larger ETU means greater modeled training stimulus for that muscle
* this is a per-muscle vector over the muscle set

For anatomical visualization, muscle values should be normalized relative to the muscle's own capacity:

`muscle.pcsa_projected_fcsa_cm2`

so that the visualization represents meaningful relative muscular exposure rather than merely favoring anatomically larger muscles.

Use a **green / emerald / teal sequential heatmap family** for ETU.

Avoid misleading rainbow heatmaps.

Provide a legend.

---

### Mode B — Recovery / active tension exposure

The relevant muscle-side quantity is derived from:

`active_tension_exposure_vector × muscle_recovery_cost_modifier`

Conceptually:

* `active_tension_exposure_vector` represents modeled active muscular tension exposure produced by the exercise
* `muscle_recovery_cost_modifier` modifies that exposure according to the modeled recovery cost of loading that muscle in this manner
* the resulting quantity represents a muscle-level recovery burden / recovery cost signal

Again normalize the muscle visualization against:

`muscle.pcsa_projected_fcsa_cm2`

Use a clearly different sequential palette from ETU.

For example:

* ETU → emerald / green
* recovery burden → coral / red / warm spectrum

Intensity should communicate magnitude.

Zero or near-zero values should visually disappear into the neutral anatomy rather than appearing as a meaningful color.

---

### Mode C / overlay — Joint load

Use:

`joint_load_exposure_vector`

This vector represents relative modeled exposure of anatomical joints during the exercise.

Joint load is conceptually separate from muscular ETU and muscular recovery exposure.

Visualize joints with a different visual grammar than muscle heatmaps.

For example:

* highlighted joint nodes
* rings
* halos
* localized markers
* amber / violet accents

Do not simply paint joint load onto muscle shapes.

The interface should make it possible to inspect:

**muscle recovery exposure + joint load exposure together**

without making the body diagram unreadable.

---

# 10. Heatmap interaction

The anatomical visualization should support serious inspection.

Consider:

* hover tooltip
* muscle/joint name
* raw value
* normalized value when relevant
* percentile / relative intensity where useful
* legend
* front/rear switching
* selected element state
* smooth but restrained transitions

When a user hovers a muscle on the SVG, the corresponding item/value elsewhere in the UI should highlight.

Where appropriate, the interaction should work in both directions:

`data → anatomy`

and

`anatomy → data`

The SVG contains stable slugs specifically to enable this linkage.

---

# 11. Exercise educational content

The exercise detail should additionally contain:

## Video gallery

Embedded YouTube technique / demonstration videos from stored links.

## Technique

Render the stored `technique` content as formatted readable text.

It should feel like practical technical documentation.

## Comments

Render the stored `comments` content separately from technique.

Maintain clear distinction between:

* canonical execution instructions
* contextual comments / caveats

---

# 12. Image system

Both:

* exercises
* muscles

will eventually receive unique visual-signature images.

These images should be visible:

* in grid cards
* in detail headers
* possibly in search results / recommendations where appropriate

Because they do not exist yet, design a reusable placeholder system that preserves final layout geometry.

Do not rely on placeholders whose dimensions would change once real imagery is added.

---

# 13. Information density and responsive behavior

Primary target is a modern desktop application.

Design first for roughly:

* 1440 px desktop
* 1920 px desktop

but keep layouts responsive enough for narrower laptop widths.

A mobile redesign is not the primary objective yet.

On large displays, use the additional width intelligently:

* anatomical visualization
* data
* navigation
* contextual panels

rather than simply increasing margins.

---

# 14. Application architecture considerations

The production application will be implemented in:

**Vue.js**

and will consume a:

**REST API**

Therefore design the UI as a system of reusable components and predictable states.

Examples:

* entity cards
* entity list rows
* filter controls
* sort controls
* atlas body viewer
* heatmap legend
* metadata sections
* media gallery
* markdown renderer
* related-entity collections

Do not produce implementation code unless necessary to communicate a design interaction.

The important goal is to create an interface that can realistically be translated into a Vue component architecture.

---

# 15. State design

Consider important application states such as:

* loading
* empty filter results
* missing image
* missing article
* missing video
* missing optional metric
* no related exercises yet
* active filters
* selected anatomical element

Use restrained skeletons/placeholders where appropriate.

Do not fill missing backend data with fabricated authoritative scientific information.

---

# 16. Filtering UX

Filtering must remain usable when the database grows significantly.

Avoid permanently consuming excessive horizontal space.

Possible solutions include:

* compact filter toolbar
* filter popover
* side panel when appropriate
* removable filter chips
* visible active-filter count

The active state should always be understandable.

Search, filters, sorting and view selection should feel like one coherent browsing control system.

---

# 17. Scientific data presentation

Use units consistently and visibly.

Examples:

* g
* cm³
* cm²
* kg

Numbers should be aligned and formatted for comparison.

For quantitative properties, consider subtle:

* inline bars
* compact scales
* sparklines only where meaningful
* comparative indicators

but do not turn every number into a chart.

Precision should serve interpretation.

---

# 18. URL / navigation model

The visual architecture should naturally map to routes such as:

`/atlas/exercises`

`/atlas/exercises/:slug`

`/atlas/muscles`

`/atlas/muscles/:slug`

The design does not have to display these URLs, but navigation hierarchy should support this structure.

---

# 19. Desired relationship between screens

The application should encourage exploratory navigation:

`Exercise → involved muscle → muscle page → related exercises → another exercise`

The product should feel like a connected anatomical knowledge graph even if the backend is initially simple.

Design cross-links accordingly.

---

# 20. Future compatibility

The Atlas is only the first module.

Later Agonez will include workout-program construction.

Users will be able to create plans, select exercises from this Atlas, start a plan, log training sessions and analyze progression over weeks.

The Dashboard will eventually expose training progression such as:

* weeks
* performed exercises
* loads
* progression
* post-workout analysis
* other training/recovery metrics

Do not design these screens now.

However, avoid architectural decisions that would make Atlas feel like an isolated standalone website.

It should already look like the knowledge layer of a larger training operating system.

---

# 21. Important design principle

Use the anatomical SVG as a **first-class interaction surface**.

Agonez's strongest visual differentiator should become the relationship between:

**structured biomechanical data ↔ human anatomy**

rather than generic charts or fitness photography.

The interface should make quantitative training data feel physically grounded in the human body.

---

# 22. Example semantic SVG contract

Inspect the attached SVG itself for the real structure.

The important implementation assumption is that anatomical elements can be addressed using semantic slugs / IDs.

For example, conceptually:

```xml
<path id="pectoralis_major_sternal" ... />
<path id="deltoid_anterior" ... />
<path id="biceps_brachii" ... />
```

Do not redraw the anatomy unless required by the visual design.

Design around the assumption that application state can map values directly onto these SVG elements.

---

# 23. Deliverables

Create a coherent high-fidelity product design showing at minimum:

1. Exercises — list view
2. Exercises — grid view
3. Muscles — list view
4. Muscles — grid view
5. Muscle detail
6. Exercise detail with anatomical ETU visualization
7. Exercise detail with recovery + joint exposure visualization
8. Representative light-theme screens
9. Representative dark-theme screens

You do not need to create nine completely disconnected compositions.

Prefer a coherent application system demonstrating these states.

Also establish:

* typography hierarchy
* color system
* spacing rhythm
* card/list language
* navigation
* filter controls
* data visualization language
* SVG heatmap language
* placeholder image language

---

# 24. Final quality bar

The result should look like a product that could realistically be implemented and used daily.

Optimize for:

* clarity
* anatomical comprehension
* analytical usefulness
* fast browsing
* information density
* visual restraint
* strong typography
* discoverability
* future extensibility

The interface should communicate:

**knowledge + anatomy + quantitative training engineering**

rather than:

**generic fitness app**.

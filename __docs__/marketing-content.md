# Agonez Marketing Content

> Internal content and product-truth brief for the future `/home` page. Customer-facing copy is in Polish. Notes for the design and implementation pipeline are sometimes in English where that reduces ambiguity.
>
> Evidence baseline: repository state and the PostgreSQL snapshot dated 2026-09-17, reviewed on 2026-09-18. Catalog counts are evidence for this snapshot, not permanent marketing promises.

## Evidence and status legend

- **[IMPLEMENTED]** — present in the current database/API and exposed in the current Vue application.
- **[PARTIALLY IMPLEMENTED]** — meaningful pieces exist, but the named product area is not complete or does not have its own user flow.
- **[PLANNED]** — described in roadmap/domain notes but absent from the current runtime.
- **[EXPERIMENTAL MODEL]** — implemented calculation or estimated catalog value that should be presented as a model, not as directly measured physiology.

Recommended public status language:

- `Available` / `Dostępne` — usable in the current application.
- `In development` / `W rozwoju` — meaningful implementation exists, but the experience or model is incomplete.
- `Coming soon` / `Wkrótce` — roadmap-only product flow with clear user value.
- `Experimental` / `Model eksperymentalny` — implemented estimate whose assumptions and uncertainty matter.

Do not put a badge on every card. Reserve badges primarily for `W rozwoju`, `Wkrótce`, and `Model eksperymentalny`. An unbadged card can represent a currently available core capability.

---

## 1. Product in one sentence

### Recommended customer-facing sentence

> **Agonez porządkuje wiedzę o treningu, pomaga budować plany i pokazuje — za pomocą jawnych modeli — jaki bodziec oraz koszt regeneracyjny może z nich wynikać.**

### Shorter hero-compatible version

> **Zrozum trening. Zbuduj plan, który ma sens.**

### Ten-second explanation

> Atlas mięśni i ćwiczeń, kreator planów oraz analiza bodźca i regeneracji dla osób trenujących i trenerów.

### Internal product definition

Agonez is a resistance-training knowledge, prescription, and analysis system focused on strength and hypertrophy. It currently joins an exercise/muscle atlas with a relational training-plan builder and an on-demand model of muscle stimulus, local muscle recovery load, and joint recovery load. It is not yet an athlete execution or workout-history system.

---

## 2. Product positioning

### Category

Agonez should be positioned as a **training knowledge and programming system**, not as another set-and-rep tracker.

The product connects:

```text
wiedza treningowa
        ↓
mięśnie, biomechanika i konkretne techniki ćwiczeń
        ↓
budowa planu
        ↓
analiza bodźca i modelowanego kosztu regeneracji
        ↓
modele progresji
        ↓
przyszłe wykonanie planu i prowadzenie zawodnika
```

### Positioning statement

> **Proste decyzje na powierzchni. Jawne modele pod spodem.**

Agonez should let a beginner answer “co mam zrobić?”, while letting an advanced lifter or coach inspect “dlaczego system pokazuje właśnie to?”. The deeper layer is a product advantage only when it remains inspectable, qualified, and honest about uncertainty.

### What makes Agonez different

1. **Atlas is connected to programming.** Exercise and muscle knowledge is not isolated editorial content; the same catalog feeds plan construction and analysis.
2. **Exercises are explicit techniques.** A named variation carries its own setup, movement path, failure criteria, recommendations, and modeled exposure rather than being reduced to an umbrella label such as “row” or “press”.
3. **The plan is structured data.** Days, rest days, exercise roles, target muscles, defaults, fallbacks, sets, rep ranges, RIR, loading modes, and progression metadata are modeled explicitly.
4. **Analysis exposes its reasoning.** Current results contain per-set provenance, intentional/incidental stimulus splits, diagnostics, model parameters, and a recovery timeline.
5. **Estimates are called estimates.** ETU, MRU, JRU, recovery hours, FCSA demand, and joint exposure are engineering model quantities, not biological measurements or medical verdicts.

### What Agonez is not — yet

- It is not currently a workout execution/logging app.
- It does not currently store athletes, clients, performed sets, actual kilograms, e1RM history, or progression state.
- It does not automatically execute progression policies.
- It does not currently provide a standalone joint/articulation atlas.
- It does not currently have a standalone science blog route.
- It is not a medical, injury-risk, or rehabilitation tool.
- It has no user authentication or plan ownership yet; current plan data is application-global. Do not market private accounts or client management before that boundary exists.

---

## 3. Audience

### Beginner

#### Audience truth

You have started training, but exercise names, technique cues, RIR, rep ranges, and plan structure feel like disconnected pieces.

#### Recommended headline

> **Zacząłeś ćwiczyć i wszystko wydaje się niepotrzebnie skomplikowane?**

#### Supporting copy

> Sprawdź, które mięśnie pracują w danym ćwiczeniu, zobacz technikę krok po kroku i zrozum, jak serie, powtórzenia oraz RIR składają się na plan.

#### Emotional promise

> **Nie musisz wiedzieć wszystkiego na starcie. Agonez pomoże Ci ułożyć elementy w spójną całość.**

#### Best first action

`Otwórz Atlas ćwiczeń`

#### Tone guardrail

Never imply that the beginner is careless or unintelligent. The problem is fragmented information and missing structure, not the person.

### Advanced lifter

#### Audience truth

You already train consistently. Now you want to compare exercises, understand where stimulus goes, see hidden work performed by assisting muscles, and reason about fatigue and recovery more precisely.

#### Recommended headline

> **Trenujesz już jakiś czas i chcesz naprawdę zrozumieć swój plan?**

#### Supporting copy

> Porównuj konkretne warianty ćwiczeń, analizuj rozkład bodźca, obciążenie stawów i modelowany dług regeneracyjny. Zejdź od programu do pojedynczej serii i zobacz źródło wyniku.

#### Emotional promise

> **Zobacz więcej niż liczbę serii na partię.**

#### Best first action

`Zobacz, jak działa Analiza`

### Coach

#### Audience truth

You already know how to coach. You need structured tools that reduce repetitive work, make assumptions explicit, and help you audit a program without taking decision-making away from you.

#### Recommended headline

> **Prowadzisz zawodników? Projektuj i analizuj plany w jednym systemie.**

#### Supporting copy

> Buduj mikrocykle z jasno zdefiniowanymi rolami ćwiczeń, zamiennikami, celami, RIR i modelami progresji. Analizuj zapisany plan i eksportuj jego uproszczoną strukturę do zewnętrznej kontroli.

#### Emotional promise

> **Agonez nie zastępuje trenera. Daje mu lepszy model roboczy i bardziej przejrzyste narzędzia.**

#### Best first action

`Otwórz Kreator planu`

#### Current-scope caveat

The current product supports plan creation and analysis, not athlete assignment, accounts, client histories, or workout execution. Coach/client operations belong in the roadmap section.

---

## 4. Hero concepts

### Concept A — recommended

**Eyebrow**

> ATLAS ĆWICZEŃ · KREATOR PLANÓW · ANALIZA TRENINGU

**Headline**

> **Zrozum trening. Zbuduj plan, który ma sens.**

**Supporting copy**

> Agonez łączy anatomię, biomechanikę i praktykę programowania. Zacznij od prostych odpowiedzi, a gdy chcesz — sprawdź modele bodźca, obciążenia i regeneracji stojące za planem.

**Primary CTA**

> Otwórz Atlas

**Secondary CTA**

> Zobacz Analizę planu

**Proof strip**

> Ponad 150 opisanych technik ćwiczeń · interaktywna anatomia · plan od serii do mikrocyklu

Use “ponad 150” rather than a permanently hard-coded `159` on the final page unless the count is bound to live catalog data.

### Concept B — more approachable

**Headline**

> **Od pierwszej serii do przemyślanego planu.**

**Supporting copy**

> Dowiedz się, jak wykonać ćwiczenie, co ono trenuje i gdzie pasuje w planie. Bez udawania, że ciało da się opisać jedną idealną liczbą.

**CTA pair**

> Zacznij od ćwiczenia
>
> Buduję plany treningowe

### Concept C — more technical

**Headline**

> **Trening jako system, nie lista ćwiczeń.**

**Supporting copy**

> Modeluj role ćwiczeń, bodziec mięśniowy, lokalny koszt regeneracji i ekspozycję stawów. Każdy wynik prowadzi z powrotem do konkretnego dnia, ćwiczenia i serii.

### Hero visual concept

Use one product-derived composition rather than a generic gym photograph:

- the cracked-face Agonez mark as the brand anchor;
- interactive front/rear anatomy with an ETU heatmap;
- a compact plan timeline entering the anatomy view;
- a small, legible provenance detail such as `Dzień 3 → Incline Press → seria 2 → klatka obojczykowa`;
- an unobtrusive label: `modelowany wynik · nie pomiar bezpośredni`.

The hero must communicate usefulness before introducing acronyms. ETU/FCSA can appear as secondary labels inside the product visual, not as the main headline.

---

## 5. Core value proposition

### Recommended four-part value story

#### 1. Najpierw zrozum ćwiczenie

> Zobacz konkretną technikę, zaangażowane mięśnie, zalecane zakresy powtórzeń i najczęstsze błędy.

#### 2. Potem zbuduj strukturę

> Ułóż dni treningowe i odpoczynkowe, role ćwiczeń, zamienniki, serie, zakresy powtórzeń oraz RIR.

#### 3. Sprawdź, co wynika z planu

> Uruchom analizę zapisanego szkicu i zobacz rozkład bodźca, modelowany koszt regeneracji oraz obciążenie stawów.

#### 4. Zejdź poziom głębiej

> Sprawdź założenia, parametry i źródło każdej składowej. Model ma pomagać w decyzji — nie udawać biologicznej pewności.

### Short value line for repeated use

> **Od wiedzy o ruchu do decyzji o planie.**

---

## 6. Product capabilities

### Muscle Atlas

**Status:** [IMPLEMENTED] — `Available`

The inspected snapshot contains 47 muscle records. Current muscle detail pages expose localized names and articles, morphology, architecture, fiber-type bias, fiber length, pennation, PCSA/FCSA-related fields, programming traits, related exercises, references, videos, a hero image, a gallery, and interactive anatomical location.

**Recommended customer copy**

> **Poznaj mięsień, zanim zaczniesz liczyć mu serie.**
>
> Anatomia, funkcja, architektura, udział typów włókien i ćwiczenia, które dostarczają mu modelowany bodziec — w jednym miejscu.

**Beginner layer**

> Gdzie znajduje się mięsień, co robi i które ćwiczenia go angażują?

**Advanced layer**

> Jak jego architektura, długość włókien, pennacja i szacowane FCSA są reprezentowane w modelu Agonez?

**Important limitation**

FCSA is not a count of muscle fibers and is not a direct measure of hypertrophic potential. In Agonez it is a modeled force-capacity reference and normalization denominator.

### Joint / Articulation Atlas

**Status:** [PARTIALLY IMPLEMENTED] + [EXPERIMENTAL MODEL] — public label: `In development`

There is no standalone joint atlas route or canonical joint database table. The implemented system currently models 11 joint/functional-articulation identifiers inside exercise vectors and plan analysis, including glenohumeral, acromioclavicular, scapulothoracic, elbow, wrist, cervical spine, lumbar spine, hip, tibiofemoral, patellofemoral, and talocrural regions.

**Safe customer copy now**

> **Zobacz, które stawy i obszary funkcjonalne są obciążane przez ćwiczenie.**
>
> Agonez pokazuje modelowaną ekspozycję stawów na poziomie ćwiczenia i całego planu. Osobny Atlas stawów jest w rozwoju.

**Do not claim yet**

- a “complete joint atlas”;
- full ROM/reference articles for every articulation;
- injury-risk or tissue-safety scoring;
- exact joint forces or recovery times.

### Exercise Atlas

**Status:** [IMPLEMENTED] — `Available`

The inspected snapshot contains 159 exercises, each with technique content, video links, a recommended rep profile, an image, and a complete engine row. The current UI supports search, facets, sorting, list/grid views, detail pages, videos, structured technique, ETU/recovery anatomy heatmaps, joint markers, and quantitative/classification data.

**Recommended customer copy**

> **Nie „wyciskanie”. Konkretna technika, konkretne założenia.**
>
> Każde ćwiczenie w Atlasie jest opisane jako określony wariant: ze sprzętem, ustawieniem, torem ruchu, zakresem, kryteriami upadku technicznego i własnym profilem modelowanej ekspozycji.

#### Stimulus

> Zobacz, do których mięśni trafia modelowany bodziec i jak duży jest względem ich szacowanej zdolności do generowania siły.

Current visual truth: the anatomy heatmap can show ETU or recovery exposure normalized against each muscle’s projected FCSA.

#### ETU

> ETU to model rozdziału efektywnego bodźca napięciowego na poszczególne mięśnie. Nie jest pomiarem EMG ani procentem aktywacji.

At catalog level, `etu_vector` estimates the stimulus of one standardized effective repetition for each muscle. At plan-analysis level, the current evaluator multiplies that vector by an effective-repetition lookup derived from RIR.

#### Systemic Propulsive FCSA Demand

> Modelowany ekwiwalent łącznej zdolności mięśniowej potrzebnej, aby w najbardziej wymagającej fazie powtórzenia przeciwstawić się zewnętrznemu obciążeniu.

This is an estimated mechanical-demand quantity in FCSA-equivalent cm². It is not total fatigue, hypertrophic stimulus, or a directly measured force.

#### Technique

Current structured technique can contain:

- short setup/execution/focus/stop summary;
- movement overview and plane;
- equipment, start position, grip, stance, and bracing;
- concentric/eccentric phases, end position, ROM, and tempo notes;
- internal and external cues;
- technical failure, RIR 1 indicators, and an RIR 0 definition;
- common mistakes, safety notes, and individualization.

#### Demonstration

YouTube demonstrations are embedded on exercise detail pages. Treat them as demonstrations selected for a record, not as universal proof that one presentation is the only correct execution for every athlete.

#### Recovery cost

The exercise detail view shows muscle recovery exposure as active tension multiplied by a muscle/exercise recovery-cost modifier. It can overlay joint-load exposure. These are comparative model quantities, not forecasts of soreness, tissue healing, or injury.

#### Classification

Implemented classification includes:

- body region;
- programming target category;
- mechanics tier (`Heavy Compound`, `Secondary Compound`, `Isolation`, `Stability Isometric`);
- resistance source (barbell, dumbbell, cable, selectorized/plate-loaded/Smith machine, bodyweight, and others);
- execution pattern (bilateral, unilateral, alternating);
- high-, moderate-, and low-load rep-range recommendations.

### Training Plan Builder

**Status:** [IMPLEMENTED] — `Available`, but accurately described as a draft/MVP workflow

The builder creates an ordered microcycle rather than a simple calendar note. It supports explicit rest days, workout units, exercise slots, roles, goals, target muscles, default and fallback variants, sets, rep ranges, RIR, loading modes/cycles, and progression-model metadata. Drafts use stable IDs, revision metadata, optimistic locking, duplication, save validation, and JSON import/export.

**Recommended customer copy**

> **Buduj plan z elementów, które mają znaczenie.**
>
> Zdefiniuj dni treningowe i odpoczynkowe, rolę każdego ćwiczenia, cele, zamienniki, serie, zakresy powtórzeń oraz RIR. Potem przejdź do Analizy zapisanego szkicu.

**Accuracy note for the design agent**

Do not call current analysis “continuous”, “instant”, or “live while typing”. The current UI analyzes the persisted draft on demand in a separate `ANALIZA` tab and marks results stale when the plan changes.

#### Exercise roles

Implemented roles are:

- główna progresja (`PRIMARY_PROGRESSIVE`);
- wtórna progresja (`SECONDARY_PROGRESSIVE`);
- akumulacja objętości (`VOLUME_ACCUMULATION`);
- akcesorium (`ACCESSORY`).

A slot represents a stable purpose in the plan. It can contain one default exercise and fallback alternatives that preserve the slot’s identity and intent. Only the default currently enters analysis.

#### Prescription dimensions

Implemented prescription fields include:

- ordered sets;
- rep range per set;
- RIR 0–4;
- high/moderate/low loading mode;
- optional repeating loading cycles;
- a minimum-volume threshold and volume-axis fields in the model.

Loading modes and cycles are stored and editable but do not currently change analysis calculations or compact export. Volume gating exists in the backend; the current UI does not yet expose full modulation controls.

### Plan Analysis

**Status:** [IMPLEMENTED] + [EXPERIMENTAL MODEL] — recommended public label: `Model eksperymentalny`

**Recommended customer copy**

> **Plan to więcej niż suma serii.**
>
> Uruchom analizę zapisanego szkicu i zobacz, gdzie trafia bodziec, które mięśnie wykonują pracę celową lub poboczną oraz jak model zachowuje dług regeneracyjny między dniami.

Current analysis provides:

- total and weekly-normalized ETU;
- ETU normalized to estimated muscle FCSA;
- intentional, incidental, and unclassified stimulus;
- before/after recovery state at each day boundary;
- local muscle recovery summaries;
- joint exposure/JRU summaries;
- a repeating-microcycle convergence simulation;
- contribution provenance down to plan day, exercise, and set;
- model parameters, timing assumptions, and data-quality diagnostics.

Current analysis does not include neural fatigue, systemic fatigue, cardiovascular/metabolic fatigue, connective-tissue/tendon models, actual session performance, or athlete-specific readiness.

### Progression Models

**Status:** [PARTIALLY IMPLEMENTED] — public label: `In development`

The current catalog contains 14 localized progression descriptions, including single progression, multiple double/triple-progression variants, e1RM top-set/back-off, and APRE 3/6/10. A model can be assigned to an exercise variant and is included as descriptive metadata in export.

**Recommended customer copy**

> **Nazwij strategię progresji zamiast ukrywać ją w notatce.**
>
> Przypisz ćwiczeniu model progresji i zachowaj jego zasady obok recepty treningowej. Automatyczne wykonywanie polityk progresji powstanie wraz z trybem prowadzenia zawodnika.

The current application explicitly labels this as metadata only. Selecting a model does not modify sets, calculate the next load, or run a progression algorithm.

### Recovery Modelling

**Status:** [IMPLEMENTED] + [EXPERIMENTAL MODEL]

The current model distinguishes local muscle recovery load and joint recovery load. It adds model-derived hours-to-fresh debt after workouts, subtracts elapsed time, and repeats the microcycle until a periodic state converges or reaches a 256-cycle limit.

**Recommended customer copy**

> **Zobacz modelowany koszt, nie fałszywą obietnicę dokładnej regeneracji.**
>
> Agonez estymuje lokalny dług mięśni i obciążenie stawów w rytmie mikrocyklu. Wynik pomaga porównywać strukturę planu — nie przewiduje dokładnie, kiedy biologicznie „będziesz gotowy”.

The UI already includes suitable caveat language: the result is not soreness, protein synthesis, injury, or literal tissue-healing time.

### Science Knowledge Base

**Status:** [PARTIALLY IMPLEMENTED] — public label: `In development`

The muscle detail view already exposes a localized Markdown “Muscle Bible”, external article links, videos, and anatomical galleries. The repository also contains extensive domain notes on biomechanics, physiology, hypertrophy, effective reps, rep ranges, PCSA/FCSA, and mechanotransduction. There is no standalone blog/knowledge-base route in the current app.

**Recommended customer copy**

> **Od pojęcia do decyzji treningowej.**
>
> Rozwijana baza wiedzy połączy anatomię, biomechanikę, fizjologię i programowanie z tym, co widzisz w Atlasie i Analizie.

Do not advertise a finished “science blog” yet. The domain notes are source material and working research notes, not all publication-ready, peer-reviewed articles.

### Athlete Management

**Status:** [PLANNED] — public label: `Coming soon`

**Recommended customer copy**

> **Plan w czasie, nie tylko na papierze.**
>
> Kolejny etap Agonez połączy plan z historią wykonania: ciężarami, powtórzeniami, RIR, zmianami ćwiczeń, deloadami, reloadami i trendami e1RM.

Potential roadmap scope supported by domain notes:

- assign/run a plan over weeks;
- derive a session prescription from the plan;
- record actual load, reps, and RIR;
- inspect history by workout and exercise;
- record plan-change and deload/reload events;
- support progression decisions and optional automation;
- track tested/estimated 1RM.

Do not claim any of these are available now.

### Mobile Training Mode

**Status:** [PLANNED] — public label: `Coming soon`

**Recommended customer copy**

> **Podczas treningu liczy się następna seria.**
>
> Planowany tryb mobilny pokaże dzisiejszy trening, pozwoli zapisać wykonanie i da szybki dostęp do techniki oraz Atlasu bez opuszczania sesji.

Roadmap notes mention:

- today’s workout;
- actual weights, reps, and RIR;
- athlete notes/comments;
- warm-up and stretching notes;
- fallback workout choices after a missed day;
- exercise/machine identification and technique reference;
- RIR calibration or max-test events.

---

## 7. Feature Cards

### Atlas mięśni

**Audience:** Beginner, advanced lifter, coach

**Status:** Available — [IMPLEMENTED]

**One-line value:** Zrozum, gdzie znajduje się mięsień, co robi i które ćwiczenia dostarczają mu modelowany bodziec.

**Short description:** Interaktywna anatomia łączy artykuł, galerię, funkcję i ćwiczenia z danymi o morfologii oraz architekturze.

**Deeper technical explanation:** Records include mass, volume, fiber-type bias, architecture, optimal fiber length, pennation, PCSA/FCSA estimates, SMH/strength-curve traits, and exercise ranking by ETU where measured. FCSA is an estimate used for capacity normalization, not a direct count of fibers or growth potential.

**Suggested visual:** Selected muscle on the front/rear SVG, with a simple “where / what it does / exercises” layer and an expandable architecture/FCSA layer.

**Relevant repository evidence:** `web-fe/src/views/MuscleDetailView.vue`, `be/src/agonez_api/modules/atlas/schemas.py`, `__docs__/database/data-dictionary.md`, `media/muscles/`, `media/galleries/muscles/`, `media/anatomy.svg`.

### Atlas stawów

**Audience:** Advanced lifter, coach

**Status:** In development — [PARTIALLY IMPLEMENTED] [EXPERIMENTAL MODEL]

**One-line value:** Sprawdź, które stawy i obszary funkcjonalne są mechanicznie eksponowane przez ćwiczenie lub plan.

**Short description:** Obecna aplikacja pokazuje stawy jako warstwę ćwiczenia i Analizy; osobny Atlas stawów jeszcze nie istnieje.

**Deeper technical explanation:** Joint load is a within-joint normalized index for 11 governed-in-prompt identifiers. JRU and hours-to-fresh are model outputs, not reaction force, tissue damage, safety, or injury probability. There is no canonical joint table today.

**Suggested visual:** Amber joint rings over neutral anatomy, with a visible “model ekspozycji · nie ocena bezpieczeństwa” label.

**Relevant repository evidence:** `prompts/estimate/4-joint_recovery_exposure_vector.md`, `web-fe/src/i18n/locales/pl/analysis.ts`, `web-fe/src/components/plans/analysis/JointSummary.vue`, `__docs__/findings/ambiguities.md`.

### Atlas ćwiczeń

**Audience:** Everyone

**Status:** Available — [IMPLEMENTED]

**One-line value:** Porównuj konkretne warianty po technice, mięśniach, zakresie obciążenia i modelowanej ekspozycji.

**Short description:** Wyszukiwalny katalog prowadzi od listy lub kafelka do pełnej instrukcji, filmu, wizualizacji anatomicznej i danych przydatnych w układaniu planu.

**Deeper technical explanation:** The inspected snapshot contains 159 catalog and engine rows with structured technique, videos, images, rep profiles, systemic FCSA demand, muscle vectors, recovery modifiers, and joint vectors.

**Suggested visual:** Exercise image beside synchronized ETU anatomy and a three-row technique summary.

**Relevant repository evidence:** `web-fe/src/views/AtlasIndexView.vue`, `web-fe/src/views/ExerciseDetailView.vue`, `prompts/estimate/6-exercise_technique.md`, `media/exercises/`, `__docs__/database/schema-overview.md`.

### Biblioteka techniki

**Audience:** Beginner, coach

**Status:** Available — [IMPLEMENTED]

**One-line value:** Wykonuj ten konkretny wariant, a nie przypadkową wersję ćwiczenia o podobnej nazwie.

**Short description:** Instrukcje obejmują ustawienie, ruch, ROM, wskazówki, upadek techniczny, RIR i częste błędy.

**Deeper technical explanation:** Technique content is a structured JSON document localized through exercise translations; the provisioning contract explicitly requires variant-specific rather than generic-family instructions.

**Suggested visual:** Expandable sequence: `Ustawienie → Wykonanie → Przerwij, gdy`, with a nearby demo frame.

**Relevant repository evidence:** `web-fe/src/components/detail/TechniqueGuide.vue`, `web-fe/src/i18n/locales/pl/atlas.ts`, `prompts/estimate/6-exercise_technique.md`, `core.exercises.technique` documented in `__docs__/database/data-dictionary.md`.

### Kreator planu

**Audience:** Intermediate/advanced lifter, coach

**Status:** Available / draft — [IMPLEMENTED]

**One-line value:** Buduj uporządkowany mikrocykl, nie luźną listę ćwiczeń.

**Short description:** Modeluj dni i odpoczynek, jednostki treningowe, role, cele, zamienniki oraz receptę każdej serii.

**Deeper technical explanation:** The relational hierarchy is Plan → Revision → Day → Workout Unit → Slot → Variant → Set. The editor validates order, one default variant, reps/RIR, catalog references, and stale-write conflicts.

**Suggested visual:** One day card opening into role-colored slots and three set rows, followed by a clear arrow to `ANALIZA`.

**Relevant repository evidence:** `web-fe/src/views/PlanCreatorView.vue`, `web-fe/src/components/plans/PlanEditor.vue`, `be/src/agonez_api/modules/plans/schemas.py`, `__docs__/architecture/domain-map.md`.

### Analiza planu

**Audience:** Advanced lifter, coach

**Status:** Available as experimental model — [IMPLEMENTED] [EXPERIMENTAL MODEL]

**One-line value:** Zobacz rozkład bodźca i modelowanego długu między dniami planu.

**Short description:** Analiza zapisanego szkicu pokazuje bodziec mięśni, ekspozycję stawów, stan przed i po treningu oraz źródło każdej składowej.

**Deeper technical explanation:** The request-time engine resolves default variants and active sets, computes ETU/MRU/JRU contributions, normalizes summaries, and simulates a repeating microcycle. It exposes diagnostics and model parameters and persists no analysis result.

**Suggested visual:** Microcycle timeline connected to before/after anatomy, a ranked muscle list, and a provenance drawer.

**Relevant repository evidence:** `web-fe/src/components/plans/analysis/PlanAnalysis.vue`, `be/src/agonez_api/modules/plans/analysis/evaluator.py`, `__docs__/flows/execution-pipeline.md`.

### Modele progresji

**Audience:** Intermediate/advanced lifter, coach

**Status:** In development — [PARTIALLY IMPLEMENTED]

**One-line value:** Przechowuj logikę progresji obok ćwiczenia, zamiast zostawiać ją w domyśle.

**Short description:** Wybierz jeden z opisanych modeli i zachowaj jego zastosowanie oraz instrukcję przy wariancie ćwiczenia.

**Deeper technical explanation:** Fourteen localized models are cataloged and assignable, but they are prose metadata. The runtime does not execute single/double/triple progression, APRE, or e1RM policies and does not calculate the next load.

**Suggested visual:** A progression selector with `Kiedy stosować` and `Jak stosować`, plus a small `automatyzacja — wkrótce` annotation.

**Relevant repository evidence:** `web-fe/src/components/plans/ProgressionModelControl.vue`, `web-fe/src/components/plans/ProgressionModelInfo.vue`, `be/src/agonez_api/migrations/versions/0003_progression_models.sql`, `__docs__/findings/ambiguities.md`.

### Model regeneracji

**Audience:** Advanced lifter, coach

**Status:** Experimental — [IMPLEMENTED] [EXPERIMENTAL MODEL]

**One-line value:** Porównuj, jak stres mięśni i stawów kumuluje się oraz opada w mikrocyklu.

**Short description:** Agonez rozdziela bodziec od kosztu i pokazuje modelowany dług gotowości przed oraz po każdym dniu.

**Deeper technical explanation:** MRU uses effective reps × active tension × recovery modifier × RIR/cumulative multipliers. JRU uses joint exposure with the same runtime multipliers. Linear velocities convert these units to hours-to-fresh; they are engineering calibration parameters.

**Suggested visual:** Before/after anatomy and a thin recovery-debt timeline, with the caveat visible rather than hidden in a tooltip.

**Relevant repository evidence:** `be/src/agonez_api/modules/plans/analysis/parameters.py`, `be/src/agonez_api/modules/plans/analysis/evaluator.py`, `web-fe/src/i18n/locales/pl/analysis.ts`.

### Import / eksport planu dla AI

**Audience:** Coach, technically minded lifter

**Status:** Available — [IMPLEMENTED]

**One-line value:** Przenieś uproszczoną strukturę planu do zewnętrznej analizy i z powrotem.

**Short description:** Eksportuj czytelny JSON lub zaimportuj walidowany dokument oparty na slugach Atlasu.

**Deeper technical explanation:** `agonez-plan-sanity-v2` exports resolved active default exercises, sets, RIR, and progression descriptions. The compact format intentionally omits fallbacks, targets, loading metadata, notes, descriptions, and internal IDs. This is interoperability, not an embedded AI coach.

**Suggested visual:** Compact JSON preview between an Agonez plan card and a neutral `narzędzie AI` node; avoid chatbot imagery.

**Relevant repository evidence:** `web-fe/src/components/plans/PlanExportDialog.vue`, `web-fe/src/components/plans/PlanImportDialog.vue`, `be/src/agonez_api/modules/plans/analysis/service.py`, `__docs__/api/endpoint-flows.md`.

### Baza wiedzy

**Audience:** Beginner, advanced lifter, sports-science student

**Status:** In development — [PARTIALLY IMPLEMENTED]

**One-line value:** Ucz się pojęcia tam, gdzie staje się ono decyzją treningową.

**Short description:** Artykuły mięśniowe i rozwijana baza wiedzy mają łączyć anatomię, fizjologię, biomechanikę oraz programowanie z narzędziami Agonez.

**Deeper technical explanation:** Muscle Markdown, references, and videos are already served; broad domain notes exist in-repo, but there is no public blog route and working notes should not automatically become published claims.

**Suggested visual:** A scientific-note card linked directly to a highlighted model field or exercise decision.

**Relevant repository evidence:** `web-fe/src/components/detail/MarkdownArticle.vue`, `web-fe/src/views/MuscleDetailView.vue`, `__docs__/domain/`.

### Prowadzenie zawodnika

**Audience:** Coach, committed lifter

**Status:** Coming soon — [PLANNED]

**One-line value:** Połącz plan z historią jego rzeczywistego wykonania.

**Short description:** Przyszły moduł ma śledzić sesje, wyniki, zmiany planu, progres, deloady/reloady i e1RM w czasie.

**Deeper technical explanation:** No athlete, assignment, scheduled session, performed set, load history, e1RM history, or progression state currently exists in the database/runtime.

**Suggested visual:** Muted roadmap timeline from `Plan` to `Prescription` to `Execution` to `History`, clearly marked `Wkrótce`.

**Relevant repository evidence:** `__docs__/architecture/domain-map.md`, `__docs__/flows/execution-pipeline.md`, `__docs__/domain/journal/26-09.md`.

### Mobilny tryb treningowy

**Audience:** Beginner, lifter, coached athlete

**Status:** Coming soon — [PLANNED]

**One-line value:** Miej dzisiejszy plan, technikę i zapis wykonania pod ręką na sali.

**Short description:** Planowany widok mobilny ma prowadzić przez sesję, zapisywać wykonanie i zapewniać szybki dostęp do Atlasu.

**Deeper technical explanation:** The idea is documented, but there is no current route, session model, performed-set persistence, or mobile execution UI.

**Suggested visual:** One restrained phone frame with today’s exercise and technique cue; keep the whole card visibly roadmap-only.

**Relevant repository evidence:** `__docs__/domain/journal/26-09.md`, explicit absences in `__docs__/README.md`.

---

## 8. Science / Methodology Layer

### Modelling philosophy

Recommended section headline:

> **Nie mierzymy biologii z ekranu. Budujemy jawny model decyzji.**

Supporting copy:

> Trening siłowy odbywa się pod niepewnością. Agonez porządkuje założenia, estymuje konsekwencje planu i pokazuje skąd bierze się wynik. Tam, gdzie nie ma pomiaru, nazywamy rzecz modelem.

Agonez’s strongest science positioning is not “we have the optimal number.” It is:

- variables are named;
- assumptions are visible;
- a normalized reference athlete is defined;
- exercise techniques are constrained;
- model quantities have separate meanings;
- results retain per-set provenance;
- missing/malformed data produces diagnostics instead of fabricated certainty;
- uncertainty and unimplemented mechanisms are explicitly disclosed.

### FCSA

Within the estimation prompts, FCSA means **Force-Transmitting Cross-Sectional Area**: fiber-derived PCSA projected onto the tendon’s line of pull. It is an estimated anatomical/mechanical quantity expressed in cm².

Agonez uses FCSA in two ways:

1. as a force-capacity-equivalent language for estimated muscle demand;
2. as a denominator for comparing a muscle’s ETU or recovery load against its modeled capacity.

Recommended customer explanation:

> **FCSA pomaga sprowadzić różne mięśnie i ćwiczenia do wspólnego punktu odniesienia: szacowanej powierzchni zdolnej przenosić siłę wzdłuż ścięgna.**

Required caveats:

- FCSA is not measured for the current user.
- It is not a fiber count.
- It is not a direct hypertrophy-potential score.
- The catalog uses projected estimates derived from morphology and architecture assumptions.
- A larger FCSA does not automatically mean that an exercise is “better”.

### Systemic Propulsive FCSA Demand

The model first reasons from effective external resistance and joint moments, then allocates required capacity across task-relevant muscles. The sum of the propulsive contribution vector equals the systemic demand within rounding tolerance.

Recommended customer explanation:

> **Systemowe zapotrzebowanie FCSA szacuje, jak dużej łącznej zdolności do generowania siły wymaga najbardziej wymagająca faza powtórzenia przy przyjętym obciążeniu i technice.**

It does not represent:

- hypertrophic stimulus;
- total muscle activation;
- systemic fatigue;
- calories or metabolic cost;
- the user’s personal limit.

### ETU

At exercise-catalog level, Agonez models:

```text
ETU_m = Active Tension Exposure_m × Hypertrophic Tension Quality Modifier_m
```

`Active Tension Exposure` includes meaningful active contractile demand, not just net propulsive force. It may include stabilizing, co-contracting, isometric, or load-transmitting roles where a plausible mechanical pathway exists.

The quality modifier asks whether the tension occurred under conditions more or less hypertrophically valuable than a conventional reference repetition: muscle length, high-tension ROM, contraction mode, resistance-profile alignment, duration of meaningful tension, and muscle-specific stretch-mediated potential.

At current plan-analysis runtime:

```text
set ETU_m = effective reps from RIR × exercise ETU vector_m
```

The effective-repetition lookup is currently:

```text
RIR 0 → 5
RIR 1 → 4
RIR 2 → 3
RIR 3 → 2
RIR 4 → 1
```

The current evaluator does not use the prescribed rep range in this equation. That limitation should remain explicit in technical copy.

Recommended customer explanation:

> **ETU to estymata tego, jak modelowany bodziec napięciowy jednego efektywnego powtórzenia rozkłada się między mięśnie.**

ETU is not:

- EMG;
- activation percentage;
- directly observed mechanical tension;
- a guaranteed dose of hypertrophy;
- a universal biological unit validated outside the Agonez model.

Normalized ETU (`ETU / estimated FCSA`) is a reference-equivalent ratio. A value above `1.0` can arise from the quality modifier and does not mean more than 100% of fibers were recruited.

### Recovery

Current muscle recovery contribution:

```text
base MRU_m =
    effective reps
    × active tension exposure_m
    × muscle–exercise recovery cost modifier_m

set MRU_m =
    base MRU_m
    × RIR recovery multiplier
    × within-workout cumulative-set multiplier
```

Current joint recovery contribution:

```text
joint exposure_j = effective reps × joint-load vector_j

set JRU_j =
    joint exposure_j
    × RIR recovery multiplier
    × within-workout cumulative-set multiplier
```

Workout contributions are converted to a linear `hours_to_fresh` debt using current engineering velocities (`0.70` for muscle density and `1.05` for joints). A repeating microcycle is simulated until its start/end debt converges or the model reports divergence.

Recommended customer explanation:

> **Model regeneracji pokazuje, jak obciążenie może kumulować się między dniami planu. To narzędzie porównawcze i diagnostyczne, nie zegar biologiczny.**

Explicit limitations:

- one global muscle-recovery velocity is currently used, not muscle-specific velocities;
- joint recovery uses an abstract model index;
- no athlete-specific sleep, nutrition, stress, training history, or readiness is included;
- no neural, systemic, cardiovascular/metabolic, tendon, or connective-tissue model exists;
- hours-to-fresh is not tissue-healing time, soreness, or injury recovery.

### Exercise specificity

Recommended section headline:

> **Technika jest częścią nazwy ćwiczenia.**

Supporting copy:

> Ustawienie ławki, chwyt, źródło oporu, podparcie tułowia i tor ruchu mogą zmienić wymagania mechaniczne. Dlatego Agonez opisuje jawne warianty, zamiast wrzucać wszystkie do jednego worka.

Repository support:

- the technique provisioning contract explicitly says “specific variant, not generic exercise family”;
- the catalog contains separate rows for incline/flat/decline presses, high/low-bar squats, multiple rows and pulldowns, supported/unsupported variants, and equipment-specific forms;
- each row can carry its own technique, load capacity, rep profile, and engine vectors.

### Reference athlete

The estimation pipeline defines a standardized reference athlete:

```text
sex: male
body mass: 85 kg
training status: advanced, proportionally developed, drug-free
barbell bench press 1RM: 100 kg
barbell back squat 1RM: 140 kg
conventional deadlift 1RM: 160 kg
default working-load context: approximately 8–12 reps at RIR 1–2
```

Recommended customer explanation:

> **Porównanie ćwiczeń wymaga wspólnej bazy. Dlatego metryki Atlasu są kalibrowane do jednego zawodnika referencyjnego i jednej konwencji wykonania. Twój wynik może istotnie się różnić.**

Why normalization exists:

- it makes exercise estimates internally comparable;
- it prevents every catalog record from silently assuming a different body mass and strength level;
- it provides a documented baseline for load capacity, bodyweight contribution, and mechanical geometry.

It does not make the catalog personalized. Do not use second-person claims such as “ty wygenerujesz 82 cm² FCSA” without a real athlete model.

### Uncertainty and limitations

Recommended compact disclosure:

> **Wartości Agonez są modelowanymi estymatami opartymi na jawnych założeniach. Pomagają porównywać ćwiczenia i strukturę planu, ale nie są bezpośrednim pomiarem organizmu ani poradą medyczną.**

Longer methodology disclosure:

- morphology and FCSA values are catalog estimates for the reference model;
- exercise vectors are estimated from biomechanics and documented calibration prompts;
- ETU includes a heuristic hypertrophic-quality modifier;
- effective reps are currently inferred from RIR through a fixed lookup;
- rep ranges and loading cycles do not currently alter analysis equations;
- recovery velocities are calibration parameters, not physiological constants;
- joint exposure is comparable primarily across exercises loading the same joint;
- analysis can return partial results with diagnostics when data is missing or malformed;
- model non-convergence is a diagnostic of the model/plan combination, not a diagnosis of overtraining.

### Methodology UI recommendation

Use progressive disclosure:

1. plain-language conclusion;
2. short “Jak to czytać?” explanation;
3. expandable equation/assumptions;
4. visible limitations;
5. repository/literature references where editorially reviewed.

Do not turn the methodology section into a wall of equations in the initial scroll. Academic respect should come from precise definitions and honest constraints, not visual density alone.

---

## 9. Recommended Home Page Narrative

### 1. Hero — understand the product in 10 seconds

**Message:** knowledge + plan building + model-based analysis.

**Copy:** `Zrozum trening. Zbuduj plan, który ma sens.`

**Visual:** cracked-face mark, anatomy heatmap, compact plan timeline.

**CTA:** `Otwórz Atlas` / `Zobacz Analizę planu`.

### 2. Three audience entry points

Three compact paths:

1. `Dopiero zaczynam` → technique, muscles, RIR, plan basics.
2. `Chcę wejść głębiej` → exercise comparison, ETU, recovery, biomechanics.
3. `Układam plany innym` → structured slots, fallbacks, roles, progression metadata, analysis, import/export.

Each path should jump to the same product story at a different depth, not create three disconnected landing pages.

### 3. The product loop

Use one simple sequence:

```text
Poznaj ćwiczenie → Zbuduj mikrocykl → Uruchom analizę → Sprawdź źródło wyniku
```

This section answers “what can I do?” before the page introduces scientific terminology.

### 4. Exercise Atlas — the most concrete proof

Show an actual exercise image, technique summary, anatomical ETU distribution, joint overlay, and recommended rep ranges. Use `ponad 150 technik` only if not bound to live count.

### 5. Plan Builder — structure over spreadsheet ambiguity

Show day/rest structure, slot roles, one fallback, three set rows, and a progression label. Explain that the plan is a relational prescription, not merely notes.

### 6. Plan Analysis — the differentiator

Transition from “build” to “reason”. Show weekly ETU, recovery before a chosen workout, joint summary, and a per-set source trail. Label it as an experimental model and state that the saved draft is analyzed on demand.

### 7. Muscle knowledge model

Move deeper into architecture, fibers, PCSA/FCSA, and related exercises. This is where the visitor discovers that Atlas data drives both visualization and analysis.

### 8. For coaches

Reframe existing capabilities as decision support:

- repeatable plan structure;
- exercise roles and fallbacks;
- explicit targets and incidental work;
- descriptive progression models;
- compact AI interoperability;
- inspectable assumptions and diagnostics.

Then distinguish roadmap items: athlete assignment, execution history, and progression automation.

### 9. Methodology — academic depth

Use the sentence `Nie mierzymy biologii z ekranu. Budujemy jawny model decyzji.` Then progressively disclose FCSA, systemic demand, ETU, MRU/JRU, the reference athlete, and limitations.

### 10. Roadmap — execution ecosystem

Show two future cards only:

- `Prowadzenie zawodnika — wkrótce`;
- `Mobilny tryb treningowy — wkrótce`.

Avoid a broad speculative feature grid. The roadmap should explain the direction from prescription to execution and history.

### 11. Final CTA

Recommended:

> **Zacznij od jednego ćwiczenia. Zobacz, jak głęboko możesz zejść.**
>
> `Otwórz Atlas ćwiczeń`

Secondary coach CTA:

> `Zbuduj szkic planu`

---

## 10. Suggested Headlines / Supporting Copy

### Product-level headlines

- **Zrozum trening. Zbuduj plan, który ma sens.**
- **Trening jako system, nie lista ćwiczeń.**
- **Od wiedzy o ruchu do decyzji o planie.**
- **Zobacz więcej niż liczbę serii na partię.**
- **Proste decyzje na powierzchni. Jawne modele pod spodem.**
- **Plan to więcej niż suma serii.**

### Beginner headlines

- **Zacząłeś ćwiczyć i wszystko wydaje się niepotrzebnie skomplikowane?**
- **Najpierw zrozum ruch. Potem dokładaj ciężar.**
- **Nie musisz wiedzieć wszystkiego na starcie.**

Supporting lines:

- `Sprawdź technikę, mięśnie i zakres powtórzeń bez skakania między przypadkowymi źródłami.`
- `Dowiedz się, co oznacza RIR i jak pojedyncza seria staje się częścią planu.`
- `Agonez porządkuje pojęcia, zamiast zasypywać Cię żargonem.`

### Advanced-lifter headlines

- **Trenujesz już jakiś czas i chcesz naprawdę zrozumieć swój plan?**
- **Porównuj bodziec, koszt i kontekst — nie tylko ciężar na sztandze.**
- **Zejdź od mikrocyklu do pojedynczej serii.**

Supporting lines:

- `Zobacz pracę celową i poboczną, modelowaną ekspozycję stawów oraz stan regeneracji przed kolejnym treningiem.`
- `Porównuj warianty w tej samej, jawnie opisanej konwencji.`
- `Sprawdź parametry i źródło wyniku, zamiast przyjmować jedną magiczną liczbę.`

### Coach headlines

- **Prowadzisz zawodników? Projektuj i analizuj plany w jednym systemie.**
- **Twoja decyzja trenerska. Lepsza infrastruktura pod spodem.**
- **Programuj jawnie: role, cele, zamienniki, progresję.**

Supporting lines:

- `Agonez wspiera audyt planu; nie udaje, że zastąpi doświadczenie trenera.`
- `Zachowaj intencję slotu nawet wtedy, gdy zmieniasz ćwiczenie na fallback.`
- `Eksportuj uproszczoną strukturę do zewnętrznej analizy i importuj ją po walidacji względem Atlasu.`

### Methodology headlines

- **Nie mierzymy biologii z ekranu. Budujemy jawny model decyzji.**
- **Model ma pokazać założenia, nie ukrywać niepewność.**
- **Wspólny punkt odniesienia. Osobne znaczenie każdej metryki.**
- **Estymata, którą można sprawdzić.**

### Roadmap headlines

- **Od planu do historii wykonania.**
- **Następny etap: plan, który żyje razem z treningiem.**
- **Dziś projektowanie i analiza. Jutro wykonanie i prowadzenie w czasie.**

---

## 11. Suggested CTAs

### Primary, currently valid

- `Otwórz Atlas`
- `Przeglądaj ćwiczenia`
- `Znajdź mięsień`
- `Zobacz technikę ćwiczenia`
- `Otwórz Kreator planu`
- `Utwórz szkic planu`
- `Zobacz, jak działa Analiza`

### Audience-routing CTAs

- `Dopiero zaczynam`
- `Chcę wejść głębiej`
- `Układam plany innym`

### Methodology CTAs

- `Jak działa ETU?`
- `Poznaj założenia modelu`
- `Zobacz zawodnika referencyjnego`
- `Sprawdź ograniczenia`

### Roadmap CTAs

Until there is a real notification/waitlist flow, use non-transactional labels such as:

- `Zobacz kierunek rozwoju`
- `Poznaj planowany tryb treningowy`

Do not use `Dołącz do waitlisty`, `Załóż konto`, `Dodaj klienta`, or `Pobierz aplikację` unless those flows are implemented.

---

## 12. Suggested Visual Assets

### Brand assets

| Asset | Use | Notes |
| --- | --- | --- |
| `web-fe/public/logo-mark.png` | Primary cracked-face mark in hero/header | 320×320 transparent crop of the top-left mark; this is the cleanest current logo asset. |
| `media/logo-mark.png` | Brand exploration / variant sheet | Despite the filename, this is the full 3×3 sheet of nine cracked-face logo variants, 1254×1254. Do not place the whole sheet as the final header logo. |
| `prompts/UI/Agonez - UI/UX design brief/agonez.logo.png` | Duplicate source of the full 3×3 sheet | Same image content as `media/logo-mark.png`. |

**Important asset warning:** `web-fe/public/agonez-logo.png` is not an image despite its extension; it currently contains text from an old API contract. Do not use it as a visual asset.

### Anatomy

| Asset | Use | Notes |
| --- | --- | --- |
| `media/anatomy.svg` | Primary interactive anatomy visual | Front and rear views with semantic muscle and joint identifiers. Used by the current app through `/assets/anatomy.svg`. |
| `media/doby_svg.svg` | Historical/source anatomy asset | Appears closely related to `media/anatomy.svg`; prefer the runtime asset above. |

The side view is described as a future v2 item in older UI notes. Do not imply it exists.

### Exercise imagery

Current images live in `media/exercises/`. Useful representative assets for the landing page include:

- `media/exercises/barbell_bench_press.png`;
- `media/exercises/high_bar_back_squat.png`;
- `media/exercises/barbell_deadlift.png`;
- `media/exercises/neutral_grip_lat_pulldown.png`;
- `media/exercises/smith_machine_incline_bench_press.png`;

Always resolve an actual filename or use the runtime media URL instead of guessing an asset path.

There are 172 files in the exercise-image directory for 159 snapshot records because duplicate/`copy` files and apparent filename mistakes exist. Resolve by actual exercise slug/runtime media resolution, not by raw file count.

### Muscle imagery

- Hero/signature images: `media/muscles/{muscle_slug}.png`.
- Galleries: `media/galleries/muscles/{muscle_slug}/`.
- Representative examples: `media/muscles/pectoralis_major_clavicular.png`, `media/muscles/latissimus_dorsi.png`, `media/muscles/deltoid_lateral.png`, `media/muscles/rectus_femoris.png`.

Some gallery images are third-party/reference material. Verify rights and attribution before using them on a public marketing page. Prefer Agonez-owned hero/signature images where provenance is clear.

### Existing product visuals to reproduce from the live UI

No dedicated screenshot files were found in the repository. The design pipeline should use real captures from these implemented routes/components rather than generate fake screenshots:

- `/atlas/exercises` — list/grid, facets, persistent anatomy;
- `/atlas/muscles` — list/grid, anatomy linkage;
- `/atlas/exercises/{slug}` — technique, image/video, ETU/recovery/joint visual;
- `/atlas/muscles/{slug}` — morphology, architecture, gallery, related exercises, Muscle Bible;
- `/plans` — plan library and import;
- `/plans/{id}` — plan editor and analysis.

### Existing visual language

The current UI uses Geist/Geist Mono, first-class light/dark themes, warm stone brand accents, and reserved analytical colors:

- ETU: emerald (`#25b581` dark / `#0d9d6d` light);
- recovery: coral (`#f4635e` dark / `#dd4f4a` light);
- joint exposure: amber (`#e5a13c` dark / `#bf7c14` light);
- brand accent: warm stone (`#d0b487` dark / `#8f6f38` light).

Preserve this semantic color separation. Do not use the brand accent as another heatmap metric.

Visual evidence: `web-fe/src/styles/tokens.css`, `be/docs/frontend-handoff.md`.

---

## 13. Current vs Roadmap Capabilities

| Capability | Internal status | Public treatment | Grounded scope / limitation |
| --- | --- | --- | --- |
| Exercise catalog browsing | [IMPLEMENTED] | Available | Search, filters, sorting, list/grid, localization, images. |
| Exercise detail and technique | [IMPLEMENTED] | Available | Structured exact-variant technique, videos, rep recommendations, quantitative fields. |
| Exercise ETU/recovery/joint visualization | [IMPLEMENTED] [EXPERIMENTAL MODEL] | Available with model disclosure | Model-derived, normalized heatmaps and joint indices. |
| Muscle catalog and detail | [IMPLEMENTED] | Available | 47 snapshot records, anatomy, morphology/architecture, articles, galleries, related exercises. |
| Standalone joint/articulation atlas | [PARTIALLY IMPLEMENTED] | In development | Joint vectors/labels/analysis exist; no joint table, content route, or dedicated atlas. |
| Relational plan builder | [IMPLEMENTED] | Available / draft | Days/rest, workout units, slots, variants, sets, roles, targets, loading metadata. |
| Fallback exercises | [IMPLEMENTED] | Available | Persisted alternatives; only default variant currently enters analysis/export. |
| On-demand plan analysis | [IMPLEMENTED] [EXPERIMENTAL MODEL] | Available as experimental | Runs against the saved draft, not continuously while editing; result not persisted. |
| ETU and intent split | [IMPLEMENTED] [EXPERIMENTAL MODEL] | Available as experimental | Intentional/incidental/unclassified contributions with per-set provenance. |
| Local muscle recovery | [IMPLEMENTED] [EXPERIMENTAL MODEL] | Available as experimental | Linear debt model with global velocity; not personalized physiology. |
| Joint recovery/JRU | [IMPLEMENTED] [EXPERIMENTAL MODEL] | Available as experimental | Comparative model; not healing time or injury risk. |
| Neural fatigue | [PLANNED] | Coming later / research | No schema, evaluator, or UI. |
| Cardiovascular/metabolic fatigue | [PLANNED] | Coming later / research | No schema, evaluator, or UI. |
| Loading modes and cycles | [PARTIALLY IMPLEMENTED] | Mention as prescription metadata only | Editable/persisted; ignored by current analysis and compact export. |
| Volume modulation | [PARTIALLY IMPLEMENTED] | In development | Backend fields/resolution exist; UI modulation tab is disabled and `focus_area` is a no-op. |
| Progression model catalog | [IMPLEMENTED] | Available as guidance | Fourteen localized descriptions assignable to variants. |
| Automatic progression execution | [PLANNED] | Coming with athlete execution | No state machine, performance history, or next-load calculation. |
| AI-friendly export/import | [IMPLEMENTED] | Available | Compact validated JSON, not a built-in AI coach; format intentionally loses some editor detail. |
| Muscle knowledge articles | [IMPLEMENTED] | Available inside muscle detail | Content exists, but completeness/editorial maturity can vary. |
| Standalone science blog | [PLANNED] | In development | Domain notes exist; no public blog route. |
| Athlete/client records | [PLANNED] | Coming soon | No athlete entity, assignment, account, or history. |
| Workout execution/logging | [PLANNED] | Coming soon | No performed sessions/sets, actual loads, reps, or RIR. |
| Mobile training mode | [PLANNED] | Coming soon | No current route or execution UI. |
| Authentication and plan ownership | Absent | Do not market | All current plan data is global to the application. |
| Multilingual product UI/catalog | [IMPLEMENTED] | Optional secondary proof | Current code supports English plus Polish, French, Spanish, German, Italian, Brazilian Portuguese, Swedish, Dutch, and Ukrainian. |

---

## 14. Claims We Should Avoid

| Avoid | Why | Safer replacement |
| --- | --- | --- |
| `Naukowo udowodniony optymalny plan` | Models and training science contain uncertainty; no optimizer exists. | `Analiza oparta na jawnych, evidence-informed modelach.` |
| `Dokładnie mierzymy napięcie mięśniowe` | Exercise vectors are estimates, not direct measurements. | `Szacujemy rozkład bodźca napięciowego w przyjętym modelu.` |
| `ETU pokazuje procent aktywacji mięśnia` | ETU is quality-modified modeled stimulus, not EMG or recruitment percentage. | `ETU estymuje efektywny bodziec przypisany mięśniowi.` |
| `FCSA pokazuje liczbę włókien mięśniowych` | FCSA is an estimated force-transmitting area. | `FCSA jest szacowanym przekrojem używanym jako odniesienie zdolności do przenoszenia siły.` |
| `Wiemy dokładnie, kiedy mięsień się zregeneruje` | Hours-to-fresh is a calibrated linear model. | `Modelujemy, jak dług regeneracyjny może kumulować się w mikrocyklu.` |
| `Oceniamy ryzyko kontuzji stawu` | Joint exposure is not a medical safety or injury probability score. | `Porównujemy modelowaną ekspozycję mechaniczną tego samego stawu między ćwiczeniami.` |
| `Analiza działa na żywo podczas każdej zmiany` | Current analysis is requested for the saved draft. | `Uruchom Analizę zapisanego szkicu i odśwież ją po zmianach.` |
| `Agonez automatycznie progresuje ciężar` | Progression models are descriptive metadata only. | `Przypisz i zachowaj zasady progresji; automatyzacja jest planowana.` |
| `Prowadź wszystkich klientów już dziś` | No athlete/client/auth/history model exists. | `Kreator i Analiza są fundamentem przyszłego modułu prowadzenia zawodnika.` |
| `Wbudowany trener AI` | Current capability is JSON import/export only. | `Eksportuj plan do zewnętrznej analizy AI i importuj walidowaną strukturę.` |
| `Pełny Atlas stawów` | Only joint vectors/labels/analysis exist. | `Warstwa ekspozycji stawów; osobny Atlas jest w rozwoju.` |
| `Pełna baza całej wiedzy treningowej` | A muscle content layer and domain notes exist, but no complete blog. | `Rozwijana baza wiedzy połączona z Atlasem.` |
| `Najlepsze ćwiczenie na mięsień` | Rankings depend on reference assumptions and one model dimension. | `Ćwiczenia z najwyższym modelowanym ETU dla tego mięśnia w przyjętych założeniach.` |
| `Gwarantowany wzrost mięśni` | Adaptation is individual and multifactorial. | `Modelowany bodziec istotny dla treningu hipertroficznego.` |
| `Spersonalizowane wyniki dla Ciebie` | Current values use a reference athlete, not user data. | `Wartości znormalizowane do wspólnego zawodnika referencyjnego.` |
| `Bezpieczne ćwiczenie` / `niebezpieczne ćwiczenie` | The model has no medical or injury-risk inference. | `Niższa/wyższa modelowana ekspozycja danego stawu w porównaniu z innymi ćwiczeniami.` |
| `Twoje plany są prywatne i bezpieczne` | Authentication/ownership is absent. | Do not make a privacy/account claim until implemented and reviewed. |

Avoid affiliation language around public educators such as Jeff Nippard. Tone references can inform accessibility, but Agonez must not suggest endorsement, partnership, or imitation.

---

## 15. Repository Evidence

### Product and capability baseline

- `__docs__/README.md` — strongest current summary of what exists and what is explicitly absent.
- `__docs__/architecture/system-overview.md` — Atlas, PlanCreator, analysis boundaries, runtime lifecycle, and security/ownership caveat.
- `__docs__/architecture/domain-map.md` — persisted catalog/prescription entities, derived ETU/MRU/JRU analysis, and absent athlete/execution concepts.
- `__docs__/flows/execution-pipeline.md` — current resolver/evaluator equations, timing, periodic recovery, import/export, and unimplemented execution.
- `__docs__/findings/ambiguities.md` — drift, units, no-op fields, metadata-only progression, absent authentication, and joint-identifier limitations.

### Atlas and database

- `__docs__/database/schema-overview.md` — snapshot counts, enums, vector inventory, and database constraints.
- `__docs__/database/data-dictionary.md` — exact exercise, muscle, engine, progression, and plan fields with unit caveats.
- `be/src/agonez_api/modules/atlas/schemas.py` — current API surface for exercise/muscle details and related exercises.
- `be/src/agonez_api/modules/atlas/repository.py` — catalog filters, sorting, translation overlays, and ETU-based relations.
- `web-fe/src/views/AtlasIndexView.vue` — searchable/filterable list and grid with anatomy linkage.
- `web-fe/src/views/ExerciseDetailView.vue` — ETU/recovery/joint visualization, technique, rep profiles, and videos.
- `web-fe/src/views/MuscleDetailView.vue` — anatomy, morphology, architecture, fibers, FCSA, articles, galleries, and related exercises.

### PlanCreator and analysis

- `be/src/agonez_api/modules/plans/schemas.py` — roles, default/fallback variants, sets, reps, RIR, loading modes, and progression assignments.
- `be/src/agonez_api/modules/plans/analysis/parameters.py` — effective-rep lookup and explicit engineering parameters.
- `be/src/agonez_api/modules/plans/analysis/evaluator.py` — ETU/MRU/JRU calculation, summaries, diagnostics, and recovery simulation.
- `web-fe/src/views/PlanCreatorView.vue` — current saved-draft/analysis workflow and disabled modulation tab.
- `web-fe/src/components/plans/analysis/` — timeline, anatomy maps, muscle/joint summaries, diagnostics, and provenance UI.
- `web-fe/src/i18n/locales/pl/plans.ts` and `analysis.ts` — current Polish product language and built-in caveats.

### Methodology and calibration

- `prompts/persona.md` — canonical reference-athlete values.
- `prompts/estimate/1-systemic-propulsive-fcsa-demand.md` — FCSA and systemic propulsive demand definition/calibration.
- `prompts/estimate/2-active_tension_exposure_vector.md` — standardized effective repetition, active tension, hypertrophic-quality modifier, ETU, and normalization.
- `prompts/estimate/4-joint_recovery_exposure_vector.md` — joint set, within-joint exposure scale, and explicit medical/safety exclusions.
- `prompts/estimate/5-muscle_recovery_cost_modifier_vector.md` — local persistent recovery-burden definition.
- `prompts/estimate/6-exercise_technique.md` — exact-variant technique philosophy and structured technique contract.
- `__docs__/domain/` — broader working notes on anatomy, biomechanics, physiology, hypertrophy, effective reps, rep ranges, PCSA/FCSA, and mechanotransduction. Treat these as research/product-development material unless editorially reviewed for publication.

### Roadmap evidence

- `__docs__/domain/journal/26-08.md` — separation of PlanCreator and PlanExecution, volume/focus ideas, atlas direction, and recovery modeling history.
- `__docs__/domain/journal/26-09.md` — execution/mobile concepts, progression direction, and the explicit Home-page audience/feature intent.

### Visual evidence

- `web-fe/public/logo-mark.png` — production crop of the cracked-face mark.
- `media/logo-mark.png` — nine-variant brand sheet.
- `media/anatomy.svg` — runtime anatomy asset.
- `media/exercises/`, `media/muscles/`, `media/galleries/muscles/` — current catalog imagery.
- `web-fe/src/styles/tokens.css` — fonts, light/dark palette, and semantic data colors.
- `be/docs/frontend-handoff.md` — established visual and interaction direction for the current application.

---

## 16. Newly Discovered Features

### Intentional vs incidental stimulus

**What it does:** A plan slot can name target muscles. Analysis partitions each muscle’s ETU into `INTENTIONAL`, `INCIDENTAL`, or `UNCLASSIFIED` without changing the raw calculation.

**Who benefits:** Advanced lifters and coaches auditing hidden volume or unintended overlap.

**Landing-page value:** High. This is easier to understand and more distinctive than leading with an acronym.

**Recommended placement:** Plan Analysis section, before the deep methodology layer.

**Suggested copy:** `Zobacz nie tylko to, co plan miał trenować, ale także pracę poboczną wynikającą z dobranych ćwiczeń.`

**Evidence:** `__docs__/flows/execution-pipeline.md`, `web-fe/src/components/plans/analysis/MuscleSummary.vue`.

### Per-set provenance

**What it does:** Analysis results can be traced to a plan day, workout, slot, exercise variant, and set, with effective reps and vector values.

**Who benefits:** Coaches, technical users, and anyone questioning a surprising total.

**Landing-page value:** Very high as a credibility signal. It proves the product does more than display opaque scores.

**Recommended placement:** Analysis visual and Methodology section.

**Suggested copy:** `Każda suma prowadzi z powrotem do konkretnej serii.`

**Evidence:** `web-fe/src/components/plans/analysis/ProvenanceInspector.vue`, `web-fe/src/api/plan-analysis-types.ts`.

### Analysis diagnostics and visible model parameters

**What it does:** Missing/malformed vectors, missing FCSA, timing assumptions, and non-convergent recovery produce inspectable diagnostics. The UI also exposes effective-rep mappings, velocities, cumulative penalties, cycle length, and model version.

**Who benefits:** Advanced lifters, coaches, researchers, and technically minded users.

**Landing-page value:** High in Layer 3; low in the hero. This is an academic-respect signal.

**Recommended placement:** Expandable `Jak działa model?` section.

**Suggested copy:** `Wynik bez ukrytych parametrów: wersja modelu, założenia i diagnostyka pozostają widoczne.`

**Evidence:** `web-fe/src/components/plans/analysis/AnalysisDiagnostics.vue`, `AnalysisModelDetails.vue`, `be/src/agonez_api/modules/plans/analysis/evaluator.py`.

### Stable exercise slots with fallbacks

**What it does:** A slot owns the purpose, role, targets, and alternatives; the exercise itself can change without losing programming intent.

**Who benefits:** Coaches and experienced lifters adapting to equipment, pain-free variants, travel, or availability.

**Landing-page value:** High in the coach section.

**Recommended placement:** Plan Builder/For Coaches.

**Suggested copy:** `Zachowaj cel slotu, nawet gdy trzeba zmienić ćwiczenie.`

**Evidence:** `__docs__/architecture/domain-map.md`, `web-fe/src/components/plans/ExerciseSlotEditor.vue`.

### Explicit rest days as analysis data

**What it does:** Rest days are first-class entries in the ordered microcycle. The editor warns when every modeled day contains a workout because recovery timing depends on those gaps.

**Who benefits:** Beginners learning plan structure and coaches checking timing.

**Landing-page value:** Medium; it is a good illustration of domain depth without jargon.

**Recommended placement:** Plan Builder microcopy or an educational callout.

**Suggested copy:** `W Agonez dzień odpoczynku nie jest pustym miejscem — określa czas między bodźcami.`

**Evidence:** `web-fe/src/features/plans/guidance.ts`, `web-fe/src/i18n/locales/pl/plans.ts`.

### Exercise-to-muscle ranking based on modeled ETU

**What it does:** Muscle detail can list exercises with measured model ETU for that muscle and fall back to target-category relations where a measured vector is unavailable.

**Who benefits:** Beginners selecting exercises and advanced users comparing variants.

**Landing-page value:** High in the Muscle Atlas section, if the interface clearly distinguishes modeled ETU from category fallback.

**Recommended placement:** Muscle Atlas proof panel.

**Suggested copy:** `Przejdź od mięśnia do ćwiczeń, które w modelu dostarczają mu największą ekspozycję.`

**Evidence:** `be/src/agonez_api/modules/atlas/repository.py`, `web-fe/src/views/MuscleDetailView.vue`.

### Recommended rep profiles by loading mode

**What it does:** Every exercise can carry separate high-, moderate-, and low-load recommended rep ranges; unsupported modes can be explicitly null. The editor can initialize three sets from a selected mode.

**Who benefits:** Beginners and coaches who want exercise-specific starting constraints rather than one universal range.

**Landing-page value:** Medium in the Exercise Atlas/Plan Builder transition.

**Recommended placement:** Exercise detail visual leading into the builder.

**Suggested copy:** `Zakres powtórzeń zależy od ćwiczenia i wybranego trybu obciążenia — nie od jednej reguły dla całego planu.`

**Evidence:** `core.exercises.recommended_rep_profile` in `__docs__/database/data-dictionary.md`, `web-fe/src/components/plans/ExerciseSlotEditor.vue`.

### Multilingual catalog and interface

**What it does:** The current application negotiates ten locales and overlays exercise, muscle, technique/article, and progression content where translations exist.

**Who benefits:** International users and coaches working across languages.

**Landing-page value:** Low for the initial Polish hero, useful as a small trust/product-maturity signal near the footer.

**Recommended placement:** Product detail/footer, not a core feature card.

**Suggested copy:** `Interfejs i katalog przygotowane do pracy w wielu językach.`

**Evidence:** `be/src/agonez_api/core/localization.py`, `web-fe/src/i18n/locales/`, translation tables documented in `__docs__/database/data-dictionary.md`.

### Compact plan portability

**What it does:** Plans can be exported to or imported from a strict, human-readable JSON format with server-side catalog validation.

**Who benefits:** Coaches and technical users moving between Agonez, scripts, and external AI analysis.

**Landing-page value:** Medium/high for coaches, but only with the lossy-format caveat.

**Recommended placement:** Coach section after plan analysis.

**Suggested copy:** `Wynieś plan do zewnętrznej kontroli i wróć z walidowaną strukturą.`

**Evidence:** `__docs__/api/examples/plan.export.response.json`, `__docs__/api/examples/plan.import.request.json`, `__docs__/api/endpoint-flows.md`.

---

## Final content direction for the design agent

The `/home` page should feel simple in its first viewport and increasingly rigorous as the user scrolls:

```text
„Co to jest i czy jest dla mnie?”
        ↓
„Co mogę zrobić już dziś?”
        ↓
„Dlaczego to jest głębsze niż tracker?”
        ↓
„Jak działa model i gdzie są jego granice?”
        ↓
„Dokąd produkt zmierza?”
```

The key emotional progression is:

- beginner: `W końcu ktoś mi to poukłada.`
- advanced lifter: `To nie jest tylko licznik serii.`
- coach: `Model jest wystarczająco jawny, żebym mógł go ocenić, a nie tylko mu zaufać.`

The page should never require the visitor to understand ETU, FCSA, MRU, or JRU before understanding the product. Those concepts earn their place only after the page has demonstrated a useful exercise, a structured plan, and an inspectable analysis.

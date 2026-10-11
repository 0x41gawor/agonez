# Agonez Mobile — implementation handoff (Flutter)

Status: design handoff v1 · October 2026
Audience: the Flutter coding agent
Read with: `mobile-design-reference.html` (interactive reference — open it, use the scenario buttons), the Design canvas *Agonez Mobile — Workout Execution + Atlas* (16 annotated static screens), `mobile-api-contract.md`, `dictionary.md`.

> **Visual intent vs implementation mechanism.** The HTML reference and canvas are built with plain CSS/JS so they render standalone. Treat their colours, sizes, spacing and copy as **intent**. Implement them with the existing Agonez theme tokens, typography and component conventions of the Flutter project. Do not port the CSS, class names or the prototype's state code. Where this document gives a number, it is the intended value unless the Agonez theme already defines a nearer one.

---

## 1. Product role in one paragraph

Mobile is a **workout execution instrument**: prescription → athlete performs → reality is recorded → performed workout is synchronized. Atlas is the second capability, always one tap away, never in the way. Planning, history matrices, Post-Workout-Analysis, MARKER.X and progression stay on desktop. Every design decision below serves one criterion: *increase the repeatability, discipline and quality of training data without becoming annoying during a hard workout.*

---

## 2. Screen architecture

```text
App shell (persistent)
├── Home                         tab
│   ├── Today card | Resume card | edge states
│   ├── Microcycle strip (7 days, status pips)
│   └── Recent (≤3 rows)
│   sheets: Plan-run context · Workout-unit picker (advanced)
├── Workout                      tab → Focus Mode when active, otherwise Home's start state
│   └── Focus Mode (full-screen, immersive; bottom nav hidden)
│       sheets: Outline · Workout actions · Hold-confirm · Exercise picker (substitute / add)
│               Atlas quick peek · Set note · Exercise note · More data · Load keypad
│               Rep picker · Edit recorded set · Finish · Sync detail / conflict
├── Atlas                        tab
│   ├── Atlas index (search, open-article chips, exercise/muscle list)
│   └── Atlas article (one per open workspace)
├── Workspace switcher           full-screen overlay (cards: pinned Workout + Atlas tabs)
├── You                          tab: plan run selection, workout settings, app settings, sync status
└── Workout recorded             post-finish screen (then Home)

Global, outside Focus Mode while a workout is active:
└── Mini workout bar (above bottom nav): unit · exercise · set · rest countdown · tap = return
```

Deliberately **not** separate screens: "Workout start" (it is Home's Today card), "Rest" (lives inside Focus Mode), "Workout outline" (a sheet), "Substitution" (a sheet flow).

---

## 3. Navigation model

### 3.1 Bottom navigation

`Home · Workout · Atlas · You` — four destinations, labels always visible.

| Item | Badge | Tap behaviour |
| --- | --- | --- |
| Home | — | Home tab (state preserved). |
| Workout | gold dot when a workout is active | Active → **Focus Mode exactly where the athlete was**. None → Home's Today card (scroll to it). |
| Atlas | count of open Atlas workspaces | Last active Atlas workspace (article or index), scroll position restored. |
| You | — | Profile/settings. |

Each tab keeps its own navigation stack (persistent shell with per-tab navigators / indexed stack). Switching tabs never rebuilds or resets another tab.

### 3.2 Focus Mode is a full-screen route above the shell

- Entering Focus Mode hides the bottom nav (the bottom of the screen belongs to the thumb and the **Confirm set** button).
- **Minimise** (chevron-down, top-left) or the system back gesture returns to the previous tab; the workout keeps running and the **mini workout bar** appears above the bottom nav on every other screen.
- The Workout tab, the mini bar, the Resume card and the pinned workspace card all re-open Focus Mode at the same state.

### 3.3 System back behaviour (Android back / iOS edge swipe)

| Where | Back does |
| --- | --- |
| A sheet is open | Close the sheet (no state change; unsaved note text is kept as a draft for that field). |
| A hold-confirm is in progress | Cancel the hold. |
| Focus Mode | Minimise to the previous tab. **Never** cancels or finishes the workout. |
| Atlas article | Pop to the previous Atlas page in that workspace; at the workspace root → Atlas index. |
| Workspace switcher | Close switcher. |
| Root of a tab | Default platform behaviour (Android: background the app). Workout keeps running. |

There is no route by which a swipe or back gesture discards workout data.

### 3.4 Plan-run context

Shown as a compact chip top-right on Home (`Autumn Cut 2026 · MC 7/8 ▾`) → sheet with runs and microcycle position. Selection is remembered locally (API §4.1) and **locked while a workout is active**. The athlete is never asked to choose a run during normal use.

---

## 4. Active workout lifecycle

```text
          ┌──────────── no active workout ────────────┐
          │                                            │
 Home ── Start (tap) ──► STARTING ──► ACTIVE ──► FINISHING ──► RECORDED ──► Home (completed state)
          │  (local first;            │   ▲            │ hold if incomplete
          │   POST /workouts queued)  │   │ minimise / tabs / Atlas: still ACTIVE
          │                           ▼   │
          │                       BACKGROUNDED / KILLED ── reopen ──► Home shows RESUME ──► ACTIVE
          └── another workout active ──► Resume (never a second start)
```

Rules:

1. **Local-first start.** On *Start*: generate `workout_id`, write the workout + frozen prescription to the local store, open Focus Mode, enqueue `POST /workouts`. The athlete never waits for the network.
2. **Single active workout.** If the local store or `/context` has an active workout, Home shows **Resume** and *Start* is not rendered. The advanced picker's start actions are disabled with an explanation.
3. **Persistence points.** Every state change that matters (confirm set, skip, add, substitute, reorder, comment, cursor move, rest start/adjust) is written to the local store **before** the UI reflects it as saved. Debounce nothing that represents a confirmed fact.
4. **Cold start.** Before rendering Home: read the local store → if a workout is active, render the Resume card immediately (no spinner), then revalidate with `/context` in the background. Restore: current exercise, current set, entry draft values (load/reps/RIR not yet confirmed), rest timer from `rest_ends_at`, open sheets are **not** restored (always resume to the plain Focus view).
5. **Finish** is only reachable inside the workout (actions sheet or the final *Finish workout* button). It is not a tab action and there is no "close workout" ✕ anywhere.
6. **Recorded.** After finalize (online or queued), show *Push A recorded* with honest sync status, then Home in its completed state.

---

## 5. Focus Mode — structure and rationale

Vertical order (top → bottom), 390 × 844 reference:

| Zone | Content | Why here |
| --- | --- | --- |
| Top bar (≈50) | Minimise · unit name + elapsed time · sync pill · Outline · Actions (⋯) | Orientation and secondary controls live at the top, away from the thumb's resting zone. |
| Progress (≈30) | Segmented bar, one segment per exercise (width ∝ sets); `EXERCISE 3 / 6` left, `7 / 16 SETS` right | Two levels of orientation without gamification. Skipped exercises are hatched. |
| Exercise header | Role eyebrow · **exercise name** (tap = Atlas peek, with Atlas glyph) · variant line, or the **lineage block** when substituted | The athlete's "where am I". Name is the Atlas entry point. |
| Set rail | One pill per set: done (`✓ 67.5×7 @1`, amber dot if it differs from prescription), current (gold), upcoming (prescribed load), skipped (dashed amber), extra (gold outline) | "Which set am I doing now?" answered at a glance. Done pills are tappable to edit. |
| Prescription card (blue family) | `PRESCRIBED · SET 2` · `67.5 kg × 5–7 @ RIR 1` · `LAST · MC6 67.5 × 6 @0` · prescription/set note | Prescription is always visible and visually distinct from actual input. |
| Rest card (replaces the prescription card while resting) | `REST 01:58` large mono countdown, −30 / +30 / end, progress line, *Up next · Set 2 · 67.5 kg × 5–7 @ RIR 1* | Rest sits where the athlete is already looking; next set's prescription stays visible inside it. |
| Entry zone (bottom-anchored) | Load stepper · Reps row · RIR row · Set note / More data chips | Thumb zone. Large targets. |
| Confirm (pinned) | `Confirm set 2` + summary line `67.5 × 6 @ 1 · then rest 03:00` | One primary action, always in the same place. |

The prescription colour family (`--prescr` blue, from the desktop Execution reference) is used **only** for prescribed values and targets. Actual values use the neutral text colour. The athlete always sees which is which.

### 5.1 Exercise complete

After the last set of an exercise is confirmed, the entry zone is replaced by an **Exercise complete** card: table of performed vs prescribed per set, *Exercise note* and *Extra set* buttons, then an *Up next* card and the primary button *Start <next exercise>*. The rest timer keeps running above. This is the natural moment for exercise-level comments without putting them in the set fast path.

The last exercise's button reads **Finish workout**.

---

## 6. One-thumb input — exact behaviour (P0)

**Target sizes:** load ± buttons 64 × 58, load value 58 high, rep/RIR buttons ≥ 54 × 54 (6 per row, 6 px gaps), Confirm 60 high full-width, chips 38 high. Nothing tapped during a set is smaller than 44 × 44.

### 6.1 Defaults

| Field | Default | Rule |
| --- | --- | --- |
| Load | Prescribed load of this set | If the previous set **of this exercise in this workout** was recorded at a load different from its prescription, *and* this set's prescribed load equals the previous set's prescribed load → prefill the previous actual load and show *kept from your last set*. Substituted / unplanned / extra sets: last actual in this workout → last performed in this plan run (`last_performed_in_run`) → empty (keypad). |
| Reps | **None selected** | The athlete must record reality; pre-selecting the target would invite one-tap "as prescribed" lies. |
| RIR | **None selected** | Same reason. |

Common path = **3 taps**: reps → RIR → Confirm. Divergent load = 4–5 taps (− once or twice).

### 6.2 Controls

- **Load stepper.** − / + change by `load_step_kg` (from prescription; 2.5 default, 1.25 for small increments). Long-press repeats at 4 Hz after 400 ms. Tapping the value opens a **numeric keypad sheet** (custom keypad, no system keyboard) with quick chips: *prescribed*, *last exposure*, *current*. Decimal point allowed, max 2 decimals.
- **Reps row.** Five numbers from `rep_min − 1` upward, plus **other** (opens a 1–30 grid sheet; the chosen value then replaces "other" in the row). The prescribed band carries a thin blue underline on each in-range button.
- **RIR row.** `0 1 2 3 4 5+` (`5+` sends 5). Target RIR has the blue underline.
- **Selection state.** Selected = inverted (light fill, dark numerals, semibold). Never colour alone: weight + fill change, and the accessible state is `selected`.
- **Confirm.** Disabled until load, reps and RIR are set; the disabled label states what is missing (*Select reps and RIR* / *Enter load*). Enabled label shows the summary that will be recorded.

### 6.3 After Confirm

1. Write set locally, enqueue `upsert_set`, light haptic.
2. Start rest timer (`rest_ends_at = now + default_rest_s`).
3. Advance to the next open set; prefill per §6.1; reps/RIR cleared.
4. Snackbar: *Set 2 recorded · 67.5 × 6 @ RIR 1 · Undo* for 6 s (positioned above the Confirm button; hidden while a sheet is open). Undo reopens the set with the recorded values preselected and enqueues `clear_set`.

### 6.4 Prescription vs actual (Scenario D)

Divergence is **not an error**:

- Load ≠ prescribed → value box gets a warm outline; label line `• −2.5 kg vs prescribed · Reset`.
- Reps outside band → `• 1 below target` / `• 2 above target`.
- RIR ≠ target → `• deeper than target` / `• further from failure`.
- The recorded set pill gets a small amber dot.

No dialogs, no confirmation, no red.

### 6.5 Optional data (progressive disclosure)

- **Set note** chip → sheet with text field + quick suggestions (*Grip slipped*, *Elbows flared*, *Reduced load after previous set*, *Pain / discomfort*, *Different equipment*, *Spotter helped*). Suggestions append; the keyboard opens only if the athlete taps the field.
- **More data** chip → sheet with `heart_rate_bpm` quick values and "future: from a paired sensor". Never required, never blocks Confirm.
- **Exercise note** → from the actions sheet or the *Exercise complete* card; scoped explicitly to "this exposure only" and visibly distinct from the plan's instructions.

---

## 7. Structural deviations (P0)

Philosophy: *Agonez does not forbid deviation; it makes the athlete consciously acknowledge it.* Friction scales with impact on comparability. No modal stacks, no countdowns, no punishment copy.

| Action | Entry point | Friction | Explanation shown | Result |
| --- | --- | --- | --- | --- |
| Skip set | ⋯ actions | **Hold 0.6 s** (neutral button) | "A skipped set is stored without values. Fewer sets than prescribed makes this exposure less comparable." | Pill → dashed *skipped*; next open set. |
| Add extra set | ⋯ actions · *Exercise complete* card | Hold 0.6 s | "Recorded separately from prescribed sets." | Extra pill (gold outline); entry for it. Unplanned exercises add sets without friction. |
| Skip exercise | ⋯ actions | **Hold 1.2 s** (warm button) | "Skipping an exercise reduces the repeatability and comparability of the training plan…" | Remaining sets skipped; next exercise; outline shows strike-through. |
| Substitute exercise | ⋯ actions | Picker (plan alternatives first, then Atlas search) → **Hold 1.2 s** with lineage preview | "Performing a different exercise breaks the trace for this slot…" | Lineage block *PERFORMED / PRESCRIBED* in header; prescription card becomes dashed "Prescription was for …"; target band still shown; load prefilled from the substitute's last performance in this run. Disabled once a set is recorded (explain why). |
| Reorder | Outline sheet → *Do next* on an upcoming exercise | Hold 1.0 s | "The planned order puts it at #4…" | Moves after current; header eyebrow `· order changed`; outline tag `planned #4`. |
| Add unplanned exercise | ⋯ actions | Atlas picker → **Hold 1.4 s** | "…isn't part of Push A. Extra work changes this session's volume…" | Inserted after current; `UNPLANNED` eyebrow; no prescription card. |
| Finish with incomplete work | ⋯ actions / last button | Sheet listing incomplete exercises → primary **Continue workout**, secondary **Hold 1.4 s Finish anyway** | "Finishing now will record N sets as not completed…" | Finalize. |

**Hold-to-confirm component:**

- Full-width, 60 high. Fill sweeps left→right over the hold duration (linear). Label: action + `hold 1.2 s` in mono.
- Release early → fill animates back in 200 ms, nothing happens, no error.
- Completion → heavy haptic, action applied, sheet closes, short snackbar describing what was recorded.
- Accessibility: also completes with a sustained press of Space/Enter (hardware keyboard) and exposes a custom accessibility action "Confirm <action>" so screen-reader users are not required to hold (TalkBack/VoiceOver double-tap-and-hold also works). Reduced-motion: the fill still progresses (it is the feedback) but without easing.
- Must not be cancelled by unrelated rebuilds (sync status changes, timer ticks). In the prototype this was a real bug: re-rendering the sheet mid-hold cancelled the gesture. Keep hold state outside widgets that rebuild on sync/timer updates.

The friction level is shown in the actions sheet as 1–3 small amber dots per action.

---

## 8. Rest timer (P1)

- Starts automatically on Confirm (and on *Start next exercise* only if no timer is running).
- Stored as `rest_ends_at` (wall-clock) + `rest_duration_s`; the countdown is derived on every frame/tick — never decremented state. Survives background, kill, reboot.
- −30 / +30 adjust `rest_ends_at`; ✕ ends rest. Client-only (API §8).
- At zero: medium haptic + (if backgrounded) local notification *Rest complete — Bench Press set 3* with the next set's prescription; card switches to *Rest complete · over by +0:14* counting up in a calm green. No alarm loops.
- The timer appears in: Focus rest card, mini workout bar, Resume card, pinned workspace card.
- The athlete can enter the next set's values while resting (entry zone stays active).
- Reserve a setting for sound on/off and default rest per role (You → Workout).

---

## 9. Atlas during a workout (P0 quick peek, P1 workspaces)

### 9.1 Level 1 — Quick peek (sheet over Focus Mode)

Trigger: tap exercise name / Atlas glyph / *Technique & anatomy* in actions. Sheet ≈ 85 % height, drag to dismiss.

Content order: name + full name + slug · **Technique TL;DR** (Setup, Execution, Focus, Stop when — same four blocks as desktop *Technique*) · body map (front/rear, involved muscles coloured) beside top-4 muscles with ETU bars · *Plan note · this workout* (the plan comment, clearly labelled as plan, not Atlas) · button **Open full Atlas article**.

Data comes from the embedded `atlas_peek` (works offline).

### 9.2 Level 2 — Full Atlas workspace

*Open full Atlas article* → opens (or focuses) an Atlas workspace for that exercise, switches to the Atlas tab, Focus Mode is minimised (mini bar visible). Article layout (mobile translation of the desktop page, not a shrink):

1. Header: eyebrow `ATLAS · EXERCISE`, name, full name, slug chip, tags, three key stats (Load capacity, Total ETU, Peak joint) in mono.
2. In-workout banner when the exercise is in today's workout.
3. Sticky section tabs: TECHNIQUE · ANATOMY · MUSCLES · DATA · VIDEO (mono, gold underline) — scrollspy, tap scrolls.
4. Technique TL;DR → Anatomy (human.svg front/rear, ETU/Recovery toggle) → Muscle ETU list (Latin names, raw cm², bar = share of capacity) → Classification & rep ranges (key/value rows) → Videos.

Interactions from desktop that need a mobile equivalent: hovering body/table sync → **tap** a muscle row highlights its region and vice versa; tap a region opens a small muscle chip with *Open muscle article* (new workspace).

### 9.3 Workspaces (browser-tab inspired, mobile-native)

- A workspace = one open Atlas article with its own back stack and scroll position.
- The **Workout** is a pinned, non-closable workspace while active (gold card, `ACTIVE`, live set/rest status, "Can't be closed here").
- Entry: the square counter button in the Atlas header (`[3]` = workout + 2 articles) or long-press on the Atlas tab. Switcher = full-screen 2-column card grid; tap a card to switch; ✕ closes Atlas cards only; *New Atlas tab* card opens the index.
- Atlas tab badge shows the number of open Atlas workspaces.
- Workspaces persist across app restarts (local store); cap at 8 (oldest non-current closes with a snackbar).
- The workspace UI never takes permanent space on the Focus screen; it lives in the Atlas tab and the switcher only.

---

## 10. Sync states (P0)

The sync pill sits in the Focus top bar; elsewhere the same state appears in the mini bar subtitle (only when not *Saved*) and in You → Sync.

| State | Pill | Meaning | Athlete action needed |
| --- | --- | --- | --- |
| Saved | `● Saved` (green dot) | Server acknowledged everything | none |
| Saving | `● Saving…` (grey dot) | Request in flight | none |
| Offline | `○ Offline · 3` (amber ring) | N ops queued; recording continues | none |
| Sync failed | `● Sync failed` (red dot) | Server error; auto-retry with backoff | optional *Retry now* |
| Conflict | `● Conflict` (red dot) | An op was not applied due to another writer | resolve in sheet (keep phone / use server) |
| Superseded | banner in Focus: "Continued on another device" | Lease moved | *Resume here* (claim) or view-only |

Tapping the pill opens the **Sync sheet**: explanation, queued count, last server ack, last few pending ops (developer-legible names are fine here but keep them muted), and the action for failed/conflict states. Sync **never** blocks Confirm, navigation or finishing.

---

## 11. Loading, empty, error and offline states

| Case | Where | Design |
| --- | --- | --- |
| No active plan run | Home | Dashed empty card: *Nothing to execute yet* + *Choose plan run* → You. |
| Rest day | Home | Today card *Rest day*, next session hint, *Train another workout-unit…* link. |
| No prescription available | Home Today card | Amber *Prescription not ready* + explanation (Post-Workout-Analysis pending) + secondary *Start with plan targets* (loads empty → keypad on first set). |
| Prescription changed before start | Home Today card | Inline amber banner listing the change (*Bench Press set 3 · 65 → 67.5 kg*); start uses the new version. |
| Workout already active (this device) | Home | Resume card replaces Today; info banner "Only one workout can be active". |
| Workout already active (other device) | Home | Amber banner *started 18:04 on another device* + *Resume it here* (claim). |
| Failed to start | Home → Focus | Start is local-first, so the athlete is already training; pill shows *Sync failed* and retries. If the server later refuses (`active_workout_exists` / `prescription_changed`), show a non-blocking banner in Focus with the choice; never delete local data. |
| Offline but usable | Focus | Pill *Offline · N*. Nothing else changes. |
| Sync pending at finish | Recorded screen | *Saved on this phone — it will be finalised when you're back online.* |
| Sync failed | Focus | Pill + automatic retry; sheet offers *Retry now*. |
| Server conflict | Focus | Pill *Conflict* + sheet comparing *This phone* vs *Server*. |
| Atlas article not cached and offline | Atlas | Article skeleton with "Available when online"; quick peek still works (embedded). |
| Initial context loading | Home | Skeleton Today card (no spinner) — but local active workout renders instantly. |

No state above is a blocking modal except the athlete-initiated sheets.

---

## 12. Haptics (P1)

| Moment | Haptic |
| --- | --- |
| Set confirmed | light impact |
| Hold-to-confirm completed | heavy impact |
| Rest timer reached zero | medium impact (+ notification if backgrounded) |
| Workout finished | success pattern |
| Workout started | medium impact |
| Stepper long-press repeat | selection tick every step (very light), optional |

Respect the system haptics setting and the in-app toggle (You → Workout → Haptics). Never use haptics for errors during a set.

---

## 13. Background and notifications (P1)

- Backgrounded during rest: schedule a local notification at `rest_ends_at` (cancel/reschedule on adjust, end rest, undo). Content: *Rest complete* + next set prescription. Tapping it opens Focus Mode.
- Optional ongoing notification / live activity while a workout is active ("Push A · Bench Press · Set 2/3 · Rest 01:12"). Desired behaviour only; platform choice is the implementer's.
- Sound: off by default; vibration on.
- No server push is required for v1.

---

## 14. Component hierarchy (names are descriptive, not widget classes)

```text
AppShell
├── TabStacks { HomeStack, AtlasStack, YouStack }
├── MiniWorkoutBar            (visible when ActiveWorkout != null && !FocusVisible)
├── BottomNav                 (hidden when FocusVisible)
└── Overlays: FocusModeRoute, WorkspaceSwitcherRoute, Snackbar host, Sheet host

FocusModeRoute
├── FocusTopBar { MinimiseButton, Title(unit, elapsed), SyncPill, OutlineButton, ActionsButton }
├── WorkoutProgress { ExerciseSegments, ExerciseCounter, SetCounter }
├── ScrollBody (owns vertical scroll)
│   ├── ExerciseHeader { RoleEyebrow, ExerciseNameButton(→AtlasPeek), VariantLine | SubstitutionLineage }
│   ├── SetRail { SetPill × n }
│   ├── RestCard | PrescriptionCard
│   ├── EntryZone { LoadStepper, RepsSelector, RirSelector, AuxChips } | ExerciseCompleteCard + NextExerciseCard
├── ConfirmBar { PrimaryButton(Confirm set | Start next | Finish) }   (pinned, outside scroll)
└── Sheets: OutlineSheet, ActionsSheet, HoldConfirmSheet, ExercisePickerSheet, AtlasPeekSheet,
            NoteSheet(set|exercise), MoreDataSheet, LoadKeypadSheet, RepGridSheet, EditSetSheet,
            FinishSheet, SyncSheet

Home
├── HomeHeader { Brand, PlanRunChip }
├── TodayCard | ResumeCard | EmptyStateCard (+ banners)
├── AlternativeWorkoutLink → WorkoutUnitPickerSheet (wheel + explanation + start/hold)
├── MicrocycleStrip { DayCell × 7 }
└── RecentList

Atlas
├── AtlasHeader { Back, Title, WorkspaceCounterButton }
├── AtlasIndex { Search, OpenArticleChips, Segmented(Exercises|Muscles), ExerciseRow × n }
└── AtlasArticle { Header, Stats, InWorkoutBanner, StickySectionTabs, TechniqueTldr, BodyMap, MuscleList, KeyValueSections, Videos }
```

### 14.1 Scroll ownership and keyboard

- Focus: the body scrolls (small phones, large fonts), the **Confirm bar is pinned** outside the scroll view, top bar + progress are pinned. On ≥ 800 px tall screens nothing should need scrolling in the normal set state.
- Sheets own their own scroll; the sheet footer (primary/hold buttons) is pinned. Drag-to-dismiss only from the grab handle / header when content is scrolled, to avoid fighting the list.
- Keyboard appears only in Note sheets and Atlas search. When open, the sheet resizes (footer stays above the keyboard); Focus content underneath does not resize. No numeric system keyboard for loads — custom keypad sheet.

### 14.2 Safe areas and sizes

- Respect top and bottom safe areas; nothing interactive in the home-indicator zone (Confirm sits above it with ≥ 8 px).
- No drawn status bars or fake device chrome; the reference artboards leave the top 44 px empty for the real status bar.
- Minimum supported: 360 × 640 logical px. On narrow widths the reps/RIR rows keep 6 columns (buttons shrink to ≥ 48 px) — never wrap into two rows.
- Large text (≥ 130 %): mono numerals in the entry zone cap their scale at 1.3×; labels wrap; the Focus body scrolls; Confirm stays pinned.
- Portrait-first; landscape not required. The Atlas article may support landscape for the body map (optional).

---

## 15. Visual language (intent)

Source of truth: existing Agonez screens (dark theme, Execution reference) — serious, precise, technical, restrained. The mobile app defaults to the **dark theme** in the gym and follows the user's theme setting; the light theme maps the same roles.

| Role | Prototype value (intent) | Use |
| --- | --- | --- |
| Ground | `#0D0F12` | App background |
| Panel / raised | `#14171B` / `#181C21` | Cards, sheets (`#15181C`) |
| Lines | `#23272D` / `#1E2227` | Hairlines, card borders |
| Controls | `#2A2E35` / `#3A3F47` | Button borders, stepper |
| Text | `#E9E7E2`, secondary `#C9CDD3`, muted `#9AA0A8`, dim `#7A808A` | |
| Gold (brand accent) | `#C2A36B`, text `#E2C690`, ink `#17140D` | Primary button, current set, active workout, focus ring. One accent only. |
| Prescription | `#8FA9C4` / `#AFC2D6`, bg `rgba(143,169,196,.07)` | Prescribed values, targets, target underlines — *only* prescription |
| Divergence / caution | `#E8B06A` | Divergence dots, deviation explanations, offline |
| Completed | `#4E9C79` / `#7FC4A0` | Done pills/sets, "Saved", completion |
| Error | `#E5735C` | Sync failed, conflict |
| Muscle heat | `#2E9E78` | Body map, ETU bars (same as desktop Atlas) |

Typography (prototype uses Geist / Geist Mono as stand-ins; use the app's configured families):

| Style | Size / weight | Use |
| --- | --- | --- |
| Display | 34 / 600, −0.02em | Today unit name |
| Exercise title | 27 / 600, −0.02em | Focus exercise name |
| Sheet title | 20 / 600 | |
| Body | 13–15 / 400–500 | |
| Eyebrow | mono 10.5, letter-spacing 0.14em, uppercase | Section labels (`PRESCRIBED · SET 2`, `EXERCISE 3 / 6`) — the signature Agonez device |
| Numerals (input) | mono 19–26 / 500 | Load value, rep/RIR buttons, prescription line |
| Clock | mono 44 | Rest countdown |

Shape & spacing: radii 8 (controls), 12–14 (cards, primary buttons), 18 (hero cards), 22 (sheet top). Side gutter 20 (16 for the entry zone). Spacing rhythm 6 / 8 / 12 / 14 / 16. Shadows only on sheets/snackbar. No gradients beyond the subtle hero-card wash; no emoji, flames, trophies or streaks; no motivational slogans.

Status is never colour-only: pills carry icons/words (`✓`, `skipped`, `EXTRA`), sync pill carries text, divergence lines carry text.

---

## 16. Accessibility

- Contrast ≥ 4.5:1 for text; muted text on panels must stay ≥ 4.5:1 (`#9AA0A8` on `#14171B` passes; avoid `#6E747D` for body copy).
- All controls are real buttons with labels: load ± ("Minus 2.5 kilograms"), value ("Load 67.5 kilograms, double-tap to type"), rep/RIR buttons announce "6 repetitions, selected, within target".
- Set rail announces "Set 1 of 3, done, 67.5 kilograms × 7 at RIR 1, differs from prescription" when applicable.
- Hold-to-confirm: custom accessibility action (see §7).
- Snackbar Undo is reachable by screen readers and stays 10 s when a screen reader is active.
- Reduced motion: no sheet springs, no progress easing; the hold fill still progresses.
- Live regions: sync state changes are announced politely; rest completion is announced.

---

## 17. Data-to-UI mapping

| UI element | Source (`mobile-api-contract.md`) |
| --- | --- |
| Run chip | `context.plan_run.name`, `today.microcycle.ordinal` / `plan_run.microcycle_count` |
| Today eyebrow | `today.date`, `today.microcycle.ordinal`, `day_ordinal` |
| Today title / readiness | `expected_session.workout_unit_name`, `prescription.readiness`, `updated_at` |
| Today facts | `exercise_count`, `set_count`, `estimated_duration_min` |
| Today exercise list | prescription `exercises[].exercise.name`, `sets.length`, `rep_min–rep_max`, `sets[0].prescribed_load_kg` |
| Microcycle strip | `context.microcycle_days[]` (`status`: completed / scheduled / in_progress / missed / cancelled / rest_day) |
| Picker wheel | `expected_session` + `alternatives[]` (+ `fallbacks[]` dashed, disabled) |
| Resume card | `active_workout` + local store (position, rest) |
| Progress segments | local performance tree: sets per exercise performance, status |
| Role eyebrow | `exercises[].slot.role` (localized) |
| Exercise name | performance `actual_exercise.name` (falls back to prescription exercise) |
| Variant line | `exercises[].variant_label` |
| Lineage block | prescription `exercise.name` + `variant_label` vs performance `actual_exercise.name` when `mode = substituted` |
| Set pills | performance `sets[]` (status, load, reps, rir) over prescription `sets[]` |
| Prescription card | prescription `sets[i].prescribed_load_kg`, `rep_min`, `rep_max`, `target_rir`, `comment`; exercise `prescription_comment` on the first set |
| LAST · MC6 | `history.previous_exposure.sets[same ordinal]` |
| Load step | `load_step_kg` |
| Rest default | `default_rest_s` (client may override from settings) |
| Divergence lines | computed client-side: actual vs prescribed (never sent as a flag) |
| Plan note in peek | `exercises[].plan_comment` |
| Atlas peek | `exercises[].atlas_peek` (offline) or `GET /atlas/exercises/{id}/peek` |
| Substitute list | `exercises[].alternatives[]` then `GET /atlas/exercises?q=&plan_run_id=` |
| Substitute load prefill | `last_performed_in_run.sets[0].load_kg` |
| Sync pill | local queue length + last response (`applied_seq`, errors) |
| Recorded summary | finalize `summary` (or local computation when queued) |

---

## 18. Locale key groups

User-facing strings must come from localization (en, pl, fr, es, de, it, nl, sv, pt-BR, uk, tr). Suggested groups — adapt naming to the Flutter project's conventions:

```text
mobile.nav                 home, workout, atlas, you, workout_active_a11y
mobile.home                today, rest_day, prescription_ready, prescription_not_ready, prescription_changed,
                           facts.exercises/sets/minutes, start, start_with_plan_targets, other_workout_unit,
                           microcycle, recent, desktop_hint, resume.*, no_run.*, active_elsewhere.*, start_failed.*
mobile.run                 sheet_title, plan, microcycle_position, locked_during_workout, remembered_hint
mobile.picker              title, today, scheduled_on, done_on, fallback, not_today_explanation, start_instead, fallback_future
mobile.workout             minimise_a11y, outline, actions, exercise_counter, set_counter, elapsed, role.*,
                           prescribed_set, last_exposure, note_label, set_label, extra_label, unplanned, order_changed,
                           exercise_complete, up_next, start_next, finish_workout
mobile.workout.set         load, reps, rir, target, tap_to_type, other, confirm, confirm_summary, select_reps_rir,
                           enter_load, kept_from_last_set, reset, recorded_snackbar, undo, edit_title, mark_skipped
mobile.workout.divergence  load_delta, reps_below, reps_above, rir_deeper, rir_lighter, differs_a11y
mobile.workout.note        set_title, exercise_title, exposure_only_hint, placeholder.*, suggestions.*
mobile.workout.moredata    title, heart_rate, future_sensor_hint
mobile.workout.deviation   section_title, friction_a11y, hold_label, hold_duration,
                           skip_set.*, add_set.*, skip_exercise.*, substitute.*, reorder.*, add_unplanned.*,
                           substitution_locked_after_sets, lineage.performed, lineage.prescribed, prescription_was_for, target_band_applies
mobile.workout.finish      title_incomplete, explanation, continue, hold_finish, complete_title, finish
mobile.workout.timer       rest, rest_complete_over, minus_30, plus_30, end_rest, up_next_set, notification.title/body
mobile.workout.sync        saved, saving, offline_count, failed, conflict, superseded, sheet.*, retry, keep_phone, use_server, resume_here
mobile.workout.recorded    title, synced, saved_locally, sets_done, not_done, structural_changes, tags.*, done
mobile.atlas               title, search_placeholder, open_articles, exercises, muscles, quick_view, open_full,
                           plan_note_this_workout, in_today_workout, sections.*, technique_tldr.*, etu, recovery,
                           classification.*, rep_ranges.*, videos, offline_unavailable
mobile.workspace           title, pinned_hint, active, cannot_close, close_a11y, new_tab, counter_a11y
mobile.you                 active_plan_run, workout_settings.*, app_settings.*, sync_status
mobile.errors              <one key per API error code in mobile-api-contract.md>
```

Exercise and muscle names come from Atlas content localization (server), not from app strings.

---

## 19. Local persistence (behavioural requirements only)

The storage technology is the implementer's choice. Required behaviour:

1. Atomic writes per user action (a confirmed set and its queued op are stored together or not at all).
2. Stored: active workout (frozen prescription, performance tree, cursor, entry draft, rest timer timestamps), op queue (with seq, epoch, op_id), last server ack, open Atlas workspaces (+ scroll offsets), selected plan run, settings.
3. Survives app kill and OS restart; is read synchronously enough at cold start to render the Resume card in the first frame after splash.
4. Op queue is FIFO; coalescing allowed only for ops on the same entity with no intervening op that depends on it.
5. Finished workouts remain locally until the finalize is acknowledged; then can be pruned.

---

## 20. Priorities

**P0 — must be exact:** today's workout flow (Home Today card, Start), Focus Mode structure, one-thumb set logging (§6 defaults, targets, 3-tap path), prescription vs actual separation and divergence treatment, active workout persistence & single-active rule, resume after kill/background, structural-deviation friction (§7 table and hold component), quick Atlas peek, workout progress, finish/finalize flow incl. incomplete confirmation, offline/sync semantics & pill states.

**P1 — should match closely:** persistent Atlas workspaces & switcher, rest timer behaviour incl. notifications, upcoming exercises (outline + next card), subtle history (`LAST · MC6`), haptics map, detailed Atlas article adaptation.

**P2 — may adapt:** transition animations, icon choices, exact shadow/radius values, decorative details (hero card wash, card textures), wheel picker styling.

---

## 21. Design decisions summary

- **Information architecture.** Four tabs, one immersive Focus route above them. The workout is a *persistent workspace*, not a page: it's reachable from the Workout tab, the mini bar, the Resume card and the pinned workspace card, and it can only end via *Finish*.
- **Why Focus Mode looks like this.** Orientation at the top (unit, progress, exercise, set rail), prescription in the middle in its own colour family, input at the bottom under the thumb, one pinned primary action. Rest replaces the prescription card in place so the athlete never navigates during a workout.
- **One-thumb strategy.** Load prefilled from the prescription (or the athlete's own last load when they deviated), reps and RIR deliberately unselected, big 6-column selectors with the target band marked, custom keypad instead of the system keyboard, 6-second Undo instead of confirmations.
- **Deviation friction.** Normal divergence is free and visible; structural changes go through one actions sheet and a hold-to-confirm whose duration scales with impact (0.6 → 1.4 s), always with one sentence on comparability. No nested modals, no countdowns.
- **Active-workout persistence.** Local-first everything: start, every set, every deviation. Timestamps instead of running state. Cold start renders Resume immediately from the local store.
- **Atlas: peek vs workspace.** Peek is a sheet over the workout for "remind me what to focus on" (TL;DR + body map + plan note) and works offline; *Open full Atlas article* creates a workspace in the Atlas tab while the workout keeps running in the mini bar.
- **Tab/workspace strategy.** Browser-tab mental model translated to mobile: a counter button and a card switcher, the workout pinned and non-closable, Atlas cards closable, nothing permanently on screen during set logging.
- **Offline/sync philosophy.** The network is never in the athlete's critical path. An ordered op log with client UUIDs makes retries harmless; the UI shows a quiet pill and asks the athlete only when a real conflict needs a human decision.

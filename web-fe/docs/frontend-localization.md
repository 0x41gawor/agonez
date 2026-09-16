# Frontend localization architecture

## Current scope

The web frontend supports English (`en`), Polish (`pl`), French (`fr`), Spanish
(`es`), and German (`de`) UI copy. The language
selector lives in the application header, persists the explicit choice under
`agonez-locale`, and otherwise starts from the browser's preferred supported
language. English remains the fallback for missing messages.

This phase translates application-owned copy only. Exercise names, muscle names,
technique, comments, and other database-authored content remain exactly as returned
by the API until the backend translation tables are connected.

## Runtime design

- `src/i18n/index.ts` owns supported locales, browser/storage detection, lazy bundle
  loading, fallback behavior, the document `lang` attribute, and persistence.
- `src/i18n/locales/{en,pl,fr,es,de}` splits messages by `common`, `atlas`, `plans`, and
  `analysis` domain. A new module can be added without growing one global file.
- `src/stores/locale.ts` is the UI-facing locale controller. Components do not write
  storage or mutate Vue I18n directly.
- `src/components/shell/LocaleSwitcher.vue` is the single global selector.
- Formatting helpers use the active locale for numbers, percentages, and dates.
- Every API request includes the active supported locale in `Accept-Language`. This is inert with the current
  backend and becomes the content-negotiation contract for the next phase.

Locale bundles are loaded on demand. The English bundle remains available as the
fallback after switching languages.

## Data and draft safety

PlanCreator's editable plan draft is deliberately language-neutral and separate from
localized Atlas catalog data:

- `usePlanDraft` loads and owns only the persisted plan aggregate.
- `useAtlasCatalogStore` owns exercise and muscle display catalogs and records which
  locale produced them.
- Changing locale reloads the catalog for that locale but does not reload, replace,
  or serialize the active draft. Unsaved plan edits therefore survive a language
  switch.
- Stable slugs and IDs remain the references stored in plans. Translated display
  strings are never persisted into plan relationships.

## Expected backend contract

The frontend is ready for either of these equivalent server interfaces:

1. Resolve localized fields from `Accept-Language` (preferred), returning the normal
   resource schema with translated display fields already overlaid.
2. Accept an explicit `lang=<supported-locale>` query parameter if HTTP content negotiation is not
   practical. The client should use one method consistently, not both.

The backend should apply a deterministic fallback chain:

`requested locale -> default/source locale -> canonical existing value`

Responses should expose the same stable resource ID and slug in every language. A
missing translation must never make an exercise or muscle disappear. Search, sort,
and pagination should operate on the resolved language on the server once localized
database content is enabled.

Recommended translation records should store the resource identity, normalized
locale tag, translated fields, and timestamps. Long structured exercise technique
may use one locale-specific JSON document per exercise while ordinary names and prose
fit conventional translation columns. The precise schema will be aligned with the
database migration before backend implementation.

## Adding a language

1. Add the locale to `SUPPORTED_LOCALES` and its lazy loader.
2. Create the same domain files beneath `src/i18n/locales/<locale>`.
3. Add the selector option and an `intlLocale` mapping.
4. Add backend content support and fallback rules.
5. Run the localization, type, lint, unit, and production build checks.

Use BCP 47 language tags at system boundaries. The current UI intentionally reduces
regional tags such as `pl-PL` and `en-US` to the supported base locales.

# Frontend localization architecture

## Current scope

The web frontend supports English (`en`), Polish (`pl`), French (`fr`), Spanish
(`es`), German (`de`), Italian (`it`), Brazilian Portuguese (`pt-BR`), Swedish
(`sv`), Dutch (`nl`), and Ukrainian (`uk`) UI copy. The language
selector lives in the application header, persists the explicit choice under
`agonez-locale`, and otherwise starts from the browser's preferred supported
language. English remains the fallback for missing messages.

Exercise and muscle fields requested from the API are localized when a database
translation exists. Missing fields fall back to canonical `core` content, so partial
translation coverage never removes or empties a catalog record.

## Runtime design

- `src/i18n/index.ts` owns supported locales, browser/storage detection, lazy bundle
  loading, fallback behavior, the document `lang` attribute, and persistence.
- `src/i18n/locales/{en,pl,fr,es,de,it,pt-BR,sv,nl,uk}` splits messages by `common`, `atlas`, `plans`, and
  `analysis` domain. A new module can be added without growing one global file.
- `src/stores/locale.ts` is the UI-facing locale controller. Components do not write
  storage or mutate Vue I18n directly.
- `src/components/shell/LocaleSwitcher.vue` is the single global selector.
- Formatting helpers use the active locale for numbers, percentages, and dates.
- Every API request includes the active supported locale in `Accept-Language`; the
  backend uses it for localized Atlas content negotiation.

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

## Backend contract

The backend resolves localized fields from `Accept-Language`, returning the normal
resource schema with translated display fields overlaid.

The backend should apply a deterministic fallback chain:

`requested locale -> default/source locale -> canonical existing value`

Responses should expose the same stable resource ID and slug in every language. A
missing translation must never make an exercise or muscle disappear. Search, sort,
and pagination should operate on the resolved language on the server once localized
database content is enabled.

Translation records store the resource identity, normalized locale tag, translated
fields, and timestamps. Long structured exercise technique may use one locale-specific
JSON document per exercise while ordinary names and prose fit conventional translation
columns.

## Adding a language

1. Add the locale to `SUPPORTED_LOCALES` and its lazy loader.
2. Create the same domain files beneath `src/i18n/locales/<locale>`.
3. Add the selector option and an `intlLocale` mapping.
4. Add backend content support and fallback rules.
5. Run the localization, type, lint, unit, and production build checks.

Use BCP 47 language tags at system boundaries. The UI reduces regional tags such as
`pl-PL` and `en-US` to supported base locales, while Portuguese variants resolve to
the explicitly supported Brazilian locale (`pt-BR`).

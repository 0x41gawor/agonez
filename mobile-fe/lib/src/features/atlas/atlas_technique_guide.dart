import 'package:flutter/material.dart';

import '../../api/json_support.dart';
import '../../design/design.dart';
import '../../l10n/generated/app_localizations.dart';

/// Accent of a technique field, mirroring the web guide's tones.
enum TechniqueTone { neutral, motion, cue, warning, effort, danger, safety }

/// One technique field ready to render, in canonical position.
@immutable
class TechniqueEntry {
  const TechniqueEntry(
    this.key,
    this.value, [
    this.tone = TechniqueTone.neutral,
  ]);

  final String key;
  final Object? value;
  final TechniqueTone tone;
}

/// A titled block of the guide: `tldr`, one of the six canonical groups, or
/// `additional` for fields the guide does not know yet.
@immutable
class TechniqueSection {
  const TechniqueSection(this.key, this.entries);

  final String key;
  final List<TechniqueEntry> entries;
}

typedef _FieldSpec = (String key, TechniqueTone tone);

const _tldrSequence = <_FieldSpec>[
  ('setup', TechniqueTone.neutral),
  ('execution', TechniqueTone.neutral),
  ('focus', TechniqueTone.cue),
  ('stop_when', TechniqueTone.warning),
];

// Canonical UI order, kept identical to web-fe's TechniqueGuide.vue. It lives
// in code because the API stores technique as Postgres jsonb, which returns
// object keys sorted by length rather than in authoring order.
const _groupSequence = <(String key, List<_FieldSpec> fields)>[
  (
    'overview',
    [
      ('overview', TechniqueTone.neutral),
      ('plane_of_movement', TechniqueTone.motion),
      ('primary_joint_actions', TechniqueTone.motion),
    ],
  ),
  (
    'preparation',
    [
      ('equipment_setup', TechniqueTone.neutral),
      ('starting_position', TechniqueTone.neutral),
      ('grip', TechniqueTone.neutral),
      ('stance', TechniqueTone.neutral),
      ('bracing', TechniqueTone.safety),
    ],
  ),
  (
    'execution',
    [
      ('concentric', TechniqueTone.motion),
      ('eccentric', TechniqueTone.motion),
      ('end_position', TechniqueTone.neutral),
      ('range_of_motion', TechniqueTone.motion),
      ('tempo_notes', TechniqueTone.neutral),
    ],
  ),
  (
    'cues',
    [
      ('internal_cues', TechniqueTone.cue),
      ('external_cues', TechniqueTone.cue),
    ],
  ),
  (
    'effort',
    [
      ('technical_failure', TechniqueTone.warning),
      ('rir_1_indicators', TechniqueTone.effort),
      ('rir_0_definition', TechniqueTone.danger),
    ],
  ),
  (
    'troubleshooting',
    [
      ('common_mistakes', TechniqueTone.warning),
      ('safety_notes', TechniqueTone.safety),
      ('individualization', TechniqueTone.neutral),
    ],
  ),
];

/// Orders an article's `technique` JSON into TL;DR, the six canonical
/// groups and finally any unknown fields. Empty fields and sections are
/// dropped, so a partially authored exercise still reads cleanly.
List<TechniqueSection> orderTechnique(JsonMap technique) {
  final tldrValue = technique['tldr'];
  final tldr = tldrValue is Map ? tldrValue.cast<String, Object?>() : null;
  final known = {
    'tldr',
    for (final (_, fields) in _groupSequence)
      for (final (key, _) in fields) key,
  };

  return [
    if (tldr != null) _section('tldr', _tldrSequence, tldr),
    for (final (key, fields) in _groupSequence)
      _section(key, fields, technique),
    TechniqueSection('additional', [
      for (final MapEntry(:key, :value) in technique.entries)
        if (!known.contains(key) && _hasContent(value))
          TechniqueEntry(key, value),
    ]),
  ].where((section) => section.entries.isNotEmpty).toList(growable: false);
}

/// Canonical fields first, then any extra keys present in [source].
TechniqueSection _section(
  String key,
  List<_FieldSpec> sequence,
  JsonMap source,
) {
  final canonical = {for (final (field, _) in sequence) field};
  return TechniqueSection(key, [
    for (final (field, tone) in sequence)
      if (_hasContent(source[field]))
        TechniqueEntry(field, source[field], tone),
    if (key == 'tldr')
      for (final MapEntry(:key, :value) in source.entries)
        if (!canonical.contains(key) && _hasContent(value))
          TechniqueEntry(key, value),
  ]);
}

bool _hasContent(Object? value) => switch (value) {
  null => false,
  final String text => text.trim().isNotEmpty,
  final List<Object?> items => items.any(_hasContent),
  final Map<Object?, Object?> map => map.values.any(_hasContent),
  _ => true,
};

/// The full technique guide shown in the Atlas article.
class AtlasTechniqueGuide extends StatelessWidget {
  const AtlasTechniqueGuide({required this.technique, super.key});

  final JsonMap technique;

  @override
  Widget build(BuildContext context) {
    final sections = orderTechnique(technique);
    if (sections.isEmpty) {
      return Text(
        AppLocalizations.of(context).atlasTechniqueEmpty,
        style: TextStyle(color: context.agonezColors.textMuted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, section) in sections.indexed) ...[
          if (index > 0) const SizedBox(height: AgonezSpacing.md),
          _SectionCard(section: section),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final TechniqueSection section;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.agonezColors;
    final textTheme = Theme.of(context).textTheme;
    final tldr = section.key == 'tldr';
    final (title, description) = _sectionText(l10n, section.key);
    return AgonezPanel(
      backgroundColor: tldr ? colors.goldSoft : null,
      borderColor: tldr ? colors.goldLine : null,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: textTheme.titleMedium),
          ),
          const SizedBox(height: 3),
          Text(
            description,
            style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: 6),
          for (final (index, entry) in section.entries.indexed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: index == 0
                  ? null
                  : BoxDecoration(
                      border: Border(top: BorderSide(color: colors.lineSubtle)),
                    ),
              child: _Field(entry: entry, label: _fieldLabel(l10n, entry.key)),
            ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.entry, required this.label});

  final TechniqueEntry entry;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.agonezColors;
    final accent = switch (entry.tone) {
      TechniqueTone.neutral => colors.controlStrong,
      TechniqueTone.motion => colors.prescription,
      TechniqueTone.cue => colors.gold,
      TechniqueTone.warning || TechniqueTone.effort => colors.caution,
      TechniqueTone.danger => colors.error,
      TechniqueTone.safety => colors.success,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 3,
          height: 14,
          margin: const EdgeInsets.only(right: 10, top: 1),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AgonezEyebrow(label, color: colors.goldText),
              const SizedBox(height: 5),
              _Value(value: entry.value),
            ],
          ),
        ),
      ],
    );
  }
}

/// Renders a technique value the way web-fe's TechniqueValue does: lists as
/// bullets, objects as labelled pairs, everything else as text.
class _Value extends StatelessWidget {
  const _Value({required this.value});

  final Object? value;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    final value = this.value;
    if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in value.where(_hasContent))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: style),
                  Expanded(child: _Value(value: item)),
                ],
              ),
            ),
        ],
      );
    }
    if (value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final MapEntry(:key, :value) in value.entries)
            if (_hasContent(value))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AgonezEyebrow(_fallbackLabel('$key'), uppercase: false),
                    const SizedBox(height: 2),
                    _Value(value: value),
                  ],
                ),
              ),
        ],
      );
    }
    return Text(value is String ? value.trim() : '$value', style: style);
  }
}

(String, String) _sectionText(AppLocalizations l10n, String key) =>
    switch (key) {
      'tldr' => (l10n.atlasTechniqueTldr, l10n.atlasTechniqueTldrDescription),
      'overview' => (
        l10n.atlasTechniqueMovementOverview,
        l10n.atlasTechniqueMovementOverviewDescription,
      ),
      'preparation' => (
        l10n.atlasTechniquePreparation,
        l10n.atlasTechniquePreparationDescription,
      ),
      'execution' => (
        l10n.atlasTechniqueRepetition,
        l10n.atlasTechniqueRepetitionDescription,
      ),
      'cues' => (l10n.atlasTechniqueCues, l10n.atlasTechniqueCuesDescription),
      'effort' => (
        l10n.atlasTechniqueEffort,
        l10n.atlasTechniqueEffortDescription,
      ),
      'troubleshooting' => (
        l10n.atlasTechniqueTroubleshooting,
        l10n.atlasTechniqueTroubleshootingDescription,
      ),
      _ => (
        l10n.atlasTechniqueAdditional,
        l10n.atlasTechniqueAdditionalDescription,
      ),
    };

String _fieldLabel(AppLocalizations l10n, String key) => switch (key) {
  'setup' => l10n.atlasTechniqueSetup,
  'execution' => l10n.atlasTechniqueExecution,
  'focus' => l10n.atlasTechniqueFocus,
  'stop_when' => l10n.atlasTechniqueStopWhen,
  'overview' => l10n.atlasTechniqueOverview,
  'plane_of_movement' => l10n.atlasTechniquePlane,
  'primary_joint_actions' => l10n.atlasTechniqueJointActions,
  'equipment_setup' => l10n.atlasTechniqueEquipment,
  'starting_position' => l10n.atlasTechniqueStartingPosition,
  'grip' => l10n.atlasTechniqueGrip,
  'stance' => l10n.atlasTechniqueStance,
  'bracing' => l10n.atlasTechniqueBracing,
  'concentric' => l10n.atlasTechniqueConcentric,
  'eccentric' => l10n.atlasTechniqueEccentric,
  'end_position' => l10n.atlasTechniqueEndPosition,
  'range_of_motion' => l10n.atlasTechniqueRange,
  'tempo_notes' => l10n.atlasTechniqueTempo,
  'internal_cues' => l10n.atlasTechniqueInternalCues,
  'external_cues' => l10n.atlasTechniqueExternalCues,
  'technical_failure' => l10n.atlasTechniqueTechnicalFailure,
  'rir_1_indicators' => l10n.atlasTechniqueRir1,
  'rir_0_definition' => l10n.atlasTechniqueRir0,
  'common_mistakes' => l10n.atlasTechniqueCommonMistakes,
  'safety_notes' => l10n.atlasTechniqueSafetyNotes,
  'individualization' => l10n.atlasTechniqueIndividualization,
  _ => _fallbackLabel(key),
};

String _fallbackLabel(String key) {
  final text = key.replaceAll('_', ' ').trim();
  return text.isEmpty ? key : text[0].toUpperCase() + text.substring(1);
}

import 'package:flutter/foundation.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../workout/load_format.dart';
import 'focus_workout_models.dart';

/// A refused edit as the athlete reads it: what it was about, and what
/// this phone and the server each hold.
@immutable
class ConflictDescription {
  const ConflictDescription({
    required this.subject,
    required this.phone,
    required this.server,
  });

  /// The exercise, and the set or note within it; null when the edit
  /// cannot be traced to anything on screen.
  final String? subject;
  final String phone;
  final String server;
}

/// Describes the operation [type] with its queued [data] against the
/// server's copy, [serverState] (null when the server has none).
ConflictDescription describeConflict({
  required String type,
  required Map<String, Object?> data,
  required Object? serverState,
  required FocusWorkoutViewModel workout,
  required AppLocalizations l10n,
}) {
  final server = serverState is Map
      ? Map<String, Object?>.from(serverState)
      : null;
  final setId = data['set_performance_id'];
  final exerciseId = data['exercise_performance_id'];
  final exercise = workout.exercises
      .where(
        (item) =>
            item.id == exerciseId || item.sets.any((set) => set.id == setId),
      )
      .firstOrNull;
  final set = exercise?.sets.where((item) => item.id == setId).firstOrNull;

  String? subject(String? detail) => exercise == null
      ? null
      : detail == null
      ? exercise.name
      : '${exercise.name} · $detail';

  switch (type) {
    case 'set_exercise_comment':
      return ConflictDescription(
        subject: subject(l10n.noteExerciseTitle),
        phone: _note(data['comment'], l10n),
        server: _note(server?['comment'], l10n),
      );
    case 'skip_exercise' || 'substitute_exercise':
      return ConflictDescription(
        subject: subject(null),
        phone: type == 'skip_exercise'
            ? _capitalised(l10n.recordedTagSkipped)
            : exercise?.name ?? _capitalised(l10n.recordedTagSubstituted),
        server: _exerciseMode(server, exercise, l10n),
      );
    case 'upsert_set' || 'skip_set' || 'clear_set':
      return ConflictDescription(
        subject: subject(set == null ? null : l10n.workoutSetLabel(set.number)),
        phone: switch (type) {
          'skip_set' => l10n.workoutSkippedLabel,
          'clear_set' => l10n.syncConflictUndone,
          _ => _set({...data, 'status': 'performed'}, l10n),
        },
        server: server == null
            ? l10n.syncConflictNotRecorded
            : _set(server, l10n),
      );
    default:
      return ConflictDescription(
        subject: subject(null),
        phone: '—',
        server: '—',
      );
  }
}

String _note(Object? value, AppLocalizations l10n) =>
    value is String && value.trim().isNotEmpty
    ? value.trim()
    : l10n.syncConflictNoNote;

String _set(Map<String, Object?> value, AppLocalizations l10n) {
  if (value['status'] == 'skipped') return l10n.workoutSkippedLabel;
  final load = _number(value['load_kg']);
  final reps = _number(value['repetitions'])?.round();
  final rir = _number(value['rir'])?.round();
  final values =
      '${load == null ? '—' : formatLoad(load)} kg × ${reps ?? '—'} '
      '@ RIR ${rir ?? '—'}';
  final note = value['comment'];
  return note is String && note.trim().isNotEmpty
      ? '$values\n${note.trim()}'
      : values;
}

String _exerciseMode(
  Map<String, Object?>? server,
  FocusExerciseViewModel? exercise,
  AppLocalizations l10n,
) => switch (server?['mode']) {
  'skipped' => _capitalised(l10n.recordedTagSkipped),
  'substituted' => _capitalised(l10n.recordedTagSubstituted),
  'added' => _capitalised(l10n.recordedTagUnplanned),
  'not_performed' => _capitalised(l10n.recordedTagIncomplete),
  _ => exercise?.prescribedName ?? exercise?.name ?? '—',
};

/// The server sends decimals as strings.
double? _number(Object? value) => switch (value) {
  num() => value.toDouble(),
  String() => double.tryParse(value),
  _ => null,
};

String _capitalised(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../storage/app_database.dart';

/// The plan's two routines around a workout's exercises.
enum RoutineKind { warmup, stretch }

/// What the athlete ticked off in one workout's routine. It stays on this
/// phone: the routines are plain notes, nothing the server records.
@immutable
class RoutineProgress {
  const RoutineProgress({this.done = const {}, this.finished = false});

  /// Ticked movements, by their place in the routine counting from 0.
  final Set<int> done;

  /// Whether the athlete moved on from the routine.
  final bool finished;

  RoutineProgress copyWith({Set<int>? done, bool? finished}) => RoutineProgress(
    done: done ?? this.done,
    finished: finished ?? this.finished,
  );
}

class RoutineProgressStore {
  const RoutineProgressStore(this._database);

  final AppDatabase _database;

  Future<RoutineProgress> load(String workoutId, RoutineKind kind) async {
    final raw = await _database.readSetting(_key(workoutId, kind));
    if (raw == null) return const RoutineProgress();
    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      return RoutineProgress(
        done: {
          for (final index in json['done']! as List<Object?>) index! as int,
        },
        finished: json['finished'] == true,
      );
    } on Object {
      // A stored value it cannot read is no progress, not a broken workout.
      return const RoutineProgress();
    }
  }

  Future<void> save(
    String workoutId,
    RoutineKind kind,
    RoutineProgress progress,
  ) => _database.writeSetting(
    _key(workoutId, kind),
    jsonEncode(<String, Object?>{
      'done': (progress.done.toList()..sort()),
      'finished': progress.finished,
    }),
  );

  static String _key(String workoutId, RoutineKind kind) =>
      'routine:${kind.name}:$workoutId';
}

import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import '../domain/models.dart';
import '../domain/ids.dart';
import 'api.dart';
import 'database.dart';

class SyncEngine {
  SyncEngine(this.db, this.api);
  final AppDatabase db;
  final MobileApi api;
  bool _busy = false;
  Timer? _retry;

  Future<void> synchronize() async {
    if (_busy) return;
    _busy = true;
    try {
      final candidate = await db.syncCandidate();
      if (candidate == null) return;
      var workout = candidate;
      if (workout.status == 'pending_start') {
        final p = Prescription.decode(workout.prescriptionJson);
        final snap = await api.start({
          'workout_id': workout.id,
          'session_id': workout.sessionId,
          'prescription_version': p.version,
          'started_at': workout.startedAt,
          'allow_missing_loads': false,
          'off_schedule': null,
        });
        await (db.update(
          db.localWorkouts,
        )..where((t) => t.id.equals(workout.id))).write(
          LocalWorkoutsCompanion(
            status: const Value('active'),
            leaseEpoch: Value((snap['lease'] as Map)['epoch'] as int),
            appliedSeq: Value(snap['applied_seq'] as int),
          ),
        );
      }
      await _repairMissingExerciseReferences(workout);
      workout = await (db.select(
        db.localWorkouts,
      )..where((t) => t.id.equals(workout.id))).getSingle();
      final current = await (db.select(
        db.localWorkouts,
      )..where((t) => t.id.equals(workout.id))).getSingle();
      final queued = await db.pending(workout.id);
      if (queued.isNotEmpty) {
        final contiguous = queued.take(200).toList();
        final response = await api.ops(workout.id, {
          'lease_epoch': current.leaseEpoch,
          'base_seq': contiguous.first.seq - 1,
          'ops': contiguous
              .map(
                (o) => {
                  'op_id': o.opId,
                  'seq': o.seq,
                  'at': o.at,
                  'type': o.type,
                  'data': jsonDecode(o.payloadJson),
                },
              )
              .toList(),
        });
        await db.transaction(() async {
          final results = (response['results'] as List).cast<Map>();
          for (final op in contiguous) {
            final result = results.firstWhere((r) => r['op_id'] == op.opId);
            final status = result['status'] as String;
            if (status == 'applied' || status == 'duplicate') {
              await (db.delete(
                db.pendingOps,
              )..where((t) => t.opId.equals(op.opId))).go();
            } else {
              final error = result['error'] as Map?;
              await (db.update(
                db.pendingOps,
              )..where((t) => t.opId.equals(op.opId))).write(
                PendingOpsCompanion(
                  state: Value(status),
                  errorCode: Value(error?['code'] as String?),
                ),
              );
            }
          }
          await (db.update(
            db.localWorkouts,
          )..where((t) => t.id.equals(workout.id))).write(
            LocalWorkoutsCompanion(
              appliedSeq: Value(response['applied_seq'] as int),
              status: Value(
                results.any((r) => r['status'] == 'conflict')
                    ? 'conflict'
                    : results.any((r) => r['status'] == 'rejected')
                    ? 'sync_failed'
                    : current.finalizeJson != null
                    ? 'pending_finalize'
                    : 'active',
              ),
            ),
          );
        });
      }
      final refreshed = await (db.select(
        db.localWorkouts,
      )..where((t) => t.id.equals(workout.id))).getSingle();
      if (refreshed.status == 'pending_finalize' &&
          (await db.pending(workout.id)).isEmpty &&
          await db.unresolvedCount(workout.id) == 0) {
        final finalizeBody = jsonDecode(refreshed.finalizeJson!) as Json;
        finalizeBody['lease_epoch'] = refreshed.leaseEpoch;
        finalizeBody['final_seq'] = refreshed.appliedSeq;
        await (db.update(
          db.localWorkouts,
        )..where((t) => t.id.equals(workout.id))).write(
          LocalWorkoutsCompanion(finalizeJson: Value(jsonEncode(finalizeBody))),
        );
        await api.finalize(workout.id, finalizeBody);
        await (db.update(
          db.localWorkouts,
        )..where((t) => t.id.equals(workout.id))).write(
          const LocalWorkoutsCompanion(
            status: Value('finalized'),
            restEndsAt: Value(null),
          ),
        );
      }
      _retry?.cancel();
    } catch (_) {
      _retry?.cancel();
      _retry = Timer(const Duration(seconds: 5), synchronize);
    } finally {
      _busy = false;
    }
  }

  Future<void> _repairMissingExerciseReferences(LocalWorkout workout) async {
    final rejected = await db.rejectedMissingExerciseRefs(workout.id);
    if (rejected.isEmpty) return;

    final snapshot = await api.snapshot(workout.id);
    final serverExercises =
        (snapshot['performance'] as Map)['exercises'] as List;
    final prescription = Prescription.decode(workout.prescriptionJson);
    final exerciseBySet = <int, Json>{};
    for (final exercise in prescription.exercises) {
      for (final set in (exercise['sets'] as List).cast<Map>()) {
        exerciseBySet[set['set_prescription_id'] as int] = exercise;
      }
    }
    final latestBySet = <int, PendingOp>{};
    for (final op in rejected) {
      final data = jsonDecode(op.payloadJson) as Json;
      final prescribedSetId = data['prescribed_set_id'] as int?;
      if (prescribedSetId != null) latestBySet[prescribedSetId] = op;
    }

    await db.transaction(() async {
      var nextSeq = workout.nextSeq;
      for (final entry in latestBySet.entries) {
        final old = entry.value;
        final data = jsonDecode(old.payloadJson) as Json;
        final exercise = exerciseBySet[entry.key];
        if (exercise == null) continue;
        final exercisePrescriptionId =
            exercise['exercise_prescription_id'] as int;
        Map? serverExercise;
        for (final candidate in serverExercises.cast<Map>()) {
          if (candidate['exercise_prescription_id'] == exercisePrescriptionId) {
            serverExercise = candidate;
            break;
          }
        }
        data['exercise_prescription_id'] = exercisePrescriptionId;
        if (serverExercise != null) {
          data['exercise_performance_id'] =
              serverExercise['exercise_performance_id'];
          for (final serverSet
              in (serverExercise['sets'] as List? ?? const []).cast<Map>()) {
            if (serverSet['prescribed_set_id'] == entry.key) {
              data['set_performance_id'] = serverSet['set_performance_id'];
              break;
            }
          }
        }
        await db
            .into(db.pendingOps)
            .insert(
              PendingOpsCompanion.insert(
                opId: AgonezIds.operation(),
                workoutId: workout.id,
                epoch: workout.leaseEpoch,
                seq: nextSeq++,
                type: 'upsert_set',
                payloadJson: jsonEncode(data),
                at: DateTime.now().toUtc().toIso8601String(),
              ),
            );
      }
      await (db.delete(db.pendingOps)..where(
            (t) =>
                t.workoutId.equals(workout.id) &
                t.state.equals('rejected') &
                t.errorCode.equals('exercise_performance_not_found'),
          ))
          .go();
      await (db.update(
        db.localWorkouts,
      )..where((t) => t.id.equals(workout.id))).write(
        LocalWorkoutsCompanion(
          nextSeq: Value(nextSeq),
          status: Value(
            workout.finalizeJson == null ? 'active' : 'pending_finalize',
          ),
        ),
      );
    });
  }
}

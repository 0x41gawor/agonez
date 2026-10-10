import 'package:agonez/data/database.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('operation sequence allocation is durable and contiguous', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await db
        .into(db.localWorkouts)
        .insert(
          LocalWorkoutsCompanion.insert(
            id: 'w',
            sessionId: 1,
            name: 'Push',
            prescriptionJson: '{}',
            startedAt: '2026-10-10T10:00:00Z',
          ),
        );
    expect(
      await db.enqueue('w', 'o1', 'set_cursor', const {'set_ordinal': 1}),
      1,
    );
    expect(
      await db.enqueue('w', 'o2', 'set_cursor', const {'set_ordinal': 2}),
      2,
    );
    expect((await db.pending('w')).map((e) => e.seq), [1, 2]);
    expect(
      (await (db.select(
        db.localWorkouts,
      )..where((t) => t.id.equals('w'))).getSingle()).nextSeq,
      3,
    );

    await (db.update(db.pendingOps)..where((t) => t.opId.equals('o1'))).write(
      const PendingOpsCompanion(state: Value('conflict')),
    );
    expect(await db.unresolvedCount('w'), 1);
    expect((await db.pending('w')).map((e) => e.opId), ['o2']);
  });
}

import 'package:agonez/src/api/atlas_models.dart';
import 'package:agonez/src/api/context_models.dart';
import 'package:agonez/src/api/operation_models.dart';
import 'package:agonez/src/api/prescription_models.dart';
import 'package:agonez/src/api/wire_enums.dart';
import 'package:agonez/src/api/workout_models.dart';

const fixtureExercise = ExerciseIdentity(
  id: 18,
  slug: 'barbell-squat',
  name: 'Barbell squat',
);

const fixtureAtlasPeek = AtlasPeek(
  exercise: fixtureExercise,
  tags: <String>['legs'],
  techniqueTldr: TechniqueTldr(
    setup: 'Brace before descending.',
    execution: null,
    focus: null,
    stopWhen: null,
  ),
  musclesTop: <AtlasMuscle>[],
  bodyMap: BodyMap(
    asset: 'anatomy.svg',
    assetVersion: '1',
    regions: <BodyMapRegion>[],
  ),
  contentLocale: 'en',
  atlasVersion: '1',
);

const fixtureSet = PrescriptionSet(
  setPrescriptionId: 477,
  ordinal: 0,
  role: 'working',
  prescribedLoadKg: 80,
  repMin: 6,
  repMax: 8,
  targetRir: 2,
  comment: null,
);

const fixturePrescriptionExercise = PrescriptionExercise(
  exercisePrescriptionId: 222,
  ordinal: 0,
  exerciseTrackId: 10,
  slot: PrescriptionSlot(goal: 'legs', role: 'primary'),
  exercise: fixtureExercise,
  variantLabel: null,
  planComment: null,
  prescriptionComment: null,
  loadStepKg: 2.5,
  defaultRestS: 180,
  sets: <PrescriptionSet>[fixtureSet],
  alternatives: <PrescriptionAlternative>[],
  history: ExerciseHistory(previousExposure: null),
  atlasPeek: fixtureAtlasPeek,
);

const fixturePrescription = WorkoutPrescription(
  sessionId: 28,
  prescriptionId: 901,
  prescriptionVersion: 'prescription-v1',
  workoutUnitName: 'Legs',
  workoutTrackId: 12,
  microcycle: PrescriptionMicrocycle(
    ordinal: 2,
    classification: PrescriptionMicrocycleClassification.normal,
  ),
  planComment: null,
  prescriptionComment: null,
  exercises: <PrescriptionExercise>[fixturePrescriptionExercise],
);

WorkoutSnapshot fixtureSnapshot({
  required String workoutId,
  required DateTime startedAt,
  int appliedSeq = 0,
  int revision = 1,
  WorkoutStatus status = WorkoutStatus.inProgress,
  DateTime? finishedAt,
  Lease lease = const Lease(
    deviceId: 'test-device',
    epoch: 1,
    isThisDevice: true,
  ),
}) => WorkoutSnapshot(
  workoutId: workoutId,
  sessionId: fixturePrescription.sessionId,
  status: status,
  startedAt: startedAt,
  finishedAt: finishedAt,
  lease: lease,
  appliedSeq: appliedSeq,
  revision: revision,
  positionHint: null,
  prescription: fixturePrescription,
  performance: const PerformanceTree(comment: null, exercises: []),
);

OperationBatchResponse fixtureOperationResponse(OperationBatch batch) =>
    OperationBatchResponse(
      appliedSeq: batch.ops.last.seq,
      revision: 2,
      results: batch.ops
          .map(
            (operation) => OperationResult(
              seq: operation.seq,
              opId: operation.opId,
              status: OperationResultStatus.applied,
            ),
          )
          .toList(growable: false),
      serverTime: DateTime.utc(2026, 10, 10, 17, 5),
    );

const emptyCompletionSummary = CompletionSummary(
  prescribedSets: 1,
  performedSets: 1,
  skippedSets: 0,
  notPerformedSets: 0,
  additionalSets: 0,
  substitutions: 0,
  skippedExercises: 0,
  addedExercises: 0,
  reordered: false,
);

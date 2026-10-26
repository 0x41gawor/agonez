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

const fixtureSecondExercise = PrescriptionExercise(
  exercisePrescriptionId: 223,
  ordinal: 1,
  exerciseTrackId: 11,
  slot: PrescriptionSlot(goal: 'legs', role: 'isolation'),
  exercise: ExerciseIdentity(id: 19, slug: 'leg-curl', name: 'Leg curl'),
  variantLabel: null,
  planComment: null,
  prescriptionComment: null,
  loadStepKg: 2.5,
  defaultRestS: 90,
  sets: <PrescriptionSet>[
    PrescriptionSet(
      setPrescriptionId: 478,
      ordinal: 0,
      role: 'working',
      prescribedLoadKg: 40,
      repMin: 10,
      repMax: 12,
      targetRir: 2,
      comment: null,
    ),
  ],
  alternatives: <PrescriptionAlternative>[],
  history: ExerciseHistory(previousExposure: null),
  atlasPeek: fixtureAtlasPeek,
);

/// [fixturePrescription] followed by [fixtureSecondExercise].
const twoExercisePrescription = WorkoutPrescription(
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
  exercises: <PrescriptionExercise>[
    fixturePrescriptionExercise,
    fixtureSecondExercise,
  ],
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

/// [fixturePrescription] with its one exercise given [sets].
WorkoutPrescription prescriptionWith(
  List<PrescriptionSet> sets, {
  String version = 'prescription-v1',
  int? exercisePrescriptionId,
  ExerciseIdentity? exercise,
  ExerciseHistory? history,
}) {
  final base = fixturePrescriptionExercise;
  return WorkoutPrescription(
    sessionId: fixturePrescription.sessionId,
    prescriptionId: fixturePrescription.prescriptionId,
    prescriptionVersion: version,
    workoutUnitName: fixturePrescription.workoutUnitName,
    workoutTrackId: fixturePrescription.workoutTrackId,
    microcycle: fixturePrescription.microcycle,
    planComment: null,
    prescriptionComment: null,
    exercises: [
      PrescriptionExercise(
        exercisePrescriptionId:
            exercisePrescriptionId ?? base.exercisePrescriptionId,
        ordinal: base.ordinal,
        exerciseTrackId: base.exerciseTrackId,
        slot: base.slot,
        exercise: exercise ?? base.exercise,
        variantLabel: null,
        planComment: null,
        prescriptionComment: null,
        loadStepKg: base.loadStepKg,
        defaultRestS: base.defaultRestS,
        sets: sets,
        alternatives: const [],
        history: history ?? base.history,
        atlasPeek: base.atlasPeek,
      ),
    ],
  );
}

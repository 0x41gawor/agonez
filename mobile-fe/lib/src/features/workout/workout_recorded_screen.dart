import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/json_support.dart';
import '../../api/prescription_models.dart';
import '../../app/app_providers.dart';
import '../../design/design.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../storage/app_database.dart';

class WorkoutRecordedScreen extends ConsumerWidget {
  const WorkoutRecordedScreen({required this.workoutId, super.key});

  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final workout = ref.watch(workoutProvider(workoutId));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        body: SafeArea(
          child: workout.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => _RecordedError(onDone: () => context.go('/home')),
            data: (value) {
              if (value == null) {
                return _RecordedError(onDone: () => context.go('/home'));
              }
              final sets =
                  ref.watch(workoutSetsProvider(workoutId)).value ??
                  const <LocalSet>[];
              final exercises =
                  ref.watch(workoutExercisesProvider(workoutId)).value ??
                  const <LocalExercise>[];
              final performed = sets
                  .where((set) => set.status == 'performed')
                  .length;
              final skipped = sets
                  .where((set) => set.status == 'skipped')
                  .length;
              final prescribed = _prescribedSetCount(value.prescriptionJson);
              final notDone = (prescribed - performed - skipped).clamp(
                0,
                prescribed,
              );
              final structuralChanges = exercises
                  .where(
                    (exercise) =>
                        exercise.mode != 'as_prescribed' ||
                        exercise.exercisePrescriptionId == null,
                  )
                  .length;
              final finalized = value.lifecycle == 'completed';
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 44, 20, 24),
                children: [
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color:
                            (finalized
                                    ? context.agonezColors.success
                                    : context.agonezColors.caution)
                                .withValues(alpha: .14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        finalized
                            ? Icons.cloud_done_outlined
                            : Icons.cloud_upload_outlined,
                        size: 34,
                        color: finalized
                            ? context.agonezColors.success
                            : context.agonezColors.caution,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    strings.recordedTitle(value.workoutUnitName),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    finalized
                        ? strings.recordedSynced
                        : strings.recordedSavedLocally,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  AgonezPanel(
                    child: Row(
                      children: [
                        Expanded(
                          child: _RecordedMetric(
                            value: '$performed',
                            label: strings.recordedSetsDone,
                          ),
                        ),
                        Expanded(
                          child: _RecordedMetric(
                            value: '$notDone',
                            label: strings.recordedNotDone,
                          ),
                        ),
                        Expanded(
                          child: _RecordedMetric(
                            value: '$structuralChanges',
                            label: strings.recordedStructuralChanges,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AgonezPrimaryButton(
                    label: strings.commonDone,
                    onPressed: () => context.go('/home'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  int _prescribedSetCount(String json) {
    try {
      final prescription = WorkoutPrescription.fromJson(
        asJsonMap(jsonDecode(json), 'prescription'),
      );
      return prescription.exercises.fold(
        0,
        (sum, exercise) => sum + exercise.sets.length,
      );
    } on Object {
      return 0;
    }
  }
}

class _RecordedMetric extends StatelessWidget {
  const _RecordedMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 4),
      Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class _RecordedError extends StatelessWidget {
  const _RecordedError({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context).errorGenericBody,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: onDone,
            child: Text(AppLocalizations.of(context).navHome),
          ),
        ],
      ),
    ),
  );
}

import '../api/api_error.dart';
import '../l10n/generated/app_localizations.dart';

String userFacingError(Object error, AppLocalizations strings) {
  if (error is AgonezApiException) {
    if (error.isTransportFailure) return strings.errorNetworkUnavailable;
    return switch (error.error?.code) {
      'active_workout_exists' => strings.errorActiveWorkoutExists,
      'prescription_changed' => strings.errorPrescriptionChanged,
      'session_not_startable' => strings.errorSessionNotStartable,
      'prescription_missing' => strings.errorPrescriptionMissing,
      'off_schedule_not_supported' => strings.errorOffScheduleNotSupported,
      'seq_gap' => strings.errorSequenceGap,
      'seq_mismatch' => strings.errorSequenceMismatch,
      'superseded' => strings.errorSuperseded,
      'workout_finalized' => strings.errorWorkoutFinalized,
      'workout_not_found' => strings.errorWorkoutNotFound,
      'ops_pending' => strings.errorOpsPending,
      'incomplete_not_acknowledged' => strings.errorIncompleteNotAcknowledged,
      'substitution_after_sets' => strings.errorSubstitutionAfterSets,
      'conflict' => strings.errorConflict,
      'rejected_operation' => strings.errorRejectedOperation,
      _ => strings.errorGenericBody,
    };
  }
  if (error is FormatException) return strings.errorInvalidResponse;
  return strings.errorGenericBody;
}

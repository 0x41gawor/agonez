// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Agonez';

  @override
  String get commonBack => 'Back';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonDone => 'Done';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonNotAvailableYet => 'Not available yet';

  @override
  String get navHome => 'Home';

  @override
  String get navWorkout => 'Workout';

  @override
  String get navAtlas => 'Atlas';

  @override
  String get navYou => 'You';

  @override
  String get navWorkoutActiveA11y => 'Workout, active';

  @override
  String get homeToday => 'Today';

  @override
  String get homeRestDay => 'Rest day';

  @override
  String get homePrescriptionReady => 'Prescription ready';

  @override
  String get homePrescriptionNotReady => 'Prescription not ready';

  @override
  String get homePrescriptionNotReadyExplanation =>
      'Post-Workout-Analysis has not produced this session\'s loads yet.';

  @override
  String get homePrescriptionChanged => 'Prescription changed';

  @override
  String homePrescriptionChangedDetail(
    String exercise,
    int setNumber,
    String before,
    String after,
  ) {
    return '$exercise, set $setNumber · $before → $after kg';
  }

  @override
  String get homeExercisesLabel => 'exercises';

  @override
  String get homeSetsLabel => 'sets';

  @override
  String get homeMinutesLabel => 'min';

  @override
  String get homeStartWorkout => 'Start workout';

  @override
  String get homeStartWithPlanTargets => 'Start with plan targets';

  @override
  String get homeOtherWorkoutUnit => 'Train another workout-unit…';

  @override
  String homeMicrocycle(int current, int total) {
    return 'Microcycle $current / $total';
  }

  @override
  String get homeRecent => 'Recent';

  @override
  String get homeDesktopHint =>
      'Trends and Post-Workout-Analysis live on desktop.';

  @override
  String get homeResumeTitle => 'Workout in progress';

  @override
  String get homeResumeWorkout => 'Resume workout';

  @override
  String homeResumeStartedAt(String time) {
    return 'Started $time';
  }

  @override
  String get homeResumeExercise => 'Exercise';

  @override
  String get homeResumeSet => 'Set';

  @override
  String get homeResumeStatus => 'Status';

  @override
  String get homeResumeExerciseComplete => 'Done';

  @override
  String homeResumeSetsTotal(int done, int total) {
    return '$done / $total sets total';
  }

  @override
  String get homeSingleActiveInfo =>
      'Only one workout can be active. Finish it from inside the workout before starting another.';

  @override
  String get homeNoRunTitle => 'Nothing to execute yet';

  @override
  String get homeNoRunExplanation =>
      'Mobile follows an active plan run. Select one to continue.';

  @override
  String get homeNoRunChoose => 'Choose plan run';

  @override
  String get homeRestDayExplanation => 'No workout-unit is scheduled today.';

  @override
  String homeNextWorkout(String date) {
    return 'Next · $date';
  }

  @override
  String get homeActiveElsewhereTitle => 'A workout is already in progress';

  @override
  String homeActiveElsewhereBody(String workout, String time) {
    return '$workout, started $time on another device.';
  }

  @override
  String get homeResumeHere => 'Resume it here';

  @override
  String get homeStartFailedTitle => 'Couldn\'t start the workout';

  @override
  String get homeStartFailedBody =>
      'Your phone has the prescription. You can keep training and it will sync later.';

  @override
  String homeCompletedAt(String time) {
    return 'Completed $time';
  }

  @override
  String get runSheetTitle => 'Plan run';

  @override
  String get runContext => 'Context';

  @override
  String get runPlan => 'Plan';

  @override
  String get runMicrocyclePosition => 'Microcycle';

  @override
  String get runLockedDuringWorkout =>
      'Switching is locked while a workout is active.';

  @override
  String get runRememberedHint =>
      'Selection is remembered. You won\'t be asked again during normal use.';

  @override
  String get runActive => 'Active';

  @override
  String get runCompleted => 'Completed';

  @override
  String get pickerTitle => 'Choose workout-unit';

  @override
  String get pickerAdvanced => 'Advanced';

  @override
  String get pickerToday => 'Today';

  @override
  String pickerScheduledOn(String date) {
    return 'Scheduled $date';
  }

  @override
  String pickerDoneOn(String date) {
    return 'Done · $date';
  }

  @override
  String get pickerFallback => 'Fallback · future';

  @override
  String get pickerTodayExplanation => 'Today\'s scheduled workout.';

  @override
  String pickerNotTodayExplanation(String workout) {
    return '$workout isn\'t scheduled for today. Training it now changes the planned order of exposures.';
  }

  @override
  String pickerStartInstead(String workout) {
    return 'Start $workout instead';
  }

  @override
  String get pickerFallbackFuture =>
      'Fallback workout-units are a future capability of the plan.';

  @override
  String get pickerOffScheduleUnsupported =>
      'This workout-unit cannot be started off schedule yet.';

  @override
  String get workoutMinimiseA11y => 'Minimise workout; keeps it running';

  @override
  String get workoutOutline => 'Outline';

  @override
  String get workoutActions => 'Workout actions';

  @override
  String workoutElapsed(String duration) {
    return 'Elapsed $duration';
  }

  @override
  String workoutExerciseCounter(int current, int total) {
    return 'EXERCISE $current / $total';
  }

  @override
  String workoutSetCounter(int done, int total) {
    return '$done / $total SETS';
  }

  @override
  String get workoutRolePrimaryProgressive => 'Primary progressive';

  @override
  String get workoutRoleSecondaryCompound => 'Secondary compound';

  @override
  String get workoutRoleIsolation => 'Isolation';

  @override
  String workoutPrescribedSet(int setNumber) {
    return 'Prescribed · set $setNumber';
  }

  @override
  String workoutLastExposure(String microcycle) {
    return 'Last · $microcycle';
  }

  @override
  String get workoutPlanNote => 'Plan note';

  @override
  String workoutSetLabel(int setNumber) {
    return 'Set $setNumber';
  }

  @override
  String get workoutExtraLabel => 'Extra';

  @override
  String get workoutSkippedLabel => 'Skipped';

  @override
  String get workoutUnplanned => 'Unplanned exercise';

  @override
  String get workoutOrderChanged => 'order changed';

  @override
  String get workoutPerformed => 'Performed';

  @override
  String get workoutPrescribed => 'Prescribed';

  @override
  String workoutPrescriptionWasFor(String exercise) {
    return 'Prescription was for $exercise';
  }

  @override
  String get workoutNoPrescriptionUnplanned => 'No prescription · unplanned';

  @override
  String get workoutExtraNotPrescribed => 'Extra set · not prescribed';

  @override
  String get workoutRecordWhatYouDo => 'Record what you actually do.';

  @override
  String workoutTargetBandApplies(String reps, int rir) {
    return 'Target band still applies: $reps reps @ RIR $rir';
  }

  @override
  String get workoutExerciseComplete => 'Exercise complete';

  @override
  String get workoutUpNext => 'Up next';

  @override
  String workoutStartNext(String exercise) {
    return 'Start $exercise';
  }

  @override
  String get workoutFinishWorkout => 'Finish workout';

  @override
  String workoutOutlineTitle(String workout) {
    return '$workout outline';
  }

  @override
  String get workoutDoNext => 'Do next';

  @override
  String workoutPlannedPosition(int position) {
    return 'planned #$position';
  }

  @override
  String get setLoad => 'Load';

  @override
  String get setReps => 'Reps';

  @override
  String get setRir => 'RIR';

  @override
  String setTarget(String target) {
    return 'target $target';
  }

  @override
  String get setTapToType => 'Tap to type';

  @override
  String get setOther => 'other';

  @override
  String setConfirm(int setNumber) {
    return 'Confirm set $setNumber';
  }

  @override
  String setConfirmSummary(String load, int reps, String rir, String rest) {
    return '$load × $reps @ $rir · then rest $rest';
  }

  @override
  String get setSelectRepsRir => 'Select reps and RIR';

  @override
  String get setEnterLoad => 'Enter load';

  @override
  String get setKeptFromLast => 'kept from your last set';

  @override
  String get setReset => 'Reset';

  @override
  String setRecordedSnackbar(int setNumber) {
    return 'Set $setNumber recorded';
  }

  @override
  String get setUndo => 'Undo';

  @override
  String setEditTitle(int setNumber) {
    return 'Edit set $setNumber';
  }

  @override
  String get setEditingNormal => 'Recorded · editing is normal';

  @override
  String setSave(int setNumber) {
    return 'Save set $setNumber';
  }

  @override
  String get setMarkSkipped => 'Mark as skipped instead…';

  @override
  String setMinusLoadA11y(String step) {
    return 'Minus $step kilograms';
  }

  @override
  String setPlusLoadA11y(String step) {
    return 'Plus $step kilograms';
  }

  @override
  String setLoadValueA11y(String load) {
    return 'Load $load kilograms, double-tap to type';
  }

  @override
  String setRepA11y(int reps, String selection, String targetState) {
    return '$reps repetitions, $selection, $targetState';
  }

  @override
  String get setSelectedA11y => 'selected';

  @override
  String get setNotSelectedA11y => 'not selected';

  @override
  String get setWithinTargetA11y => 'within target';

  @override
  String get setOutsideTargetA11y => 'outside target';

  @override
  String divergenceLoad(String delta) {
    return '$delta kg vs prescribed';
  }

  @override
  String divergenceRepsBelow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count below target',
      one: '1 below target',
    );
    return '$_temp0';
  }

  @override
  String divergenceRepsAbove(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count above target',
      one: '1 above target',
    );
    return '$_temp0';
  }

  @override
  String get divergenceRirDeeper => 'deeper than target';

  @override
  String get divergenceRirLighter => 'further from failure';

  @override
  String get divergenceDiffersA11y => 'differs from prescription';

  @override
  String noteSetTitle(int setNumber) {
    return 'Set $setNumber note';
  }

  @override
  String get noteExerciseTitle => 'Exercise note';

  @override
  String get noteExposureOnlyHint =>
      'This exposure only. It does not change the plan\'s instructions.';

  @override
  String get noteOptionalFieldData => 'Optional · field data';

  @override
  String get noteSetPlaceholder => 'e.g. Grip slipped on rep 5';

  @override
  String get noteExercisePlaceholder => 'e.g. Using both cables works better';

  @override
  String get noteSave => 'Save note';

  @override
  String get noteSuggestionGripSlipped => 'Grip slipped';

  @override
  String get noteSuggestionElbowsFlared => 'Elbows flared';

  @override
  String get noteSuggestionReducedLoad => 'Reduced load after previous set';

  @override
  String get noteSuggestionPain => 'Pain / discomfort';

  @override
  String get noteSuggestionEquipment => 'Different equipment';

  @override
  String get noteSuggestionSpotter => 'Spotter helped';

  @override
  String get moreDataTitle => 'More data';

  @override
  String get moreDataHeartRate => 'Heart rate after set';

  @override
  String get moreDataFutureSensor =>
      'Future: filled automatically from a paired sensor. Never required.';

  @override
  String get deviationSectionTitle =>
      'Change structure · recorded as deviation';

  @override
  String deviationFrictionA11y(int level) {
    return 'Friction $level of 3';
  }

  @override
  String deviationHoldDuration(String seconds) {
    return 'hold $seconds s';
  }

  @override
  String deviationSkipSet(int setNumber) {
    return 'Skip set $setNumber';
  }

  @override
  String get deviationSkipSetExplanation =>
      'A skipped set is stored without values. Fewer sets than prescribed makes this exposure less comparable.';

  @override
  String get deviationHoldSkipSet => 'Hold to skip set';

  @override
  String get deviationAddSet => 'Add extra set';

  @override
  String get deviationAddSetExplanation =>
      'The extra set is recorded separately from prescribed sets.';

  @override
  String get deviationHoldAddSet => 'Hold to add set';

  @override
  String deviationSkipExercise(String exercise) {
    return 'Skip $exercise';
  }

  @override
  String get deviationSkipExerciseExplanation =>
      'Skipping an exercise reduces the repeatability and comparability of the training plan.';

  @override
  String get deviationHoldSkipExercise => 'Hold to skip';

  @override
  String get deviationSubstitute => 'Substitute exercise…';

  @override
  String get deviationSubstituteExplanation =>
      'Performing a different exercise breaks the trace for this slot. The prescription is kept and the substitution is recorded.';

  @override
  String get deviationHoldSubstitute => 'Hold to substitute';

  @override
  String get deviationSubstitutionLocked =>
      'Not available once a set is recorded. Skip the remaining sets and add an unplanned exercise instead.';

  @override
  String get deviationReorder => 'Change order…';

  @override
  String deviationReorderExplanation(int position) {
    return 'The planned order puts it at #$position. Changing order affects fatigue and comparability.';
  }

  @override
  String get deviationHoldReorder => 'Move it next';

  @override
  String get deviationAddUnplanned => 'Add unplanned exercise…';

  @override
  String deviationAddUnplannedExplanation(String exercise, String workout) {
    return '$exercise isn\'t part of $workout. Extra work changes this session\'s volume.';
  }

  @override
  String get deviationHoldAddUnplanned => 'Hold to add';

  @override
  String get deviationPlanAlternatives => 'Plan alternatives for this slot';

  @override
  String get deviationSearchAtlas => 'Search Atlas';

  @override
  String get deviationSelectExercise => 'Select an exercise';

  @override
  String deviationContinueWith(String exercise) {
    return 'Continue with $exercise';
  }

  @override
  String get finishTitle => 'Finish workout';

  @override
  String finishIncompleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises are incomplete',
      one: '1 exercise is incomplete',
    );
    return '$_temp0';
  }

  @override
  String finishIncompleteExplanation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '1 set',
    );
    return 'Finishing now will record $_temp0 as not completed.';
  }

  @override
  String get finishContinueWorkout => 'Continue workout';

  @override
  String get finishHoldAnyway => 'Finish anyway';

  @override
  String get finishSetsRecorded => 'Sets recorded';

  @override
  String get finishDuration => 'Duration';

  @override
  String get finishOnlineHint => 'The workout will be finalised on the server.';

  @override
  String get finishOfflineHint =>
      'You are offline. It is saved on this phone and will be finalised after reconnecting.';

  @override
  String get timerRest => 'Rest';

  @override
  String timerRestComplete(String elapsed) {
    return 'Rest complete · over by +$elapsed';
  }

  @override
  String get timerMinus30 => 'Rest minus 30 seconds';

  @override
  String get timerPlus30 => 'Rest plus 30 seconds';

  @override
  String get timerEnd => 'End rest';

  @override
  String timerUpNextSet(int setNumber) {
    return 'Up next · Set $setNumber';
  }

  @override
  String get timerNotificationTitle => 'Rest complete';

  @override
  String timerNotificationBody(
    String exercise,
    int setNumber,
    String prescription,
  ) {
    return '$exercise · set $setNumber · $prescription';
  }

  @override
  String get syncSaved => 'Saved';

  @override
  String get syncSaving => 'Saving…';

  @override
  String syncOfflineCount(int count) {
    return 'Offline · $count';
  }

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get syncConflict => 'Conflict';

  @override
  String get syncSuperseded => 'Continued on another device';

  @override
  String get syncSupersededExplanation =>
      'This workout is view-only until you explicitly resume it here.';

  @override
  String get syncResumeHere => 'Resume here';

  @override
  String get syncSheetTitle => 'Sync';

  @override
  String get syncEverythingSaved => 'Everything is saved';

  @override
  String get syncSavingTitle => 'Saving…';

  @override
  String get syncOfflineTitle => 'Offline — recording continues';

  @override
  String get syncFailedTitle => 'Sync failed';

  @override
  String get syncConflictTitle => 'Changed on another device';

  @override
  String get syncLocalFirstExplanation =>
      'Every change is stored on this phone first and sent to the server in order.';

  @override
  String get syncWaiting => 'Waiting to sync';

  @override
  String get syncLastAck => 'Last server acknowledgement';

  @override
  String get syncRetryNow => 'Retry now';

  @override
  String get syncThisPhone => 'This phone';

  @override
  String get syncServer => 'Server';

  @override
  String get syncKeepPhone => 'Keep this phone\'s value';

  @override
  String get syncUseServer => 'Use server value';

  @override
  String get syncConflictExplanation =>
      'Choose which recorded value should be kept. Other workout data remains available.';

  @override
  String recordedTitle(String workout) {
    return '$workout recorded';
  }

  @override
  String get recordedSynced =>
      'Synced. Ready for Post-Workout-Analysis on desktop.';

  @override
  String get recordedSavedLocally =>
      'Saved on this phone. It will be finalised automatically when you\'re back online.';

  @override
  String get recordedSetsDone => 'sets done';

  @override
  String get recordedNotDone => 'not done';

  @override
  String get recordedStructuralChanges => 'structural changes';

  @override
  String get recordedTagSubstituted => 'substituted';

  @override
  String get recordedTagUnplanned => 'unplanned';

  @override
  String get recordedTagSkipped => 'skipped';

  @override
  String get recordedTagIncomplete => 'incomplete';

  @override
  String get recordedTagReordered => 'reordered';

  @override
  String get recordedTagNote => 'note';

  @override
  String get atlasTitle => 'Atlas';

  @override
  String get atlasSearchPlaceholder => 'Search exercises and muscles';

  @override
  String get atlasOpenArticles => 'Open articles';

  @override
  String get atlasExercises => 'Exercises';

  @override
  String get atlasMuscles => 'Muscles';

  @override
  String get atlasQuickView => 'Atlas · quick view';

  @override
  String get atlasOpenFull => 'Open full Atlas article';

  @override
  String get atlasPlanNoteThisWorkout => 'Plan note · this workout';

  @override
  String get atlasInTodayWorkout => 'In today\'s workout';

  @override
  String get atlasSectionTechnique => 'Technique';

  @override
  String get atlasSectionAnatomy => 'Anatomy';

  @override
  String get atlasSectionMuscles => 'Muscles';

  @override
  String get atlasSectionData => 'Data';

  @override
  String get atlasSectionVideo => 'Video';

  @override
  String get atlasTechniqueSetup => 'Setup';

  @override
  String get atlasTechniqueExecution => 'Execution';

  @override
  String get atlasTechniqueFocus => 'Focus';

  @override
  String get atlasTechniqueStopWhen => 'Stop when';

  @override
  String get atlasEtu => 'ETU';

  @override
  String get atlasRecovery => 'Recovery';

  @override
  String get atlasMuscleExposure => 'Muscle ETU exposure';

  @override
  String get atlasClassification => 'Classification';

  @override
  String get atlasRepRanges => 'Recommended rep ranges';

  @override
  String get atlasVideos => 'Demonstration videos';

  @override
  String get atlasLoadCapacity => 'Load capacity';

  @override
  String get atlasTotalEtu => 'Total ETU';

  @override
  String get atlasPeakJoint => 'Peak joint';

  @override
  String get atlasOfflineUnavailable =>
      'This article is available when you\'re online. Quick View remains available from the workout.';

  @override
  String get atlasOpenMuscleArticle => 'Open muscle article';

  @override
  String get workspaceTitle => 'Workspaces';

  @override
  String get workspacePinnedHint =>
      'The active workout is pinned. It ends only with Finish workout.';

  @override
  String get workspaceActive => 'Active';

  @override
  String get workspaceCannotClose => 'Can\'t be closed here';

  @override
  String workspaceCloseA11y(String name) {
    return 'Close $name';
  }

  @override
  String get workspaceNewTab => 'New Atlas tab';

  @override
  String workspaceCounterA11y(int count) {
    return 'Open workspaces: $count';
  }

  @override
  String get workspaceLimitReached =>
      'The oldest inactive Atlas workspace was closed.';

  @override
  String get youTitle => 'You';

  @override
  String get youActivePlanRun => 'Active plan run';

  @override
  String get youWorkoutSettings => 'Workout';

  @override
  String get youDefaultRestCompounds => 'Default rest · compounds';

  @override
  String get youDefaultRestIsolation => 'Default rest · isolation';

  @override
  String get youRestNotification => 'Rest-end notification';

  @override
  String get youHaptics => 'Haptics';

  @override
  String get youUnits => 'Units';

  @override
  String get youAppSettings => 'App';

  @override
  String get youTheme => 'Theme';

  @override
  String get youThemeDark => 'Dark';

  @override
  String get youLanguage => 'Language';

  @override
  String get youSyncStatus => 'Sync';

  @override
  String get youSyncUpToDate => 'up to date';

  @override
  String get youSound => 'Rest timer sound';

  @override
  String get errorGenericTitle => 'Something went wrong';

  @override
  String get errorGenericBody => 'Your local workout data is safe. Try again.';

  @override
  String get errorActiveWorkoutExists =>
      'Another workout is already active. Resume it or resolve the local workout before starting a new one.';

  @override
  String get errorPrescriptionChanged =>
      'The prescription changed before this workout reached the server. Review the new targets; your local entries are still safe.';

  @override
  String get errorSessionNotStartable =>
      'This workout-unit cannot be started in its current state.';

  @override
  String get errorPrescriptionMissing =>
      'No valid prescription is available for this workout-unit.';

  @override
  String get errorOffScheduleNotSupported =>
      'Off-schedule workout execution is not available yet.';

  @override
  String get errorSequenceGap =>
      'Some earlier changes have not reached the server yet. Agonez is reconciling the queue.';

  @override
  String get errorSequenceMismatch =>
      'The local and server workout histories disagree. Sending has stopped to protect your data.';

  @override
  String get errorSuperseded => 'This workout was continued on another device.';

  @override
  String get errorWorkoutFinalized =>
      'This workout has already been finalised.';

  @override
  String get errorWorkoutNotFound =>
      'The workout could not be found on the server. Local data has been kept.';

  @override
  String get errorOpsPending =>
      'Some workout changes still need to sync before finalisation.';

  @override
  String get errorIncompleteNotAcknowledged =>
      'Confirm that you want to finish with incomplete work.';

  @override
  String get errorSubstitutionAfterSets =>
      'An exercise cannot be substituted after its sets have been recorded.';

  @override
  String get errorConflict =>
      'This value changed elsewhere. Choose the phone or server value.';

  @override
  String get errorRejectedOperation =>
      'The server could not apply this change. Your local entry has been kept for review.';

  @override
  String get errorNetworkUnavailable =>
      'The server cannot be reached. Recording continues offline.';

  @override
  String get errorInvalidResponse =>
      'The server returned an unexpected response. Local data has been kept.';

  @override
  String get errorApiBaseUrlMissing =>
      'API_BASE_URL is not configured for this development build.';
}

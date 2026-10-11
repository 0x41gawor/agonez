import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Agonez'**
  String get appName;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonNotAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'Not available yet'**
  String get commonNotAvailableYet;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navWorkout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get navWorkout;

  /// No description provided for @navAtlas.
  ///
  /// In en, this message translates to:
  /// **'Atlas'**
  String get navAtlas;

  /// No description provided for @navYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get navYou;

  /// No description provided for @navWorkoutActiveA11y.
  ///
  /// In en, this message translates to:
  /// **'Workout, active'**
  String get navWorkoutActiveA11y;

  /// No description provided for @homeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeToday;

  /// No description provided for @homeRestDay.
  ///
  /// In en, this message translates to:
  /// **'Rest day'**
  String get homeRestDay;

  /// No description provided for @homePrescriptionReady.
  ///
  /// In en, this message translates to:
  /// **'Prescription ready'**
  String get homePrescriptionReady;

  /// No description provided for @homePrescriptionNotReady.
  ///
  /// In en, this message translates to:
  /// **'Prescription not ready'**
  String get homePrescriptionNotReady;

  /// No description provided for @homePrescriptionNotReadyExplanation.
  ///
  /// In en, this message translates to:
  /// **'Post-Workout-Analysis has not produced this session\'s loads yet.'**
  String get homePrescriptionNotReadyExplanation;

  /// No description provided for @homePrescriptionChanged.
  ///
  /// In en, this message translates to:
  /// **'Prescription changed'**
  String get homePrescriptionChanged;

  /// No description provided for @homePrescriptionChangedDetail.
  ///
  /// In en, this message translates to:
  /// **'{exercise}, set {setNumber} · {before} → {after} kg'**
  String homePrescriptionChangedDetail(
    String exercise,
    int setNumber,
    String before,
    String after,
  );

  /// No description provided for @homeExercisesLabel.
  ///
  /// In en, this message translates to:
  /// **'exercises'**
  String get homeExercisesLabel;

  /// No description provided for @homeSetsLabel.
  ///
  /// In en, this message translates to:
  /// **'sets'**
  String get homeSetsLabel;

  /// No description provided for @homeMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get homeMinutesLabel;

  /// No description provided for @homeStartWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start workout'**
  String get homeStartWorkout;

  /// No description provided for @homeStartWithPlanTargets.
  ///
  /// In en, this message translates to:
  /// **'Start with plan targets'**
  String get homeStartWithPlanTargets;

  /// No description provided for @homeOtherWorkoutUnit.
  ///
  /// In en, this message translates to:
  /// **'Train another workout-unit…'**
  String get homeOtherWorkoutUnit;

  /// No description provided for @homeMicrocycle.
  ///
  /// In en, this message translates to:
  /// **'Microcycle {current} / {total}'**
  String homeMicrocycle(int current, int total);

  /// No description provided for @homeRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get homeRecent;

  /// No description provided for @homeDesktopHint.
  ///
  /// In en, this message translates to:
  /// **'Trends and Post-Workout-Analysis live on desktop.'**
  String get homeDesktopHint;

  /// No description provided for @homeResumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout in progress'**
  String get homeResumeTitle;

  /// No description provided for @homeResumeWorkout.
  ///
  /// In en, this message translates to:
  /// **'Resume workout'**
  String get homeResumeWorkout;

  /// No description provided for @homeResumeStartedAt.
  ///
  /// In en, this message translates to:
  /// **'Started {time}'**
  String homeResumeStartedAt(String time);

  /// No description provided for @homeResumeExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get homeResumeExercise;

  /// No description provided for @homeResumeSet.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get homeResumeSet;

  /// No description provided for @homeResumeStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get homeResumeStatus;

  /// No description provided for @homeResumeExerciseComplete.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get homeResumeExerciseComplete;

  /// No description provided for @homeResumeSetsTotal.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} sets total'**
  String homeResumeSetsTotal(int done, int total);

  /// No description provided for @homeSingleActiveInfo.
  ///
  /// In en, this message translates to:
  /// **'Only one workout can be active. Finish it from inside the workout before starting another.'**
  String get homeSingleActiveInfo;

  /// No description provided for @homeNoRunTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to execute yet'**
  String get homeNoRunTitle;

  /// No description provided for @homeNoRunExplanation.
  ///
  /// In en, this message translates to:
  /// **'Mobile follows an active plan run. Select one to continue.'**
  String get homeNoRunExplanation;

  /// No description provided for @homeNoRunChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose plan run'**
  String get homeNoRunChoose;

  /// No description provided for @homeRestDayExplanation.
  ///
  /// In en, this message translates to:
  /// **'No workout-unit is scheduled today.'**
  String get homeRestDayExplanation;

  /// No description provided for @homeNextWorkout.
  ///
  /// In en, this message translates to:
  /// **'Next · {date}'**
  String homeNextWorkout(String date);

  /// No description provided for @homeActiveElsewhereTitle.
  ///
  /// In en, this message translates to:
  /// **'A workout is already in progress'**
  String get homeActiveElsewhereTitle;

  /// No description provided for @homeActiveElsewhereBody.
  ///
  /// In en, this message translates to:
  /// **'{workout}, started {time} on another device.'**
  String homeActiveElsewhereBody(String workout, String time);

  /// No description provided for @homeResumeHere.
  ///
  /// In en, this message translates to:
  /// **'Resume it here'**
  String get homeResumeHere;

  /// No description provided for @homeStartFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the workout'**
  String get homeStartFailedTitle;

  /// No description provided for @homeStartFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Your phone has the prescription. You can keep training and it will sync later.'**
  String get homeStartFailedBody;

  /// No description provided for @homeCompletedAt.
  ///
  /// In en, this message translates to:
  /// **'Completed {time}'**
  String homeCompletedAt(String time);

  /// No description provided for @runSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan run'**
  String get runSheetTitle;

  /// No description provided for @runContext.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get runContext;

  /// No description provided for @runPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get runPlan;

  /// No description provided for @runMicrocyclePosition.
  ///
  /// In en, this message translates to:
  /// **'Microcycle'**
  String get runMicrocyclePosition;

  /// No description provided for @runLockedDuringWorkout.
  ///
  /// In en, this message translates to:
  /// **'Switching is locked while a workout is active.'**
  String get runLockedDuringWorkout;

  /// No description provided for @runRememberedHint.
  ///
  /// In en, this message translates to:
  /// **'Selection is remembered. You won\'t be asked again during normal use.'**
  String get runRememberedHint;

  /// No description provided for @runActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get runActive;

  /// No description provided for @runCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get runCompleted;

  /// No description provided for @pickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose workout-unit'**
  String get pickerTitle;

  /// No description provided for @pickerAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get pickerAdvanced;

  /// No description provided for @pickerToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get pickerToday;

  /// No description provided for @pickerScheduledOn.
  ///
  /// In en, this message translates to:
  /// **'Scheduled {date}'**
  String pickerScheduledOn(String date);

  /// No description provided for @pickerDoneOn.
  ///
  /// In en, this message translates to:
  /// **'Done · {date}'**
  String pickerDoneOn(String date);

  /// No description provided for @pickerFallback.
  ///
  /// In en, this message translates to:
  /// **'Fallback · future'**
  String get pickerFallback;

  /// No description provided for @pickerTodayExplanation.
  ///
  /// In en, this message translates to:
  /// **'Today\'s scheduled workout.'**
  String get pickerTodayExplanation;

  /// No description provided for @pickerNotTodayExplanation.
  ///
  /// In en, this message translates to:
  /// **'{workout} isn\'t scheduled for today. Training it now changes the planned order of exposures.'**
  String pickerNotTodayExplanation(String workout);

  /// No description provided for @pickerStartInstead.
  ///
  /// In en, this message translates to:
  /// **'Start {workout} instead'**
  String pickerStartInstead(String workout);

  /// No description provided for @pickerFallbackFuture.
  ///
  /// In en, this message translates to:
  /// **'Fallback workout-units are a future capability of the plan.'**
  String get pickerFallbackFuture;

  /// No description provided for @pickerOffScheduleUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This workout-unit cannot be started off schedule yet.'**
  String get pickerOffScheduleUnsupported;

  /// No description provided for @workoutMinimiseA11y.
  ///
  /// In en, this message translates to:
  /// **'Minimise workout; keeps it running'**
  String get workoutMinimiseA11y;

  /// No description provided for @workoutOutline.
  ///
  /// In en, this message translates to:
  /// **'Outline'**
  String get workoutOutline;

  /// No description provided for @workoutActions.
  ///
  /// In en, this message translates to:
  /// **'Workout actions'**
  String get workoutActions;

  /// No description provided for @workoutElapsed.
  ///
  /// In en, this message translates to:
  /// **'Elapsed {duration}'**
  String workoutElapsed(String duration);

  /// No description provided for @workoutExerciseCounter.
  ///
  /// In en, this message translates to:
  /// **'EXERCISE {current} / {total}'**
  String workoutExerciseCounter(int current, int total);

  /// No description provided for @workoutSetCounter.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} SETS'**
  String workoutSetCounter(int done, int total);

  /// No description provided for @workoutRolePrimaryProgressive.
  ///
  /// In en, this message translates to:
  /// **'Primary progressive'**
  String get workoutRolePrimaryProgressive;

  /// No description provided for @workoutRoleSecondaryCompound.
  ///
  /// In en, this message translates to:
  /// **'Secondary compound'**
  String get workoutRoleSecondaryCompound;

  /// No description provided for @workoutRoleIsolation.
  ///
  /// In en, this message translates to:
  /// **'Isolation'**
  String get workoutRoleIsolation;

  /// No description provided for @workoutPrescribedSet.
  ///
  /// In en, this message translates to:
  /// **'Prescribed · set {setNumber}'**
  String workoutPrescribedSet(int setNumber);

  /// No description provided for @workoutLastExposure.
  ///
  /// In en, this message translates to:
  /// **'Last · {microcycle}'**
  String workoutLastExposure(String microcycle);

  /// No description provided for @workoutPlanNote.
  ///
  /// In en, this message translates to:
  /// **'Plan note'**
  String get workoutPlanNote;

  /// No description provided for @workoutSetLabel.
  ///
  /// In en, this message translates to:
  /// **'Set {setNumber}'**
  String workoutSetLabel(int setNumber);

  /// No description provided for @workoutExtraLabel.
  ///
  /// In en, this message translates to:
  /// **'Extra'**
  String get workoutExtraLabel;

  /// No description provided for @workoutSkippedLabel.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get workoutSkippedLabel;

  /// No description provided for @workoutUnplanned.
  ///
  /// In en, this message translates to:
  /// **'Unplanned exercise'**
  String get workoutUnplanned;

  /// No description provided for @workoutOrderChanged.
  ///
  /// In en, this message translates to:
  /// **'order changed'**
  String get workoutOrderChanged;

  /// No description provided for @workoutPerformed.
  ///
  /// In en, this message translates to:
  /// **'Performed'**
  String get workoutPerformed;

  /// No description provided for @workoutPrescribed.
  ///
  /// In en, this message translates to:
  /// **'Prescribed'**
  String get workoutPrescribed;

  /// No description provided for @workoutPrescriptionWasFor.
  ///
  /// In en, this message translates to:
  /// **'Prescription was for {exercise}'**
  String workoutPrescriptionWasFor(String exercise);

  /// No description provided for @workoutNoPrescriptionUnplanned.
  ///
  /// In en, this message translates to:
  /// **'No prescription · unplanned'**
  String get workoutNoPrescriptionUnplanned;

  /// No description provided for @workoutExtraNotPrescribed.
  ///
  /// In en, this message translates to:
  /// **'Extra set · not prescribed'**
  String get workoutExtraNotPrescribed;

  /// No description provided for @workoutRecordWhatYouDo.
  ///
  /// In en, this message translates to:
  /// **'Record what you actually do.'**
  String get workoutRecordWhatYouDo;

  /// No description provided for @workoutTargetBandApplies.
  ///
  /// In en, this message translates to:
  /// **'Target band still applies: {reps} reps @ RIR {rir}'**
  String workoutTargetBandApplies(String reps, int rir);

  /// No description provided for @workoutExerciseComplete.
  ///
  /// In en, this message translates to:
  /// **'Exercise complete'**
  String get workoutExerciseComplete;

  /// No description provided for @workoutUpNext.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get workoutUpNext;

  /// No description provided for @workoutStartNext.
  ///
  /// In en, this message translates to:
  /// **'Start {exercise}'**
  String workoutStartNext(String exercise);

  /// No description provided for @workoutFinishWorkout.
  ///
  /// In en, this message translates to:
  /// **'Finish workout'**
  String get workoutFinishWorkout;

  /// No description provided for @workoutOutlineTitle.
  ///
  /// In en, this message translates to:
  /// **'{workout} outline'**
  String workoutOutlineTitle(String workout);

  /// No description provided for @workoutDoNext.
  ///
  /// In en, this message translates to:
  /// **'Do next'**
  String get workoutDoNext;

  /// No description provided for @workoutPlannedPosition.
  ///
  /// In en, this message translates to:
  /// **'planned #{position}'**
  String workoutPlannedPosition(int position);

  /// No description provided for @setLoad.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get setLoad;

  /// No description provided for @setReps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get setReps;

  /// No description provided for @setRir.
  ///
  /// In en, this message translates to:
  /// **'RIR'**
  String get setRir;

  /// No description provided for @setTarget.
  ///
  /// In en, this message translates to:
  /// **'target {target}'**
  String setTarget(String target);

  /// No description provided for @setTapToType.
  ///
  /// In en, this message translates to:
  /// **'Tap to type'**
  String get setTapToType;

  /// No description provided for @setOther.
  ///
  /// In en, this message translates to:
  /// **'other'**
  String get setOther;

  /// No description provided for @setConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm set {setNumber}'**
  String setConfirm(int setNumber);

  /// No description provided for @setConfirmSummary.
  ///
  /// In en, this message translates to:
  /// **'{load} × {reps} @ {rir} · then rest {rest}'**
  String setConfirmSummary(String load, int reps, String rir, String rest);

  /// No description provided for @setSelectRepsRir.
  ///
  /// In en, this message translates to:
  /// **'Select reps and RIR'**
  String get setSelectRepsRir;

  /// No description provided for @setEnterLoad.
  ///
  /// In en, this message translates to:
  /// **'Enter load'**
  String get setEnterLoad;

  /// No description provided for @setKeptFromLast.
  ///
  /// In en, this message translates to:
  /// **'kept from your last set'**
  String get setKeptFromLast;

  /// No description provided for @setReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get setReset;

  /// No description provided for @setRecordedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Set {setNumber} recorded'**
  String setRecordedSnackbar(int setNumber);

  /// No description provided for @setUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get setUndo;

  /// No description provided for @setEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit set {setNumber}'**
  String setEditTitle(int setNumber);

  /// No description provided for @setEditingNormal.
  ///
  /// In en, this message translates to:
  /// **'Recorded · editing is normal'**
  String get setEditingNormal;

  /// No description provided for @setSave.
  ///
  /// In en, this message translates to:
  /// **'Save set {setNumber}'**
  String setSave(int setNumber);

  /// No description provided for @setMarkSkipped.
  ///
  /// In en, this message translates to:
  /// **'Mark as skipped instead…'**
  String get setMarkSkipped;

  /// No description provided for @setMinusLoadA11y.
  ///
  /// In en, this message translates to:
  /// **'Minus {step} kilograms'**
  String setMinusLoadA11y(String step);

  /// No description provided for @setPlusLoadA11y.
  ///
  /// In en, this message translates to:
  /// **'Plus {step} kilograms'**
  String setPlusLoadA11y(String step);

  /// No description provided for @setLoadValueA11y.
  ///
  /// In en, this message translates to:
  /// **'Load {load} kilograms, double-tap to type'**
  String setLoadValueA11y(String load);

  /// No description provided for @setRepA11y.
  ///
  /// In en, this message translates to:
  /// **'{reps} repetitions, {selection}, {targetState}'**
  String setRepA11y(int reps, String selection, String targetState);

  /// No description provided for @setSelectedA11y.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get setSelectedA11y;

  /// No description provided for @setNotSelectedA11y.
  ///
  /// In en, this message translates to:
  /// **'not selected'**
  String get setNotSelectedA11y;

  /// No description provided for @setWithinTargetA11y.
  ///
  /// In en, this message translates to:
  /// **'within target'**
  String get setWithinTargetA11y;

  /// No description provided for @setOutsideTargetA11y.
  ///
  /// In en, this message translates to:
  /// **'outside target'**
  String get setOutsideTargetA11y;

  /// No description provided for @divergenceLoad.
  ///
  /// In en, this message translates to:
  /// **'{delta} kg vs prescribed'**
  String divergenceLoad(String delta);

  /// No description provided for @divergenceRepsBelow.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 below target} other{{count} below target}}'**
  String divergenceRepsBelow(int count);

  /// No description provided for @divergenceRepsAbove.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 above target} other{{count} above target}}'**
  String divergenceRepsAbove(int count);

  /// No description provided for @divergenceRirDeeper.
  ///
  /// In en, this message translates to:
  /// **'deeper than target'**
  String get divergenceRirDeeper;

  /// No description provided for @divergenceRirLighter.
  ///
  /// In en, this message translates to:
  /// **'further from failure'**
  String get divergenceRirLighter;

  /// No description provided for @divergenceDiffersA11y.
  ///
  /// In en, this message translates to:
  /// **'differs from prescription'**
  String get divergenceDiffersA11y;

  /// No description provided for @noteSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set {setNumber} note'**
  String noteSetTitle(int setNumber);

  /// No description provided for @noteExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise note'**
  String get noteExerciseTitle;

  /// No description provided for @noteExposureOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'This exposure only. It does not change the plan\'s instructions.'**
  String get noteExposureOnlyHint;

  /// No description provided for @noteOptionalFieldData.
  ///
  /// In en, this message translates to:
  /// **'Optional · field data'**
  String get noteOptionalFieldData;

  /// No description provided for @noteSetPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Grip slipped on rep 5'**
  String get noteSetPlaceholder;

  /// No description provided for @noteExercisePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Using both cables works better'**
  String get noteExercisePlaceholder;

  /// No description provided for @noteSave.
  ///
  /// In en, this message translates to:
  /// **'Save note'**
  String get noteSave;

  /// No description provided for @noteSuggestionGripSlipped.
  ///
  /// In en, this message translates to:
  /// **'Grip slipped'**
  String get noteSuggestionGripSlipped;

  /// No description provided for @noteSuggestionElbowsFlared.
  ///
  /// In en, this message translates to:
  /// **'Elbows flared'**
  String get noteSuggestionElbowsFlared;

  /// No description provided for @noteSuggestionReducedLoad.
  ///
  /// In en, this message translates to:
  /// **'Reduced load after previous set'**
  String get noteSuggestionReducedLoad;

  /// No description provided for @noteSuggestionPain.
  ///
  /// In en, this message translates to:
  /// **'Pain / discomfort'**
  String get noteSuggestionPain;

  /// No description provided for @noteSuggestionEquipment.
  ///
  /// In en, this message translates to:
  /// **'Different equipment'**
  String get noteSuggestionEquipment;

  /// No description provided for @noteSuggestionSpotter.
  ///
  /// In en, this message translates to:
  /// **'Spotter helped'**
  String get noteSuggestionSpotter;

  /// No description provided for @moreDataTitle.
  ///
  /// In en, this message translates to:
  /// **'More data'**
  String get moreDataTitle;

  /// No description provided for @moreDataHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart rate after set'**
  String get moreDataHeartRate;

  /// No description provided for @moreDataFutureSensor.
  ///
  /// In en, this message translates to:
  /// **'Future: filled automatically from a paired sensor. Never required.'**
  String get moreDataFutureSensor;

  /// No description provided for @deviationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Change structure · recorded as deviation'**
  String get deviationSectionTitle;

  /// No description provided for @deviationFrictionA11y.
  ///
  /// In en, this message translates to:
  /// **'Friction {level} of 3'**
  String deviationFrictionA11y(int level);

  /// No description provided for @deviationHoldDuration.
  ///
  /// In en, this message translates to:
  /// **'hold {seconds} s'**
  String deviationHoldDuration(String seconds);

  /// No description provided for @deviationSkipSet.
  ///
  /// In en, this message translates to:
  /// **'Skip set {setNumber}'**
  String deviationSkipSet(int setNumber);

  /// No description provided for @deviationSkipSetExplanation.
  ///
  /// In en, this message translates to:
  /// **'A skipped set is stored without values. Fewer sets than prescribed makes this exposure less comparable.'**
  String get deviationSkipSetExplanation;

  /// No description provided for @deviationHoldSkipSet.
  ///
  /// In en, this message translates to:
  /// **'Hold to skip set'**
  String get deviationHoldSkipSet;

  /// No description provided for @deviationAddSet.
  ///
  /// In en, this message translates to:
  /// **'Add extra set'**
  String get deviationAddSet;

  /// No description provided for @deviationAddSetExplanation.
  ///
  /// In en, this message translates to:
  /// **'The extra set is recorded separately from prescribed sets.'**
  String get deviationAddSetExplanation;

  /// No description provided for @deviationHoldAddSet.
  ///
  /// In en, this message translates to:
  /// **'Hold to add set'**
  String get deviationHoldAddSet;

  /// No description provided for @deviationSkipExercise.
  ///
  /// In en, this message translates to:
  /// **'Skip {exercise}'**
  String deviationSkipExercise(String exercise);

  /// No description provided for @deviationSkipExerciseExplanation.
  ///
  /// In en, this message translates to:
  /// **'Skipping an exercise reduces the repeatability and comparability of the training plan.'**
  String get deviationSkipExerciseExplanation;

  /// No description provided for @deviationHoldSkipExercise.
  ///
  /// In en, this message translates to:
  /// **'Hold to skip'**
  String get deviationHoldSkipExercise;

  /// No description provided for @deviationSubstitute.
  ///
  /// In en, this message translates to:
  /// **'Substitute exercise…'**
  String get deviationSubstitute;

  /// No description provided for @deviationSubstituteExplanation.
  ///
  /// In en, this message translates to:
  /// **'Performing a different exercise breaks the trace for this slot. The prescription is kept and the substitution is recorded.'**
  String get deviationSubstituteExplanation;

  /// No description provided for @deviationHoldSubstitute.
  ///
  /// In en, this message translates to:
  /// **'Hold to substitute'**
  String get deviationHoldSubstitute;

  /// No description provided for @deviationSubstitutionLocked.
  ///
  /// In en, this message translates to:
  /// **'Not available once a set is recorded. Skip the remaining sets and add an unplanned exercise instead.'**
  String get deviationSubstitutionLocked;

  /// No description provided for @deviationReorder.
  ///
  /// In en, this message translates to:
  /// **'Change order…'**
  String get deviationReorder;

  /// No description provided for @deviationReorderExplanation.
  ///
  /// In en, this message translates to:
  /// **'The planned order puts it at #{position}. Changing order affects fatigue and comparability.'**
  String deviationReorderExplanation(int position);

  /// No description provided for @deviationHoldReorder.
  ///
  /// In en, this message translates to:
  /// **'Move it next'**
  String get deviationHoldReorder;

  /// No description provided for @deviationAddUnplanned.
  ///
  /// In en, this message translates to:
  /// **'Add unplanned exercise…'**
  String get deviationAddUnplanned;

  /// No description provided for @deviationAddUnplannedExplanation.
  ///
  /// In en, this message translates to:
  /// **'{exercise} isn\'t part of {workout}. Extra work changes this session\'s volume.'**
  String deviationAddUnplannedExplanation(String exercise, String workout);

  /// No description provided for @deviationHoldAddUnplanned.
  ///
  /// In en, this message translates to:
  /// **'Hold to add'**
  String get deviationHoldAddUnplanned;

  /// No description provided for @deviationPlanAlternatives.
  ///
  /// In en, this message translates to:
  /// **'Plan alternatives for this slot'**
  String get deviationPlanAlternatives;

  /// No description provided for @deviationSearchAtlas.
  ///
  /// In en, this message translates to:
  /// **'Search Atlas'**
  String get deviationSearchAtlas;

  /// No description provided for @deviationSelectExercise.
  ///
  /// In en, this message translates to:
  /// **'Select an exercise'**
  String get deviationSelectExercise;

  /// No description provided for @deviationContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Continue with {exercise}'**
  String deviationContinueWith(String exercise);

  /// No description provided for @finishTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish workout'**
  String get finishTitle;

  /// No description provided for @finishIncompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exercise is incomplete} other{{count} exercises are incomplete}}'**
  String finishIncompleteTitle(int count);

  /// No description provided for @finishIncompleteExplanation.
  ///
  /// In en, this message translates to:
  /// **'Finishing now will record {count, plural, =1{1 set} other{{count} sets}} as not completed.'**
  String finishIncompleteExplanation(int count);

  /// No description provided for @finishContinueWorkout.
  ///
  /// In en, this message translates to:
  /// **'Continue workout'**
  String get finishContinueWorkout;

  /// No description provided for @finishHoldAnyway.
  ///
  /// In en, this message translates to:
  /// **'Finish anyway'**
  String get finishHoldAnyway;

  /// No description provided for @finishSetsRecorded.
  ///
  /// In en, this message translates to:
  /// **'Sets recorded'**
  String get finishSetsRecorded;

  /// No description provided for @finishDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get finishDuration;

  /// No description provided for @finishOnlineHint.
  ///
  /// In en, this message translates to:
  /// **'The workout will be finalised on the server.'**
  String get finishOnlineHint;

  /// No description provided for @finishOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'You are offline. It is saved on this phone and will be finalised after reconnecting.'**
  String get finishOfflineHint;

  /// No description provided for @timerRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get timerRest;

  /// No description provided for @timerRestComplete.
  ///
  /// In en, this message translates to:
  /// **'Rest complete · over by +{elapsed}'**
  String timerRestComplete(String elapsed);

  /// No description provided for @timerMinus30.
  ///
  /// In en, this message translates to:
  /// **'Rest minus 30 seconds'**
  String get timerMinus30;

  /// No description provided for @timerPlus30.
  ///
  /// In en, this message translates to:
  /// **'Rest plus 30 seconds'**
  String get timerPlus30;

  /// No description provided for @timerEnd.
  ///
  /// In en, this message translates to:
  /// **'End rest'**
  String get timerEnd;

  /// No description provided for @timerUpNextSet.
  ///
  /// In en, this message translates to:
  /// **'Up next · Set {setNumber}'**
  String timerUpNextSet(int setNumber);

  /// No description provided for @timerNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest complete'**
  String get timerNotificationTitle;

  /// No description provided for @timerNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'{exercise} · set {setNumber} · {prescription}'**
  String timerNotificationBody(
    String exercise,
    int setNumber,
    String prescription,
  );

  /// No description provided for @syncSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get syncSaved;

  /// No description provided for @syncSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get syncSaving;

  /// No description provided for @syncOfflineCount.
  ///
  /// In en, this message translates to:
  /// **'Offline · {count}'**
  String syncOfflineCount(int count);

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailed;

  /// No description provided for @syncConflict.
  ///
  /// In en, this message translates to:
  /// **'Conflict'**
  String get syncConflict;

  /// No description provided for @syncSuperseded.
  ///
  /// In en, this message translates to:
  /// **'Continued on another device'**
  String get syncSuperseded;

  /// No description provided for @syncSupersededExplanation.
  ///
  /// In en, this message translates to:
  /// **'This workout is view-only until you explicitly resume it here.'**
  String get syncSupersededExplanation;

  /// No description provided for @syncResumeHere.
  ///
  /// In en, this message translates to:
  /// **'Resume here'**
  String get syncResumeHere;

  /// No description provided for @syncSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncSheetTitle;

  /// No description provided for @syncEverythingSaved.
  ///
  /// In en, this message translates to:
  /// **'Everything is saved'**
  String get syncEverythingSaved;

  /// No description provided for @syncSavingTitle.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get syncSavingTitle;

  /// No description provided for @syncOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline — recording continues'**
  String get syncOfflineTitle;

  /// No description provided for @syncFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailedTitle;

  /// No description provided for @syncConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Changed on another device'**
  String get syncConflictTitle;

  /// No description provided for @syncLocalFirstExplanation.
  ///
  /// In en, this message translates to:
  /// **'Every change is stored on this phone first and sent to the server in order.'**
  String get syncLocalFirstExplanation;

  /// No description provided for @syncWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting to sync'**
  String get syncWaiting;

  /// No description provided for @syncLastAck.
  ///
  /// In en, this message translates to:
  /// **'Last server acknowledgement'**
  String get syncLastAck;

  /// No description provided for @syncRetryNow.
  ///
  /// In en, this message translates to:
  /// **'Retry now'**
  String get syncRetryNow;

  /// No description provided for @syncThisPhone.
  ///
  /// In en, this message translates to:
  /// **'This phone'**
  String get syncThisPhone;

  /// No description provided for @syncServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get syncServer;

  /// No description provided for @syncKeepPhone.
  ///
  /// In en, this message translates to:
  /// **'Keep this phone\'s value'**
  String get syncKeepPhone;

  /// No description provided for @syncUseServer.
  ///
  /// In en, this message translates to:
  /// **'Use server value'**
  String get syncUseServer;

  /// No description provided for @syncConflictExplanation.
  ///
  /// In en, this message translates to:
  /// **'Choose which recorded value should be kept. Other workout data remains available.'**
  String get syncConflictExplanation;

  /// No description provided for @recordedTitle.
  ///
  /// In en, this message translates to:
  /// **'{workout} recorded'**
  String recordedTitle(String workout);

  /// No description provided for @recordedSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced. Ready for Post-Workout-Analysis on desktop.'**
  String get recordedSynced;

  /// No description provided for @recordedSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone. It will be finalised automatically when you\'re back online.'**
  String get recordedSavedLocally;

  /// No description provided for @recordedSetsDone.
  ///
  /// In en, this message translates to:
  /// **'sets done'**
  String get recordedSetsDone;

  /// No description provided for @recordedNotDone.
  ///
  /// In en, this message translates to:
  /// **'not done'**
  String get recordedNotDone;

  /// No description provided for @recordedStructuralChanges.
  ///
  /// In en, this message translates to:
  /// **'structural changes'**
  String get recordedStructuralChanges;

  /// No description provided for @recordedTagSubstituted.
  ///
  /// In en, this message translates to:
  /// **'substituted'**
  String get recordedTagSubstituted;

  /// No description provided for @recordedTagUnplanned.
  ///
  /// In en, this message translates to:
  /// **'unplanned'**
  String get recordedTagUnplanned;

  /// No description provided for @recordedTagSkipped.
  ///
  /// In en, this message translates to:
  /// **'skipped'**
  String get recordedTagSkipped;

  /// No description provided for @recordedTagIncomplete.
  ///
  /// In en, this message translates to:
  /// **'incomplete'**
  String get recordedTagIncomplete;

  /// No description provided for @recordedTagReordered.
  ///
  /// In en, this message translates to:
  /// **'reordered'**
  String get recordedTagReordered;

  /// No description provided for @recordedTagNote.
  ///
  /// In en, this message translates to:
  /// **'note'**
  String get recordedTagNote;

  /// No description provided for @atlasTitle.
  ///
  /// In en, this message translates to:
  /// **'Atlas'**
  String get atlasTitle;

  /// No description provided for @atlasSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search exercises and muscles'**
  String get atlasSearchPlaceholder;

  /// No description provided for @atlasOpenArticles.
  ///
  /// In en, this message translates to:
  /// **'Open articles'**
  String get atlasOpenArticles;

  /// No description provided for @atlasExercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get atlasExercises;

  /// No description provided for @atlasMuscles.
  ///
  /// In en, this message translates to:
  /// **'Muscles'**
  String get atlasMuscles;

  /// No description provided for @atlasQuickView.
  ///
  /// In en, this message translates to:
  /// **'Atlas · quick view'**
  String get atlasQuickView;

  /// No description provided for @atlasOpenFull.
  ///
  /// In en, this message translates to:
  /// **'Open full Atlas article'**
  String get atlasOpenFull;

  /// No description provided for @atlasPlanNoteThisWorkout.
  ///
  /// In en, this message translates to:
  /// **'Plan note · this workout'**
  String get atlasPlanNoteThisWorkout;

  /// No description provided for @atlasInTodayWorkout.
  ///
  /// In en, this message translates to:
  /// **'In today\'s workout'**
  String get atlasInTodayWorkout;

  /// No description provided for @atlasSectionTechnique.
  ///
  /// In en, this message translates to:
  /// **'Technique'**
  String get atlasSectionTechnique;

  /// No description provided for @atlasSectionAnatomy.
  ///
  /// In en, this message translates to:
  /// **'Anatomy'**
  String get atlasSectionAnatomy;

  /// No description provided for @atlasSectionMuscles.
  ///
  /// In en, this message translates to:
  /// **'Muscles'**
  String get atlasSectionMuscles;

  /// No description provided for @atlasSectionData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get atlasSectionData;

  /// No description provided for @atlasSectionVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get atlasSectionVideo;

  /// No description provided for @atlasTechniqueSetup.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get atlasTechniqueSetup;

  /// No description provided for @atlasTechniqueExecution.
  ///
  /// In en, this message translates to:
  /// **'Execution'**
  String get atlasTechniqueExecution;

  /// No description provided for @atlasTechniqueFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get atlasTechniqueFocus;

  /// No description provided for @atlasTechniqueStopWhen.
  ///
  /// In en, this message translates to:
  /// **'Stop when'**
  String get atlasTechniqueStopWhen;

  /// No description provided for @atlasEtu.
  ///
  /// In en, this message translates to:
  /// **'ETU'**
  String get atlasEtu;

  /// No description provided for @atlasRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get atlasRecovery;

  /// No description provided for @atlasMuscleExposure.
  ///
  /// In en, this message translates to:
  /// **'Muscle ETU exposure'**
  String get atlasMuscleExposure;

  /// No description provided for @atlasClassification.
  ///
  /// In en, this message translates to:
  /// **'Classification'**
  String get atlasClassification;

  /// No description provided for @atlasRepRanges.
  ///
  /// In en, this message translates to:
  /// **'Recommended rep ranges'**
  String get atlasRepRanges;

  /// No description provided for @atlasVideos.
  ///
  /// In en, this message translates to:
  /// **'Demonstration videos'**
  String get atlasVideos;

  /// No description provided for @atlasLoadCapacity.
  ///
  /// In en, this message translates to:
  /// **'Load capacity'**
  String get atlasLoadCapacity;

  /// No description provided for @atlasTotalEtu.
  ///
  /// In en, this message translates to:
  /// **'Total ETU'**
  String get atlasTotalEtu;

  /// No description provided for @atlasPeakJoint.
  ///
  /// In en, this message translates to:
  /// **'Peak joint'**
  String get atlasPeakJoint;

  /// No description provided for @atlasOfflineUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This article is available when you\'re online. Quick View remains available from the workout.'**
  String get atlasOfflineUnavailable;

  /// No description provided for @atlasOpenMuscleArticle.
  ///
  /// In en, this message translates to:
  /// **'Open muscle article'**
  String get atlasOpenMuscleArticle;

  /// No description provided for @workspaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Workspaces'**
  String get workspaceTitle;

  /// No description provided for @workspacePinnedHint.
  ///
  /// In en, this message translates to:
  /// **'The active workout is pinned. It ends only with Finish workout.'**
  String get workspacePinnedHint;

  /// No description provided for @workspaceActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get workspaceActive;

  /// No description provided for @workspaceCannotClose.
  ///
  /// In en, this message translates to:
  /// **'Can\'t be closed here'**
  String get workspaceCannotClose;

  /// No description provided for @workspaceCloseA11y.
  ///
  /// In en, this message translates to:
  /// **'Close {name}'**
  String workspaceCloseA11y(String name);

  /// No description provided for @workspaceNewTab.
  ///
  /// In en, this message translates to:
  /// **'New Atlas tab'**
  String get workspaceNewTab;

  /// No description provided for @workspaceCounterA11y.
  ///
  /// In en, this message translates to:
  /// **'Open workspaces: {count}'**
  String workspaceCounterA11y(int count);

  /// No description provided for @workspaceLimitReached.
  ///
  /// In en, this message translates to:
  /// **'The oldest inactive Atlas workspace was closed.'**
  String get workspaceLimitReached;

  /// No description provided for @youTitle.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youTitle;

  /// No description provided for @youActivePlanRun.
  ///
  /// In en, this message translates to:
  /// **'Active plan run'**
  String get youActivePlanRun;

  /// No description provided for @youWorkoutSettings.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get youWorkoutSettings;

  /// No description provided for @youDefaultRestCompounds.
  ///
  /// In en, this message translates to:
  /// **'Default rest · compounds'**
  String get youDefaultRestCompounds;

  /// No description provided for @youDefaultRestIsolation.
  ///
  /// In en, this message translates to:
  /// **'Default rest · isolation'**
  String get youDefaultRestIsolation;

  /// No description provided for @youRestNotification.
  ///
  /// In en, this message translates to:
  /// **'Rest-end notification'**
  String get youRestNotification;

  /// No description provided for @youHaptics.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get youHaptics;

  /// No description provided for @youUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get youUnits;

  /// No description provided for @youAppSettings.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get youAppSettings;

  /// No description provided for @youTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get youTheme;

  /// No description provided for @youThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get youThemeDark;

  /// No description provided for @youLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get youLanguage;

  /// No description provided for @youSyncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get youSyncStatus;

  /// No description provided for @youSyncUpToDate.
  ///
  /// In en, this message translates to:
  /// **'up to date'**
  String get youSyncUpToDate;

  /// No description provided for @youSound.
  ///
  /// In en, this message translates to:
  /// **'Rest timer sound'**
  String get youSound;

  /// No description provided for @errorGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGenericTitle;

  /// No description provided for @errorGenericBody.
  ///
  /// In en, this message translates to:
  /// **'Your local workout data is safe. Try again.'**
  String get errorGenericBody;

  /// No description provided for @errorActiveWorkoutExists.
  ///
  /// In en, this message translates to:
  /// **'Another workout is already active. Resume it or resolve the local workout before starting a new one.'**
  String get errorActiveWorkoutExists;

  /// No description provided for @errorPrescriptionChanged.
  ///
  /// In en, this message translates to:
  /// **'The prescription changed before this workout reached the server. Review the new targets; your local entries are still safe.'**
  String get errorPrescriptionChanged;

  /// No description provided for @errorSessionNotStartable.
  ///
  /// In en, this message translates to:
  /// **'This workout-unit cannot be started in its current state.'**
  String get errorSessionNotStartable;

  /// No description provided for @errorPrescriptionMissing.
  ///
  /// In en, this message translates to:
  /// **'No valid prescription is available for this workout-unit.'**
  String get errorPrescriptionMissing;

  /// No description provided for @errorOffScheduleNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Off-schedule workout execution is not available yet.'**
  String get errorOffScheduleNotSupported;

  /// No description provided for @errorSequenceGap.
  ///
  /// In en, this message translates to:
  /// **'Some earlier changes have not reached the server yet. Agonez is reconciling the queue.'**
  String get errorSequenceGap;

  /// No description provided for @errorSequenceMismatch.
  ///
  /// In en, this message translates to:
  /// **'The local and server workout histories disagree. Sending has stopped to protect your data.'**
  String get errorSequenceMismatch;

  /// No description provided for @errorSuperseded.
  ///
  /// In en, this message translates to:
  /// **'This workout was continued on another device.'**
  String get errorSuperseded;

  /// No description provided for @errorWorkoutFinalized.
  ///
  /// In en, this message translates to:
  /// **'This workout has already been finalised.'**
  String get errorWorkoutFinalized;

  /// No description provided for @errorWorkoutNotFound.
  ///
  /// In en, this message translates to:
  /// **'The workout could not be found on the server. Local data has been kept.'**
  String get errorWorkoutNotFound;

  /// No description provided for @errorOpsPending.
  ///
  /// In en, this message translates to:
  /// **'Some workout changes still need to sync before finalisation.'**
  String get errorOpsPending;

  /// No description provided for @errorIncompleteNotAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Confirm that you want to finish with incomplete work.'**
  String get errorIncompleteNotAcknowledged;

  /// No description provided for @errorSubstitutionAfterSets.
  ///
  /// In en, this message translates to:
  /// **'An exercise cannot be substituted after its sets have been recorded.'**
  String get errorSubstitutionAfterSets;

  /// No description provided for @errorConflict.
  ///
  /// In en, this message translates to:
  /// **'This value changed elsewhere. Choose the phone or server value.'**
  String get errorConflict;

  /// No description provided for @errorRejectedOperation.
  ///
  /// In en, this message translates to:
  /// **'The server could not apply this change. Your local entry has been kept for review.'**
  String get errorRejectedOperation;

  /// No description provided for @errorNetworkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The server cannot be reached. Recording continues offline.'**
  String get errorNetworkUnavailable;

  /// No description provided for @errorInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'The server returned an unexpected response. Local data has been kept.'**
  String get errorInvalidResponse;

  /// No description provided for @errorApiBaseUrlMissing.
  ///
  /// In en, this message translates to:
  /// **'API_BASE_URL is not configured for this development build.'**
  String get errorApiBaseUrlMissing;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

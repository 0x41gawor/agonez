// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appName => 'Agonez';

  @override
  String get commonBack => 'Wstecz';

  @override
  String get commonCancel => 'Anuluj';

  @override
  String get commonClose => 'Zamknij';

  @override
  String get commonContinue => 'Kontynuuj';

  @override
  String get commonDone => 'Gotowe';

  @override
  String get commonRetry => 'Spróbuj ponownie';

  @override
  String get commonNotAvailableYet => 'Jeszcze niedostępne';

  @override
  String get navHome => 'Start';

  @override
  String get navWorkout => 'Trening';

  @override
  String get navAtlas => 'Atlas';

  @override
  String get navYou => 'Ty';

  @override
  String get navWorkoutActiveA11y => 'Trening, aktywny';

  @override
  String get homeToday => 'Dzisiaj';

  @override
  String get homeRestDay => 'Dzień odpoczynku';

  @override
  String get homePrescriptionReady => 'Zalecenia gotowe';

  @override
  String get homePrescriptionNotReady => 'Zalecenia nie są gotowe';

  @override
  String get homePrescriptionNotReadyExplanation =>
      'Analiza po treningu nie wyznaczyła jeszcze obciążeń dla tej sesji.';

  @override
  String get homePrescriptionChanged => 'Zalecenia się zmieniły';

  @override
  String homePrescriptionChangedDetail(
    String exercise,
    int setNumber,
    String before,
    String after,
  ) {
    return '$exercise, seria $setNumber · $before → $after kg';
  }

  @override
  String get homeExercisesLabel => 'ćwiczeń';

  @override
  String get homeSetsLabel => 'serii';

  @override
  String get homeMinutesLabel => 'min';

  @override
  String get homeStartWorkout => 'Rozpocznij trening';

  @override
  String get homeStartWithPlanTargets => 'Rozpocznij z celami planu';

  @override
  String get homeOtherWorkoutUnit => 'Wybierz inną jednostkę treningową…';

  @override
  String homeMicrocycle(int current, int total) {
    return 'Mikrocykl $current / $total';
  }

  @override
  String get homeRecent => 'Ostatnie';

  @override
  String get homeDesktopHint =>
      'Trendy i analiza po treningu są dostępne na komputerze.';

  @override
  String get homeResumeTitle => 'Trening w toku';

  @override
  String get homeResumeWorkout => 'Wznów trening';

  @override
  String homeResumeStartedAt(String time) {
    return 'Rozpoczęto $time';
  }

  @override
  String get homeResumeExercise => 'Ćwiczenie';

  @override
  String get homeResumeSet => 'Seria';

  @override
  String get homeResumeStatus => 'Stan';

  @override
  String get homeResumeExerciseComplete => 'Gotowe';

  @override
  String homeResumeSetsTotal(int done, int total) {
    return '$done / $total wszystkich serii';
  }

  @override
  String get homeSingleActiveInfo =>
      'Może być aktywny tylko jeden trening. Zakończ go wewnątrz treningu, zanim rozpoczniesz następny.';

  @override
  String get homeNoRunTitle => 'Brak treningu do wykonania';

  @override
  String get homeNoRunExplanation =>
      'Aplikacja mobilna podąża za aktywną realizacją planu. Wybierz ją, aby kontynuować.';

  @override
  String get homeNoRunChoose => 'Wybierz realizację planu';

  @override
  String get homeRestDayExplanation =>
      'Na dzisiaj nie zaplanowano jednostki treningowej.';

  @override
  String homeNextWorkout(String date) {
    return 'Następny · $date';
  }

  @override
  String get homeActiveElsewhereTitle => 'Trening jest już w toku';

  @override
  String homeActiveElsewhereBody(String workout, String time) {
    return '$workout, rozpoczęto o $time na innym urządzeniu.';
  }

  @override
  String get homeResumeHere => 'Wznów tutaj';

  @override
  String get homeStartFailedTitle => 'Nie udało się rozpocząć treningu';

  @override
  String get homeStartFailedBody =>
      'Telefon ma zapisane zalecenia. Możesz trenować dalej, a dane zsynchronizują się później.';

  @override
  String homeCompletedAt(String time) {
    return 'Ukończono $time';
  }

  @override
  String get runSheetTitle => 'Realizacja planu';

  @override
  String get runContext => 'Kontekst';

  @override
  String get runPlan => 'Plan';

  @override
  String get runMicrocyclePosition => 'Mikrocykl';

  @override
  String get runLockedDuringWorkout =>
      'Zmiana jest zablokowana podczas aktywnego treningu.';

  @override
  String get runRememberedHint =>
      'Wybór jest zapamiętany. Podczas zwykłego użycia aplikacja nie zapyta ponownie.';

  @override
  String get runActive => 'Aktywna';

  @override
  String get runCompleted => 'Ukończona';

  @override
  String get pickerTitle => 'Wybierz jednostkę treningową';

  @override
  String get pickerAdvanced => 'Zaawansowane';

  @override
  String get pickerToday => 'Dzisiaj';

  @override
  String pickerScheduledOn(String date) {
    return 'Zaplanowano $date';
  }

  @override
  String pickerDoneOn(String date) {
    return 'Wykonano · $date';
  }

  @override
  String get pickerFallback => 'Zastępcza · przyszła funkcja';

  @override
  String get pickerTodayExplanation => 'Dzisiejszy zaplanowany trening.';

  @override
  String pickerNotTodayExplanation(String workout) {
    return '$workout nie jest zaplanowany na dzisiaj. Wykonanie go teraz zmienia planowaną kolejność ekspozycji.';
  }

  @override
  String pickerStartInstead(String workout) {
    return 'Rozpocznij zamiast tego: $workout';
  }

  @override
  String get pickerFallbackFuture =>
      'Zastępcze jednostki treningowe są przyszłą funkcją planu.';

  @override
  String get pickerOffScheduleUnsupported =>
      'Tej jednostki nie można jeszcze rozpocząć poza harmonogramem.';

  @override
  String get workoutMinimiseA11y =>
      'Zminimalizuj trening; trening pozostanie aktywny';

  @override
  String get workoutOutline => 'Plan treningu';

  @override
  String get workoutActions => 'Działania treningu';

  @override
  String workoutElapsed(String duration) {
    return 'Czas $duration';
  }

  @override
  String workoutExerciseCounter(int current, int total) {
    return 'ĆWICZENIE $current / $total';
  }

  @override
  String workoutSetCounter(int done, int total) {
    return 'SERIE $done / $total';
  }

  @override
  String get workoutRolePrimaryProgressive => 'Główne progresywne';

  @override
  String get workoutRoleSecondaryCompound => 'Pomocnicze wielostawowe';

  @override
  String get workoutRoleIsolation => 'Izolowane';

  @override
  String workoutPrescribedSet(int setNumber) {
    return 'ZALECONE · SERIA $setNumber';
  }

  @override
  String workoutLastExposure(String microcycle) {
    return 'OSTATNIO · $microcycle';
  }

  @override
  String get workoutPlanNote => 'Notatka planu';

  @override
  String workoutSetLabel(int setNumber) {
    return 'Seria $setNumber';
  }

  @override
  String get workoutExtraLabel => 'Dodatkowa';

  @override
  String get workoutSkippedLabel => 'Pominięta';

  @override
  String get workoutUnplanned => 'Nieplanowane ćwiczenie';

  @override
  String get workoutOrderChanged => 'zmieniona kolejność';

  @override
  String get workoutPerformed => 'Wykonano';

  @override
  String get workoutPrescribed => 'Zalecono';

  @override
  String workoutPrescriptionWasFor(String exercise) {
    return 'Zalecenia dotyczyły: $exercise';
  }

  @override
  String get workoutNoPrescriptionUnplanned => 'Bez zaleceń · nieplanowane';

  @override
  String get workoutExtraNotPrescribed => 'Dodatkowa seria · poza zaleceniami';

  @override
  String get workoutRecordWhatYouDo => 'Zapisz to, co faktycznie wykonujesz.';

  @override
  String workoutTargetBandApplies(String reps, int rir) {
    return 'Zakres docelowy nadal obowiązuje: $reps powt. @ RIR $rir';
  }

  @override
  String get workoutExerciseComplete => 'Ćwiczenie ukończone';

  @override
  String get workoutUpNext => 'Następne';

  @override
  String workoutStartNext(String exercise) {
    return 'Rozpocznij: $exercise';
  }

  @override
  String get workoutFinishWorkout => 'Zakończ trening';

  @override
  String workoutOutlineTitle(String workout) {
    return 'Plan treningu $workout';
  }

  @override
  String get workoutDoNext => 'Wykonaj teraz';

  @override
  String workoutPlannedPosition(int position) {
    return 'planowana pozycja #$position';
  }

  @override
  String get setLoad => 'Obciążenie';

  @override
  String get setReps => 'Powtórzenia';

  @override
  String get setRir => 'RIR';

  @override
  String setTarget(String target) {
    return 'cel $target';
  }

  @override
  String get setTapToType => 'Dotknij, aby wpisać';

  @override
  String get setOther => 'inne';

  @override
  String setConfirm(int setNumber) {
    return 'Potwierdź serię $setNumber';
  }

  @override
  String setConfirmSummary(String load, int reps, String rir, String rest) {
    return '$load × $reps @ $rir · potem odpoczynek $rest';
  }

  @override
  String get setSelectRepsRir => 'Wybierz powtórzenia i RIR';

  @override
  String get setEnterLoad => 'Wprowadź obciążenie';

  @override
  String get setKeptFromLast => 'zachowano z poprzedniej serii';

  @override
  String get setReset => 'Resetuj';

  @override
  String setRecordedSnackbar(int setNumber) {
    return 'Zapisano serię $setNumber';
  }

  @override
  String get setUndo => 'Cofnij';

  @override
  String setEditTitle(int setNumber) {
    return 'Edytuj serię $setNumber';
  }

  @override
  String get setEditingNormal => 'Zapisana · edycja jest normalna';

  @override
  String setSave(int setNumber) {
    return 'Zapisz serię $setNumber';
  }

  @override
  String get setMarkSkipped => 'Oznacz jako pominiętą…';

  @override
  String setMinusLoadA11y(String step) {
    return 'Zmniejsz o $step kilograma';
  }

  @override
  String setPlusLoadA11y(String step) {
    return 'Zwiększ o $step kilograma';
  }

  @override
  String setLoadValueA11y(String load) {
    return 'Obciążenie $load kilograma, dotknij dwa razy, aby wpisać';
  }

  @override
  String setRepA11y(int reps, String selection, String targetState) {
    return '$reps powtórzeń, $selection, $targetState';
  }

  @override
  String get setSelectedA11y => 'wybrane';

  @override
  String get setNotSelectedA11y => 'niewybrane';

  @override
  String get setWithinTargetA11y => 'w zakresie docelowym';

  @override
  String get setOutsideTargetA11y => 'poza zakresem docelowym';

  @override
  String divergenceLoad(String delta) {
    return '$delta kg względem zaleceń';
  }

  @override
  String divergenceRepsBelow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count poniżej celu',
      many: '$count poniżej celu',
      few: '$count poniżej celu',
      one: '1 poniżej celu',
    );
    return '$_temp0';
  }

  @override
  String divergenceRepsAbove(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count powyżej celu',
      many: '$count powyżej celu',
      few: '$count powyżej celu',
      one: '1 powyżej celu',
    );
    return '$_temp0';
  }

  @override
  String get divergenceRirDeeper => 'bliżej upadku niż cel';

  @override
  String get divergenceRirLighter => 'dalej od upadku niż cel';

  @override
  String get divergenceDiffersA11y => 'różni się od zaleceń';

  @override
  String noteSetTitle(int setNumber) {
    return 'Notatka do serii $setNumber';
  }

  @override
  String get noteExerciseTitle => 'Notatka do ćwiczenia';

  @override
  String get noteExposureOnlyHint =>
      'Dotyczy tylko tej ekspozycji. Nie zmienia instrukcji planu.';

  @override
  String get noteOptionalFieldData => 'Opcjonalne · dane z treningu';

  @override
  String get noteSetPlaceholder => 'np. chwyt puścił przy 5. powtórzeniu';

  @override
  String get noteExercisePlaceholder => 'np. lepiej działa użycie obu linek';

  @override
  String get noteSave => 'Zapisz notatkę';

  @override
  String get noteSuggestionGripSlipped => 'Chwyt puścił';

  @override
  String get noteSuggestionElbowsFlared => 'Łokcie uciekły na zewnątrz';

  @override
  String get noteSuggestionReducedLoad =>
      'Zmniejszono ciężar po poprzedniej serii';

  @override
  String get noteSuggestionPain => 'Ból / dyskomfort';

  @override
  String get noteSuggestionEquipment => 'Inny sprzęt';

  @override
  String get noteSuggestionSpotter => 'Pomoc asekurującego';

  @override
  String get moreDataTitle => 'Więcej danych';

  @override
  String get moreDataHeartRate => 'Tętno po serii';

  @override
  String get moreDataFutureSensor =>
      'W przyszłości: automatycznie z połączonego czujnika. Nigdy niewymagane.';

  @override
  String get deviationSectionTitle =>
      'Zmiana struktury · zapisywana jako odstępstwo';

  @override
  String deviationFrictionA11y(int level) {
    return 'Poziom potwierdzenia $level z 3';
  }

  @override
  String deviationHoldDuration(String seconds) {
    return 'przytrzymaj $seconds s';
  }

  @override
  String deviationSkipSet(int setNumber) {
    return 'Pomiń serię $setNumber';
  }

  @override
  String get deviationSkipSetExplanation =>
      'Pominięta seria jest zapisywana bez wartości. Mniej serii niż zalecono obniża porównywalność tej ekspozycji.';

  @override
  String get deviationHoldSkipSet => 'Przytrzymaj, aby pominąć serię';

  @override
  String get deviationAddSet => 'Dodaj serię dodatkową';

  @override
  String get deviationAddSetExplanation =>
      'Dodatkowa seria jest zapisywana oddzielnie od serii zaleconych.';

  @override
  String get deviationHoldAddSet => 'Przytrzymaj, aby dodać serię';

  @override
  String deviationSkipExercise(String exercise) {
    return 'Pomiń: $exercise';
  }

  @override
  String get deviationSkipExerciseExplanation =>
      'Pominięcie ćwiczenia obniża powtarzalność i porównywalność planu treningowego.';

  @override
  String get deviationHoldSkipExercise => 'Przytrzymaj, aby pominąć';

  @override
  String get deviationSubstitute => 'Zamień ćwiczenie…';

  @override
  String get deviationSubstituteExplanation =>
      'Wykonanie innego ćwiczenia przerywa ślad tej pozycji. Zalecenia zostają zachowane, a zamiana jest zapisywana.';

  @override
  String get deviationHoldSubstitute => 'Przytrzymaj, aby zamienić';

  @override
  String get deviationSubstitutionLocked =>
      'Niedostępne po zapisaniu serii. Pomiń pozostałe serie i dodaj ćwiczenie nieplanowane.';

  @override
  String get deviationReorder => 'Zmień kolejność…';

  @override
  String deviationReorderExplanation(int position) {
    return 'Planowana kolejność umieszcza to ćwiczenie na pozycji #$position. Zmiana wpływa na zmęczenie i porównywalność.';
  }

  @override
  String get deviationHoldReorder => 'Przenieś jako następne';

  @override
  String get deviationAddUnplanned => 'Dodaj nieplanowane ćwiczenie…';

  @override
  String deviationAddUnplannedExplanation(String exercise, String workout) {
    return '$exercise nie należy do $workout. Dodatkowa praca zmienia objętość tej sesji.';
  }

  @override
  String get deviationHoldAddUnplanned => 'Przytrzymaj, aby dodać';

  @override
  String get deviationPlanAlternatives => 'Alternatywy planu dla tej pozycji';

  @override
  String get deviationSearchAtlas => 'Przeszukaj Atlas';

  @override
  String get deviationSelectExercise => 'Wybierz ćwiczenie';

  @override
  String deviationContinueWith(String exercise) {
    return 'Kontynuuj z: $exercise';
  }

  @override
  String get finishTitle => 'Zakończ trening';

  @override
  String finishIncompleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ćwiczenia jest nieukończone',
      many: '$count ćwiczeń jest nieukończonych',
      few: '$count ćwiczenia są nieukończone',
      one: '1 ćwiczenie jest nieukończone',
    );
    return '$_temp0';
  }

  @override
  String finishIncompleteExplanation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count serii jako niewykonane',
      many: '$count serii jako niewykonanych',
      few: '$count serie jako niewykonane',
      one: '1 serię jako niewykonaną',
    );
    return 'Zakończenie teraz zapisze $_temp0.';
  }

  @override
  String get finishContinueWorkout => 'Kontynuuj trening';

  @override
  String get finishHoldAnyway => 'Zakończ mimo to';

  @override
  String get finishSetsRecorded => 'Zapisane serie';

  @override
  String get finishDuration => 'Czas trwania';

  @override
  String get finishOnlineHint => 'Trening zostanie sfinalizowany na serwerze.';

  @override
  String get finishOfflineHint =>
      'Brak połączenia. Trening zapisano w telefonie i zostanie sfinalizowany po odzyskaniu połączenia.';

  @override
  String get timerRest => 'Odpoczynek';

  @override
  String timerRestComplete(String elapsed) {
    return 'Odpoczynek zakończony · +$elapsed';
  }

  @override
  String get timerMinus30 => 'Skróć odpoczynek o 30 sekund';

  @override
  String get timerPlus30 => 'Wydłuż odpoczynek o 30 sekund';

  @override
  String get timerEnd => 'Zakończ odpoczynek';

  @override
  String timerUpNextSet(int setNumber) {
    return 'Następna · seria $setNumber';
  }

  @override
  String get timerNotificationTitle => 'Odpoczynek zakończony';

  @override
  String timerNotificationBody(
    String exercise,
    int setNumber,
    String prescription,
  ) {
    return '$exercise · seria $setNumber · $prescription';
  }

  @override
  String get syncSaved => 'Zapisano';

  @override
  String get syncSaving => 'Zapisywanie…';

  @override
  String syncOfflineCount(int count) {
    return 'Offline · $count';
  }

  @override
  String get syncFailed => 'Błąd synchronizacji';

  @override
  String get syncConflict => 'Konflikt';

  @override
  String get syncSuperseded => 'Kontynuowano na innym urządzeniu';

  @override
  String get syncSupersededExplanation =>
      'Ten trening jest tylko do odczytu, dopóki jawnie nie wznowisz go tutaj.';

  @override
  String get syncResumeHere => 'Wznów tutaj';

  @override
  String get syncSheetTitle => 'Synchronizacja';

  @override
  String get syncEverythingSaved => 'Wszystko zapisane';

  @override
  String get syncSavingTitle => 'Zapisywanie…';

  @override
  String get syncOfflineTitle => 'Offline — zapis treningu działa dalej';

  @override
  String get syncFailedTitle => 'Błąd synchronizacji';

  @override
  String get syncConflictTitle => 'Zmieniono na innym urządzeniu';

  @override
  String get syncLocalFirstExplanation =>
      'Każda zmiana jest najpierw zapisywana w telefonie, a następnie wysyłana na serwer w kolejności.';

  @override
  String get syncWaiting => 'Oczekuje na synchronizację';

  @override
  String get syncLastAck => 'Ostatnie potwierdzenie serwera';

  @override
  String get syncRetryNow => 'Spróbuj teraz';

  @override
  String get syncThisPhone => 'Ten telefon';

  @override
  String get syncServer => 'Serwer';

  @override
  String get syncKeepPhone => 'Zachowaj wartość z telefonu';

  @override
  String get syncUseServer => 'Użyj wartości z serwera';

  @override
  String get syncConflictExplanation =>
      'Wybierz wartość, która ma zostać zachowana. Pozostałe dane treningu są bezpieczne.';

  @override
  String recordedTitle(String workout) {
    return 'Zapisano: $workout';
  }

  @override
  String get recordedSynced =>
      'Zsynchronizowano. Gotowe do analizy po treningu na komputerze.';

  @override
  String get recordedSavedLocally =>
      'Zapisano na tym telefonie. Trening zostanie automatycznie sfinalizowany po odzyskaniu połączenia.';

  @override
  String get recordedSetsDone => 'serie wykonane';

  @override
  String get recordedNotDone => 'niewykonane';

  @override
  String get recordedStructuralChanges => 'zmiany struktury';

  @override
  String get recordedTagSubstituted => 'zamienione';

  @override
  String get recordedTagUnplanned => 'nieplanowane';

  @override
  String get recordedTagSkipped => 'pominięte';

  @override
  String get recordedTagIncomplete => 'nieukończone';

  @override
  String get recordedTagReordered => 'zmieniona kolejność';

  @override
  String get recordedTagNote => 'notatka';

  @override
  String get atlasTitle => 'Atlas';

  @override
  String get atlasSearchPlaceholder => 'Szukaj ćwiczeń i mięśni';

  @override
  String get atlasOpenArticles => 'Otwarte artykuły';

  @override
  String get atlasExercises => 'Ćwiczenia';

  @override
  String get atlasMuscles => 'Mięśnie';

  @override
  String get atlasQuickView => 'Atlas · szybki podgląd';

  @override
  String get atlasOpenFull => 'Otwórz pełny artykuł Atlasu';

  @override
  String get atlasPlanNoteThisWorkout => 'Notatka planu · ten trening';

  @override
  String get atlasInTodayWorkout => 'W dzisiejszym treningu';

  @override
  String get atlasSectionTechnique => 'Technika';

  @override
  String get atlasSectionAnatomy => 'Anatomia';

  @override
  String get atlasSectionMuscles => 'Mięśnie';

  @override
  String get atlasSectionData => 'Dane';

  @override
  String get atlasSectionVideo => 'Wideo';

  @override
  String get atlasTechniqueSetup => 'Ustawienie';

  @override
  String get atlasTechniqueExecution => 'Wykonanie';

  @override
  String get atlasTechniqueFocus => 'Skupienie';

  @override
  String get atlasTechniqueStopWhen => 'Przerwij, gdy';

  @override
  String get atlasEtu => 'ETU';

  @override
  String get atlasRecovery => 'Regeneracja';

  @override
  String get atlasMuscleExposure => 'Ekspozycja mięśniowa ETU';

  @override
  String get atlasClassification => 'Klasyfikacja';

  @override
  String get atlasRepRanges => 'Zalecane zakresy powtórzeń';

  @override
  String get atlasVideos => 'Filmy demonstracyjne';

  @override
  String get atlasLoadCapacity => 'Potencjał obciążenia';

  @override
  String get atlasTotalEtu => 'Łączne ETU';

  @override
  String get atlasPeakJoint => 'Główny staw';

  @override
  String get atlasOfflineUnavailable =>
      'Ten artykuł będzie dostępny online. Szybki podgląd nadal działa z poziomu treningu.';

  @override
  String get atlasOpenMuscleArticle => 'Otwórz artykuł o mięśniu';

  @override
  String get workspaceTitle => 'Obszary robocze';

  @override
  String get workspacePinnedHint =>
      'Aktywny trening jest przypięty. Kończy się wyłącznie przez Zakończ trening.';

  @override
  String get workspaceActive => 'Aktywny';

  @override
  String get workspaceCannotClose => 'Nie można tutaj zamknąć';

  @override
  String workspaceCloseA11y(String name) {
    return 'Zamknij $name';
  }

  @override
  String get workspaceNewTab => 'Nowa karta Atlasu';

  @override
  String workspaceCounterA11y(int count) {
    return 'Otwarte obszary robocze: $count';
  }

  @override
  String get workspaceLimitReached =>
      'Najstarszy nieaktywny obszar roboczy Atlasu został zamknięty.';

  @override
  String get youTitle => 'Ty';

  @override
  String get youActivePlanRun => 'Aktywna realizacja planu';

  @override
  String get youWorkoutSettings => 'Trening';

  @override
  String get youDefaultRestCompounds =>
      'Domyślny odpoczynek · ćwiczenia wielostawowe';

  @override
  String get youDefaultRestIsolation => 'Domyślny odpoczynek · izolacje';

  @override
  String get youRestNotification => 'Powiadomienie o końcu odpoczynku';

  @override
  String get youHaptics => 'Wibracje dotykowe';

  @override
  String get youUnits => 'Jednostki';

  @override
  String get youAppSettings => 'Aplikacja';

  @override
  String get youTheme => 'Motyw';

  @override
  String get youThemeDark => 'Ciemny';

  @override
  String get youLanguage => 'Język';

  @override
  String get youSyncStatus => 'Synchronizacja';

  @override
  String get youSyncUpToDate => 'aktualna';

  @override
  String get youSound => 'Dźwięk timera odpoczynku';

  @override
  String get errorGenericTitle => 'Coś poszło nie tak';

  @override
  String get errorGenericBody =>
      'Lokalne dane treningu są bezpieczne. Spróbuj ponownie.';

  @override
  String get errorActiveWorkoutExists =>
      'Inny trening jest już aktywny. Wznów go lub rozwiąż stan lokalnego treningu przed rozpoczęciem nowego.';

  @override
  String get errorPrescriptionChanged =>
      'Zalecenia zmieniły się, zanim trening dotarł do serwera. Sprawdź nowe cele; lokalne wpisy są bezpieczne.';

  @override
  String get errorSessionNotStartable =>
      'Tej jednostki treningowej nie można rozpocząć w obecnym stanie.';

  @override
  String get errorPrescriptionMissing =>
      'Brak prawidłowych zaleceń dla tej jednostki treningowej.';

  @override
  String get errorOffScheduleNotSupported =>
      'Wykonywanie treningu poza harmonogramem nie jest jeszcze dostępne.';

  @override
  String get errorSequenceGap =>
      'Niektóre wcześniejsze zmiany nie dotarły jeszcze do serwera. Agonez uzgadnia kolejkę.';

  @override
  String get errorSequenceMismatch =>
      'Lokalna i serwerowa historia treningu są niespójne. Wysyłanie zatrzymano, aby chronić dane.';

  @override
  String get errorSuperseded =>
      'Ten trening był kontynuowany na innym urządzeniu.';

  @override
  String get errorWorkoutFinalized => 'Ten trening został już sfinalizowany.';

  @override
  String get errorWorkoutNotFound =>
      'Nie znaleziono treningu na serwerze. Dane lokalne zostały zachowane.';

  @override
  String get errorOpsPending =>
      'Niektóre zmiany treningu muszą się zsynchronizować przed finalizacją.';

  @override
  String get errorIncompleteNotAcknowledged =>
      'Potwierdź zakończenie treningu z nieukończoną pracą.';

  @override
  String get errorSubstitutionAfterSets =>
      'Nie można zamienić ćwiczenia po zapisaniu jego serii.';

  @override
  String get errorConflict =>
      'Ta wartość została zmieniona gdzie indziej. Wybierz wartość z telefonu albo serwera.';

  @override
  String get errorRejectedOperation =>
      'Serwer nie mógł zastosować tej zmiany. Lokalny wpis zachowano do sprawdzenia.';

  @override
  String get errorNetworkUnavailable =>
      'Nie można połączyć się z serwerem. Zapis treningu działa offline.';

  @override
  String get errorInvalidResponse =>
      'Serwer zwrócił nieoczekiwaną odpowiedź. Dane lokalne zostały zachowane.';

  @override
  String get errorApiBaseUrlMissing =>
      'W tej wersji deweloperskiej nie skonfigurowano API_BASE_URL.';
}

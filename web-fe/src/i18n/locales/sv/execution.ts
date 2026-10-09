export default {
  execution: {
    shellStatus: 'UTFÖRANDE · DESKTOP', nav: 'Utförande',
    tabs: { overview: 'Översikt', analysis: 'Analys', timeline: 'Tidslinje', loads: 'Belastningar' },
    common: { kg: 'kg', rir: 'RIR', reps: 'reps', today: 'I dag', close: 'Stäng', save: 'Spara', cancel: 'Avbryt', edit: 'Redigera', locked: 'Låst', loading: 'Läser in utförandedata…', marker: 'MARKER.X', reserved: 'reserverad' },
    run: {
      eyebrow: 'Plankörning', from: 'Från {plan}', all: 'Alla körningar ({count})', new: 'Ny plankörning', meta: '{start} → {end} · {count} × mikrocykler på {days} dagar',
      status: { scheduled: 'Planerad', active: 'Aktiv', cancelled: 'Avbruten', completed: 'Slutförd' }, emptyTitle: 'Inga plankörningar ännu', emptyBody: 'En plankörning placerar en träningsplan i verklig kalendertid.', loadError: 'Plankörningen kunde inte läsas in', listError: 'Plankörningarna kunde inte läsas in.',
    },
    status: { scheduled: 'Planerad', in_progress: 'Pågår', completed: 'Slutförd', cancelled: 'Avbruten', missed: 'Missad', today: 'I dag' }, completion: { as_prescribed: 'Enligt ordination', fallback: 'Alternativ' }, classification: { normal: 'Normal', deload: 'Nedtrappning', reload: 'Återtrappning' },
    blocked: {
      previous_exposure_in_progress: 'Föregående exponering pågår fortfarande.', previous_exposure_not_performed: 'Föregående ordinerade exponering har inte genomförts.', session_started: 'Det här passet har redan startat.', no_future_session: 'Det finns inget senare pass i den här körningen.', run_not_active: 'Den här plankörningen är inte aktiv.', unknown: 'Den här ordinationen kan inte redigeras ännu.',
    },
    overview: {
      where: 'Din position', position: 'Mikrocykel {current} av {total} · dag {day} av {days}', positionSub: 'körningsdag {runDay} av {runDays}, {left} dagar kvar', thisMicrocycle: 'Denna mikrocykel', sessions: 'Pass i kalendern', analysisEyebrow: 'Efterträningsanalys · nästa: MC{mc}', prescriptions: 'Ordinationer för nästa mikrocykel',
      continue: 'Fortsätt {workout}', waiting: 'Väntar', saved: '{saved} / {total} sparade', latest: 'Senaste exponering · {workout} · {date}', comparison: 'Ordinerat jämfört med utfört', exercise: 'Övning', prescribed: 'Ordinerat', performed: 'Utfört', note: 'Anteckning', adherence: 'Följsamhet', didPlanHappen: 'Genomfördes planen?',
      journal: 'Journal', latestEvents: 'Senaste händelser', allEvents: 'Alla ({count})', observationPlaceholder: 'Logga en observation…', log: 'Logga', fullCalendar: 'Fullständig kalender', readOnlyDraft: 'Pågående prestation kommer från mobilappen och är skrivskyddad här.', noCurrentSessions: 'Det finns inga pass i den aktuella mikrocykeln.', noExposure: 'Ingen slutförd exponering ännu.', noEvents: 'Inga händelser har loggats.',
    },
    analysis: {
      queue: 'Ordinera MC{mc}', queueToggle: 'Kö', progress: '{saved} av {total} sparade · {locked} låsta', workoutTrace: 'träningsenhetens historik', ready: 'Klar', keyboard: 'J / K', notStarted: 'Inte påbörjad', unsaved: 'Osparade ändringar', saved: 'Sparad', locked: 'Låst',
      confirmLeave: 'Du har osparade ordinationer. Lämna Analys? Utkasten finns kvar i den här webbläsarsessionen.', basedOn: 'Baserat på MC{mc} · {date}', noSummary: 'Ingen utförd exponering', loadError: 'Analysen kunde inte läsas in.', traceEyebrow: '{workout} · plats {slot} · övningshistorik', plan: "plan: {sets} × {min}–{max} {'@'}RIR {rir}",
      continuity: 'en historik från MC{from} genom planrevisionerna {revisions}', planNote: 'Plananteckning', previous: 'Föregående övning', next: 'Nästa övning', position: '{current} / {total}', loadStrip: 'Belastning per set · kg', prescribedLegend: 'ordinerat', performedLegend: 'utfört', nextLegend: 'nästa',
      exposure: 'Exponering', set: 'Set {set}', comments: 'Kommentarer', prescription: 'Ordination', actual: 'Faktiskt', draft: 'Utkast', setSkipped: 'set hoppades över', notSynced: 'inte synkroniserat', additional: '+EXTRA', missed: 'Missad', cancelled: 'Avbruten', scheduled: 'Planerad', inProgress: 'Pågår',
      substituted: 'Ersatt med: {exercise}', exerciseSkipped: 'Övning hoppades över — inga set utfördes', noComment: 'Ingen kommentar', revision: 'Planrevision r{from} → r{to}', revisionBody: 'Gäller från MC{mc} · {date}. {changes}. Samma övningshistorik fortsätter.', compare: 'Jämför revisioner',
      expand: 'Visa detaljer för MC{mc}', collapse: 'Dölj detaljer för MC{mc}', session: 'Pass', recorded: 'Registrerat', setComment: 'Setkommentar', performanceAfterSync: 'Prestationen visas efter att passet synkroniserats från mobilen.',
      flags: { substituted: 'Ersatt', skipped: 'Överhoppad', additional_set: 'Extra set', reps_below_range: 'Repetitioner under intervallet', reps_at_floor: 'Repetitioner vid nedre gränsen', top_of_range: 'Övre delen av intervallet', load_reduced: 'Belastning minskad', personal_record: 'Personligt rekord' },
    },
    editor: {
      eyebrow: 'Nästa ordination', title: '{exercise} · MC{mc}', scheduled: '{workout} · {date} · redigerbar tills passet startar', status: { clean: 'Inte påbörjad', dirty: 'Osparad', saving: 'Sparar…', saved: 'Sparad', locked: 'Låst' },
      basis: 'Baserat på prestationen i MC{mc} · {date} · slutförd', firstExposure: 'Första exponeringen — det finns ingen tidigare prestation.', evidence: 'Reps {reps} · belastningar {loads} kg · {top} vid övre gränsen · {floor} vid nedre gränsen · {deeper} djupare än mål-RIR',
      startFrom: 'Börja från', previousPrescription: 'Ordination MC{mc}', previousPerformance: 'Prestation MC{mc}', allMinus: 'alla −{step}', allPlus: 'alla +{step}', suggestion: 'Förslag', suggestionNone: 'Progressionsmodell · ingen', suggestionBody: 'Ingen progressionsmodell är tilldelad den här platsen.',
      fromPlan: 'Från planen', load: 'Belastning kg', last: 'senast {load}', comment: 'Setkommentar (valfri)', selectSet: 'Välj set {set}', minus: 'Set {set}: dra av {step} kg', plus: 'Set {set}: lägg till {step} kg', apply: 'Tillämpa', selected: 'på {count} valda',
      prescriptionComment: 'Ordinationskommentar · endast för denna exponering', commentPlaceholder: 'Vad bör idrottaren fokusera på nästa gång?', planOwned: 'Antal set, repetitionsintervall och RIR kommer från planrevision r{revision}. Ändra dem i Planskaparen för framtida mikrocykler.',
      discard: 'Kassera', save: 'Spara', saveNext: 'Spara och nästa övning', reload: 'Läs in historiken igen', invalid: 'Set {set}: ange en giltig belastning från 0 till 1000 kg med högst 2 decimaler.', fix: 'Rätta ogiltiga belastningar innan du sparar.', lockedHelp: 'Granska historiken medan du väntar; backend låser upp redigeraren när villkoret för beredskap är uppfyllt.',
      stale_basis: 'Det finns en nyare prestation. Läs in historiken igen; dina inmatade värden behålls.', version_conflict: 'Någon annan har sparat ordinationen. Läs in den senaste versionen; dina värden behålls.', prescription_blocked: 'Ordinationen blockeras av en tidigare exponering.', session_locked: 'Passet har startat och ordinationen är låst.',
      not_next_session: 'Detta är inte längre nästa pass.', set_count_mismatch: 'Antalet set i planen har ändrats. Läs in historiken igen.', invalid_load: 'En eller flera belastningar är ogiltiga.', genericError: 'Ordinationen kunde inte sparas.', savedToast: 'Sparad · {exercise} · MC{mc}', noLoadStep: 'Planen anger inget belastningssteg; använd direkt inmatning.',
    },
    workout: {
      breadcrumb: 'Analys / träningsenhetens historik', title: '{workout}', subtitle: 'dag {day} i varje mikrocykel · {count} övningsplatser', help: 'Cell = högsta utförda belastning · repetitioner per set. Öppna en kolumn eller cell för att granska övningens historik.', occurrence: 'Tillfälle', volume: 'Volymbelastning', comment: 'Träningskommentar', prescribed: 'ordinerat', notPerformed: 'inte utfört', empty: 'inte ordinerat ännu', skipped: 'överhoppat', locked: 'låst', loadError: 'Träningshistoriken kunde inte läsas in.',
    },
    timeline: {
      eyebrow: 'Mikrocykelhistorik · kalender', title: '{count} mikrocykler · {start} → {end}', microcycles: 'Mikrocykler', weeks: 'Kalenderveckor', axis: 'Tidsaxel', helpMicrocycles: 'En rad per mikrocykel, plandagar från vänster till höger.', helpWeeks: 'Kalenderveckor från måndag till söndag. Mikrocykelgränserna förblir synliga.',
      attendance: 'Närvaro', volume: 'Volymbel.', note: '+ anteckning', notePlaceholder: 'Observation för MC{mc}…', saveNote: 'Spara anteckning', selectSession: 'Välj ett pass för att visa detaljer.', session: 'Pass · MC{mc} · D{day}', prescription: 'Ordination: {state}',
      cancelSession: 'Avbryt pass…', reclassify: 'Klassificera som avbrutet…', restore: 'Återställ som planerat', restorePast: 'Ett tidigare pass kan inte planeras om.', reason: 'Orsak', reasonPlaceholder: 't.ex. semester', logEvent: 'Logga även en journalhändelse', confirm: 'Bekräfta',
      journal: 'Plankörningens historik', filters: { all: 'Alla', plan: 'Planändringar', phases: 'Belastningsfaser', breaks: 'Uppehåll', notes: 'Poster och anteckningar' }, eventType: 'Händelsetyp', date: 'Datum', text: 'Text', eventPlaceholder: 't.ex. Platå i två veckor. Kontrollera återhämtningen.', log: 'Logga händelse', noEvents: 'Inga händelser av denna typ.', eventTypes: { observation: 'Observation', vacation: 'Semester', training_break: 'Träningsuppehåll' }, system: 'systemhändelse', user: 'loggad av användaren', loadError: 'Tidslinjen kunde inte läsas in.',
    },
    loads: {
      eyebrow: 'Analys av alla belastningar', title: 'Utvecklas lyften tillsammans?', subtitle: 'Endast slutförda prestationer; ersättningar, överhoppningar samt missade och avbrutna pass lämnar luckor.', traces: 'Övningshistorik · {shown} av {total} visas', primary: 'Huvudlyft', all: 'Alla', none: 'Inga', metric: 'Mått', scale: 'Skala', relative: '% av första exponeringen', kg: 'kg',
      top_set_load: 'Belastning i tyngsta set', mean_set_load: 'Genomsnittlig setbelastning', volume_load: 'Volymbelastning', chart: 'Diagram över belastningsutveckling', noSelection: 'Ingen övningshistorik vald', noSelectionBody: 'Välj historik till vänster eller visa alla.', showAll: 'Visa alla', byUnit: 'Efter träningsenhet', loadError: 'Belastningsanalysen kunde inte läsas in.', gap: 'lucka: {reason}',
    },
    newRun: {
      back: 'Tillbaka till Utförande', title: 'Ny plankörning', subtitle: 'Placera en planrevision i verklig kalendertid.', defaultName: '{plan} — körning', plan: 'Träningsplan', revision: 'Planrevision', name: 'Körningens namn', start: 'Startdatum', count: 'Mikrocykler', end: 'Slut (beräknat)',
      preview: 'Förhandsgranskning · det här skapas', microcycles: 'mikrocykler', sessions: 'planerade pass', workouts: 'träningshistorik', exercises: 'övningshistorik', overlap: 'Den här körningen överlappar {count} befintliga körning(ar). Passen placeras på samma datum.', draftWarning: 'Utkastrevisioner kan fortfarande ändras.', revisionStatus: { released: 'Publicerad', draft: 'Utkast', archived: 'Arkiverad' },
      invalid: 'Välj en planrevision, ett giltigt startdatum och 1–52 mikrocykler.', create: 'Skapa körning', creating: 'Skapar…', loadError: 'Planerna kunde inte läsas in.', previewError: 'Förhandsgranskningen kunde inte beräknas.', createError: 'Körningen kunde inte skapas.', noPlans: 'Skapa en träningsplan innan du startar en körning.',
    },
  },
}

export default {
  execution: {
    shellStatus: 'UYGULAMA · MASAÜSTÜ', nav: 'Uygulama',
    tabs: { overview: 'Genel bakış', analysis: 'Analiz', timeline: 'Zaman çizelgesi', loads: 'Yükler' },
    common: { kg: 'kg', rir: 'RIR', reps: 'tekrar', today: 'Bugün', close: 'Kapat', save: 'Kaydet', cancel: 'İptal', edit: 'Düzenle', locked: 'Kilitli', loading: 'Uygulama verileri yükleniyor…', marker: 'MARKER.X', reserved: 'ayrılmış' },
    cycle: { microcycle: { label: 'Mikro döngü {ordinal}', short: 'MC{ordinal}' }, week: { label: 'Hafta {ordinal}', short: 'H{ordinal}' } },
    run: {
      metaWeek: '{start} → {end} · {count} × 7 günlük antrenman haftası',
      eyebrow: 'Plan uygulaması', from: '{plan} planından', all: 'Tüm uygulamalar ({count})', new: 'Yeni plan uygulaması', meta: '{start} → {end} · {count} × {days} günlük mikro döngü',
      status: { scheduled: 'Planlandı', active: 'Aktif', cancelled: 'İptal edildi', completed: 'Tamamlandı' }, emptyTitle: 'Henüz plan uygulaması yok', emptyBody: 'Plan uygulaması, antrenman planını gerçek takvim zamanına yerleştirir.', loadError: 'Plan uygulaması yüklenemedi', listError: 'Plan uygulamaları yüklenemedi.',
    },
    status: { scheduled: 'Planlandı', in_progress: 'Devam ediyor', completed: 'Tamamlandı', cancelled: 'İptal edildi', missed: 'Kaçırıldı', today: 'Bugün' }, completion: { as_prescribed: 'Öngörüldüğü gibi', fallback: 'Alternatif' }, classification: { normal: 'Normal', deload: 'Yük azaltma', reload: 'Yük artırma' },
    blocked: {
      previous_exposure_in_progress: 'Önceki maruziyet hâlâ devam ediyor.', previous_exposure_not_performed: 'Önceki öngörülen maruziyet gerçekleştirilmedi.', session_started: 'Bu seans zaten başladı.', no_future_session: 'Bu uygulamada daha sonraki bir seans yok.', run_not_active: 'Bu plan uygulaması aktif değil.', unknown: 'Bu reçete henüz düzenlenemez.',
    },
    overview: {
      positionWeek: 'Hafta {current} / {total} · gün {day} / {days}', thisMicrocycleWeek: 'Bu hafta', prescriptionsWeek: 'Sonraki hafta reçeteleri', noCurrentSessionsWeek: 'Mevcut haftada seans yok.',
      where: 'Bulunduğunuz yer', position: 'Mikro döngü {current} / {total} · gün {day} / {days}', positionSub: 'uygulama günü {runDay} / {runDays}, {left} gün kaldı', thisMicrocycle: 'Bu mikro döngü', sessions: 'Takvimdeki seanslar', analysisEyebrow: 'Antrenman sonrası analiz · sıradaki: MC{mc}', prescriptions: 'Sonraki mikro döngü reçeteleri',
      continue: '{workout} ile devam et', waiting: 'Bekliyor', saved: '{saved} / {total} kaydedildi', latest: 'Son maruziyet · {workout} · {date}', comparison: 'Öngörülen ve gerçekleştirilen', exercise: 'Egzersiz', prescribed: 'Öngörülen', performed: 'Gerçekleştirilen', note: 'Not', adherence: 'Uyum', didPlanHappen: 'Plan gerçekleşti mi?',
      journal: 'Günlük', latestEvents: 'Son olaylar', allEvents: 'Tümü ({count})', observationPlaceholder: 'Bir gözlem kaydet…', log: 'Kaydet', fullCalendar: 'Tam takvim', readOnlyDraft: 'Devam eden performans mobil uygulamadan gelir ve burada salt okunurdur.', noCurrentSessions: 'Mevcut mikro döngüde seans yok.', noExposure: 'Henüz tamamlanmış maruziyet yok.', noEvents: 'Hiçbir olay kaydedilmedi.',
    },
    analysis: {
      queue: 'MC{mc} reçetele', queueToggle: 'Kuyruk', progress: '{saved} / {total} kaydedildi · {locked} kilitli', workoutTrace: 'antrenman birimi geçmişi', ready: 'Hazır', keyboard: 'J / K', notStarted: 'Başlamadı', unsaved: 'Kaydedilmemiş değişiklikler', saved: 'Kaydedildi', locked: 'Kilitli',
      confirmLeave: 'Kaydedilmemiş reçeteler var. Analizden çıkılsın mı? Taslaklar bu tarayıcı oturumunda kalır.', basedOn: 'MC{mc} temelinde · {date}', noSummary: 'Gerçekleştirilmiş maruziyet yok', loadError: 'Analiz yüklenemedi.', traceEyebrow: '{workout} · konum {slot} · egzersiz geçmişi', plan: "plan: {sets} × {min}–{max} {'@'}RIR {rir}",
      continuity: 'MC{from} başlangıcından {revisions} plan revizyonu boyunca tek geçmiş', planNote: 'Plan notu', previous: 'Önceki egzersiz', next: 'Sonraki egzersiz', position: '{current} / {total}', loadStrip: 'Set başına yük · kg', prescribedLegend: 'öngörülen', performedLegend: 'gerçekleştirilen', nextLegend: 'sonraki',
      exposure: 'Maruziyet', set: 'Set {set}', comments: 'Yorumlar', prescription: 'Reçete', actual: 'Gerçek', draft: 'Taslak', setSkipped: 'set atlandı', notSynced: 'senkronize edilmedi', additional: '+EK', missed: 'Kaçırıldı', cancelled: 'İptal edildi', scheduled: 'Planlandı', inProgress: 'Devam ediyor',
      substituted: 'Şununla değiştirildi: {exercise}', exerciseSkipped: 'Egzersiz atlandı — hiçbir set yapılmadı', noComment: 'Yorum yok', revision: 'Plan revizyonu r{from} → r{to}', revisionBody: 'MC{mc} · {date} itibarıyla geçerli. {changes}. Aynı egzersiz geçmişi devam eder.', compare: 'Revizyonları karşılaştır',
      expand: 'MC{mc} ayrıntılarını genişlet', collapse: 'MC{mc} ayrıntılarını daralt', session: 'Seans', recorded: 'Kaydedildi', setComment: 'Set yorumu', performanceAfterSync: 'Performans, seans mobilden senkronize edildikten sonra görünür.',
      flags: { substituted: 'Değiştirildi', skipped: 'Atlandı', additional_set: 'Ek set', reps_below_range: 'Tekrarlar aralığın altında', reps_at_floor: 'Tekrarlar alt sınırda', top_of_range: 'Aralığın üst sınırı', load_reduced: 'Yük azaltıldı', personal_record: 'Kişisel rekor' },
    },
    editor: {
      planOwnedWeek: 'Set sayısı, tekrar aralığı ve RIR plan revizyonu r{revision} içinden gelir. Gelecek haftalar için bunları Plan Oluşturucu’da değiştirin.',
      eyebrow: 'Sonraki reçete', title: '{exercise} · MC{mc}', scheduled: '{workout} · {date} · seans başlayana kadar düzenlenebilir', status: { clean: 'Başlamadı', dirty: 'Kaydedilmedi', saving: 'Kaydediliyor…', saved: 'Kaydedildi', locked: 'Kilitli' },
      basis: 'MC{mc} performansına göre · {date} · tamamlandı', firstExposure: 'İlk maruziyet — önceki performans yok.', evidence: 'Tekrar {reps} · yükler {loads} kg · {top} üst sınırda · {floor} alt sınırda · {deeper} hedef RIR’dan daha derin',
      startFrom: 'Başlangıç', previousPrescription: 'MC{mc} reçetesi', previousPerformance: 'MC{mc} performansı', allMinus: 'tümü −{step}', allPlus: 'tümü +{step}', suggestion: 'Öneri', suggestionNone: 'İlerleme modeli · yok', suggestionBody: 'Bu konuma atanmış bir ilerleme modeli yok.',
      fromPlan: 'Plandan', load: 'Yük kg', last: 'son {load}', comment: 'Set yorumu (isteğe bağlı)', selectSet: 'Set {set} seç', minus: 'Set {set}: {step} kg azalt', plus: 'Set {set}: {step} kg artır', apply: 'Uygula', selected: 'seçilen {count} sete',
      prescriptionComment: 'Reçete yorumu · yalnızca bu maruziyet için', commentPlaceholder: 'Sporcu bir dahaki sefere neye odaklanmalı?', planOwned: 'Set sayısı, tekrar aralığı ve RIR plan revizyonu r{revision} içinden gelir. Gelecek mikro döngüler için bunları Plan Oluşturucu’da değiştirin.',
      discard: 'Vazgeç', save: 'Kaydet', saveNext: 'Kaydet ve sonraki egzersiz', reload: 'Geçmişi yeniden yükle', invalid: 'Set {set}: 0 ile 1000 kg arasında, en fazla 2 ondalıklı geçerli bir yük girin.', fix: 'Kaydetmeden önce geçersiz yükleri düzeltin.', lockedHelp: 'Beklerken geçmişi inceleyin; hazır olma koşulu karşılandığında backend düzenleyicinin kilidini açar.',
      stale_basis: 'Daha yeni bir performans var. Geçmişi yeniden yükleyin; girdiğiniz değerler korunur.', version_conflict: 'Başka biri bu reçeteyi kaydetti. En son sürümü yükleyin; değerleriniz korunur.', prescription_blocked: 'Reçete önceki bir maruziyet tarafından engellendi.', session_locked: 'Seans başladı ve reçetesi kilitlendi.',
      not_next_session: 'Bu artık sonraki seans değil.', set_count_mismatch: 'Plandaki set sayısı değişti. Geçmişi yeniden yükleyin.', invalid_load: 'Bir veya daha fazla yük geçersiz.', genericError: 'Reçete kaydedilemedi.', savedToast: 'Kaydedildi · {exercise} · MC{mc}', noLoadStep: 'Plan bir yük adımı tanımlamıyor; doğrudan giriş kullanın.',
    },
    workout: {
      subtitleWeek: 'her haftanın {day}. günü · {count} egzersiz konumu',
      breadcrumb: 'Analiz / antrenman birimi geçmişi', title: '{workout}', subtitle: 'her mikro döngünün {day}. günü · {count} egzersiz konumu', help: 'Hücre = gerçekleştirilen en yüksek yük · set başına tekrar. Egzersiz geçmişini incelemek için sütun veya hücre açın.', occurrence: 'Oluşum', volume: 'Hacim-yük', comment: 'Antrenman yorumu', prescribed: 'öngörülen', notPerformed: 'gerçekleştirilmedi', empty: 'henüz reçetelenmedi', skipped: 'atlandı', locked: 'kilitli', loadError: 'Antrenman geçmişi yüklenemedi.',
    },
    timeline: {
      eyebrowWeek: 'Antrenman haftası geçmişi · takvim', titleWeek: '{count} antrenman haftası · {start} → {end}', microcyclesWeek: 'Antrenman haftaları', helpMicrocyclesWeek: 'Antrenman haftası başına bir satır, plan günleri soldan sağa.', helpWeeksWeek: 'Pazartesiden pazara takvim haftaları. Antrenman haftası sınırları görünür kalır.',
      eyebrow: 'Mikro döngü geçmişi · takvim', title: '{count} mikro döngü · {start} → {end}', microcycles: 'Mikro döngüler', weeks: 'Takvim haftaları', axis: 'Zaman ekseni', helpMicrocycles: 'Mikro döngü başına bir satır, plan günleri soldan sağa.', helpWeeks: 'Pazartesiden pazara takvim haftaları. Mikro döngü sınırları görünür kalır.',
      attendance: 'Katılım', volume: 'Hacim-yük', note: '+ not', notePlaceholder: 'MC{mc} için gözlem…', saveNote: 'Notu kaydet', selectSession: 'Ayrıntılar için bir seans seçin.', session: 'Seans · MC{mc} · G{day}', prescription: 'Reçete: {state}',
      cancelSession: 'Seansı iptal et…', reclassify: 'İptal edildi olarak sınıflandır…', restore: 'Planlandı olarak geri yükle', restorePast: 'Geçmiş bir seans yeniden planlanamaz.', reason: 'Neden', reasonPlaceholder: 'örn. tatil', logEvent: 'Ayrıca günlük olayı kaydet', confirm: 'Onayla',
      journal: 'Plan uygulaması geçmişi', filters: { all: 'Tümü', plan: 'Plan değişiklikleri', phases: 'Yük aşamaları', breaks: 'Aralar', notes: 'Kayıtlar ve notlar' }, eventType: 'Olay türü', date: 'Tarih', text: 'Metin', eventPlaceholder: 'örn. İki haftadır plato. Toparlanmayı kontrol et.', log: 'Olayı kaydet', noEvents: 'Bu türde olay yok.', eventTypes: { observation: 'Gözlem', vacation: 'Tatil', training_break: 'Antrenman arası' }, system: 'sistem olayı', user: 'kullanıcı tarafından kaydedildi', loadError: 'Zaman çizelgesi yüklenemedi.',
    },
    loads: {
      eyebrow: 'Tüm yükler analizi', title: 'Kaldırışlar birlikte ilerliyor mu?', subtitle: 'Yalnızca tamamlanmış performanslar; değişiklikler, atlamalar ve kaçırılan veya iptal edilen seanslar boşluk bırakır.', traces: 'Egzersiz geçmişleri · {shown} / {total} gösteriliyor', primary: 'Ana kaldırışlar', all: 'Tümü', none: 'Hiçbiri', metric: 'Metrik', scale: 'Ölçek', relative: 'ilk maruziyetin % değeri', kg: 'kg',
      top_set_load: 'En ağır set yükü', mean_set_load: 'Ortalama set yükü', volume_load: 'Hacim-yük', chart: 'Yük ilerleme grafiği', noSelection: 'Egzersiz geçmişi seçilmedi', noSelectionBody: 'Soldan geçmişleri seçin veya tümünü gösterin.', showAll: 'Tümünü göster', byUnit: 'Antrenman birimine göre', loadError: 'Yük analizi yüklenemedi.', gap: 'boşluk: {reason}',
    },
    newRun: {
      countWeek: 'Antrenman haftaları', microcyclesWeek: 'antrenman haftaları',
      back: 'Uygulama’ya dön', title: 'Yeni plan uygulaması', subtitle: 'Bir plan revizyonunu gerçek takvim zamanına taşıyın.', defaultName: '{plan} — uygulama', plan: 'Antrenman planı', revision: 'Plan revizyonu', name: 'Uygulama adı', start: 'Başlangıç tarihi', count: 'Mikro döngüler', end: 'Bitiş (hesaplandı)',
      preview: 'Önizleme · oluşturulacaklar', microcycles: 'mikro döngüler', sessions: 'planlanan seanslar', workouts: 'antrenman geçmişleri', exercises: 'egzersiz geçmişleri', overlap: 'Bu uygulama mevcut {count} uygulamayla çakışıyor. Her iki uygulamanın seansları aynı tarihlere yerleşecek.', draftWarning: 'Taslak revizyonlar hâlâ değişebilir.', revisionStatus: { released: 'Yayınlandı', draft: 'Taslak', archived: 'Arşivlendi' },
      invalid: 'Bir plan revizyonu, geçerli başlangıç tarihi ve 1–52 mikro döngü seçin.', create: 'Uygulama oluştur', creating: 'Oluşturuluyor…', loadError: 'Planlar yüklenemedi.', previewError: 'Uygulama önizlemesi hesaplanamadı.', createError: 'Uygulama oluşturulamadı.', noPlans: 'Bir uygulama başlatmadan önce antrenman planı oluşturun.',
    },
  },
}

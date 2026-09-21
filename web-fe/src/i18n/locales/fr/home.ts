export default {
  home: {
    brand: { name: 'AGONEZ' },
    hero: {
      betaBadge: 'BÊTA PRIVÉE · AUTOMNE 2026',
      waitlist: { label: 'Adresse e-mail', placeholder: "vous{'@'}exemple.fr", button: 'Rejoindre la liste', note: 'Aucun spam. Un seul e-mail lorsque votre invitation sera prête.', submitting: 'Inscription…', joined: 'Inscrit', success: 'Vous êtes sur la liste. Nous vous écrirons lorsque votre invitation sera prête.', error: 'Impossible d’enregistrer votre adresse. Veuillez réessayer.', emailSubject: 'Bêta privée Agonez — demande d’inscription', emailBody: 'Bonjour,\n\nje souhaite rejoindre la liste d’attente de la bêta privée d’Agonez.\n\nMon e-mail : {email}\n\nJe souhaite utiliser Agonez pour :\n' },
      eyebrow: 'ATLAS D’EXERCICES · CRÉATEUR DE PROGRAMMES · SUIVI DE LA PROGRESSION',
      title: 'Comprenez votre entraînement et construisez un programme cohérent.',
      lead: 'Voyez quels muscles votre exercice cible réellement. Organisez ces exercices en programme hebdomadaire et observez ce que ce programme fait à votre corps.',
      ctaPrimary: 'Ouvrir l’Atlas', ctaSecondary: 'Voir l’analyse du programme',
      proof: ['plus de 150 exercices', 'anatomie interactive', 'd’une répétition au microcycle'],
      frameLabel: 'agonez · /plans/4x-week-lu-pp · ANALYSE',
    },
    audiences: {
      eyebrow: '01 · POUR QUI', title: 'Et vous — où en êtes-vous ?',
      beginner: { tag: 'JE DÉBUTE', title: 'Vous commencez et tout paraît inutilement compliqué ?', body: 'Identifiez les muscles sollicités et suivez la technique étape par étape. Essayez le Créateur de programmes.', link: 'Ouvrir l’Atlas des exercices' },
      advanced: { tag: 'JE VEUX ALLER PLUS LOIN', title: 'Vous vous entraînez depuis un moment et voulez vraiment comprendre votre programme ?', body: 'Comparez les variantes, analysez la répartition du stimulus, l’exposition articulaire et la dette de récupération modélisée. Vérifiez si votre programme est optimal.', link: 'Voir comment fonctionne l’Analyse' },
      coach: { tag: 'JE PROGRAMME POUR D’AUTRES', title: 'Vous accompagnez des athlètes ? Vous voulez un outil professionnel ?', body: 'Créez des microcycles avec rôles, substitutions, objectifs, RIR et modèles de progression explicites. Suivez ensuite les progrès de vos athlètes.', link: 'Voir la section entraîneurs' },
    },
    loop: {
      s1: { title: 'Comprendre les exercices', body: 'Technique, muscles et plages de répétitions conseillées.' },
      s2: { title: 'Organiser votre split', body: 'PPL, full body ou structure personnelle — séries, RIR, charge et modèles de progression.' },
      s3: { title: 'Lancer l’analyse', body: 'Répartition du stimulus et récupération musculaire et articulaire — jusqu’à chaque série.' },
      s4: { title: 'Exécuter le programme et suivre les progrès', body: 'Exécution, historique des séries et tendance de force — la prochaine étape de votre progression.' },
    },
    exerciseAtlas: {
      eyebrow: '02 · ATLAS DES EXERCICES', title: 'Pas simplement « développé couché ». Une technique précise avec des hypothèses précises.', body: 'Chaque exercice est décrit comme une variante définie : matériel, placement, trajectoire, amplitude, critères d’échec technique et profil d’exposition modélisé.',
      etuRows: { title: 'L’exposition musculaire en chiffres', body: 'cm² bruts, part de la capacité estimée et intensité relative.' }, etuAnatomy: { title: 'Répartition du stimulus sur le corps', body: 'Carte thermique normalisée selon la FCSA estimée.' }, technique: { title: 'Technique de cette variante', body: 'Placement → exécution → quand s’arrêter.' }, classification: { title: 'Classification de la variante', body: 'Niveau mécanique, source de résistance, schéma d’exécution.' },
      disclaimer: 'valeurs normalisées sur un athlète de référence commun · vos résultats peuvent différer',
    },
    planBuilder: {
      eyebrow: '03 · CRÉATEUR DE PROGRAMMES', title: 'Construisez un programme avec les éléments qui comptent vraiment.', body: 'Définissez les jours d’entraînement et de repos, le rôle de chaque exercice, les objectifs, substitutions, séries, plages de répétitions et RIR. Un programme est un microcycle ordonné, pas une note.',
      roles: { label: 'RÔLES', body: 'Progression principale · progression secondaire · accumulation de volume · accessoire.' }, slot: { label: 'SLOT', body: 'Conservez l’intention du slot même lorsque l’exercice doit être remplacé.' }, rest: { label: 'REPOS', body: 'Un jour de repos n’est pas une case vide — il définit le temps entre les stimuli.' },
      ctaPrimary: 'Ouvrir le Créateur', ctaSecondary: 'Voir l’analyse', panelDays: { left: 'MICROCYCLE ORDONNÉ', right: '7 jours · D01–D07' }, panelSlot: { left: 'SLOT · PRESCRIPTION DES SÉRIES', right: 'rôle · exercice par défaut · RIR' },
    },
    planAnalysis: {
      eyebrow: '04 · ANALYSE DU PROGRAMME', title: 'Un programme est plus que la somme de ses séries.', body: 'Analysez un brouillon enregistré pour voir où va le stimulus, quels muscles réalisent un travail ciblé ou indirect et s’ils peuvent récupérer entre les jours.',
      strip: { left: 'MICROCYCLE · LIMITES DES JOURS', right: 'analyse du brouillon enregistré · actualiser après modification' }, recovery: { title: 'Récupération après l’entraînement', meta: 'hours_to_fresh' }, ranking: { title: 'Nombre hebdomadaire de séries par muscle', meta: 'ETU/cm²/7d' }, debts: { title: 'État de récupération musculaire', body: 'Quand le muscle sera-t-il à nouveau frais ?' }, targeted: { title: 'Travail ciblé et indirect', body: 'Voyez ce que le programme devait entraîner, mais aussi le travail indirect créé par les exercices choisis.' }, provenance: { title: 'Chaque total a une source', body: 'Chaque résultat renvoie au jour, à l’exercice et à la série, avec les répétitions effectives et les paramètres du modèle.' },
      disclaimer: 'sortie du modèle · ni courbatures, ni temps de guérison tissulaire, ni évaluation du risque de blessure',
    },
    muscleAtlas: {
      eyebrow: '05 · ATLAS DES MUSCLES', title: 'Comprenez un muscle avant de compter ses séries.', body: 'Anatomie, fonction, architecture, répartition estimée des types de fibres et meilleurs exercices — au même endroit.',
      specs: [{ k: 'MORPHOLOGIE', v: 'masse, volume' }, { k: 'ARCHITECTURE', v: 'pennation, longueur des fibres' }, { k: 'FIBRES', v: 'répartition estimée des types I et II' }, { k: 'FCSA', v: 'unité de force' }],
      note: 'La FCSA n’est ni un nombre de fibres ni un score de potentiel hypertrophique. C’est une section de transmission de force estimée, utilisée comme dénominateur commun.', link: 'Passer du muscle aux exercices',
    },
    features: {
      eyebrow: '06 · AUTRES POSSIBILITÉS', title: 'Le reste du système, en bref',
      technique: { title: 'Bibliothèque technique', body: 'Placement, mouvement, amplitude, consignes, échec technique, RIR et erreurs fréquentes.' }, io: { title: 'Import / export du programme', body: 'Téléchargez ou importez facilement un programme au format texte. Avec l’IA, importer vos propres programmes devient simple.' }, mobile: { title: 'Entraînement mobile', body: 'Ouvrez l’application pendant l’entraînement et laissez-la vous guider tout au long de la séance.' }, progress: { title: 'Suivi des progrès', body: 'Historique d’exécution, tendances de force et modèles de progression automatisés — aussi pour l’accompagnement.' }, knowledge: { title: 'Base de connaissances', body: 'Une base de connaissances sous forme de blog fondé sur la science. L’Atlas couvrira également les mouvements et les articulations.' },
    },
    model: {
      eyebrow: '07 · SOUS LE CAPOT', title: 'Nous ne mesurons pas la biologie à travers un écran. Nous construisons un modèle de décision explicite.', body: 'L’entraînement de résistance se déroule dans l’incertitude. Agonez organise les hypothèses, estime les conséquences d’un programme et montre l’origine du résultat. Sans mesure, nous parlons de modèle.',
      chain: ['exercice', 'muscles', 'stimulus mécanique', 'récupération', 'semaine du programme', 'progression'], expandHint: 'DÉPLIEZ POUR VOIR LES DÉTAILS',
      etu: { title: 'ETU', summary: 'Part du stimulus de tension d’une répétition effective attribuée à un muscle.', body: 'Un exercice ne se contente pas « d’entraîner les pectoraux ». Il possède un profil : une partie de la tension va aux muscles moteurs, une autre aux stabilisateurs. L’ETU (Effective Tension Unit) estime cette répartition pour une répétition effective afin de comparer numériquement deux variantes du même mouvement.', caveat: 'Ce n’est ni de l’EMG, ni un pourcentage d’activation, ni une mesure d’hypertrophie.' },
      fcsa: { title: 'FCSA', summary: 'Un dénominateur commun pour comparer un grand et un petit muscle sur la même échelle.', caveat: 'Il s’agit d’une demande mécanique, pas de fatigue ni d’un nombre de fibres.' },
      recovery: { title: 'MRU · JRU', summary: 'Dette musculaire et articulaire modélisée : elle augmente après une série et diminue entre les séances.', body: 'Chaque série ajoute une dette locale aux muscles, d’autant plus forte qu’elle approche de l’échec technique. Cette dette diminue avec le temps : espacer les stimuli d’un même muscle fait donc partie du programme. La JRU applique le même principe aux articulations.', caveat: 'Un outil comparatif, pas une horloge biologique ni une évaluation du risque de blessure.' },
      reference: { title: 'Athlète de référence', summary: 'Les métriques de l’Atlas sont calibrées sur une base explicitement décrite.', caveat: 'Votre point de départ peut différer sensiblement, tandis que les relations relatives ne devraient varier que très peu.' },
      limits: { title: 'Limites du modèle', summary: 'Ce que le modèle ne voit pas — indiqué clairement, sans le cacher.', note: 'la version du modèle, les hypothèses et les diagnostics restent visibles dans l’application' },
    },
    coaches: {
      eyebrow: '08 · POUR LES ENTRAÎNEURS', title: 'Accompagnez plus d’athlètes sans renoncer à la qualité du suivi.', body: 'Un modèle de microcycle, des substitutions prêtes et un audit automatique remplacent une feuille de calcul reconstruite pour chaque client. Le temps de ressaisie reste disponible pour le coaching.',
      reuse: { title: 'Un programme réutilisable', body: 'Un microcycle construit une fois — avec rôles, séries et RIR — devient le point de départ du prochain athlète.' }, swap: { title: 'Une substitution en quelques secondes', body: 'Une machine occupée ou une articulation sensible ne détruit pas le programme : le slot conserve son intention.' }, audit: { title: 'Un audit plutôt qu’un comptage manuel', body: 'Répartition du stimulus, travail indirect, dette modélisée entre les jours et progression de la charge se calculent automatiquement ; vous jugez le résultat.' }, argument: { title: 'Partage facile', body: 'Envoyez un lien à l’athlète : il obtient un programme prêt à ouvrir dans l’application.' }, adaptation: { title: 'Chaque athlète est différent', body: 'Vous voyez qu’un athlète ne récupère pas avec le programme ? Au fil du temps, vous apprenez à le connaître et pouvez adapter précisément les paramètres du modèle à son profil.' }, cta: 'Construire votre premier modèle', note: 'Les comptes athlètes et l’historique d’exécution sont prévus — aujourd’hui, vous travaillez sur vos propres programmes.',
    },
    roadmap: {
      eyebrow: '09 · LA SUITE', title: 'Aujourd’hui : conception et analyse. Demain : exécution et accompagnement dans le temps.',
      athlete: { title: 'Accompagnement des athlètes', body: 'La prochaine étape reliera le programme à l’historique d’exécution : charges, répétitions, RIR, changements d’exercices, deloads et tendances e1RM.', flow: ['Programme', 'Prescription', 'Exécution', 'Historique'] },
      mobile: { title: 'Entraînement mobile', body: 'Pendant une séance, la prochaine série compte. Le mode prévu affichera la séance du jour et donnera un accès rapide à la technique.', flow: ['Séance du jour', 'Saisir l’exécution', 'Technique'] },
    },
    cta: { eyebrow: 'UNE INVITATION OUVERTE', title: 'Aidez l’humanité à atteindre l’excellence dans l’entraînement.', body: 'Agonez en est à ses débuts. Nous le construisons au croisement de l’entraînement, de la science, de l’ingénierie et du produit.', bodySecondary: 'Si vous travaillez dans l’un de ces domaines et souhaitez co-créer un outil fondé sur des problèmes réels, une expertise métier et des retours critiques, nous vous recherchons.', rolesLabel: 'Personnes et perspectives que nous souhaitons rencontrer', roles: ['Coachs personnels', 'Athlètes', 'Biomécaniciens', 'Sciences du sport', 'Produit et ingénierie', 'UX / recherche', 'Marketing', 'Premiers partenaires et early adopters'], action: 'Échangeons', note: 'Nous sommes ouverts aux échanges ciblés et aux collaborations bien définies. Ouvre votre application e-mail.', emailSubject: 'Construisons Agonez ensemble', emailBody: 'Bonjour,\n\nje souhaite échanger au sujet d’une contribution à Agonez.\n\nMon expérience ou mon idée :\n' },
    footer: { navigation: 'Navigation de la page d’accueil', links: { exerciseAtlas: 'Atlas des exercices', muscleAtlas: 'Atlas des muscles', planBuilder: 'Créateur de programmes', analysis: 'Analyse', model: 'Modèle' }, disclaimer: 'Les valeurs Agonez sont des estimations modélisées fondées sur des hypothèses explicites. Elles ne mesurent pas votre organisme et ne constituent pas un avis médical.' },
    badges: { comingSoon: 'BIENTÔT', experimental: 'MODÈLE EXPÉRIMENTAL' },
  },
}

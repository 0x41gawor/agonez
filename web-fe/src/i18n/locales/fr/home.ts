export default {
  home: {
    brand: { name: 'AGONEZ' },
    hero: {
      eyebrow: 'ATLAS D’EXERCICES · CRÉATEUR DE PROGRAMMES · ANALYSE D’ENTRAÎNEMENT',
      title: 'Comprenez votre entraînement et construisez un programme cohérent.',
      lead: 'Voyez ce que fait réellement un exercice, organisez vos exercices en programme hebdomadaire et observez ses effets modélisés sur le corps. Les réponses restent simples — et vous pouvez approfondir leur origine.',
      ctaPrimary: 'Ouvrir l’Atlas', ctaSecondary: 'Voir l’analyse du programme',
      proof: ['plus de 150 techniques documentées', 'anatomie interactive', 'd’une série au microcycle'],
      frameLabel: 'agonez · /plans/4x-week-lu-pp · ANALYSE',
    },
    audiences: {
      eyebrow: '01 · POUR QUI', title: 'Et vous — où en êtes-vous ?',
      beginner: { tag: 'JE DÉBUTE', title: 'Vous venez de commencer et tout paraît inutilement compliqué ?', body: 'Identifiez les muscles sollicités, suivez la technique étape par étape et comprenez comment séries, répétitions et RIR forment un programme.', link: 'Ouvrir l’Atlas des exercices' },
      advanced: { tag: 'JE VEUX ALLER PLUS LOIN', title: 'Vous vous entraînez depuis un moment et voulez vraiment comprendre votre programme ?', body: 'Comparez les variantes, analysez la répartition du stimulus, l’exposition articulaire et la dette de récupération modélisée, jusqu’à chaque série.', link: 'Voir comment fonctionne l’Analyse' },
      coach: { tag: 'JE PROGRAMME POUR D’AUTRES', title: 'Vous accompagnez des athlètes ? Concevez et analysez les programmes dans un même système.', body: 'Créez des microcycles avec rôles, substitutions, objectifs, RIR et modèles de progression explicites, puis analysez le programme enregistré.', link: 'Voir la section entraîneurs' },
    },
    loop: {
      s1: { title: 'Comprendre l’exercice', body: 'Technique, muscles et plages de répétitions conseillées.' },
      s2: { title: 'Organiser votre split', body: 'PPL, full body ou structure personnelle — jours, repos, séries et RIR.' },
      s3: { title: 'Lancer l’analyse', body: 'Répartition du stimulus, récupération et exposition articulaire — jusqu’à la série.' },
      s4: { title: 'Exécuter le programme et suivre les progrès', body: 'Exécution, historique des séries et tendance de force — la prochaine étape.' },
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
      eyebrow: '04 · ANALYSE DU PROGRAMME', title: 'Un programme est plus que la somme de ses séries.', body: 'Analysez un brouillon enregistré pour voir où va le stimulus, quels muscles réalisent un travail ciblé ou indirect et comment le modèle reporte la dette de récupération entre les jours.',
      strip: { left: 'MICROCYCLE · LIMITES DES JOURS', right: 'analyse du brouillon enregistré · actualiser après modification' }, recovery: { title: 'Récupération locale après l’entraînement', meta: 'hours_to_fresh' }, ranking: { title: 'Répartition hebdomadaire du stimulus', meta: 'ETU/cm²/7d' }, debts: { title: 'Dettes modélisées les plus fortes', body: 'État de préparation à la limite du jour.' }, targeted: { title: 'Travail ciblé et indirect', body: 'Voyez ce que le programme devait entraîner, mais aussi le travail indirect créé par les exercices choisis.' }, provenance: { title: 'Chaque total a une source', body: 'Chaque résultat renvoie au jour, à l’exercice et à la série, avec les répétitions effectives et les paramètres du modèle.' },
      disclaimer: 'sortie du modèle · ni courbatures, ni temps de guérison tissulaire, ni évaluation du risque de blessure',
    },
    muscleAtlas: {
      eyebrow: '05 · ATLAS DES MUSCLES', title: 'Comprenez un muscle avant de compter ses séries.', body: 'Anatomie, fonction, architecture, répartition estimée des types de fibres et exercices offrant la plus forte exposition modélisée — au même endroit.',
      specs: [{ k: 'MORPHOLOGIE', v: 'masse, volume' }, { k: 'ARCHITECTURE', v: 'pennation, longueur des fibres' }, { k: 'FIBRES', v: 'répartition estimée' }, { k: 'FCSA', v: 'référence de capacité' }],
      note: 'La FCSA n’est ni un nombre de fibres ni un score de potentiel hypertrophique. C’est une section de transmission de force estimée, utilisée comme dénominateur commun.', link: 'Passer du muscle aux exercices',
    },
    features: {
      eyebrow: '06 · AUTRES POSSIBILITÉS', title: 'Le reste du système, en bref',
      technique: { title: 'Bibliothèque technique', body: 'Placement, mouvement, amplitude, consignes, échec technique, RIR et erreurs fréquentes.' }, io: { title: 'Import / export du programme', body: 'Exportez une structure simplifiée pour une analyse externe et réimportez un document validé.' }, mobile: { title: 'Mode entraînement mobile', body: 'La séance du jour et la technique à portée de main, sans revenir sur ordinateur.' }, progress: { title: 'Suivi des progrès', body: 'Historique d’exécution, tendances de force et modèles de progression automatisés — aussi pour l’accompagnement.' }, knowledge: { title: 'Base de connaissances', body: 'Les articles musculaires fonctionnent déjà ; la base en développement couvrira aussi les articulations et se reliera à l’Atlas et à l’Analyse.' },
    },
    model: {
      eyebrow: '07 · SOUS LE CAPOT', title: 'Nous ne mesurons pas la biologie à travers un écran. Nous construisons un modèle de décision explicite.', body: 'L’entraînement de résistance se déroule dans l’incertitude. Agonez organise les hypothèses, estime les conséquences d’un programme et montre l’origine du résultat. Sans mesure, nous parlons de modèle.',
      chain: ['exercice', 'muscles', 'stimulus mécanique', 'récupération', 'semaine du programme', 'progression'], expandHint: 'DÉPLIEZ POUR VOIR LES DÉTAILS',
      etu: { title: 'ETU', summary: 'Part du stimulus de tension d’une répétition effective attribuée à un muscle.', caveat: 'Ce n’est ni de l’EMG, ni un pourcentage d’activation, ni une mesure d’hypertrophie.' },
      fcsa: { title: 'FCSA', summary: 'Un dénominateur commun pour comparer un grand et un petit muscle sur la même échelle.', caveat: 'Il s’agit d’une demande mécanique, pas de fatigue ni d’un nombre de fibres.' },
      recovery: { title: 'MRU · JRU', summary: 'Dette musculaire et articulaire modélisée : elle augmente après une série et diminue entre les séances.', caveat: 'Un outil comparatif, pas une horloge biologique ni une évaluation du risque de blessure.' },
      reference: { title: 'Athlète de référence', summary: 'Les métriques de l’Atlas sont calibrées sur une base explicitement décrite.', caveat: 'Vos propres chiffres peuvent différer sensiblement.' },
      limits: { title: 'Limites du modèle', summary: 'Ce que le modèle ne voit pas — indiqué clairement, sans le cacher.', note: 'la version du modèle, les hypothèses et les diagnostics restent visibles dans l’application' },
    },
    coaches: {
      eyebrow: '08 · POUR LES ENTRAÎNEURS', title: 'Accompagnez plus d’athlètes sans renoncer à la qualité des programmes.', body: 'Un modèle de microcycle, des substitutions prêtes et un audit automatique remplacent une feuille de calcul reconstruite pour chaque client. Le temps de ressaisie reste disponible pour le coaching.',
      reuse: { title: 'Un programme réutilisable', body: 'Un microcycle construit une fois — avec rôles, séries et RIR — devient le point de départ du prochain athlète.' }, swap: { title: 'Une substitution en quelques secondes', body: 'Une machine occupée ou une articulation sensible ne détruit pas le programme : le slot conserve son intention.' }, audit: { title: 'Un audit plutôt qu’un comptage manuel', body: 'Répartition du stimulus, travail indirect et dette modélisée se calculent ; vous jugez le résultat.' }, argument: { title: 'Une explication pour votre athlète', body: 'Montrez pourquoi le programme est construit ainsi. L’export JSON emporte toute sa structure.' }, cta: 'Construire votre premier modèle', note: 'Les comptes athlètes et l’historique d’exécution sont prévus — aujourd’hui, vous travaillez sur vos propres programmes.',
    },
    roadmap: {
      eyebrow: '09 · LA SUITE', title: 'Aujourd’hui : conception et analyse. Ensuite : exécution et accompagnement dans le temps.',
      athlete: { title: 'Accompagnement des athlètes', body: 'La prochaine étape reliera le programme à l’historique d’exécution : charges, répétitions, RIR, changements d’exercices, deloads et tendances e1RM.', flow: ['Programme', 'Prescription', 'Exécution', 'Historique'] },
      mobile: { title: 'Mode entraînement mobile', body: 'Pendant une séance, la prochaine série compte. Le mode prévu affichera la séance du jour et donnera un accès rapide à la technique.', flow: ['Séance du jour', 'Saisir l’exécution', 'Technique'] },
    },
    cta: { title: 'Commencez par un exercice. Voyez jusqu’où vous pouvez aller.', body: 'De la compréhension du mouvement à la décision de programmation — des réponses simples en surface, des modèles explicites dessous.', primary: 'Ouvrir l’Atlas des exercices', secondary: 'Construire un brouillon' },
    footer: { navigation: 'Navigation de la page d’accueil', links: { exerciseAtlas: 'Atlas des exercices', muscleAtlas: 'Atlas des muscles', planBuilder: 'Créateur de programmes', analysis: 'Analyse', model: 'Modèle' }, disclaimer: 'Les valeurs Agonez sont des estimations modélisées fondées sur des hypothèses explicites. Elles ne mesurent pas votre organisme et ne constituent pas un avis médical.' },
    badges: { comingSoon: 'BIENTÔT', experimental: 'MODÈLE EXPÉRIMENTAL' },
  },
}

export default {
  app: {
    home: "Accueil d’Agonez Atlas", primaryNavigation: 'Navigation principale', atlas: 'Atlas', myPlans: 'Mes plans',
    dashboard: 'Tableau de bord', plannedModule: 'Module prévu', exercisesCount: '{count} exercices',
    musclesCount: '{count} muscles', planCreatorDraft: 'CRÉATEUR DE PLAN · BROUILLON',
  },
  locale: {
    label: 'Langue', changeTo: 'Passer la langue à {language}', english: 'English', polish: 'Polski',
    french: 'Français', spanish: 'Español', german: 'Deutsch',
    italian: 'Italiano', portugueseBrazil: 'Português (Brasil)', swedish: 'Svenska', dutch: 'Nederlands', ukrainian: 'Українська', turkish: 'Türkçe',
  },
  theme: { dark: 'Sombre', light: 'Clair', switchTo: 'Passer au thème {theme}' },
  common: {
    close: 'Fermer', dismiss: 'Masquer', retry: 'Réessayer', remove: 'Supprimer', open: 'Ouvrir', loading: 'Chargement…',
    noDescription: 'Aucune description', externalLink: 'lien externe', notAvailable: 'Indisponible', yes: 'Oui', no: 'Non',
    previous: 'Précédent', next: 'Suivant', page: 'Page', of: 'sur', entries: '{count} entrées',
    visualUnavailable: 'visuel indisponible', loadingDetail: 'Chargement des détails', loadingAtlas: 'Chargement des données de l’Atlas', plan: 'Plan',
  },
  errors: {
    requestFailed: 'La requête Agonez a échoué.', atlasUnavailable: 'Les données de l’Atlas sont indisponibles.',
    metadataUnavailable: 'Les métadonnées de l’Atlas sont indisponibles.', atlasLoadTitle: "Impossible de charger l’Atlas",
    atlasLoadMessage: "Vérifiez que l’API fonctionne, puis réessayez.", catalogUnavailable: "Le catalogue de l’Atlas est indisponible.",
  },
  notFound: {
    title: "Cette page de l’Atlas n’existe pas.", message: 'La route a peut-être changé ou le lien est incomplet.',
    action: "Retourner à l’Atlas",
  },
}

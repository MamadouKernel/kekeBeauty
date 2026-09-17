# Suivi du lot PWA 01

Projet : https://stitch.withgoogle.com/projects/9777037697910174912

## Réalisé dans Stitch

- Création des écrans « PWA 01 — Explorer », « PWA 01 — Chargement », « PWA 01 — Aucun résultat » et « PWA 01 — Hors connexion ».
- Révision générée pour limiter le viewport à 390 × 844, supprimer les notes de démonstration des interfaces et simplifier les états vide et hors connexion.
- Création d'une annotation externe pour identifier les données de démonstration.
- Vérification visuelle d'Explorer révisé : photos affichées, recherche, catégories, choix liste/carte et navigation basse. Le contrôle de dimensions Stitch affiche 390 × 844.

Les itérations initiales et révisées restent sur le canevas. La version Explorer à retenir est celle de 390 × 844, pas la première de 390 × 2271. Aucun ancien élément n'a été supprimé par nos actions.

## Avancement du 17 septembre 2026

- Création de « PWA 01 — Filtres », « PWA 01 — Fiche établissement », « PWA 01 — Fiche sans réservation » et « PWA 01 — Chargement (Harmonisé) ».
- Le document « Prototype PWA 01 — Découverte mobile » décrit des liens mais ne constitue pas un prototype natif navigable vérifié.
- Création distincte de « PWA 01 — Démo navigable » : plusieurs vues interactives dans un écran HTML. Le cadre Stitch indique 1280 × 868 ; il contient un gabarit mobile, et ne remplace pas une déclinaison ordinateur.
- Tests effectués au clavier dans la démo : ouverture des filtres, désélection de trois catégories, passage de quatre à deux établissements, ouverture de la première fiche, galerie de 1/3 à 2/3, retour conservant les deux résultats, ouverture de la fiche sans réservation.
- Recherche sans correspondance : zéro résultat et état vide affichés. Réinitialisation : retour aux quatre établissements. La démo a été laissée dans cet état initial.

## Réserves et suite

- Une variante de chargement harmonisée a été générée ; comparer visuellement l'ensemble des en-têtes avant validation finale.
- La conformité complète des contrastes, cibles tactiles et comportements de défilement n'est pas encore mesurée.
- Le parcours de la démo a été testé au clavier uniquement. Les clics sur le canevas imbriqué ont rencontré des erreurs de coordonnées ; la recette tactile et souris reste à faire.
- Plusieurs boutons icônes de la démo n'ont pas de nom accessible, notamment filtres, retour et galerie. Ajouter leurs libellés avant intégration.
- Le contrôle des images après navigation a relevé une image « Photo salon » non chargée. Les médias restent à fiabiliser.
- La fiche sans réservation ajoute encore une exclusivité téléphonique non spécifiée. Conserver seulement « Contactez cet établissement pour connaître ses disponibilités ».
- Vérifier la cohérence géographique des options et leur cascade. Certaines options générées ne sont pas un référentiel géographique validé.
- Le choix Liste/Carte et les accès Mes RDV/Compte ne sont pas validés. La déclinaison ordinateur reste à réaliser.
- Les noms et photos sont des contenus de démonstration, non des établissements réels validés.
- Aucun code PWA n'a été intégré dans Blazor pendant ce lot. Le DESIGN.md complet n'a pas été importé : ses règles utiles au lot ont été transmises dans le brief de génération.

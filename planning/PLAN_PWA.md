# Plan de réalisation PWA — Keke Beauty

## Décision et point de départ

La cible PWA a été confirmée par l'utilisateur. Le référentiel `DESIGN.md` est mis à jour. L'application Blazor existante reste la base ; consulter `ETAT_IMPLEMENTATION.md` pour les fonctionnalités réellement vérifiées. Ce plan n'annonce ni livraison PWA ni modification du projet Stitch distant.

## Lots et critères de sortie

| Lot | Travail | Critère de sortie | État |
| --- | --- | --- | --- |
| 0 | Formaliser PWA, cache, connexion, installation et mises à jour | Règles intégrées au DESIGN.md | Réalisé dans la documentation |
| 1 | Maquettes annuaire, filtres, fiche établissement | Mobile et ordinateur, variantes et parcours cohérents | Explorer, variantes, filtres et fiches créés ; démo testée au clavier ; réserves visuelles/accessibilité et ordinateur à traiter |
| 2 | Socle PWA dans Blazor | Manifeste, icônes, service worker limité, repli hors ligne ; recette navigateur et installé | Manifeste, icône, service worker limité et repli hors ligne réalisés ; installation sur appareil réel à recetter |
| 3 | Intégration du lot client | Recherche et fiche reliées aux données, états réseau et réservation conditionnelle | Recherche texte et catégorie reliées à PostgreSQL ; fiche/réservation existantes à harmoniser avec Stitch |
| 4 | Compléter le parcours rendez-vous | OTP fournisseur, créneaux, demande, décision, report et notifications vérifiés | À réaliser |
| 5 | Espace partenaire | KYC privé, prestations, horaires, agenda et habilitations utilisables | À réaliser |
| 6 | Abonnements et administration | Facturation, intégration paiement, validation KYC et paramétrage vérifiés | À réaliser |
| 7 | Recette et déploiement | Accessibilité, sécurité, appareils réels, réseau dégradé, mise à jour et exploitation vérifiés | À réaliser |

Le choix du logo final et ses fichiers restent à confirmer. Il ne bloque pas les premières maquettes : employer la signature textuelle Keke Beauty tant que l'asset n'est pas approuvé. Les fournisseurs SMS et paiement demandent une intégration réelle et leurs accès avant une recette complète.

## Premier lot de maquettes

Brief détaillé : `design/stitch/BRIEF_LOT_01_PWA.md`. Générer d'abord les trois vues mobiles, puis leurs adaptations ordinateur ; inspecter chaque écran avant d'étendre la direction visuelle aux autres parcours.

L'installation et les notifications dépendent des navigateurs ciblés. Vérifier les documentations officielles au moment de leur implémentation et effectuer une recette Android et iOS sur appareils réels ; ne pas présenter une maquette comme preuve de compatibilité.

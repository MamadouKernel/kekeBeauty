# Keke Beauty — Modèle logique des données initial

Actualisation : voir [DECISIONS_METIER_V1.md](DECISIONS_METIER_V1.md) pour les extensions proposées de réservation, ressources, politiques versionnées et encaissements en espèces. Les propositions structurelles V0 ci-dessous ne constituent plus la cible complète ; réconciliation et audit requis avant migration.

Statut : **version de travail**. Ce MLD transforme les entités et associations du MCD en relations, sans types SQL. Les relations du domaine annuaire et KYC sont détaillées ; les relations de réservation et de facturation restent des propositions structurales dont les cardinalités et états ne sont pas validés. Aucune migration n'en découle encore.

Notation : `PK` est la clé primaire, `FK` une clé étrangère ; `UK` est une clé candidate supplémentaire rendue unique. Un `id` technique n'autorise pas à ignorer les dépendances fonctionnelles de la relation.

## Relations de référence et d'annuaire

| Relation | Attributs logiques | Clés et liens | Source |
|---|---|---|---|
| PAYS | `pays_id`, `nom` | PK `pays_id` ; unicité de `nom` à confirmer selon référentiel | DD-011 |
| REGION | `region_id`, `pays_id`, `nom` | PK `region_id` ; FK `pays_id` → PAYS | DD-012 |
| VILLE | `ville_id`, `region_id`, `nom` | PK `ville_id` ; FK `region_id` → REGION | DD-013 |
| COMMUNE | `commune_id`, `ville_id`, `nom` | PK `commune_id` ; FK `ville_id` → VILLE | DD-014 |
| CATEGORIE | `categorie_id`, `nom`, `etat` | PK `categorie_id` | DD-010 |
| COMPTE | `compte_id`, `telephone_normalise`, `telephone_verifie_le`, `etat` | PK `compte_id` ; UK `telephone_normalise` pour les comptes actifs selon politique à valider | DD-001/028 |
| ROLE | `role_id`, `code`, `libelle` | PK `role_id` ; UK `code` | DD-028 |
| COMPTE_ROLE | `compte_id`, `role_id` | PK (`compte_id`, `role_id`) ; FK vers COMPTE et ROLE | DD-028, cumul de rôles à confirmer |
| GERANT | `gerant_id`, `compte_id`, `nom_declare` | PK `gerant_id` ; FK `compte_id` → COMPTE ; UK `compte_id` si un compte représente au plus un gérant | DD-003 ; hypothèse |
| ETABLISSEMENT | `etablissement_id`, `commune_id`, `nom`, `description`, `telephone_service`, `latitude`, `longitude`, `etat_publication` | PK `etablissement_id` ; FK `commune_id` → COMMUNE si commune disponible | DD-005 à DD-009/030 ; rattachement territorial à confirmer |
| GERANT_ETABLISSEMENT | `gerant_id`, `etablissement_id` | PK (`gerant_id`, `etablissement_id`) ; FK vers GERANT et ETABLISSEMENT | DD-029 ; cardinalités à confirmer |
| ETABLISSEMENT_CATEGORIE | `etablissement_id`, `categorie_id` | PK (`etablissement_id`, `categorie_id`) ; FK vers ETABLISSEMENT et CATEGORIE | DD-010 ; pluralité à confirmer |
| MEDIA | `media_id`, `etablissement_id`, `nature`, `reference_fichier`, `ordre`, `etat` | PK `media_id` ; FK `etablissement_id` → ETABLISSEMENT ; unicité de `reference_fichier` et de (`etablissement_id`, `ordre`) à confirmer | DD-015 |
| PRESTATION | `prestation_id`, `etablissement_id`, `nom`, `description`, `etat` | PK `prestation_id` ; FK `etablissement_id` → ETABLISSEMENT | DD-016 |
| TARIF_PRESTATION | `tarif_id`, `prestation_id`, `montant`, `devise`, `date_effet` | PK `tarif_id` ; FK `prestation_id` → PRESTATION ; UK (`prestation_id`, `date_effet`) si historique retenu | DD-017 ; historique à confirmer |
| PLAGE_OUVERTURE | `plage_id`, `etablissement_id`, `jour_semaine`, `heure_debut`, `heure_fin` | PK `plage_id` ; FK `etablissement_id` → ETABLISSEMENT | DD-008/032 |
| EXCEPTION_OUVERTURE | `exception_id`, `etablissement_id`, `date_concernee`, `heure_debut`, `heure_fin`, `ferme` | PK `exception_id` ; FK `etablissement_id` → ETABLISSEMENT | DD-008/033 ; une date peut avoir plusieurs plages |
| DOSSIER_KYC | `dossier_id`, `gerant_id`, `etat`, `soumis_le`, `decide_le`, `decide_par_compte_id`, `motif_decision` | PK `dossier_id` ; FK `gerant_id` → GERANT ; FK `decide_par_compte_id` → COMPTE | DD-027/031 ; décisions et resoumission à confirmer |
| JUSTIFICATIF_KYC | `justificatif_id`, `dossier_id`, `type_piece`, `reference_fichier_privee`, `etat` | PK `justificatif_id` ; FK `dossier_id` → DOSSIER_KYC | DD-004 ; stockage privé |

La hiérarchie géographique est obtenue par les liens COMMUNE → VILLE → REGION → PAYS. `ETABLISSEMENT` ne contient ni nom de commune, ni nom de ville, ni nom de région, ni nom de pays : ces libellés ne dépendent pas de son identifiant. Les médias, prestations et plages multiples sont des lignes séparées.

## Relations structurelles encore soumises aux règles métier

| Domaine | Relations envisagées | Pourquoi elles restent ouvertes |
|---|---|---|
| Disponibilité | `RESSOURCE`, `AFFECTATION_PRESTATION_RESSOURCE`, `PLAGE_RESSOURCE` **ou** `CAPACITE_INTERVALLE` | Employé, cabine ou capacité globale (question 09) ; le choix change les clés et cardinalités. |
| Rendez-vous | `RENDEZ_VOUS(rdv_id, client_compte_id, etablissement_id, prestation_id, debut, fin, etat)`, `EVENEMENT_RDV(evenement_id, rdv_id, acteur_compte_id, type, survenu_le, motif)`, `NOTIFICATION(notification_id, evenement_id, destinataire_compte_id, canal, etat_envoi)` | Une ou plusieurs prestations, moment de blocage, acteurs et transitions (questions 10 à 13). |
| Offres | `OFFRE(offre_id, nom, etat)`, `FONCTIONNALITE(fonctionnalite_id, code)`, `OFFRE_FONCTIONNALITE(offre_id, fonctionnalite_id)`, `TARIF_OFFRE(tarif_offre_id, offre_id, periodicite, montant, devise, date_effet)` | Définition des offres, tarifs et périodes ; droits à confirmer. |
| Souscription | `CONTRAT(contrat_id, etablissement_id, offre_id, debut, fin_engagement, periodicite, montant_accepte, devise_acceptee, etat)`, `ECHEANCE(echeance_id, contrat_id, debut_periode, fin_periode, montant_du, devise, etat)`, `PAIEMENT(paiement_id, echeance_id, reference_fournisseur, montant, devise, canal, etat)` | Renouvellement, grâce, taxes, fractionnement et imputation à confirmer (questions 14 à 17). |

Le montant accepté sur un contrat et le montant dû sur une échéance sont des **faits datés distincts** du tarif courant d'une offre. Leur conservation n'est pas une dépendance transitive à `OFFRE` : changer le prix de l'offre ne change pas rétroactivement le contrat. Il faut toutefois définir la règle de calcul et de révision avant de figer ces relations.

## Audit des trois premières formes normales sur les relations détaillées

La preuve porte sur les dépendances connues du métier. Chaque ligne indique les clés candidates connues et les dépendances non triviales à vérifier. Des clés naturelles supplémentaires pourront apparaître lors de la validation du référentiel ou des politiques d'unicité.

| Relations | Clés candidates connues | Dépendances fonctionnelles principales | Contrôle 1FN, 2FN et 3FN |
|---|---|---|---|
| PAYS, REGION, VILLE, COMMUNE | Leur identifiant respectif ; autres clés à confirmer | Identifiant → attributs propres et lien vers le niveau parent | Valeurs simples ; clé simple donc pas de dépendance partielle ; aucun nom du parent stocké, donc pas de transitivité connue. |
| CATEGORIE | `categorie_id` | `categorie_id` → nom, état | Valeurs simples ; clé simple ; aucun attribut dérivé du nom d'une autre relation. |
| COMPTE | `compte_id` ; `telephone_normalise` si unicité confirmée | `compte_id` → téléphone, vérification, état ; téléphone → compte si UK retenue | Téléphone unique et élémentaire ; clés simples ; aucun attribut d'un rôle ou d'un gérant stocké ici. |
| ROLE | `role_id`, `code` | Chacune des clés → libellé | Code et libellé élémentaires ; clés simples ; pas de dépendance non-clé → non-clé connue. |
| COMPTE_ROLE, GERANT_ETABLISSEMENT, ETABLISSEMENT_CATEGORIE | Chaque couple de FK | Couple entier → existence de l'association ; aucune propriété métier non-clé à ce stade | Une ligne par couple (1FN) ; aucun attribut dépendant d'une seule moitié (2FN) ; pas de transitivité (3FN). |
| GERANT | `gerant_id` ; `compte_id` si UK confirmée | Identifiant → compte et identité déclarée | Valeurs simples ; clés simples ; téléphone et rôles du compte absents. L'état KYC est lu dans DOSSIER_KYC, sans colonne dupliquée. |
| ETABLISSEMENT | `etablissement_id` | Identifiant → commune, nom, description, contact, GPS, état | Coordonnées séparées et élémentaires ; clé simple ; libellés géographiques et identité du gérant absents. |
| MEDIA, PRESTATION, TARIF_PRESTATION | Identifiant de chaque relation ; clés supplémentaires à confirmer | Identifiant → FK propriétaire et propriétés propres | Une occurrence par média/prestation/tarif ; clés simples ; nom du salon absent des lignes filles, montant absent de PRESTATION. Si (`prestation_id`, `date_effet`) devient clé, montant et devise doivent dépendre du couple entier. |
| PLAGE_OUVERTURE, EXCEPTION_OUVERTURE | Identifiant de chaque relation ; unicités de plages à définir | Identifiant → salon, jour/date, bornes horaires et fermeture | Bornes élémentaires, pas de colonnes `lundi1/lundi2` ; clés simples ; nom du salon absent. Toute clé naturelle de plage sera réauditée. |
| DOSSIER_KYC, JUSTIFICATIF_KYC | Identifiant de chaque relation | Dossier → gérant, état, dates, décideur, motif ; justificatif → dossier, type, référence, état | Une ligne par dossier/pièce ; clés simples ; nom du gérant et données du compte décideur absents. Le motif dépend de la décision du dossier, pas de la pièce. |

**Résultat provisoire :** les relations détaillées satisfont les 1FN, 2FN et 3FN sous les dépendances actuellement connues. Ce résultat n'est pas une certification finale : les clés candidates supplémentaires, les règles territoriales et les relations de réservation/facturation doivent être réaudités après validation des questions métier. Un `id` technique seul ne constitue pas la preuve.

## Contrôles de cohérence avant le MPD

1. Vérifier qu'un établissement appartient à une zone valide pour le pays retenu et que les catégories ne sont pas dupliquées.
2. Assurer qu'un dossier KYC soumis contient les pièces exigées, qu'une décision a un auteur habilité et que les références de justificatifs ne sont jamais publiques.
3. Définir les contraintes de non-chevauchement des plages et l'historique des tarifs ; les types et index SQL viendront dans le MPD.
4. Refaire la liste des clés candidates et dépendances fonctionnelles pour toutes les relations une fois les décisions du questionnaire reçues.

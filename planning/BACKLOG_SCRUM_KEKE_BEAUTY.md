# Keke Beauty — Product Backlog et trajectoire Scrum

Proposition initiale issue de CDC_Keke Beauty (sections 1 à 5). Les compléments nécessaires à la qualité, au lancement et à l’exploitation sont identifiés. Aucun développement n’est déclaré terminé.

## Objectif produit

Permettre aux clients de trouver un établissement de beauté fiable, le contacter et réserver ; permettre aux partenaires vérifiés de gérer leur activité et leur abonnement ; permettre à Keke Beauty de contrôler et exploiter le service.

## Hypothèses de planification

- 12 sprints de 2 semaines = trajectoire nominale de 24 semaines, pas un engagement de délai.
- Équipe, disponibilité, date de départ et vélocité inconnues : aucune affectation ni échéance calendaire inventée.
- Les points sont des estimations initiales de complexité, à reprendre en équipe. Ils ne se convertissent pas directement en jours.
- Les sprints futurs sont une prévision. Le Sprint Backlog effectif est sélectionné avec les Developers au Sprint Planning selon capacité et dépendances.
- Les travaux web/Android/iOS sont conditionnels au choix du Sprint 1. Les charges de livraison finale ne couvrent pas à elles seules le développement de trois clients : chaque fonctionnalité antérieure doit être réestimée pour toutes les plateformes retenues.
- Les tâches anomalies/incidents sont des enveloppes prévisionnelles à remplacer par les défauts réellement observés et à réestimer.
- Les paiements concernent les abonnements des établissements. Le paiement des soins, les commissions, avis clients, messagerie et fidélité ne sont pas exigés dans le CDC et ne sont pas ajoutés au périmètre.

## Organisation Scrum

- Product Owner : une personne responsable des priorités, décisions produit et critères d’acceptation, à nommer.
- Scrum Master : accompagne la méthode, les événements et la levée des obstacles, à nommer.
- Developers : équipe pluridisciplinaire assurant conception, réalisation, tests et exploitation ; affectations décidées collectivement.
- Cadence proposée : Planning 2 h au début, Daily 15 min les jours ouvrés, Review 1 h et Rétrospective 1 h en fin de sprint ; affinement 1 h par semaine. Ajuster les durées aux besoins.
- Chaque Review démontre un incrément utilisable et adapte les priorités. Chaque Rétrospective retient au moins une amélioration suivie au sprint suivant.
- Aucun Sprint 0 imposé : le premier sprint inclut une fiche utilisable en recette, en plus du cadrage.

## Definition of Ready — accord de travail proposé

Objectif compris, critères vérifiables, dépendances identifiées, décisions bloquantes résolues, exemples et maquette disponibles si nécessaires, taille compatible avec le sprint. Cette checklist est un accord local et non une règle imposée par Scrum.

## Definition of Done — à adopter par l’équipe

- Critères d’acceptation vérifiés et preuves jointes ; cas d’erreur et droits d’accès couverts.
- Revue effectuée ; contrôles automatisés adaptés au risque réussis ; absence d’anomalie critique ou bloquante connue.
- Intégration en recette, documentation et migrations à jour ; secrets et données sensibles protégés.
- Accessibilité, compatibilité et performance vérifiées selon les seuils convenus pour le changement.
- Incrément démontrable ; données de test identifiables. Une revue produit ne remplace pas les contrôles qualité.

## Gestion ClickUp proposée

- Dossier : Keke Beauty — Scrum, dans Espace de l’équipe.
- Product Backlog : source unique des éléments KB-001 à KB-084.
- Une liste par sprint : objectif, prévision, critères de sortie et références aux mêmes tâches. Si Tasks in Multiple Lists est disponible, rattacher les tâches existantes sans les dupliquer ; sinon conserver les tâches dans Product Backlog et utiliser des liens dans les fiches sprint.
- Une fiche de pilotage par sprint : Planning, Daily, affinement, Review, Rétrospective et suivi de l’objectif.
- Champs proposés : ID CDC, type/epic, priorité, points, sprint prévisionnel, responsable, dépendances. En l’absence de champs configurables, les descriptions restent la référence.
- Workflow proposé à adapter aux statuts réellement disponibles : À affiner → Prêt → En cours → En revue → En test → Terminé ; blocages signalés avec cause et responsable.
- Limiter le travail en cours selon la capacité ; mesurer points terminés, objectif atteint, défauts et éléments bloqués. Ne pas compter les points des fiches de pilotage.
- Ne pas cloner les stories dans plusieurs sprints : déplacer la prévision des tâches inachevées et conserver leur historique.

## Décisions et risques à traiter tôt

| Sujet | Action / preuve attendue | Responsable fonctionnel | Échéance relative |
|---|---|---|---|
| Plateformes, pays, devise, équipe et budget | Décision KB-001 ; ajuster charges et calendrier | Product Owner | Sprint 1 |
| Capacité des salons et règles RDV | Décision KB-002 avec exemples de chevauchement | Product Owner + partenaires pilotes | Sprint 1 |
| Engagement annuel et impayés | Conditions, grâce, renouvellement et impact sur RDV | Product Owner | Avant Sprint 5, puis Sprint 7 |
| SMS et paiement locaux | Accès sandbox, couverture réelle, quotas, coûts, contrats | Équipe technique + responsable métier | Sprint 1 ; production avant Sprint 11 |
| Yango et applications de cartes | Preuve de lien sur appareils ; repli si indisponible | Developers | Sprint 1 puis Sprint 4 |
| Données KYC et personnelles | Accès, conservation, suppression et règles pays | Responsable désigné par le Product Owner | Sprint 2 |
| Stores mobiles | Comptes, signature et délais externes si mobile retenu | Responsable publication | Démarrer Sprint 1 ; prêt Sprint 10 |
| Performance et reprise | Volumes, p95, disponibilité, RPO/RTO à convenir | Product Owner + Developers | Cadrage puis mesure Sprint 10 |

## Trajectoire des sprints

| Sprint | Objectif / résultat attendu | Points indicatifs |
|---|---|---:|
| 01 — Cadrage et première consultation | Consulter une première fiche de démonstration sur un environnement de recette. | 28 |
| 02 — Identité et inscription partenaire | Un client se connecte et un partenaire dépose un dossier sécurisé. | 31 |
| 03 — Validation et catalogue partenaire | Un établissement vérifié publie une fiche et des prestations exploitables. | 29 |
| 04 — Recherche et mise en relation | Un client trouve un salon pertinent et peut le contacter ou s’y rendre. | 28 |
| 05 — Disponibilités et demande de rendez-vous | Un client demande un créneau réellement disponible sans double réservation. | 31 |
| 06 — Gestion des rendez-vous et notifications | Client et partenaire suivent un rendez-vous confirmé, refusé ou modifié. | 29 |
| 07 — Abonnements et paiement Mobile Money | Un établissement souscrit et obtient ses droits après paiement vérifié. | 29 |
| 08 — Cartes, renouvellements et finances | Les abonnements sont encaissés, rapprochés et suivis sur leur cycle de vie. | 31 |
| 09 — Administration et exploitation métier | L’équipe Keke Beauty administre le service et traite les incidents métier. | 29 |
| 10 — Qualité et préparation des plateformes | Le produit est utilisable sur les plateformes retenues et prêt pour la recette finale. | 33 |
| 11 — Recette finale et lancement | Une version acceptée est mise en service avec des partenaires prêts à l’utiliser. | 29 |
| 12 — Stabilisation et transfert | Le service est stable, mesuré et exploitable durablement par l’équipe. | 21 |

Total indicatif : 348 points pour 84 éléments, avant réestimation des plateformes et de la capacité.

## Jalons

- Fin S4 : annuaire, fiches, recherche, appel et itinéraire démontrables.
- Fin S6 : parcours RDV complet, notifications et concurrence testés.
- Fin S8 : abonnement, encaissements et suivi financier démontrables.
- Fin S9 : exploitation métier testée avec pilotes.
- Fin S10 : qualité mesurée et plateformes retenues prêtes pour recette.
- Fin S11 : lancement sous réserve de recette, accès production et éventuelles validations des stores.
- Fin S12 : stabilisation, transfert et backlog de maintenance.

## Couverture du cahier des charges

| Exigence | Éléments |
|---|---|
| Application et cibles | KB-001, KB-006, KB-067 à KB-069 |
| Violet/blanc, ergonomie, médias | KB-003, KB-018, KB-019, KB-025, KB-066 |
| Téléphone et OTP | KB-008 à KB-010 |
| Recherche et géolocalisation | KB-021 à KB-024 |
| Prestations, tarifs, appel, itinéraire | KB-017, KB-020, KB-025 à KB-027 |
| Calendrier, rouge indisponible, confirmations/refus | KB-029 à KB-042 |
| Onboarding, identité, horaires, GPS | KB-011 à KB-016, KB-030 |
| Abonnement annuel, facturation mensuelle/annuelle | KB-043, KB-044, KB-049, KB-051 à KB-053 |
| Mobile Money, Visa, Mastercard | KB-045 à KB-048, KB-050, KB-054 |
| API, cloud, disponibilité | KB-004, KB-005, KB-024, KB-027, KB-040, KB-065, KB-070 |
| Back-office, KYC, finances et paramétrage | KB-015, KB-021, KB-043, KB-052, KB-055, KB-057 à KB-062 |

## Backlog détaillé

## Sprint 01 — Cadrage et première consultation

Consulter une première fiche de démonstration sur un environnement de recette.

### KB-001 — Valider le périmètre et les décisions produit

Priorité : high · Points : 3 · Source : CDC 1, 3.3
Dépendances : Aucune

- [ ] Pays et devise, web/mobile, budget, date et équipe consignés avec responsable et échéance
- [ ] périmètre de lancement et indicateurs de succès approuvés par le Product Owner.

### KB-002 — Établir les règles métier des rendez-vous et abonnements

Priorité : high · Points : 3 · Source : CDC 3.1–3.3
Dépendances : KB-001

- [ ] Durée, employés/capacité, fuseau horaire, délais, annulations et absences décidés
- [ ] droits gratuits/payants, engagement annuel, impayés et renouvellement explicités.

### KB-003 — Valider la direction graphique et les parcours

Priorité : high · Points : 5 · Source : CDC 2
Dépendances : KB-001

- [ ] Un logo choisi parmi les propositions ou une alternative validée
- [ ] prototype violet/blanc couvrant recherche, fiche, RDV et espace partenaire testé avec utilisateurs représentatifs.

### KB-004 — Choisir l’architecture et vérifier les fournisseurs

Priorité : high · Points : 5 · Source : CDC 4
Dépendances : KB-001

- [ ] Décisions documentées pour clients, serveur, données, hébergement et cartographie
- [ ] faisabilité, coûts et accès de test SMS, paiement et liens Yango vérifiés avec solution de repli.

### KB-005 — Installer le dépôt et la chaîne de livraison

Priorité : high · Points : 5 · Source : Complément livraison
Dépendances : KB-004

- [ ] Installation reproductible et contrôles automatiques sur une modification
- [ ] recette déployée avec configuration séparée et secrets absents du dépôt.

### KB-006 — Afficher une fiche de démonstration accessible

Priorité : high · Points : 5 · Source : CDC 3.1
Dépendances : KB-003, KB-005

- [ ] Fiche alimentée par un jeu de données de démonstration avec nom, description, prestations et tarifs
- [ ] affichage mobile et bureau, chargement et erreur contrôlés.

### KB-007 — Définir le fonctionnement Scrum et la qualité

Priorité : high · Points : 2 · Source : Complément Scrum
Dépendances : KB-001

- [ ] Product Owner, Scrum Master et Developers identifiés
- [ ] Definition of Done, cadence, registre des décisions et critères de recette partagés.

## Sprint 02 — Identité et inscription partenaire

Un client se connecte et un partenaire dépose un dossier sécurisé.

### KB-008 — Demander un code de connexion par SMS

Priorité : high · Points : 5 · Source : CDC 3.1, 4
Dépendances : KB-004, KB-005

- [ ] Numéro normalisé selon le pays
- [ ] code limité dans le temps, quota de demandes et délai de renvoi testés sans révéler l’existence d’un compte.

### KB-009 — Valider le code et gérer la session client

Priorité : high · Points : 5 · Source : CDC 3.1
Dépendances : KB-008

- [ ] Code valide utilisable une fois
- [ ] code expiré ou incorrect refusé, limite de tentatives, expiration et déconnexion testées.

### KB-010 — Appliquer les rôles et restrictions d’interaction

Priorité : high · Points : 5 · Source : CDC 3.1, 5
Dépendances : KB-009

- [ ] Client, partenaire et administrateur distingués côté serveur
- [ ] interactions réservées aux comptes connectés et accès aux données d’autrui refusés.

### KB-011 — Créer le profil partenaire et ses coordonnées

Priorité : high · Points : 5 · Source : CDC 3.2
Dépendances : KB-010

- [ ] Nom, contacts, horaires, adresse et position GPS enregistrés avec validation
- [ ] partenaire peut reprendre son dossier incomplet.

### KB-012 — Téléverser la devanture et la pièce du gérant

Priorité : high · Points : 5 · Source : CDC 3.2, 5
Dépendances : KB-011

- [ ] Formats et tailles contrôlés
- [ ] pièce d’identité stockée séparément en accès privé, lecture non autorisée refusée.

### KB-013 — Soumettre et suivre le dossier de vérification

Priorité : high · Points : 3 · Source : CDC 3.2, 5
Dépendances : KB-012

- [ ] Soumission impossible si pièces obligatoires manquent
- [ ] états brouillon, soumis et à corriger affichés sans activer le partenaire prématurément.

### KB-014 — Protéger les données personnelles dès l’inscription

Priorité : high · Points : 3 · Source : Complément exploitation
Dépendances : KB-010

- [ ] Informations collectées et finalités affichées
- [ ] accès, conservation et suppression des données et justificatifs documentés selon le pays retenu, sans pièces ni OTP dans les journaux.

## Sprint 03 — Validation et catalogue partenaire

Un établissement vérifié publie une fiche et des prestations exploitables.

### KB-015 — Traiter les dossiers de vérification dans l’administration

Priorité : normal · Points : 5 · Source : CDC 5
Dépendances : KB-013

- [ ] Administrateur autorisé examine les pièces et valide ou rejette avec motif
- [ ] historique conservé et activation réservée aux dossiers validés.

### KB-016 — Corriger et resoumettre un dossier refusé

Priorité : normal · Points : 3 · Source : CDC 3.2, 5
Dépendances : KB-015

- [ ] Partenaire voit le motif et remplace les éléments demandés
- [ ] resoumission repasse en examen sans auto-validation.

### KB-017 — Gérer les prestations et leurs tarifs

Priorité : normal · Points : 5 · Source : CDC 3.2
Dépendances : KB-011, KB-002

- [ ] Créer, modifier et retirer une prestation
- [ ] montants et devise validés, durée/capacité conforme aux règles métier et prestation retirée non réservable.

### KB-018 — Gérer les photos de l’établissement

Priorité : normal · Points : 3 · Source : CDC 3.1, 3.2
Dépendances : KB-012

- [ ] Ajouter, ordonner, remplacer et supprimer ses photos
- [ ] contrôle des fichiers, optimisation et image de remplacement fonctionnels.

### KB-019 — Gérer les vidéos courtes de l’établissement

Priorité : normal · Points : 5 · Source : CDC 2, 3.1
Dépendances : KB-018

- [ ] Durée et poids maximum décidés et appliqués
- [ ] lecture sur plateformes retenues, miniature et échec de traitement pris en charge.

### KB-020 — Publier et mettre à jour la fiche établissement

Priorité : normal · Points : 5 · Source : CDC 3.1, 3.2
Dépendances : KB-015, KB-017, KB-018

- [ ] Fiche publiée uniquement après validation et champs requis
- [ ] modification autorisée au propriétaire et visibilité conforme au statut de modération.

### KB-021 — Administrer les catégories et zones géographiques

Priorité : normal · Points : 3 · Source : CDC 5
Dépendances : KB-010, KB-001

- [ ] Catégories et hiérarchie pays/région/ville/commune administrables
- [ ] doublons et suppression d’éléments déjà utilisés contrôlés.

## Sprint 04 — Recherche et mise en relation

Un client trouve un salon pertinent et peut le contacter ou s’y rendre.

### KB-022 — Rechercher par catégorie de beauté

Priorité : normal · Points : 5 · Source : CDC 3.1
Dépendances : KB-020, KB-021

- [ ] Filtre appliqué aux établissements publiés
- [ ] pagination, chargement, absence de résultat et remise à zéro gérés.

### KB-023 — Filtrer par pays, région, ville et commune

Priorité : normal · Points : 5 · Source : CDC 3.1
Dépendances : KB-021, KB-022

- [ ] Filtres en cascade cohérents
- [ ] changement de pays réinitialise les descendants incompatibles et se combine à la catégorie.

### KB-024 — Découvrir les établissements proches

Priorité : normal · Points : 5 · Source : CDC 1, 3.1, 4
Dépendances : KB-004, KB-022

- [ ] Localisation demandée explicitement
- [ ] résultats et distances cohérents, recherche manuelle disponible si permission refusée ou position indisponible.

### KB-025 — Consulter la fiche complète et ses médias

Priorité : normal · Points : 3 · Source : CDC 3.1
Dépendances : KB-019, KB-020, KB-022

- [ ] Description, tarifs, prestations et carrousel visibles
- [ ] média absent ou indisponible ne bloque pas la consultation.

### KB-026 — Appeler l’établissement depuis sa fiche

Priorité : normal · Points : 2 · Source : CDC 3.1
Dépendances : KB-025, KB-010

- [ ] Bouton ouvre le composeur sur appareil compatible avec le bon numéro
- [ ] alternative de copie visible et interaction suit la règle de connexion.

### KB-027 — Ouvrir l’itinéraire Maps et Yango

Priorité : normal · Points : 5 · Source : CDC 3.1, 4
Dépendances : KB-004, KB-025

- [ ] Destination GPS exacte transmise aux applications retenues
- [ ] cas application absente couvert par repli vérifié sur appareils cibles.

### KB-028 — Valider le parcours annuaire en conditions réelles

Priorité : normal · Points : 3 · Source : Complément qualité
Dépendances : KB-023, KB-024, KB-026, KB-027

- [ ] Parcours recherche → fiche → contact testé sur réseau lent et écrans cibles
- [ ] navigation clavier, libellés et contraste vérifiés, anomalies bloquantes corrigées.

## Sprint 05 — Disponibilités et demande de rendez-vous

Un client demande un créneau réellement disponible sans double réservation.

### KB-029 — Activer la réservation pour un partenaire éligible

Priorité : normal · Points : 3 · Source : CDC 3.1, 3.3
Dépendances : KB-002, KB-020

- [ ] Partenaire choisit d’activer/désactiver la réservation
- [ ] contrôle d’éligibilité côté serveur avec données de test, annuaire accessible selon les droits définis.

### KB-030 — Définir les horaires et exceptions de réservation

Priorité : normal · Points : 5 · Source : CDC 3.2
Dépendances : KB-002, KB-017, KB-029

- [ ] Horaires réguliers, pauses, fermetures et jours exceptionnels éditables
- [ ] créneaux calculés selon durée, capacité et fuseau décidés.

### KB-031 — Afficher le calendrier des disponibilités

Priorité : normal · Points : 5 · Source : CDC 3.1
Dépendances : KB-030

- [ ] Calendrier reflète les créneaux valides
- [ ] indisponibilités en rouge et indiquées par un texte/symbole, dates passées non sélectionnables.

### KB-032 — Envoyer une demande de rendez-vous

Priorité : normal · Points : 5 · Source : CDC 3.1
Dépendances : KB-009, KB-031

- [ ] Client choisit service et créneau et confirme le récapitulatif
- [ ] demande persistée avec statut initial explicite et référence unique.

### KB-033 — Empêcher les conflits de réservation

Priorité : high · Points : 5 · Source : CDC 3.2
Dépendances : KB-032

- [ ] Deux demandes concurrentes ne dépassent jamais la capacité
- [ ] répétition d’une requête ne crée pas de doublon et conflit expliqué au client.

### KB-034 — Consulter ses rendez-vous côté client

Priorité : normal · Points : 3 · Source : Complément parcours RDV
Dépendances : KB-032, KB-010

- [ ] Liste et détail présentent date locale, salon, service et état
- [ ] client ne consulte que ses rendez-vous.

### KB-035 — Actualiser les disponibilités en temps réel

Priorité : normal · Points : 5 · Source : CDC 3.2
Dépendances : KB-033

- [ ] Changement de disponibilité propagé aux vues connectées
- [ ] reconnexion recharge l’état serveur et sélection devenue invalide est refusée proprement.

## Sprint 06 — Gestion des rendez-vous et notifications

Client et partenaire suivent un rendez-vous confirmé, refusé ou modifié.

### KB-036 — Afficher le tableau de bord des demandes partenaire

Priorité : normal · Points : 5 · Source : CDC 3.2
Dépendances : KB-032, KB-010

- [ ] Demandes et calendrier limités à son établissement
- [ ] filtres de date et statut, vue vide et compteurs cohérents.

### KB-037 — Confirmer ou refuser une demande

Priorité : normal · Points : 3 · Source : CDC 3.1, 3.2
Dépendances : KB-036, KB-033

- [ ] Transitions valides seulement, motif de refus disponible
- [ ] confirmation réserve et refus libère selon les règles sans conflit concurrent.

### KB-038 — Annuler un rendez-vous avec les règles convenues

Priorité : normal · Points : 3 · Source : CDC 3.2
Dépendances : KB-037, KB-002

- [ ] Acteurs autorisés et délais appliqués
- [ ] créneau libéré, historique préservé et annulation répétée sans effet supplémentaire.

### KB-039 — Reprogrammer un rendez-vous

Priorité : normal · Points : 5 · Source : CDC 3.2
Dépendances : KB-037, KB-033

- [ ] Nouveau créneau vérifié avant libération de l’ancien
- [ ] accord client selon décision métier et échec conserve le rendez-vous initial.

### KB-040 — Envoyer les confirmations et refus par SMS

Priorité : normal · Points : 5 · Source : CDC 3.1, 4
Dépendances : KB-037, KB-004

- [ ] SMS contient salon, date, heure et résultat
- [ ] envoi dédupliqué avec reprise après panne et suivi d’échec accessible.

### KB-041 — Afficher les notifications dans l’application

Priorité : normal · Points : 5 · Source : CDC 3.1, 4
Dépendances : KB-040, KB-009

- [ ] Confirmation, refus, annulation et reprogrammation apparaissent au bon destinataire
- [ ] état lu/non lu et ouverture du bon rendez-vous, accès tiers refusé.

### KB-042 — Recetter le cycle complet des rendez-vous

Priorité : normal · Points : 3 · Source : Complément qualité
Dépendances : KB-035, KB-038, KB-039, KB-040, KB-041

- [ ] Scénarios multi-clients incluant concurrence, changement d’horaire, panne SMS et reconnexion réussis
- [ ] démonstration de bout en bout acceptée.

## Sprint 07 — Abonnements et paiement Mobile Money

Un établissement souscrit et obtient ses droits après paiement vérifié.

### KB-043 — Configurer les offres et prix d’abonnement

Priorité : normal · Points : 3 · Source : CDC 3.3, 5
Dépendances : KB-002, KB-010

- [ ] Administration édite prix et fonctionnalités par offre
- [ ] historique tarifaire préserve les contrats existants, montants et devise validés.

### KB-044 — Souscrire un engagement annuel avec échéancier

Priorité : normal · Points : 5 · Source : CDC 3.3
Dépendances : KB-043

- [ ] Engagement minimum d’un an distinct de la périodicité mensuelle/annuelle
- [ ] montant, échéances et conditions acceptées sont conservés.

### KB-045 — Intégrer le paiement Mobile Money

Priorité : high · Points : 5 · Source : CDC 3.3, 4
Dépendances : KB-044, KB-004

- [ ] Initiation chez l’agrégateur avec référence unique
- [ ] Wave, Orange, MTN, Moov et autres canaux applicables sont vérifiés par pays, couverture manquante signalée avant lancement.

### KB-046 — Vérifier les retours de paiement de façon idempotente

Priorité : high · Points : 5 · Source : CDC 3.3, 4
Dépendances : KB-045

- [ ] Authenticité du retour vérifiée auprès du fournisseur
- [ ] notifications doubles, retardées ou désordonnées ne créditent pas deux fois et montant/devise/contrat concordent.

### KB-047 — Appliquer les droits après paiement confirmé

Priorité : high · Points : 5 · Source : CDC 3.3
Dépendances : KB-046, KB-029

- [ ] Droits avancés activés côté serveur après confirmation fiable
- [ ] paiement en attente/échoué ne les active pas, droits expirés testés.

### KB-048 — Gérer les paiements abandonnés et les reprises

Priorité : high · Points : 3 · Source : Complément paiement
Dépendances : KB-046

- [ ] États attente, réussi, échoué et expiré affichés
- [ ] reprise possible sans double contrat et contrôle serveur après retour du navigateur.

### KB-049 — Consulter ses justificatifs et échéances

Priorité : normal · Points : 3 · Source : CDC 3.3
Dépendances : KB-046

- [ ] Historique accessible au bon partenaire avec référence, montant, période et état
- [ ] justificatif conforme au format décidé et aucun secret de paiement exposé.

## Sprint 08 — Cartes, renouvellements et finances

Les abonnements sont encaissés, rapprochés et suivis sur leur cycle de vie.

### KB-050 — Intégrer les paiements Visa et Mastercard

Priorité : high · Points : 5 · Source : CDC 3.3
Dépendances : KB-046

- [ ] Parcours fournisseur pour les cartes retenues testé en réussite, refus et authentification requise
- [ ] aucune donnée carte sensible stockée par l’application.

### KB-051 — Gérer les échéances et renouvellements

Priorité : normal · Points : 5 · Source : CDC 3.3
Dépendances : KB-044, KB-047

- [ ] Échéances mensuelles et annuelles calculées correctement
- [ ] reconduction/résiliation suit le contrat décidé, aucun prélèvement automatique supposé sans capacité fournisseur et accord.

### KB-052 — Relancer les abonnements impayés

Priorité : normal · Points : 3 · Source : CDC 5
Dépendances : KB-051, KB-040

- [ ] Relances aux échéances convenues, dédupliquées
- [ ] paiement récent annule la relance, échecs d’envoi visibles.

### KB-053 — Suspendre et rétablir les fonctionnalités avancées

Priorité : normal · Points : 5 · Source : CDC 3.3
Dépendances : KB-051, KB-047

- [ ] Délai de grâce décidé appliqué
- [ ] droits restaurés après régularisation et traitement des RDV existants conforme à la règle validée.

### KB-054 — Rapprocher les paiements avec le fournisseur

Priorité : high · Points : 5 · Source : Complément exploitation
Dépendances : KB-046, KB-050

- [ ] Transactions orphelines et écarts montant/état détectés
- [ ] rattrapage contrôlé, audité et sans double activation.

### KB-055 — Afficher le tableau de bord financier

Priorité : normal · Points : 5 · Source : CDC 5
Dépendances : KB-049, KB-054

- [ ] Abonnements actifs, dus, encaissés et chiffre d’affaires selon définition validée
- [ ] filtres et totaux concordent avec transactions tests sans mélanger encaissement et revenu.

### KB-056 — Traiter les exceptions de paiement

Priorité : high · Points : 3 · Source : Complément exploitation
Dépendances : KB-054, KB-002

- [ ] Procédure de contestation/remboursement documentée selon contrat et capacités fournisseur
- [ ] correction tracée et droits associés cohérents sans suppression de transaction.

## Sprint 09 — Administration et exploitation métier

L’équipe Keke Beauty administre le service et traite les incidents métier.

### KB-057 — Modérer les comptes clients et établissements

Priorité : normal · Points : 5 · Source : CDC 5
Dépendances : KB-010, KB-020

- [ ] Administrateur peut suspendre et rétablir avec motif
- [ ] visibilité, connexion et RDV existants suivent les règles validées et actions auditées.

### KB-058 — Contrôler les médias et informations publiés

Priorité : normal · Points : 3 · Source : CDC 5
Dépendances : KB-019, KB-057

- [ ] Contenu problématique masqué par rôle autorisé
- [ ] propriétaire reçoit le motif et correction peut être examinée avant republication.

### KB-059 — Suivre l’activité des rendez-vous dans l’administration

Priorité : normal · Points : 3 · Source : Complément exploitation
Dépendances : KB-042, KB-010

- [ ] Recherche par référence et filtres métier
- [ ] accès minimal aux données client et historique utile au support sans usurpation silencieuse.

### KB-060 — Auditer les actions sensibles

Priorité : normal · Points : 5 · Source : Complément sécurité
Dépendances : KB-015, KB-055, KB-057

- [ ] Validation KYC, changement de tarif, suspension et correction financière historisés avec acteur/date
- [ ] accès et conservation contrôlés, secrets exclus.

### KB-061 — Mettre en œuvre les demandes sur les données personnelles

Priorité : normal · Points : 5 · Source : Complément exploitation
Dépendances : KB-014, KB-060

- [ ] Demande d’accès/correction/suppression traitée après vérification d’identité
- [ ] données supprimées ou conservées selon règles décidées et traitement des sauvegardes documenté.

### KB-062 — Préparer l’assistance et les procédures métier

Priorité : normal · Points : 3 · Source : Complément exploitation
Dépendances : KB-056, KB-059

- [ ] Procédures OTP, KYC, réservation, impayé et incident accessibles aux opérateurs
- [ ] responsabilités, escalade et canaux de contact testés.

### KB-063 — Valider l’exploitation avec un groupe pilote

Priorité : normal · Points : 5 · Source : Complément recette
Dépendances : KB-057, KB-058, KB-061, KB-062

- [ ] Jeu pilote autorisé, scénarios client/partenaire/admin exécutés
- [ ] retours priorisés et anomalies bloquantes traitées avant élargissement.

## Sprint 10 — Qualité et préparation des plateformes

Le produit est utilisable sur les plateformes retenues et prêt pour la recette finale.

### KB-064 — Vérifier la sécurité des parcours critiques

Priorité : high · Points : 5 · Source : Complément qualité
Dépendances : KB-060, KB-053

- [ ] Tests d’accès tiers, abus OTP, téléversements et paiements réalisés
- [ ] aucun défaut critique ou élevé non traité selon grille convenue.

### KB-065 — Mesurer et améliorer les performances

Priorité : normal · Points : 5 · Source : CDC 4
Dépendances : KB-028, KB-042, KB-055

- [ ] Scénarios de charge, volume et seuils p95 définis avec l’équipe puis mesurés
- [ ] recherche et réservation restent dans ces seuils sous la charge retenue.

### KB-066 — Finaliser accessibilité et expérience sur réseau faible

Priorité : normal · Points : 5 · Source : CDC 2 / Complément qualité
Dépendances : KB-063

- [ ] Parcours essentiels testés clavier/lecteur d’écran, contraste et erreurs compréhensibles
- [ ] chargement limité des médias et reprise après interruption vérifiés.

### KB-067 — Finaliser la livraison web retenue

Priorité : normal · Points : 3 · Source : CDC 1 / Condition plateforme
Dépendances : KB-001, KB-066

- [ ] Si web retenu : navigateurs cibles, responsive, domaine, HTTPS et liens directs testés
- [ ] sinon décision de non-applicabilité consignée et charge retirée.

### KB-068 — Finaliser la livraison Android si retenue

Priorité : normal · Points : 5 · Source : CDC 1 / Condition plateforme
Dépendances : KB-001, KB-066

- [ ] Si Android retenu : build signé, permissions, liens externes et tests appareils prêts pour piste interne
- [ ] sinon tâche classée non applicable après décision produit.

### KB-069 — Finaliser la livraison iOS si retenue

Priorité : normal · Points : 5 · Source : CDC 1 / Condition plateforme
Dépendances : KB-001, KB-066

- [ ] Si iOS retenu : build signé, permissions, liens externes et tests appareils prêts pour distribution de test
- [ ] sinon tâche classée non applicable après décision produit.

### KB-070 — Valider sauvegarde, restauration et supervision

Priorité : high · Points : 5 · Source : CDC 4 / Complément exploitation
Dépendances : KB-005, KB-060

- [ ] Sauvegarde restaurée en environnement isolé et objectifs de perte/reprise mesurés
- [ ] alertes sur API, OTP, paiement et files d’envoi testées avec procédure d’intervention.

## Sprint 11 — Recette finale et lancement

Une version acceptée est mise en service avec des partenaires prêts à l’utiliser.

### KB-071 — Exécuter la recette métier complète

Priorité : normal · Points : 5 · Source : Complément recette
Dépendances : KB-064, KB-065, KB-066, KB-070

- [ ] Matrice du CDC rejouée sur version candidate avec preuves
- [ ] écarts qualifiés et décision du Product Owner documentée.

### KB-072 — Corriger et vérifier les anomalies de recette

Priorité : normal · Points : 5 · Source : Complément qualité
Dépendances : KB-071

- [ ] Chaque anomalie retenue possède reproduction et test de non-régression
- [ ] aucune anomalie bloquant le lancement, charge réévaluée selon constats réels.

### KB-073 — Préparer les données de lancement

Priorité : normal · Points : 3 · Source : Complément lancement
Dépendances : KB-021, KB-015

- [ ] Zones, catégories, offres et salons pilotes validés
- [ ] import reproductible sans données fictives publiques ni doublons, accord des partenaires consigné.

### KB-074 — Former partenaires et administrateurs

Priorité : normal · Points : 3 · Source : Complément lancement
Dépendances : KB-062, KB-072

- [ ] Guides client/partenaire/admin et séance pratique disponibles
- [ ] opérateurs réalisent validation, RDV et suivi paiement sans assistance de développement.

### KB-075 — Répéter le déploiement et le retour arrière

Priorité : normal · Points : 5 · Source : Complément livraison
Dépendances : KB-070, KB-072

- [ ] Migration répétée sur copie contrôlée, sauvegarde et procédure de retour arrière testées
- [ ] critères go/no-go et responsable de lancement identifiés.

### KB-076 — Publier sur les canaux retenus

Priorité : normal · Points : 5 · Source : Complément lancement
Dépendances : KB-067, KB-068, KB-069, KB-073, KB-075

- [ ] Web déployé et/ou versions soumises puis publiées sur stores retenus
- [ ] tests de fumée en production, suivi explicite des délais de validation externes.

### KB-077 — Ouvrir le service aux premiers utilisateurs

Priorité : normal · Points : 3 · Source : Complément lancement
Dépendances : KB-074, KB-076

- [ ] Pilotes accèdent aux bons services, paiement et réservation vérifiés de bout en bout
- [ ] indicateurs initiaux et canal support opérationnels.

## Sprint 12 — Stabilisation et transfert

Le service est stable, mesuré et exploitable durablement par l’équipe.

### KB-078 — Assurer la surveillance renforcée du lancement

Priorité : normal · Points : 3 · Source : Complément exploitation
Dépendances : KB-077

- [ ] Période d’observation et seuils convenus
- [ ] incidents enregistrés, responsable de suivi connu et aucune alerte critique laissée sans traitement.

### KB-079 — Corriger les incidents et régressions de production

Priorité : normal · Points : 5 · Source : Complément qualité
Dépendances : KB-078

- [ ] Incidents priorisés selon impact, correction validée avant publication
- [ ] causes et tests de non-régression documentés, estimation révisée selon incidents constatés.

### KB-080 — Vérifier les premiers cycles financiers réels

Priorité : normal · Points : 3 · Source : Complément exploitation
Dépendances : KB-077, KB-054

- [ ] Encaissements pilotes rapprochés avec fournisseur
- [ ] échéances et droits contrôlés sans attendre un an grâce aux tests temporels, écarts corrigés.

### KB-081 — Mesurer les résultats et recueillir les retours

Priorité : normal · Points : 3 · Source : Complément produit
Dépendances : KB-077

- [ ] Indicateurs convenus mesurés sans données personnelles inutiles
- [ ] retours clients et partenaires synthétisés en améliorations ordonnées.

### KB-082 — Transférer l’exploitation technique

Priorité : normal · Points : 3 · Source : Complément transfert
Dépendances : KB-079, KB-070

- [ ] Architecture, configuration, migrations, procédures et accès remis aux responsables
- [ ] restauration et livraison réalisées par l’équipe de reprise.

### KB-083 — Valider le bilan de livraison

Priorité : normal · Points : 2 · Source : Complément clôture
Dépendances : KB-080, KB-081, KB-082

- [ ] Traçabilité CDC, périmètre réellement livré, limites et dettes résiduelles documentés
- [ ] acceptation et responsabilités de maintenance consignées.

### KB-084 — Préparer le backlog d’amélioration continue

Priorité : normal · Points : 2 · Source : Complément Scrum
Dépendances : KB-083

- [ ] Retours et dettes priorisés par valeur/risque avec Product Owner
- [ ] prochains objectifs et cadence de maintenance établis sans déclarer le produit définitivement terminé.

## Référence méthodologique

Scrum Guide officiel : https://scrumguides.org/scrum-guide.html. Les durées d’événements proposées, les points et la Definition of Ready sont des accords locaux, pas des prescriptions supplémentaires de Scrum.

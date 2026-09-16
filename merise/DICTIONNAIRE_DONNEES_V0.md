# Keke Beauty — Dictionnaire des données initial

> Version de référence : [Conception MERISE V1](CONCEPTION_MERISE_V1.md) — décisions validées, DD, MCD, MLD, MCT, MOT, MPD et audit actualisés. Cette V0 est conservée pour historique ; ses hypothèses remplacées ne sont plus applicables.

Statut : version de travail, à valider avec les réponses au questionnaire. Ce document décrit le sens métier des données sans imposer encore de tables ni de types SQL. Les identifiants de données seront repris dans le MCD, le MLD et le MPD.

| ID | Donnée | Sens et contrainte métier connus | Source | Décision ouverte |
|---|---|---|---|---|
| DD-001 | Numéro de téléphone du client | Identifiant de connexion et destinataire du code OTP ; format international à normaliser | CDC 3.1 | Pays de lancement et politique de changement de numéro |
| DD-002 | Code OTP | Secret temporaire utilisé pour valider le numéro ; ne pas conserver en clair | CDC 3.1, 4 | Durée de validité et limites de tentatives |
| DD-003 | Identité du gérant | Informations permettant la vérification du partenaire | CDC 3.2, 5 | Champs obligatoires et plusieurs gérants éventuels |
| DD-004 | Pièce d'identité du gérant | Justificatif privé soumis au contrôle administratif | CDC 3.2, 5 | Types de documents, conservation et suppression |
| DD-005 | Nom de l'établissement | Nom présenté dans l'annuaire | CDC 3.1–3.2 | Règles d'unicité ou d'homonymie |
| DD-006 | Description de l'établissement | Texte présenté sur la fiche | CDC 3.1 | Longueur, langue et modération |
| DD-007 | Téléphone de service de l'établissement | Numéro affiché pour le bouton Appeler | CDC 3.1 | Horaires d'affichage éventuels |
| DD-008 | Horaires de l'établissement | Plages d'ouverture communiquées par le partenaire | CDC 3.2 | Jours fériés, pauses, exceptions et fuseau |
| DD-009 | Position GPS de l'établissement | Coordonnées exactes utilisées pour carte et itinéraire | CDC 3.1–3.2, 4 | Modalité de validation et repli si position absente |
| DD-010 | Catégorie de beauté | Classification des établissements et filtre de recherche | CDC 3.1, 5 | Catégories initiales et appartenance multiple |
| DD-011 | Pays | Premier niveau de la hiérarchie de recherche | CDC 3.1 | Pays de lancement |
| DD-012 | Région | Deuxième niveau, rattaché à un pays | CDC 3.1 | Référentiel géographique officiel |
| DD-013 | Ville | Troisième niveau, rattaché à une région | CDC 3.1 | Définition des villes pilotes |
| DD-014 | Commune | Quatrième niveau, rattaché à une ville | CDC 3.1 | Sens local de commune et zones pilotes |
| DD-015 | Média de l'établissement | Photo ou vidéo courte présentée sur la fiche ; référence de fichier et métadonnées | CDC 2, 3.1–3.2 | Durée/poids des vidéos et ordre des médias |
| DD-016 | Prestation | Service proposé par un établissement | CDC 3.1–3.2 | Durée, capacité et prestations multiples par RDV |
| DD-017 | Tarif de prestation | Montant affiché pour une prestation d'un établissement | CDC 3.1–3.2 | Devise, date d'effet et historique des changements |
| DD-018 | Disponibilité | Créneau réservable calculé d'après horaires, exceptions et capacité | CDC 3.1–3.2 | Employé, ressource ou capacité globale ; blocage à la demande ou confirmation |
| DD-019 | Rendez-vous | Demande liant client, établissement, prestation et date/heure | CDC 3.1–3.2 | États, durée, annulation, reprogrammation |
| DD-020 | État du rendez-vous | Résultat du traitement d'une demande et de ses modifications | CDC 3.1–3.2 | Transitions exactes et acteurs autorisés |
| DD-021 | Notification de rendez-vous | Message de confirmation, refus ou indisponibilité adressé au client | CDC 3.1, 4 | Canal SMS, dans l'application, push et politique de relance |
| DD-022 | Offre d'abonnement | Fonctionnalités avancées et tarif administrables | CDC 3.3, 5 | Offres, tarifs, période de grâce |
| DD-023 | Contrat d'abonnement | Engagement d'un établissement pour au moins un an | CDC 3.3 | Renouvellement, résiliation et effet d'un impayé |
| DD-024 | Périodicité de facturation | Mensuelle ou annuelle, distincte de la durée d'engagement | CDC 3.3 | Changement en cours de contrat |
| DD-025 | Échéance d'abonnement | Somme due pour une période de facturation | CDC 3.3, 5 | Dates, devise, taxes et règles de relance |
| DD-026 | Paiement d'abonnement | Tentative et résultat d'encaissement par Mobile Money ou carte | CDC 3.3, 4 | Agrégateur, canaux réellement couverts et rapprochement |
| DD-027 | État de vérification KYC | Avancement de l'examen et décision d'activation du partenaire | CDC 3.2, 5 | États détaillés, motif de refus et resoumission |
| DD-028 | Rôle d'accès | Autorisation client, partenaire ou administrateur associée à un compte | CDC 3.1–3.2, 5 | Un compte peut-il cumuler plusieurs rôles ? |
| DD-029 | Association gérant établissement | Droit d'un gérant à administrer un établissement | CDC 3.2 | Plusieurs gérants et plusieurs salons par gérant ? |
| DD-030 | État de publication | Indique si une fiche d'établissement est visible dans l'annuaire | CDC 3.2, 5 | Règles de suspension et republication |
| DD-031 | Décision KYC | Validation ou rejet motivé d'un dossier par un administrateur | CDC 5 | États, recours et historique requis |
| DD-032 | Plage horaire | Intervalle régulier de disponibilité d'un établissement | CDC 3.2 | Pause, fuseau et ressource individuelle |
| DD-033 | Exception horaire | Fermeture ou ouverture exceptionnelle d'un établissement à une date | CDC 3.2 | Granularité et priorité sur les plages régulières |
| DD-034 | Événement de rendez-vous | Changement d'état, acteur et date d'un rendez-vous | CDC 3.2 | Transitions et conservation |
| DD-035 | Tarif d'offre accepté | Prix et devise figés au moment d'une souscription, distincts du tarif courant | CDC 3.3, 5 ; complément historique | Taxes et renégociation |

## Contrôle de normalisation prévu

Le dictionnaire ne constitue pas encore un schéma relationnel. Les regroupements et dépendances fonctionnelles seront définis dans le MCD/MLD. Par exemple, le nom d'une ville dépend de l'identité de la ville et ne doit pas être recopié comme attribut modifiable dans chaque établissement ; les prestations et médias multiples seront des occurrences liées, pas des colonnes répétées. Chaque relation du MLD sera examinée pour les 1FN, 2FN et 3FN, y compris ses clés candidates et ses dépendances transitives.

## Prochaine validation

À partir des réponses au questionnaire, compléter pour chaque donnée : définition précise, format métier, caractère obligatoire, domaine de valeurs, règle d'unicité, responsable de saisie, durée de conservation et sensibilité. Ensuite seulement, figer les cardinalités du MCD et les traitements du MCT.

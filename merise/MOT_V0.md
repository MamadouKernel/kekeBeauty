# Keke Beauty — Modèle organisationnel des traitements initial

Statut : **organisation proposée**. Le MOT reprend les opérations du MCT et précise acteur, moment, lieu logique et moyen. Les rôles exacts, horaires de support et procédures d'escalade seront confirmés avec le commanditaire. « Système » désigne l'application et ses intégrations, pas une personne.

| Traitement MCT | Responsable de l'action | Quand et déclenchement | Où et avec quel moyen | Contrôle et trace attendus |
|---|---|---|---|---|
| T-01 Demander OTP | Client ou gérant ; système pour l'émission | À la demande, tout moment | Interface web sur téléphone ; fournisseur SMS | Numéro normalisé, quotas, tentative datée sans code en clair. |
| T-02 Vérifier OTP | Client ou gérant ; système pour la vérification | À réception du code, dans sa période de validité | Interface de connexion ; service d'identité | Une utilisation, limites de tentatives, session et échec enregistrés sans secret. |
| T-03 Constituer KYC | Gérant partenaire | Avant toute activation, selon sa disponibilité | Espace partenaire ; stockage privé des pièces | Champs et fichiers requis, état brouillon/soumis, accusé de dépôt. |
| T-04 Décider KYC | Administrateur Keke Beauty habilité | Après soumission, durant la plage de traitement à définir | Back-office ; consultation privée des justificatifs | Décision et motif, acteur/date, resoumission ou activation tracés. |
| T-05 Gérer la fiche | Gérant habilité ; système contrôle la publication | Après validation et à chaque modification | Espace partenaire ; stockage des médias | Propriété du salon, tarif valide, visibilité et changement historisés. |
| T-06 Rechercher | Client ; système calcule | À chaque recherche | Interface annuaire, base et service cartographique | Filtres cohérents, salons publiés seulement, repli si géolocalisation refusée. |
| T-07 Demander RDV | Client ; système enregistre | À la sélection d'un créneau | Fiche établissement et calendrier | Droit à réserver, capacité, concurrence, référence de demande ; règle de blocage ouverte. |
| T-08 Confirmer/refuser | Gérant partenaire ; système applique | Lorsqu'une demande arrive ; délai à définir | Tableau de bord partenaire | État permis, conflit de capacité, décision et notification. |
| T-09 Annuler/reprogrammer | Acteur autorisé à définir ; système applique | Après demande ou confirmation, selon délais à définir | Espaces client/partenaire selon droits | Auteur, ancien/nouveau créneau, motif et accord éventuel du client. |
| T-10 Notifier RDV | Système ; support si échec durable | Après événement de RDV, avec reprise automatique | SMS et centre de notifications de l'application | Destinataire, contenu, tentatives et état d'envoi sans doublon. |
| T-11 Souscrire | Gérant partenaire ; système établit le contrat | À l'activation d'une offre | Espace partenaire ; catalogue d'offres | Tarif et conditions acceptés, durée minimale d'un an, échéancier. |
| T-12 Initier paiement | Gérant partenaire ; système et agrégateur | À chaque échéance payable | Parcours de paiement fournisseur | Référence unique, montant/devise et état initial. |
| T-13 Rapprocher paiement | Système ; administrateur financier pour exception | À l'arrivée du résultat vérifié et lors de contrôles périodiques | Intégration serveur de l'agrégateur ; back-office pour écarts | Authenticité, idempotence, transaction et activation des droits auditées. |
| T-14 Traiter échéance | Système ; administrateur financier en supervision | Aux dates d'échéance et de relance | Traitement planifié et tableau de bord financier | Paiement récent, grâce, relance, suspension et rétablissement selon contrat. |
| T-15 Modérer | Administrateur Keke Beauty habilité | Après signalement ou contrôle | Back-office | Motif, auteur/date, impact sur fiche/RDV/droits et possibilité de rétablissement. |

## Responsabilités à confirmer

- **Product Owner** : valide les règles et priorise les exceptions métier ; il n'exécute pas automatiquement les opérations administratives.
- **Administrateur KYC** : accès limité aux justificatifs nécessaires et décision explicite avant activation.
- **Administrateur financier** : examine les paiements à rapprocher et les impayés, sans pouvoir fabriquer un encaissement confirmé.
- **Support** : traite les incidents OTP, rendez-vous et notifications selon des droits distincts à définir.

## Organisation des cas dégradés

| Incident | Détection | Première action | Escalade à définir |
|---|---|---|---|
| SMS OTP indisponible | Échec fournisseur ou délai dépassé | Afficher l'échec sans créer de session ; limiter les renvois | Support technique et fournisseur SMS |
| Créneau devenu indisponible | Vérification serveur lors de T-07/T-08 | Refuser proprement et proposer une nouvelle sélection | Partenaire si incohérence persistante |
| Paiement en attente ou contradictoire | Retour fournisseur et rapprochement T-13 | Maintenir le droit non confirmé ; rechercher la preuve fournisseur | Administrateur financier puis agrégateur |
| Pièce KYC illisible | Examen T-04 | Demander une correction avec motif, sans activation | Administrateur KYC |
| Notification non délivrée | Tentatives T-10 | Reprise contrôlée, statut d'échec visible | Support et fournisseur |

Les horaires précis, délais de traitement, personnes nommées et canaux d'escalade appartiennent au MOT final. Le présent document n'impose aucune permanence 24 h/24 que le cahier des charges n'a pas demandée.

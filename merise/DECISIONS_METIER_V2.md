# Décisions métier V2 — dernières réponses du porteur de projet

> Les cinq questions ont été résolues par la décision « paramétrable ». Référence courante : [CONCEPTION_MERISE_V2.md](CONCEPTION_MERISE_V2.md), MLD_V2 et MPD 020. Les sections ci-dessous conservent le cadrage historique. PostgreSQL V2 est désormais chargé et testé : voir VERIFICATION_V2.md.

Ces réponses remplacent les décisions contradictoires V1. La conception, le MLD et le SQL V1 ne sont plus la cible validée et ne doivent pas être chargés comme modèle final. Ce document enregistre les décisions ; il ne prétend pas que leur traduction SQL est déjà réalisée.

## Décisions confirmées

| Sujet | Nouvelle règle | Conséquence |
|---|---|---|
| Marché | Côte d'Ivoire et XOF au lancement ; ambition panafricaine. | Conserver les référentiels pays, devises et fuseaux extensibles ; pas de lancement multi-pays immédiat. |
| Gestion | Plusieurs établissements par gérant et plusieurs gestionnaires possibles ; le gérant paie pour l'ensemble des établissements. | Introduire le payeur et le périmètre d'établissements couverts ; ne plus supposer un contrat indépendant par salon. Tarification par groupe ou par établissement à préciser. |
| Prestations | Plusieurs prestations possibles dans le même établissement ; le salon prend ensuite en charge la réalisation. | La réservation multiple reste possible ; prix/durées fixes et détail de la sélection en ligne non confirmés par cette réponse. |
| Confirmation | L'établissement doit accepter la réservation pour s'engager. | Demande → en attente du salon → acceptée ou refusée ; supprimer la confirmation automatique initiale. |
| Paiement des soins | Le client paie sur place ; la plateforme n'intervient pas. | Retirer avances, encaissements client et remboursements client du périmètre applicatif. Ne pas imposer un moyen de paiement sur place : « sur place » ne signifie pas exclusivement espèces. Les abonnements partenaires restent un domaine de paiement distinct. |
| Annulation/report | Autorisés jusqu'à une heure avant, une seule fois dans un établissement. | Remplace le délai de quatre heures. La portée du compteur « une seule fois » doit être précisée avant implémentation. Aucun remboursement géré par la plateforme. |
| Impayé | Aucun délai de grâce ; établissement désactivé. | Remplace les sept jours de grâce. Portée de la désactivation et établissements touchés par un impayé groupé à préciser. |

## Questions restantes qui changent le modèle

1. Capacité : combien de clients le salon peut-il servir au même moment ? Le salon choisit-il seulement un nombre (ex. 3), ou faut-il gérer séparément les disponibilités de chaque employé et/ou équipement ? L'acceptation manuelle ne suffit pas à prévenir deux acceptations concurrentes incompatibles.
2. Attente : une demande non encore acceptée bloque-t-elle temporairement une place ? Quelle durée de réponse du salon ? Aucun maintien de paiement de dix minutes n'est repris implicitement.
3. Limite d'annulation/report : une fois par RDV, ou une fois pour toutes les réservations d'un client dans le même salon ? Annulation et report partagent-ils ce compteur ?
4. Paiement groupé : un forfait global, ou une somme calculée selon le nombre d'établissements ? Quels établissements sont couverts par chaque échéance ? Un gestionnaire n'est pas automatiquement le payeur.
5. Désactivation : fiche masquée et nouvelles réservations interdites ? Les rendez-vous déjà acceptés restent-ils visibles et gérables ? Ne pas les annuler silencieusement.
6. Prestations : sélectionner plusieurs prestations dans la demande en ligne ou convenir des prestations supplémentaires directement au salon ? Durées nécessaires seulement si calcul de créneaux par l'application.

## Impacts MERISE à réaliser

- RG/DD : nouveau statut EN_ATTENTE_SALON, décision du salon et auteur/date ; limite de modification et son périmètre ; payeur et couverture du contrat.
- MCD/MLD : compte payeur distinct des gestionnaires, contrat associé à ses établissements couverts ; supprimer le domaine des paiements de soins. Les relations de paiement d'abonnements restent nécessaires.
- MCT/MOT : notification de demande au salon, acceptation/refus par un gestionnaire habilité, confirmation au client seulement après acceptation atomique ; désactivation à impayé sans grâce.
- MPD/audit 3FN : réviser les clés, liens et contraintes après les précisions. Aucun déploiement du V1 comme cible métier.

## État PostgreSQL

Docker Desktop démarré ; conteneur `kekebeauty-merise-db-1` PostgreSQL 17 sain à la dernière observation. Base `keke_merise`, volume dédié, aucun port hôte publié. Le chargement de `010_modele_v1.sql` et les tests ont été refusés avant exécution par la vérification automatique d'autorisation, en raison d'un quota d'utilisation atteint. Aucun résultat de test PostgreSQL à annoncer. Les scripts de test V1 sont conservés comme historiques à adapter à V2.

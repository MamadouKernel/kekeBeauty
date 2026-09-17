# Plan de conception et livraison Scrum

## État de la conception

La conception du produit complet n'est pas terminée. Elle est volontairement livrée par incréments afin que chaque sprint aboutisse à un parcours testable, démontrable et améliorable.

| Périmètre | État design | État produit |
| --- | --- | --- |
| Fondations visuelles et PWA | Référentiel défini dans `DESIGN.md` | Intégré ; recette sur appareils réels à faire |
| Découverte, recherche et fiche établissement | Maquettes mobiles disponibles | Intégré ; harmonisation, carte et accessibilité à finir |
| Demande de rendez-vous | Parcours principal défini | Créneaux, horaires, capacité, création et expiration intégrés |
| Gestion partenaire des rendez-vous | Conception partielle | Décision, report et clôture à compléter |
| Onboarding partenaire et KYC | À concevoir | Services configurables préparés, interface métier à réaliser |
| Abonnement et paiement | À concevoir | Connecteurs configurables préparés, parcours à réaliser |
| Administration | À concevoir | À réaliser |

## Mode de travail Scrum

Chaque sprint dure deux semaines. Le Product Owner priorise les résultats métier et accepte les stories. Le Scrum Master protège la cadence et traite les obstacles. L'équipe conçoit, développe, teste et démontre un incrément utilisable.

Le design travaille un sprint en avance sur les fonctionnalités suivantes, sans chercher à figer toute l'application. Une story passe par les étapes suivantes :

1. Affiner le besoin, les règles métier et les cas limites.
2. Produire le flux, les états vide/chargement/erreur et les variantes mobile/ordinateur nécessaires.
3. Valider les critères d'acceptation avec le Product Owner.
4. Développer le parcours vertical, données et interface comprises.
5. Vérifier les tests automatisés, l'accessibilité, le responsive et les appareils ciblés.
6. Démontrer l'incrément en Sprint Review et intégrer les retours au backlog.
7. Améliorer la méthode en rétrospective sans modifier silencieusement l'objectif du sprint.

## Sprint courant : gestion des rendez-vous

**Objectif :** permettre à un établissement de traiter une demande de rendez-vous de bout en bout, avec des disponibilités fiables et une information claire du client.

| Priorité | Élément de backlog | Critère d'acceptation | État |
| --- | --- | --- | --- |
| P0 | Créneaux issus des horaires réels | Fermetures, exceptions, durée et capacité sont respectées côté serveur | Terminé |
| P0 | Création concurrente fiable | Le créneau est revalidé en transaction avant confirmation | Terminé |
| P0 | Expiration automatique | Une demande non traitée expire de façon idempotente et notifie le client | Terminé |
| P0 | Décision partenaire | Le partenaire peut accepter ou refuser une demande autorisée | Terminé |
| P0 | Reprogrammation client | Le client choisit un nouveau créneau valide ; l'échec conserve l'ancien rendez-vous | Terminé |
| P1 | Proposition de report partenaire | Le partenaire propose un créneau que le client accepte ou refuse | Bloqué par décision métier |
| P1 | Clôture du rendez-vous | Le partenaire peut marquer réalisé ou absent avec traçabilité | À faire |
| P1 | Notification SMS | La file configurable envoie via le fournisseur actif et conserve les échecs | À faire |
| P1 | Design du tableau de bord partenaire | Liste, détail, actions, erreurs et états responsive validés | À faire |

## Définition de terminé

Une story est terminée lorsque :

- ses critères d'acceptation sont vérifiés sur le parcours réel ;
- les permissions, erreurs, chargements et états vides sont traités ;
- les tests adaptés au risque passent sans régression connue ;
- l'interface est vérifiée au clavier, en mobile et en ordinateur ;
- la documentation de configuration et d'exploitation est à jour ;
- le code est revu, commité et poussé ;
- l'incrément est démontrable en Sprint Review.

## Prochain incrément de design

Pendant la réalisation de la décision et du report des rendez-vous, la conception prépare le tableau de bord partenaire : file des demandes, agenda, détail d'un rendez-vous, acceptation, refus, proposition d'un autre créneau et clôture. Le sprint suivant pourra ainsi commencer avec des stories prêtes.

## Points bloquants à piloter

- Le logo final parmi les propositions fournies n'est pas sélectionné. La signature textuelle reste le repli configurable.
- Les rôles nominatifs Product Owner et Scrum Master ne sont pas encore renseignés.
- Les paramètres commerciaux de l'abonnement restent à valider.
- Les comptes réels SMS, paiement et cartographie ne sont pas fournis ; leurs intégrations restent désactivables et configurables.
- La recette tactile, les appareils cibles et les tests avec des utilisateurs ne sont pas encore planifiés.

Ces points ne bloquent pas la poursuite du développement local du sprint courant. Ils bloquent respectivement la validation finale de marque, certaines décisions produit et la recette des intégrations externes.

# Keke Beauty — Modèle conceptuel des données initial

Statut : **proposition à valider**. Le MCD décrit les objets du métier et leurs associations sans type SQL ni clé étrangère. Les cardinalités marquées « hypothèse » dépendent des réponses au questionnaire. Une cardinalité `0,N` signifie zéro ou plusieurs occurrences ; `1,1` signifie exactement une occurrence.

## Entités et identifiants conceptuels

| Entité | Identifiant | Propriétés métier principales | Références |
|---|---|---|---|
| Compte | identifiant compte | téléphone vérifié, état du compte | RG-001, DD-001 |
| Gérant | identifiant gérant | identité déclarée ; l'état de vérification est porté par le dossier KYC | RG-002/003, DD-003/027 |
| Établissement | identifiant établissement | nom, description, téléphone de service, coordonnées GPS, état de publication | RG-002/006, DD-005 à DD-009 |
| Dossier KYC | identifiant dossier | état, date de soumission, décision, motif éventuel | RG-003/016, DD-027 |
| Justificatif KYC | identifiant justificatif | type de pièce, référence privée de fichier, état | RG-003/016, DD-004 |
| Catégorie | identifiant catégorie | nom, état | RG-005, DD-010 |
| Pays | identifiant pays | nom | RG-005, DD-011 |
| Région | identifiant région | nom | RG-005, DD-012 |
| Ville | identifiant ville | nom | RG-005, DD-013 |
| Commune | identifiant commune | nom | RG-005, DD-014 |
| Média | identifiant média | nature photo/vidéo, référence de fichier, ordre | RG-006, DD-015 |
| Prestation | identifiant prestation | nom, description, durée si validée, état | RG-004, DD-016 |
| Tarif prestation | identifiant tarif | montant, devise, date d'effet éventuelle | RG-004, DD-017 |
| Plage d'ouverture | identifiant plage | jour, heure de début et de fin | RG-002, DD-008 |
| Exception d'ouverture | identifiant exception | date, fermeture ou horaires dérogatoires | RG-002, DD-008 |
| Rendez-vous | identifiant rendez-vous | date/heure, état, date de demande | RG-007 à RG-009/017, DD-018 à DD-020 |
| Événement de rendez-vous | identifiant événement | type, date/heure, auteur, motif éventuel | RG-009/010, DD-020 |
| Notification | identifiant notification | événement déclencheur, canal, état d'envoi | RG-010, DD-021 |
| Offre | identifiant offre | nom, fonctionnalités incluses, état | RG-011/012, DD-022 |
| Tarif d'offre | identifiant tarif d'offre | montant, devise, périodicité, date d'effet | RG-012, DD-022/024 |
| Contrat | identifiant contrat | début, fin minimale, périodicité, montant accepté, état | RG-011/012, DD-023/024 |
| Échéance | identifiant échéance | période due, montant, devise, état | RG-011/014, DD-025 |
| Paiement | identifiant paiement | référence, canal, montant, devise, état | RG-013/014, DD-026 |

Les identifiants sont conceptuels. Le lien entre `Compte` et `Gérant` ainsi que les rôles administrateur/partenaire seront précisés avec le modèle d'accès. Un gérant est une personne métier ; le compte est le moyen d'authentification.

## Associations et cardinalités

| Association | Côté A | Côté B | État et justification |
|---|---|---|---|
| gère | Gérant `0,N` | Établissement `1,N` | Hypothèse : au moins un gérant pour publier ; plusieurs gérants à confirmer (question 05). |
| possède un dossier | Gérant `0,N` | Dossier KYC `1,1` | Hypothèse : chaque soumission possède son propre dossier pour conserver l'historique. |
| contient | Dossier KYC `0,N` | Justificatif KYC `1,1` | Un brouillon peut être vide ; au moins une pièce est obligatoire avant soumission. Le nombre et les types requis restent à confirmer. |
| est situé dans | Établissement `1,1` | Commune `0,N` | Hypothèse : rattachement au niveau commune ; absence de commune à traiter selon pays choisi. |
| appartient à | Commune `1,1` | Ville `0,N` | Hiérarchie du CDC. |
| appartient à | Ville `1,1` | Région `0,N` | Hiérarchie du CDC. |
| appartient à | Région `1,1` | Pays `0,N` | Hiérarchie du CDC. |
| est classé dans | Établissement `1,N` | Catégorie `0,N` | Hypothèse : plusieurs catégories possibles ; à confirmer (question 06). |
| présente | Établissement `0,N` | Média `1,1` | Un média appartient à une fiche. |
| propose | Établissement `0,N` | Prestation `1,1` | Une prestation est propre à un établissement dans la première version. |
| reçoit un tarif | Prestation `1,N` | Tarif prestation `1,1` | Hypothèse : conserver l'historique des tarifs ; date d'effet à confirmer. |
| ouvre selon | Établissement `0,N` | Plage d'ouverture `1,1` | Horaires réguliers. |
| modifie ses horaires | Établissement `0,N` | Exception d'ouverture `1,1` | Fermetures et dérogations. |
| demande | Compte client `0,N` | Rendez-vous `1,1` | Un RDV possède un demandeur authentifié. |
| concerne | Établissement `0,N` | Rendez-vous `1,1` | Un RDV concerne un salon. |
| porte sur | Prestation `0,N` | Rendez-vous `1,1` | Hypothèse : une seule prestation par RDV (question 10). |
| produit | Rendez-vous `0,N` | Événement de rendez-vous `1,1` | Les transitions sont historisées. |
| déclenche | Événement de rendez-vous `0,N` | Notification `1,1` | Un événement peut déclencher plusieurs canaux. |
| souscrit | Établissement `0,N` | Contrat `1,1` | Un établissement peut avoir plusieurs contrats dans le temps. |
| relève de | Offre `0,N` | Contrat `1,1` | L'offre choisie est connue au moment de souscrire. |
| possède un tarif | Offre `0,N` | Tarif d'offre `1,1` | Tarifs modifiables et historisés. |
| crée | Contrat `1,N` | Échéance `1,1` | Engagement annuel, facturation mensuelle ou annuelle ; nombre exact selon règle validée. |
| règle | Échéance `0,N` | Paiement `1,1` | Hypothèse : plusieurs tentatives pour une échéance ; paiements fractionnés à confirmer. |

## Réservation et capacité : association encore ouverte

Le cahier des charges ne permet pas de choisir une cardinalité unique pour la ressource réservée. Les trois modèles possibles sont :

1. **Employé** : un RDV affecte un employé ; les horaires individuels et compétences par prestation deviennent des entités/associations.
2. **Ressource** : un RDV affecte une cabine, un poste ou un équipement ; sa disponibilité et sa compatibilité avec la prestation sont modélisées.
3. **Capacité globale** : un établissement fixe une capacité par intervalle ; les RDV consomment des unités de capacité.

La réponse à la question 09 du questionnaire détermine les entités et associations supplémentaires. La question 11 détermine si une demande en attente consomme déjà la capacité. Le MLD et le MPD de réservation ne seront pas figés avant ces réponses.

## Contrôle avant passage au MLD

- Valider les cardinalités avec des exemples réels : salon sans prestation, gérant avec deux salons, demande en attente, contrat renouvelé.
- Définir les dépendances fonctionnelles et clés candidates de chaque future relation, notamment les associations plusieurs à plusieurs.
- Reprendre les objets répétés (médias, prestations, plages, échéances) comme occurrences distinctes pour la 1FN.
- Vérifier la dépendance complète à la clé pour la 2FN et l'absence de transitivité pour la 3FN après transformation en MLD.

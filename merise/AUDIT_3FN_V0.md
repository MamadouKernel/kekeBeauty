# Keke Beauty — Audit initial des 1FN 2FN et 3FN

> Version de référence : [Conception MERISE V1](CONCEPTION_MERISE_V1.md) — décisions validées, DD, MCD, MLD, MCT, MOT, MPD et audit actualisés. Cette V0 est conservée pour historique ; ses hypothèses remplacées ne sont plus applicables.

Portée : les 19 relations détaillées du [MLD initial](MLD_V0.md) et reprises dans le [DDL candidat](mpd/001_socle_provisoire.sql). Cet audit repose sur les dépendances fonctionnelles **actuellement connues**. Les domaines RDV et abonnements n'ont pas encore de MPD et ne peuvent pas être déclarés conformes.

Pour chaque relation, la 1FN exige une occurrence par ligne et des attributs élémentaires au sens du métier ; la 2FN exclut une propriété qui dépend seulement d'une partie d'une clé composée ; la 3FN exclut une propriété non-clé qui dépend transitivement d'une clé via une autre propriété non-clé. Une clé technique ne prouve pas ces propriétés à elle seule.

| Relation | Clé candidate retenue ou conditionnelle | Dépendances à contrôler | Conclusion provisoire |
|---|---|---|---|
| PAYS | `pays_id` ; `nom` seulement si référentiel unique | `pays_id → nom` | 1FN : nom simple. 2FN : clé simple. 3FN : aucune propriété transitive connue. |
| REGION | `region_id` ; (`pays_id`, `nom`) si noms uniques par pays | `region_id → pays_id, nom` | Nom du pays absent. Si clé naturelle retenue, nom de région dépend du couple pays/région, pas du seul pays. |
| VILLE | `ville_id` ; (`region_id`, `nom`) si référentiel le garantit | `ville_id → region_id, nom` | Nom de région/pays absent ; clé naturelle à réexaminer si homonymies. |
| COMMUNE | `commune_id` ; (`ville_id`, `nom`) si référentiel le garantit | `commune_id → ville_id, nom` | Nom de ville/région/pays absent ; pas de transitivité connue. |
| CATEGORIE | `categorie_id` | `categorie_id → nom, etat` | Une catégorie par ligne ; clé simple ; pas de propriété d'une autre catégorie. |
| COMPTE | `compte_id` ; `telephone_normalise` si unicité validée | `compte_id → telephone, date de vérification, état` ; téléphone → compte si unique | Téléphone élémentaire ; aucune propriété de rôle ou gérant ; politique d'unicité encore ouverte. |
| ROLE | `role_id`, `code` | `role_id → code, libelle` et `code → role_id, libelle` | `code` est une clé alternative, donc sa détermination du libellé respecte la 3FN. |
| COMPTE_ROLE | (`compte_id`, `role_id`) | Couple → existence de l'association | Pas de colonnes répétées ni d'attribut dépendant du seul compte ou rôle ; 1FN/2FN/3FN. |
| GERANT | `gerant_id` ; `compte_id` si un compte = un gérant | `gerant_id → compte_id, nom_declare` | Téléphone/état KYC absents ; une alternative de clé simple n'introduit pas de dépendance partielle. |
| ETABLISSEMENT | `etablissement_id` | Identifiant → commune, nom, description, téléphone, latitude, longitude, état | Une position par fiche ; les libellés territoriaux et données du gérant sont absents. |
| GERANT_ETABLISSEMENT | (`gerant_id`, `etablissement_id`) | Couple → existence du droit de gestion | Aucune identité de gérant ou nom de salon recopié ; 1FN/2FN/3FN. |
| ETABLISSEMENT_CATEGORIE | (`etablissement_id`, `categorie_id`) | Couple → association de classement | Aucune propriété propre à un seul côté ; 1FN/2FN/3FN. |
| MEDIA | `media_id` ; référence de fichier si unicité globale validée | `media_id → salon, nature, référence, ordre, état` | Un média par ligne ; nom de salon absent. L'ordre unique par salon devra être validé. |
| PRESTATION | `prestation_id` | `prestation_id → salon, nom, description, état` | Une prestation par ligne ; tarif et nom de salon absents. |
| TARIF_PRESTATION | `tarif_id` ; (`prestation_id`, `date_effet`) si historique et date non nulle | `tarif_id → prestation, montant, devise, date` | Chaque tarif est un fait daté ; montant et devise ne dépendent pas du seul `prestation_id` si historique retenu. |
| PLAGE_OUVERTURE | `plage_id` ; clé naturelle à définir | `plage_id → salon, jour, début, fin` | Une plage par ligne ; aucun horaire en colonnes répétées ; nom du salon absent. |
| EXCEPTION_OUVERTURE | `exception_id` ; clé naturelle à définir | `exception_id → salon, date, début, fin, ferme` | Une exception par ligne ; aucune propriété du salon dupliquée. Plusieurs plages peuvent exister le même jour. |
| DOSSIER_KYC | `dossier_id` | `dossier_id → gérant, état, dates, décideur, motif` | Historique en dossiers distincts ; identité du gérant et nom du décideur absents. |
| JUSTIFICATIF_KYC | `justificatif_id` | `justificatif_id → dossier, type, référence privée, état` | Une pièce par ligne ; décision et identité du gérant absentes. |

## Points qui empêchent la certification finale

1. Le référentiel géographique peut révéler des clés naturelles ou homonymies différentes de celles envisagées.
2. Les politiques de téléphone, compte de gérant, ordre des médias et histoire des tarifs détermineront des clés alternatives à tester.
3. Les états KYC et les règles de resoumission peuvent nécessiter une relation distincte de décision si plusieurs décisions sont conservées dans un même dossier.
4. Les RDV, ressources, contrats, échéances et paiements n'ont pas encore leurs dépendances fonctionnelles validées. Leur 3FN sera prouvée relation par relation dans une version suivante.
5. Le DDL candidat n'a pas été exécuté sur PostgreSQL. L'audit logique ne remplace pas les essais de contraintes et migrations.

Résultat : **19 relations de socle compatibles avec les 1FN, 2FN et 3FN sous les hypothèses indiquées**, sans certification de l'ensemble du projet. Toute règle validée ou colonne ajoutée impose de refaire cet audit.

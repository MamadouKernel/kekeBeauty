# Keke Beauty — du démarrage à la livraison

## Point de départ

Le cahier des charges décrit trois parcours : client, établissement et administration. Le [backlog détaillé](BACKLOG_SCRUM_KEKE_BEAUTY.md) propose 84 éléments en 12 sprints de deux semaines. Il s'agit d'une prévision, à réestimer selon l'équipe et les plateformes retenues. Un premier projet Blazor .NET 10 existe dans `src/KekeBeauty.Web` et affiche une fiche fictive de démonstration ; il ne comporte encore aucun modèle de données métier.

La première activité est **KB-001 : valider le périmètre et les décisions produit**. Le premier incrément attendu à la fin du sprint 1 est une **fiche de salon de démonstration utilisable sur un environnement de recette**, accompagnée d'un socle de livraison automatisé. Les choix ouverts du cahier des charges restent des décisions à prendre avec le Product Owner.

## Parcours de réalisation

| Étape | Livrable vérifiable | Repère Scrum |
|---|---|---|
| 1. Cadrer | Pays, devise, plateformes, acteurs, périmètre de lancement, règles de RDV et abonnement, critères de réussite et responsables | Sprint 1, KB-001/002 |
| 2. Concevoir avec MERISE | Règles de gestion numérotées, dictionnaire des données (DD), MCD et MCT ; après validation, MLD et MOT ; enfin MPD et migrations | Début sprint 1, puis affinement dans chaque sprint |
| 3. Installer le socle | Dépôt .NET 10, application ASP.NET Core, interface web adaptée au téléphone, environnement de recette, chaîne de build/test, séparation des secrets | Sprint 1, KB-004/005/006 |
| 4. Ouvrir le service | OTP, rôles, dossier KYC, contrôle administratif, catalogue et fiche publiée | Sprints 2–3 |
| 5. Permettre la découverte | Catégories et zones, géolocalisation avec repli manuel, recherche, appel et itinéraire | Sprint 4 |
| 6. Réserver et gérer | Horaires, capacité, calendrier, demandes sans conflit, validation/refus/reprogrammation et notifications | Sprints 5–6 |
| 7. Encaisser et administrer | Contrat d'un an, paiement mensuel/annuel, Mobile Money, cartes, droits, renouvellements, finances et modération | Sprints 7–9 |
| 8. Préparer la sortie | Compatibilité des plateformes retenues, sécurité, performance, accessibilité, sauvegarde/restauration, recette et formation | Sprints 10–11 |
| 9. Mettre en service | Décision go/no-go, migration et retour arrière répétés, publication, vérification en production et ouverture aux partenaires pilotes | Sprint 11 |
| 10. Stabiliser et transférer | Incidents corrigés, premiers paiements rapprochés, documentation d'exploitation, bilan et backlog d'amélioration | Sprint 12 |

## Chaîne MERISE et contrôle des 3FN

Les règles de gestion définissent les invariants ; le DD définit les données. Le MCD décrit les entités et cardinalités, le MCT les événements et résultats. Le MLD transforme les associations en relations ; le MOT attribue les traitements aux acteurs, moments et moyens. Le MPD choisit les types SQL, clés, contraintes et index pour la base retenue. Chaque fonctionnalité fait évoluer ces livrables et garde une trace vers son élément KB.

Contrôle formel de **chaque relation du MLD et du MPD**, y compris après une migration :

1. Inventorier les clés candidates et dépendances fonctionnelles, sans se contenter d'une clé artificielle.
2. **1FN :** valeurs élémentaires au sens métier, aucun groupe répétitif (par exemple, `Prestation1`, `Prestation2` ou une liste de prestations dans `Etablissement`).
3. **2FN :** tout attribut non-clé dépend de la clé entière, notamment dans les associations à clé composée.
4. **3FN :** aucune dépendance transitive entre clé et attribut non-clé ; les libellés de ville et les tarifs d'offre courants restent dans leurs relations propres.
5. Vérifier la cohérence des clés étrangères, unicités et contraintes métier. Une projection de recherche ou un rapport éventuel ne devient pas la source de vérité du modèle normalisé.

Exemple : `Etablissement(id, ville_id, ...)`, `Ville(id, nom, region_id)` et `Region(id, nom, pays_id)` évitent de recopier la hiérarchie géographique dans chaque salon. Un montant accepté sur un contrat est un **fait historique du contrat** ; il n'est pas une copie à mettre à jour lorsqu'un administrateur change le tarif de l'offre.

## Technologie proposée pour le démarrage

- **API et logique métier :** ASP.NET Core 10/C#, en monolithe modulaire (identité, établissements, catalogue, réservation, abonnement, paiement et administration).
- **Interface :** Blazor Web App responsive pour les trois acteurs. Installation PWA à planifier après validation du périmètre ; notifications SMS et dans l'application indispensables au parcours.
- **Données :** PostgreSQL/PostGIS et EF Core/Npgsql, sous réserve de validation des contraintes d'hébergement et du choix de SGBD lors de KB-004.
- **Fichiers :** stockage objet privé pour les justificatifs KYC et stockage adapté aux médias ; la base ne conserve que leurs métadonnées et références.
- **Intégrations :** adaptateurs pour SMS, cartographie et agrégateur de paiement, choisis après essais avec des comptes de test.

Un MLD, un MOT et un MPD **provisoires** couvrent désormais les domaines déjà stables. Le DDL candidat PostgreSQL n'est pas une migration. Le MPD approuvé, les migrations et les fournisseurs définitifs seront établis **après** validation des règles et du MLD. Le démarrage technique peut parallèlement mettre en place la compilation et une fiche de démonstration sans prétendre figer le schéma métier.

## Point d'arrivée et critères de sortie

La livraison initiale se termine quand un client peut découvrir, contacter et réserver un établissement vérifié ; qu'un partenaire peut gérer son offre, ses RDV et son abonnement ; et qu'un administrateur peut valider, modérer et suivre les encaissements. Les parcours doivent être testés sur la ou les plateformes retenues avec des paiements vérifiés côté serveur et des notifications fiables.

Le dossier de sortie comprend : traçabilité CDC ↔ KB ↔ règles MERISE ↔ tests, modèles MERISE et MPD à jour, procédures de déploiement/restauration et d'exploitation, recette acceptée, formation des opérateurs, surveillance du lancement et backlog d'amélioration. Les stores mobiles ne sont concernés que si le Product Owner les retient.

## Décisions nécessaires pour lancer le premier sprint

| Décision | Valeur provisoire de travail | Impact |
|---|---|---|
| Pays de lancement et devise | À valider | Zones, OTP, paiements, conservation des données |
| Plateforme de lancement | Web responsive ; PWA à confirmer | Charge, distribution et tests |
| Rôles Product Owner, Scrum Master et équipe | À nommer | Priorités et capacité des sprints |
| Date de début et disponibilité de l'équipe | À renseigner | Calendrier réel et engagement de délai |
| Règles de réservation | À confirmer avec salons pilotes | Cardinalités du MCD et prévention des conflits |
| Offre, tarif, impayés et renouvellement | À définir | MCD, MCT, paiement et droits |
| Fournisseurs SMS, carte et paiement | Tests à effectuer | Coût, pays couverts et accès de production |

Ces décisions sont inscrites au sprint 1. Tant qu'elles ne sont pas prises, les modèles métier restent provisoires et le calendrier de 24 semaines n'est pas contractuel.

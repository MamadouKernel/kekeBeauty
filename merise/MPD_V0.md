# Keke Beauty — Modèle physique des données initial

Statut : **proposition technique non déployée**. Ce MPD applique le MLD initial aux domaines de référence, annuaire, catalogue et KYC avec PostgreSQL comme SGBD de travail. Le choix définitif du SGBD, du pays, des rôles et des règles de réservation doit encore être confirmé. Le fichier [DDL candidat](mpd/001_socle_provisoire.sql) est destiné à une base isolée de conception ; il n'est ni une migration approuvée ni une instruction de mise en production.

## Conventions physiques

| Objet | Choix provisoire | Motif et contrôle |
|---|---|---|
| Identifiants | `bigint GENERATED ALWAYS AS IDENTITY` et clé primaire | Identifiant stable ; les clés candidates métier restent auditées séparément. |
| Texte | `varchar` borné pour code/nom/numéro, `text` pour description/motif | La longueur définitive sera validée par le DD ; pas de champ contenant une liste de valeurs métier. |
| Montant | `numeric(12,2)` et devise `char(3)` | Les montants ne sont pas stockés en flottant ; précision et devise à confirmer. |
| Position GPS | latitude et longitude `numeric(9,6)` avec bornes | Une recherche spatiale PostGIS pourra être ajoutée après choix d'infrastructure, sans recopier les libellés géographiques. |
| Horaires | `time`, `date` et `timestamptz` selon la donnée | Les horaires du salon et les dates d'événement ont des usages différents ; fuseau de réservation à définir. |
| Médias et justificatifs | Référence de fichier et métadonnées seulement | Les pièces KYC résident dans un stockage privé, hors des tables relationnelles. |
| Intégrité | PK, FK, unicités établies et contrôles élémentaires | Les règles entre plusieurs lignes, par exemple non-chevauchement, ne peuvent pas être garanties par un simple `CHECK` de ligne. |

## Correspondance et couverture

Le DDL candidat crée les **19 relations détaillées** du MLD : PAYS, REGION, VILLE, COMMUNE, CATEGORIE, COMPTE, ROLE, COMPTE_ROLE, GERANT, ETABLISSEMENT, GERANT_ETABLISSEMENT, ETABLISSEMENT_CATEGORIE, MEDIA, PRESTATION, TARIF_PRESTATION, PLAGE_OUVERTURE, EXCEPTION_OUVERTURE, DOSSIER_KYC et JUSTIFICATIF_KYC. Les domaines Rendez-vous, Notification, Offre, Contrat, Échéance et Paiement restent hors de ce DDL jusqu'à validation de leurs règles.

## 3FN dans le MPD

Le MPD ne stocke pas `ville_nom`, `region_nom` ou `pays_nom` dans ETABLISSEMENT ; ces valeurs sont accessibles par FK. PRESTATION ne contient ni nom d'établissement ni montant courant ; ses tarifs sont des occurrences de TARIF_PRESTATION. Les associations plusieurs à plusieurs ont une ligne par paire et une clé composée. GERANT ne duplique pas l'état des dossiers KYC. Les clés candidates supplémentaires encore inconnues sont indiquées dans le MLD et ne sont pas artificiellement déclarées uniques ici. L'[audit relation par relation](AUDIT_3FN_V0.md) consigne la vérification provisoire des 1FN, 2FN et 3FN.

Ce contrôle reste **conditionnel** aux dépendances fonctionnelles réellement confirmées. Une future contrainte d'unicité, un champ métier ou une migration impose un nouvel audit 1FN/2FN/3FN. Les états, taxes, prestations multiples par RDV et droits d'abonnement doivent être détaillés avant leur MPD.

## Validation restante

1. Installer ou obtenir une base PostgreSQL de test isolée ; exécuter le DDL dans une transaction de recette, puis inspecter les tables, PK, FK et index créés.
2. Tester insertions valides, FK inexistantes, latitude invalide, montant négatif, doublons de rôle et d'association. Aucun test PostgreSQL n'a été exécuté dans cet environnement faute de serveur/CLI disponible.
3. Valider avec le Product Owner les longueurs, règles d'unicité, cardinalités et conservation KYC avant de convertir ce candidat en migration versionnée.
4. Concevoir ensuite les domaines réservation et abonnement, avec leurs règles de concurrence, d'historique et de paiement vérifié.

Référence SQL pour les contraintes PostgreSQL : https://www.postgresql.org/docs/current/ddl-constraints.html.

# Keke Beauty

Première version du projet en cours de cadrage. Les livrables MERISE sont dans `merise/` et la trajectoire Scrum dans `planning/`.

## État actuel

- **Référence actuelle : [Conception MERISE V1](merise/CONCEPTION_MERISE_V1.md)**, intégrant les dix décisions acceptées. [MLD détaillé](merise/MLD_V1.md), [SQL candidat V1](merise/mpd/010_modele_v1.sql) et [vérifications statiques](merise/VERIFICATION_V1.md). Les V0 sont conservées pour historique. Le SQL V1 vise une base vide, n'est pas déployé et doit encore être exécuté sur PostgreSQL et complété par les contrôles transactionnels.

- Réponses métier du 16 septembre intégrées dans [Décisions métier V1](merise/DECISIONS_METIER_V1.md) : CI/XOF configurable, confirmation automatique, espèces sur place et avance à la réservation configurable ; extensions de modèle proposées pour les autres paramètres configurables.

- Règles de gestion, dictionnaire des données, MCD, MCT, MLD, MOT et MPD en version de travail. Le DDL PostgreSQL du socle est un candidat non déployé.
- Application web Blazor .NET 10 avec accueil et fiche fictive de démonstration.
- Aucun schéma de base de données, compte, réservation ou paiement réel n'est encore implémenté.

## Lancer l'application

`dotnet run --project src/KekeBeauty.Web/KekeBeauty.Web.csproj`

Le projet compile avec .NET SDK 10. Les dix décisions métier ont été intégrées à la conception V1. L'exécution du DDL candidat sur PostgreSQL, les contrôles transactionnels et leur recette restent à faire avant les migrations applicatives. Aucun serveur PostgreSQL de test n'est disponible dans l'environnement actuel.

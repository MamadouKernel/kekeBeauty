# Keke Beauty

Première version du projet en cours de cadrage. Les livrables MERISE sont dans `merise/` et la trajectoire Scrum dans `planning/`.

## État actuel

- Réponses métier du 16 septembre intégrées dans [Décisions métier V1](merise/DECISIONS_METIER_V1.md) : CI/XOF configurable, confirmation automatique et espèces sur place ; extensions de modèle proposées pour les autres paramètres configurables.

- Règles de gestion, dictionnaire des données, MCD, MCT, MLD, MOT et MPD en version de travail. Le DDL PostgreSQL du socle est un candidat non déployé.
- Application web Blazor .NET 10 avec accueil et fiche fictive de démonstration.
- Aucun schéma de base de données, compte, réservation ou paiement réel n'est encore implémenté.

## Lancer l'application

`dotnet run --project src/KekeBeauty.Web/KekeBeauty.Web.csproj`

Le projet compile avec .NET SDK 10. Les réponses au questionnaire de cadrage permettront de valider les cardinalités et règles ouvertes, puis de réauditer le MLD et le MPD jusqu'à la 3FN avant les migrations de base de données. Le DDL candidat n'a pas été exécuté faute de base PostgreSQL de test disponible.

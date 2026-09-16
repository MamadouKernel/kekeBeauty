# Keke Beauty

Plateforme de découverte et de réservation d'établissements de beauté. Lancement Côte d'Ivoire / XOF, conception extensible à d'autres pays.

## État actuel

- [Conception MERISE V2](merise/CONCEPTION_MERISE_V2.md) : règles, DD, MCD, MCT, MOT et audit des trois formes normales ; [MLD détaillé](merise/MLD_V2.md).
- [Schéma PostgreSQL V2](merise/mpd/020_modele_v2.sql) chargé dans Docker Desktop : 53 tables, 64 clés étrangères. [Résultats de recette](merise/VERIFICATION_V2.md).
- Les cinq choix métier sont paramétrables. Acceptation par le salon, paiement des soins hors plateforme, annulation/report une heure avant par défaut, aucune grâce d'abonnement.
- Application Blazor .NET 10 connectée à PostgreSQL : annuaire, connexion OTP de développement, création de demandes, acceptation/refus et annulation. [État exact, preuves et travail restant](planning/ETAT_IMPLEMENTATION.md). Les fournisseurs SMS et paiement ne sont pas raccordés.
- 84 tâches dans le backlog local ; 40 créées dans ClickUp, 12 listes de sprint. Calendrier et estimations restent prévisionnels.

## Développement

Traitement d'acceptation PostgreSQL installé : [fonction et recette concurrente](merise/RECETTE_ACCEPTATION.md), 13 scénarios réussis. La recette applicative ajoute 21 scénarios HTTP/PostgreSQL. Le report et l'expiration automatique restent à réaliser.

`dotnet run --project src/KekeBeauty.Web/KekeBeauty.Web.csproj`

## Base locale

[Instructions Docker](infra/postgres/README.md). Hôte `127.0.0.1`, port `55432`, base `keke_merise`, utilisateur `keke_owner`. Mot de passe dans `infra/postgres/.env`, ignoré par Git.

Les scripts additionnels 030 à 061 relient les contraintes aux traitements transactionnels et à l'application. Les V0/V1 et leurs scripts restent conservés comme historiques. Le produit n'est pas encore prêt pour la production ; consulter l'état détaillé avant toute recette.

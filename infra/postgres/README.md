# PostgreSQL de conception — Docker Desktop

Mise à jour applicative : cette base est désormais raccordée à Blazor. Exécuter `Update-Application.ps1` après l'initialisation V2 pour installer les traitements et l'identité. Voir `planning/ETAT_IMPLEMENTATION.md` pour les tests et les limites actuelles ; les paragraphes ci-dessous décrivent également l'installation initiale.

Traitement additionnel installé : `merise/mpd/030_acceptation_rdv.sql`. Recette : `python infra/postgres/test_acceptation.py --docker '<chemin docker.exe>'`. Ce test crée une base isolée dont le nom est affiché et la conserve pour inspection ; aucune suppression automatique. Voir `merise/RECETTE_ACCEPTATION.md`.

Projet Compose `kekebeauty-merise`, service `db`, base `keke_merise`, utilisateur `keke_owner`. Image officielle PostgreSQL 17. Volume persistant dédié. Accès Windows sur `127.0.0.1:55432`, limité à cette machine pour éviter le conflit avec Kalenso sur 5432. Ce serveur valide le modèle ; ce n'est pas une base de production ni encore la base de l'application Blazor.

Le schéma V2 est chargé dans la base locale. Les scripts V1 sont historiques ; utiliser uniquement les scripts V2 ci-dessous. Le correctif 022 est déjà inclus dans l’initialisation 020.

Le mot de passe local aléatoire est dans `.env` (ignoré par Git). Sur une autre machine, créer ce fichier avec `POSTGRES_PASSWORD=<secret local>` avant de démarrer. Ne pas copier ce secret dans les documents ou GitHub.

Depuis la racine du dépôt, avec `docker` dans PATH :

```powershell
docker compose -f infra/postgres/compose.yaml --env-file infra/postgres/.env up -d --wait
docker compose -f infra/postgres/compose.yaml --env-file infra/postgres/.env exec -T db psql -U keke_owner -d keke_merise
```

Pour les autres commandes Compose, fournir aussi `--env-file infra/postgres/.env` (ou exporter POSTGRES_PASSWORD). Sur la machine actuelle, la commande Docker est dans `C:\Users\KERNELMK\AppData\Local\Programs\DockerDesktop\resources\bin\docker.exe`.

Exécution automatisée : `./infra/postgres/Test-Merise.ps1 -Docker '<chemin vers docker.exe>'`. Le script initialise uniquement si le schéma `kb` est absent ; sinon il préserve le schéma existant et teste celui-ci.

Initialisation, une seule fois sur base vide : copier `merise/mpd/020_modele_v2.sql` dans `/tmp/020_modele_v2.sql` avec `docker compose cp`, puis `exec -T db psql -v ON_ERROR_STOP=1 -U keke_owner -d keke_merise -f /tmp/020_modele_v2.sql`. Le script crée le schéma `kb` dans une transaction et échoue si ce schéma existe déjà ; ne pas le relancer pour mettre à jour une base existante.

Tests réexécutables : copier `merise/mpd/021_tests_contraintes_v2.sql` puis l'exécuter de la même façon. Les données de test sont annulées par ROLLBACK ; les séquences peuvent avancer. Les tests ne prouvent pas encore la sécurité des réservations concurrentes : le protocole de réservation n'est pas implémenté.

Arrêter sans supprimer les données : `docker compose -f infra/postgres/compose.yaml --env-file infra/postgres/.env stop`. Ne pas utiliser `down -v` pour un simple arrêt : cette option supprimerait le volume.

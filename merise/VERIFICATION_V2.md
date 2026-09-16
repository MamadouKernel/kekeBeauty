# Recette PostgreSQL V2

Environnement : Docker Desktop local, conteneur `kekebeauty-merise-db-1`, PostgreSQL **17.11**, base `keke_merise`, accès Windows `127.0.0.1:55432`.

## Résultats observés

- Initialisation `020_modele_v2.sql` exécutée et validée par COMMIT.
- **53 tables**, **64 clés étrangères**, marqueur de schéma **2**, vérifiés dans le catalogue PostgreSQL.
- Une jointure ambiguë du contrôle d'habilitation a été détectée par la recette, corrigée dans le générateur et appliquée via `022_correction_habilitation_v2.sql`.
- Recette `021_tests_contraintes_v2.sql` passée après correction : **20 cas invalides rejetés avec le SQLSTATE attendu**, plus **4 contrôles positifs** (délais/limite, acceptation habilitée, payeur pour deux salons, absence des anciennes données de paiement client/grâce).
- ROLLBACK des données fictives ; compteurs observés ensuite : **0 établissement**, **0 compte**. Les référentiels techniques XOF, permission et version de schéma restent présents.

## Cas invalides testés

Principal dupliqué ; capacité nulle ; employé de capacité > 1 ; politique incomplète ; blocage sans durée ; durée sans blocage ; mutation de politique ; ancien statut automatique ; acceptation sans décision ; décision par client non habilité ; politique inexistante ; intervalle nul ; mutation de tarif ; allocation autre salon ; groupe autre salon ; clé idempotente dupliquée ; mode de facturation manquant ; engagement < un an ; référence fournisseur dupliquée ; second encaissement d'une même tentative.

## Limites

Ce sont des tests SQL transactionnels, pas une recette de l'application complète. L'absence de surbooking concurrent, le compteur effectif d'annulation/report, les expirations, le calcul des échéances, la désactivation sans grâce, l'OTP, les webhooks et l'envoi SMS ne sont pas encore implémentés/testés. Le rôle propriétaire de test ne doit pas devenir le rôle SQL de production.

Rejouer via `infra/postgres/Test-Merise.ps1` ; il initialise seulement en l'absence de schéma et refuse un schéma de version incompatible. Aucune suppression automatique de base ou volume.

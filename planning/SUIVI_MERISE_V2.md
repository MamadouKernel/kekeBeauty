# Suivi de la consolidation MERISE V2

Référence : `merise/CONCEPTION_MERISE_V2.md`. Schéma PostgreSQL Docker chargé, 53 tables / 64 FK, 20 tests négatifs + 4 contrôles positifs passés. Les scripts de recette utilisent V2 ; V1 historique.

## Synchronisation ClickUp effectuée

- KB-002 — règles et preuves de recette : https://app.clickup.com/t/123tcvwe4gu
- KB-033 — capacité configurable, traitement concurrent restant : https://app.clickup.com/t/123tcvwe4jq
- KB-037 — acceptation manuelle, contraintes SQL réalisées : https://app.clickup.com/t/123tcvwe4jz
- KB-038 — annulation, seuil une heure, portée paramétrable : https://app.clickup.com/t/123tcvwe4k0
- KB-039 — report et conservation de l'ancien RDV en cas d'échec : https://app.clickup.com/t/123tcvwe4k1

Statuts de tâches non marqués terminés : le service et l'interface ne sont pas réalisés. Ne pas interpréter les tests SQL comme l'achèvement des critères de concurrence ou de parcours utilisateur.

Le backlog initial reste une prévision. Lors du prochain affinage, réestimer les traitements paramétrables, le payeur multi-établissements et l'absence de paiement client. La création des 44 tâches restantes et les fiches de sprint ne sont pas incluses dans cette consolidation.

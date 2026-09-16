# Vérification statique MERISE V1

- 52 tables, noms uniques.
- 31 tables cibles de références : toutes déclarées.
- 66 références : colonnes cibles présentes ; colonnes sources des FK composites présentes.
- Parenthèses équilibrées ; ancien TARIF_PRESTATION absent du candidat V1.
- MLD et SQL produits depuis le même catalogue.
- Ce contrôle ne parse pas la grammaire PostgreSQL et ne teste ni les FK composites, ni les transactions, ni les contraintes de concurrence.
- Aucun moteur PostgreSQL/psql/docker détecté dans PATH lors de cette consolidation. Exécution SQL et recette restent à faire.

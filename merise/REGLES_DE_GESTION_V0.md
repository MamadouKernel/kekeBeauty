# Règles de gestion initiales — Keke Beauty

Actualisation du 16 septembre 2026 : les réponses et amendements RG-018 à RG-027 dans [DECISIONS_METIER_V1.md](DECISIONS_METIER_V1.md) prévalent sur les questions ouvertes correspondantes ci-dessous. Les valeurs de configuration restent à définir avant activation.

Statut : **version de travail à confirmer par le Product Owner**. Une règle « CDC » vient du document ; une règle « proposée » complète un cas que le document ne tranche pas. Les décisions ouvertes ne doivent pas être codées comme vérités métier avant validation. Ces identifiants seront repris dans le DD, le MCD, le MCT, le MLD, le MOT et le MPD.

| ID | Règle | Source / état | Backlog |
|---|---|---|---|
| RG-001 | Une interaction client nécessite un compte authentifié par numéro de téléphone et OTP SMS. | CDC 3.1 | KB-008 à KB-010 |
| RG-002 | Un établissement est associé à un gérant, des coordonnées, des horaires et une position GPS exacte. | CDC 3.2 | KB-011 |
| RG-003 | L'activation d'un partenaire est précédée de la vérification de l'identité du gérant par l'administration. | CDC 3.2, 5 | KB-012 à KB-016 |
| RG-004 | Un établissement propose zéro à plusieurs prestations, chacune avec son tarif ; les modalités de durée et de capacité restent à définir. | CDC 3.1–3.2 ; compléments ouverts | KB-002, KB-017 |
| RG-005 | Un client peut rechercher des établissements par catégorie et par pays, région, ville et commune. | CDC 3.1 | KB-021 à KB-024 |
| RG-006 | Un établissement publie une fiche avec description, médias, prestations et tarifs et un moyen d'appel et d'itinéraire. | CDC 3.1 | KB-018 à KB-027 |
| RG-007 | La réservation n'est proposée que si le partenaire l'a activée et dispose des droits associés à son offre. | CDC 3.1, 3.3 | KB-029 |
| RG-008 | Un client demande une prestation et un créneau disponible ; les indisponibilités sont visibles en rouge et annoncées autrement que par la seule couleur. | CDC 3.1 ; complément accessibilité | KB-031 à KB-032 |
| RG-009 | Le partenaire peut confirmer, refuser, annuler ou reprogrammer une demande ; les transitions exactes et acteurs autorisés sont à décider. | CDC 3.1–3.2 ; détail ouvert | KB-002, KB-037 à KB-039 |
| RG-010 | Le client reçoit la confirmation ou le refus/indisponibilité par SMS ou dans l'application. | CDC 3.1, 4 | KB-040 à KB-041 |
| RG-011 | Une souscription partenaire engage au moins un an ; le paiement peut être mensuel ou annuel, sans confondre durée du contrat et fréquence de facturation. | CDC 3.3 | KB-044 |
| RG-012 | Les tarifs d'abonnement sont administrables ; un changement de tarif ne doit pas altérer le montant accepté sur un contrat déjà conclu. | CDC 3.3, 5 ; conservation proposée | KB-043 |
| RG-013 | Les moyens de paiement ciblés comprennent Mobile Money et Visa/Mastercard, sous réserve de leur couverture réelle dans le pays choisi. | CDC 3.3, 4 | KB-045, KB-050 |
| RG-014 | Un droit payant n'est accordé qu'après vérification fiable du paiement ; un retour doublé ne produit pas deux encaissements. | Complément proposé, exigence d'intégrité | KB-046 à KB-047 |
| RG-015 | Les administrateurs modèrent les comptes, vérifient le KYC et suivent les abonnements et encaissements. | CDC 5 | KB-015, KB-055 à KB-060 |
| RG-016 | Une pièce d'identité ne peut être lue que par les acteurs habilités et selon une durée de conservation à définir pour le pays retenu. | Complément proposé / réglementation à valider | KB-014, KB-061 |
| RG-017 | Une réservation simultanée ne doit jamais dépasser la capacité du créneau ; le modèle de capacité doit être défini avec les partenaires. | Complément proposé / règle ouverte | KB-002, KB-033 |

## Questions qui changent le modèle

1. Un gérant peut-il gérer plusieurs établissements ? Un établissement peut-il avoir plusieurs gérants ou comptes partenaires ?
2. Une réservation concerne-t-elle un employé précis, une ressource (cabine) ou seulement la capacité globale du salon ? Quelle est la durée de chaque prestation ?
3. Quand le créneau est-il bloqué : à la demande ou uniquement à la confirmation ? Combien de temps une demande peut-elle rester en attente ?
4. Qui peut annuler et jusqu'à quand ? Une reprogrammation nécessite-t-elle une nouvelle confirmation du client ?
5. Que deviennent les rendez-vous existants en cas de suspension, impayé ou fin d'abonnement ?
6. Quels pays, monnaies, catégories, territoires et moyens de paiement font partie du lancement ?

Les réponses alimenteront d'abord les dépendances fonctionnelles et cardinalités du MCD, puis les événements du MCT. La conformité aux 1FN, 2FN et 3FN sera contrôlée relation par relation lors du MLD/MPD.

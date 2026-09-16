# Décisions métier — 16 septembre 2026

Ce document actualise les questions ouvertes des versions V0. Il distingue les réponses du porteur de projet et les propositions de conception. Les documents et le SQL V0 restent des brouillons à réconcilier avant toute migration.

## Réponses reçues

| ID | Décision validée | Portée |
|---|---|---|
| DEC-01 | Lancement en Côte d'Ivoire, monnaie FCFA (XOF), extensible par configuration. | Référentiels pays et devises ; ne pas coder XOF comme constante globale. |
| DEC-02 | Multiplicité gérants/établissements configurable. | Conserver l'association plusieurs-à-plusieurs ; limiter les affectations par politique, sans changer le schéma. |
| DEC-03 | Modèle de capacité configurable. | Prévoir employés, ressources physiques et capacité globale. |
| DEC-04 | Durées, prix et possibilité de plusieurs prestations configurables. | Chaque combinaison effectivement réservée doit toutefois avoir durée et montant déterminés. |
| DEC-05 | Confirmation automatique selon disponibilité. | Pas de validation manuelle préalable dans le parcours initial. |
| DEC-06 | Les prestations client sont payées en espèces sur place au lancement. | Aucun acompte ou paiement client en ligne au lancement. Cette décision ne tranche pas les paiements des abonnements partenaires. |
| DEC-07 | Annulation et report configurables. | Acteurs, autorisations et délais à paramétrer. |
| DEC-08 | Conséquences de l'impayé/expiration et grâce configurables. | Séparer visibilité de la fiche, nouvelles réservations et gestion des rendez-vous déjà confirmés. |

« Configurable » valide une capacité du produit, pas toutes les valeurs possibles ni une valeur par défaut particulière.

## RG complémentaires et amendements

- RG-018 : les pays activés et devises autorisées sont administrés par la plateforme. Le lancement active CI et XOF. Les montants historiques conservent leur devise ; aucun changement de devise ne convertit les anciens montants implicitement.
- RG-019 : les affectations gérant/établissement respectent les limites applicables. Réduire une limite sous le nombre d'affectations existantes exige une résolution explicite ; aucune affectation n'est supprimée automatiquement.
- RG-020 : une réservation consomme des capacités sur un intervalle début inclus, fin exclue. Deux rendez-vous peuvent ainsi se suivre exactement. Pauses et indisponibilités sont prises en compte.
- RG-021 : avant confirmation automatique, le serveur vérifie à nouveau les droits, l'ouverture, les prestations et toutes les capacités requises dans une transaction unique. Un créneau affiché libre n'est pas une garantie de réservation.
- RG-022 : allocation des ressources, enregistrement du rendez-vous confirmé et événement de notification sont atomiques. Deux demandes concurrentes ne doivent jamais dépasser la capacité ; la seconde reçoit une indisponibilité si la première prend la dernière place.
- RG-023 : une clé d'idempotence lie la tentative au client et à son contenu. Rejouer la même demande renvoie le même résultat ; réutiliser la clé avec un contenu différent est rejeté.
- RG-024 : la notification part après validation de la transaction ; un échec SMS ne supprime pas un rendez-vous confirmé. L'envoi est repris sans créer une deuxième réservation.
- RG-025 : les prix, durées, devise et conditions acceptés sont conservés comme faits contractuels datés. Modifier un catalogue ou une politique ne réécrit pas les rendez-vous existants.
- RG-026 : un report réserve le nouvel intervalle et libère l'ancien dans la même transaction. Si le nouvel intervalle est indisponible, l'ancien rendez-vous est conservé.
- RG-027 : un rendez-vous confirmé ne vaut pas encaissement. L'enregistrement du paiement en espèces relève d'un acteur habilité du salon, avec montant, date et auteur ; il est distinct du statut du rendez-vous.

RG-004, RG-008, RG-009 et RG-017 V0 sont à lire avec ces amendements : plusieurs prestations sont possibles selon politique, la confirmation initiale est automatique et le blocage devient effectif au commit. Les annulations et reports ultérieurs restent soumis aux droits et aux politiques.

## Paramétrage proposé — à valider avant activation des salons

| Paramètre | Responsable proposé | Règle de validation |
|---|---|---|
| Pays, devises, limites de gestion | Administrateur plateforme | Référentiels valides et affectations existantes compatibles |
| Ressources, employés, capacité globale | Gérant habilité | Capacité entière positive ; aucune réduction créant un surbooking |
| Durée et prix | Gérant habilité | Durée positive, montant non négatif, devise autorisée ; variantes explicites pour les cas variables |
| Plusieurs prestations par RDV | Gérant habilité | Par défaut proposé : prestations séquentielles du même salon ; disponibilité vérifiée pour chaque segment |
| Annulation/report client et délai minimal | Gérant dans les limites plateforme | Délai entier non négatif ; politique présentée avant confirmation |
| Grâce, visibilité et droits après impayé | Administrateur plateforme | Politique datée ; conservation des rendez-vous et de leur historique |

Proposition : interdire l'activation de la réservation tant que capacité, horaires, durées et politique client ne sont pas renseignés. Une valeur manquante n'est jamais interprétée comme capacité illimitée. L'équipe peut développer et tester avec des configurations explicitement fictives en attendant les valeurs de lancement.

## Traduction MERISE proposée

### DD / MCD / MLD

Extensions logiques, à intégrer au DD détaillé puis auditer avant le MPD :

| Relation | Clé et contenu propre |
|---|---|
| DEVISE | PK code ; libellé, nombre de décimales |
| PAYS_DEVISE_AUTORISEE | PK (pays_id, code_devise), deux FK |
| POLITIQUE_RDV | PK politique_id ; FK établissement ; version, date_effet, autorise_multi_prestations, autorise_annulation_client, delai_annulation_minutes, autorise_report_client, delai_report_minutes ; UK (établissement, version) |
| VARIANTE_PRESTATION | PK variante_id ; FK prestation ; libellé, état |
| VERSION_VARIANTE | PK version_variante_id ; FK variante ; date_effet, durée_minutes, montant, FK devise ; UK (variante, date_effet) |
| RESSOURCE | PK ressource_id ; FK établissement ; nature, libellé, capacité |
| BESOIN_RESSOURCE | PK (variante_id, ressource_id) ; quantité requise ; deux FK |
| RENDEZ_VOUS | PK rdv_id ; FK client, FK politique acceptée ; état, créé_le ; salon obtenu via la politique |
| LIGNE_RDV | PK (rdv_id, numero) ; FK version_variante ; début, fin ; les lignes définissent les intervalles, sans recopier le total et la durée du RDV |
| ALLOCATION_RDV | PK (rdv_id, numero, ressource_id) ; FK ligne et ressource ; quantité allouée |
| ENCAISSEMENT_ESPECES | PK encaissement_id ; FK rdv, FK auteur ; montant, FK devise, encaissé_le |

Une variante correspond à une option à prix et durée déterminés. Les versions utilisées sont immuables. Une ressource peut représenter un employé, une cabine ou un pool de capacité globale. La sélection de ressources alternatives et les combinaisons employé + cabine restent à détailler : BESOIN_RESSOURCE seul décrit des exigences cumulatives, pas les alternatives.

Cardinalités proposées : gérant (0,n) — affecter — établissement (0,n), avec au moins un responsable avant activation ; établissement (0,n) politiques, politique (1,1) établissement ; RDV confirmé (1,n) lignes, ligne (1,1) RDV ; ligne (1,n) allocations au moment de sa confirmation. Chaque ligne et chaque ressource doivent appartenir au salon de la politique du RDV.

### Contrôle 1FN, 2FN, 3FN

Valeurs atomiques, une ligne par affectation ou allocation ; aucun tableau d'identifiants dans une colonne. Dans les associations, la quantité dépend de toute la clé composée. Les libellés du pays, de la devise, du salon et de la prestation restent dans leur référentiel. Une version immuable de variante porte ses prix et durée : ne pas les recopier dans LIGNE_RDV sans nouveau fait métier distinct. Une politique appartient à un salon : ne pas dupliquer salon_id dans RENDEZ_VOUS avec politique_id. Les contraintes entre salons, variantes et ressources nécessitent un contrôle explicite au MPD/service. Ce contrôle est une revue préliminaire, pas une certification des extensions.

### MCT / MOT

Demande client authentifiée → contrôles et allocation transactionnelle → RDV confirmé ou indisponibilité → notification asynchrone. Le client déclenche la réservation ; le système confirme ; le salon traite les exceptions autorisées et constate les espèces. Un administrateur gère les règles d'abonnement.

### MPD et recette à préparer

Verrouiller toutes les ressources concernées dans un ordre stable avant le contrôle des chevauchements, au sein de la même transaction ; tous les chemins de réservation, report, fermeture et changement de capacité suivent ce protocole. Pour une capacité N, compter les quantités réellement simultanées sur les sous-intervalles, pas seulement le nombre total de RDV qui croisent la demande. Prévoir reprise bornée des conflits transactionnels, unicité de clé d'idempotence et boîte d'envoi transactionnelle des notifications.

Recette nécessaire : demandes simultanées sur la dernière place ; capacité N ; rendez-vous adjacents ; plusieurs segments ; report concurrent conservant l'ancien créneau en cas d'échec ; double clic/rejeu ; modification de capacité ; panne SMS ; changement de prix/politique sans effet rétroactif. SQL V0 non modifié et non déployé à ce stade.

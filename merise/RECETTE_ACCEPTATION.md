# Acceptation des rendez-vous — traitement PostgreSQL

Implémentation : `mpd/030_acceptation_rdv.sql`, fonction `kb.accepter_rdv(rdv_id, auteur_compte_id)`. Installée dans la base locale `keke_merise`. Aucun changement de tables : les relations MERISE V2 sont conservées.

## Comportement réalisé

- Transaction READ COMMITTED, verrou du salon puis du RDV et des ressources, horloge relue après attente.
- Permission du gestionnaire et compte actif ; état initial en attente du salon. Rejeu accepté sans deuxième événement.
- Salon publié et contrat actif avec couverture/échéance courante ; refus immédiat en cas de dette exigible non réglée dans le périmètre facturé, sans grâce.
- Prestations actives, durée conforme à la variante et ordre successif ; horaires salon et ressources, exceptions et indisponibilités.
- Ressources déjà allouées vérifiées contre les besoins et le mode de capacité. Le choix automatique des ressources n'est pas inclus.
- Capacité contrôlée par sous-intervalle : les RDV successifs ne sont pas additionnés comme s'ils étaient simultanés. Maintiens non expirés comptés, maintien propre non compté deux fois.
- Décision, état accepté, événement et deux notifications à envoyer (SMS/in-app) enregistrés dans la même transaction. Aucun SMS effectivement envoyé par SQL.

## Recette exécutée

Commande : `python infra/postgres/test_acceptation.py --docker '<chemin docker.exe>'`.

13 scénarios passés sur PostgreSQL Docker : acteur non habilité, impayé, fermeture exceptionnelle, pause ressource, deux acceptations concurrentes sur dernière place (une seule réussit), rejeu sans doublon, RDV adjacents, capacité deux, découpage des sous-intervalles, maintien actif bloquant, acceptation de son propre maintien, refus d'une demande expirée, libération par maintien expiré.

Le test concurrent synchronise réellement deux connexions : la première conserve le verrou avant COMMIT ; la seconde attend puis recontrôle la capacité. La demande perdante reste en attente, aucun événement de confirmation n'est créé pour elle.

Bases de recette isolées conservées pour inspection : `kb_acceptance_e522f4b98165` (premiers 9 scénarios) et `kb_acceptance_56d2eaa2112a` (13 scénarios). Elles contiennent des données fictives. La base du projet `keke_merise` reste sans RDV fictif.

## Limites avant raccordement à l'application

- La garantie de concurrence concerne les appels de cette fonction. Les futures créations de maintiens, reports, fermetures et modifications de capacité doivent prendre le même verrou de salon. L'écriture directe par un propriétaire SQL peut contourner le protocole.
- Aucun endpoint public n'expose la fonction. L'identifiant auteur doit venir de l'identité authentifiée serveur, jamais d'un champ libre client. Exécution retirée à PUBLIC ; rôle applicatif minimal à créer avant intégration.
- KYC préalable à publication, intégrité des règlements entrants et émission des échéances sont des préconditions gérées par leurs futurs services. La fonction ne constitue pas une vérification fournisseur de paiement.
- Les contrats sont considérés ouverts sur [début,fin_engagement[ ; le renouvellement au-delà doit être traité explicitement.
- Une variante utilise des groupes de ressources distincts. Les groupes se recouvrant sont refusés pour éviter de sous-compter les besoins. Les soins traversant minuit sont refusés ; les horaires sont interprétés dans le fuseau du salon.
- Création de demande, choix des ressources, refus salon, annulation/report, compteur de modifications, tâche d'expiration, désactivation de visibilité et envoi des notifications restent à développer.
- Tests effectués sur capacité globale ; les modes employés/physiques et les changements d'heure nécessitent leur recette dédiée avant activation.

Cette étape réalise le traitement d'acceptation et ses vérifications ; elle ne termine pas l'ensemble du parcours de réservation.

# État vérifié de l’implémentation

## Objectif

Terminer le périmètre validé du cahier des charges. Une fonctionnalité est terminée après développement, contrôles des droits, tests des erreurs et intégration au parcours utilisateur. Le projet n’est pas encore entièrement implémenté. Aucun pourcentage global n’est déduit du nombre de tests.

## Ajouts vérifiés dans cette livraison

- Application Blazor connectée à PostgreSQL Docker par Npgsql 10.0.3.
- Connexion par téléphone international : code aléatoire chiffré au stockage, expiration cinq minutes, cinq essais, trois demandes par téléphone en quinze minutes, limitation HTTP par adresse, session de huit heures. Compte suspendu rejeté à la requête suivante.
- **Code affiché uniquement en Development. Aucun SMS réel envoyé.** En production, la demande de code répond 503 jusqu’au raccordement d’un fournisseur. Le parcours OTP ne peut donc pas être déclaré terminé en production.
- Annuaire réel : salons publiés, recherche par nom/commune, politique de visibilité après impayé, prestations et tarifs en vigueur. Aucun salon fictif ajouté à la base principale.
- Création d’un rendez-vous avec une à dix prestations successives, heure locale du salon, attribution automatique de ressources, contrôle partagé des horaires/capacités/abonnements, attente de décision du salon. Maintien facultatif selon politique. Rejeu idempotent lié au contenu.
- Rendez-vous du client et des gestionnaires habilités : acceptation, refus avec motif facultatif, annulation par le propriétaire avec délai et quota configurés. Identité issue de la session ; aucune identité fournie par formulaire.
- Refus et annulation atomiques avec événements et notifications **en attente d’envoi**.
- Protection antifalsification sur les formulaires modifiant des données.

## Preuves exécutées

- `dotnet build src/KekeBeauty.Web --no-restore` : zéro erreur, zéro avertissement.
- `infra/postgres/test_application.py` : **21 scénarios** HTTP/PostgreSQL, dernière base isolée `kb_application_8285e1937030`.
- `infra/postgres/test_acceptation.py` : **13 scénarios**, dont deux transactions concurrentes sur la dernière place ; base `kb_acceptance_91278d97813e`.
- La recette application inclut également deux créations concurrentes avec maintien : une seule obtient la dernière place, l’autre est annulée entièrement.
- Scripts 030, 040, 050, 060 et 061 installés dans `keke_merise`, sans suppression de données.
- Application locale démarrée sur `http://localhost:5083` ; accueil vérifié par HTTP 200 avec la configuration Docker locale.
- ClickUp : descriptions de KB-008, KB-032, KB-033, KB-037 et KB-038 mises à jour avec les réalisations et limites. Aucune tâche globale déclarée terminée.

Ces tests ne constituent pas une recette exhaustive du cahier des charges, un audit de sécurité ni une validation visuelle sur tous les appareils.

## Travail restant pour atteindre l’objectif

1. Finaliser le parcours rendez-vous : sélection de créneaux proposés plutôt que saisie libre, report, expiration automatique, statuts terminé/absent, affichage des notifications et envoi SMS, pagination.
2. Espace partenaire : inscription, dépôt KYC privé, validation administrative, gestion multi-établissements, habilitations, services, prix, horaires, ressources et politiques depuis des écrans. Les tables existent ; ces écrans ne sont pas livrés.
3. Recherche complète : catégories, hiérarchie géographique, distance, médias, itinéraires.
4. Abonnements : souscription du payeur multi-salons, facturation configurée, échéances, vrais paiements Mobile Money et rapprochement, relances/renouvellement. Le contrôle des droits lit actuellement les données PostgreSQL ; il ne crée pas les contrats ni les paiements.
5. Administration et exploitation : gestion des comptes et paramètres, audit, droits PostgreSQL minimaux, migrations versionnées avec suivi, sauvegarde/restauration, supervision, sécurité et protection des données.
6. Recette complète : employés/ressources physiques/combinées, changements de fuseau et d’heure, accessibilité/mobile, performances, revue fonctionnelle, déploiement et tests des fournisseurs réels.
7. Compléter la synchronisation ClickUp : 40 tâches créées sur 84 prévues ; les tâches restantes et les dépendances doivent encore être synchronisées.

## Limites connues de ce lot

- Les soins traversant minuit et les besoins de ressources dont les groupes se recouvrent sont refusés explicitement. Le mode global est couvert par les tests ; les autres modes demandent leur propre recette.
- La recherche et les rendez-vous affichent au plus cent résultats. Les horaires des rendez-vous sont explicitement affichés en UTC ; la saisie utilise le fuseau du salon.
- Le compte propriétaire PostgreSQL est employé **en développement local**. Il faudra un compte applicatif à privilèges limités pour la production.
- La révocation de session est contrôlée à chaque requête HTTP. Les pages métier de ce lot sont rendues côté serveur, sans circuit interactif persistant.
- Aucun adaptateur fournisseur fictif n’est présenté comme un paiement ou un SMS réel.

## Lancement local

Docker Desktop doit être démarré, avec `kekebeauty-merise-db-1` accessible sur `127.0.0.1:55432`.

```powershell
./infra/postgres/Update-Application.ps1 -Docker 'C:\Users\KERNELMK\AppData\Local\Programs\DockerDesktop\resources\bin\docker.exe'
dotnet run --project src/KekeBeauty.Web --launch-profile http
```

L’application lit le secret local ignoré `infra/postgres/.env` uniquement en Development. Ailleurs, fournir `ConnectionStrings__KekeBeauty` via le gestionnaire de secrets de l’hébergeur. Ne pas committer le secret.

Ouvrir `http://localhost:5083`. Une base sans établissements affiche un annuaire vide. Les données fictives sont confinées aux bases de recette, conservées pour inspection.

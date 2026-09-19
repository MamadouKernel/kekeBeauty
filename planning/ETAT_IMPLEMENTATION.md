# État vérifié de l’implémentation

## Objectif

Terminer le périmètre validé du cahier des charges. Une fonctionnalité est terminée après développement, contrôles des droits, tests des erreurs et intégration au parcours utilisateur. Le projet n’est pas encore entièrement implémenté. Aucun pourcentage global n’est déduit du nombre de tests.

## Ajouts vérifiés dans cette livraison

- Socle PWA installé : manifeste, icône, couleur de thème, service worker et page de repli hors connexion. Le cache est volontairement limité à l'icône et à la page hors connexion ; les sessions, formulaires, rendez-vous, réponses applicatives et futurs documents KYC ne sont pas mis en cache.
- Mise à jour du service worker proposée explicitement avec avertissement avant rechargement.
- Accueil remis aux couleurs Keke Beauty avec navigation responsive Explorer / Mes RDV / Compte et barre basse mobile.
- Filtre de catégorie relié aux catégories actives et aux associations établissement-catégorie PostgreSQL. Le filtre texte par nom ou commune reste disponible.
- Adaptateur OTP SMS configurable par variables d'environnement, désactivé par défaut et validé au démarrage. L'ancienne interdiction absolue en production est remplacée par un échec explicite lorsque l'adaptateur n'est pas configuré.
- Lien d'itinéraire configurable à partir des coordonnées de l'établissement ; il n'est affiché que si le service est activé et si les deux coordonnées existent.
- Contrats de configuration validés pour le paiement d'abonnement et le stockage KYC privé. Ils restent désactivés tant que les informations fournisseur et les règles métier bloquantes ne sont pas fournies.
- Centre de notifications dans « Mes RDV » relié aux notifications `in_app` et aux événements de rendez-vous PostgreSQL, limité aux vingt événements récents du compte authentifié.
- Adaptateurs configurables ajoutés pour l'initiation de paiement JSON, la vérification HMAC-SHA256 des webhooks et le stockage privé des justificatifs KYC avec liste blanche MIME, limite de taille et référence privée.
- Règles de lancement, devise, engagement, modification de rendez-vous et absence de grâce regroupées dans une configuration validée. En production, HTTPS public, clés de protection persistantes, sauvegardes et supervision deviennent obligatoires au démarrage.
- Sélection de rendez-vous en deux étapes : choix d'une à dix prestations, puis créneaux serveur de trente minutes sur quatorze jours. Le calcul couvre horaires, exceptions, plages et indisponibilités des ressources ainsi que les modes global, employés, ressources physiques et combiné ; la création transactionnelle revalide toujours le créneau.
- Expiration automatique configurable des demandes maintenues : traitement par lots avec verrouillage `SKIP LOCKED`, transition idempotente vers `expire`, événement unique et notifications in-app/SMS. Le service tourne toutes les 60 secondes par défaut.
- Report client depuis les créneaux serveur : délai et quota issus de la politique du salon, réallocation transactionnelle des ressources, rejeu idempotent et notifications. Toute erreur annule l'opération complète et conserve l'ancien planning.
- Tableau des rendez-vous paginé par vingt éléments avec compteurs partenaire et filtres de statut et de dates. Les rendez-vous passés acceptés peuvent être clôturés comme réalisés ou absents par un gestionnaire habilité.
- Proposition de reprogrammation par le partenaire : choix limité aux créneaux calculés selon les horaires d'ouverture/fermeture et les ressources, conservation de l'ancien créneau jusqu'à la réponse, acceptation ou refus par le client, revalidation transactionnelle à l'acceptation et notifications aux deux parties.
- File SMS configurable : prise concurrente avec `SKIP LOCKED`, envoi dédupliqué par notification, reprise des traitements interrompus, temporisation quadratique plafonnée et suivi des erreurs. Elle reste inactive tant que le fournisseur n'est pas configuré.

- Application Blazor connectée à PostgreSQL Docker par Npgsql 10.0.3.
- Connexion par téléphone international : code aléatoire chiffré au stockage, expiration cinq minutes, cinq essais, trois demandes par téléphone en quinze minutes, limitation HTTP par adresse, session de huit heures. Compte suspendu rejeté à la requête suivante.
- **Code affiché uniquement en Development. Aucun SMS réel envoyé.** En production, la demande de code répond 503 jusqu’au raccordement d’un fournisseur. Le parcours OTP ne peut donc pas être déclaré terminé en production.
- Annuaire réel : salons publiés, recherche par nom/commune, politique de visibilité après impayé, prestations et tarifs en vigueur. Aucun salon fictif ajouté à la base principale.
- Création d’un rendez-vous avec une à dix prestations successives, heure locale du salon, attribution automatique de ressources, contrôle partagé des horaires/capacités/abonnements, attente de décision du salon. Maintien facultatif selon politique. Rejeu idempotent lié au contenu.
- Rendez-vous du client et des gestionnaires habilités : acceptation, refus avec motif facultatif, annulation par le propriétaire avec délai et quota configurés. Identité issue de la session ; aucune identité fournie par formulaire.
- Refus et annulation atomiques avec événements et notifications **en attente d’envoi**.
- Protection antifalsification sur les formulaires modifiant des données.

## Preuves exécutées

- `infra/test-pwa.mjs` : cache public seulement, repli des navigations hors ligne, aucune interception des mutations d'authentification ou de rendez-vous.
- `infra/postgres/test_application.py` : **21 scénarios réussis** après les changements PWA, catalogue, OTP configurable et notifications ; base isolée `kb_application_9eb9bfe9ae09`, conservée pour inspection.
- Nouvelle exécution après ajout des adaptateurs paiement/KYC et des validations de production : **21 scénarios réussis**, base isolée `kb_application_7e3950a6d50f`, conservée pour inspection.
- Recette après remplacement de la date libre par les créneaux serveur : **22 scénarios réussis**, dont la présence de créneaux sélectionnables et l'absence de champ `datetime-local` ; base isolée `kb_application_27df1cb5d86e`, conservée pour inspection.
- Recette après extension aux quatre modes de capacité et correction de l'allocation par type de ressource : **23 scénarios réussis** ; base isolée `kb_application_6f08a1fc5dff`, conservée pour inspection. Les scripts additifs 030 à 061 ont ensuite été réappliqués avec succès à la base locale `keke_merise`.
- Recette après ajout de l'expiration automatique : **24 scénarios réussis** ; base isolée `kb_application_73b8f6d182c4`, conservée pour inspection. Le script additif 070 a été appliqué à `keke_merise`.
- Validation Scrum de KB-037 : compilation sans avertissement, **13 scénarios d'acceptation** dans `kb_acceptance_3c6969257022` et **24 scénarios applicatifs** dans `kb_application_79ebf1897de9`. Les contrôles couvrent notamment l'autorisation du gestionnaire, le refus idempotent, les transitions interdites, la concurrence sur la dernière place, les événements et les notifications en file.
- Validation de KB-039 : **25 scénarios applicatifs réussis** dans `kb_application_4dcdd57f3d31`. Le report client est testé via HTTP avec nouveau créneau, idempotence, quota partagé et vérification que l'échec conserve le planning précédent. La migration additive `080_report_rdv.sql` est appliquée à `keke_merise`.
- Fin de sprint technique : **27 scénarios applicatifs réussis** dans `kb_application_9bd958f4c34d`, incluant clôture idempotente, filtres/compteurs partenaire et état lu des notifications. La recette d'un fournisseur SMS réel reste bloquée par ses accès.
- Clôture du périmètre rendez-vous non bloqué : **28 scénarios applicatifs réussis** dans `kb_application_f952baf5f6ea`, incluant proposition de report partenaire, décision client, revalidation transactionnelle, quotas et concurrence.
- `dotnet build src/KekeBeauty.Web --no-restore` : zéro erreur et zéro avertissement après l'ajout PWA et la refonte de l'accueil.
- Vérification HTTP locale sur `http://localhost:5084` : accueil, manifeste, service worker et page hors connexion répondent en 200.
- Vérification visuelle de l'accueil sur ordinateur et exercice du breakpoint 390 × 844. La base locale inspectée ne contient actuellement aucune catégorie ni établissement publié à afficher.

- `dotnet build src/KekeBeauty.Web --no-restore` : zéro erreur, zéro avertissement.
- `infra/postgres/test_application.py` : **21 scénarios** HTTP/PostgreSQL, dernière base isolée `kb_application_8285e1937030`.
- `infra/postgres/test_acceptation.py` : **13 scénarios**, dont deux transactions concurrentes sur la dernière place ; base `kb_acceptance_91278d97813e`.
- La recette application inclut également deux créations concurrentes avec maintien : une seule obtient la dernière place, l’autre est annulée entièrement.
- Scripts 030, 040, 050, 060 et 061 installés dans `keke_merise`, sans suppression de données.
- Application locale démarrée sur `http://localhost:5083` ; accueil vérifié par HTTP 200 avec la configuration Docker locale.
- ClickUp : descriptions de KB-008, KB-032, KB-033, KB-037 et KB-038 mises à jour avec les réalisations et limites. Aucune tâche globale déclarée terminée.

Ces tests ne constituent pas une recette exhaustive du cahier des charges, un audit de sécurité ni une validation visuelle sur tous les appareils.

## Travail restant pour atteindre l’objectif

1. Raccorder et recetter l'envoi SMS réel avec le fournisseur retenu. La file, les reprises, la déduplication et tous les parcours rendez-vous applicatifs sont implémentés.
2. Espace partenaire : inscription, dépôt KYC privé, validation administrative, gestion multi-établissements, habilitations, services, prix, horaires, ressources et politiques depuis des écrans. Les tables existent ; ces écrans ne sont pas livrés.
3. Recherche complète : catégories, hiérarchie géographique, distance, médias, itinéraires.
4. Abonnements : souscription du payeur multi-salons, facturation configurée, échéances, vrais paiements Mobile Money et rapprochement, relances/renouvellement. Le contrôle des droits lit actuellement les données PostgreSQL ; il ne crée pas les contrats ni les paiements.
5. Administration et exploitation : gestion des comptes et paramètres, audit, droits PostgreSQL minimaux, migrations versionnées avec suivi, sauvegarde/restauration, supervision, sécurité et protection des données.
6. Recette complète : employés/ressources physiques/combinées, changements de fuseau et d’heure, accessibilité/mobile, performances, revue fonctionnelle, déploiement et tests des fournisseurs réels.
7. Compléter la synchronisation ClickUp : 84 tâches créées sur 84 prévues et identifiants vérifiés ; restent les descriptions détaillées, dépendances natives et douze fiches de pilotage des sprints. La preuve complémentaire de KB-039 est publiée.

Les points 1, 2, 4, 5 et 6 nécessitent encore du développement et, pour les intégrations réelles, les comptes fournisseur, les clés conservées dans un gestionnaire de secrets, les URL de rappel et un environnement d'hébergement. Aucun fournisseur fictif ne sera présenté comme opérationnel.

Le registre maintenu des blocages, de leurs impacts et des paramètres attendus se trouve dans [POINTS_BLOQUANTS.md](POINTS_BLOQUANTS.md). Les variables d'environnement sont détaillées dans [CONFIGURATION_INTEGRATIONS.md](CONFIGURATION_INTEGRATIONS.md).

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

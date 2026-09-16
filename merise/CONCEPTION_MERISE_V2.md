# Keke Beauty — MERISE V2, référence courante

Actualisation : le traitement `kb.accepter_rdv` est désormais implémenté et testé, y compris deux acceptations concurrentes. Voir [RECETTE_ACCEPTATION.md](RECETTE_ACCEPTATION.md) pour sa portée exacte. Les traitements de création, report et modification de capacité doivent encore adopter le même protocole ; les listes de travaux ci-dessous décrivent le périmètre complet.

Cette version applique les dernières réponses du porteur de projet et sa validation du caractère paramétrable des cinq derniers points. Les V0/V1 sont des historiques. MPD chargé dans PostgreSQL 17.11 Docker ; résultats et limites dans [VERIFICATION_V2.md](VERIFICATION_V2.md). L'application Blazor n'est pas encore connectée à ce schéma.

## 1. Règles de gestion (RG)

| ID | Règle V2 | Paramétrage / responsabilité |
|---|---|---|
| R2-01 | Lancement CI/XOF ; extension panafricaine possible. | Pays/devises/fuseaux administrables. Aucun changement automatique de devise des anciens faits. |
| R2-02 | Compte client authentifié par OTP pour réserver. | Sécurité OTP à spécifier avant service public. |
| R2-03 | Plusieurs gérants et établissements, permissions individuelles, un responsable principal avant activation. | Limites de gestion par administration ; affectations par acteurs habilités. |
| R2-04 | KYC vérifié avant activation partenaire ; documents privés. | Politique de conservation à arrêter avant collecte réelle. |
| R2-05 | Plusieurs prestations au même salon possibles. La réalisation et le règlement des soins sont gérés au salon. | Sélection multiple activable ; catalogue à variantes de prix/durée connus pour calculer les créneaux. Hypothèse technique : soins successifs, comme dans V1. |
| R2-06 | Toute réservation commence en attente du salon. Le salon accepte ou refuse explicitement. | Auteur habilité, résultat et date tracés ; aucune confirmation automatique. |
| R2-07 | Capacité globale, employés, ressources ou combinaison. | Choix obligatoire du gestionnaire avant activation ; capacités positives et ressources explicites. |
| R2-08 | La demande en attente peut réserver provisoirement une place. | Blocage oui/non obligatoire ; durée positive obligatoire seulement si blocage. Aucune valeur silencieuse de dix minutes. |
| R2-09 | Une place doit être recontrôlée atomiquement à l'acceptation. | Intervalles [début,fin[, capacités et pauses prises en compte. L'acceptation manuelle ne remplace pas le contrôle de concurrence. |
| R2-10 | Client autorisé à annuler ou reporter jusqu'à 1 h avant ; une fois par défaut. | Délai 60 minutes et limite 1 ; portée obligatoire : par RDV ou par couple client/salon. Annulation et report partagent le compteur (choix de conception documenté). |
| R2-11 | Un report échoué conserve le planning précédent. Les conditions acceptées restent celles du RDV. | Salon autorisé à proposer des alternatives ; le mécanisme de consentement au report salon reste à spécifier. |
| R2-12 | Aucun acompte, encaissement ou remboursement de prestation par la plateforme. | Le paiement sur place n'impose pas « espèces uniquement ». Aucun fournisseur de paiement client à intégrer. |
| R2-13 | Un compte payeur paie pour un ensemble d'établissements. | Distinct des comptes qui gèrent les salons. Périmètre couvert daté et périmètre facturé historisé par échéance. |
| R2-14 | Forfait global ou prix par établissement. Engagement minimum un an, mensualité ou annualité. | Mode et montant définis par l'administration, versionnés. Exemple purement illustratif : 3 salons × 10 000 = 30 000 XOF, ou forfait global 25 000 XOF. |
| R2-15 | Pas de grâce en cas d'impayé ; droits désactivés dès l'échéance dépassée. | Pas de paramètre permettant d'introduire une grâce. Nouvelles demandes et nouvelles acceptations bloquées. Visibilité fiche et gestion des RDV existants configurables par administration ; aucune suppression ni annulation silencieuse. |
| R2-16 | Un impayé concerne les établissements figurant dans son périmètre facturé. | Hypothèse opérationnelle explicite : une dette groupée désactive ce périmètre jusqu'à règlement. Un autre contrat ne permet pas de contourner une dette ; interdiction d'activation de couvertures actives concurrentes à implémenter. |
| R2-17 | Paiements d'abonnement via Mobile Money au lancement ; carte phase suivante. | Retour fournisseur vérifié ; référence et encaissement uniques ; prix, montant dû et montant encaissé sont des faits distincts. |
| R2-18 | Confirmation/notices envoyées après validation transactionnelle. | File de notification et reprise ; échec SMS ne change pas le RDV. |

Les politiques et tarifs sont immuables : une édition crée une nouvelle version. Les paramètres non renseignés empêchent l'activation ; ils ne constituent pas un blocage du développement. La géographie, les médias, les catégories, l'annuaire et les justificatifs restent ceux du CDC et du DD initial.

## 2. Dictionnaire de données (DD)

Les données V0 d'identité, annuaire, géographie, horaires et KYC sont conservées. Les DD de paiement client/avance V1 sont retirées du périmètre courant. Les champs, types, nullabilité et clés de chaque relation figurent dans [MLD_V2.md](MLD_V2.md).

| ID | Donnée | Sens, domaine et contrôle |
|---|---|---|
| D2-01 | mode_capacite | globale / employes / ressources / combinee ; obligatoire dans la politique salon |
| D2-02 | blocage_attente | Booléen explicite ; détermine la consommation temporaire de capacité |
| D2-03 | maintien_minutes | Entier > 0 si blocage, NULL sinon ; ne concerne aucun paiement |
| D2-04 | portee_modification | rendez_vous / client_etablissement ; obligatoire |
| D2-05 | limite_modifications | Entier > 0, défaut 1 ; annulation/report réussis, pas les tentatives rejetées |
| D2-06 | delai_annulation_minutes / delai_report_minutes | Entiers ≥ 0 ; défaut 60 ; seuil sur le début du premier soin |
| D2-07 | etat RDV | en_attente_salon, accepte, refuse, expire, annule, termine, absent |
| D2-08 | expire_le | Instant de fin de maintien ; à calculer depuis la politique lors de la demande |
| D2-09 | decision salon | résultat accepte/refuse, auteur compte, instant et motif facultatif ; une décision initiale par RDV |
| D2-10 | modification client | nature annulation/report, RDV, date, clé d'opération unique ; uniquement opérations réussies |
| D2-11 | payeur_compte_id | Compte responsable du contrat multi-établissements, distinct des affectations de gestion |
| D2-12 | couvert_depuis / couvert_jusqua | Période [début,fin[ de couverture d'un salon ; fin NULL = ouverte |
| D2-13 | mode_facturation | forfait / par_etablissement ; obligatoire par tarif |
| D2-14 | montant_du | Dette datée d'une échéance ; calculée et figée à émission, pas un solde courant |
| D2-15 | périmètre facturé | Une ligne par établissement inclus dans l'échéance, indépendant des changements ultérieurs du contrat |
| D2-16 | fiche_visible_si_impaye | Booléen obligatoire dans la politique abonnement, fixé par l'administration |
| D2-17 | gestion_rdv_existants_si_impaye | Booléen obligatoire ; ne vaut jamais suppression des historiques |
| D2-18 | tentative paiement | Référence fournisseur et clé opération ; référence toujours liée à une échéance d'abonnement |
| D2-19 | encaissement | Paiement abonnement vérifié ; FK unique tentative, montant effectivement reçu et date |
| D2-20 | devise / fuseau | XOF et Africa/Abidjan au lancement ; devise du tarif pour les échéances et paiements associés |

Pas de champ de compteur redondant : le nombre de modifications se calcule depuis MODIFICATION_CLIENT selon la portée acceptée. Le solde d'abonnement se calcule depuis dette et encaissements. Pas d'état KYC recopié dans GERANT.

## 3. MCD — entités et cardinalités de référence

Notation : chaque côté précise le nombre d'associations possibles pour une occurrence. Aucun FK SQL dans les objets conceptuels ; leur réalisation apparaît au MLD.

| Association | Côté A | Côté B | Contraintes |
|---|---|---|---|
| Gérer | Gérant 0,N | Établissement 0,N | Un principal minimum à activation, maximum un à tout instant |
| Habiliter | Affectation gérant/salon 0,N | Permission 0,N | Décider les RDV exige la permission correspondante |
| Situer | Établissement 0,1 | Commune 0,N | Commune requise à publication CI ; commune→ville→région→pays, chacun 1,1 vers parent |
| Classer | Établissement 0,N | Catégorie 0,N | Minimum une à publication |
| Illustrer | Établissement 0,N | Média 1,1 | Image/vidéo |
| Vérifier | Gérant 0,N | Dossier KYC 1,1 | Dossier 0,N justificatifs ; minimum à soumission |
| Proposer | Établissement 0,N | Prestation 1,1 | Prestation 0,N variantes ; variante 0,N versions ; version 1,1 variante |
| Régir | Établissement 0,N | Politique RDV 1,1 | Version immuable |
| Demander | Compte 0,N | RDV 1,1 | RDV accepte exactement une politique et en déduit son salon |
| Composer | RDV 1,N | Ligne 1,1 | Ligne choisit une version de variante du même salon |
| Décider | RDV 0,1 | Décision salon 1,1 | Auteur compte 0,N décisions ; habilité au salon au moment de décision |
| Modifier | RDV 0,N | Modification client 1,1 | Plafond conditionnel selon politique et historique du client |
| Équiper | Établissement 0,N | Ressource 1,1 | Employé, ressource physique ou pool global |
| Grouper | Groupe 1,N | Ressource 0,N | Alternatives dans un groupe, même salon |
| Exiger | Variante 0,N | Groupe 0,N | Quantité par couple, besoins cumulatifs |
| Allouer | Ligne 1,N à acceptation | Ressource 0,N | Quantité, intervalle porté par la ligne |
| Payer contrat | Compte payeur 0,N | Contrat 1,1 | Payeur distinct de gestionnaire |
| Couvrir | Contrat 0,N | Établissement 0,N | Périodes ; minimum un salon à activation ; pas de couverture active concurrente |
| Accepter tarif | Contrat 1,1 | Tarif offre 0,N | Tarif versionné → offre 1,1 et mode de facturation |
| Émettre | Contrat 0,N | Échéance 1,1 | Numéro unique par contrat, périmètre figé |
| Inclure facture | Échéance 1,N à émission | Établissement 0,N | État historique, pas une copie de la couverture courante |
| Régler | Échéance 0,N | Tentative 1,1 | Tentative 0,1 encaissement ; encaissement 1,1 tentative |
| Historiser | RDV 0,N | Événement 1,1 | Événement 0,N notifications ; destinataire compte et canal |

Les minima d'activation/composition sont des invariants transactionnels, pas tous des contraintes ligne-à-ligne du DDL. L'attribution initiale des capacités et la configuration restent sous la responsabilité du salon.

## 4. MLD et audit des trois formes normales

53 relations listées intégralement dans MLD_V2. Le script `020_modele_v2.sql` contient PK, UK, FK, contraintes de domaine et déclencheurs. Les tables ci-dessous sont regroupées uniquement pour lisibilité de l'audit ; chaque table conserve sa propre clé.

| Relations / famille | Clés et dépendances fonctionnelles | 1FN / 2FN / 3FN |
|---|---|---|
| PAYS, REGION, VILLE, COMMUNE | ID → propriétés propres,parent | Valeurs atomiques ; pas de nom du parent recopié. |
| COMPTE, GERANT, ROLE, COMPTE_ROLE | ID compte/gérant → propriétés ; code rôle et ID rôle candidats ; couple compte/rôle | Téléphone et identité séparés ; association sans attribut non-clé. Unicité téléphonique à durcir avec la politique de comptes OTP. |
| ETABLISSEMENT, CATEGORIE, ETABLISSEMENT_CATEGORIE, MEDIA | ID → propriétés ; couple salon/catégorie | Pas de hiérarchie géographique aplatie ni liste de médias. |
| GERANT_ETABLISSEMENT, PERMISSION, PERMISSION_GESTION | Couple → principal ; code → libellé ; triplet sans attribut non-clé | Propriétés liées à la clé entière, permission décrite séparément. |
| PLAGE_OUVERTURE, EXCEPTION_OUVERTURE, PLAGE_RESSOURCE, INDISPONIBILITE_RESSOURCE | ID → propriétaire et bornes | Une plage par ligne ; pas de colonnes répétées pour les jours. |
| DOSSIER_KYC, JUSTIFICATIF_KYC | ID dossier → gérant,décision ; ID pièce → dossier,type,référence | État du dossier non recopié chez le gérant ; justificatifs séparés. |
| DEVISE, PAYS_DEVISE | Code → libellé,décimales ; couple sans attribut non-clé | Pas de libellé devise dans tarifs, aucune liste dans une colonne. |
| PRESTATION, VARIANTE, VERSION_VARIANTE | IDs ; (variante,date_effet) candidat → durée,prix,devise | Ni salon ni nom de prestation recopiés dans une version. Versions immuables. |
| POLITIQUE_RDV | ID, (salon,version), (salon,date_effet) → conditions | Chaque ensemble est une clé candidate entière. Pas de libellés de salon ; paramètres typés, pas d'EAV libre. |
| RESSOURCE, GROUPE_RESSOURCE, MEMBRE_GROUPE, BESOIN_VARIANTE | ID ressource/groupe → propriétés ; couples ; (variante,groupe) → quantité | Besoin dépend du couple entier ; alternatives en lignes. |
| RENDEZ_VOUS, LIGNE_RDV, ALLOCATION_RDV | RDV → client,politique,état,dates ; (RDV,numéro) → version,bornes ; (RDV,numéro,ressource) → quantité | Salon déduit de politique ; durée/tarif catalogue non copiés. Bornes = planning convenu, durée catalogue = estimation ; adaptation éventuelle doit être explicite. |
| DECISION_SALON | ID et RDV candidat → auteur,résultat,motif,date | Une décision initiale ; son état n'est pas le cycle de vie du RDV (une acceptation peut ensuite être annulée). |
| MODIFICATION_CLIENT | ID et clé_opération → RDV,nature,date | Client/salon obtenus via RDV/politique, pas dupliqués ; pas de compteur stocké. |
| EVENEMENT_RDV, HISTORIQUE_LIGNE, NOTIFICATION | ID événement ; (événement,numéro) ; ID et (événement,destinataire,canal) | Dépendances sur clés entières ; un fait par ligne ; destinataire non recopié comme téléphone. |
| DEMANDE_IDEMPOTENTE | (compte,clé) → empreinte,RDV,date | Pas de dépendance sur compte ou clé seuls. |
| OFFRE, FONCTIONNALITE, OFFRE_FONCTIONNALITE, TARIF_OFFRE | ID/code ; couple ; ID tarif et (offre,périodicité,mode,devise,effet) | Métadonnées de fonctionnalité séparées ; tarif immuable, pas recopié au contrat. |
| POLITIQUE_ABONNEMENT, CONTRAT | ID politique → droits impayé ; contrat → payeur,tarif,politique,période,état | Pas de salon, montant, fréquence ou devise redondants dans contrat. |
| CONTRAT_ETABLISSEMENT | (contrat,salon,début_couverture) → fin | Fin dépend de toute la clé, plusieurs épisodes possibles. |
| ECHEANCE, ECHEANCE_ETABLISSEMENT | ID et (contrat,numéro) → période,exigibilité,montant dû ; couple sans propriété | Dette datée distincte du prix catalogue ; périmètre facturé distinct de couverture courante. Aucune devise dupliquée (obtenue via tarif accepté). |
| TENTATIVE_PAIEMENT, ENCAISSEMENT | ID tentative,clé_opération,référence fournisseur si présente → échéance,montant demandé,état ; ID encaissement et tentative → montant reçu,date | Pas de RDV/cible client, ni de devise redondante ; demandé et reçu sont deux faits distincts. |
| CONFIGURATION_PLATEFORME, VERSION_SCHEMA | ID/date_effet → limites ; version → date_application | Configuration datée, valeurs atomiques ; table technique de suivi isolée. |

Conclusion : aucune dépendance partielle ou transitive non justifiée identifiée dans les dépendances connues. Une clé technique ne suffit pas à prouver la 3FN ; les clés alternatives sont prises en compte. Les règles de concurrence, habilitation et minimum d'occurrences sont des contraintes supplémentaires, non des formes normales.

## 5. MCT — événements et résultats

| Événement / condition | Opération | Résultat |
|---|---|---|
| Client authentifié + salon actif | Déposer demande, calculer planning et politique | EN_ATTENTE_SALON, notification partenaire ; maintien seulement si activé |
| Gestionnaire habilité + demande en attente + droits actifs + capacité | Accepter atomiquement | Décision ACCEPTÉ et RDV ACCEPTE ; notification client après commit |
| Gestionnaire habilité refuse | Refuser et libérer le maintien | REFUSE avec motif, notification client |
| Maintien arrivé à échéance | Expirer demande bloquante | EXPIRE et libération ; reprise par nouvelle demande, pas d'acceptation rétroactive |
| Client annule dans délai/limite | Compter et annuler atomiquement | Modification enregistrée, ANNULE, capacité libérée |
| Client reporte dans délai/limite + capacité cible | Déplacer atomiquement | Compteur consommé et planning mis à jour ; échec conserve ancien RDV |
| Dette d'abonnement exigible non réglée | Calculer droits sans grâce | Désactivation périmètre facturé, visibilité/gestion existants selon politique |
| Paiement abonnement fiable | Encaisser et recalculer dette/droits | Réactivation si aucune dette bloquante ; notification administrative |
| Soin réalisé | Clore RDV | TERMINE ; aucun traitement de règlement du soin |

Sans blocage en attente, plusieurs demandes peuvent viser la même heure, mais une acceptation ne peut dépasser la capacité. Le délai de réponse sans blocage n'a pas de valeur imposée ; il pourra être ajouté comme paramètre métier distinct, sans réutiliser le maintien.

## 6. MOT — organisation

| Acteur | Lieu / moment | Responsabilité |
|---|---|---|
| Client | Web responsive, à la demande | Demande, annulation/report autorisé ; aucune saisie de paiement de soin |
| Gestionnaire habilité | Espace salon, avant activation puis demandes entrantes | Paramétrer capacité/attente/limites ; accepter/refuser ; assurer la prestation et son règlement hors plateforme |
| Compte payeur | Espace abonnement | Régler le périmètre de salons couvert |
| Administrateur | Console privée | KYC, offres, modes tarifaires, droits après impayé, résolution d'incidents |
| Serveur | À chaque mutation | Droits, contraintes, verrouillage et cohérence ; aucun appel externe sous verrou |
| Tâche planifiée | Échéances de maintien et d'abonnement | Expirations, désactivation, notifications ; contrôle synchrone des droits aussi nécessaire |

## 7. MPD — réalisé et limites

Réalisé dans PostgreSQL : 53 tables, 64 FK, PK/UK/CHECK, index des FK, immutabilité des versions et propriétaires, contrôle du salon des lignes/allocations/groupes, permission `rdv_decider`, cohérence différée état/décision à fin de transaction. Initialisation `020`, correctif historique de jointure `022`, tests `021`. Base locale dédiée, pas de données client.

À implémenter dans le service transactionnel avant utilisation réelle :

1. Verrouiller salon puis ressources dans un ordre stable ; contrôler toutes les capacités sur les sous-intervalles. Tous les chemins d'écriture (acceptation, report, indisponibilité, réduction de capacité) doivent suivre ce protocole. Le DDL seul n'empêche pas encore le surbooking.
2. Vérifier ressources requises, horaires, séquence et durée des lignes, groupe de variantes et type de capacité. Le DDL interdit le mélange de salons mais n'impose pas encore le minimum d'une ligne et d'une allocation.
3. Calculer expiration à partir de la politique ; départager atomiquement expiration et acceptation. Aucun maintien implicite lorsque désactivé.
4. Compter les annulations/reports réussis selon portée, sous verrou client/salon ou RDV ; appliquer le seuil d'une heure avant mutation. L'enregistrement ne constitue pas encore un moteur de limite.
5. Émettre les échéances et leur périmètre, calculer forfait/unitaire, vérifier engagement et couverture non chevauchante ; appliquer droits dès exigibilité sans délai de grâce. Aucune désactivation automatique n'est encore exécutée par la seule base.
6. Vérifier authenticité fournisseur et montant avant encaissement ; protéger références et opérations ; ne pas prendre `etat=succes` en entrée navigateur comme preuve.
7. Mettre en place le rôle SQL applicatif minimal (distinct du propriétaire de test), authentification et contrôles d'identité : une FK d'auteur n'authentifie pas l'appelant.
8. Transaction événement + notification et stratégie de reprise ; ne pas modifier une politique acceptée lors d'un report.

Les tests SQL passent, mais ne couvrent pas les accès HTTP, SMS, paiement réel ou concurrence du futur service. La prochaine étape de développement est le service de réservation et sa recette concurrente, puis raccordement Blazor.

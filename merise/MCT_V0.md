# Keke Beauty — Modèle conceptuel des traitements initial

Statut : **proposition à valider**. Le MCT décrit ce qui déclenche une opération métier et ce qu'elle produit, indépendamment de l'écran, du service technique ou de la personne qui l'exécute. Le MOT précisera ensuite acteur, lieu, moment et moyen.

| ID | Événement entrant | Conditions métier | Opération conceptuelle | Résultats / événements sortants | Règles |
|---|---|---|---|---|---|
| T-01 | Numéro soumis pour inscription/connexion | Numéro recevable ; quota non dépassé | Préparer une preuve de possession du numéro | Code OTP émis ou demande refusée | RG-001 |
| T-02 | Code OTP soumis | Code valide, non expiré et non utilisé | Vérifier la preuve et ouvrir la session | Compte authentifié ou échec explicite | RG-001 |
| T-03 | Informations d'établissement et pièces déposées | Champs obligatoires et fichiers recevables | Constituer puis soumettre le dossier partenaire | Dossier KYC en attente d'examen ou retour pour correction | RG-002/003/016 |
| T-04 | Dossier KYC soumis | Contrôleur habilité, pièces disponibles | Examiner et décider | Partenaire activé ou dossier rejeté avec motif | RG-003/015/016 |
| T-05 | Prestations, tarifs, médias et horaires modifiés | Partenaire habilité ; données valides | Mettre à jour la fiche et le catalogue | Fiche publiable/mise à jour ou refus de modification | RG-004/006 |
| T-06 | Critères de recherche soumis | Zones et catégorie recevables | Sélectionner les établissements publiés correspondants | Résultats ordonnés ou absence de résultat | RG-005/006 |
| T-07 | Service, date et heure demandés | Client authentifié ; réservation activée ; droit payant applicable ; capacité disponible | Enregistrer la demande sans dépasser la capacité | RDV demandé et notification à émettre ou créneau refusé | RG-007/008/017 |
| T-08 | Décision du partenaire reçue | RDV dans un état autorisant la décision | Confirmer ou refuser la demande | RDV confirmé/refusé ; disponibilité recalculée ; notification à émettre | RG-009/010/017 |
| T-09 | Annulation ou proposition de reprogrammation reçue | Acteur, délai, état et nouveau créneau autorisés | Modifier le cycle de vie du RDV | RDV annulé/reprogrammé ou changement refusé ; notification à émettre | RG-009/010/017 |
| T-10 | Événement de rendez-vous créé | Destinataire et canal valides | Préparer la communication du résultat | Notification envoyée, en attente de reprise ou en échec | RG-010 |
| T-11 | Offre et périodicité choisies | Partenaire éligible ; contrat et tarif applicables | Constituer la souscription et ses échéances | Contrat à payer ou choix refusé | RG-011/012 |
| T-12 | Paiement initié | Échéance payable ; montant et devise concordants | Ouvrir une tentative d'encaissement | Référence de paiement et parcours fournisseur ou initiation refusée | RG-013/014 |
| T-13 | Résultat de paiement reçu | Authenticité, montant, devise, référence et état vérifiés | Rapprocher la tentative et l'échéance, une seule fois | Échéance réglée et droit activé ou paiement en échec/à vérifier | RG-014 |
| T-14 | Échéance arrivée ou paiement en retard | Contrat actif ; règles de grâce/relance définies | Traiter l'échéance et les droits | Relance, maintien, suspension ou rétablissement selon contrat | RG-011/014 |
| T-15 | Signalement ou décision de modération reçue | Administrateur habilité ; motif recevable | Modérer un compte ou une fiche | Visibilité/droits modifiés et action historisée | RG-015 |

## Enchaînements à démontrer

**Partenaire** : T-03 → T-04 → T-05 → T-11 → T-12 → T-13. La fiche et la réservation ont des règles d'accès différentes ; leur activation doit suivre la politique d'offre validée.

**Client** : T-01 → T-02 → T-06 → T-07 → T-08 → T-10. T-09 peut suivre une demande ou une confirmation selon les états décidés.

**Paiement** : T-12 peut recevoir plusieurs événements du fournisseur, mais T-13 ne doit produire qu'un seul effet économique pour une même preuve d'encaissement. Un retour de navigateur ne suffit pas à déclarer le paiement réussi.

## Décisions bloquant le MCT définitif

- T-07/T-08 : moment exact où une demande réserve la capacité, durée d'attente et traitement des demandes concurrentes.
- T-09 : acteurs, délais et nécessité d'un accord client pour reprogrammer.
- T-11/T-14 : renouvellement, impayés, grâce et droits des rendez-vous existants.
- T-03/T-04 : documents KYC exigés, motifs de refus et resoumission.

Ces réponses seront reprises dans le MOT sans modifier la distinction MERISE : le MCT décrit le traitement métier ; le MOT précise son organisation concrète.

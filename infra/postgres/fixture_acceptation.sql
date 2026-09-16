INSERT INTO kb.etablissement(nom,etat_publication) VALUES ('TEST acceptance','publie');
INSERT INTO kb.compte(telephone_normalise,etat) VALUES ('client','actif'),('gerant','actif');
INSERT INTO kb.gerant(compte_id,nom_declare) VALUES(2,'Gerant');
INSERT INTO kb.gerant_etablissement VALUES(1,1,true);
INSERT INTO kb.permission_gestion VALUES(1,1,'rdv_decider');
INSERT INTO kb.politique_rdv(etablissement_id,version,date_effet,mode_capacite,blocage_attente,portee_modification)
VALUES(1,1,now(),'globale',false,'rendez_vous');
INSERT INTO kb.prestation(etablissement_id,nom,etat) VALUES(1,'Soin','actif');
INSERT INTO kb.variante(prestation_id,libelle) VALUES(1,'Standard');
INSERT INTO kb.version_variante(variante_id,date_effet,duree_minutes,montant,devise) VALUES(1,now(),30,5000,'XOF');
INSERT INTO kb.ressource(etablissement_id,nature,libelle,capacite) VALUES(1,'globale','Pool',1);
INSERT INTO kb.groupe_ressource(etablissement_id,libelle) VALUES(1,'Places');
INSERT INTO kb.membre_groupe VALUES(1,1);
INSERT INTO kb.besoin_variante VALUES(1,1,1);
INSERT INTO kb.plage_ouverture(etablissement_id,jour_semaine,heure_debut,heure_fin)
SELECT 1,n,'00:00','23:59' FROM generate_series(1,7)n;
INSERT INTO kb.plage_ressource(ressource_id,jour_semaine,debut,fin)
SELECT 1,n,'00:00','23:59' FROM generate_series(1,7)n;
INSERT INTO kb.offre(nom) VALUES('Test');
INSERT INTO kb.tarif_offre(offre_id,periodicite,mode_facturation,montant,devise,date_effet)
VALUES(1,'annuelle','forfait',1000,'XOF',now());
INSERT INTO kb.politique_abonnement(fiche_visible_si_impaye,gestion_rdv_existants_si_impaye) VALUES(false,true);
INSERT INTO kb.contrat(payeur_compte_id,tarif_offre_id,politique_abonnement_id,debut,fin_engagement,etat)
VALUES(2,1,1,CURRENT_DATE,CURRENT_DATE+interval '1 year','actif');
INSERT INTO kb.contrat_etablissement VALUES(1,1,CURRENT_DATE,NULL);
INSERT INTO kb.echeance(contrat_id,numero,debut_periode,fin_periode,exigible_le,montant_du)
VALUES(1,1,CURRENT_DATE,CURRENT_DATE+interval '1 year',now()-interval '1 minute',1000);
INSERT INTO kb.echeance_etablissement VALUES(1,1);
INSERT INTO kb.tentative_paiement(echeance_id,cle_operation,fournisseur,montant_demande,etat)
VALUES(1,'op','test',1000,'succes');
INSERT INTO kb.encaissement(tentative_id,montant,encaisse_le) VALUES(1,1000,now());
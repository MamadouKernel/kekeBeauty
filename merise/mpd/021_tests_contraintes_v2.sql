\set ON_ERROR_STOP on
BEGIN;
CREATE FUNCTION pg_temp.expect_error(label text, command text, expected text)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE command;
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE <> expected THEN
      RAISE EXCEPTION '%: expected %, received % (%)', label, expected, SQLSTATE, SQLERRM;
    END IF;
    RAISE NOTICE 'PASS: % [%]', label, expected;
    RETURN;
  END;
  RAISE EXCEPTION '%: invalid operation was accepted', label;
END $$;
INSERT INTO kb.etablissement(nom,etat_publication) VALUES ('TEST V2 rollback','brouillon') RETURNING etablissement_id AS salon \gset
INSERT INTO kb.etablissement(nom,etat_publication) VALUES ('TEST V2 autre','brouillon') RETURNING etablissement_id AS autre \gset
INSERT INTO kb.compte(telephone_normalise,etat) VALUES ('TEST V2 client','actif') RETURNING compte_id AS client \gset
INSERT INTO kb.compte(telephone_normalise,etat) VALUES ('TEST V2 gerant','actif') RETURNING compte_id AS gestionnaire \gset
INSERT INTO kb.gerant(compte_id,nom_declare) VALUES (:gestionnaire,'TEST') RETURNING gerant_id AS gerant \gset
INSERT INTO kb.gerant_etablissement VALUES (:gerant,:salon,true);
INSERT INTO kb.permission_gestion VALUES (:gerant,:salon,'rdv_decider');
INSERT INTO kb.gerant(compte_id,nom_declare) VALUES (:client,'TEST second') RETURNING gerant_id AS second \gset
SELECT pg_temp.expect_error('principal unique',format('INSERT INTO kb.gerant_etablissement VALUES (%s,%s,true)',:second,:salon),'23505');
SELECT pg_temp.expect_error('capacite positive',format('INSERT INTO kb.ressource(etablissement_id,nature,libelle,capacite) VALUES (%s,''globale'',''test'',0)',:salon),'23514');
SELECT pg_temp.expect_error('employe capacite un',format('INSERT INTO kb.ressource(etablissement_id,nature,libelle,capacite) VALUES (%s,''employe'',''test'',2)',:salon),'23514');
SELECT pg_temp.expect_error('configuration explicite',format('INSERT INTO kb.politique_rdv(etablissement_id,version,date_effet) VALUES (%s,1,CURRENT_TIMESTAMP)',:salon),'23502');
SELECT pg_temp.expect_error('blocage exige duree',format('INSERT INTO kb.politique_rdv(etablissement_id,version,date_effet,mode_capacite,blocage_attente,portee_modification) VALUES (%s,1,CURRENT_TIMESTAMP,''globale'',true,''rendez_vous'')',:salon),'23514');
SELECT pg_temp.expect_error('pas de duree sans blocage',format('INSERT INTO kb.politique_rdv(etablissement_id,version,date_effet,mode_capacite,blocage_attente,maintien_minutes,portee_modification) VALUES (%s,1,CURRENT_TIMESTAMP,''globale'',false,10,''rendez_vous'')',:salon),'23514');
INSERT INTO kb.politique_rdv(etablissement_id,version,date_effet,mode_capacite,blocage_attente,portee_modification) VALUES (:salon,1,CURRENT_TIMESTAMP,'globale',false,'rendez_vous') RETURNING politique_id AS politique \gset
DO $$ BEGIN
 IF EXISTS (SELECT 1 FROM kb.politique_rdv WHERE delai_annulation_minutes <> 60 OR delai_report_minutes <> 60 OR limite_modifications <> 1) THEN RAISE EXCEPTION 'Valeurs initiales incorrectes'; END IF;
 RAISE NOTICE 'PASS: delai 60 minutes et limite 1';
END $$;
SELECT pg_temp.expect_error('politique immuable',format('UPDATE kb.politique_rdv SET limite_modifications=2 WHERE politique_id=%s',:politique),'23514');
INSERT INTO kb.rendez_vous(client_id,politique_id) VALUES (:client,:politique) RETURNING rdv_id AS rdv \gset
SELECT pg_temp.expect_error('ancien statut automatique interdit',format('UPDATE kb.rendez_vous SET etat=''confirme'' WHERE rdv_id=%s',:rdv),'23514');
SELECT pg_temp.expect_error('acceptation sans decision interdite',format('UPDATE kb.rendez_vous SET etat=''accepte'' WHERE rdv_id=%s; SET CONSTRAINTS ALL IMMEDIATE',:rdv),'23514');
SELECT pg_temp.expect_error('decision par client interdite',format('INSERT INTO kb.decision_salon(rdv_id,auteur_compte_id,resultat) VALUES (%s,%s,''accepte'')',:rdv,:client),'23514');
SELECT pg_temp.expect_error('foreign key politique',format('INSERT INTO kb.rendez_vous(client_id,politique_id) VALUES (%s,-1)',:client),'23503');
INSERT INTO kb.prestation(etablissement_id,nom,etat) VALUES (:salon,'TEST soin','actif') RETURNING prestation_id AS prestation \gset
INSERT INTO kb.variante(prestation_id,libelle) VALUES (:prestation,'TEST') RETURNING variante_id AS variante \gset
INSERT INTO kb.version_variante(variante_id,date_effet,duree_minutes,montant,devise) VALUES (:variante,CURRENT_TIMESTAMP,30,5000,'XOF') RETURNING version_variante_id AS version_soin \gset
SELECT pg_temp.expect_error('intervalle ordonne',format('INSERT INTO kb.ligne_rdv VALUES (%s,1,%s,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)',:rdv,:version_soin),'23514');
INSERT INTO kb.ligne_rdv VALUES (:rdv,1,:version_soin,CURRENT_TIMESTAMP + interval '2 hours',CURRENT_TIMESTAMP + interval '150 minutes');
SELECT pg_temp.expect_error('tarif accepte immuable',format('UPDATE kb.version_variante SET montant=6000 WHERE version_variante_id=%s',:version_soin),'23514');
INSERT INTO kb.ressource(etablissement_id,nature,libelle,capacite) VALUES (:autre,'globale','autre pool',3) RETURNING ressource_id AS mauvaise_ressource \gset
SELECT pg_temp.expect_error('allocation autre salon interdite',format('INSERT INTO kb.allocation_rdv VALUES (%s,1,%s,1)',:rdv,:mauvaise_ressource),'23514');
INSERT INTO kb.ressource(etablissement_id,nature,libelle,capacite) VALUES (:salon,'globale','pool',3) RETURNING ressource_id AS ressource \gset
INSERT INTO kb.allocation_rdv VALUES (:rdv,1,:ressource,1);
INSERT INTO kb.groupe_ressource(etablissement_id,libelle) VALUES (:salon,'pool') RETURNING groupe_id AS groupe \gset
SELECT pg_temp.expect_error('groupe autre salon interdit',format('INSERT INTO kb.membre_groupe VALUES (%s,%s)',:groupe,:mauvaise_ressource),'23514');
INSERT INTO kb.membre_groupe VALUES (:groupe,:ressource);
INSERT INTO kb.besoin_variante VALUES (:variante,:groupe,1);
INSERT INTO kb.decision_salon(rdv_id,auteur_compte_id,resultat) VALUES (:rdv,:gestionnaire,'accepte');
UPDATE kb.rendez_vous SET etat='accepte' WHERE rdv_id=:rdv;
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
SELECT 'PASS: acceptation explicite habilitee' AS result;
INSERT INTO kb.demande_idempotente(compte_id,cle,empreinte,rdv_id) VALUES (:client,'TEST V2 key','hash',:rdv);
SELECT pg_temp.expect_error('idempotence unique',format('INSERT INTO kb.demande_idempotente(compte_id,cle,empreinte) VALUES (%s,''TEST V2 key'',''hash'')',:client),'23505');
INSERT INTO kb.offre(nom) VALUES ('TEST V2 offre') RETURNING offre_id AS offre \gset
SELECT pg_temp.expect_error('mode facturation explicite',format('INSERT INTO kb.tarif_offre(offre_id,periodicite,montant,devise,date_effet) VALUES (%s,''mensuelle'',1000,''XOF'',CURRENT_TIMESTAMP)',:offre),'23502');
INSERT INTO kb.tarif_offre(offre_id,periodicite,mode_facturation,montant,devise,date_effet) VALUES (:offre,'mensuelle','par_etablissement',1000,'XOF',CURRENT_TIMESTAMP) RETURNING tarif_offre_id AS tarif \gset
INSERT INTO kb.politique_abonnement(fiche_visible_si_impaye,gestion_rdv_existants_si_impaye) VALUES (false,true) RETURNING politique_abonnement_id AS politique_abo \gset
SELECT pg_temp.expect_error('engagement annuel',format('INSERT INTO kb.contrat(payeur_compte_id,tarif_offre_id,politique_abonnement_id,debut,fin_engagement,etat) VALUES (%s,%s,%s,''2026-01-01'',''2026-12-01'',''actif'')',:gestionnaire,:tarif,:politique_abo),'23514');
INSERT INTO kb.contrat(payeur_compte_id,tarif_offre_id,politique_abonnement_id,debut,fin_engagement,etat) VALUES (:gestionnaire,:tarif,:politique_abo,'2026-01-01','2027-01-01','brouillon') RETURNING contrat_id AS contrat \gset
INSERT INTO kb.contrat_etablissement VALUES (:contrat,:salon,'2026-01-01',NULL),(:contrat,:autre,'2026-01-01',NULL);
INSERT INTO kb.echeance(contrat_id,numero,debut_periode,fin_periode,exigible_le,montant_du) VALUES (:contrat,1,'2026-01-01','2026-02-01','2026-01-01',2000) RETURNING echeance_id AS echeance \gset
INSERT INTO kb.echeance_etablissement VALUES (:echeance,:salon),(:echeance,:autre);
SELECT 'PASS: un payeur et deux etablissements' AS result;
INSERT INTO kb.tentative_paiement(echeance_id,cle_operation,fournisseur,reference_externe,montant_demande,etat) VALUES (:echeance,'TEST V2 op1','TEST','TEST V2 ref',2000,'succes') RETURNING tentative_id AS tentative \gset
SELECT pg_temp.expect_error('reference fournisseur unique',format('INSERT INTO kb.tentative_paiement(echeance_id,cle_operation,fournisseur,reference_externe,montant_demande,etat) VALUES (%s,''TEST V2 op2'',''TEST'',''TEST V2 ref'',2000,''succes'')',:echeance),'23505');
INSERT INTO kb.encaissement(tentative_id,montant,encaisse_le) VALUES (:tentative,2000,CURRENT_TIMESTAMP);
SELECT pg_temp.expect_error('encaissement unique par tentative',format('INSERT INTO kb.encaissement(tentative_id,montant,encaisse_le) VALUES (%s,2000,CURRENT_TIMESTAMP)',:tentative),'23505');
DO $$ BEGIN
 IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='kb' AND column_name IN ('avance_due','mode_avance','grace_jours')) THEN RAISE EXCEPTION 'Anciennes regles presentes'; END IF;
 IF to_regclass('kb.cible_reglement') IS NOT NULL OR to_regclass('kb.encaissement_especes') IS NOT NULL THEN RAISE EXCEPTION 'Paiement client present'; END IF;
 RAISE NOTICE 'PASS: pas de paiement client ni grace';
END $$;
SET CONSTRAINTS ALL IMMEDIATE;
ROLLBACK;
SELECT 'V2: tests termines, fixtures annulees' AS result;

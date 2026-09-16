\set ON_ERROR_STOP on
BEGIN;
-- All fixtures are rolled back. Only the schema is retained.
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
END;
$$;
INSERT INTO kb.etablissement(nom,etat_publication) VALUES ('TEST rollback','brouillon') RETURNING etablissement_id AS salon \gset
INSERT INTO kb.compte(telephone_normalise,etat) VALUES ('+225TEST','actif') RETURNING compte_id AS client \gset
INSERT INTO kb.gerant(compte_id,nom_declare) VALUES (:client,'TEST') RETURNING gerant_id AS gerant \gset
INSERT INTO kb.gerant_etablissement VALUES (:gerant,:salon,true);
INSERT INTO kb.gerant(compte_id,nom_declare) VALUES (:client,'TEST second') RETURNING gerant_id AS second \gset
SELECT pg_temp.expect_error('one principal',format('INSERT INTO kb.gerant_etablissement VALUES (%s,%s,true)',:second,:salon),'23505');
SELECT pg_temp.expect_error('resource capacity positive',format('INSERT INTO kb.ressource(etablissement_id,nature,libelle,capacite) VALUES (%s,''globale'',''test'',0)',:salon),'23514');
SELECT pg_temp.expect_error('employee capacity one',format('INSERT INTO kb.ressource(etablissement_id,nature,libelle,capacite) VALUES (%s,''employe'',''test'',2)',:salon),'23514');
INSERT INTO kb.politique_rdv(etablissement_id,version,date_effet) VALUES (:salon,1,CURRENT_TIMESTAMP) RETURNING politique_id AS politique \gset
SELECT pg_temp.expect_error('mandatory advance requires value',format('INSERT INTO kb.politique_rdv(etablissement_id,version,date_effet,mode_avance) VALUES (%s,2,CURRENT_TIMESTAMP + interval ''1 day'',''obligatoire'')',:salon),'23514');
SELECT pg_temp.expect_error('advance percentage bounded',format('INSERT INTO kb.politique_rdv(etablissement_id,version,date_effet,mode_avance,calcul_avance,valeur_avance) VALUES (%s,2,CURRENT_TIMESTAMP + interval ''1 day'',''obligatoire'',''pourcentage'',101)',:salon),'23514');
INSERT INTO kb.rendez_vous(client_id,politique_id,etat,avance_due) VALUES (:client,:politique,'confirme',0) RETURNING rdv_id AS rdv \gset
SELECT pg_temp.expect_error('pending booking needs expiration',format('INSERT INTO kb.rendez_vous(client_id,politique_id,etat,avance_due) VALUES (%s,%s,''attente_paiement'',100)',:client,:politique),'23514');
SELECT pg_temp.expect_error('foreign key policy','INSERT INTO kb.rendez_vous(client_id,politique_id,etat,avance_due) VALUES (' || :client || ',-1,''confirme'',0)','23503');
INSERT INTO kb.prestation(etablissement_id,nom,etat) VALUES (:salon,'TEST soin','actif') RETURNING prestation_id AS prestation \gset
INSERT INTO kb.variante(prestation_id,libelle) VALUES (:prestation,'TEST') RETURNING variante_id AS variante \gset
INSERT INTO kb.version_variante(variante_id,date_effet,duree_minutes,montant,devise) VALUES (:variante,CURRENT_TIMESTAMP,30,5000,'XOF') RETURNING version_variante_id AS version_soin \gset
SELECT pg_temp.expect_error('interval ordered',format('INSERT INTO kb.ligne_rdv VALUES (%s,1,%s,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)',:rdv,:version_soin),'23514');
INSERT INTO kb.ligne_rdv VALUES (:rdv,1,:version_soin,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP + interval '30 minutes');
INSERT INTO kb.demande_idempotente(compte_id,cle,empreinte,rdv_id) VALUES (:client,'test-key','hash',:rdv);
SELECT pg_temp.expect_error('idempotency uniqueness',format('INSERT INTO kb.demande_idempotente(compte_id,cle,empreinte) VALUES (%s,''test-key'',''hash'')',:client),'23505');
SELECT pg_temp.expect_error('payment target required','INSERT INTO kb.cible_reglement(devise) VALUES (''XOF'')','23514');
INSERT INTO kb.cible_reglement(rdv_id,devise) VALUES (:rdv,'XOF') RETURNING cible_id AS cible \gset
INSERT INTO kb.tentative_paiement(cible_id,cle_operation,fournisseur,reference_externe,montant_demande,etat) VALUES (:cible,'op1','TEST','ref1',1000,'succes');
SELECT pg_temp.expect_error('provider reference deduplicated',format('INSERT INTO kb.tentative_paiement(cible_id,cle_operation,fournisseur,reference_externe,montant_demande,etat) VALUES (%s,''op2'',''TEST'',''ref1'',1000,''succes'')',:cible),'23505');
INSERT INTO kb.offre(nom) VALUES ('TEST') RETURNING offre_id AS offre \gset
INSERT INTO kb.tarif_offre(offre_id,periodicite,montant,devise,date_effet) VALUES (:offre,'mensuelle',1000,'XOF',CURRENT_TIMESTAMP) RETURNING tarif_offre_id AS tarif \gset
INSERT INTO kb.politique_abonnement DEFAULT VALUES RETURNING politique_abonnement_id AS politique_abo \gset
SELECT pg_temp.expect_error('one year commitment',format('INSERT INTO kb.contrat(etablissement_id,tarif_offre_id,politique_abonnement_id,debut,fin_engagement,etat) VALUES (%s,%s,%s,''2026-01-01'',''2026-12-01'',''actif'')',:salon,:tarif,:politique_abo),'23514');
ROLLBACK;
SELECT '12 constraint checks passed; fixtures rolled back' AS result;

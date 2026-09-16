BEGIN;
CREATE OR REPLACE FUNCTION kb.refuser_rdv(p_rdv bigint,p_auteur bigint,p_motif text) RETURNS text LANGUAGE plpgsql AS $$
DECLARE salon bigint; r kb.rendez_vous; evenement bigint;
BEGIN
 IF current_setting('transaction_isolation')<>'read committed' THEN RAISE EXCEPTION 'READ COMMITTED requis' USING ERRCODE='25001'; END IF;
 SELECT p.etablissement_id INTO salon FROM kb.rendez_vous v JOIN kb.politique_rdv p USING(politique_id) WHERE v.rdv_id=p_rdv;
 IF salon IS NULL THEN RAISE EXCEPTION 'RDV introuvable' USING ERRCODE='P0002'; END IF;
 PERFORM 1 FROM kb.etablissement WHERE etablissement_id=salon FOR UPDATE;
 SELECT * INTO r FROM kb.rendez_vous WHERE rdv_id=p_rdv FOR UPDATE;
 IF NOT EXISTS(SELECT 1 FROM kb.gerant g JOIN kb.permission_gestion pg USING(gerant_id) JOIN kb.compte c ON c.compte_id=g.compte_id
   WHERE pg.etablissement_id=salon AND c.compte_id=p_auteur AND c.etat='actif' AND pg.permission_code='rdv_decider')
 THEN RAISE EXCEPTION 'Non habilite' USING ERRCODE='42501'; END IF;
 IF r.etat='refuse' THEN RETURN 'deja_refuse'; END IF;
 IF r.etat<>'en_attente_salon' THEN RAISE EXCEPTION 'Etat incompatible' USING ERRCODE='23514'; END IF;
 IF length(p_motif)>1000 THEN RAISE EXCEPTION 'Motif trop long' USING ERRCODE='23514'; END IF;
 IF EXISTS(SELECT 1 FROM kb.echeance e JOIN kb.echeance_etablissement ee USING(echeance_id)
 JOIN kb.contrat c USING(contrat_id) JOIN kb.politique_abonnement pa USING(politique_abonnement_id)
 WHERE ee.etablissement_id=salon AND NOT pa.gestion_rdv_existants_si_impaye AND e.exigible_le<=clock_timestamp()
 AND e.montant_du>COALESCE((SELECT sum(enc.montant) FROM kb.encaissement enc JOIN kb.tentative_paiement t USING(tentative_id) WHERE t.echeance_id=e.echeance_id),0))
 THEN RAISE EXCEPTION 'Gestion suspendue pour impaye' USING ERRCODE='23514'; END IF;
 INSERT INTO kb.decision_salon(rdv_id,auteur_compte_id,resultat,motif) VALUES(p_rdv,p_auteur,'refuse',nullif(trim(p_motif),''));
 UPDATE kb.rendez_vous SET etat='refuse' WHERE rdv_id=p_rdv;
 INSERT INTO kb.evenement_rdv(rdv_id,auteur_id,nature,motif) VALUES(p_rdv,p_auteur,'refuse',nullif(trim(p_motif),'')) RETURNING evenement_id INTO evenement;
 INSERT INTO kb.notification(evenement_id,destinataire_id,canal) VALUES(evenement,r.client_id,'in_app'),(evenement,r.client_id,'sms');
 RETURN 'refuse';
END $$;
CREATE OR REPLACE FUNCTION kb.refuser_rdv(p_rdv bigint,p_auteur bigint) RETURNS text LANGUAGE sql AS $$
 SELECT kb.refuser_rdv(p_rdv,p_auteur,NULL::text)
$$;

CREATE OR REPLACE FUNCTION kb.annuler_rdv(p_rdv bigint,p_auteur bigint,p_cle text) RETURNS text LANGUAGE plpgsql AS $$
DECLARE salon bigint; r kb.rendez_vous; pol kb.politique_rdv; evenement bigint; total bigint; debut timestamptz;
BEGIN
 IF current_setting('transaction_isolation')<>'read committed' THEN RAISE EXCEPTION 'READ COMMITTED requis' USING ERRCODE='25001'; END IF;
 IF p_cle IS NULL OR length(p_cle) NOT BETWEEN 1 AND 160 THEN RAISE EXCEPTION 'Cle requise' USING ERRCODE='23514'; END IF;
 SELECT p.etablissement_id INTO salon FROM kb.rendez_vous v JOIN kb.politique_rdv p USING(politique_id) WHERE v.rdv_id=p_rdv;
 IF salon IS NULL THEN RAISE EXCEPTION 'RDV introuvable' USING ERRCODE='P0002'; END IF;
 PERFORM 1 FROM kb.etablissement WHERE etablissement_id=salon FOR UPDATE;
 SELECT * INTO r FROM kb.rendez_vous WHERE rdv_id=p_rdv FOR UPDATE;
 SELECT * INTO pol FROM kb.politique_rdv WHERE politique_id=r.politique_id;
 IF r.client_id<>p_auteur OR NOT EXISTS(SELECT 1 FROM kb.compte WHERE compte_id=p_auteur AND etat='actif') THEN RAISE EXCEPTION 'Non habilite' USING ERRCODE='42501'; END IF;
 IF EXISTS(SELECT 1 FROM kb.modification_client WHERE cle_operation=p_cle AND rdv_id=p_rdv AND nature='annulation') THEN RETURN 'deja_annule'; END IF;
 IF r.etat NOT IN ('en_attente_salon','accepte') OR NOT pol.annulation_client THEN RAISE EXCEPTION 'Annulation interdite' USING ERRCODE='23514'; END IF;
 SELECT min(l.debut) INTO debut FROM kb.ligne_rdv l WHERE rdv_id=p_rdv;
 IF debut IS NULL OR debut<clock_timestamp()+make_interval(mins=>pol.delai_annulation_minutes) THEN RAISE EXCEPTION 'Delai annulation depasse' USING ERRCODE='23514'; END IF;
 SELECT count(*) INTO total FROM kb.modification_client m JOIN kb.rendez_vous v USING(rdv_id) JOIN kb.politique_rdv p USING(politique_id)
 WHERE v.client_id=p_auteur AND ((pol.portee_modification='rendez_vous' AND v.rdv_id=p_rdv) OR (pol.portee_modification='client_etablissement' AND p.etablissement_id=salon));
 IF total>=pol.limite_modifications THEN RAISE EXCEPTION 'Quota modifications atteint' USING ERRCODE='23514'; END IF;
 INSERT INTO kb.modification_client(rdv_id,nature,cle_operation) VALUES(p_rdv,'annulation',p_cle);
 UPDATE kb.rendez_vous SET etat='annule' WHERE rdv_id=p_rdv;
 INSERT INTO kb.evenement_rdv(rdv_id,auteur_id,nature) VALUES(p_rdv,p_auteur,'annule') RETURNING evenement_id INTO evenement;
 INSERT INTO kb.notification(evenement_id,destinataire_id,canal)
 SELECT evenement,d.compte_id,c.canal FROM (
 SELECT r.client_id AS compte_id UNION SELECT g.compte_id FROM kb.gerant g JOIN kb.permission_gestion pg USING(gerant_id) WHERE pg.etablissement_id=salon AND pg.permission_code='rdv_decider'
 ) d CROSS JOIN (VALUES('sms'),('in_app')) c(canal);
 RETURN 'annule';
END $$;
REVOKE ALL ON FUNCTION kb.refuser_rdv(bigint,bigint),kb.refuser_rdv(bigint,bigint,text),kb.annuler_rdv(bigint,bigint,text) FROM PUBLIC;
COMMIT;

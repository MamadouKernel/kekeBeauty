BEGIN;

CREATE TABLE IF NOT EXISTS kb.proposition_report (
  proposition_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  rdv_id bigint NOT NULL REFERENCES kb.rendez_vous,
  propose_par bigint NOT NULL REFERENCES kb.compte,
  debut_propose timestamptz NOT NULL,
  etat text NOT NULL DEFAULT 'en_attente' CHECK (etat IN ('en_attente','acceptee','refusee','remplacee')),
  cle_operation varchar(160) NOT NULL UNIQUE,
  cle_reponse varchar(160) UNIQUE,
  cree_le timestamptz NOT NULL DEFAULT now(),
  repondu_le timestamptz,
  CONSTRAINT proposition_report_reponse_ck CHECK ((etat='en_attente' AND repondu_le IS NULL) OR etat<>'en_attente')
);
CREATE UNIQUE INDEX IF NOT EXISTS proposition_report_active_uq ON kb.proposition_report(rdv_id) WHERE etat='en_attente';

CREATE OR REPLACE FUNCTION kb.proposer_report_rdv(p_rdv bigint,p_auteur bigint,p_debut timestamptz,p_cle text)
RETURNS text LANGUAGE plpgsql AS $$
DECLARE salon bigint; r kb.rendez_vous; debut_actuel timestamptz; evenement bigint;
BEGIN
 IF p_cle IS NULL OR length(p_cle) NOT BETWEEN 1 AND 160 OR p_debut IS NULL THEN RAISE EXCEPTION 'Demande invalide' USING ERRCODE='23514'; END IF;
 IF EXISTS(SELECT 1 FROM kb.proposition_report WHERE cle_operation=p_cle AND rdv_id=p_rdv) THEN RETURN 'deja_propose'; END IF;
 IF EXISTS(SELECT 1 FROM kb.proposition_report WHERE cle_operation=p_cle) THEN RAISE EXCEPTION 'Cle deja utilisee' USING ERRCODE='23505'; END IF;
 SELECT p.etablissement_id INTO salon FROM kb.rendez_vous v JOIN kb.politique_rdv p USING(politique_id) WHERE v.rdv_id=p_rdv;
 IF salon IS NULL THEN RAISE EXCEPTION 'RDV introuvable' USING ERRCODE='P0002'; END IF;
 PERFORM 1 FROM kb.etablissement WHERE etablissement_id=salon FOR UPDATE;
 SELECT * INTO r FROM kb.rendez_vous WHERE rdv_id=p_rdv FOR UPDATE;
 IF NOT EXISTS(SELECT 1 FROM kb.gerant g JOIN kb.permission_gestion pg USING(gerant_id) JOIN kb.compte c ON c.compte_id=g.compte_id
   WHERE pg.etablissement_id=salon AND c.compte_id=p_auteur AND c.etat='actif' AND pg.permission_code='rdv_decider')
 THEN RAISE EXCEPTION 'Non habilite' USING ERRCODE='42501'; END IF;
 IF r.etat NOT IN ('en_attente_salon','accepte') THEN RAISE EXCEPTION 'Etat incompatible' USING ERRCODE='23514'; END IF;
 SELECT min(debut) INTO debut_actuel FROM kb.ligne_rdv WHERE rdv_id=p_rdv;
 IF p_debut<=clock_timestamp() OR p_debut=debut_actuel THEN RAISE EXCEPTION 'Creneau invalide' USING ERRCODE='23514'; END IF;
 UPDATE kb.proposition_report SET etat='remplacee',repondu_le=now() WHERE rdv_id=p_rdv AND etat='en_attente';
 INSERT INTO kb.proposition_report(rdv_id,propose_par,debut_propose,cle_operation) VALUES(p_rdv,p_auteur,p_debut,p_cle);
 INSERT INTO kb.evenement_rdv(rdv_id,auteur_id,nature,motif) VALUES(p_rdv,p_auteur,'proposition_report',p_debut::text) RETURNING evenement_id INTO evenement;
 INSERT INTO kb.notification(evenement_id,destinataire_id,canal) VALUES(evenement,r.client_id,'in_app'),(evenement,r.client_id,'sms');
 RETURN 'propose';
END $$;

CREATE OR REPLACE FUNCTION kb.repondre_proposition_report(p_rdv bigint,p_client bigint,p_accepter boolean,p_cle text)
RETURNS text LANGUAGE plpgsql AS $$
DECLARE proposition kb.proposition_report; r kb.rendez_vous; resultat text; evenement bigint;
BEGIN
 SELECT * INTO r FROM kb.rendez_vous WHERE rdv_id=p_rdv FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'RDV introuvable' USING ERRCODE='P0002'; END IF;
 IF r.client_id<>p_client OR NOT EXISTS(SELECT 1 FROM kb.compte WHERE compte_id=p_client AND etat='actif') THEN RAISE EXCEPTION 'Non habilite' USING ERRCODE='42501'; END IF;
 SELECT * INTO proposition FROM kb.proposition_report WHERE rdv_id=p_rdv AND etat='en_attente' FOR UPDATE;
 IF NOT FOUND THEN
   IF EXISTS(SELECT 1 FROM kb.proposition_report WHERE rdv_id=p_rdv AND cle_reponse=p_cle AND etat IN ('acceptee','refusee')) THEN RETURN 'deja_repondu'; END IF;
   RAISE EXCEPTION 'Proposition introuvable' USING ERRCODE='P0002';
 END IF;
 IF NOT p_accepter THEN
   UPDATE kb.proposition_report SET etat='refusee',repondu_le=now(),cle_reponse=p_cle WHERE proposition_id=proposition.proposition_id;
   INSERT INTO kb.evenement_rdv(rdv_id,auteur_id,nature) VALUES(p_rdv,p_client,'refus_report') RETURNING evenement_id INTO evenement;
   INSERT INTO kb.notification(evenement_id,destinataire_id,canal)
     SELECT evenement,g.compte_id,c.canal FROM kb.gerant g JOIN kb.permission_gestion pg USING(gerant_id)
     CROSS JOIN (VALUES('sms'),('in_app')) c(canal) WHERE pg.etablissement_id=(SELECT etablissement_id FROM kb.politique_rdv WHERE politique_id=r.politique_id) AND pg.permission_code='rdv_decider';
   RETURN 'refusee';
 END IF;
 resultat:=kb.reporter_rdv(p_rdv,p_client,proposition.debut_propose,p_cle);
 UPDATE kb.proposition_report SET etat='acceptee',repondu_le=now(),cle_reponse=p_cle WHERE proposition_id=proposition.proposition_id;
 RETURN resultat;
END $$;

REVOKE ALL ON FUNCTION kb.proposer_report_rdv(bigint,bigint,timestamptz,text) FROM PUBLIC;
REVOKE ALL ON FUNCTION kb.repondre_proposition_report(bigint,bigint,boolean,text) FROM PUBLIC;
COMMIT;

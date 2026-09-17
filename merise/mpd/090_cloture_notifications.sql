BEGIN;
ALTER TABLE kb.notification ADD COLUMN IF NOT EXISTS derniere_erreur text;
ALTER TABLE kb.notification ADD COLUMN IF NOT EXISTS traite_le timestamptz;
ALTER TABLE kb.notification ADD COLUMN IF NOT EXISTS lu_le timestamptz;

CREATE OR REPLACE FUNCTION kb.cloturer_rdv(p_rdv bigint,p_auteur bigint,p_resultat text)
RETURNS text LANGUAGE plpgsql AS $$
DECLARE salon bigint; r kb.rendez_vous; evenement bigint; debut timestamptz;
BEGIN
 IF p_resultat NOT IN ('termine','absent') THEN RAISE EXCEPTION 'Resultat invalide' USING ERRCODE='23514'; END IF;
 SELECT p.etablissement_id INTO salon FROM kb.rendez_vous v JOIN kb.politique_rdv p USING(politique_id) WHERE v.rdv_id=p_rdv;
 IF salon IS NULL THEN RAISE EXCEPTION 'RDV introuvable' USING ERRCODE='P0002'; END IF;
 PERFORM 1 FROM kb.etablissement WHERE etablissement_id=salon FOR UPDATE;
 SELECT * INTO r FROM kb.rendez_vous WHERE rdv_id=p_rdv FOR UPDATE;
 IF NOT EXISTS(SELECT 1 FROM kb.gerant g JOIN kb.permission_gestion pg USING(gerant_id) JOIN kb.compte c ON c.compte_id=g.compte_id
   WHERE pg.etablissement_id=salon AND c.compte_id=p_auteur AND c.etat='actif' AND pg.permission_code='rdv_decider')
 THEN RAISE EXCEPTION 'Non habilite' USING ERRCODE='42501'; END IF;
 IF r.etat=p_resultat THEN RETURN 'deja_cloture'; END IF;
 IF r.etat<>'accepte' THEN RAISE EXCEPTION 'Etat incompatible' USING ERRCODE='23514'; END IF;
 SELECT min(l.debut) INTO debut FROM kb.ligne_rdv l WHERE l.rdv_id=p_rdv;
 IF debut>clock_timestamp() THEN RAISE EXCEPTION 'Rendez-vous futur' USING ERRCODE='23514'; END IF;
 UPDATE kb.rendez_vous SET etat=p_resultat WHERE rdv_id=p_rdv;
 INSERT INTO kb.evenement_rdv(rdv_id,auteur_id,nature) VALUES(p_rdv,p_auteur,p_resultat) RETURNING evenement_id INTO evenement;
 INSERT INTO kb.notification(evenement_id,destinataire_id,canal) VALUES(evenement,r.client_id,'in_app'),(evenement,r.client_id,'sms');
 RETURN p_resultat;
END $$;
REVOKE ALL ON FUNCTION kb.cloturer_rdv(bigint,bigint,text) FROM PUBLIC;
COMMIT;

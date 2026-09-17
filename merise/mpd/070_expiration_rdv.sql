BEGIN;
CREATE OR REPLACE FUNCTION kb.expirer_demandes_rdv(p_limite integer DEFAULT 100)
RETURNS integer LANGUAGE plpgsql AS $$
DECLARE item record; evenement bigint; total integer:=0;
BEGIN
  IF p_limite NOT BETWEEN 1 AND 1000 THEN
    RAISE EXCEPTION 'Limite invalide' USING ERRCODE='23514';
  END IF;
  FOR item IN
    SELECT rdv_id,client_id FROM kb.rendez_vous
    WHERE etat='en_attente_salon' AND expire_le IS NOT NULL AND expire_le<=clock_timestamp()
    ORDER BY expire_le,rdv_id FOR UPDATE SKIP LOCKED LIMIT p_limite
  LOOP
    UPDATE kb.rendez_vous SET etat='expire' WHERE rdv_id=item.rdv_id AND etat='en_attente_salon';
    IF FOUND THEN
      INSERT INTO kb.evenement_rdv(rdv_id,nature,motif)
      VALUES(item.rdv_id,'expire','Demande expirée automatiquement faute de décision dans le délai configuré.')
      RETURNING evenement_id INTO evenement;
      INSERT INTO kb.notification(evenement_id,destinataire_id,canal)
      VALUES(evenement,item.client_id,'in_app'),(evenement,item.client_id,'sms');
      total:=total+1;
    END IF;
  END LOOP;
  RETURN total;
END $$;
REVOKE ALL ON FUNCTION kb.expirer_demandes_rdv(integer) FROM PUBLIC;
COMMIT;

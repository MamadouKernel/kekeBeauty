-- Traitement serveur de l'acceptation. Appel sous READ COMMITTED.
-- Les autres mutations de planning doivent verrouiller le salon avant d'ecrire.
BEGIN;
CREATE OR REPLACE FUNCTION kb.accepter_rdv(p_rdv bigint, p_auteur bigint)
RETURNS text LANGUAGE plpgsql AS $$
DECLARE
    salon bigint; r kb.rendez_vous; pol kb.politique_rdv;
    instant timestamptz; ligne record; res record; evenement bigint; tz text;
    jour date; v_debut time; v_fin time; charge bigint;
BEGIN
    IF current_setting('transaction_isolation') <> 'read committed' THEN
        RAISE EXCEPTION 'READ COMMITTED requis' USING ERRCODE='25001';
    END IF;
    SELECT p.etablissement_id INTO salon FROM kb.rendez_vous v
    JOIN kb.politique_rdv p USING(politique_id) WHERE v.rdv_id=p_rdv;
    IF salon IS NULL THEN RAISE EXCEPTION 'RDV introuvable' USING ERRCODE='P0002'; END IF;
    -- Ordre commun a tous les futurs traitements : salon, RDV, ressources.
    SELECT fuseau INTO tz FROM kb.etablissement WHERE etablissement_id=salon FOR UPDATE;
    SELECT * INTO r FROM kb.rendez_vous WHERE rdv_id=p_rdv FOR UPDATE;
    SELECT * INTO pol FROM kb.politique_rdv WHERE politique_id=r.politique_id;
    instant := clock_timestamp();
    IF NOT EXISTS (
        SELECT 1 FROM kb.gerant g JOIN kb.permission_gestion pg USING(gerant_id)
        JOIN kb.compte c ON c.compte_id=g.compte_id
        WHERE pg.etablissement_id=salon AND g.compte_id=p_auteur
          AND c.etat='actif' AND pg.permission_code='rdv_decider'
    ) THEN RAISE EXCEPTION 'Non habilite' USING ERRCODE='42501'; END IF;
    -- Rejeu apres succes : aucun nouvel evenement ni nouvelle notification.
    IF r.etat='accepte' THEN RETURN 'deja_accepte'; END IF;
    IF r.etat <> 'en_attente_salon' THEN
        RAISE EXCEPTION 'Etat incompatible' USING ERRCODE='23514';
    END IF;
    IF pol.blocage_attente AND (r.expire_le IS NULL OR r.expire_le <= instant) THEN
        RAISE EXCEPTION 'Maintien expire ou absent' USING ERRCODE='23514';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM kb.etablissement WHERE etablissement_id=salon AND etat_publication='publie') THEN
        RAISE EXCEPTION 'Salon non publie' USING ERRCODE='23514';
    END IF;
    -- Au moins un contrat actif couvrant le salon, avec une echeance courante.
    IF NOT EXISTS (
      SELECT 1 FROM kb.contrat c JOIN kb.contrat_etablissement ce USING(contrat_id)
      JOIN kb.echeance e USING(contrat_id)
      JOIN kb.echeance_etablissement ee ON ee.echeance_id=e.echeance_id AND ee.etablissement_id=salon
      WHERE ce.etablissement_id=salon AND c.etat='actif'
        AND c.debut <= (instant AT TIME ZONE tz)::date
        AND c.fin_engagement > (instant AT TIME ZONE tz)::date
        AND ce.couvert_depuis <= (instant AT TIME ZONE tz)::date
        AND (ce.couvert_jusqua IS NULL OR ce.couvert_jusqua > (instant AT TIME ZONE tz)::date)
        AND e.debut_periode <= (instant AT TIME ZONE tz)::date AND e.fin_periode > (instant AT TIME ZONE tz)::date
    ) THEN RAISE EXCEPTION 'Abonnement actif requis' USING ERRCODE='23514'; END IF;
    IF EXISTS (
      SELECT 1 FROM kb.echeance e JOIN kb.echeance_etablissement ee USING(echeance_id)
      WHERE ee.etablissement_id=salon AND e.exigible_le <= instant
      AND e.montant_du > COALESCE((SELECT sum(enc.montant) FROM kb.encaissement enc
          JOIN kb.tentative_paiement t USING(tentative_id) WHERE t.echeance_id=e.echeance_id),0)
    ) THEN RAISE EXCEPTION 'Abonnement impaye sans grace' USING ERRCODE='23514'; END IF;
    IF NOT EXISTS (SELECT 1 FROM kb.ligne_rdv WHERE rdv_id=p_rdv) THEN
        RAISE EXCEPTION 'Prestation requise' USING ERRCODE='23514'; END IF;
    IF NOT pol.multi_prestations AND (SELECT count(*) FROM kb.ligne_rdv WHERE rdv_id=p_rdv)>1 THEN
        RAISE EXCEPTION 'Plusieurs prestations interdites' USING ERRCODE='23514'; END IF;
    IF EXISTS (SELECT 1 FROM (
      SELECT debut,lag(fin) OVER(ORDER BY numero) AS precedente FROM kb.ligne_rdv WHERE rdv_id=p_rdv
    ) x WHERE precedente>debut) THEN
        RAISE EXCEPTION 'Prestations non successives' USING ERRCODE='23514'; END IF;
    PERFORM 1 FROM kb.ressource WHERE etablissement_id=salon ORDER BY ressource_id FOR UPDATE;
    FOR ligne IN SELECT l.*,v.variante_id,v.duree_minutes,va.actif,p.etat AS etat_prestation
      FROM kb.ligne_rdv l JOIN kb.version_variante v USING(version_variante_id)
      JOIN kb.variante va USING(variante_id) JOIN kb.prestation p USING(prestation_id)
      WHERE l.rdv_id=p_rdv ORDER BY l.numero
    LOOP
      IF ligne.debut<=instant OR NOT ligne.actif OR ligne.etat_prestation<>'actif'
         OR ligne.fin-ligne.debut <> make_interval(mins=>ligne.duree_minutes) THEN
        RAISE EXCEPTION 'Prestation, debut ou duree invalide' USING ERRCODE='23514'; END IF;
      jour := (ligne.debut AT TIME ZONE tz)::date;
      v_debut := (ligne.debut AT TIME ZONE tz)::time;
      v_fin := (ligne.fin AT TIME ZONE tz)::time;
      IF jour<>(ligne.fin AT TIME ZONE tz)::date THEN
        RAISE EXCEPTION 'Soin traversant minuit non pris en charge' USING ERRCODE='23514'; END IF;
      IF EXISTS (SELECT 1 FROM kb.exception_ouverture WHERE etablissement_id=salon AND date_concernee=jour) THEN
        IF EXISTS (SELECT 1 FROM kb.exception_ouverture WHERE etablissement_id=salon AND date_concernee=jour AND ferme)
          OR NOT EXISTS (SELECT 1 FROM kb.exception_ouverture WHERE etablissement_id=salon AND date_concernee=jour
              AND NOT ferme AND v_debut>=exception_ouverture.heure_debut AND v_fin<=exception_ouverture.heure_fin) THEN
          RAISE EXCEPTION 'Exception ouverture incompatible' USING ERRCODE='23514'; END IF;
      ELSIF NOT EXISTS (SELECT 1 FROM kb.plage_ouverture po WHERE po.etablissement_id=salon
            AND po.jour_semaine=extract(isodow FROM jour) AND po.heure_debut<=v_debut AND po.heure_fin>=v_fin) THEN
        RAISE EXCEPTION 'Salon ferme sur ce creneau' USING ERRCODE='23514';
      END IF;
      IF NOT EXISTS (SELECT 1 FROM kb.besoin_variante WHERE variante_id=ligne.variante_id) THEN
        RAISE EXCEPTION 'Besoins de ressources absents' USING ERRCODE='23514'; END IF;
      -- Une ressource ne satisfait pas deux besoins simultanes de la meme variante.
      -- Les groupes qui se recouvrent sont refuses plutot que sous-compter la charge.
      IF EXISTS (SELECT mg.ressource_id FROM kb.besoin_variante b JOIN kb.membre_groupe mg USING(groupe_id)
          WHERE b.variante_id=ligne.variante_id GROUP BY mg.ressource_id HAVING count(*)>1) THEN
        RAISE EXCEPTION 'Groupes de besoins ambigus' USING ERRCODE='23514'; END IF;
      IF EXISTS (SELECT 1 FROM kb.besoin_variante b WHERE b.variante_id=ligne.variante_id
          AND NOT EXISTS (SELECT 1 FROM kb.allocation_rdv a JOIN kb.membre_groupe mg USING(ressource_id)
            WHERE a.rdv_id=p_rdv AND a.numero=ligne.numero AND mg.groupe_id=b.groupe_id AND a.quantite=b.quantite))
        OR (SELECT count(*) FROM kb.allocation_rdv WHERE rdv_id=p_rdv AND numero=ligne.numero)
          <> (SELECT count(*) FROM kb.besoin_variante WHERE variante_id=ligne.variante_id) THEN
        RAISE EXCEPTION 'Allocations incompletes ou superflues' USING ERRCODE='23514'; END IF;
      IF EXISTS (SELECT 1 FROM kb.allocation_rdv a JOIN kb.ressource s USING(ressource_id)
        WHERE a.rdv_id=p_rdv AND a.numero=ligne.numero AND
        (NOT s.actif OR (pol.mode_capacite='globale' AND s.nature<>'globale')
         OR (pol.mode_capacite='employes' AND s.nature<>'employe')
         OR (pol.mode_capacite='ressources' AND s.nature<>'physique'))) THEN
        RAISE EXCEPTION 'Mode capacite incompatible' USING ERRCODE='23514'; END IF;
      FOR res IN SELECT a.*,s.capacite FROM kb.allocation_rdv a JOIN kb.ressource s USING(ressource_id)
        WHERE a.rdv_id=p_rdv AND a.numero=ligne.numero
      LOOP
        IF NOT EXISTS (SELECT 1 FROM kb.plage_ressource pr WHERE pr.ressource_id=res.ressource_id
          AND pr.jour_semaine=extract(isodow FROM jour) AND pr.debut<=v_debut AND pr.fin>=v_fin)
          OR EXISTS (SELECT 1 FROM kb.indisponibilite_ressource i WHERE i.ressource_id=res.ressource_id
              AND i.debut<ligne.fin AND i.fin>ligne.debut) THEN
          RAISE EXCEPTION 'Ressource indisponible' USING ERRCODE='23514'; END IF;
        WITH occupations AS (
          SELECT l.debut,l.fin,a.quantite FROM kb.allocation_rdv a JOIN kb.ligne_rdv l USING(rdv_id,numero)
          JOIN kb.rendez_vous rv USING(rdv_id) JOIN kb.politique_rdv pp USING(politique_id)
          WHERE a.ressource_id=res.ressource_id AND rv.rdv_id<>p_rdv
            AND l.debut<ligne.fin AND l.fin>ligne.debut
            AND (rv.etat='accepte' OR (rv.etat='en_attente_salon' AND pp.blocage_attente AND rv.expire_le>instant))
        ), points AS (SELECT ligne.debut AS t UNION SELECT debut FROM occupations WHERE debut>=ligne.debut)
        SELECT COALESCE(max((SELECT COALESCE(sum(o.quantite),0) FROM occupations o WHERE o.debut<=t AND o.fin>t)),0)
          INTO charge FROM points;
        IF charge+res.quantite>res.capacite THEN
          RAISE EXCEPTION 'Capacite insuffisante' USING ERRCODE='23P01'; END IF;
      END LOOP;
    END LOOP;
    INSERT INTO kb.decision_salon(rdv_id,auteur_compte_id,resultat) VALUES (p_rdv,p_auteur,'accepte');
    UPDATE kb.rendez_vous SET etat='accepte' WHERE rdv_id=p_rdv;
    INSERT INTO kb.evenement_rdv(rdv_id,auteur_id,nature) VALUES(p_rdv,p_auteur,'accepte') RETURNING evenement_id INTO evenement;
    INSERT INTO kb.notification(evenement_id,destinataire_id,canal) VALUES(evenement,r.client_id,'in_app'),(evenement,r.client_id,'sms');
    RETURN 'accepte';
END $$;
REVOKE ALL ON FUNCTION kb.accepter_rdv(bigint,bigint) FROM PUBLIC;
COMMIT;

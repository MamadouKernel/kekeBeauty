BEGIN;
CREATE OR REPLACE FUNCTION kb.reporter_rdv(p_rdv bigint,p_auteur bigint,p_debut timestamptz,p_cle text)
RETURNS text LANGUAGE plpgsql AS $$
DECLARE
 salon bigint; r kb.rendez_vous; pol kb.politique_rdv; tz text; instant timestamptz;
 ancien_debut timestamptz; total bigint; versions bigint[]; numero integer:=0;
 version_id bigint; variante bigint; duree integer; fin_soin timestamptz;
 besoin record; candidat record; choisi bigint; evenement bigint;
BEGIN
 IF current_setting('transaction_isolation')<>'read committed' THEN RAISE EXCEPTION 'READ COMMITTED requis' USING ERRCODE='25001'; END IF;
 IF p_cle IS NULL OR length(p_cle) NOT BETWEEN 1 AND 160 OR p_debut IS NULL THEN RAISE EXCEPTION 'Demande invalide' USING ERRCODE='23514'; END IF;
 IF EXISTS(SELECT 1 FROM kb.modification_client WHERE cle_operation=p_cle AND rdv_id=p_rdv AND nature='report') THEN RETURN 'deja_reporte'; END IF;
 IF EXISTS(SELECT 1 FROM kb.modification_client WHERE cle_operation=p_cle) THEN RAISE EXCEPTION 'Cle deja utilisee' USING ERRCODE='23505'; END IF;

 SELECT p.etablissement_id INTO salon FROM kb.rendez_vous v JOIN kb.politique_rdv p USING(politique_id) WHERE v.rdv_id=p_rdv;
 IF salon IS NULL THEN RAISE EXCEPTION 'RDV introuvable' USING ERRCODE='P0002'; END IF;
 SELECT fuseau INTO tz FROM kb.etablissement WHERE etablissement_id=salon FOR UPDATE;
 SELECT * INTO r FROM kb.rendez_vous WHERE rdv_id=p_rdv FOR UPDATE;
 SELECT * INTO pol FROM kb.politique_rdv WHERE politique_id=r.politique_id;
 instant:=clock_timestamp();
 IF r.client_id<>p_auteur OR NOT EXISTS(SELECT 1 FROM kb.compte WHERE compte_id=p_auteur AND etat='actif') THEN RAISE EXCEPTION 'Non habilite' USING ERRCODE='42501'; END IF;
 IF r.etat NOT IN ('en_attente_salon','accepte') OR NOT pol.report_client THEN RAISE EXCEPTION 'Report interdit' USING ERRCODE='23514'; END IF;
 SELECT min(l.debut),array_agg(l.version_variante_id ORDER BY l.numero) INTO ancien_debut,versions FROM kb.ligne_rdv l WHERE l.rdv_id=p_rdv;
 IF ancien_debut IS NULL OR ancien_debut<instant+make_interval(mins=>pol.delai_report_minutes) THEN RAISE EXCEPTION 'Delai report depasse' USING ERRCODE='23514'; END IF;
 SELECT count(*) INTO total FROM kb.modification_client m JOIN kb.rendez_vous v USING(rdv_id) JOIN kb.politique_rdv p USING(politique_id)
 WHERE v.client_id=p_auteur AND ((pol.portee_modification='rendez_vous' AND v.rdv_id=p_rdv) OR (pol.portee_modification='client_etablissement' AND p.etablissement_id=salon));
 IF total>=pol.limite_modifications THEN RAISE EXCEPTION 'Quota modifications atteint' USING ERRCODE='23514'; END IF;

 PERFORM 1 FROM kb.ressource WHERE etablissement_id=salon ORDER BY ressource_id FOR UPDATE;
 DELETE FROM kb.allocation_rdv WHERE rdv_id=p_rdv;
 DELETE FROM kb.ligne_rdv WHERE rdv_id=p_rdv;
 FOREACH version_id IN ARRAY versions LOOP
   numero:=numero+1;
   SELECT vv.duree_minutes,vv.variante_id INTO duree,variante FROM kb.version_variante vv
     JOIN kb.variante va USING(variante_id) JOIN kb.prestation pr USING(prestation_id)
     WHERE vv.version_variante_id=version_id AND pr.etablissement_id=salon AND va.actif AND pr.etat='actif';
   IF NOT FOUND THEN RAISE EXCEPTION 'Prestation invalide' USING ERRCODE='23514'; END IF;
   fin_soin:=p_debut+make_interval(mins=>duree);
   INSERT INTO kb.ligne_rdv VALUES(p_rdv,numero,version_id,p_debut,fin_soin);
   FOR besoin IN SELECT * FROM kb.besoin_variante WHERE variante_id=variante ORDER BY groupe_id LOOP
     choisi:=NULL;
     FOR candidat IN SELECT s.* FROM kb.ressource s JOIN kb.membre_groupe mg USING(ressource_id)
       WHERE mg.groupe_id=besoin.groupe_id AND s.actif AND s.capacite>=besoin.quantite
         AND (pol.mode_capacite='combinee' OR (pol.mode_capacite='globale' AND s.nature='globale')
           OR (pol.mode_capacite='employes' AND s.nature='employe') OR (pol.mode_capacite='ressources' AND s.nature='physique'))
       ORDER BY s.ressource_id LOOP
       IF EXISTS(SELECT 1 FROM kb.indisponibilite_ressource i WHERE i.ressource_id=candidat.ressource_id AND i.debut<fin_soin AND i.fin>p_debut)
         OR NOT EXISTS(SELECT 1 FROM kb.plage_ressource pr WHERE pr.ressource_id=candidat.ressource_id
           AND pr.jour_semaine=extract(isodow FROM p_debut AT TIME ZONE tz)
           AND pr.debut<=(p_debut AT TIME ZONE tz)::time AND pr.fin>=(fin_soin AT TIME ZONE tz)::time)
       THEN CONTINUE; END IF;
       IF (WITH occupations AS (
         SELECT l.debut,l.fin,a.quantite FROM kb.allocation_rdv a JOIN kb.ligne_rdv l USING(rdv_id,numero)
         JOIN kb.rendez_vous v USING(rdv_id) JOIN kb.politique_rdv p USING(politique_id)
         WHERE a.ressource_id=candidat.ressource_id AND v.rdv_id<>p_rdv AND l.debut<fin_soin AND l.fin>p_debut
           AND (v.etat='accepte' OR (v.etat='en_attente_salon' AND p.blocage_attente AND v.expire_le>instant))
       ), points AS (SELECT p_debut AS t UNION SELECT debut FROM occupations WHERE debut>=p_debut)
       SELECT COALESCE(max((SELECT COALESCE(sum(o.quantite),0) FROM occupations o WHERE o.debut<=t AND o.fin>t)),0) FROM points)
       +besoin.quantite<=candidat.capacite THEN choisi:=candidat.ressource_id; EXIT; END IF;
     END LOOP;
     IF choisi IS NULL THEN RAISE EXCEPTION 'Aucune ressource disponible' USING ERRCODE='23P01'; END IF;
     INSERT INTO kb.allocation_rdv VALUES(p_rdv,numero,choisi,besoin.quantite);
   END LOOP;
   p_debut:=fin_soin;
 END LOOP;
 PERFORM kb.verifier_creneau_rdv(p_rdv);
 INSERT INTO kb.modification_client(rdv_id,nature,cle_operation) VALUES(p_rdv,'report',p_cle);
 INSERT INTO kb.evenement_rdv(rdv_id,auteur_id,nature,motif) VALUES(p_rdv,p_auteur,'report','Ancien debut: '||ancien_debut::text) RETURNING evenement_id INTO evenement;
 INSERT INTO kb.notification(evenement_id,destinataire_id,canal)
 SELECT evenement,d.compte_id,c.canal FROM (
   SELECT r.client_id AS compte_id UNION SELECT g.compte_id FROM kb.gerant g JOIN kb.permission_gestion pg USING(gerant_id)
   WHERE pg.etablissement_id=salon AND pg.permission_code='rdv_decider'
 ) d CROSS JOIN (VALUES('sms'),('in_app')) c(canal);
 RETURN 'reporte';
END $$;
REVOKE ALL ON FUNCTION kb.reporter_rdv(bigint,bigint,timestamptz,text) FROM PUBLIC;
COMMIT;

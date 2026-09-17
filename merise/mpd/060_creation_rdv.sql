BEGIN;
-- Allocation automatique déterministe. Les besoins d'une variante doivent être
-- disjoints ; le validateur partagé refuse les configurations ambiguës.
CREATE OR REPLACE FUNCTION kb.creer_rdv(p_client bigint,p_salon bigint,p_versions bigint[],p_debut timestamptz,p_cle text)
RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE pol kb.politique_rdv; rdv bigint; empreinte text; ancien record;
 version_id bigint; duree integer; variante bigint; numero integer:=0;
 besoin record; candidat record; choisi bigint; fin_soin timestamptz; instant timestamptz; tz text;
BEGIN
 IF current_setting('transaction_isolation')<>'read committed' THEN RAISE EXCEPTION 'READ COMMITTED requis' USING ERRCODE='25001'; END IF;
 IF p_cle IS NULL OR length(p_cle) NOT BETWEEN 1 AND 160 OR cardinality(p_versions) NOT BETWEEN 1 AND 10 OR p_versions IS NULL OR p_debut IS NULL THEN
   RAISE EXCEPTION 'Demande invalide' USING ERRCODE='23514'; END IF;
 IF NOT EXISTS(SELECT 1 FROM kb.compte WHERE compte_id=p_client AND etat='actif' AND telephone_verifie_le IS NOT NULL) THEN
   RAISE EXCEPTION 'Connexion verifiee requise' USING ERRCODE='42501'; END IF;
 -- Empreinte textuelle canonique : le rejeu doit conserver tous les paramètres.
 empreinte:=encode(sha256(convert_to(p_salon::text||'/'||p_versions::text||'/'||extract(epoch FROM p_debut)::text,'UTF8')),'hex');
 PERFORM pg_advisory_xact_lock(hashtextextended(p_client::text||'/'||p_cle,1));
 SELECT * INTO ancien FROM kb.demande_idempotente WHERE compte_id=p_client AND cle=p_cle;
 IF FOUND THEN
   IF ancien.empreinte<>empreinte THEN RAISE EXCEPTION 'Cle reutilisee avec une autre demande' USING ERRCODE='23514'; END IF;
   RETURN ancien.rdv_id;
 END IF;
 SELECT fuseau INTO tz FROM kb.etablissement WHERE etablissement_id=p_salon FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Salon introuvable' USING ERRCODE='P0002'; END IF;
 instant:=clock_timestamp();
 SELECT * INTO pol FROM kb.politique_rdv WHERE etablissement_id=p_salon AND date_effet<=instant ORDER BY date_effet DESC LIMIT 1;
 IF NOT FOUND THEN RAISE EXCEPTION 'Politique non configuree' USING ERRCODE='23514'; END IF;
 INSERT INTO kb.rendez_vous(client_id,politique_id,expire_le)
 VALUES(p_client,pol.politique_id,CASE WHEN pol.blocage_attente THEN instant+make_interval(mins=>pol.maintien_minutes) END)
 RETURNING rdv_id INTO rdv;
 FOREACH version_id IN ARRAY p_versions LOOP
   numero:=numero+1;
   SELECT v.duree_minutes,v.variante_id INTO duree,variante FROM kb.version_variante v
     JOIN kb.variante va USING(variante_id) JOIN kb.prestation pr USING(prestation_id)
     WHERE v.version_variante_id=version_id AND pr.etablissement_id=p_salon AND v.date_effet<=instant
       AND NOT EXISTS(SELECT 1 FROM kb.version_variante newer WHERE newer.variante_id=v.variante_id AND newer.date_effet>v.date_effet AND newer.date_effet<=instant);
   IF NOT FOUND THEN RAISE EXCEPTION 'Tarif obsolete ou prestation invalide' USING ERRCODE='23514'; END IF;
   fin_soin:=p_debut+make_interval(mins=>duree);
   INSERT INTO kb.ligne_rdv VALUES(rdv,numero,version_id,p_debut,fin_soin);
   FOR besoin IN SELECT * FROM kb.besoin_variante WHERE variante_id=variante ORDER BY groupe_id LOOP
     choisi:=NULL;
     FOR candidat IN SELECT s.* FROM kb.ressource s JOIN kb.membre_groupe mg USING(ressource_id)
       WHERE mg.groupe_id=besoin.groupe_id AND s.actif AND s.capacite>=besoin.quantite
         AND (pol.mode_capacite='combinee'
           OR (pol.mode_capacite='globale' AND s.nature='globale')
           OR (pol.mode_capacite='employes' AND s.nature='employe')
           OR (pol.mode_capacite='ressources' AND s.nature='physique'))
       ORDER BY s.ressource_id LOOP
       IF EXISTS(SELECT 1 FROM kb.indisponibilite_ressource i WHERE i.ressource_id=candidat.ressource_id AND i.debut<fin_soin AND i.fin>p_debut)
         OR NOT EXISTS(SELECT 1 FROM kb.plage_ressource pr WHERE pr.ressource_id=candidat.ressource_id
           AND pr.jour_semaine=extract(isodow FROM p_debut AT TIME ZONE tz)
           AND pr.debut<=(p_debut AT TIME ZONE tz)::time AND pr.fin>=(fin_soin AT TIME ZONE tz)::time)
       THEN CONTINUE; END IF;
       IF (WITH occupations AS (
         SELECT l.debut,l.fin,a.quantite FROM kb.allocation_rdv a JOIN kb.ligne_rdv l USING(rdv_id,numero)
         JOIN kb.rendez_vous v USING(rdv_id) JOIN kb.politique_rdv p USING(politique_id)
         WHERE a.ressource_id=candidat.ressource_id AND v.rdv_id<>rdv AND l.debut<fin_soin AND l.fin>p_debut
           AND (v.etat='accepte' OR (v.etat='en_attente_salon' AND p.blocage_attente AND v.expire_le>instant))
         ), points AS (SELECT p_debut AS t UNION SELECT debut FROM occupations WHERE debut>=p_debut)
         SELECT COALESCE(max((SELECT COALESCE(sum(o.quantite),0) FROM occupations o WHERE o.debut<=t AND o.fin>t)),0) FROM points)
         +besoin.quantite<=candidat.capacite THEN choisi:=candidat.ressource_id; EXIT; END IF;
     END LOOP;
     IF choisi IS NULL THEN RAISE EXCEPTION 'Aucune ressource disponible' USING ERRCODE='23P01'; END IF;
     INSERT INTO kb.allocation_rdv VALUES(rdv,numero,choisi,besoin.quantite);
   END LOOP;
   p_debut:=fin_soin;
 END LOOP;
 PERFORM kb.verifier_creneau_rdv(rdv);
 INSERT INTO kb.demande_idempotente(compte_id,cle,empreinte,rdv_id) VALUES(p_client,p_cle,empreinte,rdv);
 INSERT INTO kb.evenement_rdv(rdv_id,auteur_id,nature) VALUES(rdv,p_client,'demande');
 RETURN rdv;
END $$;
REVOKE ALL ON FUNCTION kb.creer_rdv(bigint,bigint,bigint[],timestamptz,text) FROM PUBLIC;
COMMIT;

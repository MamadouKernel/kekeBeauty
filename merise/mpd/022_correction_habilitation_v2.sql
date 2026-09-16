-- Correction de la jointure de controle d'habilitation, appliquee lors de la recette V2.
-- Le schema initial 020 contient deja cette correction pour les nouvelles installations.
BEGIN;
CREATE OR REPLACE FUNCTION kb.verifier_auteur_decision() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM kb.rendez_vous r JOIN kb.politique_rdv p USING(politique_id)
    JOIN kb.gerant_etablissement ge ON ge.etablissement_id=p.etablissement_id
    JOIN kb.gerant g USING(gerant_id)
    JOIN kb.permission_gestion pg ON pg.gerant_id=g.gerant_id AND pg.etablissement_id=p.etablissement_id
    WHERE r.rdv_id=NEW.rdv_id AND g.compte_id=NEW.auteur_compte_id AND pg.permission_code='rdv_decider'
  ) THEN
    RAISE EXCEPTION 'Gestionnaire habilite requis' USING ERRCODE='23514';
  END IF;
  RETURN NEW;
END $$;
COMMIT;

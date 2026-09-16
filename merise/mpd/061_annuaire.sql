BEGIN;
CREATE OR REPLACE VIEW kb.annuaire AS
SELECT e.* FROM kb.etablissement e WHERE e.etat_publication='publie'
AND EXISTS(SELECT 1 FROM kb.contrat c JOIN kb.contrat_etablissement ce USING(contrat_id)
 JOIN kb.politique_abonnement pa USING(politique_abonnement_id)
 WHERE ce.etablissement_id=e.etablissement_id AND c.etat='actif'
 AND ce.couvert_depuis<=(now() AT TIME ZONE e.fuseau)::date AND (ce.couvert_jusqua IS NULL OR ce.couvert_jusqua>(now() AT TIME ZONE e.fuseau)::date)
 AND (pa.fiche_visible_si_impaye OR (
 c.debut<=(now() AT TIME ZONE e.fuseau)::date AND c.fin_engagement>(now() AT TIME ZONE e.fuseau)::date
 AND EXISTS(SELECT 1 FROM kb.echeance ec JOIN kb.echeance_etablissement ee USING(echeance_id)
 WHERE ec.contrat_id=c.contrat_id AND ee.etablissement_id=e.etablissement_id
 AND ec.debut_periode<=(now() AT TIME ZONE e.fuseau)::date AND ec.fin_periode>(now() AT TIME ZONE e.fuseau)::date)
 AND NOT EXISTS(SELECT 1 FROM kb.echeance ec JOIN kb.echeance_etablissement ee USING(echeance_id)
 WHERE ee.etablissement_id=e.etablissement_id AND ec.exigible_le<=now()
 AND ec.montant_du>coalesce((SELECT sum(enc.montant) FROM kb.encaissement enc JOIN kb.tentative_paiement t USING(tentative_id) WHERE t.echeance_id=ec.echeance_id),0))
 )));
COMMIT;

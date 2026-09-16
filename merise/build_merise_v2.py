"""Build a fresh V2 schema from the frozen V1 baseline; never connects to a database."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent
sql = (ROOT / 'mpd/010_modele_v1.sql').read_text(encoding='utf-8')
sql = sql.replace('-- Candidat V1, base PostgreSQL vide uniquement. Non deploye.',
                  '-- Keke Beauty V2: schema initial, base vide uniquement. Ne pas rejouer sur un schema existant.')

def replace_table(name, body):
    global sql
    pattern = rf'CREATE TABLE kb\.{name} \(.*?\n\);'
    sql, n = re.subn(pattern, f'CREATE TABLE kb.{name} (\n{body.strip()}\n);', sql, count=1, flags=re.S)
    assert n == 1, name

def remove_table(name):
    global sql
    sql, n = re.subn(rf'CREATE TABLE kb\.{name} \(.*?\n\);\n', '', sql, count=1, flags=re.S)
    assert n == 1, name

replace_table('politique_rdv', '''
    politique_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    etablissement_id bigint NOT NULL REFERENCES kb.etablissement(etablissement_id),
    version integer NOT NULL CHECK (version > 0),
    date_effet timestamptz NOT NULL,
    mode_capacite varchar(20) NOT NULL CHECK (mode_capacite IN ('globale','employes','ressources','combinee')),
    blocage_attente boolean NOT NULL,
    maintien_minutes integer,
    portee_modification varchar(30) NOT NULL CHECK (portee_modification IN ('rendez_vous','client_etablissement')),
    limite_modifications integer NOT NULL DEFAULT 1 CHECK (limite_modifications > 0),
    multi_prestations boolean NOT NULL DEFAULT true,
    annulation_client boolean NOT NULL DEFAULT true,
    report_client boolean NOT NULL DEFAULT true,
    delai_annulation_minutes integer NOT NULL DEFAULT 60 CHECK (delai_annulation_minutes >= 0),
    delai_report_minutes integer NOT NULL DEFAULT 60 CHECK (delai_report_minutes >= 0),
    UNIQUE (etablissement_id, version),
    UNIQUE (etablissement_id, date_effet),
    CHECK ((blocage_attente AND maintien_minutes IS NOT NULL AND maintien_minutes > 0)
        OR (NOT blocage_attente AND maintien_minutes IS NULL))
''')
replace_table('rendez_vous', '''
    rdv_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id bigint NOT NULL REFERENCES kb.compte(compte_id),
    politique_id bigint NOT NULL REFERENCES kb.politique_rdv(politique_id),
    etat varchar(30) NOT NULL DEFAULT 'en_attente_salon' CHECK (etat IN ('en_attente_salon','accepte','refuse','expire','annule','termine','absent')),
    cree_le timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expire_le timestamptz,
    CHECK (expire_le IS NULL OR expire_le > cree_le)
''')
replace_table('politique_abonnement', '''
    politique_abonnement_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fiche_visible_si_impaye boolean NOT NULL,
    gestion_rdv_existants_si_impaye boolean NOT NULL,
    cree_le timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
''')
replace_table('contrat', '''
    contrat_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    payeur_compte_id bigint NOT NULL REFERENCES kb.compte(compte_id),
    tarif_offre_id bigint NOT NULL REFERENCES kb.tarif_offre(tarif_offre_id),
    politique_abonnement_id bigint NOT NULL REFERENCES kb.politique_abonnement(politique_abonnement_id),
    debut date NOT NULL,
    fin_engagement date NOT NULL,
    etat varchar(20) NOT NULL CHECK (etat IN ('brouillon','actif','clos')),
    CHECK (fin_engagement >= (debut + interval '1 year')::date)
''')
sql = sql.replace("    periodicite varchar(20) NOT NULL CHECK (periodicite IN ('mensuelle','annuelle')),",
    "    periodicite varchar(20) NOT NULL CHECK (periodicite IN ('mensuelle','annuelle')),\n    mode_facturation varchar(25) NOT NULL CHECK (mode_facturation IN ('forfait','par_etablissement')),")
sql = sql.replace('UNIQUE (offre_id, periodicite, devise, date_effet)',
                  'UNIQUE (offre_id, periodicite, mode_facturation, devise, date_effet)')
remove_table('cible_reglement')
sql = sql.replace('    cible_id bigint NOT NULL REFERENCES kb.cible_reglement(cible_id),',
                  '    echeance_id bigint NOT NULL REFERENCES kb.echeance(echeance_id),')
replace_table('encaissement', '''
    encaissement_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tentative_id bigint NOT NULL UNIQUE REFERENCES kb.tentative_paiement(tentative_id),
    montant numeric(14,4) NOT NULL CHECK (montant > 0),
    encaisse_le timestamptz NOT NULL
''')
for name in ('encaissement_mobile', 'encaissement_especes', 'remboursement'):
    remove_table(name)
sql = sql.replace("WHERE etat = 'attente_paiement'", "WHERE etat = 'en_attente_salon'")
sql = sql.replace('-- Contraintes interrelations et immutabilité : voir CONCEPTION_MERISE_V1.md.',
                  '-- Contraintes interrelations restantes : voir CONCEPTION_MERISE_V2.md.')
sql = re.sub(r'-- Un encaissement exige.*\n', '', sql)
extra = '''
CREATE TABLE kb.contrat_etablissement (
    contrat_id bigint NOT NULL REFERENCES kb.contrat(contrat_id),
    etablissement_id bigint NOT NULL REFERENCES kb.etablissement(etablissement_id),
    couvert_depuis date NOT NULL,
    couvert_jusqua date,
    PRIMARY KEY (contrat_id, etablissement_id, couvert_depuis),
    CHECK (couvert_jusqua IS NULL OR couvert_depuis < couvert_jusqua)
);
-- Périmètre facturé figé par échéance, distinct de la couverture courante du contrat.
CREATE TABLE kb.echeance_etablissement (
    echeance_id bigint NOT NULL REFERENCES kb.echeance(echeance_id),
    etablissement_id bigint NOT NULL REFERENCES kb.etablissement(etablissement_id),
    PRIMARY KEY (echeance_id, etablissement_id)
);
CREATE TABLE kb.decision_salon (
    decision_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rdv_id bigint NOT NULL REFERENCES kb.rendez_vous(rdv_id),
    auteur_compte_id bigint NOT NULL REFERENCES kb.compte(compte_id),
    resultat varchar(20) NOT NULL CHECK (resultat IN ('accepte','refuse')),
    motif text,
    decide_le timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (rdv_id)
);
CREATE TABLE kb.modification_client (
    modification_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rdv_id bigint NOT NULL REFERENCES kb.rendez_vous(rdv_id),
    nature varchar(20) NOT NULL CHECK (nature IN ('annulation','report')),
    effectue_le timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cle_operation varchar(160) NOT NULL UNIQUE
);
CREATE TABLE kb.version_schema (
    version integer PRIMARY KEY,
    applique_le timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO kb.version_schema(version) VALUES (2);
-- Chaque FK reçoit un index si aucun index valide ne possède ce préfixe de colonnes.
DO $$
DECLARE fk record;
BEGIN
  FOR fk IN
    SELECT c.oid, c.conrelid, c.conkey,
           string_agg(quote_ident(a.attname), ', ' ORDER BY u.ord) AS colonnes
    FROM pg_constraint c
    CROSS JOIN LATERAL unnest(c.conkey) WITH ORDINALITY u(attnum,ord)
    JOIN pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=u.attnum
    WHERE c.contype='f' AND c.connamespace='kb'::regnamespace
      AND NOT EXISTS (
        SELECT 1 FROM pg_index i WHERE i.indrelid=c.conrelid AND i.indisvalid
        AND i.indpred IS NULL AND i.indexprs IS NULL
        AND ARRAY(SELECT x FROM unnest(i.indkey) WITH ORDINALITY ix(x,pos)
                  WHERE pos <= cardinality(c.conkey) ORDER BY pos) = c.conkey
      )
    GROUP BY c.oid,c.conrelid,c.conkey
  LOOP
    EXECUTE format('CREATE INDEX %I ON %s (%s)', 'fk_' || fk.oid || '_ix', fk.conrelid::regclass, fk.colonnes);
  END LOOP;
END $$;
'''
# Membership and allocations must point to the same establishment (no duplicated salon FK).
guards = '''
CREATE FUNCTION kb.verifier_appartenance() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE a bigint; b bigint;
BEGIN
  IF TG_TABLE_NAME='membre_groupe' THEN
    SELECT etablissement_id INTO a FROM kb.groupe_ressource WHERE groupe_id=NEW.groupe_id;
    SELECT etablissement_id INTO b FROM kb.ressource WHERE ressource_id=NEW.ressource_id;
  ELSIF TG_TABLE_NAME='besoin_variante' THEN
    SELECT p.etablissement_id INTO a FROM kb.variante v JOIN kb.prestation p USING(prestation_id) WHERE v.variante_id=NEW.variante_id;
    SELECT etablissement_id INTO b FROM kb.groupe_ressource WHERE groupe_id=NEW.groupe_id;
  ELSIF TG_TABLE_NAME='ligne_rdv' THEN
    SELECT p.etablissement_id INTO a FROM kb.rendez_vous r JOIN kb.politique_rdv p USING(politique_id) WHERE r.rdv_id=NEW.rdv_id;
    SELECT p.etablissement_id INTO b FROM kb.version_variante vv JOIN kb.variante v USING(variante_id) JOIN kb.prestation p USING(prestation_id) WHERE vv.version_variante_id=NEW.version_variante_id;
  ELSE
    SELECT p.etablissement_id INTO a FROM kb.rendez_vous r JOIN kb.politique_rdv p USING(politique_id) WHERE r.rdv_id=NEW.rdv_id;
    SELECT etablissement_id INTO b FROM kb.ressource WHERE ressource_id=NEW.ressource_id;
  END IF;
  IF a IS NOT NULL AND b IS NOT NULL AND a <> b THEN
    RAISE EXCEPTION 'Les objets doivent appartenir au meme etablissement' USING ERRCODE='23514';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER meme_salon BEFORE INSERT OR UPDATE ON kb.membre_groupe FOR EACH ROW EXECUTE FUNCTION kb.verifier_appartenance();
CREATE TRIGGER meme_salon BEFORE INSERT OR UPDATE ON kb.besoin_variante FOR EACH ROW EXECUTE FUNCTION kb.verifier_appartenance();
CREATE TRIGGER meme_salon BEFORE INSERT OR UPDATE ON kb.ligne_rdv FOR EACH ROW EXECUTE FUNCTION kb.verifier_appartenance();
CREATE TRIGGER meme_salon BEFORE INSERT OR UPDATE ON kb.allocation_rdv FOR EACH ROW EXECUTE FUNCTION kb.verifier_appartenance();
-- Les associations propriétaires et versions sont immuables ; nouvelle version pour toute modification.
CREATE FUNCTION kb.interdire_modification() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'Objet immuable : creer une nouvelle version' USING ERRCODE='23514';
END $$;
CREATE TRIGGER immuable BEFORE UPDATE OR DELETE ON kb.politique_rdv FOR EACH ROW EXECUTE FUNCTION kb.interdire_modification();
CREATE TRIGGER immuable BEFORE UPDATE OR DELETE ON kb.version_variante FOR EACH ROW EXECUTE FUNCTION kb.interdire_modification();
CREATE TRIGGER immuable BEFORE UPDATE OR DELETE ON kb.tarif_offre FOR EACH ROW EXECUTE FUNCTION kb.interdire_modification();
CREATE TRIGGER immuable BEFORE UPDATE OR DELETE ON kb.politique_abonnement FOR EACH ROW EXECUTE FUNCTION kb.interdire_modification();
CREATE TRIGGER proprietaire_fixe BEFORE UPDATE OF etablissement_id ON kb.prestation FOR EACH ROW EXECUTE FUNCTION kb.interdire_modification();
CREATE TRIGGER proprietaire_fixe BEFORE UPDATE OF prestation_id ON kb.variante FOR EACH ROW EXECUTE FUNCTION kb.interdire_modification();
CREATE TRIGGER proprietaire_fixe BEFORE UPDATE OF etablissement_id ON kb.ressource FOR EACH ROW EXECUTE FUNCTION kb.interdire_modification();
CREATE TRIGGER proprietaire_fixe BEFORE UPDATE OF etablissement_id ON kb.groupe_ressource FOR EACH ROW EXECUTE FUNCTION kb.interdire_modification();
CREATE TRIGGER conditions_fixes BEFORE UPDATE OF politique_id,client_id ON kb.rendez_vous FOR EACH ROW EXECUTE FUNCTION kb.interdire_modification();
CREATE FUNCTION kb.verifier_decision() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE r kb.rendez_vous; d kb.decision_salon; salon bigint;
BEGIN
  SELECT * INTO r FROM kb.rendez_vous WHERE rdv_id=NEW.rdv_id;
  SELECT * INTO d FROM kb.decision_salon WHERE rdv_id=NEW.rdv_id;
  IF r.etat IN ('accepte','termine','absent') AND (d.decision_id IS NULL OR d.resultat <> 'accepte') THEN
    RAISE EXCEPTION 'Acceptation explicite du salon requise' USING ERRCODE='23514';
  END IF;
  IF r.etat='refuse' AND (d.decision_id IS NULL OR d.resultat <> 'refuse') THEN
    RAISE EXCEPTION 'Refus explicite du salon requis' USING ERRCODE='23514';
  END IF;
  IF d.decision_id IS NOT NULL AND r.etat IN ('en_attente_salon','expire') THEN
    RAISE EXCEPTION 'Decision incompatible avec etat du rendez-vous' USING ERRCODE='23514';
  END IF;
  RETURN NULL;
END $$;
CREATE FUNCTION kb.verifier_auteur_decision() RETURNS trigger LANGUAGE plpgsql AS $$
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
CREATE TRIGGER auteur_habilite BEFORE INSERT ON kb.decision_salon FOR EACH ROW EXECUTE FUNCTION kb.verifier_auteur_decision();
CREATE TRIGGER decision_immuable BEFORE UPDATE OR DELETE ON kb.decision_salon FOR EACH ROW EXECUTE FUNCTION kb.interdire_modification();
CREATE CONSTRAINT TRIGGER decision_coherente AFTER INSERT OR UPDATE ON kb.rendez_vous DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION kb.verifier_decision();
CREATE CONSTRAINT TRIGGER decision_coherente AFTER INSERT ON kb.decision_salon DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION kb.verifier_decision();
INSERT INTO kb.permission(code,libelle) VALUES ('rdv_decider','Accepter ou refuser les demandes de rendez-vous');
'''
sql = sql.replace('\nCOMMIT;', '\n' + extra + guards + '\nCOMMIT;')
assert 'avance' not in sql
assert 'grace_jours' not in sql
assert 'cible_reglement' not in sql
tables = re.findall(r'CREATE TABLE kb\.(\w+) \((.*?)\n\);',sql,re.S)
names = {n for n,b in tables}
refs = re.findall(r'REFERENCES kb\.(\w+)\(([^)]+)\)',sql)
assert len(names)==len(tables)
assert all(n in names for n,cols in refs)
(ROOT/'mpd/020_modele_v2.sql').write_text(sql,encoding='utf-8')
lines=['# MLD / MPD V2 — relations et contraintes','',
       'Généré par `build_merise_v2.py` depuis la base V1 figée. Référence métier : CONCEPTION_MERISE_V2.md. Les types physiques sont montrés pour traçabilité ; le DD et les cardinalités restent définis dans la conception.','']
for n,b in tables:
    if n=='etablissement': b+='\n    fuseau varchar(80) NOT NULL DEFAULT \'Africa/Abidjan\''
    if n=='gerant_etablissement': b+='\n    principal boolean NOT NULL DEFAULT false -- unique partiel par salon'
    lines += [f'## {n.upper()}','','```sql',b.strip(),'```','']
(ROOT/'MLD_V2.md').write_text('\n'.join(lines),encoding='utf-8')
print(f'V2: {len(tables)} tables, {len(refs)} foreign keys; no client-payment tables.')

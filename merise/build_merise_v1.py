"""Build the reviewable standalone PostgreSQL candidate and its relation inventory."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent
base = (ROOT / 'mpd/001_socle_provisoire.sql').read_text(encoding='utf-8')
base = re.sub(r'CREATE TABLE kb\.tarif_prestation \(.*?\n\);\n', '', base, flags=re.S)
base = re.sub(r'CREATE INDEX tarif_prestation_service_ix.*?\n', '', base)
base = base[base.index('CREATE SCHEMA kb;'):]
extra = r'''
CREATE TABLE kb.devise (
    code char(3) PRIMARY KEY,
    libelle varchar(80) NOT NULL,
    decimales smallint NOT NULL CHECK (decimales BETWEEN 0 AND 4)
);
CREATE TABLE kb.pays_devise (
    pays_id bigint NOT NULL REFERENCES kb.pays(pays_id),
    code char(3) NOT NULL REFERENCES kb.devise(code),
    PRIMARY KEY (pays_id, code)
);
ALTER TABLE kb.etablissement ADD COLUMN fuseau varchar(80) NOT NULL DEFAULT 'Africa/Abidjan';
ALTER TABLE kb.gerant_etablissement ADD COLUMN principal boolean NOT NULL DEFAULT false;
CREATE UNIQUE INDEX un_principal_par_salon ON kb.gerant_etablissement(etablissement_id) WHERE principal;
CREATE TABLE kb.permission (
    code varchar(60) PRIMARY KEY,
    libelle varchar(160) NOT NULL
);
CREATE TABLE kb.permission_gestion (
    gerant_id bigint NOT NULL,
    etablissement_id bigint NOT NULL,
    permission_code varchar(60) NOT NULL REFERENCES kb.permission(code),
    PRIMARY KEY (gerant_id, etablissement_id, permission_code),
    FOREIGN KEY (gerant_id, etablissement_id) REFERENCES kb.gerant_etablissement(gerant_id, etablissement_id)
);
CREATE TABLE kb.politique_rdv (
    politique_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    etablissement_id bigint NOT NULL REFERENCES kb.etablissement(etablissement_id),
    version integer NOT NULL CHECK (version > 0),
    date_effet timestamptz NOT NULL,
    multi_prestations boolean NOT NULL DEFAULT true,
    annulation_client boolean NOT NULL DEFAULT true,
    report_client boolean NOT NULL DEFAULT true,
    delai_annulation_minutes integer NOT NULL DEFAULT 240 CHECK (delai_annulation_minutes >= 0),
    delai_report_minutes integer NOT NULL DEFAULT 240 CHECK (delai_report_minutes >= 0),
    mode_avance varchar(20) NOT NULL DEFAULT 'desactivee' CHECK (mode_avance IN ('desactivee','facultative','obligatoire')),
    calcul_avance varchar(20) CHECK (calcul_avance IN ('fixe','pourcentage')),
    valeur_avance numeric(14,4),
    devise_fixe char(3) REFERENCES kb.devise(code),
    maintien_minutes integer NOT NULL DEFAULT 10 CHECK (maintien_minutes > 0),
    remboursement_tardif_pct numeric(5,2) NOT NULL DEFAULT 100 CHECK (remboursement_tardif_pct BETWEEN 0 AND 100),
    remboursement_absence_pct numeric(5,2) NOT NULL DEFAULT 100 CHECK (remboursement_absence_pct BETWEEN 0 AND 100),
    UNIQUE (etablissement_id, version),
    UNIQUE (etablissement_id, date_effet),
    CHECK ((mode_avance = 'desactivee' AND calcul_avance IS NULL AND valeur_avance IS NULL AND devise_fixe IS NULL)
        OR (mode_avance <> 'desactivee' AND calcul_avance IS NOT NULL AND valeur_avance IS NOT NULL AND valeur_avance > 0
            AND ((calcul_avance = 'fixe' AND devise_fixe IS NOT NULL)
                OR (calcul_avance = 'pourcentage' AND valeur_avance <= 100 AND devise_fixe IS NULL))))
);
CREATE TABLE kb.variante (
    variante_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    prestation_id bigint NOT NULL REFERENCES kb.prestation(prestation_id),
    libelle varchar(160) NOT NULL,
    actif boolean NOT NULL DEFAULT true
);
CREATE TABLE kb.version_variante (
    version_variante_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    variante_id bigint NOT NULL REFERENCES kb.variante(variante_id),
    date_effet timestamptz NOT NULL,
    duree_minutes integer NOT NULL CHECK (duree_minutes > 0),
    montant numeric(14,4) NOT NULL CHECK (montant >= 0),
    devise char(3) NOT NULL REFERENCES kb.devise(code),
    UNIQUE (variante_id, date_effet)
);
CREATE TABLE kb.ressource (
    ressource_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    etablissement_id bigint NOT NULL REFERENCES kb.etablissement(etablissement_id),
    nature varchar(20) NOT NULL CHECK (nature IN ('employe','physique','globale')),
    libelle varchar(160) NOT NULL,
    capacite integer NOT NULL CHECK (capacite > 0),
    actif boolean NOT NULL DEFAULT true,
    CHECK (nature <> 'employe' OR capacite = 1)
);
CREATE TABLE kb.groupe_ressource (
    groupe_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    etablissement_id bigint NOT NULL REFERENCES kb.etablissement(etablissement_id),
    libelle varchar(160) NOT NULL
);
CREATE TABLE kb.membre_groupe (
    groupe_id bigint NOT NULL REFERENCES kb.groupe_ressource(groupe_id),
    ressource_id bigint NOT NULL REFERENCES kb.ressource(ressource_id),
    PRIMARY KEY (groupe_id, ressource_id)
);
CREATE TABLE kb.besoin_variante (
    variante_id bigint NOT NULL REFERENCES kb.variante(variante_id),
    groupe_id bigint NOT NULL REFERENCES kb.groupe_ressource(groupe_id),
    quantite integer NOT NULL CHECK (quantite > 0),
    PRIMARY KEY (variante_id, groupe_id)
);
CREATE TABLE kb.plage_ressource (
    plage_ressource_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ressource_id bigint NOT NULL REFERENCES kb.ressource(ressource_id),
    jour_semaine smallint NOT NULL CHECK (jour_semaine BETWEEN 1 AND 7),
    debut time NOT NULL,
    fin time NOT NULL,
    CHECK (debut < fin)
);
CREATE TABLE kb.indisponibilite_ressource (
    indisponibilite_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ressource_id bigint NOT NULL REFERENCES kb.ressource(ressource_id),
    debut timestamptz NOT NULL,
    fin timestamptz NOT NULL,
    motif text,
    CHECK (debut < fin)
);
CREATE TABLE kb.rendez_vous (
    rdv_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id bigint NOT NULL REFERENCES kb.compte(compte_id),
    politique_id bigint NOT NULL REFERENCES kb.politique_rdv(politique_id),
    etat varchar(30) NOT NULL CHECK (etat IN ('attente_paiement','confirme','expire','annule','termine','absent')),
    cree_le timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expire_le timestamptz,
    avance_due numeric(14,4) NOT NULL CHECK (avance_due >= 0),
    CHECK (etat <> 'attente_paiement' OR expire_le IS NOT NULL),
    CHECK (expire_le IS NULL OR expire_le > cree_le)
);
CREATE TABLE kb.ligne_rdv (
    rdv_id bigint NOT NULL REFERENCES kb.rendez_vous(rdv_id),
    numero integer NOT NULL CHECK (numero > 0),
    version_variante_id bigint NOT NULL REFERENCES kb.version_variante(version_variante_id),
    debut timestamptz NOT NULL,
    fin timestamptz NOT NULL,
    PRIMARY KEY (rdv_id, numero),
    CHECK (debut < fin)
);
CREATE TABLE kb.allocation_rdv (
    rdv_id bigint NOT NULL,
    numero integer NOT NULL,
    ressource_id bigint NOT NULL REFERENCES kb.ressource(ressource_id),
    quantite integer NOT NULL CHECK (quantite > 0),
    PRIMARY KEY (rdv_id, numero, ressource_id),
    FOREIGN KEY (rdv_id, numero) REFERENCES kb.ligne_rdv(rdv_id, numero)
);
CREATE TABLE kb.demande_idempotente (
    compte_id bigint NOT NULL REFERENCES kb.compte(compte_id),
    cle varchar(160) NOT NULL,
    empreinte varchar(128) NOT NULL,
    rdv_id bigint REFERENCES kb.rendez_vous(rdv_id),
    cree_le timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (compte_id, cle)
);
CREATE TABLE kb.evenement_rdv (
    evenement_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rdv_id bigint NOT NULL REFERENCES kb.rendez_vous(rdv_id),
    auteur_id bigint REFERENCES kb.compte(compte_id),
    nature varchar(40) NOT NULL,
    survenu_le timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    motif text
);
CREATE TABLE kb.historique_ligne (
    evenement_id bigint NOT NULL REFERENCES kb.evenement_rdv(evenement_id),
    numero integer NOT NULL,
    ancien_debut timestamptz NOT NULL,
    ancienne_fin timestamptz NOT NULL,
    nouveau_debut timestamptz NOT NULL,
    nouvelle_fin timestamptz NOT NULL,
    PRIMARY KEY (evenement_id, numero),
    CHECK (ancien_debut < ancienne_fin AND nouveau_debut < nouvelle_fin)
);
CREATE TABLE kb.notification (
    notification_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    evenement_id bigint NOT NULL REFERENCES kb.evenement_rdv(evenement_id),
    destinataire_id bigint NOT NULL REFERENCES kb.compte(compte_id),
    canal varchar(20) NOT NULL CHECK (canal IN ('sms','in_app')),
    etat varchar(20) NOT NULL DEFAULT 'a_envoyer' CHECK (etat IN ('a_envoyer','en_cours','envoye','echec')),
    essais integer NOT NULL DEFAULT 0 CHECK (essais >= 0),
    prochain_essai timestamptz,
    UNIQUE (evenement_id, destinataire_id, canal)
);
CREATE TABLE kb.offre (
    offre_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom varchar(120) NOT NULL,
    actif boolean NOT NULL DEFAULT true
);
CREATE TABLE kb.fonctionnalite (
    code varchar(60) PRIMARY KEY,
    libelle varchar(160) NOT NULL
);
CREATE TABLE kb.offre_fonctionnalite (
    offre_id bigint NOT NULL REFERENCES kb.offre(offre_id),
    code varchar(60) NOT NULL REFERENCES kb.fonctionnalite(code),
    PRIMARY KEY (offre_id, code)
);
CREATE TABLE kb.tarif_offre (
    tarif_offre_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    offre_id bigint NOT NULL REFERENCES kb.offre(offre_id),
    periodicite varchar(20) NOT NULL CHECK (periodicite IN ('mensuelle','annuelle')),
    montant numeric(14,4) NOT NULL CHECK (montant >= 0),
    devise char(3) NOT NULL REFERENCES kb.devise(code),
    date_effet timestamptz NOT NULL,
    UNIQUE (offre_id, periodicite, devise, date_effet)
);
CREATE TABLE kb.politique_abonnement (
    politique_abonnement_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    grace_jours integer NOT NULL DEFAULT 7 CHECK (grace_jours >= 0),
    fiche_visible_apres_grace boolean NOT NULL DEFAULT true,
    nouvelles_reservations_apres_grace boolean NOT NULL DEFAULT false,
    cree_le timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE kb.contrat (
    contrat_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    etablissement_id bigint NOT NULL REFERENCES kb.etablissement(etablissement_id),
    tarif_offre_id bigint NOT NULL REFERENCES kb.tarif_offre(tarif_offre_id),
    politique_abonnement_id bigint NOT NULL REFERENCES kb.politique_abonnement(politique_abonnement_id),
    debut date NOT NULL,
    fin_engagement date NOT NULL,
    etat varchar(20) NOT NULL CHECK (etat IN ('brouillon','actif','clos')),
    CHECK (fin_engagement >= (debut + interval '1 year')::date)
);
CREATE TABLE kb.echeance (
    echeance_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    contrat_id bigint NOT NULL REFERENCES kb.contrat(contrat_id),
    numero integer NOT NULL CHECK (numero > 0),
    debut_periode date NOT NULL,
    fin_periode date NOT NULL,
    exigible_le timestamptz NOT NULL,
    montant_du numeric(14,4) NOT NULL CHECK (montant_du >= 0),
    UNIQUE (contrat_id, numero),
    CHECK (debut_periode < fin_periode)
);
CREATE TABLE kb.cible_reglement (
    cible_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rdv_id bigint UNIQUE REFERENCES kb.rendez_vous(rdv_id),
    echeance_id bigint UNIQUE REFERENCES kb.echeance(echeance_id),
    devise char(3) NOT NULL REFERENCES kb.devise(code),
    CHECK ((rdv_id IS NOT NULL AND echeance_id IS NULL) OR (rdv_id IS NULL AND echeance_id IS NOT NULL))
);
CREATE TABLE kb.tentative_paiement (
    tentative_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cible_id bigint NOT NULL REFERENCES kb.cible_reglement(cible_id),
    cle_operation varchar(160) NOT NULL UNIQUE,
    fournisseur varchar(80) NOT NULL,
    reference_externe varchar(200),
    montant_demande numeric(14,4) NOT NULL CHECK (montant_demande > 0),
    etat varchar(20) NOT NULL CHECK (etat IN ('initie','en_attente','succes','echec','expire')),
    cree_le timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (fournisseur, reference_externe)
);
CREATE TABLE kb.encaissement (
    encaissement_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    montant numeric(14,4) NOT NULL CHECK (montant > 0),
    encaisse_le timestamptz NOT NULL
);
CREATE TABLE kb.encaissement_mobile (
    encaissement_id bigint PRIMARY KEY REFERENCES kb.encaissement(encaissement_id),
    tentative_id bigint NOT NULL UNIQUE REFERENCES kb.tentative_paiement(tentative_id)
);
CREATE TABLE kb.encaissement_especes (
    encaissement_id bigint PRIMARY KEY REFERENCES kb.encaissement(encaissement_id),
    cible_id bigint NOT NULL REFERENCES kb.cible_reglement(cible_id),
    auteur_id bigint NOT NULL REFERENCES kb.compte(compte_id),
    cle_operation varchar(160) NOT NULL UNIQUE
);
CREATE TABLE kb.remboursement (
    remboursement_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    encaissement_id bigint NOT NULL REFERENCES kb.encaissement(encaissement_id),
    cle_operation varchar(160) NOT NULL UNIQUE,
    montant numeric(14,4) NOT NULL CHECK (montant > 0),
    etat varchar(20) NOT NULL CHECK (etat IN ('demande','en_cours','valide','echec')),
    reference_externe varchar(200),
    cree_le timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE kb.configuration_plateforme (
    configuration_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_effet timestamptz NOT NULL UNIQUE,
    max_salons_par_gerant integer CHECK (max_salons_par_gerant > 0),
    max_gerants_par_salon integer CHECK (max_gerants_par_salon > 0)
);
CREATE INDEX allocation_ressource_ix ON kb.allocation_rdv(ressource_id);
CREATE INDEX ligne_intervalle_ix ON kb.ligne_rdv(debut, fin);
CREATE INDEX rdv_expiration_ix ON kb.rendez_vous(expire_le) WHERE etat = 'attente_paiement';
CREATE INDEX notification_reprise_ix ON kb.notification(prochain_essai) WHERE etat IN ('a_envoyer','echec');
-- Contraintes interrelations et immutabilité : voir CONCEPTION_MERISE_V1.md.
-- Un encaissement exige exactement un sous-type (mobile ou espèces), à contrôler transactionnellement.
-- Limites de gestion NULL = aucune limite administrative ; ce n'est pas une capacité de réservation.
INSERT INTO kb.devise(code, libelle, decimales) VALUES ('XOF','Franc CFA BCEAO',0);
'''
sql = '-- Candidat V1, base PostgreSQL vide uniquement. Non deploye.\nBEGIN;\n' + base + extra + '\nCOMMIT;\n'
(ROOT / 'mpd/010_modele_v1.sql').write_text(sql, encoding='utf-8')
tables = re.findall(r'CREATE TABLE kb\.(\w+) \((.*?)\n\);', sql, re.S)
names = {n for n, _ in tables}
refs = set(re.findall(r'REFERENCES kb\.(\w+)', sql))
assert len(names) == len(tables), 'Duplicate table'
assert refs <= names, refs - names
assert 'tarif_prestation' not in names
assert sql.count('(') == sql.count(')'), 'Unbalanced parentheses'
columns = {}
for name, body in tables:
    columns[name] = set(re.findall(r'^\s*(\w+)\s+(?:bigint|integer|smallint|varchar|char|numeric|boolean|text|date|time|timestamptz)\b', body, re.M))
references = re.findall(r'REFERENCES kb\.(\w+)\(([^)]+)\)', sql)
for target, fields in references:
    assert {f.strip() for f in fields.split(',')} <= columns[target], (target, fields)
for name, body in tables:
    for fields in re.findall(r'FOREIGN KEY \(([^)]+)\)', body):
        assert {f.strip() for f in fields.split(',')} <= columns[name], (name, fields)
lines = ['# MLD V1 — inventaire des relations', '',
         'Généré par `build_merise_v1.py`. Les types SQL figurent dans le MPD ; cet inventaire reprend les attributs et contraintes pour traçabilité. Sens métier, cardinalités et audit : CONCEPTION_MERISE_V1.md.', '',
         'Le socle compte 18 relations conservées ; TARIF_PRESTATION est remplacée. Les ajouts ALTER (fuseau établissement, principal affectation) sont inclus ci-dessous.', '']
for name, body in tables:
    if name == 'etablissement': body += '\n    fuseau (Africa/Abidjan par défaut)'
    if name == 'gerant_etablissement': body += '\n    principal (false par défaut ; unicité partielle par salon)'
    lines.extend([f'## {name.upper()}', '', '```sql', body.strip(), '```', ''])
(ROOT / 'MLD_V1.md').write_text('\n'.join(lines), encoding='utf-8')
report = f'''# Vérification statique MERISE V1

- {len(tables)} tables, noms uniques.
- {len(refs)} tables cibles de références : toutes déclarées.
- {len(references)} références : colonnes cibles présentes ; colonnes sources des FK composites présentes.
- Parenthèses équilibrées ; ancien TARIF_PRESTATION absent du candidat V1.
- MLD et SQL produits depuis le même catalogue.
- Ce contrôle ne parse pas la grammaire PostgreSQL et ne teste ni les FK composites, ni les transactions, ni les contraintes de concurrence.
- Aucun moteur PostgreSQL/psql/docker détecté dans PATH lors de cette consolidation. Exécution SQL et recette restent à faire.
'''
(ROOT / 'VERIFICATION_V1.md').write_text(report, encoding='utf-8')
print(report)

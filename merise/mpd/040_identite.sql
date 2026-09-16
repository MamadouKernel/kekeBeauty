-- Identité technique : un téléphone identifie un seul compte.
-- Une migration refuse les doublons existants au lieu de fusionner des personnes.
BEGIN;
CREATE UNIQUE INDEX IF NOT EXISTS ux_compte_telephone ON kb.compte(telephone_normalise);
CREATE TABLE IF NOT EXISTS kb.defi_connexion (
    defi_id uuid PRIMARY KEY,
    telephone varchar(20) NOT NULL,
    preuve text NOT NULL,
    expire_le timestamptz NOT NULL,
    cree_le timestamptz NOT NULL DEFAULT clock_timestamp(),
    essais integer NOT NULL DEFAULT 0 CHECK (essais BETWEEN 0 AND 5),
    consomme boolean NOT NULL DEFAULT false
);
CREATE INDEX IF NOT EXISTS ix_defi_telephone_date ON kb.defi_connexion(telephone,cree_le);
COMMIT;

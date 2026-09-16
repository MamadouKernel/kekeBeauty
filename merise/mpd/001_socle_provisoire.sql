-- Keke Beauty : DDL candidat pour une base PostgreSQL de conception isolée.
-- Ne pas appliquer en production. Domaines RDV et paiement encore ouverts.

CREATE SCHEMA kb;

CREATE TABLE kb.pays (
    pays_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom varchar(120) NOT NULL
);

CREATE TABLE kb.region (
    region_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pays_id bigint NOT NULL REFERENCES kb.pays(pays_id),
    nom varchar(120) NOT NULL
);

CREATE TABLE kb.ville (
    ville_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    region_id bigint NOT NULL REFERENCES kb.region(region_id),
    nom varchar(120) NOT NULL
);

CREATE TABLE kb.commune (
    commune_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ville_id bigint NOT NULL REFERENCES kb.ville(ville_id),
    nom varchar(120) NOT NULL
);

CREATE TABLE kb.categorie (
    categorie_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom varchar(120) NOT NULL,
    etat varchar(30) NOT NULL
);

CREATE TABLE kb.compte (
    compte_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    telephone_normalise varchar(20) NOT NULL,
    telephone_verifie_le timestamptz,
    etat varchar(30) NOT NULL
);

CREATE TABLE kb.role (
    role_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code varchar(30) NOT NULL UNIQUE,
    libelle varchar(120) NOT NULL
);

CREATE TABLE kb.compte_role (
    compte_id bigint NOT NULL REFERENCES kb.compte(compte_id),
    role_id bigint NOT NULL REFERENCES kb.role(role_id),
    PRIMARY KEY (compte_id, role_id)
);

CREATE TABLE kb.gerant (
    gerant_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    compte_id bigint NOT NULL REFERENCES kb.compte(compte_id),
    nom_declare varchar(160) NOT NULL
);

CREATE TABLE kb.etablissement (
    etablissement_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    commune_id bigint REFERENCES kb.commune(commune_id),
    nom varchar(160) NOT NULL,
    description text,
    telephone_service varchar(20),
    latitude numeric(9,6),
    longitude numeric(9,6),
    etat_publication varchar(30) NOT NULL,
    CONSTRAINT coordonnees_ensemble CHECK ((latitude IS NULL AND longitude IS NULL) OR (latitude IS NOT NULL AND longitude IS NOT NULL)),
    CONSTRAINT latitude_valide CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT longitude_valide CHECK (longitude BETWEEN -180 AND 180)
);

CREATE TABLE kb.gerant_etablissement (
    gerant_id bigint NOT NULL REFERENCES kb.gerant(gerant_id),
    etablissement_id bigint NOT NULL REFERENCES kb.etablissement(etablissement_id),
    PRIMARY KEY (gerant_id, etablissement_id)
);

CREATE TABLE kb.etablissement_categorie (
    etablissement_id bigint NOT NULL REFERENCES kb.etablissement(etablissement_id),
    categorie_id bigint NOT NULL REFERENCES kb.categorie(categorie_id),
    PRIMARY KEY (etablissement_id, categorie_id)
);

CREATE TABLE kb.media (
    media_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    etablissement_id bigint NOT NULL REFERENCES kb.etablissement(etablissement_id),
    nature varchar(20) NOT NULL,
    reference_fichier text NOT NULL,
    ordre integer NOT NULL CHECK (ordre >= 0),
    etat varchar(30) NOT NULL
);

CREATE TABLE kb.prestation (
    prestation_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    etablissement_id bigint NOT NULL REFERENCES kb.etablissement(etablissement_id),
    nom varchar(160) NOT NULL,
    description text,
    etat varchar(30) NOT NULL
);

CREATE TABLE kb.tarif_prestation (
    tarif_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    prestation_id bigint NOT NULL REFERENCES kb.prestation(prestation_id),
    montant numeric(12,2) NOT NULL CHECK (montant >= 0),
    devise char(3) NOT NULL,
    date_effet date
);

CREATE TABLE kb.plage_ouverture (
    plage_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    etablissement_id bigint NOT NULL REFERENCES kb.etablissement(etablissement_id),
    jour_semaine smallint NOT NULL CHECK (jour_semaine BETWEEN 1 AND 7),
    heure_debut time NOT NULL,
    heure_fin time NOT NULL,
    CONSTRAINT plage_ordre CHECK (heure_debut < heure_fin)
);

CREATE TABLE kb.exception_ouverture (
    exception_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    etablissement_id bigint NOT NULL REFERENCES kb.etablissement(etablissement_id),
    date_concernee date NOT NULL,
    heure_debut time,
    heure_fin time,
    ferme boolean NOT NULL,
    CONSTRAINT exception_coherente CHECK (
        (ferme AND heure_debut IS NULL AND heure_fin IS NULL)
        OR (NOT ferme AND heure_debut IS NOT NULL AND heure_fin IS NOT NULL AND heure_debut < heure_fin)
    )
);

CREATE TABLE kb.dossier_kyc (
    dossier_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    gerant_id bigint NOT NULL REFERENCES kb.gerant(gerant_id),
    etat varchar(30) NOT NULL,
    soumis_le timestamptz,
    decide_le timestamptz,
    decide_par_compte_id bigint REFERENCES kb.compte(compte_id),
    motif_decision text
);

CREATE TABLE kb.justificatif_kyc (
    justificatif_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dossier_id bigint NOT NULL REFERENCES kb.dossier_kyc(dossier_id),
    type_piece varchar(60) NOT NULL,
    reference_fichier_privee text NOT NULL,
    etat varchar(30) NOT NULL
);

CREATE INDEX region_pays_ix ON kb.region(pays_id);
CREATE INDEX ville_region_ix ON kb.ville(region_id);
CREATE INDEX commune_ville_ix ON kb.commune(ville_id);
CREATE INDEX compte_telephone_ix ON kb.compte(telephone_normalise);
CREATE INDEX gerant_compte_ix ON kb.gerant(compte_id);
CREATE INDEX etablissement_commune_ix ON kb.etablissement(commune_id);
CREATE INDEX gerant_etablissement_salon_ix ON kb.gerant_etablissement(etablissement_id);
CREATE INDEX etablissement_categorie_categorie_ix ON kb.etablissement_categorie(categorie_id);
CREATE INDEX media_salon_ix ON kb.media(etablissement_id);
CREATE INDEX prestation_salon_ix ON kb.prestation(etablissement_id);
CREATE INDEX tarif_prestation_service_ix ON kb.tarif_prestation(prestation_id);
CREATE INDEX plage_salon_ix ON kb.plage_ouverture(etablissement_id);
CREATE INDEX exception_salon_date_ix ON kb.exception_ouverture(etablissement_id, date_concernee);
CREATE INDEX dossier_kyc_gerant_ix ON kb.dossier_kyc(gerant_id);
CREATE INDEX dossier_kyc_decideur_ix ON kb.dossier_kyc(decide_par_compte_id);
CREATE INDEX justificatif_dossier_ix ON kb.justificatif_kyc(dossier_id);

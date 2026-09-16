# MLD V1 — inventaire des relations

Généré par `build_merise_v1.py`. Les types SQL figurent dans le MPD ; cet inventaire reprend les attributs et contraintes pour traçabilité. Sens métier, cardinalités et audit : CONCEPTION_MERISE_V1.md.

Le socle compte 18 relations conservées ; TARIF_PRESTATION est remplacée. Les ajouts ALTER (fuseau établissement, principal affectation) sont inclus ci-dessous.

## PAYS

```sql
pays_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom varchar(120) NOT NULL
```

## REGION

```sql
region_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pays_id bigint NOT NULL REFERENCES kb.pays(pays_id),
    nom varchar(120) NOT NULL
```

## VILLE

```sql
ville_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    region_id bigint NOT NULL REFERENCES kb.region(region_id),
    nom varchar(120) NOT NULL
```

## COMMUNE

```sql
commune_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ville_id bigint NOT NULL REFERENCES kb.ville(ville_id),
    nom varchar(120) NOT NULL
```

## CATEGORIE

```sql
categorie_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom varchar(120) NOT NULL,
    etat varchar(30) NOT NULL
```

## COMPTE

```sql
compte_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    telephone_normalise varchar(20) NOT NULL,
    telephone_verifie_le timestamptz,
    etat varchar(30) NOT NULL
```

## ROLE

```sql
role_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code varchar(30) NOT NULL UNIQUE,
    libelle varchar(120) NOT NULL
```

## COMPTE_ROLE

```sql
compte_id bigint NOT NULL REFERENCES kb.compte(compte_id),
    role_id bigint NOT NULL REFERENCES kb.role(role_id),
    PRIMARY KEY (compte_id, role_id)
```

## GERANT

```sql
gerant_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    compte_id bigint NOT NULL REFERENCES kb.compte(compte_id),
    nom_declare varchar(160) NOT NULL
```

## ETABLISSEMENT

```sql
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
    fuseau (Africa/Abidjan par défaut)
```

## GERANT_ETABLISSEMENT

```sql
gerant_id bigint NOT NULL REFERENCES kb.gerant(gerant_id),
    etablissement_id bigint NOT NULL REFERENCES kb.etablissement(etablissement_id),
    PRIMARY KEY (gerant_id, etablissement_id)
    principal (false par défaut ; unicité partielle par salon)
```

## ETABLISSEMENT_CATEGORIE

```sql
etablissement_id bigint NOT NULL REFERENCES kb.etablissement(etablissement_id),
    categorie_id bigint NOT NULL REFERENCES kb.categorie(categorie_id),
    PRIMARY KEY (etablissement_id, categorie_id)
```

## MEDIA

```sql
media_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    etablissement_id bigint NOT NULL REFERENCES kb.etablissement(etablissement_id),
    nature varchar(20) NOT NULL,
    reference_fichier text NOT NULL,
    ordre integer NOT NULL CHECK (ordre >= 0),
    etat varchar(30) NOT NULL
```

## PRESTATION

```sql
prestation_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    etablissement_id bigint NOT NULL REFERENCES kb.etablissement(etablissement_id),
    nom varchar(160) NOT NULL,
    description text,
    etat varchar(30) NOT NULL
```

## PLAGE_OUVERTURE

```sql
plage_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    etablissement_id bigint NOT NULL REFERENCES kb.etablissement(etablissement_id),
    jour_semaine smallint NOT NULL CHECK (jour_semaine BETWEEN 1 AND 7),
    heure_debut time NOT NULL,
    heure_fin time NOT NULL,
    CONSTRAINT plage_ordre CHECK (heure_debut < heure_fin)
```

## EXCEPTION_OUVERTURE

```sql
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
```

## DOSSIER_KYC

```sql
dossier_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    gerant_id bigint NOT NULL REFERENCES kb.gerant(gerant_id),
    etat varchar(30) NOT NULL,
    soumis_le timestamptz,
    decide_le timestamptz,
    decide_par_compte_id bigint REFERENCES kb.compte(compte_id),
    motif_decision text
```

## JUSTIFICATIF_KYC

```sql
justificatif_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dossier_id bigint NOT NULL REFERENCES kb.dossier_kyc(dossier_id),
    type_piece varchar(60) NOT NULL,
    reference_fichier_privee text NOT NULL,
    etat varchar(30) NOT NULL
```

## DEVISE

```sql
code char(3) PRIMARY KEY,
    libelle varchar(80) NOT NULL,
    decimales smallint NOT NULL CHECK (decimales BETWEEN 0 AND 4)
```

## PAYS_DEVISE

```sql
pays_id bigint NOT NULL REFERENCES kb.pays(pays_id),
    code char(3) NOT NULL REFERENCES kb.devise(code),
    PRIMARY KEY (pays_id, code)
```

## PERMISSION

```sql
code varchar(60) PRIMARY KEY,
    libelle varchar(160) NOT NULL
```

## PERMISSION_GESTION

```sql
gerant_id bigint NOT NULL,
    etablissement_id bigint NOT NULL,
    permission_code varchar(60) NOT NULL REFERENCES kb.permission(code),
    PRIMARY KEY (gerant_id, etablissement_id, permission_code),
    FOREIGN KEY (gerant_id, etablissement_id) REFERENCES kb.gerant_etablissement(gerant_id, etablissement_id)
```

## POLITIQUE_RDV

```sql
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
```

## VARIANTE

```sql
variante_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    prestation_id bigint NOT NULL REFERENCES kb.prestation(prestation_id),
    libelle varchar(160) NOT NULL,
    actif boolean NOT NULL DEFAULT true
```

## VERSION_VARIANTE

```sql
version_variante_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    variante_id bigint NOT NULL REFERENCES kb.variante(variante_id),
    date_effet timestamptz NOT NULL,
    duree_minutes integer NOT NULL CHECK (duree_minutes > 0),
    montant numeric(14,4) NOT NULL CHECK (montant >= 0),
    devise char(3) NOT NULL REFERENCES kb.devise(code),
    UNIQUE (variante_id, date_effet)
```

## RESSOURCE

```sql
ressource_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    etablissement_id bigint NOT NULL REFERENCES kb.etablissement(etablissement_id),
    nature varchar(20) NOT NULL CHECK (nature IN ('employe','physique','globale')),
    libelle varchar(160) NOT NULL,
    capacite integer NOT NULL CHECK (capacite > 0),
    actif boolean NOT NULL DEFAULT true,
    CHECK (nature <> 'employe' OR capacite = 1)
```

## GROUPE_RESSOURCE

```sql
groupe_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    etablissement_id bigint NOT NULL REFERENCES kb.etablissement(etablissement_id),
    libelle varchar(160) NOT NULL
```

## MEMBRE_GROUPE

```sql
groupe_id bigint NOT NULL REFERENCES kb.groupe_ressource(groupe_id),
    ressource_id bigint NOT NULL REFERENCES kb.ressource(ressource_id),
    PRIMARY KEY (groupe_id, ressource_id)
```

## BESOIN_VARIANTE

```sql
variante_id bigint NOT NULL REFERENCES kb.variante(variante_id),
    groupe_id bigint NOT NULL REFERENCES kb.groupe_ressource(groupe_id),
    quantite integer NOT NULL CHECK (quantite > 0),
    PRIMARY KEY (variante_id, groupe_id)
```

## PLAGE_RESSOURCE

```sql
plage_ressource_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ressource_id bigint NOT NULL REFERENCES kb.ressource(ressource_id),
    jour_semaine smallint NOT NULL CHECK (jour_semaine BETWEEN 1 AND 7),
    debut time NOT NULL,
    fin time NOT NULL,
    CHECK (debut < fin)
```

## INDISPONIBILITE_RESSOURCE

```sql
indisponibilite_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ressource_id bigint NOT NULL REFERENCES kb.ressource(ressource_id),
    debut timestamptz NOT NULL,
    fin timestamptz NOT NULL,
    motif text,
    CHECK (debut < fin)
```

## RENDEZ_VOUS

```sql
rdv_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id bigint NOT NULL REFERENCES kb.compte(compte_id),
    politique_id bigint NOT NULL REFERENCES kb.politique_rdv(politique_id),
    etat varchar(30) NOT NULL CHECK (etat IN ('attente_paiement','confirme','expire','annule','termine','absent')),
    cree_le timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expire_le timestamptz,
    avance_due numeric(14,4) NOT NULL CHECK (avance_due >= 0),
    CHECK (etat <> 'attente_paiement' OR expire_le IS NOT NULL),
    CHECK (expire_le IS NULL OR expire_le > cree_le)
```

## LIGNE_RDV

```sql
rdv_id bigint NOT NULL REFERENCES kb.rendez_vous(rdv_id),
    numero integer NOT NULL CHECK (numero > 0),
    version_variante_id bigint NOT NULL REFERENCES kb.version_variante(version_variante_id),
    debut timestamptz NOT NULL,
    fin timestamptz NOT NULL,
    PRIMARY KEY (rdv_id, numero),
    CHECK (debut < fin)
```

## ALLOCATION_RDV

```sql
rdv_id bigint NOT NULL,
    numero integer NOT NULL,
    ressource_id bigint NOT NULL REFERENCES kb.ressource(ressource_id),
    quantite integer NOT NULL CHECK (quantite > 0),
    PRIMARY KEY (rdv_id, numero, ressource_id),
    FOREIGN KEY (rdv_id, numero) REFERENCES kb.ligne_rdv(rdv_id, numero)
```

## DEMANDE_IDEMPOTENTE

```sql
compte_id bigint NOT NULL REFERENCES kb.compte(compte_id),
    cle varchar(160) NOT NULL,
    empreinte varchar(128) NOT NULL,
    rdv_id bigint REFERENCES kb.rendez_vous(rdv_id),
    cree_le timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (compte_id, cle)
```

## EVENEMENT_RDV

```sql
evenement_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rdv_id bigint NOT NULL REFERENCES kb.rendez_vous(rdv_id),
    auteur_id bigint REFERENCES kb.compte(compte_id),
    nature varchar(40) NOT NULL,
    survenu_le timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    motif text
```

## HISTORIQUE_LIGNE

```sql
evenement_id bigint NOT NULL REFERENCES kb.evenement_rdv(evenement_id),
    numero integer NOT NULL,
    ancien_debut timestamptz NOT NULL,
    ancienne_fin timestamptz NOT NULL,
    nouveau_debut timestamptz NOT NULL,
    nouvelle_fin timestamptz NOT NULL,
    PRIMARY KEY (evenement_id, numero),
    CHECK (ancien_debut < ancienne_fin AND nouveau_debut < nouvelle_fin)
```

## NOTIFICATION

```sql
notification_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    evenement_id bigint NOT NULL REFERENCES kb.evenement_rdv(evenement_id),
    destinataire_id bigint NOT NULL REFERENCES kb.compte(compte_id),
    canal varchar(20) NOT NULL CHECK (canal IN ('sms','in_app')),
    etat varchar(20) NOT NULL DEFAULT 'a_envoyer' CHECK (etat IN ('a_envoyer','en_cours','envoye','echec')),
    essais integer NOT NULL DEFAULT 0 CHECK (essais >= 0),
    prochain_essai timestamptz,
    UNIQUE (evenement_id, destinataire_id, canal)
```

## OFFRE

```sql
offre_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom varchar(120) NOT NULL,
    actif boolean NOT NULL DEFAULT true
```

## FONCTIONNALITE

```sql
code varchar(60) PRIMARY KEY,
    libelle varchar(160) NOT NULL
```

## OFFRE_FONCTIONNALITE

```sql
offre_id bigint NOT NULL REFERENCES kb.offre(offre_id),
    code varchar(60) NOT NULL REFERENCES kb.fonctionnalite(code),
    PRIMARY KEY (offre_id, code)
```

## TARIF_OFFRE

```sql
tarif_offre_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    offre_id bigint NOT NULL REFERENCES kb.offre(offre_id),
    periodicite varchar(20) NOT NULL CHECK (periodicite IN ('mensuelle','annuelle')),
    montant numeric(14,4) NOT NULL CHECK (montant >= 0),
    devise char(3) NOT NULL REFERENCES kb.devise(code),
    date_effet timestamptz NOT NULL,
    UNIQUE (offre_id, periodicite, devise, date_effet)
```

## POLITIQUE_ABONNEMENT

```sql
politique_abonnement_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    grace_jours integer NOT NULL DEFAULT 7 CHECK (grace_jours >= 0),
    fiche_visible_apres_grace boolean NOT NULL DEFAULT true,
    nouvelles_reservations_apres_grace boolean NOT NULL DEFAULT false,
    cree_le timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
```

## CONTRAT

```sql
contrat_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    etablissement_id bigint NOT NULL REFERENCES kb.etablissement(etablissement_id),
    tarif_offre_id bigint NOT NULL REFERENCES kb.tarif_offre(tarif_offre_id),
    politique_abonnement_id bigint NOT NULL REFERENCES kb.politique_abonnement(politique_abonnement_id),
    debut date NOT NULL,
    fin_engagement date NOT NULL,
    etat varchar(20) NOT NULL CHECK (etat IN ('brouillon','actif','clos')),
    CHECK (fin_engagement >= (debut + interval '1 year')::date)
```

## ECHEANCE

```sql
echeance_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    contrat_id bigint NOT NULL REFERENCES kb.contrat(contrat_id),
    numero integer NOT NULL CHECK (numero > 0),
    debut_periode date NOT NULL,
    fin_periode date NOT NULL,
    exigible_le timestamptz NOT NULL,
    montant_du numeric(14,4) NOT NULL CHECK (montant_du >= 0),
    UNIQUE (contrat_id, numero),
    CHECK (debut_periode < fin_periode)
```

## CIBLE_REGLEMENT

```sql
cible_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rdv_id bigint UNIQUE REFERENCES kb.rendez_vous(rdv_id),
    echeance_id bigint UNIQUE REFERENCES kb.echeance(echeance_id),
    devise char(3) NOT NULL REFERENCES kb.devise(code),
    CHECK ((rdv_id IS NOT NULL AND echeance_id IS NULL) OR (rdv_id IS NULL AND echeance_id IS NOT NULL))
```

## TENTATIVE_PAIEMENT

```sql
tentative_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cible_id bigint NOT NULL REFERENCES kb.cible_reglement(cible_id),
    cle_operation varchar(160) NOT NULL UNIQUE,
    fournisseur varchar(80) NOT NULL,
    reference_externe varchar(200),
    montant_demande numeric(14,4) NOT NULL CHECK (montant_demande > 0),
    etat varchar(20) NOT NULL CHECK (etat IN ('initie','en_attente','succes','echec','expire')),
    cree_le timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (fournisseur, reference_externe)
```

## ENCAISSEMENT

```sql
encaissement_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    montant numeric(14,4) NOT NULL CHECK (montant > 0),
    encaisse_le timestamptz NOT NULL
```

## ENCAISSEMENT_MOBILE

```sql
encaissement_id bigint PRIMARY KEY REFERENCES kb.encaissement(encaissement_id),
    tentative_id bigint NOT NULL UNIQUE REFERENCES kb.tentative_paiement(tentative_id)
```

## ENCAISSEMENT_ESPECES

```sql
encaissement_id bigint PRIMARY KEY REFERENCES kb.encaissement(encaissement_id),
    cible_id bigint NOT NULL REFERENCES kb.cible_reglement(cible_id),
    auteur_id bigint NOT NULL REFERENCES kb.compte(compte_id),
    cle_operation varchar(160) NOT NULL UNIQUE
```

## REMBOURSEMENT

```sql
remboursement_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    encaissement_id bigint NOT NULL REFERENCES kb.encaissement(encaissement_id),
    cle_operation varchar(160) NOT NULL UNIQUE,
    montant numeric(14,4) NOT NULL CHECK (montant > 0),
    etat varchar(20) NOT NULL CHECK (etat IN ('demande','en_cours','valide','echec')),
    reference_externe varchar(200),
    cree_le timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
```

## CONFIGURATION_PLATEFORME

```sql
configuration_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_effet timestamptz NOT NULL UNIQUE,
    max_salons_par_gerant integer CHECK (max_salons_par_gerant > 0),
    max_gerants_par_salon integer CHECK (max_gerants_par_salon > 0)
```

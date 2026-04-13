-- ============================================================
-- PROJET ORACLE : Gestion des Absences Étudiants
-- Script 01 : Création du schéma (Tables, Contraintes, Index)
-- ISCAE - Master MPIAG 2025-2026
-- ============================================================

-- ============================================================
-- ÉTAPE 1 : Création de l'utilisateur/schéma dédié
-- ============================================================
-- Exécuter en tant que SYSTEM ou SYS AS SYSDBA

ALTER SESSION SET "_ORACLE_SCRIPT" = TRUE;

-- Supprimer l'utilisateur s'il existe déjà
BEGIN
    EXECUTE IMMEDIATE 'DROP USER gestion_absences CASCADE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Créer l'utilisateur
CREATE USER gestion_absences IDENTIFIED BY gestion2025
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    QUOTA UNLIMITED ON USERS;

-- Accorder les privilèges
GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE MATERIALIZED VIEW TO gestion_absences;
GRANT CREATE SEQUENCE TO gestion_absences;
GRANT CREATE TRIGGER TO gestion_absences;
GRANT CREATE PROCEDURE TO gestion_absences;
GRANT CREATE SESSION TO gestion_absences;
GRANT EXECUTE ON DBMS_LOCK TO gestion_absences;

-- ============================================================
-- ÉTAPE 2 : Connexion au schéma
-- ============================================================
CONNECT gestion_absences/gestion2025@localhost:1521/XE;

-- ============================================================
-- ÉTAPE 3 : Tables de référence
-- ============================================================

-- Table des filières
CREATE TABLE FILIERES (
    id_filiere    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code_filiere  VARCHAR2(20)  NOT NULL UNIQUE,
    nom_filiere   VARCHAR2(100) NOT NULL,
    description   VARCHAR2(500),
    date_creation DATE DEFAULT SYSDATE NOT NULL
);

-- Table des groupes
CREATE TABLE GROUPES (
    id_groupe    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code_groupe  VARCHAR2(20)  NOT NULL UNIQUE,
    nom_groupe   VARCHAR2(100) NOT NULL,
    id_filiere   NUMBER        NOT NULL,
    annee_universitaire VARCHAR2(9) NOT NULL,
    CONSTRAINT fk_groupe_filiere FOREIGN KEY (id_filiere) REFERENCES FILIERES(id_filiere)
);

-- Table des semestres
CREATE TABLE SEMESTRES (
    id_semestre  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code_semestre VARCHAR2(10) NOT NULL UNIQUE,
    nom_semestre VARCHAR2(50)  NOT NULL,
    date_debut   DATE          NOT NULL,
    date_fin     DATE          NOT NULL,
    annee_universitaire VARCHAR2(9) NOT NULL,
    CONSTRAINT chk_dates_semestre CHECK (date_fin > date_debut)
);

-- ============================================================
-- ÉTAPE 4 : Tables principales
-- ============================================================

-- Table des étudiants
CREATE TABLE ETUDIANTS (
    id_etudiant  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cne          VARCHAR2(20)  NOT NULL UNIQUE,
    nom          VARCHAR2(50)  NOT NULL,
    prenom       VARCHAR2(50)  NOT NULL,
    date_naissance DATE        NOT NULL,
    email        VARCHAR2(100) UNIQUE,
    telephone    VARCHAR2(20),
    adresse      VARCHAR2(200),
    id_groupe    NUMBER        NOT NULL,
    statut       VARCHAR2(20)  DEFAULT 'ACTIF' NOT NULL,
    date_inscription DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_etudiant_groupe FOREIGN KEY (id_groupe) REFERENCES GROUPES(id_groupe),
    CONSTRAINT chk_statut_etudiant CHECK (statut IN ('ACTIF', 'SUSPENDU', 'EXCLU', 'DIPLOME')),
    CONSTRAINT chk_date_naissance CHECK (date_naissance < SYSDATE)
);

-- Table des enseignants
CREATE TABLE ENSEIGNANTS (
    id_enseignant NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    matricule     VARCHAR2(20)  NOT NULL UNIQUE,
    nom           VARCHAR2(50)  NOT NULL,
    prenom        VARCHAR2(50)  NOT NULL,
    email         VARCHAR2(100) UNIQUE,
    telephone     VARCHAR2(20),
    specialite    VARCHAR2(100),
    grade         VARCHAR2(50),
    statut        VARCHAR2(20) DEFAULT 'ACTIF' NOT NULL,
    CONSTRAINT chk_statut_enseignant CHECK (statut IN ('ACTIF', 'INACTIF'))
);

-- Table des matières
CREATE TABLE MATIERES (
    id_matiere    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code_matiere  VARCHAR2(20)  NOT NULL UNIQUE,
    nom_matiere   VARCHAR2(100) NOT NULL,
    coefficient   NUMBER(3,1)   NOT NULL,
    volume_horaire NUMBER(5)    NOT NULL,
    id_filiere    NUMBER        NOT NULL,
    id_semestre   NUMBER        NOT NULL,
    type_matiere  VARCHAR2(20)  DEFAULT 'COURS' NOT NULL,
    CONSTRAINT fk_matiere_filiere FOREIGN KEY (id_filiere) REFERENCES FILIERES(id_filiere),
    CONSTRAINT fk_matiere_semestre FOREIGN KEY (id_semestre) REFERENCES SEMESTRES(id_semestre),
    CONSTRAINT chk_coefficient CHECK (coefficient > 0),
    CONSTRAINT chk_volume_horaire CHECK (volume_horaire > 0),
    CONSTRAINT chk_type_matiere CHECK (type_matiere IN ('COURS', 'TD', 'TP'))
);

-- Table des affectations enseignant-matière
CREATE TABLE AFFECTATIONS (
    id_affectation NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_enseignant  NUMBER NOT NULL,
    id_matiere     NUMBER NOT NULL,
    id_groupe      NUMBER NOT NULL,
    annee_universitaire VARCHAR2(9) NOT NULL,
    CONSTRAINT fk_affect_enseignant FOREIGN KEY (id_enseignant) REFERENCES ENSEIGNANTS(id_enseignant),
    CONSTRAINT fk_affect_matiere FOREIGN KEY (id_matiere) REFERENCES MATIERES(id_matiere),
    CONSTRAINT fk_affect_groupe FOREIGN KEY (id_groupe) REFERENCES GROUPES(id_groupe),
    CONSTRAINT uk_affectation UNIQUE (id_enseignant, id_matiere, id_groupe, annee_universitaire)
);

-- Table des séances
CREATE TABLE SEANCES (
    id_seance     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_matiere    NUMBER        NOT NULL,
    id_enseignant NUMBER        NOT NULL,
    id_groupe     NUMBER        NOT NULL,
    date_seance   DATE          NOT NULL,
    heure_debut   VARCHAR2(5)   NOT NULL,
    heure_fin     VARCHAR2(5)   NOT NULL,
    salle         VARCHAR2(30),
    type_seance   VARCHAR2(20)  DEFAULT 'COURS' NOT NULL,
    statut        VARCHAR2(20)  DEFAULT 'PLANIFIEE' NOT NULL,
    CONSTRAINT fk_seance_matiere FOREIGN KEY (id_matiere) REFERENCES MATIERES(id_matiere),
    CONSTRAINT fk_seance_enseignant FOREIGN KEY (id_enseignant) REFERENCES ENSEIGNANTS(id_enseignant),
    CONSTRAINT fk_seance_groupe FOREIGN KEY (id_groupe) REFERENCES GROUPES(id_groupe),
    CONSTRAINT chk_type_seance CHECK (type_seance IN ('COURS', 'TD', 'TP')),
    CONSTRAINT chk_statut_seance CHECK (statut IN ('PLANIFIEE', 'EFFECTUEE', 'ANNULEE'))
);

-- Table des absences
CREATE TABLE ABSENCES (
    id_absence    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_etudiant   NUMBER        NOT NULL,
    id_seance     NUMBER        NOT NULL,
    date_absence  DATE          DEFAULT SYSDATE NOT NULL,
    est_justifiee NUMBER(1)     DEFAULT 0 NOT NULL,
    motif         VARCHAR2(200),
    date_saisie   DATE          DEFAULT SYSDATE NOT NULL,
    saisi_par     VARCHAR2(50),
    CONSTRAINT fk_absence_etudiant FOREIGN KEY (id_etudiant) REFERENCES ETUDIANTS(id_etudiant),
    CONSTRAINT fk_absence_seance FOREIGN KEY (id_seance) REFERENCES SEANCES(id_seance),
    CONSTRAINT uk_absence UNIQUE (id_etudiant, id_seance),
    CONSTRAINT chk_est_justifiee CHECK (est_justifiee IN (0, 1))
);

-- Table des justificatifs
CREATE TABLE JUSTIFICATIFS (
    id_justificatif NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_absence      NUMBER        NOT NULL,
    type_justificatif VARCHAR2(50) NOT NULL,
    description     VARCHAR2(500),
    fichier_path    VARCHAR2(300),
    date_soumission DATE DEFAULT SYSDATE NOT NULL,
    date_traitement DATE,
    statut          VARCHAR2(20)  DEFAULT 'EN_ATTENTE' NOT NULL,
    traite_par      VARCHAR2(50),
    commentaire     VARCHAR2(500),
    CONSTRAINT fk_justif_absence FOREIGN KEY (id_absence) REFERENCES ABSENCES(id_absence),
    CONSTRAINT chk_type_justif CHECK (type_justificatif IN ('MEDICAL', 'FAMILIAL', 'ADMINISTRATIF', 'AUTRE')),
    CONSTRAINT chk_statut_justif CHECK (statut IN ('EN_ATTENTE', 'ACCEPTE', 'REFUSE'))
);

-- Table de configuration des seuils
CREATE TABLE SEUILS_ABSENCES (
    id_seuil      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_filiere    NUMBER NOT NULL,
    seuil_avertissement NUMBER(5) DEFAULT 3 NOT NULL,
    seuil_exclusion     NUMBER(5) DEFAULT 6 NOT NULL,
    annee_universitaire VARCHAR2(9) NOT NULL,
    CONSTRAINT fk_seuil_filiere FOREIGN KEY (id_filiere) REFERENCES FILIERES(id_filiere),
    CONSTRAINT chk_seuils CHECK (seuil_exclusion > seuil_avertissement),
    CONSTRAINT uk_seuil UNIQUE (id_filiere, annee_universitaire)
);

-- ============================================================
-- ÉTAPE 5 : Table d'audit
-- ============================================================

CREATE TABLE AUDIT_LOG (
    id_audit      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name    VARCHAR2(50)  NOT NULL,
    operation     VARCHAR2(10)  NOT NULL,
    record_id     NUMBER,
    old_values    CLOB,
    new_values    CLOB,
    utilisateur   VARCHAR2(50)  DEFAULT USER,
    date_operation TIMESTAMP    DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT chk_operation CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE'))
);

-- Table des notifications
CREATE TABLE NOTIFICATIONS (
    id_notification NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_etudiant     NUMBER NOT NULL,
    type_notification VARCHAR2(50) NOT NULL,
    message         VARCHAR2(500) NOT NULL,
    est_lue         NUMBER(1) DEFAULT 0 NOT NULL,
    date_creation   TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT fk_notif_etudiant FOREIGN KEY (id_etudiant) REFERENCES ETUDIANTS(id_etudiant),
    CONSTRAINT chk_type_notif CHECK (type_notification IN ('AVERTISSEMENT', 'EXCLUSION', 'JUSTIFICATIF', 'INFO')),
    CONSTRAINT chk_est_lue CHECK (est_lue IN (0, 1))
);

-- ============================================================
-- ÉTAPE 6 : Index pour optimisation
-- ============================================================

-- Index sur les clés étrangères (performance des jointures)
CREATE INDEX idx_groupe_filiere ON GROUPES(id_filiere);
CREATE INDEX idx_etudiant_groupe ON ETUDIANTS(id_groupe);
CREATE INDEX idx_matiere_filiere ON MATIERES(id_filiere);
CREATE INDEX idx_matiere_semestre ON MATIERES(id_semestre);
CREATE INDEX idx_affect_enseignant ON AFFECTATIONS(id_enseignant);
CREATE INDEX idx_affect_matiere ON AFFECTATIONS(id_matiere);
CREATE INDEX idx_affect_groupe ON AFFECTATIONS(id_groupe);
CREATE INDEX idx_seance_matiere ON SEANCES(id_matiere);
CREATE INDEX idx_seance_enseignant ON SEANCES(id_enseignant);
CREATE INDEX idx_seance_groupe ON SEANCES(id_groupe);
CREATE INDEX idx_absence_etudiant ON ABSENCES(id_etudiant);
CREATE INDEX idx_absence_seance ON ABSENCES(id_seance);
CREATE INDEX idx_justif_absence ON JUSTIFICATIFS(id_absence);
CREATE INDEX idx_notif_etudiant ON NOTIFICATIONS(id_etudiant);

-- Index fonctionnels pour les recherches fréquentes
CREATE INDEX idx_seance_date ON SEANCES(date_seance);
CREATE INDEX idx_absence_date ON ABSENCES(date_absence);
CREATE INDEX idx_etudiant_nom ON ETUDIANTS(UPPER(nom), UPPER(prenom));
CREATE INDEX idx_etudiant_statut ON ETUDIANTS(statut);
CREATE INDEX idx_absence_justifiee ON ABSENCES(est_justifiee);
CREATE INDEX idx_justif_statut ON JUSTIFICATIFS(statut);
CREATE INDEX idx_audit_table ON AUDIT_LOG(table_name, date_operation);
CREATE INDEX idx_seance_statut ON SEANCES(statut);

-- ============================================================
-- Fin du script 01
-- ============================================================
COMMIT;

SELECT 'Schema créé avec succès !' AS RESULTAT FROM DUAL;

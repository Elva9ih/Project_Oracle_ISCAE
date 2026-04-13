-- Fix: Create ETUDIANTS without SYSDATE check
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
    CONSTRAINT chk_statut_etudiant CHECK (statut IN ('ACTIF', 'SUSPENDU', 'EXCLU', 'DIPLOME'))
);

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

-- Missing indexes
CREATE INDEX idx_etudiant_groupe ON ETUDIANTS(id_groupe);
CREATE INDEX idx_absence_etudiant ON ABSENCES(id_etudiant);
CREATE INDEX idx_absence_seance ON ABSENCES(id_seance);
CREATE INDEX idx_justif_absence ON JUSTIFICATIFS(id_absence);
CREATE INDEX idx_notif_etudiant ON NOTIFICATIONS(id_etudiant);
CREATE INDEX idx_absence_date ON ABSENCES(date_absence);
CREATE INDEX idx_etudiant_nom ON ETUDIANTS(UPPER(nom), UPPER(prenom));
CREATE INDEX idx_etudiant_statut ON ETUDIANTS(statut);
CREATE INDEX idx_absence_justifiee ON ABSENCES(est_justifiee);
CREATE INDEX idx_justif_statut ON JUSTIFICATIFS(statut);

COMMIT;
SELECT 'Tables fix OK!' AS RESULTAT FROM DUAL;
EXIT;

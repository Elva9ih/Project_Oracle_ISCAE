-- ============================================================
-- PROJET ORACLE : Gestion des Absences Étudiants
-- Script 03 : Triggers (Audit, Cohérence, Automatisation)
-- ============================================================

CONNECT gestion_absences/gestion2025@localhost:1521/XE;

-- ============================================================
-- TRIGGER 1 : Audit des opérations sur ABSENCES
-- Journalisation de chaque INSERT/UPDATE/DELETE
-- ============================================================

CREATE OR REPLACE TRIGGER trg_audit_absences
AFTER INSERT OR UPDATE OR DELETE ON ABSENCES
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(10);
    v_old_vals  CLOB;
    v_new_vals  CLOB;
BEGIN
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_new_vals := 'id_etudiant=' || :NEW.id_etudiant ||
                      ', id_seance=' || :NEW.id_seance ||
                      ', est_justifiee=' || :NEW.est_justifiee ||
                      ', motif=' || :NEW.motif;
        INSERT INTO AUDIT_LOG (table_name, operation, record_id, new_values)
        VALUES ('ABSENCES', v_operation, :NEW.id_absence, v_new_vals);

    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_old_vals := 'est_justifiee=' || :OLD.est_justifiee || ', motif=' || :OLD.motif;
        v_new_vals := 'est_justifiee=' || :NEW.est_justifiee || ', motif=' || :NEW.motif;
        INSERT INTO AUDIT_LOG (table_name, operation, record_id, old_values, new_values)
        VALUES ('ABSENCES', v_operation, :NEW.id_absence, v_old_vals, v_new_vals);

    ELSIF DELETING THEN
        v_operation := 'DELETE';
        v_old_vals := 'id_etudiant=' || :OLD.id_etudiant ||
                      ', id_seance=' || :OLD.id_seance ||
                      ', est_justifiee=' || :OLD.est_justifiee;
        INSERT INTO AUDIT_LOG (table_name, operation, record_id, old_values)
        VALUES ('ABSENCES', v_operation, :OLD.id_absence, v_old_vals);
    END IF;
END;
/

-- ============================================================
-- TRIGGER 2 : Audit des opérations sur ETUDIANTS
-- ============================================================

CREATE OR REPLACE TRIGGER trg_audit_etudiants
AFTER INSERT OR UPDATE OR DELETE ON ETUDIANTS
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(10);
    v_old_vals  CLOB;
    v_new_vals  CLOB;
BEGIN
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_new_vals := 'cne=' || :NEW.cne || ', nom=' || :NEW.nom ||
                      ', prenom=' || :NEW.prenom || ', statut=' || :NEW.statut;
        INSERT INTO AUDIT_LOG (table_name, operation, record_id, new_values)
        VALUES ('ETUDIANTS', v_operation, :NEW.id_etudiant, v_new_vals);

    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_old_vals := 'nom=' || :OLD.nom || ', prenom=' || :OLD.prenom || ', statut=' || :OLD.statut;
        v_new_vals := 'nom=' || :NEW.nom || ', prenom=' || :NEW.prenom || ', statut=' || :NEW.statut;
        INSERT INTO AUDIT_LOG (table_name, operation, record_id, old_values, new_values)
        VALUES ('ETUDIANTS', v_operation, :NEW.id_etudiant, v_old_vals, v_new_vals);

    ELSIF DELETING THEN
        v_operation := 'DELETE';
        v_old_vals := 'cne=' || :OLD.cne || ', nom=' || :OLD.nom || ', prenom=' || :OLD.prenom;
        INSERT INTO AUDIT_LOG (table_name, operation, record_id, old_values)
        VALUES ('ETUDIANTS', v_operation, :OLD.id_etudiant, v_old_vals);
    END IF;
END;
/

-- ============================================================
-- TRIGGER 3 : Audit des justificatifs
-- ============================================================

CREATE OR REPLACE TRIGGER trg_audit_justificatifs
AFTER INSERT OR UPDATE ON JUSTIFICATIFS
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(10);
    v_old_vals  CLOB;
    v_new_vals  CLOB;
BEGIN
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_new_vals := 'id_absence=' || :NEW.id_absence ||
                      ', type=' || :NEW.type_justificatif ||
                      ', statut=' || :NEW.statut;
        INSERT INTO AUDIT_LOG (table_name, operation, record_id, new_values)
        VALUES ('JUSTIFICATIFS', v_operation, :NEW.id_justificatif, v_new_vals);

    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_old_vals := 'statut=' || :OLD.statut;
        v_new_vals := 'statut=' || :NEW.statut || ', traite_par=' || :NEW.traite_par;
        INSERT INTO AUDIT_LOG (table_name, operation, record_id, old_values, new_values)
        VALUES ('JUSTIFICATIFS', v_operation, :NEW.id_justificatif, v_old_vals, v_new_vals);
    END IF;
END;
/

-- ============================================================
-- TRIGGER 4 : Mettre à jour la date de séance dans l'absence
-- Quand une absence est insérée, copier la date de la séance
-- ============================================================

CREATE OR REPLACE TRIGGER trg_absence_date_auto
BEFORE INSERT ON ABSENCES
FOR EACH ROW
DECLARE
    v_date_seance DATE;
BEGIN
    SELECT date_seance INTO v_date_seance
    FROM SEANCES WHERE id_seance = :NEW.id_seance;
    :NEW.date_absence := v_date_seance;
END;
/

-- ============================================================
-- TRIGGER 5 : Empêcher la modification d'une absence déjà justifiée
-- ============================================================

CREATE OR REPLACE TRIGGER trg_protect_absence_justifiee
BEFORE UPDATE OF est_justifiee ON ABSENCES
FOR EACH ROW
BEGIN
    -- On ne peut pas dé-justifier une absence
    IF :OLD.est_justifiee = 1 AND :NEW.est_justifiee = 0 THEN
        RAISE_APPLICATION_ERROR(-20020, 'Impossible de retirer la justification d''une absence déjà justifiée.');
    END IF;
END;
/

-- ============================================================
-- TRIGGER 6 : Empêcher l'insertion d'absence pour étudiant non actif
-- ============================================================

CREATE OR REPLACE TRIGGER trg_check_etudiant_actif
BEFORE INSERT ON ABSENCES
FOR EACH ROW
DECLARE
    v_statut VARCHAR2(20);
BEGIN
    SELECT statut INTO v_statut
    FROM ETUDIANTS WHERE id_etudiant = :NEW.id_etudiant;

    IF v_statut != 'ACTIF' THEN
        RAISE_APPLICATION_ERROR(-20021, 'Impossible de saisir une absence pour un étudiant non actif (statut: ' || v_statut || ').');
    END IF;
END;
/

-- ============================================================
-- TRIGGER 7 : Notification automatique lors du changement de statut
-- ============================================================

CREATE OR REPLACE TRIGGER trg_notif_changement_statut
AFTER UPDATE OF statut ON ETUDIANTS
FOR EACH ROW
BEGIN
    IF :OLD.statut != :NEW.statut THEN
        INSERT INTO NOTIFICATIONS (id_etudiant, type_notification, message)
        VALUES (:NEW.id_etudiant, 'INFO',
                'Votre statut a été modifié de ' || :OLD.statut || ' à ' || :NEW.statut || '.');
    END IF;
END;
/

-- ============================================================
-- TRIGGER 8 : Marquer la séance comme effectuée si des absences sont saisies
-- ============================================================

CREATE OR REPLACE TRIGGER trg_seance_effectuee
AFTER INSERT ON ABSENCES
FOR EACH ROW
BEGIN
    UPDATE SEANCES
    SET statut = 'EFFECTUEE'
    WHERE id_seance = :NEW.id_seance
      AND statut = 'PLANIFIEE';
END;
/

SELECT 'Triggers créés avec succès !' AS RESULTAT FROM DUAL;

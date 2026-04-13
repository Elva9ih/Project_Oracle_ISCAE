-- Trigger 1: Audit ABSENCES
CREATE OR REPLACE TRIGGER trg_audit_absences
AFTER INSERT OR UPDATE OR DELETE ON ABSENCES
FOR EACH ROW
DECLARE
    v_op VARCHAR2(10); v_old CLOB; v_new CLOB;
BEGIN
    IF INSERTING THEN
        v_op := 'INSERT';
        v_new := 'id_etudiant=' || :NEW.id_etudiant || ', id_seance=' || :NEW.id_seance || ', est_justifiee=' || :NEW.est_justifiee;
        INSERT INTO AUDIT_LOG (table_name, operation, record_id, new_values) VALUES ('ABSENCES', v_op, :NEW.id_absence, v_new);
    ELSIF UPDATING THEN
        v_op := 'UPDATE';
        v_old := 'est_justifiee=' || :OLD.est_justifiee || ', motif=' || :OLD.motif;
        v_new := 'est_justifiee=' || :NEW.est_justifiee || ', motif=' || :NEW.motif;
        INSERT INTO AUDIT_LOG (table_name, operation, record_id, old_values, new_values) VALUES ('ABSENCES', v_op, :NEW.id_absence, v_old, v_new);
    ELSIF DELETING THEN
        v_op := 'DELETE';
        v_old := 'id_etudiant=' || :OLD.id_etudiant || ', id_seance=' || :OLD.id_seance;
        INSERT INTO AUDIT_LOG (table_name, operation, record_id, old_values) VALUES ('ABSENCES', v_op, :OLD.id_absence, v_old);
    END IF;
END;
/

-- Trigger 2: Audit ETUDIANTS
CREATE OR REPLACE TRIGGER trg_audit_etudiants
AFTER INSERT OR UPDATE OR DELETE ON ETUDIANTS
FOR EACH ROW
DECLARE
    v_op VARCHAR2(10); v_old CLOB; v_new CLOB;
BEGIN
    IF INSERTING THEN
        v_op := 'INSERT';
        v_new := 'cne=' || :NEW.cne || ', nom=' || :NEW.nom || ', prenom=' || :NEW.prenom || ', statut=' || :NEW.statut;
        INSERT INTO AUDIT_LOG (table_name, operation, record_id, new_values) VALUES ('ETUDIANTS', v_op, :NEW.id_etudiant, v_new);
    ELSIF UPDATING THEN
        v_op := 'UPDATE';
        v_old := 'nom=' || :OLD.nom || ', statut=' || :OLD.statut;
        v_new := 'nom=' || :NEW.nom || ', statut=' || :NEW.statut;
        INSERT INTO AUDIT_LOG (table_name, operation, record_id, old_values, new_values) VALUES ('ETUDIANTS', v_op, :NEW.id_etudiant, v_old, v_new);
    ELSIF DELETING THEN
        v_op := 'DELETE';
        v_old := 'cne=' || :OLD.cne || ', nom=' || :OLD.nom;
        INSERT INTO AUDIT_LOG (table_name, operation, record_id, old_values) VALUES ('ETUDIANTS', v_op, :OLD.id_etudiant, v_old);
    END IF;
END;
/

-- Trigger 3: Audit JUSTIFICATIFS
CREATE OR REPLACE TRIGGER trg_audit_justificatifs
AFTER INSERT OR UPDATE ON JUSTIFICATIFS
FOR EACH ROW
DECLARE
    v_op VARCHAR2(10); v_old CLOB; v_new CLOB;
BEGIN
    IF INSERTING THEN
        v_new := 'id_absence=' || :NEW.id_absence || ', type=' || :NEW.type_justificatif || ', statut=' || :NEW.statut;
        INSERT INTO AUDIT_LOG (table_name, operation, record_id, new_values) VALUES ('JUSTIFICATIFS', 'INSERT', :NEW.id_justificatif, v_new);
    ELSIF UPDATING THEN
        v_old := 'statut=' || :OLD.statut;
        v_new := 'statut=' || :NEW.statut || ', traite_par=' || :NEW.traite_par;
        INSERT INTO AUDIT_LOG (table_name, operation, record_id, old_values, new_values) VALUES ('JUSTIFICATIFS', 'UPDATE', :NEW.id_justificatif, v_old, v_new);
    END IF;
END;
/

-- Trigger 4: Auto-set date absence from seance
CREATE OR REPLACE TRIGGER trg_absence_date_auto
BEFORE INSERT ON ABSENCES
FOR EACH ROW
DECLARE
    v_date DATE;
BEGIN
    SELECT date_seance INTO v_date FROM SEANCES WHERE id_seance = :NEW.id_seance;
    :NEW.date_absence := v_date;
END;
/

-- Trigger 5: Protect justified absences
CREATE OR REPLACE TRIGGER trg_protect_absence_justifiee
BEFORE UPDATE OF est_justifiee ON ABSENCES
FOR EACH ROW
BEGIN
    IF :OLD.est_justifiee = 1 AND :NEW.est_justifiee = 0 THEN
        RAISE_APPLICATION_ERROR(-20020, 'Impossible de retirer la justification.');
    END IF;
END;
/

-- Trigger 6: Check student is active before absence
CREATE OR REPLACE TRIGGER trg_check_etudiant_actif
BEFORE INSERT ON ABSENCES
FOR EACH ROW
DECLARE
    v_statut VARCHAR2(20);
BEGIN
    SELECT statut INTO v_statut FROM ETUDIANTS WHERE id_etudiant = :NEW.id_etudiant;
    IF v_statut != 'ACTIF' THEN
        RAISE_APPLICATION_ERROR(-20021, 'Etudiant non actif (statut: ' || v_statut || ').');
    END IF;
END;
/

-- Trigger 7: Notification on status change
CREATE OR REPLACE TRIGGER trg_notif_changement_statut
AFTER UPDATE OF statut ON ETUDIANTS
FOR EACH ROW
BEGIN
    IF :OLD.statut != :NEW.statut THEN
        INSERT INTO NOTIFICATIONS (id_etudiant, type_notification, message)
        VALUES (:NEW.id_etudiant, 'INFO', 'Statut modifie de ' || :OLD.statut || ' a ' || :NEW.statut || '.');
    END IF;
END;
/

-- Trigger 8: Auto mark seance as done
CREATE OR REPLACE TRIGGER trg_seance_effectuee
AFTER INSERT ON ABSENCES
FOR EACH ROW
BEGIN
    UPDATE SEANCES SET statut = 'EFFECTUEE' WHERE id_seance = :NEW.id_seance AND statut = 'PLANIFIEE';
END;
/

SELECT 'Triggers crees avec succes !' AS RESULTAT FROM DUAL;
EXIT;

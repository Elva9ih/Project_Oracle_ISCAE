SET SERVEROUTPUT ON;

CREATE OR REPLACE PACKAGE PKG_ABSENCES AS
    FUNCTION get_nb_absences(p_id_etudiant NUMBER, p_id_semestre NUMBER DEFAULT NULL) RETURN NUMBER;
    FUNCTION get_nb_absences_non_justifiees(p_id_etudiant NUMBER, p_id_semestre NUMBER DEFAULT NULL) RETURN NUMBER;
    FUNCTION get_taux_absence(p_id_etudiant NUMBER, p_id_semestre NUMBER DEFAULT NULL) RETURN NUMBER;
    FUNCTION est_en_depassement(p_id_etudiant NUMBER) RETURN VARCHAR2;
    FUNCTION get_statut_etudiant_absences(p_id_etudiant NUMBER) RETURN VARCHAR2;
    PROCEDURE marquer_absence(p_id_etudiant NUMBER, p_id_seance NUMBER, p_motif VARCHAR2 DEFAULT NULL, p_saisi_par VARCHAR2 DEFAULT USER);
    PROCEDURE marquer_absences_bulk(p_id_seance NUMBER, p_ids_etudiants VARCHAR2, p_saisi_par VARCHAR2 DEFAULT USER);
    PROCEDURE justifier_absence(p_id_absence NUMBER, p_type_justificatif VARCHAR2, p_description VARCHAR2, p_fichier_path VARCHAR2 DEFAULT NULL);
    PROCEDURE traiter_justificatif(p_id_justificatif NUMBER, p_statut VARCHAR2, p_commentaire VARCHAR2 DEFAULT NULL, p_traite_par VARCHAR2 DEFAULT USER);
    PROCEDURE verifier_seuils_etudiant(p_id_etudiant NUMBER);
    PROCEDURE cloturer_semestre(p_id_semestre NUMBER, p_traite_par VARCHAR2 DEFAULT USER);
    e_absence_existe    EXCEPTION;
    e_etudiant_inactif  EXCEPTION;
    e_seance_non_trouvee EXCEPTION;
    e_seuil_depasse     EXCEPTION;
END PKG_ABSENCES;
/

CREATE OR REPLACE PACKAGE BODY PKG_ABSENCES AS

    FUNCTION get_nb_absences(p_id_etudiant NUMBER, p_id_semestre NUMBER DEFAULT NULL) RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        IF p_id_semestre IS NULL THEN
            SELECT COUNT(*) INTO v_count FROM ABSENCES WHERE id_etudiant = p_id_etudiant;
        ELSE
            SELECT COUNT(*) INTO v_count FROM ABSENCES a
            JOIN SEANCES s ON a.id_seance = s.id_seance
            JOIN MATIERES m ON s.id_matiere = m.id_matiere
            WHERE a.id_etudiant = p_id_etudiant AND m.id_semestre = p_id_semestre;
        END IF;
        RETURN v_count;
    END get_nb_absences;

    FUNCTION get_nb_absences_non_justifiees(p_id_etudiant NUMBER, p_id_semestre NUMBER DEFAULT NULL) RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        IF p_id_semestre IS NULL THEN
            SELECT COUNT(*) INTO v_count FROM ABSENCES WHERE id_etudiant = p_id_etudiant AND est_justifiee = 0;
        ELSE
            SELECT COUNT(*) INTO v_count FROM ABSENCES a
            JOIN SEANCES s ON a.id_seance = s.id_seance
            JOIN MATIERES m ON s.id_matiere = m.id_matiere
            WHERE a.id_etudiant = p_id_etudiant AND a.est_justifiee = 0 AND m.id_semestre = p_id_semestre;
        END IF;
        RETURN v_count;
    END get_nb_absences_non_justifiees;

    FUNCTION get_taux_absence(p_id_etudiant NUMBER, p_id_semestre NUMBER DEFAULT NULL) RETURN NUMBER IS
        v_total NUMBER; v_abs NUMBER;
    BEGIN
        IF p_id_semestre IS NULL THEN
            SELECT COUNT(*) INTO v_total FROM SEANCES s
            JOIN ETUDIANTS e ON s.id_groupe = e.id_groupe
            WHERE e.id_etudiant = p_id_etudiant AND s.statut = 'EFFECTUEE';
        ELSE
            SELECT COUNT(*) INTO v_total FROM SEANCES s
            JOIN ETUDIANTS e ON s.id_groupe = e.id_groupe
            JOIN MATIERES m ON s.id_matiere = m.id_matiere
            WHERE e.id_etudiant = p_id_etudiant AND s.statut = 'EFFECTUEE' AND m.id_semestre = p_id_semestre;
        END IF;
        IF v_total = 0 THEN RETURN 0; END IF;
        v_abs := get_nb_absences(p_id_etudiant, p_id_semestre);
        RETURN ROUND((v_abs / v_total) * 100, 2);
    END get_taux_absence;

    FUNCTION est_en_depassement(p_id_etudiant NUMBER) RETURN VARCHAR2 IS
        v_nb NUMBER; v_seuil_a NUMBER; v_seuil_e NUMBER; v_id_f NUMBER;
    BEGIN
        SELECT g.id_filiere INTO v_id_f FROM ETUDIANTS e JOIN GROUPES g ON e.id_groupe = g.id_groupe WHERE e.id_etudiant = p_id_etudiant;
        BEGIN
            SELECT seuil_avertissement, seuil_exclusion INTO v_seuil_a, v_seuil_e
            FROM SEUILS_ABSENCES WHERE id_filiere = v_id_f AND ROWNUM = 1;
        EXCEPTION WHEN NO_DATA_FOUND THEN v_seuil_a := 3; v_seuil_e := 6;
        END;
        v_nb := get_nb_absences_non_justifiees(p_id_etudiant);
        IF v_nb >= v_seuil_e THEN RETURN 'EXCLUSION';
        ELSIF v_nb >= v_seuil_a THEN RETURN 'AVERTISSEMENT';
        ELSE RETURN 'NORMAL';
        END IF;
    END est_en_depassement;

    FUNCTION get_statut_etudiant_absences(p_id_etudiant NUMBER) RETURN VARCHAR2 IS
        v_taux NUMBER; v_dep VARCHAR2(20);
    BEGIN
        v_taux := get_taux_absence(p_id_etudiant);
        v_dep := est_en_depassement(p_id_etudiant);
        IF v_dep = 'EXCLUSION' THEN RETURN 'CRITIQUE (taux: ' || v_taux || '%)';
        ELSIF v_dep = 'AVERTISSEMENT' THEN RETURN 'ATTENTION (taux: ' || v_taux || '%)';
        ELSE RETURN 'NORMAL (taux: ' || v_taux || '%)';
        END IF;
    END get_statut_etudiant_absences;

    PROCEDURE marquer_absence(p_id_etudiant NUMBER, p_id_seance NUMBER, p_motif VARCHAR2 DEFAULT NULL, p_saisi_par VARCHAR2 DEFAULT USER) IS
        v_statut VARCHAR2(20); v_count NUMBER; v_date DATE;
    BEGIN
        SELECT statut INTO v_statut FROM ETUDIANTS WHERE id_etudiant = p_id_etudiant;
        IF v_statut != 'ACTIF' THEN RAISE e_etudiant_inactif; END IF;
        BEGIN SELECT date_seance INTO v_date FROM SEANCES WHERE id_seance = p_id_seance;
        EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_seance_non_trouvee; END;
        SELECT COUNT(*) INTO v_count FROM ABSENCES WHERE id_etudiant = p_id_etudiant AND id_seance = p_id_seance;
        IF v_count > 0 THEN RAISE e_absence_existe; END IF;
        INSERT INTO ABSENCES (id_etudiant, id_seance, date_absence, motif, saisi_par) VALUES (p_id_etudiant, p_id_seance, v_date, p_motif, p_saisi_par);
        verifier_seuils_etudiant(p_id_etudiant);
        COMMIT;
    EXCEPTION
        WHEN e_absence_existe THEN RAISE_APPLICATION_ERROR(-20001, 'Absence existe deja.');
        WHEN e_etudiant_inactif THEN RAISE_APPLICATION_ERROR(-20002, 'Etudiant non actif.');
        WHEN e_seance_non_trouvee THEN RAISE_APPLICATION_ERROR(-20003, 'Seance non trouvee.');
        WHEN OTHERS THEN ROLLBACK; RAISE;
    END marquer_absence;

    PROCEDURE marquer_absences_bulk(p_id_seance NUMBER, p_ids_etudiants VARCHAR2, p_saisi_par VARCHAR2 DEFAULT USER) IS
        v_id VARCHAR2(20); v_pos NUMBER; v_list VARCHAR2(4000) := p_ids_etudiants || ',';
        v_errors NUMBER := 0; v_success NUMBER := 0;
    BEGIN
        SAVEPOINT sp_bulk;
        WHILE INSTR(v_list, ',') > 0 LOOP
            v_pos := INSTR(v_list, ',');
            v_id := TRIM(SUBSTR(v_list, 1, v_pos - 1));
            v_list := SUBSTR(v_list, v_pos + 1);
            IF v_id IS NOT NULL THEN
                BEGIN marquer_absence(TO_NUMBER(v_id), p_id_seance, NULL, p_saisi_par); v_success := v_success + 1;
                EXCEPTION WHEN OTHERS THEN v_errors := v_errors + 1; END;
            END IF;
        END LOOP;
        IF v_success = 0 AND v_errors > 0 THEN ROLLBACK TO sp_bulk; RAISE_APPLICATION_ERROR(-20010, 'Aucune absence enregistree.'); END IF;
        COMMIT;
    END marquer_absences_bulk;

    PROCEDURE justifier_absence(p_id_absence NUMBER, p_type_justificatif VARCHAR2, p_description VARCHAR2, p_fichier_path VARCHAR2 DEFAULT NULL) IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM ABSENCES WHERE id_absence = p_id_absence;
        IF v_count = 0 THEN RAISE_APPLICATION_ERROR(-20004, 'Absence non trouvee.'); END IF;
        INSERT INTO JUSTIFICATIFS (id_absence, type_justificatif, description, fichier_path) VALUES (p_id_absence, p_type_justificatif, p_description, p_fichier_path);
        COMMIT;
    END justifier_absence;

    PROCEDURE traiter_justificatif(p_id_justificatif NUMBER, p_statut VARCHAR2, p_commentaire VARCHAR2 DEFAULT NULL, p_traite_par VARCHAR2 DEFAULT USER) IS
        v_id_absence NUMBER;
    BEGIN
        IF p_statut NOT IN ('ACCEPTE', 'REFUSE') THEN RAISE_APPLICATION_ERROR(-20005, 'Statut invalide.'); END IF;
        UPDATE JUSTIFICATIFS SET statut = p_statut, commentaire = p_commentaire, traite_par = p_traite_par, date_traitement = SYSDATE
        WHERE id_justificatif = p_id_justificatif RETURNING id_absence INTO v_id_absence;
        IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20006, 'Justificatif non trouve.'); END IF;
        IF p_statut = 'ACCEPTE' THEN
            UPDATE ABSENCES SET est_justifiee = 1 WHERE id_absence = v_id_absence;
            DECLARE v_id_e NUMBER;
            BEGIN SELECT id_etudiant INTO v_id_e FROM ABSENCES WHERE id_absence = v_id_absence; verifier_seuils_etudiant(v_id_e); END;
        END IF;
        COMMIT;
    END traiter_justificatif;

    PROCEDURE verifier_seuils_etudiant(p_id_etudiant NUMBER) IS
        v_dep VARCHAR2(20); v_nb NUMBER; v_msg VARCHAR2(500);
    BEGIN
        v_dep := est_en_depassement(p_id_etudiant);
        v_nb := get_nb_absences_non_justifiees(p_id_etudiant);
        IF v_dep = 'EXCLUSION' THEN
            UPDATE ETUDIANTS SET statut = 'EXCLU' WHERE id_etudiant = p_id_etudiant;
            v_msg := 'EXCLUSION: ' || v_nb || ' absences non justifiees. Statut change a EXCLU.';
            INSERT INTO NOTIFICATIONS (id_etudiant, type_notification, message) VALUES (p_id_etudiant, 'EXCLUSION', v_msg);
        ELSIF v_dep = 'AVERTISSEMENT' THEN
            v_msg := 'AVERTISSEMENT: ' || v_nb || ' absences non justifiees.';
            INSERT INTO NOTIFICATIONS (id_etudiant, type_notification, message) VALUES (p_id_etudiant, 'AVERTISSEMENT', v_msg);
        END IF;
    END verifier_seuils_etudiant;

    PROCEDURE cloturer_semestre(p_id_semestre NUMBER, p_traite_par VARCHAR2 DEFAULT USER) IS
    BEGIN
        SAVEPOINT sp_cloture;
        UPDATE SEANCES SET statut = 'EFFECTUEE' WHERE statut = 'PLANIFIEE'
            AND id_matiere IN (SELECT id_matiere FROM MATIERES WHERE id_semestre = p_id_semestre);
        UPDATE JUSTIFICATIFS SET statut = 'REFUSE', commentaire = 'Cloture automatique', traite_par = p_traite_par, date_traitement = SYSDATE
        WHERE statut = 'EN_ATTENTE' AND id_absence IN (
            SELECT a.id_absence FROM ABSENCES a JOIN SEANCES s ON a.id_seance = s.id_seance
            JOIN MATIERES m ON s.id_matiere = m.id_matiere WHERE m.id_semestre = p_id_semestre);
        COMMIT;
    EXCEPTION WHEN OTHERS THEN ROLLBACK TO sp_cloture; RAISE;
    END cloturer_semestre;

END PKG_ABSENCES;
/

-- Package PKG_STATISTIQUES
CREATE OR REPLACE PACKAGE PKG_STATISTIQUES AS
    FUNCTION get_top_absents(p_id_groupe NUMBER DEFAULT NULL, p_limit NUMBER DEFAULT 10) RETURN SYS_REFCURSOR;
    FUNCTION get_stats_par_matiere(p_id_semestre NUMBER DEFAULT NULL) RETURN SYS_REFCURSOR;
    FUNCTION get_stats_par_groupe(p_annee VARCHAR2 DEFAULT NULL) RETURN SYS_REFCURSOR;
    FUNCTION get_evolution_mensuelle(p_id_groupe NUMBER DEFAULT NULL) RETURN SYS_REFCURSOR;
    PROCEDURE generer_rapport_absences(p_id_groupe NUMBER, p_date_debut DATE, p_date_fin DATE, p_resultat OUT SYS_REFCURSOR);
END PKG_STATISTIQUES;
/

CREATE OR REPLACE PACKAGE BODY PKG_STATISTIQUES AS

    FUNCTION get_top_absents(p_id_groupe NUMBER DEFAULT NULL, p_limit NUMBER DEFAULT 10) RETURN SYS_REFCURSOR IS
        v_c SYS_REFCURSOR;
    BEGIN
        OPEN v_c FOR
            SELECT e.id_etudiant, e.cne, e.nom, e.prenom, e.statut,
                   COUNT(a.id_absence) AS total_absences,
                   SUM(CASE WHEN a.est_justifiee = 0 THEN 1 ELSE 0 END) AS absences_non_justifiees
            FROM ETUDIANTS e LEFT JOIN ABSENCES a ON e.id_etudiant = a.id_etudiant
            WHERE (p_id_groupe IS NULL OR e.id_groupe = p_id_groupe)
            GROUP BY e.id_etudiant, e.cne, e.nom, e.prenom, e.statut
            ORDER BY total_absences DESC FETCH FIRST p_limit ROWS ONLY;
        RETURN v_c;
    END get_top_absents;

    FUNCTION get_stats_par_matiere(p_id_semestre NUMBER DEFAULT NULL) RETURN SYS_REFCURSOR IS
        v_c SYS_REFCURSOR;
    BEGIN
        OPEN v_c FOR
            SELECT m.id_matiere, m.code_matiere, m.nom_matiere, COUNT(DISTINCT s.id_seance) AS nb_seances, COUNT(a.id_absence) AS total_absences
            FROM MATIERES m LEFT JOIN SEANCES s ON m.id_matiere = s.id_matiere LEFT JOIN ABSENCES a ON s.id_seance = a.id_seance
            WHERE (p_id_semestre IS NULL OR m.id_semestre = p_id_semestre)
            GROUP BY m.id_matiere, m.code_matiere, m.nom_matiere ORDER BY total_absences DESC;
        RETURN v_c;
    END get_stats_par_matiere;

    FUNCTION get_stats_par_groupe(p_annee VARCHAR2 DEFAULT NULL) RETURN SYS_REFCURSOR IS
        v_c SYS_REFCURSOR;
    BEGIN
        OPEN v_c FOR
            SELECT g.id_groupe, g.code_groupe, g.nom_groupe, f.nom_filiere, COUNT(DISTINCT e.id_etudiant) AS nb_etudiants, COUNT(a.id_absence) AS total_absences
            FROM GROUPES g JOIN FILIERES f ON g.id_filiere = f.id_filiere LEFT JOIN ETUDIANTS e ON g.id_groupe = e.id_groupe LEFT JOIN ABSENCES a ON e.id_etudiant = a.id_etudiant
            WHERE (p_annee IS NULL OR g.annee_universitaire = p_annee)
            GROUP BY g.id_groupe, g.code_groupe, g.nom_groupe, f.nom_filiere ORDER BY total_absences DESC;
        RETURN v_c;
    END get_stats_par_groupe;

    FUNCTION get_evolution_mensuelle(p_id_groupe NUMBER DEFAULT NULL) RETURN SYS_REFCURSOR IS
        v_c SYS_REFCURSOR;
    BEGIN
        OPEN v_c FOR
            SELECT TO_CHAR(a.date_absence, 'YYYY-MM') AS mois, COUNT(*) AS total_absences,
                   SUM(CASE WHEN a.est_justifiee = 0 THEN 1 ELSE 0 END) AS non_justifiees,
                   SUM(CASE WHEN a.est_justifiee = 1 THEN 1 ELSE 0 END) AS justifiees
            FROM ABSENCES a JOIN ETUDIANTS e ON a.id_etudiant = e.id_etudiant
            WHERE (p_id_groupe IS NULL OR e.id_groupe = p_id_groupe)
            GROUP BY TO_CHAR(a.date_absence, 'YYYY-MM') ORDER BY mois;
        RETURN v_c;
    END get_evolution_mensuelle;

    PROCEDURE generer_rapport_absences(p_id_groupe NUMBER, p_date_debut DATE, p_date_fin DATE, p_resultat OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_resultat FOR
            SELECT e.cne, e.nom, e.prenom, m.nom_matiere, s.date_seance, s.heure_debut, s.heure_fin,
                   CASE WHEN a.est_justifiee = 1 THEN 'Oui' ELSE 'Non' END AS justifiee, a.motif
            FROM ABSENCES a JOIN ETUDIANTS e ON a.id_etudiant = e.id_etudiant
            JOIN SEANCES s ON a.id_seance = s.id_seance JOIN MATIERES m ON s.id_matiere = m.id_matiere
            WHERE e.id_groupe = p_id_groupe AND a.date_absence BETWEEN p_date_debut AND p_date_fin
            ORDER BY e.nom, e.prenom, a.date_absence;
    END generer_rapport_absences;

END PKG_STATISTIQUES;
/

SELECT 'Packages PL/SQL crees avec succes !' AS RESULTAT FROM DUAL;
EXIT;

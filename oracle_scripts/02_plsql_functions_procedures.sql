-- ============================================================
-- PROJET ORACLE : Gestion des Absences Étudiants
-- Script 02 : Fonctions, Procédures et Packages PL/SQL
-- ============================================================

CONNECT gestion_absences/gestion2025@localhost:1521/XE;

-- ============================================================
-- PACKAGE : PKG_ABSENCES
-- Gestion complète des absences
-- ============================================================

CREATE OR REPLACE PACKAGE PKG_ABSENCES AS

    -- Fonctions
    FUNCTION get_nb_absences(p_id_etudiant NUMBER, p_id_semestre NUMBER DEFAULT NULL) RETURN NUMBER;
    FUNCTION get_nb_absences_non_justifiees(p_id_etudiant NUMBER, p_id_semestre NUMBER DEFAULT NULL) RETURN NUMBER;
    FUNCTION get_taux_absence(p_id_etudiant NUMBER, p_id_semestre NUMBER DEFAULT NULL) RETURN NUMBER;
    FUNCTION est_en_depassement(p_id_etudiant NUMBER) RETURN VARCHAR2;
    FUNCTION get_statut_etudiant_absences(p_id_etudiant NUMBER) RETURN VARCHAR2;

    -- Procédures
    PROCEDURE marquer_absence(
        p_id_etudiant NUMBER,
        p_id_seance   NUMBER,
        p_motif       VARCHAR2 DEFAULT NULL,
        p_saisi_par   VARCHAR2 DEFAULT USER
    );

    PROCEDURE marquer_absences_bulk(
        p_id_seance     NUMBER,
        p_ids_etudiants VARCHAR2, -- liste CSV des IDs
        p_saisi_par     VARCHAR2 DEFAULT USER
    );

    PROCEDURE justifier_absence(
        p_id_absence        NUMBER,
        p_type_justificatif VARCHAR2,
        p_description       VARCHAR2,
        p_fichier_path      VARCHAR2 DEFAULT NULL
    );

    PROCEDURE traiter_justificatif(
        p_id_justificatif NUMBER,
        p_statut          VARCHAR2,
        p_commentaire     VARCHAR2 DEFAULT NULL,
        p_traite_par      VARCHAR2 DEFAULT USER
    );

    PROCEDURE verifier_seuils_etudiant(p_id_etudiant NUMBER);

    PROCEDURE cloturer_semestre(
        p_id_semestre NUMBER,
        p_traite_par  VARCHAR2 DEFAULT USER
    );

    -- Exceptions personnalisées
    e_absence_existe    EXCEPTION;
    e_etudiant_inactif  EXCEPTION;
    e_seance_non_trouvee EXCEPTION;
    e_seuil_depasse     EXCEPTION;

END PKG_ABSENCES;
/

CREATE OR REPLACE PACKAGE BODY PKG_ABSENCES AS

    -- ========================================================
    -- FONCTION : Nombre total d'absences d'un étudiant
    -- ========================================================
    FUNCTION get_nb_absences(p_id_etudiant NUMBER, p_id_semestre NUMBER DEFAULT NULL) RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        IF p_id_semestre IS NULL THEN
            SELECT COUNT(*) INTO v_count
            FROM ABSENCES
            WHERE id_etudiant = p_id_etudiant;
        ELSE
            SELECT COUNT(*) INTO v_count
            FROM ABSENCES a
            JOIN SEANCES s ON a.id_seance = s.id_seance
            JOIN MATIERES m ON s.id_matiere = m.id_matiere
            WHERE a.id_etudiant = p_id_etudiant
              AND m.id_semestre = p_id_semestre;
        END IF;
        RETURN v_count;
    END get_nb_absences;

    -- ========================================================
    -- FONCTION : Nombre d'absences non justifiées
    -- ========================================================
    FUNCTION get_nb_absences_non_justifiees(p_id_etudiant NUMBER, p_id_semestre NUMBER DEFAULT NULL) RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        IF p_id_semestre IS NULL THEN
            SELECT COUNT(*) INTO v_count
            FROM ABSENCES
            WHERE id_etudiant = p_id_etudiant
              AND est_justifiee = 0;
        ELSE
            SELECT COUNT(*) INTO v_count
            FROM ABSENCES a
            JOIN SEANCES s ON a.id_seance = s.id_seance
            JOIN MATIERES m ON s.id_matiere = m.id_matiere
            WHERE a.id_etudiant = p_id_etudiant
              AND a.est_justifiee = 0
              AND m.id_semestre = p_id_semestre;
        END IF;
        RETURN v_count;
    END get_nb_absences_non_justifiees;

    -- ========================================================
    -- FONCTION : Taux d'absence en pourcentage
    -- ========================================================
    FUNCTION get_taux_absence(p_id_etudiant NUMBER, p_id_semestre NUMBER DEFAULT NULL) RETURN NUMBER IS
        v_total_seances NUMBER;
        v_nb_absences   NUMBER;
    BEGIN
        IF p_id_semestre IS NULL THEN
            SELECT COUNT(*) INTO v_total_seances
            FROM SEANCES s
            JOIN ETUDIANTS e ON s.id_groupe = e.id_groupe
            WHERE e.id_etudiant = p_id_etudiant
              AND s.statut = 'EFFECTUEE';
        ELSE
            SELECT COUNT(*) INTO v_total_seances
            FROM SEANCES s
            JOIN ETUDIANTS e ON s.id_groupe = e.id_groupe
            JOIN MATIERES m ON s.id_matiere = m.id_matiere
            WHERE e.id_etudiant = p_id_etudiant
              AND s.statut = 'EFFECTUEE'
              AND m.id_semestre = p_id_semestre;
        END IF;

        IF v_total_seances = 0 THEN
            RETURN 0;
        END IF;

        v_nb_absences := get_nb_absences(p_id_etudiant, p_id_semestre);
        RETURN ROUND((v_nb_absences / v_total_seances) * 100, 2);
    END get_taux_absence;

    -- ========================================================
    -- FONCTION : Vérifier si l'étudiant dépasse le seuil
    -- ========================================================
    FUNCTION est_en_depassement(p_id_etudiant NUMBER) RETURN VARCHAR2 IS
        v_nb_non_just NUMBER;
        v_seuil_excl  NUMBER;
        v_seuil_avert NUMBER;
        v_id_filiere  NUMBER;
    BEGIN
        -- Récupérer la filière de l'étudiant
        SELECT g.id_filiere INTO v_id_filiere
        FROM ETUDIANTS e
        JOIN GROUPES g ON e.id_groupe = g.id_groupe
        WHERE e.id_etudiant = p_id_etudiant;

        -- Récupérer les seuils
        BEGIN
            SELECT seuil_avertissement, seuil_exclusion
            INTO v_seuil_avert, v_seuil_excl
            FROM SEUILS_ABSENCES
            WHERE id_filiere = v_id_filiere
              AND ROWNUM = 1
            ORDER BY annee_universitaire DESC;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_seuil_avert := 3;
                v_seuil_excl := 6;
        END;

        v_nb_non_just := get_nb_absences_non_justifiees(p_id_etudiant);

        IF v_nb_non_just >= v_seuil_excl THEN
            RETURN 'EXCLUSION';
        ELSIF v_nb_non_just >= v_seuil_avert THEN
            RETURN 'AVERTISSEMENT';
        ELSE
            RETURN 'NORMAL';
        END IF;
    END est_en_depassement;

    -- ========================================================
    -- FONCTION : Statut global de l'étudiant
    -- ========================================================
    FUNCTION get_statut_etudiant_absences(p_id_etudiant NUMBER) RETURN VARCHAR2 IS
        v_taux NUMBER;
        v_depassement VARCHAR2(20);
    BEGIN
        v_taux := get_taux_absence(p_id_etudiant);
        v_depassement := est_en_depassement(p_id_etudiant);

        IF v_depassement = 'EXCLUSION' THEN
            RETURN 'CRITIQUE - Seuil d''exclusion atteint (taux: ' || v_taux || '%)';
        ELSIF v_depassement = 'AVERTISSEMENT' THEN
            RETURN 'ATTENTION - Seuil d''avertissement atteint (taux: ' || v_taux || '%)';
        ELSE
            RETURN 'NORMAL (taux: ' || v_taux || '%)';
        END IF;
    END get_statut_etudiant_absences;

    -- ========================================================
    -- PROCÉDURE : Marquer une absence individuelle
    -- ========================================================
    PROCEDURE marquer_absence(
        p_id_etudiant NUMBER,
        p_id_seance   NUMBER,
        p_motif       VARCHAR2 DEFAULT NULL,
        p_saisi_par   VARCHAR2 DEFAULT USER
    ) IS
        v_statut_etudiant VARCHAR2(20);
        v_count NUMBER;
        v_date_seance DATE;
    BEGIN
        -- Vérifier que l'étudiant est actif
        SELECT statut INTO v_statut_etudiant
        FROM ETUDIANTS WHERE id_etudiant = p_id_etudiant;

        IF v_statut_etudiant != 'ACTIF' THEN
            RAISE e_etudiant_inactif;
        END IF;

        -- Vérifier que la séance existe
        BEGIN
            SELECT date_seance INTO v_date_seance
            FROM SEANCES WHERE id_seance = p_id_seance;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE e_seance_non_trouvee;
        END;

        -- Vérifier que l'absence n'existe pas déjà
        SELECT COUNT(*) INTO v_count
        FROM ABSENCES
        WHERE id_etudiant = p_id_etudiant AND id_seance = p_id_seance;

        IF v_count > 0 THEN
            RAISE e_absence_existe;
        END IF;

        -- Insérer l'absence
        INSERT INTO ABSENCES (id_etudiant, id_seance, date_absence, motif, saisi_par)
        VALUES (p_id_etudiant, p_id_seance, v_date_seance, p_motif, p_saisi_par);

        -- Vérifier les seuils après insertion
        verifier_seuils_etudiant(p_id_etudiant);

        COMMIT;

    EXCEPTION
        WHEN e_absence_existe THEN
            RAISE_APPLICATION_ERROR(-20001, 'Cette absence existe déjà pour cet étudiant et cette séance.');
        WHEN e_etudiant_inactif THEN
            RAISE_APPLICATION_ERROR(-20002, 'L''étudiant n''est pas actif (statut: ' || v_statut_etudiant || ').');
        WHEN e_seance_non_trouvee THEN
            RAISE_APPLICATION_ERROR(-20003, 'La séance spécifiée n''existe pas.');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END marquer_absence;

    -- ========================================================
    -- PROCÉDURE : Marquer absences en masse (bulk)
    -- ========================================================
    PROCEDURE marquer_absences_bulk(
        p_id_seance     NUMBER,
        p_ids_etudiants VARCHAR2,
        p_saisi_par     VARCHAR2 DEFAULT USER
    ) IS
        v_id VARCHAR2(20);
        v_pos NUMBER;
        v_list VARCHAR2(4000) := p_ids_etudiants || ',';
        v_id_etudiant NUMBER;
        v_errors NUMBER := 0;
        v_success NUMBER := 0;
    BEGIN
        SAVEPOINT sp_bulk_absences;

        WHILE INSTR(v_list, ',') > 0 LOOP
            v_pos := INSTR(v_list, ',');
            v_id := TRIM(SUBSTR(v_list, 1, v_pos - 1));
            v_list := SUBSTR(v_list, v_pos + 1);

            IF v_id IS NOT NULL THEN
                BEGIN
                    v_id_etudiant := TO_NUMBER(v_id);
                    marquer_absence(v_id_etudiant, p_id_seance, NULL, p_saisi_par);
                    v_success := v_success + 1;
                EXCEPTION
                    WHEN OTHERS THEN
                        v_errors := v_errors + 1;
                END;
            END IF;
        END LOOP;

        IF v_success = 0 AND v_errors > 0 THEN
            ROLLBACK TO sp_bulk_absences;
            RAISE_APPLICATION_ERROR(-20010, 'Aucune absence n''a pu être enregistrée. Erreurs: ' || v_errors);
        END IF;

        COMMIT;
    END marquer_absences_bulk;

    -- ========================================================
    -- PROCÉDURE : Justifier une absence
    -- ========================================================
    PROCEDURE justifier_absence(
        p_id_absence        NUMBER,
        p_type_justificatif VARCHAR2,
        p_description       VARCHAR2,
        p_fichier_path      VARCHAR2 DEFAULT NULL
    ) IS
        v_count NUMBER;
    BEGIN
        -- Vérifier que l'absence existe
        SELECT COUNT(*) INTO v_count FROM ABSENCES WHERE id_absence = p_id_absence;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20004, 'L''absence spécifiée n''existe pas.');
        END IF;

        -- Insérer le justificatif
        INSERT INTO JUSTIFICATIFS (id_absence, type_justificatif, description, fichier_path)
        VALUES (p_id_absence, p_type_justificatif, p_description, p_fichier_path);

        COMMIT;
    END justifier_absence;

    -- ========================================================
    -- PROCÉDURE : Traiter un justificatif (accepter/refuser)
    -- ========================================================
    PROCEDURE traiter_justificatif(
        p_id_justificatif NUMBER,
        p_statut          VARCHAR2,
        p_commentaire     VARCHAR2 DEFAULT NULL,
        p_traite_par      VARCHAR2 DEFAULT USER
    ) IS
        v_id_absence NUMBER;
    BEGIN
        IF p_statut NOT IN ('ACCEPTE', 'REFUSE') THEN
            RAISE_APPLICATION_ERROR(-20005, 'Le statut doit être ACCEPTE ou REFUSE.');
        END IF;

        -- Mettre à jour le justificatif
        UPDATE JUSTIFICATIFS
        SET statut = p_statut,
            commentaire = p_commentaire,
            traite_par = p_traite_par,
            date_traitement = SYSDATE
        WHERE id_justificatif = p_id_justificatif
        RETURNING id_absence INTO v_id_absence;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20006, 'Justificatif non trouvé.');
        END IF;

        -- Si accepté, marquer l'absence comme justifiée
        IF p_statut = 'ACCEPTE' THEN
            UPDATE ABSENCES
            SET est_justifiee = 1
            WHERE id_absence = v_id_absence;

            -- Re-vérifier les seuils
            DECLARE
                v_id_etudiant NUMBER;
            BEGIN
                SELECT id_etudiant INTO v_id_etudiant
                FROM ABSENCES WHERE id_absence = v_id_absence;
                verifier_seuils_etudiant(v_id_etudiant);
            END;
        END IF;

        COMMIT;
    END traiter_justificatif;

    -- ========================================================
    -- PROCÉDURE : Vérifier les seuils et envoyer notifications
    -- ========================================================
    PROCEDURE verifier_seuils_etudiant(p_id_etudiant NUMBER) IS
        v_depassement VARCHAR2(20);
        v_nb_absences NUMBER;
        v_message VARCHAR2(500);
    BEGIN
        v_depassement := est_en_depassement(p_id_etudiant);
        v_nb_absences := get_nb_absences_non_justifiees(p_id_etudiant);

        IF v_depassement = 'EXCLUSION' THEN
            -- Mettre à jour le statut de l'étudiant
            UPDATE ETUDIANTS SET statut = 'EXCLU' WHERE id_etudiant = p_id_etudiant;

            v_message := 'EXCLUSION : Vous avez atteint ' || v_nb_absences ||
                         ' absences non justifiées. Votre statut a été changé à EXCLU.';
            INSERT INTO NOTIFICATIONS (id_etudiant, type_notification, message)
            VALUES (p_id_etudiant, 'EXCLUSION', v_message);

        ELSIF v_depassement = 'AVERTISSEMENT' THEN
            v_message := 'AVERTISSEMENT : Vous avez ' || v_nb_absences ||
                         ' absences non justifiées. Veuillez régulariser votre situation.';
            INSERT INTO NOTIFICATIONS (id_etudiant, type_notification, message)
            VALUES (p_id_etudiant, 'AVERTISSEMENT', v_message);
        END IF;
    END verifier_seuils_etudiant;

    -- ========================================================
    -- PROCÉDURE : Clôturer un semestre
    -- ========================================================
    PROCEDURE cloturer_semestre(
        p_id_semestre NUMBER,
        p_traite_par  VARCHAR2 DEFAULT USER
    ) IS
        CURSOR c_seances IS
            SELECT s.id_seance
            FROM SEANCES s
            JOIN MATIERES m ON s.id_matiere = m.id_matiere
            WHERE m.id_semestre = p_id_semestre
              AND s.statut = 'PLANIFIEE';
    BEGIN
        SAVEPOINT sp_cloture;

        -- Marquer toutes les séances planifiées comme effectuées
        FOR rec IN c_seances LOOP
            UPDATE SEANCES SET statut = 'EFFECTUEE' WHERE id_seance = rec.id_seance;
        END LOOP;

        -- Rejeter tous les justificatifs en attente
        UPDATE JUSTIFICATIFS j
        SET j.statut = 'REFUSE',
            j.commentaire = 'Clôture automatique du semestre',
            j.traite_par = p_traite_par,
            j.date_traitement = SYSDATE
        WHERE j.statut = 'EN_ATTENTE'
          AND j.id_absence IN (
              SELECT a.id_absence
              FROM ABSENCES a
              JOIN SEANCES s ON a.id_seance = s.id_seance
              JOIN MATIERES m ON s.id_matiere = m.id_matiere
              WHERE m.id_semestre = p_id_semestre
          );

        COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO sp_cloture;
            RAISE;
    END cloturer_semestre;

END PKG_ABSENCES;
/

-- ============================================================
-- PACKAGE : PKG_STATISTIQUES
-- Statistiques et rapports
-- ============================================================

CREATE OR REPLACE PACKAGE PKG_STATISTIQUES AS

    FUNCTION get_top_absents(p_id_groupe NUMBER DEFAULT NULL, p_limit NUMBER DEFAULT 10) RETURN SYS_REFCURSOR;
    FUNCTION get_stats_par_matiere(p_id_semestre NUMBER DEFAULT NULL) RETURN SYS_REFCURSOR;
    FUNCTION get_stats_par_groupe(p_annee VARCHAR2 DEFAULT NULL) RETURN SYS_REFCURSOR;
    FUNCTION get_evolution_mensuelle(p_id_groupe NUMBER DEFAULT NULL) RETURN SYS_REFCURSOR;

    PROCEDURE generer_rapport_absences(
        p_id_groupe  NUMBER,
        p_date_debut DATE,
        p_date_fin   DATE,
        p_resultat   OUT SYS_REFCURSOR
    );

END PKG_STATISTIQUES;
/

CREATE OR REPLACE PACKAGE BODY PKG_STATISTIQUES AS

    -- ========================================================
    -- FONCTION : Top des étudiants les plus absents
    -- ========================================================
    FUNCTION get_top_absents(p_id_groupe NUMBER DEFAULT NULL, p_limit NUMBER DEFAULT 10) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT e.id_etudiant, e.cne, e.nom, e.prenom, e.statut,
                   COUNT(a.id_absence) AS total_absences,
                   SUM(CASE WHEN a.est_justifiee = 0 THEN 1 ELSE 0 END) AS absences_non_justifiees,
                   SUM(CASE WHEN a.est_justifiee = 1 THEN 1 ELSE 0 END) AS absences_justifiees
            FROM ETUDIANTS e
            LEFT JOIN ABSENCES a ON e.id_etudiant = a.id_etudiant
            WHERE (p_id_groupe IS NULL OR e.id_groupe = p_id_groupe)
            GROUP BY e.id_etudiant, e.cne, e.nom, e.prenom, e.statut
            ORDER BY total_absences DESC
            FETCH FIRST p_limit ROWS ONLY;
        RETURN v_cursor;
    END get_top_absents;

    -- ========================================================
    -- FONCTION : Statistiques par matière
    -- ========================================================
    FUNCTION get_stats_par_matiere(p_id_semestre NUMBER DEFAULT NULL) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT m.id_matiere, m.code_matiere, m.nom_matiere,
                   COUNT(DISTINCT s.id_seance) AS nb_seances,
                   COUNT(a.id_absence) AS total_absences,
                   ROUND(AVG(CASE WHEN a.id_absence IS NOT NULL THEN 1 ELSE 0 END) * 100, 2) AS taux_moyen
            FROM MATIERES m
            LEFT JOIN SEANCES s ON m.id_matiere = s.id_matiere
            LEFT JOIN ABSENCES a ON s.id_seance = a.id_seance
            WHERE (p_id_semestre IS NULL OR m.id_semestre = p_id_semestre)
            GROUP BY m.id_matiere, m.code_matiere, m.nom_matiere
            ORDER BY total_absences DESC;
        RETURN v_cursor;
    END get_stats_par_matiere;

    -- ========================================================
    -- FONCTION : Statistiques par groupe
    -- ========================================================
    FUNCTION get_stats_par_groupe(p_annee VARCHAR2 DEFAULT NULL) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT g.id_groupe, g.code_groupe, g.nom_groupe,
                   f.nom_filiere,
                   COUNT(DISTINCT e.id_etudiant) AS nb_etudiants,
                   COUNT(a.id_absence) AS total_absences,
                   ROUND(COUNT(a.id_absence) / NULLIF(COUNT(DISTINCT e.id_etudiant), 0), 2) AS moyenne_absences
            FROM GROUPES g
            JOIN FILIERES f ON g.id_filiere = f.id_filiere
            LEFT JOIN ETUDIANTS e ON g.id_groupe = e.id_groupe
            LEFT JOIN ABSENCES a ON e.id_etudiant = a.id_etudiant
            WHERE (p_annee IS NULL OR g.annee_universitaire = p_annee)
            GROUP BY g.id_groupe, g.code_groupe, g.nom_groupe, f.nom_filiere
            ORDER BY total_absences DESC;
        RETURN v_cursor;
    END get_stats_par_groupe;

    -- ========================================================
    -- FONCTION : Évolution mensuelle des absences
    -- ========================================================
    FUNCTION get_evolution_mensuelle(p_id_groupe NUMBER DEFAULT NULL) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT TO_CHAR(a.date_absence, 'YYYY-MM') AS mois,
                   COUNT(*) AS total_absences,
                   SUM(CASE WHEN a.est_justifiee = 0 THEN 1 ELSE 0 END) AS non_justifiees,
                   SUM(CASE WHEN a.est_justifiee = 1 THEN 1 ELSE 0 END) AS justifiees
            FROM ABSENCES a
            JOIN ETUDIANTS e ON a.id_etudiant = e.id_etudiant
            WHERE (p_id_groupe IS NULL OR e.id_groupe = p_id_groupe)
            GROUP BY TO_CHAR(a.date_absence, 'YYYY-MM')
            ORDER BY mois;
        RETURN v_cursor;
    END get_evolution_mensuelle;

    -- ========================================================
    -- PROCÉDURE : Générer rapport d'absences
    -- ========================================================
    PROCEDURE generer_rapport_absences(
        p_id_groupe  NUMBER,
        p_date_debut DATE,
        p_date_fin   DATE,
        p_resultat   OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_resultat FOR
            SELECT e.cne, e.nom, e.prenom,
                   m.nom_matiere,
                   s.date_seance, s.heure_debut, s.heure_fin,
                   CASE WHEN a.est_justifiee = 1 THEN 'Oui' ELSE 'Non' END AS justifiee,
                   a.motif
            FROM ABSENCES a
            JOIN ETUDIANTS e ON a.id_etudiant = e.id_etudiant
            JOIN SEANCES s ON a.id_seance = s.id_seance
            JOIN MATIERES m ON s.id_matiere = m.id_matiere
            WHERE e.id_groupe = p_id_groupe
              AND a.date_absence BETWEEN p_date_debut AND p_date_fin
            ORDER BY e.nom, e.prenom, a.date_absence;
    END generer_rapport_absences;

END PKG_STATISTIQUES;
/

SELECT 'Packages PL/SQL créés avec succès !' AS RESULTAT FROM DUAL;

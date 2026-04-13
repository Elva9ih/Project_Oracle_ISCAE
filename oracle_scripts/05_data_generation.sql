-- ============================================================
-- PROJET ORACLE : Gestion des Absences Étudiants
-- Script 05 : Génération de données volumineuses
-- Objectif : 100 000+ lignes dans les tables clés
-- ============================================================

CONNECT gestion_absences/gestion2025@localhost:1521/XE;

SET SERVEROUTPUT ON;

-- ============================================================
-- ÉTAPE 1 : Données de référence
-- ============================================================

-- Filières
INSERT INTO FILIERES (code_filiere, nom_filiere, description) VALUES ('MPIAG', 'Management des Projets Informatiques et Administration Générale', 'Master en gestion de projets IT');
INSERT INTO FILIERES (code_filiere, nom_filiere, description) VALUES ('GFC', 'Gestion Financière et Comptable', 'Master en finance et comptabilité');
INSERT INTO FILIERES (code_filiere, nom_filiere, description) VALUES ('MRH', 'Management des Ressources Humaines', 'Master en ressources humaines');
INSERT INTO FILIERES (code_filiere, nom_filiere, description) VALUES ('MCO', 'Marketing et Commerce', 'Master en marketing et commerce');
INSERT INTO FILIERES (code_filiere, nom_filiere, description) VALUES ('MAE', 'Management et Administration des Entreprises', 'Master en administration');

-- Semestres
INSERT INTO SEMESTRES (code_semestre, nom_semestre, date_debut, date_fin, annee_universitaire) VALUES ('S1-2526', 'Semestre 1', DATE '2025-09-15', DATE '2026-01-31', '2025-2026');
INSERT INTO SEMESTRES (code_semestre, nom_semestre, date_debut, date_fin, annee_universitaire) VALUES ('S2-2526', 'Semestre 2', DATE '2026-02-01', DATE '2026-06-30', '2025-2026');

COMMIT;

-- Groupes (3 groupes par filière = 15 groupes)
DECLARE
    v_id_filiere NUMBER;
BEGIN
    FOR f IN (SELECT id_filiere, code_filiere FROM FILIERES) LOOP
        FOR i IN 1..3 LOOP
            INSERT INTO GROUPES (code_groupe, nom_groupe, id_filiere, annee_universitaire)
            VALUES (f.code_filiere || '-G' || i, f.code_filiere || ' Groupe ' || i, f.id_filiere, '2025-2026');
        END LOOP;
    END LOOP;
    COMMIT;
END;
/

-- Seuils d'absences par filière
BEGIN
    FOR f IN (SELECT id_filiere FROM FILIERES) LOOP
        INSERT INTO SEUILS_ABSENCES (id_filiere, seuil_avertissement, seuil_exclusion, annee_universitaire)
        VALUES (f.id_filiere, 3, 6, '2025-2026');
    END LOOP;
    COMMIT;
END;
/

-- ============================================================
-- ÉTAPE 2 : Enseignants (50 enseignants)
-- ============================================================

DECLARE
    TYPE t_noms IS TABLE OF VARCHAR2(50);
    TYPE t_prenoms IS TABLE OF VARCHAR2(50);
    v_noms t_noms := t_noms('BENNANI', 'EL AMRANI', 'TAZI', 'ALAOUI', 'BERRADA',
                             'FASSI', 'CHRAIBI', 'SQALLI', 'IDRISSI', 'BENJELLOUN',
                             'LAHLOU', 'BOUZIDI', 'KETTANI', 'ZNIBER', 'SEBTI',
                             'KADIRI', 'CHERKAOUI', 'MANSOURI', 'RACHIDI', 'FILALI',
                             'OUAZZANI', 'BENKIRANE', 'TAHIRI', 'JAIDI', 'SLIMANI',
                             'BOUAZZA', 'HASSANI', 'NACIRI', 'GUEDIRA', 'BELHAJ',
                             'RAMI', 'MOULINE', 'HAJJI', 'SEFRIOUI', 'MEKOUAR',
                             'BENSOUDA', 'LAHRICHI', 'AOUAD', 'CHAMI', 'TOUNSI',
                             'ANDALOUSSI', 'BENABDALLAH', 'KABBAJ', 'DOUIRI', 'GHAZI',
                             'BOUABID', 'LAMRANI', 'BENNIS', 'ZERHOUNI', 'OUAHBI');
    v_prenoms t_prenoms := t_prenoms('Mohammed', 'Fatima', 'Ahmed', 'Khadija', 'Youssef',
                                      'Zineb', 'Omar', 'Amina', 'Hassan', 'Nadia',
                                      'Rachid', 'Laila', 'Karim', 'Salma', 'Driss',
                                      'Houda', 'Samir', 'Meryem', 'Abdelaziz', 'Soukaina',
                                      'Mehdi', 'Ghita', 'Amine', 'Imane', 'Khalid',
                                      'Hanane', 'Younes', 'Asmaa', 'Hamid', 'Naima',
                                      'Adil', 'Sara', 'Mustapha', 'Loubna', 'Jamal',
                                      'Rajae', 'Aziz', 'Sanae', 'Brahim', 'Wafae',
                                      'Noureddine', 'Ilham', 'Said', 'Souad', 'Fouad',
                                      'Latifa', 'Hicham', 'Karima', 'Taoufik', 'Samira');
    v_specs t_noms := t_noms('Informatique', 'Finance', 'Marketing', 'Droit', 'Management',
                              'Comptabilité', 'Statistiques', 'Économie', 'Communication', 'Anglais');
    v_grades t_noms := t_noms('Professeur', 'Maître de Conférences', 'Assistant', 'Vacataire');
BEGIN
    FOR i IN 1..50 LOOP
        INSERT INTO ENSEIGNANTS (matricule, nom, prenom, email, telephone, specialite, grade)
        VALUES (
            'ENS' || LPAD(i, 4, '0'),
            v_noms(i),
            v_prenoms(i),
            LOWER(v_prenoms(i)) || '.' || LOWER(REPLACE(v_noms(i), ' ', '')) || '@iscae.ma',
            '06' || LPAD(TRUNC(DBMS_RANDOM.VALUE(10000000, 99999999)), 8, '0'),
            v_specs(MOD(i - 1, 10) + 1),
            v_grades(MOD(i - 1, 4) + 1)
        );
    END LOOP;
    COMMIT;
END;
/

-- ============================================================
-- ÉTAPE 3 : Matières (10 matières par filière = 50 matières)
-- ============================================================

DECLARE
    TYPE t_matieres IS TABLE OF VARCHAR2(100);
    v_matieres_info t_matieres := t_matieres(
        'Bases de Données Avancées', 'Développement Web', 'Gestion de Projets IT',
        'Sécurité Informatique', 'Intelligence Artificielle',
        'Réseaux et Systèmes', 'Algorithmique Avancée', 'Cloud Computing',
        'Big Data et Analytics', 'Programmation Mobile'
    );
    v_matieres_fin t_matieres := t_matieres(
        'Comptabilité Approfondie', 'Audit Financier', 'Finance de Marché',
        'Contrôle de Gestion', 'Fiscalité',
        'Analyse Financière', 'Normes IFRS', 'Finance Internationale',
        'Risk Management', 'Mathématiques Financières'
    );
    v_matieres_rh t_matieres := t_matieres(
        'Gestion des Compétences', 'Droit Social', 'Recrutement et Intégration',
        'Formation et Développement', 'Rémunération et Avantages',
        'Relations Sociales', 'SIRH', 'Conduite du Changement',
        'Communication Interne', 'Management d''Équipe'
    );
    v_matieres_mkt t_matieres := t_matieres(
        'Marketing Digital', 'Comportement du Consommateur', 'Stratégie Commerciale',
        'Communication Publicitaire', 'E-Commerce',
        'Études de Marché', 'Marketing International', 'Brand Management',
        'Distribution et Logistique', 'Marketing des Services'
    );
    v_matieres_mae t_matieres := t_matieres(
        'Management Stratégique', 'Économie d''Entreprise', 'Droit des Affaires',
        'Leadership et Gouvernance', 'Entrepreneuriat',
        'Gestion des Opérations', 'Environnement Économique', 'Négociation',
        'Qualité et Performance', 'Management Interculturel'
    );

    v_id_filiere NUMBER;
    v_id_sem1 NUMBER;
    v_id_sem2 NUMBER;
    v_mat_index NUMBER;
    v_code VARCHAR2(20);
    v_nom VARCHAR2(100);
BEGIN
    SELECT id_semestre INTO v_id_sem1 FROM SEMESTRES WHERE code_semestre = 'S1-2526';
    SELECT id_semestre INTO v_id_sem2 FROM SEMESTRES WHERE code_semestre = 'S2-2526';

    FOR f IN (SELECT id_filiere, code_filiere FROM FILIERES ORDER BY id_filiere) LOOP
        FOR i IN 1..10 LOOP
            -- Sélectionner le nom de matière selon la filière
            IF f.code_filiere = 'MPIAG' THEN v_nom := v_matieres_info(i);
            ELSIF f.code_filiere = 'GFC' THEN v_nom := v_matieres_fin(i);
            ELSIF f.code_filiere = 'MRH' THEN v_nom := v_matieres_rh(i);
            ELSIF f.code_filiere = 'MCO' THEN v_nom := v_matieres_mkt(i);
            ELSE v_nom := v_matieres_mae(i);
            END IF;

            v_code := f.code_filiere || '-M' || LPAD(i, 2, '0');

            INSERT INTO MATIERES (code_matiere, nom_matiere, coefficient, volume_horaire, id_filiere, id_semestre, type_matiere)
            VALUES (
                v_code,
                v_nom,
                ROUND(DBMS_RANDOM.VALUE(1, 4), 1),
                CASE WHEN i <= 5 THEN 40 ELSE 30 END,
                f.id_filiere,
                CASE WHEN i <= 5 THEN v_id_sem1 ELSE v_id_sem2 END,
                CASE MOD(i, 3) WHEN 0 THEN 'TP' WHEN 1 THEN 'COURS' ELSE 'TD' END
            );
        END LOOP;
    END LOOP;
    COMMIT;
END;
/

-- ============================================================
-- ÉTAPE 4 : Étudiants (800 étudiants - ~53 par groupe)
-- ============================================================

DECLARE
    TYPE t_arr IS TABLE OF VARCHAR2(50);
    v_noms t_arr := t_arr('ACHOUR', 'ADNANE', 'AITBRAHIM', 'AITYOUSSEF', 'AMEUR',
                           'AZIZI', 'BADAOUI', 'BADR', 'BAKALI', 'BELGHITI',
                           'BENALI', 'BENCHEKROUN', 'BENHADDOU', 'BENMOUSSA', 'BENSAID',
                           'BOUAZZAOUI', 'BOUHDADI', 'BOUKILI', 'BOURASS', 'CHAABI',
                           'DAHBI', 'DAOUDI', 'ELAMRANI', 'ELFASSI', 'ELGHAZI',
                           'ELKADIRI', 'ELMANSOURI', 'ELMOUSLIM', 'ERRACHIDI', 'ESSADIKI',
                           'FADILI', 'FARIDI', 'GHARBAOUI', 'GUENNOUN', 'HABTI',
                           'HAMDAOUI', 'HAMMADI', 'HARMOUCH', 'IBRAHIMI', 'JALIL');
    v_prenoms t_arr := t_arr('Anas', 'Ayoub', 'Badr', 'Chaima', 'Douae',
                              'Fatima Zahra', 'Ghita', 'Hamza', 'Ikram', 'Jihane',
                              'Kaoutar', 'Lamiae', 'Marouane', 'Najat', 'Othmane',
                              'Rachida', 'Salah', 'Taha', 'Widad', 'Yassine');
    v_counter NUMBER := 0;
    v_nom VARCHAR2(50);
    v_prenom VARCHAR2(50);
BEGIN
    FOR g IN (SELECT id_groupe, code_groupe FROM GROUPES ORDER BY id_groupe) LOOP
        FOR i IN 1..53 LOOP
            v_counter := v_counter + 1;
            v_nom := v_noms(MOD(v_counter - 1, 40) + 1);
            v_prenom := v_prenoms(MOD(i - 1, 20) + 1);

            BEGIN
                INSERT INTO ETUDIANTS (cne, nom, prenom, date_naissance, email, telephone, id_groupe)
                VALUES (
                    'CNE' || LPAD(v_counter, 6, '0'),
                    v_nom,
                    v_prenom,
                    DATE '1998-01-01' + TRUNC(DBMS_RANDOM.VALUE(0, 2500)),
                    LOWER(v_prenom) || '.' || LOWER(v_nom) || v_counter || '@etud.iscae.ma',
                    '06' || LPAD(TRUNC(DBMS_RANDOM.VALUE(10000000, 99999999)), 8, '0'),
                    g.id_groupe
                );
            EXCEPTION
                WHEN DUP_VAL_ON_INDEX THEN NULL;
            END;
        END LOOP;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Étudiants insérés: ' || v_counter);
END;
/

-- ============================================================
-- ÉTAPE 5 : Affectations enseignant-matière-groupe
-- ============================================================

DECLARE
    v_ens_id NUMBER;
    v_counter NUMBER := 0;
BEGIN
    FOR m IN (SELECT id_matiere, id_filiere FROM MATIERES ORDER BY id_matiere) LOOP
        FOR g IN (SELECT id_groupe FROM GROUPES WHERE id_filiere = m.id_filiere ORDER BY id_groupe) LOOP
            v_counter := v_counter + 1;
            -- Assigner un enseignant (round-robin)
            SELECT id_enseignant INTO v_ens_id
            FROM (SELECT id_enseignant, ROWNUM rn FROM ENSEIGNANTS ORDER BY id_enseignant)
            WHERE rn = MOD(v_counter - 1, 50) + 1;

            INSERT INTO AFFECTATIONS (id_enseignant, id_matiere, id_groupe, annee_universitaire)
            VALUES (v_ens_id, m.id_matiere, g.id_groupe, '2025-2026');
        END LOOP;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Affectations créées: ' || v_counter);
END;
/

-- ============================================================
-- ÉTAPE 6 : Séances (20 séances par matière-groupe = ~3000 séances)
-- ============================================================

DECLARE
    v_date DATE;
    v_heures_debut DBMS_SQL.VARCHAR2_TABLE;
    v_heures_fin   DBMS_SQL.VARCHAR2_TABLE;
    v_salles DBMS_SQL.VARCHAR2_TABLE;
    v_counter NUMBER := 0;
BEGIN
    v_heures_debut(1) := '08:30'; v_heures_fin(1) := '10:00';
    v_heures_debut(2) := '10:15'; v_heures_fin(2) := '11:45';
    v_heures_debut(3) := '14:00'; v_heures_fin(3) := '15:30';
    v_heures_debut(4) := '15:45'; v_heures_fin(4) := '17:15';

    v_salles(1) := 'A101'; v_salles(2) := 'A102'; v_salles(3) := 'A201';
    v_salles(4) := 'A202'; v_salles(5) := 'B101'; v_salles(6) := 'B102';
    v_salles(7) := 'B201'; v_salles(8) := 'B202'; v_salles(9) := 'C101';
    v_salles(10) := 'AMPHI1';

    FOR aff IN (SELECT a.id_enseignant, a.id_matiere, a.id_groupe,
                       m.id_semestre
                FROM AFFECTATIONS a
                JOIN MATIERES m ON a.id_matiere = m.id_matiere) LOOP

        -- Déterminer la date de début selon le semestre
        IF aff.id_semestre = (SELECT id_semestre FROM SEMESTRES WHERE code_semestre = 'S1-2526') THEN
            v_date := DATE '2025-09-15';
        ELSE
            v_date := DATE '2026-02-01';
        END IF;

        FOR i IN 1..20 LOOP
            v_counter := v_counter + 1;
            v_date := v_date + TRUNC(DBMS_RANDOM.VALUE(3, 10));

            -- Éviter les weekends
            IF TO_CHAR(v_date, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH') IN ('SAT', 'SUN') THEN
                v_date := v_date + 2;
            END IF;

            DECLARE
                v_slot NUMBER := MOD(i - 1, 4) + 1;
            BEGIN
                INSERT INTO SEANCES (id_matiere, id_enseignant, id_groupe, date_seance,
                                    heure_debut, heure_fin, salle, type_seance, statut)
                VALUES (
                    aff.id_matiere,
                    aff.id_enseignant,
                    aff.id_groupe,
                    v_date,
                    v_heures_debut(v_slot),
                    v_heures_fin(v_slot),
                    v_salles(MOD(v_counter - 1, 10) + 1),
                    CASE MOD(i, 3) WHEN 0 THEN 'TP' WHEN 1 THEN 'COURS' ELSE 'TD' END,
                    'EFFECTUEE'
                );
            END;
        END LOOP;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Séances créées: ' || v_counter);
END;
/

-- ============================================================
-- ÉTAPE 7 : Absences (100 000+ absences)
-- Désactiver temporairement les triggers pour la performance
-- ============================================================

ALTER TRIGGER trg_audit_absences DISABLE;
ALTER TRIGGER trg_absence_date_auto DISABLE;
ALTER TRIGGER trg_check_etudiant_actif DISABLE;
ALTER TRIGGER trg_seance_effectuee DISABLE;

DECLARE
    v_counter NUMBER := 0;
    v_target NUMBER := 120000;
    v_id_etudiant NUMBER;
    v_id_seance NUMBER;
    v_date_seance DATE;
    v_est_justifiee NUMBER;
BEGIN
    FOR i IN 1..v_target LOOP
        BEGIN
            -- Sélectionner un étudiant aléatoire
            SELECT id_etudiant INTO v_id_etudiant
            FROM (SELECT id_etudiant FROM ETUDIANTS WHERE statut = 'ACTIF' ORDER BY DBMS_RANDOM.VALUE)
            WHERE ROWNUM = 1;

            -- Sélectionner une séance aléatoire du même groupe
            SELECT s.id_seance, s.date_seance INTO v_id_seance, v_date_seance
            FROM SEANCES s
            JOIN ETUDIANTS e ON s.id_groupe = e.id_groupe
            WHERE e.id_etudiant = v_id_etudiant
            AND s.statut = 'EFFECTUEE'
            AND NOT EXISTS (SELECT 1 FROM ABSENCES a WHERE a.id_etudiant = v_id_etudiant AND a.id_seance = s.id_seance)
            AND ROWNUM = 1
            ORDER BY DBMS_RANDOM.VALUE;

            -- 20% de chance d'être justifiée
            v_est_justifiee := CASE WHEN DBMS_RANDOM.VALUE < 0.2 THEN 1 ELSE 0 END;

            INSERT INTO ABSENCES (id_etudiant, id_seance, date_absence, est_justifiee,
                                 motif, saisi_par)
            VALUES (v_id_etudiant, v_id_seance, v_date_seance, v_est_justifiee,
                    CASE WHEN v_est_justifiee = 1 THEN 'Justifié' ELSE NULL END,
                    'SYSTEM');

            v_counter := v_counter + 1;

            IF MOD(v_counter, 10000) = 0 THEN
                COMMIT;
                DBMS_OUTPUT.PUT_LINE('Absences insérées: ' || v_counter);
            END IF;

        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN NULL;
            WHEN NO_DATA_FOUND THEN NULL;
        END;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Total absences insérées: ' || v_counter);
END;
/

-- Réactiver les triggers
ALTER TRIGGER trg_audit_absences ENABLE;
ALTER TRIGGER trg_absence_date_auto ENABLE;
ALTER TRIGGER trg_check_etudiant_actif ENABLE;
ALTER TRIGGER trg_seance_effectuee ENABLE;

-- ============================================================
-- ÉTAPE 8 : Justificatifs (pour ~20% des absences justifiées)
-- ============================================================

DECLARE
    v_counter NUMBER := 0;
    TYPE t_types IS TABLE OF VARCHAR2(20);
    v_types t_types := t_types('MEDICAL', 'FAMILIAL', 'ADMINISTRATIF', 'AUTRE');
BEGIN
    FOR a IN (SELECT id_absence FROM ABSENCES WHERE est_justifiee = 1 AND ROWNUM <= 25000) LOOP
        INSERT INTO JUSTIFICATIFS (id_absence, type_justificatif, description, statut, date_traitement, traite_par)
        VALUES (
            a.id_absence,
            v_types(MOD(v_counter, 4) + 1),
            'Justificatif soumis automatiquement pour test',
            'ACCEPTE',
            SYSDATE,
            'ADMIN'
        );
        v_counter := v_counter + 1;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Justificatifs créés: ' || v_counter);
END;
/

-- ============================================================
-- ÉTAPE 9 : Rafraîchir les vues matérialisées
-- ============================================================

BEGIN
    REFRESH_ALL_MV;
END;
/

-- ============================================================
-- Vérification des données
-- ============================================================

SELECT 'FILIERES' AS TABLE_NAME, COUNT(*) AS NB_ROWS FROM FILIERES
UNION ALL SELECT 'GROUPES', COUNT(*) FROM GROUPES
UNION ALL SELECT 'SEMESTRES', COUNT(*) FROM SEMESTRES
UNION ALL SELECT 'ENSEIGNANTS', COUNT(*) FROM ENSEIGNANTS
UNION ALL SELECT 'MATIERES', COUNT(*) FROM MATIERES
UNION ALL SELECT 'ETUDIANTS', COUNT(*) FROM ETUDIANTS
UNION ALL SELECT 'AFFECTATIONS', COUNT(*) FROM AFFECTATIONS
UNION ALL SELECT 'SEANCES', COUNT(*) FROM SEANCES
UNION ALL SELECT 'ABSENCES', COUNT(*) FROM ABSENCES
UNION ALL SELECT 'JUSTIFICATIFS', COUNT(*) FROM JUSTIFICATIFS
UNION ALL SELECT 'NOTIFICATIONS', COUNT(*) FROM NOTIFICATIONS
UNION ALL SELECT 'AUDIT_LOG', COUNT(*) FROM AUDIT_LOG
ORDER BY TABLE_NAME;

SELECT 'Données générées avec succès !' AS RESULTAT FROM DUAL;

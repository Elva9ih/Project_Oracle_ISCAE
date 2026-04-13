SET SERVEROUTPUT ON;

-- Filieres
INSERT INTO FILIERES (code_filiere, nom_filiere, description) VALUES ('MPIAG', 'Management des Projets Informatiques', 'Master en gestion de projets IT');
INSERT INTO FILIERES (code_filiere, nom_filiere, description) VALUES ('GFC', 'Gestion Financiere et Comptable', 'Master en finance');
INSERT INTO FILIERES (code_filiere, nom_filiere, description) VALUES ('MRH', 'Management des Ressources Humaines', 'Master RH');
INSERT INTO FILIERES (code_filiere, nom_filiere, description) VALUES ('MCO', 'Marketing et Commerce', 'Master marketing');
INSERT INTO FILIERES (code_filiere, nom_filiere, description) VALUES ('MAE', 'Management et Administration', 'Master admin');

-- Semestres
INSERT INTO SEMESTRES (code_semestre, nom_semestre, date_debut, date_fin, annee_universitaire) VALUES ('S1-2526', 'Semestre 1', DATE '2025-09-15', DATE '2026-01-31', '2025-2026');
INSERT INTO SEMESTRES (code_semestre, nom_semestre, date_debut, date_fin, annee_universitaire) VALUES ('S2-2526', 'Semestre 2', DATE '2026-02-01', DATE '2026-06-30', '2025-2026');
COMMIT;

-- Groupes (3 per filiere = 15)
DECLARE
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

-- Seuils
BEGIN
    FOR f IN (SELECT id_filiere FROM FILIERES) LOOP
        INSERT INTO SEUILS_ABSENCES (id_filiere, seuil_avertissement, seuil_exclusion, annee_universitaire) VALUES (f.id_filiere, 3, 6, '2025-2026');
    END LOOP;
    COMMIT;
END;
/

-- 50 Enseignants
DECLARE
    TYPE t_arr IS TABLE OF VARCHAR2(50);
    v_noms t_arr := t_arr('BENNANI','ELAMRANI','TAZI','ALAOUI','BERRADA','FASSI','CHRAIBI','SQALLI','IDRISSI','BENJELLOUN',
                           'LAHLOU','BOUZIDI','KETTANI','ZNIBER','SEBTI','KADIRI','CHERKAOUI','MANSOURI','RACHIDI','FILALI',
                           'OUAZZANI','BENKIRANE','TAHIRI','JAIDI','SLIMANI','BOUAZZA','HASSANI','NACIRI','GUEDIRA','BELHAJ',
                           'RAMI','MOULINE','HAJJI','SEFRIOUI','MEKOUAR','BENSOUDA','LAHRICHI','AOUAD','CHAMI','TOUNSI',
                           'ANDALOUSSI','BENABDALLAH','KABBAJ','DOUIRI','GHAZI','BOUABID','LAMRANI','BENNIS','ZERHOUNI','OUAHBI');
    v_prenoms t_arr := t_arr('Mohammed','Fatima','Ahmed','Khadija','Youssef','Zineb','Omar','Amina','Hassan','Nadia',
                              'Rachid','Laila','Karim','Salma','Driss','Houda','Samir','Meryem','Abdelaziz','Soukaina',
                              'Mehdi','Ghita','Amine','Imane','Khalid','Hanane','Younes','Asmaa','Hamid','Naima',
                              'Adil','Sara','Mustapha','Loubna','Jamal','Rajae','Aziz','Sanae','Brahim','Wafae',
                              'Noureddine','Ilham','Said','Souad','Fouad','Latifa','Hicham','Karima','Taoufik','Samira');
    v_specs t_arr := t_arr('Informatique','Finance','Marketing','Droit','Management','Comptabilite','Statistiques','Economie','Communication','Anglais');
    v_grades t_arr := t_arr('Professeur','Maitre de Conferences','Assistant','Vacataire');
BEGIN
    FOR i IN 1..50 LOOP
        INSERT INTO ENSEIGNANTS (matricule, nom, prenom, email, telephone, specialite, grade)
        VALUES ('ENS' || LPAD(i, 4, '0'), v_noms(i), v_prenoms(i),
                LOWER(v_prenoms(i)) || '.' || LOWER(v_noms(i)) || '@iscae.ma',
                '06' || LPAD(TRUNC(DBMS_RANDOM.VALUE(10000000, 99999999)), 8, '0'),
                v_specs(MOD(i - 1, 10) + 1), v_grades(MOD(i - 1, 4) + 1));
    END LOOP;
    COMMIT;
END;
/

-- 50 Matieres (10 per filiere)
DECLARE
    TYPE t_arr IS TABLE OF VARCHAR2(100);
    v_mats t_arr := t_arr('Bases de Donnees Avancees','Developpement Web','Gestion de Projets IT','Securite Informatique','Intelligence Artificielle',
                           'Reseaux et Systemes','Algorithmique Avancee','Cloud Computing','Big Data Analytics','Programmation Mobile',
                           'Comptabilite Approfondie','Audit Financier','Finance de Marche','Controle de Gestion','Fiscalite',
                           'Analyse Financiere','Normes IFRS','Finance Internationale','Risk Management','Maths Financieres',
                           'Gestion des Competences','Droit Social','Recrutement et Integration','Formation et Dev','Remuneration',
                           'Relations Sociales','SIRH','Conduite du Changement','Communication Interne','Management Equipe',
                           'Marketing Digital','Comportement Consommateur','Strategie Commerciale','Communication Pub','E-Commerce',
                           'Etudes de Marche','Marketing International','Brand Management','Distribution Logistique','Marketing Services',
                           'Management Strategique','Economie Entreprise','Droit des Affaires','Leadership Gouvernance','Entrepreneuriat',
                           'Gestion Operations','Environnement Economique','Negociation','Qualite Performance','Management Interculturel');
    v_idx NUMBER := 0;
    v_id_s1 NUMBER; v_id_s2 NUMBER;
BEGIN
    SELECT id_semestre INTO v_id_s1 FROM SEMESTRES WHERE code_semestre = 'S1-2526';
    SELECT id_semestre INTO v_id_s2 FROM SEMESTRES WHERE code_semestre = 'S2-2526';
    FOR f IN (SELECT id_filiere, code_filiere FROM FILIERES ORDER BY id_filiere) LOOP
        FOR i IN 1..10 LOOP
            v_idx := v_idx + 1;
            INSERT INTO MATIERES (code_matiere, nom_matiere, coefficient, volume_horaire, id_filiere, id_semestre, type_matiere)
            VALUES (f.code_filiere || '-M' || LPAD(i, 2, '0'), v_mats(v_idx),
                    ROUND(DBMS_RANDOM.VALUE(1, 4), 1), CASE WHEN i <= 5 THEN 40 ELSE 30 END,
                    f.id_filiere, CASE WHEN i <= 5 THEN v_id_s1 ELSE v_id_s2 END,
                    CASE MOD(i, 3) WHEN 0 THEN 'TP' WHEN 1 THEN 'COURS' ELSE 'TD' END);
        END LOOP;
    END LOOP;
    COMMIT;
END;
/

-- 795 Etudiants (53 per groupe)
DECLARE
    TYPE t_arr IS TABLE OF VARCHAR2(50);
    v_noms t_arr := t_arr('ACHOUR','ADNANE','AITBRAHIM','AITYOUSSEF','AMEUR','AZIZI','BADAOUI','BADR','BAKALI','BELGHITI',
                           'BENALI','BENCHEKROUN','BENHADDOU','BENMOUSSA','BENSAID','BOUAZZAOUI','BOUHDADI','BOUKILI','BOURASS','CHAABI',
                           'DAHBI','DAOUDI','ELAMRANI','ELFASSI','ELGHAZI','ELKADIRI','ELMANSOURI','ELMOUSLIM','ERRACHIDI','ESSADIKI',
                           'FADILI','FARIDI','GHARBAOUI','GUENNOUN','HABTI','HAMDAOUI','HAMMADI','HARMOUCH','IBRAHIMI','JALIL');
    v_prenoms t_arr := t_arr('Anas','Ayoub','Badr','Chaima','Douae','FatimaZahra','Ghita','Hamza','Ikram','Jihane',
                              'Kaoutar','Lamiae','Marouane','Najat','Othmane','Rachida','Salah','Taha','Widad','Yassine');
    v_c NUMBER := 0;
BEGIN
    FOR g IN (SELECT id_groupe, code_groupe FROM GROUPES ORDER BY id_groupe) LOOP
        FOR i IN 1..53 LOOP
            v_c := v_c + 1;
            BEGIN
                INSERT INTO ETUDIANTS (cne, nom, prenom, date_naissance, email, telephone, id_groupe)
                VALUES ('CNE' || LPAD(v_c, 6, '0'), v_noms(MOD(v_c - 1, 40) + 1), v_prenoms(MOD(i - 1, 20) + 1),
                        DATE '1998-01-01' + TRUNC(DBMS_RANDOM.VALUE(0, 2500)),
                        'etud' || v_c || '@etud.iscae.ma',
                        '06' || LPAD(TRUNC(DBMS_RANDOM.VALUE(10000000, 99999999)), 8, '0'), g.id_groupe);
            EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL;
            END;
        END LOOP;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Etudiants inseres: ' || v_c);
END;
/

-- Affectations
DECLARE
    v_ens_id NUMBER; v_c NUMBER := 0;
BEGIN
    FOR m IN (SELECT id_matiere, id_filiere FROM MATIERES ORDER BY id_matiere) LOOP
        FOR g IN (SELECT id_groupe FROM GROUPES WHERE id_filiere = m.id_filiere ORDER BY id_groupe) LOOP
            v_c := v_c + 1;
            SELECT id_enseignant INTO v_ens_id FROM (SELECT id_enseignant, ROWNUM rn FROM ENSEIGNANTS ORDER BY id_enseignant) WHERE rn = MOD(v_c - 1, 50) + 1;
            INSERT INTO AFFECTATIONS (id_enseignant, id_matiere, id_groupe, annee_universitaire) VALUES (v_ens_id, m.id_matiere, g.id_groupe, '2025-2026');
        END LOOP;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Affectations: ' || v_c);
END;
/

-- Seances (20 per affectation = ~3000)
DECLARE
    v_date DATE; v_c NUMBER := 0;
    TYPE t_h IS TABLE OF VARCHAR2(5);
    v_hd t_h := t_h('08:30','10:15','14:00','15:45');
    v_hf t_h := t_h('10:00','11:45','15:30','17:15');
    TYPE t_s IS TABLE OF VARCHAR2(10);
    v_salles t_s := t_s('A101','A102','A201','A202','B101','B102','B201','B202','C101','AMPHI1');
    v_id_s1 NUMBER;
BEGIN
    SELECT id_semestre INTO v_id_s1 FROM SEMESTRES WHERE code_semestre = 'S1-2526';
    FOR aff IN (SELECT a.id_enseignant, a.id_matiere, a.id_groupe, m.id_semestre FROM AFFECTATIONS a JOIN MATIERES m ON a.id_matiere = m.id_matiere) LOOP
        IF aff.id_semestre = v_id_s1 THEN v_date := DATE '2025-09-15'; ELSE v_date := DATE '2026-02-01'; END IF;
        FOR i IN 1..20 LOOP
            v_c := v_c + 1;
            v_date := v_date + TRUNC(DBMS_RANDOM.VALUE(3, 10));
            IF TO_CHAR(v_date, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH') IN ('SAT','SUN') THEN v_date := v_date + 2; END IF;
            INSERT INTO SEANCES (id_matiere, id_enseignant, id_groupe, date_seance, heure_debut, heure_fin, salle, type_seance, statut)
            VALUES (aff.id_matiere, aff.id_enseignant, aff.id_groupe, v_date,
                    v_hd(MOD(i-1,4)+1), v_hf(MOD(i-1,4)+1), v_salles(MOD(v_c-1,10)+1),
                    CASE MOD(i,3) WHEN 0 THEN 'TP' WHEN 1 THEN 'COURS' ELSE 'TD' END, 'EFFECTUEE');
        END LOOP;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Seances: ' || v_c);
END;
/

DBMS_OUTPUT.PUT_LINE('Reference data + seances done. Now generating absences...');

-- Disable triggers for bulk insert performance
ALTER TRIGGER trg_audit_absences DISABLE;
ALTER TRIGGER trg_absence_date_auto DISABLE;
ALTER TRIGGER trg_check_etudiant_actif DISABLE;
ALTER TRIGGER trg_seance_effectuee DISABLE;

-- 120000 absences
DECLARE
    v_c NUMBER := 0; v_id_e NUMBER; v_id_s NUMBER; v_date DATE; v_just NUMBER;
BEGIN
    FOR i IN 1..120000 LOOP
        BEGIN
            SELECT id_etudiant INTO v_id_e FROM (SELECT id_etudiant FROM ETUDIANTS WHERE statut = 'ACTIF' ORDER BY DBMS_RANDOM.VALUE) WHERE ROWNUM = 1;
            SELECT s.id_seance, s.date_seance INTO v_id_s, v_date
            FROM SEANCES s JOIN ETUDIANTS e ON s.id_groupe = e.id_groupe
            WHERE e.id_etudiant = v_id_e AND s.statut = 'EFFECTUEE'
            AND NOT EXISTS (SELECT 1 FROM ABSENCES a WHERE a.id_etudiant = v_id_e AND a.id_seance = s.id_seance)
            AND ROWNUM = 1;
            v_just := CASE WHEN DBMS_RANDOM.VALUE < 0.2 THEN 1 ELSE 0 END;
            INSERT INTO ABSENCES (id_etudiant, id_seance, date_absence, est_justifiee, motif, saisi_par)
            VALUES (v_id_e, v_id_s, v_date, v_just, CASE WHEN v_just = 1 THEN 'Justifie' ELSE NULL END, 'SYSTEM');
            v_c := v_c + 1;
            IF MOD(v_c, 10000) = 0 THEN COMMIT; DBMS_OUTPUT.PUT_LINE('Absences: ' || v_c); END IF;
        EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; WHEN NO_DATA_FOUND THEN NULL;
        END;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Total absences: ' || v_c);
END;
/

-- Re-enable triggers
ALTER TRIGGER trg_audit_absences ENABLE;
ALTER TRIGGER trg_absence_date_auto ENABLE;
ALTER TRIGGER trg_check_etudiant_actif ENABLE;
ALTER TRIGGER trg_seance_effectuee ENABLE;

-- Justificatifs for justified absences
DECLARE
    v_c NUMBER := 0;
    TYPE t_t IS TABLE OF VARCHAR2(20);
    v_types t_t := t_t('MEDICAL','FAMILIAL','ADMINISTRATIF','AUTRE');
BEGIN
    FOR a IN (SELECT id_absence FROM ABSENCES WHERE est_justifiee = 1 AND ROWNUM <= 25000) LOOP
        INSERT INTO JUSTIFICATIFS (id_absence, type_justificatif, description, statut, date_traitement, traite_par)
        VALUES (a.id_absence, v_types(MOD(v_c, 4) + 1), 'Justificatif automatique', 'ACCEPTE', SYSDATE, 'ADMIN');
        v_c := v_c + 1;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Justificatifs: ' || v_c);
END;
/

-- Refresh materialized views
BEGIN
    REFRESH_ALL_MV;
END;
/

-- Verification
SELECT 'FILIERES' AS T, COUNT(*) AS N FROM FILIERES UNION ALL
SELECT 'GROUPES', COUNT(*) FROM GROUPES UNION ALL
SELECT 'SEMESTRES', COUNT(*) FROM SEMESTRES UNION ALL
SELECT 'ENSEIGNANTS', COUNT(*) FROM ENSEIGNANTS UNION ALL
SELECT 'MATIERES', COUNT(*) FROM MATIERES UNION ALL
SELECT 'ETUDIANTS', COUNT(*) FROM ETUDIANTS UNION ALL
SELECT 'AFFECTATIONS', COUNT(*) FROM AFFECTATIONS UNION ALL
SELECT 'SEANCES', COUNT(*) FROM SEANCES UNION ALL
SELECT 'ABSENCES', COUNT(*) FROM ABSENCES UNION ALL
SELECT 'JUSTIFICATIFS', COUNT(*) FROM JUSTIFICATIFS ORDER BY T;

EXIT;

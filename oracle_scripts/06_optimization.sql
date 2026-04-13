-- ============================================================
-- PROJET ORACLE : Gestion des Absences Étudiants
-- Script 06 : Optimisation et Plans d'Exécution (EXPLAIN PLAN)
-- ============================================================

CONNECT gestion_absences/gestion2025@localhost:1521/XE;

SET SERVEROUTPUT ON;
SET LINESIZE 200;

-- ============================================================
-- TEST 1 : Recherche d'absences par étudiant (SANS index vs AVEC index)
-- ============================================================

-- Analyser les tables pour que l'optimiseur ait des statistiques
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'ABSENCES');
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'ETUDIANTS');
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'SEANCES');
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'MATIERES');
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'GROUPES');
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'FILIERES');
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'ENSEIGNANTS');
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'JUSTIFICATIFS');
END;
/

-- ============================================================
-- EXPLAIN PLAN : Requête 1 - Absences détaillées d'un étudiant
-- ============================================================

EXPLAIN PLAN FOR
SELECT e.nom, e.prenom, m.nom_matiere, s.date_seance, a.est_justifiee
FROM ABSENCES a
JOIN ETUDIANTS e ON a.id_etudiant = e.id_etudiant
JOIN SEANCES s ON a.id_seance = s.id_seance
JOIN MATIERES m ON s.id_matiere = m.id_matiere
WHERE e.cne = 'CNE000001';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());

-- ============================================================
-- EXPLAIN PLAN : Requête 2 - Top 10 étudiants les plus absents
-- ============================================================

EXPLAIN PLAN FOR
SELECT e.nom, e.prenom, COUNT(*) AS nb_absences
FROM ABSENCES a
JOIN ETUDIANTS e ON a.id_etudiant = e.id_etudiant
WHERE a.est_justifiee = 0
GROUP BY e.nom, e.prenom
ORDER BY nb_absences DESC
FETCH FIRST 10 ROWS ONLY;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());

-- ============================================================
-- EXPLAIN PLAN : Requête 3 - Statistiques par matière
-- ============================================================

EXPLAIN PLAN FOR
SELECT m.nom_matiere, COUNT(a.id_absence) AS total_absences,
       ROUND(AVG(CASE WHEN a.est_justifiee = 1 THEN 1 ELSE 0 END) * 100, 2) AS pct_justifiees
FROM MATIERES m
JOIN SEANCES s ON m.id_matiere = s.id_matiere
LEFT JOIN ABSENCES a ON s.id_seance = a.id_seance
GROUP BY m.nom_matiere
ORDER BY total_absences DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());

-- ============================================================
-- EXPLAIN PLAN : Requête 4 - Utilisation de la vue matérialisée
-- ============================================================

EXPLAIN PLAN FOR
SELECT * FROM MV_STATS_PAR_GROUPE
WHERE total_absences > 100
ORDER BY total_absences DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());

-- ============================================================
-- COMPARAISON : Requête directe vs Vue Matérialisée
-- ============================================================

-- Mesurer le temps : requête directe sur les tables
SET TIMING ON;

SELECT g.code_groupe, g.nom_groupe, f.nom_filiere,
       COUNT(DISTINCT e.id_etudiant) AS nb_etudiants,
       COUNT(a.id_absence) AS total_absences
FROM GROUPES g
JOIN FILIERES f ON g.id_filiere = f.id_filiere
LEFT JOIN ETUDIANTS e ON g.id_groupe = e.id_groupe
LEFT JOIN ABSENCES a ON e.id_etudiant = a.id_etudiant
GROUP BY g.code_groupe, g.nom_groupe, f.nom_filiere
ORDER BY total_absences DESC;

-- Mesurer le temps : même résultat via vue matérialisée
SELECT code_groupe, nom_groupe, nom_filiere, nb_etudiants, total_absences
FROM MV_STATS_PAR_GROUPE
ORDER BY total_absences DESC;

SET TIMING OFF;

-- ============================================================
-- TEST : Impact de l'index sur la recherche par date
-- ============================================================

EXPLAIN PLAN FOR
SELECT COUNT(*) FROM ABSENCES
WHERE date_absence BETWEEN DATE '2025-10-01' AND DATE '2025-12-31';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());

-- ============================================================
-- TEST : Recherche par nom avec index fonctionnel
-- ============================================================

EXPLAIN PLAN FOR
SELECT * FROM ETUDIANTS
WHERE UPPER(nom) = 'BENNANI' AND UPPER(prenom) = 'AHMED';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());

SELECT 'Tests d''optimisation terminés !' AS RESULTAT FROM DUAL;

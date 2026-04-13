-- Fix MV_KPI_GLOBAL using a regular view instead
CREATE OR REPLACE VIEW V_KPI_GLOBAL AS
SELECT (SELECT COUNT(*) FROM ETUDIANTS WHERE statut = 'ACTIF') AS nb_etudiants_actifs,
       (SELECT COUNT(*) FROM ETUDIANTS WHERE statut = 'EXCLU') AS nb_etudiants_exclus,
       (SELECT COUNT(*) FROM ENSEIGNANTS WHERE statut = 'ACTIF') AS nb_enseignants,
       (SELECT COUNT(*) FROM SEANCES WHERE statut = 'EFFECTUEE') AS nb_seances_effectuees,
       (SELECT COUNT(*) FROM ABSENCES) AS total_absences,
       (SELECT COUNT(*) FROM ABSENCES WHERE est_justifiee = 0) AS absences_non_justifiees,
       (SELECT COUNT(*) FROM ABSENCES WHERE est_justifiee = 1) AS absences_justifiees,
       (SELECT COUNT(*) FROM JUSTIFICATIFS WHERE statut = 'EN_ATTENTE') AS justificatifs_en_attente,
       SYSDATE AS date_refresh
FROM DUAL;

-- Update REFRESH_ALL_MV to skip MV_KPI_GLOBAL
CREATE OR REPLACE PROCEDURE REFRESH_ALL_MV AS
BEGIN
    DBMS_MVIEW.REFRESH('MV_STATS_PAR_GROUPE', 'C');
    DBMS_MVIEW.REFRESH('MV_STATS_PAR_MATIERE', 'C');
    DBMS_MVIEW.REFRESH('MV_EVOLUTION_MENSUELLE', 'C');
END;
/

SELECT 'Fix MV OK!' AS RESULTAT FROM DUAL;
EXIT;

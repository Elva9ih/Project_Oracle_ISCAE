-- ============================================================
-- PROJET ORACLE : Gestion des Absences Étudiants
-- Script 04 : Vues et Vues Matérialisées
-- ============================================================

CONNECT gestion_absences/gestion2025@localhost:1521/XE;

-- ============================================================
-- VUE 1 : Liste détaillée des absences
-- ============================================================

CREATE OR REPLACE VIEW V_ABSENCES_DETAIL AS
SELECT
    a.id_absence,
    e.id_etudiant,
    e.cne,
    e.nom AS nom_etudiant,
    e.prenom AS prenom_etudiant,
    g.code_groupe,
    g.nom_groupe,
    f.nom_filiere,
    m.code_matiere,
    m.nom_matiere,
    ens.nom AS nom_enseignant,
    ens.prenom AS prenom_enseignant,
    s.date_seance,
    s.heure_debut,
    s.heure_fin,
    s.salle,
    s.type_seance,
    a.est_justifiee,
    CASE WHEN a.est_justifiee = 1 THEN 'Oui' ELSE 'Non' END AS justifiee_libelle,
    a.motif,
    a.date_saisie,
    a.saisi_par
FROM ABSENCES a
JOIN ETUDIANTS e ON a.id_etudiant = e.id_etudiant
JOIN GROUPES g ON e.id_groupe = g.id_groupe
JOIN FILIERES f ON g.id_filiere = f.id_filiere
JOIN SEANCES s ON a.id_seance = s.id_seance
JOIN MATIERES m ON s.id_matiere = m.id_matiere
JOIN ENSEIGNANTS ens ON s.id_enseignant = ens.id_enseignant;

-- ============================================================
-- VUE 2 : Résumé des absences par étudiant
-- ============================================================

CREATE OR REPLACE VIEW V_RESUME_ABSENCES_ETUDIANT AS
SELECT
    e.id_etudiant,
    e.cne,
    e.nom,
    e.prenom,
    e.statut,
    g.code_groupe,
    f.nom_filiere,
    COUNT(a.id_absence) AS total_absences,
    SUM(CASE WHEN a.est_justifiee = 0 THEN 1 ELSE 0 END) AS absences_non_justifiees,
    SUM(CASE WHEN a.est_justifiee = 1 THEN 1 ELSE 0 END) AS absences_justifiees,
    PKG_ABSENCES.get_taux_absence(e.id_etudiant) AS taux_absence,
    PKG_ABSENCES.est_en_depassement(e.id_etudiant) AS niveau_alerte
FROM ETUDIANTS e
JOIN GROUPES g ON e.id_groupe = g.id_groupe
JOIN FILIERES f ON g.id_filiere = f.id_filiere
LEFT JOIN ABSENCES a ON e.id_etudiant = a.id_etudiant
GROUP BY e.id_etudiant, e.cne, e.nom, e.prenom, e.statut, g.code_groupe, f.nom_filiere;

-- ============================================================
-- VUE 3 : Séances avec nombre d'absents
-- ============================================================

CREATE OR REPLACE VIEW V_SEANCES_ABSENTS AS
SELECT
    s.id_seance,
    s.date_seance,
    s.heure_debut,
    s.heure_fin,
    s.salle,
    s.type_seance,
    s.statut AS statut_seance,
    m.code_matiere,
    m.nom_matiere,
    ens.nom || ' ' || ens.prenom AS enseignant,
    g.code_groupe,
    (SELECT COUNT(*) FROM ETUDIANTS et WHERE et.id_groupe = s.id_groupe) AS effectif_groupe,
    COUNT(a.id_absence) AS nb_absents,
    ROUND(COUNT(a.id_absence) * 100.0 /
          NULLIF((SELECT COUNT(*) FROM ETUDIANTS et WHERE et.id_groupe = s.id_groupe), 0), 2) AS taux_absence
FROM SEANCES s
JOIN MATIERES m ON s.id_matiere = m.id_matiere
JOIN ENSEIGNANTS ens ON s.id_enseignant = ens.id_enseignant
JOIN GROUPES g ON s.id_groupe = g.id_groupe
LEFT JOIN ABSENCES a ON s.id_seance = a.id_seance
GROUP BY s.id_seance, s.date_seance, s.heure_debut, s.heure_fin, s.salle,
         s.type_seance, s.statut, m.code_matiere, m.nom_matiere,
         ens.nom, ens.prenom, g.code_groupe, s.id_groupe;

-- ============================================================
-- VUE 4 : Justificatifs en attente
-- ============================================================

CREATE OR REPLACE VIEW V_JUSTIFICATIFS_EN_ATTENTE AS
SELECT
    j.id_justificatif,
    j.type_justificatif,
    j.description,
    j.date_soumission,
    j.statut,
    e.cne,
    e.nom || ' ' || e.prenom AS etudiant,
    m.nom_matiere,
    s.date_seance
FROM JUSTIFICATIFS j
JOIN ABSENCES a ON j.id_absence = a.id_absence
JOIN ETUDIANTS e ON a.id_etudiant = e.id_etudiant
JOIN SEANCES s ON a.id_seance = s.id_seance
JOIN MATIERES m ON s.id_matiere = m.id_matiere
WHERE j.statut = 'EN_ATTENTE'
ORDER BY j.date_soumission;

-- ============================================================
-- VUE 5 : Notifications non lues
-- ============================================================

CREATE OR REPLACE VIEW V_NOTIFICATIONS_NON_LUES AS
SELECT
    n.id_notification,
    n.type_notification,
    n.message,
    n.date_creation,
    e.cne,
    e.nom || ' ' || e.prenom AS etudiant
FROM NOTIFICATIONS n
JOIN ETUDIANTS e ON n.id_etudiant = e.id_etudiant
WHERE n.est_lue = 0
ORDER BY n.date_creation DESC;

-- ============================================================
-- VUE MATÉRIALISÉE 1 : Tableau de bord - Stats par groupe
-- ============================================================

CREATE MATERIALIZED VIEW MV_STATS_PAR_GROUPE
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT
    g.id_groupe,
    g.code_groupe,
    g.nom_groupe,
    f.code_filiere,
    f.nom_filiere,
    COUNT(DISTINCT e.id_etudiant) AS nb_etudiants,
    COUNT(a.id_absence) AS total_absences,
    SUM(CASE WHEN a.est_justifiee = 0 THEN 1 ELSE 0 END) AS absences_non_justifiees,
    SUM(CASE WHEN a.est_justifiee = 1 THEN 1 ELSE 0 END) AS absences_justifiees,
    ROUND(COUNT(a.id_absence) / NULLIF(COUNT(DISTINCT e.id_etudiant), 0), 2) AS moyenne_absences_par_etudiant
FROM GROUPES g
JOIN FILIERES f ON g.id_filiere = f.id_filiere
LEFT JOIN ETUDIANTS e ON g.id_groupe = e.id_groupe
LEFT JOIN ABSENCES a ON e.id_etudiant = a.id_etudiant
GROUP BY g.id_groupe, g.code_groupe, g.nom_groupe, f.code_filiere, f.nom_filiere;

-- ============================================================
-- VUE MATÉRIALISÉE 2 : Tableau de bord - Stats par matière
-- ============================================================

CREATE MATERIALIZED VIEW MV_STATS_PAR_MATIERE
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT
    m.id_matiere,
    m.code_matiere,
    m.nom_matiere,
    m.type_matiere,
    f.nom_filiere,
    sem.nom_semestre,
    COUNT(DISTINCT s.id_seance) AS nb_seances,
    COUNT(a.id_absence) AS total_absences,
    ROUND(COUNT(a.id_absence) / NULLIF(COUNT(DISTINCT s.id_seance), 0), 2) AS moyenne_absences_par_seance
FROM MATIERES m
JOIN FILIERES f ON m.id_filiere = f.id_filiere
JOIN SEMESTRES sem ON m.id_semestre = sem.id_semestre
LEFT JOIN SEANCES s ON m.id_matiere = s.id_matiere
LEFT JOIN ABSENCES a ON s.id_seance = a.id_seance
GROUP BY m.id_matiere, m.code_matiere, m.nom_matiere, m.type_matiere, f.nom_filiere, sem.nom_semestre;

-- ============================================================
-- VUE MATÉRIALISÉE 3 : Évolution mensuelle des absences
-- ============================================================

CREATE MATERIALIZED VIEW MV_EVOLUTION_MENSUELLE
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT
    TO_CHAR(a.date_absence, 'YYYY-MM') AS mois,
    TO_CHAR(a.date_absence, 'Month YYYY') AS mois_libelle,
    COUNT(*) AS total_absences,
    SUM(CASE WHEN a.est_justifiee = 0 THEN 1 ELSE 0 END) AS non_justifiees,
    SUM(CASE WHEN a.est_justifiee = 1 THEN 1 ELSE 0 END) AS justifiees,
    COUNT(DISTINCT a.id_etudiant) AS nb_etudiants_concernes
FROM ABSENCES a
GROUP BY TO_CHAR(a.date_absence, 'YYYY-MM'), TO_CHAR(a.date_absence, 'Month YYYY');

-- ============================================================
-- VUE MATÉRIALISÉE 4 : Statistiques globales (KPIs)
-- ============================================================

CREATE MATERIALIZED VIEW MV_KPI_GLOBAL
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT
    (SELECT COUNT(*) FROM ETUDIANTS WHERE statut = 'ACTIF') AS nb_etudiants_actifs,
    (SELECT COUNT(*) FROM ETUDIANTS WHERE statut = 'EXCLU') AS nb_etudiants_exclus,
    (SELECT COUNT(*) FROM ENSEIGNANTS WHERE statut = 'ACTIF') AS nb_enseignants,
    (SELECT COUNT(*) FROM SEANCES WHERE statut = 'EFFECTUEE') AS nb_seances_effectuees,
    (SELECT COUNT(*) FROM ABSENCES) AS total_absences,
    (SELECT COUNT(*) FROM ABSENCES WHERE est_justifiee = 0) AS absences_non_justifiees,
    (SELECT COUNT(*) FROM ABSENCES WHERE est_justifiee = 1) AS absences_justifiees,
    (SELECT COUNT(*) FROM JUSTIFICATIFS WHERE statut = 'EN_ATTENTE') AS justificatifs_en_attente,
    SYSDATE AS date_refresh
FROM DUAL;

-- ============================================================
-- Procédure pour rafraîchir toutes les vues matérialisées
-- ============================================================

CREATE OR REPLACE PROCEDURE REFRESH_ALL_MV AS
BEGIN
    DBMS_MVIEW.REFRESH('MV_STATS_PAR_GROUPE', 'C');
    DBMS_MVIEW.REFRESH('MV_STATS_PAR_MATIERE', 'C');
    DBMS_MVIEW.REFRESH('MV_EVOLUTION_MENSUELLE', 'C');
    DBMS_MVIEW.REFRESH('MV_KPI_GLOBAL', 'C');
END;
/

SELECT 'Vues et vues matérialisées créées avec succès !' AS RESULTAT FROM DUAL;

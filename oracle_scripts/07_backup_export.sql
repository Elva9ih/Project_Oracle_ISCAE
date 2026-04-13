-- ============================================================
-- PROJET ORACLE : Gestion des Absences Étudiants
-- Script 07 : Export, Sauvegarde et Automatisation
-- ============================================================

-- ============================================================
-- A) COMMANDES DATA PUMP (à exécuter via ligne de commande OS)
-- ============================================================

-- 1. Créer le répertoire Oracle pour les exports
-- Exécuter en tant que SYSTEM :
-- CREATE OR REPLACE DIRECTORY DATA_PUMP_DIR AS 'C:\oracle_backup';
-- GRANT READ, WRITE ON DIRECTORY DATA_PUMP_DIR TO gestion_absences;

-- 2. Export complet du schéma (exécuter en CMD Windows) :
-- expdp gestion_absences/gestion2025@localhost:1521/XE schemas=gestion_absences directory=DATA_PUMP_DIR dumpfile=absences_full_%U.dmp logfile=export_full.log

-- 3. Export de tables spécifiques :
-- expdp gestion_absences/gestion2025@localhost:1521/XE tables=ABSENCES,ETUDIANTS,SEANCES directory=DATA_PUMP_DIR dumpfile=absences_tables.dmp logfile=export_tables.log

-- 4. Import (restauration) :
-- impdp gestion_absences/gestion2025@localhost:1521/XE schemas=gestion_absences directory=DATA_PUMP_DIR dumpfile=absences_full_%U.dmp logfile=import_full.log

-- ============================================================
-- B) Script de configuration (exécuter en tant que SYSTEM)
-- ============================================================

CONNECT system/YOUR_PASSWORD@localhost:1521/XE;

-- Créer le répertoire de backup
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE DIRECTORY DATA_PUMP_DIR AS ''C:\oracle_backup''';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

GRANT READ, WRITE ON DIRECTORY DATA_PUMP_DIR TO gestion_absences;

-- ============================================================
-- C) Script batch Windows pour sauvegarde automatisée
-- Fichier : backup_oracle.bat
-- ============================================================

-- Contenu du fichier batch (à créer manuellement) :
--
-- @echo off
-- set ORACLE_SID=XE
-- set ORACLE_HOME=C:\app\chico\product\18.0.0\dbhomeXE
-- set PATH=%ORACLE_HOME%\bin;%PATH%
-- set BACKUP_DIR=C:\oracle_backup
-- set DATE_STR=%date:~-4%%date:~-7,2%%date:~-10,2%
--
-- echo ======================================
-- echo Sauvegarde Oracle - %DATE_STR%
-- echo ======================================
--
-- expdp gestion_absences/gestion2025@localhost:1521/XE ^
--   schemas=gestion_absences ^
--   directory=DATA_PUMP_DIR ^
--   dumpfile=backup_%DATE_STR%.dmp ^
--   logfile=backup_%DATE_STR%.log ^
--   compression=ALL
--
-- REM Supprimer les backups de plus de 30 jours
-- forfiles /p "%BACKUP_DIR%" /s /m *.dmp /d -30 /c "cmd /c del @path" 2>nul
-- forfiles /p "%BACKUP_DIR%" /s /m *.log /d -30 /c "cmd /c del @path" 2>nul
--
-- echo Sauvegarde terminée !

-- ============================================================
-- D) Planification via Tâche Windows (équivalent cron)
-- ============================================================

-- Exécuter en CMD administrateur :
-- schtasks /create /tn "Oracle_Backup_Daily" /tr "C:\oracle_backup\backup_oracle.bat" /sc daily /st 02:00

SELECT 'Script de backup configuré !' AS RESULTAT FROM DUAL;

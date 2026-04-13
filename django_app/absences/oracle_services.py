"""
Service layer: appels directs aux procédures et fonctions Oracle PL/SQL.
Toute la logique métier est côté Oracle, Django ne fait que l'appeler.
"""
from django.db import connection


def call_oracle_function(func_name, params=None, return_type='NUMBER'):
    """Appeler une fonction Oracle et retourner le résultat."""
    with connection.cursor() as cursor:
        if return_type == 'NUMBER':
            result = cursor.callfunc(func_name, float, params or [])
        else:
            result = cursor.callfunc(func_name, str, params or [])
        return result


def call_oracle_procedure(proc_name, params=None):
    """Appeler une procédure Oracle."""
    with connection.cursor() as cursor:
        cursor.callproc(proc_name, params or [])


def get_nb_absences(id_etudiant, id_semestre=None):
    """Nombre total d'absences d'un étudiant."""
    return int(call_oracle_function(
        'PKG_ABSENCES.GET_NB_ABSENCES',
        [id_etudiant, id_semestre]
    ))


def get_nb_absences_non_justifiees(id_etudiant, id_semestre=None):
    """Nombre d'absences non justifiées."""
    return int(call_oracle_function(
        'PKG_ABSENCES.GET_NB_ABSENCES_NON_JUSTIFIEES',
        [id_etudiant, id_semestre]
    ))


def get_taux_absence(id_etudiant, id_semestre=None):
    """Taux d'absence en pourcentage."""
    return call_oracle_function(
        'PKG_ABSENCES.GET_TAUX_ABSENCE',
        [id_etudiant, id_semestre]
    )


def get_statut_absences(id_etudiant):
    """Statut global d'un étudiant (NORMAL, AVERTISSEMENT, EXCLUSION)."""
    return call_oracle_function(
        'PKG_ABSENCES.EST_EN_DEPASSEMENT',
        [id_etudiant],
        return_type='STRING'
    )


def marquer_absence(id_etudiant, id_seance, motif=None, saisi_par='APP_USER'):
    """Marquer une absence via la procédure Oracle."""
    call_oracle_procedure(
        'PKG_ABSENCES.MARQUER_ABSENCE',
        [id_etudiant, id_seance, motif, saisi_par]
    )


def marquer_absences_bulk(id_seance, ids_etudiants, saisi_par='APP_USER'):
    """Marquer des absences en masse."""
    ids_csv = ','.join(str(i) for i in ids_etudiants)
    call_oracle_procedure(
        'PKG_ABSENCES.MARQUER_ABSENCES_BULK',
        [id_seance, ids_csv, saisi_par]
    )


def justifier_absence(id_absence, type_justificatif, description, fichier_path=None):
    """Soumettre un justificatif."""
    call_oracle_procedure(
        'PKG_ABSENCES.JUSTIFIER_ABSENCE',
        [id_absence, type_justificatif, description, fichier_path]
    )


def traiter_justificatif(id_justificatif, statut, commentaire=None, traite_par='ADMIN'):
    """Accepter ou refuser un justificatif."""
    call_oracle_procedure(
        'PKG_ABSENCES.TRAITER_JUSTIFICATIF',
        [id_justificatif, statut, commentaire, traite_par]
    )


def cloturer_semestre(id_semestre, traite_par='ADMIN'):
    """Clôturer un semestre."""
    call_oracle_procedure(
        'PKG_ABSENCES.CLOTURER_SEMESTRE',
        [id_semestre, traite_par]
    )


def refresh_materialized_views():
    """Rafraîchir toutes les vues matérialisées."""
    call_oracle_procedure('REFRESH_ALL_MV')


def get_kpi_global():
    """Récupérer les KPIs globaux depuis la vue matérialisée."""
    with connection.cursor() as cursor:
        cursor.execute("SELECT * FROM V_KPI_GLOBAL")
        columns = [col[0] for col in cursor.description]
        row = cursor.fetchone()
        if row:
            return dict(zip(columns, row))
        return {}


def get_stats_par_groupe():
    """Stats par groupe depuis la vue matérialisée."""
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT code_groupe, nom_groupe, nom_filiere, nb_etudiants,
                   total_absences, absences_non_justifiees, absences_justifiees,
                   moyenne_absences_par_etudiant
            FROM MV_STATS_PAR_GROUPE
            ORDER BY total_absences DESC
        """)
        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]


def get_stats_par_matiere():
    """Stats par matière depuis la vue matérialisée."""
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT code_matiere, nom_matiere, type_matiere, nom_filiere,
                   nb_seances, total_absences, moyenne_absences_par_seance
            FROM MV_STATS_PAR_MATIERE
            ORDER BY total_absences DESC
        """)
        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]


def get_evolution_mensuelle():
    """Évolution mensuelle des absences."""
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT mois, mois_libelle, total_absences, non_justifiees,
                   justifiees, nb_etudiants_concernes
            FROM MV_EVOLUTION_MENSUELLE
            ORDER BY mois
        """)
        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]


def execute_raw_query(sql, params=None):
    """Exécuter une requête SQL brute et retourner les résultats."""
    with connection.cursor() as cursor:
        cursor.execute(sql, params or [])
        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]

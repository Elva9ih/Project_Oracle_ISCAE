from django.urls import path
from . import views

urlpatterns = [
    # Dashboard
    path('', views.dashboard, name='dashboard'),

    # Étudiants CRUD
    path('etudiants/', views.etudiant_list, name='etudiant_list'),
    path('etudiants/ajouter/', views.etudiant_create, name='etudiant_create'),
    path('etudiants/<int:pk>/', views.etudiant_detail, name='etudiant_detail'),
    path('etudiants/<int:pk>/modifier/', views.etudiant_update, name='etudiant_update'),
    path('etudiants/<int:pk>/supprimer/', views.etudiant_delete, name='etudiant_delete'),

    # Enseignants CRUD
    path('enseignants/', views.enseignant_list, name='enseignant_list'),
    path('enseignants/ajouter/', views.enseignant_create, name='enseignant_create'),
    path('enseignants/<int:pk>/modifier/', views.enseignant_update, name='enseignant_update'),

    # Séances
    path('seances/', views.seance_list, name='seance_list'),
    path('seances/ajouter/', views.seance_create, name='seance_create'),

    # Absences
    path('absences/', views.absence_list, name='absence_list'),
    path('absences/marquer/', views.marquer_absences, name='marquer_absences'),

    # Justificatifs
    path('justificatifs/', views.justificatif_list, name='justificatif_list'),
    path('justificatifs/creer/<int:absence_id>/', views.justificatif_create, name='justificatif_create'),
    path('justificatifs/<int:pk>/traiter/', views.justificatif_traiter, name='justificatif_traiter'),

    # Statistiques
    path('stats/groupes/', views.stats_par_groupe, name='stats_groupe'),
    path('stats/matieres/', views.stats_par_matiere, name='stats_matiere'),

    # Audit
    path('audit/', views.audit_log, name='audit_log'),

    # Traitements Oracle
    path('traitements/', views.traitements, name='traitements'),

    # User Management
    path('utilisateurs/', views.user_list, name='user_list'),
    path('utilisateurs/creer/', views.user_create, name='user_create'),
    path('utilisateurs/<int:pk>/supprimer/', views.user_delete, name='user_delete'),

    # Exports
    path('export/excel/', views.export_absences_excel, name='export_excel'),
    path('export/pdf/', views.export_absences_pdf, name='export_pdf'),
]

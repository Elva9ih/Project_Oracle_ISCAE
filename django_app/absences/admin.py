from django.contrib import admin
from .models import (
    Filiere, Groupe, Semestre, Etudiant, Enseignant,
    Matiere, Seance, Absence, Justificatif, AuditLog, Notification
)

admin.site.site_header = "Gestion des Absences - ISCAE"
admin.site.site_title = "Admin Absences"

@admin.register(Filiere)
class FiliereAdmin(admin.ModelAdmin):
    list_display = ['code_filiere', 'nom_filiere']

@admin.register(Groupe)
class GroupeAdmin(admin.ModelAdmin):
    list_display = ['code_groupe', 'nom_groupe', 'id_filiere']

@admin.register(Etudiant)
class EtudiantAdmin(admin.ModelAdmin):
    list_display = ['cne', 'nom', 'prenom', 'id_groupe', 'statut']
    list_filter = ['statut', 'id_groupe']
    search_fields = ['cne', 'nom', 'prenom']

@admin.register(Enseignant)
class EnseignantAdmin(admin.ModelAdmin):
    list_display = ['matricule', 'nom', 'prenom', 'specialite', 'grade']

@admin.register(Absence)
class AbsenceAdmin(admin.ModelAdmin):
    list_display = ['id_absence', 'id_etudiant', 'id_seance', 'date_absence', 'est_justifiee']
    list_filter = ['est_justifiee', 'date_absence']

@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = ['table_name', 'operation', 'record_id', 'utilisateur', 'date_operation']
    list_filter = ['table_name', 'operation']

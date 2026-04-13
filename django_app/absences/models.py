from django.db import models
from django.contrib.auth.models import User


class UserProfile(models.Model):
    ROLE_CHOICES = [
        ('ADMIN', 'Administrateur'),
        ('ENSEIGNANT', 'Enseignant'),
        ('ETUDIANT', 'Étudiant'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='ETUDIANT')
    id_etudiant = models.ForeignKey('Etudiant', on_delete=models.SET_NULL, null=True, blank=True, db_column='ID_ETUDIANT_LINK')
    id_enseignant = models.ForeignKey('Enseignant', on_delete=models.SET_NULL, null=True, blank=True, db_column='ID_ENSEIGNANT_LINK')

    class Meta:
        db_table = 'USER_PROFILES'

    def __str__(self):
        return f"{self.user.username} ({self.get_role_display()})"

    @property
    def is_admin(self):
        return self.role == 'ADMIN'

    @property
    def is_enseignant(self):
        return self.role == 'ENSEIGNANT'

    @property
    def is_etudiant(self):
        return self.role == 'ETUDIANT'


class Filiere(models.Model):
    id_filiere = models.AutoField(primary_key=True, db_column='ID_FILIERE')
    code_filiere = models.CharField(max_length=20, unique=True, db_column='CODE_FILIERE')
    nom_filiere = models.CharField(max_length=100, db_column='NOM_FILIERE')
    description = models.CharField(max_length=500, blank=True, null=True, db_column='DESCRIPTION')
    date_creation = models.DateField(auto_now_add=True, db_column='DATE_CREATION')

    class Meta:
        managed = False
        db_table = 'FILIERES'

    def __str__(self):
        return f"{self.code_filiere} - {self.nom_filiere}"


class Groupe(models.Model):
    id_groupe = models.AutoField(primary_key=True, db_column='ID_GROUPE')
    code_groupe = models.CharField(max_length=20, unique=True, db_column='CODE_GROUPE')
    nom_groupe = models.CharField(max_length=100, db_column='NOM_GROUPE')
    id_filiere = models.ForeignKey(Filiere, on_delete=models.CASCADE, db_column='ID_FILIERE')
    annee_universitaire = models.CharField(max_length=9, db_column='ANNEE_UNIVERSITAIRE')

    class Meta:
        managed = False
        db_table = 'GROUPES'

    def __str__(self):
        return self.code_groupe


class Semestre(models.Model):
    id_semestre = models.AutoField(primary_key=True, db_column='ID_SEMESTRE')
    code_semestre = models.CharField(max_length=10, unique=True, db_column='CODE_SEMESTRE')
    nom_semestre = models.CharField(max_length=50, db_column='NOM_SEMESTRE')
    date_debut = models.DateField(db_column='DATE_DEBUT')
    date_fin = models.DateField(db_column='DATE_FIN')
    annee_universitaire = models.CharField(max_length=9, db_column='ANNEE_UNIVERSITAIRE')

    class Meta:
        managed = False
        db_table = 'SEMESTRES'

    def __str__(self):
        return self.nom_semestre


class Etudiant(models.Model):
    STATUT_CHOICES = [
        ('ACTIF', 'Actif'),
        ('SUSPENDU', 'Suspendu'),
        ('EXCLU', 'Exclu'),
        ('DIPLOME', 'Diplômé'),
    ]

    id_etudiant = models.AutoField(primary_key=True, db_column='ID_ETUDIANT')
    cne = models.CharField(max_length=20, unique=True, db_column='CNE')
    nom = models.CharField(max_length=50, db_column='NOM')
    prenom = models.CharField(max_length=50, db_column='PRENOM')
    date_naissance = models.DateField(db_column='DATE_NAISSANCE')
    email = models.CharField(max_length=100, blank=True, null=True, db_column='EMAIL')
    telephone = models.CharField(max_length=20, blank=True, null=True, db_column='TELEPHONE')
    adresse = models.CharField(max_length=200, blank=True, null=True, db_column='ADRESSE')
    id_groupe = models.ForeignKey(Groupe, on_delete=models.CASCADE, db_column='ID_GROUPE')
    statut = models.CharField(max_length=20, choices=STATUT_CHOICES, default='ACTIF', db_column='STATUT')
    date_inscription = models.DateField(auto_now_add=True, db_column='DATE_INSCRIPTION')

    class Meta:
        managed = False
        db_table = 'ETUDIANTS'

    def __str__(self):
        return f"{self.cne} - {self.nom} {self.prenom}"


class Enseignant(models.Model):
    id_enseignant = models.AutoField(primary_key=True, db_column='ID_ENSEIGNANT')
    matricule = models.CharField(max_length=20, unique=True, db_column='MATRICULE')
    nom = models.CharField(max_length=50, db_column='NOM')
    prenom = models.CharField(max_length=50, db_column='PRENOM')
    email = models.CharField(max_length=100, blank=True, null=True, db_column='EMAIL')
    telephone = models.CharField(max_length=20, blank=True, null=True, db_column='TELEPHONE')
    specialite = models.CharField(max_length=100, blank=True, null=True, db_column='SPECIALITE')
    grade = models.CharField(max_length=50, blank=True, null=True, db_column='GRADE')
    statut = models.CharField(max_length=20, default='ACTIF', db_column='STATUT')

    class Meta:
        managed = False
        db_table = 'ENSEIGNANTS'

    def __str__(self):
        return f"{self.matricule} - {self.nom} {self.prenom}"


class Matiere(models.Model):
    id_matiere = models.AutoField(primary_key=True, db_column='ID_MATIERE')
    code_matiere = models.CharField(max_length=20, unique=True, db_column='CODE_MATIERE')
    nom_matiere = models.CharField(max_length=100, db_column='NOM_MATIERE')
    coefficient = models.DecimalField(max_digits=3, decimal_places=1, db_column='COEFFICIENT')
    volume_horaire = models.IntegerField(db_column='VOLUME_HORAIRE')
    id_filiere = models.ForeignKey(Filiere, on_delete=models.CASCADE, db_column='ID_FILIERE')
    id_semestre = models.ForeignKey(Semestre, on_delete=models.CASCADE, db_column='ID_SEMESTRE')
    type_matiere = models.CharField(max_length=20, default='COURS', db_column='TYPE_MATIERE')

    class Meta:
        managed = False
        db_table = 'MATIERES'

    def __str__(self):
        return f"{self.code_matiere} - {self.nom_matiere}"


class Seance(models.Model):
    id_seance = models.AutoField(primary_key=True, db_column='ID_SEANCE')
    id_matiere = models.ForeignKey(Matiere, on_delete=models.CASCADE, db_column='ID_MATIERE')
    id_enseignant = models.ForeignKey(Enseignant, on_delete=models.CASCADE, db_column='ID_ENSEIGNANT')
    id_groupe = models.ForeignKey(Groupe, on_delete=models.CASCADE, db_column='ID_GROUPE')
    date_seance = models.DateField(db_column='DATE_SEANCE')
    heure_debut = models.CharField(max_length=5, db_column='HEURE_DEBUT')
    heure_fin = models.CharField(max_length=5, db_column='HEURE_FIN')
    salle = models.CharField(max_length=30, blank=True, null=True, db_column='SALLE')
    type_seance = models.CharField(max_length=20, default='COURS', db_column='TYPE_SEANCE')
    statut = models.CharField(max_length=20, default='PLANIFIEE', db_column='STATUT')

    class Meta:
        managed = False
        db_table = 'SEANCES'

    def __str__(self):
        return f"Séance {self.id_seance} - {self.date_seance}"


class Absence(models.Model):
    id_absence = models.AutoField(primary_key=True, db_column='ID_ABSENCE')
    id_etudiant = models.ForeignKey(Etudiant, on_delete=models.CASCADE, db_column='ID_ETUDIANT')
    id_seance = models.ForeignKey(Seance, on_delete=models.CASCADE, db_column='ID_SEANCE')
    date_absence = models.DateField(db_column='DATE_ABSENCE')
    est_justifiee = models.IntegerField(default=0, db_column='EST_JUSTIFIEE')
    motif = models.CharField(max_length=200, blank=True, null=True, db_column='MOTIF')
    date_saisie = models.DateField(auto_now_add=True, db_column='DATE_SAISIE')
    saisi_par = models.CharField(max_length=50, blank=True, null=True, db_column='SAISI_PAR')

    class Meta:
        managed = False
        db_table = 'ABSENCES'

    def __str__(self):
        return f"Absence {self.id_absence}"


class Justificatif(models.Model):
    id_justificatif = models.AutoField(primary_key=True, db_column='ID_JUSTIFICATIF')
    id_absence = models.ForeignKey(Absence, on_delete=models.CASCADE, db_column='ID_ABSENCE')
    type_justificatif = models.CharField(max_length=50, db_column='TYPE_JUSTIFICATIF')
    description = models.CharField(max_length=500, blank=True, null=True, db_column='DESCRIPTION')
    fichier_path = models.CharField(max_length=300, blank=True, null=True, db_column='FICHIER_PATH')
    date_soumission = models.DateField(auto_now_add=True, db_column='DATE_SOUMISSION')
    date_traitement = models.DateField(blank=True, null=True, db_column='DATE_TRAITEMENT')
    statut = models.CharField(max_length=20, default='EN_ATTENTE', db_column='STATUT')
    traite_par = models.CharField(max_length=50, blank=True, null=True, db_column='TRAITE_PAR')
    commentaire = models.CharField(max_length=500, blank=True, null=True, db_column='COMMENTAIRE')

    class Meta:
        managed = False
        db_table = 'JUSTIFICATIFS'

    def __str__(self):
        return f"Justificatif {self.id_justificatif}"


class AuditLog(models.Model):
    id_audit = models.AutoField(primary_key=True, db_column='ID_AUDIT')
    table_name = models.CharField(max_length=50, db_column='TABLE_NAME')
    operation = models.CharField(max_length=10, db_column='OPERATION')
    record_id = models.IntegerField(blank=True, null=True, db_column='RECORD_ID')
    old_values = models.TextField(blank=True, null=True, db_column='OLD_VALUES')
    new_values = models.TextField(blank=True, null=True, db_column='NEW_VALUES')
    utilisateur = models.CharField(max_length=50, blank=True, null=True, db_column='UTILISATEUR')
    date_operation = models.DateTimeField(db_column='DATE_OPERATION')

    class Meta:
        managed = False
        db_table = 'AUDIT_LOG'
        ordering = ['-date_operation']

    def __str__(self):
        return f"{self.operation} on {self.table_name} at {self.date_operation}"


class Notification(models.Model):
    id_notification = models.AutoField(primary_key=True, db_column='ID_NOTIFICATION')
    id_etudiant = models.ForeignKey(Etudiant, on_delete=models.CASCADE, db_column='ID_ETUDIANT')
    type_notification = models.CharField(max_length=50, db_column='TYPE_NOTIFICATION')
    message = models.CharField(max_length=500, db_column='MESSAGE')
    est_lue = models.IntegerField(default=0, db_column='EST_LUE')
    date_creation = models.DateTimeField(db_column='DATE_CREATION')

    class Meta:
        managed = False
        db_table = 'NOTIFICATIONS'
        ordering = ['-date_creation']

    def __str__(self):
        return f"Notification {self.id_notification}"

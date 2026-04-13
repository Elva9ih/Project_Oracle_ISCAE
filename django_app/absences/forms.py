from django import forms
from .models import Etudiant, Enseignant, Seance, Groupe, Matiere, Filiere, UserProfile


class BootstrapMixin:
    """Auto-add Bootstrap classes to all form fields."""
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        for name, field in self.fields.items():
            widget = field.widget
            if isinstance(widget, forms.CheckboxSelectMultiple):
                continue
            if isinstance(widget, (forms.CheckboxInput,)):
                widget.attrs.setdefault('class', 'form-check-input')
            elif isinstance(widget, (forms.Select, forms.SelectMultiple)):
                widget.attrs.setdefault('class', 'form-select')
            elif isinstance(widget, forms.FileInput):
                widget.attrs.setdefault('class', 'form-control')
            elif isinstance(widget, forms.Textarea):
                widget.attrs.setdefault('class', 'form-control')
            else:
                widget.attrs.setdefault('class', 'form-control')


class EtudiantForm(BootstrapMixin, forms.ModelForm):
    class Meta:
        model = Etudiant
        fields = ['cne', 'nom', 'prenom', 'date_naissance', 'email', 'telephone', 'adresse', 'id_groupe', 'statut']
        widgets = {
            'date_naissance': forms.DateInput(attrs={'type': 'date'}),
        }


class EnseignantForm(BootstrapMixin, forms.ModelForm):
    class Meta:
        model = Enseignant
        fields = ['matricule', 'nom', 'prenom', 'email', 'telephone', 'specialite', 'grade', 'statut']


class SeanceForm(BootstrapMixin, forms.ModelForm):
    class Meta:
        model = Seance
        fields = ['id_matiere', 'id_enseignant', 'id_groupe', 'date_seance', 'heure_debut', 'heure_fin', 'salle', 'type_seance', 'statut']
        widgets = {
            'date_seance': forms.DateInput(attrs={'type': 'date'}),
        }


class MarquerAbsenceForm(BootstrapMixin, forms.Form):
    seance = forms.ModelChoiceField(
        queryset=Seance.objects.all().order_by('-date_seance'),
        label='Séance'
    )
    etudiants = forms.ModelMultipleChoiceField(
        queryset=Etudiant.objects.filter(statut='ACTIF'),
        widget=forms.CheckboxSelectMultiple,
        label='Étudiants absents'
    )
    motif = forms.CharField(max_length=200, required=False, label='Motif')

    def __init__(self, *args, **kwargs):
        groupe_id = kwargs.pop('groupe_id', None)
        super().__init__(*args, **kwargs)
        if groupe_id:
            self.fields['etudiants'].queryset = Etudiant.objects.filter(
                id_groupe=groupe_id, statut='ACTIF'
            ).order_by('nom', 'prenom')
            self.fields['seance'].queryset = Seance.objects.filter(
                id_groupe=groupe_id
            ).order_by('-date_seance')


class JustificatifForm(BootstrapMixin, forms.Form):
    TYPE_CHOICES = [
        ('MEDICAL', 'Médical'),
        ('FAMILIAL', 'Familial'),
        ('ADMINISTRATIF', 'Administratif'),
        ('AUTRE', 'Autre'),
    ]
    type_justificatif = forms.ChoiceField(choices=TYPE_CHOICES, label='Type')
    description = forms.CharField(widget=forms.Textarea(attrs={'rows': 3}), label='Description')
    fichier = forms.FileField(required=False, label='Fichier justificatif')


class TraiterJustificatifForm(BootstrapMixin, forms.Form):
    STATUT_CHOICES = [
        ('ACCEPTE', 'Accepter'),
        ('REFUSE', 'Refuser'),
    ]
    statut = forms.ChoiceField(choices=STATUT_CHOICES, label='Décision')
    commentaire = forms.CharField(
        widget=forms.Textarea(attrs={'rows': 2}),
        required=False,
        label='Commentaire'
    )


class FiltreAbsencesForm(BootstrapMixin, forms.Form):
    groupe = forms.ModelChoiceField(
        queryset=Groupe.objects.all(),
        required=False,
        label='Groupe'
    )
    matiere = forms.ModelChoiceField(
        queryset=Matiere.objects.all(),
        required=False,
        label='Matière'
    )
    date_debut = forms.DateField(
        required=False,
        widget=forms.DateInput(attrs={'type': 'date'}),
        label='Date début'
    )
    date_fin = forms.DateField(
        required=False,
        widget=forms.DateInput(attrs={'type': 'date'}),
        label='Date fin'
    )
    justifiee = forms.ChoiceField(
        choices=[('', 'Toutes'), ('0', 'Non justifiées'), ('1', 'Justifiées')],
        required=False,
        label='Justifiée'
    )


class UserCreateForm(BootstrapMixin, forms.Form):
    username = forms.CharField(max_length=150, label="Nom d'utilisateur")
    password = forms.CharField(widget=forms.PasswordInput, label='Mot de passe')
    first_name = forms.CharField(max_length=30, required=False, label='Prénom')
    last_name = forms.CharField(max_length=150, required=False, label='Nom')
    email = forms.EmailField(required=False, label='Email')
    role = forms.ChoiceField(choices=UserProfile.ROLE_CHOICES, label='Rôle')
    id_etudiant = forms.ModelChoiceField(
        queryset=Etudiant.objects.all().order_by('nom', 'prenom'),
        required=False,
        label='Lier à un étudiant'
    )
    id_enseignant = forms.ModelChoiceField(
        queryset=Enseignant.objects.all().order_by('nom', 'prenom'),
        required=False,
        label='Lier à un enseignant'
    )

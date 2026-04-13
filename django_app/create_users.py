import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'gestion_absences.settings')
sys.path.insert(0, os.path.dirname(__file__))
django.setup()

from django.contrib.auth.models import User
from absences.models import UserProfile, Etudiant, Enseignant

# 1. Create profile for admin
admin_user = User.objects.get(username='admin')
profile, created = UserProfile.objects.get_or_create(user=admin_user, defaults={'role': 'ADMIN'})
if created:
    print("Admin profile created")
else:
    print("Admin profile already exists")

# 2. Create a teacher account linked to first enseignant
ens = Enseignant.objects.first()
if ens:
    teacher_user, created = User.objects.get_or_create(
        username='enseignant1',
        defaults={'first_name': ens.prenom, 'last_name': ens.nom, 'email': ens.email or ''}
    )
    if created:
        teacher_user.set_password('ens12345')
        teacher_user.save()
    UserProfile.objects.get_or_create(
        user=teacher_user,
        defaults={'role': 'ENSEIGNANT', 'id_enseignant': ens}
    )
    print(f"Teacher account: enseignant1 / ens12345 (linked to {ens})")

# 3. Create a student account linked to first etudiant
etud = Etudiant.objects.first()
if etud:
    student_user, created = User.objects.get_or_create(
        username='etudiant1',
        defaults={'first_name': etud.prenom, 'last_name': etud.nom, 'email': etud.email or ''}
    )
    if created:
        student_user.set_password('etu12345')
        student_user.save()
    UserProfile.objects.get_or_create(
        user=student_user,
        defaults={'role': 'ETUDIANT', 'id_etudiant': etud}
    )
    print(f"Student account: etudiant1 / etu12345 (linked to {etud})")

print("\nDone! 3 accounts ready.")

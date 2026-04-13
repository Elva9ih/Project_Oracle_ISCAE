from .decorators import get_user_role


def user_role(request):
    """Add user role to all templates."""
    if request.user.is_authenticated:
        role = get_user_role(request.user)
        return {
            'user_role': role,
            'is_admin': role == 'ADMIN',
            'is_enseignant': role == 'ENSEIGNANT',
            'is_etudiant': role == 'ETUDIANT',
        }
    return {'user_role': None, 'is_admin': False, 'is_enseignant': False, 'is_etudiant': False}

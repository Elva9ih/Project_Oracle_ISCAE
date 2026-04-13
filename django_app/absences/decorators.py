from functools import wraps
from django.shortcuts import redirect
from django.contrib import messages


def get_user_role(user):
    """Get role from user profile, default to ADMIN for superusers."""
    if user.is_superuser:
        return 'ADMIN'
    try:
        return user.profile.role
    except Exception:
        return None


def role_required(*roles):
    """Decorator: only allow users with specified roles."""
    def decorator(view_func):
        @wraps(view_func)
        def wrapper(request, *args, **kwargs):
            user_role = get_user_role(request.user)
            if user_role in roles:
                return view_func(request, *args, **kwargs)
            messages.error(request, "Vous n'avez pas les droits pour accéder à cette page.")
            return redirect('dashboard')
        return wrapper
    return decorator


def admin_required(view_func):
    return role_required('ADMIN')(view_func)


def enseignant_required(view_func):
    return role_required('ADMIN', 'ENSEIGNANT')(view_func)


def etudiant_required(view_func):
    return role_required('ADMIN', 'ETUDIANT')(view_func)

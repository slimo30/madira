from rest_framework.permissions import BasePermission
from .models import User

class IsAdmin(BasePermission):
    """Allow only admins"""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == User.Role.ADMIN


class IsAdminOrResponsible(BasePermission):
    """Allow admins and responsible users"""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role in [
            User.Role.ADMIN, User.Role.RESPONSIBLE
        ]

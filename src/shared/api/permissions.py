from rest_framework.permissions import (
    BasePermission,
)
from rest_framework.permissions import (
    IsAuthenticated as DRFIsAuthenticated,
)


class IsAuthenticatedAndActive(DRFIsAuthenticated):

    def has_permission(self, request, view):
        return bool(
            super().has_permission(request, view) and
            request.user.is_active
        )
    
class HasGroupPermission(BasePermission):

    def has_permission(self, request, view):
        required_groups = getattr(view, 'required_groups', [])
        if not required_groups:
            return True
        return request.user.groups.filter(name__in=required_groups).exists()

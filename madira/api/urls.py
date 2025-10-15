# api/urls.py

from django.urls import path
from .views import (
    test_api,
    LoginView,
    CreateUserView,
    ListUsersView,
    GetUserByIdView,
    GetCurrentUserView,
    DeactivateUserView,
    ReactivateUserView,
    LogoutView, 
)

urlpatterns = [
    # Test endpoint
    path('test/', test_api, name='test-api'),
    
    # Authentication
    path('login/', LoginView.as_view(), name='login'),
    path('logout/', LogoutView.as_view(), name='logout'),  

    # User management
    path('users/', ListUsersView.as_view(), name='list-users'),
    path('users/create/', CreateUserView.as_view(), name='create-user'),
    path('users/me/', GetCurrentUserView.as_view(), name='current-user'),
    path('users/<int:id>/', GetUserByIdView.as_view(), name='get-user'),
    
    # User activation/deactivation (Admin only)
    path('users/<int:user_id>/deactivate/', DeactivateUserView.as_view(), name='deactivate-user'),
    path('users/<int:user_id>/reactivate/', ReactivateUserView.as_view(), name='reactivate-user'),
]
from django.urls import path
from .views import LoginView, CreateUserView, ListUsersView 
from . import views  # ✅ This line is essential

urlpatterns = [
    path('test/', views.test_api, name='test-api'),
    path('login/', LoginView.as_view(), name='login'),
    path('users/', ListUsersView.as_view(), name='list-users'),
    path('users/create/', CreateUserView.as_view(), name='create-user'),
]

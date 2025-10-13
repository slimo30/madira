from rest_framework import generics, permissions
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from .models import User
from .serializers import UserSerializer, CreateUserSerializer



from django.http import JsonResponse

def test_api(request):
    return JsonResponse({"message": "API is working!"})


# ---------------------------
# JWT Login View
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.views import TokenObtainPairView

class MyTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        # Add custom claims to the token
        token['username'] = user.username
        token['role'] = user.role
        return token

    def validate(self, attrs):
        data = super().validate(attrs)
        # Add extra fields to the response body
        data['username'] = self.user.username
        data['role'] = self.user.role
        return data


class LoginView(TokenObtainPairView):
    serializer_class = MyTokenObtainPairSerializer


# ---------------------------
# Create User (POST)
# ---------------------------
class CreateUserView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = CreateUserSerializer
    permission_classes = [permissions.IsAdminUser]  # only admins can create users


# ---------------------------
# List Users (GET)
# ---------------------------
class ListUsersView(generics.ListAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

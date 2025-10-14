from rest_framework import generics, permissions, views, status
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import AccessToken
from django.contrib.auth import authenticate
from django.http import JsonResponse
from django.shortcuts import get_object_or_404
from .models import User
from .serializers import UserSerializer, CreateUserSerializer


def test_api(request):
    return JsonResponse({"message": "API is working!"})


# ---------------------------
# Simple JWT Login View
# ---------------------------
class LoginView(views.APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')

        if not username or not password:
            return Response(
                {"error": "Username and password are required."},
                status=status.HTTP_400_BAD_REQUEST
            )

        user = authenticate(username=username, password=password)

        if user is None:
            return Response(
                {"error": "Invalid credentials."},
                status=status.HTTP_401_UNAUTHORIZED
            )

        if not user.is_active:
            return Response(
                {"error": "Account is deactivated."},
                status=status.HTTP_403_FORBIDDEN
            )

        # Generate access token (valid for 2 days as configured in settings.py)
        access_token = AccessToken.for_user(user)
        access_token['username'] = user.username
        access_token['role'] = user.role

        return Response({
            "access": str(access_token),
            "username": user.username,
            "role": user.role
        }, status=status.HTTP_200_OK)




# ---------------------------
# Create User (POST)
# ---------------------------
class CreateUserView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = CreateUserSerializer
    permission_classes = [permissions.IsAdminUser]


# ---------------------------
# List Users (GET)
# ---------------------------
class ListUsersView(generics.ListAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]


# ---------------------------
# Get User by ID (GET)
# ---------------------------
class GetUserByIdView(generics.RetrieveAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]
    lookup_field = 'id'


# ---------------------------
# Get Current User (GET)
# ---------------------------
class GetCurrentUserView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data, status=status.HTTP_200_OK)


class DeactivateUserView(views.APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, user_id):
        user = get_object_or_404(User, id=user_id)
        
        if user.id == request.user.id:
            return Response(
                {"error": "You cannot deactivate your own account."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user.is_active = False
        user.save()
        
        return Response(
            {"message": f"User {user.username} has been deactivated."},
            status=status.HTTP_200_OK
        )



# ---------------------------
# Reactivate User (POST)
# ---------------------------
class ReactivateUserView(views.APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, user_id):
        user = get_object_or_404(User, id=user_id)
        
        user.is_active = True
        user.save()
        
        return Response(
            {"message": f"User {user.username} has been reactivated."},
            status=status.HTTP_200_OK
        )

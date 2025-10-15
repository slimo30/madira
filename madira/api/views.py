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


# views.py (ADD THIS TO YOUR EXISTING FILE)

from rest_framework import views, permissions, status
from rest_framework.response import Response
from .models import BlacklistedToken
from datetime import timedelta
from django.utils import timezone

class LogoutView(views.APIView):
    """
    Logout endpoint - adds current JWT token to blacklist
    and automatically cleans up expired tokens older than 30 days
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        try:
            # Extract token from Authorization header
            auth_header = request.META.get('HTTP_AUTHORIZATION', '')
            
            if not auth_header.startswith('Bearer '):
                return Response(
                    {"error": "Invalid authorization header"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            token = auth_header.split(' ')[1]
            
            # Check if already blacklisted
            if BlacklistedToken.objects.filter(token=token).exists():
                return Response(
                    {"message": "Already logged out"},
                    status=status.HTTP_200_OK
                )
            
            # Get optional metadata
            ip_address = self.get_client_ip(request)
            user_agent = request.META.get('HTTP_USER_AGENT', '')[:255]
            
            # Add token to blacklist
            BlacklistedToken.objects.create(
                token=token,
                user=request.user,
                ip_address=ip_address,
                user_agent=user_agent
            )
            
            # AUTOMATIC CLEANUP: Delete tokens older than 30 days
            cleanup_result = self.cleanup_expired_tokens(days=30)
            
            response_data = {
                "message": "Successfully logged out",
                "detail": "Your session has been terminated"
            }
            
            # Optional: Include cleanup info in response (for debugging)
            if cleanup_result['deleted_count'] > 0:
                response_data['cleanup'] = f"Cleaned up {cleanup_result['deleted_count']} expired tokens"
            
            return Response(response_data, status=status.HTTP_200_OK)
        
        except Exception as e:
            return Response(
                {"error": f"Logout failed: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def get_client_ip(self, request):
        """Extract client IP address"""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0].strip()
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip
    
    def cleanup_expired_tokens(self, days=30):
        """
        Delete blacklisted tokens older than specified days.
        Since tokens expire after 30 days, there's no need to keep
        blacklisted tokens older than that in the database.
        
        Args:
            days (int): Number of days after which tokens should be removed
            
        Returns:
            dict: Information about the cleanup operation
        """
        try:
            # Calculate cutoff date
            cutoff_date = timezone.now() - timedelta(minutes=2)
            
            # Delete old tokens
            deleted_count, _ = BlacklistedToken.objects.filter(
                blacklisted_at__lt=cutoff_date
            ).delete()
            
            return {
                'success': True,
                'deleted_count': deleted_count,
                'cutoff_date': cutoff_date
            }
        
        except Exception as e:
            # Log error but don't fail logout if cleanup fails
            print(f"Token cleanup error: {str(e)}")
            return {
                'success': False,
                'deleted_count': 0,
                'error': str(e)
            }
# middleware.py

from django.utils.deprecation import MiddlewareMixin
from django.http import JsonResponse
from .models import BlacklistedToken


class TokenBlacklistMiddleware(MiddlewareMixin):
    """
    Checks every incoming request to see if JWT token is blacklisted.
    If blacklisted, returns 401 Unauthorized immediately.
    """
    
    def process_request(self, request):
        # Skip check for certain paths
        excluded_paths = [
            '/api/login/',
            '/api/logout/',
            '/admin/',
            '/api/docs/',
        ]
        
        # Don't check if path is excluded
        if any(request.path.startswith(path) for path in excluded_paths):
            return None
        
        # Only check API endpoints
        if not request.path.startswith('/api/'):
            return None
        
        # Get Authorization header
        auth_header = request.META.get('HTTP_AUTHORIZATION', '')
        
        if auth_header.startswith('Bearer '):
            token = auth_header.split(' ')[1]
            
            # Check if token exists in blacklist
            if BlacklistedToken.objects.filter(token=token).exists():
                return JsonResponse(
                    {
                        "error": "Token has been invalidated",
                        "detail": "This session has been terminated. Please login again.",
                        "code": "TOKEN_BLACKLISTED"
                    },
                    status=401
                )
        
        # Token is valid, continue processing
        return None
import os
import django
import sys

def create_or_update_superuser():
    try:
        # Setup Django environment
        os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'madira.settings')
        django.setup()

        from django.contrib.auth import get_user_model
        
        User = get_user_model()
        USERNAME = 'madira'
        # Pre-hashed password (PBKDF2 SHA256)
        # This hash corresponds to the secure admin password
        PASSWORD_HASH = 'pbkdf2_sha256$1000000$A6drN9HKhUpfW1GUJtkXa4$F7nFsdfxYu2sTRW27Y1cpU6Y1+rkm5+rQ5iQwx8Ym0o='

        user = User.objects.filter(username=USERNAME).first()
        
        if not user:
            print(f"Creating new superuser '{USERNAME}'...")
            user = User(username=USERNAME)
        else:
            print(f"Updating existing user '{USERNAME}'...")

        # Set attributes directly (including the hashed password)
        user.password = PASSWORD_HASH
        user.is_staff = True
        user.is_superuser = True
        user.is_active = True
        # Ensure role is admin
        if hasattr(user, 'role'):
            user.role = 'admin'
            
        user.save()
        
        print(f"Successfully configured user '{USERNAME}' with admin privileges.")
            
    except Exception as e:
        print(f"ERROR: Failed to create/update superuser: {e}")
        sys.exit(1)

if __name__ == '__main__':
    create_or_update_superuser()

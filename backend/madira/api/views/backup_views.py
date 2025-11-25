import subprocess
import os
import time
import sqlite3
from datetime import datetime
from django.http import HttpResponse, JsonResponse
from django.conf import settings
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.core.management import call_command
from io import StringIO
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework import serializers
import shutil
import tempfile




class DatabaseBackupView(APIView):
    """
    Create a SQL backup of the entire database.
    GET /api/backup/download/
    
    Returns: SQL file that can be used to restore the database
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        """Generate and download SQL backup"""
        try:
            print("="*80)
            print("🗄️  DATABASE BACKUP STARTED")
            print(f"   Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            print("="*80)
            
            start_time = time.time()
            
            # Get database settings
            db_settings = settings.DATABASES['default']
            db_engine = db_settings['ENGINE']
            
            print(f"📊 Database Engine: {db_engine}")
            
            # Generate SQL dump based on database type
            if 'sqlite' in db_engine:
                sql_dump = self._backup_sqlite(db_settings)
            elif 'postgresql' in db_engine:
                sql_dump = self._backup_postgresql(db_settings)
            elif 'mysql' in db_engine:
                sql_dump = self._backup_mysql(db_settings)
            else:
                return Response({
                    'success': False,
                    'error': f'Database engine {db_engine} is not supported for backup'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Calculate backup time
            backup_time = time.time() - start_time
            backup_size_mb = len(sql_dump.encode('utf-8')) / (1024 * 1024)
            
            print("="*80)
            print("✅ DATABASE BACKUP COMPLETED")
            print(f"   Time: {backup_time:.2f} seconds")
            print(f"   Size: {backup_size_mb:.2f} MB")
            print(f"   Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            print("="*80)
            
            # Create HTTP response with SQL file
            response = HttpResponse(sql_dump, content_type='application/sql')
            filename = f"madira_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.sql"
            response['Content-Disposition'] = f'attachment; filename="{filename}"'
            
            return response
            
        except Exception as e:
            print(f"❌ Backup failed: {str(e)}")
            import traceback
            traceback.print_exc()
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    def _backup_sqlite(self, db_settings):
        """Backup SQLite database to SQL dump"""
        db_path = str(db_settings['NAME'])
        
        print(f"📂 Database file: {db_path}")
        
        if not os.path.exists(db_path):
            raise FileNotFoundError(f"Database file not found: {db_path}")
        
        try:
            # Method 1: Try using sqlite3 command line tool
            print("🔧 Using sqlite3 command to create backup...")
            result = subprocess.run(
                ['sqlite3', db_path, '.dump'],
                capture_output=True,
                text=True,
                check=False,
                timeout=300  # 5 minute timeout
            )
            
            if result.returncode == 0 and result.stdout:
                sql_dump = result.stdout
                
                # Verify the dump has content
                if len(sql_dump) < 100:
                    raise Exception("Generated backup is too small, may be incomplete")
                
                # Add header
                header = f"""-- Madira Database Backup
-- Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
-- Database: SQLite
-- File: {db_path}
-- Size: {os.path.getsize(db_path) / (1024 * 1024):.2f} MB

"""
                print("✅ SQLite backup created successfully using sqlite3 command")
                return header + sql_dump
            else:
                # Fall through to Python method
                print(f"⚠️  sqlite3 command failed or produced no output: {result.stderr}")
                raise FileNotFoundError("sqlite3 not available")
                
        except (FileNotFoundError, subprocess.TimeoutExpired) as e:
            # Method 2: Use Python sqlite3 module (more reliable)
            print("🐍 Using Python sqlite3 module to create backup...")
            
            conn = sqlite3.connect(db_path)
            sql_dump_lines = []
            
            for line in conn.iterdump():
                sql_dump_lines.append(line)
            
            conn.close()
            
            sql_dump = '\n'.join(sql_dump_lines)
            
            # Verify the dump has content
            if len(sql_dump) < 100:
                raise Exception("Generated backup is too small, may be incomplete")
            
            # Add header
            header = f"""-- Madira Database Backup
-- Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
-- Database: SQLite
-- File: {db_path}
-- Size: {os.path.getsize(db_path) / (1024 * 1024):.2f} MB
-- Method: Python sqlite3 module

"""
            print("✅ SQLite backup created successfully using Python")
            return header + sql_dump
    
    def _backup_postgresql(self, db_settings):
        """Backup PostgreSQL database to SQL dump"""
        db_name = db_settings['NAME']
        db_user = db_settings.get('USER', 'postgres')
        db_password = db_settings.get('PASSWORD', '')
        db_host = db_settings.get('HOST', 'localhost')
        db_port = db_settings.get('PORT', '5432')
        
        print(f"🐘 PostgreSQL: {db_user}@{db_host}:{db_port}/{db_name}")
        
        # Set password environment variable
        env = os.environ.copy()
        if db_password:
            env['PGPASSWORD'] = db_password
        
        # Run pg_dump
        cmd = [
            'pg_dump',
            '-h', db_host,
            '-p', str(db_port),
            '-U', db_user,
            '--no-owner',
            '--no-acl',
            '--clean',
            '--if-exists',
            db_name
        ]
        
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            env=env,
            check=True,
            timeout=600  # 10 minute timeout
        )
        
        header = f"""-- Madira Database Backup
-- Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
-- Database: PostgreSQL
-- Database Name: {db_name}

"""
        print("✅ PostgreSQL backup created successfully")
        return header + result.stdout
    
    def _backup_mysql(self, db_settings):
        """Backup MySQL database to SQL dump"""
        db_name = db_settings['NAME']
        db_user = db_settings.get('USER', 'root')
        db_password = db_settings.get('PASSWORD', '')
        db_host = db_settings.get('HOST', 'localhost')
        db_port = db_settings.get('PORT', '3306')
        
        print(f"🐬 MySQL: {db_user}@{db_host}:{db_port}/{db_name}")
        
        # Build mysqldump command
        cmd = [
            'mysqldump',
            '-h', db_host,
            '-P', str(db_port),
            '-u', db_user
        ]
        
        if db_password:
            cmd.append(f'--password={db_password}')
        
        cmd.extend([
            '--single-transaction',
            '--quick',
            '--lock-tables=false',
            '--add-drop-table',
            db_name
        ])
        
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=True,
            timeout=600  # 10 minute timeout
        )
        
        header = f"""-- Madira Database Backup
-- Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
-- Database: MySQL
-- Database Name: {db_name}

"""
        print("✅ MySQL backup created successfully")
        return header + result.stdout



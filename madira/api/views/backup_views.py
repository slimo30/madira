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


class RestoreSerializer(serializers.Serializer):
    """Serializer for database restore - shows file upload field in DRF"""
    file = serializers.FileField(required=False, help_text="Upload SQL backup file")
    sql = serializers.CharField(required=False, help_text="Or paste SQL content directly", style={'base_template': 'textarea.html'})
    
    def validate(self, data):
        if not data.get('file') and not data.get('sql'):
            raise serializers.ValidationError("Either 'file' or 'sql' must be provided")
        return data


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


class DatabaseRestoreView(APIView):
    """
    Restore database from SQL backup file.
    POST /api/backup/restore/
    
    Body: 
    - file: SQL backup file (multipart/form-data)
    OR
    - sql: SQL content as text (application/json)
    """
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    serializer_class = RestoreSerializer
    
    def get_serializer(self, *args, **kwargs):
        """Return serializer instance for DRF to render the form"""
        return RestoreSerializer(*args, **kwargs)
    
    def get(self, request):
        """Show restore form - GET method for DRF browsable API"""
        serializer = self.get_serializer()
        return Response({
            'message': 'Upload a SQL backup file to restore the database',
            'instructions': {
                'method': 'POST',
                'content_type': 'multipart/form-data or application/json',
                'option_1': 'Upload file: Send "file" field with SQL backup file',
                'option_2': 'Or send JSON with "sql" field containing SQL content',
                'example_curl': 'curl -X POST -H "Authorization: Bearer YOUR_TOKEN" -F "file=@backup.sql" http://localhost:8000/api/backup/restore/'
            },
            'warning': '⚠️ Restoring will overwrite the current database. For SQLite, an automatic backup will be created.',
            'database_info': self._get_db_info()
        })
    
    def _get_db_info(self):
        """Get current database information"""
        db_settings = settings.DATABASES['default']
        db_engine = db_settings['ENGINE']
        
        if 'sqlite' in db_engine:
            db_path = str(db_settings['NAME'])
            return {
                'type': 'SQLite',
                'file': db_path,
                'exists': os.path.exists(db_path),
                'size_mb': round(os.path.getsize(db_path) / (1024 * 1024), 2) if os.path.exists(db_path) else 0
            }
        elif 'postgresql' in db_engine:
            return {
                'type': 'PostgreSQL',
                'name': db_settings['NAME'],
                'host': db_settings.get('HOST', 'localhost')
            }
        elif 'mysql' in db_engine:
            return {
                'type': 'MySQL',
                'name': db_settings['NAME'],
                'host': db_settings.get('HOST', 'localhost')
            }
        else:
            return {'type': 'Unknown'}
    
    def post(self, request):
        """Restore database from SQL backup"""
        serializer = RestoreSerializer(data=request.data)
        
        if not serializer.is_valid():
            return Response({
                'success': False,
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            print("="*80)
            print("🔄 DATABASE RESTORE STARTED")
            print(f"   Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            print(f"   User: {request.user.username}")
            print("="*80)
            
            start_time = time.time()
            
            # Get SQL content from validated data
            if 'file' in serializer.validated_data and serializer.validated_data['file']:
                sql_file = serializer.validated_data['file']
                print(f"📁 Restoring from file: {sql_file.name}")
                sql_content = sql_file.read().decode('utf-8')
            elif 'sql' in serializer.validated_data and serializer.validated_data['sql']:
                print("📝 Restoring from SQL text content")
                sql_content = serializer.validated_data['sql']
            else:
                return Response({
                    'success': False,
                    'error': 'No SQL file or content provided.'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            print(f"📊 SQL content size: {len(sql_content) / 1024:.2f} KB")
            
            # Validate SQL content
            if len(sql_content.strip()) < 50:
                return Response({
                    'success': False,
                    'error': 'SQL content is too small or empty'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Get database settings
            db_settings = settings.DATABASES['default']
            db_engine = db_settings['ENGINE']
            
            print(f"🎯 Target database: {db_engine}")
            
            # Restore based on database type
            if 'sqlite' in db_engine:
                result = self._restore_sqlite(db_settings, sql_content)
            elif 'postgresql' in db_engine:
                result = self._restore_postgresql(db_settings, sql_content)
            elif 'mysql' in db_engine:
                result = self._restore_mysql(db_settings, sql_content)
            else:
                return Response({
                    'success': False,
                    'error': f'Database engine {db_engine} is not supported for restore'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            restore_time = time.time() - start_time
            
            print("="*80)
            print("✅ DATABASE RESTORE COMPLETED")
            print(f"   Time: {restore_time:.2f} seconds")
            print(f"   Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            print("="*80)
            
            return Response({
                'success': True,
                'message': 'Database restored successfully',
                'restore_time': round(restore_time, 2),
                'backup_created': result.get('backup_path') if isinstance(result, dict) else None,
                'details': result.get('details') if isinstance(result, dict) else None
            })
            
        except Exception as e:
            print(f"❌ Restore failed: {str(e)}")
            import traceback
            traceback.print_exc()
            return Response({
                'success': False,
                'error': str(e),
                'details': 'Check server logs for more information'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    def _restore_sqlite(self, db_settings, sql_content):
        """Restore SQLite database from SQL dump"""
        db_path = str(db_settings['NAME'])
        
        print(f"📂 Target database: {db_path}")
        
        # Check if it's JSON format (from dumpdata)
        sql_stripped = sql_content.strip()
        if sql_stripped.startswith('[') or 'loaddata' in sql_content[:500]:
            print("🔍 Detected JSON format, using Django loaddata...")
            return self._restore_sqlite_json(sql_content)
        
        # SQL format - use Python sqlite3 module for reliability
        print("🔍 Detected SQL format, using Python sqlite3 module...")
        
        # Create backup of current database
        backup_path = None
        if os.path.exists(db_path):
            backup_path = f"{db_path}.backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
            shutil.copy2(db_path, backup_path)
            print(f"📦 Current database backed up to: {backup_path}")
        
        # Create a temporary database file
        temp_db_path = f"{db_path}.temp_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        try:
            # Method 1: Try using sqlite3 command with proper piping
            print("⚙️  Attempting restore with sqlite3 command...")
            try:
                # Write SQL to temporary file for better reliability
                with tempfile.NamedTemporaryFile(mode='w', suffix='.sql', delete=False, encoding='utf-8') as f:
                    f.write(sql_content)
                    temp_sql_path = f.name
                
                # Execute using sqlite3 command with file input
                result = subprocess.run(
                    ['sqlite3', temp_db_path, f'.read {temp_sql_path}'],
                    capture_output=True,
                    text=True,
                    timeout=300,
                    check=False
                )
                
                # Alternative: Use stdin redirect
                if result.returncode != 0 or not os.path.exists(temp_db_path) or os.path.getsize(temp_db_path) < 1000:
                    print("⚙️  Trying alternative method with stdin...")
                    result = subprocess.run(
                        ['sqlite3', temp_db_path],
                        input=sql_content,
                        capture_output=True,
                        text=True,
                        timeout=300,
                        check=False
                    )
                
                # Clean up temp SQL file
                if os.path.exists(temp_sql_path):
                    os.unlink(temp_sql_path)
                
                # Check if restore was successful
                if result.returncode == 0 and os.path.exists(temp_db_path):
                    temp_size = os.path.getsize(temp_db_path)
                    if temp_size > 1000:  # Reasonable minimum size
                        print(f"✅ sqlite3 command restore successful ({temp_size / 1024:.2f} KB)")
                        # Replace old database with new one
                        if os.path.exists(db_path):
                            os.remove(db_path)
                        shutil.move(temp_db_path, db_path)
                        
                        return {
                            'success': True,
                            'backup_path': backup_path,
                            'details': f'Database restored using sqlite3 command ({temp_size / 1024:.2f} KB)'
                        }
                    else:
                        print(f"⚠️  sqlite3 created file too small: {temp_size} bytes")
                
                # If we get here, sqlite3 method didn't work well
                if os.path.exists(temp_db_path):
                    os.remove(temp_db_path)
                    
            except Exception as e:
                print(f"⚠️  sqlite3 command method failed: {str(e)}")
                if os.path.exists(temp_db_path):
                    os.remove(temp_db_path)
            
            # Method 2: Use Python sqlite3 module (more reliable)
            print("🐍 Using Python sqlite3 module for restore...")
            
            # Remove old database
            if os.path.exists(db_path):
                os.remove(db_path)
                print(f"🗑️  Removed old database file")
            
            # Create new connection and execute SQL
            conn = sqlite3.connect(db_path)
            conn.isolation_level = None  # Autocommit mode
            
            try:
                # Split SQL into statements and execute
                # Remove comments and empty lines
                sql_lines = []
                in_transaction = False
                
                for line in sql_content.split('\n'):
                    stripped = line.strip()
                    # Skip comments
                    if stripped.startswith('--') or not stripped:
                        continue
                    sql_lines.append(line)
                
                sql_clean = '\n'.join(sql_lines)
                
                # Execute the SQL script
                print("⚙️  Executing SQL statements...")
                cursor = conn.cursor()
                cursor.executescript(sql_clean)
                cursor.close()
                conn.commit()
                
                print("✅ SQL execution completed")
                
            except Exception as e:
                conn.rollback()
                conn.close()
                # Restore backup on error
                if backup_path and os.path.exists(backup_path):
                    if os.path.exists(db_path):
                        os.remove(db_path)
                    shutil.copy2(backup_path, db_path)
                    print(f"↩️  Restored backup due to error")
                raise Exception(f"SQL execution failed: {str(e)}")
            
            conn.close()
            
            # Verify the database was created and has content
            if not os.path.exists(db_path):
                if backup_path and os.path.exists(backup_path):
                    shutil.copy2(backup_path, db_path)
                raise Exception("Database file was not created")
            
            db_size = os.path.getsize(db_path)
            if db_size < 1000:  # Less than 1KB is suspicious
                if backup_path and os.path.exists(backup_path):
                    shutil.copy2(backup_path, db_path)
                raise Exception(f"Database file is too small ({db_size} bytes), restore may have failed")
            
            # Verify database integrity
            try:
                test_conn = sqlite3.connect(db_path)
                test_cursor = test_conn.cursor()
                test_cursor.execute("PRAGMA integrity_check")
                integrity = test_cursor.fetchone()
                test_cursor.close()
                test_conn.close()
                
                if integrity[0] != 'ok':
                    raise Exception(f"Database integrity check failed: {integrity[0]}")
                    
                print("✅ Database integrity verified")
            except Exception as e:
                print(f"⚠️  Integrity check warning: {str(e)}")
            
            print(f"✅ Database restored successfully ({db_size / 1024:.2f} KB)")
            return {
                'success': True,
                'backup_path': backup_path,
                'details': f'Database restored using Python sqlite3 ({db_size / 1024:.2f} KB)'
            }
            
        except Exception as e:
            # Restore backup on any error
            if backup_path and os.path.exists(backup_path):
                if os.path.exists(db_path):
                    os.remove(db_path)
                shutil.copy2(backup_path, db_path)
                print(f"↩️  Restored backup due to error: {str(e)}")
            # Clean up temp file
            if os.path.exists(temp_db_path):
                os.remove(temp_db_path)
            raise
    
    def _restore_sqlite_json(self, json_content):
        """Restore SQLite from JSON format (Django dumpdata)"""
        import json
        import tempfile
        
        # Remove comments and get JSON
        lines = [line for line in json_content.split('\n') if not line.strip().startswith('--')]
        json_content = '\n'.join(lines)
        
        # Validate JSON
        try:
            json.loads(json_content)
        except json.JSONDecodeError as e:
            raise Exception(f"Invalid JSON format: {str(e)}")
        
        # Save to temp file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            f.write(json_content)
            temp_path = f.name
        
        try:
            print(f"📝 Loading JSON data from temp file: {temp_path}")
            call_command('loaddata', temp_path)
            print("✅ JSON data loaded successfully")
            return {'success': True, 'details': 'Restored from JSON format'}
        finally:
            if os.path.exists(temp_path):
                os.unlink(temp_path)
    
    def _restore_postgresql(self, db_settings, sql_content):
        """Restore PostgreSQL database from SQL dump"""
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
        
        # Run psql to restore
        cmd = [
            'psql',
            '-h', db_host,
            '-p', str(db_port),
            '-U', db_user,
            '-d', db_name,
            '-v', 'ON_ERROR_STOP=1'  # Stop on first error
        ]
        
        print("⚙️  Executing SQL dump...")
        result = subprocess.run(
            cmd,
            input=sql_content,
            capture_output=True,
            text=True,
            env=env,
            timeout=600
        )
        
        if result.returncode != 0:
            error_msg = result.stderr if result.stderr else result.stdout
            raise Exception(f"PostgreSQL restore failed: {error_msg}")
        
        print("✅ PostgreSQL restore completed")
        return {'success': True, 'details': 'PostgreSQL restore completed'}
    
    def _restore_mysql(self, db_settings, sql_content):
        """Restore MySQL database from SQL dump"""
        db_name = db_settings['NAME']
        db_user = db_settings.get('USER', 'root')
        db_password = db_settings.get('PASSWORD', '')
        db_host = db_settings.get('HOST', 'localhost')
        db_port = db_settings.get('PORT', '3306')
        
        print(f"🐬 MySQL: {db_user}@{db_host}:{db_port}/{db_name}")
        
        # Build mysql command
        cmd = [
            'mysql',
            '-h', db_host,
            '-P', str(db_port),
            '-u', db_user
        ]
        
        if db_password:
            cmd.append(f'--password={db_password}')
        
        cmd.append(db_name)
        
        print("⚙️  Executing SQL dump...")
        result = subprocess.run(
            cmd,
            input=sql_content,
            capture_output=True,
            text=True,
            timeout=600
        )
        
        if result.returncode != 0:
            error_msg = result.stderr if result.stderr else result.stdout
            raise Exception(f"MySQL restore failed: {error_msg}")
        
        print("✅ MySQL restore completed")
        return {'success': True, 'details': 'MySQL restore completed'}


class BackupInfoView(APIView):
    """
    Get information about backup/restore capabilities.
    GET /api/backup/info/
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        """Return database and backup information"""
        db_settings = settings.DATABASES['default']
        db_engine = db_settings['ENGINE']
        
        # Check which backup tools are available
        tools_available = {}
        
        if 'sqlite' in db_engine:
            tools_available['sqlite3_command'] = self._check_command('sqlite3')
            tools_available['python_sqlite3'] = True  # Always available in Python
            db_type = 'SQLite'
            db_file = str(db_settings['NAME'])
            db_size = os.path.getsize(db_file) / (1024 * 1024) if os.path.exists(db_file) else 0
        elif 'postgresql' in db_engine:
            tools_available['pg_dump'] = self._check_command('pg_dump')
            tools_available['psql'] = self._check_command('psql')
            db_type = 'PostgreSQL'
            db_file = None
            db_size = None
        elif 'mysql' in db_engine:
            tools_available['mysqldump'] = self._check_command('mysqldump')
            tools_available['mysql'] = self._check_command('mysql')
            db_type = 'MySQL'
            db_file = None
            db_size = None
        else:
            db_type = 'Unknown'
            db_file = None
            db_size = None
        
        # Check if backup/restore is fully supported
        backup_supported = False
        restore_supported = False
        
        if 'sqlite' in db_engine:
            # SQLite is always supported via Python module
            backup_supported = True
            restore_supported = True
        elif 'postgresql' in db_engine:
            backup_supported = tools_available.get('pg_dump', False)
            restore_supported = tools_available.get('psql', False)
        elif 'mysql' in db_engine:
            backup_supported = tools_available.get('mysqldump', False)
            restore_supported = tools_available.get('mysql', False)
        
        return Response({
            'success': True,
            'database': {
                'type': db_type,
                'engine': db_engine,
                'name': str(db_settings.get('NAME')),
                'host': db_settings.get('HOST'),
                'file': db_file,
                'size_mb': round(db_size, 2) if db_size else None
            },
            'backup_tools': tools_available,
            'backup_supported': backup_supported,
            'restore_supported': restore_supported,
            'endpoints': {
                'backup': '/api/backup/download/',
                'restore': '/api/backup/restore/',
                'info': '/api/backup/info/'
            },
            'instructions': {
                'backup': 'GET /api/backup/download/ to download SQL backup',
                'restore': 'POST /api/backup/restore/ with file or sql field',
                'check_tools': 'Install required tools if backup/restore is not supported'
            }
        })
    
    def _check_command(self, command):
        """Check if a command is available in PATH"""
        try:
            result = subprocess.run(
                [command, '--version'],
                capture_output=True,
                check=False,
                timeout=5
            )
            return result.returncode == 0
        except (FileNotFoundError, subprocess.TimeoutExpired):
            return False
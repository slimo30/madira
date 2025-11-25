# Database Backup and Restore Guide

This document provides comprehensive instructions for backing up and restoring the Madira database manually.

---

## Table of Contents

1. [Overview](#overview)
2. [Backup Process](#backup-process)
3. [Restore Process](#restore-process)
4. [Database-Specific Instructions](#database-specific-instructions)
5. [Best Practices](#best-practices)
6. [Troubleshooting](#troubleshooting)

---

## Overview

The Madira application provides an automated backup API endpoint and supports manual backup/restore operations for three database types:

- **SQLite** (Development/Small deployments)
- **PostgreSQL** (Production recommended)
- **MySQL** (Alternative production option)

### Backup File Format

All backups are generated as `.sql` files containing:
- Database schema (CREATE TABLE statements)
- All data (INSERT statements)
- Metadata header with timestamp and database info

---

## Backup Process

### Method 1: Using the API Endpoint (Recommended)

#### Prerequisites
- Authenticated user account
- Active server running

#### Steps

1. **Make a GET request to the backup endpoint:**

   ```bash
   curl -X GET http://localhost:8000/api/backup/download/ \
     -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
     -o backup_$(date +%Y%m%d_%H%M%S).sql
   ```

2. **Or use a web browser:**
   - Navigate to: `http://localhost:8000/api/backup/download/`
   - Login if prompted
   - The backup file will download automatically

3. **Verify the backup:**
   ```bash
   # Check file size (should not be empty)
   ls -lh backup_*.sql
   
   # View first few lines
   head -n 20 backup_*.sql
   ```

#### Expected Output

```sql
-- Madira Database Backup
-- Generated: 2025-11-25 15:29:01
-- Database: SQLite
-- File: /path/to/db.sqlite3
-- Size: 2.45 MB

BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS "django_migrations" (...);
-- ... rest of database
```

### Method 2: Manual Command-Line Backup

#### SQLite

```bash
# Navigate to database location
cd /path/to/madira/backend/madira

# Create backup using sqlite3 command
sqlite3 db.sqlite3 .dump > backup_$(date +%Y%m%d_%H%M%S).sql

# Or using Python
python -c "
import sqlite3
conn = sqlite3.connect('db.sqlite3')
with open('backup.sql', 'w') as f:
    for line in conn.iterdump():
        f.write(f'{line}\n')
conn.close()
"
```

#### PostgreSQL

```bash
# Set password (optional, if required)
export PGPASSWORD='your_password'

# Create backup
pg_dump -h localhost \
  -p 5432 \
  -U your_username \
  --no-owner \
  --no-acl \
  --clean \
  --if-exists \
  madira_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Unset password
unset PGPASSWORD
```

#### MySQL

```bash
# Create backup
mysqldump -h localhost \
  -P 3306 \
  -u your_username \
  -p \
  --single-transaction \
  --quick \
  --lock-tables=false \
  --add-drop-table \
  madira_db > backup_$(date +%Y%m%d_%H%M%S).sql
```

---

## Restore Process

> [!CAUTION]
> Restoring a backup will **OVERWRITE** all existing data in the database. Always create a backup of the current database before restoring.

### Pre-Restore Checklist

- [ ] Stop the Django development server
- [ ] Create a backup of the current database (if needed)
- [ ] Verify the backup file is not corrupted
- [ ] Ensure you have the correct database credentials

### SQLite Restore

> [!TIP]
> This method creates a **new database file** instead of overwriting the existing one, keeping your original database intact.

```bash
# Stop the server first
# Kill the Django server process or press Ctrl+C

# Navigate to project directory
cd /path/to/madira/backend/madira

# Step 1: Create a new database from the backup file
sqlite3 new_madira_db.sqlite3
```

Once in the SQLite interactive shell:

```sql
-- Read and execute the backup file
.read madira_backup_20251125_141034.sql

-- Verify the restore
SELECT COUNT(*) FROM django_migrations;

-- Exit SQLite
.quit
```

**Step 2: Update Django settings to use the new database**

Edit `madira/settings.py`:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'new_madira_db.sqlite3',  # Changed from db.sqlite3
    }
}
```

**Step 3: Verify and restart**

```bash
# Verify the new database file exists
ls -lh new_madira_db.sqlite3

# Restart server with new database
python manage.py runserver
```

**Alternative: One-line restore (overwrites existing database)**

If you want to restore directly to the existing database:

```bash
# Backup current database first
cp db.sqlite3 db.sqlite3.backup_$(date +%Y%m%d_%H%M%S)

# Restore from backup file
sqlite3 db.sqlite3 < backup_20251125_152901.sql

# Verify restore
sqlite3 db.sqlite3 "SELECT COUNT(*) FROM django_migrations;"

# Restart server
python manage.py runserver
```

### PostgreSQL Restore

```bash
# Stop the Django server

# Set password
export PGPASSWORD='your_password'

# IMPORTANT: The backup file contains --clean and --if-exists flags
# which will drop existing tables before recreating them
# This preserves the database but replaces the data

# Restore to existing database
psql -h localhost \
  -p 5432 \
  -U your_username \
  -d madira_db \
  -f backup_20251125_152901.sql

# Verify restore
psql -h localhost -p 5432 -U your_username -d madira_db -c "SELECT COUNT(*) FROM django_migrations;"

# Unset password
unset PGPASSWORD

# Restart server
python manage.py runserver
```

### MySQL Restore

```bash
# Stop the Django server

# IMPORTANT: The backup file contains DROP TABLE statements
# which will remove existing tables before recreating them
# This preserves the database but replaces the data

# Restore to existing database
mysql -h localhost \
  -P 3306 \
  -u your_username \
  -p \
  madira_db < backup_20251125_152901.sql

# Verify restore
mysql -h localhost -P 3306 -u your_username -p madira_db -e "SELECT COUNT(*) FROM django_migrations;"

# Restart server
python manage.py runserver
```

---

## Database-Specific Instructions

### SQLite

**Advantages:**
- Simple file-based database
- No server setup required
- Easy to backup (just copy the file)

**Backup Options:**

1. **File Copy (Fastest):**
   ```bash
   cp db.sqlite3 db_backup_$(date +%Y%m%d_%H%M%S).sqlite3
   ```

2. **SQL Dump (Portable):**
   ```bash
   sqlite3 db.sqlite3 .dump > backup.sql
   ```

**Restore Options:**

1. **File Replace:**
   ```bash
   cp db_backup_20251125_152901.sqlite3 db.sqlite3
   ```

2. **SQL Import:**
   ```bash
   sqlite3 db.sqlite3 < backup.sql
   ```

### PostgreSQL

**Advantages:**
- Production-grade reliability
- Advanced features (ACID compliance, concurrent access)
- Better performance for large datasets

**Required Tools:**
- `pg_dump` (backup)
- `psql` (restore)
- `createdb` / `dropdb` (database management)

**Connection String Format:**
```
postgresql://username:password@host:port/database_name
```

**Common Issues:**
- Password authentication: Use `PGPASSWORD` environment variable or `.pgpass` file
- Permission errors: Ensure user has CREATE/DROP privileges
- Connection refused: Check PostgreSQL service is running

### MySQL

**Advantages:**
- Wide hosting support
- Good performance
- Familiar to many developers

**Required Tools:**
- `mysqldump` (backup)
- `mysql` (restore)

**Connection String Format:**
```
mysql://username:password@host:port/database_name
```

**Common Issues:**
- Password on command line: Use `--password` flag or config file
- Character encoding: Add `--default-character-set=utf8mb4`
- Large imports: Increase `max_allowed_packet` setting

---

## Best Practices

### Backup Strategy

1. **Automated Backups:**
   ```bash
   # Add to crontab for daily backups at 2 AM
   0 2 * * * curl -X GET http://localhost:8000/api/backup/download/ \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -o /backups/madira_$(date +\%Y\%m\%d).sql
   ```

2. **Retention Policy:**
   - Keep daily backups for 7 days
   - Keep weekly backups for 4 weeks
   - Keep monthly backups for 12 months

3. **Storage Locations:**
   - Local backups: `/backups/` directory
   - Remote backups: Cloud storage (S3, Google Cloud Storage)
   - Offsite backups: Different physical location

4. **Backup Verification:**
   ```bash
   # Test restore in a separate database
   sqlite3 test_restore.db < backup.sql
   sqlite3 test_restore.db "SELECT COUNT(*) FROM users;"
   ```

### Security

> [!IMPORTANT]
> Backup files contain sensitive data. Protect them appropriately.

1. **Encrypt Backups:**
   ```bash
   # Encrypt backup file
   gpg --symmetric --cipher-algo AES256 backup.sql
   
   # Decrypt when needed
   gpg --decrypt backup.sql.gpg > backup.sql
   ```

2. **Secure Storage:**
   - Set restrictive file permissions: `chmod 600 backup.sql`
   - Store in encrypted directories
   - Use secure transfer protocols (SFTP, SCP)

3. **Access Control:**
   - Limit who can download backups (authentication required)
   - Audit backup access logs
   - Rotate backup encryption keys

### Performance

1. **Large Databases:**
   - Use compression: `gzip backup.sql`
   - Schedule during low-traffic periods
   - Monitor disk space

2. **Backup Size Optimization:**
   ```bash
   # Compress during backup
   sqlite3 db.sqlite3 .dump | gzip > backup.sql.gz
   
   # Restore from compressed backup
   gunzip -c backup.sql.gz | sqlite3 db.sqlite3
   ```

---

## Troubleshooting

### Common Issues

#### 1. "Database is locked" (SQLite)

**Problem:** Another process is using the database.

**Solution:**
```bash
# Stop the Django server
# Wait a few seconds
# Try backup again
```

#### 2. "Permission denied"

**Problem:** Insufficient file or database permissions.

**Solution:**
```bash
# Check file permissions
ls -l db.sqlite3

# Fix permissions
chmod 644 db.sqlite3

# For PostgreSQL/MySQL, check user privileges
# PostgreSQL:
psql -c "SELECT * FROM pg_roles WHERE rolname='your_username';"

# MySQL:
mysql -e "SHOW GRANTS FOR 'your_username'@'localhost';"
```

#### 3. "Backup file is empty or too small"

**Problem:** Backup process failed silently.

**Solution:**
```bash
# Check for errors in Django logs
# Verify database file exists and has content
sqlite3 db.sqlite3 "SELECT COUNT(*) FROM sqlite_master WHERE type='table';"

# Try manual backup method
```

#### 4. "Command not found: sqlite3/pg_dump/mysqldump"

**Problem:** Database tools not installed.

**Solution:**
```bash
# macOS
brew install sqlite3  # Usually pre-installed
brew install postgresql
brew install mysql

# Ubuntu/Debian
sudo apt-get install sqlite3
sudo apt-get install postgresql-client
sudo apt-get install mysql-client

# Verify installation
which sqlite3
which pg_dump
which mysqldump
```

#### 5. "Restore fails with syntax errors"

**Problem:** Backup file is corrupted or incomplete.

**Solution:**
```bash
# Verify backup file integrity
head -n 50 backup.sql
tail -n 50 backup.sql

# Check for COMMIT statement at end (SQLite)
grep -c "COMMIT" backup.sql

# Try creating a new backup
```

#### 6. "Authentication failed" (PostgreSQL/MySQL)

**Problem:** Incorrect credentials or connection settings.

**Solution:**
```bash
# Check Django settings.py for correct credentials
cat madira/settings.py | grep -A 10 "DATABASES"

# Test connection manually
# PostgreSQL:
psql -h localhost -p 5432 -U your_username -d madira_db -c "SELECT 1;"

# MySQL:
mysql -h localhost -P 3306 -u your_username -p -e "SELECT 1;"
```

### Getting Help

If you encounter issues not covered here:

1. Check Django server logs for detailed error messages
2. Verify database connection settings in `settings.py`
3. Test database connectivity manually
4. Check disk space: `df -h`
5. Review file permissions: `ls -la`

---

## Quick Reference

### Backup Commands

| Database   | Command |
|------------|---------|
| SQLite     | `sqlite3 db.sqlite3 .dump > backup.sql` |
| PostgreSQL | `pg_dump -U user -d dbname > backup.sql` |
| MySQL      | `mysqldump -u user -p dbname > backup.sql` |

### Restore Commands

| Database   | Command |
|------------|---------|
| SQLite     | `sqlite3 db.sqlite3 < backup.sql` |
| PostgreSQL | `psql -U user -d dbname < backup.sql` |
| MySQL      | `mysql -u user -p dbname < backup.sql` |

### File Locations

| Item | Path |
|------|------|
| SQLite Database | `/path/to/madira/backend/madira/db.sqlite3` |
| Backup Endpoint | `http://localhost:8000/api/backup/download/` |
| Settings File | `/path/to/madira/backend/madira/madira/settings.py` |

---

## Additional Resources

- [Django Database Backup Documentation](https://docs.djangoproject.com/en/stable/topics/db/)
- [SQLite Backup Documentation](https://www.sqlite.org/backup.html)
- [PostgreSQL Backup Documentation](https://www.postgresql.org/docs/current/backup.html)
- [MySQL Backup Documentation](https://dev.mysql.com/doc/refman/8.0/en/backup-and-recovery.html)

---

**Last Updated:** 2025-11-25  
**Version:** 1.0

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

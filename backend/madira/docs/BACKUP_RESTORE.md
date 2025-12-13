# Database Restore Guide

### SQLite Restore (Using Python Script)

This method uses a dedicated Python script to safely restore your database from a SQL backup file. It automatically backs up your current database before applying changes.

**Prerequisites:**

- Ensure your backup file (e.g., `madira_backup_20251213_232623.sql`) is located in the `backend/madira/` folder.
- Stop the running Django server (Ctrl+C).

**Step 1: Navigate to the project directory**

Open your terminal (PowerShell or CMD) and navigate to the backend folder:

```powershell
cd f:\madira\backend\madira
```

**Step 2: Run the restore script**

Run the `restore_db.py` script followed by your backup filename:

```powershell
python restore_db.py madira_backup_20251213_232623.sql
```

_Note: Replace `madira_backup_20251213_232623.sql` with your actual backup filename._

**What the script does:**

1.  Checks if the backup file exists.
2.  Renames your current `db.sqlite3` to `db.sqlite3.old` (safety backup).
3.  Creates a fresh `db.sqlite3`.
4.  Executes the SQL commands from your backup file to restore data.

**Step 3: Restart the Server**

Once the script displays "SUCCESS! Database restored.", you can restart your server:

```powershell
python manage.py runserver
```

### Troubleshooting

If the restore fails, the script will attempt to restore your original database from `db.sqlite3.old`.
If you need to manually revert, simply rename `db.sqlite3.old` back to `db.sqlite3`.

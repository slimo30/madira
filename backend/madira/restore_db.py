import sqlite3
import os
import sys

# Configuration
DB_FILE = 'db.sqlite3'

def restore_database(sql_file):
    # Check if file exists
    if not os.path.exists(sql_file):
        print(f"Error: Backup file '{sql_file}' not found in {os.getcwd()}!")
        return

    # 1. Backup existing DB
    if os.path.exists(DB_FILE):
        print(f"Backing up current {DB_FILE} to {DB_FILE}.old...")
        if os.path.exists(f"{DB_FILE}.old"):
            os.remove(f"{DB_FILE}.old")
        os.rename(DB_FILE, f"{DB_FILE}.old")
    
    # 2. Create new DB and execute SQL
    print(f"Restoring from {sql_file}...")
    try:
        # Connect to new database
        conn = sqlite3.connect(DB_FILE)
        cursor = conn.cursor()
        
        # Read SQL file
        print("Reading SQL file...")
        with open(sql_file, 'r', encoding='utf-8') as f:
            sql_script = f.read()
            
        # Execute
        print("Executing SQL script (this might take a moment)...")
        cursor.executescript(sql_script)
        conn.commit()
        conn.close()
        
        print("="*40)
        print("SUCCESS! Database restored.")
        print("="*40)
        
    except Exception as e:
        print(f"Error during restore: {e}")
        # Restore the old db if failed
        if os.path.exists(f"{DB_FILE}.old"):
            print("Restoring original database due to failure...")
            if os.path.exists(DB_FILE):
                os.remove(DB_FILE)
            os.rename(f"{DB_FILE}.old", DB_FILE)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        sql_file = sys.argv[1]
    else:
        print("Usage: python restore_db.py <backup_file.sql>")
        sql_file = input("Enter the backup SQL filename: ").strip()
        
    restore_database(sql_file)

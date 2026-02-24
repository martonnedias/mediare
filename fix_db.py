import sqlite3
import os

db_path = os.path.join("backend", "mediare.db")
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

try:
    print("Adding resguardo_active column to users table...")
    cursor.execute("ALTER TABLE users ADD COLUMN resguardo_active BOOLEAN DEFAULT 0;")
    print("Success!")
except sqlite3.OperationalError as e:
    print(f"Error or already exists: {e}")

try:
    print("Adding deleted_at column to users table...")
    cursor.execute("ALTER TABLE users ADD COLUMN deleted_at DATETIME;")
    print("Success!")
except sqlite3.OperationalError as e:
    print(f"Error or already exists: {e}")

conn.commit()
conn.close()

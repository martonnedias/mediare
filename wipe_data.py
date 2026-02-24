import sqlite3
import os

def force_clear_db():
    db_path = os.path.join("backend", "mediare.db")
    if not os.path.exists(db_path):
        print("ℹ️ Banco não encontrado.")
        return

    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Obter todas as tabelas
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = [t[0] for t in cursor.fetchall() if t[0] != 'sqlite_sequence']
        
        print(f"🧹 Limpando {len(tables)} tabelas no SQLite...")
        for table in tables:
            try:
                cursor.execute(f"DELETE FROM {table};")
                print(f"   - {table} limpa.")
            except Exception as e:
                print(f"   ⚠️ Erro na tabela {table}: {e}")
        
        conn.commit()
        conn.close()
        print("✅ Dados removidos do banco existente.")
    except Exception as e:
        print(f"❌ Erro fatal ao acessar banco: {e}")

if __name__ == "__main__":
    force_clear_db()

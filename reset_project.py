import os
import sqlite3
import firebase_admin
from firebase_admin import auth, credentials

# 1. Limpar Banco de Dados Local (SQLite)
def clear_local_db():
    db_path = os.path.join("backend", "mediare.db")
    if os.path.exists(db_path):
        print(f"📂 Deletando banco de dados local: {db_path}")
        try:
            # Fechar conexões se houver e deletar o arquivo
            os.remove(db_path)
            print("✅ Arquivo sqlite removido com sucesso.")
        except Exception as e:
            print(f"❌ Erro ao remover banco local: {e}")
    else:
        print("ℹ️ Banco de dados local não encontrado.")

# 2. Limpar Usuários do Firebase
def clear_firebase_users():
    cred_path = os.path.join("backend", "mediare-8be4c-firebase-adminsdk-fbsvc-a6a6ab6335.json")
    if not os.path.exists(cred_path):
        print("❌ Arquivo de credenciais do Firebase não encontrado. Pulando limpeza do Firebase.")
        return

    print("🔥 Iniciando limpeza de usuários no Firebase Console...")
    try:
        # Inicializa se não estiver inicializado
        if not firebase_admin._apps:
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        
        # Listar todos os usuários
        page = auth.list_users()
        total_deleted = 0
        
        while page:
            users = [user.uid for user in page.users]
            if users:
                auth.delete_users(users)
                total_deleted += len(users)
                print(f"🗑️ Deletados {len(users)} usuários...")
            page = page.get_next_page()
            
        print(f"✅ Sucesso! {total_deleted} usuários removidos do Firebase.")
    except Exception as e:
        print(f"❌ Erro ao limpar Firebase: {e}")

if __name__ == "__main__":
    print("🧹 --- INICIANDO LIMPEZA TOTAL --- 🧹")
    clear_local_db()
    clear_firebase_users()
    print("\n🚀 TUDO LIMPO! Agora você pode criar uma conta nova no App.")

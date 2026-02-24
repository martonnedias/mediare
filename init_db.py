#!/usr/bin/env python
"""
Script para inicializar o banco de dados SQLite
"""
from backend.database import engine
from backend.models import Base

def init_db():
    """Cria todas as tabelas no banco de dados"""
    print("Criando tabelas no banco de dados...")
    Base.metadata.create_all(bind=engine)
    print("✅ Banco de dados inicializado com sucesso!")

if __name__ == "__main__":
    init_db()

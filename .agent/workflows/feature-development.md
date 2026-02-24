---
description: Fluxo de trabalho estruturado para implementar novas funcionalidades ou refatorações importantes no projeto Mediare-MGCF.
---

# Fluxo de Desenvolvimento de Funcionalidades

Este fluxo orienta o processo de implementação de uma nova funcionalidade ou mudança significativa, garantindo alinhamento com a arquitetura e padrões de qualidade do projeto.

## 1. Preparação e Design
1.  **Revisar Documentação**:
    -   Leia o `PLAN.md` para confirmar o escopo e os requisitos da funcionalidade.
    -   Leia o `ARCHITECTURE.md` para entender onde os novos componentes se encaixam (Módulo Backend, Camada Frontend, Esquema do Banco de Dados).
2.  **Criar Plano de Tarefa**:
    -   Se a tarefa for complexa, crie um arquivo de plano de implementação (ex: `.agent/tasks/nome-da-funcionalidade.md`) detalhando os passos.

## 2. Implementação Backend (Python/FastAPI)
// turbo
1.  **Definir Modelos**: Se as estruturas de dados mudarem, atualize `backend/models.py` ou crie novos modelos.
2.  **Migração de Banco de Dados**:
    -   Atualize `init_db.py` ou execute scripts de migração, se aplicável.
    -   Verifique as alterações de esquema localmente.
3.  **Implementar Lógica**:
    -   Crie/Atualize endpoints em `backend/main.py` ou roteadores específicos.
    -   Implemente a lógica de negócios em serviços/controladores.
4.  **Testar Backend**:
    -   Execute testes unitários: `pytest backend/tests/`
    -   Verifique os endpoints manualmente (ex: via Swagger em `/docs`).

## 3. Implementação Frontend (Flutter)
// turbo
1.  **Atualizar Gerenciamento de Estado**:
    -   Crie/Atualize Bloc/Cubit se um novo estado for necessário.
    -   Defina eventos e estados claramente.
2.  **Implementar UI**:
    -   Crie widgets responsivos em `frontend/lib/screens/` ou `frontend/lib/widgets/`.
    -   Garanta compatibilidade tanto com Mobile quanto Web (verifique as restrições em `ARCHITECTURE.md`).
3.  **Integrar API**:
    -   Atualize `frontend/lib/services/` para chamar os novos endpoints do backend.
4.  **Testar Frontend**:
    -   Execute testes de widget/unitários: `flutter test`
    -   Verifique o comportamento no Chrome (Web) e Emulador (Mobile).

## 4. Garantia de Qualidade e Limpeza
1.  **Verificação de Lint**:
    -   Backend: `flake8 backend/` ou similar.
    -   Frontend: `flutter analyze`.
2.  **Atualizar Documentação**:
    -   Atualize `API_DOCS.md` se os endpoints mudarem.
    -   Atualize `ARCHITECTURE.md` se ocorrerem mudanças estruturais.
3.  **Commitar Mudanças**:
    -   Prepare os arquivos: `git add .`
    -   Faça o commit com mensagem descritiva: `git commit -m "feat: descrição da mudança"`

## 5. Verificação Final
1.  **Iniciar Serviços**:
    -   Backend: `uvicorn backend.main:app --reload`
    -   Frontend: `flutter run -d chrome`
2.  **Teste Manual**: Execute um teste completo do fluxo de usuário da nova funcionalidade.

# TESTING.md

## Como rodar os testes

### Backend
1. Certifique-se de que o ambiente virtual do Python está ativado.
2. Instale as dependências do projeto:
   ```bash
   pip install -r requirements.txt
   ```
3. Execute os testes com o pytest:
   ```bash
   pytest
   ```

### Frontend
1. Certifique-se de que o Flutter está instalado e configurado.
2. Execute os testes de widgets:
   ```bash
   flutter test
   ```

### Testes Cobertos
- **Backend**:
  - Cadastro rigoroso (Módulo 1).
  - Calendário e check-in.
  - Financeiro base.
  - Chat com IA (mockando OpenAI).
  - Gamificação básica.
- **Frontend**:
  - Testes de widgets para telas principais.
  - Testes de integração para fluxos principais.
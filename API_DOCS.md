# API_DOCS.md

## Endpoints Principais

### 1. Onboarding
- **POST /onboarding/complete-profile**: Completa o perfil do usuário com dados pessoais, CPF/RG e foto de perfil.
- **POST /onboarding/create-family**: Cria a primeira família, definindo o modo colaborativo/unilateral e cadastrando pelo menos uma criança.

### 2. Calendário & Convivência
- **POST /calendar/rules**: Define regras de guarda para crianças.
- **GET /calendar/events**: Lista eventos de convivência por criança, período e família.
- **POST /checkins**: Registra check-in de retirada/devolução com GPS e status.

### 3. Financeiro
- **POST /expenses**: Cria uma nova despesa com upload de comprovante e cálculo de hash SHA‑256.
- **GET /expenses**: Lista despesas por família, criança e período.
- **POST /budgets**: Cria um novo orçamento.
- **PUT /budgets/{id}/status**: Altera o status de um orçamento.

### 4. Chat com IA
- **POST /chats/messages**: Envia mensagem no chat oficial da família com moderação por IA.
- **GET /chats/messages**: Lista mensagens por família com paginação.
- **POST /chats/messages/{id}/read**: Marca mensagens como lidas.

### 5. Gamificação
- **POST /tasks**: Cria uma nova tarefa para uma criança.
- **POST /tasks/{id}/complete**: Registra a conclusão de uma tarefa pela criança.
- **POST /rewards**: Cria uma nova recompensa.
- **POST /rewards/{id}/redeem**: Registra o resgate de uma recompensa.

### 6. Relatórios Jurídicos
- **POST /reports**: Gera um novo relatório em PDF com linha do tempo, filtros e estatísticas.
- **GET /reports**: Lista relatórios gerados.
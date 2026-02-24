# MEDIARE - MGCF (Mediador de Guarda & Compliance Familiar)

## Visão Geral do Projeto
O MEDIARE - MGCF é uma plataforma SaaS que transforma a gestão de guarda compartilhada ou unilateral em um processo organizado, transparente e juridicamente válido. O sistema oferece funcionalidades como:

- Cadastro rigoroso e multi-família.
- Calendário de convivência com check-ins GPS.
- Gestão financeira com rateio de despesas e orçamentos.
- Chat com moderação por IA.
- Gamificação infantil (Modo Criança) com tarefas, recompensas e níveis.
- Relatórios jurídicos com linha do tempo, estatísticas e hash SHA‑256.

## Como Subir o Ambiente Local

### Backend
1. Certifique-se de ter Python 3.11+ instalado.
2. Instale as dependências:
   ```bash
   pip install -r requirements.txt
   ```
3. Configure as variáveis de ambiente necessárias (ex.: credenciais do Firebase, S3, etc.).
4. Execute o servidor:
   ```bash
   uvicorn main:app --reload
   ```

### Frontend
1. Certifique-se de ter o Flutter SDK instalado.
2. Instale as dependências:
   ```bash
   flutter pub get
   ```
3. Execute o aplicativo:
   ```bash
   flutter run
   ```

## Como Rodar os Testes

### Backend
Execute os testes com o pytest:
```bash
pytest
```

### Frontend
Execute os testes de widgets:
```bash
flutter test
```
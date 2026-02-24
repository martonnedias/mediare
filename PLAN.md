# PLAN – MEDIARE - MGCF – MVP 1.0 (Gamificação Completa)
## Baseado no Roadmap Oficial – 20+ Sprints

---

## 1. Objetivo do MVP 1.0

Entregar um aplicativo mobile (Android + iOS) com:

- Cadastro rigoroso & multi‑família.
- Calendário & convivência com check-in GPS.
- Gestão de endereços.
- Módulo financeiro + orçamentos.
- Chat com IA de moderação.
- Gamificação infantil completa (Modo Criança).
- Compromissos avançados.
- Relatórios jurídicos com hash SHA‑256.
- Infraestrutura invisível (offline, feature flags, monitoramento, exclusão de conta).

---

## 2. Fases e Sprints (macro)

### Fase 1 – Fundamentos (Infra + Autenticação + Núcleo Familiar)

**Sprints 1–2: Infraestrutura e Autenticação**

- [x] Configurar cloud (AWS/GCP/Azure) e repositórios.
- [x] Subir base do backend FastAPI (projeto, estrutura de pastas).
- [x] Subir base do app Flutter (projeto inicial).
- [x] Integrar Firebase Authentication no app.
- [x] Criar tabelas:
  - `users`
  - `family_units`
  - `children`
- [x] Implementar wizard de cadastro (Passo 1: Perfil, Passo 2: Família, Passo 3: Filhos).
- [x] Integrar com API de onboarding.
  - Cadastro de pelo menos 1 criança.
- [x] Conectar wizard ao backend (criação de família e crianças).
- [x] **Adicionar suporte inicial ao Flutter Web no projeto.**

**Sprints 3–4: Núcleo Familiar (Multi-Família, Modo Colaborativo/Unilateral)**

- [x] Implementar lógica multi‑família:
  - Um usuário pode ter múltiplas `family_units`.
- [x] Implementar `family_members`.
- [x] Implementar `mode` (colaborativo vs unilateral) nas famílias.
- [x] Criar context switcher no app para trocar de família.
- [x] Filtros por criança nas telas relevantes.
- [x] **Garantir compatibilidade do Modo Colaborativo/Unilateral no Flutter Web.** (Verificado: Adicionados indicadores visuais de modo nas telas de Finanças e Orçamentos para melhor contextualização).

---

### Fase 2 – Localizações, Calendário e Convivência

**Sprints 5–6: Módulo de Endereços**

- [x] Criar tabelas:
  - `locations`
  - `location_usage_history`
- [x] Implementar cadastro e edição de endereços no app:
  - Tipos pré-definidos (Casa Pai, Casa Mãe, Escola, etc.).
- [x] Integrar Google Maps API para geocodificação.
- [x] Implementar verificação de proximidade GPS (backend + app).
- [x] Registrar histórico de uso de cada localização.
- [x] **Adicionar suporte ao cadastro e edição de endereços no Flutter Web.**

**Sprints 7–8: Calendário & Convivência**

- [x] Criar tabelas:
  - `custody_calendar_rules`
  - `custody_events`
  - `checkins`
- [x] Implementar calendário de guarda no app:
  - Visualização mensal/semanal.
  - Filtro por criança.
- [x] Implementar check-in de retirada/devolução com GPS.
- [x] Registrar atrasos automaticamente (regras simples).
- [x] Integrar com endereços pré-cadastrados.
- [x] Criar visualizações amigáveis para o Modo Criança (sem dados sensíveis).
- [x] **Garantir que o calendário e check-ins sejam responsivos e compatíveis com navegadores.**

---

### Fase 3 – Financeiro & Orçamentos

**Sprints 9–10: Financeiro Base**

- [x] Criar tabelas:
  - `expenses`
  - `expense_shares`
- [x] Implementar registro de despesas no app:
  - Upload de comprovantes.
  - Vinculação a criança.
- [x] Integrar com S3/Firebase Storage (Implementado suporte híbrido S3/Local com endpoint seguro).
- [x] Calcular hash SHA‑256 de comprovantes no backend e salvar no banco.
- [x] Implementar rateio automático configurável (percentual por genitor).
- [x] UI de histórico de despesas.
- [x] **Adicionar suporte ao cadastro e edição de endereços no Flutter Web.**
- [x] **Adicionar suporte ao registro de despesas no Flutter Web.**
- [x] **Garantir que o sistema de orçamentos funcione no Flutter Web.**
- [x] **Implementar download real de relatórios PDF no Web.**

---

### Fase 4 – Comunicação & IA

**Sprints 13–14: Chat com IA**

- [x] Criar tabelas:
  - `family_chats`
  - `chat_messages`
  - `chat_message_reads`
- [x] Implementar chat oficial por família no app.
- [x] Integrar com OpenAI GPT‑4 para moderação (Implementado via Mock Inteligente no Backend).
- [x] Criar visualizações no app para mensagens bloqueadas/sugeridas.
- [x] Implementar read receipts no chat.
- [x] **Adicionar suporte ao Chat e Moderação IA no Flutter Web.**

---

### Fase 5 – Gamificação Completa (Modo Criança)

**Sprints 15–17: Gamificação Infantil (Modo Criança)**

- [x] Criar tabelas.
- [x] Implementar interface lúdica para o Modo Criança (Mobile + Web).
- [x] Implementar lógica de pontos e níveis no backend.
- [x] Criar endpoints para gerenciar tarefas, recompensas e pontos.
- [x] Garantir que o Modo Criança não exiba dados sensíveis.

---

### Fase 6 – Compromissos Avançados & Relatórios

**Sprints 18–19: Compromissos Avançados**

- [x] Criar tabelas.
- [x] Implementar lógica de detecção automática de atrasos.
- [x] Criar endpoints para gerenciar compromissos e checklists.
- [x] Implementar interface para criação, edição e exibição de compromissos (Mobile + Web).
- [x] Exibir status de compromissos em tempo real.

**Sprints 20–21: Relatórios Jurídicos**

- [x] Criar tabelas.
- [x] Implementar registro automático de eventos importantes no `event_log`.
- [x] Implementar geração de relatórios em PDF com linha do tempo e estatísticas.
- [x] Calcular hash SHA‑256 dos relatórios.
- [x] Criar interface para configuração, geração e download de relatórios (Mobile + Web).

---

### Fase 7 – Infraestrutura Invisível & Lançamento

**Sprints 22–23: Infraestrutura Invisível**

- [x] Implementar comportamento offline-first no frontend com Hive.
- [x] Criar fila de pendências para sincronização automática.
- [x] Configurar deep linking para abrir telas específicas via notificações push.
- [x] Integrar feature flags via Remote Config.
- [x] Criar endpoint de health check no backend.
- [x] Configurar logs estruturados básicos no backend.
- [x] Configurar Crashlytics e Sentry para monitoramento de erros e desempenho.

**Sprints 24–25: Testes e Ajustes**

- [x] Criar/ajustar suíte de testes unitários e de integração no backend:
  - Módulo 1 (cadastro rigoroso).
  - Calendário + check-in.
  - Financeiro base.
  - Chat com IA (mockando OpenAI).
  - Gamificação básica.
- [x] Adicionar testes de widgets e integração no frontend para fluxos principais.
- [x] Ajustar UX/UI com estados vazios, mensagens de erro e loading.
- [x] Corrigir bugs encontrados durante os testes.
- [x] Documentar como rodar os testes no arquivo TESTING.md.
- [x] **Eliminar todos os DeprecationWarning do backend (0 warnings nos testes).**
- [x] **Migrar datetime.utcnow() → datetime.now(timezone.utc) em 9 arquivos.**
- [x] **Migrar SQLAlchemy declarative_base() → DeclarativeBase (SQLAlchemy 2.0).**
- [x] **Migrar Pydantic V1 @validator → @field_validator e class Config → model_config.**
- [x] **Migrar google.generativeai → google.genai (novo SDK).**
- [x] **Atualizar frontend _viewReceipt para usar endpoint seguro /attachments/expenses/{id}.**
- [x] **Corrigir bug de prompt duplicado em agreements.py (modo colaborativo/unilateral).**

**Sprints 26–27: Preparação para Lançamento**

- [x] Atualizar README.md com visão geral, instruções de ambiente local e testes.
- [x] Documentar endpoints principais em `API_DOCS.md`.
- [x] Adicionar eventos básicos de analytics no app (criação de família, registro de despesa, uso do Modo Criança).
- [x] Configurar para publicação no Google Play e Apple App Store.
- [x] Aplicar UI/UX "Premium" e Designer de Alta Fidelidade em todo o sistema Web.
- [x] Criar tela de Login (Landing visual) com Glassmorphism e então atualizar para o perfil Soft & Supportive (Bordas curtas "Squircles" e Tons Pastel).
- [x] Refatorar Calendário com Linha do Tempo contínua sincronizada a Checkins de Crianças.
- [x] Refatorar Interface Administrativa (Painel de Configurações) implementando modal granular.
- [x] Integrar Dashboard dinâmico consolidando todos os módulos.
- [x] Criar `RELEASE_CHECKLIST.md` com revisões realizadas para o lançamento.

---

## 4. Fora de Escopo (Versão 2.0 – Growth)

> Não implementar no MVP, apenas manter em mente para arquitetura:

- Fintech (carteiras, Pix/Boleto, split de pagamentos).
- IA preditiva (curva de tensão, sugestões proativas).
- Integrações com escolas, saúde, portais.
- Marketplace de profissionais (psicólogos, advogados, peritos).
- Licenças B2B (escolas, escritórios, planos de saúde).

---

## 5. Observações Gerais

- Qualquer alteração estrutural deve ser refletida em:
  - `ARCHITECTURE.md`
  - Documento mestre do produto
- Cada sprint deve encerrar com:
  - Backend funcional para o módulo.
  - Integração mínima no app para teste interno.
  - Lista clara de débitos técnicos (se existirem).

### Sprint 9-10: Financeiro Base

- Backend:
  - [x] Tabelas expenses / expense_shares
  - [x] Endpoints REST para CRUD de despesas e rateios

- Frontend Mobile (Flutter):
  - [x] Tela de cadastro de despesa (mobile)
  - [x] Tela de lista de despesas por criança (mobile)

- Frontend Web (Flutter Web):
  - [x] Lista de despesas com visão em tabela (desktop)
  - [x] Filtros avançados (período, tipo, criança) otimizados para mouse/teclado

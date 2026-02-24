# ARCHITECTURE – MEDIARE - MGCF (Mediador de Guarda & Compliance Familiar)
## Versão 1.0 – MVP com Gamificação Completa
## Baseado no Documento Mestre – Fevereiro/2026

---

## 1. Visão Geral da Arquitetura

O MEDIARE - MGCF é um SaaS mobile-first (Android + iOS) para gestão de guarda e compliance familiar, com:

- Aplicativo mobile em **Flutter** para genitores e crianças.
- Backend em **Python/FastAPI** com banco **PostgreSQL**.
- Armazenamento de mídias em **S3 ou Firebase Storage**.
- **Firebase Authentication** como provedor de identidade.
- **Redis + Celery** para tarefas assíncronas.
- Camada forte de segurança jurídica (hash SHA-256, soft delete, RLS, multi-tenant por família).

---

## 2. Stack Tecnológico (confirmado pelo documento mestre)

### 2.1 Backend

- Linguagem: **Python 3.11+**
- Framework: **FastAPI**
- Banco de Dados: **PostgreSQL 14+**
- Cache: **Redis**
- Tarefas Assíncronas: **Celery**
- Storage de Arquivos: **AWS S3** ou **Firebase Storage** (decisão de implementação concreta pode escolher um dos dois, mantendo interface de abstração).

### 2.2 Frontend Mobile e Web

- Framework: **Flutter** (Dart 3.0+)
  - Suporte completo para **Flutter Web** para compatibilidade com navegadores.
- Gerência de Estado: **Flutter Bloc**
- Cache Local: **Hive**
- Mapas: **Google Maps Flutter**
- Notificações Push: **Firebase Cloud Messaging**
- **Responsividade:**
  - Garantir que todas as telas sejam responsivas e funcionem bem em dispositivos móveis e navegadores.
  - Testar compatibilidade com navegadores modernos (Chrome, Firefox, Edge, Safari).

### 2.3 Infraestrutura

- **Health Check:**
  - Endpoint `/health` para verificar o status do sistema.
  - Retorna status `ok` e mensagem de saúde do sistema.

- **Logs Estruturados:**
  - Configuração básica de logs estruturados com timestamps, níveis de log e mensagens.
  - Integração com Sentry e Crashlytics para monitoramento de erros e desempenho.

- **Offline-First:**
  - Uso do Hive no Flutter para cache de dados críticos.
  - Fila de pendências para sincronização automática quando a conexão for restabelecida.

- **Deep Linking:**
  - Configuração de deep linking para abrir telas específicas via notificações push.

- **Feature Flags:**
  - Integração com Remote Config para ativar/desativar funcionalidades como IA.

### 2.4 Integrações

- IA (moderação de chat): **OpenAI GPT‑4**
- Geolocalização: **Google Maps API**
- Pagamentos (V2, não MVP): Iugu, Asaas ou Stripe

### 2.4 Requisitos Não Funcionais

- **Escalabilidade:**
  - Suporte para múltiplos núcleos familiares (multi-tenant).
  - Capacidade de lidar com picos de uso, especialmente em horários de maior demanda (ex.: finais de semana e feriados).

- **Disponibilidade:**
  - Garantir uptime de 99,9%.
  - Implementar health checks e monitoramento contínuo.

- **Desempenho:**
  - Resposta de API em menos de 200ms para 95% das requisições.
  - Otimização de consultas ao banco de dados com índices e RLS (Row Level Security).

- **Segurança:**
  - Autenticação robusta com Firebase Authentication + JWT.
  - Proteção contra injeção de SQL, XSS e CSRF.
  - Implementação de rate limiting para evitar abusos.
  - Logs estruturados para auditoria e rastreamento de eventos críticos.

### 2.5 Segurança e Imutabilidade Jurídica

- **Imutabilidade de Dados:**
  - Implementar soft delete obrigatório (campos `deleted_at` e `deleted_by`).
  - Calcular e armazenar hash SHA-256 para todas as mídias e relatórios.

- **Controle de Acesso:**
  - Filtragem de dados por `family_unit_id` para garantir isolamento entre famílias.
  - Configuração de RLS (Row Level Security) no PostgreSQL para reforçar a segurança.

- **Proteção de Dados Sensíveis:**
  - Criptografia de dados sensíveis em repouso e em trânsito.
  - Garantir conformidade com LGPD e GDPR.

- **Logs e Auditoria:**
  - Manter uma tabela de `event_log` para registrar todas as ações relevantes.
  - Logs devem incluir timestamp, usuário, ação e contexto.

---

## 3. Segurança, Multi‑Tenant e Conformidade

### 3.1 Autenticação e Autorização

- Autenticação:
  - **Firebase Authentication** (e‑mail/senha, possivelmente telefone ou outros métodos depois).
- Tokens de acesso:
  - **JWT** com expiração de 24h.
  - Refresh tokens com rotação.
- Autorização:
  - Controle por **família (tenant)** e por **papel** dentro da família.
  - Row Level Security (RLS) no PostgreSQL garantindo isolamento por `family_unit`.

### 3.2 Isolamento Multi‑Tenant

- Cada **família** é um tenant lógico.
- Todas as tabelas ligadas a dados de uso (children, events, expenses, chat, etc.) são filtradas por `family_unit_id`.
- Regras:
  - Nenhuma query de domínio pode ser escrita sem o filtro de tenant.
  - RLS habilitado no Postgres para reforçar isolamento no nível do banco.

### 3.3 Dados e Criptografia

- Em repouso:
  - Criptografia **AES‑256** no nível de storage/disco (configuração de infraestrutura).
- Em trânsito:
  - **TLS 1.3** em toda comunicação externa (API, app e **navegadores**).
- Integridade de mídias:
  - Hash **SHA‑256** armazenado no banco para cada mídia ou comprovante relevante.
  - Usado para validar que arquivos não foram alterados.

### 3.4 Imutabilidade Jurídica

- **Soft delete obrigatório:**
  - Nenhum registro de domínio crítico é apagado fisicamente.
  - Campos típicos:
    - `deleted_at`, `deleted_by`.
  - Histórico completo de mudanças (auditoria).
- Linha do tempo imutável:
  - Todos os eventos importantes (check‑ins, atrasos, despesas, alterações de compromissos) são inseridos em tabela de eventos com carimbo de tempo.

### 3.5 Conformidade

- LGPD compliant:
  - Consentimento explícito para uso de dados.
  - Políticas de retenção e anonimização ao excluir conta.
- Botão de exclusão de conta (requisito Apple/Google):
  - No app, mas na prática, conta é:
    - Desativada,
    - Dados pessoais minimizados/anonimizados, mantendo integridade jurídica de registros.

---

## 4. Modelagem de Domínio (alto nível)

> Nomes de tabelas são sugestivos; podem ser ajustados na implementação desde que mantenham a semântica do documento mestre.

### 4.1 Núcleo de Usuários e Famílias

- **users**
  - `id`
  - `firebase_uid`
  - `name`
  - `email`
  - `phone` (opcional)
  - `cpf`, `rg` (opcional ou obrigatório; wizard exige CPF/RG – implementar validação)
  - `photo_url`
  - `created_at`, `updated_at`
  - `is_active`

- **family_units**
  - `id`
  - `owner_user_id` (genitor que criou a família)
  - `name` (ex.: “Família de [criança X]”)
  - `mode` (`collaborative` | `unilateral`)
  - `created_at`, `updated_at`

- **family_members**
  - `id`
  - `family_unit_id`
  - `user_id`
  - `role` (`parent`, `child`, `lawyer`, `other`)
  - `status` (`active`, `invited`, `removed`)
  - `created_at`, `updated_at`

- **children**
  - `id`
  - `family_unit_id`
  - `name`
  - `birth_date`
  - `gender` (opcional)
  - `notes` (ex.: saúde, necessidades especiais – armazenar com cuidado)
  - `created_at`, `updated_at`

### 4.2 Endereços e Localizações (Módulo 2)

- **locations**
  - `id`
  - `family_unit_id`
  - `label` (Casa Pai, Casa Mãe, Escola, Médico etc.)
  - `address_line_1`, `address_line_2`
  - `city`, `state`, `zip_code`, `country`
  - `latitude`, `longitude`
  - `visibility` (`both_parents`, `owner_only`, …)
  - `created_at`, `updated_at`

- **location_usage_history**
  - `id`
  - `family_unit_id`
  - `location_id`
  - `used_by_user_id`
  - `used_at`
  - `usage_type` (retirada, devolução, compromisso etc.)

### 4.3 Calendário & Convivência (Módulo 3)

- **custody_calendar_rules** (configurações de guarda – fim de semana alternado, feriados, etc.)
  - `id`
  - `family_unit_id`
  - `rule_type`
  - `metadata` (JSON com detalhes da regra)
  - `created_at`, `updated_at`

- **custody_events** (instâncias do calendário – onde a criança estará em cada dia)
  - `id`
  - `family_unit_id`
  - `child_id`
  - `start_datetime`
  - `end_datetime`
  - `responsible_parent_id` (user)
  - `location_id` (onde a criança estará)
  - `source` (`rule`, `manual`)
  - `created_at`, `updated_at`

- **checkins**
  - `id`
  - `family_unit_id`
  - `child_id`
  - `event_id` (custody_event ou compromisso)
  - `performed_by_user_id`
  - `checkin_type` (`pickup`, `dropoff`)
  - `timestamp`
  - `latitude`, `longitude`
  - `distance_to_expected_location` (m)
  - `status` (`on_time`, `late`, `wrong_place`)
  - `created_at`

### 4.4 Financeiro & Orçamentos (Módulo 4)

- **expenses**
  - `id`
  - `family_unit_id`
  - `child_id` (opcional; despesa geral ou por criança)
  - `created_by_user_id`
  - `amount`
  - `currency`
  - `category` (saúde, educação, lazer, etc.)
  - `description`
  - `date`
  - `attachment_url`
  - `attachment_hash_sha256`
  - `status` (`recorded`, `agreed`, `disputed`)
  - `created_at`, `updated_at`

- **expense_shares**
  - `id`
  - `expense_id`
  - `user_id`
  - `percentage`
  - `amount_value`
  - `status` (`pending`, `accepted`, `rejected`)

- **budgets**
  - `id`
  - `family_unit_id`
  - `created_by_user_id`
  - `child_id` (opcional)
  - `description`
  - `estimated_amount`
  - `status` (`proposed`, `approved`, `rejected`, `canceled`)
  - `created_at`, `updated_at`

### 4.5 Chat com IA (Módulo 5)

- **family_chats**
  - `id`
  - `family_unit_id`
  - (Um chat oficial por família.)

- **chat_messages**
  - `id`
  - `family_chat_id`
  - `sender_user_id`
  - `content` (texto bruto)
  - `clean_content` (versão sugerida pela IA – se aplicável)
  - `toxicity_score` (float)
  - `sentiment_score` (float)
  - `moderation_status` (`allowed`, `blocked`, `needs_rewrite`)
  - `created_at`

- **chat_message_reads**
  - `id`
  - `message_id`
  - `user_id`
  - `read_at`

### 4.6 Gamificação Infantil (Módulo 6)

- **tasks**
  - `id`
  - `family_unit_id`
  - `child_id`
  - `created_by_user_id` (pai/mãe)
  - `title`
  - `description`
  - `points`
  - `due_date`
  - `status` (`pending`, `completed`, `approved`, `rejected`)
  - `created_at`, `updated_at`

- **rewards**
  - `id`
  - `family_unit_id`
  - `title`
  - `description`
  - `cost_points`
  - `is_active`
  - `created_at`, `updated_at`

- **child_points_ledger**
  - `id`
  - `family_unit_id`
  - `child_id`
  - `change` (int, positivo ou negativo)
  - `reason` (`task_completed`, `reward_redeemed`, ajuste, etc.)
  - `related_task_id` (opcional)
  - `related_reward_id` (opcional)
  - `created_at`

- **child_levels**
  - `id`
  - `child_id`
  - `current_level` (Bronze, Prata, Ouro, Platina, Diamante)
  - `current_points`
  - `updated_at`

### 4.7 Compromissos Avançados (Módulo 7)

- **appointments**
  - `id`
  - `family_unit_id`
  - `child_id` (opcional)
  - `created_by_user_id`
  - `type` (passeio, viagem, saída, atividade, consulta médica etc.)
  - `start_datetime`
  - `end_datetime`
  - `origin_location_id`
  - `destination_location_id`
  - `transport_responsible_user_id` (quem busca)
  - `return_responsible_user_id` (quem leva de volta)
  - `financial_responsible_user_id` (quem arca com custo principal)
  - `status` (9 estados; ex.: `scheduled`, `confirmed`, `in_progress`, `completed`, `late`, `canceled` etc.)
  - `created_at`, `updated_at`

- **appointment_checklists**
  - `id`
  - `appointment_id`
  - `item`
  - `is_pre` (pré ou pós-compromisso)
  - `is_mandatory`

- **appointment_checklist_status**
  - `id`
  - `appointment_id`
  - `item_id`
  - `checked_by_user_id`
  - `checked_at`

- **appointment_status_history**
  - `id`
  - `appointment_id`
  - `old_status`
  - `new_status`
  - `changed_by_user_id`
  - `changed_at`

### 4.8 Relatórios Jurídicos (Módulo 8)

- **event_log** (tabela de eventos para linha do tempo)
  - `id`
  - `family_unit_id`
  - `event_type` (despesa_criada, atraso_registrado, checkin_feito, mensagem_enviada, tarefa_concluída, etc.)
  - `entity_type` (`expense`, `appointment`, `checkin`, `chat_message`, etc.)
  - `entity_id`
  - `performed_by_user_id`
  - `metadata` (JSON de detalhes)
  - `created_at`

- **reports**
  - `id`
  - `family_unit_id`
  - `generated_by_user_id`
  - `report_type`
  - `period_start`
  - `period_end`
  - `filters` (JSON)
  - `file_url` (PDF gerado)
  - `file_hash_sha256`
  - `created_at`

---

## 5. Arquitetura Frontend (Flutter)

### 5.1 Estrutura de Módulos (alto nível)

- `auth` – login, cadastro, recuperação.
- `onboarding` – wizard de cadastro rigoroso.
- `families` – seleção e gerenciamento de famílias (multi‑família, context switcher).
- `children` – cadastro/edição e Modo Criança.
- `addresses` – cadastro e gestão de endereços.
- `calendar` – calendário de guarda e visualizações.
- `finance` – despesas, orçamentos, histórico.
- `chat` – chat com moderação.
- `gamification` – tarefas, pontos, recompensas, Jornada do Herói.
- `appointments` – compromissos avançados.
- `reports` – geração e download de PDFs.

### 5.2 Cache Local e Offline‑First

- Banco local com **Hive** para:
  - Dados de família, crianças, endereços.
  - Calendário de curto prazo.
  - Últimos eventos e histórico recente.
- Estratégia:
  - App funciona offline usando dados em cache.
  - Fila de pendências (ações a sincronizar quando a rede voltar).

---

## 6. Fluxos Assíncronos (Celery)

Exemplos de tarefas em background:

- Geração de relatórios PDF (Módulo 8).
- Cálculo de hashes de arquivos grandes.
- Envio de notificações push.
- Processamento de análises de IA mais pesadas (se não forem síncronas).

---

## 7. Observações e TODOs

- Decisões pendentes de detalhamento:
  - Política exata de moderação de chat (bloqueio x sugestão).
  - Níveis específicos (faixas de pontos) da gamificação.
  - Conjunto exato dos 9 status de compromissos.
- Todos esses pontos devem ser resolvidos no nível de produto e, depois, refletidos aqui.

Frontend Mobile
Framework: Flutter (Dart 3.0+)
State Management: Flutter Bloc
Cache Local: Hive
Mapas: Google Maps Flutter
Notificações: Firebase Messaging

[NOTA ADICIONAL PARA WEB]
Frontend Web (MVP)
Framework: Flutter Web (mesma base de código)
Responsividade: LayoutBuilder + MediaQuery
Deploy: Firebase Hosting ou Vercel

Frontend Web (V2.0 - opcional)
Framework: React + Next.js
State Management: Zustand ou Redux Toolkit
Deploy: Vercel

## Frontend

- Framework: Flutter (Dart 3.0+)
- Plataformas alvo:
  - Android
  - iOS
  - Web (Flutter Web)
- Padrões de Interface e Temas:
  - Estilo de Componentes Base: Padrão "Soft & Supportive", obrigatório forçar App a `ThemeMode.light`.
  - Formas: Arredondamentos de 24px (squircles) e sombras leves/suaves sem hard edges coloridas.
  - Componentes Reutilizáveis customizados: `SoftButton`, `SoftInput`, `MediareCard`, `MediareDialog`.
- Padrões de Adaptação:
  - Design responsivo (layouts adaptáveis para mobile e desktop).
  - Cuidado especial com:
    - Tabelas e grids na Web.
    - Navegação por teclado na Web (acessibilidade).

## Suporte a Web

- O mesmo backend FastAPI atende:
  - App Flutter (Android/iOS)
  - App Flutter Web
- As rotas da API não dependem de plataforma.
- Specificidades de UX por plataforma são tratadas na camada de UI, mas:
  - Regras de negócio são idênticas.
  - Validações são centralizadas no backend.

---

## 8. Integração do Flutter Web

- **Infraestrutura:**
  - Configurar o build do Flutter para Web durante o pipeline de CI/CD (GitHub Actions).
  - Garantir que o deploy do Flutter Web seja realizado em um bucket S3 ou serviço equivalente com suporte a hosting de aplicações estáticas.
- **Armazenamento de Mídias:**
  - Garantir que o Flutter Web utilize a mesma interface de abstração para S3 ou Firebase Storage.
- **Autenticação:**
  - Confirmar compatibilidade do Firebase Authentication com Flutter Web.
- **Monitoramento:**
  - Configurar Firebase Crashlytics para suporte a Web.
- **Testes:**
  - Implementar testes de usabilidade e responsividade para navegadores.



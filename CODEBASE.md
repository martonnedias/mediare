# MEDIARE - MGCF: Mapeamento de Código (Codebase Map)

Este documento atua como um guia absoluto de mapeamento para novos engenheiros que atuem na base de código do **Mediare - MGCF (MVP 1.0)**. Ele lista onde os recursos lógicos e visuais habitam para as duas camadas do monorepo (Frontend Flutter e Backend FastAPI).

---

## 1. Frontend (Flutter / Dart)
O Frontend mora em `\frontend\lib`. Ele utiliza os componentes temáticos globais injetados em `main.dart` no estilo **Soft & Supportive** e se comunica à rede pelo `api_service.dart`.

### 1.1 Serviços Core (Services)
*   **`main.dart`**: Entrypoint e Configuração global (ThemeMode.light, cores pastéis e esquemas de border radius globais) e Wrapper de rota de Autenticação inicial.
*   **`api_service.dart`**: Trata das interceptações e repasses HTTP (GET, POST, etc.) baseadas na API Python. Contém lógica segura de Headers de Autenticação.
*   **`auth_service.dart`**: Comunicação nativa das Firebase APIs para Auth, Registro, e checagens seguras (SecureStorage / SharedPreferences delegados pelo ambiente).
*   **`family_service.dart`**: Listener Singleton providenciando broadcast de Notifiers do modelo `FamilyUnit` focado caso a rede multi-membro comute.
*   **`sync_service.dart`**: Motor offline-first (utilizando **Hive**). Adiciona requisições (como envio de recibos do módulo financeiro) à fila caso os dados de rede esgotem ou caiam. 
*   **`responsive_shell.dart`**: Gerencia o rescalonamento Sidebar / Bottom Navigation Bar caso o runtime do app detecte rodagem Web vs Runtime mobile.

### 1.2 Telas Principais (Screens)
*   **`login_screen.dart`**: Página de porta de entrada e call-to-actions, renderiza visual responsivo com painel envidraçado adaptado para tons Clean;
*   **`signup_screen.dart`**: Fluxo de criação de usuário. Acopla o consentimento obrigatório LGPD/Termos e direciona a requisição do usuário de `sync` (sincronização base Firebase -> PostgreSQL).
*   **`onboarding_screen.dart`**: Wizard de configuração dividido em Tiers (Setup do adulto, setup do ambiente da famiglia e inserção da dependência criança). Utiliza widgets da UI clean.
*   **`home_screen.dart`**: Controla o Hub interno após onboarding. Envia dados para sub-dashboards em `dashboard_screen.dart`.
*   **`dashboard_screen.dart`**: Sumários e atalhos globais, divididos via Feature-Gates em "Visão do Adulto" vs "Visão da Criança" baseada na Flag da conta.
*   **`settings_screen.dart`**: O Control-Panel administrativo. Onde funções destrutivas e LGPD, exclusão de dados e relatórios gerados via IA moram formatados inline em design cards minimalistas.

### 1.3 Módulos Funcionais
*   **`calendar_screen.dart`**: Motor do Calendário de Convivência GPS. Plota tanto o mês da vivência parental (via blocos verde/azul bebê diários) e o Tracking-GPS via timeline para Checkins locais.
*   **`finance_screen.dart`**: Controle Mútuo de Gastos. Carrega dinamicamente chaves `/expenses/categories` para inserção de boletos baseadas em ML / OCR nativo em imagem e PDF com a visibilidade rateada.
*   **`locations_screen.dart`**: Cadastramento fixo das âncoras familiares servindo do catálogo `/locations/types` onde o Google Maps Places Autocomplete varre coordenadas atutais de escola, clinicas, e casas e salva.
*   **`chat_screen.dart`**: Área restrita da troca de diálogo moderado. A API OpenAI checa e filtra envios sensíveis criando "breezes" da comunicação. 
*   **`appointments_screen.dart`**: Eventos complexos agendados. Diferem de calendários, pois necessitam Checklist, Confirmações Pré-venda e Responsáveis por transportes.
*   **`child_mode_screen.dart`**: (Gamificação) Concentra renderização gamificada diária voltada ao menor para ver de forma transparente qual pai ele irá e pontuações do app.

### 1.4 UI & Componentes (`mediare_widgets.dart`)
Concentra as implementações universais do estilo "Soft & Supportive":
*   `SoftButton`: Botão principal de elevação morta curvatura `16px`.
*   `SoftInput`: Input formulário base com hint-texts centralizados minimalistas sem cores saturadas.
*   `MediareCard`: O contêiner de `24px` "Squircle" com sombras leves, moldando 80% do design moderno das boxes.
*   `MediareDialog`: Interpola e substitui showDialong providenciando overlays modais limpas estilo cards que saem por baixo da tela ou ocupam telas inteiras num layout de web (850px locked).

---

## 2. Backend (Python / FastAPI)
A base lógica, relacional e de segurança jurídica isolada sob `\backend`. 

*   **`main.py`**: Ponto de montagem da FastAPI e injeção do roteador de domínios. Liga o middleware OAuth, middlewares CORS e integrações Sentry. Inicia em conjunto ao servidor rodado via UVicorn.
*   **`models.py`**: O mapa canônico final de tabelas **SQLAlchemy**. Contém desde os esquemas RLS de Multi-tenant (Family Units) a Hashes da rede. (Ex: `CustodyEvent`, `CheckIn`, `Expense` e `Report`).
*   **`schemas.py`**: Protocolos e modelos do **Pydantic** para in e out da rede HTTP, garantindo Data Validation e Serialization dos Objects JSONs do Dart antes de tocarem a Engine ORM dos Modelos de DB.
*   **`dependencies.py`**: Provedor das Dependências Centrais, essencialmente entrega as requisições de DB da Session e o validador de `get_current_user` descriptografando o Token Firebase que desce nas Headings em cada requisição.

### 2.1 Roteadores (Controllers) (`\backend\routers`)
*   **`users.py`**: Controla sync account Pós-Firebase (`/users/sync`), fetch de onboarding state e o ecossistema e lista de criancás `/users/children`.
*   **`families.py`**: Rotas que gerenciam criação de novos lares `FamilyUnit`, gestão de colab/unilateral modes, e convites paralelos.
*   **`calendar.py`**: Une logicamente as Querys do Mês aos `checkins`, devolvendo a Timeline populada. Trata a adição global de eventos isolados (`CustodyEvent`).
*   **`checkins.py`**: Grava Check-ins avulsos passados do front (lat/lon) atrelados ou não à um Schedule. 
*   **`expenses.py`**: Gerenciador que faz Upload pra S3 via endpoint Multipart Form, delega Análise Generativa de Documentos de recibos e atrela custos aos membros. Exporta predefinição em `/categories`.
*   **`locations.py`**: Controla adição de endereços fixos por família e expõe via `autocomplete` o PlaceAPI de localizações Google.
*   **`reports.py`**: Central do motor assíncrono final que capta Log do banco do App, manda para GPT resumos de "Clima e Relatório Jurídico do mês", exporta o HTML com carimbo Hash e gera / Serve um PDF em rotas seguras para o Juizado via App.

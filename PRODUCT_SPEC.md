# PRODUCT_SPEC – MEDIARE - MGCF (Mediador de Guarda & Compliance Familiar)
## Versão do Produto: 1.0 (MVP com Gamificação Completa)
## Status: Baseado no Documento Mestre – Fevereiro/2026

---

## 1. Visão geral do produto

- **Nome oficial:** MEDIARE - MGCF (Mediador de Guarda & Compliance Familiar)
- **Tagline:** "Transformando conflitos em acordos, registros em provas e obrigações em conquistas"
- **Categoria:** SaaS (Software as a Service)
- **Plataforma inicial:** Mobile-first (Android + iOS) **e Web (Flutter Web)** com possível expansão para outras plataformas no futuro.
- **Modelo de negócio:** Freemium com plano Premium de assinatura

### 1.1 Problema que resolve

Famílias separadas enfrentam, no dia a dia:

- Conflitos sobre convivência e troca de datas.
- Disputas financeiras sobre despesas da criança.
- Falta de provas confiáveis em processos judiciais.
- Comunicação hostil entre genitores.
- Ansiedade da criança com a separação.
- Desinformação sobre rotina escolar e saúde.

### 1.2 Solução oferecida

O MEDIARE - MGCF transforma a gestão da guarda (compartilhada ou unilateral) em um processo:

- **Organizado:** calendário centralizado, endereços cadastrados, compromissos rastreados.
- **Transparente:** linha do tempo imutável, hash de integridade, relatórios auditáveis.
- **Juridicamente válido:** registros robustos aceitos em tribunais (PDFs, hashes, histórico).
- **Pacífico:** IA modera comunicação e sugere reescritas neutras.
- **Educativo:** gamificação engaja a criança, transformando obrigações em conquistas.

---

## 2. Público-alvo

### 2.1 Primário – Genitores separados

- Em processo de separação ou já separados.
- Com ou sem acordo judicial formal.
- Guarda compartilhada ou unilateral.
- Diferentes níveis de colaboração com o ex-parceiro.

**Perfis:**

- **Genitor colaborativo:**
  - Usa todas as funções (calendário, chat, financeiro, gamificação, relatórios).
- **Genitor unilateral:**
  - Usa o app como "Diário de Bordo" mesmo que o outro não entre (Modo Unilateral robusto).

### 2.2 Secundário

- **Profissionais jurídicos:**
  - Advogados de família, peritos, mediadores, defensores.
- **Crianças e adolescentes:**
  - Faixa etária: 4–17 anos.
  - Acesso via **Modo Criança** (interface lúdica, segura e isolada).
- **Instituições:**
  - Escolas, psicólogos, assistentes sociais (futuro/B2B).

---

## 3. Proposta de valor (por persona)

### 3.1 Genitores

- **Segurança jurídica**
  - Registros imutáveis (soft delete).
  - Hash de integridade em mídias.
  - Relatórios em PDF com linha do tempo e assinatura digital.

- **Paz financeira**
  - Rateio automático de despesas.
  - Aprovação prévia de gastos (orçamentos).
  - Histórico auditável de acordos financeiros.

- **Redução de conflitos**
  - IA de moderação de chat: bloqueio de mensagens tóxicas, sugestão de reescrita.
  - Registro de descumprimentos e atrasos.
  - Formalização digital de acordos.

- **Organização da rotina**
  - Calendário centralizado de convivência.
  - Endereços pré-cadastrados.
  - Compromissos rastreados com status e checklist.
  - Check-ins com GPS (retirada/devolução).

### 3.2 Crianças

- **Engajamento positivo**
  - Sistema de pontos (StarPoints), níveis e recompensas.
  - Narrativa de “Jornada do Herói”.

- **Redução de ansiedade**
  - Visualização clara da agenda (onde estará e com quem).
  - Feedback positivo por cumprimento de tarefas.

- **Educação**
  - Metas educativas e tarefas escolares gamificadas.
  - Gráficos de evolução.

### 3.3 Profissionais jurídicos

- **Eficiência**
  - Relatórios prontos em PDF.
  - Linha do tempo cronológica.
  - Dados auditáveis e filtráveis.

- **Confiabilidade**
  - Hash de integridade.
  - Imutabilidade de registros (soft delete, histórico).

---

## 3. Histórias de Usuário

### 3.1 Genitor Colaborativo

- Como um genitor colaborativo, quero registrar compromissos no calendário para que o outro genitor seja notificado e possa confirmar ou sugerir alterações.
- Como um genitor colaborativo, quero aprovar ou rejeitar despesas enviadas pelo outro genitor para garantir que os gastos sejam justos e acordados.
- Como um genitor colaborativo, quero acessar o aplicativo pelo navegador do meu computador para gerenciar o calendário de convivência de forma mais prática.
- Como um genitor colaborativo, quero registrar despesas e anexar comprovantes diretamente pelo navegador para maior conveniência.
- Como um genitor colaborativo, quero alternar entre diferentes famílias no aplicativo para gerenciar múltiplos contextos familiares.
- Como um genitor colaborativo, quero definir o modo de colaboração (colaborativo ou unilateral) ao criar uma nova família.

### 3.2 Genitor Unilateral

- Como um genitor unilateral, quero registrar compromissos e despesas para manter um histórico pessoal, mesmo sem a participação do outro genitor.
- Como um genitor unilateral, quero usar o aplicativo no navegador para registrar eventos e despesas, mesmo que o outro genitor não utilize o sistema.
- Como um genitor unilateral, quero usar o aplicativo para gerenciar uma única família sem depender da adesão do outro genitor.
- Como um genitor unilateral, quero alternar entre diferentes famílias, caso eu seja responsável por mais de uma.

### 3.3 Criança

- Como criança, quero ganhar pontos (StarPoints) ao cumprir tarefas e compromissos para me sentir motivado e engajado.
- Como criança, quero visualizar minhas conquistas e recompensas para acompanhar meu progresso na "Jornada do Herói".
- Como uma criança, quero acessar o Modo Criança pelo navegador para acompanhar minha agenda e ganhar recompensas de forma divertida.

### 3.4 Profissionais Jurídicos

- Como um advogado, quero acessar relatórios e registros pelo navegador para facilitar a análise e uso em processos judiciais.

---

## 4. Fluxos de Usuário

### 4.1 Modo Colaborativo vs Unilateral
- No modo colaborativo, ambos os genitores têm acesso igual às funcionalidades da família.
- No modo unilateral, apenas um genitor tem acesso e controle total sobre os registros.

### 4.2 Multi-família
- Usuários podem criar ou participar de múltiplas famílias.
- O aplicativo deve permitir alternar entre famílias ativas por meio de um Context Switcher.
- Todas as funcionalidades do aplicativo devem respeitar o contexto da família ativa.

### 4.3 Gestão de Endereços
- Usuários podem cadastrar, editar, listar e remover endereços associados à família ativa.
- Cada endereço deve ser vinculado a um tipo predefinido (Casa Pai, Casa Mãe, Escola, etc.).
- O sistema deve integrar com o Google Maps API para geocodificação (endereço → latitude/longitude).
- Histórico de uso de localizações deve ser registrado automaticamente para check-ins e compromissos.

### 4.4 Calendário & Convivência
- Usuários podem definir regras de guarda para crianças (ex.: horários de convivência).
- Eventos de convivência são listados por criança, período e família.
- Check-ins de retirada/devolução podem ser registrados com GPS e status (on_time, late, etc.).
- Atrasos são registrados automaticamente com base em horários previstos.

### 4.5 Gestão de Despesas
- Usuários podem registrar despesas associadas a uma criança e anexar comprovantes.
- O sistema deve calcular o hash SHA‑256 do comprovante e armazená-lo para validação futura.
- Despesas podem ser rateadas automaticamente entre os membros da família com base em percentuais configuráveis.
- Despesas podem ser listadas e filtradas por família, criança e período.

### 4.6 Gestão de Orçamentos
- Usuários podem criar orçamentos com descrição, valor estimado e criança opcional.
- Orçamentos podem ser aprovados, rejeitados ou cancelados, com status atualizados automaticamente.
- Orçamentos podem ser vinculados a despesas ou compromissos quando aplicável.
- O sistema deve listar orçamentos por status (pendentes, aprovados, rejeitados).

### 4.7 Chat com IA & Mediação
- Usuários podem enviar mensagens no chat oficial da família.
- Mensagens são analisadas pela IA para calcular `toxicity_score` e `sentiment_score`.
- Mensagens muito tóxicas são bloqueadas ou recebem sugestões de reescrita antes do envio.
- Mensagens podem ser marcadas como lidas (read receipts).
- Mensagens são listadas por família com paginação.

### 4.8 Modo Criança – Gamificação
- Pais podem criar, editar e excluir tarefas associadas a uma criança.
- Crianças podem marcar tarefas como concluídas, e os pais podem aprová-las.
- O sistema atualiza automaticamente os pontos e níveis das crianças com base nas tarefas concluídas.
- Crianças podem resgatar recompensas disponíveis com os pontos acumulados.
- O Modo Criança exibe uma interface lúdica com:
  - Lista de tarefas do dia.
  - Feedback visual e sonoro ao completar tarefas.
  - Exibição de pontos, nível atual e recompensas disponíveis.

### 4.9 Compromissos Avançados
- Usuários podem criar, editar e excluir compromissos associados a uma família.
- Compromissos podem ter 9 status de execução: Agendado, Confirmado, Em Andamento, Cumprido, Atrasado, Cancelado, etc.
- O sistema detecta automaticamente atrasos com base no horário planejado vs horário real (check-ins).
- Checklists pré e pós-compromisso podem ser gerenciados pelos responsáveis.
- O histórico de status dos compromissos é registrado automaticamente.

### 4.10 Relatórios Jurídicos
- Eventos importantes (despesas, atrasos, check-ins, compromissos, chat, tarefas) são registrados automaticamente no `event_log`.
- Usuários podem configurar relatórios com filtros por período, criança e tipo de dado.
- Relatórios são gerados em PDF com:
  - Linha do tempo cronológica.
  - Estatísticas de cumprimento.
  - Hash SHA‑256 exibido no rodapé para validação.
- Relatórios gerados são listados no sistema com opção de download ou visualização.

### 4.11 Infraestrutura Invisível
- O sistema deve funcionar no modo offline-first, utilizando cache local (Hive) para dados críticos.
- Dados pendentes devem ser sincronizados automaticamente quando a conexão for restabelecida.
- Notificações push devem suportar deep linking para abrir telas específicas no aplicativo.
- Feature flags devem ser configuradas via Remote Config para ativar/desativar funcionalidades específicas.

### Critérios de Aceite
- O sistema deve funcionar corretamente no modo offline e sincronizar dados pendentes ao voltar online.
- O deep linking deve abrir as telas corretas com base nas notificações push recebidas.
- Feature flags devem ser configuráveis e refletir mudanças em tempo real no aplicativo.
- Logs estruturados devem registrar eventos importantes no backend.
- O endpoint `/health` deve retornar o status do sistema.

---

## 4. Critérios de Aceite

- O usuário consegue registrar um compromisso no calendário em até 3 passos.
- O sistema notifica o outro genitor sobre novos compromissos ou alterações.
- O sistema permite que os genitores aprovem ou rejeitem despesas em até 2 cliques.
- A criança consegue visualizar suas tarefas e recompensas de forma lúdica e intuitiva.
- Todos os registros possuem hash SHA-256 para garantir integridade e validade jurídica.
- Endereços devem ser filtrados por `family_unit_id`.
- Apenas usuários com permissões adequadas podem criar, editar ou remover endereços.
- A geocodificação deve validar endereços antes de salvá-los no sistema.
- O frontend deve ser responsivo e exibir mapas para visualização de localizações (quando possível).
- Regras de guarda devem ser vinculadas a `family_unit_id` e `child_id`.
- Eventos e check-ins devem ser filtrados por `family_unit_id` e `child_id`.
- O frontend deve exibir um calendário com visão mensal/semanal e filtros por criança.
- O Modo Criança deve exibir uma versão lúdica do calendário, sem detalhes de conflito.

---

## 5. Gamificação Infantil

- **Sistema de Pontos (StarPoints):**
  - Cada tarefa ou compromisso cumprido pela criança gera pontos.
  - Os pais podem configurar a quantidade de pontos para cada tarefa.

- **Recompensas Configuráveis:**
  - Os pais podem criar recompensas personalizadas (ex.: 100 pontos = 1 hora de videogame).

- **Jornada do Herói:**
  - Interface lúdica que apresenta a criança como um herói em uma jornada.
  - Conquistas e badges são desbloqueados conforme o progresso.

- **Feedback Visual:**
  - Animações e sons para celebrar conquistas.
  - Indicadores claros de progresso e metas alcançadas.

---

## 4. Modelo de negócio (1.0)

### 4.1 Plano FREE

- 1 família.
- 1 criança.
- Calendário básico.
- Chat com moderação básica.
- Relatórios limitados (1 por mês).

### 4.2 Plano PREMIUM

- Múltiplas famílias.
- Múltiplas crianças.
- Relatórios ilimitados.
- Hash de integridade em todas as mídias relevantes.
- Gamificação completa (Modo Criança completo).
- Orçamentos & compromissos avançados.
- Módulo de endereços.
- Armazenamento em nuvem (com limites definidos em política).
- Suporte prioritário.

*(Detalhes exatos de limite de armazenamento, se existirem, devem ser definidos em política de produto – `TODO: confirmar`.)*

---

## 5. Escopo funcional – MVP 1.0 (por módulo)

### 5.1 MÓDULO 1 – Cadastro Rigoroso & Multi-Família (Core do onboarding)

**Objetivo:**  
Garantir identificação robusta de genitores e estruturação correta das famílias e crianças, com suporte a múltiplos núcleos familiares (Premium).

**Funcionalidades chave:**

- Wizard obrigatório de cadastro:
  - Dados pessoais do genitor (nome, CPF, RG, e-mail, telefone).
  - Upload de selfie e/ou documento.
- Cadastro de pelo menos 1 criança (obrigatório).
- Multi-família:
  - Um usuário pode ter múltiplas “family_units” (Premium).
- **Modo Colaborativo vs Modo Unilateral:**
  - Colaborativo: ambos os genitores usam o app.
  - Unilateral: apenas um genitor usa; o outro não entra, mas o sistema continua funcionando como “diário de bordo”.

**Regras críticas:**

- Cada família é um tenant lógico isolado.
- Não é permitido usar o app sem vincular a pelo menos uma criança.

---

### 5.2 MÓDULO 2 – Gestão de Endereços & Localizações

**Objetivo:**  
Organizar locais relevantes e associá-los aos eventos (retirada, devolução, escola, médico etc.), com suporte a GPS.

**Funcionalidades:**

- Cadastro de endereços completos.
- Tipos pré-definidos (Casa Pai, Casa Mãe, Escola, Médico, etc.).
- Geocodificação automática via Google Maps API.
- Verificação de proximidade GPS (check-in).
- Histórico de uso por localização.
- Configuração de visibilidade entre genitores.

---

### 5.3 MÓDULO 3 – Calendário & Convivência

**Objetivo:**  
Centralizar o calendário de guarda, convivência e trocas.

**Funcionalidades:**

- Calendário oficial de guarda.
- Filtro por criança.
- Solicitação de troca de datas.
- Check-in de retirada/devolução com GPS.
- Registro de atrasos.
- Integração com endereços cadastrados.
- Visualização lúdica para Modo Criança (sem dados sensíveis).

---

### 5.4 MÓDULO 4 – Financeiro & Orçamentos

**Objetivo:**  
Organizar despesas da criança, com rateios justos e auditáveis.

**Funcionalidades:**

- Registro de despesas com anexos (comprovantes).
- Rateio automático configurável (percentuais).
- Sistema de orçamentos:
  - Criação de orçamento (antes da despesa).
  - Aprovação/recusa do orçamento.
  - Negociação de rateios.
- Histórico completo.
- Hash de integridade dos comprovantes (para validação jurídica).

---

### 5.5 MÓDULO 5 – Chat com IA & Mediação

**Objetivo:**  
Ser o canal oficial de comunicação entre genitores, com moderação automática.

**Funcionalidades:**

- Chat por família (canal único oficial).
- Moderação automática por IA:
  - Bloqueio de mensagens tóxicas.
  - Sugestão de reescrita neutra.
  - Análise de sentimento.
- Prova de leitura (read receipts).
- Transformação de mensagens em:
  - Tarefas.
  - Acordos.
  - Itens de calendário ou compromissos.

**Regras:**

- Mensagens tóxicas podem:
  - Ser bloqueadas.
  - Ser marcadas e exigir reescrita.
  - `TODO: confirmar política UX: bloqueia duro ou só alerta?`

---

### 5.6 MÓDULO 6 – Gamificação Infantil (Modo Criança)

**Objetivo:**  
Transformar obrigações (tarefas, rotina) em conquistas lúdicas.

**Funcionalidades:**

- Sistema de pontos (StarPoints).
- Níveis (Bronze → Diamante).
- Tarefas criadas pelos pais:
  - Tarefas escolares.
  - Tarefas de rotina (ex.: arrumar mochila, horário de dormir).
- Execução e aprovação de tarefas:
  - Criança marca como feita.
  - Pai/mãe aprova.
- Recompensas configuráveis (ex.: passeio, tempo de tela).
- Conquistas e badges automáticos.
- Interface lúdica “Jornada do Herói”.
- Isolamento de dados sensíveis:
  - Modo Criança não mostra conflitos, finanças, detalhes de adulto.

---

### 5.7 MÓDULO 7 – Compromissos Avançados

**Objetivo:**  
Detalhar eventos específicos além do calendário de guarda: passeios, viagens, atividades.

**Funcionalidades:**

- Criação de compromissos detalhados:
  - Tipo (passeio, viagem, consulta, atividade escolar, etc.).
  - Responsável pelo transporte (quem busca/quem leva).
  - Responsabilidades financeiras (quem paga o quê).
- Integração com endereços cadastrados.
- 9 status de execução (Agendado, Confirmado, Em Andamento, Cumprido, Atrasado, Cancelado, etc.).
- Detecção automática de atrasos.
- Checklist pré e pós-compromisso.
- Histórico de mudanças (quem alterou o quê, quando).

---

### 5.8 MÓDULO 8 – Relatórios Jurídicos

**Objetivo:**  
Gerar relatórios aceitos em tribunais, com integridade e auditabilidade.

**Funcionalidades:**

- Linha do tempo imutável (eventos ordenados).
- Exportação em PDF:
  - Com assinatura digital.
  - Com hash SHA-256 no rodapé para cada relatório/arquivo.
- Filtros:
  - Por período.
  - Por tipo de dado (financeiro, calendário, atrasos, etc.).
  - Por criança.
- Estatísticas de cumprimento (percentual de compromissos honrados vs. atrasos).
- Anexos de evidências:
  - Capturas de tela, comprovantes, fotos relevantes.

---

### 5.9 MÓDULO 9 – Infraestrutura Invisível

**Objetivo:**  
Garantir que o app funcione bem tecnicamente, muitas vezes de forma transparente ao usuário.

**Funcionalidades:**

- Offline-first (cache local via Hive).
- Deep linking em notificações (abrir tela certa ao clicar).
- Feature flags (Remote Config).
- Monitoramento de erros (Sentry + Crashlytics).
- Exclusão de conta em conformidade com lojas (Apple/Google).
- Compressão automática de imagens.
- Sincronização automática com o backend.

---

## 6. Métricas de sucesso (MVP 1.0)

- **Aquisição:**
  - 1.000 usuários em 3 meses.
  - 50% criam pelo menos uma família.
  - 30% registram pelo menos um evento ou despesa.

- **Engajamento:**
  - 60% ativos semanais (WAU).
  - 3+ sessões/semana por usuário.
  - 5+ eventos/despesas por mês.

- **Retenção:**
  - 70% retenção 1º mês.
  - 50% 3º mês.
  - 40% 6º mês.

- **Monetização:**
  - 15% conversão para Premium em 3 meses.
  - LTV R$ 500 por usuário Premium.

- **Qualidade:**
  - NPS > 50.
  - Nota média > 4.5.
  - Taxa de crash < 1%.

---

## 7. Riscos relevantes (MVP) e diretrizes

- **Baixa adesão do outro genitor:**
  - Modo Unilateral precisa ser realmente útil sozinho.

- **Dados sensíveis de crianças:**
  - Modo Criança isolado, sem exposição de conflitos.

- **Conflitos jurídicos sobre validade de provas:**
  - Soft delete, hashes, logs, linha do tempo imutável.

- **Custo de IA (chat):**
  - Feature flag para ligar/desligar moderação.
  - Otimização de chamadas e prompts.

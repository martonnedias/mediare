# Fluxograma Operacional – MEDIARE MGCF (Versão 1.0)

Este documento descreve detalhadamente as jornadas mapeadas e concluídas que operam hoje no MVP da Plataforma. Aqui rastreamos as integrações ponta a ponta que o código exerce.

## 1. A Jornada do Onboarding e Segurança Inicial
O fluxo base do App determina a segurança do multi-tenant PostgreSQL (Separar cada criança e família de contas vazadas).

1. O Usuário acessa o app via Mobile ou URL pelo Flutter Web num layout Soft Clean.
2. Aciona Auth-State via Firebase Authentication (Provedor oficial nativo e criptográfico).
3. Posta na Rota `/users/sync` do FastAPI.
4. O Backend confirma se `onboarding_completed` é `True`. Caso `False`:
   * Redireciona o usuário a **Wizard de Onboarding**.
   * Cadastra Cpf, LGPD, Laços Pessoais e Nomenclatura da Família no Módulo `FamilyService`.
   * Cadastra os dados Sensíveis Menores `/children/` na Base de dados.
   * Modifica Boolean do Backend para fechar o gate da Rota. Redireciona ao Hub do App.

## 2. O Aglutinador: `Calendar` x `Checkins` (Timeline de Convivência)
Os dados parentais não habitam rotas separadas na visualização. 

1. O Usuário clica na tela **Calendário**. 
2. A tela dispara um HTTP Request parametrizado para `/calendar/events` puxando os 30 dias passados + 30 futuros baseados na _sua_ Família filtrada.
3. O Backend compila a listagem base ORM iterando relações da tabela filha (Model.CheckIn). Em uma única requisição a UI recebe os Agendamentos prévios (`CustodyEvents`) + Pontos geolocais do dia (`Checkins`).
4. **Plotagem da Grade Mensal:** Pontos verdes e azuis determinam quem cuida naquele dia via layout do grid.
5. **A Linha do Tempo (24H):** Widgets customizados varrem horizontalmente as horas convertendo carimbos de Checkin via ícones do mapa, permitindo clareza total dos fatos e locais e gerando um botão interativo instantâneo de GPS Checkin caso a troca ainda dependa do usuário naquele horário.

## 3. Gastos, Finanças e OCR de I.A
Comprovantes precisam de segurança anti-fraude integrando Análise Lógica antes de entrarem para rateio ou bloqueios legais nas finanças.

1. Genitor aperta Botão de Adição no módulo.
2. Faz upload de PDF/IMG ou Câmera do recibo.
3. Chama Rota API via Multipart-Form enviando Bytes brutos na `/expenses/analyze-receipt`.
4. A IA do Backend detecta CNPJ, Gasto Numérico Decimal, formata os números, os injeta limpos pro App. 
5. O Usuário corrige via `SoftInputs` os resquícios, altera para Categoria de gastos (`/expenses/categories`) customizadas (Saúde/Educação).
6. FastAPI manda Arquivo Binário assinado Hash (SHA256) pra S3 Bucket. Salva string do storage, vincula o valor Decimal com a chave Multi-Tenant. Transmite a métrica (Ex: 50/50 Divisão) ao Dashboard Geral da Casa.

## 4. Auditoria Jurídica Autônoma
No menu `Settings` o MVP concentra o exportador de fatos consolidado. Todo evento de calendário, GPS checado e pagamento enviado compõem um Rastreio de ID Interna no Backend (Log Histórico).

1. Advogado orienta, Genitor requer: Clica em "Exportar Dossier".
2. O Backend FastAPI inicia `GET Reports`. Coleta `events` e `expenses`. Dispara Payload JSON via IA do Google Studio/GPT.
3. A inteligência aglutina em PT-BR a prosa narrativa imparcial se houve desregulação de prazos parentais no mês, atrasos ou faltas graves ("Contexto Geral"). 
4. A Rota Backend compõe Documento Jinja/HTML estilizado com Logo com PDF renderizado localmente enviando Hash criptográfico, e gerencia na tela Final para impressão. 

## 5. Falta de Rede, Conexão e Fila
Disparos que ocorrem durante saídas ou cortes de internet precisam subsistir.

1. Tela Mobile recebe bloqueio Exception na Rede (`SocketException` interna do HTTP).
2. O wrapper central (`SyncService` e o uso adaptado de Hive BD) arquiva localmente Payload bruto do calendário ou Gastos criados.
3. Notifica interface amarela Soft, "Aguardando Sincronização offline".
4. Ao restabelecimento App-Lifecycle o singleton limpa fila do Local storage varrendo cada Index efetuado o Request pendente e acionando callbacks UI para refresh e repintura correta das Listviews.

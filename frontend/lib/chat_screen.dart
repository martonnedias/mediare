import 'package:flutter/material.dart';
import 'api_service.dart';
import 'family_service.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  List<dynamic> _messages = [];
  bool _isLoading = true;
  int get _chatId => FamilyService().currentFamily.id;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await ApiService.get('/chats/messages?chat_id=$_chatId');
      setState(() {
        _messages = response['messages'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      _loadMockMessages();
    }
  }

  void _loadMockMessages() {
    setState(() {
      _messages = [
        {'id': 1, 'sender_id': 2, 'content': 'Olá, como está a Ana?', 'moderation_status': 'allowed', 'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String()},
        {'id': 2, 'sender_id': 1, 'content': 'Ela está bem, acabou de chegar da escola.', 'moderation_status': 'allowed', 'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String()},
        {'id': 3, 'sender_id': 2, 'content': 'Ótimo. Lembre de mandar o casaco amanhã.', 'moderation_status': 'needs_rewrite', 'created_at': DateTime.now().toIso8601String()},
      ];
      _isLoading = false;
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text;
    _messageController.clear();

    try {
      await ApiService.post('/chats/messages', {
        'chat_id': _chatId,
        'content': content,
      });
      _fetchMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('bloqueada') 
              ? 'Mensagem bloqueada por toxicidade! Mantenha o respeito.' 
              : 'Erro ao enviar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Column(
      children: [
        if (isDesktop) _buildWebHeader(context),
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'Conversa Geral'),
            Tab(text: 'Acordos & Notas'),
            Tab(text: 'Saúde & Escola'),
            Tab(text: 'Moderação IA'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildChatThread(context, isDesktop),
              _buildNotesView(context),
              const Center(child: Text('Tópico de Saúde e Escola em breve')),
              _buildIAModerationView(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Text(
            'Central de Comunicação',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.security, size: 16, color: Colors.green),
                SizedBox(width: 8),
                Text('Chat Monitorado por IA', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatThread(BuildContext context, bool isDesktop) {
    return Column(
      children: [
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final bool isMe = msg['sender_id'] == 1; // Mock: assumindo user_id 1
                  return _MessageBubble(
                    isMe: isMe, 
                    message: msg['content'],
                    status: msg['moderation_status'],
                    timestamp: msg['created_at'],
                  );
                },
              ),
        ),
        _buildMessageInput(context, isDesktop),
      ],
    );
  }

  Widget _buildMessageInput(BuildContext context, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.attach_file, color: Colors.grey), onPressed: () {}),
          Expanded(
            child: TextField(
              controller: _messageController,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Digite sua mensagem amigável...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestAIAgreement() async {
    final conflictController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('IA Mediadora • Sugerir Acordo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Descreva brevemente o impasse ou o que precisa ser decidido:', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: conflictController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ex: Não entramos em acordo sobre o horário do curso de inglês...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () async {
              final conflict = conflictController.text;
              Navigator.pop(context);
              _showAISuggestion(conflict);
            },
            child: const Text('GERAR SUGESTÃO'),
          ),
        ],
      ),
    );
  }

  void _showAISuggestion(String conflict) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AISuggestionSheet(conflict: conflict),
    );
  }

  Widget _buildNotesView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Text(
              'Acordos Imutáveis',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _requestAIAgreement,
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('IA MEDIADORA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildNoteCard('Troca de Final de Semana', 'Ana ficará com o Pai no dia 15/02 conforme acordado no chat.', 'Assinado: Genitor A, Genitor B'),
        _buildNoteCard('Divisão de Material Escolar', 'Rateio de 50% para a lista de livros técnicos.', 'Assinado: Genitor A, Genitor B'),
      ],
    );
  }

  Widget _buildNoteCard(String title, String content, String hash) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(content, style: TextStyle(color: Colors.grey.shade700)),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.verified_user, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Text(hash, style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIAModerationView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Icon(Icons.psychology, size: 80, color: Theme.of(context).primaryColor),
          const SizedBox(height: 24),
          Text(
            'Monitoramento de Bem-Estar',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nossa IA analisa o tom das mensagens para prevenir conflitos e garantir que a comunicação seja focada no melhor interesse da criança.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 40),
          _buildInsightCard('Últimos 30 dias', 'Comunicação Estável', Icons.trending_up, Colors.green),
          _buildInsightCard('Alertas de Tom', '0 Detectados', Icons.notifications_none, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final bool isMe;
  final String message;
  final String status;
  final String timestamp;

  const _MessageBubble({
    required this.isMe, 
    required this.message, 
    required this.status,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime dt = DateTime.parse(timestamp);
    final String timeStr = DateFormat('HH:mm').format(dt);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * (isMe ? 0.6 : 0.7)),
            decoration: BoxDecoration(
              color: isMe ? Theme.of(context).primaryColor : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(20),
              ),
              boxShadow: [
                if (!isMe) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(color: (isMe ? Colors.white70 : Colors.grey), fontSize: 10),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all, size: 12, color: Colors.white70),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (status == 'needs_rewrite')
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Sugestão IA: Tom pode ser interpretado como hostil.',
                    style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _AISuggestionSheet extends StatefulWidget {
  final String conflict;
  const _AISuggestionSheet({Key? key, required this.conflict}) : super(key: key);

  @override
  State<_AISuggestionSheet> createState() => _AISuggestionSheetState();
}

class _AISuggestionSheetState extends State<_AISuggestionSheet> {
  String? _suggestion;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchSuggestion();
  }

  Future<void> _fetchSuggestion() async {
    try {
      final res = await ApiService.post('/agreements/suggest', {
        'conflict_context': widget.conflict,
        'child_name': 'Filho(a)', // Pode ser extraído da família
        'family_unit_id': FamilyService().currentFamily.id,
      });
      setState(() {
        _suggestion = res['suggestion'];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _suggestion = "Erro ao obter sugestão: $e";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber),
              const SizedBox(width: 12),
              Text('Sugestão da IA Mediadora', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analisando contexto e gerando resolução pacífica...'),
                ],
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(
                _suggestion ?? '',
                style: const TextStyle(fontSize: 15, height: 1.5, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context), 
                    child: const Text('IGNORAR'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Lógica futura: salvar como acordo oficial
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acordo enviado para validação do outro genitor.')));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                    child: const Text('ACEITAR E ENVIAR'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

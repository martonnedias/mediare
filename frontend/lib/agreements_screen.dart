import 'package:flutter/material.dart';
import 'api_service.dart';
import 'family_service.dart';
import 'package:intl/intl.dart';
import 'utils.dart';

class AgreementsScreen extends StatefulWidget {
  const AgreementsScreen({Key? key}) : super(key: key);

  @override
  State<AgreementsScreen> createState() => _AgreementsScreenState();
}

class _AgreementsScreenState extends State<AgreementsScreen> {
  List<dynamic> _agreements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAgreements();
  }

  Future<void> _fetchAgreements() async {
    setState(() => _isLoading = true);
    try {
      final familyId = FamilyService().currentFamily.id;
      final response = await ApiService.get('/agreements?family_unit_id=$familyId');
      setState(() {
        _agreements = response['agreements'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddAgreementDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddAgreementDialog(onSuccess: _fetchAgreements),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _agreements.isEmpty
                      ? _buildEmptyState()
                      : _buildAgreementsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAgreementDialog,
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.gavel, color: Colors.white),
        label: const Text('NOVA CLÁUSULA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acordos e Convivência',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
        const Text('Repositório oficial de cláusulas e combinados da família'),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.gavel_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Nenhuma cláusula registrada.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Registre os combinados para evitar conflitos futuros.'),
        ],
      ),
    );
  }

  Widget _buildAgreementsList() {
    return ListView.builder(
      itemCount: _agreements.length,
      itemBuilder: (context, index) {
        final agreement = _agreements[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            title: Text(agreement['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Status: ${agreement['status']} • ${DateFormat('dd/MM/yy').format(DateTime.parse(agreement['created_at']))}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(agreement['content']),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddAgreementDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const _AddAgreementDialog({Key? key, required this.onSuccess}) : super(key: key);

  @override
  State<_AddAgreementDialog> createState() => _AddAgreementDialogState();
}

class _AddAgreementDialogState extends State<_AddAgreementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSubmitting = false;
  String? _aiSuggestion;

  Future<void> _getAiSuggestion() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Descreva o contexto do conflito ou regra no campo de conteúdo para a IA ajudar.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await ApiService.post('/agreements/suggest', {
        'conflict_context': _contentController.text,
        'child_name': 'Filhos',
        'family_unit_id': FamilyService().currentFamily.id,
      });
      setState(() {
        _aiSuggestion = response['suggestion'];
        _isSubmitting = false;
      });
      _showAiSuggestionDialog();
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro na IA: $e')));
    }
  }

  void _showAiSuggestionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sugestão do Mediador IA'),
        content: SingleChildScrollView(child: Text(_aiSuggestion ?? '')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('FECHAR')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _contentController.text = _aiSuggestion!;
              });
              Navigator.pop(context);
            },
            child: const Text('USAR TEXTO'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final familyId = FamilyService().currentFamily.id;
      await ApiService.post('/agreements', {
        'title': _titleController.text,
        'content': _contentController.text,
        'status': 'approved',
        'family_unit_id': familyId,
      });
      Navigator.pop(context);
      widget.onSuccess();
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova Cláusula / Acordo'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppUI.buildPremiumTextField(
                controller: _titleController,
                label: 'Título da Cláusula',
                hint: 'Ex: Regra de Finais de Semana',
                icon: Icons.title,
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 20),
              AppUI.buildPremiumTextField(
                controller: _contentController,
                label: 'Conteúdo da Regra',
                hint: 'Descreva detalhadamente o combinado...',
                icon: Icons.description,
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _getAiSuggestion,
                icon: const Icon(Icons.psychology),
                label: const Text('AJUDA COM IA (MEDIADOR)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
          child: _isSubmitting 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('SALVAR ACORDO'),
        ),
      ],
    );
  }
}

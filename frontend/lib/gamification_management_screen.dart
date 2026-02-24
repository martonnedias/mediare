import 'package:flutter/material.dart';
import 'api_service.dart';
import 'family_service.dart';
import 'package:intl/intl.dart';
import 'utils.dart';

class GamificationManagementScreen extends StatefulWidget {
  const GamificationManagementScreen({Key? key}) : super(key: key);

  @override
  State<GamificationManagementScreen> createState() => _GamificationManagementScreenState();
}

class _GamificationManagementScreenState extends State<GamificationManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _tasks = [];
  List<dynamic> _rewards = [];
  List<dynamic> _children = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      final familyId = FamilyService().currentFamily.id;
      final childrenRes = await ApiService.get('/users/children?family_unit_id=$familyId');
      _children = childrenRes['children'] ?? [];

      final tasksRes = await ApiService.get('/tasks?family_unit_id=$familyId');
      _tasks = tasksRes['tasks'] ?? [];

      final rewardsRes = await ApiService.get('/rewards?family_unit_id=$familyId');
      _rewards = rewardsRes['rewards'] ?? [];
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddTaskDialog(
        children: _children,
        onSuccess: _fetchInitialData,
      ),
    );
  }

  void _showAddRewardDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddRewardDialog(
        onSuccess: _fetchInitialData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32.0 : 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).primaryColor,
                tabs: const [
                  Tab(text: 'MISSÕES'),
                  Tab(text: 'RECOMPENSAS'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTasksSection(),
                _buildRewardsSection(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tabController.index == 0 ? _showAddTaskDialog : _showAddRewardDialog,
        backgroundColor: Theme.of(context).primaryColor,
        icon: Icon(_tabController.index == 0 ? Icons.add_task : Icons.card_giftcard, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'NOVA MISSÃO' : 'NOVA RECOMPENSA',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Text(
      'Gestão de Gamificação',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
    );
  }

  Widget _buildTasksSection() {
    if (_children.isEmpty) {
      return const Center(child: Text('Cadastre filhos no perfil para gerenciar missões.'));
    }
    if (_tasks.isEmpty) {
      return const Center(child: Text('Nenhuma missão cadastrada.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        final isCompleted = task['status'] == 'completed';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCompleted ? Colors.green.withValues(alpha: 0.1) : Colors.amber.withValues(alpha: 0.1),
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.pending_actions,
                color: isCompleted ? Colors.green : Colors.amber,
              ),
            ),
            title: Text(
              task['name'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text('${task['points']} XP • Para: ${task['child_name'] ?? 'Filho'}'),
            trailing: isCompleted 
                ? null 
                : TextButton(
                    onPressed: () => _completeTask(task['id']),
                    child: const Text('CONCLUIR'),
                  ),
            onLongPress: () => _deleteTask(task['id']),
          ),
        );
      },
    );
  }

  Widget _buildRewardsSection() {
    if (_rewards.isEmpty) {
      return const Center(child: Text('Nenhuma recompensa cadastrada.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rewards.length,
      itemBuilder: (context, index) {
        final reward = _rewards[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE0F2FE),
              child: Icon(Icons.card_giftcard, color: Color(0xFF0284C7)),
            ),
            title: Text(
              reward['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${reward['points_required']} XP Necessários'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteReward(reward['id']),
            ),
          ),
        );
      },
    );
  }

  Future<void> _completeTask(int taskId) async {
    try {
      await ApiService.post('/tasks/$taskId/complete', {});
      _fetchInitialData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _deleteTask(int taskId) async {
    try {
      await ApiService.delete('/tasks/$taskId');
      _fetchInitialData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _deleteReward(int rewardId) async {
    try {
      await ApiService.delete('/rewards/$rewardId');
      _fetchInitialData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }
}

class _AddTaskDialog extends StatefulWidget {
  final List<dynamic> children;
  final VoidCallback onSuccess;

  const _AddTaskDialog({Key? key, required this.children, required this.onSuccess}) : super(key: key);

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pointsController = TextEditingController(text: '50');
  int? _selectedChildId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.children.isNotEmpty) {
      _selectedChildId = widget.children[0]['id'];
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedChildId == null) return;
    setState(() => _isSubmitting = true);

    try {
      final familyId = FamilyService().currentFamily.id;
      await ApiService.post('/tasks', {
        'name': _nameController.text,
        'points': int.parse(_pointsController.text),
        'child_id': _selectedChildId,
        'family_unit_id': familyId,
        'description': 'Missão cadastrada pelo tutor',
      });
      Navigator.pop(context);
      widget.onSuccess();
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _fetchAISuggestions() async {
    if (_selectedChildId == null) return;
    setState(() => _isSubmitting = true);

    try {
      final response = await ApiService.get('/tasks/suggest-ai?child_id=$_selectedChildId');
      final List<dynamic> suggestions = response['suggestions'] ?? [];
      
      if (suggestions.isNotEmpty) {
        final first = suggestions[0];
        setState(() {
          _nameController.text = first['name'];
          _pointsController.text = first['points'].toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sugestão da IA carregada: ${first['name']}'),
          backgroundColor: Colors.blue.shade800,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível obter sugestões agora.')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova Missão'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: _selectedChildId,
              decoration: const InputDecoration(labelText: 'Filho Atribuído'),
              items: widget.children.map<DropdownMenuItem<int>>((c) => DropdownMenuItem<int>(
                value: c['id'],
                child: Text(c['name']),
              )).toList(),
              onChanged: (v) => setState(() => _selectedChildId = v),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _isSubmitting ? null : _fetchAISuggestions,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('GERAR MISSÃO COM IA'),
                style: TextButton.styleFrom(foregroundColor: Colors.blue.shade700),
              ),
            ),
            const SizedBox(height: 8),
            AppUI.buildPremiumTextField(
              controller: _nameController,
              label: 'Nome da Missão',
              hint: 'Ex: Arrumar Cama, Fazer Lição',
              icon: Icons.assignment,
              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 20),
            AppUI.buildPremiumTextField(
              controller: _pointsController,
              label: 'Valor em XP',
              hint: 'Ex: 50, 100',
              icon: Icons.star,
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
          child: _isSubmitting 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('CRIAR MISSÃO'),
        ),
      ],
    );
  }
}

class _AddRewardDialog extends StatefulWidget {
  final VoidCallback onSuccess;

  const _AddRewardDialog({Key? key, required this.onSuccess}) : super(key: key);

  @override
  State<_AddRewardDialog> createState() => _AddRewardDialogState();
}

class _AddRewardDialogState extends State<_AddRewardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pointsController = TextEditingController(text: '200');
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final familyId = FamilyService().currentFamily.id;
      await ApiService.post('/rewards', {
        'name': _nameController.text,
        'points_required': int.parse(_pointsController.text),
        'description': 'Recompensa cadastrada pelo tutor',
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
      title: const Text('Nova Recompensa'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppUI.buildPremiumTextField(
              controller: _nameController,
              label: 'Nome da Recompensa',
              hint: 'Ex: Cinema, Sorvete, Hora de Game',
              icon: Icons.card_giftcard,
              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 20),
            AppUI.buildPremiumTextField(
              controller: _pointsController,
              label: 'XP Necessário',
              hint: 'Ex: 200, 500',
              icon: Icons.star_border,
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
          child: _isSubmitting 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('CRIAR RECOMPENSA'),
        ),
      ],
    );
  }
}

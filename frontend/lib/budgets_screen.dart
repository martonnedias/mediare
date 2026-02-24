import 'package:flutter/material.dart';
import 'api_service.dart';
import 'family_service.dart';
import 'package:intl/intl.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({Key? key}) : super(key: key);

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  List<dynamic> _budgets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBudgets();
  }

  Future<void> _fetchBudgets() async {
    setState(() => _isLoading = true);
    try {
      final familyId = FamilyService().currentFamily.id;
      final response = await ApiService.get('/budgets?family_unit_id=$familyId');
      setState(() {
        _budgets = response['budgets'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      _loadMockBudgets();
    }
  }

  void _loadMockBudgets() {
    setState(() {
      _budgets = [
        {'id': 1, 'description': 'Reforma Quarto Infantil', 'estimated_value': 2500.0, 'status': 'proposed', 'created_at': DateTime.now().toIso8601String()},
        {'id': 2, 'description': 'Lista Material 2026', 'estimated_value': 850.0, 'status': 'approved', 'created_at': DateTime.now().toIso8601String()},
        {'id': 3, 'description': 'Viagem Disney Julho', 'estimated_value': 12000.0, 'status': 'rejected', 'created_at': DateTime.now().toIso8601String()},
      ];
      _isLoading = false;
    });
  }

  Future<void> _updateStatus(int id, String status) async {
    try {
      await ApiService.put('/budgets/$id/status', {'status': status});
      _fetchBudgets();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar: $e')));
    }
  }

  void _showAddBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddBudgetDialog(onSuccess: _fetchBudgets),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 32),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _budgets.isEmpty 
                ? const Center(child: Text('Nenhum orçamento cadastrado.'))
                : isDesktop ? _buildWebTable(currency) : _buildMobileList(currency),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Sistema de Orçamentos',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(FamilyService().currentFamily.mode.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  backgroundColor: FamilyService().currentFamily.mode == 'Colaborativo' ? Colors.green : Colors.orange,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Text('Aprovação e negociação de gastos extraordinários'),
          ],
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _showAddBudgetDialog,
          icon: const Icon(Icons.add),
          label: const Text('Novo Orçamento'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        ),
      ],
    );
  }

  Widget _buildWebTable(NumberFormat currency) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 40,
          columns: const [
            DataColumn(label: Text('Descrição')),
            DataColumn(label: Text('Valor Estimado')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Data')),
            DataColumn(label: Text('Ações')),
          ],
          rows: _budgets.map((b) {
            final statusInfo = _getStatusInfo(b['status']);
            return DataRow(cells: [
              DataCell(Text(b['description'], style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(currency.format(b['estimated_value']))),
              DataCell(Chip(
                label: Text(statusInfo.label, style: TextStyle(color: statusInfo.color, fontSize: 11)),
                backgroundColor: statusInfo.color.withValues(alpha: 0.1),
              )),
              DataCell(Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(b['created_at'])))),
              DataCell(Row(
                children: [
                  if (b['status'] == 'proposed') ...[
                    IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _updateStatus(b['id'], 'approved')),
                    IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _updateStatus(b['id'], 'rejected')),
                  ],
                  IconButton(icon: const Icon(Icons.message_outlined, color: Colors.blue), onPressed: () {}),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileList(NumberFormat currency) {
    return ListView.builder(
      itemCount: _budgets.length,
      itemBuilder: (context, index) {
        final b = _budgets[index];
        final statusInfo = _getStatusInfo(b['status']);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(b['description'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Valor: ${currency.format(b['estimated_value'])} • ${statusInfo.label}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        );
      },
    );
  }

  _StatusInfo _getStatusInfo(String status) {
    switch (status) {
      case 'approved': return _StatusInfo('Aprovado', Colors.green);
      case 'rejected': return _StatusInfo('Recusado', Colors.red);
      case 'proposed': return _StatusInfo('Em Análise', Colors.orange);
      default: return _StatusInfo('Cancelado', Colors.grey);
    }
  }
}

class _AddBudgetDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const _AddBudgetDialog({required this.onSuccess});

  @override
  State<_AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<_AddBudgetDialog> {
  final _descController = TextEditingController();
  final _valController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_descController.text.isEmpty || _valController.text.isEmpty) return;
    setState(() => _isSubmitting = true);

    try {
      await ApiService.post('/budgets', {
        'description': _descController.text,
        'estimated_value': double.parse(_valController.text.replaceAll(',', '.')),
        'family_unit_id': FamilyService().currentFamily.id,
        'child_id': null, // Opcional para o MVP
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
      title: const Text('Novo Orçamento'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Descrição do Gasto')),
          const SizedBox(height: 16),
          TextField(controller: _valController, decoration: const InputDecoration(labelText: 'Valor Estimado (R\$)'), keyboardType: TextInputType.number),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
          child: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('ENVIAR PARA APROVAÇÃO'),
        ),
      ],
    );
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  _StatusInfo(this.label, this.color);
}
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'family_service.dart';
import 'sync_service.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({Key? key}) : super(key: key);

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  List<dynamic> _expenses = [];
  bool _isLoading = true;
  double _totalExpenses = 0.0;
  double _myShare = 0.0;
  double _paidAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
    FamilyService().addListener(_onFamilyChanged);
  }

  @override
  void dispose() {
    FamilyService().removeListener(_onFamilyChanged);
    super.dispose();
  }

  void _onFamilyChanged() {
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    setState(() => _isLoading = true);
    final familyId = FamilyService().currentFamily.id;
    try {
      final response = await ApiService.get('/expenses?family_unit_id=$familyId');
      final List<dynamic> fetchedExpenses = response['expenses'] ?? [];
      
      double total = 0.0;
      for (var exp in fetchedExpenses) {
        total += (exp['amount'] as num).toDouble();
      }

      setState(() {
        _expenses = fetchedExpenses;
        _totalExpenses = total;
        _myShare = total * 0.5;
        _paidAmount = total * 0.3;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _loadMockData();
    }
  }

  void _loadMockData() {
    final familyName = FamilyService().currentFamily.name;
    setState(() {
      _expenses = List.generate(5, (index) => {
        'id': index,
        'description': index % 2 == 0 ? 'Mensalidade Escolar ($familyName)' : 'Atividade Extra',
        'amount': index % 2 == 0 ? 1250.0 : 450.0,
        'created_at': DateTime.now().subtract(Duration(days: index)).toIso8601String(),
        'status': 'Aprovado',
        'attachment_url': null,
      });
      _totalExpenses = 1700.0;
      _myShare = 850.0;
      _paidAmount = 500.0;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : isDesktop 
              ? _WebFinanceView(expenses: _expenses, total: _totalExpenses, myShare: _myShare, paid: _paidAmount, onRefresh: _fetchExpenses) 
              : _MobileFinanceView(expenses: _expenses, total: _totalExpenses, myShare: _myShare, paid: _paidAmount, onRefresh: _fetchExpenses),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseModal(context, isDesktop),
        backgroundColor: const Color(0xFF059669),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddExpenseModal(BuildContext context, bool isDesktop) {
    showDialog(
      context: context,
      builder: (context) => _AddExpenseModal(isDesktop: isDesktop, onSuccess: _fetchExpenses),
    );
  }
}

class _MobileFinanceView extends StatelessWidget {
  final List<dynamic> expenses;
  final double total;
  final double myShare;
  final double paid;
  final VoidCallback onRefresh;

  const _MobileFinanceView({required this.expenses, required this.total, required this.myShare, required this.paid, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSummaryCard(context),
          const SizedBox(height: 24),
          const Text('Lançamentos Recentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...expenses.map((exp) => _buildExpenseCard(context, exp)).toList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _row('Total de Despesas', currency.format(total), Colors.black),
            _row('Sua Parte (50%)', currency.format(myShare), Theme.of(context).primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, dynamic exp) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(exp['description'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Valor: ${currency.format(exp['amount'])}'),
        trailing: exp['attachment_url'] != null ? const Icon(Icons.attach_file, size: 18) : null,
        onTap: () => _viewReceipt(context, exp['id']),
      ),
    );
  }

  void _viewReceipt(BuildContext context, int? expenseId) async {
    if (expenseId == null) return;
    final uri = Uri.parse('${ApiService.baseUrl}/attachments/expenses/$expenseId');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _WebFinanceView extends StatefulWidget {
  final List<dynamic> expenses;
  final double total;
  final double myShare;
  final double paid;
  final VoidCallback onRefresh;

  const _WebFinanceView({required this.expenses, required this.total, required this.myShare, required this.paid, required this.onRefresh});

  @override
  State<_WebFinanceView> createState() => _WebFinanceViewState();
}

class _WebFinanceViewState extends State<_WebFinanceView> {
  String _selectedChild = 'Todos os Filhos';
  String _selectedPeriod = 'Últimos 30 Dias';
  List<String> _childNames = ['Todos os Filhos'];

  @override
  void initState() {
    super.initState();
    _fetchChildren();
  }

  Future<void> _fetchChildren() async {
    try {
      final response = await ApiService.get('/users/children');
      final List<dynamic> children = response['children'] ?? [];
      if (mounted) {
        setState(() {
          _childNames = ['Todos os Filhos', ...children.map((c) => c['name'] as String)];
        });
      }
    } catch (e) {
      debugPrint('Erro ao buscar filhos para filtro: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Gestão Financeira', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
              const SizedBox(width: 12),
              Chip(
                label: Text(FamilyService().currentFamily.mode.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                backgroundColor: FamilyService().currentFamily.mode == 'Colaborativo' ? Colors.green : Colors.orange,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              const Spacer(),
              _buildFilterDropdown(
                value: _childNames.contains(_selectedChild) ? _selectedChild : _childNames.first,
                items: _childNames,
                onChanged: (v) => setState(() => _selectedChild = v!),
              ),
              const SizedBox(width: 16),
              _buildFilterDropdown(
                value: _selectedPeriod,
                items: ['Este Mês', 'Últimos 30 Dias', 'Últimos 90 Dias', 'Personalizado'],
                onChanged: (v) => setState(() => _selectedPeriod = v!),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('FILTRAR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _indicator('Total Mês', currency.format(widget.total), Icons.bar_chart, Colors.blue),
              const SizedBox(width: 20),
              _indicator('Pendente', currency.format(widget.myShare - widget.paid), Icons.warning_amber, Colors.orange),
              const SizedBox(width: 20),
              _indicator('Sua Cota', currency.format(widget.myShare), Icons.person, Colors.teal),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ListView(
                  children: [
                    DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                      columns: const [
                        DataColumn(label: Text('Descrição', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Valor Total', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Data', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: widget.expenses.map((e) {
                        final dt = DateTime.parse(e['created_at']);
                        return DataRow(cells: [
                          DataCell(Text(e['description'], style: const TextStyle(fontWeight: FontWeight.w500))),
                          DataCell(Text(currency.format(e['amount']))),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (e['status'] == 'Aprovado' ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(e['status'] ?? 'Pendente', style: TextStyle(color: (e['status'] == 'Aprovado' ? Colors.green : Colors.orange), fontSize: 12, fontWeight: FontWeight.bold)),
                          )),
                          DataCell(Text(DateFormat('dd/MM/yyyy').format(dt))),
                          DataCell(Row(children: [
                            if (e['attachment_url'] != null) IconButton(icon: const Icon(Icons.description_outlined, color: Colors.blue, size: 20), onPressed: () => _viewReceipt(e['id'])),
                            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () {}),
                          ])),
                        ]);
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _indicator(String label, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color)),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
          ],
        ),
      ),
    );
  }

  void _viewReceipt(int? expenseId) async {
    if (expenseId == null) return;
    final uri = Uri.parse('${ApiService.baseUrl}/attachments/expenses/$expenseId');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}


class _AddExpenseModal extends StatefulWidget {
  final bool isDesktop;
  final VoidCallback onSuccess;
  const _AddExpenseModal({required this.isDesktop, required this.onSuccess});

  @override
  State<_AddExpenseModal> createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends State<_AddExpenseModal> {
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  PlatformFile? _pickedFile;
  bool _isSubmitting = false;
  List<dynamic> _children = [];
  int? _selectedChildId;
  String? _selectedCategory;
  List<String> _categories = [];
  bool _isLoadingChildren = true;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchChildren();
    _fetchCategories();
  }

  Future<void> _fetchChildren() async {
    try {
      final response = await ApiService.get('/users/children');
      if (mounted) {
        setState(() {
          _children = response['children'] ?? [];
          if (_children.isNotEmpty) _selectedChildId = _children[0]['id'];
          _isLoadingChildren = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingChildren = false);
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await ApiService.get('/expenses/categories');
      if (mounted) {
        setState(() {
          _categories = List<String>.from(response['categories']);
          if (_categories.isNotEmpty) _selectedCategory = _categories[0];
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categories = ['Educação', 'Saúde', 'Alimentação', 'Vestuário', 'Lazer', 'Transporte', 'Moradia', 'Outros'];
          _selectedCategory = _categories[0];
          _isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) setState(() => _pickedFile = result.files.first);
  }

  Future<void> _scanReceipt() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;
    
    setState(() {
      _pickedFile = result.files.first;
      _isSubmitting = true;
    });

    try {
      final analysis = await ApiService.postMultipart(
        '/expenses/analyze-receipt',
        {},
        _pickedFile!.bytes!.toList(),
        _pickedFile!.name,
      );

      if (analysis != null) {
        setState(() {
          _descController.text = analysis['description'] ?? '';
          _amountController.text = (analysis['amount']?.toString() ?? '').replaceAll('.', ',');
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados extraídos com sucesso! Por favor, confira antes de salvar.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('IA não conseguiu ler este recibo: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submit() async {
    if (_descController.text.isEmpty || _amountController.text.isEmpty || _pickedFile == null || _selectedChildId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha todos os campos, selecione o filho e anexe o comprovante.')));
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final res = await SyncService.postMultipartOrEnqueue(
        '/expenses',
        {
          'description': _descController.text,
          'amount': _amountController.text.replaceAll(',', '.'),
          'child_id': _selectedChildId.toString(),
          'family_unit_id': FamilyService().currentFamily.id.toString(),
        },
        _pickedFile!.bytes!.toList(),
        _pickedFile!.name,
      );
      Navigator.pop(context);
      if (res?['status'] == 'queued') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offline: Despesa salva na fila para sincronização posterior.')));
      } else {
        widget.onSuccess();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova Despesa'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoadingChildren)
              const LinearProgressIndicator()
            else if (_children.isEmpty)
              const Text('Nenhum filho cadastrado na família.', style: TextStyle(color: Colors.red, fontSize: 12))
            else
              DropdownButtonFormField<int>(
                value: _selectedChildId,
                decoration: const InputDecoration(labelText: 'Vincular ao Filho'),
                items: _children.map<DropdownMenuItem<int>>((c) => DropdownMenuItem<int>(
                  value: c['id'],
                  child: Text(c['name']),
                )).toList(),
                onChanged: (v) => setState(() => _selectedChildId = v),
              ),
            const SizedBox(height: 16),
            _isLoadingCategories 
              ? const LinearProgressIndicator()
              : DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _scanReceipt,
                icon: const Icon(Icons.document_scanner_outlined),
                label: const Text('ESCANEAR RECIBO COM IA'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Descrição')),
            const SizedBox(height: 16),
            TextField(controller: _amountController, decoration: const InputDecoration(labelText: 'Valor (R\$)', prefixText: 'R\$ '), keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            InkWell(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload, color: _pickedFile != null ? Colors.green : Colors.grey),
                    const SizedBox(height: 8),
                    Text(_pickedFile?.name ?? 'Anexar Comprovante (Obrigatório)', style: TextStyle(fontSize: 12, color: _pickedFile != null ? Colors.green : Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
          child: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('SALVAR'),
        ),
      ],
    );
  }
}
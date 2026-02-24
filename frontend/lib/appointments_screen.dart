import 'package:flutter/material.dart';
import 'api_service.dart';
import 'family_service.dart';
import 'package:intl/intl.dart';
import 'utils.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<dynamic> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      final familyId = FamilyService().currentFamily.id;
      final response = await ApiService.get('/appointments?family_unit_id=$familyId');
      setState(() {
        _appointments = response['appointments'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      _loadMockData();
    }
  }

  void _loadMockData() {
    setState(() {
      _appointments = List.generate(6, (index) => {
        'id': index,
        'type': ['Saúde', 'Viagem', 'Educação', 'Lazer', 'Saúde', 'Esporte'][index % 6],
        'description': ['Consulta Dentista', 'Viagem de Férias', 'Reunião Escolar', 'Aniversário Primo', 'Aula de Inglês', 'Treino Judô'][index % 6],
        'scheduled_time': DateTime.now().add(Duration(days: index)).toIso8601String(),
        'status': index % 3 == 0 ? 'Confirmado' : (index % 3 == 1 ? 'Em Andamento' : 'Agendado'),
      });
      _isLoading = false;
    });
  }

  void _showAddAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddAppointmentDialog(onSuccess: _fetchAppointments),
    );
  }

  void _showDetails(dynamic appointment) {
     showModalBottomSheet(
       context: context,
       isScrollControlled: true,
       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
       builder: (context) => _AppointmentDetailsSheet(appointment: appointment, onRefresh: _fetchAppointments),
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
                  : _appointments.isEmpty
                      ? _buildEmptyState()
                      : isDesktop ? _buildWebGrid() : _buildMobileList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAppointmentDialog,
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('NOVO COMPROMISSO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Nenhum compromisso agendado.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _showAddAppointmentDialog,
            child: const Text('ADICIONAR PRIMEIRO'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compromissos e Agendamentos',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
        const Text('Gestão de passeios, consultas e viagens com checklist compartilhado'),
      ],
    );
  }

  Widget _buildWebGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.0,
      ),
      itemCount: _appointments.length,
      itemBuilder: (context, index) => _buildAppointmentCard(_appointments[index]),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      itemCount: _appointments.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildAppointmentCard(_appointments[index]),
      ),
    );
  }

  Widget _buildAppointmentCard(dynamic appointment) {
    final status = appointment['status'] ?? 'Agendado';
    final color = status == 'Confirmado' ? Colors.green : (status == 'Em Andamento' ? Colors.orange : Colors.blue);
    final date = DateTime.parse(appointment['scheduled_time']);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDetails(appointment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.5))),
                    child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                ],
              ),
              const SizedBox(height: 12),
              Text(appointment['description'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(
                '${DateFormat('dd/MM/yyyy HH:mm').format(date)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const Spacer(),
              if (appointment['location_name'] != null)
                 Padding(
                   padding: const EdgeInsets.only(bottom: 8),
                   child: Row(
                     children: [
                       const Icon(Icons.location_on, size: 14, color: Colors.blueGrey),
                       const SizedBox(width: 4),
                       Expanded(child: Text(appointment['location_name'], style: const TextStyle(fontSize: 12, color: Colors.blueGrey), overflow: TextOverflow.ellipsis)),
                     ],
                   ),
                 ),
              Row(
                children: [
                  const Icon(Icons.checklist, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  const Text('Ver Checklist', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentDetailsSheet extends StatefulWidget {
  final dynamic appointment;
  final VoidCallback onRefresh;
  const _AppointmentDetailsSheet({required this.appointment, required this.onRefresh});

  @override
  State<_AppointmentDetailsSheet> createState() => _AppointmentDetailsSheetState();
}

class _AppointmentDetailsSheetState extends State<_AppointmentDetailsSheet> {
  List<dynamic> _checklist = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChecklist();
  }

  Future<void> _fetchChecklist() async {
    try {
      final res = await ApiService.get('/appointments/${widget.appointment['id']}/checklist');
      setState(() {
        _checklist = res['checklist'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addChecklistItem(String desc) async {
    try {
      await ApiService.post('/appointments/${widget.appointment['id']}/checklist', {'item_description': desc});
      _fetchChecklist();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(widget.appointment['scheduled_time']);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.appointment['description'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Agendado para: ${DateFormat('dd MMMM yyyy, HH:mm', 'pt_BR').format(date)}',
            style: const TextStyle(color: Colors.grey),
          ),
          const Divider(height: 32),
          const Text('CHECKLIST DE PREPARAÇÃO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_checklist.isEmpty)
             const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('Nenhum item no checklist.'))
          else
            ..._checklist.map((item) => CheckboxListTile(
              title: Text(item['item_description']),
              value: item['is_checked'] ?? false,
              onChanged: (val) async {
                // Implement toggle status
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            )).toList(),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Adicionar item ao checklist...',
              suffixIcon: IconButton(icon: const Icon(Icons.add), onPressed: () {}),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (val) {
              if (val.isNotEmpty) _addChecklistItem(val);
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('FECHAR'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text('CONFIRMAR'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _AddAppointmentDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const _AddAppointmentDialog({required this.onSuccess});

  @override
  State<_AddAppointmentDialog> createState() => _AddAppointmentDialogState();
}

class _AddAppointmentDialogState extends State<_AddAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  List<dynamic> _locations = [];
  int? _selectedLocationId;
  String _selectedType = 'Saúde';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSubmitting = false;
  bool _isLoadingLocations = true;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    try {
      final response = await ApiService.get('/locations');
      setState(() {
        _locations = response['locations'] ?? [];
        _isLoadingLocations = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocations = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final scheduledTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ).toIso8601String();

      await ApiService.post('/appointments', {
        'type': _selectedType,
        'description': _descController.text,
        'scheduled_time': scheduledTime,
        'family_unit_id': FamilyService().currentFamily.id,
        'location_id': _selectedLocationId,
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
      title: const Text('Novo Compromisso'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: ['Saúde', 'Educação', 'Viagem', 'Esporte', 'Lazer']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedLocationId,
                decoration: const InputDecoration(
                  labelText: 'Local / Endereço (Opcional)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                items: [
                   const DropdownMenuItem<int>(value: null, child: Text('Nenhum')),
                   ..._locations.map<DropdownMenuItem<int>>((l) => DropdownMenuItem<int>(
                    value: l['id'],
                    child: Text('${l['name']} (${l['type']})'),
                  )).toList(),
                ],
                onChanged: (v) => setState(() => _selectedLocationId = v),
              ),
              const SizedBox(height: 16),
              AppUI.buildPremiumTextField(
                controller: _descController,
                label: 'Descrição/Título',
                hint: 'Ex: Consulta Pediatra, Jogo de Futebol',
                icon: Icons.edit,
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Horário (Estimado)'),
                subtitle: Text(_selectedTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: _selectedTime);
                  if (picked != null) setState(() => _selectedTime = picked);
                },
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
          child: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('SALVAR'),
        ),
      ],
    );
  }
}
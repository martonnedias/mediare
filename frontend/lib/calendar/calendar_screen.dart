import 'package:flutter/material.dart';
import '../api_service.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _events = [];
  String? _rawResponse;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final start = DateFormat('yyyy-MM-dd').format(now);
      final end = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 7)));

      // Ajuste childId/token conforme sua sessão; usando childId=1 como demo
      // Durante desenvolvimento, usamos o endpoint mock para garantir visualização
      final events = await ApiService.getAppointments(childId: 1, startDate: start, endDate: end, useMock: true);

      setState(() {
        _events = events;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário de Convivência'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Depurar resposta bruta',
            onPressed: () async {
              await _loadRawResponse();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Erro: $_error'))
              : _events.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Nenhum compromisso encontrado'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () async => await _loadRawResponse(),
                            child: const Text('Ver resposta bruta (debug)'),
                          ),
                          if (_rawResponse != null) ...[
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: SelectableText(_rawResponse!),
                            ),
                          ]
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _events.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final e = _events[index];
                        final id = e['id'] ?? e['ID'] ?? '---';
                        final date = e['event_date'] ?? e['scheduled_time'] ?? e['created_at'] ?? '';
                        final status = e['status'] ?? '';
                        final description = e['description'] ?? e['type'] ?? '';

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.event),
                            title: Text(description.toString().isEmpty ? 'Compromisso #$id' : description.toString()),
                            subtitle: Text('Data: $date\nStatus: $status'),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
    );
  }

    Future<void> _loadRawResponse() async {
      setState(() {
        _rawResponse = null;
        _error = null;
      });

      try {
        final now = DateTime.now();
        final start = DateFormat('yyyy-MM-dd').format(now);
        final end = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 7)));

        final raw = await ApiService.getRawAppointments(childId: 1, startDate: start, endDate: end, useMock: true);
        setState(() {
          _rawResponse = raw;
        });
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Resposta bruta'),
            content: SingleChildScrollView(child: SelectableText(_rawResponse ?? '')),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar')),
            ],
          ),
        );
      } catch (e) {
        setState(() {
          _error = e.toString();
        });
      }
    }
}
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'family_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isGenerating = false;
  bool _isLoadingHistory = true;
  List<dynamic> _reportsHistory = [];

  // Filtros
  bool _includeEvents = true;
  bool _includeExpenses = true;
  bool _includeChat = false;

  @override
  void initState() {
    super.initState();
    _fetchReports();
    FamilyService().addListener(_onFamilyChanged);
  }

  @override
  void dispose() {
    FamilyService().removeListener(_onFamilyChanged);
    super.dispose();
  }

  void _onFamilyChanged() {
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoadingHistory = true);
    try {
      final response = await ApiService.get('/reports');
      setState(() {
        _reportsHistory = response['reports'] ?? [];
        _isLoadingHistory = false;
      });
    } catch (e) {
      _loadMockHistory();
    }
  }

  void _loadMockHistory() {
    setState(() {
      _reportsHistory = [
        {
          'id': 1, 
          'name': 'Relatório Mensal Auditado', 
          'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(), 
          'hash_sha256': 'sha256:882ae3e2b9c7d...', 
          'pdf_url': 'reports/mock_report.pdf'
        },
      ];
      _isLoadingHistory = false;
    });
  }

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);
    final familyId = FamilyService().currentFamily.id;
    try {
      await ApiService.post('/reports', {
        'name': 'Relatório ${DateFormat('MMM/yyyy').format(DateTime.now())}',
        'filters': {
          'family_unit_id': familyId,
          'include_events': _includeEvents,
          'include_expenses': _includeExpenses,
          'include_chat': _includeChat,
        },
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Relatório gerado com sucesso!'), backgroundColor: Colors.green),
      );
      _fetchReports();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _downloadReport(int? reportId) async {
    if (reportId == null) return;
    final url = Uri.parse('${ApiService.baseUrl}/attachments/reports/$reportId');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o link.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: _buildGeneratorCard()),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: _buildHistoryPanel()),
              ],
            )
          else
            Column(
              children: [
                _buildGeneratorCard(),
                const SizedBox(height: 24),
                _buildHistoryPanel(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Relatórios de Auditoria',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
        ),
        const Text('Gere documentos certificados com validade jurídica para o processo.'),
      ],
    );
  }

  Widget _buildGeneratorCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Configurar Relatório', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Eventos e Convivência'),
              value: _includeEvents,
              onChanged: (v) => setState(() => _includeEvents = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Despesas e Rateios'),
              value: _includeExpenses,
              onChanged: (v) => setState(() => _includeExpenses = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Logs de Chat (IA Moderado)'),
              value: _includeChat,
              onChanged: (v) => setState(() => _includeChat = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateReport,
                icon: _isGenerating 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf),
                label: Text(_isGenerating ? 'GERANDO...' : 'GERAR PDF AGORA'),
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Histórico de Emissões', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(onPressed: _fetchReports, icon: const Icon(Icons.refresh, size: 16), label: const Text('Atualizar')),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 400,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: _isLoadingHistory
            ? const Center(child: CircularProgressIndicator())
            : _reportsHistory.isEmpty
              ? const Center(child: Text('Nenhum relatório gerado ainda.'))
              : ListView.separated(
                  itemCount: _reportsHistory.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final report = _reportsHistory[index];
                    return ListTile(
                      leading: const Icon(Icons.verified, color: Colors.green),
                      title: Text(report['name'] ?? 'Relatório', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Emitido em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(report['created_at']))}', style: const TextStyle(fontSize: 11)),
                          Text('HASH: ${(report['hash_sha256'] ?? 'N/A').toString().substring(0, 15)}...', style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace')),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.download_rounded, color: Theme.of(context).primaryColor),
                        onPressed: () => _downloadReport(report['id']),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
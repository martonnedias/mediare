import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class DiscoveryScreen extends StatefulWidget {
  final int childId;
  final String city;

  const DiscoveryScreen({
    Key? key,
    required this.childId,
    this.city = "São Paulo", // Default city
  }) : super(key: key);

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  bool _isLoading = true;
  String? _summary;
  List<dynamic> _categories = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDiscovery();
  }

  Future<void> _fetchDiscovery() async {
    try {
      int effectiveChildId = widget.childId;
      
      // Se não tiver ID, busca o primeiro filho da família ativa
      if (effectiveChildId == 0) {
        final families = await ApiService.get('/onboarding/families');
        if (families != null && families['families'] != null && families['families'].isNotEmpty) {
           final familyId = families['families'][0]['id'];
           // Aqui precisaríamos de um endpoint para listar filhos de uma família
           // Por enquanto, vamos tentar buscar do endpoint de onboarding ou similar
           final response = await ApiService.get('/onboarding/families'); // Simulação
           // Na estrutura real, precisaríamos de /families/{id}/children
        }
      }

      final response = await ApiService.get(
        '/child-discovery?child_id=$effectiveChildId&city=${widget.city}',
      );

      if (response != null && response is Map<String, dynamic>) {
        setState(() {
          _summary = response['summary'];
          _categories = response['categories'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Não foi possível carregar as descobertas no momento.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Erro de conexão. Tente novamente mais tarde.";
        _isLoading = false;
      });
    }
  }

  Future<void> _openLink(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background will be handled by the shell gradient
      appBar: AppBar(
        title: const Text('Descobertas IA', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : _error != null
              ? _buildErrorPlaceholder()
              : _buildContent(),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology_outlined, size: 80, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _fetchDiscovery();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
              child: const Text('TENTAR NOVAMENTE'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_summary != null) ...[
            _buildGlassCard(
              child: Column(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amber, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    _summary!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          ..._categories.map((cat) => _buildCategorySection(cat)).toList(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCategorySection(Map<String, dynamic> category) {
    final items = category['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            category['category'] ?? 'Novidades',
            style: const TextStyle(
              color: Color(0xFF60A5FA),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...items.map((item) => _buildItemCard(item)).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openLink(item['link']),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] ?? 'Sem título',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (item['date'] != null)
                          Text(
                            item['date'],
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          item['description'] ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: child,
    );
  }
}

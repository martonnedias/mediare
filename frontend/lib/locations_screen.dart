import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'family_service.dart';
import 'utils.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({Key? key}) : super(key: key);

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  List<dynamic> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    setState(() => _isLoading = true);
    try {
      final familyId = FamilyService().currentFamily.id;
      final response = await ApiService.get('/locations?family_unit_id=$familyId');
      setState(() {
        _locations = response['locations'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar endereços: $e')),
        );
      }
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
          _buildHeader(context, isDesktop),
          const SizedBox(height: 32),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _locations.isEmpty
                    ? _buildEmptyState()
                    : isDesktop ? _buildWebGrid() : _buildMobileList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Nenhum endereço cadastrado',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          const Text('Adicione locais seguros para começar.'),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestão de Endereços',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const Text('Locais seguros para troca e visitas'),
          ],
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => _showAddLocationModal(context, isDesktop),
          icon: const Icon(Icons.add_location_alt),
          label: const Text('Novo Endereço'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildWebGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.2,
      ),
      itemCount: _locations.length,
      itemBuilder: (context, index) => _buildLocationCard(_locations[index]),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      itemCount: _locations.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildLocationCard(_locations[index]),
      ),
    );
  }

  Widget _buildLocationCard(dynamic location) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showLocationDetails(context, location);
        }, // Mostrar detalhes
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: Icon(
                  _getIconForType(location['type']),
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      location['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location['address'] != null && location['address'].toString().isNotEmpty
                          ? '${location['type']} • ${location['address']}'
                          : location['type'] ?? '',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.map_outlined, color: Theme.of(context).primaryColor),
                onPressed: () async {
                  final lat = location['latitude'];
                  final lng = location['longitude'];
                  final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Não foi possível abrir o mapa.')),
                      );
                    }
                  }
                }, // Abrir mapa
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'casa pai':
      case 'casa mãe':
      case 'residência':
        return Icons.home;
      case 'escola':
      case 'educação':
        return Icons.school;
      case 'hospital':
      case 'psicólogo':
      case 'saúde':
        return Icons.local_hospital;
      case 'parque':
      case 'lazer':
        return Icons.park;
      default:
        return Icons.location_on;
    }
  }

  void _showLocationDetails(BuildContext context, dynamic location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getIconForType(location['type'] ?? ''), color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Expanded(child: Text(location['name'] ?? 'Detalhes do Endereço')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${location['type'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (location['address'] != null && location['address'].toString().isNotEmpty)
              Text('Endereço: ${location['address']}'),
            const SizedBox(height: 8),
            Text('Coordenadas: ${location['latitude']}, ${location['longitude']}', 
                 style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showAddLocationModal(BuildContext context, bool isDesktop) {
    showDialog(
      context: context,
      builder: (context) => _AddLocationDialog(
        onSuccess: () {
          Navigator.pop(context);
          _fetchLocations();
        },
      ),
    );
  }
}

class _AddLocationDialog extends StatefulWidget {
  final VoidCallback onSuccess;

  const _AddLocationDialog({Key? key, required this.onSuccess}) : super(key: key);

  @override
  State<_AddLocationDialog> createState() => _AddLocationDialogState();
}

class _AddLocationDialogState extends State<_AddLocationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedType;
  bool _isSubmitting = false;
  bool _isLoadingTypes = true;

  List<String> _types = [];

  @override
  void initState() {
    super.initState();
    _fetchTypes();
  }

  Future<void> _fetchTypes() async {
    try {
      final response = await ApiService.get('/locations/types');
      if (mounted) {
        setState(() {
          _types = List<String>.from(response['types']);
          if (_types.isNotEmpty) {
            _selectedType = _types.first;
          }
          _isLoadingTypes = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _types = ['Residência', 'Casa Pai', 'Casa Mãe', 'Escola', 'Hospital', 'Psicólogo', 'Clínica', 'Parque', 'Clube', 'Outro'];
          _selectedType = _types.first;
          _isLoadingTypes = false;
        });
      }
    }
  }

  Future<void> _fetchPlaceDetails(String placeId) async {
    try {
      final response = await ApiService.get('/locations/place-details?place_id=$placeId');
      setState(() {
        _nameController.text = response['name'] ?? _nameController.text;
        _addressController.text = response['address'] ?? _addressController.text;
        String suggested = response['suggested_type'] ?? 'Outro';
        if (_types.contains(suggested)) {
          _selectedType = suggested;
        }
      });
    } catch (e) {
      debugPrint('Erro ao buscar detalhes do lugar: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final familyId = FamilyService().currentFamily.id;
      await ApiService.post('/locations', {
        'name': _nameController.text,
        'type': _selectedType,
        'address': _addressController.text,
        'family_unit_id': familyId,
      });
      widget.onSuccess();
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cadastrar endereço: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Endereço Safe'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Busca do Estabelecimento (Prioridade)
              Autocomplete<Map<String, dynamic>>(
                displayStringForOption: (option) => option['description'],
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text.length < 3) return const Iterable<Map<String, dynamic>>.empty();
                  try {
                    final response = await ApiService.get('/locations/autocomplete?query=${Uri.encodeComponent(textEditingValue.text)}');
                    if (response['predictions'] != null) {
                      return (response['predictions'] as List).cast<Map<String, dynamic>>();
                    }
                  } catch (e) {
                    debugPrint('Erro autocomplete: $e');
                  }
                  return const Iterable<Map<String, dynamic>>.empty();
                },
                onSelected: (Map<String, dynamic> selection) async {
                  final placeId = selection['place_id'];
                  if (placeId != null) {
                    _fetchPlaceDetails(placeId);
                  }
                },
                fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Buscar Estabelecimento ou Nome', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        onFieldSubmitted: (_) => onSubmitted(),
                        decoration: InputDecoration(
                          hintText: 'Digite o nome do local...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (val) {
                          // Se o usuário apagar o que buscou e escrever manual, atualizamos o nome
                          _nameController.text = val;
                        },
                      ),
                    ],
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 300,
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final Map<String, dynamic> option = options.elementAt(index);
                            return ListTile(
                              leading: const Icon(Icons.location_on, size: 18),
                              title: Text(option['description'] ?? '', style: const TextStyle(fontSize: 13)),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // 2. Nome do Local (Editável)
              AppUI.buildPremiumTextField(
                controller: _nameController,
                label: 'Nome para Exibição',
                hint: 'Ex: Escola do João, Clínica Dr. Silva',
                icon: Icons.edit_note,
                validator: (v) => v?.isEmpty ?? true ? 'Defina um nome' : null,
              ),
              const SizedBox(height: 20),

              // 3. Tipo de Local
              _isLoadingTypes 
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'Categoria / Tipo',
                      filled: true,
                      fillColor: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _selectedType = v),
                  ),
              const SizedBox(height: 20),

              // 4. Endereço Completo (Editável)
              AppUI.buildPremiumTextField(
                controller: _addressController,
                label: 'Endereço Completo',
                hint: 'Rua, Número, Bairro...',
                icon: Icons.map,
                validator: (v) => v?.isEmpty ?? true ? 'Endereço necessário' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
          child: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Salvar'),
        ),
      ],
    );
  }
}
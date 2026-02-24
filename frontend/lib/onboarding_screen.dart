import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'api_service.dart';
import 'family_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:intl/intl.dart';
import 'mediare_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;

  // Step 1: Profile
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _cpfFormatter = MaskTextInputFormatter(mask: '###.###.###-##', filter: { "#": RegExp(r'[0-9]') }, type: MaskAutoCompletionType.lazy);
  String _parentRole = 'Pai';

  // Step 2: Family
  final _familyNameController = TextEditingController();
  String _familyMode = 'Colaborativo';
  String _valuesProfile = 'Neutro/Educativo';

  // Step 3: Children
  final List<Map<String, String>> _children = [];
  final _childNameController = TextEditingController();
  final _childCpfController = TextEditingController();
  final _childCpfFormatter = MaskTextInputFormatter(mask: '###.###.###-##', filter: { "#": RegExp(r'[0-9]') }, type: MaskAutoCompletionType.lazy);
  final _childBirthController = TextEditingController();
  final _childBirthFormatter = MaskTextInputFormatter(
    mask: '##/##/####', 
    filter: { "#": RegExp(r'[0-9]') }, 
    type: MaskAutoCompletionType.lazy
  );

  bool _isSubmitting = false;

  String? _validateCPF(String? value) {
    if (value == null || value.isEmpty) return 'CPF é obrigatório';
    final cpf = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpf.length != 11) return 'CPF deve ter 11 dígitos';
    return null;
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (_nameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nome é obrigatório')));
        return;
      }
      final cpfError = _validateCPF(_cpfController.text);
      if (cpfError != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cpfError)));
        return;
      }
    }
    
    if (_currentPage == 1) {
      if (_familyNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nome da família é obrigatório')));
        return;
      }
    }
    
    if (_currentPage < 2) {
      setState(() => _currentPage++);
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      firstDate: DateTime(1960),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light(), // Usando tema claro agora
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _childBirthController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  String _formatDateForBackend(String date) {
    try {
      final parts = date.split('/');
      if (parts.length == 3) {
        return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      }
    } catch (_) {}
    return date;
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isSubmitting = true);
    try {
      await ApiService.post('/onboarding/complete-profile', {
        'full_name': _nameController.text,
        'cpf': _cpfController.text,
        'profile_picture': 'https://ui-avatars.com/api/?name=${_nameController.text}',
      });

      await ApiService.post('/onboarding/create-family', {
        'name': _familyNameController.text,
        'mode': _familyMode,
        'values_profile': _valuesProfile,
        'children': _children,
      });

      await FamilyService().fetchFamilies();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [_buildUserHeader()],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'app_logo',
                child: Image.asset(
                  'assets/images/mediare_logo.png',
                  height: 60,
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0F2FE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security_rounded, size: 40, color: Color(0xFF144BB8)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Configuração de Conta',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Siga os passos para ativar seu ambiente familiar seguro.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 650 : 500),
                child: MediareCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStepper(),
                      const SizedBox(height: 40),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        alignment: Alignment.topCenter,
                        curve: Curves.easeInOut,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _currentPage == 0
                              ? KeyedSubtree(key: const ValueKey(0), child: _buildProfileStep())
                              : _currentPage == 1
                                  ? KeyedSubtree(key: const ValueKey(1), child: _buildFamilyStep())
                                  : KeyedSubtree(key: const ValueKey(2), child: _buildChildrenStep()),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentPage > 0)
                            TextButton(
                              onPressed: () => setState(() => _currentPage--),
                              child: const Text('VOLTAR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                            )
                          else
                            const SizedBox(),
                          _isSubmitting
                              ? const CircularProgressIndicator()
                              : SoftButton( // Usando o elemento soft button novo
                                  text: (_currentPage == 2 ? 'FINALIZAR SETUP' : 'PRÓXIMO PASSO').toUpperCase(),
                                  onPressed: _nextPage,
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index <= _currentPage;
        return Expanded(
          child: Column(
            children: [
              Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF144BB8) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                ['Perfil', 'Família', 'Filhos'][index].toUpperCase(),
                style: TextStyle(
                  color: isActive ? const Color(0xFF144BB8) : Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seu Perfil Principal', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
        const SizedBox(height: 6),
        const Text('Dados para validação de guarda', style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 32),
        SoftInput(
          controller: _nameController,
          label: 'NOME COMPLETO',
          hint: 'Como consta no RG/CNH',
        ),
        const SizedBox(height: 20),
        SoftInput(
          controller: _cpfController,
          label: 'CPF',
          hint: '000.000.000-00',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _parentRole,
          decoration: InputDecoration(
            labelText: 'PAPEL FAMILIAR',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
            filled: true,
            fillColor: Colors.white,
          ),
          items: ['Pai', 'Mãe', 'Guardião Legal', 'Avô/Avó', 'Tio/Tia', 'Outro'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (v) => setState(() => _parentRole = v!),
        ),
      ],
    );
  }

  Widget _buildFamilyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Unidade Familiar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
        const SizedBox(height: 6),
        const Text('Configure o núcleo e o ambiente de convivência', style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 32),
        SoftInput(
          controller: _familyNameController,
          label: 'NOME DA UNIDADE',
          hint: 'Ex: Família Silva Souza',
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _familyMode,
          decoration: InputDecoration(
            labelText: 'MODO DE CONVIVÊNCIA',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
            filled: true,
            fillColor: Colors.white,
          ),
          items: ['Colaborativo', 'Unilateral', 'Gamification_only'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (v) => setState(() => _familyMode = v!),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _valuesProfile,
          decoration: InputDecoration(
            labelText: 'PERFIL DE VALORES DA GUARDA',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
            filled: true,
            fillColor: Colors.white,
          ),
          items: ['Neutro/Educativo', 'Conservadora', 'Religiosa', 'Tradicional', 'Liberal'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (v) => setState(() => _valuesProfile = v!),
        ),
      ],
    );
  }

  Widget _buildChildrenStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gestão de Filhos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
        const SizedBox(height: 6),
        const Text('Cadastre as crianças envolvidas no calendário', style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              SoftInput(
                controller: _childNameController,
                label: 'NOME DA CRIANÇA',
                hint: 'Nome completo',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SoftInput(
                      controller: _childCpfController,
                      label: 'CPF (OPCIONAL)',
                      hint: '000.000.000-00',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: IgnorePointer(
                        child: SoftInput(
                          controller: _childBirthController,
                          label: 'NASCIMENTO',
                          hint: 'DD/MM/AAAA',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (_childNameController.text.isNotEmpty && _childBirthController.text.isNotEmpty) {
                      setState(() {
                        _children.add({
                          'name': _childNameController.text,
                          'cpf': _childCpfController.text,
                          'birth_date': _formatDateForBackend(_childBirthController.text),
                        });
                        _childNameController.clear();
                        _childCpfController.clear();
                        _childBirthController.clear();
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nome e data de nascimento são obrigatórios.')));
                    }
                  },
                  icon: const Icon(Icons.add_rounded, color: Color(0xFF144BB8)),
                  label: const Text('ADICIONAR FILHO À LISTA', style: TextStyle(color: Color(0xFF144BB8), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF144BB8)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _children.length,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                  child: const Icon(Icons.child_care_rounded, color: Color(0xFF489CE5), size: 20),
                ),
                title: Text(_children[index]['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Nascimento: ${_children[index]['birth_date']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: () => setState(() => _children.removeAt(index)),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUserHeader() {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Center(
        child: InkWell(
          onTap: () async {
            await AuthService().signOut();
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFF144BB8),
                  child: Text(
                    (user.email ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.logout, color: Colors.grey, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

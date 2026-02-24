import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'login_screen.dart';
import 'family_service.dart';
import 'mediare_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  List<dynamic> _families = [];
  bool _resguardoActive = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final futures = await Future.wait([
        FamilyService().fetchFamilies(),
        ApiService.get('/users/me'),
      ]);
      
      if (mounted) {
        setState(() {
          _families = FamilyService().availableFamilies.map((f) => {
            'id': f.id,
            'name': f.name,
            'mode': f.mode
          }).toList();
          
          final profileData = futures[1];
          if (profileData != null && profileData is Map) {
             _resguardoActive = profileData['resguardo_active'] == true;
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleResguardo(bool newValue) async {
    setState(() => _resguardoActive = newValue);
    try {
      await ApiService.put('/users/profile', {'resguardo_active': newValue});
      if (mounted) {
        if (newValue) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Filtro de Resguardo Ativado. Notificações mutadas.')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Filtro de Resguardo Desativado.')));
        }
      }
    } catch (e) {
      setState(() => _resguardoActive = !newValue); // Revert on failure
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  void _showAddMemberDialog(int familyId) {
    showDialog(
      context: context,
      builder: (context) => _AddMemberDialog(familyId: familyId),
    );
  }

  void _showEditProfileDialog() {
     showDialog(
      context: context,
      builder: (context) => const _EditProfileDialog(),
    );
  }

  void _exportDossier() async {
     // Show loading dialog
     showDialog(
       context: context,
       barrierDismissible: false,
       builder: (context) => AlertDialog(
         backgroundColor: Colors.white,
         content: Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             const CircularProgressIndicator(color: Color(0xFF144BB8)),
             const SizedBox(width: 20),
             Expanded(child: Text('Análise de Convivência e Geração do Dossier via IA em andamento...', style: TextStyle(color: Theme.of(context).primaryColor))),
           ],
         ),
       ),
     );

     try {
       final response = await ApiService.post('/reports', {
         'name': 'Dossier de Compliance Familiar - Automático',
         'filters': {'include_events': true, 'include_expenses': true}
       });
       
       if (context.mounted) Navigator.pop(context); // Close loading dialog
       
       if (response != null && response['url'] != null) {
          final urlString = '${ApiService.baseUrl}${response['url']}';
          final uri = Uri.parse(urlString);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o PDF.')));
          }
       }
     } catch (e) {
       if (context.mounted) {
         Navigator.pop(context); // Close loading dialog
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao gerar relatório: $e')));
       }
     }
  }

  void _confirmDeleteAccount() {
    MediareDialog.showWide(
      context: context,
      title: 'Excluir Conta?',
      content: const Text(
          'Tem certeza que deseja solicitar a exclusão da sua conta?\n'
          'Essa ação apagará seus acessos e desvinculará seu perfil das famílias e relatórios. '
          'Por questões de LGPD e auditoria judicial, dados passados emitidos em laudos serão ofuscados e arquivados com formatação irreversível.',
          style: TextStyle(height: 1.5),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
        SoftButton(
          text: 'Excluir Definitivamente',
          isDestructive: true,
          onPressed: () async {
            Navigator.pop(context);
            try {
              setState(() => _isLoading = true);
              await ApiService.delete('/users/me');
              await AuthService().signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            } catch (e) {
              if (mounted) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
              }
            }
          },
        ),
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Configurações',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                _buildSectionHeader('Minha Família'),
                if (_isLoading)
                  const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
                else
                  ..._families.map((f) => _buildSettingTile(
                    Icons.family_restroom_rounded, 
                    f['name'], 
                    'Modo: ${f['mode']}',
                    trailing: IconButton(
                      icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF144BB8)),
                      onPressed: () => _showAddMemberDialog(f['id']),
                      tooltip: 'Adicionar Membro (Pai/Mãe)',
                    ),
                    onTap: () {},
                  )).toList(),
                _buildSettingTile(Icons.add_circle_outline_rounded, 'Criar Nova Unidade Familiar', 'Adicionar novo núcleo de gestão', onTap: () {}),
                
                const SizedBox(height: 32),
                _buildSectionHeader('Conta & Segurança'),
                _buildSettingTile(Icons.person_outline_rounded, 'Meu Perfil', 'Dados cadastrais e fotos', onTap: _showEditProfileDialog),
                _buildSettingTile(Icons.lock_outline_rounded, 'Segurança', 'Alterar senha e autenticação 2FA', onTap: () {}),
                
                const SizedBox(height: 32),
                _buildSectionHeader('Preferências do App'),
                _buildSettingTile(Icons.notifications_none_rounded, 'Notificações', 'Configurar alertas de chat e despesas', onTap: () {}),
                
                // Resguardo Switch directly injected inside a tile matching the soft aesthetic
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100, width: 1.5),
                  ),
                  child: SwitchListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    value: _resguardoActive,
                    onChanged: _toggleResguardo,
                    title: Text('Filtro de Resguardo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor)),
                    subtitle: const Text('Silenciar notificações nos dias sem a criança', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    activeColor: const Color(0xFF144BB8),
                    secondary: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.do_not_disturb_on_outlined, color: Color(0xFF144BB8), size: 22),
                    ),
                  ),
                ),

                _buildSettingTile(Icons.palette_outlined, 'Aparência', 'Tema claro/escuro e cores', onTap: () {}),
                
                const SizedBox(height: 32),
                _buildSectionHeader('Controles Admin & Judiciais'),
                _buildSettingTile(Icons.download_rounded, 'Exportar Dossier Judicial', 'Baixar logs em PDF de chats e eventos.', onTap: _exportDossier),
                _buildSettingTile(Icons.history_rounded, 'Auditoria de Acessos', 'Ver dispositivos logados e IPs.', onTap: () {}),
                _buildSettingTile(Icons.admin_panel_settings_outlined, 'Permissões do Perfil Infantil', 'Limitar funções no Child Mode.', onTap: () {}),

                const SizedBox(height: 32),
                _buildSectionHeader('Suporte'),
                _buildSettingTile(Icons.help_outline_rounded, 'Central de Ajuda', 'Tutoriais e suporte jurídico', onTap: () {}),
                _buildSettingTile(Icons.info_outline_rounded, 'Sobre o Mediare', 'Versão 1.0.0-PRO • SHA-256 Verified', onTap: () {}),
                
                const SizedBox(height: 24),
                Divider(color: Colors.grey.shade100, height: 32),
                
                Center(
                  child: SoftButton(
                    onPressed: _confirmDeleteAccount,
                    isDestructive: true,
                    icon: Icons.delete_forever_rounded,
                    text: 'EXCLUIR MINHA CONTA'
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, String subtitle, {required VoidCallback onTap, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFF144BB8), size: 22),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 22, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class _AddMemberDialog extends StatefulWidget {
  final int familyId;
  const _AddMemberDialog({required this.familyId});

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_emailController.text.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await ApiService.post('/families/${widget.familyId}/members', {
        'email': _emailController.text,
        'role': 'parent'
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membro adicionado!'), backgroundColor: Color(0xFF10B981)));
    } catch (e) {
      if(mounted) setState(() => _isSubmitting = false);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Conectar outro Membro', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
               icon: const Icon(Icons.close_rounded, color: Colors.grey),
               onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Insira o e-mail do outro genitor ou mediador para conectá-lo a esta unidade familiar. Eles receberão um alerta ao logar.', style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5)),
            const SizedBox(height: 24),
            SoftInput(
              controller: _emailController,
              label: 'E-mail do Usuário',
              hint: 'exemplo@email.com',
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
        _isSubmitting ? const CircularProgressIndicator() : SoftButton(
          text: 'ADICIONAR',
          onPressed: _submit,
        ),
      ],
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog();

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _nameController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_nameController.text.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await ApiService.put('/users/profile', {
        'full_name': _nameController.text,
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil atualizado!')));
    } catch (e) {
      if(mounted) setState(() => _isSubmitting = false);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Editar Perfil', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
               icon: const Icon(Icons.close_rounded, color: Colors.grey),
               onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            SoftInput(
              controller: _nameController,
              label: 'Nome Completo',
              hint: 'Digite seu nome completo',
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
        _isSubmitting ? const CircularProgressIndicator() : SoftButton(
          text: 'SALVAR',
          onPressed: _submit,
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'api_service.dart';
import 'onboarding_screen.dart';
import 'mediare_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isObscured = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos.')),
      );
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa aceitar os Termos de Uso para continuar.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem.')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A senha deve ter pelo menos 6 caracteres.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final error = await _authService.signUp(email: email, password: password);

    if (error == null) {
      if (mounted) {
        // Tenta sincronizar (criar usuário no banco)
        try {
          await ApiService.post('/users/sync', {});
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        } catch (e) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Conta criada, mas erro ao sincronizar: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).primaryColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
             constraints: const BoxConstraints(maxWidth: 450),
             child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Hero(
                     tag: 'app_logo',
                     child: Image.asset(
                       'assets/images/mediare_logo.png',
                       height: 60,
                       errorBuilder: (context, error, stackTrace) => Container(
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: const Color(0xFFE0F2FE),
                           shape: BoxShape.circle,
                         ),
                         child: const Icon(Icons.security_rounded, size: 40, color: Color(0xFF144BB8)),
                       ),
                     ),
                   ),
                   const SizedBox(height: 32),
                   Text(
                     'Nova Conta',
                     style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                     textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 8),
                   Text(
                     'Comece a organizar a vida familiar com segurança e conformidade.',
                     style: Theme.of(context).textTheme.bodyMedium,
                     textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 40),
                   MediareCard(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.stretch,
                       children: [
                         SoftInput(
                           label: 'E-mail Pessoal',
                           hint: 'exemplo@email.com',
                           controller: _emailController,
                           keyboardType: TextInputType.emailAddress,
                         ),
                         const SizedBox(height: 20),
                         SoftInput(
                           label: 'Senha de Acesso',
                           hint: '••••••••',
                           controller: _passwordController,
                           obscureText: _isObscured,
                         ),
                         const SizedBox(height: 20),
                         SoftInput(
                           label: 'Confirme a Senha',
                           hint: '••••••••',
                           controller: _confirmPasswordController,
                           obscureText: _isObscured,
                         ),
                         
                         const SizedBox(height: 12),
                         Align(
                           alignment: Alignment.centerRight,
                           child: TextButton.icon(
                             onPressed: () => setState(() => _isObscured = !_isObscured),
                             icon: Icon(
                               _isObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded, 
                               size: 16, 
                               color: Colors.grey
                             ),
                             label: Text(
                               _isObscured ? 'Mostrar Senhas' : 'Ocultar Senhas', 
                               style: const TextStyle(color: Colors.grey, fontSize: 13)
                             ),
                           ),
                         ),
                         
                         const SizedBox(height: 12),
                         Container(
                           decoration: BoxDecoration(
                             color: const Color(0xFFF8FAFC),
                             borderRadius: BorderRadius.circular(16),
                             border: Border.all(color: Colors.grey.shade200),
                           ),
                           child: Theme(
                             data: ThemeData(
                               unselectedWidgetColor: Colors.grey.shade400,
                             ),
                             child: CheckboxListTile(
                               value: _acceptedTerms,
                               onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
                               title: const Text(
                                 'Eu li e aceito os Termos de Uso e Política de Privacidade de Dados', 
                                 style: TextStyle(fontSize: 12, color: Color(0xFF475569))
                               ),
                               controlAffinity: ListTileControlAffinity.leading,
                               activeColor: const Color(0xFF144BB8),
                               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                             ),
                           ),
                         ),
                         
                         const SizedBox(height: 24),
                         SizedBox(
                           height: 56,
                           child: SoftButton(
                             text: 'FINALIZAR CADASTRO',
                             onPressed: _isLoading ? null : _handleSignup,
                           ),
                         ),
                         if (_isLoading)
                           const Padding(
                             padding: EdgeInsets.only(top: 16.0),
                             child: Center(child: CircularProgressIndicator()),
                           ),
                       ],
                     ),
                   ),
                   const SizedBox(height: 24),
                   const Center(
                     child: Text(
                       'Proteção de Dados Nível Institucional (LGPD)',
                       style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                     ),
                   ),
                ],
             ),
          ),
        ),
      ),
    );
  }
}

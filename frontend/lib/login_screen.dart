import 'package:flutter/material.dart';
import 'dart:ui';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'auth_service.dart';
import 'api_service.dart';
import 'family_service.dart';
import 'utils.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
    
    // Verifica se retornou de um redirecionamento do Google (Web)
    _checkRedirectResult();
  }

  Future<void> _checkRedirectResult() async {
    final user = _authService.currentUser;
    if (user != null) {
      await _syncAndNavigate();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    
    final error = await _authService.signInWithGoogle();
    
    if (error == null) {
      await _syncAndNavigate();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _syncAndNavigate() async {
      try {
        final syncResponse = await ApiService.post('/users/sync', {});
        final isCompleted = syncResponse['onboarding_completed'] == true;
        
        if (mounted) {
          if (isCompleted) {
            await FamilyService().fetchFamilies();
            Navigator.pushReplacement(
              context,
              FadePageRoute(page: const HomeScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              FadePageRoute(page: const OnboardingScreen()),
            );
          }
        }
      } catch (e) {
        debugPrint('Erro no _syncAndNavigate: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao sincronizar dados: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final error = await _authService.signIn(email: email, password: password);

    if (error == null) {
      await _syncAndNavigate();
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
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1050;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: isDesktop 
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBrandingSection(true, theme),
                    const SizedBox(width: 80),
                    _buildLoginCard(context, theme),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBrandingSection(false, theme),
                    const SizedBox(height: 48),
                    _buildLoginCard(context, theme),
                  ],
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingSection(bool isDesktop, ThemeData theme) {
    return Container(
      constraints: BoxConstraints(maxWidth: isDesktop ? 500 : 400),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Hero(
            tag: 'app_logo',
            child: Image.asset(
              'assets/images/mediare_logo.png',
              height: isDesktop ? 220 : 120,
              errorBuilder: (context, error, stackTrace) => ConstrainedBox(
                constraints: BoxConstraints(maxHeight: isDesktop ? 220 : 120),
                child: Icon(Icons.security, size: isDesktop ? 100 : 60, color: theme.primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'MEDIARE • MGCF',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.primaryColor, 
              fontSize: isDesktop ? 34 : 22, 
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'TRANSFORMANDO CONFLITOS EM CONFORMIDADE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600, 
              fontSize: isDesktop ? 12 : 10, 
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context, ThemeData theme) {
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width > 500 ? 450.0 : size.width - 48.0;
    
    return SizedBox(
      width: cardWidth,
      child: Card(
        // Utilizando o CardTheme definido no main.dart (Squircles brancos com sombra leve)
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Acesso Seguro',
                style: TextStyle(color: theme.primaryColor, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Gerencie o bem-estar da sua família com inteligência e segurança.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 40),
              _buildInputField(
                label: 'ID DE USUÁRIO (E-MAIL)',
                icon: Icons.alternate_email_rounded,
                hint: 'seu@email.com',
                controller: _emailController,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 24),
              _buildInputField(
                label: 'CHAVE DE ACESSO (SENHA)',
                icon: Icons.key_rounded,
                hint: '••••••••',
                isPassword: true,
                controller: _passwordController,
                textInputAction: TextInputAction.done,
                onSubmitted: _handleLogin,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Recuperar acesso', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('ENTRAR NO SISTEMA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                ),
              ),
              const SizedBox(height: 24),
              _buildDivider(),
              const SizedBox(height: 24),
              _buildGoogleButton(),
              const SizedBox(height: 48),
              _buildFooterButtons(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade200)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('OU CONECTE COM', style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        ),
        Expanded(child: Divider(color: Colors.grey.shade200)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _handleGoogleLogin,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/240px-Google_%22G%22_logo.svg.png',
              height: 20,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.account_circle, size: 20, color: Colors.grey.shade700),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'Google WorkID', 
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterButtons(ThemeData theme) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Novo por aqui?', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            TextButton(
              onPressed: () => Navigator.push(context, FadePageRoute(page: const SignupScreen())),
              child: const Text('Criar conta corporativa', style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          '© 2026 MEDIARE - MGCF • PROTOCOLO SEGURO TLS 1.3',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputAction? textInputAction,
    VoidCallback? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.1),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(fontSize: 15),
          textInputAction: textInputAction,
          onFieldSubmitted: (_) => onSubmitted?.call(),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:ui';
import 'api_service.dart';
import 'package:intl/intl.dart';

import 'family_service.dart';
import 'auth_service.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const DashboardScreen({Key? key, this.onNavigate}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  double _pendingFinance = 0.0;
  int _appointmentsCount = 0;
  int _tasksCompleted = 0;
  int _childLevel = 1;
  int _newMessages = 0;
  int _pendingBudgets = 0;
  String _harmonyInsight = 'Carregando insights da família...';

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _fetchHarmonyInsight();
    FamilyService().addListener(_onFamilyChanged);
  }

  Future<void> _fetchHarmonyInsight() async {
    try {
      final res = await ApiService.get('/gamification/harmony-insight');
      if (mounted) {
        setState(() => _harmonyInsight = res['insight'] ?? '');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _harmonyInsight = 'A colaboração entre os pais é o melhor presente para os filhos.');
      }
    }
  }

  @override
  void dispose() {
    FamilyService().removeListener(_onFamilyChanged);
    super.dispose();
  }

  void _onFamilyChanged() {
    _fetchDashboardData();
    _fetchHarmonyInsight();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    
    // Check if we have a valid family
    if (FamilyService().currentFamily.id == 0) {
       setState(() {
         _isLoading = false;
         _pendingFinance = 0;
         _appointmentsCount = 0;
       });
       return;
    }

    final familyId = FamilyService().currentFamily.id;
    try {
      // Buscando dados reais das APIs integradas
      final expenses = await ApiService.get('/expenses?family_unit_id=$familyId');
      final appointments = await ApiService.get('/appointments?family_unit_id=$familyId');
      
      final List<dynamic> expList = expenses['expenses'] ?? [];
      final List<dynamic> appList = appointments['appointments'] ?? [];
      
      List<dynamic> msgList = [];
      List<dynamic> budList = [];
      
      try {
         final messages = await ApiService.get('/chats/messages?chat_id=1');
         msgList = messages['messages'] ?? [];
      } catch (_) {}

      try {
         final budgets = await ApiService.get('/budgets');
         budList = budgets['budgets'] ?? [];
      } catch (_) {}

      // Gamification context for the first child
      int childLevel = 1;
      int tasksDone = 0;
      try {
         final childrenRes = await ApiService.get('/users/children');
         final List<dynamic> children = childrenRes['children'] ?? [];
         if (children.isNotEmpty) {
            final childId = children[0]['id'];
            final progress = await ApiService.get('/child-progress/$childId');
            childLevel = progress['level'] ?? 1;
            
            final tasksRes = await ApiService.get('/tasks?child_id=$childId');
            final List<dynamic> tasks = tasksRes['tasks'] ?? [];
            tasksDone = tasks.where((t) => t['status'] == 'completed').length;
         }
      } catch (_) {}

      setState(() {
        _pendingFinance = expList.where((e) => e['status'] == 'Pendente').fold(0.0, (sum, e) => sum + (e['amount'] as num).toDouble());
        _appointmentsCount = appList.length;
        _childLevel = childLevel; 
        _tasksCompleted = tasksDone; 
        _newMessages = msgList.length;
        _pendingBudgets = budList.where((b) => b['status'] == 'proposed').length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro no Dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(context, isDesktop),
          const SizedBox(height: 16),
          _buildBannerMode(),
          const SizedBox(height: 16),
          _buildHarmonyInsightBanner(),
          const SizedBox(height: 32),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (isDesktop) 
            _buildDesktopGrid(context, currencyFormat)
          else 
            _buildMobileList(context, currencyFormat),
        ],
      ),
    );
  }

  Widget _buildHarmonyInsightBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF3B82F6), size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'INSIGHT DE HARMONIA (IA)',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF2563EB), letterSpacing: 1.5),
                ),
                const SizedBox(height: 6),
                Text(
                  _harmonyInsight,
                  style: TextStyle(fontSize: 15, color: Theme.of(context).primaryColor, fontStyle: FontStyle.italic, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerMode() {
    final family = FamilyService().currentFamily;
    final isUnilateral = family.mode == 'Unilateral';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isUnilateral ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: isUnilateral ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUnilateral ? Icons.gavel_rounded : Icons.handshake_rounded, 
            color: isUnilateral ? const Color(0xFFD97706) : const Color(0xFF0F766E),
            size: 16,
          ),
          const SizedBox(width: 12),
          Text(
            'Modo ${family.mode}',
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 12,
              color: isUnilateral ? const Color(0xFFD97706) : const Color(0xFF0F766E),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, bool isDesktop) {
    final today = DateFormat("d 'de' MMMM 'de' y", 'pt_BR').format(DateTime.now());
    final userName = AuthService().currentUser?.displayName?.split(' ').first ?? 'Usuário';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Olá, $userName! 👋',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).primaryColor,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          today.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopGrid(BuildContext context, NumberFormat currency) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: 2.5,
      children: [
        _buildDashboardCard(
          context,
          title: 'Compromissos',
          icon: Icons.calendar_month_outlined,
          color: const Color(0xFF3B82F6), // Blue
          content: [
            'Proximo: Consulta Pediátrica',
            'Sincronizado com agenda Google',
          ],
          actionLabel: 'Ver Agenda',
          onAction: () => widget.onNavigate?.call(7),
        ),
        _buildDashboardCard(
          context,
          title: 'Financeiro',
          icon: Icons.account_balance_wallet_outlined,
          color: const Color(0xFF10B981), // Green
          content: [
            'Pendente para aprovação: ${currency.format(_pendingFinance)}',
            'Total do mês está dentro da meta',
          ],
          actionLabel: 'Ver Finanças',
          onAction: () => widget.onNavigate?.call(2),
        ),
        _buildDashboardCard(
          context,
          title: 'Comunicação',
          icon: Icons.chat_bubble_outline,
          color: const Color(0xFF8B5CF6), // Purple
          content: [
            '$_newMessages novas mensagens no chat',
            'IA: Tom da conversa está estável',
          ],
          actionLabel: 'Abrir Chat',
          onAction: () => widget.onNavigate?.call(3),
        ),
        _buildDashboardCard(
          context,
          title: 'Gamificação (Pedro)',
          icon: Icons.star_border_purple500,
          color: const Color(0xFFF59E0B), // Amber
          content: [
            'Nível $_childLevel • Guardião da Paz',
            '$_tasksCompleted tarefas concluídas hoje',
          ],
          actionLabel: 'Modo Criança',
          onAction: () => widget.onNavigate?.call(6),
        ),
        _buildDashboardCard(
          context,
          title: 'Orçamentos',
          icon: Icons.receipt_long,
          color: const Color(0xFF14B8A6), // Teal
          content: [
            '$_pendingBudgets orçamentos em análise',
            'Último: Reforma Quarto Infantil',
          ],
          actionLabel: 'Ver Acordos',
          onAction: () => widget.onNavigate?.call(9),
        ),
      ],
    );
  }

  Widget _buildMobileList(BuildContext context, NumberFormat currency) {
    return Column(
      children: [
        _buildDashboardCard(
          context,
          title: 'Compromissos',
          icon: Icons.event,
          color: const Color(0xFF3B82F6),
          content: ['$_appointmentsCount eventos na agenda'],
          actionLabel: 'Ver Mais',
          onAction: () => widget.onNavigate?.call(7),
        ),
        const SizedBox(height: 16),
        _buildDashboardCard(
          context,
          title: 'Financeiro',
          icon: Icons.attach_money,
          color: const Color(0xFF10B981),
          content: ['Pendente: ${currency.format(_pendingFinance)}'],
          actionLabel: 'Detalhes',
          onAction: () => widget.onNavigate?.call(2),
        ),
        const SizedBox(height: 16),
        _buildDashboardCard(
          context,
          title: 'Orçamentos',
          icon: Icons.receipt_long,
          color: const Color(0xFF14B8A6),
          content: ['$_pendingBudgets pendentes'],
          actionLabel: 'Ver',
          onAction: () => widget.onNavigate?.call(9),
        ),
      ],
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<String> content,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor, letterSpacing: -0.2),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ...content.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item, 
                          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: color.withOpacity(0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(actionLabel.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
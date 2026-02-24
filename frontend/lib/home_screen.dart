import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'responsive_shell.dart';
import 'hamburger_menu.dart';
import 'bottom_navigation.dart';
import 'screens.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'api_service.dart';
import 'family_context_switcher.dart';
import 'notification_service.dart';
import 'family_service.dart';
import 'utils.dart';
import 'auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _currentRoute = 'inicio';

  late final List<Widget> _screens = [
    DashboardScreen(onNavigate: (index) {
      setState(() {
        _currentIndex = index;
        _updateRouteFromIndex(index);
      });
    }),
    const CalendarScreen(),
    const FinanceScreen(),
    const ChatScreen(),
    const SettingsScreen(),
    const LocationsScreen(),
    const GamificationManagementScreen(),
    const AppointmentsScreen(),
    const ReportsScreen(),
    const BudgetsScreen(),
    const AgreementsScreen(),
    const DiscoveryScreen(childId: 0), // childId 0 indica buscar auto
  ];

  @override
  void initState() {
    super.initState();
    FamilyService().fetchFamilies();
    NotificationService().fetchNotifications();
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notificações'),
        content: SizedBox(
          width: 400,
          height: 500,
          child: ListenableBuilder(
            listenable: NotificationService(),
            builder: (context, _) {
              final notifs = NotificationService().notifications;
              if (NotificationService().isLoading) return const Center(child: CircularProgressIndicator());
              if (notifs.isEmpty) return const Center(child: Text('Nenhuma notificação por enquanto.'));
              
              return ListView.separated(
                itemCount: notifs.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final n = notifs[index];
                  return ListTile(
                    leading: Icon(
                      n.type == 'success' ? Icons.check_circle : Icons.info,
                      color: n.isRead ? Colors.grey : (n.type == 'success' ? Colors.green : Colors.blue),
                    ),
                    title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                    subtitle: Text(n.content),
                    onTap: () {
                      if (!n.isRead) NotificationService().markAsRead(n.id);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('FECHAR')),
        ],
      ),
    );
  }

  Future<void> _triggerEmergency() async {
    // Show a small confirmation dialog to prevent accidental triggers
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Emergência Médica', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text('Essa ação enviará um alerta imediato com sua localização para todos os responsáveis do seu núcleo familiar atual. Tem certeza?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('DISPARAR AGORA'),
          ),
        ],
      )
    );

    if (confirm != true) return;

    try {
      // Hardcoded dummy coords for MVP/Sandbox demonstration since Geolocation needs specific App permissions
      final res = await ApiService.post('/notifications/emergency', {
        "latitude": -23.550520,
        "longitude": -46.633308,
        "message": "EMERGÊNCIA MÉDICA ACIONADA"
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('ALERTA ENVIADO a todos os membros.'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao enviar alerta: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    return ResponsiveShell(
      currentRoute: _currentRoute,
      onItemSelected: _handleMenuRoute,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/mediare_logo.png',
              height: 28,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.security, size: 24, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 12),
            const Text(
              'MEDIARE • MGCF',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2),
            ),
          ],
        ),
        actions: [
          if (isDesktop)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
              child: FamilyContextSwitcher(),
            ),
          ListenableBuilder(
            listenable: NotificationService(),
            builder: (context, _) => Badge(
              backgroundColor: const Color(0xFFEF4444),
              label: Text('${NotificationService().unreadCount}'),
              isLabelVisible: NotificationService().unreadCount > 0,
              child: IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () => _showNotifications(context),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => _showProfileDialog(context),
          ),
          if (isDesktop)
            IconButton(
              icon: const Icon(Icons.cloud_queue_rounded),
              onPressed: () async {
                try {
                  final response = await ApiService.get('/health');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Backend Status: ${response['message']}'),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await AuthService().signOut();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: HamburgerMenu(onItemSelected: _handleMenuRoute),
      body: _screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: _triggerEmergency,
        backgroundColor: const Color(0xFFEF4444),
        elevation: 4,
        highlightElevation: 8,
        tooltip: 'Emergência Médica',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: isDesktop 
          ? null 
          : Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
              ),
              child: BottomNavigation(
                currentIndex: _currentIndex < 5 ? _currentIndex : 0, 
                onTabSelected: (int index) {
                  setState(() {
                    _currentIndex = index;
                    _updateRouteFromIndex(index);
                  });
                },
              ),
            ),
    );
  }

  void _updateRouteFromIndex(int index) {
    final routes = ['inicio', 'calendario', 'financeiro', 'chat', 'configuracoes'];
    if (index < routes.length) {
      _currentRoute = routes[index];
    }
  }

  void _handleMenuRoute(String route) {
    debugPrint('Navegando para: $route');
    setState(() {
      _currentRoute = route;
      switch (route) {
        case 'inicio':
          _currentIndex = 0;
          break;
        case 'calendario':
        case 'agenda':
          _currentIndex = 1;
          break;
        case 'financeiro':
        case 'financas':
          _currentIndex = 2;
          break;
        case 'chat':
          _currentIndex = 3;
          break;
        case 'configuracoes':
        case 'config':
          _currentIndex = 4;
          break;
        case 'enderecos':
          _currentIndex = 5;
          break;
        case 'gamificacao':
          _currentIndex = 6;
          break;
        case 'compromissos':
          _currentIndex = 7;
          break;
        case 'relatorios':
          _currentIndex = 8;
          break;
        case 'orcamentos':
          _currentIndex = 9;
          break;
        case 'acordos':
          _currentIndex = 10;
          break;
        case 'descobertas':
          _currentIndex = 11;
          break;
        default:
          _currentIndex = 0;
      }
    });
  }

  void _showProfileDialog(BuildContext context) {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Meu Perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30, 
              backgroundColor: Theme.of(context).primaryColor, 
              child: const Icon(Icons.person, size: 40, color: Colors.white)
            ),
            const SizedBox(height: 16),
            Text(user?.email ?? 'Usuário', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Sessão Protegida SHA-256', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('FECHAR')),
          ElevatedButton(
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                 Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('SAIR DA CONTA'),
          ),
        ],
      ),
    );
  }
  Widget _buildOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 50,
          ),
        ],
      ),
    );
  }
}

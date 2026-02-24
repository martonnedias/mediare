import 'package:flutter/material.dart';

class ResponsiveShell extends StatefulWidget {
  final Widget body;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Function(String) onItemSelected;
  final String currentRoute;

  const ResponsiveShell({
    Key? key,
    required this.body,
    this.drawer,
    this.bottomNavigationBar,
    this.appBar,
    this.floatingActionButton,
    required this.onItemSelected,
    required this.currentRoute,
  }) : super(key: key);

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  final ValueNotifier<bool> _isCollapsed = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    if (!isDesktop) {
      return Scaffold(
        appBar: widget.appBar,
        drawer: widget.drawer,
        body: widget.body,
        floatingActionButton: widget.floatingActionButton,
        bottomNavigationBar: widget.bottomNavigationBar,
      );
    }

    return Scaffold(
      appBar: widget.appBar,
      floatingActionButton: widget.floatingActionButton,
      body: Row(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: _isCollapsed,
            builder: (context, collapsed, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: collapsed ? 80 : 250,
                curve: Curves.easeInOut,
                child: _WebSidebar(
                  isCollapsed: collapsed,
                  onToggle: () => _isCollapsed.value = !collapsed,
                  onItemSelected: widget.onItemSelected,
                  currentRoute: widget.currentRoute,
                ),
              );
            },
          ),
          Expanded(
            child: widget.body,
          ),
        ],
      ),
    );
  }
}

class _WebSidebar extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onToggle;
  final Function(String) onItemSelected;
  final String currentRoute;

  const _WebSidebar({
    Key? key,
    required this.isCollapsed,
    required this.onToggle,
    required this.onItemSelected,
    required this.currentRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    isCollapsed ? Icons.menu : Icons.menu_open,
                    color: Colors.white70,
                  ),
                  onPressed: onToggle,
                  tooltip: isCollapsed ? 'Expandir' : 'Recolher',
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, thickness: 1, indent: 20, endIndent: 20),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _SidebarItem(
                  icon: Icons.dashboard,
                  label: 'Início',
                  route: 'inicio',
                  isCollapsed: isCollapsed,
                  isSelected: currentRoute == 'inicio',
                  onTap: () => onItemSelected('inicio'),
                ),
                _SidebarItem(
                  icon: Icons.calendar_today,
                  label: 'Calendário',
                  route: 'calendario',
                  isCollapsed: isCollapsed,
                  isSelected: currentRoute == 'calendario',
                  onTap: () => onItemSelected('calendario'),
                ),
                _SidebarItem(
                  icon: Icons.attach_money,
                  label: 'Financeiro',
                  route: 'financeiro',
                  isCollapsed: isCollapsed,
                  isSelected: currentRoute == 'financeiro',
                  onTap: () => onItemSelected('financeiro'),
                ),
                _SidebarItem(
                  icon: Icons.chat,
                  label: 'Chat',
                  route: 'chat',
                  isCollapsed: isCollapsed,
                  isSelected: currentRoute == 'chat',
                  onTap: () => onItemSelected('chat'),
                ),
                _SidebarItem(
                  icon: Icons.receipt_long,
                  label: 'Orçamentos',
                  route: 'orcamentos',
                  isCollapsed: isCollapsed,
                  isSelected: currentRoute == 'orcamentos',
                  onTap: () => onItemSelected('orcamentos'),
                ),
                const Divider(color: Colors.white24, height: 20),
                _SidebarItem(
                  icon: Icons.location_on,
                  label: 'Endereços',
                  route: 'enderecos',
                  isCollapsed: isCollapsed,
                  isSelected: currentRoute == 'enderecos',
                  onTap: () => onItemSelected('enderecos'),
                ),
                _SidebarItem(
                  icon: Icons.videogame_asset,
                  label: 'Gamificação',
                  route: 'gamificacao',
                  isCollapsed: isCollapsed,
                  isSelected: currentRoute == 'gamificacao',
                  onTap: () => onItemSelected('gamificacao'),
                ),
                _SidebarItem(
                  icon: Icons.assignment,
                  label: 'Compromissos',
                  route: 'compromissos',
                  isCollapsed: isCollapsed,
                  isSelected: currentRoute == 'compromissos',
                  onTap: () => onItemSelected('compromissos'),
                ),
                _SidebarItem(
                  icon: Icons.description,
                  label: 'Relatórios',
                  route: 'relatorios',
                  isCollapsed: isCollapsed,
                  isSelected: currentRoute == 'relatorios',
                  onTap: () => onItemSelected('relatorios'),
                ),
                const Divider(color: Colors.white24, height: 20),
                _SidebarItem(
                  icon: Icons.settings,
                  label: 'Ajustes',
                  route: 'configuracoes',
                  isCollapsed: isCollapsed,
                  isSelected: currentRoute == 'configuracoes',
                  onTap: () => onItemSelected('configuracoes'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isCollapsed;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.route,
    required this.isCollapsed,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? Colors.white.withValues(alpha: 0.2)
                  : (_isHovered ? Colors.white.withValues(alpha: 0.1) : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: widget.isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 24,
                ),
                if (!widget.isCollapsed) ...[
                  const SizedBox(width: 15),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

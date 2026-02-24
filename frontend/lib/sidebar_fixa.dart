import 'package:flutter/material.dart';

class SidebarFixa extends StatelessWidget {
  final Function(String) onItemSelected;

  const SidebarFixa({Key? key, required this.onItemSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.home,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                Text(
                  'MEDIARE',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Início'),
                  onTap: () => onItemSelected('inicio'),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Calendário'),
                  onTap: () => onItemSelected('calendario'),
                ),
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Financeiro'),
                  onTap: () => onItemSelected('financeiro'),
                ),
                ListTile(
                  leading: const Icon(Icons.chat),
                  title: const Text('Chat'),
                  onTap: () => onItemSelected('chat'),
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Configurações'),
                  onTap: () => onItemSelected('configuracoes'),
                ),
                ListTile(
                  leading: const Icon(Icons.event),
                  title: const Text('Compromissos'),
                  onTap: () => onItemSelected('compromissos'),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Endereços'),
                  onTap: () => onItemSelected('enderecos'),
                ),
                ListTile(
                  leading: const Icon(Icons.videogame_asset),
                  title: const Text('Gamificação'),
                  onTap: () => onItemSelected('gamificacao'),
                ),
                ListTile(
                  leading: const Icon(Icons.report),
                  title: const Text('Relatórios'),
                  onTap: () => onItemSelected('relatorios'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
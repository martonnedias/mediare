import 'package:flutter/material.dart';
import 'family_context_switcher.dart';

class NavbarSuperior extends StatelessWidget {
  final String title;
  final Function()? onMenuPressed;

  const NavbarSuperior({
    Key? key,
    required this.title,
    this.onMenuPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: onMenuPressed,
          child: Icon(
            Icons.home,
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: FamilyContextSwitcher(),
        ),
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.account_circle),
          onPressed: () {},
        ),
      ],
    );
  }
}

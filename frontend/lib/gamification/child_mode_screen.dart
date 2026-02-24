import 'package:flutter/material.dart';

class ChildModeScreen extends StatelessWidget {
  const ChildModeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jornada do Herói'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Lista de tarefas do dia'),
            Text('Pontos e nível atual'),
            Text('Recompensas disponíveis'),
          ],
        ),
      ),
    );
  }
}
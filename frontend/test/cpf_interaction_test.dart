import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediare_mgcf/onboarding_screen.dart';



import 'helpers/mock_firebase.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() async {
    await initializeMockFirebase();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Teste de interação com campo CPF no Onboarding', (WidgetTester tester) async {
    // Carrega o Onboarding
    await tester.pumpWidget(const MaterialApp(
      home: OnboardingScreen(),
    ));

    // Localiza o campo de CPF
    final cpfField = find.byType(TextFormField).at(1); // O segundo campo é o CPF (Perfil)
    expect(cpfField, findsOneWidget);

    print('--- Iniciando Teste de Digitação Apex ---');

    // Simula a digitação número a número
    String cpfToType = '12345678901';
    String currentTyped = '';

    for (int i = 0; i < cpfToType.length; i++) {
      currentTyped += cpfToType[i];
      await tester.enterText(cpfField, currentTyped);
      await tester.pump();
      
      // Obtém o texto atual do campo (com máscara aplicada pelo formatter)
      final EditableText editableText = tester.widget<EditableText>(
        find.descendant(of: cpfField, matching: find.byType(EditableText))
      );
      print('Digitado: ${cpfToType[i]} | Valor no Campo: ${editableText.controller.text}');
    }

    // Verifica o valor final com a máscara do brasil_fields
    final finalValue = tester.widget<TextFormField>(cpfField).controller?.text;
    print('--- Resultado Final: $finalValue ---');
    
    expect(finalValue, equals('123.456.789-01'));
  });
}

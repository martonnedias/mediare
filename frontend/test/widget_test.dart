import 'package:flutter_test/flutter_test.dart';
import 'package:mediare_mgcf/main.dart';

import 'package:google_fonts/google_fonts.dart';
import 'helpers/mock_firebase.dart';

void main() {
  setUpAll(() async {
    await initializeMockFirebase();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Testa se a tela inicial carrega corretamente', (WidgetTester tester) async {
    // Carrega o app
    await tester.pumpWidget(const MyApp());
    
    // Aguarda as animações e transições (como o StreamBuilder do AuthWrapper)
    // Usamos pump() repetidamente ou pumpAndSettle()
    await tester.pumpAndSettle();

    // Verifica se o título ou copyright está presente
    expect(find.textContaining('MEDIARE - MGCF'), findsWidgets);

    // Verifica se o botão de login (ENTRAR NO SISTEMA) está presente
    expect(find.text('ENTRAR NO SISTEMA'), findsOneWidget);
  });
}
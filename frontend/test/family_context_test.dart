import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediare_mgcf/family_service.dart';
import 'package:mediare_mgcf/family_context_switcher.dart';

void main() {
  test('FamilyService updates current family and notifies listeners', () {
    final service = FamilyService();
    bool notified = false;
    service.addListener(() {
      notified = true;
    });

    final newFamily = Family(id: 99, name: 'Família Teste', mode: 'Unilateral');
    service.setFamilies([service.currentFamily, newFamily]);
    
    service.setFamily(newFamily);

    expect(service.currentFamily.id, 99);
    expect(service.currentFamily.mode, 'Unilateral');
    expect(notified, true);
  });

  testWidgets('FamilyContextSwitcher displays current family mode', (WidgetTester tester) async {
    // Reset service
    FamilyService().setFamilies([
      Family(id: 1, name: 'Família A', mode: 'Colaborativo'),
      Family(id: 2, name: 'Família B', mode: 'Unilateral')
    ]);
    FamilyService().setFamily(FamilyService().availableFamilies[0]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FamilyContextSwitcher(),
        ),
      ),
    );

    // Verifica se "Família A (Colaborativo)" está presente
    expect(find.text('Família A (Colaborativo)'), findsWidgets);

    // Simular troca
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    
    // No menu aberto, Família B deve aparecer.
    await tester.tap(find.text('Família B (Unilateral)').last);
    await tester.pumpAndSettle();

    expect(FamilyService().currentFamily.name, 'Família B');
    expect(find.text('Família B (Unilateral)'), findsWidgets);
  });
}

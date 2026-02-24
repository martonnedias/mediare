import 'package:flutter/material.dart';
import 'family_service.dart';

class FamilyContextSwitcher extends StatelessWidget {
  final bool isLight;
  const FamilyContextSwitcher({Key? key, this.isLight = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = FamilyService();
    
    return ListenableBuilder(
      listenable: service,
      builder: (context, child) {
        final current = service.currentFamily;

        return Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: current.id,
              dropdownColor: Theme.of(context).primaryColor,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
              underline: const SizedBox.shrink(),
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              items: service.availableFamilies.map((f) {
                return DropdownMenuItem<int>(
                  value: f.id,
                  child: Text('${f.name} (${f.mode})'),
                );
              }).toList(),
              onChanged: (id) {
                if (id != null) {
                  final selected = service.availableFamilies.firstWhere((f) => f.id == id);
                  service.setFamily(selected);
                }
              },
            ),
          ),
        );
      },
    );
  }
}

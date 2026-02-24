import 'package:flutter/material.dart';
import 'api_service.dart';

class Family {
  final int id;
  final String name;
  final String mode; // 'Colaborativo' ou 'Unilateral'

  Family({required this.id, required this.name, required this.mode});
}

class FamilyService extends ChangeNotifier {
  static final FamilyService _instance = FamilyService._internal();
  factory FamilyService() => _instance;

  FamilyService._internal();

  Family? _currentFamily;
  List<Family> _availableFamilies = [];

  Family get currentFamily => _currentFamily ?? Family(id: 0, name: 'Carregando...', mode: '...');
  List<Family> get availableFamilies => _availableFamilies;

  void setFamily(Family family) {
    _currentFamily = family;
    notifyListeners();
  }

  void setFamilies(List<Family> families) {
    _availableFamilies = families;
    if (families.isNotEmpty && !families.contains(_currentFamily)) {
      _currentFamily = families.first;
    }
    notifyListeners();
  }

  Future<void> fetchFamilies() async {
    try {
      final response = await ApiService.get('/users/me/families');
      final List<dynamic> familiesJson = response['families'] ?? [];
      
      final families = familiesJson.map((f) => Family(
        id: f['id'],
        name: f['name'],
        mode: f['mode'],
      )).toList();

      setFamilies(families);
    } catch (e) {
      debugPrint('Erro ao buscar famílias: $e');
      // Mantém as famílias atuais ou limpa se for crítico
    }
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';

// Pour l'instant, nous créons des classes simplifiées
// Vous pourrez les remplacer par les vraies classes quand elles seront créées

class ConducteurModel {
  final String? id;
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ConducteurModel({
    this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
    this.createdAt,
    this.updatedAt,
  });

  ConducteurModel copyWith({
    String? id,
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConducteurModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ConducteurService {
  Future<ConducteurModel?> getConducteurById(String conducteurId) async {
    // Simulation d'un appel API
    await Future.delayed(const Duration(milliseconds: 500));
    return null; // À implémenter
  }

  Future<List<ConducteurModel>> getAllConducteurs() async {
    // Simulation d'un appel API
    await Future.delayed(const Duration(milliseconds: 500));
    return []; // À implémenter
  }

  Future<String?> addConducteur(
    ConducteurModel conducteur, {
    File? photoPermis,
    File? photoCIN,
  }) async {
    // Simulation d'un appel API
    await Future.delayed(const Duration(milliseconds: 1000));
    return 'conducteur_${DateTime.now().millisecondsSinceEpoch}'; // ID simulé
  }

  Future<bool> updateConducteur(
    ConducteurModel conducteur, {
    File? photoPermis,
    File? photoCIN,
  }) async {
    // Simulation d'un appel API
    await Future.delayed(const Duration(milliseconds: 1000));
    return true; // Succès simulé
  }

  Future<void> deleteConducteur(String conducteurId) async {
    // Simulation d'un appel API
    await Future.delayed(const Duration(milliseconds: 500));
    // Suppression simulée
  }
}

class ConducteurProvider with ChangeNotifier {
  final ConducteurService _conducteurService = ConducteurService();
  
  ConducteurModel? _selectedConducteur;
  List<ConducteurModel> _conducteurs = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  ConducteurModel? get selectedConducteur => _selectedConducteur;
  List<ConducteurModel> get conducteurs => _conducteurs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Méthodes
  Future<ConducteurModel?> getConducteurById(String conducteurId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      _selectedConducteur = await _conducteurService.getConducteurById(conducteurId);
      
      _isLoading = false;
      notifyListeners();
      
      return _selectedConducteur;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  Future<List<ConducteurModel>> getAllConducteurs() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      _conducteurs = await _conducteurService.getAllConducteurs();
      
      _isLoading = false;
      notifyListeners();
      
      return _conducteurs;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  Future<String?> addConducteur(
    ConducteurModel conducteur, {
    File? photoPermis,
    File? photoCIN,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final conducteurId = await _conducteurService.addConducteur(
        conducteur,
        photoPermis: photoPermis,
        photoCIN: photoCIN,
      );
      
      if (conducteurId != null) {
        final newConducteur = conducteur.copyWith(id: conducteurId);
        _conducteurs.add(newConducteur);
      }
      
      _isLoading = false;
      notifyListeners();
      
      return conducteurId;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  Future<bool> updateConducteur(
    ConducteurModel conducteur, {
    File? photoPermis,
    File? photoCIN,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final success = await _conducteurService.updateConducteur(
        conducteur,
        photoPermis: photoPermis,
        photoCIN: photoCIN,
      );
      
      if (success) {
        // Mettre à jour le conducteur dans la liste locale
        final index = _conducteurs.indexWhere((c) => c.id == conducteur.id);
        if (index != -1) {
          _conducteurs[index] = conducteur;
        }
        
        // Mettre à jour le conducteur sélectionné si nécessaire
        if (_selectedConducteur?.id == conducteur.id) {
          _selectedConducteur = conducteur;
        }
      }
      
      _isLoading = false;
      notifyListeners();
      
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  Future<bool> deleteConducteur(String conducteurId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _conducteurService.deleteConducteur(conducteurId);
      
      // Supprimer le conducteur de la liste locale
      _conducteurs.removeWhere((c) => c.id == conducteurId);
      
      // Réinitialiser le conducteur sélectionné si nécessaire
      if (_selectedConducteur?.id == conducteurId) {
        _selectedConducteur = null;
      }
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Méthodes utilitaires
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _selectedConducteur = null;
    _conducteurs.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}

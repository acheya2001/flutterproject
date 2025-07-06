import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/vehicule_service.dart';
import '../models/vehicule_model.dart';
import '../../../core/services/notification_reminder_service.dart';


class VehiculeProvider with ChangeNotifier {
  final VehiculeService _vehiculeService = VehiculeService();
  final NotificationReminderService _notificationService = NotificationReminderService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Supprimé le champ _auth inutilisé

  
  List<VehiculeModel> _vehicules = [];
  bool _isLoading = false;
  String? _error;
  double _uploadProgress = 0.0;
  bool _isCancelled = false;

  List<VehiculeModel> get vehicules => _vehicules;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get uploadProgress => _uploadProgress;

  // Méthodes utilitaires pour gérer l'état
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Récupérer les véhicules d'un propriétaire
  Future<void> fetchVehiculesByProprietaireId(String proprietaireId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _vehicules = await _vehiculeService.getVehiculesByProprietaireId(proprietaireId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Ajouter cette méthode à votre VehiculeProvider
  Future<void> fetchVehicules() async {
    try {
      setLoading(true);
      setError(null);

      // Récupérer l'ID de l'utilisateur connecté
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setError("Utilisateur non connecté");
        setLoading(false);
        return;
      }

      debugPrint('[VehiculeProvider] Récupération des véhicules pour l\'utilisateur: ${user.uid}');

      // Récupérer les véhicules depuis Firestore en utilisant proprietaireId
      final snapshot = await _firestore
          .collection('vehicules')
          .where('proprietaireId', isEqualTo: user.uid)
          .get();

      debugPrint('[VehiculeProvider] ${snapshot.docs.length} véhicules trouvés');

      final List<VehiculeModel> loadedVehicules = snapshot.docs
          .map((doc) => VehiculeModel.fromFirestore(doc))
          .toList();

      _vehicules = loadedVehicules;
      debugPrint('[VehiculeProvider] Véhicules chargés: ${_vehicules.length}');
      notifyListeners();
    } catch (e) {
      debugPrint('[VehiculeProvider] Erreur lors du chargement des véhicules: $e');
      setError("Erreur lors du chargement des véhicules: $e");
    } finally {
      setLoading(false);
    }
  }



  // Ajouter un véhicule
  Future<String?> addVehicule({
    required VehiculeModel vehicule,
    File? photoRecto,
    File? photoVerso,
  }) async {
    try {
      // Réinitialiser complètement l'état avant de commencer
      resetForNewOperation();

      _isLoading = true;
      _error = null;
      _uploadProgress = 0.0;
      _isCancelled = false;
      notifyListeners();

      if (_isCancelled) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final String? vehiculeId = await _vehiculeService.addVehicule(
        vehicule,
        photoRecto: photoRecto,
        photoVerso: photoVerso,
        onProgress: (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );

      if (_isCancelled) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      if (vehiculeId != null) {
        // Ajouter le véhicule à la liste locale
        final newVehicule = vehicule.copyWith(id: vehiculeId);
        _vehicules.add(newVehicule);
        
        // Programmer les notifications de rappel d'assurance
        await _notificationService.scheduleInsuranceReminders(newVehicule);
        debugPrint('[VehiculeProvider] Notifications programmées pour le véhicule ${newVehicule.immatriculation}');
        
        _isLoading = false;
        _uploadProgress = 1.0;
        notifyListeners();
        return vehiculeId;
      } else {
        _isLoading = false;
        _error = 'Erreur lors de l\'ajout du véhicule';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      _uploadProgress = 0.0;
      debugPrint('[VehiculeProvider] Erreur lors de l\'ajout du véhicule: $e');
      notifyListeners();
      rethrow;
    }
  }

  // Mettre à jour un véhicule
  Future<bool> updateVehicule({
    required VehiculeModel vehicule,
    File? photoRecto,
    File? photoVerso,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      _uploadProgress = 0.0;
      _isCancelled = false;
      notifyListeners();

      if (_isCancelled) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final bool success = await _vehiculeService.updateVehicule(
        vehicule,
        photoRecto: photoRecto,
        photoVerso: photoVerso,
        onProgress: (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );

      if (_isCancelled) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (success) {
        // Mettre à jour le véhicule dans la liste locale
        final index = _vehicules.indexWhere((v) => v.id == vehicule.id);
        if (index != -1) {
          _vehicules[index] = vehicule;
        }
        
        // Reprogrammer les notifications de rappel d'assurance
        await _notificationService.scheduleInsuranceReminders(vehicule);
        debugPrint('[VehiculeProvider] Notifications reprogrammées pour le véhicule ${vehicule.immatriculation}');
        
        _isLoading = false;
        _uploadProgress = 1.0;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _error = 'Erreur lors de la mise à jour du véhicule';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      _uploadProgress = 0.0;
      debugPrint('[VehiculeProvider] Erreur lors de la mise à jour du véhicule: $e');
      notifyListeners();
      rethrow;
    }
  }

  // Supprimer un véhicule
  Future<void> deleteVehicule(String vehiculeId, String proprietaireId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _vehiculeService.deleteVehicule(vehiculeId, proprietaireId);
      
      // Annuler les notifications programmées pour ce véhicule
      await _notificationService.cancelVehiculeReminders(vehiculeId);
      debugPrint('[VehiculeProvider] Notifications annulées pour le véhicule $vehiculeId');
      
      // Supprimer le véhicule de la liste locale
      _vehicules.removeWhere((vehicule) => vehicule.id == vehiculeId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      debugPrint('[VehiculeProvider] Erreur lors de la suppression du véhicule: $e');
      notifyListeners();
      rethrow;
    }
  }

  // Annuler l'opération en cours
  void cancelVehiculeOperation() {
    _isCancelled = true;
    notifyListeners();
  }

  // Réinitialiser l'état
  void reset() {
    _isLoading = false;
    _error = null;
    _uploadProgress = 0.0;
    _isCancelled = false;
    notifyListeners();
  }

  // Réinitialiser l'état avant une nouvelle opération
  void resetForNewOperation() {
    _isLoading = false;
    _error = null;
    _uploadProgress = 0.0;
    _isCancelled = false;
    notifyListeners();
  }
  
  // Ajouter une méthode pour récupérer l'historique des notifications
  Future<List<Map<String, dynamic>>> getNotificationHistory(String userId) async {
    try {
      return await _notificationService.getNotificationHistory(userId);
    } catch (e) {
      debugPrint('[VehiculeProvider] Erreur lors de la récupération de l\'historique: $e');
      return [];
    }
  }
  
  // Ajouter une méthode pour marquer une notification comme lue
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);
    } catch (e) {
      debugPrint('[VehiculeProvider] Erreur lors du marquage comme lu: $e');
    }
  }
}

// Provider Riverpod pour VehiculeProvider
final vehiculeProvider = ChangeNotifierProvider<VehiculeProvider>((ref) {
  return VehiculeProvider();
});

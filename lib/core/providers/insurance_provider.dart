import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:constat_tunisie/data/services/insurance_service.dart';
import 'package:constat_tunisie/data/models/insurance_model.dart';

class InsuranceProvider with ChangeNotifier {
  final InsuranceService _insuranceService = InsuranceService();
  final Logger _logger = Logger();
  
  List<InsuranceCompany> _insuranceCompanies = [];
  List<InsuranceAgency> _agencies = [];
  List<InsuranceContract> _contracts = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<InsuranceCompany> get insuranceCompanies => _insuranceCompanies;
  List<InsuranceAgency> get agencies => _agencies;
  List<InsuranceContract> get contracts => _contracts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Charger toutes les compagnies d'assurance
  Future<void> loadInsuranceCompanies() async {
    _setLoading(true);
    _clearError();
    
    try {
      _insuranceCompanies = await _insuranceService.getAllInsuranceCompanies();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _logger.e('Erreur lors du chargement des compagnies d\'assurance: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Charger les agences d'une compagnie d'assurance
  Future<void> loadAgenciesByInsurance(String insuranceId) async {
    _setLoading(true);
    _clearError();
    
    try {
      _agencies = await _insuranceService.getAgenciesByInsurance(insuranceId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _logger.e('Erreur lors du chargement des agences: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Charger les contrats d'un conducteur
  Future<void> loadDriverContracts(String driverId) async {
    _setLoading(true);
    _clearError();
    
    try {
      _contracts = await _insuranceService.getDriverContracts(driverId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _logger.e('Erreur lors du chargement des contrats: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Charger les contrats actifs d'un conducteur
  Future<void> loadActiveDriverContracts(String driverId) async {
    _setLoading(true);
    _clearError();
    
    try {
      _contracts = await _insuranceService.getActiveDriverContracts(driverId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _logger.e('Erreur lors du chargement des contrats actifs: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Vérifier si un véhicule a un contrat d'assurance actif
  Future<bool> checkVehicleInsurance(String vehicleId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final hasInsurance = await _insuranceService.hasActiveInsurance(vehicleId);
      return hasInsurance;
    } catch (e) {
      _setError(e.toString());
      _logger.e('Erreur lors de la vérification de l\'assurance: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Obtenir le contrat actif d'un véhicule
  Future<InsuranceContract?> getActiveVehicleContract(String vehicleId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final contract = await _insuranceService.getActiveVehicleContract(vehicleId);
      return contract;
    } catch (e) {
      _setError(e.toString());
      _logger.e('Erreur lors de la récupération du contrat actif: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Créer un nouveau contrat d'assurance
  Future<String?> createContract(InsuranceContract contract) async {
    _setLoading(true);
    _clearError();
    
    try {
      final contractId = await _insuranceService.createContract(contract);
      await loadDriverContracts(contract.driverId);
      return contractId;
    } catch (e) {
      _setError(e.toString());
      _logger.e('Erreur lors de la création du contrat: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Helpers
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
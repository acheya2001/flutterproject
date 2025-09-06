import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vehicule_model.dart';
import '../models/conducteur_info_model.dart';

/// 🔄 Service d'auto-remplissage pour les formulaires d'accident
/// Intégré au système existant de l'application
class AutoFillService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 📋 Auto-remplir le formulaire d'accident basé sur le véhicule sélectionné
  static Future<Map<String, dynamic>> autoFillAccidentForm({
    required String vehicleId,
    String? conducteurId,
  }) async {
    try {
      print('🔄 [AUTO_FILL] Début auto-remplissage pour véhicule: $vehicleId');

      final user = _auth.currentUser;
      final effectiveConducteurId = conducteurId ?? user?.uid;
      
      if (effectiveConducteurId == null) {
        throw Exception('Conducteur non identifié');
      }

      // 1. Récupérer les informations du véhicule
      final vehicleData = await _getVehicleData(vehicleId);
      if (vehicleData == null) {
        throw Exception('Véhicule introuvable');
      }

      // 2. Récupérer les informations du conducteur
      final conducteurData = await _getConducteurData(effectiveConducteurId);
      if (conducteurData == null) {
        throw Exception('Conducteur introuvable');
      }

      // 3. Construire les données pré-remplies
      final autoFilledData = _buildAutoFilledData(
        vehicleData: vehicleData,
        conducteurData: conducteurData,
      );

      print('✅ [AUTO_FILL] Auto-remplissage terminé avec succès');
      return {
        'success': true,
        'data': autoFilledData,
        'hasValidInsurance': vehicleData['estAssure'] ?? false,
        'insuranceStatus': _getInsuranceStatus(vehicleData),
      };

    } catch (e) {
      print('❌ [AUTO_FILL] Erreur auto-remplissage: $e');
      return {
        'success': false,
        'error': e.toString(),
        'data': {},
      };
    }
  }

  /// 🚗 Récupérer les données du véhicule depuis votre collection existante
  static Future<Map<String, dynamic>?> _getVehicleData(String vehicleId) async {
    try {
      final doc = await _firestore.collection('vehicules').doc(vehicleId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('❌ Erreur récupération véhicule: $e');
      return null;
    }
  }

  /// 👤 Récupérer les données du conducteur depuis vos collections existantes
  static Future<Map<String, dynamic>?> _getConducteurData(String conducteurId) async {
    try {
      // Essayer d'abord dans la collection 'conducteurs'
      var doc = await _firestore.collection('conducteurs').doc(conducteurId).get();
      if (doc.exists) return doc.data();

      // Sinon essayer dans 'users'
      doc = await _firestore.collection('users').doc(conducteurId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('❌ Erreur récupération conducteur: $e');
      return null;
    }
  }

  /// 🔧 Construire les données pré-remplies selon votre structure existante
  static Map<String, dynamic> _buildAutoFilledData({
    required Map<String, dynamic> vehicleData,
    required Map<String, dynamic> conducteurData,
  }) {
    return {
      // Informations du véhicule (selon votre modèle Vehicule)
      'vehicule': {
        'id': vehicleData['id'],
        'marque': vehicleData['marque'] ?? '',
        'modele': vehicleData['modele'] ?? '',
        'numeroImmatriculation': vehicleData['numeroImmatriculation'] ?? '',
        'couleur': vehicleData['couleur'] ?? '',
        'annee': vehicleData['annee'] ?? DateTime.now().year,
        'typeVehicule': vehicleData['typeVehicule'] ?? 'VP',
        'carburant': vehicleData['carburant'] ?? 'essence',
        'usage': vehicleData['usage'] ?? 'Personnel',
        'nombrePlaces': vehicleData['nombrePlaces'] ?? 5,
        'numeroSerie': vehicleData['numeroSerie'] ?? '',
        'puissanceFiscale': vehicleData['puissanceFiscale'] ?? '',
        'cylindree': vehicleData['cylindree'] ?? '',
        'poids': vehicleData['poids'] ?? 0.0,
        'genre': vehicleData['genre'] ?? 'VP',
        'numeroCarteGrise': vehicleData['numeroCarteGrise'] ?? '',
      },

      // Informations du conducteur (selon votre modèle ConducteurInfoModel)
      'conducteur': {
        'id': conducteurData['id'] ?? conducteurData['uid'] ?? '',
        'nom': conducteurData['nom'] ?? '',
        'prenom': conducteurData['prenom'] ?? '',
        'adresse': conducteurData['adresse'] ?? '',
        'telephone': conducteurData['telephone'] ?? '',
        'email': conducteurData['email'] ?? '',
        'numeroPermis': conducteurData['numeroPermis'] ?? conducteurData['permisNumero'] ?? '',
        'categoriePermis': vehicleData['categoriePermis'] ?? 'B',
        'dateObtentionPermis': vehicleData['dateObtentionPermis'],
        'dateExpirationPermis': vehicleData['dateExpirationPermis'],
      },

      // Informations d'assurance (selon votre modèle Vehicule)
      'assurance': {
        'estAssure': vehicleData['estAssure'] ?? false,
        'compagnieAssuranceId': vehicleData['compagnieAssuranceId'] ?? '',
        'compagnieAssuranceNom': vehicleData['compagnieAssuranceNom'] ?? '',
        'agenceAssuranceId': vehicleData['agenceAssuranceId'] ?? '',
        'agenceAssuranceNom': vehicleData['agenceAssuranceNom'] ?? '',
        'numeroContratAssurance': vehicleData['numeroContratAssurance'] ?? '',
        'dateDebutAssurance': vehicleData['dateDebutAssurance'],
        'dateFinAssurance': vehicleData['dateFinAssurance'],
        'typeContratAssurance': vehicleData['typeContratAssurance'] ?? '',
        'franchiseAssurance': vehicleData['franchiseAssurance'] ?? 0.0,
        'primeAnnuelle': vehicleData['primeAnnuelle'] ?? 0.0,
      },

      // Métadonnées
      'metadata': {
        'autoFilledAt': DateTime.now().toIso8601String(),
        'hasValidInsurance': vehicleData['estAssure'] ?? false,
        'insuranceStatus': _getInsuranceStatus(vehicleData),
        'dataSource': 'existing_system',
      },

      // Champs pré-calculés pour le formulaire
      'preCalculated': {
        'isOwner': vehicleData['conducteurId'] == conducteurData['id'] || 
                   vehicleData['conducteurId'] == conducteurData['uid'],
        'hasValidInsurance': vehicleData['estAssure'] == true && 
                           _isInsuranceValid(vehicleData),
        'insuranceExpiryWarning': _getExpiryWarning(vehicleData['dateFinAssurance']),
        'vehicleAge': DateTime.now().year - (vehicleData['annee'] ?? DateTime.now().year),
      },
    };
  }

  /// ✅ Vérifier si l'assurance est valide
  static bool _isInsuranceValid(Map<String, dynamic> vehicleData) {
    if (vehicleData['estAssure'] != true) return false;
    
    final dateFin = vehicleData['dateFinAssurance'];
    if (dateFin == null) return false;
    
    DateTime expiryDate;
    if (dateFin is Timestamp) {
      expiryDate = dateFin.toDate();
    } else if (dateFin is DateTime) {
      expiryDate = dateFin;
    } else {
      return false;
    }
    
    return expiryDate.isAfter(DateTime.now());
  }

  /// ⚠️ Obtenir l'avertissement d'expiration
  static String? _getExpiryWarning(dynamic dateFin) {
    if (dateFin == null) return null;
    
    DateTime expiryDate;
    if (dateFin is Timestamp) {
      expiryDate = dateFin.toDate();
    } else if (dateFin is DateTime) {
      expiryDate = dateFin;
    } else {
      return null;
    }
    
    final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
    
    if (daysUntilExpiry <= 0) {
      return 'Assurance expirée';
    } else if (daysUntilExpiry <= 30) {
      return 'Expire dans $daysUntilExpiry jour${daysUntilExpiry > 1 ? 's' : ''}';
    }
    
    return null;
  }

  /// 📊 Obtenir le statut d'assurance
  static String _getInsuranceStatus(Map<String, dynamic> vehicleData) {
    // Utiliser le nouveau champ statutAssurance en priorité
    final statutAssurance = vehicleData['statutAssurance'];
    if (statutAssurance != null) {
      switch (statutAssurance) {
        case 'non_assure':
          return 'Non assuré';
        case 'en_attente_validation':
          return 'En attente de validation';
        case 'assure':
          // Vérifier si l'assurance est encore valide
          if (!_isInsuranceValid(vehicleData)) {
            return 'Assurance expirée';
          }

          final dateFin = vehicleData['dateFinAssurance'];
          if (dateFin != null) {
            DateTime expiryDate;
            if (dateFin is Timestamp) {
              expiryDate = dateFin.toDate();
            } else if (dateFin is DateTime) {
              expiryDate = dateFin;
            } else {
              return 'Assuré';
            }

            final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;

            if (daysUntilExpiry <= 30) {
              return 'Expire bientôt';
            }
          }
          return 'Assuré';
        case 'expire':
          return 'Assurance expirée';
        default:
          return 'Statut inconnu';
      }
    }

    // Fallback vers l'ancienne logique pour compatibilité
    if (vehicleData['estAssure'] != true) return 'Non assuré';

    if (!_isInsuranceValid(vehicleData)) {
      return 'Assurance expirée';
    }

    final dateFin = vehicleData['dateFinAssurance'];
    if (dateFin != null) {
      DateTime expiryDate;
      if (dateFin is Timestamp) {
        expiryDate = dateFin.toDate();
      } else if (dateFin is DateTime) {
        expiryDate = dateFin;
      } else {
        return 'Statut inconnu';
      }

      final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;

      if (daysUntilExpiry <= 30) {
        return 'Expire bientôt';
      }
    }

    return 'Assuré';
  }

  /// 🔍 Obtenir les véhicules réels du conducteur avec contrats actifs
  static Future<List<Map<String, dynamic>>> getConducteurVehicles({String? conducteurId}) async {
    try {
      final user = _auth.currentUser;
      final effectiveConducteurId = conducteurId ?? user?.uid;

      if (effectiveConducteurId == null) return [];

      print('🔍 Recherche véhicules pour conducteur: $effectiveConducteurId');

      // 1. Chercher dans vehicules_assures avec statut actif
      final vehiculesAssuresSnapshot = await _firestore
          .collection('vehicules_assures')
          .where('conducteurId', isEqualTo: effectiveConducteurId)
          .where('statut', isEqualTo: 'actif')
          .get();

      final vehicles = <Map<String, dynamic>>[];

      for (final doc in vehiculesAssuresSnapshot.docs) {
        final vehicleData = doc.data();

        // Vérifier que le contrat est actif
        final dateFinContrat = vehicleData['dateFinContrat'];
        bool contratActif = true;

        if (dateFinContrat != null) {
          final dateFinDateTime = dateFinContrat is Timestamp
              ? dateFinContrat.toDate()
              : DateTime.tryParse(dateFinContrat.toString());

          if (dateFinDateTime != null && dateFinDateTime.isBefore(DateTime.now())) {
            contratActif = false;
          }
        }

        if (contratActif) {
          vehicles.add({
            ...vehicleData,
            'id': doc.id,
            'source': 'vehicule_assure',
            'hasValidInsurance': true,
            'insuranceStatus': 'Assuré',
            'isActive': true,
          });
        }
      }

      // 2. Si aucun véhicule dans vehicules_assures, chercher dans demandes_contrats avec statut contrat_actif
      if (vehicles.isEmpty) {
        print('🔍 Aucun véhicule dans vehicules_assures, recherche dans demandes_contrats...');

        final contratsSnapshot = await _firestore
            .collection('demandes_contrats')
            .where('conducteurId', isEqualTo: effectiveConducteurId)
            .where('statut', isEqualTo: 'contrat_actif')
            .get();

        for (final doc in contratsSnapshot.docs) {
          final contratData = doc.data();

          vehicles.add({
            ...contratData,
            'id': doc.id,
            'source': 'demande_contrat',
            'hasValidInsurance': true,
            'insuranceStatus': 'Contrat Actif',
            'isActive': true,
            // Mapper les champs pour compatibilité
            'marqueVehicule': contratData['marque'],
            'modeleVehicule': contratData['modele'],
            'numeroImmatriculation': contratData['immatriculation'],
            'couleurVehicule': contratData['couleur'],
            'anneeVehicule': contratData['annee'],
          });
        }
      }

      print('✅ ${vehicles.length} véhicules actifs trouvés');
      return vehicles;
    } catch (e) {
      print('❌ Erreur récupération véhicules conducteur: $e');
      return [];
    }
  }
}

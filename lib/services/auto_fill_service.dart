import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🔄 Service de pré-remplissage automatique des formulaires
class AutoFillService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 👤 Récupérer et pré-remplir les données du conducteur connecté
  static Future<Map<String, dynamic>> getPreFilledConducteurData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      // Récupérer les données du conducteur
      final conducteurDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!conducteurDoc.exists) return {};

      final data = conducteurDoc.data()!;
      
      return {
        'nom': data['nom'] ?? '',
        'prenom': data['prenom'] ?? '',
        'email': data['email'] ?? user.email ?? '',
        'telephone': data['telephone'] ?? '',
        'adresse': data['adresse'] ?? '',
        'cin': data['cin'] ?? '',
        'dateNaissance': data['dateNaissance'],
        'lieuNaissance': data['lieuNaissance'] ?? '',
        'profession': data['profession'] ?? '',
        'numeroPermis': data['numeroPermis'] ?? '',
        'categoriePermis': data['categoriePermis'] ?? '',
        'dateObtentionPermis': data['dateObtentionPermis'],
      };
    } catch (e) {
      print('❌ Erreur récupération données conducteur: $e');
      return {};
    }
  }

  /// 🚗 Récupérer les véhicules du conducteur avec données d'assurance
  static Future<List<Map<String, dynamic>>> getPreFilledVehicules() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final vehiculesQuery = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('vehicules')
          .where('statut', isEqualTo: 'actif')
          .get();

      List<Map<String, dynamic>> vehicules = [];

      for (final doc in vehiculesQuery.docs) {
        final vehiculeData = doc.data();
        
        // Récupérer les données d'assurance si disponibles
        Map<String, dynamic> assuranceData = {};
        if (vehiculeData['contratId'] != null) {
          assuranceData = await _getAssuranceData(vehiculeData['contratId']);
        }

        vehicules.add({
          'id': doc.id,
          'marque': vehiculeData['marque'] ?? '',
          'modele': vehiculeData['modele'] ?? '',
          'immatriculation': vehiculeData['immatriculation'] ?? '',
          'couleur': vehiculeData['couleur'] ?? '',
          'annee': vehiculeData['annee'] ?? '',
          'numeroSerie': vehiculeData['numeroSerie'] ?? '',
          'puissance': vehiculeData['puissance'] ?? '',
          'energie': vehiculeData['energie'] ?? '',
          'usage': vehiculeData['usage'] ?? '',
          'contratId': vehiculeData['contratId'],
          'numeroContrat': vehiculeData['numeroContrat'] ?? '',
          'assurance': assuranceData,
        });
      }

      return vehicules;
    } catch (e) {
      print('❌ Erreur récupération véhicules: $e');
      return [];
    }
  }

  /// 🛡️ Récupérer les données d'assurance d'un contrat
  static Future<Map<String, dynamic>> _getAssuranceData(String contratId) async {
    try {
      final contratDoc = await _firestore
          .collection('contrats_assurance')
          .doc(contratId)
          .get();

      if (!contratDoc.exists) return {};

      final data = contratDoc.data()!;
      
      return {
        'compagnie': data['compagnie'] ?? '',
        'agence': data['agence'] ?? '',
        'numeroPolice': data['numeroPolice'] ?? '',
        'dateDebut': data['dateDebut'],
        'dateFin': data['dateFin'],
        'typeContrat': data['typeContrat'] ?? '',
        'franchise': data['franchise'] ?? '',
        'plafondGarantie': data['plafondGarantie'] ?? '',
        'garanties': data['garanties'] ?? [],
        'agent': data['agent'] ?? {},
      };
    } catch (e) {
      print('❌ Erreur récupération assurance: $e');
      return {};
    }
  }

  /// 📍 Pré-remplir les données de localisation (dernière position connue)
  static Future<Map<String, dynamic>> getPreFilledLocation() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      // Récupérer la dernière position enregistrée
      final locationQuery = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('locations')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (locationQuery.docs.isEmpty) return {};

      final locationData = locationQuery.docs.first.data();
      
      return {
        'latitude': locationData['latitude'],
        'longitude': locationData['longitude'],
        'adresse': locationData['adresse'] ?? '',
        'ville': locationData['ville'] ?? '',
        'codePostal': locationData['codePostal'] ?? '',
        'timestamp': locationData['timestamp'],
      };
    } catch (e) {
      print('❌ Erreur récupération localisation: $e');
      return {};
    }
  }

  /// 🕐 Pré-remplir la date et l'heure actuelles
  static Map<String, dynamic> getPreFilledDateTime() {
    final now = DateTime.now();
    
    return {
      'date': now,
      'heure': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      'dateFormatted': '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
      'timestamp': Timestamp.fromDate(now),
    };
  }

  /// 📋 Pré-remplir un formulaire complet d'accident
  static Future<Map<String, dynamic>> getCompletePreFilledData() async {
    try {
      final conducteurData = await getPreFilledConducteurData();
      final vehicules = await getPreFilledVehicules();
      final locationData = await getPreFilledLocation();
      final dateTimeData = getPreFilledDateTime();

      return {
        'conducteur': conducteurData,
        'vehicules': vehicules,
        'vehiculeSelectionne': vehicules.isNotEmpty ? vehicules.first : null,
        'location': locationData,
        'dateTime': dateTimeData,
        'isPreFilled': true,
        'preFilledAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Erreur pré-remplissage complet: $e');
      return {
        'isPreFilled': false,
        'error': e.toString(),
      };
    }
  }

  /// 💾 Sauvegarder les préférences de pré-remplissage
  static Future<void> savePreFillPreferences(Map<String, dynamic> preferences) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('auto_fill')
          .set({
        ...preferences,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Préférences de pré-remplissage sauvegardées');
    } catch (e) {
      print('❌ Erreur sauvegarde préférences: $e');
    }
  }

  /// 📖 Récupérer les préférences de pré-remplissage
  static Future<Map<String, dynamic>> getPreFillPreferences() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final preferencesDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('auto_fill')
          .get();

      if (!preferencesDoc.exists) return {};

      return preferencesDoc.data()!;
    } catch (e) {
      print('❌ Erreur récupération préférences: $e');
      return {};
    }
  }

  /// 🔄 Mettre à jour la dernière position pour le pré-remplissage
  static Future<void> updateLastKnownLocation(double latitude, double longitude, String adresse) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('locations')
          .add({
        'latitude': latitude,
        'longitude': longitude,
        'adresse': adresse,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'auto_fill_location',
      });

      print('📍 Position mise à jour pour pré-remplissage');
    } catch (e) {
      print('❌ Erreur mise à jour position: $e');
    }
  }

  /// 🧹 Nettoyer les anciennes données de localisation (garder seulement les 10 dernières)
  static Future<void> cleanOldLocationData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final allLocationsQuery = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('locations')
          .orderBy('timestamp', descending: true)
          .get();

      // Supprimer les documents au-delà des 10 premiers
      if (allLocationsQuery.docs.length > 10) {
        final docsToDelete = allLocationsQuery.docs.skip(10);
        for (final doc in docsToDelete) {
          await doc.reference.delete();
        }
      }



      print('🧹 Anciennes données de localisation nettoyées');
    } catch (e) {
      print('❌ Erreur nettoyage données: $e');
    }
  }
}

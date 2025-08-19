import 'package:cloud_firestore/cloud_firestore.dart';

class InsuranceDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Récupère toutes les compagnies d'assurance actives depuis Firebase uniquement
  static Future<List<Map<String, dynamic>>> getCompagnies() async {
    try {
      print('🔍 Chargement des compagnies depuis Firebase...');

      // Récupérer toutes les compagnies et filtrer côté client pour éviter l'index
      final QuerySnapshot snapshot = await _firestore
          .collection('compagnies')
          .get();

      print('📊 Nombre de compagnies trouvées: ${snapshot.docs.length}');

      final compagnies = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'nom': data['nom'] ?? 'Nom non spécifié',
              'code': data['code'] ?? doc.id,
              'email': data['email'] ?? '',
              'telephone': data['telephone'] ?? '',
              'adresse': data['adresse'] ?? '',
              'isActive': data['isActive'] ?? true,
              'createdAt': data['createdAt'],
              'updatedAt': data['updatedAt'],
            };
          })
          .where((compagnie) => compagnie['isActive'] == true) // Filtrer côté client
          .toList();

      // Trier par nom côté client
      compagnies.sort((a, b) => (a['nom'] as String).compareTo(b['nom'] as String));

      print('🏢 Compagnies actives trouvées: ${compagnies.length}');
      for (final compagnie in compagnies) {
        print('  - ${compagnie['nom']} (ID: ${compagnie['id']})');
      }

      if (compagnies.isEmpty) {
        print('⚠️ Aucune compagnie active trouvée dans Firebase');
        throw Exception('Aucune compagnie d\'assurance disponible');
      }

      return compagnies;
    } catch (e) {
      print('❌ Erreur lors de la récupération des compagnies: $e');
      // Ne plus retourner de fallback - forcer l'utilisation de Firebase
      throw Exception('Impossible de charger les compagnies d\'assurance: $e');
    }
  }

  /// Récupère toutes les agences d'une compagnie spécifique depuis Firebase uniquement
  static Future<List<Map<String, dynamic>>> getAgencesByCompagnie(String compagnieId) async {
    try {
      print('🔍 Chargement des agences pour compagnie: $compagnieId');

      // Récupérer toutes les agences et filtrer côté client
      final QuerySnapshot snapshot = await _firestore
          .collection('agences')
          .where('compagnieId', isEqualTo: compagnieId)
          .get();

      print('📊 Nombre d\'agences trouvées: ${snapshot.docs.length}');

      final agences = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'nom': data['nom'] ?? 'Nom non spécifié',
              'code': data['code'] ?? doc.id,
              'compagnieId': data['compagnieId'] ?? compagnieId,
              'email': data['email'] ?? '',
              'telephone': data['telephone'] ?? '',
              'adresse': data['adresse'] ?? '',
              'ville': data['ville'] ?? '',
              'codePostal': data['codePostal'] ?? '',
              'isActive': data['isActive'] ?? true,
              'createdAt': data['createdAt'],
              'updatedAt': data['updatedAt'],
            };
          })
          .where((agence) => agence['isActive'] == true) // Filtrer côté client
          .toList();

      // Trier par nom côté client
      agences.sort((a, b) => (a['nom'] as String).compareTo(b['nom'] as String));

      print('🏪 Agences actives trouvées: ${agences.length}');
      for (final agence in agences) {
        print('  - ${agence['nom']} (ID: ${agence['id']})');
      }

      if (agences.isEmpty) {
        print('⚠️ Aucune agence trouvée pour la compagnie: $compagnieId');
      }

      return agences;
    } catch (e) {
      print('❌ Erreur lors de la récupération des agences: $e');
      // Ne plus retourner de fallback - forcer l'utilisation de Firebase
      throw Exception('Impossible de charger les agences: $e');
    }
  }

  /// Récupère toutes les agences (pour les cas où on a besoin de toutes)
  static Future<List<Map<String, dynamic>>> getAllAgences() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('agences')
          .where('isActive', isEqualTo: true)
          .orderBy('nom')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'nom': data['nom'] ?? 'Nom non spécifié',
          'code': data['code'] ?? doc.id,
          'compagnieId': data['compagnieId'] ?? '',
          'compagnieNom': data['compagnieNom'] ?? '',
          'email': data['email'] ?? '',
          'telephone': data['telephone'] ?? '',
          'adresse': data['adresse'] ?? '',
          'ville': data['ville'] ?? '',
          'codePostal': data['codePostal'] ?? '',
          'isActive': data['isActive'] ?? true,
        };
      }).toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération de toutes les agences: $e');
      throw Exception('Impossible de charger les agences: $e');
    }
  }

  /// Récupère une compagnie spécifique par son ID
  static Future<Map<String, dynamic>?> getCompagnieById(String compagnieId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('compagnies')
          .doc(compagnieId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'nom': data['nom'] ?? 'Nom non spécifié',
          'code': data['code'] ?? doc.id,
          'email': data['email'] ?? '',
          'telephone': data['telephone'] ?? '',
          'adresse': data['adresse'] ?? '',
          'isActive': data['isActive'] ?? true,
        };
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de la compagnie $compagnieId: $e');
      return null;
    }
  }

  /// Récupère une agence spécifique par son ID
  static Future<Map<String, dynamic>?> getAgenceById(String agenceId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('agences')
          .doc(agenceId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'nom': data['nom'] ?? 'Nom non spécifié',
          'code': data['code'] ?? doc.id,
          'compagnieId': data['compagnieId'] ?? '',
          'email': data['email'] ?? '',
          'telephone': data['telephone'] ?? '',
          'adresse': data['adresse'] ?? '',
          'ville': data['ville'] ?? '',
          'codePostal': data['codePostal'] ?? '',
          'isActive': data['isActive'] ?? true,
        };
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'agence $agenceId: $e');
      return null;
    }
  }



  /// Vérifie si une compagnie existe et est active
  static Future<bool> isCompagnieActive(String compagnieId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('compagnies')
          .doc(compagnieId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['isActive'] ?? false;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la vérification de la compagnie: $e');
      return false;
    }
  }

  /// Vérifie si une agence existe et est active
  static Future<bool> isAgenceActive(String agenceId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('agences')
          .doc(agenceId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['isActive'] ?? false;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la vérification de l\'agence: $e');
      return false;
    }
  }

  /// Méthode pour créer des données de test (à utiliser uniquement en développement)
  static Future<void> createTestData() async {
    try {
      print('🧪 Création de données de test...');

      // Créer des compagnies de test
      final compagniesTest = [
        {
          'nom': 'STAR Assurances',
          'code': 'STAR',
          'email': 'contact@star.tn',
          'telephone': '+216 71 123 456',
          'adresse': 'Avenue Habib Bourguiba, Tunis',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'nom': 'GAT Assurances',
          'code': 'GAT',
          'email': 'info@gat.tn',
          'telephone': '+216 71 234 567',
          'adresse': 'Rue de la Liberté, Tunis',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'nom': 'MAGHREBIA Assurances',
          'code': 'MAGHREBIA',
          'email': 'contact@maghrebia.tn',
          'telephone': '+216 71 345 678',
          'adresse': 'Avenue Mohamed V, Tunis',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      for (final compagnie in compagniesTest) {
        final docRef = await _firestore.collection('compagnies').add(compagnie);
        print('✅ Compagnie créée: ${compagnie['nom']} (ID: ${docRef.id})');

        // Créer des agences pour chaque compagnie
        final agencesTest = [
          {
            'nom': 'Agence ${compagnie['nom']} - Tunis Centre',
            'code': '${compagnie['code']}_TUN',
            'compagnieId': docRef.id,
            'ville': 'Tunis',
            'email': 'tunis@${compagnie['code'].toString().toLowerCase()}.tn',
            'telephone': '+216 71 111 111',
            'adresse': 'Centre-ville, Tunis',
            'codePostal': '1000',
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          {
            'nom': 'Agence ${compagnie['nom']} - Sfax',
            'code': '${compagnie['code']}_SFAX',
            'compagnieId': docRef.id,
            'ville': 'Sfax',
            'email': 'sfax@${compagnie['code'].toString().toLowerCase()}.tn',
            'telephone': '+216 74 222 222',
            'adresse': 'Centre-ville, Sfax',
            'codePostal': '3000',
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        ];

        for (final agence in agencesTest) {
          final agenceRef = await _firestore.collection('agences').add(agence);
          print('  ✅ Agence créée: ${agence['nom']} (ID: ${agenceRef.id})');
        }
      }

      print('🎉 Données de test créées avec succès !');
    } catch (e) {
      print('❌ Erreur lors de la création des données de test: $e');
      throw Exception('Impossible de créer les données de test: $e');
    }
  }
}

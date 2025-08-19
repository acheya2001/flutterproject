import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🧪 Script pour ajouter des données de test
class TestDataScript {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🚗 Ajouter un véhicule de test en attente
  static Future<void> addTestVehicle() async {
    try {
      // Données de test pour un véhicule
      final testVehicle = {
        // Informations véhicule
        'marque': 'Peugeot',
        'modele': '208',
        'annee': 2020,
        'numeroImmatriculation': '123 TUN 456',
        'numeroSerie': 'VF3XXXXXXXXXXXXXXX',
        'couleur': 'Blanc',
        'carburant': 'Essence',
        'puissanceFiscale': 7,
        'usage': 'Personnel',
        'nombrePlaces': 5,

        // Informations propriétaire
        'nomProprietaire': 'Ben Ahmed',
        'prenomProprietaire': 'Mohamed',
        'adresseProprietaire': '123 Avenue Habib Bourguiba, Tunis',
        'numeroPermis': 'A123456789',
        'categoriePermis': 'B',
        'dateObtentionPermis': Timestamp.fromDate(DateTime(2018, 5, 15)),

        // Informations assurance
        'agenceAssuranceId': '3SlpifCIp4Wp5bMXdcD1', // ID de l'agence de test
        'compagnieAssuranceId': 'test_compagnie_id',
        'agenceAssuranceNom': 'Agence Test Tunis',
        'compagnieAssuranceNom': 'Assurance Test',

        // Statut et métadonnées
        'etatCompte': 'En attente',
        'conducteurId': 'test_conducteur_id',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),

        // Documents (optionnels)
        'carteGriseUrl': null,
        'permisUrl': null,
        'photoVehiculeUrl': null,

        // Informations supplémentaires
        'kilometrage': 45000,
        'datePremiereImmatriculation': Timestamp.fromDate(DateTime(2020, 3, 10)),
        'contrôleTechnique': {
          'date': Timestamp.fromDate(DateTime(2023, 8, 15)),
          'valide': true,
        },
      };

      // Ajouter le véhicule à Firestore
      final docRef = await _firestore.collection('vehicules').add(testVehicle);
      
      print('✅ [TEST] Véhicule de test ajouté avec ID: ${docRef.id}');
      print('🚗 [TEST] Véhicule: ${testVehicle['marque']} ${testVehicle['modele']}');
      print('📍 [TEST] Agence: ${testVehicle['agenceAssuranceId']}');
      print('📊 [TEST] Statut: ${testVehicle['etatCompte']}');

    } catch (e) {
      print('❌ [TEST] Erreur ajout véhicule de test: $e');
    }
  }

  /// 🏢 Ajouter une agence de test
  static Future<void> addTestAgency() async {
    try {
      final testAgency = {
        'nom': 'Agence Test Tunis',
        'adresse': '456 Avenue de la République, Tunis',
        'telephone': '+216 71 123 456',
        'email': 'agence.test@assurance.tn',
        'compagnieId': 'test_compagnie_id',
        'code': 'AGT001',
        'region': 'Tunis',
        'statut': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Utiliser un ID spécifique pour les tests
      await _firestore.collection('agences').doc('3SlpifCIp4Wp5bMXdcD1').set(testAgency);
      
      print('✅ [TEST] Agence de test ajoutée avec ID: 3SlpifCIp4Wp5bMXdcD1');
      print('🏢 [TEST] Agence: ${testAgency['nom']}');

    } catch (e) {
      print('❌ [TEST] Erreur ajout agence de test: $e');
    }
  }

  /// 🏭 Ajouter une compagnie de test
  static Future<void> addTestCompany() async {
    try {
      final testCompany = {
        'nom': 'Assurance Test',
        'adresse': '789 Boulevard du 7 Novembre, Tunis',
        'telephone': '+216 71 987 654',
        'email': 'contact@assurance-test.tn',
        'siteWeb': 'www.assurance-test.tn',
        'code': 'AST001',
        'statut': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('compagnies').doc('test_compagnie_id').set(testCompany);
      
      print('✅ [TEST] Compagnie de test ajoutée avec ID: test_compagnie_id');
      print('🏭 [TEST] Compagnie: ${testCompany['nom']}');

    } catch (e) {
      print('❌ [TEST] Erreur ajout compagnie de test: $e');
    }
  }

  /// 👤 Ajouter un agent de test
  static Future<void> addTestAgent() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ [TEST] Aucun utilisateur connecté');
        return;
      }

      final testAgent = {
        'nom': 'Agent',
        'prenom': 'Test',
        'email': currentUser.email,
        'role': 'agent',
        'agenceId': '3SlpifCIp4Wp5bMXdcD1',
        'compagnieId': 'test_compagnie_id',
        'statut': 'actif',
        'isFirstLogin': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(currentUser.uid).set(testAgent, SetOptions(merge: true));
      
      print('✅ [TEST] Agent de test configuré avec ID: ${currentUser.uid}');
      print('👤 [TEST] Agent: ${testAgent['prenom']} ${testAgent['nom']}');
      print('🏢 [TEST] Agence: ${testAgent['agenceId']}');

    } catch (e) {
      print('❌ [TEST] Erreur configuration agent de test: $e');
    }
  }

  /// 🧪 Exécuter tous les tests de données
  static Future<void> runAllTests() async {
    print('🧪 [TEST] Début de l\'ajout des données de test...');
    
    await addTestCompany();
    await Future.delayed(Duration(seconds: 1));
    
    await addTestAgency();
    await Future.delayed(Duration(seconds: 1));
    
    await addTestAgent();
    await Future.delayed(Duration(seconds: 1));
    
    await addTestVehicle();
    
    print('🎉 [TEST] Toutes les données de test ont été ajoutées !');
    print('📱 [TEST] Vous pouvez maintenant tester le dashboard agent');
  }

  /// 🗑️ Nettoyer les données de test
  static Future<void> cleanTestData() async {
    try {
      print('🗑️ [TEST] Nettoyage des données de test...');

      // Supprimer les véhicules de test
      final vehiculesQuery = await _firestore
          .collection('vehicules')
          .where('agenceAssuranceId', isEqualTo: '3SlpifCIp4Wp5bMXdcD1')
          .get();

      for (final doc in vehiculesQuery.docs) {
        await doc.reference.delete();
        print('🗑️ [TEST] Véhicule supprimé: ${doc.id}');
      }

      // Supprimer l'agence de test
      await _firestore.collection('agences').doc('3SlpifCIp4Wp5bMXdcD1').delete();
      print('🗑️ [TEST] Agence supprimée: 3SlpifCIp4Wp5bMXdcD1');

      // Supprimer la compagnie de test
      await _firestore.collection('compagnies').doc('test_compagnie_id').delete();
      print('🗑️ [TEST] Compagnie supprimée: test_compagnie_id');

      print('✅ [TEST] Nettoyage terminé !');

    } catch (e) {
      print('❌ [TEST] Erreur lors du nettoyage: $e');
    }
  }

  /// 📊 Vérifier les données existantes
  static Future<void> checkExistingData() async {
    try {
      print('📊 [TEST] Vérification des données existantes...');

      // Vérifier les véhicules en attente
      final vehiculesQuery = await _firestore
          .collection('vehicules')
          .where('etatCompte', isEqualTo: 'En attente')
          .get();

      print('🚗 [TEST] ${vehiculesQuery.docs.length} véhicules en attente trouvés');

      for (final doc in vehiculesQuery.docs) {
        final data = doc.data();
        print('   - ${data['marque']} ${data['modele']} (Agence: ${data['agenceAssuranceId']})');
      }

      // Vérifier les agences
      final agencesQuery = await _firestore.collection('agences').get();
      print('🏢 [TEST] ${agencesQuery.docs.length} agences trouvées');

      for (final doc in agencesQuery.docs) {
        final data = doc.data();
        print('   - ${data['nom']} (ID: ${doc.id})');
      }

      // Vérifier l'utilisateur actuel
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          print('👤 [TEST] Utilisateur actuel: ${userData['prenom']} ${userData['nom']} (${userData['role']})');
          print('🏢 [TEST] Agence: ${userData['agenceId']}');
        }
      }

    } catch (e) {
      print('❌ [TEST] Erreur lors de la vérification: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// 🧪 Service de test du nouveau système
class TestNewSystem {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🚀 Tester le système complet
  static Future<void> testCompleteSystem() async {
    print('🧪 === TEST DU SYSTÈME COMPLET ===');
    
    try {
      // 1. Tester les compagnies
      await _testCompagnies();
      
      // 2. Tester les demandes
      await _testDemandes();
      
      // 3. Tester les admins
      await _testAdmins();
      
      print('✅ === TOUS LES TESTS RÉUSSIS ===');
    } catch (e) {
      print('❌ Erreur lors des tests: $e');
    }
  }

  /// 🏢 Tester les compagnies
  static Future<void> _testCompagnies() async {
    print('\n🏢 Test des compagnies...');
    
    final snapshot = await _firestore.collection('compagnies_assurance').get();
    
    print('📊 Nombre de compagnies: ${snapshot.docs.length}');
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      print('  • ${data['nom']} (${data['secteur']}) - Fondée en ${data['fondee']}');
    }
    
    if (snapshot.docs.length >= 10) {
      print('✅ Compagnies OK - ${snapshot.docs.length} compagnies trouvées');
    } else {
      print('⚠️ Peu de compagnies trouvées: ${snapshot.docs.length}');
    }
  }

  /// 📋 Tester les demandes
  static Future<void> _testDemandes() async {
    print('\n📋 Test des demandes...');
    
    final snapshot = await _firestore.collection('demandes_agents').get();
    
    print('📊 Nombre de demandes: ${snapshot.docs.length}');
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      print('  • ${data['prenom']} ${data['nom']} - ${data['compagnieNom']} - ${data['statut']}');
      
      // Vérifier les nouveaux champs
      if (data.containsKey('agenceNom')) {
        print('    Agence: ${data['agenceNom']} (${data['agenceVille']})');
      }
      if (data.containsKey('justificatifTravailFourni')) {
        print('    Justificatif: ${data['justificatifTravailFourni'] ? '✅' : '❌'}');
      }
    }
    
    print('✅ Demandes OK');
  }

  /// 👨‍💼 Tester les admins
  static Future<void> _testAdmins() async {
    print('\n👨‍💼 Test des admins...');
    
    final snapshot = await _firestore.collection('admins_users').get();
    
    print('📊 Nombre d\'admins: ${snapshot.docs.length}');
    
    final adminTypes = <String, int>{};
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final type = data['type'] as String;
      adminTypes[type] = (adminTypes[type] ?? 0) + 1;
      
      print('  • ${data['prenom']} ${data['nom']} (${data['email']}) - Type: $type');
    }
    
    print('\n📊 Répartition par type:');
    adminTypes.forEach((type, count) {
      print('  • $type: $count');
    });
    
    print('✅ Admins OK');
  }

  /// 🔍 Tester une demande spécifique
  static Future<void> testSpecificDemande(String demandeId) async {
    print('\n🔍 Test demande spécifique: $demandeId');
    
    try {
      final doc = await _firestore.collection('demandes_agents').doc(demandeId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        print('✅ Demande trouvée:');
        print('  • Nom: ${data['prenom']} ${data['nom']}');
        print('  • Email: ${data['email']}');
        print('  • Compagnie: ${data['compagnieNom']}');
        print('  • Agence: ${data['agenceNom']} (${data['agenceVille']})');
        print('  • Statut: ${data['statut']}');
        print('  • Justificatif: ${data['justificatifTravailFourni'] ?? false}');
        
        if (data.containsKey('agenceNouvelle')) {
          print('  • Nouvelle agence: ${data['agenceNouvelle']}');
        }
      } else {
        print('❌ Demande non trouvée');
      }
    } catch (e) {
      print('❌ Erreur: $e');
    }
  }

  /// 📈 Statistiques globales
  static Future<void> showGlobalStats() async {
    print('\n📈 === STATISTIQUES GLOBALES ===');
    
    try {
      // Compagnies
      final compagniesSnapshot = await _firestore.collection('compagnies_assurance').get();
      print('🏢 Compagnies: ${compagniesSnapshot.docs.length}');
      
      // Agences
      final agencesSnapshot = await _firestore.collection('agences_assurance').get();
      print('🏪 Agences: ${agencesSnapshot.docs.length}');
      
      // Demandes
      final demandesSnapshot = await _firestore.collection('demandes_agents').get();
      print('📋 Demandes: ${demandesSnapshot.docs.length}');
      
      final demandesEnAttente = demandesSnapshot.docs
          .where((doc) => doc.data()['statut'] == 'en_attente')
          .length;
      print('⏳ Demandes en attente: $demandesEnAttente');
      
      // Admins
      final adminsSnapshot = await _firestore.collection('admins_users').get();
      print('👨‍💼 Admins: ${adminsSnapshot.docs.length}');
      
      // Agents
      final agentsSnapshot = await _firestore.collection('agents_assurance').get();
      print('👥 Agents: ${agentsSnapshot.docs.length}');
      
      print('\n✅ Statistiques affichées');
    } catch (e) {
      print('❌ Erreur statistiques: $e');
    }
  }

  /// 🧹 Nettoyer les données de test
  static Future<void> cleanTestData() async {
    print('\n🧹 Nettoyage des données de test...');
    
    try {
      // Supprimer les demandes de test
      final demandesSnapshot = await _firestore.collection('demandes_agents').get();
      for (final doc in demandesSnapshot.docs) {
        await doc.reference.delete();
      }
      print('✅ Demandes supprimées: ${demandesSnapshot.docs.length}');
      
      print('✅ Nettoyage terminé');
    } catch (e) {
      print('❌ Erreur nettoyage: $e');
    }
  }

  /// 🎯 Créer une demande de test
  static Future<String> createTestDemande() async {
    print('\n🎯 Création demande de test...');
    
    try {
      final demandData = {
        'email': 'test.agent@email.com',
        'nom': 'Test',
        'prenom': 'Agent',
        'telephone': '+216 20 123 456',
        'compagnieId': 'star_assurance',
        'compagnieNom': 'STAR Assurance',
        'agenceNom': 'STAR Test Agence',
        'agenceAdresse': 'Rue de Test, Tunis',
        'agenceVille': 'Tunis',
        'agenceGouvernorat': 'Tunis',
        'agenceTelephone': '+216 71 123 456',
        'agenceNouvelle': true,
        'poste': 'Agent Commercial',
        'numeroAgent': 'TEST001',
        'userType': 'agent_assurance',
        'statut': 'en_attente',
        'dateCreation': FieldValue.serverTimestamp(),
        'motDePasseTemporaire': 'TestPassword123!',
        'cin': 'TEST123456',
        'justificatifTravailFourni': true,
      };

      final docRef = await _firestore.collection('demandes_agents').add(demandData);
      
      print('✅ Demande de test créée: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Erreur création demande test: $e');
      return '';
    }
  }
}

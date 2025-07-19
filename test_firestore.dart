import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// 🧪 Script de test direct pour diagnostiquer Firestore
void main() async {
  print('🧪 === TEST FIRESTORE DIRECT ===');
  
  try {
    // Initialiser Firebase
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyD2vejYDavUL9Rifv2UgDb4l2AFhXF8c_s',
        appId: '1:324863789443:web:52bec42558c4193e78ceb6',
        messagingSenderId: '324863789443',
        projectId: 'assuranceaccident-2c2fa',
        authDomain: 'assuranceaccident-2c2fa.firebaseapp.com',
        storageBucket: 'assuranceaccident-2c2fa.firebasestorage.app',
        measurementId: 'G-8FGZE2HWR2',
      ),
    );
    
    print('✅ Firebase initialisé');
    
    final firestore = FirebaseFirestore.instance;
    
    // Test 1: Lister les collections existantes
    print('\n📋 Test 1: Collections existantes');
    try {
      // Essayer de lire quelques collections connues
      final collections = ['users', 'compagnies_assurance', 'agences', 'admin_notifications'];
      
      for (final collectionName in collections) {
        try {
          final snapshot = await firestore.collection(collectionName).limit(1).get();
          print('  ✅ $collectionName: ${snapshot.docs.length} documents (accessible)');
        } catch (e) {
          print('  ❌ $collectionName: Erreur - $e');
        }
      }
    } catch (e) {
      print('❌ Erreur test collections: $e');
    }
    
    // Test 2: Créer un document de test
    print('\n📝 Test 2: Création document test');
    try {
      final testId = 'test_${DateTime.now().millisecondsSinceEpoch}';
      final testData = {
        'test': true,
        'created_at': FieldValue.serverTimestamp(),
        'message': 'Test de création directe',
        'id': testId,
      };
      
      await firestore.collection('test_creation').doc(testId).set(testData);
      print('  ✅ Document test créé: $testId');
      
      // Vérifier la lecture
      final doc = await firestore.collection('test_creation').doc(testId).get();
      if (doc.exists) {
        print('  ✅ Document test lu avec succès');
        print('  📄 Données: ${doc.data()}');
        
        // Nettoyer
        await firestore.collection('test_creation').doc(testId).delete();
        print('  🧹 Document test supprimé');
      } else {
        print('  ❌ Document test non trouvé après création');
      }
    } catch (e) {
      print('❌ Erreur test création: $e');
    }
    
    // Test 3: Créer un admin de test dans users
    print('\n👤 Test 3: Création admin test');
    try {
      final adminId = 'admin_test_${DateTime.now().millisecondsSinceEpoch}';
      final adminData = {
        'uid': adminId,
        'email': 'admin.test@assurance.tn',
        'nom': 'Test',
        'prenom': 'Admin',
        'role': 'admin_compagnie',
        'status': 'actif',
        'compagnieId': 'test-assurance',
        'compagnieNom': 'Test Assurance',
        'created_at': FieldValue.serverTimestamp(),
        'created_by': 'test_script',
        'source': 'direct_test',
        'isTest': true,
      };
      
      await firestore.collection('users').doc(adminId).set(adminData);
      print('  ✅ Admin test créé: $adminId');
      
      // Vérifier la lecture
      final doc = await firestore.collection('users').doc(adminId).get();
      if (doc.exists) {
        print('  ✅ Admin test lu avec succès');
        print('  📄 Données: ${doc.data()}');
        
        // Nettoyer
        await firestore.collection('users').doc(adminId).delete();
        print('  🧹 Admin test supprimé');
      } else {
        print('  ❌ Admin test non trouvé après création');
      }
    } catch (e) {
      print('❌ Erreur test admin: $e');
    }
    
    // Test 4: Créer les vrais admins
    print('\n🔄 Test 4: Création admins réels');
    try {
      final companies = [
        {'id': 'star-assurance', 'nom': 'STAR Assurance', 'email': 'admin.star@assurance.tn'},
        {'id': 'comar-assurance', 'nom': 'COMAR Assurance', 'email': 'admin.comar@assurance.tn'},
        {'id': 'gat-assurance', 'nom': 'GAT Assurance', 'email': 'admin.gat@assurance.tn'},
        {'id': 'maghrebia-assurance', 'nom': 'Maghrebia Assurance', 'email': 'admin.maghrebia@assurance.tn'},
      ];
      
      int created = 0;
      for (final company in companies) {
        try {
          final adminId = 'admin_${company['id']}_${DateTime.now().millisecondsSinceEpoch}';
          
          final adminData = {
            'uid': adminId,
            'email': company['email'],
            'nom': 'Admin',
            'prenom': company['nom'],
            'role': 'admin_compagnie',
            'status': 'actif',
            'compagnieId': company['id'],
            'compagnieNom': company['nom'],
            'created_at': FieldValue.serverTimestamp(),
            'created_by': 'test_script',
            'source': 'script_creation',
            'isLegitimate': true,
          };
          
          await firestore.collection('users').doc(adminId).set(adminData);
          print('  ✅ Admin créé: ${company['email']} (ID: $adminId)');
          created++;
          
          // Petite pause
          await Future.delayed(const Duration(milliseconds: 500));
          
        } catch (e) {
          print('  ❌ Erreur pour ${company['email']}: $e');
        }
      }
      
      print('  📊 Total créés: $created admins');
      
    } catch (e) {
      print('❌ Erreur création admins: $e');
    }
    
    // Test 5: Vérifier le résultat final
    print('\n📊 Test 5: Vérification finale');
    try {
      final usersSnapshot = await firestore.collection('users').get();
      print('  📋 Total documents dans users: ${usersSnapshot.docs.length}');
      
      final adminsSnapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_compagnie')
          .get();
      print('  👥 Total admin_compagnie: ${adminsSnapshot.docs.length}');
      
      for (final doc in adminsSnapshot.docs) {
        final data = doc.data();
        print('    - ${data['email']} (${data['compagnieNom']})');
      }
      
    } catch (e) {
      print('❌ Erreur vérification finale: $e');
    }
    
    print('\n✅ === TEST TERMINÉ ===');
    
  } catch (e) {
    print('❌ Erreur générale: $e');
  }
}

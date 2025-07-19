import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🧪 Script de test pour créer les admins rapidement
void main() async {
  print('🧪 === TEST CRÉATION ADMINS ===');
  
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialiser Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialisé');
    
    // Tester la connexion Firestore
    await testFirestoreConnection();
    
    // Créer les admins
    await createTestAdmins();
    
    // Vérifier la création
    await verifyAdminsCreation();
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
  
  print('🏁 === TEST TERMINÉ ===');
}

/// 🔗 Tester la connexion Firestore
Future<void> testFirestoreConnection() async {
  try {
    print('🔗 Test connexion Firestore...');
    
    final firestore = FirebaseFirestore.instance;
    
    // Test simple d'écriture/lecture
    await firestore.collection('test_connection').doc('test').set({
      'test': true,
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    final doc = await firestore.collection('test_connection').doc('test').get();
    
    if (doc.exists) {
      print('✅ Connexion Firestore OK');
      // Nettoyer
      await firestore.collection('test_connection').doc('test').delete();
    } else {
      print('❌ Connexion Firestore KO');
    }
    
  } catch (e) {
    print('❌ Erreur connexion Firestore: $e');
  }
}

/// 👥 Créer les admins de test
Future<void> createTestAdmins() async {
  final firestore = FirebaseFirestore.instance;
  
  final admins = [
    {
      'id': 'admin_star_test_script',
      'email': 'admin.star@assurance.tn',
      'compagnieId': 'star-assurance',
      'compagnieNom': 'STAR Assurance',
    },
    {
      'id': 'admin_comar_test_script',
      'email': 'admin.comar@assurance.tn',
      'compagnieId': 'comar-assurance',
      'compagnieNom': 'COMAR Assurance',
    },
    {
      'id': 'admin_gat_test_script',
      'email': 'admin.gat@assurance.tn',
      'compagnieId': 'gat-assurance',
      'compagnieNom': 'GAT Assurance',
    },
    {
      'id': 'admin_maghrebia_test_script',
      'email': 'admin.maghrebia@assurance.tn',
      'compagnieId': 'maghrebia-assurance',
      'compagnieNom': 'Maghrebia Assurance',
    },
  ];

  print('👥 Création des admins...');
  int created = 0;
  
  for (final admin in admins) {
    try {
      print('🔄 Création ${admin['email']}...');
      
      final adminData = {
        'uid': admin['id']!,
        'email': admin['email']!,
        'nom': 'Admin',
        'prenom': admin['compagnieNom']!,
        'role': 'admin_compagnie',
        'status': 'actif',
        'compagnieId': admin['compagnieId']!,
        'compagnieNom': admin['compagnieNom']!,
        'created_at': FieldValue.serverTimestamp(),
        'created_by': 'test_script',
        'source': 'test_creation',
        'isLegitimate': true,
        'isActive': true,
        'test_created': true,
      };

      await firestore
          .collection('users')
          .doc(admin['id']!)
          .set(adminData, SetOptions(merge: true));

      print('✅ ${admin['email']} créé');
      created++;
      
    } catch (e) {
      print('❌ Erreur pour ${admin['email']}: $e');
    }
  }
  
  print('📊 Résultat: $created/${admins.length} admins créés');
}

/// ✅ Vérifier la création des admins
Future<void> verifyAdminsCreation() async {
  try {
    print('✅ Vérification des admins créés...');
    
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection('users').get();
    
    print('📋 Total documents dans users: ${snapshot.docs.length}');
    
    final adminCompagnies = snapshot.docs
        .where((doc) => doc.data()['role'] == 'admin_compagnie')
        .toList();
    
    print('👥 Admin compagnies trouvés: ${adminCompagnies.length}');
    
    for (final doc in adminCompagnies) {
      final data = doc.data();
      print('  ✅ ${data['email']} (${data['compagnieNom']})');
    }
    
    if (adminCompagnies.length >= 4) {
      print('🎉 SUCCESS: Tous les admins sont créés !');
      print('🎯 Vous pouvez maintenant:');
      print('   • Lancer l\'application Flutter');
      print('   • Accéder au Super Admin Dashboard');
      print('   • Gérer les compagnies d\'assurance');
    } else {
      print('⚠️ WARNING: Seulement ${adminCompagnies.length}/4 admins créés');
    }
    
  } catch (e) {
    print('❌ Erreur vérification: $e');
  }
}

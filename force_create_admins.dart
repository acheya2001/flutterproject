import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// 🔥 SCRIPT DE FORCE BRUTE - CRÉATION ADMINS
/// Ce script VA créer les admins, point final !
void main() async {
  print('🔥 === FORCE BRUTE - CRÉATION ADMINS ===');
  
  try {
    // Configuration Firebase manuelle
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDGpAHia_wEmrhnmYNrZFoYU7n3ooUoAgs",
        authDomain: "assuranceaccident-2024.firebaseapp.com",
        projectId: "assuranceaccident-2024",
        storageBucket: "assuranceaccident-2024.appspot.com",
        messagingSenderId: "1059917372502",
        appId: "1:1059917372502:web:c727b5b5f5b5b5b5b5b5b5",
      ),
    );
    
    final firestore = FirebaseFirestore.instance;
    print('✅ Firebase connecté');
    
    // FORCER la création des admins
    await forceCreateAdmins(firestore);
    
    print('🎉 ADMINS CRÉÉS AVEC SUCCÈS !');
    exit(0);
    
  } catch (e) {
    print('❌ Erreur: $e');
    exit(1);
  }
}

/// 💪 FORCER la création des admins
Future<void> forceCreateAdmins(FirebaseFirestore firestore) async {
  print('💪 FORCE BRUTE - Création des admins...');
  
  final admins = [
    {
      'id': 'admin_star_force',
      'email': 'admin.star@assurance.tn',
      'compagnieId': 'star-assurance',
      'compagnieNom': 'STAR Assurance',
      'password': 'StarAdmin2024!',
    },
    {
      'id': 'admin_comar_force',
      'email': 'admin.comar@assurance.tn',
      'compagnieId': 'comar-assurance',
      'compagnieNom': 'COMAR Assurance',
      'password': 'ComarAdmin2024!',
    },
    {
      'id': 'admin_gat_force',
      'email': 'admin.gat@assurance.tn',
      'compagnieId': 'gat-assurance',
      'compagnieNom': 'GAT Assurance',
      'password': 'GatAdmin2024!',
    },
    {
      'id': 'admin_maghrebia_force',
      'email': 'admin.maghrebia@assurance.tn',
      'compagnieId': 'maghrebia-assurance',
      'compagnieNom': 'Maghrebia Assurance',
      'password': 'MaghrebiaAdmin2024!',
    },
  ];
  
  int created = 0;
  
  for (final admin in admins) {
    try {
      print('🔄 FORCE ${admin['email']}...');
      
      final adminData = {
        'uid': admin['id']!,
        'email': admin['email']!,
        'nom': 'Admin',
        'prenom': admin['compagnieNom']!,
        'role': 'admin_compagnie',
        'status': 'actif',
        'compagnieId': admin['compagnieId']!,
        'compagnieNom': admin['compagnieNom']!,
        'password': admin['password']!,
        'isLegitimate': true,
        'isActive': true,
        'created_by': 'force_script',
        'created_at': FieldValue.serverTimestamp(),
        'source': 'force_creation',
        'permissions': ['read_company_data', 'manage_agents'],
      };
      
      // MÉTHODE 1: Set direct
      await firestore
          .collection('users')
          .doc(admin['id']!)
          .set(adminData, SetOptions(merge: true));
      
      print('✅ ${admin['email']} CRÉÉ !');
      created++;
      
      // Vérification immédiate
      final doc = await firestore
          .collection('users')
          .doc(admin['id']!)
          .get();
      
      if (doc.exists) {
        print('✅ VÉRIFIÉ: ${admin['email']} existe dans Firestore');
      } else {
        print('⚠️ PROBLÈME: ${admin['email']} non trouvé après création');
        
        // MÉTHODE 2: Transaction de force
        await firestore.runTransaction((transaction) async {
          final docRef = firestore.collection('users').doc(admin['id']!);
          transaction.set(docRef, adminData);
        });
        
        print('🔧 FORCÉ via transaction: ${admin['email']}');
      }
      
    } catch (e) {
      print('❌ ÉCHEC ${admin['email']}: $e');
      
      // MÉTHODE 3: Batch de force
      try {
        final batch = firestore.batch();
        final docRef = firestore.collection('users').doc(admin['id']!);
        batch.set(docRef, {
          'uid': admin['id']!,
          'email': admin['email']!,
          'nom': 'Admin',
          'prenom': admin['compagnieNom']!,
          'role': 'admin_compagnie',
          'status': 'actif',
          'compagnieId': admin['compagnieId']!,
          'compagnieNom': admin['compagnieNom']!,
          'password': admin['password']!,
          'isLegitimate': true,
          'isActive': true,
          'created_by': 'force_batch',
          'source': 'batch_force',
        });
        
        await batch.commit();
        print('🔧 FORCÉ via batch: ${admin['email']}');
        created++;
        
      } catch (e2) {
        print('💥 ÉCHEC TOTAL ${admin['email']}: $e2');
      }
    }
  }
  
  print('📊 RÉSULTAT FORCE: $created/${admins.length} admins créés');
  
  // Vérification finale BRUTALE
  await verifyBrutal(firestore);
}

/// 🔍 Vérification brutale
Future<void> verifyBrutal(FirebaseFirestore firestore) async {
  print('🔍 VÉRIFICATION BRUTALE...');
  
  try {
    final snapshot = await firestore
        .collection('users')
        .where('role', isEqualTo: 'admin_compagnie')
        .get();
    
    print('📊 TOTAL ADMINS TROUVÉS: ${snapshot.docs.length}');
    
    if (snapshot.docs.isEmpty) {
      print('💥 AUCUN ADMIN TROUVÉ - PROBLÈME MAJEUR !');
    } else {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        print('✅ ADMIN: ${data['email']} - ${data['compagnieNom']}');
      }
    }
    
  } catch (e) {
    print('❌ Erreur vérification: $e');
  }
}

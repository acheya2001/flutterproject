import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🚀 Script de création directe des admins - SANS TIMEOUT
void main() async {
  print('🚀 === CRÉATION DIRECTE ADMINS ===');
  
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialiser Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialisé');
    
    // Configuration Firestore sans timeout
    final firestore = FirebaseFirestore.instance;
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    print('⚙️ Firestore configuré');
    
    // Créer les admins directement
    await createAdminsDirectly(firestore);
    
    // Vérifier la création
    await verifyCreation(firestore);
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
  
  print('🏁 === SCRIPT TERMINÉ ===');
}

/// 👥 Créer les admins directement
Future<void> createAdminsDirectly(FirebaseFirestore firestore) async {
  print('👥 === CRÉATION DIRECTE DES ADMINS ===');

  // IDs fixes pour éviter les doublons
  final admins = [
    {
      'id': 'admin_star_production',
      'email': 'admin.star@assurance.tn',
      'compagnieId': 'star-assurance',
      'compagnieNom': 'STAR Assurance',
    },
    {
      'id': 'admin_comar_production',
      'email': 'admin.comar@assurance.tn',
      'compagnieId': 'comar-assurance',
      'compagnieNom': 'COMAR Assurance',
    },
    {
      'id': 'admin_gat_production',
      'email': 'admin.gat@assurance.tn',
      'compagnieId': 'gat-assurance',
      'compagnieNom': 'GAT Assurance',
    },
    {
      'id': 'admin_maghrebia_production',
      'email': 'admin.maghrebia@assurance.tn',
      'compagnieId': 'maghrebia-assurance',
      'compagnieNom': 'Maghrebia Assurance',
    },
  ];

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
        'created_by': 'direct_script',
        'source': 'direct_creation',
        'isLegitimate': true,
        'isActive': true,
        'script_version': 'direct_v1',
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Utiliser set avec merge pour éviter les conflits
      await firestore
          .collection('users')
          .doc(admin['id']!)
          .set(adminData, SetOptions(merge: true));

      print('✅ ${admin['email']} créé avec succès');
      created++;
      
      // Petite pause entre les créations
      await Future.delayed(const Duration(milliseconds: 500));
      
    } catch (e) {
      print('❌ Erreur pour ${admin['email']}: $e');
      
      // Essayer une méthode alternative
      try {
        print('🔄 Tentative alternative pour ${admin['email']}...');
        
        await firestore.runTransaction((transaction) async {
          final docRef = firestore.collection('users').doc(admin['id']!);
          
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
            'created_by': 'direct_script_transaction',
            'source': 'direct_creation_fallback',
            'isLegitimate': true,
            'isActive': true,
          };

          transaction.set(docRef, adminData, SetOptions(merge: true));
        });
        
        print('✅ ${admin['email']} créé via transaction');
        created++;
        
      } catch (e2) {
        print('❌ Échec définitif pour ${admin['email']}: $e2');
      }
    }
  }
  
  print('📊 Résultat final: $created/${admins.length} admins créés');
}

/// ✅ Vérifier la création
Future<void> verifyCreation(FirebaseFirestore firestore) async {
  print('✅ === VÉRIFICATION CRÉATION ===');
  
  try {
    // Essayer de lire depuis le cache d'abord
    QuerySnapshot? snapshot;
    
    try {
      snapshot = await firestore
          .collection('users')
          .get(const GetOptions(source: Source.cache));
      print('📋 Lecture depuis le cache: ${snapshot.docs.length} documents');
    } catch (e) {
      print('⚠️ Cache non disponible: $e');
    }
    
    // Essayer de lire depuis le serveur
    try {
      snapshot = await firestore
          .collection('users')
          .get(const GetOptions(source: Source.server));
      print('📋 Lecture depuis le serveur: ${snapshot.docs.length} documents');
    } catch (e) {
      print('⚠️ Serveur non disponible: $e');
    }
    
    // Lecture par défaut
    if (snapshot == null) {
      snapshot = await firestore.collection('users').get();
      print('📋 Lecture par défaut: ${snapshot.docs.length} documents');
    }
    
    final adminCompagnies = snapshot.docs
        .where((doc) => doc.data() is Map && (doc.data() as Map)['role'] == 'admin_compagnie')
        .toList();
    
    print('👥 Admin compagnies trouvés: ${adminCompagnies.length}');
    
    for (final doc in adminCompagnies) {
      final data = doc.data() as Map<String, dynamic>;
      print('  ✅ ${data['email']} (${data['compagnieNom']})');
    }
    
    if (adminCompagnies.length >= 4) {
      print('🎉 SUCCESS: Tous les admins sont créés !');
      print('🎯 L\'application devrait maintenant fonctionner !');
    } else {
      print('⚠️ WARNING: Seulement ${adminCompagnies.length}/4 admins créés');
    }
    
  } catch (e) {
    print('❌ Erreur vérification: $e');
  }
}

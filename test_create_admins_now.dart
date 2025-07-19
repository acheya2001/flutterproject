import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🚀 Script d'urgence pour créer les admins MAINTENANT
void main() async {
  print('🚀 === CRÉATION URGENTE ADMINS ===');
  
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialiser Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialisé');
    
    // Créer les admins immédiatement
    await createAdminsNow();
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
  
  print('🏁 === TERMINÉ ===');
}

/// 👥 Créer les admins maintenant
Future<void> createAdminsNow() async {
  final firestore = FirebaseFirestore.instance;
  
  final admins = [
    {
      'id': 'admin_star_urgent',
      'email': 'admin.star@assurance.tn',
      'compagnieId': 'star-assurance',
      'compagnieNom': 'STAR Assurance',
    },
    {
      'id': 'admin_comar_urgent',
      'email': 'admin.comar@assurance.tn',
      'compagnieId': 'comar-assurance',
      'compagnieNom': 'COMAR Assurance',
    },
    {
      'id': 'admin_gat_urgent',
      'email': 'admin.gat@assurance.tn',
      'compagnieId': 'gat-assurance',
      'compagnieNom': 'GAT Assurance',
    },
    {
      'id': 'admin_maghrebia_urgent',
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
        'created_by': 'urgent_script',
        'source': 'emergency_creation',
        'isLegitimate': true,
        'isActive': true,
        'emergency_created': true,
      };

      await firestore
          .collection('users')
          .doc(admin['id']!)
          .set(adminData, SetOptions(merge: true));

      print('✅ ${admin['email']} créé avec succès');
      created++;
      
    } catch (e) {
      print('❌ Erreur pour ${admin['email']}: $e');
    }
  }
  
  print('📊 Résultat: $created/${admins.length} admins créés');
  
  // Vérifier la création
  try {
    final snapshot = await firestore.collection('users').get();
    print('📋 Total documents dans users: ${snapshot.docs.length}');
    
    final adminCompagnies = snapshot.docs
        .where((doc) => doc.data()['role'] == 'admin_compagnie')
        .toList();
    
    print('👥 Admin compagnies trouvés: ${adminCompagnies.length}');
    for (final doc in adminCompagnies) {
      final data = doc.data();
      print('  - ${data['email']} (${data['compagnieNom']})');
    }
    
  } catch (e) {
    print('❌ Erreur vérification: $e');
  }
}

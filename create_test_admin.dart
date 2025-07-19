import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// 🚀 Script pour créer rapidement un Admin Compagnie de test
void main() async {
  print('🚀 Création d\'Admin Compagnie de test...');
  
  try {
    // Initialiser Firebase
    await Firebase.initializeApp();
    final firestore = FirebaseFirestore.instance;
    
    // Données de test
    const compagnieId = 'star_assurance';
    const compagnieNom = 'STAR Assurance';
    const adminEmail = 'admin.star@assurance.tn';
    const adminPassword = 'Star123';
    
    print('📝 Création de la compagnie: $compagnieNom');
    
    // 1. Créer la compagnie
    await firestore
        .collection('compagnies_assurance')
        .doc(compagnieId)
        .set({
      'nom': compagnieNom,
      'code': 'STAR',
      'status': 'actif',
      'created_at': FieldValue.serverTimestamp(),
      'created_by': 'test_script',
      'adresse': 'Avenue Habib Bourguiba, Tunis',
      'telephone': '+216 71 123 456',
      'email': adminEmail,
      'description': 'Compagnie d\'assurance STAR - Créée pour test',
    });
    
    print('👤 Création de l\'admin: $adminEmail');
    
    // 2. Créer l'admin compagnie
    await firestore
        .collection('users')
        .doc('admin_star_test')
        .set({
      'uid': 'admin_star_test',
      'email': adminEmail,
      'nom': 'Admin',
      'prenom': 'STAR',
      'role': 'admin_compagnie',
      'status': 'actif',
      'isActive': true,
      'compagnieId': compagnieId,
      'compagnieNom': compagnieNom,
      
      // Mots de passe dans tous les champs possibles
      'password': adminPassword,
      'temporaryPassword': adminPassword,
      'motDePasseTemporaire': adminPassword,
      
      'created_at': FieldValue.serverTimestamp(),
      'created_by': 'test_script',
      'source': 'test_creation',
      'phone': '+216 71 123 456',
      'address': 'Tunis, Tunisie',
      'isLegitimate': true,
      'accountType': 'admin_system',
      'passwordChangeRequired': false,
    });
    
    print('✅ Admin Compagnie créé avec succès !');
    print('');
    print('🔑 IDENTIFIANTS DE CONNEXION:');
    print('📧 Email: $adminEmail');
    print('🔐 Mot de passe: $adminPassword');
    print('🏢 Compagnie: $compagnieNom');
    print('');
    print('🎯 Vous pouvez maintenant vous connecter avec ces identifiants !');
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

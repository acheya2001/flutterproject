import 'package:flutter/material.dart';
import 'lib/features/auth/models/user_model.dart';
import 'lib/utils/user_type.dart';

void main() {
  print('🧪 Test des corrections UserModel...');
  
  try {
    // Test création UserModel
    final user = UserModel(
      uid: 'test123',
      email: 'test@example.com',
      nom: 'Test',
      prenom: 'User',
      telephone: '+216 98 123 456',
      userType: UserType.conducteur,
      dateCreation: DateTime.now(),
    );
    
    print('✅ UserModel créé avec succès');
    print('   UID: ${user.uid}');
    print('   Email: ${user.email}');
    print('   Type: ${user.userType}');
    
    // Test toFirestore
    final firestore = user.toFirestore();
    print('✅ toFirestore() fonctionne');
    print('   Champs: ${firestore.keys.join(', ')}');
    
    // Test getters de compatibilité
    print('✅ Getters de compatibilité:');
    print('   id: ${user.id}');
    print('   type: ${user.type}');
    print('   createdAt: ${user.createdAt}');
    
    print('\n🎉 Tous les tests passent !');
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

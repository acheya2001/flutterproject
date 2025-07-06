import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // Initialiser Firebase
  await Firebase.initializeApp();
  
  final firestore = FirebaseFirestore.instance;
  
  // UID de l'utilisateur qui essaie de se connecter
  const String userUid = 'EdLj7lJtUHTE1qshIVC8iH0KISu2';
  
  try {
    // 1. Créer une compagnie d'assurance test
    await firestore.collection('insurance_companies').doc('star').set({
      'nom': 'STAR Assurances',
      'code': 'STAR',
      'statut': 'active',
      'adresse': 'Tunis, Tunisie',
      'telephone': '+216 71 123 456',
      'email': 'contact@star.tn',
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('✅ Compagnie STAR créée');
    
    // 2. Créer une agence test
    await firestore.collection('agences').doc('star_tunis_01').set({
      'nom': 'STAR Tunis Centre',
      'compagnie': 'STAR',
      'gouvernorat': 'Tunis',
      'adresse': 'Avenue Habib Bourguiba, Tunis',
      'telephone': '+216 71 234 567',
      'statut': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('✅ Agence STAR Tunis créée');
    
    // 3. Créer le profil assureur pour l'utilisateur
    await firestore.collection('assureurs').doc(userUid).set({
      'email': 'hammami123rahma@gmail.com',
      'nom': 'Hammami',
      'prenom': 'Rahma',
      'telephone': '+216 20 123 456',
      'compagnie': 'STAR',
      'matricule': 'STAR001',
      'agence': 'star_tunis_01',
      'poste': 'Agent Commercial',
      'permissions': ['view_contracts', 'create_contracts', 'manage_clients'],
      'dossierIds': [],
      'date_embauche': Timestamp.fromDate(DateTime(2024, 1, 15)),
      'statut': 'actif',
      'adresse': 'Tunis, Tunisie',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'derniere_connexion': null,
    });
    print('✅ Profil assureur créé pour UID: $userUid');
    
    // 4. Créer aussi un document dans la collection users
    await firestore.collection('users').doc(userUid).set({
      'email': 'hammami123rahma@gmail.com',
      'userType': 'assureur',
      'accountStatus': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('✅ Document users créé');
    
    print('\n🎉 Tous les documents de test ont été créés avec succès !');
    print('L\'utilisateur peut maintenant se connecter en tant qu\'agent d\'assurance.');
    
  } catch (e) {
    print('❌ Erreur lors de la création des documents: $e');
  }
}

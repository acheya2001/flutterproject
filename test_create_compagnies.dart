import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

/// 🏢 Script pour créer des compagnies d'assurance de test
void main() async {
  // Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  
  // Données des compagnies d'assurance tunisiennes
  final compagnies = [
    {
      'nom': 'STAR Assurances',
      'code': 'STAR',
      'adresse': 'Avenue Habib Bourguiba, Tunis',
      'ville': 'Tunis',
      'gouvernorat': 'Tunis',
      'telephone': '+216 71 123 456',
      'email': 'contact@star.tn',
      'siteWeb': 'www.star.tn',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'nom': 'Maghrebia Assurances',
      'code': 'MAGH',
      'adresse': 'Rue de la Liberté, Tunis',
      'ville': 'Tunis',
      'gouvernorat': 'Tunis',
      'telephone': '+216 71 234 567',
      'email': 'info@maghrebia.tn',
      'siteWeb': 'www.maghrebia.tn',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'nom': 'Assurances Salim',
      'code': 'SALIM',
      'adresse': 'Avenue Mohamed V, Sfax',
      'ville': 'Sfax',
      'gouvernorat': 'Sfax',
      'telephone': '+216 74 345 678',
      'email': 'contact@salim.tn',
      'siteWeb': 'www.salim.tn',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'nom': 'GAT Assurances',
      'code': 'GAT',
      'adresse': 'Rue Ibn Khaldoun, Sousse',
      'ville': 'Sousse',
      'gouvernorat': 'Sousse',
      'telephone': '+216 73 456 789',
      'email': 'info@gat.tn',
      'siteWeb': 'www.gat.tn',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'nom': 'BH Assurance',
      'code': 'BHA',
      'adresse': 'Avenue Bourguiba, Tunis',
      'ville': 'Tunis',
      'gouvernorat': 'Tunis',
      'telephone': '+216 71 567 890',
      'email': 'contact@bh-assurance.tn',
      'siteWeb': 'www.bh-assurance.tn',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
  ];

  try {
    print('🏢 Création des compagnies d\'assurance...');
    
    for (int i = 0; i < compagnies.length; i++) {
      final compagnie = compagnies[i];
      
      // Ajouter la compagnie à Firestore
      final docRef = await firestore
          .collection('compagnies_assurance')
          .add(compagnie);
      
      print('✅ Compagnie créée: ${compagnie['nom']} (ID: ${docRef.id})');
    }
    
    print('\n🎉 Toutes les compagnies ont été créées avec succès!');
    print('📊 Total: ${compagnies.length} compagnies');
    
  } catch (e) {
    print('❌ Erreur lors de la création des compagnies: $e');
  }
}

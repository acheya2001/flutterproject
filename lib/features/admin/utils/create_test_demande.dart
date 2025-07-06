import 'package:cloud_firestore/cloud_firestore.dart';

/// 🧪 Utilitaire pour créer une demande de test
class CreateTestDemande {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Créer une demande de test pour vérifier l'interface admin
  static Future<void> createTestDemande() async {
    try {
      final testDemande = {
        'email': 'test.agent@star.tn',
        'nom': 'Testeur',
        'prenom': 'Agent',
        'telephone': '+216 20 123 456',
        'compagnie': 'STAR Assurances',
        'agence': 'Agence Test Tunis',
        'gouvernorat': 'Tunis',
        'poste': 'Agent Commercial',
        'numeroAgent': 'TEST001',
        'userType': 'assureur',
        'statut': 'en_attente',
        'dateCreation': FieldValue.serverTimestamp(),
        'motDePasseTemporaire': 'test123',
      };

      await _firestore.collection('demandes_inscription').add(testDemande);
      print('✅ Demande de test créée avec succès !');
    } catch (e) {
      print('❌ Erreur création demande de test: $e');
    }
  }

  /// Créer plusieurs demandes de test
  static Future<void> createMultipleTestDemandes() async {
    final demandes = [
      {
        'email': 'agent1@star.tn',
        'nom': 'Ben Ali',
        'prenom': 'Mohamed',
        'telephone': '+216 20 111 111',
        'compagnie': 'STAR Assurances',
        'agence': 'Agence Tunis Centre',
        'gouvernorat': 'Tunis',
        'poste': 'Agent Commercial',
        'numeroAgent': 'STAR001',
        'userType': 'assureur',
        'statut': 'en_attente',
        'dateCreation': FieldValue.serverTimestamp(),
        'motDePasseTemporaire': 'password123',
      },
      {
        'email': 'agent2@gat.tn',
        'nom': 'Trabelsi',
        'prenom': 'Fatma',
        'telephone': '+216 20 222 222',
        'compagnie': 'GAT Assurances',
        'agence': 'Agence Sousse',
        'gouvernorat': 'Sousse',
        'poste': 'Conseiller Clientèle',
        'numeroAgent': 'GAT002',
        'userType': 'assureur',
        'statut': 'en_attente',
        'dateCreation': FieldValue.serverTimestamp(),
        'motDePasseTemporaire': 'password456',
      },
      {
        'email': 'agent3@bh.tn',
        'nom': 'Khelifi',
        'prenom': 'Ahmed',
        'telephone': '+216 20 333 333',
        'compagnie': 'BH Assurance',
        'agence': 'Agence Sfax',
        'gouvernorat': 'Sfax',
        'poste': 'Chargé de Sinistres',
        'numeroAgent': 'BH003',
        'userType': 'assureur',
        'statut': 'en_attente',
        'dateCreation': FieldValue.serverTimestamp(),
        'motDePasseTemporaire': 'password789',
      },
    ];

    try {
      for (final demande in demandes) {
        await _firestore.collection('demandes_inscription').add(demande);
      }
      print('✅ ${demandes.length} demandes de test créées avec succès !');
    } catch (e) {
      print('❌ Erreur création demandes de test: $e');
    }
  }

  /// Nettoyer toutes les demandes de test
  static Future<void> cleanTestDemandes() async {
    try {
      final query = await _firestore
          .collection('demandes_inscription')
          .where('email', whereIn: [
            'test.agent@star.tn',
            'agent1@star.tn',
            'agent2@gat.tn',
            'agent3@bh.tn',
          ])
          .get();

      for (final doc in query.docs) {
        await doc.reference.delete();
      }
      
      print('✅ Demandes de test nettoyées !');
    } catch (e) {
      print('❌ Erreur nettoyage: $e');
    }
  }
}

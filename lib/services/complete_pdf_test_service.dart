import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'complete_elegant_pdf_service.dart';

/// 🧪 Service de test pour le générateur PDF complet et élégant
/// Crée des données de test complètes avec plusieurs participants
class CompletePdfTestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🎯 Créer une session de test complète et générer le PDF
  static Future<String> creerSessionTestEtGenererPDF() async {
    try {
      print('🧪 [TEST PDF] Début création session de test complète');

      // 1. Créer une session de test avec ID unique
      final sessionId = 'test_session_${DateTime.now().millisecondsSinceEpoch}';
      
      // 2. Créer les données de la session principale
      await _creerSessionPrincipale(sessionId);
      
      // 3. Créer les participants avec formulaires complets
      await _creerParticipantsComplets(sessionId);
      
      // 4. Créer les signatures
      await _creerSignatures(sessionId);
      
      // 5. Créer le croquis
      await _creerCroquis(sessionId);
      
      // 6. Créer les photos
      await _creerPhotos(sessionId);
      
      print('✅ [TEST PDF] Session de test créée: $sessionId');
      
      // 7. Générer le PDF complet
      print('📄 [TEST PDF] Génération du PDF...');
      final pdfPath = await CompleteElegantPdfService.genererConstatCompletElegant(
        sessionId: sessionId,
      );
      
      print('✅ [TEST PDF] PDF généré avec succès: $pdfPath');
      return pdfPath;
      
    } catch (e) {
      print('❌ [TEST PDF] Erreur: $e');
      rethrow;
    }
  }

  /// 📋 Créer la session principale
  static Future<void> _creerSessionPrincipale(String sessionId) async {
    final sessionData = {
      'sessionCode': 'TEST_${sessionId.substring(sessionId.length - 6)}',
      'typeAccident': 'Accident collaboratif de test',
      'nombreVehicules': 3,
      'statut': 'en_cours',
      'conducteurCreateur': 'user_test_a',
      'dateCreation': Timestamp.now(),
      'dateModification': Timestamp.now(),
      'participants': [
        {
          'userId': 'user_test_a',
          'roleVehicule': 'A',
          'nom': 'Ben Ahmed',
          'prenom': 'Mohamed',
          'email': 'mohamed.benahmed@email.tn',
          'telephone': '+216 98 123 456',
          'estCreateur': true,
          'statut': 'signe',
          'formulaireStatus': 'termine',
        },
        {
          'userId': 'user_test_b',
          'roleVehicule': 'B',
          'nom': 'Trabelsi',
          'prenom': 'Fatma',
          'email': 'fatma.trabelsi@email.tn',
          'telephone': '+216 97 654 321',
          'estCreateur': false,
          'statut': 'signe',
          'formulaireStatus': 'termine',
        },
        {
          'userId': 'user_test_c',
          'roleVehicule': 'C',
          'nom': 'Khelifi',
          'prenom': 'Ahmed',
          'email': 'ahmed.khelifi@email.tn',
          'telephone': '+216 96 789 123',
          'estCreateur': false,
          'statut': 'en_cours',
          'formulaireStatus': 'en_cours',
        },
      ],
    };

    await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .set(sessionData);
  }

  /// 👥 Créer les participants avec formulaires complets
  static Future<void> _creerParticipantsComplets(String sessionId) async {
    // Participant A (Créateur)
    await _creerParticipant(sessionId, 'user_test_a', 'A', {
      'donneesPersonnelles': {
        'nom': 'Ben Ahmed',
        'prenom': 'Mohamed',
        'dateNaissance': '15/03/1985',
        'adresse': '123 Avenue Habib Bourguiba, Tunis 1000',
        'telephone': '+216 98 123 456',
        'email': 'mohamed.benahmed@email.tn',
        'cin': '12345678',
        'numeroPermis': 'TN123456789',
        'categoriePermis': 'B',
        'dateDelivrancePermis': '20/05/2005',
        'dateValiditePermis': '20/05/2025',
        'lieuDelivrancePermis': 'Tunis',
      },
      'donneesVehicule': {
        'marque': 'Peugeot',
        'modele': '308',
        'type': 'Berline',
        'immatriculation': '123 TUN 456',
        'annee': '2020',
        'couleur': 'Blanc',
        'puissance': '110 CV',
        'nombrePlaces': '5',
      },
      'donneesAssurance': {
        'compagnie': 'STAR Assurances',
        'agence': 'Agence Tunis Centre',
        'numeroPolice': 'STAR2024001234',
        'attestationDu': '01/01/2024',
        'attestationAu': '31/12/2024',
        'agent': 'Mme Leila Sassi',
        'telephoneAgent': '+216 71 123 456',
      },
      'circonstancesSelectionnees': [
        'Stationnait',
        'Sortait d\'un stationnement',
        'Roulait dans le même sens',
      ],
      'degats': {
        'description': 'Rayures sur le pare-chocs avant droit et phare endommagé',
        'pointImpact': 'Avant droit',
        'degatsVisibles': true,
      },
      'temoins': [
        {
          'nom': 'Mme Amina Bouaziz',
          'adresse': '456 Rue de la République, Tunis',
          'telephone': '+216 98 987 654',
        },
      ],
      'dateAccident': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'heureAccident': '14:30',
      'lieuAccident': 'Avenue Habib Bourguiba, devant la Banque Centrale',
      'lieuGps': {
        'latitude': 36.8065,
        'longitude': 10.1815,
      },
      'blesses': false,
      'aSigne': true,
    });

    // Participant B
    await _creerParticipant(sessionId, 'user_test_b', 'B', {
      'donneesPersonnelles': {
        'nom': 'Trabelsi',
        'prenom': 'Fatma',
        'dateNaissance': '22/08/1990',
        'adresse': '789 Rue Ibn Khaldoun, Sfax 3000',
        'telephone': '+216 97 654 321',
        'email': 'fatma.trabelsi@email.tn',
        'cin': '87654321',
        'numeroPermis': 'TN987654321',
        'categoriePermis': 'B',
        'dateDelivrancePermis': '10/12/2010',
        'dateValiditePermis': '10/12/2030',
        'lieuDelivrancePermis': 'Sfax',
      },
      'donneesVehicule': {
        'marque': 'Renault',
        'modele': 'Clio',
        'type': 'Citadine',
        'immatriculation': '789 TUN 123',
        'annee': '2019',
        'couleur': 'Rouge',
        'puissance': '90 CV',
        'nombrePlaces': '5',
      },
      'donneesAssurance': {
        'compagnie': 'AMI Assurances',
        'agence': 'Agence Sfax Nord',
        'numeroPolice': 'AMI2024005678',
        'attestationDu': '15/02/2024',
        'attestationAu': '14/02/2025',
        'agent': 'M. Karim Jemli',
        'telephoneAgent': '+216 74 987 654',
      },
      'circonstancesSelectionnees': [
        'Roulait dans le même sens',
        'Changeait de file',
        'Dépassait',
      ],
      'degats': {
        'description': 'Aile arrière gauche enfoncée et feu arrière cassé',
        'pointImpact': 'Arrière gauche',
        'degatsVisibles': true,
      },
      'temoins': [],
      'dateAccident': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'heureAccident': '14:30',
      'lieuAccident': 'Avenue Habib Bourguiba, devant la Banque Centrale',
      'lieuGps': {
        'latitude': 36.8065,
        'longitude': 10.1815,
      },
      'blesses': false,
      'aSigne': true,
    });

    // Participant C
    await _creerParticipant(sessionId, 'user_test_c', 'C', {
      'donneesPersonnelles': {
        'nom': 'Khelifi',
        'prenom': 'Ahmed',
        'dateNaissance': '05/11/1978',
        'adresse': '321 Avenue de la Liberté, Sousse 4000',
        'telephone': '+216 96 789 123',
        'email': 'ahmed.khelifi@email.tn',
        'cin': '11223344',
        'numeroPermis': 'TN112233445',
        'categoriePermis': 'B+E',
        'dateDelivrancePermis': '15/07/1998',
        'dateValiditePermis': '15/07/2028',
        'lieuDelivrancePermis': 'Sousse',
      },
      'donneesVehicule': {
        'marque': 'Mercedes',
        'modele': 'Sprinter',
        'type': 'Utilitaire',
        'immatriculation': '456 TUN 789',
        'annee': '2021',
        'couleur': 'Blanc',
        'puissance': '150 CV',
        'nombrePlaces': '3',
      },
      'donneesAssurance': {
        'compagnie': 'MAGHREBIA Assurances',
        'agence': 'Agence Sousse Centre',
        'numeroPolice': 'MAG2024009876',
        'attestationDu': '01/03/2024',
        'attestationAu': '28/02/2025',
        'agent': 'Mme Sonia Hamdi',
        'telephoneAgent': '+216 73 456 789',
      },
      'circonstancesSelectionnees': [
        'Roulait dans le même sens',
        'Suivait un autre véhicule',
      ],
      'degats': {
        'description': 'Pare-chocs avant légèrement rayé',
        'pointImpact': 'Avant centre',
        'degatsVisibles': true,
      },
      'temoins': [
        {
          'nom': 'M. Nabil Gharbi',
          'adresse': '654 Rue Mongi Slim, Sousse',
          'telephone': '+216 95 321 987',
        },
        {
          'nom': 'Mme Rim Bouzid',
          'adresse': '987 Avenue Tahar Sfar, Sousse',
          'telephone': '+216 94 159 753',
        },
      ],
      'dateAccident': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'heureAccident': '14:30',
      'lieuAccident': 'Avenue Habib Bourguiba, devant la Banque Centrale',
      'lieuGps': {
        'latitude': 36.8065,
        'longitude': 10.1815,
      },
      'blesses': false,
      'aSigne': false,
    });
  }

  /// 👤 Créer un participant individuel
  static Future<void> _creerParticipant(String sessionId, String userId, String roleVehicule, Map<String, dynamic> donneesFormulaire) async {
    await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .collection('participants_data')
        .doc(userId)
        .set({
      'donneesFormulaire': donneesFormulaire,
      'roleVehicule': roleVehicule,
      'etapeActuelle': '7',
      'statut': donneesFormulaire['aSigne'] == true ? 'termine' : 'en_cours',
      'dateCreation': Timestamp.now(),
      'dateModification': Timestamp.now(),
    });
  }

  /// ✍️ Créer les signatures
  static Future<void> _creerSignatures(String sessionId) async {
    // Signature A
    await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .collection('signatures')
        .doc('user_test_a')
        .set({
      'timestamp': Timestamp.now().toDate().toIso8601String(),
      'ip': '192.168.1.100',
      'device': 'Samsung Galaxy S21',
      'hash': 'abc123def456',
      'signatureData': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
    });

    // Signature B
    await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .collection('signatures')
        .doc('user_test_b')
        .set({
      'timestamp': Timestamp.now().toDate().toIso8601String(),
      'ip': '192.168.1.101',
      'device': 'iPhone 13',
      'hash': 'def456ghi789',
      'signatureData': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
    });
  }

  /// 🎨 Créer le croquis
  static Future<void> _creerCroquis(String sessionId) async {
    await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .collection('croquis')
        .doc('principal')
        .set({
      'source': 'collaborative_sketch',
      'dateCreation': Timestamp.now().toDate().toIso8601String(),
      'imageBase64': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
      'createdBy': 'user_test_a',
      'validatedBy': ['user_test_a', 'user_test_b'],
    });
  }

  /// 📸 Créer les photos
  static Future<void> _creerPhotos(String sessionId) async {
    await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .collection('photos')
        .doc('photo1')
        .set({
      'url': 'https://example.com/photo1.jpg',
      'description': 'Vue générale de l\'accident',
      'uploadedBy': 'user_test_a',
      'timestamp': Timestamp.now(),
    });

    await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .collection('photos')
        .doc('photo2')
        .set({
      'url': 'https://example.com/photo2.jpg',
      'description': 'Dégâts véhicule A',
      'uploadedBy': 'user_test_a',
      'timestamp': Timestamp.now(),
    });
  }

  /// 🧹 Nettoyer les données de test
  static Future<void> nettoyerDonneesTest() async {
    try {
      if (kDebugMode) {
        print('🧹 [TEST PDF] Nettoyage des données de test...');
        
        // Rechercher et supprimer toutes les sessions de test
        final sessionsTest = await _firestore
            .collection('sessions_collaboratives')
            .where('sessionCode', isGreaterThanOrEqualTo: 'TEST_')
            .where('sessionCode', isLessThan: 'TEST_z')
            .get();

        for (final doc in sessionsTest.docs) {
          await doc.reference.delete();
        }

        print('✅ [TEST PDF] ${sessionsTest.docs.length} sessions de test supprimées');
      }
    } catch (e) {
      print('❌ [TEST PDF] Erreur nettoyage: $e');
    }
  }
}

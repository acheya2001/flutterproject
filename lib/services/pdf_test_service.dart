import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'modern_tunisian_pdf_service.dart';

/// 🧪 Service de test pour la génération PDF améliorée
class PDFTestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🧪 Tester la génération PDF avec des données réelles
  static Future<String> testerGenerationPDF() async {
    try {
      print('🧪 [TEST] Début du test de génération PDF');

      // 1. Créer une session de test avec des données complètes
      final sessionId = await _creerSessionTest();
      print('✅ [TEST] Session de test créée: $sessionId');

      // 2. Générer le PDF avec le service amélioré
      final pdfUrl = await ModernTunisianPdfService.genererConstatModerne(
        sessionId: sessionId,
      );
      print('✅ [TEST] PDF généré avec succès: $pdfUrl');

      return pdfUrl;

    } catch (e) {
      print('❌ [TEST] Erreur lors du test: $e');
      rethrow;
    }
  }

  /// 📋 Créer une session de test avec des données complètes
  static Future<String> _creerSessionTest() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final sessionId = 'test_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    // Données de session complètes
    final sessionData = {
      'id': sessionId,
      'codeSession': 'TST${now.millisecondsSinceEpoch.toString().substring(8)}',
      'typeAccident': 'collaboratif',
      'statut': 'complete',
      'dateCreation': Timestamp.fromDate(now),
      'participants': [
        {
          'userId': user.uid,
          'nom': 'Conducteur Test A',
          'prenom': 'Ahmed',
          'role': 'conducteur_a',
          'vehiculeId': 'vehicule_a',
          'donneesFormulaire': _genererDonneesFormulaireTest('A'),
        },
        {
          'userId': 'user_test_b',
          'nom': 'Conducteur Test B', 
          'prenom': 'Mohamed',
          'role': 'conducteur_b',
          'vehiculeId': 'vehicule_b',
          'donneesFormulaire': _genererDonneesFormulaireTest('B'),
        },
      ],
      'donneesAccident': {
        'dateAccident': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
        'heureAccident': '14:30',
        'lieuAccident': 'Avenue Habib Bourguiba, Tunis',
        'blesses': false,
        'degatsAutres': false,
        'temoins': [
          {
            'nom': 'Témoin Test',
            'adresse': '123 Rue de la Paix, Tunis',
            'telephone': '+216 20 123 456',
          }
        ],
      },
    };

    // Sauvegarder la session
    await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .set(sessionData);

    // Créer les formulaires individuels
    await _creerFormulairesTest(sessionId, user.uid);

    // Créer un croquis de test
    await _creerCroquisTest(sessionId);

    // Créer des signatures de test
    await _creerSignaturesTest(sessionId, user.uid);

    return sessionId;
  }

  /// 📝 Générer des données de formulaire de test
  static Map<String, dynamic> _genererDonneesFormulaireTest(String vehicule) {
    return {
      'dateAccident': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      'heureAccident': '14:30',
      'lieuAccident': 'Avenue Habib Bourguiba, Tunis',
      'blesses': false,
      'temoins': [
        {
          'nom': 'Témoin Test $vehicule',
          'adresse': '123 Rue Test, Tunis',
          'telephone': '+216 20 123 456',
        }
      ],
      'vehiculeSelectionne': {
        'immatriculation': '123 TUN ${vehicule}456',
        'marque': vehicule == 'A' ? 'Peugeot' : 'Renault',
        'modele': vehicule == 'A' ? '208' : 'Clio',
        'compagnieAssurance': vehicule == 'A' ? 'STAR' : 'GAT',
        'numeroContrat': 'CNT${vehicule}123456',
        'dateDebutValidite': DateTime(2024, 1, 1).toIso8601String(),
        'dateFinValidite': DateTime(2024, 12, 31).toIso8601String(),
      },
      'conducteur': {
        'nom': 'Conducteur Test $vehicule',
        'prenom': vehicule == 'A' ? 'Ahmed' : 'Mohamed',
        'dateNaissance': '1985-05-15',
        'numeroPermis': 'P${vehicule}123456',
        'dateDelivrancePermis': DateTime(2010, 3, 20).toIso8601String(),
      },
      'pointChocSelectionne': vehicule == 'A' ? 'Avant droit' : 'Avant gauche',
      'degatsSelectionnes': [
        vehicule == 'A' ? 'Pare-choc avant' : 'Aile avant',
        vehicule == 'A' ? 'Phare droit' : 'Phare gauche',
      ],
      'circonstancesSelectionnees': [
        vehicule == 'A' ? 'roulait' : 'virait_gauche',
        vehicule == 'A' ? 'venait_droite' : 'ignorait_signal_arret',
      ],
      'observations': 'Accident survenu lors d\'un changement de direction. '
                     'Véhicule $vehicule ${vehicule == 'A' ? 'roulait normalement' : 'tournait à gauche'}.',
      'remarques': 'Conditions météo: ensoleillé. Chaussée sèche.',
    };
  }

  /// 📝 Créer les formulaires de test
  static Future<void> _creerFormulairesTest(String sessionId, String userId) async {
    // Formulaire pour conducteur A
    await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .collection('participants_data')
        .doc(userId)
        .set({
      'donneesFormulaire': _genererDonneesFormulaireTest('A'),
      'dateCreation': Timestamp.now(),
    });

    // Formulaire pour conducteur B
    await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .collection('participants_data')
        .doc('user_test_b')
        .set({
      'donneesFormulaire': _genererDonneesFormulaireTest('B'),
      'dateCreation': Timestamp.now(),
    });
  }

  /// 🎨 Créer un croquis de test
  static Future<void> _creerCroquisTest(String sessionId) async {
    await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .collection('croquis')
        .doc('croquis_test')
        .set({
      'imageUrl': 'https://example.com/croquis_test.png',
      'dateCreation': Timestamp.now(),
      'validePar': ['user_a', 'user_b'],
      'description': 'Croquis de test montrant la collision',
    });
  }

  /// ✍️ Créer des signatures de test
  static Future<void> _creerSignaturesTest(String sessionId, String userId) async {
    // Signature base64 de test (petit carré noir)
    const signatureTestBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

    // Signature conducteur A
    await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .collection('signatures')
        .doc(userId)
        .set({
      'signatureBase64': signatureTestBase64,
      'dateSignature': Timestamp.now(),
      'nomConducteur': 'Ahmed Conducteur Test A',
    });

    // Signature conducteur B
    await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .collection('signatures')
        .doc('user_test_b')
        .set({
      'signatureBase64': signatureTestBase64,
      'dateSignature': Timestamp.now(),
      'nomConducteur': 'Mohamed Conducteur Test B',
    });
  }

  /// 🧹 Nettoyer les données de test
  static Future<void> nettoyerDonneesTest() async {
    try {
      // Supprimer les sessions de test (plus anciennes que 1 heure)
      final cutoff = DateTime.now().subtract(const Duration(hours: 1));
      final sessions = await _firestore
          .collection('sessions_collaboratives')
          .where('dateCreation', isLessThan: Timestamp.fromDate(cutoff))
          .get();

      for (final doc in sessions.docs) {
        if (doc.id.startsWith('test_')) {
          await doc.reference.delete();
          print('🧹 [TEST] Session de test supprimée: ${doc.id}');
        }
      }

      print('✅ [TEST] Nettoyage terminé');
    } catch (e) {
      print('❌ [TEST] Erreur lors du nettoyage: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🔍 Service de débogage pour les signatures
class SignatureDebugService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _sessionsCollection = 'sessions_collaboratives';

  /// 🔍 Déboguer les signatures d'une session
  static Future<void> debugSignatures(String sessionId) async {
    try {
      print('🔍 [DEBUG] === DÉBUT DEBUG SIGNATURES ===');
      print('🔍 [DEBUG] Session ID: $sessionId');
      print('🔍 [DEBUG] Collection: $_sessionsCollection');

      // 1. Vérifier que la session existe
      final sessionDoc = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        print('❌ [DEBUG] Session non trouvée: $sessionId');
        return;
      }

      print('✅ [DEBUG] Session trouvée');
      final sessionData = sessionDoc.data()!;
      
      // 2. Afficher les participants
      final participants = sessionData['participants'] as List<dynamic>? ?? [];
      print('🔍 [DEBUG] Participants: ${participants.length}');
      for (final participant in participants) {
        print('🔍 [DEBUG] - Participant: ${participant['userId']} - Statut: ${participant['statut']}');
      }

      // 3. Vérifier la sous-collection signatures
      final signaturesSnapshot = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection('signatures')
          .get();

      print('🔍 [DEBUG] Signatures dans sous-collection: ${signaturesSnapshot.docs.length}');
      
      for (final doc in signaturesSnapshot.docs) {
        final data = doc.data();
        print('🔍 [DEBUG] - Signature: ${doc.id}');
        print('🔍 [DEBUG]   - userId: ${data['userId']}');
        print('🔍 [DEBUG]   - roleVehicule: ${data['roleVehicule']}');
        print('🔍 [DEBUG]   - dateSignature: ${data['dateSignature']}');
        print('🔍 [DEBUG]   - taille base64: ${data['signatureBase64']?.length ?? 0}');
      }

      // 4. Vérifier la progression
      final progression = sessionData['progression'] as Map<String, dynamic>? ?? {};
      print('🔍 [DEBUG] Progression: $progression');

      print('🔍 [DEBUG] === FIN DEBUG SIGNATURES ===');

    } catch (e) {
      print('❌ [DEBUG] Erreur debug signatures: $e');
      print('❌ [DEBUG] Stack trace: ${StackTrace.current}');
    }
  }

  /// 🧪 Tester l'ajout d'une signature
  static Future<void> testAjoutSignature(String sessionId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ [TEST] Utilisateur non connecté');
        return;
      }

      print('🧪 [TEST] Test ajout signature pour session: $sessionId');
      print('🧪 [TEST] Utilisateur: ${user.uid}');

      // Créer une signature de test
      final signatureData = {
        'userId': user.uid,
        'roleVehicule': 'conducteur_a',
        'signatureBase64': 'TEST_SIGNATURE_BASE64_DATA',
        'dateSignature': Timestamp.fromDate(DateTime.now()),
        'dateCreation': DateTime.now().toIso8601String(),
        'isTest': true,
      };

      // Sauvegarder directement
      await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection('signatures')
          .doc('${user.uid}_test')
          .set(signatureData);

      print('✅ [TEST] Signature de test ajoutée');

      // Vérifier immédiatement
      final testDoc = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection('signatures')
          .doc('${user.uid}_test')
          .get();

      if (testDoc.exists) {
        print('✅ [TEST] Signature de test vérifiée');
        
        // Supprimer la signature de test
        await testDoc.reference.delete();
        print('✅ [TEST] Signature de test supprimée');
      } else {
        print('❌ [TEST] Signature de test non trouvée');
      }

    } catch (e) {
      print('❌ [TEST] Erreur test signature: $e');
    }
  }

  /// 🔧 Réparer les signatures manquantes
  static Future<void> repererSignatures(String sessionId) async {
    try {
      print('🔧 [REPAIR] Début réparation signatures pour: $sessionId');

      // Récupérer la session
      final sessionDoc = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        print('❌ [REPAIR] Session non trouvée');
        return;
      }

      final sessionData = sessionDoc.data()!;
      final participants = sessionData['participants'] as List<dynamic>? ?? [];

      // Vérifier chaque participant qui devrait avoir signé
      for (final participant in participants) {
        final userId = participant['userId'] as String;
        final statut = participant['statut'] as String?;
        
        if (statut == 'signe' || statut == 'termine') {
          // Vérifier si la signature existe
          final signatureDoc = await _firestore
              .collection(_sessionsCollection)
              .doc(sessionId)
              .collection('signatures')
              .doc(userId)
              .get();

          if (!signatureDoc.exists) {
            print('🔧 [REPAIR] Signature manquante pour: $userId');
            
            // Créer une signature de récupération
            await _firestore
                .collection(_sessionsCollection)
                .doc(sessionId)
                .collection('signatures')
                .doc(userId)
                .set({
              'userId': userId,
              'roleVehicule': 'conducteur_a', // Par défaut
              'signatureBase64': 'SIGNATURE_RECUPEREE',
              'dateSignature': Timestamp.fromDate(DateTime.now()),
              'dateCreation': DateTime.now().toIso8601String(),
              'isRecovered': true,
            });
            
            print('✅ [REPAIR] Signature de récupération créée pour: $userId');
          }
        }
      }

      print('✅ [REPAIR] Réparation terminée');

    } catch (e) {
      print('❌ [REPAIR] Erreur réparation: $e');
    }
  }
}

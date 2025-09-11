import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/collaborative_session_model.dart';

/// 🔄 Service de synchronisation des données communes pour sessions collaboratives
class CollaborativeDataSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _sessionsCollection = 'sessions_collaboratives';

  /// 📝 Sauvegarder les données communes (remplies par le créateur A)
  static Future<void> sauvegarderDonneesCommunes({
    required String sessionId,
    required Map<String, dynamic> donneesCommunes,
  }) async {
    try {
      print('🔄 [SYNC] Sauvegarde données communes pour session: $sessionId');
      
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'donneesCommunes': {
          ...donneesCommunes,
          'dateModification': DateTime.now().toIso8601String(),
          'modifiePar': FirebaseAuth.instance.currentUser?.uid,
        },
      });
      
      print('✅ [SYNC] Données communes sauvegardées');
    } catch (e) {
      print('❌ [SYNC] Erreur sauvegarde données communes: $e');
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }

  /// 📡 Stream des données communes en temps réel
  static Stream<Map<String, dynamic>?> streamDonneesCommunes(String sessionId) {
    return _firestore
        .collection(_sessionsCollection)
        .doc(sessionId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return doc.data()!['donneesCommunes'] as Map<String, dynamic>?;
      }
      return null;
    });
  }

  /// 🔍 Récupérer les données communes
  static Future<Map<String, dynamic>?> recupererDonneesCommunes(String sessionId) async {
    try {
      final doc = await _firestore.collection(_sessionsCollection).doc(sessionId).get();
      
      if (doc.exists && doc.data() != null) {
        return doc.data()!['donneesCommunes'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('❌ [SYNC] Erreur récupération données communes: $e');
      return null;
    }
  }

  /// 👤 Mettre à jour le statut d'un participant
  static Future<void> mettreAJourStatutParticipant({
    required String sessionId,
    required String participantId,
    required FormulaireStatus nouveauStatut,
  }) async {
    try {
      print('🔄 [SYNC] Mise à jour statut participant: $participantId -> $nouveauStatut');
      
      final sessionDoc = await _firestore.collection(_sessionsCollection).doc(sessionId).get();
      
      if (!sessionDoc.exists) {
        throw Exception('Session non trouvée');
      }
      
      final sessionData = sessionDoc.data()!;
      final participants = List<Map<String, dynamic>>.from(sessionData['participants'] ?? []);
      
      // Trouver et mettre à jour le participant
      for (int i = 0; i < participants.length; i++) {
        if (participants[i]['userId'] == participantId) {
          participants[i]['formulaireStatus'] = nouveauStatut.name;
          participants[i]['formulaireComplete'] = nouveauStatut == FormulaireStatus.termine;
          if (nouveauStatut == FormulaireStatus.termine) {
            participants[i]['dateFormulaireFini'] = DateTime.now().toIso8601String();
            participants[i]['statut'] = 'formulaire_fini';
          }
          break;
        }
      }
      
      // Calculer la nouvelle progression
      final progression = _calculerProgression(participants);
      
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'participants': participants,
        'progression': progression,
        'dateModification': DateTime.now().toIso8601String(),
      });
      
      print('✅ [SYNC] Statut participant mis à jour');
    } catch (e) {
      print('❌ [SYNC] Erreur mise à jour statut: $e');
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  /// 📊 Calculer la progression de la session
  static Map<String, dynamic> _calculerProgression(List<Map<String, dynamic>> participants) {
    int participantsRejoints = 0;
    int formulairesTermines = 0;
    int croquisValides = 0;
    int signaturesEffectuees = 0;

    for (final participant in participants) {
      final statut = participant['statut'] as String?;
      final formulaireStatus = participant['formulaireStatus'] as String?;
      final aRejoint = participant['aRejoint'] as bool? ?? false;
      final formulaireComplete = participant['formulaireComplete'] as bool? ?? false;
      final croquisValide = participant['croquisValide'] as bool? ?? false;
      final aSigne = participant['aSigne'] as bool? ?? false;

      // Compter les participants qui ont rejoint
      if (aRejoint || statut == 'rejoint' || statut == 'formulaire_fini' || statut == 'signe') {
        participantsRejoints++;
      }

      // Compter les formulaires terminés
      if (formulaireComplete || formulaireStatus == 'termine' || statut == 'formulaire_fini' || statut == 'signe') {
        formulairesTermines++;
      }

      // Compter les croquis validés
      if (croquisValide || statut == 'croquis_valide' || statut == 'signe') {
        croquisValides++;
      }

      // Compter les signatures
      if (aSigne || statut == 'signe') {
        signaturesEffectuees++;
      }
    }
    
    final peutFinaliser = formulairesTermines == participants.length && 
                         croquisValides == participants.length;
    
    return {
      'participantsRejoints': participantsRejoints,
      'formulairesTermines': formulairesTermines,
      'croquisValides': croquisValides,
      'signaturesEffectuees': signaturesEffectuees,
      'croquisCree': true, // Sera géré par le service de croquis
      'peutFinaliser': peutFinaliser,
    };
  }

  /// 🎨 Sauvegarder le croquis collaboratif
  static Future<void> sauvegarderCroquis({
    required String sessionId,
    required Map<String, dynamic> croquisData,
  }) async {
    try {
      print('🔄 [SYNC] Sauvegarde croquis pour session: $sessionId');
      
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'croquis': {
          ...croquisData,
          'dateModification': DateTime.now().toIso8601String(),
          'creePar': FirebaseAuth.instance.currentUser?.uid,
        },
      });
      
      print('✅ [SYNC] Croquis sauvegardé');
    } catch (e) {
      print('❌ [SYNC] Erreur sauvegarde croquis: $e');
      throw Exception('Erreur lors de la sauvegarde du croquis: $e');
    }
  }

  /// 🎨 Stream du croquis en temps réel
  static Stream<Map<String, dynamic>?> streamCroquis(String sessionId) {
    return _firestore
        .collection(_sessionsCollection)
        .doc(sessionId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return doc.data()!['croquis'] as Map<String, dynamic>?;
      }
      return null;
    });
  }

  /// ✅ Valider le croquis par un participant
  static Future<void> validerCroquis({
    required String sessionId,
    required String participantId,
    required bool accepte,
    String? commentaire,
  }) async {
    try {
      print('🔄 [SYNC] Validation croquis par: $participantId -> $accepte');
      
      final validationData = {
        'participantId': participantId,
        'accepte': accepte,
        'commentaire': commentaire,
        'dateValidation': DateTime.now().toIso8601String(),
      };
      
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'validationsCroquis.$participantId': validationData,
      });
      
      // Mettre à jour le statut du participant si accepté
      if (accepte) {
        await mettreAJourStatutParticipant(
          sessionId: sessionId,
          participantId: participantId,
          nouveauStatut: FormulaireStatus.termine,
        );
      }
      
      print('✅ [SYNC] Validation croquis enregistrée');
    } catch (e) {
      print('❌ [SYNC] Erreur validation croquis: $e');
      throw Exception('Erreur lors de la validation: $e');
    }
  }

  /// 📡 Stream de la session complète en temps réel
  static Stream<CollaborativeSession?> streamSession(String sessionId) {
    return _firestore
        .collection(_sessionsCollection)
        .doc(sessionId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return CollaborativeSession.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  /// 📋 Sauvegarder les données du formulaire d'un participant
  static Future<void> sauvegarderFormulaireParticipant({
    required String sessionId,
    required String participantId,
    required Map<String, dynamic> donneesFormulaire,
  }) async {
    try {
      print('🔄 [SYNC] Sauvegarde formulaire participant: $participantId');
      
      await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection('formulaires')
          .doc(participantId)
          .set({
        ...donneesFormulaire,
        'dateModification': DateTime.now().toIso8601String(),
        'participantId': participantId,
      }, SetOptions(merge: true));
      
      print('✅ [SYNC] Formulaire participant sauvegardé');
    } catch (e) {
      print('❌ [SYNC] Erreur sauvegarde formulaire: $e');
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }

  /// 📖 Récupérer le formulaire d'un participant
  static Future<Map<String, dynamic>?> recupererFormulaireParticipant({
    required String sessionId,
    required String participantId,
  }) async {
    try {
      final doc = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection('formulaires')
          .doc(participantId)
          .get();
      
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('❌ [SYNC] Erreur récupération formulaire: $e');
      return null;
    }
  }

  /// 📡 Stream des formulaires de tous les participants
  static Stream<List<Map<String, dynamic>>> streamTousLesFormulaires(String sessionId) {
    return _firestore
        .collection(_sessionsCollection)
        .doc(sessionId)
        .collection('formulaires')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    });
  }
}

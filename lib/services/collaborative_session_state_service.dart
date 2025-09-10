import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/collaborative_session_model.dart';

/// 🔄 Service pour gérer les états des sessions collaboratives
class CollaborativeSessionStateService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 💾 Sauvegarder l'état du formulaire d'un participant
  static Future<void> sauvegarderEtatFormulaire({
    required String sessionId,
    required String participantId,
    required Map<String, dynamic> donneesFormulaire,
    required String etapeActuelle,
    required List<bool> etapesValidees,
  }) async {
    try {
      await _firestore
          .collection('collaborative_sessions')
          .doc(sessionId)
          .collection('participants_data')
          .doc(participantId)
          .set({
        'donneesFormulaire': donneesFormulaire,
        'etapeActuelle': etapeActuelle,
        'etapesValidees': etapesValidees,
        'statut': _determinerStatut(etapesValidees),
        'derniereMiseAJour': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ État formulaire sauvegardé pour participant $participantId');
    } catch (e) {
      print('❌ Erreur sauvegarde état formulaire: $e');
      throw e;
    }
  }

  /// 📥 Charger l'état du formulaire d'un participant
  static Future<Map<String, dynamic>?> chargerEtatFormulaire({
    required String sessionId,
    required String participantId,
  }) async {
    try {
      final doc = await _firestore
          .collection('collaborative_sessions')
          .doc(sessionId)
          .collection('participants_data')
          .doc(participantId)
          .get();

      if (doc.exists) {
        print('✅ État formulaire chargé pour participant $participantId');
        return doc.data();
      }
      return null;
    } catch (e) {
      print('❌ Erreur chargement état formulaire: $e');
      return null;
    }
  }

  /// 📋 Obtenir tous les formulaires des participants d'une session
  static Future<Map<String, Map<String, dynamic>>> obtenirTousLesFormulaires({
    required String sessionId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('collaborative_sessions')
          .doc(sessionId)
          .collection('participants_data')
          .get();

      final Map<String, Map<String, dynamic>> formulaires = {};
      
      for (final doc in snapshot.docs) {
        formulaires[doc.id] = doc.data();
      }

      print('✅ ${formulaires.length} formulaires chargés pour session $sessionId');
      return formulaires;
    } catch (e) {
      print('❌ Erreur chargement formulaires: $e');
      return {};
    }
  }

  /// 🔍 Vérifier si un participant peut consulter les autres formulaires
  static Future<bool> peutConsulterAutresFormulaires({
    required String sessionId,
    required String participantId,
  }) async {
    try {
      // Vérifier que le participant a terminé son formulaire
      final etatParticipant = await chargerEtatFormulaire(
        sessionId: sessionId,
        participantId: participantId,
      );

      if (etatParticipant == null) return false;

      final statut = etatParticipant['statut'] ?? 'en_cours';
      return statut == 'termine';
    } catch (e) {
      print('❌ Erreur vérification consultation: $e');
      return false;
    }
  }

  /// 📊 Obtenir le statut global de la session
  static Future<Map<String, dynamic>> obtenirStatutSession({
    required String sessionId,
  }) async {
    try {
      // Charger la session
      final sessionDoc = await _firestore
          .collection('collaborative_sessions')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        throw Exception('Session non trouvée');
      }

      final sessionData = sessionDoc.data()!;
      final participants = List<String>.from(sessionData['participants'] ?? []);

      // Charger les états de tous les participants
      final formulaires = await obtenirTousLesFormulaires(sessionId: sessionId);

      int termines = 0;
      int enCours = 0;
      int nonCommences = 0;

      for (final participantId in participants) {
        final formulaire = formulaires[participantId];
        if (formulaire == null) {
          nonCommences++;
        } else {
          final statut = formulaire['statut'] ?? 'en_cours';
          switch (statut) {
            case 'termine':
              termines++;
              break;
            case 'en_cours':
              enCours++;
              break;
            default:
              nonCommences++;
          }
        }
      }

      final bool tousTermines = termines == participants.length;
      final bool sessionComplete = tousTermines && participants.isNotEmpty;

      return {
        'totalParticipants': participants.length,
        'termines': termines,
        'enCours': enCours,
        'nonCommences': nonCommences,
        'tousTermines': tousTermines,
        'sessionComplete': sessionComplete,
        'pourcentageCompletion': participants.isEmpty ? 0 : (termines / participants.length * 100).round(),
      };
    } catch (e) {
      print('❌ Erreur statut session: $e');
      return {
        'totalParticipants': 0,
        'termines': 0,
        'enCours': 0,
        'nonCommences': 0,
        'tousTermines': false,
        'sessionComplete': false,
        'pourcentageCompletion': 0,
      };
    }
  }

  /// 🔄 Stream pour suivre les changements d'état en temps réel
  static Stream<Map<String, dynamic>> suivreStatutSession({
    required String sessionId,
  }) {
    return _firestore
        .collection('collaborative_sessions')
        .doc(sessionId)
        .collection('participants_data')
        .snapshots()
        .asyncMap((_) async {
      return await obtenirStatutSession(sessionId: sessionId);
    });
  }

  /// 🎯 Marquer un participant comme ayant terminé
  static Future<void> marquerParticipantTermine({
    required String sessionId,
    required String participantId,
  }) async {
    try {
      await _firestore
          .collection('collaborative_sessions')
          .doc(sessionId)
          .collection('participants_data')
          .doc(participantId)
          .update({
        'statut': 'termine',
        'dateTerminaison': FieldValue.serverTimestamp(),
      });

      print('✅ Participant $participantId marqué comme terminé');
    } catch (e) {
      print('❌ Erreur marquage terminé: $e');
      throw e;
    }
  }

  /// 🔧 Déterminer le statut basé sur les étapes validées
  static String _determinerStatut(List<bool> etapesValidees) {
    if (etapesValidees.isEmpty) return 'non_commence';
    
    final nombreEtapesValidees = etapesValidees.where((validee) => validee).length;
    final nombreTotalEtapes = etapesValidees.length;
    
    if (nombreEtapesValidees == 0) return 'non_commence';
    if (nombreEtapesValidees == nombreTotalEtapes) return 'termine';
    return 'en_cours';
  }

  /// 🗑️ Nettoyer les données d'une session expirée
  static Future<void> nettoyerSessionExpiree({
    required String sessionId,
  }) async {
    try {
      // Supprimer toutes les données des participants
      final participantsSnapshot = await _firestore
          .collection('collaborative_sessions')
          .doc(sessionId)
          .collection('participants_data')
          .get();

      final batch = _firestore.batch();
      for (final doc in participantsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Supprimer la session elle-même
      batch.delete(_firestore.collection('collaborative_sessions').doc(sessionId));

      await batch.commit();
      print('✅ Session $sessionId nettoyée');
    } catch (e) {
      print('❌ Erreur nettoyage session: $e');
      throw e;
    }
  }

  /// 📱 Sauvegarder automatiquement en sortant du formulaire
  static Future<void> sauvegardeAutomatiqueEnSortie({
    required String sessionId,
    required Map<String, dynamic> donneesFormulaire,
    required String etapeActuelle,
    required List<bool> etapesValidees,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await sauvegarderEtatFormulaire(
        sessionId: sessionId,
        participantId: user.uid,
        donneesFormulaire: donneesFormulaire,
        etapeActuelle: etapeActuelle,
        etapesValidees: etapesValidees,
      );

      print('✅ Sauvegarde automatique en sortie effectuée');
    } catch (e) {
      print('❌ Erreur sauvegarde automatique en sortie: $e');
    }
  }
}

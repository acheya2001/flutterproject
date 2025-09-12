import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/collaborative_session_model.dart';

/// 🔄 Service de synchronisation des données communes pour sessions collaboratives
class CollaborativeDataSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _sessionsCollection = 'sessions_collaboratives';
  static const Uuid _uuid = Uuid();

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
      
      // Calculer la nouvelle progression avec comptage réel des signatures
      final progression = await calculerProgression(sessionId, participants);

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
  static Future<Map<String, dynamic>> calculerProgression(String sessionId, List<Map<String, dynamic>> participants) async {
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

      // Compter les participants qui ont rejoint
      if (aRejoint || statut == 'rejoint' || statut == 'formulaire_fini' || statut == 'signe') {
        participantsRejoints++;
      }

      // Compter les formulaires terminés
      if (formulaireComplete || formulaireStatus == 'termine' || statut == 'formulaire_fini' || statut == 'signe') {
        formulairesTermines++;
      }

    }

    // 🔥 Compter les validations de croquis réelles depuis Firestore
    try {
      final sessionDoc = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .get();

      if (sessionDoc.exists) {
        final sessionData = sessionDoc.data()!;
        final validationsCroquis = sessionData['validationsCroquis'] as Map<String, dynamic>? ?? {};

        // Compter les validations acceptées
        croquisValides = validationsCroquis.values
            .where((validation) => validation['accepte'] == true)
            .length;
        print('📊 [SYNC] Validations croquis comptées: $croquisValides');
      }
    } catch (e) {
      print('❌ [SYNC] Erreur comptage validations croquis: $e');
      // Fallback: compter depuis les statuts des participants
      for (final participant in participants) {
        final statut = participant['statut'] as String?;
        final croquisValide = participant['croquisValide'] as bool? ?? false;
        if (croquisValide || statut == 'croquis_valide' || statut == 'signe') {
          croquisValides++;
        }
      }
    }

    // 🔥 Compter les signatures réelles depuis la sous-collection
    try {
      print('🔍 [SYNC] Comptage signatures pour session: $sessionId');
      print('🔍 [SYNC] Collection: $_sessionsCollection');

      final signaturesSnapshot = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection('signatures')
          .get();

      signaturesEffectuees = signaturesSnapshot.docs.length;
      print('📊 [SYNC] Signatures trouvées dans sous-collection: $signaturesEffectuees');

      // Debug: afficher les signatures trouvées
      for (final doc in signaturesSnapshot.docs) {
        final data = doc.data();
        print('🔍 [SYNC] Signature trouvée: ${doc.id} - userId: ${data['userId']} - role: ${data['roleVehicule']}');
      }

    } catch (e) {
      print('❌ [SYNC] Erreur comptage signatures: $e');
      print('❌ [SYNC] Stack trace: ${StackTrace.current}');

      // Fallback: compter depuis les statuts des participants
      print('🔄 [SYNC] Fallback: comptage depuis statuts participants');
      for (final participant in participants) {
        final statut = participant['statut'] as String?;
        final aSigne = participant['aSigne'] as bool? ?? false;
        print('🔍 [SYNC] Participant ${participant['userId']}: statut=$statut, aSigne=$aSigne');
        if (aSigne || statut == 'signe') {
          signaturesEffectuees++;
        }
      }
      print('📊 [SYNC] Signatures comptées (fallback): $signaturesEffectuees');
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

  /// 📊 Calculer la progression de la session (version synchrone pour compatibilité)
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

      // Compter les signatures (fallback)
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

      // Sauvegarder la validation
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'validationsCroquis.$participantId': validationData,
      });

      // Recalculer la progression avec les nouvelles validations
      final sessionDoc = await _firestore.collection(_sessionsCollection).doc(sessionId).get();
      if (sessionDoc.exists) {
        final sessionData = sessionDoc.data()!;
        final participants = List<Map<String, dynamic>>.from(sessionData['participants'] ?? []);

        // Calculer la nouvelle progression
        final progression = await calculerProgression(sessionId, participants);

        // Mettre à jour la progression
        await _firestore.collection(_sessionsCollection).doc(sessionId).update({
          'progression': progression,
          'dateModification': DateTime.now().toIso8601String(),
        });

        print('✅ [SYNC] Progression mise à jour après validation croquis');
      }

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

  /// 👥 Ajouter un témoin partagé à la session
  static Future<void> ajouterTemoinPartage({
    required String sessionId,
    required String ajoutePar,
    required Map<String, dynamic> temoinData,
  }) async {
    try {
      print('🔄 [SYNC] Ajout témoin partagé par: $ajoutePar');

      final temoinId = _uuid.v4();
      final temoinComplet = {
        'id': temoinId,
        ...temoinData,
        'ajoutePar': ajoutePar,
        'dateAjout': DateTime.now().toIso8601String(),
      };

      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'temoinsPartages.$temoinId': temoinComplet,
        'dateModification': DateTime.now().toIso8601String(),
      });

      print('✅ [SYNC] Témoin partagé ajouté: $temoinId');
    } catch (e) {
      print('❌ [SYNC] Erreur ajout témoin: $e');
      throw Exception('Erreur lors de l\'ajout du témoin: $e');
    }
  }

  /// 👥 Supprimer un témoin partagé
  static Future<void> supprimerTemoinPartage({
    required String sessionId,
    required String temoinId,
    required String supprimePar,
  }) async {
    try {
      print('🔄 [SYNC] Suppression témoin partagé: $temoinId par $supprimePar');

      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'temoinsPartages.$temoinId': FieldValue.delete(),
        'dateModification': DateTime.now().toIso8601String(),
      });

      print('✅ [SYNC] Témoin partagé supprimé: $temoinId');
    } catch (e) {
      print('❌ [SYNC] Erreur suppression témoin: $e');
      throw Exception('Erreur lors de la suppression du témoin: $e');
    }
  }

  /// 👥 Écouter les témoins partagés en temps réel
  static Stream<Map<String, dynamic>> ecouterTemoinsPartages(String sessionId) {
    return _firestore
        .collection(_sessionsCollection)
        .doc(sessionId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return {};

      final data = snapshot.data()!;
      return Map<String, dynamic>.from(data['temoinsPartages'] ?? {});
    });
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



  /// 🎨 Obtenir les validations du croquis
  static Future<Map<String, dynamic>> obtenirValidationsCroquis({
    required String sessionId,
  }) async {
    try {
      final sessionDoc = await _firestore.collection(_sessionsCollection).doc(sessionId).get();

      if (!sessionDoc.exists) {
        throw Exception('Session non trouvée');
      }

      final data = sessionDoc.data() as Map<String, dynamic>;
      return data['validationsCroquis'] as Map<String, dynamic>? ?? {};

    } catch (e) {
      print('❌ [CROQUIS] Erreur récupération validations: $e');
      return {};
    }
  }

  /// 🎨 Écouter les validations du croquis en temps réel
  static Stream<Map<String, dynamic>> ecouterValidationsCroquis({
    required String sessionId,
  }) {
    return _firestore
        .collection(_sessionsCollection)
        .doc(sessionId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return {};

      final data = snapshot.data() as Map<String, dynamic>;
      return data['validationsCroquis'] as Map<String, dynamic>? ?? {};
    });
  }
}

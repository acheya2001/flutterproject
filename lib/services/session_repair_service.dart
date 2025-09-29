import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🔧 Service de réparation des sessions collaboratives
class SessionRepairService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔄 Réparer toutes les sessions avec des problèmes de comptage
  static Future<void> repairAllSessions() async {
    try {
      print('🔧 [REPAIR] Début de la réparation des sessions...');

      // Récupérer toutes les sessions collaboratives actives
      final sessionsQuery = await _firestore
          .collection('sessions_collaboratives')
          .where('statut', whereIn: ['creation', 'en_attente', 'en_cours', 'attente_participants'])
          .get();

      print('🔍 [REPAIR] ${sessionsQuery.docs.length} sessions trouvées');

      int sessionsReparees = 0;
      for (final sessionDoc in sessionsQuery.docs) {
        final sessionData = sessionDoc.data();
        final sessionId = sessionDoc.id;

        print('\n🔧 [REPAIR] Analyse session: $sessionId');
        
        if (await _repairSession(sessionId, sessionData)) {
          sessionsReparees++;
        }
      }

      print('\n✅ [REPAIR] Réparation terminée: $sessionsReparees sessions réparées');

    } catch (e) {
      print('❌ [REPAIR] Erreur lors de la réparation: $e');
      rethrow;
    }
  }

  /// 🔧 Réparer une session spécifique
  static Future<bool> _repairSession(String sessionId, Map<String, dynamic> sessionData) async {
    try {
      bool needsRepair = false;
      final updates = <String, dynamic>{};

      // 1. Vérifier et corriger la liste des participants
      List<dynamic> participants = List.from(sessionData['participants'] ?? []);
      final nombreVehicules = sessionData['nombreVehicules'] ?? 2;

      print('📊 [REPAIR] Session $sessionId: ${participants.length}/$nombreVehicules participants');

      // 2. Vérifier les participants invités non comptabilisés
      final participantsInvites = sessionData['participants_invites'] as List<dynamic>? ?? [];
      
      for (final invite in participantsInvites) {
        final inviteId = invite['participantId'] as String?;
        
        // Vérifier si cet invité est déjà dans la liste principale
        final dejaPresent = participants.any((p) => p['userId'] == inviteId);
        
        if (!dejaPresent && inviteId != null) {
          print('🔄 [REPAIR] Ajout participant invité manquant: ${invite['nom']} ${invite['prenom']}');
          
          participants.add({
            'userId': inviteId,
            'nom': invite['nom'] ?? 'Inconnu',
            'prenom': invite['prenom'] ?? '',
            'email': invite['email'] ?? '',
            'telephone': invite['telephone'] ?? '',
            'roleVehicule': invite['roleVehicule'] ?? 'B',
            'statut': 'formulaire_fini',
            'formulaireComplete': true,
            'formulaireStatus': 'termine',
            'dateRejoint': invite['dateParticipation'] ?? DateTime.now().toIso8601String(),
            'dateFormulaireFini': invite['dateParticipation'] ?? DateTime.now().toIso8601String(),
            'type': 'conducteur_non_inscrit',
            'estInvite': true,
          });
          
          needsRepair = true;
        }
      }

      // 3. Vérifier les formulaires terminés dans la sous-collection
      final formulairesQuery = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('formulaires')
          .get();

      for (final formulaireDoc in formulairesQuery.docs) {
        final formulaireData = formulaireDoc.data();
        final userId = formulaireDoc.id;
        
        if (formulaireData['complete'] == true) {
          // Vérifier si ce participant est dans la liste principale
          final participantIndex = participants.indexWhere((p) => p['userId'] == userId);
          
          if (participantIndex != -1) {
            // Mettre à jour le statut si nécessaire
            final participant = participants[participantIndex];
            if (participant['statut'] != 'formulaire_fini' || participant['formulaireComplete'] != true) {
              print('🔄 [REPAIR] Correction statut participant: $userId');
              participants[participantIndex] = {
                ...participant,
                'statut': 'formulaire_fini',
                'formulaireComplete': true,
                'formulaireStatus': 'termine',
                'dateFormulaireFini': DateTime.now().toIso8601String(),
              };
              needsRepair = true;
            }
          }
        }
      }

      // 4. Recalculer la progression
      if (needsRepair || sessionData['progression'] == null) {
        final participantsRejoints = participants.length;
        final formulairesTermines = participants.where((p) => 
          p['formulaireComplete'] == true || 
          p['statut'] == 'formulaire_fini' ||
          p['formulaireStatus'] == 'termine'
        ).length;

        final progression = {
          'participantsRejoints': participantsRejoints,
          'formulairesTermines': formulairesTermines,
          'pourcentage': participantsRejoints > 0 ? ((formulairesTermines / participantsRejoints) * 100).round() : 0,
        };

        // 5. Déterminer le nouveau statut
        String nouveauStatut = sessionData['statut'] ?? 'en_cours';
        
        if (participantsRejoints >= nombreVehicules) {
          if (formulairesTermines >= nombreVehicules) {
            nouveauStatut = 'validation_croquis';
          } else {
            nouveauStatut = 'en_cours';
          }
        } else {
          nouveauStatut = 'attente_participants';
        }

        updates.addAll({
          'participants': participants,
          'progression': progression,
          'statut': nouveauStatut,
          'dateModification': DateTime.now().toIso8601String(),
          'lastRepair': DateTime.now().toIso8601String(),
        });

        needsRepair = true;
        print('📊 [REPAIR] Nouvelle progression: $participantsRejoints/$nombreVehicules participants, $formulairesTermines formulaires terminés');
        print('🔄 [REPAIR] Nouveau statut: $nouveauStatut');
      }

      // 6. Appliquer les corrections
      if (needsRepair) {
        await _firestore
            .collection('sessions_collaboratives')
            .doc(sessionId)
            .update(updates);
        
        print('✅ [REPAIR] Session $sessionId réparée avec succès');
        return true;
      } else {
        print('✅ [REPAIR] Session $sessionId OK, aucune réparation nécessaire');
        return false;
      }

    } catch (e) {
      print('❌ [REPAIR] Erreur réparation session $sessionId: $e');
      return false;
    }
  }

  /// 🔍 Diagnostiquer une session spécifique
  static Future<Map<String, dynamic>> diagnosticSession(String sessionId) async {
    try {
      final sessionDoc = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        return {'error': 'Session non trouvée'};
      }

      final sessionData = sessionDoc.data()!;
      final participants = List.from(sessionData['participants'] ?? []);
      final participantsInvites = sessionData['participants_invites'] as List<dynamic>? ?? [];
      final nombreVehicules = sessionData['nombreVehicules'] ?? 2;
      final progression = sessionData['progression'] as Map<String, dynamic>? ?? {};

      // Compter les formulaires terminés dans la sous-collection
      final formulairesQuery = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('formulaires')
          .where('complete', isEqualTo: true)
          .get();

      return {
        'sessionId': sessionId,
        'statut': sessionData['statut'],
        'nombreVehicules': nombreVehicules,
        'participants': {
          'total': participants.length,
          'details': participants,
        },
        'participantsInvites': {
          'total': participantsInvites.length,
          'details': participantsInvites,
        },
        'formulairesTermines': {
          'dansProgression': progression['formulairesTermines'] ?? 0,
          'dansCollection': formulairesQuery.docs.length,
        },
        'progression': progression,
        'needsRepair': participants.length != (progression['participantsRejoints'] ?? 0) ||
                      formulairesQuery.docs.length != (progression['formulairesTermines'] ?? 0),
      };

    } catch (e) {
      return {'error': 'Erreur diagnostic: $e'};
    }
  }

  /// 🚀 Réparer une session spécifique (méthode publique)
  static Future<bool> repairSpecificSession(String sessionId) async {
    try {
      final sessionDoc = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        print('❌ [REPAIR] Session $sessionId non trouvée');
        return false;
      }

      return await _repairSession(sessionId, sessionDoc.data()!);
    } catch (e) {
      print('❌ [REPAIR] Erreur réparation session $sessionId: $e');
      return false;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/guest_participant_model.dart';

/// 🎯 Service pour gérer les participants invités (conducteurs non inscrits)
class GuestParticipantService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'guest_participants';

  /// ➕ Ajouter un participant invité à une session
  static Future<void> ajouterParticipantInvite(GuestParticipant participant) async {
    try {
      print('🎯 Ajout participant invité: ${participant.participantId}');
      
      // Sauvegarder dans la collection des participants invités
      await _firestore
          .collection(_collection)
          .doc(participant.participantId)
          .set(participant.toMap());

      // Mettre à jour la session collaborative pour inclure ce participant
      await _ajouterParticipantASession(participant);

      print('✅ Participant invité ajouté avec succès');
    } catch (e) {
      print('❌ Erreur ajout participant invité: $e');
      rethrow;
    }
  }

  /// 🔄 Ajouter le participant à la session collaborative
  static Future<void> _ajouterParticipantASession(GuestParticipant participant) async {
    try {
      final sessionRef = _firestore
          .collection('sessions_collaboratives')
          .doc(participant.sessionId);

      await _firestore.runTransaction((transaction) async {
        final sessionDoc = await transaction.get(sessionRef);
        
        if (!sessionDoc.exists) {
          throw Exception('Session non trouvée');
        }

        final sessionData = sessionDoc.data()!;
        final participants = List<Map<String, dynamic>>.from(sessionData['participants'] ?? []);

        // Créer l'entrée du participant pour la session
        final participantEntry = {
          'userId': participant.participantId,
          'nom': '${participant.infosPersonnelles.prenom} ${participant.infosPersonnelles.nom}',
          'roleVehicule': participant.roleVehicule,
          'statut': 'formulaire_fini', // Le formulaire est déjà rempli
          'dateRejointe': Timestamp.fromDate(participant.dateCreation),
          'isGuest': true, // Marquer comme invité
          'formulaireComplete': participant.formulaireComplete,
          'formulaireStatus': 'termine',
          'aSigne': false, // Pas encore signé
        };

        participants.add(participantEntry);

        // Mettre à jour la session
        transaction.update(sessionRef, {
          'participants': participants,
          'nombreParticipants': participants.length,
          'dateModification': Timestamp.fromDate(DateTime.now()),
        });
      });

      print('✅ Participant ajouté à la session collaborative');
    } catch (e) {
      print('❌ Erreur ajout participant à session: $e');
      rethrow;
    }
  }

  /// 📋 Récupérer un participant invité par ID
  static Future<GuestParticipant?> obtenirParticipantInvite(String participantId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(participantId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return GuestParticipant.fromMap(doc.data()!);
    } catch (e) {
      print('❌ Erreur récupération participant invité: $e');
      return null;
    }
  }

  /// 📋 Récupérer tous les participants invités d'une session
  static Future<List<GuestParticipant>> obtenirParticipantsInvitesSession(String sessionId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('sessionId', isEqualTo: sessionId)
          .get();

      return querySnapshot.docs
          .map((doc) => GuestParticipant.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Erreur récupération participants invités session: $e');
      return [];
    }
  }

  /// ✏️ Mettre à jour un participant invité
  static Future<void> mettreAJourParticipantInvite(GuestParticipant participant) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(participant.participantId)
          .update({
        ...participant.toMap(),
        'dateModification': Timestamp.fromDate(DateTime.now()),
      });

      print('✅ Participant invité mis à jour');
    } catch (e) {
      print('❌ Erreur mise à jour participant invité: $e');
      rethrow;
    }
  }

  /// ✍️ Marquer un participant invité comme ayant signé
  static Future<void> marquerCommeSigneParticipantInvite(String participantId) async {
    try {
      // Mettre à jour dans la collection des participants invités
      await _firestore
          .collection(_collection)
          .doc(participantId)
          .update({
        'aSigne': true,
        'dateSignature': Timestamp.fromDate(DateTime.now()),
        'dateModification': Timestamp.fromDate(DateTime.now()),
      });

      // Mettre à jour dans la session collaborative
      final participant = await obtenirParticipantInvite(participantId);
      if (participant != null) {
        await _mettreAJourStatutDansSession(participant.sessionId, participantId, 'signe');
      }

      print('✅ Participant invité marqué comme signé');
    } catch (e) {
      print('❌ Erreur marquage signature participant invité: $e');
      rethrow;
    }
  }

  /// 🔄 Mettre à jour le statut d'un participant dans la session
  static Future<void> _mettreAJourStatutDansSession(
    String sessionId, 
    String participantId, 
    String nouveauStatut
  ) async {
    try {
      final sessionRef = _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId);

      await _firestore.runTransaction((transaction) async {
        final sessionDoc = await transaction.get(sessionRef);
        
        if (!sessionDoc.exists) {
          throw Exception('Session non trouvée');
        }

        final sessionData = sessionDoc.data()!;
        final participants = List<Map<String, dynamic>>.from(sessionData['participants'] ?? []);

        // Trouver et mettre à jour le participant
        for (int i = 0; i < participants.length; i++) {
          if (participants[i]['userId'] == participantId) {
            participants[i]['statut'] = nouveauStatut;
            participants[i]['aSigne'] = nouveauStatut == 'signe';
            break;
          }
        }

        // Mettre à jour la session
        transaction.update(sessionRef, {
          'participants': participants,
          'dateModification': Timestamp.fromDate(DateTime.now()),
        });
      });

      print('✅ Statut participant mis à jour dans session');
    } catch (e) {
      print('❌ Erreur mise à jour statut dans session: $e');
      rethrow;
    }
  }

  /// 🗑️ Supprimer un participant invité
  static Future<void> supprimerParticipantInvite(String participantId) async {
    try {
      // Récupérer les infos du participant avant suppression
      final participant = await obtenirParticipantInvite(participantId);
      
      if (participant != null) {
        // Supprimer de la collection des participants invités
        await _firestore
            .collection(_collection)
            .doc(participantId)
            .delete();

        // Retirer de la session collaborative
        await _retirerParticipantDeSession(participant.sessionId, participantId);
      }

      print('✅ Participant invité supprimé');
    } catch (e) {
      print('❌ Erreur suppression participant invité: $e');
      rethrow;
    }
  }

  /// 🔄 Retirer un participant de la session collaborative
  static Future<void> _retirerParticipantDeSession(String sessionId, String participantId) async {
    try {
      final sessionRef = _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId);

      await _firestore.runTransaction((transaction) async {
        final sessionDoc = await transaction.get(sessionRef);
        
        if (!sessionDoc.exists) {
          throw Exception('Session non trouvée');
        }

        final sessionData = sessionDoc.data()!;
        final participants = List<Map<String, dynamic>>.from(sessionData['participants'] ?? []);

        // Retirer le participant
        participants.removeWhere((p) => p['userId'] == participantId);

        // Mettre à jour la session
        transaction.update(sessionRef, {
          'participants': participants,
          'nombreParticipants': participants.length,
          'dateModification': Timestamp.fromDate(DateTime.now()),
        });
      });

      print('✅ Participant retiré de la session collaborative');
    } catch (e) {
      print('❌ Erreur retrait participant de session: $e');
      rethrow;
    }
  }

  /// 📊 Obtenir les statistiques des participants invités
  static Future<Map<String, dynamic>> obtenirStatistiquesParticipantsInvites() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .get();

      final participants = querySnapshot.docs
          .map((doc) => GuestParticipant.fromMap(doc.data()))
          .toList();

      final totalParticipants = participants.length;
      final participantsComplets = participants.where((p) => p.formulaireComplete).length;
      final participantsAujourdhui = participants.where((p) => 
          p.dateCreation.isAfter(DateTime.now().subtract(const Duration(days: 1)))
      ).length;

      return {
        'totalParticipants': totalParticipants,
        'participantsComplets': participantsComplets,
        'participantsAujourdhui': participantsAujourdhui,
        'tauxCompletion': totalParticipants > 0 ? (participantsComplets / totalParticipants * 100).round() : 0,
      };
    } catch (e) {
      print('❌ Erreur statistiques participants invités: $e');
      return {
        'totalParticipants': 0,
        'participantsComplets': 0,
        'participantsAujourdhui': 0,
        'tauxCompletion': 0,
      };
    }
  }

  /// 🔍 Rechercher des participants invités par critères
  static Future<List<GuestParticipant>> rechercherParticipantsInvites({
    String? sessionId,
    String? nom,
    String? cin,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      if (sessionId != null) {
        query = query.where('sessionId', isEqualTo: sessionId);
      }

      if (dateDebut != null) {
        query = query.where('dateCreation', isGreaterThanOrEqualTo: Timestamp.fromDate(dateDebut));
      }

      if (dateFin != null) {
        query = query.where('dateCreation', isLessThanOrEqualTo: Timestamp.fromDate(dateFin));
      }

      final querySnapshot = await query.get();
      
      List<GuestParticipant> participants = querySnapshot.docs
          .map((doc) => GuestParticipant.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Filtres additionnels côté client
      if (nom != null && nom.isNotEmpty) {
        participants = participants.where((p) => 
            '${p.infosPersonnelles.prenom} ${p.infosPersonnelles.nom}'
                .toLowerCase()
                .contains(nom.toLowerCase())
        ).toList();
      }

      if (cin != null && cin.isNotEmpty) {
        participants = participants.where((p) => 
            p.infosPersonnelles.cin.contains(cin)
        ).toList();
      }

      return participants;
    } catch (e) {
      print('❌ Erreur recherche participants invités: $e');
      return [];
    }
  }
}

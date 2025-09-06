import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sinistre_model.dart';
import '../models/accident_session_complete.dart';

/// 🚨 Service pour gérer les sinistres
class SinistreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'sinistres';

  /// 📝 Créer un sinistre à partir d'une session de constat
  static Future<String> creerSinistreDepuisSession({
    required AccidentSessionComplete session,
    required String conducteurId,
    required Map<String, dynamic> vehiculeInfo,
    required Map<String, dynamic> contratInfo,
  }) async {
    try {
      final now = DateTime.now();
      final numeroSinistre = _genererNumeroSinistre();

      final sinistre = SinistreModel(
        id: '',
        numeroSinistre: numeroSinistre,
        sessionId: session.id,
        codeSession: session.codeSession,
        
        // Informations du conducteur déclarant
        conducteurDeclarantId: conducteurId,
        vehiculeId: vehiculeInfo['id'] ?? '',
        contratId: contratInfo['id'] ?? '',
        compagnieId: contratInfo['compagnieId'] ?? '',
        agenceId: contratInfo['agenceId'] ?? '',
        
        // Informations de l'accident
        dateAccident: session.infosGenerales.dateAccident,
        heureAccident: session.infosGenerales.heureAccident,
        lieuAccident: session.infosGenerales.lieuAccident,
        lieuGps: session.infosGenerales.lieuGps,
        
        // Détails
        typeAccident: session.typeAccident,
        nombreVehicules: session.nombreVehicules,
        blesses: session.infosGenerales.blesses,
        degatsMateriels: session.infosGenerales.degatsMaterielsAutres,
        
        // Statut et workflow
        statut: SinistreStatut.enAttente,
        statutSession: _determinerStatutSession(session),
        
        // Participants
        conducteurs: session.conducteurs.map((c) => {
          'userId': c.userId,
          'nom': c.nom,
          'prenom': c.prenom,
          'email': c.email,
          'telephone': c.telephone,
          'roleVehicule': c.roleVehicule,
          'estCreateur': c.estCreateur,
          'aRejoint': c.aRejoint,
          'estInscrit': c.estInscrit ?? true,
        }).toList(),
        
        // Données du constat
        croquisData: session.croquis.croquisData.isNotEmpty
            ? {'data': session.croquis.croquisData}
            : {},
        circonstances: session.circonstances.circonstancesParVehicule,
        photos: session.photos.map((photo) => {'url': photo}).toList(),
        
        // Métadonnées
        dateCreation: now,
        dateModification: now,
        creeParConducteur: true,
      );

      final docRef = await _firestore.collection(_collection).add(sinistre.toMap());
      
      // Mettre à jour la session avec l'ID du sinistre
      await _firestore
          .collection('accident_sessions_complete')
          .doc(session.id)
          .update({
        'sinistreId': docRef.id,
        'dateDeclaration': now,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur création sinistre: $e');
    }
  }

  /// 📊 Récupérer les sinistres d'un conducteur
  static Stream<List<SinistreModel>> getSinistresStream(String conducteurId) {
    return _firestore
        .collection(_collection)
        .where('conducteurDeclarantId', isEqualTo: conducteurId)
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SinistreModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// 🔍 Récupérer un sinistre par ID
  static Future<SinistreModel?> getSinistreById(String sinistreId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(sinistreId).get();
      if (doc.exists) {
        return SinistreModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur récupération sinistre: $e');
    }
  }

  /// 🔄 Mettre à jour le statut d'un sinistre
  static Future<void> updateStatutSinistre({
    required String sinistreId,
    required SinistreStatut nouveauStatut,
    String? commentaire,
  }) async {
    try {
      final updates = {
        'statut': nouveauStatut.name,
        'dateModification': DateTime.now(),
      };

      if (commentaire != null) {
        updates['commentaireStatut'] = commentaire;
      }

      await _firestore.collection(_collection).doc(sinistreId).update(updates);
    } catch (e) {
      throw Exception('Erreur mise à jour statut: $e');
    }
  }

  /// 📈 Mettre à jour le statut de session
  static Future<void> updateStatutSession({
    required String sinistreId,
    required StatutSession nouveauStatut,
  }) async {
    try {
      await _firestore.collection(_collection).doc(sinistreId).update({
        'statutSession': nouveauStatut.name,
        'dateModification': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Erreur mise à jour statut session: $e');
    }
  }

  /// 🎲 Générer un numéro de sinistre unique
  static String _genererNumeroSinistre() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final timestamp = now.millisecondsSinceEpoch.toString().substring(8);
    return 'SIN-$year$month$day-$timestamp';
  }

  /// 📊 Déterminer le statut de session
  static StatutSession _determinerStatutSession(AccidentSessionComplete session) {
    final conducteurs = session.conducteurs;
    final nombreTotal = session.nombreVehicules;
    final nombreRejoint = conducteurs.where((c) => c.aRejoint).length;

    if (nombreRejoint < nombreTotal) {
      return StatutSession.enAttenteParticipants;
    } else if (session.statut == 'en_cours') {
      return StatutSession.enCoursRemplissage;
    } else if (session.statut == 'termine') {
      return StatutSession.termine;
    } else {
      return StatutSession.enAttenteParticipants;
    }
  }

  /// 📋 Récupérer les sinistres avec participants
  static Stream<List<Map<String, dynamic>>> getSinistresAvecParticipants(String conducteurId) {
    return _firestore
        .collection(_collection)
        .where('conducteurs', arrayContainsAny: [
          {'userId': conducteurId}
        ])
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList());
  }

  /// 🔄 Synchroniser avec la session de constat
  static Future<void> synchroniserAvecSession(String sessionId) async {
    try {
      // Récupérer la session mise à jour
      final sessionDoc = await _firestore
          .collection('accident_sessions_complete')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) return;

      final sessionData = sessionDoc.data()!;
      final session = AccidentSessionComplete.fromMap(sessionData, sessionId);

      // Trouver le sinistre correspondant
      final sinistreQuery = await _firestore
          .collection(_collection)
          .where('sessionId', isEqualTo: sessionId)
          .limit(1)
          .get();

      if (sinistreQuery.docs.isEmpty) return;

      final sinistreDoc = sinistreQuery.docs.first;
      
      // Mettre à jour le sinistre
      await sinistreDoc.reference.update({
        'statutSession': _determinerStatutSession(session).name,
        'conducteurs': session.conducteurs.map((c) => {
          'userId': c.userId,
          'nom': c.nom,
          'prenom': c.prenom,
          'email': c.email,
          'telephone': c.telephone,
          'roleVehicule': c.roleVehicule,
          'estCreateur': c.estCreateur,
          'aRejoint': c.aRejoint,
          'estInscrit': c.estInscrit ?? true,
        }).toList(),
        'croquisData': session.croquis.croquisData.isNotEmpty
            ? {'data': session.croquis.croquisData}
            : {},
        'circonstances': session.circonstances.circonstancesParVehicule,
        'photos': session.photos.map((photo) => {'url': photo}).toList(),
        'dateModification': DateTime.now(),
      });

    } catch (e) {
      print('Erreur synchronisation sinistre: $e');
    }
  }

  /// 📊 Statistiques des sinistres
  static Future<Map<String, int>> getStatistiquesSinistres(String conducteurId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('conducteurDeclarantId', isEqualTo: conducteurId)
          .get();

      final sinistres = query.docs.map((doc) => doc.data()).toList();

      return {
        'total': sinistres.length,
        'enAttente': sinistres.where((s) => s['statut'] == 'enAttente').length,
        'enCours': sinistres.where((s) => s['statut'] == 'enCours').length,
        'termines': sinistres.where((s) => s['statut'] == 'termine').length,
        'rejetes': sinistres.where((s) => s['statut'] == 'rejete').length,
      };
    } catch (e) {
      return {
        'total': 0,
        'enAttente': 0,
        'enCours': 0,
        'termines': 0,
        'rejetes': 0,
      };
    }
  }
}

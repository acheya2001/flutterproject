import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sinistre_model.dart';

/// 🚨 Service moderne pour la gestion des sinistres
class ModernSinistreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 📊 Créer un nouveau sinistre avec workflow intelligent
  static Future<String> creerSinistre({
    required String sessionId,
    required String codeSession,
    required Map<String, dynamic> accidentData,
    required List<Map<String, dynamic>> conducteurs,
    required Map<String, dynamic> croquisData,
    required List<String> photos,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Récupérer les informations du conducteur déclarant
      final conducteurDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!conducteurDoc.exists) {
        throw Exception('Informations conducteur non trouvées');
      }

      final conducteurData = conducteurDoc.data()!;
      final numeroSinistre = await _genererNumeroSinistre();

      // Créer le sinistre
      final sinistre = SinistreModel(
        id: '',
        numeroSinistre: numeroSinistre,
        sessionId: sessionId,
        codeSession: codeSession,
        conducteurDeclarantId: user.uid,
        vehiculeId: accidentData['vehiculeId'] ?? '',
        contratId: accidentData['contratId'] ?? '',
        compagnieId: conducteurData['compagnieId'] ?? '',
        agenceId: conducteurData['agenceId'] ?? '',
        dateAccident: accidentData['dateAccident'],
        heureAccident: accidentData['heureAccident'] ?? '',
        lieuAccident: accidentData['lieuAccident'] ?? '',
        lieuGps: accidentData['lieuGps'] ?? '',
        typeAccident: accidentData['typeAccident'] ?? 'Collision',
        nombreVehicules: conducteurs.length,
        blesses: accidentData['blesses'] ?? false,
        degatsMateriels: accidentData['degatsMateriels'] ?? true,
        statut: SinistreStatut.enAttente,
        statutSession: _determinerStatutSession(conducteurs),
        conducteurs: conducteurs,
        croquisData: croquisData,
        circonstances: accidentData['circonstances'] ?? {},
        photos: photos.map((url) => {'url': url}).toList(),
        dateCreation: DateTime.now(),
        dateModification: DateTime.now(),
        creeParConducteur: true,
      );

      // Sauvegarder dans Firestore
      final docRef = await _firestore.collection('sinistres').add(sinistre.toMap());

      // Envoyer vers les agences respectives
      await _envoyerVersAgences(docRef.id, conducteurs);

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur création sinistre: $e');
    }
  }

  /// 📤 Envoyer le sinistre vers les agences des conducteurs
  static Future<void> _envoyerVersAgences(String sinistreId, List<Map<String, dynamic>> conducteurs) async {
    try {
      for (final conducteur in conducteurs) {
        final agenceId = conducteur['agenceId'];
        if (agenceId != null && agenceId.isNotEmpty) {
          await _firestore
              .collection('agences')
              .doc(agenceId)
              .collection('sinistres_recus')
              .doc(sinistreId)
              .set({
            'sinistreId': sinistreId,
            'conducteurId': conducteur['id'],
            'dateReception': FieldValue.serverTimestamp(),
            'statut': 'nouveau',
            'traite': false,
          });
        }
      }
    } catch (e) {
      print('❌ Erreur envoi vers agences: $e');
    }
  }

  /// 🔢 Générer un numéro de sinistre unique
  static Future<String> _genererNumeroSinistre() async {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    
    // Compter les sinistres du jour
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final count = await _firestore
        .collection('sinistres')
        .where('dateCreation', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dateCreation', isLessThan: Timestamp.fromDate(endOfDay))
        .get();
    
    final sequence = (count.docs.length + 1).toString().padLeft(3, '0');
    return 'SIN$year$month$day$sequence';
  }

  /// 📊 Déterminer le statut de session selon les participants
  static StatutSession _determinerStatutSession(List<Map<String, dynamic>> conducteurs) {
    final totalConducteurs = conducteurs.length;
    final conducteursRejoints = conducteurs.where((c) => c['aRejoint'] == true).length;
    final conducteursTermines = conducteurs.where((c) => c['formulaireComplete'] == true).length;

    if (conducteursTermines == totalConducteurs) {
      return StatutSession.termine;
    } else if (conducteursRejoints == totalConducteurs) {
      return StatutSession.enCoursRemplissage;
    } else {
      return StatutSession.enAttenteParticipants;
    }
  }

  /// 👤 Rejoindre une session (conducteur inscrit)
  static Future<Map<String, dynamic>> rejoindreSesssionInscrit({
    required String codeSession,
    required String conducteurId,
  }) async {
    try {
      // Trouver la session
      final sessionQuery = await _firestore
          .collection('accident_sessions_complete')
          .where('codePublic', isEqualTo: codeSession)
          .get();

      if (sessionQuery.docs.isEmpty) {
        throw Exception('Session non trouvée');
      }

      final sessionDoc = sessionQuery.docs.first;
      final sessionData = sessionDoc.data();

      // Récupérer les informations du conducteur
      final conducteurDoc = await _firestore
          .collection('users')
          .doc(conducteurId)
          .get();

      if (!conducteurDoc.exists) {
        throw Exception('Conducteur non trouvé');
      }

      final conducteurData = conducteurDoc.data()!;

      // Récupérer les véhicules du conducteur
      final vehiculesQuery = await _firestore
          .collection('users')
          .doc(conducteurId)
          .collection('vehicules')
          .where('statut', isEqualTo: 'actif')
          .get();

      final vehicules = vehiculesQuery.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      return {
        'success': true,
        'sessionId': sessionDoc.id,
        'sessionData': sessionData,
        'conducteurData': conducteurData,
        'vehicules': vehicules,
        'isInscrit': true,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 👥 Rejoindre une session (conducteur invité non-inscrit)
  static Future<Map<String, dynamic>> rejoindreSesssionInvite({
    required String codeSession,
  }) async {
    try {
      // Trouver la session
      final sessionQuery = await _firestore
          .collection('accident_sessions_complete')
          .where('codePublic', isEqualTo: codeSession)
          .get();

      if (sessionQuery.docs.isEmpty) {
        throw Exception('Session non trouvée');
      }

      final sessionDoc = sessionQuery.docs.first;
      final sessionData = sessionDoc.data();

      // Récupérer les compagnies et agences pour les dropdowns
      final compagniesQuery = await _firestore
          .collection('compagnies_assurance')
          .get();

      final compagnies = compagniesQuery.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      return {
        'success': true,
        'sessionId': sessionDoc.id,
        'sessionData': sessionData,
        'compagnies': compagnies,
        'isInscrit': false,
        'requiresFullForm': true,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 📋 Récupérer les agences d'une compagnie
  static Future<List<Map<String, dynamic>>> getAgencesParCompagnie(String compagnieId) async {
    try {
      final agencesQuery = await _firestore
          .collection('compagnies_assurance')
          .doc(compagnieId)
          .collection('agences')
          .get();

      return agencesQuery.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('❌ Erreur récupération agences: $e');
      return [];
    }
  }

  /// 📊 Mettre à jour le statut d'un sinistre
  static Future<void> mettreAJourStatut({
    required String sinistreId,
    required SinistreStatut nouveauStatut,
    String? commentaire,
  }) async {
    try {
      await _firestore.collection('sinistres').doc(sinistreId).update({
        'statut': nouveauStatut.name,
        'dateModification': FieldValue.serverTimestamp(),
        if (commentaire != null) 'commentaireStatut': commentaire,
      });
    } catch (e) {
      throw Exception('Erreur mise à jour statut: $e');
    }
  }

  /// 📱 Récupérer les sinistres d'un conducteur
  static Stream<List<Map<String, dynamic>>> getSinistresStream(String conducteurId) {
    return _firestore
        .collection('sinistres')
        .where('conducteurDeclarantId', isEqualTo: conducteurId)
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList());
  }
}

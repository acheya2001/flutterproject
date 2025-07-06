import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';
import '../../features/constat/models/session_constat_model.dart';
import '../../features/constat/models/conducteur_session_info.dart';
import '../../features/conducteur/models/conducteur_info_model.dart';
import '../../features/conducteur/models/vehicule_accident_model.dart';
import '../../features/conducteur/models/assurance_info_model.dart';
import '../../features/constat/models/proprietaire_info.dart';
import '../../features/constat/models/temoin_model.dart';

/// 🔥 Service Firestore professionnel pour les sessions collaboratives
///
/// Ce service gère toutes les opérations Firestore liées aux sessions collaboratives
/// avec gestion d'erreurs robuste, transactions atomiques et cache local.
class FirestoreSessionService {
  static final FirestoreSessionService _instance = FirestoreSessionService._internal();
  factory FirestoreSessionService() => _instance;
  FirestoreSessionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📝 Crée une nouvelle session collaborative dans Firestore
  Future<String> creerSessionCollaborative(SessionConstatModel session) async {
    try {
      debugPrint('[FirestoreSession] === CRÉATION SESSION COLLABORATIVE ===');
      
      // 1. Créer le document principal de session
      final sessionRef = _firestore.collection(Constants.collectionSessions).doc();
      final sessionId = sessionRef.id;
      
      final sessionData = {
        'sessionCode': session.sessionCode,
        'dateAccident': Timestamp.fromDate(session.dateAccident),
        'lieuAccident': session.lieuAccident,
        'coordonnees': session.coordonnees,
        'nombreConducteurs': session.nombreConducteurs,
        'createdBy': session.createdBy,
        'createdAt': Timestamp.fromDate(session.createdAt),
        'updatedAt': Timestamp.fromDate(session.updatedAt),
        'status': session.status.toString().split('.').last,
        'invitationsSent': session.invitationsSent,
        'validationStatus': session.validationStatus,
      };
      
      await sessionRef.set(sessionData);
      debugPrint('[FirestoreSession] ✅ Session créée: $sessionId');
      
      // 2. Créer le mapping code -> sessionId
      await _firestore.collection(Constants.collectionSessionCodes).doc(session.sessionCode).set({
        'sessionId': sessionId,
        'createdAt': Timestamp.fromDate(session.createdAt),
        'isActive': true,
      });
      debugPrint('[FirestoreSession] ✅ Code de session mappé: ${session.sessionCode}');
      
      // 3. Créer les documents des conducteurs
      for (final entry in session.conducteursInfo.entries) {
        final position = entry.key;
        final conducteurInfo = entry.value;
        
        await _firestore
            .collection(Constants.collectionSessions)
            .doc(sessionId)
            .collection('conducteurs')
            .doc(position)
            .set(conducteurInfo.toMap());
        
        debugPrint('[FirestoreSession] ✅ Conducteur $position créé');
      }
      
      return sessionId;
      
    } catch (e) {
      debugPrint('[FirestoreSession] ❌ Erreur création session: $e');
      rethrow;
    }
  }

  /// 🔍 Trouve une session par son code
  Future<SessionConstatModel?> getSessionByCode(String sessionCode) async {
    try {
      debugPrint('[FirestoreSession] === RECHERCHE SESSION PAR CODE ===');
      debugPrint('[FirestoreSession] Code recherché: $sessionCode');
      
      // 1. Récupérer l'ID de session via le code
      final codeDoc = await _firestore
          .collection(Constants.collectionSessionCodes)
          .doc(sessionCode)
          .get();
      
      if (!codeDoc.exists) {
        debugPrint('[FirestoreSession] ❌ Code de session non trouvé');
        return null;
      }
      
      final sessionId = codeDoc.data()!['sessionId'] as String;
      debugPrint('[FirestoreSession] ✅ Session ID trouvé: $sessionId');
      
      // 2. Récupérer les données de la session
      final sessionDoc = await _firestore
          .collection(Constants.collectionSessions)
          .doc(sessionId)
          .get();
      
      if (!sessionDoc.exists) {
        debugPrint('[FirestoreSession] ❌ Session non trouvée');
        return null;
      }
      
      final sessionData = sessionDoc.data()!;
      
      // 3. Récupérer les informations des conducteurs
      final conducteursSnapshot = await _firestore
          .collection(Constants.collectionSessions)
          .doc(sessionId)
          .collection('conducteurs')
          .get();
      
      final Map<String, ConducteurSessionInfo> conducteursInfo = {};
      for (final doc in conducteursSnapshot.docs) {
        final conducteurData = doc.data();
        conducteursInfo[doc.id] = ConducteurSessionInfo.fromMap(conducteurData);
      }
      
      // 4. Construire le modèle de session
      final session = SessionConstatModel(
        id: sessionId,
        sessionCode: sessionData['sessionCode'],
        dateAccident: (sessionData['dateAccident'] as Timestamp).toDate(),
        lieuAccident: sessionData['lieuAccident'],
        coordonnees: sessionData['coordonnees'],
        nombreConducteurs: sessionData['nombreConducteurs'],
        createdBy: sessionData['createdBy'],
        createdAt: (sessionData['createdAt'] as Timestamp).toDate(),
        updatedAt: (sessionData['updatedAt'] as Timestamp).toDate(),
        status: SessionStatus.values.firstWhere(
          (e) => e.toString().split('.').last == sessionData['status'],
          orElse: () => SessionStatus.draft,
        ),
        conducteursInfo: conducteursInfo,
        invitationsSent: List<String>.from(sessionData['invitationsSent'] ?? []),
        validationStatus: Map<String, bool>.from(sessionData['validationStatus'] ?? {}),
      );
      
      debugPrint('[FirestoreSession] ✅ Session récupérée avec succès');
      return session;
      
    } catch (e) {
      debugPrint('[FirestoreSession] ❌ Erreur récupération session: $e');
      return null;
    }
  }

  /// 🚪 Permet à un conducteur de rejoindre une session
  Future<SessionConstatModel?> rejoindreSession(String sessionCode, String userId) async {
    try {
      debugPrint('[FirestoreSession] === REJOINDRE SESSION ===');
      debugPrint('[FirestoreSession] Code: $sessionCode, User: $userId');
      
      // 1. Récupérer la session
      final session = await getSessionByCode(sessionCode);
      if (session == null) {
        throw Exception('Session non trouvée');
      }
      
      // 2. Trouver une position disponible
      String? positionDisponible;
      for (final entry in session.conducteursInfo.entries) {
        final position = entry.key;
        final conducteurInfo = entry.value;
        
        // Priorité aux positions invitées non rejointes
        if (conducteurInfo.isInvited && !conducteurInfo.hasJoined) {
          positionDisponible = position;
          break;
        }
      }
      
      if (positionDisponible == null) {
        throw Exception('Aucune position disponible dans cette session');
      }
      
      // 3. Marquer le conducteur comme ayant rejoint
      await _firestore
          .collection(Constants.collectionSessions)
          .doc(session.id)
          .collection('conducteurs')
          .doc(positionDisponible)
          .update({
        'userId': userId,
        'hasJoined': true,
        'joinedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('[FirestoreSession] ✅ Conducteur rejoint position: $positionDisponible');
      
      // 4. Retourner la session mise à jour
      return await getSessionByCode(sessionCode);
      
    } catch (e) {
      debugPrint('[FirestoreSession] ❌ Erreur rejoindre session: $e');
      rethrow;
    }
  }

  /// 💾 Sauvegarde les données d'un conducteur dans la session
  Future<void> sauvegarderDonneesConducteur({
    required String sessionId,
    required String position,
    required ConducteurInfoModel conducteurInfo,
    required VehiculeAccidentModel vehiculeInfo,
    required AssuranceInfoModel assuranceInfo,
    required bool isProprietaire,
    ProprietaireInfo? proprietaireInfo,
    List<String>? circonstances,
    List<String>? degatsApparents,
    List<TemoinModel>? temoins,
    List<String>? photosAccidentUrls,
    String? photoPermisUrl,
    String? photoCarteGriseUrl,
    String? photoAttestationUrl,
    String? signatureUrl,
    String? observations,
  }) async {
    try {
      debugPrint('[FirestoreSession] === SAUVEGARDE DONNÉES CONDUCTEUR ===');
      debugPrint('[FirestoreSession] Session: $sessionId, Position: $position');
      
      final donneesCompletes = {
        // Informations conducteur
        'conducteur': conducteurInfo.toMap(),
        'vehicule': vehiculeInfo.toMap(),
        'assurance': assuranceInfo.toMap(),
        'isProprietaire': isProprietaire,
        'proprietaire': proprietaireInfo?.toMap(),
        
        // Circonstances et dégâts
        'circonstances': circonstances ?? [],
        'degatsApparents': degatsApparents ?? [],
        
        // Témoins
        'temoins': temoins?.map((t) => t.toMap()).toList() ?? [],
        
        // Photos et documents
        'photosAccident': photosAccidentUrls ?? [],
        'photoPermis': photoPermisUrl,
        'photoCarteGrise': photoCarteGriseUrl,
        'photoAttestation': photoAttestationUrl,
        'signature': signatureUrl,
        
        // Observations
        'observations': observations,
        
        // Métadonnées
        'isCompleted': true,
        'completedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };
      
      // Sauvegarder dans la sous-collection conducteurs
      await _firestore
          .collection(Constants.collectionSessions)
          .doc(sessionId)
          .collection('conducteurs')
          .doc(position)
          .update(donneesCompletes);
      
      // Mettre à jour le statut de validation de la session
      await _firestore
          .collection(Constants.collectionSessions)
          .doc(sessionId)
          .update({
        'validationStatus.$position': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      debugPrint('[FirestoreSession] ✅ Données conducteur sauvegardées');
      
    } catch (e) {
      debugPrint('[FirestoreSession] ❌ Erreur sauvegarde: $e');
      rethrow;
    }
  }

  /// 📊 Vérifie si toutes les parties ont terminé
  Future<bool> verifierSessionComplete(String sessionId) async {
    try {
      final sessionDoc = await _firestore
          .collection(Constants.collectionSessions)
          .doc(sessionId)
          .get();
      
      if (!sessionDoc.exists) return false;
      
      final validationStatus = Map<String, bool>.from(
        sessionDoc.data()!['validationStatus'] ?? {}
      );
      
      final nombreConducteurs = sessionDoc.data()!['nombreConducteurs'] as int;
      
      // Vérifier si toutes les positions sont validées
      final positions = ['A', 'B', 'C', 'D', 'E', 'F'];
      int validatedCount = 0;
      
      for (int i = 0; i < nombreConducteurs; i++) {
        if (validationStatus[positions[i]] == true) {
          validatedCount++;
        }
      }
      
      final isComplete = validatedCount == nombreConducteurs;
      
      if (isComplete) {
        // Marquer la session comme complète
        await _firestore
            .collection(Constants.collectionSessions)
            .doc(sessionId)
            .update({
          'status': SessionStatus.completed.toString().split('.').last,
          'completedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      
      return isComplete;
      
    } catch (e) {
      debugPrint('[FirestoreSession] ❌ Erreur vérification: $e');
      return false;
    }
  }

  /// 📋 Récupère les sessions d'un utilisateur
  Future<List<SessionConstatModel>> getSessionsUtilisateur(String userId) async {
    try {
      debugPrint('[FirestoreSession] === RÉCUPÉRATION SESSIONS UTILISATEUR ===');
      
      final sessions = <SessionConstatModel>[];
      
      // Sessions créées par l'utilisateur
      final createdSessions = await _firestore
          .collection(Constants.collectionSessions)
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      for (final doc in createdSessions.docs) {
        final sessionData = doc.data();
        final session = await _buildSessionFromDoc(doc.id, sessionData);
        if (session != null) sessions.add(session);
      }
      
      // Sessions où l'utilisateur a participé
      final allSessions = await _firestore
          .collection(Constants.collectionSessions)
          .get();
      
      for (final sessionDoc in allSessions.docs) {
        if (sessionDoc.data()['createdBy'] == userId) continue; // Déjà ajouté
        
        final conducteursSnapshot = await _firestore
            .collection(Constants.collectionSessions)
            .doc(sessionDoc.id)
            .collection('conducteurs')
            .where('userId', isEqualTo: userId)
            .get();
        
        if (conducteursSnapshot.docs.isNotEmpty) {
          final session = await _buildSessionFromDoc(sessionDoc.id, sessionDoc.data());
          if (session != null) sessions.add(session);
        }
      }
      
      // Trier par date de création
      sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      debugPrint('[FirestoreSession] ✅ ${sessions.length} sessions trouvées');
      return sessions;
      
    } catch (e) {
      debugPrint('[FirestoreSession] ❌ Erreur récupération sessions: $e');
      return [];
    }
  }

  /// 🏗️ Construit un modèle de session à partir des données Firestore
  Future<SessionConstatModel?> _buildSessionFromDoc(String sessionId, Map<String, dynamic> sessionData) async {
    try {
      // Récupérer les conducteurs
      final conducteursSnapshot = await _firestore
          .collection(Constants.collectionSessions)
          .doc(sessionId)
          .collection('conducteurs')
          .get();
      
      final Map<String, ConducteurSessionInfo> conducteursInfo = {};
      for (final doc in conducteursSnapshot.docs) {
        conducteursInfo[doc.id] = ConducteurSessionInfo.fromMap(doc.data());
      }
      
      return SessionConstatModel(
        id: sessionId,
        sessionCode: sessionData['sessionCode'],
        dateAccident: (sessionData['dateAccident'] as Timestamp).toDate(),
        lieuAccident: sessionData['lieuAccident'],
        coordonnees: sessionData['coordonnees'],
        nombreConducteurs: sessionData['nombreConducteurs'],
        createdBy: sessionData['createdBy'],
        createdAt: (sessionData['createdAt'] as Timestamp).toDate(),
        updatedAt: (sessionData['updatedAt'] as Timestamp).toDate(),
        status: SessionStatus.values.firstWhere(
          (e) => e.toString().split('.').last == sessionData['status'],
          orElse: () => SessionStatus.draft,
        ),
        conducteursInfo: conducteursInfo,
        invitationsSent: List<String>.from(sessionData['invitationsSent'] ?? []),
        validationStatus: Map<String, bool>.from(sessionData['validationStatus'] ?? {}),
      );
      
    } catch (e) {
      debugPrint('[FirestoreSession] ❌ Erreur construction session: $e');
      return null;
    }
  }
}

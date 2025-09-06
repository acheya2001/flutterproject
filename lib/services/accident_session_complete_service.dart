import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/accident_session_complete.dart';
import 'sinistre_service.dart';

/// 🎯 Service complet de gestion des sessions d'accident multi-conducteurs
class AccidentSessionCompleteService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'sessions_accidents_completes';

  /// 🆕 Créer une nouvelle session d'accident
  static Future<AccidentSessionComplete> creerNouvelleSession({
    required String typeAccident,
    required int nombreVehicules,
    required String nomCreateur,
    required String prenomCreateur,
    required String emailCreateur,
    required String telephoneCreateur,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Générer un code de session unique
      final codeSession = _genererCodeSession();

      // Créer la session
      final session = AccidentSessionComplete(
        id: '', // Sera défini après création
        codeSession: codeSession,
        typeAccident: typeAccident,
        nombreVehicules: nombreVehicules,
        statut: 'en_attente',
        conducteurCreateur: user.uid,
        conducteurs: [
          ConducteurSession(
            userId: user.uid,
            nom: nomCreateur,
            prenom: prenomCreateur,
            email: emailCreateur,
            telephone: telephoneCreateur,
            roleVehicule: 'A', // Le créateur est toujours véhicule A
            estCreateur: true,
            aRejoint: true,
            dateRejoint: DateTime.now(),
          ),
        ],
        infosGenerales: InfosGeneralesAccident(
          dateAccident: DateTime.now(),
          heureAccident: '',
          lieuAccident: '',
          lieuGps: '',
          blesses: false,
          detailsBlesses: '',
          degatsMaterielsAutres: false,
          detailsDegatsAutres: '',
          temoins: [],
        ),
        vehicules: [],
        circonstances: CirconstancesAccident(circonstancesParVehicule: {}),
        croquis: CroquisAccident(croquisData: '', annotations: []),
        photos: [],
        signatures: {},
        dateCreation: DateTime.now(),
      );

      // Sauvegarder en Firestore
      final docRef = await _firestore.collection(_collection).add(session.toMap());
      
      // Retourner la session avec l'ID
      return AccidentSessionComplete(
        id: docRef.id,
        codeSession: session.codeSession,
        typeAccident: session.typeAccident,
        nombreVehicules: session.nombreVehicules,
        statut: session.statut,
        conducteurCreateur: session.conducteurCreateur,
        conducteurs: session.conducteurs,
        infosGenerales: session.infosGenerales,
        vehicules: session.vehicules,
        circonstances: session.circonstances,
        croquis: session.croquis,
        photos: session.photos,
        signatures: session.signatures,
        dateCreation: session.dateCreation,
      );
    } catch (e) {
      print('Erreur création session: $e');
      throw Exception('Impossible de créer la session: $e');
    }
  }

  /// 🔍 Obtenir une session par code de session
  static Future<AccidentSessionComplete?> obtenirSessionParCode(String codeSession) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('codeSession', isEqualTo: codeSession)
          .where('statut', whereIn: ['en_attente', 'en_cours'])
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return AccidentSessionComplete.fromMap(doc.data(), doc.id);
      }

      return null;
    } catch (e) {
      print('Erreur obtention session par code: $e');
      return null;
    }
  }

  /// 🔍 Rejoindre une session avec un code
  static Future<AccidentSessionComplete> rejoindreSession({
    required String codeSession,
    required String nomConducteur,
    required String prenomConducteur,
    required String emailConducteur,
    required String telephoneConducteur,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Chercher la session par code (seulement les sessions actives)
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('codeSession', isEqualTo: codeSession)
          .where('statut', whereIn: ['creation', 'en_attente', 'en_cours'])
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Code de session invalide ou session expirée');
      }

      final doc = querySnapshot.docs.first;
      final session = AccidentSessionComplete.fromMap(doc.data(), doc.id);

      // Vérifier si l'utilisateur peut rejoindre
      if (session.conducteurs.length >= session.nombreVehicules) {
        throw Exception('Session complète');
      }

      // Vérifier si l'utilisateur a déjà rejoint
      final conducteurExistant = session.conducteurs.where((c) => c.userId == user.uid).firstOrNull;
      if (conducteurExistant != null) {
        // L'utilisateur a déjà rejoint, retourner la session existante
        print('🔄 Utilisateur déjà dans la session, retour de la session existante');
        return session;
      }

      // Déterminer le rôle du véhicule
      final rolesUtilises = session.conducteurs.map((c) => c.roleVehicule).toList();
      final roleVehicule = _obtenirProchainRole(rolesUtilises);

      // Ajouter le conducteur
      final nouveauConducteur = ConducteurSession(
        userId: user.uid,
        nom: nomConducteur,
        prenom: prenomConducteur,
        email: emailConducteur,
        telephone: telephoneConducteur,
        roleVehicule: roleVehicule,
        estCreateur: false,
        aRejoint: true,
        dateRejoint: DateTime.now(),
      );

      final conducteursUpdated = [...session.conducteurs, nouveauConducteur];

      // Mettre à jour le statut si tous les conducteurs ont rejoint
      String nouveauStatut = session.statut;
      if (conducteursUpdated.length == session.nombreVehicules) {
        nouveauStatut = 'en_cours';
      }

      // Mettre à jour en Firestore
      await _firestore.collection(_collection).doc(session.id).update({
        'conducteurs': conducteursUpdated.map((c) => c.toMap()).toList(),
        'statut': nouveauStatut,
        'dateModification': FieldValue.serverTimestamp(),
      });

      // Retourner la session mise à jour
      return AccidentSessionComplete(
        id: session.id,
        codeSession: session.codeSession,
        typeAccident: session.typeAccident,
        nombreVehicules: session.nombreVehicules,
        statut: nouveauStatut,
        conducteurCreateur: session.conducteurCreateur,
        conducteurs: conducteursUpdated,
        infosGenerales: session.infosGenerales,
        vehicules: session.vehicules,
        circonstances: session.circonstances,
        croquis: session.croquis,
        photos: session.photos,
        signatures: session.signatures,
        dateCreation: session.dateCreation,
        dateModification: DateTime.now(),
      );
    } catch (e) {
      print('Erreur rejoindre session: $e');
      throw Exception('Impossible de rejoindre la session: $e');
    }
  }

  /// 📋 Obtenir une session par ID
  static Future<AccidentSessionComplete?> obtenirSession(String sessionId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(sessionId).get();
      
      if (!doc.exists) return null;
      
      return AccidentSessionComplete.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('Erreur obtenir session: $e');
      return null;
    }
  }

  /// 🔄 Écouter les changements d'une session en temps réel
  static Stream<AccidentSessionComplete?> ecouterSession(String sessionId) {
    return _firestore
        .collection(_collection)
        .doc(sessionId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return AccidentSessionComplete.fromMap(doc.data()!, doc.id);
        });
  }

  /// ✏️ Mettre à jour les informations générales
  static Future<void> mettreAJourInfosGenerales(
    String sessionId,
    InfosGeneralesAccident infosGenerales,
  ) async {
    try {
      await _firestore.collection(_collection).doc(sessionId).update({
        'infosGenerales': infosGenerales.toMap(),
        'dateModification': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur mise à jour infos générales: $e');
      throw Exception('Impossible de mettre à jour les informations générales');
    }
  }

  /// 🚗 Ajouter/Mettre à jour un véhicule
  static Future<void> mettreAJourVehicule(
    String sessionId,
    VehiculeAccident vehicule,
  ) async {
    try {
      final session = await obtenirSession(sessionId);
      if (session == null) throw Exception('Session non trouvée');

      // Mettre à jour ou ajouter le véhicule
      final vehiculesUpdated = [...session.vehicules];
      final index = vehiculesUpdated.indexWhere((v) => v.roleVehicule == vehicule.roleVehicule);
      
      if (index >= 0) {
        vehiculesUpdated[index] = vehicule;
      } else {
        vehiculesUpdated.add(vehicule);
      }

      await _firestore.collection(_collection).doc(sessionId).update({
        'vehicules': vehiculesUpdated.map((v) => v.toMap()).toList(),
        'dateModification': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur mise à jour véhicule: $e');
      throw Exception('Impossible de mettre à jour le véhicule');
    }
  }

  /// 📝 Mettre à jour les circonstances
  static Future<void> mettreAJourCirconstances(
    String sessionId,
    String roleVehicule,
    List<String> circonstances,
  ) async {
    try {
      final session = await obtenirSession(sessionId);
      if (session == null) throw Exception('Session non trouvée');

      final circonstancesUpdated = Map<String, List<String>>.from(
        session.circonstances.circonstancesParVehicule,
      );
      circonstancesUpdated[roleVehicule] = circonstances;

      await _firestore.collection(_collection).doc(sessionId).update({
        'circonstances.circonstancesParVehicule': circonstancesUpdated,
        'dateModification': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur mise à jour circonstances: $e');
      throw Exception('Impossible de mettre à jour les circonstances');
    }
  }

  /// 🎨 Mettre à jour le croquis
  static Future<void> mettreAJourCroquis(
    String sessionId,
    CroquisAccident croquis,
  ) async {
    try {
      await _firestore.collection(_collection).doc(sessionId).update({
        'croquis': croquis.toMap(),
        'dateModification': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur mise à jour croquis: $e');
      throw Exception('Impossible de mettre à jour le croquis');
    }
  }

  /// ✍️ Ajouter une signature
  static Future<void> ajouterSignature(
    String sessionId,
    String roleVehicule,
    String signatureData,
  ) async {
    try {
      await _firestore.collection(_collection).doc(sessionId).update({
        'signatures.$roleVehicule': signatureData,
        'dateModification': FieldValue.serverTimestamp(),
      });

      // Vérifier si toutes les signatures sont présentes
      final session = await obtenirSession(sessionId);
      if (session != null && session.signatures.length == session.nombreVehicules) {
        await _firestore.collection(_collection).doc(sessionId).update({
          'statut': 'signe',
          'dateFinalisation': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Erreur ajout signature: $e');
      throw Exception('Impossible d\'ajouter la signature');
    }
  }

  /// 🔢 Générer un code de session unique
  static String _genererCodeSession() {
    final random = Random();
    final code = random.nextInt(999999).toString().padLeft(6, '0');
    return code;
  }

  /// 🎯 Obtenir le prochain rôle de véhicule disponible
  static String _obtenirProchainRole(List<String> rolesUtilises) {
    const roles = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];
    
    for (final role in roles) {
      if (!rolesUtilises.contains(role)) {
        return role;
      }
    }
    
    return 'Z'; // Fallback
  }

  /// 📊 Obtenir les sessions d'un utilisateur
  static Future<List<AccidentSessionComplete>> obtenirSessionsUtilisateur(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('conducteurs', arrayContainsAny: [
            {'userId': userId}
          ])
          .orderBy('dateCreation', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AccidentSessionComplete.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Erreur obtenir sessions utilisateur: $e');
      return [];
    }
  }

  /// 🔄 Mettre à jour le statut de la session avec détails
  static Future<void> mettreAJourStatut(
    String sessionId,
    String nouveauStatut, {
    String? message,
    Map<String, dynamic>? metadonnees,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final updateData = {
        'statut': nouveauStatut,
        'dateModification': FieldValue.serverTimestamp(),
        'lastUpdatedBy': user?.uid,
      };

      if (message != null) {
        updateData['dernierMessage'] = message;
      }

      if (metadonnees != null) {
        updateData.addAll(metadonnees);
      }

      // Mettre à jour la session
      await _firestore.collection(_collection).doc(sessionId).update(updateData);

      // Ajouter à l'historique
      await _ajouterHistoriqueStatut(sessionId, nouveauStatut, message);

      // Notifier les participants
      await notifierParticipants(
        sessionId,
        message ?? 'Statut mis à jour: $nouveauStatut',
        titre: 'Mise à jour de session',
      );

      print('✅ Statut de la session mis à jour: $nouveauStatut');
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du statut: $e');
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }

  /// 📝 Ajouter un événement à l'historique de la session
  static Future<void> _ajouterHistoriqueStatut(
    String sessionId,
    String statut,
    String? message,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await _firestore
          .collection(_collection)
          .doc(sessionId)
          .collection('historique')
          .add({
        'statut': statut,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user?.uid,
        'userEmail': user?.email,
      });
    } catch (e) {
      print('❌ Erreur lors de l\'ajout à l\'historique: $e');
    }
  }

  /// 📜 Obtenir l'historique d'une session
  static Stream<QuerySnapshot> obtenirHistoriqueSession(String sessionId) {
    return _firestore
        .collection(_collection)
        .doc(sessionId)
        .collection('historique')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// 🔔 Notifier tous les participants d'un changement
  static Future<void> notifierParticipants(
    String sessionId,
    String message, {
    String? titre,
    Map<String, dynamic>? donnees,
  }) async {
    try {
      final session = await obtenirSession(sessionId);
      if (session == null) return;

      for (final conducteur in session.conducteurs) {
        await _firestore.collection('notifications').add({
          'userId': conducteur.userId,
          'sessionId': sessionId,
          'titre': titre ?? 'Mise à jour de session',
          'message': message,
          'type': 'session_update',
          'donnees': donnees,
          'lu': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      print('✅ Notifications envoyées à ${session.conducteurs.length} participants');
    } catch (e) {
      print('❌ Erreur lors de l\'envoi des notifications: $e');
    }
  }

  /// 📊 Obtenir les statistiques d'une session
  static Future<Map<String, dynamic>> obtenirStatistiquesSession(String sessionId) async {
    try {
      final session = await obtenirSession(sessionId);
      if (session == null) return {};

      final maintenant = DateTime.now();
      final dureeSession = maintenant.difference(session.dateCreation);

      // Calculer le pourcentage de completion
      int etapesCompletes = 0;
      int etapesTotales = 6; // infos, véhicules, assurance, circonstances, croquis, signatures

      if (session.infosGenerales.lieuAccident.isNotEmpty) etapesCompletes++;
      if (session.vehicules.isNotEmpty) etapesCompletes++;
      if (session.circonstances.circonstancesParVehicule.isNotEmpty) etapesCompletes++;
      if (session.croquis.croquisData.isNotEmpty) etapesCompletes++;
      if (session.signatures.isNotEmpty) etapesCompletes++;
      if (session.photos.isNotEmpty) etapesCompletes++;

      final pourcentageCompletion = (etapesCompletes / etapesTotales * 100).round();

      return {
        'dureeSession': dureeSession.inMinutes,
        'pourcentageCompletion': pourcentageCompletion,
        'etapesCompletes': etapesCompletes,
        'etapesTotales': etapesTotales,
        'nombreParticipants': session.conducteurs.length,
        'nombreVehiculesMax': session.nombreVehicules,
        'sessionComplete': session.conducteurs.length == session.nombreVehicules,
        'derniereMiseAJour': session.dateModification ?? session.dateCreation,
      };
    } catch (e) {
      print('❌ Erreur lors du calcul des statistiques: $e');
      return {};
    }
  }

  /// 🎯 Obtenir une session par ID avec alias
  static Future<AccidentSessionComplete?> obtenirSessionParId(String sessionId) async {
    return await obtenirSession(sessionId);
  }

  /// 🔍 Rechercher des sessions par critères
  static Future<List<AccidentSessionComplete>> rechercherSessions({
    String? statut,
    String? typeAccident,
    DateTime? dateDebut,
    DateTime? dateFin,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      if (statut != null) {
        query = query.where('statut', isEqualTo: statut);
      }

      if (typeAccident != null) {
        query = query.where('typeAccident', isEqualTo: typeAccident);
      }

      if (dateDebut != null) {
        query = query.where('dateCreation', isGreaterThanOrEqualTo: Timestamp.fromDate(dateDebut));
      }

      if (dateFin != null) {
        query = query.where('dateCreation', isLessThanOrEqualTo: Timestamp.fromDate(dateFin));
      }

      query = query.orderBy('dateCreation', descending: true).limit(limit);

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => AccidentSessionComplete.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('❌ Erreur lors de la recherche: $e');
      return [];
    }
  }

  /// 🏁 Terminer une session et créer le sinistre
  static Future<String> terminerSessionEtCreerSinistre({
    required String sessionId,
    required String conducteurId,
    required Map<String, dynamic> vehiculeInfo,
    required Map<String, dynamic> contratInfo,
  }) async {
    try {
      // Récupérer la session
      final sessionDoc = await _firestore.collection(_collection).doc(sessionId).get();
      if (!sessionDoc.exists) {
        throw Exception('Session non trouvée');
      }

      final session = AccidentSessionComplete.fromMap(sessionDoc.data()!, sessionId);

      // Mettre à jour le statut de la session
      await _firestore.collection(_collection).doc(sessionId).update({
        'statut': 'termine',
        'dateTerminaison': FieldValue.serverTimestamp(),
      });

      // Créer le sinistre
      final sinistreId = await SinistreService.creerSinistreDepuisSession(
        session: session,
        conducteurId: conducteurId,
        vehiculeInfo: vehiculeInfo,
        contratInfo: contratInfo,
      );

      return sinistreId;
    } catch (e) {
      throw Exception('Erreur lors de la finalisation: $e');
    }
  }

  /// 📊 Mettre à jour le statut de session simple
  static Future<void> updateStatutSession({
    required String sessionId,
    required String nouveauStatut,
  }) async {
    try {
      await _firestore.collection(_collection).doc(sessionId).update({
        'statut': nouveauStatut,
        'dateModification': FieldValue.serverTimestamp(),
      });

      // Synchroniser avec le sinistre si il existe
      await SinistreService.synchroniserAvecSession(sessionId);
    } catch (e) {
      throw Exception('Erreur mise à jour statut: $e');
    }
  }
}

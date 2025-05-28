import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/constat_model.dart';
import '../models/conducteur_info_model.dart' as conducteur_models;
import '../models/vehicule_accident_model.dart' as vehicule_models;
import '../models/assurance_info_model.dart' as assurance_models;
import '../models/temoin_model.dart' as temoin_models;

class ConstatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<ConstatModel> _constats = [];
  bool _isLoading = false;
  String? _errorMessage;
  double _uploadProgress = 0.0;

  List<ConstatModel> get constats => _constats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get uploadProgress => _uploadProgress;

  Future<void> sauvegarderConstatComplet({
    required ConstatModel constat,
    required conducteur_models.ConducteurInfoModel conducteurInfo,
    required vehicule_models.VehiculeAccidentModel vehiculeInfo,
    required assurance_models.AssuranceInfoModel assuranceInfo,
    required List<temoin_models.TemoinModel> temoins,
    required List<File> photosAccident,
    File? photoPermis,
    File? photoCarteGrise,
    File? photoAttestation,
    Uint8List? signature,
  }) async {
    try {
      _setLoading(true);
      _uploadProgress = 0.0;

      // 1. Créer le conducteur
      _uploadProgress = 0.1;
      notifyListeners();
      
      final conducteurDoc = await _firestore.collection('conducteurs').add(conducteurInfo.toMap());
      final conducteurId = conducteurDoc.id;

      // 2. Upload photo permis si disponible
      String? urlPhotoPermis;
      if (photoPermis != null) {
        _uploadProgress = 0.2;
        notifyListeners();
        urlPhotoPermis = await _uploadFile(
          photoPermis,
          'conducteurs/$conducteurId/permis.jpg',
        );
        
        await conducteurDoc.update({'photoPermisUrl': urlPhotoPermis});
      }

      // 3. Créer le véhicule
      _uploadProgress = 0.3;
      notifyListeners();
      
      final vehiculeAvecConducteur = vehicule_models.VehiculeAccidentModel(
        marque: vehiculeInfo.marque,
        type: vehiculeInfo.type,
        numeroImmatriculation: vehiculeInfo.numeroImmatriculation,
        sensCirculation: vehiculeInfo.sensCirculation,
        venantDe: vehiculeInfo.venantDe,
        allantA: vehiculeInfo.allantA,
        degatsApparents: vehiculeInfo.degatsApparents,
        conducteurId: conducteurId,
        createdAt: vehiculeInfo.createdAt,
      );
      
      final vehiculeDoc = await _firestore.collection('vehicules_accident').add(vehiculeAvecConducteur.toMap());
      final vehiculeId = vehiculeDoc.id;

      // 4. Upload photo carte grise si disponible
      String? urlPhotoCarteGrise;
      if (photoCarteGrise != null) {
        _uploadProgress = 0.4;
        notifyListeners();
        urlPhotoCarteGrise = await _uploadFile(
          photoCarteGrise,
          'vehicules/$vehiculeId/carte_grise.jpg',
        );
        
        await vehiculeDoc.update({'photoCarteGriseUrl': urlPhotoCarteGrise});
      }

      // 5. Créer l'assurance
      _uploadProgress = 0.5;
      notifyListeners();
      
      final assuranceAvecConducteur = assurance_models.AssuranceInfoModel(
        societeAssurance: assuranceInfo.societeAssurance,
        numeroContrat: assuranceInfo.numeroContrat,
        agence: assuranceInfo.agence,
        conducteurId: conducteurId,
        createdAt: assuranceInfo.createdAt,
      );
      
      final assuranceDoc = await _firestore.collection('assurances').add(assuranceAvecConducteur.toMap());

      // 6. Upload photo attestation si disponible
      String? urlPhotoAttestation;
      if (photoAttestation != null) {
        _uploadProgress = 0.6;
        notifyListeners();
        urlPhotoAttestation = await _uploadFile(
          photoAttestation,
          'assurances/${assuranceDoc.id}/attestation.jpg',
        );
        
        await assuranceDoc.update({'photoAttestationUrl': urlPhotoAttestation});
      }

      // 7. Créer le constat principal
      _uploadProgress = 0.7;
      notifyListeners();
      
      final constatDoc = await _firestore.collection('constats').add(constat.toMap());
      final constatId = constatDoc.id;

      // 8. Créer les témoins
      List<String> temoinsIds = [];
      for (temoin_models.TemoinModel temoin in temoins) {
        final temoinAvecConstat = temoin_models.TemoinModel(
          nom: temoin.nom,
          adresse: temoin.adresse,
          telephone: temoin.telephone,
          estPassagerA: temoin.estPassagerB,
          estPassagerB: temoin.estPassagerB,
          constatId: constatId,
          createdAt: temoin.createdAt,
        );
        
        final temoinDoc = await _firestore.collection('temoins').add(temoinAvecConstat.toMap());
        temoinsIds.add(temoinDoc.id);
      }

      // 9. Upload photos accident
      _uploadProgress = 0.8;
      notifyListeners();
      
      List<String> urlsPhotosAccident = [];
      for (int i = 0; i < photosAccident.length; i++) {
        final url = await _uploadFile(
          photosAccident[i],
          'constats/$constatId/accident_$i.jpg',
        );
        urlsPhotosAccident.add(url);
      }

      // 10. Upload signature si disponible
      String? urlSignature;
      if (signature != null) {
        _uploadProgress = 0.9;
        notifyListeners();
        urlSignature = await _uploadSignature(
          signature,
          'constats/$constatId/signature.png',
        );
      }

      // 11. Mettre à jour le constat avec tous les IDs et URLs
      _uploadProgress = 0.95;
      notifyListeners();
      
      await constatDoc.update({
        'id': constatId,
        'vehiculeIds': [vehiculeId],
        'conducteurIds': [conducteurId],
        'temoinsIds': temoinsIds,
        'photosUrls': urlsPhotosAccident,
        'croquis': urlSignature,
        'updatedAt': DateTime.now(),
      });

      // 12. Créer le constat final pour la liste locale
      final constatFinal = constat.copyWith(
        id: constatId,
        vehiculeIds: [vehiculeId],
        conducteurIds: [conducteurId],
        temoinsIds: temoinsIds,
        photosUrls: urlsPhotosAccident,
        croquis: urlSignature,
        updatedAt: DateTime.now(),
      );

      _constats.add(constatFinal);
      _uploadProgress = 1.0;
      _setLoading(false);
      
    } catch (e) {
      _setError('Erreur lors de la sauvegarde: $e');
      _setLoading(false);
      rethrow;
    }
  }

  Future<String> _uploadFile(File file, String path) async {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<String> _uploadSignature(Uint8List signature, String path) async {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putData(signature);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> fetchConstatsByUserId(String userId) async {
    try {
      _setLoading(true);
      
      final querySnapshot = await _firestore
          .collection('constats')
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _constats = querySnapshot.docs
          .map((doc) => ConstatModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors du chargement: $e');
      _setLoading(false);
    }
  }

  Future<void> validerConstat(String constatId, String userId) async {
    try {
      await _firestore.collection('constats').doc(constatId).update({
        'validationStatus.$userId': true,
        'status': 'validated',
        'updatedAt': DateTime.now(),
      });

      final index = _constats.indexWhere((c) => c.id == constatId);
      if (index != -1) {
        final updatedValidation = Map<String, bool>.from(_constats[index].validationStatus);
        updatedValidation[userId] = true;
        
        _constats[index] = _constats[index].copyWith(
          validationStatus: updatedValidation,
          status: ConstatStatus.validated,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      _setError('Erreur lors de la validation: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getConstatComplet(String constatId) async {
    try {
      // Récupérer le constat principal
      final constatDoc = await _firestore.collection('constats').doc(constatId).get();
      if (!constatDoc.exists) throw Exception('Constat non trouvé');
      
      final constat = ConstatModel.fromMap({...constatDoc.data()!, 'id': constatDoc.id});
      
      // Récupérer les conducteurs
      List<conducteur_models.ConducteurInfoModel> conducteurs = [];
      for (String conducteurId in constat.conducteurIds) {
        final conducteurDoc = await _firestore.collection('conducteurs').doc(conducteurId).get();
        if (conducteurDoc.exists) {
          conducteurs.add(conducteur_models.ConducteurInfoModel.fromMap({...conducteurDoc.data()!, 'id': conducteurDoc.id}));
        }
      }
      
      // Récupérer les véhicules
      List<vehicule_models.VehiculeAccidentModel> vehicules = [];
      for (String vehiculeId in constat.vehiculeIds) {
        final vehiculeDoc = await _firestore.collection('vehicules_accident').doc(vehiculeId).get();
        if (vehiculeDoc.exists) {
          vehicules.add(vehicule_models.VehiculeAccidentModel.fromMap({...vehiculeDoc.data()!, 'id': vehiculeDoc.id}));
        }
      }
      
      // Récupérer les témoins
      List<temoin_models.TemoinModel> temoins = [];
      for (String temoinId in constat.temoinsIds) {
        final temoinDoc = await _firestore.collection('temoins').doc(temoinId).get();
        if (temoinDoc.exists) {
          temoins.add(temoin_models.TemoinModel.fromMap({...temoinDoc.data()!, 'id': temoinDoc.id}));
        }
      }
      
      return {
        'constat': constat,
        'conducteurs': conducteurs,
        'vehicules': vehicules,
        'temoins': temoins,
      };
    } catch (e) {
      _setError('Erreur lors du chargement du constat complet: $e');
      rethrow;
    }
  }

  // ========== MÉTHODES COLLABORATIVES ==========

// Créer une session collaborative
Future<String> creerSessionCollaborative({
  required String createdBy,
  required int nombreConducteurs,
  required Map<String, dynamic> accidentInfo,
}) async {
  try {
    final sessionDoc = await _firestore.collection('sessions_collaboratives').add({
      'createdBy': createdBy,
      'nombreConducteurs': nombreConducteurs,
      'accidentInfo': accidentInfo,
      'status': 'active',
      'participantsJoints': [createdBy],
      'conducteursData': {},
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    });
    
    return sessionDoc.id;
  } catch (e) {
    _setError('Erreur lors de la création de session: $e');
    rethrow;
  }
}

// Créer une invitation
Future<void> creerInvitation({
  required String sessionId,
  required String email,
  required String position,
  required String invitedBy,
}) async {
  try {
    await _firestore.collection('invitations').add({
      'sessionId': sessionId,
      'email': email,
      'position': position,
      'invitedBy': invitedBy,
      'status': 'pending',
      'createdAt': DateTime.now(),
    });
  } catch (e) {
    _setError('Erreur lors de la création d\'invitation: $e');
    rethrow;
  }
}

// Envoyer email d'invitation
Future<void> envoyerEmailInvitation({
  required String email,
  required String sessionId,
  required String position,
}) async {
  try {
    // Simuler l'envoi d'email (à remplacer par un vrai service)
    await Future.delayed(Duration(seconds: 1));
    
    // Dans un vrai projet, utiliser un service comme SendGrid, Firebase Functions, etc.
    print('Email envoyé à $email pour rejoindre la session $sessionId en position $position');
    
    // Marquer l'invitation comme envoyée
    final invitations = await _firestore
        .collection('invitations')
        .where('sessionId', isEqualTo: sessionId)
        .where('email', isEqualTo: email)
        .get();
    
    for (var doc in invitations.docs) {
      await doc.reference.update({
        'emailSent': true,
        'sentAt': DateTime.now(),
      });
    }
  } catch (e) {
    _setError('Erreur lors de l\'envoi d\'email: $e');
    rethrow;
  }
}

// Rejoindre une session
Future<Map<String, dynamic>> rejoindreSesssion(String sessionId, String userId) async {
  try {
    final sessionDoc = await _firestore.collection('sessions_collaboratives').doc(sessionId).get();
    
    if (!sessionDoc.exists) {
      throw Exception('Session non trouvée');
    }
    
    final sessionData = sessionDoc.data()!;
    
    // Vérifier si l'utilisateur peut rejoindre
    final participantsJoints = List<String>.from(sessionData['participantsJoints'] ?? []);
    
    if (!participantsJoints.contains(userId)) {
      // Ajouter l'utilisateur aux participants
      participantsJoints.add(userId);
      
      await sessionDoc.reference.update({
        'participantsJoints': participantsJoints,
        'updatedAt': DateTime.now(),
      });
    }
    
    return {
      'sessionId': sessionId,
      'sessionData': sessionData,
      'position': _determinerPosition(participantsJoints, userId),
    };
  } catch (e) {
    _setError('Erreur lors de la connexion à la session: $e');
    rethrow;
  }
}

// Obtenir les données d'une session
Future<Map<String, dynamic>?> getSessionData(String sessionId) async {
  try {
    final sessionDoc = await _firestore.collection('sessions_collaboratives').doc(sessionId).get();
    
    if (!sessionDoc.exists) return null;
    
    return sessionDoc.data();
  } catch (e) {
    _setError('Erreur lors de la récupération des données de session: $e');
    return null;
  }
}

// Sauvegarder les données d'un conducteur dans une session
Future<void> sauvegarderDonneesConducteurSession({
  required String sessionId,
  required String position,
  required Map<String, dynamic> donneesCompletesConstat,
}) async {
  try {
    await _firestore.collection('sessions_collaboratives').doc(sessionId).update({
      'conducteursData.$position': donneesCompletesConstat,
      'updatedAt': DateTime.now(),
    });
  } catch (e) {
    _setError('Erreur lors de la sauvegarde des données: $e');
    rethrow;
  }
}

// Sauvegarder constat collaboratif complet
Future<void> sauvegarderConstatCollaboratif({
  required String sessionId,
  required Map<String, dynamic> donneesCompletesConstat,
}) async {
  try {
    _setLoading(true);
    
    // Récupérer les données de la session
    final sessionDoc = await _firestore.collection('sessions_collaboratives').doc(sessionId).get();
    if (!sessionDoc.exists) throw Exception('Session non trouvée');
    
    final sessionData = sessionDoc.data()!;
    final conducteursData = Map<String, dynamic>.from(sessionData['conducteursData'] ?? {});
    
    // Créer le constat principal avec toutes les données
    final constatDoc = await _firestore.collection('constats').add({
      ...donneesCompletesConstat,
      'sessionId': sessionId,
      'isCollaborative': true,
      'participantsData': conducteursData,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    });
    
    // Marquer la session comme terminée
    await sessionDoc.reference.update({
      'status': 'completed',
      'constatId': constatDoc.id,
      'completedAt': DateTime.now(),
    });
    
    _setLoading(false);
  } catch (e) {
    _setError('Erreur lors de la sauvegarde du constat collaboratif: $e');
    _setLoading(false);
    rethrow;
  }
}

// Écouter les changements d'une session en temps réel
Stream<DocumentSnapshot> ecouterSession(String sessionId) {
  return _firestore.collection('sessions_collaboratives').doc(sessionId).snapshots();
}

// Déterminer la position d'un utilisateur dans la session
String _determinerPosition(List<String> participantsJoints, String userId) {
  final positions = ['A', 'B', 'C', 'D', 'E'];
  final index = participantsJoints.indexOf(userId);
  return index >= 0 && index < positions.length ? positions[index] : 'A';
}

// Vérifier si une session existe
Future<bool> sessionExiste(String sessionId) async {
  try {
    final doc = await _firestore.collection('sessions_collaboratives').doc(sessionId).get();
    return doc.exists;
  } catch (e) {
    return false;
  }
}

// Obtenir les invitations d'un utilisateur
Future<List<Map<String, dynamic>>> getInvitationsUtilisateur(String email) async {
  try {
    final querySnapshot = await _firestore
        .collection('invitations')
        .where('email', isEqualTo: email)
        .where('status', isEqualTo: 'pending')
        .get();
    
    return querySnapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  } catch (e) {
    _setError('Erreur lors de la récupération des invitations: $e');
    return [];
  }
}

  void _setLoading(bool loading) {
    _isLoading = loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }
}

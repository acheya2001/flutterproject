import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/constat_model.dart';
import '../models/participant_model.dart';
// Import supprimé car non utilisé
import '../../vehicule/services/vehicule_service.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/notification_service.dart';

class ConstatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final VehiculeService _vehiculeService = VehiculeService();
  final OCRService _ocrService = OCRService();
  final AIService _aiService = AIService();
  final NotificationService _notificationService = NotificationService();
  final Uuid _uuid = const Uuid();

  // Créer un nouveau constat
  Future<ConstatModel> createConstat({
    required String userId,
    required DateTime dateAccident,
    required String lieuAccident,
    GeoPoint? coordonnees,
    String? adresseAccident,
  }) async {
    try {
      debugPrint('[ConstatService] Création d\'un nouveau constat');
      
      final String constatId = _uuid.v4();
      final now = DateTime.now();
      
      final constatData = {
        'id': constatId,
        'dateAccident': dateAccident,
        'lieuAccident': lieuAccident,
        'coordonnees': coordonnees,
        'adresseAccident': adresseAccident,
        'vehiculeIds': <String>[],
        'conducteurIds': <String>[],
        'temoinsIds': <String>[],
        'photosUrls': <String>[],
        'validationStatus': <String, bool>{},
        'status': ConstatStatus.draft.toString().split('.').last,
        'createdAt': now,
        'updatedAt': now,
        'createdBy': userId,
      };
      
      await _firestore.collection('constats').doc(constatId).set(constatData);
      
      debugPrint('[ConstatService] Constat créé avec ID: $constatId');
      
      return ConstatModel(
        id: constatId,
        dateAccident: dateAccident,
        lieuAccident: lieuAccident,
        coordonnees: coordonnees,
        adresseAccident: adresseAccident,
        vehiculeIds: [],
        conducteurIds: [],
        validationStatus: {},
        status: ConstatStatus.draft,
        createdAt: now,
        updatedAt: now,
        createdBy: userId,
      );
    } catch (e) {
      debugPrint('[ConstatService] Erreur lors de la création du constat: $e');
      rethrow;
    }
  }

  // Ajouter un véhicule au constat
  Future<void> addVehiculeToConstat({
    required String constatId,
    required String vehiculeId,
  }) async {
    try {
      debugPrint('[ConstatService] Ajout du véhicule $vehiculeId au constat $constatId');
      
      final constatDoc = await _firestore.collection('constats').doc(constatId).get();
      if (!constatDoc.exists) {
        throw Exception('Constat non trouvé');
      }
      
      final List<String> vehiculeIds = List<String>.from(constatDoc.data()?['vehiculeIds'] ?? []);
      if (!vehiculeIds.contains(vehiculeId)) {
        vehiculeIds.add(vehiculeId);
        
        await _firestore.collection('constats').doc(constatId).update({
          'vehiculeIds': vehiculeIds,
          'updatedAt': DateTime.now(),
        });
        
        debugPrint('[ConstatService] Véhicule ajouté avec succès');
      } else {
        debugPrint('[ConstatService] Le véhicule est déjà associé à ce constat');
      }
    } catch (e) {
      debugPrint('[ConstatService] Erreur lors de l\'ajout du véhicule: $e');
      rethrow;
    }
  }

  // Ajouter un participant au constat
  Future<ParticipantModel> addParticipantToConstat({
    required String constatId,
    required String nom,
    required String prenom,
    required String telephone,
    String? email,
    String? adresse,
    required ParticipantRole role,
    String? vehiculeId,
    bool estProprietaire = false,
    String? userId,
    String? permisNumero,
    DateTime? permisDelivreLe,
    DateTime? permisValideJusquau,
    File? photoPermis,
    File? photoCIN,
  }) async {
    try {
      debugPrint('[ConstatService] Ajout d\'un participant au constat $constatId');
      
      final String participantId = _uuid.v4();
      final now = DateTime.now();
      
      // Vérifier si le permis est valide
      bool permisValide = false;
      if (permisValideJusquau != null) {
        permisValide = permisValideJusquau.isAfter(DateTime.now());
      }
      
      // Vérifier si l'assurance est valide (si un véhicule est spécifié)
      bool assuranceValide = false;
      if (vehiculeId != null) {
        final vehicule = await _vehiculeService.getVehiculeById(vehiculeId);
        if (vehicule != null && vehicule.dateFinValidite != null) {
          // Correction: Utilisation de l'opérateur ! pour éviter l'erreur null
          assuranceValide = vehicule.dateFinValidite!.isAfter(DateTime.now());
        }
      }
      
      // Uploader les photos si fournies
      String? urlPhotoPermis;
      String? urlPhotoCIN;
      
      if (photoPermis != null) {
        final permisRef = _storage.ref().child('permis/$participantId.jpg');
        await permisRef.putFile(photoPermis);
        urlPhotoPermis = await permisRef.getDownloadURL();
        
        // Extraire les informations du permis via OCR
        final permisInfo = await _ocrService.extractPermisInfo(photoPermis);
        if (permisInfo != null) {
          permisNumero = permisInfo['numero'] ?? permisNumero;
          permisDelivreLe = permisInfo['delivreLe'] ?? permisDelivreLe;
          permisValideJusquau = permisInfo['valideJusquau'] ?? permisValideJusquau;
          
          // Vérifier à nouveau la validité du permis
          if (permisValideJusquau != null) {
            permisValide = permisValideJusquau.isAfter(DateTime.now());
          }
        }
      }
      
      if (photoCIN != null) {
        final cinRef = _storage.ref().child('cin/$participantId.jpg');
        await cinRef.putFile(photoCIN);
        urlPhotoCIN = await cinRef.getDownloadURL();
        
        // Extraire les informations de la CIN via OCR
        final cinInfo = await _ocrService.extractCINInfo(photoCIN);
        if (cinInfo != null) {
          nom = cinInfo['nom'] ?? nom;
          prenom = cinInfo['prenom'] ?? prenom;
          adresse = cinInfo['adresse'] ?? adresse;
        }
      }
      
      final participantData = {
        'id': participantId,
        'constatId': constatId,
        'userId': userId,
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'email': email,
        'adresse': adresse,
        'permisNumero': permisNumero,
        'permisDelivreLe': permisDelivreLe,
        'permisValideJusquau': permisValideJusquau,
        'urlPhotoPermis': urlPhotoPermis,
        'urlPhotoCIN': urlPhotoCIN,
        'role': role.toString().split('.').last,
        'vehiculeId': vehiculeId,
        'estProprietaire': estProprietaire,
        'permisValide': permisValide,
        'assuranceValide': assuranceValide,
        'createdAt': now,
        'updatedAt': now,
      };
      
      await _firestore.collection('participants').doc(participantId).set(participantData);
      
      // Mettre à jour le constat avec l'ID du participant
      final constatDoc = await _firestore.collection('constats').doc(constatId).get();
      if (constatDoc.exists) {
        final List<String> conducteurIds = List<String>.from(constatDoc.data()?['conducteurIds'] ?? []);
        final List<String> temoinsIds = List<String>.from(constatDoc.data()?['temoinsIds'] ?? []);
        
        if (role == ParticipantRole.conducteur) {
          if (!conducteurIds.contains(participantId)) {
            conducteurIds.add(participantId);
          }
        } else if (role == ParticipantRole.temoin) {
          if (!temoinsIds.contains(participantId)) {
            temoinsIds.add(participantId);
          }
        }
        
        await _firestore.collection('constats').doc(constatId).update({
          'conducteurIds': conducteurIds,
          'temoinsIds': temoinsIds,
          'updatedAt': now,
        });
      }
      
      debugPrint('[ConstatService] Participant ajouté avec ID: $participantId');
      
      return ParticipantModel(
        id: participantId,
        constatId: constatId,
        userId: userId,
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        email: email,
        adresse: adresse,
        permisNumero: permisNumero,
        permisDelivreLe: permisDelivreLe,
        permisValideJusquau: permisValideJusquau,
        urlPhotoPermis: urlPhotoPermis,
        urlPhotoCIN: urlPhotoCIN,
        role: role,
        vehiculeId: vehiculeId,
        estProprietaire: estProprietaire,
        permisValide: permisValide,
        assuranceValide: assuranceValide,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      debugPrint('[ConstatService] Erreur lors de l\'ajout du participant: $e');
      rethrow;
    }
  }

  // Ajouter des photos au constat
  Future<List<String>> addPhotosToConstat({
    required String constatId,
    required List<File> photos,
  }) async {
    try {
      debugPrint('[ConstatService] Ajout de ${photos.length} photos au constat $constatId');
      
      final List<String> photoUrls = [];
      
      for (int i = 0; i < photos.length; i++) {
        final File photo = photos[i];
        final String photoId = _uuid.v4();
        final photoRef = _storage.ref().child('constats/$constatId/photos/$photoId.jpg');
        
        await photoRef.putFile(photo);
        final String photoUrl = await photoRef.getDownloadURL();
        photoUrls.add(photoUrl);
      }
      
      // Mettre à jour le constat avec les URLs des photos
      final constatDoc = await _firestore.collection('constats').doc(constatId).get();
      if (constatDoc.exists) {
        final List<String> existingPhotos = List<String>.from(constatDoc.data()?['photosUrls'] ?? []);
        existingPhotos.addAll(photoUrls);
        
        await _firestore.collection('constats').doc(constatId).update({
          'photosUrls': existingPhotos,
          'updatedAt': DateTime.now(),
        });
      }
      
      debugPrint('[ConstatService] Photos ajoutées avec succès');
      return photoUrls;
    } catch (e) {
      debugPrint('[ConstatService] Erreur lors de l\'ajout des photos: $e');
      rethrow;
    }
  }

  // Ajouter une description vocale et générer une reconstruction
  Future<Map<String, String>> addVocalDescriptionAndGenerateReconstruction({
    required String constatId,
    required File audioFile,
    required List<String> photoUrls,
  }) async {
    try {
      debugPrint('[ConstatService] Ajout d\'une description vocale et génération de reconstruction pour le constat $constatId');
      
      // Uploader le fichier audio
      final audioRef = _storage.ref().child('constats/$constatId/audio/description.mp3');
      await audioRef.putFile(audioFile);
      final String audioUrl = await audioRef.getDownloadURL();
      
      // Transcrire l'audio en texte
      final String transcription = await _aiService.transcribeAudio(audioFile);
      
      // Générer une reconstruction vidéo basée sur les photos et la description
      final String videoUrl = await _aiService.generateAccidentReconstruction(
        photoUrls: photoUrls,
        description: transcription,
      );
      
      // Mettre à jour le constat
      await _firestore.collection('constats').doc(constatId).update({
        'descriptionVocale': audioUrl,
        'transcriptionDescription': transcription,
        'videoReconstruction': videoUrl,
        'updatedAt': DateTime.now(),
      });
      
      debugPrint('[ConstatService] Description vocale et reconstruction générées avec succès');
      
      return {
        'audioUrl': audioUrl,
        'transcription': transcription,
        'videoUrl': videoUrl,
      };
    } catch (e) {
      debugPrint('[ConstatService] Erreur lors de l\'ajout de la description vocale: $e');
      rethrow;
    }
  }

  // Générer un croquis de l'accident
  Future<String> generateAccidentSketch({
    required String constatId,
    required List<String> photoUrls,
    required String description,
  }) async {
    try {
      debugPrint('[ConstatService] Génération d\'un croquis pour le constat $constatId');
      
      // Utiliser l'IA pour générer un croquis
      final String sketchUrl = await _aiService.generateAccidentSketch(
        photoUrls: photoUrls,
        description: description,
      );
      
      // Mettre à jour le constat
      await _firestore.collection('constats').doc(constatId).update({
        'croquis': sketchUrl,
        'updatedAt': DateTime.now(),
      });
      
      debugPrint('[ConstatService] Croquis généré avec succès');
      return sketchUrl;
    } catch (e) {
      debugPrint('[ConstatService] Erreur lors de la génération du croquis: $e');
      rethrow;
    }
  }

  // Inviter un autre conducteur à participer au constat
  Future<void> inviteConducteur({
    required String constatId,
    required String telephone,
    String? email,
    String? nom,
    String? prenom,
  }) async {
    try {
      debugPrint('[ConstatService] Invitation d\'un conducteur pour le constat $constatId');
      
      // Générer un code d'invitation unique
      final String invitationCode = _uuid.v4().substring(0, 6).toUpperCase();
      
      // Enregistrer l'invitation dans Firestore
      await _firestore.collection('invitations').add({
        'constatId': constatId,
        'telephone': telephone,
        'email': email,
        'nom': nom,
        'prenom': prenom,
        'code': invitationCode,
        'status': 'pending',
        'createdAt': DateTime.now(),
      });
      
      // Envoyer une notification SMS
      await _notificationService.sendSMS(
        to: telephone,
        message: 'Vous avez été invité à participer à un constat d\'accident. '
                'Utilisez le code $invitationCode pour rejoindre le constat dans l\'application Constat Tunisie.',
      );
      
      // Envoyer un email si disponible
      if (email != null) {
        await _notificationService.sendEmail(
          to: email,
          subject: 'Invitation à participer à un constat d\'accident',
          body: 'Vous avez été invité à participer à un constat d\'accident. '
                'Utilisez le code $invitationCode pour rejoindre le constat dans l\'application Constat Tunisie.',
        );
      }
      
      debugPrint('[ConstatService] Invitation envoyée avec succès');
    } catch (e) {
      debugPrint('[ConstatService] Erreur lors de l\'invitation du conducteur: $e');
      rethrow;
    }
  }

  // Valider un constat par un conducteur
  Future<void> validateConstat({
    required String constatId,
    required String participantId,
  }) async {
    try {
      debugPrint('[ConstatService] Validation du constat $constatId par le participant $participantId');
      
      // Récupérer le constat
      final constatDoc = await _firestore.collection('constats').doc(constatId).get();
      if (!constatDoc.exists) {
        throw Exception('Constat non trouvé');
      }
      
      // Récupérer le participant
      final participantDoc = await _firestore.collection('participants').doc(participantId).get();
      if (!participantDoc.exists) {
        throw Exception('Participant non trouvé');
      }
      
      // Vérifier que le participant est bien un conducteur
      final participantData = participantDoc.data();
      if (participantData == null || participantData['role'] != 'conducteur') {
        throw Exception('Seuls les conducteurs peuvent valider un constat');
      }
      
      // Mettre à jour le statut de validation
      final Map<String, bool> validationStatus = Map<String, bool>.from(constatDoc.data()?['validationStatus'] ?? {});
      validationStatus[participantId] = true;
      
      await _firestore.collection('constats').doc(constatId).update({
        'validationStatus': validationStatus,
        'updatedAt': DateTime.now(),
      });
      
      // Vérifier si tous les conducteurs ont validé
      final List<String> conducteurIds = List<String>.from(constatDoc.data()?['conducteurIds'] ?? []);
      bool allValidated = true;
      
      for (final conducteurId in conducteurIds) {
        if (validationStatus[conducteurId] != true) {
          allValidated = false;
          break;
        }
      }
      
      // Si tous les conducteurs ont validé, mettre à jour le statut du constat
      if (allValidated) {
        await _firestore.collection('constats').doc(constatId).update({
          'status': ConstatStatus.validated.toString().split('.').last,
          'updatedAt': DateTime.now(),
        });
        
        debugPrint('[ConstatService] Tous les conducteurs ont validé le constat');
      }
      
      debugPrint('[ConstatService] Constat validé par le participant avec succès');
    } catch (e) {
      debugPrint('[ConstatService] Erreur lors de la validation du constat: $e');
      rethrow;
    }
  }

  // Soumettre un constat validé à l'assurance
  Future<void> submitConstatToInsurance({
    required String constatId,
  }) async {
    try {
      debugPrint('[ConstatService] Soumission du constat $constatId à l\'assurance');
      
      // Récupérer le constat
      final constatDoc = await _firestore.collection('constats').doc(constatId).get();
      if (!constatDoc.exists) {
        throw Exception('Constat non trouvé');
      }
      
      // Vérifier que le constat est validé
      final constatStatus = constatDoc.data()?['status'];
      if (constatStatus != ConstatStatus.validated.toString().split('.').last) {
        throw Exception('Le constat doit être validé par tous les conducteurs avant d\'être soumis');
      }
      
      // Mettre à jour le statut du constat
      await _firestore.collection('constats').doc(constatId).update({
        'status': ConstatStatus.submitted.toString().split('.').last,
        'updatedAt': DateTime.now(),
      });
      
      // Notifier les assureurs concernés
      final List<String> vehiculeIds = List<String>.from(constatDoc.data()?['vehiculeIds'] ?? []);
      for (final vehiculeId in vehiculeIds) {
        final vehicule = await _vehiculeService.getVehiculeById(vehiculeId);
        if (vehicule != null && vehicule.assureur != null) {
          // Rechercher les assureurs de cette compagnie
          final assureursQuery = await _firestore.collection('assureurs')
              .where('compagnie', isEqualTo: vehicule.assureur)
              .get();
          
          for (final assureurDoc in assureursQuery.docs) {
            final assureurId = assureurDoc.id;
            final assureurData = assureurDoc.data();
            
            // Ajouter le constat à la liste des dossiers de l'assureur
            final List<String> dossierIds = List<String>.from(assureurData['dossierIds'] ?? []);
            if (!dossierIds.contains(constatId)) {
              dossierIds.add(constatId);
              
              await _firestore.collection('assureurs').doc(assureurId).update({
                'dossierIds': dossierIds,
              });
            }
            
            // Récupérer l'utilisateur associé à cet assureur
            final userDoc = await _firestore.collection('users').doc(assureurId).get();
            if (userDoc.exists) {
              // Correction: Suppression de la vérification inutile avec null
              final userData = userDoc.data()!;
              
              // Envoyer une notification
              if (userData['email'] != null) {
                await _notificationService.sendEmail(
                  to: userData['email'],
                  subject: 'Nouveau constat soumis',
                  body: 'Un nouveau constat d\'accident a été soumis et nécessite votre attention.',
                );
              }
            }
          }
        }
      }
      
      debugPrint('[ConstatService] Constat soumis à l\'assurance avec succès');
    } catch (e) {
      debugPrint('[ConstatService] Erreur lors de la soumission du constat: $e');
      rethrow;
    }
  }

  // Récupérer un constat par son ID
  Future<ConstatModel?> getConstatById(String constatId) async {
    try {
      debugPrint('[ConstatService] Récupération du constat $constatId');
      
      final constatDoc = await _firestore.collection('constats').doc(constatId).get();
      if (!constatDoc.exists || constatDoc.data() == null) {
        debugPrint('[ConstatService] Constat non trouvé');
        return null;
      }
      
      return ConstatModel.fromMap(constatDoc.data()!);
    } catch (e) {
      debugPrint('[ConstatService] Erreur lors de la récupération du constat: $e');
      return null;
    }
  }

  // Récupérer les constats d'un utilisateur
  Future<List<ConstatModel>> getConstatsByUserId(String userId) async {
    try {
      debugPrint('[ConstatService] Récupération des constats de l\'utilisateur $userId');
      
      final constatsQuery = await _firestore.collection('constats')
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      final List<ConstatModel> constats = [];
      
      for (final doc in constatsQuery.docs) {
        if (doc.data() != null) {
          constats.add(ConstatModel.fromMap(doc.data()));
        }
      }
      
      // Récupérer également les constats où l'utilisateur est participant
      final participantsQuery = await _firestore.collection('participants')
          .where('userId', isEqualTo: userId)
          .get();
      
      final Set<String> constatIds = {};
      
      for (final doc in participantsQuery.docs) {
        final constatId = doc.data()['constatId'] as String?;
        if (constatId != null && !constatIds.contains(constatId)) {
          constatIds.add(constatId);
          
          final constatDoc = await _firestore.collection('constats').doc(constatId).get();
          if (constatDoc.exists && constatDoc.data() != null) {
            constats.add(ConstatModel.fromMap(constatDoc.data()!));
          }
        }
      }
      
      debugPrint('[ConstatService] ${constats.length} constats récupérés');
      return constats;
    } catch (e) {
      debugPrint('[ConstatService] Erreur lors de la récupération des constats: $e');
      return [];
    }
  }
}
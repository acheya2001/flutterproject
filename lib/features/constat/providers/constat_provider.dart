import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/proprietaire_info.dart';

// Ensure these custom service paths are correct
import '../../../core/services/firebase_email_service.dart';
import '../../../core/services/storage_service.dart';

// Model imports - ensure paths and definitions are correct
import '../../conducteur/models/assurance_info_model.dart' as conducteur_assurance_model;
import '../../conducteur/models/conducteur_info_model.dart' as conducteur_info_model;
import '../../conducteur/models/vehicule_accident_model.dart' as conducteur_vehicule_model;
import '../models/constat_model.dart';
import '../models/temoin_model.dart' as temoin_model;
import '../models/session_constat_model.dart' as session_model;

// CRITICAL: This import MUST point to the file where your Riverpod 'authProvider' is defined.
// e.g., import '../../auth/providers/auth_provider.dart';
// This example assumes auth_provider.dart exports a Riverpod provider named 'authProvider'
// which provides an instance of a class that has a 'currentUser' property.
import '../../auth/providers/auth_provider.dart'; 

import '../models/conducteur_session_info.dart'; // Assuming this model exists

// Dummy PDF Generator class (replace with actual implementation)
class PdfGenerator {
  Future<File> generatePdf(Map<String, dynamic> constatData) async {
    debugPrint("Generating PDF with data: $constatData");
    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/dummy_constat_${constatData['id'] ?? 'new'}.pdf");
    // Replace with actual PDF generation logic
    await file.writeAsString("Dummy PDF Content for constat ID: ${constatData['id'] ?? 'N/A'}\nDate: ${DateTime.now()}\nData: ${constatData.toString()}");
    debugPrint("Dummy PDF created at ${file.path}");
    return file;
  }
}

// Riverpod provider definition for ConstatProvider
final constatProvider = ChangeNotifierProvider((ref) => ConstatProvider(ref));

class ConstatProvider extends ChangeNotifier {
  final Ref ref;
  ConstatProvider(this.ref);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Assuming StorageService is implemented and works as expected
  final StorageService _storageService = StorageService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? newError) {
    _error = newError;
    notifyListeners();
  }

  Future<String> sauvegarderConstatComplet({
    required ConstatModel constat,
    required conducteur_info_model.ConducteurInfoModel conducteurInfo,
    required conducteur_vehicule_model.VehiculeAccidentModel vehiculeInfo,
    required conducteur_assurance_model.AssuranceInfoModel assuranceInfo,
    List<temoin_model.TemoinModel>? temoins,
    List<File>? photosAccident,
    File? photoPermis,
    File? photoCarteGrise,
    File? photoAssurance,
    Uint8List? signature,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      // Accessing currentUser from the Riverpod authProvider
      final authState = ref.read(authProvider); // Assuming authProvider provides your AuthProvider class instance
      final user = authState.currentUser; // Assuming AuthProvider class has a currentUser property
      
      if (user == null || user.id.isEmpty) { 
        throw Exception('Utilisateur non authentifié ou ID utilisateur manquant.');
      }

      List<String> photosAccidentUrls = [];
      if (photosAccident != null && photosAccident.isNotEmpty) {
        photosAccidentUrls = await Future.wait(photosAccident.map((photo) =>
            _storageService.uploadFile('constat_photos/${user.id}/${DateTime.now().millisecondsSinceEpoch}_${photo.path.split('/').last}', photo)));
      }

      String? photoPermisUrl = photoPermis != null ? await _storageService.uploadFile(
          'constat_photos/${user.id}/permis_${DateTime.now().millisecondsSinceEpoch}', photoPermis) : null;

      String? photoCarteGriseUrl = photoCarteGrise != null ? await _storageService.uploadFile(
          'constat_photos/${user.id}/cartegrise_${DateTime.now().millisecondsSinceEpoch}', photoCarteGrise) : null;

      String? photoAssuranceUrl = photoAssurance != null ? await _storageService.uploadFile(
          'constat_photos/${user.id}/assurance_${DateTime.now().millisecondsSinceEpoch}', photoAssurance) : null;
      
      String? signatureUrl = signature != null ? await _storageService.uploadBytes(
          'constat_signatures/${user.id}/signature_${DateTime.now().millisecondsSinceEpoch}.png', signature) : null;

      final enrichedConstat = constat.copyWith(
        photosUrls: photosAccidentUrls,
        // Add other URLs if your ConstatModel is designed to hold them directly
      );

      final constatData = enrichedConstat.toJson();
      
      // Embedding related information directly into the constat document
      constatData['conducteurInfo'] = conducteurInfo.toJson();
      constatData['vehiculeInfo'] = vehiculeInfo.toJson();
      constatData['assuranceInfo'] = assuranceInfo.toJson();
      constatData['temoins'] = temoins?.map((t) => t.toJson()).toList();
      constatData['userId'] = user.id; 
      constatData['photoPermisUrl'] = photoPermisUrl;
      constatData['photoCarteGriseUrl'] = photoCarteGriseUrl;
      constatData['photoAssuranceUrl'] = photoAssuranceUrl;
      constatData['signatureUrl'] = signatureUrl;
      constatData['createdAt'] = FieldValue.serverTimestamp(); // Add creation timestamp

      final docRef = await _firestore.collection('constats').add(constatData);
      await docRef.update({'id': docRef.id}); // Store the document ID within the document

      _setLoading(false);
      return docRef.id;
    } catch (e) {
      _setError("Erreur lors de la sauvegarde du constat : ${e.toString()}");
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> genererEtPartagerPdf(String constatId) async {
    _setLoading(true);
    _setError(null);
    try {
      final constatDoc = await _firestore.collection('constats').doc(constatId).get();
      if (!constatDoc.exists || constatDoc.data() == null) throw Exception('Constat non trouvé');

      final constatData = constatDoc.data()!;
      final pdfGenerator = PdfGenerator(); // Using the dummy generator
      final pdfFile = await pdfGenerator.generatePdf(constatData);

      await Share.shareXFiles([XFile(pdfFile.path, mimeType: 'application/pdf')], text: 'Constat Amiable PDF - ID: $constatId');
      _setLoading(false);
    } catch (e) {
      _setError('Erreur génération/partage PDF: ${e.toString()}');
      _setLoading(false);
      rethrow;
    }
  }
  
  Future<void> genererEtEnvoyerPdfParEmail(String constatId, String recipientEmail) async {
    _setLoading(true);
    _setError(null);
    try {
      final constatDoc = await _firestore.collection('constats').doc(constatId).get();
      if (!constatDoc.exists || constatDoc.data() == null) throw Exception('Constat non trouvé');

      // Note: PDF generation et pièces jointes seront implémentés plus tard

      // Note: Firebase Functions ne supporte pas les pièces jointes directement
      // Pour l'instant, on envoie juste un email de notification
      await FirebaseEmailService.sendEmail(
        to: recipientEmail,
        subject: 'Votre Constat Amiable - ID: $constatId',
        body: 'Votre constat amiable a été généré avec succès.\n\nID du constat: $constatId\n\nVous pouvez le consulter dans l\'application.',
        isHtml: false,
      );
      debugPrint('Email avec PDF envoyé à $recipientEmail pour constat ID: $constatId');
      _setLoading(false);
    } catch (e) {
      _setError('Erreur envoi PDF par email: ${e.toString()}');
      _setLoading(false);
      rethrow;
    }
  }

  Future<String> creerSessionConstat({
    required int nombreConducteurs,
    required List<String> emailsInvites,
    DateTime? dateAccident,
    String? lieuAccident,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final authState = ref.read(authProvider);
      final user = authState.currentUser;
      if (user == null || user.id.isEmpty) { 
        throw Exception('Utilisateur non authentifié ou ID utilisateur manquant.');
      }

      final sessionCode = _genererCodeSession();
      final now = DateTime.now();
      Map<String, ConducteurSessionInfo> conducteursMap = {};
      
      // Initiator (Conducteur A)
      conducteursMap['A'] = ConducteurSessionInfo(
        position: 'A',
        userId: user.id, 
        email: user.email, // Assuming UserModel has an email property
        isInvited: false,
        hasJoined: true,
        isCompleted: false, // Will be completed when they submit their part
        joinedAt: now,
        isProprietaire: true, // Default, can be updated later by the user
      );

      final positions = ['B', 'C', 'D', 'E', 'F']; // Supports up to 6 drivers total
      for (int i = 0; i < nombreConducteurs - 1; i++) {
        if (i >= positions.length) break; // Safety break
        final position = positions[i];
        final emailInvite = i < emailsInvites.length ? emailsInvites[i].trim() : null; 
        conducteursMap[position] = ConducteurSessionInfo(
          position: position,
          email: emailInvite,
          isInvited: emailInvite != null && emailInvite.isNotEmpty,
          hasJoined: false,
          isCompleted: false,
          isProprietaire: true, // Default
        );
      }

      final session = session_model.SessionConstatModel(
        id: '', // Will be set after document creation
        sessionCode: sessionCode,
        dateAccident: dateAccident ?? now,
        lieuAccident: lieuAccident ?? '',
        nombreConducteurs: nombreConducteurs,
        createdBy: user.id, 
        createdAt: now,
        updatedAt: now,
        status: session_model.SessionStatus.draft,
        conducteursInfo: conducteursMap,
        invitationsSent: emailsInvites.where((e) => e.trim().isNotEmpty).toList(),
        validationStatus: {}, // Initialize as empty
      );

      final docRef = await _firestore.collection('sessions_constat').add(session.toJson());
      await docRef.update({'id': docRef.id}); // Store the ID within the document

      // Send email invitations
      for (String emailToInvite in emailsInvites) {
        if(emailToInvite.trim().isNotEmpty) {
          await FirebaseEmailService.envoyerInvitation(
            email: emailToInvite.trim(),
            sessionCode: sessionCode,
            sessionId: docRef.id,
          );
        }
      }
      _setLoading(false);
      return docRef.id;
    } catch (e) {
      _setError("Erreur création session constat : ${e.toString()}");
      _setLoading(false);
      rethrow;
    }
  }

  String _genererCodeSession() {
    final now = DateTime.now();
    // More robust random part
    final randomPart = (DateTime.now().microsecondsSinceEpoch % 100000).toString().padLeft(5, '0');
    return 'S${now.year%100}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}$randomPart';
  }

  Future<session_model.SessionConstatModel?> rejoindreSessionConstat(String sessionCode) async {
    _setLoading(true);
    _setError(null);
    try {
      final querySnapshot = await _firestore
          .collection('sessions_constat')
          .where('sessionCode', isEqualTo: sessionCode.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _setLoading(false);
        return null; // Session not found
      }
      final sessionDoc = querySnapshot.docs.first;
      final session = session_model.SessionConstatModel.fromJson(sessionDoc.data());
      
      final authState = ref.read(authProvider);
      final currentUser = authState.currentUser;

      if (currentUser != null) {
        bool needsUpdate = false;
        String? userPositionInSession;

        session.conducteursInfo.forEach((position, conducteurSessInfo) {
          if (conducteurSessInfo.email == currentUser.email && !conducteurSessInfo.hasJoined) {
            userPositionInSession = position;
          }
        });

        if (userPositionInSession != null) {
          final updatedInfo = session.conducteursInfo[userPositionInSession!]!.copyWith(
            hasJoined: true,
            joinedAt: DateTime.now(),
            userId: currentUser.id,
          );
          session.conducteursInfo[userPositionInSession!] = updatedInfo;
          needsUpdate = true;
        }
        
        if (needsUpdate) {
          await sessionDoc.reference.update({
            'conducteursInfo': session.conducteursInfo.map((key, value) => MapEntry(key, value.toJson())),
            'updatedAt': FieldValue.serverTimestamp(),
            });
        }
      }
      _setLoading(false);
      return session;
    } catch (e) {
      _setError("Erreur pour rejoindre la session : ${e.toString()}");
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> enregistrerInformationsConducteurDansSession({
      required String sessionId,
      required String position, // e.g., "A", "B"
      required conducteur_info_model.ConducteurInfoModel conducteurInfo,
      required conducteur_vehicule_model.VehiculeAccidentModel vehiculeInfo,
      required conducteur_assurance_model.AssuranceInfoModel assuranceInfo,
      required bool isProprietaire,
      ProprietaireInfo? proprietaireInfo,
      List<int>? circonstances,
      List<String>? degatsApparents,
      List<temoin_model.TemoinModel>? temoins,
      List<File>? photosAccident,
      File? photoPermis,
      File? photoCarteGrise,
      File? photoAttestation,
      Uint8List? signature,
      String? observations,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final sessionRef = _firestore.collection('sessions_constat').doc(sessionId);
      final authState = ref.read(authProvider);
      final currentUser = authState.currentUser;

      if (currentUser == null || currentUser.id.isEmpty) {
        throw Exception('Utilisateur non authentifié.');
      }
      
      // Upload files
      List<String> photosAccidentUrls = [];
      if (photosAccident != null && photosAccident.isNotEmpty) {
        photosAccidentUrls = await Future.wait(photosAccident.map((photo) =>
            _storageService.uploadFile('session_photos/$sessionId/$position/accident_${DateTime.now().millisecondsSinceEpoch}_${photo.path.split('/').last}', photo)));
      }
      String? photoPermisUrl = photoPermis != null ? await _storageService.uploadFile('session_photos/$sessionId/$position/permis_${DateTime.now().millisecondsSinceEpoch}', photoPermis) : null;
      String? photoCarteGriseUrl = photoCarteGrise != null ? await _storageService.uploadFile('session_photos/$sessionId/$position/carte_grise_${DateTime.now().millisecondsSinceEpoch}', photoCarteGrise) : null;
      String? photoAttestationUrl = photoAttestation != null ? await _storageService.uploadFile('session_photos/$sessionId/$position/attestation_${DateTime.now().millisecondsSinceEpoch}', photoAttestation) : null;
      String? signatureUrl = signature != null ? await _storageService.uploadBytes('session_signatures/$sessionId/$position/signature_${DateTime.now().millisecondsSinceEpoch}.png', signature) : null;

      // Data for the specific conductor's part of the session
      // This will be stored within the ConducteurSessionInfo for that position
      final conducteurPartData = {
        'conducteurInfo': conducteurInfo.toJson(),
        'vehiculeInfo': vehiculeInfo.toJson(),
        'assuranceInfo': assuranceInfo.toJson(),
        'isProprietaire': isProprietaire,
        'proprietaireInfo': proprietaireInfo?.toJson(), 
        'circonstances': circonstances,
        'degatsApparents': degatsApparents,
        'temoins': temoins?.map((t) => t.toJson()).toList(),
        'photosAccidentUrls': photosAccidentUrls,
        'photoPermisUrl': photoPermisUrl,
        'photoCarteGriseUrl': photoCarteGriseUrl,
        'photoAttestationUrl': photoAttestationUrl,
        'signatureUrl': signatureUrl,
        'observations': observations,
        // Note: isCompleted, completedAt, userId for ConducteurSessionInfo will be updated separately or as part of a combined update
      };

      // Path to the specific conductor's data within the conducteursInfo map
      String conductorInfoPath = 'conducteursInfo.$position.declarationData'; // Storing as a sub-map
      String conductorCompletedPath = 'conducteursInfo.$position.isCompleted';
      String conductorCompletedAtPath = 'conducteursInfo.$position.completedAt';
      String conductorUserIdPath = 'conducteursInfo.$position.userId';


      await sessionRef.update({
        conductorInfoPath: conducteurPartData,
        conductorCompletedPath: true,
        conductorCompletedAtPath: FieldValue.serverTimestamp(),
        conductorUserIdPath: currentUser.id, // Ensure userId is set for this conductor
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint("Informations du conducteur $position enregistrées pour la session $sessionId");
      _setLoading(false);
    } catch (e) {
      _setError("Erreur enregistrement infos conducteur session : ${e.toString()}");
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> finaliserSessionConstat(String sessionId) async {
    _setLoading(true);
    _setError(null);
    try {
      final sessionRef = _firestore.collection('sessions_constat').doc(sessionId);
      await sessionRef.update({
        'status': session_model.SessionStatus.completed.name, // Storing enum name as string
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _envoyerNotificationsFinalisation(sessionId);
      _setLoading(false);
    } catch (e) {
      _setError("Erreur finalisation session : ${e.toString()}");
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> _envoyerNotificationsFinalisation(String sessionId) async {
    try {
      final sessionDoc = await _firestore.collection('sessions_constat').doc(sessionId).get();
      if (!sessionDoc.exists || sessionDoc.data() == null) {
        debugPrint('Session non trouvée pour notification de finalisation: $sessionId');
        return;
      }

      final session = session_model.SessionConstatModel.fromJson(sessionDoc.data()!);
      Set<String> recipientEmails = {}; // Use a Set to avoid duplicate emails

      session.conducteursInfo.forEach((_, conducteurSessInfo) {
        if (conducteurSessInfo.email != null && conducteurSessInfo.email!.trim().isNotEmpty) {
          recipientEmails.add(conducteurSessInfo.email!.trim());
        }
      });
      
      // Attempt to get creator's email if not already included
      if (session.createdBy.isNotEmpty) {
        try {
          final creatorUserDoc = await _firestore.collection('users').doc(session.createdBy).get();
          if (creatorUserDoc.exists) {
            final creatorEmail = creatorUserDoc.data()?['email'] as String?;
            if (creatorEmail != null && creatorEmail.trim().isNotEmpty) {
              recipientEmails.add(creatorEmail.trim());
            }
          }
        } catch (e) {
          debugPrint("Erreur pour récupérer l'email du créateur (${session.createdBy}): $e");
        }
      }
      
      for (final email in recipientEmails) {
        await FirebaseEmailService.sendEmail(
          to: email,
          subject: 'Constat Collaboratif Finalisé - Session ${session.sessionCode}',
          body: 'Bonjour,\n\nLe constat collaboratif (Session: ${session.sessionCode}) auquel vous avez participé a été finalisé.\n\nVous pourrez consulter les détails dans l\'application.\n\nCordialement,\nL\'équipe Constat Tunisie',
          isHtml: false,
        );
      }
    } catch (e) {
      debugPrint("Erreur envoi notifications finalisation: $e");
      // Do not rethrow, as finalization itself might have succeeded.
    }
  }
}
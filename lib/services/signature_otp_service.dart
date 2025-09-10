import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/collaborative_session_model.dart';

/// ✍️ Service pour gérer les signatures électroniques avec OTP
class SignatureOTPService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _otpCollection = 'signature_otp';
  static const String _signaturesCollection = 'signatures';

  /// 📱 Générer et envoyer un OTP pour signature
  static Future<String> genererOTPSignature({
    required String sessionId,
    required String userId,
    required String telephone,
  }) async {
    try {
      // Générer un OTP à 6 chiffres
      final otp = _genererOTP();
      
      // Sauvegarder l'OTP en base avec expiration (5 minutes)
      await _firestore.collection(_otpCollection).doc('${sessionId}_$userId').set({
        'otp': otp,
        'sessionId': sessionId,
        'userId': userId,
        'telephone': telephone,
        'dateCreation': FieldValue.serverTimestamp(),
        'dateExpiration': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 5))),
        'utilise': false,
        'tentatives': 0,
      });

      // Simuler l'envoi SMS (à remplacer par un vrai service SMS)
      await _simulerEnvoiSMS(telephone, otp);
      
      return otp; // En production, ne pas retourner l'OTP !
    } catch (e) {
      print('❌ Erreur génération OTP: $e');
      throw Exception('Impossible de générer l\'OTP: $e');
    }
  }

  /// ✅ Vérifier un OTP et effectuer la signature
  static Future<bool> verifierEtSigner({
    required String sessionId,
    required String userId,
    required String otpSaisi,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Récupérer l'OTP stocké
      final otpDoc = await _firestore.collection(_otpCollection).doc('${sessionId}_$userId').get();
      
      if (!otpDoc.exists) {
        throw Exception('Aucun OTP trouvé pour cette session');
      }

      final otpData = otpDoc.data()!;
      final otpStocke = otpData['otp'] as String;
      final dateExpiration = (otpData['dateExpiration'] as Timestamp).toDate();
      final utilise = otpData['utilise'] as bool;
      final tentatives = otpData['tentatives'] as int;

      // Vérifications
      if (utilise) {
        throw Exception('Cet OTP a déjà été utilisé');
      }

      if (DateTime.now().isAfter(dateExpiration)) {
        throw Exception('Cet OTP a expiré');
      }

      if (tentatives >= 3) {
        throw Exception('Trop de tentatives. Demandez un nouvel OTP');
      }

      // Incrémenter les tentatives
      await _firestore.collection(_otpCollection).doc('${sessionId}_$userId').update({
        'tentatives': tentatives + 1,
      });

      if (otpSaisi != otpStocke) {
        throw Exception('OTP incorrect');
      }

      // OTP correct - effectuer la signature
      await _effectuerSignature(sessionId, userId);

      // Marquer l'OTP comme utilisé
      await _firestore.collection(_otpCollection).doc('${sessionId}_$userId').update({
        'utilise': true,
        'dateUtilisation': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('❌ Erreur vérification OTP: $e');
      throw Exception('Erreur lors de la vérification: $e');
    }
  }

  /// ✍️ Effectuer la signature électronique
  static Future<void> _effectuerSignature(String sessionId, String userId) async {
    try {
      // Enregistrer la signature
      await _firestore
          .collection('collaborative_sessions')
          .doc(sessionId)
          .collection(_signaturesCollection)
          .doc(userId)
          .set({
        'userId': userId,
        'dateSignature': FieldValue.serverTimestamp(),
        'methode': 'OTP_SMS',
        'ipAddress': 'N/A', // Peut être récupéré si nécessaire
        'userAgent': 'Mobile App',
      });

      // Mettre à jour le statut du participant
      final sessionDoc = await _firestore
          .collection('collaborative_sessions')
          .doc(sessionId)
          .get();

      if (sessionDoc.exists) {
        final sessionData = sessionDoc.data()!;
        final participants = List<Map<String, dynamic>>.from(sessionData['participants'] ?? []);
        
        // Trouver et mettre à jour le participant
        for (int i = 0; i < participants.length; i++) {
          if (participants[i]['userId'] == userId) {
            participants[i]['statut'] = 'signe';
            participants[i]['dateSignature'] = Timestamp.fromDate(DateTime.now());
            break;
          }
        }

        // Compter les signatures
        final signaturesSnapshot = await _firestore
            .collection('collaborative_sessions')
            .doc(sessionId)
            .collection(_signaturesCollection)
            .get();

        final nombreSignatures = signaturesSnapshot.docs.length;
        final nombreParticipants = participants.length;

        // Mettre à jour la session
        await _firestore.collection('collaborative_sessions').doc(sessionId).update({
          'participants': participants,
          'progression.signaturesEffectuees': nombreSignatures,
          'statut': nombreSignatures >= nombreParticipants ? 'signe' : 'pret_signature',
          'dateModification': FieldValue.serverTimestamp(),
        });

        // Si toutes les signatures sont effectuées, finaliser le constat
        if (nombreSignatures >= nombreParticipants) {
          await _finaliserConstat(sessionId);
        }
      }
    } catch (e) {
      print('❌ Erreur signature: $e');
      throw Exception('Erreur lors de la signature: $e');
    }
  }

  /// 🏁 Finaliser le constat (génération PDF et envoi)
  static Future<void> _finaliserConstat(String sessionId) async {
    try {
      // Marquer la session comme finalisée
      await _firestore.collection('collaborative_sessions').doc(sessionId).update({
        'statut': 'finalise',
        'dateFinalisation': FieldValue.serverTimestamp(),
      });

      // Générer le PDF du constat (à implémenter)
      final pdfUrl = await _genererPDFConstat(sessionId);

      // Envoyer aux compagnies d'assurance (à implémenter)
      await _envoyerAuxCompagnies(sessionId, pdfUrl);

      print('✅ Constat finalisé avec succès');
    } catch (e) {
      print('❌ Erreur finalisation: $e');
      throw Exception('Erreur lors de la finalisation: $e');
    }
  }

  /// 📄 Générer le PDF du constat (placeholder)
  static Future<String> _genererPDFConstat(String sessionId) async {
    // TODO: Implémenter la génération PDF avec toutes les données
    // - Informations de tous les participants
    // - Croquis de l'accident
    // - Circonstances et dégâts
    // - Signatures électroniques
    
    await Future.delayed(const Duration(seconds: 2)); // Simulation
    return 'https://example.com/constat_$sessionId.pdf';
  }

  /// 📧 Envoyer le constat aux compagnies (placeholder)
  static Future<void> _envoyerAuxCompagnies(String sessionId, String pdfUrl) async {
    try {
      // Récupérer les données de la session
      final sessionDoc = await _firestore.collection('collaborative_sessions').doc(sessionId).get();
      
      if (!sessionDoc.exists) return;

      final sessionData = sessionDoc.data()!;
      final participants = List<Map<String, dynamic>>.from(sessionData['participants'] ?? []);

      // Extraire les compagnies d'assurance uniques
      final compagnies = <String>{};
      for (final participant in participants) {
        // TODO: Récupérer les données de formulaire pour obtenir les compagnies
        // compagnies.add(participant['compagnieAssurance']);
      }

      // TODO: Envoyer par email à chaque compagnie
      // - Utiliser le service d'email existant
      // - Joindre le PDF du constat
      // - Inclure les détails de l'accident
      
      print('📧 Constat envoyé à ${compagnies.length} compagnies');
    } catch (e) {
      print('❌ Erreur envoi compagnies: $e');
    }
  }

  /// 📱 Simuler l'envoi SMS (à remplacer par un vrai service)
  static Future<void> _simulerEnvoiSMS(String telephone, String otp) async {
    // TODO: Intégrer un vrai service SMS (Twilio, AWS SNS, etc.)
    print('📱 SMS envoyé à $telephone: Votre code de signature est $otp');
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// 🔢 Générer un OTP à 6 chiffres
  static String _genererOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// 📊 Obtenir le statut des signatures d'une session
  static Future<Map<String, dynamic>> obtenirStatutSignatures(String sessionId) async {
    try {
      final signaturesSnapshot = await _firestore
          .collection('collaborative_sessions')
          .doc(sessionId)
          .collection(_signaturesCollection)
          .get();

      final sessionDoc = await _firestore.collection('collaborative_sessions').doc(sessionId).get();
      
      if (!sessionDoc.exists) {
        throw Exception('Session non trouvée');
      }

      final sessionData = sessionDoc.data()!;
      final participants = List<Map<String, dynamic>>.from(sessionData['participants'] ?? []);

      return {
        'nombreSignatures': signaturesSnapshot.docs.length,
        'nombreParticipants': participants.length,
        'signaturesCompletes': signaturesSnapshot.docs.length >= participants.length,
        'participantsSignes': signaturesSnapshot.docs.map((doc) => doc.id).toList(),
      };
    } catch (e) {
      print('❌ Erreur statut signatures: $e');
      return {
        'nombreSignatures': 0,
        'nombreParticipants': 0,
        'signaturesCompletes': false,
        'participantsSignes': [],
      };
    }
  }

  /// 🔄 Vérifier si un utilisateur a déjà signé
  static Future<bool> aDejaSigneUtilisateur(String sessionId, String userId) async {
    try {
      final signatureDoc = await _firestore
          .collection('collaborative_sessions')
          .doc(sessionId)
          .collection(_signaturesCollection)
          .doc(userId)
          .get();

      return signatureDoc.exists;
    } catch (e) {
      print('❌ Erreur vérification signature: $e');
      return false;
    }
  }

  /// 🗑️ Nettoyer les OTP expirés (à appeler périodiquement)
  static Future<void> nettoyerOTPExpires() async {
    try {
      final maintenant = Timestamp.fromDate(DateTime.now());
      
      final otpExpires = await _firestore
          .collection(_otpCollection)
          .where('dateExpiration', isLessThan: maintenant)
          .get();

      final batch = _firestore.batch();
      for (final doc in otpExpires.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('🗑️ ${otpExpires.docs.length} OTP expirés supprimés');
    } catch (e) {
      print('❌ Erreur nettoyage OTP: $e');
    }
  }
}

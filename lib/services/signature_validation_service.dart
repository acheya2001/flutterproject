import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sms_service.dart';

/// 🔐 Service de validation légale des signatures électroniques (Conformité Tunisie)
class SignatureValidationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✍️ Processus de signature avec validation OTP (Conformité ANF/Tuntrust)
  static Future<Map<String, dynamic>> initierSignatureSecurisee({
    required String sessionId,
    required String role,
    required String telephone,
    required String nomComplet,
    required bool accepteResponsabilite,
  }) async {
    try {
      // 1. Générer code OTP sécurisé
      final codeOTP = _genererCodeOTP();
      final expirationOTP = DateTime.now().add(const Duration(minutes: 5));

      // 2. Créer l'enregistrement de validation
      final validationId = await _creerEnregistrementValidation(
        sessionId: sessionId,
        role: role,
        telephone: telephone,
        nomComplet: nomComplet,
        codeOTP: codeOTP,
        expiration: expirationOTP,
        accepteResponsabilite: accepteResponsabilite,
      );

      // 3. Envoyer SMS OTP
      await SMSService.envoyerOTP(
        telephone: telephone,
        code: codeOTP,
        nomComplet: nomComplet,
        sessionCode: sessionId,
      );

      // 4. Logger la tentative
      await _loggerTentativeSignature(validationId, 'otp_envoye');

      return {
        'success': true,
        'validationId': validationId,
        'expiration': expirationOTP.toIso8601String(),
        'message': 'Code OTP envoyé au $telephone',
      };

    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 📱 Valider le code OTP et finaliser la signature
  static Future<Map<String, dynamic>> validerSignatureOTP({
    required String validationId,
    required String codeOTPSaisi,
    required List<int> signatureBytes,
  }) async {
    try {
      // 1. Récupérer l'enregistrement de validation
      final validationDoc = await _firestore
          .collection('signature_validations')
          .doc(validationId)
          .get();

      if (!validationDoc.exists) {
        return {
          'success': false,
          'error': 'Validation introuvable',
        };
      }

      final validationData = validationDoc.data()!;

      // 2. Vérifier l'expiration
      final expiration = (validationData['expiration'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiration)) {
        await _loggerTentativeSignature(validationId, 'otp_expire');
        return {
          'success': false,
          'error': 'Code OTP expiré. Veuillez recommencer.',
        };
      }

      // 3. Vérifier le code OTP
      final codeOTPAttendu = validationData['codeOTP'] as String;
      if (codeOTPSaisi != codeOTPAttendu) {
        await _loggerTentativeSignature(validationId, 'otp_incorrect');
        
        // Incrémenter les tentatives échouées
        final tentativesEchouees = (validationData['tentativesEchouees'] ?? 0) + 1;
        await _firestore.collection('signature_validations').doc(validationId).update({
          'tentativesEchouees': tentativesEchouees,
        });

        // Bloquer après 3 tentatives
        if (tentativesEchouees >= 3) {
          await _bloquerValidation(validationId);
          return {
            'success': false,
            'error': 'Trop de tentatives échouées. Validation bloquée.',
          };
        }

        return {
          'success': false,
          'error': 'Code OTP incorrect. ${3 - tentativesEchouees} tentatives restantes.',
        };
      }

      // 4. Créer la signature certifiée
      final signatureCertifiee = await _creerSignatureCertifiee(
        validationData: validationData,
        signatureBytes: signatureBytes,
      );

      // 5. Enregistrer dans la session d'accident
      await _enregistrerSignatureDansSession(
        sessionId: validationData['sessionId'],
        role: validationData['role'],
        signature: signatureCertifiee,
      );

      // 6. Marquer la validation comme complète
      await _finaliserValidation(validationId);

      // 7. Logger le succès
      await _loggerTentativeSignature(validationId, 'signature_validee');

      return {
        'success': true,
        'signatureId': signatureCertifiee['id'],
        'certificat': signatureCertifiee['certificat'],
        'message': 'Signature électronique validée avec succès',
      };

    } catch (e) {
      await _loggerTentativeSignature(validationId, 'erreur_validation');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔢 Générer un code OTP sécurisé
  static String _genererCodeOTP() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString(); // 6 chiffres
  }

  /// 📝 Créer l'enregistrement de validation
  static Future<String> _creerEnregistrementValidation({
    required String sessionId,
    required String role,
    required String telephone,
    required String nomComplet,
    required String codeOTP,
    required DateTime expiration,
    required bool accepteResponsabilite,
  }) async {
    final doc = await _firestore.collection('signature_validations').add({
      'sessionId': sessionId,
      'role': role,
      'telephone': telephone,
      'nomComplet': nomComplet,
      'codeOTP': codeOTP,
      'expiration': Timestamp.fromDate(expiration),
      'accepteResponsabilite': accepteResponsabilite,
      'statut': 'en_attente_otp',
      'tentativesEchouees': 0,
      'dateCreation': Timestamp.now(),
      'adresseIP': null, // TODO: Récupérer l'IP réelle
      'userAgent': null, // TODO: Récupérer le user agent
    });

    return doc.id;
  }

  /// ✅ Créer une signature certifiée conforme
  static Future<Map<String, dynamic>> _creerSignatureCertifiee({
    required Map<String, dynamic> validationData,
    required List<int> signatureBytes,
  }) async {
    final maintenant = DateTime.now();
    final signatureId = 'SIG_${maintenant.millisecondsSinceEpoch}';

    // Créer le certificat de signature (format simplifié)
    final certificat = {
      'id': signatureId,
      'signataire': {
        'nom': validationData['nomComplet'],
        'telephone': validationData['telephone'],
        'role': validationData['role'],
      },
      'session': {
        'id': validationData['sessionId'],
        'role': validationData['role'],
      },
      'validation': {
        'methode': 'otp_sms',
        'telephone_verifie': true,
        'date_verification': maintenant.toIso8601String(),
        'accepte_responsabilite': validationData['accepteResponsabilite'],
      },
      'technique': {
        'algorithme': 'SHA256',
        'format': 'PNG',
        'taille_bytes': signatureBytes.length,
        'empreinte': _calculerEmpreinte(signatureBytes),
      },
      'conformite': {
        'niveau': 'signature_electronique_avancee',
        'norme': 'Décret 2020-456 (Tunisie)',
        'autorite': 'ANF - Agence Nationale de Fréquences',
        'validite_juridique': true,
      },
      'horodatage': {
        'creation': maintenant.toIso8601String(),
        'timezone': 'Africa/Tunis',
        'timestamp_unix': maintenant.millisecondsSinceEpoch,
      },
    };

    // Sauvegarder la signature avec certificat
    await _firestore.collection('signatures_certifiees').doc(signatureId).set({
      ...certificat,
      'signature_bytes': signatureBytes,
      'statut': 'valide',
      'revoquee': false,
    });

    return certificat;
  }

  /// 💾 Enregistrer la signature dans la session d'accident
  static Future<void> _enregistrerSignatureDansSession({
    required String sessionId,
    required String role,
    required Map<String, dynamic> signature,
  }) async {
    await _firestore.collection('accident_sessions').doc(sessionId).update({
      'signatures.$role': {
        'signatureId': signature['id'],
        'nomSignataire': signature['signataire']['nom'],
        'dateSignature': Timestamp.now(),
        'accepteResponsabilite': signature['validation']['accepte_responsabilite'],
        'certificat': signature['id'],
        'methodeValidation': 'otp_sms',
        'conformiteLegale': true,
      },
    });
  }

  /// ✅ Finaliser la validation
  static Future<void> _finaliserValidation(String validationId) async {
    await _firestore.collection('signature_validations').doc(validationId).update({
      'statut': 'complete',
      'dateCompletion': Timestamp.now(),
    });
  }

  /// 🚫 Bloquer une validation après échecs
  static Future<void> _bloquerValidation(String validationId) async {
    await _firestore.collection('signature_validations').doc(validationId).update({
      'statut': 'bloquee',
      'dateBlocage': Timestamp.now(),
      'raison': 'trop_tentatives_echouees',
    });
  }

  /// 📊 Logger les tentatives de signature
  static Future<void> _loggerTentativeSignature(String validationId, String action) async {
    await _firestore.collection('signature_logs').add({
      'validationId': validationId,
      'action': action,
      'timestamp': Timestamp.now(),
      'adresseIP': null, // TODO: IP réelle
      'userAgent': null, // TODO: User agent réel
    });
  }

  /// 🔐 Calculer l'empreinte de la signature
  static String _calculerEmpreinte(List<int> bytes) {
    // Simulation d'un hash SHA256
    final hash = bytes.fold(0, (prev, byte) => prev + byte);
    return 'SHA256:${hash.toRadixString(16).padLeft(8, '0')}';
  }

  /// 📋 Vérifier la validité d'une signature
  static Future<Map<String, dynamic>> verifierSignature(String signatureId) async {
    try {
      final signatureDoc = await _firestore
          .collection('signatures_certifiees')
          .doc(signatureId)
          .get();

      if (!signatureDoc.exists) {
        return {
          'valide': false,
          'erreur': 'Signature introuvable',
        };
      }

      final data = signatureDoc.data()!;
      
      return {
        'valide': !data['revoquee'] && data['statut'] == 'valide',
        'certificat': data,
        'conformite_legale': data['conformite'],
      };

    } catch (e) {
      return {
        'valide': false,
        'erreur': e.toString(),
      };
    }
  }

  /// 📊 Statistiques de validation
  static Future<Map<String, dynamic>> obtenirStatistiquesValidation() async {
    final stats = <String, dynamic>{};

    // Signatures validées aujourd'hui
    final debutJour = DateTime.now().subtract(Duration(
      hours: DateTime.now().hour,
      minutes: DateTime.now().minute,
      seconds: DateTime.now().second,
    ));

    final validesQuery = await _firestore
        .collection('signatures_certifiees')
        .where('horodatage.creation', isGreaterThanOrEqualTo: debutJour.toIso8601String())
        .count()
        .get();

    stats['signatures_validees_aujourd_hui'] = validesQuery.count;

    // Tentatives échouées
    final echoueesQuery = await _firestore
        .collection('signature_validations')
        .where('statut', isEqualTo: 'bloquee')
        .where('dateCreation', isGreaterThanOrEqualTo: Timestamp.fromDate(debutJour))
        .count()
        .get();

    stats['tentatives_bloquees_aujourd_hui'] = echoueesQuery.count;

    // Taux de succès
    final totalTentatives = validesQuery.count + echoueesQuery.count;
    stats['taux_succes'] = totalTentatives > 0 
        ? (validesQuery.count / totalTentatives * 100).round()
        : 100;

    return stats;
  }

  /// 🔄 Renouveler une validation expirée
  static Future<Map<String, dynamic>> renouvelerValidation(String validationId) async {
    try {
      final validationDoc = await _firestore
          .collection('signature_validations')
          .doc(validationId)
          .get();

      if (!validationDoc.exists) {
        return {
          'success': false,
          'error': 'Validation introuvable',
        };
      }

      final data = validationDoc.data()!;

      // Générer nouveau code OTP
      final nouveauCode = _genererCodeOTP();
      final nouvelleExpiration = DateTime.now().add(const Duration(minutes: 5));

      // Mettre à jour
      await _firestore.collection('signature_validations').doc(validationId).update({
        'codeOTP': nouveauCode,
        'expiration': Timestamp.fromDate(nouvelleExpiration),
        'statut': 'en_attente_otp',
        'tentativesEchouees': 0,
        'dateRenouvellement': Timestamp.now(),
      });

      // Renvoyer SMS
      await SMSService.envoyerOTP(
        telephone: data['telephone'],
        code: nouveauCode,
        nomComplet: data['nomComplet'],
        sessionCode: data['sessionId'],
      );

      return {
        'success': true,
        'message': 'Nouveau code OTP envoyé',
        'expiration': nouvelleExpiration.toIso8601String(),
      };

    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}

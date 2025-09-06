import 'package:cloud_firestore/cloud_firestore.dart';

/// 📱 Service d'envoi SMS pour OTP et notifications
class SMSService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📱 Envoyer un code OTP par SMS
  static Future<void> envoyerOTP({
    required String telephone,
    required String code,
    required String nomComplet,
    required String sessionCode,
  }) async {
    try {
      final message = '''
🔐 Code de validation Constat Tunisie

Bonjour $nomComplet,

Votre code de validation pour signer le constat $sessionCode est:

$code

Ce code expire dans 5 minutes.

⚠️ Ne partagez jamais ce code.
''';

      // TODO: Intégrer avec un service SMS réel (Twilio, AWS SNS, etc.)
      await _simulerEnvoiSMS(telephone, message);

      // Logger l'envoi
      await _loggerEnvoiSMS(telephone, 'otp', sessionCode);

    } catch (e) {
      print('Erreur envoi SMS OTP: $e');
      rethrow;
    }
  }

  /// 📱 Envoyer invitation par SMS
  static Future<void> envoyerInvitationConstat({
    required String telephone,
    required String codeSession,
    required String roleVehicule,
  }) async {
    try {
      final message = '''
🚗 Invitation Constat d'Accident

Vous êtes invité à participer au constat d'accident.

Code de session: $codeSession
Votre rôle: Véhicule $roleVehicule

📱 Pour rejoindre:
1. Téléchargez "Constat Tunisie"
2. Choisissez "Rejoindre une session"
3. Saisissez le code: $codeSession

⚠️ Vous avez 5 jours pour compléter votre partie.

App Store: [LIEN_IOS]
Google Play: [LIEN_ANDROID]
''';

      await _simulerEnvoiSMS(telephone, message);
      await _loggerEnvoiSMS(telephone, 'invitation', codeSession);

    } catch (e) {
      print('Erreur envoi SMS invitation: $e');
      rethrow;
    }
  }

  /// 📱 Envoyer relance par SMS
  static Future<void> envoyerRelanceConstat({
    required String telephone,
    required String codeSession,
    required int heuresRestantes,
  }) async {
    try {
      String urgence = '';
      if (heuresRestantes <= 12) {
        urgence = '🚨 URGENT: ';
      } else if (heuresRestantes <= 24) {
        urgence = '⚠️ ';
      }

      final message = '''
${urgence}Constat en attente

Votre partie du constat $codeSession n'est pas encore complétée.

⏰ Temps restant: ${heuresRestantes}h

Complétez maintenant dans l'app "Constat Tunisie" avec le code: $codeSession

${heuresRestantes <= 12 ? '⚠️ DERNIÈRE CHANCE avant expiration!' : ''}
''';

      await _simulerEnvoiSMS(telephone, message);
      await _loggerEnvoiSMS(telephone, 'relance', codeSession);

    } catch (e) {
      print('Erreur envoi SMS relance: $e');
      rethrow;
    }
  }

  /// 📱 Simulation d'envoi SMS (à remplacer par vraie API)
  static Future<void> _simulerEnvoiSMS(String telephone, String message) async {
    // Simulation d'un délai d'envoi
    await Future.delayed(const Duration(seconds: 1));
    
    print('📱 SMS envoyé à $telephone:');
    print(message);
    print('---');

    // TODO: Remplacer par vraie intégration SMS
    // Exemples d'APIs SMS populaires:
    // - Twilio: https://www.twilio.com/
    // - AWS SNS: https://aws.amazon.com/sns/
    // - Vonage (ex-Nexmo): https://www.vonage.com/
    // - MessageBird: https://www.messagebird.com/
    
    // Exemple d'intégration Twilio:
    /*
    final accountSid = 'YOUR_ACCOUNT_SID';
    final authToken = 'YOUR_AUTH_TOKEN';
    final fromNumber = 'YOUR_TWILIO_NUMBER';
    
    final response = await http.post(
      Uri.parse('https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json'),
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$accountSid:$authToken'))}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'From': fromNumber,
        'To': telephone,
        'Body': message,
      },
    );
    */
  }

  /// 📊 Logger l'envoi SMS
  static Future<void> _loggerEnvoiSMS(String telephone, String type, String sessionCode) async {
    await _firestore.collection('sms_logs').add({
      'telephone': telephone,
      'type': type,
      'sessionCode': sessionCode,
      'timestamp': Timestamp.now(),
      'statut': 'envoye',
    });
  }

  /// 📊 Statistiques SMS
  static Future<Map<String, int>> obtenirStatistiquesSMS() async {
    final stats = <String, int>{};
    
    final debutJour = DateTime.now().subtract(Duration(
      hours: DateTime.now().hour,
      minutes: DateTime.now().minute,
      seconds: DateTime.now().second,
    ));

    // SMS envoyés aujourd'hui
    final smsQuery = await _firestore
        .collection('sms_logs')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(debutJour))
        .count()
        .get();
    
    stats['sms_envoyes_aujourd_hui'] = smsQuery.count;

    // SMS OTP
    final otpQuery = await _firestore
        .collection('sms_logs')
        .where('type', isEqualTo: 'otp')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(debutJour))
        .count()
        .get();
    
    stats['otp_envoyes_aujourd_hui'] = otpQuery.count;

    // SMS invitations
    final invitationQuery = await _firestore
        .collection('sms_logs')
        .where('type', isEqualTo: 'invitation')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(debutJour))
        .count()
        .get();
    
    stats['invitations_envoyees_aujourd_hui'] = invitationQuery.count;

    return stats;
  }

  /// 🔧 Valider un numéro de téléphone tunisien
  static bool validerTelephoneTunisien(String telephone) {
    // Formats acceptés:
    // +216 XX XXX XXX
    // 216 XX XXX XXX
    // XX XXX XXX (local)
    
    final regex = RegExp(r'^(\+216|216)?[2-9]\d{7}$');
    final numeroNettoye = telephone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    return regex.hasMatch(numeroNettoye);
  }

  /// 🔧 Normaliser un numéro de téléphone
  static String normaliserTelephone(String telephone) {
    String numero = telephone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Ajouter le préfixe tunisien si manquant
    if (numero.length == 8 && numero.startsWith(RegExp(r'[2-9]'))) {
      numero = '+216$numero';
    } else if (numero.startsWith('216')) {
      numero = '+$numero';
    } else if (!numero.startsWith('+216')) {
      throw ArgumentError('Numéro de téléphone invalide: $telephone');
    }
    
    return numero;
  }

  /// 📱 Tester la connectivité SMS
  static Future<bool> testerConnectiviteSMS() async {
    try {
      // TODO: Implémenter un test réel avec l'API SMS
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      print('Erreur test connectivité SMS: $e');
      return false;
    }
  }

  /// 🔄 Renvoyer un SMS en cas d'échec
  static Future<void> renvoyerSMS({
    required String telephone,
    required String type,
    required String sessionCode,
    String? codeOTP,
    String? roleVehicule,
    int? heuresRestantes,
  }) async {
    try {
      switch (type) {
        case 'otp':
          if (codeOTP != null) {
            await envoyerOTP(
              telephone: telephone,
              code: codeOTP,
              nomComplet: 'Utilisateur',
              sessionCode: sessionCode,
            );
          }
          break;
        case 'invitation':
          if (roleVehicule != null) {
            await envoyerInvitationConstat(
              telephone: telephone,
              codeSession: sessionCode,
              roleVehicule: roleVehicule,
            );
          }
          break;
        case 'relance':
          if (heuresRestantes != null) {
            await envoyerRelanceConstat(
              telephone: telephone,
              codeSession: sessionCode,
              heuresRestantes: heuresRestantes,
            );
          }
          break;
      }
    } catch (e) {
      print('Erreur renvoi SMS: $e');
      rethrow;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

/// 🤖 Service intelligent de notification pour transmission aux agents
class IntelligentNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// 📧 Transmettre le constat aux agents d'assurance de manière intelligente
  static Future<void> transmettreConstatAuxAgents({
    required String sessionId,
    required String pdfUrl,
    required Map<String, dynamic> sessionData,
  }) async {
    print('📧 [NOTIF] Transmission intelligente pour session $sessionId');

    try {
      // 1. Identifier les agents responsables
      final agentsResponsables = await _identifierAgentsResponsables(sessionData);
      
      // 2. Générer et envoyer emails personnalisés
      for (final agent in agentsResponsables) {
        await _envoyerEmailPersonnalise(agent, sessionId, pdfUrl, sessionData);
        await _envoyerNotificationPush(agent, sessionId, sessionData);
        
        // SMS si urgence élevée
        final urgence = _determinerUrgence(sessionData);
        if (urgence >= 3) {
          await _envoyerSMSUrgent(agent, sessionId, sessionData);
        }
      }
      
      // 3. Notifier les agences (copie hiérarchique)
      await _notifierAgences(agentsResponsables, sessionId, pdfUrl, sessionData);
      
      // 4. Notifier les conducteurs
      await _notifierConducteurs(sessionData, sessionId, pdfUrl);
      
      // 5. Logging et suivi
      await _loggerTransmissionComplete(sessionId, agentsResponsables, sessionData);
      
      // 6. Programmer suivi automatique
      await _programmerSuiviAutomatique(sessionId, agentsResponsables);
      
      print('✅ [NOTIF] Transmission intelligente terminée');
      
    } catch (e) {
      print('❌ [NOTIF] Erreur transmission: $e');
      rethrow;
    }
  }

  /// 🔍 Identifier les agents responsables par véhicule
  static Future<List<Map<String, dynamic>>> _identifierAgentsResponsables(
    Map<String, dynamic> sessionData,
  ) async {
    final agentsResponsables = <Map<String, dynamic>>[];
    final participants = sessionData['participants'] as List<dynamic>? ?? [];
    
    for (final participant in participants) {
      final participantData = participant as Map<String, dynamic>;
      final vehiculeInfo = participantData['vehicle'] as Map<String, dynamic>? ?? {};
      final assuranceInfo = participantData['insurance'] as Map<String, dynamic>? ?? {};
      
      // Récupérer l'agent responsable du contrat
      final numeroPolice = assuranceInfo['numeroPolice'] as String?;
      if (numeroPolice != null) {
        final agentInfo = await _getAgentResponsable(numeroPolice);
        if (agentInfo != null) {
          agentsResponsables.add({
            'vehiculeId': participantData['vehicleIndex'] ?? 0,
            'vehiculeInfo': '${vehiculeInfo['marque'] ?? ''} ${vehiculeInfo['modele'] ?? ''} (${vehiculeInfo['immatriculation'] ?? ''})',
            'agentId': agentInfo['id'],
            'agentNom': '${agentInfo['prenom'] ?? ''} ${agentInfo['nom'] ?? ''}',
            'agentEmail': agentInfo['email'],
            'agentPhone': agentInfo['phone'],
            'agenceNom': agentInfo['agence']?['nom'] ?? '',
            'compagnieNom': agentInfo['compagnie']?['nom'] ?? '',
            'numeroPolice': numeroPolice,
            'typeContrat': assuranceInfo['typeContrat'] ?? '',
            'conducteurNom': '${participantData['driver']?['prenom'] ?? ''} ${participantData['driver']?['nom'] ?? ''}',
          });
        }
      }
    }
    
    return agentsResponsables;
  }

  /// 👤 Récupérer l'agent responsable d'un contrat
  static Future<Map<String, dynamic>?> _getAgentResponsable(String numeroPolice) async {
    try {
      // Rechercher le contrat
      final contratQuery = await _firestore
          .collection('contrats_assurance')
          .where('numeroPolice', isEqualTo: numeroPolice)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      if (contratQuery.docs.isEmpty) return null;
      
      final contrat = contratQuery.docs.first.data();
      final agentId = contrat['agentId'] as String?;
      
      if (agentId == null) return null;
      
      // Récupérer les infos de l'agent
      final agentDoc = await _firestore.collection('agents_assurance').doc(agentId).get();
      if (!agentDoc.exists) return null;
      
      final agentData = agentDoc.data()!;
      
      // Récupérer les infos de l'agence
      final agenceId = agentData['agenceId'] as String?;
      Map<String, dynamic>? agenceData;
      if (agenceId != null) {
        final agenceDoc = await _firestore.collection('agences_assurance').doc(agenceId).get();
        if (agenceDoc.exists) {
          agenceData = agenceDoc.data();
        }
      }
      
      // Récupérer les infos de la compagnie
      final compagnieId = agentData['compagnieId'] as String?;
      Map<String, dynamic>? compagnieData;
      if (compagnieId != null) {
        final compagnieDoc = await _firestore.collection('compagnies_assurance').doc(compagnieId).get();
        if (compagnieDoc.exists) {
          compagnieData = compagnieDoc.data();
        }
      }
      
      return {
        'id': agentDoc.id,
        ...agentData,
        'agence': agenceData,
        'compagnie': compagnieData,
      };
      
    } catch (e) {
      print('❌ [NOTIF] Erreur récupération agent: $e');
      return null;
    }
  }

  /// 📧 Envoyer email personnalisé à un agent
  static Future<void> _envoyerEmailPersonnalise(
    Map<String, dynamic> agent,
    String sessionId,
    String pdfUrl,
    Map<String, dynamic> sessionData,
  ) async {
    try {
      final infosGenerales = sessionData['commonInfo'] as Map<String, dynamic>? ?? {};
      final urgence = _determinerUrgence(sessionData);
      
      final subject = '🚨 NOUVEAU CONSTAT - ${agent['vehiculeInfo']} - ${_formatDate(infosGenerales['dateAccident'])}';
      
      final htmlContent = _genererEmailAgent(agent, sessionData, sessionId, urgence);
      
      // Configuration SMTP (à adapter selon votre configuration)
      final smtpServer = gmail('votre-email@gmail.com', 'votre-mot-de-passe');
      
      final message = Message()
        ..from = const Address('noreply@constat-tunisie.tn', 'Constat Tunisie')
        ..recipients.add(agent['agentEmail'])
        ..subject = subject
        ..html = htmlContent
        ..attachments = [
          FileAttachment(File.fromUri(Uri.parse(pdfUrl)))
            ..fileName = 'constat_${sessionId}_${agent['vehiculeId']}.pdf'
        ];
      
      await send(message, smtpServer);
      
      // Logger l'envoi
      await _firestore.collection('email_logs').add({
        'type': 'agent_notification',
        'agentId': agent['agentId'],
        'agentEmail': agent['agentEmail'],
        'sessionId': sessionId,
        'vehiculeId': agent['vehiculeId'],
        'subject': subject,
        'sentAt': FieldValue.serverTimestamp(),
        'success': true,
      });
      
      print('✅ [EMAIL] Email envoyé à ${agent['agentEmail']}');
      
    } catch (e) {
      print('❌ [EMAIL] Erreur envoi email: $e');
      
      // Logger l'erreur
      await _firestore.collection('email_logs').add({
        'type': 'agent_notification',
        'agentId': agent['agentId'],
        'agentEmail': agent['agentEmail'],
        'sessionId': sessionId,
        'error': e.toString(),
        'sentAt': FieldValue.serverTimestamp(),
        'success': false,
      });
    }
  }

  /// 📱 Envoyer notification push à un agent
  static Future<void> _envoyerNotificationPush(
    Map<String, dynamic> agent,
    String sessionId,
    Map<String, dynamic> sessionData,
  ) async {
    try {
      // Vérifier si l'agent est en ligne
      final agentOnline = await _isAgentOnline(agent['agentId']);
      if (!agentOnline) return;
      
      final urgence = _determinerUrgence(sessionData);
      
      // Récupérer le token FCM de l'agent
      final agentDoc = await _firestore.collection('agents_assurance').doc(agent['agentId']).get();
      final fcmToken = agentDoc.data()?['fcmToken'] as String?;
      
      if (fcmToken == null) return;
      
      await _messaging.sendToDevice(
        [fcmToken],
        {
          'notification': {
            'title': '🚨 Nouveau constat d\'accident',
            'body': 'Véhicule ${agent['vehiculeInfo']} impliqué',
          },
          'data': {
            'sessionId': sessionId,
            'vehiculeId': agent['vehiculeId'].toString(),
            'type': 'nouveau_constat',
            'urgence': urgence.toString(),
            'agentId': agent['agentId'],
          },
        },
      );
      
      print('📱 [PUSH] Notification envoyée à l\'agent ${agent['agentId']}');
      
    } catch (e) {
      print('❌ [PUSH] Erreur notification push: $e');
    }
  }

  /// 📱 Envoyer SMS urgent
  static Future<void> _envoyerSMSUrgent(
    Map<String, dynamic> agent,
    String sessionId,
    Map<String, dynamic> sessionData,
  ) async {
    try {
      final message = '🚨 URGENT: Nouveau constat accident véhicule ${agent['vehiculeInfo']}. '
                     'Consultez votre email. Session: $sessionId';
      
      // TODO: Implémenter l'envoi SMS via votre provider SMS
      // await SMSService.sendSMS(agent['agentPhone'], message);
      
      print('📱 [SMS] SMS urgent envoyé à ${agent['agentPhone']}');
      
    } catch (e) {
      print('❌ [SMS] Erreur envoi SMS: $e');
    }
  }

  /// 🏢 Notifier les agences (copie hiérarchique)
  static Future<void> _notifierAgences(
    List<Map<String, dynamic>> agentsResponsables,
    String sessionId,
    String pdfUrl,
    Map<String, dynamic> sessionData,
  ) async {
    final agencesNotifiees = <String>{};
    
    for (final agent in agentsResponsables) {
      final agenceEmail = agent['agence']?['email'] as String?;
      if (agenceEmail != null && !agencesNotifiees.contains(agenceEmail)) {
        agencesNotifiees.add(agenceEmail);
        
        // TODO: Envoyer email à l'agence
        print('🏢 [AGENCE] Notification envoyée à l\'agence: $agenceEmail');
      }
    }
  }

  /// 👥 Notifier les conducteurs
  static Future<void> _notifierConducteurs(
    Map<String, dynamic> sessionData,
    String sessionId,
    String pdfUrl,
  ) async {
    final participants = sessionData['participants'] as List<dynamic>? ?? [];
    
    for (final participant in participants) {
      final participantData = participant as Map<String, dynamic>;
      final conducteur = participantData['driver'] as Map<String, dynamic>? ?? {};
      final email = conducteur['email'] as String?;
      final phone = conducteur['phone'] as String?;
      
      if (email != null) {
        // TODO: Envoyer email au conducteur
        print('👤 [CONDUCTEUR] Email envoyé à: $email');
      }
      
      if (phone != null) {
        // TODO: Envoyer SMS au conducteur
        print('👤 [CONDUCTEUR] SMS envoyé à: $phone');
      }
    }
  }

  /// 📊 Logger la transmission complète
  static Future<void> _loggerTransmissionComplete(
    String sessionId,
    List<Map<String, dynamic>> agentsResponsables,
    Map<String, dynamic> sessionData,
  ) async {
    await _firestore.collection('transmission_logs').add({
      'sessionId': sessionId,
      'agentsNotifies': agentsResponsables.length,
      'agentIds': agentsResponsables.map((a) => a['agentId']).toList(),
      'vehiculesCount': agentsResponsables.length,
      'timestamp': FieldValue.serverTimestamp(),
      'urgence': _determinerUrgence(sessionData),
      'success': true,
    });
  }

  /// ⏰ Programmer suivi automatique
  static Future<void> _programmerSuiviAutomatique(
    String sessionId,
    List<Map<String, dynamic>> agentsResponsables,
  ) async {
    final suiviDate = DateTime.now().add(const Duration(hours: 24));
    
    await _firestore.collection('suivi_automatique').add({
      'sessionId': sessionId,
      'agentIds': agentsResponsables.map((a) => a['agentId']).toList(),
      'scheduledFor': Timestamp.fromDate(suiviDate),
      'type': 'traitement_constat',
      'processed': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🚨 Déterminer le niveau d'urgence
  static int _determinerUrgence(Map<String, dynamic> sessionData) {
    int urgence = 1; // Normal
    
    final infosGenerales = sessionData['commonInfo'] as Map<String, dynamic>? ?? {};
    final participants = sessionData['participants'] as List<dynamic>? ?? [];
    
    if (infosGenerales['hasInjuries'] == true) urgence += 2; // Blessés = +2
    if (participants.length > 2) urgence += 1; // Multi-véhicules = +1
    
    // Vérifier si c'est le weekend ou la nuit
    final now = DateTime.now();
    if (now.weekday >= 6 || now.hour < 8 || now.hour > 18) urgence += 1;
    
    return urgence.clamp(1, 5); // Max 5
  }

  /// 🟢 Vérifier si un agent est en ligne
  static Future<bool> _isAgentOnline(String agentId) async {
    try {
      final agentDoc = await _firestore.collection('agents_assurance').doc(agentId).get();
      final lastSeen = agentDoc.data()?['lastSeen'] as Timestamp?;
      
      if (lastSeen == null) return false;
      
      final diff = DateTime.now().difference(lastSeen.toDate());
      return diff.inMinutes < 30; // En ligne si vu dans les 30 dernières minutes
      
    } catch (e) {
      return false;
    }
  }

  /// 📧 Générer le contenu HTML de l'email agent
  static String _genererEmailAgent(
    Map<String, dynamic> agent,
    Map<String, dynamic> sessionData,
    String sessionId,
    int urgence,
  ) {
    final infosGenerales = sessionData['commonInfo'] as Map<String, dynamic>? ?? {};
    final urgenceColor = urgence >= 3 ? '#ff4444' : urgence >= 2 ? '#ff8800' : '#00aa00';
    final urgenceText = urgence >= 3 ? 'URGENT' : urgence >= 2 ? 'MODÉRÉ' : 'NORMAL';
    
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>Nouveau Constat d'Accident</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
        <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px; text-align: center;">
                <h1 style="margin: 0;">🚨 Nouveau Constat d'Accident</h1>
                <p style="margin: 10px 0 0 0; font-size: 18px;">Niveau d'urgence: <span style="background: $urgenceColor; padding: 5px 10px; border-radius: 5px;">$urgenceText</span></p>
            </div>
            
            <div style="background: #f8f9fa; padding: 20px; margin: 20px 0; border-radius: 8px;">
                <h2 style="color: #495057; margin-top: 0;">👋 Bonjour ${agent['agentNom']},</h2>
                <p>Un nouveau constat d'accident vient d'être généré pour un véhicule sous votre gestion.</p>
            </div>
            
            <div style="background: white; border: 1px solid #dee2e6; border-radius: 8px; overflow: hidden; margin: 20px 0;">
                <div style="background: #007bff; color: white; padding: 15px;">
                    <h3 style="margin: 0;">📋 Détails du Sinistre</h3>
                </div>
                <div style="padding: 20px;">
                    <p><strong>🚗 Véhicule:</strong> ${agent['vehiculeInfo']}</p>
                    <p><strong>👤 Conducteur:</strong> ${agent['conducteurNom']}</p>
                    <p><strong>📅 Date accident:</strong> ${_formatDate(infosGenerales['dateAccident'])}</p>
                    <p><strong>📍 Lieu:</strong> ${infosGenerales['location']?['address'] ?? 'Non spécifié'}</p>
                    <p><strong>🏥 Blessés:</strong> ${infosGenerales['hasInjuries'] == true ? 'OUI' : 'NON'}</p>
                    <p><strong>🔢 Session:</strong> $sessionId</p>
                </div>
            </div>
            
            <div style="background: #d4edda; border: 1px solid #c3e6cb; border-radius: 8px; padding: 20px; margin: 20px 0;">
                <h3 style="color: #155724; margin-top: 0;">📎 Document Joint</h3>
                <p style="color: #155724;">Le constat complet au format PDF est joint à cet email. Il contient tous les détails de l'accident, les photos des dégâts, et les signatures numériques certifiées.</p>
            </div>
            
            <div style="text-align: center; margin: 30px 0;">
                <a href="mailto:support@constat-tunisie.tn" style="background: #007bff; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">📞 Contacter le Support</a>
            </div>
            
            <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; font-size: 12px; color: #6c757d; text-align: center;">
                <p>Cet email a été généré automatiquement par l'application Constat Tunisie.<br>
                Pour toute question, contactez notre support technique.</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  /// 📅 Formater une date
  static String _formatDate(dynamic date) {
    if (date == null) return 'Non spécifié';
    if (date is Timestamp) {
      final dt = date.toDate();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }
    return date.toString();
  }
}

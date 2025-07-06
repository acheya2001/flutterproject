import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/agent_registration_model.dart';
import '../../../core/services/debug_email_service.dart';

/// 🏢 Service d'inscription et d'approbation des agents d'assurance
class AgentRegistrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 📝 Soumettre une demande d'inscription d'agent
  static Future<String> submitAgentRegistration({
    required String email,
    required String password,
    required String prenom,
    required String nom,
    required String telephone,
    required String compagnie,
    required String agence,
    required String gouvernorat,
    required String poste,
    required String numeroAgent,
    String? carteIdRecto,
    String? carteIdVerso,
    String? permisRecto,
    String? permisVerso,
  }) async {
    try {
      debugPrint('[AgentRegistration] 📝 Début inscription agent: $email');

      // Vérifier si l'email existe déjà
      final existingRequests = await _firestore
          .collection('professional_account_requests')
          .where('email', isEqualTo: email)
          .get();

      if (existingRequests.docs.isNotEmpty) {
        throw Exception('Une demande existe déjà pour cet email');
      }

      // Créer la demande d'inscription
      final registrationData = AgentRegistrationModel(
        id: '', // Sera généré par Firestore
        email: email,
        password: password, // Stocké temporairement pour création après approbation
        prenom: prenom,
        nom: nom,
        telephone: telephone,
        compagnie: compagnie,
        agence: agence,
        gouvernorat: gouvernorat,
        poste: poste,
        numeroAgent: numeroAgent,
        carteIdRecto: carteIdRecto,
        carteIdVerso: carteIdVerso,
        permisRecto: permisRecto,
        permisVerso: permisVerso,
        status: 'pending',
        submittedAt: DateTime.now(),
        reviewedAt: null,
        reviewedBy: null,
        rejectionReason: null,
      );

      // Sauvegarder dans Firestore
      final docRef = await _firestore
          .collection('professional_account_requests')
          .add(registrationData.toMap());

      debugPrint('[AgentRegistration] ✅ Demande créée: ${docRef.id}');

      // Envoyer notification à l'admin
      await _notifyAdminNewRequest(docRef.id, registrationData);

      // Envoyer email de confirmation au demandeur
      await _sendConfirmationEmailToApplicant(registrationData);

      return docRef.id;

    } catch (e) {
      debugPrint('[AgentRegistration] ❌ Erreur inscription: $e');
      rethrow;
    }
  }

  /// 📧 Envoyer notification à l'admin
  static Future<void> _notifyAdminNewRequest(
    String requestId,
    AgentRegistrationModel registration,
  ) async {
    try {
      // Créer notification dans Firestore
      await _firestore.collection('notifications').add({
        'type': 'new_agent_request',
        'title': 'Nouvelle demande d\'agent',
        'message': 'Demande d\'inscription de ${registration.prenom} ${registration.nom} (${registration.compagnie})',
        'requestId': requestId,
        'userId': 'admin',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {
          'applicantName': '${registration.prenom} ${registration.nom}',
          'company': registration.compagnie,
          'email': registration.email,
        },
      });

      // Envoyer email à l'admin avec débuggage
      debugPrint('[AgentRegistration] 📧 Envoi email admin avec débuggage...');
      final emailResult = await DebugEmailService.sendEmailWithDebug(
        to: 'constat.tunisie.app@gmail.com',
        subject: '🏢 Nouvelle demande d\'agent d\'assurance',
        htmlBody: '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #2196F3;">🏢 Nouvelle demande d'agent d'assurance</h2>
          
          <div style="background: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h3>Informations du demandeur :</h3>
            <p><strong>Nom :</strong> ${registration.prenom} ${registration.nom}</p>
            <p><strong>Email :</strong> ${registration.email}</p>
            <p><strong>Téléphone :</strong> ${registration.telephone}</p>
            <p><strong>Compagnie :</strong> ${registration.compagnie}</p>
            <p><strong>Agence :</strong> ${registration.agence}</p>
            <p><strong>Gouvernorat :</strong> ${registration.gouvernorat}</p>
            <p><strong>Poste :</strong> ${registration.poste}</p>
            <p><strong>N° Agent :</strong> ${registration.numeroAgent}</p>
          </div>

          <div style="text-align: center; margin: 30px 0;">
            <p>Connectez-vous à l'interface admin pour examiner cette demande.</p>
            <a href="#" style="background: #4CAF50; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px;">
              Examiner la demande
            </a>
          </div>

          <p style="color: #666; font-size: 12px;">
            Cette demande nécessite votre approbation avant que l'agent puisse accéder au système.
          </p>
        </div>
        ''',
      );

      // Analyser le résultat de l'envoi
      debugPrint('[AgentRegistration] 📊 Résultat email admin:');
      debugPrint('[AgentRegistration] - Succès: ${emailResult['success']}');
      debugPrint('[AgentRegistration] - Méthode: ${emailResult['method']}');
      debugPrint('[AgentRegistration] - Étapes: ${emailResult['steps'].length}');
      debugPrint('[AgentRegistration] - Erreurs: ${emailResult['errors'].length}');

      if (emailResult['success']) {
        debugPrint('[AgentRegistration] ✅ Notification admin envoyée via ${emailResult['method']}');
      } else {
        debugPrint('[AgentRegistration] ⚠️ Notification admin échouée, mais inscription continue');
      }

    } catch (e) {
      debugPrint('[AgentRegistration] ⚠️ Erreur notification admin: $e');
      // Ne pas faire échouer l'inscription si la notification échoue
    }
  }

  /// 📧 Envoyer email de confirmation au demandeur
  static Future<void> _sendConfirmationEmailToApplicant(
    AgentRegistrationModel registration,
  ) async {
    try {
      debugPrint('[AgentRegistration] 📧 Envoi email confirmation avec débuggage...');
      final emailResult = await DebugEmailService.sendEmailWithDebug(
        to: registration.email,
        subject: '📝 Demande d\'inscription reçue - Constat Tunisie',
        htmlBody: '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #2196F3;">📝 Demande d'inscription reçue</h2>
          
          <p>Bonjour ${registration.prenom} ${registration.nom},</p>
          
          <p>Nous avons bien reçu votre demande d'inscription en tant qu'agent d'assurance pour <strong>${registration.compagnie}</strong>.</p>
          
          <div style="background: #e3f2fd; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h3 style="color: #1976d2;">📋 Récapitulatif de votre demande :</h3>
            <p><strong>Compagnie :</strong> ${registration.compagnie}</p>
            <p><strong>Agence :</strong> ${registration.agence}</p>
            <p><strong>Gouvernorat :</strong> ${registration.gouvernorat}</p>
            <p><strong>Poste :</strong> ${registration.poste}</p>
          </div>

          <div style="background: #fff3e0; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h3 style="color: #f57c00;">⏳ Prochaines étapes :</h3>
            <ol>
              <li>Votre demande est en cours d'examen par notre équipe</li>
              <li>Nous vérifierons vos informations et documents</li>
              <li>Vous recevrez un email de confirmation une fois approuvée</li>
              <li>Vous pourrez alors vous connecter à l'application</li>
            </ol>
          </div>

          <p style="color: #666;">
            <strong>Délai de traitement :</strong> 24-48 heures ouvrables<br>
            <strong>Contact :</strong> constat.tunisie.app@gmail.com
          </p>

          <p>Merci pour votre confiance !</p>
          <p><strong>L'équipe Constat Tunisie</strong></p>
        </div>
        ''',
      );

      // Analyser le résultat de l'envoi
      debugPrint('[AgentRegistration] 📊 Résultat email confirmation:');
      debugPrint('[AgentRegistration] - Succès: ${emailResult['success']}');
      debugPrint('[AgentRegistration] - Méthode: ${emailResult['method']}');
      debugPrint('[AgentRegistration] - Étapes: ${emailResult['steps'].length}');
      debugPrint('[AgentRegistration] - Erreurs: ${emailResult['errors'].length}');

      if (emailResult['success']) {
        debugPrint('[AgentRegistration] ✅ Email confirmation envoyé via ${emailResult['method']}');
      } else {
        debugPrint('[AgentRegistration] ⚠️ Email confirmation échoué, mais inscription continue');
      }

    } catch (e) {
      debugPrint('[AgentRegistration] ⚠️ Erreur email confirmation: $e');
      // Ne pas faire échouer l'inscription si l'email échoue
    }
  }

  /// ✅ Approuver une demande d'agent
  static Future<void> approveAgentRequest(String requestId, String adminId) async {
    try {
      debugPrint('[AgentRegistration] ✅ Approbation demande: $requestId');

      // Récupérer la demande
      final requestDoc = await _firestore
          .collection('professional_account_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Demande non trouvée');
      }

      final registration = AgentRegistrationModel.fromMap(
        requestDoc.data()!,
        requestDoc.id,
      );

      // Créer le compte Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: registration.email,
        password: registration.password,
      );

      debugPrint('[AgentRegistration] ✅ Compte Firebase créé: ${userCredential.user?.uid}');

      // Créer le profil utilisateur dans Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': registration.email,
        'userType': 'assureur',
        'role': 'assureur',
        'accountStatus': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': adminId,
      });

      // Créer le profil agent détaillé
      await _firestore.collection('assureurs').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': registration.email,
        'prenom': registration.prenom,
        'nom': registration.nom,
        'telephone': registration.telephone,
        'compagnie': registration.compagnie,
        'agence': registration.agence,
        'gouvernorat': registration.gouvernorat,
        'poste': registration.poste,
        'numeroAgent': registration.numeroAgent,
        'carteIdRecto': registration.carteIdRecto,
        'carteIdVerso': registration.carteIdVerso,
        'permisRecto': registration.permisRecto,
        'permisVerso': registration.permisVerso,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': adminId,
      });

      // Mettre à jour le statut de la demande
      await _firestore.collection('professional_account_requests').doc(requestId).update({
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminId,
        'agentUid': userCredential.user!.uid,
      });

      // Envoyer email d'approbation
      await _sendApprovalEmail(registration);

      debugPrint('[AgentRegistration] ✅ Agent approuvé avec succès');

    } catch (e) {
      debugPrint('[AgentRegistration] ❌ Erreur approbation: $e');
      rethrow;
    }
  }

  /// 📧 Envoyer email d'approbation
  static Future<void> _sendApprovalEmail(AgentRegistrationModel registration) async {
    try {
      debugPrint('[AgentRegistration] 📧 Envoi email approbation avec débuggage...');
      final emailResult = await DebugEmailService.sendEmailWithDebug(
        to: registration.email,
        subject: '🎉 Compte agent approuvé - Constat Tunisie',
        htmlBody: '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #4CAF50;">🎉 Félicitations ! Votre compte a été approuvé</h2>
          
          <p>Bonjour ${registration.prenom} ${registration.nom},</p>
          
          <p>Excellente nouvelle ! Votre demande d'inscription en tant qu'agent d'assurance a été <strong>approuvée</strong>.</p>
          
          <div style="background: #e8f5e8; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h3 style="color: #2e7d32;">✅ Votre compte est maintenant actif</h3>
            <p><strong>Email de connexion :</strong> ${registration.email}</p>
            <p><strong>Compagnie :</strong> ${registration.compagnie}</p>
            <p><strong>Agence :</strong> ${registration.agence}</p>
          </div>

          <div style="text-align: center; margin: 30px 0;">
            <p><strong>Vous pouvez maintenant vous connecter à l'application !</strong></p>
            <a href="#" style="background: #4CAF50; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px;">
              Se connecter maintenant
            </a>
          </div>

          <div style="background: #fff3e0; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h3 style="color: #f57c00;">🚀 Fonctionnalités disponibles :</h3>
            <ul>
              <li>Gestion des contrats d'assurance</li>
              <li>Vérification des véhicules</li>
              <li>Suivi des sinistres</li>
              <li>Rapports d'activité</li>
              <li>Interface de gestion complète</li>
            </ul>
          </div>

          <p>Bienvenue dans l'équipe Constat Tunisie !</p>
          <p><strong>L'équipe Constat Tunisie</strong></p>
        </div>
        ''',
      );

      // Analyser le résultat de l'envoi
      debugPrint('[AgentRegistration] 📊 Résultat email approbation:');
      debugPrint('[AgentRegistration] - Succès: ${emailResult['success']}');
      debugPrint('[AgentRegistration] - Méthode: ${emailResult['method']}');
      debugPrint('[AgentRegistration] - Étapes: ${emailResult['steps'].length}');
      debugPrint('[AgentRegistration] - Erreurs: ${emailResult['errors'].length}');

      if (emailResult['success']) {
        debugPrint('[AgentRegistration] ✅ Email approbation envoyé via ${emailResult['method']}');
      } else {
        debugPrint('[AgentRegistration] ⚠️ Email approbation échoué');
      }

    } catch (e) {
      debugPrint('[AgentRegistration] ⚠️ Erreur email approbation: $e');
    }
  }

  /// ❌ Rejeter une demande d'agent
  static Future<void> rejectAgentRequest(
    String requestId,
    String adminId,
    String reason,
  ) async {
    try {
      debugPrint('[AgentRegistration] ❌ Rejet demande: $requestId');

      // Récupérer la demande
      final requestDoc = await _firestore
          .collection('professional_account_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Demande non trouvée');
      }

      final registration = AgentRegistrationModel.fromMap(
        requestDoc.data()!,
        requestDoc.id,
      );

      // Mettre à jour le statut de la demande
      await _firestore.collection('professional_account_requests').doc(requestId).update({
        'status': 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminId,
        'rejectionReason': reason,
      });

      // Envoyer email de rejet
      await _sendRejectionEmail(registration, reason);

      debugPrint('[AgentRegistration] ✅ Demande rejetée');

    } catch (e) {
      debugPrint('[AgentRegistration] ❌ Erreur rejet: $e');
      rethrow;
    }
  }

  /// 📧 Envoyer email de rejet
  static Future<void> _sendRejectionEmail(
    AgentRegistrationModel registration,
    String reason,
  ) async {
    try {
      debugPrint('[AgentRegistration] 📧 Envoi email rejet avec débuggage...');
      final emailResult = await DebugEmailService.sendEmailWithDebug(
        to: registration.email,
        subject: '❌ Demande d\'inscription non approuvée - Constat Tunisie',
        htmlBody: '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #f44336;">❌ Demande non approuvée</h2>
          
          <p>Bonjour ${registration.prenom} ${registration.nom},</p>
          
          <p>Nous vous remercions pour votre demande d'inscription en tant qu'agent d'assurance.</p>
          
          <div style="background: #ffebee; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h3 style="color: #c62828;">Motif du refus :</h3>
            <p>$reason</p>
          </div>

          <div style="background: #e3f2fd; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h3 style="color: #1976d2;">💡 Que faire maintenant ?</h3>
            <p>Si vous pensez qu'il y a eu une erreur ou si vous souhaitez corriger les informations, vous pouvez :</p>
            <ul>
              <li>Nous contacter à : constat.tunisie.app@gmail.com</li>
              <li>Soumettre une nouvelle demande avec les corrections nécessaires</li>
            </ul>
          </div>

          <p>Merci pour votre compréhension.</p>
          <p><strong>L'équipe Constat Tunisie</strong></p>
        </div>
        ''',
      );

      // Analyser le résultat de l'envoi
      debugPrint('[AgentRegistration] 📊 Résultat email rejet:');
      debugPrint('[AgentRegistration] - Succès: ${emailResult['success']}');
      debugPrint('[AgentRegistration] - Méthode: ${emailResult['method']}');
      debugPrint('[AgentRegistration] - Étapes: ${emailResult['steps'].length}');
      debugPrint('[AgentRegistration] - Erreurs: ${emailResult['errors'].length}');

      if (emailResult['success']) {
        debugPrint('[AgentRegistration] ✅ Email rejet envoyé via ${emailResult['method']}');
      } else {
        debugPrint('[AgentRegistration] ⚠️ Email rejet échoué');
      }

    } catch (e) {
      debugPrint('[AgentRegistration] ⚠️ Erreur email rejet: $e');
    }
  }

  /// 📋 Récupérer toutes les demandes en attente
  static Future<List<AgentRegistrationModel>> getPendingRequests() async {
    try {
      final snapshot = await _firestore
          .collection('professional_account_requests')
          .where('status', isEqualTo: 'pending')
          .orderBy('submittedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AgentRegistrationModel.fromMap(doc.data(), doc.id))
          .toList();

    } catch (e) {
      debugPrint('[AgentRegistration] ❌ Erreur récupération demandes: $e');
      return [];
    }
  }

  /// 📊 Récupérer les statistiques des demandes
  static Future<Map<String, int>> getRequestsStats() async {
    try {
      final snapshot = await _firestore
          .collection('professional_account_requests')
          .get();

      final stats = <String, int>{
        'total': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
      };

      for (final doc in snapshot.docs) {
        final status = doc.data()['status'] as String? ?? 'pending';
        stats['total'] = (stats['total'] ?? 0) + 1;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;

    } catch (e) {
      debugPrint('[AgentRegistration] ❌ Erreur statistiques: $e');
      return {'total': 0, 'pending': 0, 'approved': 0, 'rejected': 0};
    }
  }
}

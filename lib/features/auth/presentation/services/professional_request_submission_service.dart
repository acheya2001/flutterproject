import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../admin/models/professional_request_model_final.dart';
import '../../../../core/services/email_notification_service.dart';

/// 📤 Service pour soumettre les demandes de comptes professionnels
class ProfessionalRequestSubmissionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'demandes_professionnels';

  /// 📤 Soumettre une demande de compte professionnel
  static Future<bool> submitRequest(ProfessionalRequestModel request) async {
    try {
      debugPrint('[REQUEST_SUBMISSION] 📤 Soumission demande: ${request.nomComplet}');

      // Vérifier si l'email existe déjà
      final existingRequest = await _checkExistingEmail(request.email);
      if (existingRequest) {
        throw Exception('Une demande avec cet email existe déjà');
      }

      // Préparer les données pour Firestore
      final requestData = request.toFirestore();
      
      // Ajouter des métadonnées
      requestData['created_at'] = FieldValue.serverTimestamp();
      requestData['updated_at'] = FieldValue.serverTimestamp();
      requestData['ip_address'] = await _getClientIP();
      requestData['user_agent'] = 'Flutter Mobile App';

      // Soumettre à Firestore
      final docRef = await _firestore.collection(_collection).add(requestData);
      
      debugPrint('[REQUEST_SUBMISSION] ✅ Demande soumise avec ID: ${docRef.id}');
      
      // Envoyer une notification aux admins (optionnel)
      await _notifyAdmins(request);

      // Envoyer un email de notification aux admins
      try {
        await EmailNotificationService.sendNewRequestNotificationToAdmins(
          nomComplet: request.nomComplet,
          email: request.email,
          role: request.roleFormate,
          requestId: docRef.id,
        );
        debugPrint('[ProfessionalRequest] ✅ Email de notification envoyé aux admins');
      } catch (e) {
        debugPrint('[ProfessionalRequest] ⚠️ Erreur envoi email: $e');
        // Ne pas bloquer la soumission si l'email échoue
      }
      
      return true;

    } catch (e) {
      debugPrint('[REQUEST_SUBMISSION] ❌ Erreur soumission: $e');
      rethrow;
    }
  }

  /// 🔍 Vérifier si un email existe déjà
  static Future<bool> _checkExistingEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('[REQUEST_SUBMISSION] ❌ Erreur vérification email: $e');
      return false;
    }
  }

  /// 🌐 Obtenir l'adresse IP du client (simulation)
  static Future<String> _getClientIP() async {
    // En production, vous pourriez utiliser un service pour obtenir l'IP réelle
    return 'Unknown';
  }

  /// 🔔 Notifier les admins d'une nouvelle demande
  static Future<void> _notifyAdmins(ProfessionalRequestModel request) async {
    try {
      // Créer une notification pour les admins
      await _firestore.collection('admin_notifications').add({
        'type': 'new_professional_request',
        'title': 'Nouvelle demande de compte professionnel',
        'message': '${request.nomComplet} a soumis une demande de compte ${request.roleFormate}',
        'request_id': request.id,
        'request_email': request.email,
        'request_role': request.roleDemande,
        'created_at': FieldValue.serverTimestamp(),
        'is_read': false,
        'priority': 'normal',
      });

      debugPrint('[REQUEST_SUBMISSION] 🔔 Notification admin créée');
    } catch (e) {
      debugPrint('[REQUEST_SUBMISSION] ❌ Erreur notification admin: $e');
      // Ne pas faire échouer la soumission si la notification échoue
    }
  }

  /// 📊 Obtenir les statistiques de soumission
  static Future<Map<String, dynamic>> getSubmissionStats() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      final futures = await Future.wait([
        // Demandes aujourd'hui
        _firestore
            .collection(_collection)
            .where('envoye_le', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .get(),
        
        // Demandes cette semaine
        _firestore
            .collection(_collection)
            .where('envoye_le', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
            .get(),
        
        // Demandes ce mois
        _firestore
            .collection(_collection)
            .where('envoye_le', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
            .get(),
        
        // Total des demandes
        _firestore.collection(_collection).get(),
      ]);

      return {
        'today': futures[0].docs.length,
        'this_week': futures[1].docs.length,
        'this_month': futures[2].docs.length,
        'total': futures[3].docs.length,
        'by_status': _calculateStatusStats(futures[3].docs),
        'by_role': _calculateRoleStats(futures[3].docs),
      };

    } catch (e) {
      debugPrint('[REQUEST_SUBMISSION] ❌ Erreur statistiques: $e');
      return {
        'today': 0,
        'this_week': 0,
        'this_month': 0,
        'total': 0,
        'by_status': {},
        'by_role': {},
      };
    }
  }

  /// 📊 Calculer les statistiques par statut
  static Map<String, int> _calculateStatusStats(List<QueryDocumentSnapshot> docs) {
    final stats = <String, int>{
      'en_attente': 0,
      'acceptee': 0,
      'rejetee': 0,
    };

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'en_attente';
      stats[status] = (stats[status] ?? 0) + 1;
    }

    return stats;
  }

  /// 📊 Calculer les statistiques par rôle
  static Map<String, int> _calculateRoleStats(List<QueryDocumentSnapshot> docs) {
    final stats = <String, int>{
      'agent_agence': 0,
      'expert_auto': 0,
      'admin_compagnie': 0,
      'admin_agence': 0,
    };

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final role = data['role_demande'] ?? '';
      stats[role] = (stats[role] ?? 0) + 1;
    }

    return stats;
  }

  /// ✅ Valider une demande avant soumission
  static String? validateRequest(ProfessionalRequestModel request) {
    // Validation des champs communs
    if (request.nomComplet.trim().isEmpty) {
      return 'Le nom complet est obligatoire';
    }
    
    if (request.email.trim().isEmpty || !_isValidEmail(request.email)) {
      return 'Email invalide';
    }
    
    if (request.tel.trim().isEmpty) {
      return 'Le numéro de téléphone est obligatoire';
    }
    
    if (request.cin.trim().isEmpty) {
      return 'Le CIN est obligatoire';
    }

    // Validation spécifique par rôle
    switch (request.roleDemande) {
      case 'agent_agence':
        if (request.nomAgence?.trim().isEmpty ?? true) {
          return 'Le nom de l\'agence est obligatoire pour un agent';
        }
        if (request.compagnie?.trim().isEmpty ?? true) {
          return 'La compagnie d\'assurance est obligatoire pour un agent';
        }
        if (request.adresseAgence?.trim().isEmpty ?? true) {
          return 'L\'adresse de l\'agence est obligatoire pour un agent';
        }
        break;

      case 'expert_auto':
        if (request.numAgrement?.trim().isEmpty ?? true) {
          return 'Le numéro d\'agrément est obligatoire pour un expert';
        }
        if (request.compagnie?.trim().isEmpty ?? true) {
          return 'La compagnie d\'assurance est obligatoire pour un expert';
        }
        if (request.zoneIntervention?.trim().isEmpty ?? true) {
          return 'La zone d\'intervention est obligatoire pour un expert';
        }
        break;

      case 'admin_compagnie':
        if (request.nomCompagnie?.trim().isEmpty ?? true) {
          return 'Le nom de la compagnie est obligatoire pour un admin compagnie';
        }
        if (request.fonction?.trim().isEmpty ?? true) {
          return 'La fonction est obligatoire pour un admin compagnie';
        }
        if (request.adresseSiege?.trim().isEmpty ?? true) {
          return 'L\'adresse du siège est obligatoire pour un admin compagnie';
        }
        break;

      case 'admin_agence':
        if (request.nomAgence?.trim().isEmpty ?? true) {
          return 'Le nom de l\'agence est obligatoire pour un admin agence';
        }
        if (request.compagnie?.trim().isEmpty ?? true) {
          return 'La compagnie d\'assurance est obligatoire pour un admin agence';
        }
        if (request.ville?.trim().isEmpty ?? true) {
          return 'La ville est obligatoire pour un admin agence';
        }
        if (request.adresseAgence?.trim().isEmpty ?? true) {
          return 'L\'adresse de l\'agence est obligatoire pour un admin agence';
        }
        break;

      default:
        return 'Rôle invalide';
    }

    return null; // Validation réussie
  }

  /// ✅ Valider l'email
  static bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  /// 📤 Soumettre une demande avec validation
  static Future<bool> submitRequestWithValidation(ProfessionalRequestModel request) async {
    // Valider la demande
    final validationError = validateRequest(request);
    if (validationError != null) {
      throw Exception(validationError);
    }

    // Soumettre la demande
    return await submitRequest(request);
  }

  /// 🔄 Mettre à jour une demande existante
  static Future<bool> updateRequest(String requestId, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = FieldValue.serverTimestamp();
      
      await _firestore.collection(_collection).doc(requestId).update(updates);
      
      debugPrint('[REQUEST_SUBMISSION] ✅ Demande mise à jour: $requestId');
      return true;

    } catch (e) {
      debugPrint('[REQUEST_SUBMISSION] ❌ Erreur mise à jour: $e');
      return false;
    }
  }

  /// 🗑️ Supprimer une demande
  static Future<bool> deleteRequest(String requestId) async {
    try {
      await _firestore.collection(_collection).doc(requestId).delete();
      
      debugPrint('[REQUEST_SUBMISSION] ✅ Demande supprimée: $requestId');
      return true;

    } catch (e) {
      debugPrint('[REQUEST_SUBMISSION] ❌ Erreur suppression: $e');
      return false;
    }
  }

  /// 📋 Obtenir une demande par ID
  static Future<ProfessionalRequestModel?> getRequestById(String requestId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(requestId).get();
      
      if (doc.exists) {
        return ProfessionalRequestModel.fromFirestore(doc);
      }
      
      return null;

    } catch (e) {
      debugPrint('[REQUEST_SUBMISSION] ❌ Erreur récupération: $e');
      return null;
    }
  }
}

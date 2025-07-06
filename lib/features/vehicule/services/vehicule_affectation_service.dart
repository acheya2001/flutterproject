import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/vehicule_conducteur_liaison_model.dart';
import '../models/vehicule_assure_model.dart';
import '../../auth/models/user_model.dart';

/// 🔗 Service d'affectation véhicule-conducteur
class VehiculeAffectationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🚗 Affecter un véhicule à un conducteur
  static Future<VehiculeConducteurLiaisonModel> affecterVehicule({
    required String vehiculeId,
    required String conducteurEmail,
    required String agentAffecteur,
    required String agenceId,
    required String compagnieId,
    List<String>? droits,
    DateTime? dateExpiration,
    String? commentaire,
  }) async {
    try {
      debugPrint('🔗 Affectation véhicule: $vehiculeId → $conducteurEmail');

      // Vérifier que le véhicule existe
      final vehiculeDoc = await _firestore
          .collection('vehicules_assures')
          .doc(vehiculeId)
          .get();

      if (!vehiculeDoc.exists) {
        throw Exception('Véhicule non trouvé: $vehiculeId');
      }

      // Vérifier s'il y a déjà une affectation active pour ce véhicule
      final existingLiaisons = await _firestore
          .collection('vehicules_conducteurs_liaisons')
          .where('vehicule_id', isEqualTo: vehiculeId)
          .where('statut', isEqualTo: 'actif')
          .get();

      // Désactiver les anciennes liaisons si nécessaire
      final batch = _firestore.batch();
      for (final doc in existingLiaisons.docs) {
        batch.update(doc.reference, {
          'statut': 'annule',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Créer la nouvelle liaison
      final now = DateTime.now();
      final liaisonId = _firestore.collection('vehicules_conducteurs_liaisons').doc().id;
      
      final liaison = VehiculeConducteurLiaisonModel(
        id: liaisonId,
        vehiculeId: vehiculeId,
        conducteurEmail: conducteurEmail.toLowerCase().trim(),
        agentAffecteur: agentAffecteur,
        agenceId: agenceId,
        compagnieId: compagnieId,
        dateAffectation: now,
        dateExpiration: dateExpiration,
        statut: LiaisonStatus.actif,
        droits: droits ?? ConducteurDroits.defaultDroits,
        commentaire: commentaire,
        createdAt: now,
        updatedAt: now,
      );

      // Ajouter la nouvelle liaison au batch
      batch.set(
        _firestore.collection('vehicules_conducteurs_liaisons').doc(liaisonId),
        liaison.toFirestore(),
      );

      // Exécuter le batch
      await batch.commit();

      debugPrint('✅ Véhicule affecté avec succès');

      // Envoyer notification email (TODO: implémenter)
      await _envoyerNotificationAffectation(liaison);

      return liaison;
    } catch (e) {
      debugPrint('❌ Erreur affectation véhicule: $e');
      rethrow;
    }
  }

  /// 📧 Envoyer notification d'affectation
  static Future<void> _envoyerNotificationAffectation(VehiculeConducteurLiaisonModel liaison) async {
    try {
      // TODO: Implémenter l'envoi d'email
      debugPrint('📧 Notification envoyée à: ${liaison.conducteurEmail}');
      
      // Marquer la notification comme envoyée
      await _firestore
          .collection('vehicules_conducteurs_liaisons')
          .doc(liaison.id)
          .update({
        'notification_envoyee': true,
        'date_notification': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Erreur envoi notification: $e');
    }
  }

  /// 📋 Obtenir les véhicules d'un conducteur
  static Future<List<VehiculeAssureModel>> getVehiculesConducteur(String conducteurEmail) async {
    try {
      debugPrint('📋 Récupération véhicules pour: $conducteurEmail');

      // Récupérer les liaisons actives
      final liaisonsSnapshot = await _firestore
          .collection('vehicules_conducteurs_liaisons')
          .where('conducteur_email', isEqualTo: conducteurEmail.toLowerCase().trim())
          .where('statut', isEqualTo: 'actif')
          .get();

      if (liaisonsSnapshot.docs.isEmpty) {
        debugPrint('ℹ️ Aucun véhicule affecté à ce conducteur');
        return [];
      }

      // Récupérer les détails des véhicules
      final List<VehiculeAssureModel> vehicules = [];
      
      for (final liaisonDoc in liaisonsSnapshot.docs) {
        final liaison = VehiculeConducteurLiaisonModel.fromFirestore(liaisonDoc);
        
        final vehiculeDoc = await _firestore
            .collection('vehicules_assures')
            .doc(liaison.vehiculeId)
            .get();

        if (vehiculeDoc.exists) {
          final vehicule = VehiculeAssureModel.fromFirestore(vehiculeDoc);
          vehicules.add(vehicule);
        }
      }

      debugPrint('✅ ${vehicules.length} véhicules trouvés');
      return vehicules;
    } catch (e) {
      debugPrint('❌ Erreur récupération véhicules conducteur: $e');
      rethrow;
    }
  }

  /// 🔍 Obtenir les liaisons d'un agent
  static Future<List<VehiculeConducteurLiaisonModel>> getLiaisonsAgent(String agentId) async {
    try {
      final snapshot = await _firestore
          .collection('vehicules_conducteurs_liaisons')
          .where('agent_affecteur', isEqualTo: agentId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => VehiculeConducteurLiaisonModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération liaisons agent: $e');
      rethrow;
    }
  }

  /// 🔄 Modifier le statut d'une liaison
  static Future<void> modifierStatutLiaison(String liaisonId, LiaisonStatus nouveauStatut) async {
    try {
      await _firestore
          .collection('vehicules_conducteurs_liaisons')
          .doc(liaisonId)
          .update({
        'statut': nouveauStatut.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Statut liaison modifié: $liaisonId → ${nouveauStatut.name}');
    } catch (e) {
      debugPrint('❌ Erreur modification statut liaison: $e');
      rethrow;
    }
  }

  /// 🔑 Modifier les droits d'une liaison
  static Future<void> modifierDroitsLiaison(String liaisonId, List<String> nouveauxDroits) async {
    try {
      await _firestore
          .collection('vehicules_conducteurs_liaisons')
          .doc(liaisonId)
          .update({
        'droits': nouveauxDroits,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Droits liaison modifiés: $liaisonId');
    } catch (e) {
      debugPrint('❌ Erreur modification droits liaison: $e');
      rethrow;
    }
  }

  /// 📊 Obtenir les statistiques d'affectation
  static Future<Map<String, dynamic>> getStatistiquesAffectation(String agentId) async {
    try {
      final snapshot = await _firestore
          .collection('vehicules_conducteurs_liaisons')
          .where('agent_affecteur', isEqualTo: agentId)
          .get();

      int totalAffectations = snapshot.docs.length;
      int affectationsActives = 0;
      int affectationsExpirees = 0;
      int affectationsSuspendues = 0;

      for (final doc in snapshot.docs) {
        final liaison = VehiculeConducteurLiaisonModel.fromFirestore(doc);
        switch (liaison.statut) {
          case LiaisonStatus.actif:
            affectationsActives++;
            break;
          case LiaisonStatus.expire:
            affectationsExpirees++;
            break;
          case LiaisonStatus.suspendu:
            affectationsSuspendues++;
            break;
          case LiaisonStatus.annule:
            // Ne pas compter les annulées
            break;
        }
      }

      return {
        'total_affectations': totalAffectations,
        'affectations_actives': affectationsActives,
        'affectations_expirees': affectationsExpirees,
        'affectations_suspendues': affectationsSuspendues,
        'taux_activite': totalAffectations > 0 ? (affectationsActives / totalAffectations) * 100 : 0,
      };
    } catch (e) {
      debugPrint('❌ Erreur statistiques affectation: $e');
      rethrow;
    }
  }

  /// 🔍 Vérifier si un conducteur peut utiliser un véhicule
  static Future<bool> peutUtiliserVehicule(String conducteurEmail, String vehiculeId, String droit) async {
    try {
      final snapshot = await _firestore
          .collection('vehicules_conducteurs_liaisons')
          .where('conducteur_email', isEqualTo: conducteurEmail.toLowerCase().trim())
          .where('vehicule_id', isEqualTo: vehiculeId)
          .where('statut', isEqualTo: 'actif')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return false;

      final liaison = VehiculeConducteurLiaisonModel.fromFirestore(snapshot.docs.first);
      
      // Vérifier l'expiration
      if (liaison.isExpire) return false;
      
      // Vérifier le droit
      return liaison.hasDroit(droit);
    } catch (e) {
      debugPrint('❌ Erreur vérification droit véhicule: $e');
      return false;
    }
  }

  /// 🔄 Synchroniser les liaisons avec les comptes conducteurs
  static Future<void> synchroniserLiaisons() async {
    try {
      debugPrint('🔄 Synchronisation des liaisons...');

      // Récupérer toutes les liaisons sans conducteur_id
      final liaisonsSnapshot = await _firestore
          .collection('vehicules_conducteurs_liaisons')
          .where('conducteur_id', isNull: true)
          .get();

      final batch = _firestore.batch();
      int synchronized = 0;

      for (final liaisonDoc in liaisonsSnapshot.docs) {
        final liaison = VehiculeConducteurLiaisonModel.fromFirestore(liaisonDoc);
        
        // Chercher le conducteur par email
        final conducteurSnapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: liaison.conducteurEmail)
            .where('type', isEqualTo: 'conducteur')
            .limit(1)
            .get();

        if (conducteurSnapshot.docs.isNotEmpty) {
          final conducteurId = conducteurSnapshot.docs.first.id;
          batch.update(liaisonDoc.reference, {
            'conducteur_id': conducteurId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          synchronized++;
        }
      }

      if (synchronized > 0) {
        await batch.commit();
        debugPrint('✅ $synchronized liaisons synchronisées');
      } else {
        debugPrint('ℹ️ Aucune liaison à synchroniser');
      }
    } catch (e) {
      debugPrint('❌ Erreur synchronisation liaisons: $e');
      rethrow;
    }
  }
}

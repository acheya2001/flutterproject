import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vehicle_status_model.dart';

/// 📊 Service de suivi des véhicules pour les conducteurs
class VehicleTrackingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 📝 Créer un suivi de statut pour un nouveau véhicule
  static Future<void> createVehicleTracking({
    required String vehicleId,
    required String conducteurId,
    String? agenceId,
    String? agenceNom,
  }) async {
    try {
      final tracking = VehicleStatusModel(
        vehicleId: vehicleId,
        conducteurId: conducteurId,
        currentStatus: VehicleStatus.enAttente,
        agenceId: agenceId,
        agenceNom: agenceNom,
        lastUpdated: DateTime.now(),
        history: [
          StatusHistoryEntry(
            status: VehicleStatus.enAttente,
            timestamp: DateTime.now(),
            actorId: conducteurId,
            actorRole: 'conducteur',
            comment: 'Demande d\'assurance soumise',
          ),
        ],
      );

      await _firestore
          .collection('vehicle_tracking')
          .doc(vehicleId)
          .set(tracking.toMap());

      print('✅ Suivi créé pour véhicule: $vehicleId');
    } catch (e) {
      print('❌ Erreur création suivi: $e');
      throw Exception('Erreur lors de la création du suivi: $e');
    }
  }

  /// 🔄 Mettre à jour le statut d'un véhicule
  static Future<void> updateVehicleStatus({
    required String vehicleId,
    required String newStatus,
    String? actorId,
    String? actorName,
    String? actorRole,
    String? agentId,
    String? agentNom,
    String? comment,
    String? rejectionReason,
  }) async {
    try {
      final trackingRef = _firestore.collection('vehicle_tracking').doc(vehicleId);
      final trackingDoc = await trackingRef.get();

      if (!trackingDoc.exists) {
        throw Exception('Suivi non trouvé pour le véhicule: $vehicleId');
      }

      final currentTracking = VehicleStatusModel.fromMap(trackingDoc.data()!);
      
      // Créer nouvelle entrée d'historique
      final historyEntry = StatusHistoryEntry(
        status: newStatus,
        timestamp: DateTime.now(),
        actorId: actorId,
        actorName: actorName,
        actorRole: actorRole,
        comment: comment,
        reason: rejectionReason,
      );

      // Mettre à jour le suivi
      final updatedHistory = [...currentTracking.history, historyEntry];
      
      await trackingRef.update({
        'currentStatus': newStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
        'agentId': agentId ?? currentTracking.agentId,
        'agentNom': agentNom ?? currentTracking.agentNom,
        'rejectionReason': rejectionReason,
        'history': updatedHistory.map((entry) => entry.toMap()).toList(),
      });

      // Mettre à jour aussi le véhicule principal
      await _firestore.collection('vehicules').doc(vehicleId).update({
        'etatCompte': newStatus,
        'agentAffecteId': agentId,
        'agentAffecteNom': agentNom,
        'rejectionReason': rejectionReason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Statut mis à jour: $vehicleId -> $newStatus');
    } catch (e) {
      print('❌ Erreur mise à jour statut: $e');
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }

  /// 📋 Récupérer le suivi d'un véhicule
  static Future<VehicleStatusModel?> getVehicleTracking(String vehicleId) async {
    try {
      final doc = await _firestore
          .collection('vehicle_tracking')
          .doc(vehicleId)
          .get();

      if (doc.exists) {
        return VehicleStatusModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Erreur récupération suivi: $e');
      return null;
    }
  }

  /// 📊 Stream du suivi d'un véhicule (temps réel)
  static Stream<VehicleStatusModel?> streamVehicleTracking(String vehicleId) {
    return _firestore
        .collection('vehicle_tracking')
        .doc(vehicleId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return VehicleStatusModel.fromMap(doc.data()!);
          }
          return null;
        });
  }

  /// 📋 Récupérer tous les suivis d'un conducteur
  static Stream<List<VehicleStatusModel>> streamConducteurVehicleTrackings(String conducteurId) {
    return _firestore
        .collection('vehicle_tracking')
        .where('conducteurId', isEqualTo: conducteurId)
        .snapshots()
        .map((snapshot) {
          final trackings = snapshot.docs
              .map((doc) => VehicleStatusModel.fromMap(doc.data()))
              .toList();

          // Trier côté client pour éviter l'index composite
          trackings.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
          return trackings;
        });
  }

  /// 🔔 Notifier le conducteur d'un changement de statut
  static Future<void> notifyConducteurStatusChange({
    required String vehicleId,
    required String conducteurId,
    required String newStatus,
    String? agentName,
    String? comment,
    String? rejectionReason,
  }) async {
    try {
      // Créer une notification pour le conducteur
      await _firestore
          .collection('notifications')
          .add({
        'type': 'vehicle_status_change',
        'recipientId': conducteurId,
        'recipientRole': 'conducteur',
        'title': 'Mise à jour de votre demande d\'assurance',
        'message': _getNotificationMessage(newStatus, agentName, rejectionReason),
        'data': {
          'vehicleId': vehicleId,
          'newStatus': newStatus,
          'agentName': agentName,
          'comment': comment,
          'rejectionReason': rejectionReason,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Notification envoyée au conducteur: $conducteurId');
    } catch (e) {
      print('❌ Erreur envoi notification: $e');
    }
  }

  /// 📝 Générer le message de notification
  static String _getNotificationMessage(String status, String? agentName, String? rejectionReason) {
    switch (status) {
      case VehicleStatus.affecteAgent:
        return 'Votre dossier a été affecté à l\'agent ${agentName ?? 'un agent'} pour traitement.';
      case VehicleStatus.contratCree:
        return 'Félicitations ! Votre contrat d\'assurance a été créé avec succès.';
      case VehicleStatus.documentsRequis:
        return 'Des documents supplémentaires sont requis pour finaliser votre dossier.';
      case VehicleStatus.rejete:
        return 'Votre demande a été rejetée. Raison: ${rejectionReason ?? 'Non spécifiée'}';
      case VehicleStatus.traiteAgent:
        return 'Votre dossier a été traité par l\'agent ${agentName ?? ''}.';
      default:
        return 'Le statut de votre demande a été mis à jour: $status';
    }
  }

  /// 🔄 Affecter un véhicule à un agent (utilisé par Admin Agence)
  static Future<void> assignVehicleToAgent({
    required String vehicleId,
    required String agentId,
    required String agentName,
    required String adminId,
    required String adminName,
    String? comment,
  }) async {
    await updateVehicleStatus(
      vehicleId: vehicleId,
      newStatus: VehicleStatus.affecteAgent,
      actorId: adminId,
      actorName: adminName,
      actorRole: 'admin_agence',
      agentId: agentId,
      agentNom: agentName,
      comment: comment ?? 'Dossier affecté à l\'agent $agentName',
    );

    // Récupérer l'ID du conducteur pour la notification
    final vehicleDoc = await _firestore.collection('vehicules').doc(vehicleId).get();
    if (vehicleDoc.exists) {
      final conducteurId = vehicleDoc.data()?['conducteurId'];
      if (conducteurId != null) {
        await notifyConducteurStatusChange(
          vehicleId: vehicleId,
          conducteurId: conducteurId,
          newStatus: VehicleStatus.affecteAgent,
          agentName: agentName,
          comment: comment,
        );
      }
    }
  }

  /// ✅ Créer un contrat (utilisé par Agent)
  static Future<void> createContract({
    required String vehicleId,
    required String agentId,
    required String agentName,
    String? contractNumber,
    String? comment,
  }) async {
    await updateVehicleStatus(
      vehicleId: vehicleId,
      newStatus: VehicleStatus.contratCree,
      actorId: agentId,
      actorName: agentName,
      actorRole: 'agent',
      comment: comment ?? 'Contrat créé avec succès${contractNumber != null ? ' - N°$contractNumber' : ''}',
    );

    // Récupérer l'ID du conducteur pour la notification
    final vehicleDoc = await _firestore.collection('vehicules').doc(vehicleId).get();
    if (vehicleDoc.exists) {
      final conducteurId = vehicleDoc.data()?['conducteurId'];
      if (conducteurId != null) {
        await notifyConducteurStatusChange(
          vehicleId: vehicleId,
          conducteurId: conducteurId,
          newStatus: VehicleStatus.contratCree,
          agentName: agentName,
          comment: comment,
        );
      }
    }
  }

  /// ❌ Rejeter un véhicule (utilisé par Admin Agence ou Agent)
  static Future<void> rejectVehicle({
    required String vehicleId,
    required String rejectionReason,
    required String actorId,
    required String actorName,
    required String actorRole,
  }) async {
    await updateVehicleStatus(
      vehicleId: vehicleId,
      newStatus: VehicleStatus.rejete,
      actorId: actorId,
      actorName: actorName,
      actorRole: actorRole,
      rejectionReason: rejectionReason,
      comment: 'Demande rejetée: $rejectionReason',
    );

    // Récupérer l'ID du conducteur pour la notification
    final vehicleDoc = await _firestore.collection('vehicules').doc(vehicleId).get();
    if (vehicleDoc.exists) {
      final conducteurId = vehicleDoc.data()?['conducteurId'];
      if (conducteurId != null) {
        await notifyConducteurStatusChange(
          vehicleId: vehicleId,
          conducteurId: conducteurId,
          newStatus: VehicleStatus.rejete,
          rejectionReason: rejectionReason,
        );
      }
    }
  }
}

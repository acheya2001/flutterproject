import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/insurance_structure_model.dart';
import '../../../services/agent_notification_service.dart';
import '../../notifications/services/email_notification_service.dart';
import '../../conducteur/models/conducteur_vehicle_model.dart';

/// 🔧 Service pour gérer la structure d'assurance (Compagnies → Agences → Agents)
/// Utilise les collections créées par les administrateurs
class InsuranceStructureService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🏢 Obtenir toutes les compagnies d'assurance actives (créées par les admins)
  static Future<List<Map<String, dynamic>>> getActiveCompanies() async {
    try {
      print('🔍 Recherche des compagnies dans la collection compagnies_assurance...');

      // D'abord, essayons de récupérer TOUTES les compagnies pour voir ce qui existe
      final allCompaniesSnapshot = await _firestore
          .collection('compagnies')
          .get();

      print('📊 Nombre total de compagnies trouvées: ${allCompaniesSnapshot.docs.length}');

      for (final doc in allCompaniesSnapshot.docs) {
        print('🏢 Compagnie trouvée: ${doc.id} - Data: ${doc.data()}');
      }

      // Maintenant essayons avec le filtre status (vos données utilisent 'active' en anglais)
      final querySnapshot = await _firestore
          .collection('compagnies')
          .where('status', isEqualTo: 'active')
          .get();

      print('✅ Compagnies actives trouvées: ${querySnapshot.docs.length}');

      final companies = querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'companyId': doc.id,
                'name': doc.data()['nom'] ?? '',
                'code': doc.data()['code'] ?? '',
                'logo': doc.data()['logoUrl'],
                'description': doc.data()['description'],
                'website': doc.data()['siteWeb'],
                'phone': doc.data()['telephone'],
                'email': doc.data()['email'],
                'isActive': doc.data()['status'] == 'active',
                ...doc.data(),
              })
          .toList();

      print('🎯 Compagnies formatées: $companies');
      return companies;
    } catch (e) {
      print('❌ Erreur récupération compagnies: $e');
      throw Exception('Erreur lors de la récupération des compagnies: $e');
    }
  }

  /// 🏪 Obtenir les agences d'une compagnie (créées par les admins)
  static Future<List<Map<String, dynamic>>> getAgenciesByCompany(String companyId) async {
    try {
      print('🔍 Recherche des agences pour compagnie: $companyId');

      // D'abord, voir toutes les agences
      final allAgenciesSnapshot = await _firestore
          .collection('agences')
          .get();

      print('📊 Nombre total d\'agences trouvées: ${allAgenciesSnapshot.docs.length}');

      for (final doc in allAgenciesSnapshot.docs) {
        print('🏪 Agence trouvée: ${doc.id} - Data: ${doc.data()}');
      }

      // Maintenant avec le filtre compagnieId (utiliser isActive au lieu de status)
      final querySnapshot = await _firestore
          .collection('agences')
          .where('compagnieId', isEqualTo: companyId)
          .where('isActive', isEqualTo: true)
          .get();

      print('✅ Agences trouvées pour compagnie $companyId: ${querySnapshot.docs.length}');

      // Enrichir les données des agences avec le nombre d'agents
      final agencies = <Map<String, dynamic>>[];

      for (final doc in querySnapshot.docs) {
        final agencyData = doc.data();

        // Compter le nombre d'agents actifs dans cette agence
        final agentsQuery = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'agent')
            .where('agenceId', isEqualTo: doc.id)
            .where('isActive', isEqualTo: true)
            .get();

        final agencyInfo = {
          'id': doc.id,
          'agencyId': doc.id,
          'companyId': agencyData['compagnieId'] ?? '',
          'name': agencyData['nom'] ?? '',
          'code': agencyData['code'] ?? '',
          'address': agencyData['adresse'],
          'city': agencyData['ville'],
          'governorate': agencyData['gouvernorat'],
          'postalCode': agencyData['codePostal'],
          'phone': agencyData['telephone'],
          'email': agencyData['email'],
          'managerName': agencyData['responsable'],
          'isActive': agencyData['isActive'] == true,
          'nombreAgents': agentsQuery.docs.length,
          ...agencyData,
        };

        agencies.add(agencyInfo);
      }

      return agencies;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des agences: $e');
    }
  }

  /// 👨‍💼 Obtenir les agents d'une agence (depuis la collection users)
  static Future<List<Map<String, dynamic>>> getAgentsByAgency(String agencyId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('agenceId', isEqualTo: agencyId)
          .where('status', isEqualTo: 'active')
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'agentId': doc.id,
                'agencyId': doc.data()['agenceId'] ?? '',
                'companyId': doc.data()['compagnieId'] ?? '',
                'firstName': doc.data()['prenom'] ?? '',
                'lastName': doc.data()['nom'] ?? '',
                'email': doc.data()['email'] ?? '',
                'phone': doc.data()['telephone'] ?? '',
                'employeeId': doc.data()['numeroAgent'],
                'role': doc.data()['poste'] ?? 'agent',
                'isActive': doc.data()['status'] == 'active',
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des agents: $e');
    }
  }

  /// 🚗 Soumettre un véhicule pour validation
  static Future<void> submitVehicleForValidation({
    required String vehicleId,
    required String conducteurId,
    required String conducteurNom,
    required String conducteurPrenom,
    required String conducteurTelephone,
    // Informations conducteur enrichies
    required String conducteurAddress,
    required String conducteurEmail,
    required String permisNumber,
    DateTime? permisDeliveryDate,
    // Informations compagnie/agence
    required String companyId,
    required String companyName,
    required String agencyId,
    required String agencyName,
    // Informations véhicule enrichies
    required String brand,
    required String model,
    required String plate,
    required int year,
    String? vin,
    required String color,
    required String carteGriseNumber,
    required String fuelType,
    DateTime? firstRegistrationDate,
    // Documents
    required List<String> documents,
  }) async {
    try {
      final pendingVehicle = PendingVehicle(
        vehicleId: vehicleId,
        conducteurId: conducteurId,
        conducteurNom: conducteurNom,
        conducteurPrenom: conducteurPrenom,
        conducteurTelephone: conducteurTelephone,
        // Informations conducteur enrichies
        conducteurAddress: conducteurAddress,
        conducteurEmail: conducteurEmail,
        permisNumber: permisNumber,
        permisDeliveryDate: permisDeliveryDate,
        // Informations compagnie/agence
        companyId: companyId,
        companyName: companyName,
        agencyId: agencyId,
        agencyName: agencyName,
        // Informations véhicule enrichies
        brand: brand,
        model: model,
        plate: plate,
        year: year,
        vin: vin,
        color: color,
        carteGriseNumber: carteGriseNumber,
        fuelType: fuelType,
        firstRegistrationDate: firstRegistrationDate,
        // Documents
        documents: documents,
        submittedAt: DateTime.now(),
      );

      // Sauvegarder dans la collection des véhicules en attente (pour les agents)
      await _firestore
          .collection('vehicules_en_attente')
          .doc(vehicleId)
          .set(pendingVehicle.toMap());

      // NOUVEAU : Sauvegarder aussi dans la collection du conducteur (pour son dashboard)
      final conducteurVehicle = ConducteurVehicleModel(
        vehicleId: vehicleId,
        conducteurUid: conducteurId,
        // Informations véhicule
        plate: plate,
        brand: brand,
        model: model,
        year: year,
        vin: vin,
        color: color,
        carteGriseNumber: carteGriseNumber,
        fuelType: fuelType,
        firstRegistrationDate: firstRegistrationDate,
        // Informations conducteur
        conducteurNom: conducteurNom,
        conducteurPrenom: conducteurPrenom,
        conducteurAddress: conducteurAddress,
        conducteurPhone: conducteurTelephone,
        conducteurEmail: conducteurEmail,
        permisNumber: permisNumber,
        permisDeliveryDate: permisDeliveryDate,
        // Propriétaire (conducteur par défaut)
        isConducteurOwner: true,
        // Documents et contrats
        contracts: [], // Sera rempli après validation par l'agent
        documents: documents.map((url) => VehicleDocument(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'uploaded',
          fileName: 'document_${DateTime.now().millisecondsSinceEpoch}',
          storagePath: url,
          downloadUrl: url,
          uploadedAt: DateTime.now(),
          isVerified: false,
        )).toList(),
        // Métadonnées
        createdAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
        isActive: true,
        isFakeData: false,
      );

      await _firestore
          .collection('conducteurs')
          .doc(conducteurId)
          .collection('vehicles')
          .doc(vehicleId)
          .set(conducteurVehicle.toMap());

      // Notifier les agents de l'agence
      await AgentNotificationService.notifyAgentsOfNewVehicle(
        agencyId: agencyId,
        vehicle: pendingVehicle,
      );

      debugPrint('[INSURANCE] ✅ Véhicule soumis pour validation: $vehicleId');

    } catch (e) {
      debugPrint('[INSURANCE] ❌ Erreur soumission véhicule: $e');
      throw Exception('Erreur lors de la soumission du véhicule: $e');
    }
  }

  /// 📢 Notifier les agents d'un nouveau véhicule
  static Future<void> _notifyAgentsOfNewVehicle(
    String agencyId,
    PendingVehicle vehicle,
  ) async {
    try {
      // Obtenir tous les agents de l'agence depuis la collection users
      final agents = await getAgentsByAgency(agencyId);

      print('🔔 Notification de ${agents.length} agents pour l\'agence $agencyId');

      // Créer une notification pour chaque agent
      for (final agent in agents) {
        await _firestore.collection('notifications').add({
          'recipientId': agent['agentId'],
          'recipientType': 'agent',
          'type': 'new_vehicle_pending',
          'title': 'Nouveau véhicule en attente',
          'message': 'Un nouveau véhicule ${vehicle.fullName} (${vehicle.plate}) a été soumis pour validation par ${vehicle.conducteurId}',
          'data': {
            'vehicleId': vehicle.vehicleId,
            'conducteurId': vehicle.conducteurId,
            'agencyId': agencyId,
            'companyId': vehicle.companyId,
            'vehicleName': vehicle.fullName,
            'plate': vehicle.plate,
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Envoyer email/SMS si configuré
        await _sendEmailNotificationToAgent(agent, vehicle);
      }

      print('✅ Notifications envoyées à ${agents.length} agents');
    } catch (e) {
      print('❌ Erreur lors de la notification des agents: $e');
    }
  }

  /// 📧 Envoyer notification email à un agent
  static Future<void> _sendEmailNotificationToAgent(
    Map<String, dynamic> agent,
    PendingVehicle vehicle,
  ) async {
    try {
      // Récupérer le nom de l'agence
      final agencyName = await _getAgencyName(vehicle.agencyId);

      // Envoyer l'email via le service dédié
      await EmailNotificationService.sendVehicleValidationNotification(
        agentEmail: agent['email'] ?? '',
        agentName: '${agent['firstName'] ?? ''} ${agent['lastName'] ?? ''}',
        vehicleName: vehicle.fullName,
        plate: vehicle.plate,
        conducteurId: vehicle.conducteurId,
        agencyName: agencyName,
      );

      // Envoyer SMS si numéro disponible
      if (agent['phone'] != null && agent['phone'].toString().isNotEmpty) {
        await EmailNotificationService.sendSMSNotification(
          phoneNumber: agent['phone'],
          message: 'Nouveau véhicule ${vehicle.plate} en attente de validation. Consultez votre dashboard.',
          type: 'vehicle_validation',
        );
      }
    } catch (e) {
      print('❌ Erreur envoi notification agent: $e');
    }
  }

  /// 🏪 Récupérer le nom d'une agence
  static Future<String> _getAgencyName(String agencyId) async {
    try {
      final doc = await _firestore
          .collection('agences')
          .doc(agencyId)
          .get();

      if (doc.exists) {
        return doc.data()?['nom'] ?? 'Agence inconnue';
      }
      return 'Agence inconnue';
    } catch (e) {
      return 'Agence inconnue';
    }
  }

  /// 📋 Obtenir les véhicules en attente pour une agence
  static Future<List<PendingVehicle>> getPendingVehiclesByAgency(String agencyId) async {
    try {
      final querySnapshot = await _firestore
          .collection('vehicules_en_attente')
          .where('agencyId', isEqualTo: agencyId)
          .where('status', isEqualTo: 'pending')
          .orderBy('submittedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PendingVehicle.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des véhicules en attente: $e');
    }
  }

  /// ✅ Valider un véhicule (par un agent)
  static Future<void> validateVehicle(String vehicleId, String agentId) async {
    try {
      await _firestore
          .collection('vehicules_en_attente')
          .doc(vehicleId)
          .update({
        'status': VehicleStatus.valide.value,
        'validatedBy': agentId,
        'validatedAt': FieldValue.serverTimestamp(),
      });

      // Notifier le conducteur
      final vehicleDoc = await _firestore
          .collection('vehicules_en_attente')
          .doc(vehicleId)
          .get();

      if (vehicleDoc.exists) {
        final vehicle = PendingVehicle.fromMap(vehicleDoc.data()!);
        await _notifyConducteurVehicleValidated(vehicle);
      }

      debugPrint('[INSURANCE] ✅ Véhicule validé: $vehicleId par agent: $agentId');
    } catch (e) {
      debugPrint('[INSURANCE] ❌ Erreur validation véhicule: $e');
      throw Exception('Erreur lors de la validation du véhicule: $e');
    }
  }

  /// ❌ Rejeter un véhicule (par un agent)
  static Future<void> rejectVehicle(
    String vehicleId, 
    String agentId, 
    String reason,
  ) async {
    try {
      await _firestore
          .collection('vehicules_en_attente')
          .doc(vehicleId)
          .update({
        'status': VehicleStatus.refuse.value,
        'validatedBy': agentId,
        'validatedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
      });

      // Notifier le conducteur
      final vehicleDoc = await _firestore
          .collection('vehicules_en_attente')
          .doc(vehicleId)
          .get();

      if (vehicleDoc.exists) {
        final vehicle = PendingVehicle.fromMap(vehicleDoc.data()!);
        await _notifyConducteurVehicleRejected(vehicle, reason);
      }
    } catch (e) {
      debugPrint('[INSURANCE] ❌ Erreur rejet véhicule: $e');
      throw Exception('Erreur lors du rejet du véhicule: $e');
    }
  }

  /// 📋 Créer un contrat et marquer le véhicule comme assuré
  static Future<String> createContractForVehicle({
    required String vehicleId,
    required String agentId,
    required String numeroContrat,
    required String typeCouverture,
    required DateTime dateDebut,
    required DateTime dateFin,
    required double montantPrime,
    String? conditionsParticulieres,
  }) async {
    try {
      // 1. Récupérer les infos du véhicule
      final vehicleDoc = await _firestore
          .collection('vehicules_en_attente')
          .doc(vehicleId)
          .get();

      if (!vehicleDoc.exists) {
        throw Exception('Véhicule non trouvé');
      }

      final vehicle = PendingVehicle.fromMap(vehicleDoc.data()!);

      // 2. Créer le contrat
      final contractRef = await _firestore.collection('contrats').add({
        'numeroContrat': numeroContrat,
        'vehiculeId': vehicleId,
        'conducteurId': vehicle.conducteurId,
        'agenceId': vehicle.agencyId,
        'compagnieId': vehicle.companyId,
        'agentId': agentId,
        'typeCouverture': typeCouverture,
        'dateDebut': Timestamp.fromDate(dateDebut),
        'dateFin': Timestamp.fromDate(dateFin),
        'montantPrime': montantPrime,
        'conditionsParticulieres': conditionsParticulieres,
        'statut': 'actif',
        'vehiculeInfo': {
          'marque': vehicle.brand,
          'modele': vehicle.model,
          'immatriculation': vehicle.plate,
          'annee': vehicle.year,
          'couleur': vehicle.color,
          'numeroCarteGrise': vehicle.carteGriseNumber,
        },
        'conducteurInfo': {
          'nom': vehicle.conducteurNom,
          'prenom': vehicle.conducteurPrenom,
          'telephone': vehicle.conducteurTelephone,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Mettre à jour le statut du véhicule
      await _firestore
          .collection('vehicules_en_attente')
          .doc(vehicleId)
          .update({
        'status': VehicleStatus.assure.value,
        'contractId': contractRef.id,
        'contractNumber': numeroContrat,
        'contractCreatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Notifier le conducteur
      await _notifyConducteurVehicleInsured(vehicle, numeroContrat);

      debugPrint('[INSURANCE] ✅ Contrat créé: ${contractRef.id} pour véhicule: $vehicleId');
      return contractRef.id;

    } catch (e) {
      debugPrint('[INSURANCE] ❌ Erreur création contrat: $e');
      throw Exception('Erreur lors de la création du contrat: $e');
    }
  }

  /// 📢 Notifier le conducteur que son véhicule a été validé
  static Future<void> _notifyConducteurVehicleValidated(PendingVehicle vehicle) async {
    try {
      await _firestore.collection('notifications').add({
        'recipientId': vehicle.conducteurId,
        'recipientType': 'conducteur',
        'type': 'vehicle_validated',
        'title': 'Véhicule validé',
        'message': 'Votre véhicule ${vehicle.fullName} (${vehicle.plate}) a été validé par l\'agence',
        'data': {
          'vehicleId': vehicle.vehicleId,
          'agencyId': vehicle.agencyId,
          'companyId': vehicle.companyId,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors de la notification du conducteur: $e');
    }
  }

  /// 📢 Notifier le conducteur que son véhicule a été rejeté
  static Future<void> _notifyConducteurVehicleRejected(
    PendingVehicle vehicle, 
    String reason,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'recipientId': vehicle.conducteurId,
        'recipientType': 'conducteur',
        'type': 'vehicle_rejected',
        'title': 'Véhicule rejeté',
        'message': 'Votre véhicule ${vehicle.fullName} (${vehicle.plate}) a été rejeté. Raison: $reason',
        'data': {
          'vehicleId': vehicle.vehicleId,
          'agencyId': vehicle.agencyId,
          'companyId': vehicle.companyId,
          'rejectionReason': reason,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors de la notification du conducteur: $e');
    }
  }

  /// 📢 Notifier le conducteur que son véhicule est maintenant assuré
  static Future<void> _notifyConducteurVehicleInsured(
    PendingVehicle vehicle,
    String numeroContrat,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'recipientId': vehicle.conducteurId,
        'recipientType': 'conducteur',
        'type': 'vehicle_insured',
        'title': 'Véhicule assuré',
        'message': 'Votre véhicule ${vehicle.fullName} (${vehicle.plate}) est maintenant assuré. Contrat: $numeroContrat',
        'data': {
          'vehicleId': vehicle.vehicleId,
          'agencyId': vehicle.agencyId,
          'companyId': vehicle.companyId,
          'contractNumber': numeroContrat,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Erreur lors de la notification du conducteur: $e');
    }
  }

  /// 🔄 Stream des véhicules en attente pour une agence
  static Stream<List<PendingVehicle>> streamPendingVehiclesByAgency(String agencyId) {
    return _firestore
        .collection('vehicules_en_attente')
        .where('agencyId', isEqualTo: agencyId)
        .where('status', isEqualTo: VehicleStatus.enAttenteValidation.value)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PendingVehicle.fromMap(doc.data()))
            .toList());
  }

  /// 📊 Obtenir les statistiques d'une agence
  static Future<Map<String, int>> getAgencyStats(String agencyId) async {
    try {
      final pendingQuery = await _firestore
          .collection('vehicules_en_attente')
          .where('agencyId', isEqualTo: agencyId)
          .where('status', isEqualTo: VehicleStatus.enAttenteValidation.value)
          .get();

      final validatedQuery = await _firestore
          .collection('vehicules_en_attente')
          .where('agencyId', isEqualTo: agencyId)
          .where('status', isEqualTo: VehicleStatus.valide.value)
          .get();

      final rejectedQuery = await _firestore
          .collection('vehicules_en_attente')
          .where('agencyId', isEqualTo: agencyId)
          .where('status', isEqualTo: VehicleStatus.refuse.value)
          .get();

      final insuredQuery = await _firestore
          .collection('vehicules_en_attente')
          .where('agencyId', isEqualTo: agencyId)
          .where('status', isEqualTo: VehicleStatus.assure.value)
          .get();

      return {
        'pending': pendingQuery.docs.length,
        'validated': validatedQuery.docs.length,
        'rejected': rejectedQuery.docs.length,
        'insured': insuredQuery.docs.length,
        'total': pendingQuery.docs.length + validatedQuery.docs.length + rejectedQuery.docs.length + insuredQuery.docs.length,
      };
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }
}

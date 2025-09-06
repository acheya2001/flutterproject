import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../features/insurance/models/digital_contract_model.dart';
import '../features/insurance/models/insurance_structure_model.dart';
import 'notification_service.dart';
import 'contract_completion_service.dart';

/// 🏢 Service principal pour la gestion complète des contrats numériques
/// Implémente le workflow complet : Conducteur → Admin Agence → Agent → Contrat → Paiement → Documents
class DigitalContractService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ========================================
  // 🚗 ÉTAPE 1: AJOUT VÉHICULE PAR CONDUCTEUR
  // ========================================

  /// 📝 Le conducteur ajoute un véhicule (statut: En attente de validation)
  static Future<String> submitVehicleForInsurance({
    required String conducteurId,
    required String compagnieId,
    required String agenceId,
    required Map<String, dynamic> vehicleData,
    required Map<String, dynamic> conducteurData,
  }) async {
    try {
      debugPrint('[DIGITAL_CONTRACT] 🚗 Soumission véhicule par conducteur: $conducteurId');

      // Créer le véhicule en attente
      final vehicleRef = await _firestore.collection('vehicules_en_attente').add({
        // Informations véhicule
        ...vehicleData,
        // Informations conducteur
        'conducteurId': conducteurId,
        'conducteurNom': conducteurData['nom'] ?? '',
        'conducteurPrenom': conducteurData['prenom'] ?? '',
        'conducteurTelephone': conducteurData['telephone'] ?? '',
        'conducteurEmail': conducteurData['email'] ?? '',
        'conducteurAddress': conducteurData['adresse'] ?? '',
        'permisNumber': conducteurData['permisNumber'] ?? '',
        'permisDeliveryDate': conducteurData['permisDeliveryDate'],
        // Compagnie et agence
        'compagnieId': compagnieId,
        'agenceId': agenceId,
        // Statut et métadonnées
        'status': VehicleStatus.enAttenteValidation.value,
        'submittedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'origin': 'conducteur_submission',
      });

      // Notifier l'admin agence
      await _notifyAdminAgenceNewVehicle(agenceId, vehicleRef.id, vehicleData, conducteurData);

      debugPrint('[DIGITAL_CONTRACT] ✅ Véhicule soumis: ${vehicleRef.id}');
      return vehicleRef.id;

    } catch (e) {
      debugPrint('[DIGITAL_CONTRACT] ❌ Erreur soumission véhicule: $e');
      throw Exception('Erreur lors de la soumission du véhicule: $e');
    }
  }

  // ========================================
  // 🏢 ÉTAPE 2: VALIDATION PAR ADMIN AGENCE
  // ========================================

  /// ✅ Admin agence valide le véhicule et assigne un agent
  static Future<void> validateVehicleByAdmin({
    required String vehicleId,
    required String adminId,
    required String assignedAgentId,
    String? notes,
  }) async {
    try {
      debugPrint('[DIGITAL_CONTRACT] ✅ Validation véhicule par admin: $vehicleId');

      // Récupérer les infos du véhicule
      final vehicleDoc = await _firestore.collection('vehicules_en_attente').doc(vehicleId).get();
      if (!vehicleDoc.exists) throw Exception('Véhicule non trouvé');

      final vehicleData = vehicleDoc.data()!;

      // Mettre à jour le statut
      await _firestore.collection('vehicules_en_attente').doc(vehicleId).update({
        'status': VehicleStatus.valide.value,
        'validatedBy': adminId,
        'validatedAt': FieldValue.serverTimestamp(),
        'assignedAgentId': assignedAgentId,
        'assignedAt': FieldValue.serverTimestamp(),
        'adminNotes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notifier l'agent assigné
      await _notifyAgentVehicleAssigned(assignedAgentId, vehicleId, vehicleData);

      // Notifier le conducteur
      await _notifyConducteurVehicleValidated(vehicleData['conducteurId'], vehicleId, vehicleData);

      debugPrint('[DIGITAL_CONTRACT] ✅ Véhicule validé et assigné à agent: $assignedAgentId');

    } catch (e) {
      debugPrint('[DIGITAL_CONTRACT] ❌ Erreur validation véhicule: $e');
      throw Exception('Erreur lors de la validation: $e');
    }
  }

  /// ❌ Admin agence rejette le véhicule
  static Future<void> rejectVehicleByAdmin({
    required String vehicleId,
    required String adminId,
    required String rejectionReason,
  }) async {
    try {
      debugPrint('[DIGITAL_CONTRACT] ❌ Rejet véhicule par admin: $vehicleId');

      // Récupérer les infos du véhicule
      final vehicleDoc = await _firestore.collection('vehicules_en_attente').doc(vehicleId).get();
      if (!vehicleDoc.exists) throw Exception('Véhicule non trouvé');

      final vehicleData = vehicleDoc.data()!;

      // Mettre à jour le statut
      await _firestore.collection('vehicules_en_attente').doc(vehicleId).update({
        'status': VehicleStatus.refuse.value,
        'rejectedBy': adminId,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectionReason': rejectionReason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notifier le conducteur
      await _notifyConducteurVehicleRejected(vehicleData['conducteurId'], vehicleId, rejectionReason);

      debugPrint('[DIGITAL_CONTRACT] ❌ Véhicule rejeté avec raison: $rejectionReason');

    } catch (e) {
      debugPrint('[DIGITAL_CONTRACT] ❌ Erreur rejet véhicule: $e');
      throw Exception('Erreur lors du rejet: $e');
    }
  }

  // ========================================
  // 👨‍💼 ÉTAPE 3: CRÉATION CONTRAT PAR AGENT
  // ========================================

  /// 📋 Agent commence la création du contrat
  static Future<String> startContractCreation({
    required String vehicleId,
    required String agentId,
    required ContractType contractType,
    required List<Garantie> garanties,
    required double primeAnnuelle,
    required PaymentFrequency paymentFrequency,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      debugPrint('[DIGITAL_CONTRACT] 📋 Début création contrat par agent: $agentId');

      // Récupérer les infos du véhicule
      final vehicleDoc = await _firestore.collection('vehicules_en_attente').doc(vehicleId).get();
      if (!vehicleDoc.exists) throw Exception('Véhicule non trouvé');

      final vehicleData = vehicleDoc.data()!;

      // Générer numéro de contrat unique
      final numeroContrat = await _generateContractNumber(
        vehicleData['compagnieId'], 
        vehicleData['agenceId'], 
        contractType
      );

      // Calculer les échéances
      final echeances = _calculatePaymentSchedule(primeAnnuelle, paymentFrequency);

      // Créer le contrat en brouillon
      final contractRef = await _firestore.collection('contrats_numeriques').add({
        'numeroContrat': numeroContrat,
        'vehiculeId': vehicleId,
        'conducteurId': vehicleData['conducteurId'],
        'agentId': agentId,
        'agenceId': vehicleData['agenceId'],
        'compagnieId': vehicleData['compagnieId'],
        'typeContrat': contractType.value,
        'statut': ContractStatus.brouillon.value,
        'dateDebut': Timestamp.fromDate(DateTime.now()),
        'dateFin': Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))),
        'primeAnnuelle': primeAnnuelle,
        'franchise': _calculateFranchise(contractType, primeAnnuelle),
        'garanties': garanties.map((g) => g.toMap()).toList(),
        'paiement': PaymentInfo(
          methode: PaymentMethod.carteBancaire,
          frequence: paymentFrequency,
          montantTotal: primeAnnuelle,
          montantPaye: 0.0,
          echeances: echeances,
          statut: PaymentStatus.enAttente,
        ).toMap(),
        'documents': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': agentId,
        'isActive': true,
        ...?additionalInfo,
      });

      // Mettre à jour le statut du véhicule
      await _firestore.collection('vehicules_en_attente').doc(vehicleId).update({
        'status': VehicleStatus.contratEnCours.value,
        'contractId': contractRef.id,
        'contractStartedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[DIGITAL_CONTRACT] ✅ Contrat créé en brouillon: ${contractRef.id}');
      return contractRef.id;

    } catch (e) {
      debugPrint('[DIGITAL_CONTRACT] ❌ Erreur création contrat: $e');
      throw Exception('Erreur lors de la création du contrat: $e');
    }
  }

  /// 📤 Agent finalise et propose le contrat au conducteur
  static Future<void> proposeContractToConducteur({
    required String contractId,
    required String agentId,
  }) async {
    try {
      debugPrint('[DIGITAL_CONTRACT] 📤 Proposition contrat au conducteur: $contractId');

      // Récupérer le contrat
      final contractDoc = await _firestore.collection('contrats_numeriques').doc(contractId).get();
      if (!contractDoc.exists) throw Exception('Contrat non trouvé');

      final contractData = contractDoc.data()!;

      // Générer les documents préliminaires
      final documents = await _generateContractDocuments(contractId, contractData);

      // Mettre à jour le contrat
      await _firestore.collection('contrats_numeriques').doc(contractId).update({
        'statut': ContractStatus.propose.value,
        'proposedAt': FieldValue.serverTimestamp(),
        'proposedBy': agentId,
        'documents': documents.map((d) => d.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour le statut du véhicule
      await _firestore.collection('vehicules_en_attente').doc(contractData['vehiculeId']).update({
        'status': VehicleStatus.contratPropose.value,
        'contractProposedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notifier le conducteur
      await _notifyConducteurContractProposed(contractData['conducteurId'], contractId, contractData);

      debugPrint('[DIGITAL_CONTRACT] ✅ Contrat proposé au conducteur');

    } catch (e) {
      debugPrint('[DIGITAL_CONTRACT] ❌ Erreur proposition contrat: $e');
      throw Exception('Erreur lors de la proposition: $e');
    }
  }

  // ========================================
  // 🔧 MÉTHODES UTILITAIRES PRIVÉES
  // ========================================

  /// Générer un numéro de contrat unique
  static Future<String> _generateContractNumber(String compagnieId, String agenceId, ContractType type) async {
    final year = DateTime.now().year;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${compagnieId.toUpperCase()}-${type.value.toUpperCase()}-$year-$timestamp';
  }

  /// Calculer les échéances de paiement
  static List<PaymentInstallment> _calculatePaymentSchedule(double totalAmount, PaymentFrequency frequency) {
    final installmentCount = frequency.installmentCount;
    final installmentAmount = totalAmount / installmentCount;
    final echeances = <PaymentInstallment>[];

    for (int i = 0; i < installmentCount; i++) {
      final dueDate = DateTime.now().add(Duration(days: (365 / installmentCount * i).round()));
      echeances.add(PaymentInstallment(
        numero: i + 1,
        montant: installmentAmount,
        dateEcheance: dueDate,
      ));
    }

    return echeances;
  }

  /// Calculer la franchise selon le type de contrat
  static double _calculateFranchise(ContractType type, double prime) {
    switch (type) {
      case ContractType.responsabiliteCivile:
        return 0.0;
      case ContractType.tiersPlusVol:
        return prime * 0.1; // 10% de la prime
      case ContractType.tousRisques:
        return prime * 0.15; // 15% de la prime
      case ContractType.temporaire:
        return prime * 0.05; // 5% de la prime
    }
  }

  /// Générer les documents du contrat
  static Future<List<ContractDocument>> _generateContractDocuments(String contractId, Map<String, dynamic> contractData) async {
    // Cette méthode sera implémentée pour générer les PDF
    // Pour l'instant, on retourne une liste vide
    return [];
  }

  // ========================================
  // 🔔 MÉTHODES DE NOTIFICATION PRIVÉES
  // ========================================

  static Future<void> _notifyAdminAgenceNewVehicle(String agenceId, String vehicleId, Map<String, dynamic> vehicleData, Map<String, dynamic> conducteurData) async {
    try {
      // Récupérer les admins de l'agence
      final adminsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin_agence')
          .where('agenceId', isEqualTo: agenceId)
          .where('isActive', isEqualTo: true)
          .get();

      for (final adminDoc in adminsQuery.docs) {
        await NotificationService.createNotification(
          recipientId: adminDoc.id,
          type: 'vehicle_submitted',
          title: 'Nouvelle demande d\'assurance',
          message: 'Véhicule ${vehicleData['marque']} ${vehicleData['modele']} soumis par ${conducteurData['prenom']} ${conducteurData['nom']}',
          data: {
            'vehicleId': vehicleId,
            'conducteurId': conducteurData['conducteurId'],
            'action': 'validate_vehicle',
          },
        );
      }
    } catch (e) {
      debugPrint('[DIGITAL_CONTRACT] ❌ Erreur notification admin agence: $e');
    }
  }

  static Future<void> _notifyAgentVehicleAssigned(String agentId, String vehicleId, Map<String, dynamic> vehicleData) async {
    try {
      await NotificationService.createNotification(
        recipientId: agentId,
        type: 'vehicle_assigned',
        title: 'Véhicule assigné',
        message: 'Créez un contrat pour ${vehicleData['marque']} ${vehicleData['modele']} (${vehicleData['numeroImmatriculation']})',
        data: {
          'vehicleId': vehicleId,
          'action': 'create_contract',
        },
      );
    } catch (e) {
      debugPrint('[DIGITAL_CONTRACT] ❌ Erreur notification agent: $e');
    }
  }

  static Future<void> _notifyConducteurVehicleValidated(String conducteurId, String vehicleId, Map<String, dynamic> vehicleData) async {
    try {
      await NotificationService.createNotification(
        recipientId: conducteurId,
        type: 'vehicle_validated',
        title: 'Demande validée ✅',
        message: 'Votre véhicule ${vehicleData['marque']} ${vehicleData['modele']} a été validé. Un agent va créer votre contrat.',
        data: {
          'vehicleId': vehicleId,
          'action': 'view_status',
        },
      );
    } catch (e) {
      debugPrint('[DIGITAL_CONTRACT] ❌ Erreur notification conducteur validé: $e');
    }
  }

  static Future<void> _notifyConducteurVehicleRejected(String conducteurId, String vehicleId, String reason) async {
    try {
      await NotificationService.createNotification(
        recipientId: conducteurId,
        type: 'vehicle_rejected',
        title: 'Demande rejetée ❌',
        message: 'Votre demande a été rejetée. Raison: $reason',
        data: {
          'vehicleId': vehicleId,
          'rejectionReason': reason,
          'action': 'view_rejection',
        },
      );
    } catch (e) {
      debugPrint('[DIGITAL_CONTRACT] ❌ Erreur notification conducteur rejeté: $e');
    }
  }

  static Future<void> _notifyConducteurContractProposed(String conducteurId, String contractId, Map<String, dynamic> contractData) async {
    try {
      await NotificationService.createNotification(
        recipientId: conducteurId,
        type: 'contract_proposed',
        title: 'Contrat proposé 📋',
        message: 'Votre contrat ${contractData['typeContrat']} est prêt. Prime: ${contractData['primeAnnuelle']} DT/an',
        data: {
          'contractId': contractId,
          'action': 'review_contract',
        },
      );
    } catch (e) {
      debugPrint('[DIGITAL_CONTRACT] ❌ Erreur notification contrat proposé: $e');
    }
  }
}

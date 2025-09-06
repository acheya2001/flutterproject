import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'contract_number_service.dart';
import 'contract_completion_service.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

/// 📋 Service de gestion des contrats d'assurance
class ContractService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 📝 Créer un nouveau contrat (côté agent)
  static Future<String?> createContract({
    required String vehiculeId,
    required String conducteurId,
    required String agenceId,
    required String compagnieId,
    required String typeCouverture,
    required double primeAssurance,
    required DateTime dateDebut,
    required DateTime dateFin,
    Map<String, dynamic>? optionsSupplementaires,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Agent non connecté');
      }

      // Générer numéro de contrat unique avec le nouveau service
      final numeroContrat = await ContractNumberService.generateUniqueContractNumber(
        compagnieId: compagnieId,
        agenceId: agenceId,
        typeContrat: typeCouverture,
      );
      
      // Créer le contrat
      final contractRef = await _firestore.collection('contrats').add({
        'numeroContrat': numeroContrat,
        'vehiculeId': vehiculeId,
        'conducteurId': conducteurId,
        'agenceId': agenceId,
        'compagnieId': compagnieId,
        'agentId': currentUser.uid,
        'typeCouverture': typeCouverture,
        'primeAssurance': primeAssurance,
        'dateDebut': Timestamp.fromDate(dateDebut),
        'dateFin': Timestamp.fromDate(dateFin),
        'statut': 'actif',
        'optionsSupplementaires': optionsSupplementaires ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Récupérer les données complètes du contrat pour le traitement post-création
      final fullContractData = {
        'id': contractRef.id,
        'numeroContrat': numeroContrat,
        'vehiculeId': vehiculeId,
        'conducteurId': conducteurId,
        'agenceId': agenceId,
        'compagnieId': compagnieId,
        'agentId': currentUser.uid,
        'typeContrat': typeCouverture,
        'primeAnnuelle': primeAssurance,
        'dateDebut': Timestamp.fromDate(dateDebut),
        'dateFin': Timestamp.fromDate(dateFin),
        'statut': 'actif',
        'optionsSupplementaires': optionsSupplementaires ?? {},
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 🎯 Lancer le processus complet de finalisation du contrat
      try {
        final completionResults = await ContractCompletionService.completeContractProcess(
          contractId: contractRef.id,
          vehicleId: vehiculeId,
          conducteurId: conducteurId,
          contractData: fullContractData,
        );

        print('✅ [CONTRACT_SERVICE] Contrat créé et finalisé: ${contractRef.id}');
        print('📄 Documents générés: ${completionResults['documents']}');
        print('📧 Notification envoyée: ${completionResults['notificationSent']}');

      } catch (e) {
        print('⚠️ [CONTRACT_SERVICE] Contrat créé mais erreur finalisation: $e');

        // Fallback: mise à jour basique du véhicule si la finalisation échoue
        await _firestore.collection('vehicules').doc(vehiculeId).update({
          'statutAssurance': 'assure',
          'numeroContratAssurance': numeroContrat,
          'contractId': contractRef.id,
          'agenceAssuranceId': agenceId,
          'compagnieAssuranceId': compagnieId,
          'estAssure': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Notification basique en cas d'échec de la finalisation complète
        await NotificationService.notifyContractCreated(
          conducteurId: conducteurId,
          vehiculeId: vehiculeId,
          numeroContrat: numeroContrat,
          agenceNom: 'Agence',
          vehiculeInfo: 'Véhicule',
        );
      }

      debugPrint('✅ Contrat créé: $numeroContrat');
      return contractRef.id;
    } catch (e) {
      debugPrint('❌ Erreur création contrat: $e');
      return null;
    }
  }

  /// 🔢 Générer un numéro de contrat unique
  static Future<String> _generateContractNumber(String compagnieId) async {
    try {
      // Format: COMP_YYYY_NNNNNN
      final year = DateTime.now().year;
      final compagnieCode = compagnieId.substring(0, 4).toUpperCase();
      
      // Compter les contrats existants cette année
      final startOfYear = DateTime(year, 1, 1);
      final endOfYear = DateTime(year, 12, 31, 23, 59, 59);
      
      final existingContracts = await _firestore
          .collection('contrats')
          .where('compagnieId', isEqualTo: compagnieId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfYear))
          .get();

      final nextNumber = existingContracts.docs.length + 1;
      final numeroContrat = '${compagnieCode}_${year}_${nextNumber.toString().padLeft(6, '0')}';
      
      return numeroContrat;
    } catch (e) {
      // Fallback avec timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'CTR_$timestamp';
    }
  }

  /// 📋 Récupérer les véhicules affectés aux agents d'une agence
  static Stream<QuerySnapshot> getPendingVehicles(String agenceId) {
    return _firestore
        .collection('vehicules')
        .where('etatCompte', isEqualTo: 'Affecté à Agent')
        .where('agenceAssuranceId', isEqualTo: agenceId)
        .snapshots();
  }

  /// 📋 Récupérer les contrats d'un conducteur
  static Stream<QuerySnapshot> getConducteurContracts(String conducteurId) {
    return _firestore
        .collection('contrats')
        .where('conducteurId', isEqualTo: conducteurId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 📋 Récupérer les contrats d'une agence
  static Stream<QuerySnapshot> getAgenceContracts(String agenceId) {
    return _firestore
        .collection('contrats')
        .where('agenceId', isEqualTo: agenceId)
        .snapshots();
  }

  /// 📄 Récupérer les détails d'un contrat
  static Future<Map<String, dynamic>?> getContractDetails(String contractId) async {
    try {
      final contractDoc = await _firestore.collection('contrats').doc(contractId).get();
      if (!contractDoc.exists) return null;

      final contractData = contractDoc.data()!;
      
      // Récupérer les infos du véhicule
      final vehiculeDoc = await _firestore
          .collection('vehicules')
          .doc(contractData['vehiculeId'])
          .get();
      
      // Récupérer les infos du conducteur
      final conducteurDoc = await _firestore
          .collection('users')
          .doc(contractData['conducteurId'])
          .get();
      
      // Récupérer les infos de l'agence
      final agenceDoc = await _firestore
          .collection('agences')
          .doc(contractData['agenceId'])
          .get();

      return {
        'contrat': contractData,
        'vehicule': vehiculeDoc.exists ? vehiculeDoc.data() : null,
        'conducteur': conducteurDoc.exists ? conducteurDoc.data() : null,
        'agence': agenceDoc.exists ? agenceDoc.data() : null,
      };
    } catch (e) {
      debugPrint('❌ Erreur récupération contrat: $e');
      return null;
    }
  }

  /// 🔄 Renouveler un contrat
  static Future<bool> renewContract({
    required String contractId,
    required DateTime nouvelleDateFin,
    required double nouvellePrime,
  }) async {
    try {
      await _firestore.collection('contrats').doc(contractId).update({
        'dateFin': Timestamp.fromDate(nouvelleDateFin),
        'primeAssurance': nouvellePrime,
        'statut': 'actif',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Contrat renouvelé: $contractId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur renouvellement: $e');
      return false;
    }
  }

  /// ❌ Résilier un contrat
  static Future<bool> cancelContract(String contractId, String motif) async {
    try {
      await _firestore.collection('contrats').doc(contractId).update({
        'statut': 'resilie',
        'motifResiliation': motif,
        'dateResiliation': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Contrat résilié: $contractId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur résiliation: $e');
      return false;
    }
  }
}

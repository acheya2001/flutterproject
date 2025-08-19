import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/notifications/services/notification_service.dart';

/// 📋 Service pour gérer les actions après création de contrat
class PostContractService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🎯 Traitement complet après création de contrat
  static Future<Map<String, dynamic>> processAfterContractCreation({
    required String contractId,
    required String vehicleId,
    required String conducteurId,
    required String agentId,
    required Map<String, dynamic> contractData,
  }) async {
    try {
      print('📋 [POST_CONTRACT] Début traitement post-création contrat: $contractId');

      final results = <String, dynamic>{};

      // 1. Mettre à jour le statut du véhicule
      await _updateVehicleStatus(vehicleId, contractId);
      results['vehicleUpdated'] = true;

      // 2. Créer la carte verte d'assurance
      final carteVerte = await _generateCarteVerte(contractData, vehicleId);
      results['carteVerte'] = carteVerte;

      // 3. Notifier le conducteur
      await _notifyConducteur(conducteurId, contractData, carteVerte);
      results['conducteurNotified'] = true;

      // 4. Mettre à jour les statistiques agent
      await _updateAgentStats(agentId, contractData);
      results['agentStatsUpdated'] = true;

      // 5. Créer l'échéancier de paiement
      final echeancier = await _createEcheancier(contractId, contractData);
      results['echeancier'] = echeancier;

      // 6. Archiver les documents
      await _archiveDocuments(vehicleId, contractId);
      results['documentsArchived'] = true;

      print('✅ [POST_CONTRACT] Traitement terminé avec succès');
      return results;

    } catch (e) {
      print('❌ [POST_CONTRACT] Erreur traitement: $e');
      throw Exception('Erreur post-création contrat: $e');
    }
  }

  /// 🚗 Mettre à jour le statut du véhicule
  static Future<void> _updateVehicleStatus(String vehicleId, String contractId) async {
    try {
      // Mettre à jour dans la collection véhicules
      await _firestore.collection('vehicules').doc(vehicleId).update({
        'etatCompte': 'Assuré',
        'contractId': contractId,
        'dateAssurance': FieldValue.serverTimestamp(),
        'isAssured': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ [POST_CONTRACT] Véhicule $vehicleId marqué comme assuré');
    } catch (e) {
      print('❌ [POST_CONTRACT] Erreur mise à jour véhicule: $e');
    }
  }

  /// 🛡️ Générer la carte verte d'assurance
  static Future<Map<String, dynamic>> _generateCarteVerte(
    Map<String, dynamic> contractData,
    String vehicleId,
  ) async {
    try {
      final carteVerteId = 'cv_${DateTime.now().millisecondsSinceEpoch}';
      
      final carteVerte = {
        'id': carteVerteId,
        'numeroContrat': contractData['numeroContrat'],
        'numeroPolice': contractData['numeroContrat'],
        'compagnieAssurance': contractData['compagnieNom'] ?? 'Compagnie d\'Assurance',
        'agenceAssurance': contractData['agenceNom'] ?? 'Agence d\'Assurance',
        'assure': {
          'nom': contractData['nomAssure'],
          'prenom': contractData['prenomAssure'],
          'adresse': contractData['adresseAssure'],
        },
        'vehicule': {
          'marque': contractData['vehiculeInfo']?['marque'],
          'modele': contractData['vehiculeInfo']?['modele'],
          'immatriculation': contractData['vehiculeInfo']?['numeroImmatriculation'],
          'annee': contractData['vehiculeInfo']?['annee'],
        },
        'validite': {
          'dateDebut': contractData['dateDebut'],
          'dateFin': contractData['dateFin'],
        },
        'typeAssurance': contractData['typeContrat'],
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      // Sauvegarder la carte verte
      await _firestore
          .collection('cartes_vertes')
          .doc(carteVerteId)
          .set(carteVerte);

      print('✅ [POST_CONTRACT] Carte verte générée: $carteVerteId');
      return carteVerte;

    } catch (e) {
      print('❌ [POST_CONTRACT] Erreur génération carte verte: $e');
      return {};
    }
  }

  /// 🔔 Notifier le conducteur
  static Future<void> _notifyConducteur(
    String conducteurId,
    Map<String, dynamic> contractData,
    Map<String, dynamic> carteVerte,
  ) async {
    try {
      // Notification dans l'app
      await NotificationService.createNotification(
        recipientId: conducteurId,
        recipientType: 'conducteur',
        type: 'contract_validated',
        title: '🎉 Contrat d\'assurance validé !',
        message: 'Votre contrat ${contractData['numeroContrat']} est maintenant actif. Votre véhicule est assuré !',
        data: {
          'contractId': contractData['id'],
          'numeroContrat': contractData['numeroContrat'],
          'carteVerteId': carteVerte['id'],
        },
      );

      // Créer une notification détaillée pour le conducteur
      await _firestore.collection('notifications_conducteur').add({
        'conducteurId': conducteurId,
        'type': 'contrat_valide',
        'title': 'Contrat d\'assurance validé',
        'message': 'Félicitations ! Votre contrat d\'assurance est maintenant actif.',
        'contractData': {
          'numeroContrat': contractData['numeroContrat'],
          'dateDebut': contractData['dateDebut'],
          'dateFin': contractData['dateFin'],
          'typeAssurance': contractData['typeContrat'],
        },
        'carteVerte': carteVerte,
        'actions': [
          {
            'label': 'Voir le contrat',
            'action': 'view_contract',
            'contractId': contractData['id'],
          },
          {
            'label': 'Télécharger carte verte',
            'action': 'download_carte_verte',
            'carteVerteId': carteVerte['id'],
          },
        ],
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ [POST_CONTRACT] Conducteur $conducteurId notifié');
    } catch (e) {
      print('❌ [POST_CONTRACT] Erreur notification conducteur: $e');
    }
  }

  /// 📊 Mettre à jour les statistiques agent
  static Future<void> _updateAgentStats(String agentId, Map<String, dynamic> contractData) async {
    try {
      final agentRef = _firestore.collection('users').doc(agentId);
      
      await _firestore.runTransaction((transaction) async {
        final agentDoc = await transaction.get(agentRef);
        
        if (agentDoc.exists) {
          final currentStats = agentDoc.data()?['stats'] ?? {};
          final contratsCreated = (currentStats['contratsCreated'] ?? 0) + 1;
          final totalPrimes = (currentStats['totalPrimes'] ?? 0.0) + (contractData['montantPrime'] ?? 0.0);
          
          transaction.update(agentRef, {
            'stats.contratsCreated': contratsCreated,
            'stats.totalPrimes': totalPrimes,
            'stats.lastContractDate': FieldValue.serverTimestamp(),
            'lastActivity': FieldValue.serverTimestamp(),
          });
        }
      });

      print('✅ [POST_CONTRACT] Statistiques agent $agentId mises à jour');
    } catch (e) {
      print('❌ [POST_CONTRACT] Erreur mise à jour stats agent: $e');
    }
  }

  /// 💰 Créer l'échéancier de paiement
  static Future<Map<String, dynamic>> _createEcheancier(
    String contractId,
    Map<String, dynamic> contractData,
  ) async {
    try {
      final montantPrime = contractData['montantPrime'] ?? 0.0;
      final dateDebut = (contractData['dateDebut'] as Timestamp).toDate();
      
      // Créer échéancier annuel (12 mensualités)
      final montantMensuel = montantPrime / 12;
      final echeances = <Map<String, dynamic>>[];
      
      for (int i = 0; i < 12; i++) {
        final dateEcheance = DateTime(dateDebut.year, dateDebut.month + i, dateDebut.day);
        
        echeances.add({
          'numero': i + 1,
          'dateEcheance': Timestamp.fromDate(dateEcheance),
          'montant': montantMensuel,
          'statut': 'en_attente',
          'datePaiement': null,
          'modePaiement': null,
        });
      }
      
      final echeancier = {
        'contractId': contractId,
        'numeroContrat': contractData['numeroContrat'],
        'montantTotal': montantPrime,
        'montantMensuel': montantMensuel,
        'nombreEcheances': 12,
        'echeances': echeances,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      // Sauvegarder l'échéancier
      await _firestore
          .collection('echeanciers')
          .doc(contractId)
          .set(echeancier);
      
      print('✅ [POST_CONTRACT] Échéancier créé pour contrat $contractId');
      return echeancier;
      
    } catch (e) {
      print('❌ [POST_CONTRACT] Erreur création échéancier: $e');
      return {};
    }
  }

  /// 📄 Archiver les documents
  static Future<void> _archiveDocuments(String vehicleId, String contractId) async {
    try {
      // Récupérer les documents du véhicule
      final vehicleDoc = await _firestore.collection('vehicules').doc(vehicleId).get();
      
      if (vehicleDoc.exists) {
        final vehicleData = vehicleDoc.data()!;
        
        // Archiver les documents importants
        final documentsArchive = {
          'contractId': contractId,
          'vehicleId': vehicleId,
          'documents': {
            'carteGrise': vehicleData['imageCarteGriseUrl'],
            'permisConduire': vehicleData['imagePermisUrl'],
          },
          'vehicleInfo': {
            'marque': vehicleData['marque'],
            'modele': vehicleData['modele'],
            'immatriculation': vehicleData['numeroImmatriculation'],
            'proprietaire': {
              'nom': vehicleData['nomProprietaire'],
              'prenom': vehicleData['prenomProprietaire'],
            },
          },
          'archivedAt': FieldValue.serverTimestamp(),
        };
        
        await _firestore
            .collection('documents_archives')
            .doc(contractId)
            .set(documentsArchive);
      }
      
      print('✅ [POST_CONTRACT] Documents archivés pour contrat $contractId');
    } catch (e) {
      print('❌ [POST_CONTRACT] Erreur archivage documents: $e');
    }
  }

  /// 📋 Récupérer le résumé pour le conducteur
  static Future<Map<String, dynamic>> getConducteurContractSummary(String contractId) async {
    try {
      final contractDoc = await _firestore.collection('contrats').doc(contractId).get();
      final carteVerteQuery = await _firestore
          .collection('cartes_vertes')
          .where('numeroContrat', isEqualTo: contractDoc.data()?['numeroContrat'])
          .limit(1)
          .get();
      
      final echeancierDoc = await _firestore.collection('echeanciers').doc(contractId).get();
      
      return {
        'contrat': contractDoc.data(),
        'carteVerte': carteVerteQuery.docs.isNotEmpty ? carteVerteQuery.docs.first.data() : null,
        'echeancier': echeancierDoc.data(),
      };
    } catch (e) {
      print('❌ [POST_CONTRACT] Erreur récupération résumé: $e');
      return {};
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/contract_number_service.dart';

/// 📋 Service de gestion des contrats pour les agents
class AgentContractService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 📊 Types de contrats disponibles
  static const Map<String, Map<String, dynamic>> contractTypes = {
    'responsabiliteCivile': {
      'displayName': 'Responsabilité Civile',
      'description': 'RC obligatoire uniquement',
      'basePrime': 300.0,
      'code': 'RC',
    },
    'tiersPlusVol': {
      'displayName': 'Tiers + Vol',
      'description': 'RC + Vol + Incendie + Bris de glace',
      'basePrime': 600.0,
      'code': 'TPV',
    },
    'tousRisques': {
      'displayName': 'Tous Risques',
      'description': 'Couverture complète tous dommages',
      'basePrime': 1200.0,
      'code': 'TR',
    },
    'temporaire': {
      'displayName': 'Temporaire',
      'description': 'Assurance courte durée',
      'basePrime': 150.0,
      'code': 'TEMP',
    },
    'flotte': {
      'displayName': 'Flotte',
      'description': 'Multi-véhicules entreprise',
      'basePrime': 800.0,
      'code': 'FLOTTE',
    },
  };

  /// 💰 Calculer la prime d'assurance
  static double calculatePrime({
    required String contractType,
    required int vehicleYear,
    int? puissanceFiscale,
    String? usage,
    String? region,
  }) {
    final baseInfo = contractTypes[contractType];
    if (baseInfo == null) return 500.0;

    double prime = baseInfo['basePrime'] as double;
    final currentYear = DateTime.now().year;
    final vehicleAge = currentYear - vehicleYear;

    // 🚗 Ajustement selon l'âge du véhicule
    if (vehicleAge > 10) {
      prime *= 0.8; // Réduction pour véhicule ancien
    } else if (vehicleAge < 2) {
      prime *= 1.3; // Majoration pour véhicule neuf
    } else if (vehicleAge <= 5) {
      prime *= 1.1; // Légère majoration pour véhicule récent
    }

    // ⚡ Ajustement selon la puissance fiscale
    if (puissanceFiscale != null) {
      if (puissanceFiscale > 15) {
        prime *= 1.4; // Majoration pour véhicule puissant
      } else if (puissanceFiscale > 10) {
        prime *= 1.2;
      } else if (puissanceFiscale < 6) {
        prime *= 0.9; // Réduction pour véhicule peu puissant
      }
    }

    // 🚙 Ajustement selon l'usage
    switch (usage?.toLowerCase()) {
      case 'professionnel':
      case 'commercial':
        prime *= 1.5;
        break;
      case 'taxi':
      case 'transport':
        prime *= 2.0;
        break;
      case 'personnel':
      default:
        // Pas d'ajustement
        break;
    }

    return prime.roundToDouble();
  }

  /// 📄 Créer un contrat d'assurance
  static Future<String> createContract({
    required Map<String, dynamic> vehicleData,
    required String contractType,
    required double primeAnnuelle,
    required DateTime dateDebut,
    required DateTime dateFin,
    String? numeroContrat,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Générer un numéro de contrat si non fourni
      final contractNumber = numeroContrat ?? await ContractNumberService.generateUniqueContractNumber(
        compagnieId: vehicleData['compagnieAssuranceId'] ?? 'default_company',
        agenceId: vehicleData['agenceAssuranceId'] ?? 'default_agency',
        typeContrat: contractType,
      );

      final contractData = {
        // Informations de base
        'numeroContrat': contractNumber,
        'typeContrat': contractType,
        'typeContratDisplay': contractTypes[contractType]?['displayName'] ?? contractType,
        'primeAnnuelle': primeAnnuelle,
        'dateDebut': Timestamp.fromDate(dateDebut),
        'dateFin': Timestamp.fromDate(dateFin),
        'statut': 'Proposé', // En attente d'acceptation du conducteur
        
        // Informations véhicule
        'vehiculeId': vehicleData['id'],
        'vehiculeInfo': {
          'marque': vehicleData['marque'],
          'modele': vehicleData['modele'],
          'immatriculation': vehicleData['numeroImmatriculation'],
          'annee': vehicleData['annee'],
          'puissanceFiscale': vehicleData['puissanceFiscale'],
          'usage': vehicleData['usage'],
          'numeroSerie': vehicleData['numeroSerie'],
        },

        // Informations conducteur/propriétaire
        'conducteurId': vehicleData['conducteurId'],
        'proprietaireInfo': {
          'nom': vehicleData['nomProprietaire'],
          'prenom': vehicleData['prenomProprietaire'],
          'adresse': vehicleData['adresseProprietaire'],
          'numeroPermis': vehicleData['numeroPermis'],
          'categoriePermis': vehicleData['categoriePermis'],
        },

        // Informations agence/agent
        'agenceId': vehicleData['agenceAssuranceId'],
        'compagnieId': vehicleData['compagnieAssuranceId'],
        'agentId': user.uid,
        'agentEmail': user.email,

        // Métadonnées
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
        
        // Informations additionnelles
        ...?additionalInfo,
      };

      // Créer le contrat
      final docRef = await _firestore.collection('contrats').add(contractData);

      // Mettre à jour le véhicule
      await _firestore.collection('vehicules').doc(vehicleData['id']).update({
        'etatCompte': 'Contrat Proposé',
        'contractId': docRef.id,
        'contractProposedAt': FieldValue.serverTimestamp(),
        'contractProposedBy': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Créer une notification pour le conducteur
      await _createConducteurNotification(
        conducteurId: vehicleData['conducteurId'],
        contractId: docRef.id,
        vehicleInfo: vehicleData,
        contractType: contractTypes[contractType]?['displayName'] ?? contractType,
        prime: primeAnnuelle,
      );

      print('✅ [CONTRACT] Contrat créé: ${docRef.id} pour véhicule ${vehicleData['id']}');
      return docRef.id;

    } catch (e) {
      print('❌ [CONTRACT] Erreur création contrat: $e');
      rethrow;
    }
  }

  /// 🔔 Créer une notification pour le conducteur
  static Future<void> _createConducteurNotification({
    required String conducteurId,
    required String contractId,
    required Map<String, dynamic> vehicleInfo,
    required String contractType,
    required double prime,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'type': 'contract_proposed',
        'title': 'Nouveau Contrat d\'Assurance',
        'message': 'Un contrat $contractType a été proposé pour votre ${vehicleInfo['marque']} ${vehicleInfo['modele']}',
        'recipientId': conducteurId,
        'recipientType': 'conducteur',
        'contractId': contractId,
        'vehicleId': vehicleInfo['id'],
        'data': {
          'contractType': contractType,
          'prime': prime,
          'vehicleInfo': {
            'marque': vehicleInfo['marque'],
            'modele': vehicleInfo['modele'],
            'immatriculation': vehicleInfo['numeroImmatriculation'],
          },
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ [NOTIFICATION] Erreur création notification: $e');
    }
  }

  /// 🔢 Générer un numéro de contrat unique
  static String _generateContractNumber(String contractType) {
    final typeCode = contractTypes[contractType]?['code'] ?? 'CTR';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return '$typeCode-${DateTime.now().year}-$random';
  }

  /// 📋 Récupérer les contrats d'un agent
  static Stream<QuerySnapshot> getAgentContracts(String agentId) {
    return _firestore
        .collection('contrats')
        .where('agentId', isEqualTo: agentId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 📋 Récupérer les contrats d'une agence
  static Stream<QuerySnapshot> getAgenceContracts(String agenceId) {
    return _firestore
        .collection('contrats')
        .where('agenceId', isEqualTo: agenceId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 📊 Récupérer les statistiques des contrats
  static Future<Map<String, int>> getContractStats(String agentId) async {
    try {
      final snapshot = await _firestore
          .collection('contrats')
          .where('agentId', isEqualTo: agentId)
          .get();

      final stats = <String, int>{
        'total': 0,
        'proposes': 0,
        'actifs': 0,
        'expires': 0,
        'rejetes': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final statut = data['statut'] as String? ?? '';
        
        stats['total'] = (stats['total'] ?? 0) + 1;
        
        switch (statut.toLowerCase()) {
          case 'proposé':
            stats['proposes'] = (stats['proposes'] ?? 0) + 1;
            break;
          case 'actif':
            stats['actifs'] = (stats['actifs'] ?? 0) + 1;
            break;
          case 'expiré':
            stats['expires'] = (stats['expires'] ?? 0) + 1;
            break;
          case 'rejeté':
            stats['rejetes'] = (stats['rejetes'] ?? 0) + 1;
            break;
        }
      }

      return stats;
    } catch (e) {
      print('❌ [STATS] Erreur récupération stats: $e');
      return {
        'total': 0,
        'proposes': 0,
        'actifs': 0,
        'expires': 0,
        'rejetes': 0,
      };
    }
  }
}

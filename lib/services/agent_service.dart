import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

/// 🏢 Service de gestion pour Agent
/// Gère toutes les opérations spécifiques aux agents
class AgentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 👤 Récupérer les informations de l'agent connecté
  static Future<Map<String, dynamic>?> getAgentInfo(String agentId) async {
    try {
      debugPrint('[AGENT] 👤 Récupération infos agent: $agentId');

      final agentDoc = await _firestore.collection('users').doc(agentId).get();
      if (!agentDoc.exists) {
        debugPrint('[AGENT] ❌ Agent non trouvé: $agentId');
        return null;
      }

      final agentData = agentDoc.data()!;
      agentData['id'] = agentDoc.id;

      // Récupérer les informations de l'agence
      final agenceId = agentData['agenceId'];
      if (agenceId != null) {
        final agenceDoc = await _firestore.collection('agences').doc(agenceId).get();
        if (agenceDoc.exists) {
          agentData['agenceInfo'] = agenceDoc.data();
        }
      }

      // Récupérer les informations de la compagnie
      final compagnieId = agentData['compagnieId'];
      if (compagnieId != null) {
        final compagnieDoc = await _firestore.collection('compagnies_assurance').doc(compagnieId).get();
        if (compagnieDoc.exists) {
          agentData['compagnieInfo'] = compagnieDoc.data();
        }
      }

      debugPrint('[AGENT] ✅ Infos agent récupérées: ${agentData['prenom']} ${agentData['nom']}');
      return agentData;

    } catch (e) {
      debugPrint('[AGENT] ❌ Erreur récupération agent: $e');
      return null;
    }
  }

  /// 📊 Récupérer les statistiques de l'agent
  static Future<Map<String, dynamic>> getAgentStats(String agentId) async {
    try {
      debugPrint('[AGENT] 📊 Récupération stats agent: $agentId');

      // Compter les contrats créés par cet agent
      final contratsQuery = await _firestore
          .collection('contrats')
          .where('agentId', isEqualTo: agentId)  // Utiliser agentId au lieu de createdBy
          .get();

      final totalContrats = contratsQuery.docs.length;
      final contratsActifs = contratsQuery.docs.where((doc) => 
          doc.data()['statut'] == 'actif' || doc.data()['isActive'] == true).length;

      // Compter les véhicules gérés
      final vehiculesQuery = await _firestore
          .collection('vehicules')
          .where('agentId', isEqualTo: agentId)
          .get();

      final totalVehicules = vehiculesQuery.docs.length;

      // Compter les conducteurs gérés
      final conducteursQuery = await _firestore
          .collection('conducteurs')
          .where('agentId', isEqualTo: agentId)
          .get();

      final totalConducteurs = conducteursQuery.docs.length;

      // Compter les sinistres traités
      final sinistresQuery = await _firestore
          .collection('sinistres')
          .where('agentId', isEqualTo: agentId)
          .get();

      final totalSinistres = sinistresQuery.docs.length;
      final sinistresEnCours = sinistresQuery.docs.where((doc) => 
          doc.data()['statut'] == 'en_cours' || doc.data()['statut'] == 'ouvert').length;

      // Récupérer les dernières activités
      final recentActivities = await _getRecentActivities(agentId);

      final stats = {
        'totalContrats': totalContrats,
        'contratsActifs': contratsActifs,
        'totalVehicules': totalVehicules,
        'totalConducteurs': totalConducteurs,
        'totalSinistres': totalSinistres,
        'sinistresEnCours': sinistresEnCours,
        'recentActivities': recentActivities,
      };

      debugPrint('[AGENT] ✅ Stats récupérées: $totalContrats contrats, $totalVehicules véhicules');
      return stats;

    } catch (e) {
      debugPrint('[AGENT] ❌ Erreur récupération stats: $e');
      return {
        'totalContrats': 0,
        'contratsActifs': 0,
        'totalVehicules': 0,
        'totalConducteurs': 0,
        'totalSinistres': 0,
        'sinistresEnCours': 0,
        'recentActivities': [],
      };
    }
  }

  /// 📝 Récupérer les activités récentes de l'agent
  static Future<List<Map<String, dynamic>>> _getRecentActivities(String agentId) async {
    try {
      List<Map<String, dynamic>> activities = [];

      // Derniers contrats créés - SANS orderBy pour éviter l'erreur d'index
      final contratsQuery = await _firestore
          .collection('contrats')
          .where('agentId', isEqualTo: agentId)  // Utiliser agentId au lieu de createdBy
          .get();

      // Trier en mémoire et limiter à 3
      final sortedDocs = contratsQuery.docs.toList();
      sortedDocs.sort((a, b) {
        final aDate = a.data()['createdAt'] as Timestamp?;
        final bDate = b.data()['createdAt'] as Timestamp?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      for (var doc in sortedDocs.take(3)) {
        final data = doc.data();
        activities.add({
          'type': 'contrat_created',
          'title': 'Contrat créé',
          'description': 'Contrat ${data['numeroContrat'] ?? doc.id}',
          'timestamp': data['createdAt'],
          'icon': 'contract',
        });
      }

      // Derniers véhicules ajoutés
      final vehiculesQuery = await _firestore
          .collection('vehicules')
          .where('agentId', isEqualTo: agentId)
          .orderBy('createdAt', descending: true)
          .limit(2)
          .get();

      for (var doc in vehiculesQuery.docs) {
        final data = doc.data();
        activities.add({
          'type': 'vehicule_added',
          'title': 'Véhicule ajouté',
          'description': '${data['marque']} ${data['modele']} - ${data['immatriculation']}',
          'timestamp': data['createdAt'],
          'icon': 'car',
        });
      }

      // Trier par timestamp décroissant
      activities.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return activities.take(5).toList();

    } catch (e) {
      debugPrint('[AGENT] ❌ Erreur récupération activités: $e');
      return [];
    }
  }

  /// 📋 Récupérer les contrats de l'agent
  static Future<List<Map<String, dynamic>>> getAgentContrats(String agentId) async {
    try {
      debugPrint('[AGENT] 📋 Récupération contrats agent: $agentId');

      // Requête simplifiée pour éviter l'index composite
      final contratsQuery = await _firestore
          .collection('contrats')
          .where('createdBy', isEqualTo: agentId)
          .get();

      List<Map<String, dynamic>> contrats = [];
      for (var doc in contratsQuery.docs) {
        final contratData = doc.data();
        contratData['id'] = doc.id;
        contrats.add(contratData);
      }

      // Trier côté client par date de création (plus récent en premier)
      contrats.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      debugPrint('[AGENT] ✅ ${contrats.length} contrats récupérés et triés');
      return contrats;

    } catch (e) {
      debugPrint('[AGENT] ❌ Erreur récupération contrats: $e');
      return [];
    }
  }

  /// 🚗 Récupérer les véhicules de l'agent
  static Future<List<Map<String, dynamic>>> getAgentVehicules(String agentId) async {
    try {
      debugPrint('[AGENT] 🚗 Récupération véhicules agent: $agentId');

      final vehiculesQuery = await _firestore
          .collection('vehicules')
          .where('agentId', isEqualTo: agentId)
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> vehicules = [];
      for (var doc in vehiculesQuery.docs) {
        final vehiculeData = doc.data();
        vehiculeData['id'] = doc.id;
        vehicules.add(vehiculeData);
      }

      debugPrint('[AGENT] ✅ ${vehicules.length} véhicules récupérés');
      return vehicules;

    } catch (e) {
      debugPrint('[AGENT] ❌ Erreur récupération véhicules: $e');
      return [];
    }
  }

  /// 👥 Récupérer les conducteurs de l'agent
  static Future<List<Map<String, dynamic>>> getAgentConducteurs(String agentId) async {
    try {
      debugPrint('[AGENT] 👥 Récupération conducteurs agent: $agentId');

      final conducteursQuery = await _firestore
          .collection('conducteurs')
          .where('agentId', isEqualTo: agentId)
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> conducteurs = [];
      for (var doc in conducteursQuery.docs) {
        final conducteurData = doc.data();
        conducteurData['id'] = doc.id;
        conducteurs.add(conducteurData);
      }

      debugPrint('[AGENT] ✅ ${conducteurs.length} conducteurs récupérés');
      return conducteurs;

    } catch (e) {
      debugPrint('[AGENT] ❌ Erreur récupération conducteurs: $e');
      return [];
    }
  }

  /// 🚨 Récupérer les sinistres de l'agent
  static Future<List<Map<String, dynamic>>> getAgentSinistres(String agentId) async {
    try {
      debugPrint('[AGENT] 🚨 Récupération sinistres agent: $agentId');

      final sinistresQuery = await _firestore
          .collection('sinistres')
          .where('agentId', isEqualTo: agentId)
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> sinistres = [];
      for (var doc in sinistresQuery.docs) {
        final sinistreData = doc.data();
        sinistreData['id'] = doc.id;
        sinistres.add(sinistreData);
      }

      debugPrint('[AGENT] ✅ ${sinistres.length} sinistres récupérés');
      return sinistres;

    } catch (e) {
      debugPrint('[AGENT] ❌ Erreur récupération sinistres: $e');
      return [];
    }
  }

  /// ➕ Créer un nouveau contrat
  static Future<Map<String, dynamic>> createContrat({
    required String agentId,
    required String agenceId,
    required String compagnieId,
    required String numeroContrat,
    required String typeContrat,
    required String nomAssure,
    required String prenomAssure,
    required String telephoneAssure,
    required String emailAssure,
    required DateTime dateDebut,
    required DateTime dateFin,
    required double montantPrime,
    String? adresseAssure,
    String? cinAssure,
    Map<String, dynamic>? vehiculeInfo,
  }) async {
    try {
      debugPrint('[AGENT] ➕ Création contrat: $numeroContrat');

      // Vérifier si le numéro de contrat existe déjà
      final existingContratQuery = await _firestore
          .collection('contrats')
          .where('numeroContrat', isEqualTo: numeroContrat)
          .limit(1)
          .get();

      if (existingContratQuery.docs.isNotEmpty) {
        return {
          'success': false,
          'error': 'Numéro de contrat déjà utilisé',
          'message': 'Ce numéro de contrat existe déjà',
        };
      }

      // Créer une référence de document pour auto-générer l'ID
      final docRef = _firestore.collection('contrats').doc();
      final contratId = docRef.id;

      // Données du contrat
      final contratData = {
        'id': contratId,
        'numeroContrat': numeroContrat,
        'typeContrat': typeContrat,
        'nomAssure': nomAssure,
        'prenomAssure': prenomAssure,
        'telephoneAssure': telephoneAssure,
        'emailAssure': emailAssure,
        'adresseAssure': adresseAssure,
        'cinAssure': cinAssure,
        'dateDebut': Timestamp.fromDate(dateDebut),
        'dateFin': Timestamp.fromDate(dateFin),
        'montantPrime': montantPrime,
        'statut': 'actif',
        'isActive': true,
        'agentId': agentId,
        'agenceId': agenceId,
        'compagnieId': compagnieId,
        'vehiculeInfo': vehiculeInfo,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': agentId,
        'origin': 'agent_creation',
      };

      // Créer le contrat dans Firestore
      await docRef.set(contratData);

      debugPrint('[AGENT] ✅ Contrat créé avec succès: $numeroContrat');
      return {
        'success': true,
        'message': 'Contrat créé avec succès',
        'contratId': contratId,
        'numeroContrat': numeroContrat,
      };

    } catch (e) {
      debugPrint('[AGENT] ❌ Erreur création contrat: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de la création du contrat',
      };
    }
  }

  /// ➕ Ajouter un véhicule
  static Future<Map<String, dynamic>> addVehicule({
    required String agentId,
    required String agenceId,
    required String compagnieId,
    required String immatriculation,
    required String marque,
    required String modele,
    required int annee,
    required String typeVehicule,
    required String couleur,
    String? numeroSerie,
    String? contratId,
    String? conducteurId,
  }) async {
    try {
      debugPrint('[AGENT] ➕ Ajout véhicule: $immatriculation');

      // Vérifier si l'immatriculation existe déjà
      final existingVehiculeQuery = await _firestore
          .collection('vehicules')
          .where('immatriculation', isEqualTo: immatriculation)
          .limit(1)
          .get();

      if (existingVehiculeQuery.docs.isNotEmpty) {
        return {
          'success': false,
          'error': 'Immatriculation déjà utilisée',
          'message': 'Cette immatriculation existe déjà',
        };
      }

      // Créer une référence de document pour auto-générer l'ID
      final docRef = _firestore.collection('vehicules').doc();
      final vehiculeId = docRef.id;

      // Données du véhicule
      final vehiculeData = {
        'id': vehiculeId,
        'immatriculation': immatriculation,
        'marque': marque,
        'modele': modele,
        'annee': annee,
        'typeVehicule': typeVehicule,
        'couleur': couleur,
        'numeroSerie': numeroSerie,
        'contratId': contratId,
        'conducteurId': conducteurId,
        'agentId': agentId,
        'agenceId': agenceId,
        'compagnieId': compagnieId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': agentId,
        'origin': 'agent_creation',
      };

      // Créer le véhicule dans Firestore
      await docRef.set(vehiculeData);

      debugPrint('[AGENT] ✅ Véhicule ajouté avec succès: $immatriculation');
      return {
        'success': true,
        'message': 'Véhicule ajouté avec succès',
        'vehiculeId': vehiculeId,
        'immatriculation': immatriculation,
      };

    } catch (e) {
      debugPrint('[AGENT] ❌ Erreur ajout véhicule: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de l\'ajout du véhicule',
      };
    }
  }

  /// ➕ Ajouter un conducteur
  static Future<Map<String, dynamic>> addConducteur({
    required String agentId,
    required String agenceId,
    required String compagnieId,
    required String nom,
    required String prenom,
    required String cin,
    required String telephone,
    required DateTime dateNaissance,
    required String numeroPermis,
    required DateTime dateObtentionPermis,
    String? email,
    String? adresse,
    String? vehiculeId,
  }) async {
    try {
      debugPrint('[AGENT] ➕ Ajout conducteur: $prenom $nom');

      // Vérifier si le CIN existe déjà
      final existingConducteurQuery = await _firestore
          .collection('conducteurs')
          .where('cin', isEqualTo: cin)
          .limit(1)
          .get();

      if (existingConducteurQuery.docs.isNotEmpty) {
        return {
          'success': false,
          'error': 'CIN déjà utilisé',
          'message': 'Ce CIN existe déjà',
        };
      }

      // Créer une référence de document pour auto-générer l'ID
      final docRef = _firestore.collection('conducteurs').doc();
      final conducteurId = docRef.id;

      // Données du conducteur
      final conducteurData = {
        'id': conducteurId,
        'nom': nom,
        'prenom': prenom,
        'cin': cin,
        'telephone': telephone,
        'email': email,
        'adresse': adresse,
        'dateNaissance': Timestamp.fromDate(dateNaissance),
        'numeroPermis': numeroPermis,
        'dateObtentionPermis': Timestamp.fromDate(dateObtentionPermis),
        'vehiculeId': vehiculeId,
        'agentId': agentId,
        'agenceId': agenceId,
        'compagnieId': compagnieId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': agentId,
        'origin': 'agent_creation',
      };

      // Créer le conducteur dans Firestore
      await docRef.set(conducteurData);

      debugPrint('[AGENT] ✅ Conducteur ajouté avec succès: $prenom $nom');
      return {
        'success': true,
        'message': 'Conducteur ajouté avec succès',
        'conducteurId': conducteurId,
        'displayName': '$prenom $nom',
      };

    } catch (e) {
      debugPrint('[AGENT] ❌ Erreur ajout conducteur: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erreur lors de l\'ajout du conducteur',
      };
    }
  }
}

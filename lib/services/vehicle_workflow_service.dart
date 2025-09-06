import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 🚗 Service de gestion du workflow des véhicules
/// Gère le processus : Conducteur → Admin Agence → Agent → Contrat
class VehicleWorkflowService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📋 États possibles d'un véhicule dans le workflow
  static const String ETAT_EN_ATTENTE = 'En attente';
  static const String ETAT_VALIDE_ADMIN = 'Validé par Admin';
  static const String ETAT_AFFECTE_AGENT = 'Affecté à Agent';
  static const String ETAT_ASSURE = 'Assuré';
  static const String ETAT_REJETE = 'Rejeté';

  /// 🏢 Récupérer les véhicules pour l'admin agence
  static Future<List<Map<String, dynamic>>> getVehiclesForAdminAgence(String agenceId) async {
    try {
      debugPrint('[WORKFLOW] 📋 Récupération véhicules pour agence: $agenceId');

      final query = await _firestore
          .collection('vehicules')
          .where('agenceId', isEqualTo: agenceId)
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> vehicules = [];

      for (var doc in query.docs) {
        Map<String, dynamic> vehiculeData = doc.data();
        vehiculeData['id'] = doc.id;

        // Enrichir avec les informations du conducteur
        if (vehiculeData['conducteurId'] != null) {
          final conducteurDoc = await _firestore
              .collection('users')
              .doc(vehiculeData['conducteurId'])
              .get();

          if (conducteurDoc.exists) {
            vehiculeData['conducteurInfo'] = conducteurDoc.data();
          }
        }

        // Enrichir avec les informations de l'agent affecté
        if (vehiculeData['agentAffecteId'] != null) {
          final agentDoc = await _firestore
              .collection('users')
              .doc(vehiculeData['agentAffecteId'])
              .get();

          if (agentDoc.exists) {
            vehiculeData['agentInfo'] = agentDoc.data();
          }
        }

        vehicules.add(vehiculeData);
      }

      debugPrint('[WORKFLOW] ✅ ${vehicules.length} véhicules récupérés');
      return vehicules;

    } catch (e) {
      debugPrint('[WORKFLOW] ❌ Erreur récupération véhicules: $e');
      return [];
    }
  }

  /// ✅ Valider un véhicule par l'admin agence
  static Future<bool> validerVehiculeParAdmin({
    required String vehiculeId,
    required String adminId,
    required String agenceId,
  }) async {
    try {
      debugPrint('[WORKFLOW] ✅ Validation véhicule $vehiculeId par admin $adminId');

      await _firestore.collection('vehicules').doc(vehiculeId).update({
        'etatCompte': ETAT_VALIDE_ADMIN,
        'dateValidation': FieldValue.serverTimestamp(),
        'adminValidateurId': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Créer un historique
      await _creerHistoriqueAction(
        vehiculeId: vehiculeId,
        action: 'validation_admin',
        utilisateurId: adminId,
        details: {
          'etatPrecedent': ETAT_EN_ATTENTE,
          'nouvelEtat': ETAT_VALIDE_ADMIN,
          'agenceId': agenceId,
        },
      );

      debugPrint('[WORKFLOW] ✅ Véhicule validé avec succès');
      return true;

    } catch (e) {
      debugPrint('[WORKFLOW] ❌ Erreur validation véhicule: $e');
      return false;
    }
  }

  /// 👨‍💼 Affecter un véhicule à un agent
  static Future<bool> affecterVehiculeAAgent({
    required String vehiculeId,
    required String agentId,
    required String adminId,
    required String agenceId,
  }) async {
    try {
      debugPrint('[WORKFLOW] 👨‍💼 Affectation véhicule $vehiculeId à agent $agentId');

      // Vérifier que l'agent appartient à la même agence
      final agentDoc = await _firestore.collection('users').doc(agentId).get();
      if (!agentDoc.exists) {
        throw Exception('Agent non trouvé');
      }

      final agentData = agentDoc.data()!;
      if (agentData['agenceId'] != agenceId) {
        throw Exception('Agent n\'appartient pas à cette agence');
      }

      await _firestore.collection('vehicules').doc(vehiculeId).update({
        'etatCompte': ETAT_AFFECTE_AGENT,
        'agentAffecteId': agentId,
        'dateAffectation': FieldValue.serverTimestamp(),
        'adminAffectateurId': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Créer un historique
      await _creerHistoriqueAction(
        vehiculeId: vehiculeId,
        action: 'affectation_agent',
        utilisateurId: adminId,
        details: {
          'etatPrecedent': ETAT_VALIDE_ADMIN,
          'nouvelEtat': ETAT_AFFECTE_AGENT,
          'agentId': agentId,
          'agentNom': '${agentData['prenom']} ${agentData['nom']}',
          'agenceId': agenceId,
        },
      );

      debugPrint('[WORKFLOW] ✅ Véhicule affecté avec succès');
      return true;

    } catch (e) {
      debugPrint('[WORKFLOW] ❌ Erreur affectation véhicule: $e');
      return false;
    }
  }

  /// 📋 Marquer un véhicule comme assuré (après création du contrat)
  static Future<bool> marquerVehiculeAssure({
    required String vehiculeId,
    required String contratId,
    required String agentId,
  }) async {
    try {
      debugPrint('[WORKFLOW] 📋 Marquage véhicule $vehiculeId comme assuré');

      await _firestore.collection('vehicules').doc(vehiculeId).update({
        'etatCompte': ETAT_ASSURE,
        'contratId': contratId,
        'dateContrat': FieldValue.serverTimestamp(),
        'agentContratId': agentId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Créer un historique
      await _creerHistoriqueAction(
        vehiculeId: vehiculeId,
        action: 'creation_contrat',
        utilisateurId: agentId,
        details: {
          'etatPrecedent': ETAT_AFFECTE_AGENT,
          'nouvelEtat': ETAT_ASSURE,
          'contratId': contratId,
        },
      );

      debugPrint('[WORKFLOW] ✅ Véhicule marqué comme assuré');
      return true;

    } catch (e) {
      debugPrint('[WORKFLOW] ❌ Erreur marquage véhicule assuré: $e');
      return false;
    }
  }

  /// ❌ Rejeter un véhicule
  static Future<bool> rejeterVehicule({
    required String vehiculeId,
    required String utilisateurId,
    required String motif,
  }) async {
    try {
      debugPrint('[WORKFLOW] ❌ Rejet véhicule $vehiculeId');

      await _firestore.collection('vehicules').doc(vehiculeId).update({
        'etatCompte': ETAT_REJETE,
        'dateRejet': FieldValue.serverTimestamp(),
        'utilisateurRejetId': utilisateurId,
        'motifRejet': motif,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Créer un historique
      await _creerHistoriqueAction(
        vehiculeId: vehiculeId,
        action: 'rejet',
        utilisateurId: utilisateurId,
        details: {
          'motif': motif,
          'nouvelEtat': ETAT_REJETE,
        },
      );

      debugPrint('[WORKFLOW] ✅ Véhicule rejeté');
      return true;

    } catch (e) {
      debugPrint('[WORKFLOW] ❌ Erreur rejet véhicule: $e');
      return false;
    }
  }

  /// 📜 Récupérer l'historique d'un véhicule
  static Future<List<Map<String, dynamic>>> getHistoriqueVehicule(String vehiculeId) async {
    try {
      final query = await _firestore
          .collection('historique_vehicules')
          .where('vehiculeId', isEqualTo: vehiculeId)
          .orderBy('dateAction', descending: true)
          .get();

      List<Map<String, dynamic>> historique = [];

      for (var doc in query.docs) {
        Map<String, dynamic> actionData = doc.data();
        actionData['id'] = doc.id;

        // Enrichir avec les informations de l'utilisateur
        if (actionData['utilisateurId'] != null) {
          final userDoc = await _firestore
              .collection('users')
              .doc(actionData['utilisateurId'])
              .get();

          if (userDoc.exists) {
            actionData['utilisateurInfo'] = userDoc.data();
          }
        }

        historique.add(actionData);
      }

      return historique;

    } catch (e) {
      debugPrint('[WORKFLOW] ❌ Erreur récupération historique: $e');
      return [];
    }
  }

  /// 📊 Statistiques du workflow pour l'admin agence
  static Future<Map<String, dynamic>> getStatistiquesWorkflow(String agenceId) async {
    try {
      final query = await _firestore
          .collection('vehicules')
          .where('agenceId', isEqualTo: agenceId)
          .get();

      Map<String, int> stats = {
        'total': 0,
        'enAttente': 0,
        'valides': 0,
        'affectes': 0,
        'assures': 0,
        'rejetes': 0,
      };

      for (var doc in query.docs) {
        final data = doc.data();
        final etat = data['etatCompte'] ?? ETAT_EN_ATTENTE;

        stats['total'] = stats['total']! + 1;

        switch (etat) {
          case ETAT_EN_ATTENTE:
            stats['enAttente'] = stats['enAttente']! + 1;
            break;
          case ETAT_VALIDE_ADMIN:
            stats['valides'] = stats['valides']! + 1;
            break;
          case ETAT_AFFECTE_AGENT:
            stats['affectes'] = stats['affectes']! + 1;
            break;
          case ETAT_ASSURE:
            stats['assures'] = stats['assures']! + 1;
            break;
          case ETAT_REJETE:
            stats['rejetes'] = stats['rejetes']! + 1;
            break;
        }
      }

      return stats;

    } catch (e) {
      debugPrint('[WORKFLOW] ❌ Erreur calcul statistiques: $e');
      return {};
    }
  }

  /// 📝 Créer une entrée d'historique
  static Future<void> _creerHistoriqueAction({
    required String vehiculeId,
    required String action,
    required String utilisateurId,
    required Map<String, dynamic> details,
  }) async {
    try {
      await _firestore.collection('historique_vehicules').add({
        'vehiculeId': vehiculeId,
        'action': action,
        'utilisateurId': utilisateurId,
        'details': details,
        'dateAction': FieldValue.serverTimestamp(),
      });

      debugPrint('[WORKFLOW] 📝 Historique créé pour action: $action');

    } catch (e) {
      debugPrint('[WORKFLOW] ❌ Erreur création historique: $e');
    }
  }

  /// 🔍 Rechercher des véhicules avec filtres
  static Future<List<Map<String, dynamic>>> rechercherVehicules({
    required String agenceId,
    String? etat,
    String? agentId,
    String? recherche,
  }) async {
    try {
      Query query = _firestore
          .collection('vehicules')
          .where('agenceId', isEqualTo: agenceId);

      if (etat != null && etat.isNotEmpty) {
        query = query.where('etatCompte', isEqualTo: etat);
      }

      if (agentId != null && agentId.isNotEmpty) {
        query = query.where('agentAffecteId', isEqualTo: agentId);
      }

      final querySnapshot = await query
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> vehicules = [];

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> vehiculeData = doc.data() as Map<String, dynamic>;
        vehiculeData['id'] = doc.id;

        // Filtrer par recherche textuelle si spécifiée
        if (recherche != null && recherche.isNotEmpty) {
          final searchLower = recherche.toLowerCase();
          final marque = (vehiculeData['marque'] ?? '').toString().toLowerCase();
          final modele = (vehiculeData['modele'] ?? '').toString().toLowerCase();
          final immat = (vehiculeData['numeroImmatriculation'] ?? '').toString().toLowerCase();

          if (!marque.contains(searchLower) && 
              !modele.contains(searchLower) && 
              !immat.contains(searchLower)) {
            continue;
          }
        }

        // Enrichir avec les informations du conducteur
        if (vehiculeData['conducteurId'] != null) {
          final conducteurDoc = await _firestore
              .collection('users')
              .doc(vehiculeData['conducteurId'])
              .get();

          if (conducteurDoc.exists) {
            vehiculeData['conducteurInfo'] = conducteurDoc.data();
          }
        }

        vehicules.add(vehiculeData);
      }

      return vehicules;

    } catch (e) {
      debugPrint('[WORKFLOW] ❌ Erreur recherche véhicules: $e');
      return [];
    }
  }
}

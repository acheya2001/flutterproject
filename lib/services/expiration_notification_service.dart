import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// 📅 Service de notification d'expiration des contrats
class ExpirationNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔔 Vérifier et envoyer les notifications d'expiration
  static Future<void> verifierEtNotifierExpirations() async {
    try {
      print('🔍 Vérification des contrats arrivant à expiration...');

      final maintenant = DateTime.now();
      
      // Dates de notification (30, 15, 7, 3, 1 jour avant expiration)
      final dates = [
        maintenant.add(const Duration(days: 30)),
        maintenant.add(const Duration(days: 15)),
        maintenant.add(const Duration(days: 7)),
        maintenant.add(const Duration(days: 3)),
        maintenant.add(const Duration(days: 1)),
      ];

      // Récupérer tous les contrats actifs
      final contratsSnapshot = await _firestore
          .collection('demandes_contrats')
          .where('statut', isEqualTo: 'contrat_actif')
          .where('dateFinContrat', isNotEqualTo: null)
          .get();

      print('📋 ${contratsSnapshot.docs.length} contrats actifs trouvés');

      for (final contratDoc in contratsSnapshot.docs) {
        final contratData = contratDoc.data();
        final dateFinContrat = contratData['dateFinContrat'];
        
        if (dateFinContrat == null) continue;

        DateTime dateFin;
        if (dateFinContrat is Timestamp) {
          dateFin = dateFinContrat.toDate();
        } else if (dateFinContrat is DateTime) {
          dateFin = dateFinContrat;
        } else {
          continue;
        }

        // Vérifier si le contrat expire dans les prochains jours
        await _verifierEtNotifierContrat(contratDoc.id, contratData, dateFin, maintenant);
      }

      print('✅ Vérification des expirations terminée');

    } catch (e) {
      print('❌ Erreur lors de la vérification des expirations: $e');
    }
  }

  /// 📝 Vérifier et notifier un contrat spécifique
  static Future<void> _verifierEtNotifierContrat(
    String contratId,
    Map<String, dynamic> contratData,
    DateTime dateFin,
    DateTime maintenant,
  ) async {
    final conducteurId = contratData['conducteurId'];
    if (conducteurId == null) return;

    final joursRestants = dateFin.difference(maintenant).inDays;
    
    // Définir les seuils de notification
    List<int> seuils = [30, 15, 7, 3, 1];
    
    for (int seuil in seuils) {
      if (joursRestants == seuil) {
        // Vérifier si la notification a déjà été envoyée
        final notificationExiste = await _notificationDejaEnvoyee(
          conducteurId, 
          contratId, 
          'expiration_$seuil'
        );

        if (!notificationExiste) {
          await _envoyerNotificationExpiration(
            conducteurId,
            contratData,
            contratId,
            joursRestants,
            dateFin,
          );
        }
        break;
      }
    }

    // Notification spéciale pour contrat expiré
    if (joursRestants <= 0 && joursRestants >= -7) {
      final notificationExiste = await _notificationDejaEnvoyee(
        conducteurId, 
        contratId, 
        'expire'
      );

      if (!notificationExiste) {
        await _envoyerNotificationExpire(
          conducteurId,
          contratData,
          contratId,
          dateFin,
        );
      }
    }
  }

  /// 📧 Envoyer notification d'expiration imminente
  static Future<void> _envoyerNotificationExpiration(
    String conducteurId,
    Map<String, dynamic> contratData,
    String contratId,
    int joursRestants,
    DateTime dateFin,
  ) async {
    try {
      String titre;
      String message;
      String priorite;

      if (joursRestants >= 15) {
        titre = '📅 Renouvellement de contrat à prévoir';
        message = 'Votre contrat d\'assurance expire dans $joursRestants jours (le ${DateFormat('dd/MM/yyyy').format(dateFin)}). Pensez à le renouveler pour éviter toute interruption de couverture.';
        priorite = 'normale';
      } else if (joursRestants >= 7) {
        titre = '⚠️ Contrat expire bientôt';
        message = 'ATTENTION: Votre contrat d\'assurance expire dans $joursRestants jours (le ${DateFormat('dd/MM/yyyy').format(dateFin)}). Contactez votre agent pour le renouveler rapidement.';
        priorite = 'haute';
      } else {
        titre = '🚨 URGENT: Contrat expire très bientôt';
        message = 'URGENT: Votre contrat d\'assurance expire dans $joursRestants jour(s) seulement (le ${DateFormat('dd/MM/yyyy').format(dateFin)}). Renouvelez-le immédiatement pour éviter une suspension de couverture.';
        priorite = 'critique';
      }

      // Ajouter les informations du véhicule
      final vehiculeInfo = '🚗 ${contratData['marque']} ${contratData['modele']} (${contratData['immatriculation']})';
      final numeroContrat = contratData['numeroContrat'] ?? contratId;

      // Récupérer les informations de l'agent
      final agentId = contratData['agentId'];
      String agentEmail = contratData['agentEmail'] ?? '';
      String agentNom = contratData['agentNom'] ?? '';
      String agentTelephone = '';

      // Si les informations ne sont pas directement dans le contrat, les récupérer depuis users
      if (agentId != null && (agentEmail.isEmpty || agentNom.isEmpty)) {
        try {
          final agentDoc = await _firestore
              .collection('users')
              .doc(agentId)
              .get();

          if (agentDoc.exists) {
            final agentData = agentDoc.data()!;
            if (agentEmail.isEmpty) agentEmail = agentData['email'] ?? '';
            if (agentNom.isEmpty) agentNom = '${agentData['prenom'] ?? ''} ${agentData['nom'] ?? ''}'.trim();
            agentTelephone = agentData['telephone'] ?? '';
          }
        } catch (e) {
          print('❌ Erreur récupération agent: $e');
        }
      }

      await _firestore.collection('notifications').add({
        'conducteurId': conducteurId,
        'type': 'expiration_contrat',
        'sousType': 'expiration_$joursRestants',
        'titre': titre,
        'message': '$message\n\n$vehiculeInfo\n📋 N° Contrat: $numeroContrat',
        'contratId': contratId,
        'numeroContrat': numeroContrat,
        'joursRestants': joursRestants,
        'dateExpiration': DateFormat('dd/MM/yyyy').format(dateFin),
        'vehiculeInfo': vehiculeInfo,
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
        'priorite': priorite,
        'actionRequise': true,
        'actionLabel': 'Contacter l\'agent',
        // Informations de l'agent
        'agentId': agentId,
        'agentEmail': agentEmail,
        'agentNom': agentNom,
        'agentTelephone': agentTelephone,
      });

      print('📧 Notification expiration envoyée: $joursRestants jours restants pour contrat $numeroContrat');

    } catch (e) {
      print('❌ Erreur envoi notification expiration: $e');
    }
  }

  /// 🚨 Envoyer notification de contrat expiré
  static Future<void> _envoyerNotificationExpire(
    String conducteurId,
    Map<String, dynamic> contratData,
    String contratId,
    DateTime dateFin,
  ) async {
    try {
      final vehiculeInfo = '🚗 ${contratData['marque']} ${contratData['modele']} (${contratData['immatriculation']})';
      final numeroContrat = contratData['numeroContrat'] ?? contratId;

      // Récupérer les informations de l'agent
      final agentId = contratData['agentId'];
      String agentEmail = contratData['agentEmail'] ?? '';
      String agentNom = contratData['agentNom'] ?? '';
      String agentTelephone = '';

      // Si les informations ne sont pas directement dans le contrat, les récupérer depuis users
      if (agentId != null && (agentEmail.isEmpty || agentNom.isEmpty)) {
        try {
          final agentDoc = await _firestore
              .collection('users')
              .doc(agentId)
              .get();

          if (agentDoc.exists) {
            final agentData = agentDoc.data()!;
            if (agentEmail.isEmpty) agentEmail = agentData['email'] ?? '';
            if (agentNom.isEmpty) agentNom = '${agentData['prenom'] ?? ''} ${agentData['nom'] ?? ''}'.trim();
            agentTelephone = agentData['telephone'] ?? '';
          }
        } catch (e) {
          print('❌ Erreur récupération agent: $e');
        }
      }

      await _firestore.collection('notifications').add({
        'conducteurId': conducteurId,
        'type': 'contrat_expire',
        'sousType': 'expire',
        'titre': '🚨 CONTRAT EXPIRÉ',
        'message': 'ATTENTION: Votre contrat d\'assurance a expiré le ${DateFormat('dd/MM/yyyy').format(dateFin)}. Votre véhicule n\'est plus couvert. Renouvelez immédiatement votre contrat.\n\n$vehiculeInfo\n📋 N° Contrat: $numeroContrat',
        'contratId': contratId,
        'numeroContrat': numeroContrat,
        'dateExpiration': DateFormat('dd/MM/yyyy').format(dateFin),
        'vehiculeInfo': vehiculeInfo,
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
        'priorite': 'critique',
        'actionRequise': true,
        'actionLabel': 'Contacter l\'agent',
        // Informations de l'agent
        'agentId': agentId,
        'agentEmail': agentEmail,
        'agentNom': agentNom,
        'agentTelephone': agentTelephone,
      });

      // Marquer le contrat comme expiré
      await _firestore
          .collection('demandes_contrats')
          .doc(contratId)
          .update({
        'statut': 'expire',
        'dateExpiration': FieldValue.serverTimestamp(),
      });

      print('🚨 Notification contrat expiré envoyée pour contrat $numeroContrat');

    } catch (e) {
      print('❌ Erreur envoi notification expiration: $e');
    }
  }

  /// 🔍 Vérifier si une notification a déjà été envoyée
  static Future<bool> _notificationDejaEnvoyee(
    String conducteurId,
    String contratId,
    String sousType,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('conducteurId', isEqualTo: conducteurId)
          .where('contratId', isEqualTo: contratId)
          .where('sousType', isEqualTo: sousType)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Erreur vérification notification: $e');
      return false;
    }
  }

  /// 📊 Obtenir les statistiques d'expiration
  static Future<Map<String, int>> obtenirStatistiquesExpiration() async {
    try {
      final maintenant = DateTime.now();
      final dans30Jours = maintenant.add(const Duration(days: 30));

      final contratsSnapshot = await _firestore
          .collection('demandes_contrats')
          .where('statut', isEqualTo: 'contrat_actif')
          .where('dateFinContrat', isNotEqualTo: null)
          .get();

      int expirentDans30Jours = 0;
      int expirentDans15Jours = 0;
      int expirentDans7Jours = 0;
      int expires = 0;

      for (final doc in contratsSnapshot.docs) {
        final data = doc.data();
        final dateFinContrat = data['dateFinContrat'];
        
        if (dateFinContrat == null) continue;

        DateTime dateFin;
        if (dateFinContrat is Timestamp) {
          dateFin = dateFinContrat.toDate();
        } else if (dateFinContrat is DateTime) {
          dateFin = dateFinContrat;
        } else {
          continue;
        }

        final joursRestants = dateFin.difference(maintenant).inDays;

        if (joursRestants <= 0) {
          expires++;
        } else if (joursRestants <= 7) {
          expirentDans7Jours++;
        } else if (joursRestants <= 15) {
          expirentDans15Jours++;
        } else if (joursRestants <= 30) {
          expirentDans30Jours++;
        }
      }

      return {
        'dans30Jours': expirentDans30Jours,
        'dans15Jours': expirentDans15Jours,
        'dans7Jours': expirentDans7Jours,
        'expires': expires,
      };

    } catch (e) {
      print('❌ Erreur statistiques expiration: $e');
      return {};
    }
  }
}

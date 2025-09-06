import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 📊 Service de suivi et gestion des sinistres avec statuts modernes
class SinistreTrackingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🎯 Statuts possibles des sinistres
  static const Map<String, Map<String, dynamic>> STATUTS = {
    'en_attente': {
      'label': 'En attente',
      'description': 'En attente de rejoindre la session',
      'color': 0xFFF59E0B, // Orange
      'icon': 'pending',
      'priority': 1,
    },
    'en_cours': {
      'label': 'En cours',
      'description': 'Remplissage du constat en cours',
      'color': 0xFF3B82F6, // Bleu
      'icon': 'edit',
      'priority': 2,
    },
    'brouillon': {
      'label': 'Brouillon',
      'description': 'Sauvegardé temporairement',
      'color': 0xFF6B7280, // Gris
      'icon': 'draft',
      'priority': 0,
    },
    'termine': {
      'label': 'Terminé',
      'description': 'Constat finalisé et signé',
      'color': 0xFF10B981, // Vert
      'icon': 'check_circle',
      'priority': 4,
    },
    'envoye_agence': {
      'label': 'Envoyé à l\'agence',
      'description': 'Transmis à votre agence d\'assurance',
      'color': 0xFF8B5CF6, // Violet
      'icon': 'send',
      'priority': 5,
    },
    'en_expertise': {
      'label': 'En expertise',
      'description': 'Évaluation par un expert',
      'color': 0xFFEF4444, // Rouge
      'icon': 'assessment',
      'priority': 3,
    },
    'clos': {
      'label': 'Clos',
      'description': 'Dossier fermé et traité',
      'color': 0xFF374151, // Gris foncé
      'icon': 'archive',
      'priority': 6,
    },
  };

  /// 📝 Créer un nouveau sinistre avec suivi
  static Future<String?> createSinistreWithTracking({
    required String conducteurId,
    required String type,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final now = DateTime.now();
      final user = _auth.currentUser;
      
      if (user == null) throw Exception('Utilisateur non connecté');

      // Récupérer les infos du conducteur
      final conducteurDoc = await _firestore
          .collection('users')
          .doc(conducteurId)
          .get();

      final conducteurData = conducteurDoc.data() ?? {};
      final agenceId = conducteurData['agenceId'] ?? '';
      final compagnieId = conducteurData['compagnieId'] ?? '';

      final sinistreData = {
        // Identifiants
        'conducteurId': conducteurId,
        'conducteurDeclarantId': conducteurId,
        'createdBy': conducteurId,
        'agenceId': agenceId,
        'compagnieId': compagnieId,
        
        // Dates
        'dateCreation': Timestamp.fromDate(now),
        'dateOuverture': Timestamp.fromDate(now),
        'lastUpdated': Timestamp.fromDate(now),
        
        // Statut et progression
        'statut': 'en_attente',
        'etapeActuelle': 'choix_type',
        'progression': 0,
        'isActive': true,
        
        // Informations de base
        'type': type,
        'description': description ?? 'Déclaration d\'accident en cours...',
        'lieu': 'À déterminer',
        'nombreVehicules': 1,
        'nombreConducteurs': 1,
        
        // Métadonnées
        'metadata': {
          'version': '2.0',
          'source': 'mobile_app',
          'workflow': 'moderne',
          'device': 'mobile',
          ...?metadata,
        },
        
        // Suivi
        'historique': [
          {
            'action': 'creation',
            'statut': 'en_attente',
            'timestamp': Timestamp.fromDate(now),
            'userId': conducteurId,
            'description': 'Sinistre créé',
          }
        ],
      };

      final docRef = await _firestore
          .collection('sinistres')
          .add(sinistreData);

      print('✅ Sinistre créé avec suivi: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Erreur création sinistre: $e');
      return null;
    }
  }

  /// 🔄 Mettre à jour le statut d'un sinistre
  static Future<bool> updateStatut({
    required String sinistreId,
    required String newStatut,
    String? description,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final now = DateTime.now();
      final user = _auth.currentUser;
      
      if (user == null) throw Exception('Utilisateur non connecté');

      final updateData = {
        'statut': newStatut,
        'lastUpdated': Timestamp.fromDate(now),
        ...?additionalData,
      };

      // Ajouter à l'historique
      await _firestore
          .collection('sinistres')
          .doc(sinistreId)
          .update({
        ...updateData,
        'historique': FieldValue.arrayUnion([
          {
            'action': 'update_statut',
            'statut': newStatut,
            'timestamp': Timestamp.fromDate(now),
            'userId': user.uid,
            'description': description ?? 'Statut mis à jour vers $newStatut',
          }
        ]),
      });

      print('✅ Statut mis à jour: $newStatut');
      return true;
    } catch (e) {
      print('❌ Erreur mise à jour statut: $e');
      return false;
    }
  }

  /// 📊 Mettre à jour la progression
  static Future<bool> updateProgression({
    required String sinistreId,
    required int progression,
    String? etapeActuelle,
  }) async {
    try {
      final updateData = {
        'progression': progression,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      };

      if (etapeActuelle != null) {
        updateData['etapeActuelle'] = etapeActuelle;
      }

      await _firestore
          .collection('sinistres')
          .doc(sinistreId)
          .update(updateData);

      return true;
    } catch (e) {
      print('❌ Erreur mise à jour progression: $e');
      return false;
    }
  }

  /// 📤 Finaliser et envoyer à l'agence
  static Future<bool> finaliserEtEnvoyer({
    required String sinistreId,
    required Map<String, dynamic> constatData,
  }) async {
    try {
      final now = DateTime.now();
      final user = _auth.currentUser;
      
      if (user == null) throw Exception('Utilisateur non connecté');

      // Récupérer les infos du sinistre
      final sinistreDoc = await _firestore
          .collection('sinistres')
          .doc(sinistreId)
          .get();

      if (!sinistreDoc.exists) {
        throw Exception('Sinistre introuvable');
      }

      final sinistreData = sinistreDoc.data()!;
      final agenceId = sinistreData['agenceId'] ?? '';

      // Mettre à jour le sinistre
      await _firestore
          .collection('sinistres')
          .doc(sinistreId)
          .update({
        'statut': 'envoye_agence',
        'progression': 100,
        'etapeActuelle': 'finalise',
        'dateFinalisation': Timestamp.fromDate(now),
        'constatData': constatData,
        'lastUpdated': Timestamp.fromDate(now),
        'historique': FieldValue.arrayUnion([
          {
            'action': 'finalisation',
            'statut': 'envoye_agence',
            'timestamp': Timestamp.fromDate(now),
            'userId': user.uid,
            'description': 'Constat finalisé et envoyé à l\'agence',
          }
        ]),
      });

      // Créer une notification pour l'agence si agenceId existe
      if (agenceId.isNotEmpty) {
        await _createAgenceNotification(agenceId, sinistreId, sinistreData);
      }

      print('✅ Sinistre finalisé et envoyé');
      return true;
    } catch (e) {
      print('❌ Erreur finalisation: $e');
      return false;
    }
  }

  /// 📧 Créer une notification pour l'agence
  static Future<void> _createAgenceNotification(
    String agenceId,
    String sinistreId,
    Map<String, dynamic> sinistreData,
  ) async {
    try {
      await _firestore
          .collection('notifications_agence')
          .add({
        'agenceId': agenceId,
        'type': 'nouveau_sinistre',
        'sinistreId': sinistreId,
        'conducteurId': sinistreData['conducteurId'],
        'titre': 'Nouveau sinistre reçu',
        'message': 'Un nouveau constat d\'accident a été soumis par un de vos assurés',
        'dateCreation': Timestamp.fromDate(DateTime.now()),
        'isRead': false,
        'priority': 'high',
        'metadata': {
          'type': sinistreData['type'],
          'lieu': sinistreData['lieu'],
        },
      });
    } catch (e) {
      print('❌ Erreur création notification agence: $e');
    }
  }

  /// 📊 Obtenir les statistiques des sinistres pour un conducteur
  static Future<Map<String, int>> getStatistiques(String conducteurId) async {
    try {
      final snapshot = await _firestore
          .collection('sinistres')
          .where('conducteurId', isEqualTo: conducteurId)
          .get();

      final stats = <String, int>{};
      
      for (final statut in STATUTS.keys) {
        stats[statut] = 0;
      }

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final statut = data['statut'] ?? 'en_attente';
        stats[statut] = (stats[statut] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('❌ Erreur récupération statistiques: $e');
      return {};
    }
  }

  /// 🎨 Obtenir les informations de style pour un statut
  static Map<String, dynamic> getStatutInfo(String statut) {
    return STATUTS[statut] ?? STATUTS['en_attente']!;
  }

  /// 📱 Stream des sinistres pour un conducteur avec statuts
  static Stream<List<Map<String, dynamic>>> getSinistresStream(String conducteurId) {
    return _firestore
        .collection('sinistres')
        .where('conducteurId', isEqualTo: conducteurId)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'statutInfo': getStatutInfo(data['statut'] ?? 'en_attente'),
          ...data,
        };
      }).toList();
    });
  }
}

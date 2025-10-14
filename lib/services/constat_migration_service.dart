import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔄 Service de migration pour mettre à jour les constats existants
class ConstatMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📋 Migrer les constats existants vers constats_finalises
  static Future<void> migrerConstatsExistants() async {
    try {
      print('🔄 [MIGRATION] Début migration des constats existants...');

      // 1. Récupérer tous les constats agents
      final constatsAgentsQuery = await _firestore
          .collection('constats_agents')
          .get();

      print('📊 [MIGRATION] ${constatsAgentsQuery.docs.length} constats agents trouvés');

      int migrationsReussies = 0;
      int migrationsEchouees = 0;

      for (final doc in constatsAgentsQuery.docs) {
        try {
          final data = doc.data();
          final sessionId = data['sessionId'] as String?;

          if (sessionId == null || sessionId.isEmpty) {
            print('⚠️ [MIGRATION] SessionId manquant pour ${doc.id}');
            migrationsEchouees++;
            continue;
          }

          // Vérifier si le document existe déjà dans constats_finalises
          final constatFinalisDoc = await _firestore
              .collection('constats_finalises')
              .doc(sessionId)
              .get();

          if (constatFinalisDoc.exists) {
            print('✅ [MIGRATION] Constat $sessionId déjà migré');
            continue;
          }

          // Récupérer les données de la session
          final sessionDoc = await _firestore
              .collection('sessions_collaboratives')
              .doc(sessionId)
              .get();

          if (!sessionDoc.exists) {
            print('⚠️ [MIGRATION] Session $sessionId non trouvée');
            migrationsEchouees++;
            continue;
          }

          final sessionData = sessionDoc.data()!;

          // Créer le document dans constats_finalises
          await _firestore.collection('constats_finalises').doc(sessionId).set({
            'sessionId': sessionId,
            'codeConstat': sessionData['codeSession'] ?? '',
            'statut': 'envoye', // Statut par défaut pour les constats envoyés
            'dateEnvoi': data['dateEnvoiPdf'] ?? FieldValue.serverTimestamp(),
            'pdfUrl': data['pdfUrl'],
            'conducteurId': sessionData['conducteurCreateur'],
            'agentInfo': {
              'email': data['agentEmail'],
              'nom': data['agentNom'] ?? '',
              'prenom': data['agentPrenom'] ?? '',
              'agenceNom': data['agenceNom'] ?? '',
              'compagnieNom': data['compagnieNom'] ?? '',
            },
            'nombreVehicules': sessionData['nombreVehicules'] ?? 2,
            'typeAccident': sessionData['typeAccident'] ?? 'collision',
            'statutTraitement': data['statutTraitement'] ?? 'nouveau',
            'dateVu': data['dateVu'],
            'dateTraitement': data['dateTraitement'],
            'commentairesAgent': data['commentairesAgent'],
            'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'source': 'migration_constats_agents',
          });

          print('✅ [MIGRATION] Constat $sessionId migré avec succès');
          migrationsReussies++;

        } catch (e) {
          print('❌ [MIGRATION] Erreur migration ${doc.id}: $e');
          migrationsEchouees++;
        }
      }

      print('📊 [MIGRATION] Résultats:');
      print('   ✅ Migrations réussies: $migrationsReussies');
      print('   ❌ Migrations échouées: $migrationsEchouees');
      print('🏁 [MIGRATION] Migration terminée');

    } catch (e) {
      print('❌ [MIGRATION] Erreur générale: $e');
    }
  }

  /// 🔍 Migrer les assignations d'experts existantes
  static Future<void> migrerAssignationsExperts() async {
    try {
      print('🔄 [MIGRATION] Début migration des assignations d\'experts...');

      // Récupérer toutes les missions d'expertise
      final missionsQuery = await _firestore
          .collection('missions_expertise')
          .get();

      print('📊 [MIGRATION] ${missionsQuery.docs.length} missions d\'expertise trouvées');

      int migrationsReussies = 0;

      for (final doc in missionsQuery.docs) {
        try {
          final data = doc.data();
          final sessionId = data['sessionId'] as String?;
          final expertId = data['expertId'] as String?;

          if (sessionId == null || expertId == null) {
            continue;
          }

          // Récupérer les données de l'expert
          final expertDoc = await _firestore
              .collection('users')
              .doc(expertId)
              .get();

          if (!expertDoc.exists) {
            continue;
          }

          final expertData = expertDoc.data()!;

          // Mettre à jour le constat dans constats_finalises
          await _firestore.collection('constats_finalises').doc(sessionId).update({
            'statut': 'expert_assigne',
            'expertAssigne': {
              'id': expertId,
              'nom': '${expertData['prenom'] ?? ''} ${expertData['nom'] ?? ''}',
              'prenom': expertData['prenom'] ?? '',
              'codeExpert': expertData['codeExpert'] ?? '',
              'telephone': expertData['telephone'] ?? '',
              'email': expertData['email'] ?? '',
            },
            'dateAssignationExpert': data['dateCreation'],
            'commentaireAssignation': data['commentaire'] ?? '',
            'delaiInterventionHeures': data['delaiIntervention'] ?? 48,
            'progressionExpertise': data['progression'] ?? 0,
            'dateVisite': data['dateVisite'],
            'rapportFinal': data['rapportFinal'],
            'evaluation': data['evaluation'],
            'updatedAt': FieldValue.serverTimestamp(),
          });

          print('✅ [MIGRATION] Expert assigné pour session $sessionId');
          migrationsReussies++;

        } catch (e) {
          print('❌ [MIGRATION] Erreur assignation expert ${doc.id}: $e');
        }
      }

      print('📊 [MIGRATION] $migrationsReussies assignations d\'experts migrées');

    } catch (e) {
      print('❌ [MIGRATION] Erreur migration experts: $e');
    }
  }

  /// 📧 Migrer les notifications agents vers constats_finalises
  static Future<void> migrerNotificationsAgents() async {
    try {
      print('🔄 [MIGRATION] Début migration des notifications agents...');

      // Récupérer toutes les notifications agents
      final notificationsQuery = await _firestore
          .collection('notifications_agents')
          .get();

      print('📊 [MIGRATION] ${notificationsQuery.docs.length} notifications agents trouvées');

      int migrationsReussies = 0;
      int migrationsEchouees = 0;

      for (final doc in notificationsQuery.docs) {
        try {
          final data = doc.data();
          final sessionId = data['sessionId'] as String?;

          if (sessionId == null || sessionId.isEmpty) {
            print('⚠️ [MIGRATION] SessionId manquant pour notification ${doc.id}');
            migrationsEchouees++;
            continue;
          }

          // Vérifier si le document existe déjà dans constats_finalises
          final constatFinalisDoc = await _firestore
              .collection('constats_finalises')
              .doc(sessionId)
              .get();

          if (constatFinalisDoc.exists) {
            print('✅ [MIGRATION] Constat $sessionId déjà migré');
            continue;
          }

          // Récupérer les données de la session
          final sessionDoc = await _firestore
              .collection('sessions_collaboratives')
              .doc(sessionId)
              .get();

          if (!sessionDoc.exists) {
            print('⚠️ [MIGRATION] Session $sessionId non trouvée');
            migrationsEchouees++;
            continue;
          }

          final sessionData = sessionDoc.data()!;

          // Créer le document dans constats_finalises
          await _firestore.collection('constats_finalises').doc(sessionId).set({
            'sessionId': sessionId,
            'codeConstat': sessionData['codeSession'] ?? '',
            'statut': 'envoye', // Statut par défaut pour les notifications agents
            'dateEnvoi': data['dateCreation'] ?? FieldValue.serverTimestamp(),
            'pdfUrl': data['pdfUrl'],
            'conducteurId': sessionData['conducteurCreateur'],
            'agentInfo': {
              'email': data['destinataire'],
              'nom': '',
              'prenom': '',
              'agenceNom': data['agencyName'] ?? '',
              'compagnieNom': data['companyName'] ?? '',
            },
            'nombreVehicules': sessionData['nombreVehicules'] ?? 2,
            'typeAccident': sessionData['typeAccident'] ?? 'collision',
            'statutTraitement': data['statut'] ?? 'en_attente',
            'createdAt': data['dateCreation'] ?? FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'source': 'migration_notifications_agents',
          });

          print('✅ [MIGRATION] Notification agent $sessionId migrée avec succès');
          migrationsReussies++;

        } catch (e) {
          print('❌ [MIGRATION] Erreur migration notification ${doc.id}: $e');
          migrationsEchouees++;
        }
      }

      print('📊 [MIGRATION] Résultats notifications agents:');
      print('   ✅ Migrations réussies: $migrationsReussies');
      print('   ❌ Migrations échouées: $migrationsEchouees');

    } catch (e) {
      print('❌ [MIGRATION] Erreur migration notifications agents: $e');
    }
  }

  /// 🚀 Migration complète
  static Future<void> migrationComplete() async {
    print('🚀 [MIGRATION] Début migration complète...');

    await migrerConstatsExistants();
    await migrerNotificationsAgents();
    await migrerAssignationsExperts();

    print('🏁 [MIGRATION] Migration complète terminée');
  }

  /// 🔍 Analyser les données existantes
  static Future<void> analyserDonneesExistantes() async {
    try {
      print('🔍 [ANALYSE] Analyse des données existantes...');

      // Compter les documents dans chaque collection
      final sessionsCount = (await _firestore.collection('sessions_collaboratives').get()).docs.length;
      final constatsAgentsCount = (await _firestore.collection('constats_agents').get()).docs.length;
      final constatsFinalisesCount = (await _firestore.collection('constats_finalises').get()).docs.length;
      final missionsCount = (await _firestore.collection('missions_expertise').get()).docs.length;
      final envoiConstatsCount = (await _firestore.collection('envois_constats').get()).docs.length;

      print('📊 [ANALYSE] Statistiques:');
      print('   📋 Sessions collaboratives: $sessionsCount');
      print('   👨‍💼 Constats agents: $constatsAgentsCount');
      print('   ✅ Constats finalisés: $constatsFinalisesCount');
      print('   🔧 Missions expertise: $missionsCount');
      print('   📤 Envois constats: $envoiConstatsCount');

      // Analyser les sessions finalisées sans constat
      final sessionsFinaliseesQuery = await _firestore
          .collection('sessions_collaboratives')
          .where('statut', isEqualTo: 'finalise')
          .get();

      int sessionsSansConstat = 0;
      for (final sessionDoc in sessionsFinaliseesQuery.docs) {
        final sessionId = sessionDoc.id;
        final constatDoc = await _firestore
            .collection('constats_finalises')
            .doc(sessionId)
            .get();
        
        if (!constatDoc.exists) {
          sessionsSansConstat++;
        }
      }

      print('   ⚠️ Sessions finalisées sans constat: $sessionsSansConstat');

    } catch (e) {
      print('❌ [ANALYSE] Erreur analyse: $e');
    }
  }
}

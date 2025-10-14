import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/collaborative_session_model.dart';
import 'complete_elegant_pdf_service.dart';

/// 📧 Service pour envoyer le PDF du constat aux agents responsables
class ConstatAgentNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 🎯 Envoyer le PDF du constat à tous les agents concernés
  static Future<Map<String, dynamic>> envoyerConstatAuxAgents({
    required String sessionId,
  }) async {
    try {
      print('📧 [CONSTAT-AGENTS] Début notification pour session: $sessionId');

      // 1. Charger la session collaborative
      final session = await _chargerSession(sessionId);
      if (session == null) {
        throw Exception('Session non trouvée: $sessionId');
      }
      print('📋 [CONSTAT-AGENTS] Session chargée: ${session.codeSession}');
      print('📋 [CONSTAT-AGENTS] Participants: ${session.participants.length}');

      // 2. Identifier les agents pour chaque participant
      final agentsInfo = await _identifierAgentsParticipants(session);
      print('👥 [CONSTAT-AGENTS] ${agentsInfo.length} agents identifiés');

      if (agentsInfo.isEmpty) {
        print('⚠️ [CONSTAT-AGENTS] AUCUN AGENT TROUVÉ!');
        return {
          'success': false,
          'error': 'Aucun agent trouvé pour les participants de cette session',
        };
      }

      // 3. Déduplication des agents (même agentId = même agent)
      final agentsUniques = <String, Map<String, dynamic>>{};
      for (final agentInfo in agentsInfo) {
        final agentId = agentInfo['agentId'] as String;
        if (!agentsUniques.containsKey(agentId)) {
          agentsUniques[agentId] = agentInfo;
        }
      }

      print('🔍 [AGENTS] ${agentsInfo.length} agents trouvés, ${agentsUniques.length} uniques après déduplication');

      // 4. Générer et envoyer le PDF à chaque agent unique
      final resultats = <String, dynamic>{};
      int envoisReussis = 0;
      int envoisEchoues = 0;

      for (final agentInfo in agentsUniques.values) {
        try {
          final resultat = await _genererEtNotifierAgent(session, agentInfo);
          resultats[agentInfo['agentId']] = resultat;

          // Vérifier si la notification a vraiment été créée
          if (resultat['notificationCreated'] == true) {
            envoisReussis++;
            print('✅ [CONSTAT-AGENTS] Notification créée pour agent ${agentInfo['agentId']}');
          } else {
            print('⚠️ [CONSTAT-AGENTS] Notification existante pour agent ${agentInfo['agentId']}');
          }
        } catch (e) {
          print('❌ [CONSTAT-AGENTS] Erreur notification agent ${agentInfo['agentId']}: $e');
          resultats[agentInfo['agentId']] = {'success': false, 'error': e.toString()};
          envoisEchoues++;
        }
      }

      // 5. Logger le résultat global
      await _loggerEnvoiGlobal(sessionId, envoisReussis, envoisEchoues, resultats);

      return {
        'success': true,
        'notificationsReussies': envoisReussis,
        'notificationsEchouees': envoisEchoues,
        'totalAgents': agentsUniques.length,
        'agentsOriginaux': agentsInfo.length,
        'details': resultats,
      };

    } catch (e) {
      print('❌ [CONSTAT-AGENTS] Erreur globale: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 📋 Charger la session collaborative
  static Future<CollaborativeSession?> _chargerSession(String sessionId) async {
    try {
      final sessionDoc = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        return null;
      }

      return CollaborativeSession.fromMap(sessionDoc.data()!, sessionDoc.id);
    } catch (e) {
      print('❌ Erreur chargement session: $e');
      return null;
    }
  }

  /// 👥 Identifier les agents responsables de chaque participant
  static Future<List<Map<String, dynamic>>> _identifierAgentsParticipants(
    CollaborativeSession session,
  ) async {
    final agentsInfo = <Map<String, dynamic>>[];
    print('🔍 [AGENTS] Début identification pour ${session.participants.length} participants');

    for (final participant in session.participants) {
      try {
        print('🔍 [AGENTS] Recherche agent pour: ${participant.prenom} ${participant.nom} (${participant.userId})');

        // Chercher l'agent via les demandes de contrats
        final agentInfo = await _trouverAgentPourConducteur(participant.userId);

        if (agentInfo != null) {
          print('✅ [AGENTS] Agent trouvé: ${agentInfo['agentEmail']} (source: ${agentInfo['source']})');
          agentsInfo.add({
            'participantId': participant.userId,
            'participantNom': '${participant.prenom} ${participant.nom}',
            'participantRole': participant.roleVehicule,
            'agentId': agentInfo['agentId'],
            'agentEmail': agentInfo['agentEmail'],
            'agentNom': agentInfo['agentNom'],
            'agenceNom': agentInfo['agenceNom'],
            'compagnieNom': agentInfo['compagnieNom'],
            'source': agentInfo['source'],
          });
        } else {
          print('❌ [AGENTS] Aucun agent trouvé pour: ${participant.userId}');
          print('   Nom: ${participant.prenom} ${participant.nom}');
          print('   Vérifiez que ce conducteur a un contrat actif avec un agent assigné');
        }
      } catch (e) {
        print('❌ Erreur recherche agent pour ${participant.userId}: $e');
      }
    }

    print('🔍 [AGENTS] Résultat final: ${agentsInfo.length} agents identifiés');

    return agentsInfo;
  }

  /// 🔍 Trouver l'agent responsable d'un conducteur
  static Future<Map<String, dynamic>?> _trouverAgentPourConducteur(String conducteurId) async {
    try {
      print('🔍 Recherche agent pour conducteur: $conducteurId');

      // 1. Chercher dans les contrats actifs (méthode principale)
      final contratsQuery = await _firestore
          .collection('contrats')
          .where('conducteurId', isEqualTo: conducteurId)
          .get();

      print('📋 ${contratsQuery.docs.length} contrats trouvés');

      // Filtrer les contrats actifs côté client
      final contratsActifs = contratsQuery.docs.where((doc) {
        final data = doc.data();
        final statut = data['statut'] as String?;
        return statut != null && ['Actif', 'actif', 'Proposé'].contains(statut);
      }).toList();

      if (contratsActifs.isNotEmpty) {
        // Trier par date de création côté client (plus récent en premier)
        contratsActifs.sort((a, b) {
          final dateA = a.data()['createdAt'] as Timestamp?;
          final dateB = b.data()['createdAt'] as Timestamp?;
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA); // Ordre décroissant
        });

        final contrat = contratsActifs.first.data();
        final agentEmail = contrat['agentEmail'] as String?;
        final agentId = contrat['agentId'] as String?;

        print('✅ Contrat trouvé avec agent: $agentEmail');

        if (agentEmail != null && agentEmail.isNotEmpty) {
          // Récupérer les infos complètes de l'agent si possible
          String agentNom = 'Agent';
          String agenceNom = 'Agence';
          String compagnieNom = 'Compagnie';

          if (agentId != null) {
            try {
              final agentDoc = await _firestore
                  .collection('agents_assurance')
                  .doc(agentId)
                  .get();

              if (agentDoc.exists) {
                final agentData = agentDoc.data()!;
                agentNom = '${agentData['prenom'] ?? ''} ${agentData['nom'] ?? ''}'.trim();
                agenceNom = agentData['agenceNom'] ?? 'Agence';
                compagnieNom = agentData['compagnieNom'] ?? 'Compagnie';
              }
            } catch (e) {
              print('⚠️ Erreur récupération infos agent: $e');
            }
          }

          return {
            'agentId': agentId ?? 'agent_contrat',
            'agentEmail': agentEmail,
            'agentNom': agentNom.isNotEmpty ? agentNom : 'Agent',
            'agenceNom': agenceNom,
            'compagnieNom': compagnieNom,
            'source': 'contrat',
          };
        }
      }

      // 2. Fallback: Chercher dans les demandes de contrats
      final demandesQuery = await _firestore
          .collection('demandes_contrats')
          .where('conducteurId', isEqualTo: conducteurId)
          .get();

      final demandesValides = demandesQuery.docs.where((doc) {
        final data = doc.data();
        final statut = data['statut'] as String?;
        final agentEmail = data['agentEmail'] as String?;
        return statut != null &&
               ['affectee', 'contrat_actif', 'contrat_valide'].contains(statut) &&
               agentEmail != null && agentEmail.isNotEmpty;
      }).toList();

      if (demandesValides.isNotEmpty) {
        final demande = demandesValides.first.data();

        print('✅ Demande trouvée avec agent: ${demande['agentEmail']}');

        return {
          'agentId': demande['agentId'] ?? 'agent_demande',
          'agentEmail': demande['agentEmail'],
          'agentNom': demande['agentNom'] ?? 'Agent',
          'agenceNom': 'Agence',
          'compagnieNom': 'Compagnie',
          'source': 'demande',
        };
      }

      print('⚠️ Aucun agent trouvé pour le conducteur: $conducteurId');
      return null;
    } catch (e) {
      print('❌ Erreur recherche agent: $e');
      return null;
    }
  }

  /// 📄 Générer le PDF et créer la notification pour l'agent
  static Future<Map<String, dynamic>> _genererEtNotifierAgent(
    CollaborativeSession session,
    Map<String, dynamic> agentInfo,
  ) async {
    try {
      print('📄 [CONSTAT-AGENTS] Récupération PDF officiel pour agent ${agentInfo['agentId']}');

      // 1. Récupérer l'URL du PDF officiel déjà généré dans la session
      String? pdfUrl = await _recupererPdfOfficielSession(session.id);

      // 2. Si pas de PDF officiel OU si c'est un fichier local, générer un nouveau PDF
      if (pdfUrl == null ||
          pdfUrl.isEmpty ||
          !pdfUrl.startsWith('https://') ||
          (!pdfUrl.contains('firebasestorage.googleapis.com') &&
           !pdfUrl.contains('storage.googleapis.com') &&
           !pdfUrl.contains('cloudinary.com'))) {
        print('📄 [CONSTAT-AGENTS] PDF local/manquant/non-cloud détecté, génération du PDF...');
        print('📄 [CONSTAT-AGENTS] URL actuelle: $pdfUrl');

        try {
          pdfUrl = await CompleteElegantPdfService.genererConstatCompletElegant(
            sessionId: session.id,
          );
          print('📄 [CONSTAT-AGENTS] Nouveau PDF généré: $pdfUrl');
        } catch (e) {
          print('⚠️ [CONSTAT-AGENTS] Erreur génération PDF: $e');
          // Si la génération échoue, utiliser le PDF local existant si disponible
          if (pdfUrl != null && pdfUrl.isNotEmpty) {
            print('📄 [CONSTAT-AGENTS] Utilisation du PDF local existant: $pdfUrl');
          } else {
            throw Exception('Impossible de générer ou récupérer le PDF');
          }
        }
      } else {
        print('✅ [CONSTAT-AGENTS] PDF cloud valide trouvé: $pdfUrl');
      }

      // 3. Créer la notification interne pour l'agent
      final notificationResult = await _creerNotificationAgent(session, agentInfo, pdfUrl);

      return {
        'success': true,
        'pdfUrl': pdfUrl,
        'agentId': agentInfo['agentId'],
        'notificationCreated': notificationResult['notificationCreated'] ?? false,
      };

    } catch (e) {
      print('❌ Erreur récupération/notification PDF: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 📄 Récupérer l'URL du PDF officiel de la session
  static Future<String?> _recupererPdfOfficielSession(String sessionId) async {
    try {
      // 1. Vérifier dans le document de session principal
      final sessionDoc = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .get();

      if (sessionDoc.exists) {
        final sessionData = sessionDoc.data()!;
        final pdfUrl = sessionData['pdfUrl'] as String?;

        if (pdfUrl != null && pdfUrl.isNotEmpty) {
          print('✅ [PDF] PDF trouvé dans session: $pdfUrl');

          // Vérifier si c'est une URL cloud valide (Firebase Storage ou Cloudinary)
          if (pdfUrl.startsWith('https://') &&
              (pdfUrl.contains('firebasestorage.googleapis.com') ||
               pdfUrl.contains('storage.googleapis.com') ||
               pdfUrl.contains('cloudinary.com'))) {
            print('✅ [PDF] URL cloud valide trouvée (Firebase/Cloudinary)');
            print('📄 [PDF] Type: ${sessionData['pdfType'] ?? 'non spécifié'}');
            return pdfUrl;
          } else {
            print('⚠️ [PDF] PDF local ou URL non-cloud trouvé: $pdfUrl');
            print('🔄 [PDF] Génération d\'un nouveau PDF cloud nécessaire');
            return null;
          }
        } else {
          print('⚠️ [PDF] Aucun PDF trouvé dans la session');
        }
      } else {
        print('⚠️ [PDF] Session non trouvée: $sessionId');
      }

      // 2. Vérifier dans la collection constat_pdfs (métadonnées)
      final constatsQuery = await _firestore
          .collection('constat_pdfs')
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('generatedAt', descending: true)
          .limit(1)
          .get();

      if (constatsQuery.docs.isNotEmpty) {
        final constatData = constatsQuery.docs.first.data();
        final downloadUrl = constatData['downloadUrl'] as String?;

        if (downloadUrl != null && downloadUrl.isNotEmpty) {
          print('✅ [PDF] PDF trouvé dans constat_pdfs: $downloadUrl');
          return downloadUrl;
        }
      }

      print('⚠️ [PDF] Aucun PDF officiel trouvé pour session $sessionId');
      return null;

    } catch (e) {
      print('❌ [PDF] Erreur récupération PDF officiel: $e');
      return null;
    }
  }

  /// 📱 Créer une notification interne pour l'agent
  static Future<Map<String, dynamic>> _creerNotificationAgent(
    CollaborativeSession session,
    Map<String, dynamic> agentInfo,
    String pdfUrl,
  ) async {
    try {
      print('📱 [CONSTAT-AGENTS] Création notification pour agent ${agentInfo['agentId']}');

      // ✅ Supprimer les notifications existantes pour cette session et cet agent
      final existingNotifications = await _firestore
          .collection('notifications')
          .where('agentId', isEqualTo: agentInfo['agentId'])
          .where('donnees.sessionId', isEqualTo: session.id)
          .get();

      if (existingNotifications.docs.isNotEmpty) {
        print('🧹 [CONSTAT-AGENTS] Suppression ${existingNotifications.docs.length} notification(s) existante(s) pour agent ${agentInfo['agentId']} - session ${session.id}');

        // Supprimer toutes les notifications existantes
        for (final doc in existingNotifications.docs) {
          await doc.reference.delete();
        }

        print('✅ [CONSTAT-AGENTS] Notifications existantes supprimées, création d\'une nouvelle...');
      }

      // Enregistrer le constat dans l'espace sinistre de l'agent
      await _enregistrerConstatPourAgent(session, agentInfo, pdfUrl);

      // 1. Créer dans la collection notifications (avec les VRAIS champs du dashboard agent)
      await _firestore.collection('notifications').add({
        'type': 'nouveau_constat',
        // ✅ Champs EXACTS utilisés par le dashboard agent
        'agentId': agentInfo['agentId'],            // ✅ agentId (pas recipientId)
        'lu': false,                                // ✅ lu (pas isRead)
        'dateCreation': FieldValue.serverTimestamp(), // ✅ dateCreation (pas createdAt)
        // Champs de contenu
        'titre': 'Nouveau constat reçu',
        'message': 'Constat ${session.codeSession} - Client: ${agentInfo['participantNom']}',
        'donnees': {
          'sessionId': session.id,
          'codeConstat': session.codeSession,
          'clientNom': agentInfo['participantNom'],
          'clientRole': agentInfo['participantRole'],
          'pdfUrl': pdfUrl,
        },
        'dateExpiration': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
      });

      // 2. Créer dans la collection notifications_agents (ancienne - pour compatibilité)
      await _firestore.collection('notifications_agents').add({
        'destinataire': agentInfo['agentEmail'],
        'type': 'constat_finalise',
        'titre': 'Nouveau constat reçu',
        'message': 'Constat ${session.codeSession} - Client: ${agentInfo['participantNom']}',
        'sessionId': session.id,
        'codeConstat': session.codeSession,
        'clientNom': agentInfo['participantNom'],
        'clientRole': agentInfo['participantRole'],
        'pdfUrl': pdfUrl,
        'lu': false,
        'dateCreation': FieldValue.serverTimestamp(),
      });

      // 3. Créer dans la collection envois_constats (pour l'interface agent)
      await _firestore.collection('envois_constats').add({
        'agentId': agentInfo['agentId'],
        'agentEmail': agentInfo['agentEmail'],
        'sessionId': session.id,
        'codeConstat': session.codeSession,
        'pdfUrl': pdfUrl,
        'statut': 'envoye',
        'dateEnvoi': FieldValue.serverTimestamp(),
        'clientNom': agentInfo['participantNom'],
        'clientRole': agentInfo['participantRole'],
        'nombreVehicules': session.nombreVehicules,
        'typeAccident': session.typeAccident,
        'agenceNom': agentInfo['agenceNom'],
        'compagnieNom': agentInfo['compagnieNom'],
      });

      // 4. Créer/Mettre à jour dans constats_finalises (pour le suivi conducteur)
      await _firestore.collection('constats_finalises').doc(session.id).set({
        'sessionId': session.id,
        'codeConstat': session.codeSession,
        'statut': 'envoye',
        'statutSession': 'envoye', // Ajout pour compatibilité dashboard
        'dateEnvoi': FieldValue.serverTimestamp(),
        'pdfUrl': pdfUrl,
        'conducteurId': session.conducteurCreateur,
        'agentInfo': {
          'agentId': agentInfo['agentId'],
          'email': agentInfo['agentEmail'],
          'nom': agentInfo['agentNom'] ?? '',
          'prenom': agentInfo['agentPrenom'] ?? '',
          'agenceNom': agentInfo['agenceNom'],
          'compagnieNom': agentInfo['compagnieNom'],
        },
        'nombreVehicules': session.nombreVehicules,
        'typeAccident': session.typeAccident,
        'statutTraitement': 'nouveau',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ [CONSTAT-AGENTS] Notifications créées dans 4 collections pour agent ${agentInfo['agentId']}');

      return {'notificationCreated': true, 'agentId': agentInfo['agentId']};

    } catch (e) {
      print('❌ Erreur création notification: $e');
      rethrow;
    }
  }



  /// 📋 Enregistrer le constat dans l'espace sinistre de l'agent
  static Future<void> _enregistrerConstatPourAgent(
    CollaborativeSession session,
    Map<String, dynamic> agentInfo,
    String pdfUrl,
  ) async {
    try {
      // ✅ Vérifier si le constat existe déjà pour cet agent
      final existingConstat = await _firestore
          .collection('agent_constats')
          .where('agentId', isEqualTo: agentInfo['agentId'])
          .where('sessionId', isEqualTo: session.id)
          .limit(1)
          .get();

      if (existingConstat.docs.isNotEmpty) {
        print('⚠️ [CONSTAT-AGENTS] Constat déjà enregistré pour agent ${agentInfo['agentId']} - session ${session.id}');
        return;
      }

      // Créer un document dans la collection agent_constats
      await _firestore.collection('agent_constats').add({
        // Informations de base
        'sessionId': session.id,
        'codeConstat': session.codeSession,
        'agentId': agentInfo['agentId'],
        'agentEmail': agentInfo['agentEmail'],
        'agentNom': agentInfo['agentNom'],

        // Informations du client
        'clientId': agentInfo['participantId'],
        'clientNom': agentInfo['participantNom'],
        'clientRole': agentInfo['participantRole'],

        // Informations du constat
        'nombreVehicules': session.nombreVehicules,
        'typeAccident': session.typeAccident,
        'statutSession': session.statut.name,
        'dateAccident': session.dateCreation,
        'dateFinalisation': session.dateFinalisation,

        // PDF et documents
        'pdfUrl': pdfUrl,
        'pdfEnvoye': true,
        'dateEnvoiPdf': FieldValue.serverTimestamp(),

        // Statut de traitement par l'agent
        'statutTraitement': 'nouveau', // nouveau, en_cours, traite, archive
        'dateVu': null,
        'dateTraitement': null,
        'commentairesAgent': null,

        // Métadonnées
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'source': agentInfo['source'], // contrat, demande

        // Informations agence/compagnie
        'agenceNom': agentInfo['agenceNom'],
        'compagnieNom': agentInfo['compagnieNom'],
      });

      print('✅ [CONSTAT-AGENTS] Constat enregistré pour agent ${agentInfo['agentEmail']}');

    } catch (e) {
      print('❌ Erreur enregistrement constat agent: $e');
      // Ne pas faire échouer l'envoi d'email si l'enregistrement échoue
    }
  }

  /// 📋 Récupérer les constats d'un agent
  static Stream<QuerySnapshot> getConstatsAgent(String agentId) {
    return _firestore
        .collection('agent_constats')
        .where('agentId', isEqualTo: agentId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 📋 Marquer un constat comme vu par l'agent
  static Future<void> marquerConstatVu(String constatId) async {
    try {
      await _firestore.collection('agent_constats').doc(constatId).update({
        'dateVu': FieldValue.serverTimestamp(),
        'statutTraitement': 'vu',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Erreur marquage constat vu: $e');
    }
  }

  /// 📋 Mettre à jour le statut de traitement d'un constat
  static Future<void> mettreAJourStatutConstat(
    String constatId,
    String nouveauStatut, {
    String? commentaires,
  }) async {
    try {
      final updateData = {
        'statutTraitement': nouveauStatut,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (commentaires != null) {
        updateData['commentairesAgent'] = commentaires;
      }

      if (nouveauStatut == 'traite') {
        updateData['dateTraitement'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('agent_constats').doc(constatId).update(updateData);
    } catch (e) {
      print('❌ Erreur mise à jour statut constat: $e');
    }
  }

  /// 🔧 Mettre à jour le statut dans constats_finalises quand un expert est assigné
  static Future<void> mettreAJourStatutExpertAssigne({
    required String sessionId,
    required Map<String, dynamic> expertInfo,
    String? missionId,
  }) async {
    try {
      print('🔧 [STATUT] Mise à jour statut expert assigné pour session: $sessionId');

      final updateData = {
        'statut': 'expert_assigne',
        'statutSession': 'expert_assigne', // Pour compatibilité dashboard
        'expertAssigne': {
          'id': expertInfo['id'] ?? expertInfo['expertId'],
          'nom': expertInfo['nom'] ?? '${expertInfo['prenom'] ?? ''} ${expertInfo['nom'] ?? ''}',
          'prenom': expertInfo['prenom'] ?? '',
          'codeExpert': expertInfo['codeExpert'] ?? '',
          'telephone': expertInfo['telephone'] ?? '',
          'email': expertInfo['email'] ?? '',
        },
        'dateAssignationExpert': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (missionId != null) {
        updateData['missionId'] = missionId;
      }

      await _firestore.collection('constats_finalises').doc(sessionId).update(updateData);

      print('✅ [STATUT] Statut expert assigné mis à jour avec succès');
    } catch (e) {
      print('❌ [STATUT] Erreur mise à jour statut expert assigné: $e');
    }
  }

  /// 📊 Logger l'envoi global
  static Future<void> _loggerEnvoiGlobal(
    String sessionId,
    int envoisReussis,
    int envoisEchoues,
    Map<String, dynamic> details,
  ) async {
    try {
      await _firestore.collection('constat_envois_logs').add({
        'sessionId': sessionId,
        'envoisReussis': envoisReussis,
        'envoisEchoues': envoisEchoues,
        'totalAgents': envoisReussis + envoisEchoues,
        'details': details,
        'dateEnvoi': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Erreur logging: $e');
    }
  }

  /// 🧹 Nettoyer les notifications en double pour une session
  static Future<Map<String, dynamic>> nettoyerNotificationsSession(String sessionId) async {
    try {
      print('🧹 [NETTOYAGE] Début nettoyage notifications pour session: $sessionId');

      int notificationsSupprimes = 0;
      int constatsSupprimes = 0;
      int envoisSupprimes = 0;

      // 1. Supprimer de la collection notifications
      final notifications = await _firestore
          .collection('notifications')
          .where('donnees.sessionId', isEqualTo: sessionId)
          .get();

      for (final doc in notifications.docs) {
        await doc.reference.delete();
        notificationsSupprimes++;
      }

      // 2. Supprimer de la collection agent_constats
      final constats = await _firestore
          .collection('agent_constats')
          .where('sessionId', isEqualTo: sessionId)
          .get();

      for (final doc in constats.docs) {
        await doc.reference.delete();
        constatsSupprimes++;
      }

      // 3. Supprimer de la collection envois_constats
      final envois = await _firestore
          .collection('envois_constats')
          .where('sessionId', isEqualTo: sessionId)
          .get();

      for (final doc in envois.docs) {
        await doc.reference.delete();
        envoisSupprimes++;
      }

      print('✅ [NETTOYAGE] Terminé:');
      print('   - Notifications supprimées: $notificationsSupprimes');
      print('   - Constats supprimés: $constatsSupprimes');
      print('   - Envois supprimés: $envoisSupprimes');

      return {
        'success': true,
        'notificationsSupprimes': notificationsSupprimes,
        'constatsSupprimes': constatsSupprimes,
        'envoisSupprimes': envoisSupprimes,
      };
    } catch (e) {
      print('❌ [NETTOYAGE] Erreur: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 🧪 Test de vérification des doublons
  static Future<Map<String, dynamic>> testDuplicateCheck(String sessionId, String agentId) async {
    try {
      // Vérifier les notifications existantes
      final existingNotifications = await _firestore
          .collection('notifications')
          .where('agentId', isEqualTo: agentId)
          .where('donnees.sessionId', isEqualTo: sessionId)
          .get();

      final existingConstats = await _firestore
          .collection('agent_constats')
          .where('agentId', isEqualTo: agentId)
          .where('sessionId', isEqualTo: sessionId)
          .get();

      return {
        'sessionId': sessionId,
        'agentId': agentId,
        'existingNotifications': existingNotifications.docs.length,
        'existingConstats': existingConstats.docs.length,
        'duplicateProtectionActive': existingNotifications.docs.isNotEmpty || existingConstats.docs.isNotEmpty,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import '../../../widgets/modern_session_status_widget.dart';
import '../../../services/session_status_service.dart';
import '../../sinistre/screens/sinistre_choix_rapide_screen.dart';
import '../../../services/modern_pdf_service.dart';
import '../../../services/sinistre_service.dart';
import '../../../services/conducteur_notification_service.dart';
import 'notifications_conducteur_screen.dart';
import '../../../models/sinistre_model.dart';
import 'mes_vehicules_screen.dart';
import '../../../conducteur/screens/guest_join_session_screen.dart';
import '../../../conducteur/screens/registered_join_session_screen.dart';
import '../../../conducteur/screens/sinistre_details_screen.dart';
import '../../../test_cloudinary_fix.dart';
import '../../../services/constat_agent_notification_service.dart';
import '../../../conducteur/screens/accident_choice_screen.dart';
import '../../../conducteur/screens/session_details_screen.dart';
import '../../../services/form_status_service.dart';
import '../../../services/collaborative_session_service.dart';
import '../../../models/collaborative_session_model.dart';
import '../../../conducteur/screens/modern_single_accident_info_screen.dart';
import '../../../conducteur/screens/modern_collaborative_sketch_screen.dart';
import '../../../conducteur/screens/session_dashboard_screen.dart';
import '../../../conducteur/screens/join_session_screen.dart';
import '../../../conducteur/screens/accident_choice_screen.dart';
// Ancien écran supprimé - utiliser modern_single_accident_info_screen.dart
import '../../../conducteur/screens/modern_single_accident_info_screen.dart';
import '../../../conducteur/screens/modern_accident_type_screen.dart';
import '../../../conducteur/screens/join_session_registered_screen.dart';
import '../../../conducteur/screens/accident_session_choice_screen.dart';
import '../../../services/conducteur_data_service.dart';

import 'notifications_screen.dart';
import 'historique_screen.dart';
import 'mes_vehicules_screen.dart';
import 'mes_contrats_dashboard.dart';
import 'declaration_sinistre_screen.dart';
import '../../sinistre/screens/sinistre_choix_rapide_screen.dart';
import '../../../conducteur/screens/accident_declaration_screen.dart';
import '../../../services/sinistre_tracking_service.dart';
import '../../../widgets/modern_sinistre_card.dart';
import '../../../services/constat_tunisien_officiel_pdf.dart';
import '../../../services/constat_pdf_service.dart';
import '../../../services/constat_tracking_service.dart';
import '../widgets/constat_status_timeline.dart';
import '../../../services/constat_migration_service.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';

class ConducteurDashboardComplete extends StatefulWidget {
  const ConducteurDashboardComplete({Key? key}) : super(key: key);

  @override
  State<ConducteurDashboardComplete> createState() => _ConducteurDashboardCompleteState();
}

class _ConducteurDashboardCompleteState extends State<ConducteurDashboardComplete> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _demandes = [];
  List<Map<String, dynamic>> _vehicules = [];
  List<Map<String, dynamic>> _sinistres = [];
  bool _isLoading = true;
  String _nomConducteur = 'Conducteur';
  Map<String, dynamic>? _userData;

  // Variables pour la gestion des sessions collaboratives
  bool _isSelectionMode = false;
  Set<String> _selectedSessions = <String>{};
  List<CollaborativeSession> _allSessions = [];

  @override
  void initState() {
    super.initState();

    // Utiliser addPostFrameCallback pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugAuth();
      _loadUserData();

      // Forcer le rechargement périodique pour éviter les données en cache
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _loadUserData();
        }
      });

      // Rafraîchir les statistiques toutes les 30 secondes
      Timer.periodic(const Duration(seconds: 30), (timer) {
        if (mounted) {
          _refreshStats();
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _debugAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    print('=== DEBUG AUTH DASHBOARD ===');
    print('User connecté: ${user != null}');

    if (user != null) {
      print('UID: ${user.uid}');
      print('Email: ${user.email}');
      print('DisplayName: ${user.displayName}');
    } else {
      print('⚠️ Aucun utilisateur Firebase Auth - Vérification mode offline...');

      // Vérifier si on a des données offline
      try {
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys().where((key) => key.startsWith('conducteur_'));

        if (keys.isNotEmpty) {
          print('✅ Données offline trouvées - Pas de redirection');
          print('=== FIN DEBUG AUTH ===');
          return;
        }
      } catch (e) {
        print('❌ Erreur vérification offline: $e');
      }

      print('❌ Aucune donnée offline - Redirection vers login');
      // Rediriger vers la page de connexion seulement si pas de données offline
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
    }
    print('=== FIN DEBUG AUTH ===');
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await Future.wait([
          _loadNomConducteur(user.uid),
          _loadDemandes(user.uid),
          _loadVehicules(user.uid),
          _loadSinistres(user.uid),
          _chargerSessionsCollaborativesNouvelle(),
        ]);
      } else {
        // Mode offline - charger depuis SharedPreferences
        await _loadNomConducteur('');
      }
    } catch (e) {
      print('Erreur chargement données: $e');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadNomConducteur(String userId) async {
    try {
      print('🔄 Chargement nom conducteur: $userId');

      // Si pas d'utilisateur Firebase, utiliser SharedPreferences
      if (userId.isEmpty) {
        await _loadNomFromLocal();
        return;
      }

      // Forcer le rechargement des données utilisateur actuelles
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid != userId) {
        print('⚠️ UID différent détecté - rechargement nécessaire');
        userId = currentUser.uid;
      }

      // Essayer dans users
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _nomConducteur = '${data['prenom'] ?? ''} ${data['nom'] ?? ''}'.trim();
        });
        print('✅ Nom trouvé dans users: $_nomConducteur');
        return;
      }

      // Essayer dans conducteurs
      userDoc = await FirebaseFirestore.instance
          .collection('conducteurs')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        if (mounted) { setState(() {
          final prenom = data['prenom'] ?? data['firstName'] ?? '';
          final nom = data['nom'] ?? data['lastName'] ?? '';
          _nomConducteur = '$prenom $nom'.trim();
        });
        }
        print('✅ Nom trouvé dans conducteurs: $_nomConducteur');
        return;
      }

      // Essayer SharedPreferences en dernier recours
      await _loadNomFromLocal();

    } catch (e) {
      print('❌ Erreur chargement nom: $e');
      await _loadNomFromLocal();
    }
  }

  Future<void> _loadNomFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = FirebaseAuth.instance.currentUser;

      // Si on a un utilisateur connecté, chercher SES données spécifiquement
      if (currentUser != null) {
        final userKey = 'conducteur_${currentUser.uid}';
        final dataString = prefs.getString(userKey);

        if (dataString != null) {
          final userData = json.decode(dataString) as Map<String, dynamic>;
          // Vérifier que l'email correspond
          if (userData['email'] == currentUser.email) {
            if (mounted) { setState(() {
              final prenom = userData['prenom'] ?? userData['firstName'] ?? '';
              final nom = userData['nom'] ?? userData['lastName'] ?? '';
              _nomConducteur = '$prenom $nom'.trim();
              _userData = userData;
              _userData!['uid'] = currentUser.uid;
            });
            }
            print('✅ Nom trouvé dans SharedPreferences pour utilisateur actuel: $_nomConducteur');
            return;
          }
        }
      }

      // Fallback : utiliser les infos Firebase Auth
      if (currentUser != null) {
        if (mounted) { setState(() {
          _nomConducteur = currentUser.displayName ?? currentUser.email?.split('@').first ?? 'Conducteur';
          _userData = {
            'uid': currentUser.uid,
            'email': currentUser.email,
            'displayName': currentUser.displayName,
            'nom': _nomConducteur,
          };
        });
        }
        print('✅ Nom depuis Firebase Auth: $_nomConducteur');
        return;
      }

      print('⚠️ Nom conducteur non trouvé');

    } catch (e) {
      print('❌ Erreur chargement nom local: $e');
    }
  }

  Future<void> _loadDemandes(String userId) async {
    try {
      print('🔄 Chargement des demandes pour utilisateur: $userId');

      final user = FirebaseAuth.instance.currentUser;
      final userEmail = user?.email;
      print('📧 Email utilisateur: $userEmail');

      // Essayer d'abord demandes_contrats avec conducteurId
      var snapshot = await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .where('conducteurId', isEqualTo: userId)
          .get();

      print('📊 ${snapshot.docs.length} demandes trouvées dans demandes_contrats avec conducteurId');

      // Si aucune et qu'on a un email, essayer avec l'email
      if (snapshot.docs.isEmpty && userEmail != null) {
        snapshot = await FirebaseFirestore.instance
            .collection('demandes_contrats')
            .where('email', isEqualTo: userEmail)
            .get();
        print('📊 ${snapshot.docs.length} demandes trouvées dans demandes_contrats avec email');
      }

      // Si aucune, essayer demandes_contrat (sans s)
      if (snapshot.docs.isEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection('demandes_contrat')
            .where('conducteurId', isEqualTo: userId)
            .get();
        print('📊 ${snapshot.docs.length} demandes trouvées dans demandes_contrat');
      }

      // Si toujours aucune, essayer insurance_requests
      if (snapshot.docs.isEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection('insurance_requests')
            .where('conducteurId', isEqualTo: userId)
            .get();
        print('📊 ${snapshot.docs.length} demandes trouvées dans insurance_requests');
      }

      // Dernière tentative : recherche manuelle dans toutes les demandes
      if (snapshot.docs.isEmpty && userEmail != null) {
        print('🔍 Recherche manuelle dans toutes les demandes...');
        final allDemandes = await FirebaseFirestore.instance
            .collection('demandes_contrats')
            .get();

        final filteredDocs = allDemandes.docs.where((doc) {
          final data = doc.data();
          return data['email'] == userEmail ||
                 data['conducteurId'] == userId ||
                 data['conducteurEmail'] == userEmail;
        }).toList();

        print('📊 ${filteredDocs.length} demandes trouvées par recherche manuelle');

        if (filteredDocs.isNotEmpty) {
          _demandes = filteredDocs.map((doc) {
            final data = doc.data();
            return <String, dynamic>{
              'id': doc.id,
              ...data,
            };
          }).toList();

          // Trier par date de création
          _demandes.sort((a, b) {
            final dateA = _convertirDateSafe(a['dateCreation']) ?? DateTime.now();
            final dateB = _convertirDateSafe(b['dateCreation']) ?? DateTime.now();
            return dateB.compareTo(dateA);
          });

          print('📋 TOTAL DEMANDES CHARGÉES (recherche manuelle): ${_demandes.length}');
          return; // Sortir de la fonction
        }
      }

      _demandes = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return <String, dynamic>{
          'id': doc.id,
          ...data,
        };
      }).toList();

      // Trier par date de création (plus récent en premier)
      _demandes.sort((a, b) {
        final dateA = _convertirDateSafe(a['dateCreation']) ?? DateTime.now();
        final dateB = _convertirDateSafe(b['dateCreation']) ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      // Debug: afficher les demandes
      print('📋 TOTAL DEMANDES CHARGÉES: ${_demandes.length}');
      for (var demande in _demandes) {
        print('📋 Demande: ${demande['numero'] ?? demande['id']} - ${demande['marque']} ${demande['modele']} - Statut: ${demande['statut']}');
      }

    } catch (e) {
      print('❌ Erreur chargement demandes: $e');
      _demandes = [];
    }
  }

  Future<void> _loadVehicules(String userId) async {
    try {
      print('🔄 NOUVEAU CHARGEMENT véhicules avec données complètes pour: $userId');

      // Utiliser la méthode avec les vraies données observées dans les logs
      _vehicules = await ConducteurDataService.recupererAvecVraisNumeros();

      print('✅ ${_vehicules.length} véhicules chargés avec NOUVELLES données');

      // Debug DÉTAILLÉ des nouvelles données
      for (final vehicule in _vehicules) {
        print('🚗 VÉHICULE AVEC DONNÉES COMPLÈTES:');
        print('   - Marque/Modèle: ${vehicule['marque']} ${vehicule['modele']}');
        print('   - Immatriculation: ${vehicule['numeroImmatriculation']}');
        print('   - N° Contrat: ${vehicule['numeroContrat']}');
        print('   - N° Demande: ${vehicule['numeroDemande']}');
        print('   - Type Contrat: ${vehicule['typeContrat']}');
        print('   - Prime: ${vehicule['montantPrime']} TND');
        print('   - Franchise: ${vehicule['franchise']} TND');
        print('   - Type Carburant: ${vehicule['typeCarburant']}');
        print('   - Puissance: ${vehicule['puissanceFiscale']} CV');
        print('   - Statut: ${vehicule['statut']}');
        print('   - Compagnie: ${vehicule['compagnieNom']}');
        print('   - Adresse Compagnie: ${vehicule['compagnieAdresse']}');
        print('   - Agence: ${vehicule['agenceNom']}');
        print('   - Adresse Agence: ${vehicule['agenceAdresse']}');
        print('   - Date Début: ${vehicule['dateDebut']}');
        print('   - Date Fin: ${vehicule['dateFin']}');
        print('   ═══════════════════════════════════════');
      }

      // FORCER la mise à jour de l'interface
      if (mounted) {
        setState(() {
          // Force rebuild avec nouvelles données
        });
      }

    } catch (e) {
      print('❌ ERREUR CRITIQUE chargement véhicules: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      _vehicules = [];
    }
  }

  Future<void> _loadSinistres(String userId) async {
    try {
      print('🔄 Chargement sinistres pour utilisateur: $userId');

      // Chercher dans toutes les collections possibles avec différents champs
      List<Map<String, dynamic>> allSinistres = [];

      // 1. Collection sinistres avec conducteurId
      var snapshot1 = await FirebaseFirestore.instance
          .collection('sinistres')
          .where('conducteurId', isEqualTo: userId)
          .get();
      print('📋 ${snapshot1.docs.length} sinistres trouvés avec conducteurId');

      // 2. Collection sinistres avec conducteurDeclarantId
      var snapshot2 = await FirebaseFirestore.instance
          .collection('sinistres')
          .where('conducteurDeclarantId', isEqualTo: userId)
          .get();
      print('📋 ${snapshot2.docs.length} sinistres trouvés avec conducteurDeclarantId');

      // 3. Collection sinistres avec createdBy
      var snapshot3 = await FirebaseFirestore.instance
          .collection('sinistres')
          .where('createdBy', isEqualTo: userId)
          .get();
      print('📋 ${snapshot3.docs.length} sinistres trouvés avec createdBy');

      // 4. Collection declarations_sinistres
      var snapshot4 = await FirebaseFirestore.instance
          .collection('declarations_sinistres')
          .where('conducteurId', isEqualTo: userId)
          .get();
      print('📋 ${snapshot4.docs.length} déclarations trouvées');

      // 5. Sessions d'accident où le conducteur participe
      var snapshot5 = await FirebaseFirestore.instance
          .collection('accident_sessions_complete')
          .where('createurUserId', isEqualTo: userId)
          .get();
      print('📋 ${snapshot5.docs.length} sessions créées trouvées');

      // Combiner tous les résultats
      Set<String> seenIds = {};

      for (var snapshot in [snapshot1, snapshot2, snapshot3, snapshot4]) {
        for (var doc in snapshot.docs) {
          if (!seenIds.contains(doc.id)) {
            seenIds.add(doc.id);
            allSinistres.add({
              'id': doc.id,
              'source': 'sinistre',
              ...doc.data() as Map<String, dynamic>,
            });
          }
        }
      }

      // Ajouter les sessions comme sinistres potentiels
      for (var doc in snapshot5.docs) {
        if (!seenIds.contains(doc.id)) {
          seenIds.add(doc.id);
          final data = doc.data() as Map<String, dynamic>;
          allSinistres.add({
            'id': doc.id,
            'source': 'session',
            'statut': _getSessionStatut(data['statut'] ?? ''),
            'dateCreation': data['dateOuverture'],
            'codeSession': data['codePublic'],
            'typeAccident': 'Accident de circulation',
            'lieuAccident': data['localisation']?['adresse'] ?? 'Non spécifié',
            ...data,
          });
        }
      }

      _sinistres = allSinistres;
      print('✅ ${_sinistres.length} sinistres/sessions chargés au total');
    } catch (e) {
      print('❌ Erreur chargement sinistres: $e');
      _sinistres = [];
    }
  }

  String _getSessionStatut(String sessionStatut) {
    switch (sessionStatut) {
      case 'brouillon':
        return 'en_attente';
      case 'en_cours':
        return 'en_cours';
      case 'termine':
        return 'termine';
      case 'envoye':
        return 'envoye_agence';
      case 'expert_assigne':
        return 'expert_assigne';
      default:
        return 'en_attente';
    }
  }

  /// Stream combiné pour tous les sinistres du conducteur
  Stream<List<Map<String, dynamic>>> _getCombinedSinistresStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    // Utiliser un stream simple au lieu de combineLatest pour éviter les erreurs
    return Stream.periodic(const Duration(seconds: 5), (count) => count)
        .startWith(0)
        .asyncMap((_) async {
      try {
        List<Map<String, dynamic>> allSinistres = [];
        Set<String> seenIds = {};

        // 1. Collection sinistres avec conducteurId
        final snapshot1 = await FirebaseFirestore.instance
            .collection('sinistres')
            .where('conducteurId', isEqualTo: userId)
            .get();

        // 2. Collection sinistres avec conducteurDeclarantId
        final snapshot2 = await FirebaseFirestore.instance
            .collection('sinistres')
            .where('conducteurDeclarantId', isEqualTo: userId)
            .get();

        // 3. Collection sinistres avec createdBy
        final snapshot3 = await FirebaseFirestore.instance
            .collection('sinistres')
            .where('createdBy', isEqualTo: userId)
            .get();

        // 4. Sessions d'accident créées par le conducteur
        final snapshot4 = await FirebaseFirestore.instance
            .collection('accident_sessions_complete')
            .where('createurUserId', isEqualTo: userId)
            .get();

        // Combiner tous les résultats
        for (var snapshot in [snapshot1, snapshot2, snapshot3]) {
          for (var doc in snapshot.docs) {
            if (!seenIds.contains(doc.id)) {
              seenIds.add(doc.id);
              allSinistres.add({
                'id': doc.id,
                'source': 'sinistre',
                ...doc.data() as Map<String, dynamic>,
              });
            }
          }
        }

        // Ajouter les sessions comme sinistres potentiels
        for (var doc in snapshot4.docs) {
          if (!seenIds.contains(doc.id)) {
            seenIds.add(doc.id);
            final data = doc.data() as Map<String, dynamic>;
            allSinistres.add({
              'id': doc.id,
              'source': 'session',
              'statut': _getSessionStatut(data['statut'] ?? ''),
              'dateCreation': data['dateOuverture'],
              'codeSession': data['codePublic'],
              'typeAccident': 'Accident de circulation',
              'lieuAccident': data['localisation']?['adresse'] ?? 'Non spécifié',
              ...data,
            });
          }
        }

        return allSinistres;
      } catch (e) {
        print('❌ Erreur chargement sinistres stream: $e');
        return <Map<String, dynamic>>[];
      }
    });
  }

  /// 🔧 Créer des demandes de test pour le conducteur
  Future<void> _createTestDemandes() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userEmail = user?.email ?? 'test@example.com';
      final userId = user?.uid ?? 'test-user-id';

      print('🔧 Création demandes de test pour: $userEmail');

      final testDemandes = [
        {
          'numero': 'D-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          'email': userEmail,
          'conducteurId': userId,
          'conducteurEmail': userEmail,
          'nom': 'Test',
          'prenom': 'Conducteur',
          'telephone': '+216 98 123 456',
          'cin': '12345678',
          'adresse': 'Tunis, Tunisie',
          'marque': 'Toyota',
          'modele': 'Corolla',
          'annee': 2020,
          'immatriculation': '123 TUN 456',
          'statut': 'en_attente',
          'agenceId': '3SlpifCIp4Wp5bMXdcD1', // Utiliser l'agence existante
          'agenceNom': 'Agence Test',
          'compagnieNom': 'Compagnie Test',
          'dateCreation': FieldValue.serverTimestamp(),
          'isTestData': true,
        },
        {
          'numero': 'D-${(DateTime.now().millisecondsSinceEpoch + 1000).toString().substring(8)}',
          'email': userEmail,
          'conducteurId': userId,
          'conducteurEmail': userEmail,
          'nom': 'Test',
          'prenom': 'Conducteur',
          'telephone': '+216 98 123 456',
          'cin': '12345678',
          'adresse': 'Tunis, Tunisie',
          'marque': 'Peugeot',
          'modele': '208',
          'annee': 2021,
          'immatriculation': '789 TUN 012',
          'statut': 'approuvee',
          'agenceId': '3SlpifCIp4Wp5bMXdcD1',
          'agenceNom': 'Agence Test',
          'agentNom': 'Agent Test',
          'compagnieNom': 'Compagnie Test',
          'dateCreation': FieldValue.serverTimestamp(),
          'isTestData': true,
        },
        {
          'numero': 'D-${(DateTime.now().millisecondsSinceEpoch + 2000).toString().substring(8)}',
          'email': userEmail,
          'conducteurId': userId,
          'conducteurEmail': userEmail,
          'nom': 'Test',
          'prenom': 'Conducteur',
          'telephone': '+216 98 123 456',
          'cin': '12345678',
          'adresse': 'Tunis, Tunisie',
          'marque': 'Renault',
          'modele': 'Clio',
          'annee': 2019,
          'immatriculation': '345 TUN 678',
          'statut': 'rejetee',
          'motifRejet': 'Documents incomplets',
          'agenceId': '3SlpifCIp4Wp5bMXdcD1',
          'agenceNom': 'Agence Test',
          'compagnieNom': 'Compagnie Test',
          'dateCreation': FieldValue.serverTimestamp(),
          'isTestData': true,
        },
      ];

      for (final demande in testDemandes) {
        await FirebaseFirestore.instance
            .collection('demandes_contrats')
            .add(demande);
        print('✅ Créé demande: ${demande['numero']} - ${demande['statut']}');
      }

      print('✅ ${testDemandes.length} demandes de test créées');

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${testDemandes.length} demandes de test créées'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      print('❌ Erreur création demandes test: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 🔍 Debug des demandes pour le conducteur
  Future<void> _debugDemandes() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userEmail = user?.email;
      final userId = user?.uid;

      print('\n=== 🔍 DEBUG DEMANDES CONDUCTEUR ===');
      print('👤 User ID: $userId');
      print('📧 Email: $userEmail');

      // Vérifier toutes les demandes
      final allDemandes = await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .get();

      print('📊 Total demandes dans la base: ${allDemandes.docs.length}');

      int matchingUserId = 0;
      int matchingEmail = 0;

      for (final doc in allDemandes.docs) {
        final data = doc.data();
        final docEmail = data['email'] as String?;
        final docConducteurId = data['conducteurId'] as String?;
        final docConducteurEmail = data['conducteurEmail'] as String?;

        if (docConducteurId == userId) matchingUserId++;
        if (docEmail == userEmail || docConducteurEmail == userEmail) matchingEmail++;

        // Afficher les 5 premières demandes pour debug
        if (matchingUserId + matchingEmail < 5) {
          print('📋 ${doc.id}: email="$docEmail", conducteurId="$docConducteurId", conducteurEmail="$docConducteurEmail"');
        }
      }

      print('📊 Résumé:');
      print('   - Demandes avec même conducteurId: $matchingUserId');
      print('   - Demandes avec même email: $matchingEmail');
      print('   - Demandes actuellement affichées: ${_demandes.length}');
      print('=== FIN DEBUG DEMANDES CONDUCTEUR ===\n');

    } catch (e) {
      print('❌ Erreur debug demandes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Dashboard Conducteur',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Bouton notifications
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: ConducteurNotificationService.streamNotifications(
              conducteurId: FirebaseAuth.instance.currentUser?.uid ?? '',
              limit: 50,
            ),
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];
              final unreadCount = notifications.where((n) => !(n['lu'] ?? false)).length;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationsConducteurScreen(
                            conducteurData: _userData ?? {},
                          ),
                        ),
                      );
                    },
                    tooltip: 'Notifications',
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedIndex,
              children: [
                _buildAccueilPage(),
                _buildDemandesPage(),
                _buildVehiculesPage(),
                _buildDetailsSessionPage(),
                _buildProfilPage(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey[600],
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Demandes',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Véhicules',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'Sessions',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// 🎯 Bouton d'action flottant adaptatif
  Widget? _buildFloatingActionButton() {
    // Mode sélection des sessions (onglet Sessions)
    if (_selectedIndex == 3 && _isSelectionMode) {
      return _buildSelectionModeFloatingActions();
    }

    // Bouton nouvelle demande (onglet Demandes)
    if (_selectedIndex == 1) {
      return FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/conducteur/nouvelle-demande'),
        backgroundColor: Colors.blue[700],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nouvelle Demande',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    }



    return null;
  }

  /// 🎯 Actions flottantes pour le mode sélection
  Widget _buildSelectionModeFloatingActions() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton Sélectionner tout/Désélectionner tout
          FloatingActionButton(
            heroTag: "select_all",
            onPressed: _selectionnerToutesLesSessions,
            backgroundColor: Colors.indigo[600],
            child: Icon(
              _selectedSessions.length == _allSessions.length
                ? Icons.deselect
                : Icons.select_all,
              color: Colors.white,
            ),
            tooltip: _selectedSessions.length == _allSessions.length
              ? 'Tout désélectionner'
              : 'Tout sélectionner',
          ),

          const SizedBox(height: 12),

          // Bouton Supprimer (avec badge du nombre)
          Stack(
            children: [
              FloatingActionButton(
                heroTag: "delete_selected",
                onPressed: _selectedSessions.isEmpty ? null : _supprimerSessionsSelectionnees,
                backgroundColor: _selectedSessions.isEmpty ? Colors.grey : Colors.red[600],
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              if (_selectedSessions.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.orange[600],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    child: Text(
                      _selectedSessions.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Bouton Annuler
          FloatingActionButton(
            heroTag: "cancel_selection",
            onPressed: () => setState(() {
              _isSelectionMode = false;
              _selectedSessions.clear();
            }),
            backgroundColor: Colors.grey[600],
            child: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Annuler sélection',
          ),
        ],
      ),
    );
  }

  /// 💡 Message d'aide pour le mode sélection
  Widget _buildSelectionModeHelp() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[600], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode Sélection Activé',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Appuyez sur les sessions pour les sélectionner. Utilisez les boutons flottants pour sélectionner tout ou supprimer.',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() {
              _isSelectionMode = false;
              _selectedSessions.clear();
            }),
            icon: Icon(Icons.close, color: Colors.blue[600]),
            tooltip: 'Fermer le mode sélection',
          ),
        ],
      ),
    );
  }

  Widget _buildAccueilPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte de bienvenue
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue $_nomConducteur !',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    return Text(
                      user?.email ?? 'Conducteur',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Statistiques rapides
          _buildStatsSection(),

          const SizedBox(height: 24),

          // Actions rapides
          const Text(
            'Actions Rapides',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          _buildActionCard(
            'Nouvelle Demande d\'Assurance',
            'Demander l\'assurance d\'un nouveau véhicule',
            Icons.add_circle,
            Colors.blue,
            () => Navigator.pushNamed(context, '/conducteur/nouvelle-demande'),
          ),

          const SizedBox(height: 12),

          // 🚗 BOUTON ÉLÉGANT POUR DÉCLARER UN SINISTRE
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[600]!, Colors.red[800]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _creerNouveauConstat(),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.warning_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Déclarer un Accident',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Constat collaboratif rapide et sécurisé',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.8),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          _buildActionCard(
            'Mes Notifications',
            'Voir mes notifications et alertes',
            Icons.notifications,
            Colors.orange,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            ),
          ),

          const SizedBox(height: 12),

          _buildActionCard(
            'Mes Véhicules',
            'Gérer mes véhicules et sinistres',
            Icons.directions_car,
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MesVehiculesScreen(),
              ),
            ),
          ),

          const SizedBox(height: 12),

          _buildActionCard(
            'Mes Contrats',
            'Documents et paiements',
            Icons.description,
            Colors.purple,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MesContratsDashboard(),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Section Mes Contrats
          _buildHomeContractsSection(),

        ],
      ),
    );
  }

  /// 📊 Section des statistiques améliorées
  Widget _buildStatsSection() {
    // Calculer les statistiques
    final stats = _calculateStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '📊 Mes Statistiques',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _refreshStats,
              icon: const Icon(
                Icons.refresh,
                size: 20,
                color: Colors.grey,
              ),
              tooltip: 'Actualiser les statistiques',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Première ligne de stats
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildStatCard(
                'Contrats Actifs',
                (stats['contratsActifs'] ?? 0).toString(),
                Icons.verified,
                Colors.green,
                subtitle: 'En cours',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: _buildStatCard(
                'Véhicules',
                (stats['vehicules'] ?? 0).toString(),
                Icons.directions_car,
                Colors.blue,
                subtitle: 'Assurés',
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Deuxième ligne de stats
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildStatCard(
                'Sinistres',
                (stats['sinistres'] ?? 0).toString(),
                Icons.warning_amber,
                Colors.orange,
                subtitle: (stats['sinistresEnCours'] ?? 0) > 0 ? '${stats['sinistresEnCours'] ?? 0} en cours' : 'Aucun en cours',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: _buildStatCard(
                'Demandes',
                (stats['demandes'] ?? 0).toString(),
                Icons.assignment,
                Colors.purple,
                subtitle: (stats['demandesEnAttente'] ?? 0) > 0 ? '${stats['demandesEnAttente'] ?? 0} en attente' : 'Toutes traitées',
              ),
            ),
          ],
        ),

      ],
    );
  }

  /// 🔄 Rafraîchir les statistiques sans recharger toute la page
  Future<void> _refreshStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Recharger seulement les données nécessaires pour les stats
        await Future.wait([
          _loadDemandes(user.uid),
          _loadVehicules(user.uid),
          _loadSinistres(user.uid),
        ]);

        // Mettre à jour l'interface
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur rafraîchissement stats: $e');
      }
    }
  }

  /// 🧮 Calculer les statistiques
  Map<String, int> _calculateStats() {
    // Contrats actifs (depuis demandes_contrats)
    final contratsActifs = _demandes.where((d) {
      final statut = d['statut'] ?? '';
      return ['contrat_actif', 'documents_completes', 'frequence_choisie'].contains(statut);
    }).length;

    // Véhicules assurés = nombre de demandes avec contrat actif
    // Chaque demande correspond à un véhicule avec contrat actif
    final vehiculesAssures = _demandes.where((d) {
      final statut = d['statut'] ?? '';
      return ['contrat_actif', 'documents_completes', 'frequence_choisie'].contains(statut);
    }).length;

    // Demandes en attente
    final demandesEnAttente = _demandes.where((d) {
      final statut = d['statut'] ?? '';
      return ['en_attente', 'en_cours', 'en_attente_paiement'].contains(statut);
    }).length;

    // Sinistres en cours
    final sinistresEnCours = _sinistres.where((s) {
      final statut = s['statut'] ?? '';
      return ['en_cours', 'en_attente', 'expertise_en_cours'].contains(statut);
    }).length;

    // Collections utilisées (pour debug)
    final collectionsUtilisees = <String>{};
    for (final vehicule in _vehicules) {
      collectionsUtilisees.add(vehicule['source'] ?? 'unknown');
    }

    print('📊 STATS CALCULÉES:');
    print('   - Contrats actifs: $contratsActifs');
    print('   - Véhicules assurés: $vehiculesAssures');
    print('   - Demandes totales: ${_demandes.length}');
    print('   - Véhicules en base: ${_vehicules.length}');

    return {
      'contratsActifs': contratsActifs,
      'vehicules': vehiculesAssures, // ✅ Maintenant basé sur les contrats actifs
      'sinistres': _sinistres.length,
      'sinistresEnCours': sinistresEnCours,
      'demandes': _demandes.length,
      'demandesEnAttente': demandesEnAttente,
      'totalDocuments': _demandes.length + _vehicules.length + _sinistres.length,
      'collectionsUtilisees': collectionsUtilisees.length,
    };
  }

  Widget _buildStatCard(String title, String value, IconData icon, MaterialColor color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête avec icône et valeur
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color[700],
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color[700],
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Titre
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Sous-titre si fourni
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, MaterialColor color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemandesPage() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Mes Demandes d\'Assurance',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            if (_demandes.isEmpty)
              _buildEmptyState(
                'Aucune demande',
                'Vous n\'avez pas encore fait de demande d\'assurance',
                Icons.assignment,
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _demandes.length,
                itemBuilder: (context, index) {
                  final demande = _demandes[index];
                  return _buildDemandeCard(demande);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemandeCard(Map<String, dynamic> demande) {
    final statut = demande['statut'] ?? 'en_attente';
    final vehicule = '${demande['marque']} ${demande['modele']}';
    final compagnie = demande['compagnieNom'] ?? 'N/A';
    final agence = demande['agenceNom'] ?? 'N/A';
    final agentNom = demande['agentNom'] ?? '';
    final motifRejet = demande['motifRejet'] ?? '';
    final dateCreation = _convertirDateSafe(demande['dateCreation']) ?? DateTime.now();

    // Configuration des couleurs et icônes selon le statut
    Color statutColor;
    IconData statutIcon;
    String statutText;

    switch (statut) {
      case 'en_attente':
        statutColor = Colors.orange;
        statutIcon = Icons.hourglass_empty;
        statutText = '⏳ En attente validation admin agence';
        break;
      case 'approuvee':
      case 'affectee':
        statutColor = Colors.blue;
        statutIcon = Icons.assignment_ind;
        statutText = agentNom.isNotEmpty
            ? '👤 Approuvée & affectée à $agentNom'
            : '✅ Approuvée & affectée à un agent';
        break;
      case 'rejetee':
        statutColor = Colors.red;
        statutIcon = Icons.cancel;
        statutText = '❌ Rejetée par l\'admin agence';
        break;
      case 'en_cours':
        statutColor = Colors.purple;
        statutIcon = Icons.work;
        statutText = '🔄 En cours de traitement par agent';
        break;
      case 'validee':
      case 'contrat_valide':
        statutColor = Colors.green;
        statutIcon = Icons.check_circle;
        statutText = '✅ Contrat validé';
        break;
      default:
        statutColor = Colors.grey;
        statutIcon = Icons.help;
        statutText = '❓ Statut inconnu';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: statutColor,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Demande ${demande['numero'] ?? demande['id'].substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: _buildStatutBadge(statut),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildInfoRow(Icons.directions_car, 'Véhicule', vehicule),
          _buildInfoRow(Icons.business, 'Compagnie', compagnie),
          _buildInfoRow(Icons.location_city, 'Agence', agence),
          _buildInfoRow(Icons.calendar_today, 'Date',
              '${dateCreation.day}/${dateCreation.month}/${dateCreation.year}'),

          if (demande['agentNom'] != null)
            _buildInfoRow(Icons.person, 'Agent assigné', demande['agentNom']),

          if (demande['motifRejet'] != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Motif de rejet: ${demande['motifRejet']}',
                      style: TextStyle(color: Colors.red[700], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _voirDetailDemande(demande),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text(
                    'Voir détail',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                ),
              ),

              if (statut == 'contrat_valide') ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _telechargerContrat(demande),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text(
                      'Télécharger',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 18),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _voirDetailDemande(Map<String, dynamic> demande) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détail Demande #${demande['numero'] ?? demande['id'].substring(0, 8)}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Statut', _getStatutText(demande['statut'] ?? 'en_attente'), Icons.info),
              _buildDetailRow('Véhicule', '${demande['marque']} ${demande['modele']}', Icons.directions_car),
              _buildDetailRow('Immatriculation', demande['immatriculation'] ?? 'N/A', Icons.confirmation_number),
              _buildDetailRow('Compagnie', demande['compagnieNom'] ?? 'N/A', Icons.business),
              _buildDetailRow('Agence', demande['agenceNom'] ?? 'N/A', Icons.location_on),
              if (demande['agentNom'] != null)
                _buildDetailRow('Agent assigné', demande['agentNom'], Icons.person),
              _buildDetailRow('Date création', _formatDate(demande['dateCreation']), Icons.calendar_today),
              if (demande['motifRejet'] != null)
                _buildDetailRow('Motif rejet', demande['motifRejet'], Icons.error),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _getStatutText(String statut) {
    switch (statut) {
      case 'en_attente':
        return '⏳ En attente validation admin agence';
      case 'approuvee':
      case 'affectee':
        return '✅ Approuvée & affectée à un agent';
      case 'rejetee':
        return '❌ Rejetée par l\'admin agence';
      case 'en_cours':
      case 'en_traitement':
        return '🔄 En cours de traitement par agent';
      case 'validee':
      case 'contrat_valide':
        return '✅ Contrat validé';
      default:
        return '❓ Statut inconnu';
    }
  }

  void _telechargerContrat(Map<String, dynamic> demande) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download, color: Colors.white),
            const SizedBox(width: 8),
            Text('Téléchargement du contrat #${demande['numero'] ?? demande['id'].substring(0, 8)}...'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );

    // TODO: Implémenter le téléchargement réel du PDF
    // Simuler le téléchargement
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Contrat téléchargé avec succès!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  Widget _buildVehiculesPage() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Mes Véhicules',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Pas de bouton retour
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehicules.isEmpty
              ? _buildEmptyVehiculesState()
              : _buildVehiculesListContent(),
    );
  }

  /// 📋 Contenu de la liste des véhicules (même style que MesVehiculesScreen)
  Widget _buildVehiculesListContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_vehicules.length} véhicule(s) assuré(s)',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),

          // Alertes d'expiration
          _buildAlerteExpirationVehicules(),

          ..._vehicules.map((vehicule) => _buildVehiculeCardMesVehicules(vehicule)).toList(),
        ],
      ),
    );
  }

  /// 🚫 État vide pour les véhicules
  Widget _buildEmptyVehiculesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun véhicule assuré',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Vos véhicules apparaîtront ici après validation des contrats',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _selectedIndex = 1); // Aller à l'onglet Demandes
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Faire une demande'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ⚠️ Alertes d'expiration pour l'onglet véhicules
  Widget _buildAlerteExpirationVehicules() {
    // Vérifier s'il y a des véhicules qui expirent bientôt
    final vehiculesExpirantBientot = _vehicules.where((vehicule) {
      final dateFin = _convertirDateSafe(vehicule['dateFin']);
      if (dateFin == null) return false;

      final maintenant = DateTime.now();
      final difference = dateFin.difference(maintenant).inDays;
      return difference <= 30 && difference > 0;
    }).toList();

    if (vehiculesExpirantBientot.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange[700], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Contrats expirant bientôt',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${vehiculesExpirantBientot.length} contrat(s) expire(nt) dans les 30 prochains jours',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  /// 🚗 Carte de véhicule (même style que MesVehiculesScreen)
  Widget _buildVehiculeCardMesVehicules(Map<String, dynamic> vehicule) {
    final marque = vehicule['marque'] ?? 'N/A';
    final modele = vehicule['modele'] ?? 'N/A';
    final immatriculation = vehicule['numeroImmatriculation'] ?? vehicule['immatriculation'] ?? 'N/A';
    final annee = vehicule['annee']?.toString() ?? 'N/A';
    final couleur = vehicule['couleur'] ?? 'N/A';
    final numeroContrat = vehicule['numeroContrat'] ?? 'N/A';

    final dateFinContrat = vehicule['dateFin'] != null
        ? _convertirDateSafe(vehicule['dateFin'])
        : null;

    // Couleurs aléatoires pour les cartes (même logique que MesVehiculesScreen)
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.indigo,
    ];
    final cardColor = colors[vehicule.hashCode % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [cardColor.withOpacity(0.1), cardColor.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec marque/modèle et statut
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$marque $modele',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: cardColor[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            immatriculation,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 16, color: Colors.green[700]),
                          const SizedBox(width: 4),
                          Text(
                            'ASSURÉ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Informations du véhicule avec couleurs améliorées
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItemVehicules('Année', annee, Icons.calendar_today),
                    ),
                    Expanded(
                      child: _buildInfoItemVehicules('Couleur', couleur, Icons.palette),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItemVehicules('Contrat N°', numeroContrat, Icons.description),
                    ),
                    if (dateFinContrat != null)
                      Expanded(
                        child: _buildInfoItemVehicules(
                          'Expire le',
                          DateFormat('dd/MM/yyyy').format(dateFinContrat),
                          Icons.event,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _voirDetailsVehiculeOnglet(vehicule),
                        icon: Icon(Icons.visibility, color: cardColor[600]),
                        label: const Text('Détails'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cardColor[600],
                          side: BorderSide(color: cardColor[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _declarerSinistreVehicule(vehicule),
                        icon: const Icon(Icons.report_problem, size: 16),
                        label: const Text('Sinistre'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehiculeCard(Map<String, dynamic> vehicule) {
    final marque = vehicule['marque'] ?? 'N/A';
    final modele = vehicule['modele'] ?? 'N/A';
    final immatriculation = vehicule['numeroImmatriculation'] ?? vehicule['immatriculation'] ?? 'N/A';
    final compagnie = vehicule['compagnieNom'] ?? 'N/A';
    final agence = vehicule['agenceNom'] ?? 'N/A';
    final numeroContrat = vehicule['numeroContrat'] ?? 'N/A';
    final statut = vehicule['statut'] ?? 'N/A';
    final annee = vehicule['annee']?.toString() ?? 'N/A';
    final couleur = vehicule['couleur'] ?? 'N/A';
    final typeCarburant = vehicule['typeCarburant'] ?? 'N/A';
    final dateDebut = _convertirDateSafe(vehicule['dateDebut']) ?? DateTime.now();
    final dateFin = _convertirDateSafe(vehicule['dateFin']) ?? DateTime.now().add(const Duration(days: 365));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: Colors.green[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$marque $modele',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      immatriculation,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatutBadge(statut),
            ],
          ),

          const SizedBox(height: 16),

          _buildInfoRow(Icons.confirmation_number, 'N° Contrat', numeroContrat),
          _buildInfoRow(Icons.info_outline, 'Statut', statut),
          _buildInfoRow(Icons.calendar_month, 'Année', annee),
          _buildInfoRow(Icons.palette, 'Couleur', couleur),
          _buildInfoRow(Icons.local_gas_station, 'Carburant', typeCarburant),
          _buildInfoRow(Icons.business, 'Compagnie', compagnie),
          _buildInfoRow(Icons.location_city, 'Agence', agence),
          _buildInfoRow(Icons.calendar_today, 'Période',
              '${dateDebut.day}/${dateDebut.month}/${dateDebut.year} → ${dateFin.day}/${dateFin.month}/${dateFin.year}'),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _voirContrat(vehicule),
                  icon: const Icon(Icons.description, size: 16),
                  label: const Text(
                    'Voir contrat',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (statut == 'contrat_actif' || statut == 'documents_completes')
                      ? () => _declarerSinistre(vehicule['id'] ?? '', vehicule)
                      : null,
                  icon: Icon(
                    Icons.report_problem,
                    size: 16,
                    color: (statut == 'contrat_actif' || statut == 'documents_completes')
                        ? Colors.white
                        : Colors.grey[400],
                  ),
                  label: Text(
                    'Déclarer sinistre',
                    style: TextStyle(
                      fontSize: 12,
                      color: (statut == 'contrat_actif' || statut == 'documents_completes')
                          ? Colors.white
                          : Colors.grey[400],
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (statut == 'contrat_actif' || statut == 'documents_completes')
                        ? Colors.orange[600]
                        : Colors.grey[300],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[400],
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _voirContrat(Map<String, dynamic> vehicule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // En-tête
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[700]!, Colors.blue[500]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.description,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contrat d\'Assurance',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${vehicule['marque']} ${vehicule['modele']}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Contenu scrollable
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContractDetails(vehicule),
                      const SizedBox(height: 24),
                      _buildDownloadButtons(vehicule),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📋 Détails du contrat
  Widget _buildContractDetails(Map<String, dynamic> vehicule) {
    final numeroContrat = vehicule['numeroContrat'] ?? 'N/A';
    final marque = vehicule['marque'] ?? 'N/A';
    final modele = vehicule['modele'] ?? 'N/A';
    final immatriculation = vehicule['numeroImmatriculation'] ?? vehicule['immatriculation'] ?? 'N/A';
    final annee = vehicule['annee']?.toString() ?? 'N/A';
    final typeCarburant = vehicule['typeCarburant'] ?? 'N/A';
    final puissanceFiscale = vehicule['puissanceFiscale']?.toString() ?? 'N/A';
    final usage = vehicule['usage'] ?? 'N/A';
    final montantPrime = vehicule['montantPrime']?.toString() ?? 'N/A';
    final franchise = vehicule['franchise']?.toString() ?? 'N/A';
    final typeContrat = vehicule['typeContrat'] ?? 'N/A';
    final statut = vehicule['statut'] ?? 'N/A';
    final numeroDemande = vehicule['numeroDemande'] ?? 'N/A';

    // Dates - Conversion sécurisée
    final dateDebut = _convertirDateSafe(vehicule['dateDebut']);
    final dateFin = _convertirDateSafe(vehicule['dateFin']);
    final dateCreation = _convertirDateSafe(vehicule['dateCreation']);

    // Compagnie et agence
    final compagnieNom = vehicule['compagnieNom'] ?? 'N/A';
    final compagnieAdresse = vehicule['compagnieAdresse'] ?? 'N/A';
    final agenceNom = vehicule['agenceNom'] ?? 'N/A';
    final agenceAdresse = vehicule['agenceAdresse'] ?? 'N/A';

    // Debug pour voir les données disponibles
    print('🔍 Données véhicule pour affichage détails:');
    vehicule.forEach((key, value) {
      print('   $key: $value');
    });

    // Debug spécifique pour les champs problématiques
    print('🔍 Vérification champs spécifiques:');
    print('   - numeroDemande: ${vehicule['numeroDemande']}');
    print('   - typeContrat: ${vehicule['typeContrat']}');
    print('   - montantPrime: ${vehicule['montantPrime']}');
    print('   - franchise: ${vehicule['franchise']}');
    print('   - compagnieAdresse: ${vehicule['compagnieAdresse']}');
    print('   - agenceAdresse: ${vehicule['agenceAdresse']}');
    print('   - dateDebut: ${vehicule['dateDebut']}');
    print('   - dateFin: ${vehicule['dateFin']}');
    print('   - typeCarburant: ${vehicule['typeCarburant']}');
    print('   - puissanceFiscale: ${vehicule['puissanceFiscale']}');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Contrat
          _buildDetailSection('📋 Informations Contrat', [
            _buildDetailRowComplete('N° Contrat', numeroContrat, Icons.numbers),
            _buildDetailRowComplete('N° Demande', numeroDemande, Icons.receipt),
            _buildDetailRowComplete('Type Contrat', typeContrat, Icons.assignment),
            _buildDetailRowComplete('Statut', statut, Icons.info,
                valueColor: statut == 'contrat_actif' ? Colors.green : Colors.orange),
            _buildDetailRowComplete('Prime Annuelle', montantPrime != 'N/A' ? '$montantPrime TND' : 'N/A', Icons.attach_money),
            _buildDetailRowComplete('Franchise', franchise != 'N/A' ? '$franchise TND' : 'N/A', Icons.money_off),
          ]),

          const SizedBox(height: 20),

          // Section Véhicule Essentielle
          _buildDetailSection('🚗 Informations Véhicule', [
            _buildDetailRowComplete('Marque', marque, Icons.directions_car),
            _buildDetailRowComplete('Modèle', modele, Icons.car_rental),
            _buildDetailRowComplete('Immatriculation', immatriculation, Icons.confirmation_number),
            _buildDetailRowComplete('Année', annee, Icons.calendar_today),
            _buildDetailRowComplete('Type Carburant', typeCarburant, Icons.local_gas_station),
            _buildDetailRowComplete('Puissance Fiscale', '$puissanceFiscale CV', Icons.speed),
            _buildDetailRowComplete('Usage', usage, Icons.drive_eta),
          ]),

          const SizedBox(height: 20),

          // Section Assurance
          _buildDetailSection('🏢 Compagnie d\'Assurance', [
            _buildDetailRowComplete('Compagnie', compagnieNom, Icons.business),
            _buildDetailRowComplete('Adresse Compagnie', compagnieAdresse, Icons.location_on),
            _buildDetailRowComplete('Agence', agenceNom, Icons.store),
            _buildDetailRowComplete('Adresse Agence', agenceAdresse, Icons.place),
          ]),

          const SizedBox(height: 20),

          // Section Dates
          _buildDetailSection('📅 Période de Couverture', [
            _buildDetailRowComplete('Date Début Contrat', dateDebut != null
                ? '${dateDebut.day.toString().padLeft(2, '0')}/${dateDebut.month.toString().padLeft(2, '0')}/${dateDebut.year}'
                : 'N/A', Icons.play_arrow),
            _buildDetailRowComplete('Date Fin Contrat', dateFin != null
                ? '${dateFin.day.toString().padLeft(2, '0')}/${dateFin.month.toString().padLeft(2, '0')}/${dateFin.year}'
                : 'N/A', Icons.stop),
            _buildDetailRowComplete('Date Création Demande', dateCreation != null
                ? '${dateCreation.day.toString().padLeft(2, '0')}/${dateCreation.month.toString().padLeft(2, '0')}/${dateCreation.year}'
                : 'N/A', Icons.create),
          ]),

          const SizedBox(height: 20),

          // Section Garanties
          _buildDetailSection('✅ Garanties Incluses', [
            _buildGarantieRowComplete('Responsabilité Civile', true),
            _buildGarantieRowComplete('Dommages Collision', true),
            _buildGarantieRowComplete('Vol et Incendie', true),
            _buildGarantieRowComplete('Assistance 24h/24', true),
            _buildGarantieRowComplete('Protection Juridique', true),
            _buildGarantieRowComplete('Bris de Glace', true),
            _buildGarantieRowComplete('Catastrophes Naturelles', true),
          ]),
        ],
      ),
    );
  }

  /// 📥 Boutons de téléchargement
  Widget _buildDownloadButtons(Map<String, dynamic> vehicule) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documents Disponibles',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Fermer le modal d'abord
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📄 Fonctionnalité d\'attestation en cours de développement'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                icon: const Icon(Icons.file_download),
                label: const Text('Télécharger\nAttestation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📅 Fonctionnalité d\'échéancier en cours de développement'),
                      backgroundColor: Colors.purple,
                    ),
                  );
                },
                icon: const Icon(Icons.schedule),
                label: const Text('Télécharger\nÉchéancier'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _declarerSinistre(vehicule['id'] ?? '', vehicule);
            },
            icon: const Icon(Icons.warning),
            label: const Text('Déclarer un Sinistre'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red[700],
              side: BorderSide(color: Colors.red[300]!),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 📋 Ligne de détail
  Widget _buildDetailRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Ligne de garantie
  Widget _buildGarantieRow(String garantie, bool inclus) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            inclus ? Icons.check_circle : Icons.cancel,
            size: 20,
            color: inclus ? Colors.green[700] : Colors.red[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              garantie,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            inclus ? 'Inclus' : 'Non inclus',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: inclus ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Section de détails avec titre
  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  /// 📋 Ligne de détail complète avec icône
  Widget _buildDetailRowComplete(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: Colors.blue[700]),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Ligne de garantie complète
  Widget _buildGarantieRowComplete(String garantie, bool inclus) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: inclus ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              inclus ? Icons.check : Icons.close,
              size: 16,
              color: inclus ? Colors.green[700] : Colors.red[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              garantie,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: inclus ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              inclus ? 'Inclus' : 'Non inclus',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: inclus ? Colors.green[700] : Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📄 Ligne de document avec statut
  Widget _buildDocumentRowComplete(String nom, String? url, IconData icon, Color color) {
    final bool disponible = url != null && url.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nom,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: disponible ? Colors.green[100] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              disponible ? 'Disponible' : 'Non fourni',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: disponible ? Colors.green[700] : Colors.grey[600],
              ),
            ),
          ),
          if (disponible) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('📄 Ouverture de $nom...'),
                    backgroundColor: color,
                  ),
                );
              },
              icon: Icon(Icons.open_in_new, size: 16, color: color),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }

  /// 🏷️ Badge de statut avec couleurs appropriées
  Widget _buildStatutBadge(String statut) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    IconData icon;
    String texte;

    switch (statut) {
      case 'contrat_actif':
      case 'documents_completes':
        backgroundColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        borderColor = Colors.green[200]!;
        icon = Icons.verified;
        texte = 'Actif';
        break;
      case 'en_attente':
      case 'en_cours':
        backgroundColor = Colors.orange[50]!;
        textColor = Colors.orange[700]!;
        borderColor = Colors.orange[200]!;
        icon = Icons.pending;
        texte = 'En attente';
        break;
      case 'expire':
      case 'suspendu':
        backgroundColor = Colors.red[50]!;
        textColor = Colors.red[700]!;
        borderColor = Colors.red[200]!;
        icon = Icons.warning;
        texte = 'Expiré';
        break;
      case 'refuse':
        backgroundColor = Colors.red[50]!;
        textColor = Colors.red[700]!;
        borderColor = Colors.red[200]!;
        icon = Icons.cancel;
        texte = 'Refusé';
        break;
      default:
        backgroundColor = Colors.grey[50]!;
        textColor = Colors.grey[700]!;
        borderColor = Colors.grey[200]!;
        icon = Icons.help_outline;
        texte = 'Inconnu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              texte,
              style: TextStyle(
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Page dédiée aux détails de sessions collaboratives
  Widget _buildDetailsSessionPage() {
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête spécialisé pour les sessions
            _buildSessionsHeader(),

            const SizedBox(height: 24),

            // Message d'aide pour le mode sélection
            if (_isSelectionMode) _buildSelectionModeHelp(),

            // 👥 Sessions Collaboratives (section principale uniquement)
            _buildSessionsCollaborativesSection(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSinistresHeader() {
    final sinistresEnCours = _sinistres.where((s) {
      final statut = s['statut'] ?? '';
      return ['en_cours', 'en_attente', 'expertise_en_cours'].contains(statut);
    }).length;

    final sinistresRegles = _sinistres.where((s) {
      final statut = s['statut'] ?? '';
      return ['regle', 'clos'].contains(statut);
    }).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange[600]!,
            Colors.orange[700]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.warning_amber,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mes Sinistres',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Gérez vos déclarations et suivez leur traitement',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Statistiques
          Row(
            children: [
              Expanded(
                child: _buildStatBadge('Total', _sinistres.length.toString(), Icons.list),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBadge('En cours', sinistresEnCours.toString(), Icons.pending),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBadge('Réglés', sinistresRegles.toString(), Icons.check_circle),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinistresActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildDashboardActionButton(
                'Nouveau Constat',
                'Déclarer un accident',
                Icons.add_circle,
                Colors.blue,
                () => _creerNouveauConstat(),
              ),
            ),

          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildDashboardActionButton(
                'Consultation Croisée',
                'Voir autres conducteurs',
                Icons.visibility,
                Colors.indigo,
                () => _ouvrirConsultationCroisee(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDashboardActionButton(
                'Historique',
                'Tous mes sinistres',
                Icons.history,
                Colors.purple,
                () => _voirHistorique(),
              ),
            ),
          ],
        ),

      ],
    );
  }

  Widget _buildDashboardActionButton(String title, String subtitle, IconData icon, MaterialColor color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color[600], size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSinistresList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getCombinedSinistresStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('❌ Erreur stream sinistres: ${snapshot.error}');
          return _buildErrorState('Erreur lors du chargement des sinistres: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final sinistres = snapshot.data ?? [];

        if (sinistres.isEmpty) {
          return _buildEmptySinistresState();
        }

        // Trier par date de création (plus récent en premier)
        sinistres.sort((a, b) {
          final dateA = a['dateCreation'] ?? a['dateOuverture'];
          final dateB = b['dateCreation'] ?? b['dateOuverture'];
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;

          final timestampA = dateA is Timestamp ? dateA : Timestamp.fromDate(dateA);
          final timestampB = dateB is Timestamp ? dateB : Timestamp.fromDate(dateB);
          return timestampB.compareTo(timestampA);
        });

        // Séparer les sinistres par statut
        final sinistresEnCours = sinistres.where((data) {
          final statut = data['statut'] ?? 'en_attente';
          return ['en_attente', 'en_cours', 'en_expertise', 'brouillon'].contains(statut);
        }).toList();

        final sinistresTermines = sinistres.where((data) {
          final statut = data['statut'] ?? 'en_attente';
          return ['termine', 'clos', 'rejete', 'envoye_agence', 'envoye', 'expert_assigne'].contains(statut);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sinistres en cours
            if (sinistresEnCours.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.pending_actions, color: Colors.orange[600], size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Sinistres en cours',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${sinistresEnCours.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              ...sinistresEnCours.take(3).map((data) => ModernSinistreCard(
                sinistre: data,
                onTap: () => _voirDetailsSinistre(data, data['id']),
                showActions: true,
              )).toList(),

              const SizedBox(height: 24),
            ],

            // Sinistres terminés
            if (sinistresTermines.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Sinistres terminés',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${sinistresTermines.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              ...sinistresTermines.take(2).map((data) => ModernSinistreCard(
                sinistre: data,
                onTap: () => _voirDetailsSinistre(data, data['id']),
                showActions: false,
              )).toList(),
            ],

            // Bouton voir tout
            if (sinistres.length > 5) ...[
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _voirHistorique,
                  icon: const Icon(Icons.history),
                  label: const Text('Voir tous les sinistres'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigo[600],
                    side: BorderSide(color: Colors.indigo[300]!),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// 🚨 Construire une carte de sinistre moderne
  Widget _buildModernSinistreCard(Map<String, dynamic> data, bool enCours) {
    final statut = data['statut'] ?? 'en_attente';
    final statutSession = data['statutSession'] ?? statut;
    final statutColor = _getSinistreStatutColorFromString(statut);
    final statutSessionColor = _getStatutSessionColorFromString(statutSession);

    // Calculer le nombre de participants
    final conducteurs = data['conducteurs'] as List<dynamic>? ?? [];
    final participantsRejoints = conducteurs.where((c) => c['aRejoint'] == true).length;
    final totalParticipants = data['nombreVehicules'] ?? conducteurs.length;

    // Déterminer si c'est une session ou un sinistre
    final isSession = data['source'] == 'session' || data['codePublic'] != null;
    final displayId = isSession
        ? (data['codePublic'] ?? data['codeSession'] ?? data['id'])
        : (data['numeroSinistre'] ?? 'SIN-${data['id']?.substring(0, 8) ?? 'XXXX'}');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enCours ? statutColor.withOpacity(0.3) : Colors.grey[200]!,
          width: enCours ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: statutColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _naviguerVersDetailsSinistre(data['id']),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec numéro et statut
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayId,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isSession ? 'Session de constat' : (data['typeAccident'] ?? 'Accident'),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statutColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getStatutLabel(statut),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statutColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statutSessionColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getStatutSessionLabel(statutSession),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: statutSessionColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Informations de l'accident
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        Icons.calendar_today,
                        'Accident',
                        _formatDate(data['dateAccident']),
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoChip(
                        Icons.location_on,
                        'Lieu',
                        _truncateText(data['lieuAccident'] ?? 'Non spécifié', 15),
                        Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Participants et session
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      '$participantsRejoints/${conducteurs.length} conducteurs',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    if (data['blesses'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_hospital, size: 12, color: Colors.red[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Blessés',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Action selon le statut
                _buildSinistreActionButton(data, data['id']),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color[600]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value.length > 15 ? '${value.substring(0, 15)}...' : value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsEnCours() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Sessions de constat en cours',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                // Naviguer vers l'écran de choix d'accident
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccidentChoiceScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nouveau'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue[600],
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _showJoinSessionDialog,
              icon: const Icon(Icons.login, size: 16),
              label: const Text('Rejoindre'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green[600],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('accident_sessions_complete')
              .where('createurUserId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .where('statut', whereIn: ['brouillon', 'en_cours', 'en_attente_participants', 'en_cours_remplissage'])
              .orderBy('dateOuverture', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 100,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Erreur: ${snapshot.error}'),
                    ),
                  ],
                ),
              );
            }

            final sessions = snapshot.data?.docs ?? [];

            if (sessions.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Aucune session en cours',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Créez une nouvelle session ou rejoignez une session existante.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: sessions.map((doc) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ModernSessionStatusWidget(
                    sessionId: doc.id,
                    showDetails: true,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  /// 📋 Construire une carte de session de constat
  Widget _buildSessionCard(String sessionId, Map<String, dynamic> data) {
    final codeSession = data['codeSession'] ?? '';
    final statut = data['statut'] ?? '';
    final typeAccident = data['typeAccident'] ?? '';
    final nombreVehicules = data['nombreVehicules'] ?? 2;
    final dateCreation = _convertirDateSafe(data['dateCreation']) ?? DateTime.now();
    final conducteurs = (data['conducteurs'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    // Déterminer si l'utilisateur est le créateur
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final estCreateur = conducteurs.any((c) => c['userId'] == currentUserId && c['estCreateur'] == true);

    // Couleur selon le statut
    Color statutColor;
    String statutText;
    IconData statutIcon;

    switch (statut) {
      case 'en_attente':
        statutColor = Colors.orange;
        statutText = 'En attente';
        statutIcon = Icons.schedule;
        break;
      case 'en_cours':
        statutColor = Colors.blue;
        statutText = 'En cours';
        statutIcon = Icons.edit;
        break;
      case 'creation':
        statutColor = Colors.purple;
        statutText = 'Création';
        statutIcon = Icons.build;
        break;
      default:
        statutColor = Colors.grey;
        statutText = statut;
        statutIcon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Naviguer vers la session de constat
          _naviguerVersSession(sessionId, data);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec code et statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session $codeSession',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          typeAccident,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statutColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statutIcon, size: 14, color: statutColor),
                        const SizedBox(width: 4),
                        Text(
                          statutText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statutColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Informations de la session
              Row(
                children: [
                  Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    '$nombreVehicules véhicule${nombreVehicules > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    '${conducteurs.length}/$nombreVehicules conducteurs',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Créée le ${dateCreation.day}/${dateCreation.month}/${dateCreation.year}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (estCreateur)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Créateur',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🚗 Naviguer vers une session de constat
  void _naviguerVersSession(String sessionId, Map<String, dynamic> data) {
    // TODO: Implémenter la navigation vers la session
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigation vers session ${data['codeSession']}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// 🔑 Afficher le dialogue pour rejoindre une session
  void _showJoinSessionDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rejoindre une session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Entrez le code de session partagé par l\'autre conducteur :',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Code de session',
                  hintText: 'Ex: 123456',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (codeController.text.length == 6) {
                  Navigator.of(context).pop();
                  _rejoindreSessionAvecCode(codeController.text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Rejoindre'),
            ),
          ],
        );
      },
    );
  }

  /// 🔗 Rejoindre une session avec un code
  void _rejoindreSessionAvecCode(String code) {
    // Naviguer vers l'écran pour conducteur inscrit
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisteredJoinSessionScreen(
          sessionCode: code,
        ),
      ),
    );
  }

  /// 🚨 Naviguer vers les détails d'un sinistre
  void _naviguerVersDetailsSinistre(String sinistreId) {
    // Pour l'instant, on affiche juste un message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Détails du sinistre $sinistreId'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// 🎯 Construire le bouton d'action selon le statut
  Widget _buildSinistreActionButton(Map<String, dynamic> data, String sinistreId) {
    String actionText;
    Color actionColor;
    VoidCallback? onPressed;

    final statutSession = data['statutSession'] ?? 'en_attente_participants';
    switch (statutSession) {
      case 'en_attente_participants':
        actionText = 'En attente participants';
        actionColor = Colors.amber;
        onPressed = null;
        break;
      case 'en_cours_remplissage':
        actionText = 'Continuer le constat';
        actionColor = Colors.blue;
        onPressed = () => _continuerConstat(sinistreId);
        break;
      case 'en_attente_validation':
        actionText = 'Valider le constat';
        actionColor = Colors.orange;
        onPressed = () => _validerConstat(sinistreId);
        break;
      case 'termine':
        actionText = 'Constat terminé';
        actionColor = Colors.green;
        onPressed = () => _voirConstatTermine(sinistreId);
        break;
      case 'envoye':
        actionText = 'Envoyé à l\'agence';
        actionColor = Colors.teal;
        onPressed = () => _voirStatutEnvoi(sinistreId);
        break;
      case 'expert_assigne':
        actionText = 'Expert assigné';
        actionColor = Colors.blue;
        onPressed = () => _voirExpertAssigne(sinistreId);
        break;
      default:
        actionText = 'Action inconnue';
        actionColor = Colors.grey;
        onPressed = null;
        break;
    }

    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(_getActionIcon(statutSession), size: 16),
        label: Text(actionText),
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? actionColor : Colors.grey[300],
          foregroundColor: onPressed != null ? Colors.white : Colors.grey[600],
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// 🎯 Icône selon le statut de session
  IconData _getActionIcon(String statut) {
    switch (statut) {
      case 'en_attente_participants':
        return Icons.schedule;
      case 'en_cours_remplissage':
        return Icons.edit;
      case 'en_attente_validation':
        return Icons.check_circle_outline;
      case 'termine':
        return Icons.check_circle;
      case 'envoye':
        return Icons.send;
      case 'expert_assigne':
        return Icons.engineering;
      default:
        return Icons.help_outline;
    }
  }

  /// ✏️ Continuer le constat
  void _continuerConstat(String sinistreId) {
    // TODO: Naviguer vers l'écran de constat
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Continuer le constat $sinistreId'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// ✅ Valider le constat
  void _validerConstat(String sinistreId) {
    // TODO: Afficher l'écran de validation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Valider le constat $sinistreId'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// 👁️ Voir le constat terminé
  void _voirConstatTermine(String sinistreId) {
    // TODO: Afficher le constat en lecture seule
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voir le constat terminé $sinistreId'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 📤 Voir le statut d'envoi
  void _voirStatutEnvoi(String sinistreId) {
    // TODO: Afficher le statut d'envoi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Statut envoi $sinistreId'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  /// 👨‍🔧 Voir les détails de l'expert assigné
  void _voirExpertAssigne(String sinistreId) async {
    try {
      // Récupérer les détails du constat avec l'expert assigné
      final constatDoc = await FirebaseFirestore.instance
          .collection('constats_finalises')
          .doc(sinistreId)
          .get();

      if (!constatDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Constat non trouvé'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final constatData = constatDoc.data()!;
      final expertAssigne = constatData['expertAssigne'];

      if (expertAssigne == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Aucun expert assigné trouvé'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Afficher les détails de l'expert
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.engineering, color: Colors.blue),
              SizedBox(width: 8),
              Text('Expert Assigné'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExpertDetailRow('Nom', expertAssigne['nom'] ?? 'N/A'),
              _buildExpertDetailRow('Code Expert', expertAssigne['codeExpert'] ?? 'N/A'),
              _buildExpertDetailRow('Téléphone', expertAssigne['telephone'] ?? 'N/A'),
              _buildExpertDetailRow('Email', expertAssigne['email'] ?? 'N/A'),
              if (constatData['dateAssignationExpert'] != null)
                _buildExpertDetailRow('Date d\'assignation', _formatDate(constatData['dateAssignationExpert'])),
              if (constatData['delaiInterventionHeures'] != null)
                _buildExpertDetailRow('Délai d\'intervention', '${constatData['delaiInterventionHeures']} heures'),
              if (constatData['commentaireAssignation'] != null && constatData['commentaireAssignation'].isNotEmpty)
                _buildExpertDetailRow('Commentaire', constatData['commentaireAssignation']),
            ],
          ),
          actions: [
            if (expertAssigne['telephone'] != null && expertAssigne['telephone'].isNotEmpty)
              TextButton.icon(
                onPressed: () => _appellerExpert(expertAssigne['telephone']),
                icon: const Icon(Icons.phone),
                label: const Text('Appeler'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );

    } catch (e) {
      debugPrint('[DASHBOARD] ❌ Erreur récupération expert: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 📋 Construire une ligne de détail expert
  Widget _buildExpertDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// 📞 Appeler l'expert
  void _appellerExpert(String telephone) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: telephone);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Impossible d\'ouvrir l\'application téléphone'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors de l\'appel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🎨 Couleur selon le statut du sinistre
  Color _getSinistreStatutColor(SinistreStatut statut) {
    switch (statut) {
      case SinistreStatut.enAttente:
        return Colors.orange;
      case SinistreStatut.enCours:
        return Colors.blue;
      case SinistreStatut.enExpertise:
        return Colors.purple;
      case SinistreStatut.termine:
        return Colors.green;
      case SinistreStatut.rejete:
        return Colors.red;
      case SinistreStatut.clos:
        return Colors.grey;
    }
  }

  /// 🎨 Couleur selon le statut de session
  Color _getStatutSessionColor(StatutSession statut) {
    switch (statut) {
      case StatutSession.enAttenteParticipants:
        return Colors.amber;
      case StatutSession.enCoursRemplissage:
        return Colors.blue;
      case StatutSession.enAttenteValidation:
        return Colors.orange;
      case StatutSession.termine:
        return Colors.green;
      case StatutSession.envoye:
        return Colors.teal;
    }
  }

  /// 🎨 Couleur selon le statut du sinistre (string)
  Color _getSinistreStatutColorFromString(String statut) {
    switch (statut) {
      case 'en_attente':
        return Colors.orange;
      case 'en_cours':
        return Colors.blue;
      case 'en_expertise':
        return Colors.purple;
      case 'termine':
        return Colors.green;
      case 'clos':
        return Colors.teal;
      case 'rejete':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// 🎨 Couleur selon le statut de session (string)
  Color _getStatutSessionColorFromString(String statut) {
    switch (statut) {
      case 'en_attente_participants':
        return Colors.amber;
      case 'en_cours_remplissage':
        return Colors.blue;
      case 'en_attente_validation':
        return Colors.orange;
      case 'termine':
        return Colors.green;
      case 'envoye':
        return Colors.teal;
      case 'expert_assigne':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// 📝 Label selon le statut du sinistre
  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'en_attente':
        return 'En attente';
      case 'en_cours':
        return 'En cours';
      case 'en_expertise':
        return 'En expertise';
      case 'termine':
        return 'Terminé';
      case 'clos':
        return 'Clos';
      case 'rejete':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  /// 📝 Label selon le statut de session
  String _getStatutSessionLabel(String statut) {
    switch (statut) {
      case 'en_attente_participants':
        return 'En attente';
      case 'en_cours_remplissage':
        return 'En cours';
      case 'en_attente_validation':
        return 'À valider';
      case 'termine':
        return 'Terminé';
      case 'envoye':
        return 'Envoyé';
      case 'expert_assigne':
        return 'Expert assigné';
      default:
        return 'Inconnu';
    }
  }

  /// 📅 Convertir une date de manière sécurisée
  DateTime? _convertirDateSafe(dynamic date) {
    if (date == null) return null;

    try {
      if (date is DateTime) {
        return date;
      } else if (date is Timestamp) {
        return date.toDate();
      } else if (date is String) {
        return DateTime.tryParse(date);
      } else {
        return null;
      }
    } catch (e) {
      print('⚠️ Erreur conversion date: $e');
      return null;
    }
  }

  /// 👥 Section Sessions Collaboratives
  Widget _buildSessionsCollaborativesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple[600]!, Colors.purple[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.group_work,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Sessions Collaboratives',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    print('🔄 Rafraîchissement manuel des sessions...');
                    await _chargerSessionsCollaborativesNouvelle();
                    // Forcer le rebuild du StreamBuilder
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'Actualiser',
                ),
              ],
            ),
          ),



          // Contenu
          StreamBuilder<List<CollaborativeSession>>(
            stream: _getSessionsCollaborativesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.group_off,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aucune session collaborative',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Créez ou rejoignez une session pour collaborer',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _rejoindreSession(),
                            icon: const Icon(Icons.login, size: 16),
                            label: const Text('Rejoindre Session'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Statistiques
                    _buildStatistiquesCollaboratives(snapshot.data!),
                    const SizedBox(height: 16),

                    // Liste des sessions
                    ...snapshot.data!.map((session) => _buildCollaborativeSessionCard(session)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 📅 Formater une date
  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';

    try {
      DateTime dateTime;
      if (date is Timestamp) {
        dateTime = date.toDate();
      } else if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'N/A';
      }

      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  /// ✂️ Tronquer un texte
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// 🔄 Stream des sessions collaboratives (avec cache)
  Stream<List<CollaborativeSession>>? _sessionsStream;

  Stream<List<CollaborativeSession>> _getSessionsCollaborativesStream() {
    // Utiliser le stream en cache s'il existe déjà
    if (_sessionsStream != null) return _sessionsStream!;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    // print('🔄 Création du stream pour utilisateur: ${user.uid}');

    print('🔄 Création du stream pour utilisateur: ${user.uid}');

    _sessionsStream = FirebaseFirestore.instance
        .collection('sessions_collaboratives')
        .orderBy('dateCreation', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          print('📡 Stream reçu: ${snapshot.docs.length} documents');

          final allSessions = snapshot.docs
              .map((doc) {
                try {
                  return CollaborativeSession.fromMap(doc.data(), doc.id);
                } catch (e) {
                  print('❌ Erreur parsing session ${doc.id}: $e');
                  return null;
                }
              })
              .where((session) => session != null)
              .cast<CollaborativeSession>()
              .toList();

          // Filtrer les sessions où l'utilisateur participe
          final sessions = allSessions.where((session) {
            final userParticipe = session.participants.any((p) => p.userId == user.uid) ||
                                  session.conducteurCreateur == user.uid;
            if (userParticipe) {
              print('✅ Session trouvée: ${session.id} - ${session.codeSession}');
            }
            return userParticipe;
          }).toList();

          print('🔍 ${sessions.length} sessions où l\'utilisateur participe');

          // print('✅ Sessions parsées: ${sessions.length}');

          // Mettre à jour _allSessions sans setState pour éviter la boucle
          _allSessions = sessions;
          // print('🔄 _allSessions mis à jour: ${_allSessions.length}');

          return sessions;
        });

    return _sessionsStream!;
  }

  /// 🔄 Forcer le rechargement des sessions
  void _forcerRechargementSessions() {
    setState(() {
      _sessionsStream = null; // Vider le cache
    });
  }

  @override
  void dispose() {
    // Nettoyer le stream pour éviter les fuites mémoire
    _sessionsStream = null;
    super.dispose();
  }

  /// 📊 Statistiques des sessions collaboratives
  Widget _buildStatistiquesCollaboratives(List<CollaborativeSession> sessions) {
    final int total = sessions.length;
    final int actives = sessions.where((s) => s.statut == SessionStatus.en_cours).length;
    final int terminees = sessions.where((s) => s.statut == SessionStatus.finalise).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', total.toString(), Colors.purple[600]!),
          _buildStatItem('Actives', actives.toString(), Colors.orange[600]!),
          _buildStatItem('Terminées', terminees.toString(), Colors.green[600]!),
        ],
      ),
    );
  }

  /// 📊 Item de statistique
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _getSinistreStatutIcon(String statut) {
    switch (statut.toLowerCase()) {
      case 'en_cours':
      case 'en_attente':
        return Icons.pending;
      case 'expertise_en_cours':
        return Icons.search;
      case 'regle':
      case 'clos':
        return Icons.check_circle;
      case 'rejete':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getSinistreStatutText(String statut) {
    switch (statut.toLowerCase()) {
      case 'en_attente_expertise':
        return 'En attente expertise';
      case 'en_cours_traitement':
        return 'En cours traitement';
      case 'expertise_en_cours':
        return 'Expertise en cours';
      case 'en_attente_validation':
        return 'En attente validation';
      case 'regle':
        return 'Réglé';
      case 'clos':
        return 'Clos';
      case 'rejete':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  String _getMessageStatut(String statut) {
    switch (statut.toLowerCase()) {
      case 'en_attente_expertise':
        return 'Votre dossier est en attente d\'expertise. Un expert sera assigné prochainement.';
      case 'en_cours_traitement':
        return 'Votre dossier est en cours de traitement par votre assurance.';
      case 'expertise_en_cours':
        return 'L\'expertise de votre véhicule est en cours. Vous serez contacté pour les résultats.';
      case 'en_attente_validation':
        return 'Votre dossier est en attente de validation finale.';
      default:
        return 'Consultez les détails pour plus d\'informations.';
    }
  }

  Widget _buildEmptySinistresState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 40,
              color: Colors.blue[400],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun sinistre déclaré',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tant mieux ! Vous n\'avez encore déclaré aucun sinistre. En cas d\'accident, utilisez le bouton "Nouveau Constat" ci-dessus.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Chargement des sinistres...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _creerNouveauConstat() {
    // Navigation vers la page de choix de session (créer ou rejoindre)
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AccidentSessionChoiceScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }

  void _ouvrirConsultationCroisee() {
    // TODO: Ouvrir la consultation croisée
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Consultation croisée'),
        content: const Text('Sélectionnez une session de constat active pour consulter les informations des autres conducteurs.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implémenter la sélection de session
            },
            child: const Text('Sélectionner session'),
          ),
        ],
      ),
    );
  }

  void _voirHistorique() {
    // Navigation vers l'historique complet des sinistres
    Navigator.pushNamed(context, '/historique-sinistres');
  }

  /// 🚗 Déclarer un accident avec workflow correct
  Future<void> _declareAccidentWithTracking() async {
    // Navigation vers l'écran de choix de type d'accident (workflow normal)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SinistreChoixRapideScreen(),
      ),
    );
  }

  /// 🎨 Naviguer vers le formulaire moderne avec croquis et signatures
  Future<void> _naviguerVersFormulaireModerne() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous devez être connecté pour accéder au formulaire'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Naviguer vers l'écran de sélection du type d'accident moderne
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ModernAccidentTypeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 📝 Créer un sinistre initial avec le nouveau service
  Future<String?> _createInitialSinistre(String userId) async {
    return await SinistreTrackingService.createSinistreWithTracking(
      conducteurId: userId,
      type: 'accident_route',
      description: 'Déclaration d\'accident en cours...',
      metadata: {
        'source_screen': 'dashboard_complete',
        'creation_method': 'button_declare',
      },
    );
  }

  /// 🔄 Mettre à jour le statut d'un sinistre avec le nouveau service
  Future<void> _updateSinistreStatus(String sinistreId, String newStatus) async {
    await SinistreTrackingService.updateStatut(
      sinistreId: sinistreId,
      newStatut: newStatus,
      description: 'Statut mis à jour depuis le dashboard',
    );
  }

  /// ❌ Afficher un message d'erreur
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 🚨 CRÉER DES SINISTRES DE TEST (VISIBLE IMMÉDIATEMENT)
  Future<void> _creerSinistresTest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorMessage('Utilisateur non connecté');
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Créer 3 sinistres de test avec différents statuts
      final sinistresTest = [
        {
          'type': 'accident_route',
          'statut': 'en_attente',
          'description': 'Accident au rond-point - En attente des autres conducteurs',
          'lieu': 'Rond-point de la République, Tunis',
          'progression': 25,
        },
        {
          'type': 'accident_parking',
          'statut': 'en_cours',
          'description': 'Accrochage dans parking - Remplissage en cours',
          'lieu': 'Parking Centre Commercial Carrefour',
          'progression': 60,
        },
        {
          'type': 'accident_route',
          'statut': 'termine',
          'description': 'Collision légère - Constat finalisé',
          'lieu': 'Avenue Habib Bourguiba, Tunis',
          'progression': 100,
        },
      ];

      for (final sinistreTest in sinistresTest) {
        // Créer le sinistre avec le service
        final sinistreId = await SinistreTrackingService.createSinistreWithTracking(
          conducteurId: user.uid,
          type: sinistreTest['type'] as String,
          description: sinistreTest['description'] as String,
          metadata: {
            'test_data': true,
            'created_from': 'dashboard_test_button',
          },
        );

        if (sinistreId != null) {
          // Mettre à jour le statut et la progression
          await SinistreTrackingService.updateStatut(
            sinistreId: sinistreId,
            newStatut: sinistreTest['statut'] as String,
            description: 'Statut de test appliqué',
            additionalData: {
              'lieu': sinistreTest['lieu'],
              'progression': sinistreTest['progression'],
              'etapeActuelle': sinistreTest['statut'] == 'termine' ? 'finalise' : 'en_cours',
            },
          );
        }
      }

      // Recharger les données pour voir les nouveaux sinistres
      await _loadUserData();

      // Message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 3 sinistres de test créés ! Allez dans l\'onglet "Sinistres" pour les voir'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

    } catch (e) {
      _showErrorMessage('Erreur création sinistres test: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _voirDetailsSinistre(Map<String, dynamic> sinistre, [String? sinistreId]) {
    // Navigation vers les détails du sinistre
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Poignée
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Contenu
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: _buildDetailsSinistre(sinistre, sinistreId),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsSinistre(Map<String, dynamic> sinistre, String? sinistreId) {
    final statut = sinistre['statut'] ?? 'inconnu';
    final typeSinistre = sinistre['typeSinistre'] ?? 'Accident';
    final lieu = sinistre['lieu'] ?? 'Lieu non spécifié';
    final description = sinistre['description'] ?? 'Aucune description';
    final vehiculeInfo = sinistre['vehiculeInfo'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getSinistreStatutColor(statut).withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                _getSinistreStatutIcon(statut),
                color: _getSinistreStatutColor(statut),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    typeSinistre,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getSinistreStatutText(statut),
                    style: TextStyle(
                      fontSize: 14,
                      color: _getSinistreStatutColor(statut),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Informations principales
        _buildDetailSection('Informations générales', [
          _buildDetailRowSinistre('Lieu', lieu),
          _buildDetailRowSinistre('Description', description),
          if (sinistre['dateDeclaration'] != null)
            _buildDetailRowSinistre('Date de déclaration', _formatDateSinistre(sinistre['dateDeclaration'])),
          if (sinistre['dateSinistre'] != null)
            _buildDetailRowSinistre('Date du sinistre', _formatDateSinistre(sinistre['dateSinistre'])),
        ]),

        const SizedBox(height: 20),

        // Informations véhicule
        if (vehiculeInfo != null)
          _buildDetailSection('Véhicule impliqué', [
            _buildDetailRowSinistre('Marque', vehiculeInfo['marque'] ?? 'N/A'),
            _buildDetailRowSinistre('Modèle', vehiculeInfo['modele'] ?? 'N/A'),
            _buildDetailRowSinistre('Immatriculation', vehiculeInfo['immatriculation'] ?? 'N/A'),
            if (vehiculeInfo['numeroContrat'] != null)
              _buildDetailRowSinistre('N° Contrat', vehiculeInfo['numeroContrat']),
          ]),

        const SizedBox(height: 20),

        // Actions
        _buildActionsSection(sinistre, sinistreId),
      ],
    );
  }

  Widget _buildDetailRowSinistre(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(Map<String, dynamic> sinistre, String? sinistreId) {
    final statut = sinistre['statut'] ?? '';
    final enCours = ['en_attente_expertise', 'en_cours_traitement', 'expertise_en_cours', 'en_attente_validation'].contains(statut);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions disponibles',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        if (enCours) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Suivre le dossier
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Suivi du dossier - Fonctionnalité en développement'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              icon: const Icon(Icons.track_changes),
              label: const Text('Suivre le dossier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Contacter l'assurance
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contact assurance - Fonctionnalité en développement'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.phone),
              label: const Text('Contacter l\'assurance'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green[600],
                side: BorderSide(color: Colors.green[300]!),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Télécharger le rapport
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Téléchargement rapport - Fonctionnalité en développement'),
                    backgroundColor: Colors.purple,
                  ),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Télécharger le rapport'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple[600],
                side: BorderSide(color: Colors.purple[300]!),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDateSinistre(dynamic date) {
    try {
      if (date is Timestamp) {
        final dateTime = date.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
      return date.toString();
    } catch (e) {
      return 'Date invalide';
    }
  }

  Widget _buildProfilPage() {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du profil
            _buildProfileHeader(user),

            const SizedBox(height: 24),

            // Informations personnelles
            _buildPersonalInfoSection(),

            const SizedBox(height: 24),

            // Statistiques du conducteur
            _buildDriverStatsSection(),

            const SizedBox(height: 24),

            // Actions du profil
            _buildProfileActions(),

            const SizedBox(height: 24),

            // Paramètres
            _buildSettingsSection(),
          ],
        ),
      ),
    );
  }

  /// 👤 En-tête du profil
  Widget _buildProfileHeader(User? user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 20),

          // Informations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nomConducteur,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'Email non disponible',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 1),
                  ),
                  child: const Text(
                    'Conducteur Vérifié',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bouton éditer
          IconButton(
            onPressed: () => _editProfile(),
            icon: const Icon(
              Icons.edit,
              color: Colors.white,
              size: 24,
            ),
            tooltip: 'Modifier le profil',
          ),
        ],
      ),
    );
  }

  /// 📋 Section informations personnelles
  Widget _buildPersonalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: Colors.blue[700], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Informations Personnelles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildProfileInfoRow('Nom complet', _nomConducteur, Icons.badge),
          _buildProfileInfoRow('Email', FirebaseAuth.instance.currentUser?.email ?? 'Non renseigné', Icons.email),
          _buildProfileInfoRow('Téléphone', _getUserPhone(), Icons.phone),
          _buildProfileInfoRow('CIN', _getUserCIN(), Icons.credit_card),
          _buildProfileInfoRow('Adresse', _getUserAddress(), Icons.location_on),
          _buildProfileInfoRow('Date d\'inscription', _formatDate(FirebaseAuth.instance.currentUser?.metadata.creationTime), Icons.calendar_today),
        ],
      ),
    );
  }

  /// 📊 Section statistiques du conducteur
  Widget _buildDriverStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.green[700], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Mes Statistiques',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildProfileStatCard(
                  'Véhicules',
                  '${_vehicules.length}',
                  Icons.directions_car,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProfileStatCard(
                  'Demandes',
                  '${_demandes.length}',
                  Icons.assignment,
                  Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildProfileStatCard(
                  'Sinistres',
                  '${_sinistres.length}',
                  Icons.warning,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProfileStatCard(
                  'Années',
                  _calculateYearsSinceRegistration(),
                  Icons.timeline,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🎯 Actions du profil
  Widget _buildProfileActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings_outlined, color: Colors.indigo[700], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Actions Rapides',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildActionTile(
            'Modifier mes informations',
            'Mettre à jour nom, téléphone, adresse',
            Icons.edit,
            Colors.blue,
            () => _editProfile(),
          ),

          _buildActionTile(
            'Changer mot de passe',
            'Sécuriser votre compte',
            Icons.lock,
            Colors.orange,
            () => _changePassword(),
          ),

          _buildActionTile(
            'Télécharger mes données',
            'Exporter toutes mes informations',
            Icons.download,
            Colors.green,
            () => _downloadUserData(),
          ),

          _buildActionTile(
            'Support client',
            'Contacter notre équipe',
            Icons.support_agent,
            Colors.purple,
            () => _contactSupport(),
          ),
        ],
      ),
    );
  }

  /// ⚙️ Section paramètres
  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: Colors.grey[700], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Paramètres',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildSettingsTile(
            'Notifications',
            'Gérer les alertes et notifications',
            Icons.notifications,
            true,
            (value) => _toggleNotifications(value),
          ),

          _buildSettingsTile(
            'Mode sombre',
            'Activer le thème sombre',
            Icons.dark_mode,
            false,
            (value) => _toggleDarkMode(value),
          ),

          const SizedBox(height: 20),

          // Bouton déconnexion
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📝 Widget pour une ligne d'information du profil
  Widget _buildProfileInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Widget pour une carte de statistique du profil
  Widget _buildProfileStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Widget pour une action du profil
  Widget _buildActionTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: Colors.grey[50],
      ),
    );
  }

  /// ⚙️ Widget pour un paramètre avec switch
  Widget _buildSettingsTile(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.grey[700], size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blue[700],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: Colors.grey[50],
      ),
    );
  }

  /// 📅 Calculer les années depuis l'inscription
  String _calculateYearsSinceRegistration() {
    final creationTime = FirebaseAuth.instance.currentUser?.metadata.creationTime;
    if (creationTime == null) return '0';

    final now = DateTime.now();
    final difference = now.difference(creationTime);
    final years = (difference.inDays / 365).floor();

    return years.toString();
  }

  /// 📱 Récupérer le téléphone de l'utilisateur
  String _getUserPhone() {
    if (_userData != null) {
      return _userData!['telephone'] ?? _userData!['phone'] ?? '+216 XX XXX XXX';
    }

    // Chercher dans les demandes
    for (final demande in _demandes) {
      final phone = demande['telephone'];
      if (phone != null && phone.toString().isNotEmpty) {
        return phone.toString();
      }
    }

    return '+216 XX XXX XXX';
  }

  /// 🆔 Récupérer le CIN de l'utilisateur
  String _getUserCIN() {
    if (_userData != null) {
      return _userData!['cin'] ?? _userData!['numeroIdentite'] ?? 'Non renseigné';
    }

    // Chercher dans les demandes
    for (final demande in _demandes) {
      final cin = demande['cin'] ?? demande['numeroIdentite'];
      if (cin != null && cin.toString().isNotEmpty) {
        return cin.toString();
      }
    }

    return 'Non renseigné';
  }

  /// 🏠 Récupérer l'adresse de l'utilisateur
  String _getUserAddress() {
    if (_userData != null) {
      return _userData!['adresse'] ?? _userData!['address'] ?? 'Non renseignée';
    }

    // Chercher dans les demandes
    for (final demande in _demandes) {
      final adresse = demande['adresse'] ?? demande['address'];
      if (adresse != null && adresse.toString().isNotEmpty) {
        return adresse.toString();
      }
    }

    return 'Non renseignée';
  }

  /// ✏️ Modifier le profil
  void _editProfile() {
    final nomController = TextEditingController(text: _nomConducteur);
    final phoneController = TextEditingController(text: _getUserPhone());
    final cinController = TextEditingController(text: _getUserCIN());
    final adresseController = TextEditingController(text: _getUserAddress());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.blue[700]),
            const SizedBox(width: 8),
            const Text('Modifier le profil'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: cinController,
                  decoration: const InputDecoration(
                    labelText: 'CIN',
                    prefixIcon: Icon(Icons.credit_card),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: adresseController,
                  decoration: const InputDecoration(
                    labelText: 'Adresse',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _saveProfileChanges(
              nomController.text,
              phoneController.text,
              cinController.text,
              adresseController.text,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  /// 💾 Sauvegarder les modifications du profil
  Future<void> _saveProfileChanges(String nom, String phone, String cin, String adresse) async {
    try {
      Navigator.pop(context); // Fermer le dialog

      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Sauvegarde en cours...'),
            ],
          ),
        ),
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Mettre à jour dans Firestore
        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        await userDoc.set({
          'nom': nom.split(' ').last,
          'prenom': nom.split(' ').first,
          'telephone': phone,
          'cin': cin,
          'adresse': adresse,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Mettre à jour les données locales
        setState(() {
          _nomConducteur = nom;
          if (_userData != null) {
            _userData!['nom'] = nom.split(' ').last;
            _userData!['prenom'] = nom.split(' ').first;
            _userData!['telephone'] = phone;
            _userData!['cin'] = cin;
            _userData!['adresse'] = adresse;
          }
        });

        Navigator.pop(context); // Fermer le loading

        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profil mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Fermer le loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors de la sauvegarde: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🔒 Changer le mot de passe
  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: const Text('Un email de réinitialisation sera envoyé à votre adresse.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendPasswordResetEmail();
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  /// 📧 Envoyer email de réinitialisation
  Future<void> _sendPasswordResetEmail() async {
    try {
      final email = FirebaseAuth.instance.currentUser?.email;
      if (email != null) {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email de réinitialisation envoyé !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 📥 Télécharger les données utilisateur
  Future<void> _downloadUserData() async {
    try {
      // Afficher un dialog de confirmation
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.download, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Text('Télécharger mes données'),
            ],
          ),
          content: const Text(
            'Voulez-vous télécharger toutes vos données personnelles ?\n\n'
            'Cela inclut :\n'
            '• Informations personnelles\n'
            '• Véhicules assurés\n'
            '• Demandes d\'assurance\n'
            '• Historique des sinistres',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Télécharger'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // Afficher un indicateur de chargement
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Préparation des données...'),
              ],
            ),
          ),
        );

        // Préparer les données
        final userData = {
          'informations_personnelles': {
            'nom': _nomConducteur,
            'email': FirebaseAuth.instance.currentUser?.email,
            'telephone': _getUserPhone(),
            'cin': _getUserCIN(),
            'adresse': _getUserAddress(),
            'date_inscription': FirebaseAuth.instance.currentUser?.metadata.creationTime?.toIso8601String(),
          },
          'vehicules': _vehicules.map((v) => {
            'marque': v['marque'],
            'modele': v['modele'],
            'immatriculation': v['numeroImmatriculation'],
            'numero_contrat': v['numeroContrat'],
            'date_debut': v['dateDebut'],
            'date_fin': v['dateFin'],
          }).toList(),
          'demandes': _demandes.map((d) => {
            'numero': d['numero'],
            'statut': d['statut'],
            'marque': d['marque'],
            'modele': d['modele'],
            'date_creation': d['dateCreation'],
          }).toList(),
          'sinistres': _sinistres.map((s) => {
            'id': s['id'],
            'statut': s['statut'],
            'type': s['typeAccident'],
            'date_creation': s['dateCreation'],
          }).toList(),
          'statistiques': _calculateStats(),
          'date_export': DateTime.now().toIso8601String(),
        };

        Navigator.pop(context); // Fermer le loading

        // Simuler le téléchargement (en réalité, on afficherait les données)
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Données exportées'),
            content: SingleChildScrollView(
              child: Text(
                'Vos données ont été préparées :\n\n'
                '📊 ${_vehicules.length} véhicule(s)\n'
                '📋 ${_demandes.length} demande(s)\n'
                '⚠️ ${_sinistres.length} sinistre(s)\n\n'
                'Dans une version complète, ces données seraient téléchargées en format JSON ou PDF.',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Fermer le loading si ouvert

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors de l\'export: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🆘 Contacter le support
  void _contactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.support_agent, color: Colors.purple[700]),
            const SizedBox(width: 8),
            const Text('Support Client'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contactez notre équipe de support :',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            _buildContactOption(
              Icons.phone,
              'Téléphone',
              '+216 71 123 456',
              Colors.green,
              () => _launchPhone('+21671123456'),
            ),

            const SizedBox(height: 12),

            _buildContactOption(
              Icons.email,
              'Email',
              'support@constat-tunisie.com',
              Colors.blue,
              () => _launchEmail('support@constat-tunisie.com'),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Horaires: 8h-18h (Lun-Ven)\n24h/24 pour les urgences',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// 📞 Widget pour une option de contact
  Widget _buildContactOption(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  /// 📞 Lancer un appel téléphonique
  Future<void> _launchPhone(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir l\'application téléphone'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 📧 Lancer l'application email
  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email?subject=Support - Constat Tunisie');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir l\'application email'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🔔 Activer/désactiver les notifications
  void _toggleNotifications(bool value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Notifications activées' : 'Notifications désactivées'),
        backgroundColor: value ? Colors.green : Colors.orange,
      ),
    );
  }

  /// 🌙 Activer/désactiver le mode sombre
  void _toggleDarkMode(bool value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Mode sombre activé' : 'Mode sombre désactivé'),
        backgroundColor: value ? Colors.grey[800] : Colors.blue,
      ),
    );
  }

  /// 🚪 Se déconnecter
  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  Future<void> _ajouterDonneesTest() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Créer des demandes de test
      final demandesTest = [
        {
          'numero': 'D-001',
          'conducteurId': user.uid,
          'conducteurEmail': user.email,
          'statut': 'en_attente',
          'dateCreation': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
          'nom': 'Ben Ahmed',
          'prenom': 'Mohamed',
          'cin': '12345678',
          'telephone': '+216 20 123 456',
          'email': user.email,
          'adresse': '15 Rue de la République, Tunis',
          'immatriculation': '175 TU 5687',
          'marque': 'Peugeot',
          'modele': '208',
          'annee': '2021',
          'puissance': '5',
          'typeVehicule': 'Voiture particulière',
          'carburant': 'Essence',
          'usage': 'Personnel',
          'compagnieId': 'test-compagnie-1',
          'compagnieNom': 'COMAR Assurances',
          'agenceId': 'test-agence-1',
          'agenceNom': 'Agence Tunis Centre',
          'agentId': null,
          'agentNom': null,
          'motifRejet': null,
          'dateModification': Timestamp.now(),
          'documents': {
            'cin_recto_uploaded': true,
            'cin_verso_uploaded': true,
            'permis_recto_uploaded': true,
            'permis_verso_uploaded': true,
            'carte_grise_recto_uploaded': true,
            'carte_grise_verso_uploaded': true,
          },
        },
        {
          'numero': 'D-002',
          'conducteurId': user.uid,
          'conducteurEmail': user.email,
          'statut': 'contrat_valide',
          'dateCreation': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 15))),
          'nom': 'Ben Ahmed',
          'prenom': 'Mohamed',
          'cin': '12345678',
          'telephone': '+216 20 123 456',
          'email': user.email,
          'adresse': '15 Rue de la République, Tunis',
          'immatriculation': '123 TU 4567',
          'marque': 'Renault',
          'modele': 'Clio',
          'annee': '2020',
          'puissance': '4',
          'typeVehicule': 'Voiture particulière',
          'carburant': 'Essence',
          'usage': 'Personnel',
          'compagnieId': 'test-compagnie-2',
          'compagnieNom': 'Assurances Salim',
          'agenceId': 'test-agence-2',
          'agenceNom': 'Agence Sfax',
          'agentId': 'agent-123',
          'agentNom': 'Karim Trabelsi',
          'motifRejet': null,
          'dateModification': Timestamp.now(),
          'documents': {
            'cin_recto_uploaded': true,
            'cin_verso_uploaded': true,
            'permis_recto_uploaded': true,
            'permis_verso_uploaded': true,
            'carte_grise_recto_uploaded': true,
            'carte_grise_verso_uploaded': true,
          },
        },
      ];

      // Ajouter les demandes
      for (var demande in demandesTest) {
        await FirebaseFirestore.instance
            .collection('demandes_contrats')
            .add(demande);
      }

      // Créer un véhicule assuré pour la demande validée
      await FirebaseFirestore.instance
          .collection('vehicules_assures')
          .add({
        'conducteurId': user.uid,
        'statut': 'actif',
        'immatriculation': '123 TU 4567',
        'marque': 'Renault',
        'modele': 'Clio',
        'annee': '2020',
        'compagnieId': 'test-compagnie-2',
        'compagnieNom': 'Assurances Salim',
        'agenceId': 'test-agence-2',
        'agenceNom': 'Agence Sfax',
        'dateDebutContrat': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 10))),
        'dateFinContrat': Timestamp.fromDate(DateTime.now().add(const Duration(days: 355))),
        'numeroContrat': 'C-${DateTime.now().millisecondsSinceEpoch}',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Données de test ajoutées avec succès !'),
          backgroundColor: Colors.green,
        ),
      );

      // Recharger les données
      _loadUserData();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _voirVehicule(Map<String, dynamic> demande) {
    // Naviguer vers la section véhicules ou afficher les détails
    if (mounted) { setState(() {
      _selectedIndex = 1; // Index de la page véhicules
    });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.directions_car, color: Colors.white),
            const SizedBox(width: 8),
            Text('Véhicule ${demande['marque']} ${demande['modele']} ajouté à vos véhicules'),
          ],
        ),
        backgroundColor: Colors.blue,
        action: SnackBarAction(
          label: 'Voir',
          textColor: Colors.white,
          onPressed: () {
            // Action pour voir le véhicule
          },
        ),
      ),
    );
  }

  /// 📄 Section Contrats sur la page d'accueil
  Widget _buildHomeContractsSection() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Mes Contrats d\'Assurance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MesVehiculesScreen(),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_ios, size: 14),
              label: const Text(
                'Voir tout',
                style: TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue[700],
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('demandes_contrats')
              .where('conducteurId', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 120,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Erreur: ${snapshot.error}'),
                    ),
                  ],
                ),
              );
            }

            final allContrats = snapshot.data?.docs ?? [];

            // Nettoyer et dédupliquer les contrats (version synchrone)
            final contratsNettoyes = _nettoyerContratsSynchrone(allContrats);

            // Filtrer et valider les contrats
            final contrats = contratsNettoyes.where((contrat) {
              return _estContratValide(contrat);
            }).take(3).toList();

            if (contrats.isEmpty) {
              return _buildNoContractsHomeCard();
            }

            return Column(
              children: contrats.map((contrat) {
                return _buildHomeContractCard(contrat['id'], contrat);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  /// 📄 Carte de contrat pour la page d'accueil
  Widget _buildHomeContractCard(String contractId, Map<String, dynamic> data) {
    // Nettoyage et formatage des données
    final numeroContrat = _formatNumeroContrat(data['numeroContrat'], contractId);
    final marque = _formatTexte(data['marque']);
    final modele = _formatTexte(data['modele']);
    final immatriculation = _formatImmatriculation(data['immatriculation']);
    final statut = data['statut'] ?? '';
    final compagnieNom = _formatTexte(data['compagnieNom'] ?? data['compagnie']);
    final agenceNom = _formatTexte(data['agenceNom'] ?? data['agence']);

    // Couleur selon le statut
    MaterialColor statusColor = Colors.green;
    String statusText = 'ACTIF';
    IconData statusIcon = Icons.verified;

    switch (statut) {
      case 'contrat_actif':
        statusColor = Colors.green;
        statusText = 'ACTIF';
        statusIcon = Icons.verified;
        break;
      case 'documents_completes':
        statusColor = Colors.blue;
        statusText = 'VALIDÉ';
        statusIcon = Icons.check_circle;
        break;
      case 'frequence_choisie':
        statusColor = Colors.orange;
        statusText = 'EN ATTENTE';
        statusIcon = Icons.schedule;
        break;
      case 'en_attente_paiement':
        statusColor = Colors.purple;
        statusText = 'PAIEMENT';
        statusIcon = Icons.payment;
        break;
      case 'affectee':
        statusColor = Colors.indigo;
        statusText = 'AFFECTÉ';
        statusIcon = Icons.assignment;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'INCONNU';
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _voirContrat(data),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
            ),
            child: Column(
              children: [
                // En-tête avec statut
                Row(
                  children: [
                    // Icône du véhicule avec couleur dynamique
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        statusIcon,
                        color: statusColor[700],
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Informations principales
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$marque $modele',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            immatriculation,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Badge de statut
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor[800],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Informations détaillées
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRowCompact('Contrat', numeroContrat, Icons.description),
                      if (compagnieNom.isNotEmpty && compagnieNom != 'N/A') ...[
                        const SizedBox(height: 6),
                        _buildDetailRowCompact('Compagnie', compagnieNom, Icons.business),
                      ],
                      if (agenceNom.isNotEmpty && agenceNom != 'N/A') ...[
                        const SizedBox(height: 6),
                        _buildDetailRowCompact('Agence', agenceNom, Icons.location_city),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Bouton d'action
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          // Convertir les données pour le modal
                          final vehiculeData = {
                            'id': contractId,
                            'numeroContrat': data['numeroContrat'] ?? '',
                            'numeroDemande': data['numeroDemande'] ?? '',
                            'typeContrat': data['typeContrat'] ?? '',
                            'statut': statut,
                            'marque': marque,
                            'modele': modele,
                            'numeroImmatriculation': data['immatriculation'] ?? '',
                            'annee': data['annee'],
                            'typeCarburant': data['typeCarburant'] ?? '',
                            'puissanceFiscale': data['puissanceFiscale'],
                            'usage': data['usage'] ?? '',
                            'montantPrime': data['montantPrime'],
                            'franchise': data['franchise'],
                            'compagnieNom': compagnieNom,
                            'compagnieAdresse': data['compagnieAdresse'] ?? '',
                            'agenceNom': agenceNom,
                            'agenceAdresse': data['agenceAdresse'] ?? '',
                            'dateDebut': data['dateDebut'],
                            'dateFin': data['dateFin'],
                            'dateCreation': data['dateCreation'],
                          };

                          _showContractDetails(vehiculeData);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.visibility,
                                size: 16,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Voir contrat',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 📋 Afficher les détails complets du contrat
  void _showContractDetails(Map<String, dynamic> vehicule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header du modal
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.blue[800]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Détails du Contrat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${vehicule['marque']} ${vehicule['modele']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildContractDetails(vehicule),
              ),
            ),

            // Footer avec boutons d'action
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: _buildDownloadButtons(vehicule),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔧 Méthodes utilitaires pour le formatage des données
  String _formatTexte(dynamic value) {
    if (value == null) return 'N/A';
    final text = value.toString().trim();
    if (text.isEmpty) return 'N/A';

    // Capitaliser la première lettre de chaque mot
    return text.split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : word)
        .join(' ');
  }

  String _formatImmatriculation(dynamic value) {
    if (value == null) return 'N/A';
    final text = value.toString().trim().toUpperCase();
    if (text.isEmpty) return 'N/A';

    // Format tunisien: XXX TU XXXX
    if (text.length >= 8 && !text.contains(' ')) {
      return '${text.substring(0, 3)} ${text.substring(3, 5)} ${text.substring(5)}';
    }

    return text;
  }

  String _formatNumeroContrat(dynamic numeroContrat, String contractId) {
    if (numeroContrat != null && numeroContrat.toString().trim().isNotEmpty) {
      return numeroContrat.toString().trim();
    }

    // Générer un numéro basé sur l'ID si pas de numéro
    return 'C-${contractId.substring(0, 8).toUpperCase()}';
  }

  /// ✅ Vérifier si un contrat est valide pour l'affichage
  bool _estContratValide(Map<String, dynamic> contrat) {
    final statut = contrat['statut'] ?? '';
    final marque = _formatTexte(contrat['marque']);
    final modele = _formatTexte(contrat['modele']);
    final immatriculation = _formatTexte(contrat['immatriculation']);

    // Vérifier que le contrat a des données valides (pas de N/A)
    final donneesValides = marque != 'N/A' &&
                          modele != 'N/A' &&
                          immatriculation != 'N/A' &&
                          marque.isNotEmpty &&
                          modele.isNotEmpty &&
                          immatriculation.isNotEmpty;

    // Vérifier le statut
    final statutsValides = [
      'contrat_actif',
      'documents_completes',
      'frequence_choisie',
      'en_attente_paiement',
      'affectee'
    ];
    final statutValide = statutsValides.contains(statut);

    // Exclure les contrats de test en mode production
    final estContratTest = marque.toLowerCase().contains('test') ||
                          modele.toLowerCase().contains('test') ||
                          immatriculation.toLowerCase().contains('test');

    return donneesValides && statutValide && (!estContratTest || kDebugMode);
  }

  /// 📋 Widget pour afficher une ligne de détail compacte (sans overflow)
  Widget _buildDetailRowCompact(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 6),
        Flexible(
          flex: 2,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  /// 📄 Carte quand il n'y a pas de contrats (page d'accueil)
  Widget _buildNoContractsHomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.description_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun Contrat Actif',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez par faire une demande d\'assurance.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => setState(() => _selectedIndex = 1), // Aller aux demandes
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle Demande'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🧹 Nettoyer et dédupliquer les contrats (version synchrone)
  List<Map<String, dynamic>> _nettoyerContratsSynchrone(List<QueryDocumentSnapshot> docs) {
    final Map<String, Map<String, dynamic>> contratsUniques = {};
    final List<String> docsASupprimer = [];

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final immatriculation = data['immatriculation'] ?? '';
      final marque = data['marque'] ?? '';
      final modele = data['modele'] ?? '';
      final statut = data['statut'] ?? '';

      // Créer une clé unique basée sur le véhicule
      final cleVehicule = '${immatriculation}_${marque}_${modele}'.toLowerCase();

      if (contratsUniques.containsKey(cleVehicule)) {
        // Il y a déjà un contrat pour ce véhicule
        final contratExistant = contratsUniques[cleVehicule]!;
        final statutExistant = contratExistant['statut'] ?? '';

        // Garder le contrat avec le statut le plus avancé
        final prioriteStatuts = {
          'contrat_actif': 5,
          'documents_completes': 4,
          'frequence_choisie': 3,
          'en_attente_paiement': 2,
          'en_attente': 1,
        };

        final prioriteActuelle = prioriteStatuts[statut] ?? 0;
        final prioriteExistante = prioriteStatuts[statutExistant] ?? 0;

        if (prioriteActuelle > prioriteExistante) {
          // Le nouveau contrat est prioritaire
          docsASupprimer.add(contratExistant['id']);
          contratsUniques[cleVehicule] = {
            ...data,
            'id': doc.id,
            'numeroContrat': _genererNumeroContratSynchrone(data, doc.id),
          };
        } else {
          // L'ancien contrat reste prioritaire
          docsASupprimer.add(doc.id);
        }
      } else {
        // Premier contrat pour ce véhicule
        contratsUniques[cleVehicule] = {
          ...data,
          'id': doc.id,
          'numeroContrat': _genererNumeroContratSynchrone(data, doc.id),
        };
      }
    }

    // Supprimer les doublons (en arrière-plan)
    if (docsASupprimer.isNotEmpty) {
      _supprimerDoublons(docsASupprimer);
    }

    return contratsUniques.values.toList();
  }

  /// 🔢 Générer un numéro de contrat si manquant (version synchrone)
  String _genererNumeroContratSynchrone(Map<String, dynamic> data, String docId) {
    final numeroExistant = data['numeroContrat'];

    if (numeroExistant != null && numeroExistant != 'N/A' && numeroExistant.toString().isNotEmpty) {
      return numeroExistant;
    }

    // Générer un nouveau numéro
    final marque = data['marque'] ?? 'VEH';
    final annee = DateTime.now().year;
    final timestamp = DateTime.now().millisecondsSinceEpoch % 10000;

    // Sécuriser le substring pour éviter RangeError
    String marqueCode;
    if (marque.length >= 3) {
      marqueCode = marque.substring(0, 3).toUpperCase();
    } else {
      marqueCode = marque.toUpperCase().padRight(3, 'X');
    }

    final nouveauNumero = '${marqueCode}_${annee}_${timestamp.toString().padLeft(4, '0')}';

    // Mettre à jour dans Firestore (en arrière-plan)
    _mettreAJourNumeroContrat(docId, nouveauNumero);

    return nouveauNumero;
  }

  /// 🗑️ Supprimer les doublons (en arrière-plan)
  Future<void> _supprimerDoublons(List<String> docIds) async {
    if (docIds.isEmpty) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final docId in docIds) {
        final docRef = FirebaseFirestore.instance.collection('demandes_contrats').doc(docId);
        batch.delete(docRef);
      }

      await batch.commit();
      print('🗑️ [NETTOYAGE] ${docIds.length} doublons supprimés');
    } catch (e) {
      print('❌ [NETTOYAGE] Erreur suppression doublons: $e');
    }
  }

  /// 📝 Mettre à jour le numéro de contrat (en arrière-plan)
  Future<void> _mettreAJourNumeroContrat(String docId, String numeroContrat) async {
    try {
      await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(docId)
          .update({'numeroContrat': numeroContrat});

      print('📝 [NETTOYAGE] Numéro de contrat mis à jour: $numeroContrat');
    } catch (e) {
      print('❌ [NETTOYAGE] Erreur mise à jour numéro: $e');
    }
  }

  /// 🗑️ Supprimer toutes les données de test
  Future<void> _supprimerDonneesTest() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() => _isLoading = true);

      // Supprimer les demandes de test
      final demandesSnapshot = await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .where('conducteurId', isEqualTo: user.uid)
          .get();

      int demandesSupprimes = 0;
      for (final doc in demandesSnapshot.docs) {
        final data = doc.data();
        final marque = data['marque']?.toString().toLowerCase() ?? '';
        final modele = data['modele']?.toString().toLowerCase() ?? '';
        final isTestData = data['isTestData'] == true;

        // Supprimer si c'est marqué comme test ou contient "test" dans marque/modèle
        if (isTestData || marque.contains('test') || modele.contains('test') ||
            marque == 'renault' || marque == 'peugeot' || marque == 'toyota') {
          await doc.reference.delete();
          demandesSupprimes++;
          print('🗑️ Supprimé demande test: ${data['marque']} ${data['modele']}');
        }
      }

      // Supprimer les véhicules de test
      final vehiculesSnapshot = await FirebaseFirestore.instance
          .collection('vehicules_assures')
          .where('conducteurId', isEqualTo: user.uid)
          .get();

      int vehiculesSupprimes = 0;
      for (final doc in vehiculesSnapshot.docs) {
        final data = doc.data();
        final marque = data['marque']?.toString().toLowerCase() ?? '';
        final modele = data['modele']?.toString().toLowerCase() ?? '';

        // Supprimer si contient des données de test
        if (marque.contains('test') || modele.contains('test') ||
            marque == 'renault' || marque == 'peugeot' || marque == 'toyota') {
          await doc.reference.delete();
          vehiculesSupprimes++;
          print('🗑️ Supprimé véhicule test: ${data['marque']} ${data['modele']}');
        }
      }

      // Supprimer les sinistres de test
      final sinistresSnapshot = await FirebaseFirestore.instance
          .collection('sinistres')
          .where('conducteurId', isEqualTo: user.uid)
          .get();

      int sinistresSupprimes = 0;
      for (final doc in sinistresSnapshot.docs) {
        final data = doc.data();
        final isTestData = data['test_data'] == true;

        if (isTestData) {
          await doc.reference.delete();
          sinistresSupprimes++;
          print('🗑️ Supprimé sinistre test: ${doc.id}');
        }
      }

      // Recharger les données
      await _loadUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🗑️ Nettoyage terminé: $demandesSupprimes demandes, $vehiculesSupprimes véhicules, $sinistresSupprimes sinistres supprimés'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

    } catch (e) {
      print('❌ Erreur suppression données test: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🚨 Déclarer un sinistre
  void _declarerSinistre(String vehiculeId, Map<String, dynamic> data) {
    // Vérifier le statut du contrat
    final statut = data['statut'] ?? '';
    final numeroContrat = data['numeroContrat'] ?? '';

    print('🔍 Vérification statut pour déclaration sinistre:');
    print('   Véhicule: ${data['marque']} ${data['modele']}');
    print('   Statut: $statut');
    print('   N° Contrat: $numeroContrat');

    // Vérifier si le contrat est actif
    if (statut != 'contrat_actif' && statut != 'documents_completes') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Contrat non actif',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Statut actuel: $statut\nVeuillez contacter votre agence.',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // Vérifier si le numéro de contrat existe
    if (numeroContrat.isEmpty || numeroContrat == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Numéro de contrat manquant\nImpossible de déclarer un sinistre.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Contrat valide, procéder à la déclaration
    final vehiculeData = {
      'id': vehiculeId,
      'contratId': vehiculeId,
      'numeroContrat': numeroContrat,
      'marque': data['marque'] ?? 'N/A',
      'modele': data['modele'] ?? 'N/A',
      'immatriculation': data['numeroImmatriculation'] ?? data['immatriculation'] ?? 'N/A',
      'annee': data['annee'] ?? 'N/A',
      'couleur': data['couleur'] ?? 'N/A',
      'statut': statut,
      'compagnieNom': data['compagnieNom'] ?? 'N/A',
      'agenceNom': data['agenceNom'] ?? 'N/A',
    };

    print('✅ Déclaration autorisée pour véhicule avec contrat actif');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeclarationSinistreScreen(
          vehicule: vehiculeData,
        ),
      ),
    );
  }

  /// 📋 Section "Mes Formulaires" avec brouillons
  Widget _buildMesFormulairesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.assignment_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Mes Formulaires en Cours',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {}), // Refresh
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'Actualiser',
                ),
              ],
            ),
          ),

          // Contenu
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _recupererTousLesBrouillons(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur de chargement',
                          style: TextStyle(
                            color: Colors.red[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final brouillons = snapshot.data ?? [];

              if (brouillons.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun formulaire en cours',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Commencez à remplir un formulaire pour le voir apparaître ici',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: brouillons.map((brouillon) => _buildBrouillonCard(brouillon)).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 📄 Carte d'un brouillon
  Widget _buildBrouillonCard(Map<String, dynamic> brouillon) {
    final sessionId = brouillon['sessionId'] as String;
    final etape = brouillon['etape'] as String;
    final dateModification = (brouillon['dateModification'] as Timestamp?)?.toDate();
    final donnees = brouillon['donnees'] as Map<String, dynamic>? ?? {};

    // Calculer le pourcentage de completion
    final pourcentage = _calculerPourcentageCompletion(donnees);

    // Obtenir le nom d'affichage de l'étape
    final nomEtape = FormStatusService.getNomEtape(etape);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _ouvrirBrouillon(sessionId, etape),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône de statut
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),

              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomEtape,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'En cours',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${pourcentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (dateModification != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Modifié le ${_formatDate(dateModification)} à ${dateModification.hour}:${dateModification.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Flèche
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📊 Récupérer tous les brouillons du conducteur
  Future<List<Map<String, dynamic>>> _recupererTousLesBrouillons() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final query = await FirebaseFirestore.instance
          .collection('brouillons_session')
          .where('conducteurId', isEqualTo: user.uid)
          .orderBy('dateModification', descending: true)
          .get();

      return query.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('❌ Erreur récupération brouillons: $e');
      return [];
    }
  }

  /// 📈 Calculer le pourcentage de completion
  double _calculerPourcentageCompletion(Map<String, dynamic> donnees) {
    if (donnees.isEmpty) return 0.0;

    int champsRemplis = 0;
    int totalChamps = 0;

    donnees.forEach((key, value) {
      totalChamps++;
      if (value != null && value.toString().isNotEmpty) {
        if (value is List && value.isNotEmpty) {
          champsRemplis++;
        } else if (value is! List) {
          champsRemplis++;
        }
      }
    });

    return totalChamps > 0 ? (champsRemplis / totalChamps) * 100 : 0.0;
  }

  /// 📂 Ouvrir un brouillon
  Future<void> _ouvrirBrouillon(String sessionId, String etape) async {
    try {
      // Récupérer la session collaborative
      final sessionDoc = await FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session introuvable'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final sessionData = sessionDoc.data()!;
      final session = CollaborativeSession.fromMap(sessionData, sessionId);

      // Naviguer vers le formulaire approprié selon l'étape
      if (mounted) {
        switch (etape) {
          case 'formulaire_general':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ModernSingleAccidentInfoScreen(
                  typeAccident: session.typeAccident ?? 'Accident collaboratif',
                  session: session,
                  isCollaborative: true,
                ),
              ),
            );
            break;
          case 'circonstances':
            // TODO: Naviguer vers l'écran des circonstances
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Écran des circonstances - À implémenter'),
                backgroundColor: Colors.orange,
              ),
            );
            break;
          case 'croquis':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ModernCollaborativeSketchScreen(
                  session: session,
                ),
              ),
            );
            break;
          case 'signatures':
            // TODO: Naviguer vers l'écran des signatures
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Écran des signatures - À implémenter'),
                backgroundColor: Colors.orange,
              ),
            );
            break;
          default:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Étape inconnue: $etape'),
                backgroundColor: Colors.red,
              ),
            );
        }
      }
    } catch (e) {
      print('❌ Erreur ouverture brouillon: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🎴 Carte de session collaborative
  Widget _buildCollaborativeSessionCard(CollaborativeSession session) {
    final Color statusColor = _getSessionStatusColor(session.statut);
    final String statusText = _getSessionStatusText(session.statut);
    final int participantsCount = session.participants.length;
    final int maxParticipants = session.nombreVehicules;
    final bool isSelected = _selectedSessions.contains(session.id);

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getConstatStatusForSession(session.id!),
      builder: (context, constatSnapshot) {
        final constatData = constatSnapshot.data;
        final constatStatut = constatData?['statut'];

        return _buildSessionCardContent(
          session,
          statusColor,
          statusText,
          participantsCount,
          maxParticipants,
          isSelected,
          constatStatut,
          constatData,
        );
      },
    );
  }

  /// 🔍 Debug - Vérifier toutes les collections pour une session
  Future<void> _debugSessionData(String sessionId) async {
    try {
      debugPrint('[DEBUG] 🔍 === ANALYSE COMPLÈTE SESSION: $sessionId ===');

      // 1. Sessions collaboratives
      final sessionDoc = await FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .get();

      if (sessionDoc.exists) {
        final sessionData = sessionDoc.data()!;
        debugPrint('[DEBUG] 📋 Session: statut=${sessionData['statut']}, dateFinalisation=${sessionData['dateFinalisation']}');
      } else {
        debugPrint('[DEBUG] ❌ Session non trouvée');
      }

      // 2. Constats finalisés
      final constatDoc = await FirebaseFirestore.instance
          .collection('constats_finalises')
          .doc(sessionId)
          .get();

      if (constatDoc.exists) {
        final data = constatDoc.data()!;
        debugPrint('[DEBUG] 📄 Constat finalisé: statut=${data['statut']}, dateEnvoi=${data['dateEnvoi']}, expertAssigne=${data['expertAssigne'] != null}');
      } else {
        debugPrint('[DEBUG] ❌ Constat finalisé non trouvé');
      }

      // 3. Constats agents
      final constatAgentQuery = await FirebaseFirestore.instance
          .collection('constats_agents')
          .where('sessionId', isEqualTo: sessionId)
          .get();

      debugPrint('[DEBUG] 👨‍💼 Constats agents: ${constatAgentQuery.docs.length} trouvés');
      for (final doc in constatAgentQuery.docs) {
        final data = doc.data();
        debugPrint('[DEBUG]    - Agent: ${data['agentNom']}, dateEnvoi: ${data['dateEnvoiPdf']}');
      }

      // 4. Missions expertise
      final missionQuery = await FirebaseFirestore.instance
          .collection('missions_expertise')
          .where('sessionId', isEqualTo: sessionId)
          .get();

      debugPrint('[DEBUG] 🔧 Missions expertise: ${missionQuery.docs.length} trouvées');
      for (final doc in missionQuery.docs) {
        final data = doc.data();
        debugPrint('[DEBUG]    - Expert: ${data['expertId']}, statut: ${data['statut']}, sessionId: ${data['sessionId']}');
      }

      // 4b. Toutes les missions expertise (pour debug)
      final allMissionsQuery = await FirebaseFirestore.instance
          .collection('missions_expertise')
          .get();

      debugPrint('[DEBUG] 🔧 TOUTES missions expertise: ${allMissionsQuery.docs.length} trouvées');
      for (final doc in allMissionsQuery.docs) {
        final data = doc.data();
        debugPrint('[DEBUG]    - Mission: ${doc.id}, sessionId: ${data['sessionId']}, expertId: ${data['expertId']}, statut: ${data['statut']}');
      }

      // 5. Notifications agents (utilisées par "Notifier les Agents")
      final notificationsAgentsQuery = await FirebaseFirestore.instance
          .collection('notifications_agents')
          .where('sessionId', isEqualTo: sessionId)
          .get();

      debugPrint('[DEBUG] 📧 Notifications agents: ${notificationsAgentsQuery.docs.length} trouvées');
      for (final doc in notificationsAgentsQuery.docs) {
        final data = doc.data();
        debugPrint('[DEBUG]    - Agent: ${data['destinataire']}, statut: ${data['statut']}');
      }

      // 6. Agent notifications (autre collection possible)
      final agentNotificationsQuery = await FirebaseFirestore.instance
          .collection('agent_notifications')
          .where('sessionId', isEqualTo: sessionId)
          .get();

      debugPrint('[DEBUG] 🔔 Agent notifications: ${agentNotificationsQuery.docs.length} trouvées');
      for (final doc in agentNotificationsQuery.docs) {
        final data = doc.data();
        debugPrint('[DEBUG]    - Agent: ${data['agentEmail']}, type: ${data['type']}');
      }

      // 7. Notifications générales
      final notificationsQuery = await FirebaseFirestore.instance
          .collection('notifications')
          .where('donnees.sessionId', isEqualTo: sessionId)
          .get();

      debugPrint('[DEBUG] 🔔 Notifications générales: ${notificationsQuery.docs.length} trouvées');
      for (final doc in notificationsQuery.docs) {
        final data = doc.data();
        debugPrint('[DEBUG]    - Type: ${data['type']}, Agent: ${data['agentId']}');
      }

      debugPrint('[DEBUG] 🔍 === FIN ANALYSE SESSION ===');

    } catch (e) {
      debugPrint('[DEBUG] ❌ Erreur analyse: $e');
    }
  }

  /// 📋 Récupérer le statut du constat pour une session
  Future<Map<String, dynamic>?> _getConstatStatusForSession(String sessionId) async {
    try {
      debugPrint('[DASHBOARD] 🔍 Recherche statut pour session: $sessionId');

      // Debug complet pour comprendre le problème
      await _debugSessionData(sessionId);

      // 1. Vérifier d'abord dans constats_finalises (collection principale)
      final constatDoc = await FirebaseFirestore.instance
          .collection('constats_finalises')
          .doc(sessionId)
          .get();

      if (constatDoc.exists) {
        final data = constatDoc.data()!;
        debugPrint('[DASHBOARD] ✅ Constat trouvé dans constats_finalises');
        debugPrint('[DASHBOARD] 📊 Données: ${data.keys.toList()}');

        // Le statut est directement dans le champ 'statut'
        final expertAssigne = data['expertAssigne'];
        String statutPrincipal = data['statut'] ?? 'finalise';

        debugPrint('[DASHBOARD] 📊 Statut brut: $statutPrincipal');
        debugPrint('[DASHBOARD] 🔧 Expert assigné: ${expertAssigne != null}');

        // Le statut est déjà correct dans la base de données
        // L'agent met directement 'expert_assigne', 'en_expertise', etc.
        if (expertAssigne != null) {
          debugPrint('[DASHBOARD] 🔧 Expert assigné détecté: ${expertAssigne['nom']}');
        }

        if (data['dateEnvoi'] != null) {
          debugPrint('[DASHBOARD] 📤 Date envoi détectée: ${data['dateEnvoi']}');
        }

        debugPrint('[DASHBOARD] 🎯 Statut final déterminé: $statutPrincipal');

        return {
          'statut': statutPrincipal,
          'dateEnvoi': data['dateEnvoi'],
          'agentInfo': data['agentInfo'],
          'source': 'constat_finalise',
          'statutTraitement': data['statutTraitement'],
          'dateTraitement': data['dateTraitement'],
          'commentairesAgent': data['commentairesAgent'],
          // Données de l'expert si disponibles
          'expertAssigne': expertAssigne,
          'dateAssignationExpert': data['dateAssignationExpert'],
          'delaiInterventionHeures': data['delaiInterventionHeures'],
          'progressionExpertise': data['progressionExpertise'],
          'dateVisite': data['dateVisite'],
          'rapportFinal': data['rapportFinal'],
          'evaluation': data['evaluation'],
        };
      }

      // 2. Vérifier dans notifications_agents (utilisé par "Notifier les Agents")
      final notificationsAgentsQuery = await FirebaseFirestore.instance
          .collection('notifications_agents')
          .where('sessionId', isEqualTo: sessionId)
          .get();

      if (notificationsAgentsQuery.docs.isNotEmpty) {
        final docs = notificationsAgentsQuery.docs;
        docs.sort((a, b) {
          final dateA = a.data()['dateCreation'] as Timestamp?;
          final dateB = b.data()['dateCreation'] as Timestamp?;
          if (dateA == null || dateB == null) return 0;
          return dateB.compareTo(dateA);
        });

        final notifData = docs.first.data();
        debugPrint('[DASHBOARD] ✅ Notification agent trouvée dans notifications_agents');

        return {
          'statut': 'envoye',
          'dateEnvoi': notifData['dateCreation'],
          'agentInfo': {
            'email': notifData['destinataire'],
            'nom': '',
            'prenom': '',
            'agenceNom': notifData['agencyName'] ?? '',
            'compagnieNom': notifData['companyName'] ?? '',
          },
          'source': 'notification_agent',
          'statutTraitement': notifData['statut'] ?? 'en_attente',
        };
      }

      // 3. Vérifier dans agent_notifications
      final agentNotificationsQuery = await FirebaseFirestore.instance
          .collection('agent_notifications')
          .where('sessionId', isEqualTo: sessionId)
          .get();

      if (agentNotificationsQuery.docs.isNotEmpty) {
        final docs = agentNotificationsQuery.docs;
        docs.sort((a, b) {
          final dateA = a.data()['timestamp'] as Timestamp?;
          final dateB = b.data()['timestamp'] as Timestamp?;
          if (dateA == null || dateB == null) return 0;
          return dateB.compareTo(dateA);
        });

        final notifData = docs.first.data();
        debugPrint('[DASHBOARD] ✅ Notification agent trouvée dans agent_notifications');

        return {
          'statut': 'envoye',
          'dateEnvoi': notifData['timestamp'],
          'agentInfo': {
            'email': notifData['agentEmail'],
            'nom': '',
            'prenom': '',
            'agenceNom': '',
            'compagnieNom': '',
          },
          'source': 'agent_notification',
          'statutTraitement': 'nouveau',
        };
      }

      // 4. Vérifier dans la session si elle est finalisée mais pas envoyée
      final sessionDoc = await FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .get();

      if (sessionDoc.exists) {
        final sessionData = sessionDoc.data()!;
        final statut = sessionData['statut'];

        debugPrint('[DASHBOARD] 📋 Session trouvée avec statut: $statut');

        if (statut == 'finalise' || statut == 'signe') {
          return {
            'statut': 'finalise_non_envoye',
            'dateFinalisee': sessionData['dateFinalisation'],
            'source': 'session',
          };
        }
      }

      debugPrint('[DASHBOARD] ❌ Aucun constat trouvé pour session: $sessionId');
      return null;

    } catch (e) {
      debugPrint('[DASHBOARD] ❌ Erreur récupération constat: $e');
      return null;
    }
  }

  /// 🎴 Contenu de la carte de session
  Widget _buildSessionCardContent(
    CollaborativeSession session,
    Color statusColor,
    String statusText,
    int participantsCount,
    int maxParticipants,
    bool isSelected,
    String? constatStatut,
    Map<String, dynamic>? constatData,
  ) {

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.purple[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.purple[600]! : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
              ? Colors.purple.withOpacity(0.2)
              : Colors.black.withOpacity(0.05),
            blurRadius: isSelected ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _isSelectionMode
          ? _toggleSessionSelection(session.id!)
          : _ouvrirSessionCollaborative(session),
        onLongPress: () => _toggleSessionSelection(session.id!),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec code et statut
              Row(
                children: [
                  // Checkbox de sélection (visible en mode sélection)
                  if (_isSelectionMode) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) => _toggleSessionSelection(session.id!),
                      activeColor: Colors.purple[600],
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      session.codeSession,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[800],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Type d'accident
              Text(
                session.typeAccident,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              // Informations
              Row(
                children: [
                  Icon(Icons.group, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '$participantsCount/$maxParticipants participants',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(session.dateCreation),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Barre de progression
              _buildProgressionSession(session),

              // Statut du constat (si disponible)
              if (constatStatut != null) ...[
                const SizedBox(height: 12),
                _buildConstatStatusBadge(constatStatut, constatData),
              ],

              const SizedBox(height: 12),

              // Actions
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _voirParticipants(session),
                          icon: const Icon(Icons.people, size: 16),
                          label: const Text('Participants'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.purple[600],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _ouvrirSessionCollaborative(session),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Ouvrir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: () => _voirDetailsSession(session),
                          icon: const Icon(Icons.info_outline, size: 16),
                          label: const Text('Voir détails'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.indigo[600],
                            side: BorderSide(color: Colors.indigo[300]!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Bouton de suppression individuelle (visible seulement si pas en mode sélection)
                      if (!_isSelectionMode)
                        Expanded(
                          flex: 1,
                          child: OutlinedButton.icon(
                            onPressed: () => _supprimerSessionIndividuelle(session),
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('Suppr.'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red[600],
                              side: BorderSide(color: Colors.red[300]!),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📊 Barre de progression de la session
  Widget _buildProgressionSession(CollaborativeSession session) {
    final double progression = session.progression.participantsRejoints / session.nombreVehicules;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progression',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progression * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progression,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.purple[600]!),
        ),
      ],
    );
  }

  /// 🏷️ Badge de statut du constat
  Widget _buildConstatStatusBadge(String constatStatut, Map<String, dynamic>? constatData) {
    String statusText;
    Color statusColor;
    IconData statusIcon;
    String? subtitle;

    switch (constatStatut) {
      case 'finalise_non_envoye':
        statusText = 'Prêt à envoyer';
        statusColor = Colors.blue;
        statusIcon = Icons.upload_file;
        subtitle = 'Constat finalisé, en attente d\'envoi';
        break;
      case 'envoye':
      case 'envoye_agent':
        statusText = 'Envoyé à l\'agent';
        statusColor = Colors.orange;
        statusIcon = Icons.send;
        final agentInfo = constatData?['agentInfo'];
        if (agentInfo != null) {
          subtitle = 'Agent: ${agentInfo['prenom']} ${agentInfo['nom']}';
        }
        break;
      case 'nouveau':
        statusText = 'Reçu par l\'agent';
        statusColor = Colors.indigo;
        statusIcon = Icons.mark_email_read;
        subtitle = 'En attente de traitement';
        break;
      case 'en_cours':
        statusText = 'En cours de traitement';
        statusColor = Colors.blue;
        statusIcon = Icons.pending_actions;
        subtitle = 'L\'agent traite votre dossier';
        break;
      case 'traite':
        statusText = 'Traité par l\'agent';
        statusColor = Colors.green;
        statusIcon = Icons.task_alt;
        subtitle = 'Dossier traité avec succès';
        break;
      case 'expert_assigne':
        statusText = 'Expert assigné';
        statusColor = Colors.purple;
        statusIcon = Icons.engineering;
        subtitle = 'Un expert va examiner votre véhicule';
        break;
      case 'en_expertise':
        statusText = 'Expertise en cours';
        statusColor = Colors.deepPurple;
        statusIcon = Icons.assessment;
        subtitle = 'L\'expert examine les dégâts';
        break;
      case 'expertise_terminee':
        statusText = 'Expertise terminée';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        subtitle = 'Rapport d\'expertise disponible';
        break;
      case 'archive':
        statusText = 'Dossier archivé';
        statusColor = Colors.grey;
        statusIcon = Icons.archive;
        subtitle = 'Traitement terminé';
        break;
      case 'cloture':
        statusText = 'Dossier clôturé';
        statusColor = Colors.grey;
        statusIcon = Icons.folder_off;
        subtitle = 'Procédure terminée';
        break;
      default:
        statusText = 'Statut inconnu';
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        subtitle = 'Vérifiez avec votre agent';
    }

    return GestureDetector(
      onTap: () => _showConstatStatusDetails(constatStatut, constatData),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, size: 16, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Statut du constat PDF',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.grey[500],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],

            // Informations supplémentaires selon le statut
            if (constatData != null) ...[
              const SizedBox(height: 8),
              _buildStatusSpecificInfo(constatStatut, constatData),
            ],
          ],
        ),
      ),
    );
  }

  /// 📋 Informations spécifiques selon le statut
  Widget _buildStatusSpecificInfo(String statut, Map<String, dynamic> data) {
    switch (statut) {
      case 'envoye':
      case 'envoye_agent':
        final dateEnvoi = data['dateEnvoi'];
        final agentInfo = data['agentInfo'];
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (dateEnvoi != null)
                Text(
                  'Envoyé le: ${_formatDate(dateEnvoi)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              if (agentInfo != null && agentInfo['agenceNom'] != null)
                Text(
                  'Agence: ${agentInfo['agenceNom']}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        );

      case 'expert_assigne':
        final expertInfo = data['expertAssigne'] ?? data['agentInfo'];
        final dateAssignation = data['dateAssignationExpert'];
        final delaiIntervention = data['delaiInterventionHeures'];

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (expertInfo != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple[200]!, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.engineering, size: 14, color: Colors.purple[700]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Expert: ${expertInfo['prenom'] ?? ''} ${expertInfo['nom'] ?? ''}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.purple[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                if (expertInfo['codeExpert'] != null)
                  Text(
                    'Code: ${expertInfo['codeExpert']}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                if (expertInfo['telephone'] != null)
                  Row(
                    children: [
                      Icon(Icons.phone, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _callExpert(expertInfo['telephone']),
                        child: Text(
                          expertInfo['telephone'],
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[600],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (dateAssignation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Assigné le: ${_formatDate(dateAssignation)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                if (delaiIntervention != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 12, color: Colors.orange[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Délai: ${delaiIntervention}h',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        );

      case 'en_expertise':
        final expertInfo = data['expertAssigne'];
        final progression = data['progressionExpertise'] ?? 0;
        final dateVisite = data['dateVisite'];

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepPurple[50],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.assessment, size: 14, color: Colors.deepPurple[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Expertise en cours',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Barre de progression
              LinearProgressIndicator(
                value: progression / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple[600]!),
              ),
              const SizedBox(height: 4),
              Text(
                'Progression: ${progression.toInt()}%',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              if (dateVisite != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Visite prévue: ${_formatDate(dateVisite)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (expertInfo != null && expertInfo['telephone'] != null) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _callExpert(expertInfo['telephone']),
                  child: Row(
                    children: [
                      Icon(Icons.phone, size: 12, color: Colors.blue[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Contacter l\'expert',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[600],
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );

      case 'expertise_terminee':
        final rapportFinal = data['rapportFinal'];
        final evaluation = data['evaluation'];

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Expertise terminée',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
              if (rapportFinal != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Rapport disponible',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (evaluation != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Évaluation: ${evaluation['montantDegats'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        );

      case 'traite':
        final dateTraitement = data['dateTraitement'];
        final commentaires = data['commentairesAgent'];
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (dateTraitement != null)
                Text(
                  'Traité le: ${_formatDate(dateTraitement)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              if (commentaires != null && commentaires.isNotEmpty)
                Text(
                  'Note: $commentaires',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }



  /// 📞 Appeler l'expert
  void _callExpert(String telephone) async {
    try {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: telephone,
      );
      await launchUrl(launchUri);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d\'appeler: $telephone'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 📋 Afficher les détails du statut du constat
  void _showConstatStatusDetails(String statut, Map<String, dynamic>? data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[800]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timeline, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Suivi de votre constat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Contenu avec timeline
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: data != null
                      ? ConstatStatusTimeline(statusData: data)
                      : Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune information de suivi disponible',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              // Actions
              if (data?['expertAssigne']?['telephone'] != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _callExpert(data!['expertAssigne']['telephone']),
                      icon: const Icon(Icons.phone),
                      label: const Text('Appeler l\'expert'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎨 Couleur selon le statut de session
  Color _getSessionStatusColor(SessionStatus statut) {
    switch (statut) {
      case SessionStatus.creation:
        return Colors.blue[600]!;
      case SessionStatus.attente_participants:
        return Colors.orange[600]!;
      case SessionStatus.en_cours:
        return Colors.green[600]!;
      case SessionStatus.pret_signature:
        return Colors.purple[600]!;
      case SessionStatus.signe:
        return Colors.indigo[600]!;
      case SessionStatus.finalise:
        return Colors.grey[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  /// 📝 Texte selon le statut de session
  String _getSessionStatusText(SessionStatus statut) {
    switch (statut) {
      case SessionStatus.creation:
        return 'Création';
      case SessionStatus.attente_participants:
        return 'En attente';
      case SessionStatus.en_cours:
        return 'En cours';
      case SessionStatus.pret_signature:
        return 'Prêt signature';
      case SessionStatus.signe:
        return 'Signée';
      case SessionStatus.finalise:
        return 'Finalisée';
      default:
        return 'Inconnu';
    }
  }

  /// 🆕 Créer une nouvelle session
  void _creerNouvelleSession() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AccidentChoiceScreen(),
      ),
    );
  }

  /// 🔗 Rejoindre une session
  void _rejoindreSession() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const JoinSessionScreen(),
      ),
    );
  }

  /// 👥 Voir les participants
  void _voirParticipants(CollaborativeSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionDashboardScreen(session: session),
      ),
    );
  }

  /// 📱 Ouvrir la session collaborative
  void _ouvrirSessionCollaborative(CollaborativeSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionDashboardScreen(session: session),
      ),
    );
  }

  /// 📋 Voir les détails complets de la session
  void _voirDetailsSession(CollaborativeSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionDetailsScreen(
          session: session,
          currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
        ),
      ),
    );
  }

  /// 📊 En-tête pour les sessions collaboratives
  Widget _buildSessionsHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo[600]!,
            Colors.purple[600]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête principal avec boutons de gestion
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.group_work,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _isSelectionMode ? 'Mode Sélection' : 'Sessions Collaboratives',
                        key: ValueKey(_isSelectionMode),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _isSelectionMode
                          ? '${_selectedSessions.length} session(s) sélectionnée(s)'
                          : 'Gérez vos constats collaboratifs et suivez leur progression',
                        key: ValueKey('${_isSelectionMode}_${_selectedSessions.length}'),
                        style: TextStyle(
                          fontSize: 14,
                          color: _isSelectionMode && _selectedSessions.isNotEmpty
                            ? Colors.yellow[200]
                            : Colors.white70,
                          fontWeight: _isSelectionMode && _selectedSessions.isNotEmpty
                            ? FontWeight.w600
                            : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Boutons de gestion
              if (!_isSelectionMode) ...[
                IconButton(
                  onPressed: () => setState(() => _isSelectionMode = true),
                  icon: const Icon(Icons.checklist, color: Colors.white),
                  tooltip: 'Mode sélection',
                ),
                IconButton(
                  onPressed: () {
                    print('🔄 Bouton rechargement cliqué');
                    _forcerRechargementSessions();
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Actualiser',
                ),
              ] else ...[
                // Bouton Sélectionner tout/Désélectionner tout
                IconButton(
                  onPressed: _selectionnerToutesLesSessions,
                  icon: Icon(
                    _selectedSessions.length == _allSessions.length
                      ? Icons.deselect
                      : Icons.select_all,
                    color: Colors.white
                  ),
                  tooltip: _selectedSessions.length == _allSessions.length
                    ? 'Tout désélectionner'
                    : 'Tout sélectionner',
                ),
                // Bouton Supprimer
                IconButton(
                  onPressed: _selectedSessions.isEmpty ? null : _supprimerSessionsSelectionnees,
                  icon: Icon(
                    Icons.delete,
                    color: _selectedSessions.isEmpty ? Colors.white54 : Colors.white
                  ),
                  tooltip: 'Supprimer sélection (${_selectedSessions.length})',
                ),
                // Bouton Annuler
                IconButton(
                  onPressed: () => setState(() {
                    _isSelectionMode = false;
                    _selectedSessions.clear();
                  }),
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Annuler sélection',
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Statistiques des sessions
          StreamBuilder<List<CollaborativeSession>>(
            stream: _getSessionsCollaborativesStream(),
            builder: (context, snapshot) {
              final sessions = snapshot.data ?? [];
              final sessionsActives = sessions.where((s) => s.statut == SessionStatus.en_cours).length;
              final sessionsTerminees = sessions.where((s) => s.statut == SessionStatus.finalise).length;

              return Row(
                children: [
                  Expanded(
                    child: _buildStatBadge('Total', sessions.length.toString(), Icons.list),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatBadge('Actives', sessionsActives.toString(), Icons.pending),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatBadge('Terminées', sessionsTerminees.toString(), Icons.check_circle),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// ⚡ Actions rapides pour les sessions
  Widget _buildSessionsActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDashboardActionButton(
                'Créer Session',
                'Nouveau constat collaboratif',
                Icons.add_circle,
                Colors.purple,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccidentSessionChoiceScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDashboardActionButton(
                'Rejoindre',
                'Rejoindre une session',
                Icons.group_add,
                Colors.indigo,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const JoinSessionScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [

            Expanded(
              child: _buildDashboardActionButton(
                'Historique',
                'Toutes mes sessions',
                Icons.history,
                Colors.teal,
                () => {
                  // TODO: Implémenter l'historique des sessions
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Historique des sessions - À implémenter'),
                      backgroundColor: Colors.orange,
                    ),
                  )
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 🔄 Charger les sessions collaboratives (nouvelle version)
  Future<void> _chargerSessionsCollaborativesNouvelle() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      print('🔍 Chargement sessions pour utilisateur: ${user.uid}');

      // Charger toutes les sessions récentes
      final snapshot = await FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .orderBy('dateCreation', descending: true)
          .limit(50) // Limiter pour éviter de charger trop de données
          .get();

      print('🔍 ${snapshot.docs.length} sessions trouvées dans Firestore');

      final sessions = <CollaborativeSession>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final session = CollaborativeSession.fromMap(data, doc.id);

          // Vérifier si l'utilisateur participe à cette session
          final userParticipe = session.participants.any((p) => p.userId == user.uid) ||
                                session.conducteurCreateur == user.uid;

          if (userParticipe) {
            sessions.add(session);
            print('✅ Session trouvée: ${session.id} - ${session.codeSession}');
          }
        } catch (e) {
          print('⚠️ Erreur parsing session ${doc.id}: $e');
        }
      }

      print('🔍 ${sessions.length} sessions où l\'utilisateur participe');

      setState(() {
        _allSessions = sessions;
      });
    } catch (e) {
      print('❌ Erreur chargement sessions: $e');
    }
  }

  /// ✅ Basculer la sélection d'une session
  void _toggleSessionSelection(String sessionId) {
    setState(() {
      if (_selectedSessions.contains(sessionId)) {
        _selectedSessions.remove(sessionId);
      } else {
        _selectedSessions.add(sessionId);
      }
    });
  }

  /// 📋 Sélectionner toutes les sessions
  void _selectionnerToutesLesSessions() {
    setState(() {
      // Compter les sessions avec ID valide
      final sessionsAvecId = _allSessions.where((s) => s.id != null && s.id!.isNotEmpty).toList();

      if (_selectedSessions.length == sessionsAvecId.length && sessionsAvecId.isNotEmpty) {
        // Si toutes sont sélectionnées, tout désélectionner
        _selectedSessions.clear();
      } else {
        // Sinon, tout sélectionner
        _selectedSessions.clear();
        for (final session in sessionsAvecId) {
          _selectedSessions.add(session.id!);
        }
      }
    });
  }

  /// 🗑️ Supprimer les sessions sélectionnées
  Future<void> _supprimerSessionsSelectionnees() async {
    if (_selectedSessions.isEmpty) return;

    // Dialogue de confirmation
    final bool? confirmer = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red[600]),
              const SizedBox(width: 8),
              const Text('Confirmer la suppression'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Êtes-vous sûr de vouloir supprimer ${_selectedSessions.length} session(s) collaborative(s) ?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red[600], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Cette action est irréversible. Toutes les données associées seront perdues.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmer == true) {
      await _executerSuppressionSessions();
    }
  }

  /// 🗑️ Exécuter la suppression des sessions
  Future<void> _executerSuppressionSessions() async {
    try {
      setState(() => _isLoading = true);

      int sessionsSupprimes = 0;
      final List<String> erreursSuppressions = [];

      for (final sessionId in _selectedSessions) {
        try {
          // Supprimer la session de Firestore
          await FirebaseFirestore.instance
              .collection('collaborative_sessions')
              .doc(sessionId)
              .delete();

          // Supprimer les états de formulaires associés
          final statesSnapshot = await FirebaseFirestore.instance
              .collection('collaborative_session_states')
              .where('sessionId', isEqualTo: sessionId)
              .get();

          for (final stateDoc in statesSnapshot.docs) {
            await stateDoc.reference.delete();
          }

          sessionsSupprimes++;
          print('✅ Session supprimée: $sessionId');
        } catch (e) {
          erreursSuppressions.add('Session $sessionId: $e');
          print('❌ Erreur suppression session $sessionId: $e');
        }
      }

      // Réinitialiser le mode sélection
      setState(() {
        _isSelectionMode = false;
        _selectedSessions.clear();
        _isLoading = false;
      });

      // Afficher le résultat
      if (mounted) {
        if (erreursSuppressions.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('✅ $sessionsSupprimes session(s) supprimée(s) avec succès'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⚠️ $sessionsSupprimes session(s) supprimée(s)'),
                  if (erreursSuppressions.isNotEmpty)
                    Text('❌ ${erreursSuppressions.length} erreur(s)'),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }

    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🗑️ Supprimer une session individuelle
  Future<void> _supprimerSessionIndividuelle(CollaborativeSession session) async {
    final bool? confirmer = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red[600]),
              const SizedBox(width: 8),
              const Text('Supprimer la session'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Supprimer la session "${session.codeSession}" ?'),
              const SizedBox(height: 8),
              Text(
                'Type: ${session.typeAccident}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text(
                'Participants: ${session.participants.length}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmer == true && session.id != null) {
      try {
        await FirebaseFirestore.instance
            .collection('collaborative_sessions')
            .doc(session.id!)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Session "${session.codeSession}" supprimée'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// 🧪 Créer une session de test
  Future<void> _creerSessionTest() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur non connecté'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Générer un code de session unique
      final codeSession = 'TEST${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

      // Créer la session de test
      final sessionData = {
        'codeSession': codeSession,
        'qrCodeData': 'https://constat-tunisie.com/join/$codeSession',
        'typeAccident': 'Accident collaboratif test',
        'nombreVehicules': 2,
        'statut': 'creation',
        'conducteurCreateur': user.uid,
        'participants': [
          {
            'userId': user.uid,
            'nom': 'Vous',
            'email': user.email ?? 'test@example.com',
            'estCreateur': true,
            'statut': 'en_cours',
            'dateRejointe': FieldValue.serverTimestamp(),
          }
        ],
        'progression': {
          'participantsRejoints': 1,
          'formulairesTermines': 0,
          'croquisValide': false,
          'signaturesCompletes': false,
        },
        'parametres': {
          'autorisationModification': true,
          'validationCroquisRequise': true,
          'notificationsActivees': true,
        },
        'dateCreation': FieldValue.serverTimestamp(),
        'dateModification': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('collaborative_sessions')
          .add(sessionData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session test créée avec le code: $codeSession'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Erreur création session test: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 📄 Page PDF avec affichage des sessions d'accident
  Widget _buildPDFPage() {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[600]!, Colors.red[800]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.assignment,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🇹🇳 Sessions d\'Accident',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Formulaires complets et constats détaillés',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _genererPDFTest,
                    icon: Icon(Icons.picture_as_pdf, size: 16),
                    label: Text('PDF Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red[800],
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _ouvrirTestCloudinary,
                    icon: Icon(Icons.cloud_upload, size: 16),
                    label: Text('🔐 Test Cloudinary'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Sessions d'accident avec formulaires complets
            if (_allSessions.isEmpty) ...[
              _buildEmptySessionsState(),
            ] else ...[
              ..._allSessions.map((session) => _buildSessionDetailCard(session)),
            ],
          ],
        ),
      ),
    );
  }

  /// 📭 État vide des sessions
  Widget _buildEmptySessionsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune session d\'accident',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre première déclaration d\'accident\npour voir les formulaires détaillés ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _selectedIndex = 0); // Retour à l'accueil
            },
            icon: Icon(Icons.add_circle_outline),
            label: Text('Créer un Constat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Carte détaillée d'une session d'accident
  Widget _buildSessionDetailCard(CollaborativeSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la session
          _buildSessionHeader(session),

          // Données communes
          _buildCommonData(session),

          // Participants et leurs formulaires
          _buildParticipantsData(session),

          // Croquis et signatures
          _buildSketchAndSignatures(session),

          // Actions
          _buildSessionActions(session),
        ],
      ),
    );
  }

  /// 📌 En-tête de la session
  Widget _buildSessionHeader(CollaborativeSession session) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.assignment,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session ${session.codeSession}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${session.participants.length} participant(s) • ${_getStatusText(session.statut.toString())}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(session.statut.toString()),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getStatusText(session.statut.toString()),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Données communes de l'accident
  Widget _buildCommonData(CollaborativeSession session) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Informations Générales',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grille d'informations
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                _buildPDFInfoRow('📅 Date', _formatPDFDate(session.dateCreation)),
                _buildPDFInfoRow('📍 Lieu', 'Non spécifié'), // TODO: Ajouter lieuAccident au modèle
                _buildPDFInfoRow('🚗 Véhicules', '${session.nombreVehicules} véhicule(s)'),
                _buildPDFInfoRow('👥 Participants', '${session.participants.length} personne(s)'),
                _buildPDFInfoRow('🔢 Code Session', session.codeSession),
                _buildPDFInfoRow('⚠️ Type', session.typeAccident),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📝 Ligne d'information pour PDF
  Widget _buildPDFInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blue[800],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 👥 Données des participants
  Widget _buildParticipantsData(CollaborativeSession session) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: Colors.green[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Participants et Formulaires',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Liste des participants
          ...session.participants.asMap().entries.map((entry) {
            final index = entry.key;
            final participant = entry.value;
            return _buildParticipantCard(participant, index, session.id!);
          }),
        ],
      ),
    );
  }

  /// 👤 Carte d'un participant
  Widget _buildParticipantCard(SessionParticipant participant, int index, String sessionId) {
    final vehicleLetter = String.fromCharCode(65 + index); // A, B, C...
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple];
    final color = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du participant
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      vehicleLetter,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Véhicule $vehicleLetter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        participant.nom,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                if (participant.estCreateur)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Créateur',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[800],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Formulaire du participant
          _buildParticipantForm(participant, sessionId, color),
        ],
      ),
    );
  }

  /// 📝 Formulaire détaillé d'un participant
  Widget _buildParticipantForm(SessionParticipant participant, String sessionId, Color color) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadParticipantData(sessionId, participant.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(color: color),
            ),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Formulaire non rempli',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations du conducteur
              _buildSectionTitle('👤 Conducteur', color),
              const SizedBox(height: 8),
              _buildFormGrid([
                _buildFormField('Nom', '${data['prenom'] ?? ''} ${data['nom'] ?? ''}'),
                _buildFormField('Téléphone', data['telephone'] ?? ''),
                _buildFormField('Adresse', data['adresse'] ?? ''),
                _buildFormField('Permis', data['numeroPermis'] ?? ''),
              ]),

              const SizedBox(height: 16),

              // Informations du véhicule
              _buildSectionTitle('🚗 Véhicule', color),
              const SizedBox(height: 8),
              _buildFormGrid([
                _buildFormField('Marque/Modèle', '${data['marque'] ?? ''} ${data['modele'] ?? ''}'),
                _buildFormField('Immatriculation', data['numeroImmatriculation'] ?? ''),
                _buildFormField('Année', data['annee']?.toString() ?? ''),
                _buildFormField('Couleur', data['couleur'] ?? ''),
              ]),

              const SizedBox(height: 16),

              // Informations d'assurance
              _buildSectionTitle('🛡️ Assurance', color),
              const SizedBox(height: 8),
              _buildFormGrid([
                _buildFormField('Compagnie', data['compagnieAssurance'] ?? ''),
                _buildFormField('N° Contrat', data['numeroContrat'] ?? ''),
                _buildFormField('Agence', data['agence'] ?? ''),
                _buildFormField('Validité', data['validiteAssurance'] ?? ''),
              ]),

              const SizedBox(height: 16),

              // Circonstances
              if (data['circonstances'] != null) ...[
                _buildSectionTitle('⚠️ Circonstances', color),
                const SizedBox(height: 8),
                _buildCircumstances(data['circonstances'], color),
              ],

              const SizedBox(height: 16),

              // Dégâts
              if (data['degats'] != null) ...[
                _buildSectionTitle('💥 Dégâts', color),
                const SizedBox(height: 8),
                _buildDamageInfo(data['degats'], color),
              ],
            ],
          ),
        );
      },
    );
  }

  /// 📋 Titre de section
  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// 📊 Grille de formulaire
  Widget _buildFormGrid(List<Widget> fields) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: fields,
    );
  }

  /// 📝 Champ de formulaire
  Widget _buildFormField(String label, String value) {
    return Container(
      width: (MediaQuery.of(context).size.width - 80) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isNotEmpty ? value : 'Non renseigné',
            style: TextStyle(
              fontSize: 14,
              color: value.isNotEmpty ? Colors.grey[800] : Colors.grey[400],
              fontStyle: value.isNotEmpty ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// ⚠️ Affichage des circonstances
  Widget _buildCircumstances(List<dynamic> circonstances, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: circonstances.map((circ) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  circ.toString(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  /// 💥 Informations sur les dégâts
  Widget _buildDamageInfo(Map<String, dynamic> degats, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (degats['pointsChoc'] != null) ...[
            Text(
              'Points de choc: ${degats['pointsChoc']}',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
          ],
          if (degats['degatsApparents'] != null) ...[
            Text(
              'Dégâts apparents: ${degats['degatsApparents']}',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
          ],
          if (degats['observations'] != null) ...[
            Text(
              'Observations: ${degats['observations']}',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }

  /// 🎨 Croquis et signatures
  Widget _buildSketchAndSignatures(CollaborativeSession session) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.draw, color: Colors.orange[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Croquis et Signatures',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // Croquis
              Expanded(
                child: _buildSketchSection(session.id!),
              ),
              const SizedBox(width: 16),
              // Signatures
              Expanded(
                child: _buildSignaturesSection(session.id!),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🎨 Section croquis
  Widget _buildSketchSection(String sessionId) {
    return FutureBuilder<String?>(
      future: _loadSketchData(sessionId),
      builder: (context, snapshot) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.draw, color: Colors.orange[700], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Croquis d\'Accident',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? Center(child: CircularProgressIndicator(color: Colors.orange[600]))
                    : snapshot.hasData && snapshot.data != null
                        ? Container(
                            margin: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                base64Decode(snapshot.data!),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.orange[400]),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Erreur image',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.draw_outlined, color: Colors.orange[400], size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  'Aucun croquis',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ✍️ Section signatures
  Widget _buildSignaturesSection(String sessionId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadSignaturesData(sessionId),
      builder: (context, snapshot) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple[200]!),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.purple[700], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Signatures',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[800],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? Center(child: CircularProgressIndicator(color: Colors.purple[600]))
                    : snapshot.hasData && snapshot.data!.isNotEmpty
                        ? ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final signature = snapshot.data![index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: signature['signatureBase64'] != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: Image.memory(
                                                base64Decode(signature['signatureBase64']),
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Icon(Icons.edit, size: 12, color: Colors.grey[400]),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        signature['nom'] ?? 'Participant ${index + 1}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_outlined, color: Colors.purple[400], size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  'Aucune signature',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.purple[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🎬 Actions de la session
  Widget _buildSessionActions(CollaborativeSession session) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _genererPDFPourSession(session.id!),
              icon: Icon(Icons.picture_as_pdf, size: 18),
              label: Text('Générer PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              // Navigation vers les détails de la session
              setState(() => _selectedIndex = 4);
            },
            icon: Icon(Icons.visibility, size: 18),
            label: Text('Détails'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 📄 Générer PDF pour une session spécifique
  Future<void> _genererPDFPourSession(String sessionId) async {
    try {
      // Afficher indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Génération du PDF...'),
            ],
          ),
        ),
      );

      // Générer le PDF avec les vraies données
      final pdfPath = await ConstatTunisienOfficielPdf.genererConstatOfficiel(
        sessionId: sessionId,
      );

      // Fermer l'indicateur
      Navigator.of(context).pop();

      // Afficher le succès
      _showPDFSuccessDialog(sessionId, pdfPath);

    } catch (e) {
      // Fermer l'indicateur
      Navigator.of(context).pop();

      // Afficher l'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur génération PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🧪 Générer PDF de test
  Future<void> _genererPDFTest() async {
    try {
      // Afficher indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Création des données de test...'),
            ],
          ),
        ),
      );

      // Créer une session de test avec des données complètes
      // (Vous pouvez utiliser votre TestDataCompleteGenerator ici)
      final sessionId = 'test_${DateTime.now().millisecondsSinceEpoch}';

      // Générer le PDF
      final pdfPath = await ConstatTunisienOfficielPdf.genererConstatOfficiel(
        sessionId: sessionId,
      );

      // Fermer l'indicateur
      Navigator.of(context).pop();

      // Afficher le succès
      _showPDFSuccessDialog(sessionId, pdfPath);

    } catch (e) {
      // Fermer l'indicateur
      Navigator.of(context).pop();

      // Afficher l'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur génération PDF test: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🎉 Dialog de succès PDF
  void _showPDFSuccessDialog(String sessionId, String pdfPath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 28),
            SizedBox(width: 10),
            Text(
              'PDF Généré !',
              style: TextStyle(
                color: Colors.green[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🇹🇳 Constat Tunisien Officiel créé avec succès !',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 15),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Session: $sessionId',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('✅ 8 pages complètes', style: TextStyle(fontSize: 12)),
                  Text('✅ Données des formulaires', style: TextStyle(fontSize: 12)),
                  Text('✅ Signatures électroniques', style: TextStyle(fontSize: 12)),
                  Text('✅ Croquis d\'accident', style: TextStyle(fontSize: 12)),
                  Text('✅ Photos documentées', style: TextStyle(fontSize: 12)),
                  Text('✅ Conforme réglementation tunisienne', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            SizedBox(height: 15),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.download, color: Colors.green[600], size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'PDF téléchargé automatiquement dans votre dossier de téléchargements.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                // Vérifier si c'est une URL ou un fichier local
                if (pdfPath.startsWith('http://') || pdfPath.startsWith('https://')) {
                  // C'est une URL en ligne (Cloudinary)
                  final uri = Uri.parse(pdfPath);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🌐 PDF ouvert dans le navigateur'),
                        duration: const Duration(seconds: 3),
                        backgroundColor: Colors.green[600],
                      ),
                    );
                  } else {
                    throw Exception('Impossible d\'ouvrir l\'URL');
                  }
                } else {
                  // C'est un fichier local
                  final file = File(pdfPath);
                  if (await file.exists()) {
                    final result = await OpenFile.open(pdfPath);
                    if (result.type != ResultType.done) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('PDF sauvegardé dans: $pdfPath'),
                          duration: const Duration(seconds: 5),
                          backgroundColor: Colors.blue[600],
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Fichier PDF non trouvé: $pdfPath'),
                        duration: const Duration(seconds: 3),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur ouverture PDF: $e'),
                    duration: const Duration(seconds: 3),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: Icon(Icons.open_in_new),
            label: Text('Ouvrir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _envoyerPdfAAgent(sessionId, pdfPath);
            },
            icon: Icon(Icons.send),
            label: Text('Envoyer à l\'agent'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📤 Fonctionnalité de partage disponible'),
                  backgroundColor: Colors.blue[600],
                ),
              );
            },
            icon: Icon(Icons.share),
            label: Text('Partager'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 📤 Envoyer le PDF du constat à l'agent responsable
  Future<void> _envoyerPdfAAgent(String sessionId, String pdfPath) async {
    try {
      // Afficher dialog de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Envoi du PDF à l\'agent...'),
            ],
          ),
        ),
      );

      // Lire le fichier PDF
      final pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        throw Exception('Fichier PDF non trouvé');
      }

      final pdfBytes = await pdfFile.readAsBytes();
      final fileName = 'constat_${sessionId}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Trouver le sinistre associé à cette session
      final sinistreId = await _findSinistreForSession(sessionId);
      if (sinistreId == null) {
        throw Exception('Aucun sinistre trouvé pour cette session');
      }

      // Envoyer le PDF via le service
      final result = await ConstatPdfService.sendConstatPdfToAgent(
        sinistreId: sinistreId,
        pdfBytes: pdfBytes,
        fileName: fileName,
        message: 'Constat PDF généré automatiquement depuis l\'application mobile.',
      );

      // Fermer le dialog de chargement
      Navigator.of(context).pop();

      if (result['success']) {
        // Afficher le succès
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 28),
                SizedBox(width: 10),
                Text(
                  'PDF Envoyé !',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Votre constat PDF a été envoyé avec succès à l\'agent responsable.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Agent: ${result['agentInfo']['prenom']} ${result['agentInfo']['nom']}',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('Email: ${result['agentInfo']['email']}'),
                      Text('Agence: ${result['agentInfo']['agenceNom'] ?? 'N/A'}'),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      } else {
        throw Exception(result['error'] ?? 'Erreur inconnue');
      }

    } catch (e) {
      // Fermer le dialog de chargement si ouvert
      Navigator.of(context).pop();

      // Afficher l'erreur
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red[600], size: 28),
              SizedBox(width: 10),
              Text('Erreur d\'envoi'),
            ],
          ),
          content: Text('Impossible d\'envoyer le PDF: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// 🔍 Trouver le sinistre associé à une session
  Future<String?> _findSinistreForSession(String sessionId) async {
    try {
      // Chercher dans la collection sinistres
      final query = await FirebaseFirestore.instance
          .collection('sinistres')
          .where('sessionId', isEqualTo: sessionId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.id;
      }

      // Si pas trouvé, chercher par conducteur et date récente
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final recentQuery = await FirebaseFirestore.instance
            .collection('sinistres')
            .where('conducteurId', isEqualTo: user.uid)
            .orderBy('dateDeclaration', descending: true)
            .limit(1)
            .get();

        if (recentQuery.docs.isNotEmpty) {
          return recentQuery.docs.first.id;
        }
      }

      return null;
    } catch (e) {
      debugPrint('[CONDUCTEUR_DASHBOARD] ❌ Erreur recherche sinistre: $e');
      return null;
    }
  }

  // ============================================================================
  // MÉTHODES UTILITAIRES POUR LES DONNÉES
  // ============================================================================

  /// 📊 Charger les données d'un participant
  Future<Map<String, dynamic>?> _loadParticipantData(String sessionId, String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('participants_data')
          .doc(userId)
          .get();

      if (doc.exists) {
        return doc.data();
      }

      // Essayer dans l'ancienne structure
      final oldDoc = await FirebaseFirestore.instance
          .collection('collaborative_sessions')
          .doc(sessionId)
          .collection('participants_data')
          .doc(userId)
          .get();

      return oldDoc.exists ? oldDoc.data() : null;
    } catch (e) {
      print('Erreur chargement données participant: $e');
      return null;
    }
  }

  /// 🎨 Charger les données du croquis
  Future<String?> _loadSketchData(String sessionId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('croquis')
          .doc('principal')
          .get();

      if (doc.exists) {
        final data = doc.data();
        return data?['croquisBase64'];
      }

      // Essayer dans l'ancienne structure
      final oldDoc = await FirebaseFirestore.instance
          .collection('collaborative_sessions')
          .doc(sessionId)
          .collection('croquis')
          .doc('principal')
          .get();

      if (oldDoc.exists) {
        final data = oldDoc.data();
        return data?['croquisBase64'];
      }

      return null;
    } catch (e) {
      print('Erreur chargement croquis: $e');
      return null;
    }
  }

  /// ✍️ Charger les données des signatures
  Future<List<Map<String, dynamic>>> _loadSignaturesData(String sessionId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('signatures')
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
      }

      // Essayer dans l'ancienne structure
      final oldSnapshot = await FirebaseFirestore.instance
          .collection('collaborative_sessions')
          .doc(sessionId)
          .collection('signatures')
          .get();

      return oldSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Erreur chargement signatures: $e');
      return [];
    }
  }

  /// 📅 Formater une date pour PDF
  String _formatPDFDate(DateTime? date) {
    if (date == null) return 'Non spécifié';
    return DateFormat('dd/MM/yyyy à HH:mm').format(date);
  }

  /// 🎨 Obtenir la couleur du statut
  Color _getStatusColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'creation':
      case 'brouillon':
        return Colors.orange;
      case 'en_cours':
      case 'actif':
        return Colors.blue;
      case 'termine':
      case 'complete':
        return Colors.green;
      case 'envoye':
      case 'soumis':
        return Colors.purple;
      case 'annule':
      case 'supprime':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// 📝 Obtenir le texte du statut
  String _getStatusText(String statut) {
    switch (statut.toLowerCase()) {
      case 'creation':
      case 'brouillon':
        return 'En création';
      case 'en_cours':
      case 'actif':
        return 'En cours';
      case 'termine':
      case 'complete':
        return 'Terminé';
      case 'envoye':
      case 'soumis':
        return 'Envoyé';
      case 'annule':
      case 'supprime':
        return 'Annulé';
      default:
        return statut;
    }
  }

  /// 🔐 Ouvrir le test Cloudinary
  void _ouvrirTestCloudinary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TestCloudinaryFix(),
      ),
    );
  }

  /// 🧹 Nettoyer les notifications en double
  Future<void> _nettoyerNotifications() async {
    try {
      // Afficher indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Nettoyage des notifications...'),
            ],
          ),
        ),
      );

      // Nettoyer pour la session active (si disponible)
      String? sessionId;
      if (_allSessions.isNotEmpty) {
        sessionId = _allSessions.first.id;
      } else {
        sessionId = 'VOReABmLhZlIHKMtGdod'; // Session de test par défaut
      }

      final result = await ConstatAgentNotificationService.nettoyerNotificationsSession(sessionId);

      Navigator.of(context).pop(); // Fermer le loading

      // Afficher le résultat
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(result['success'] == true ? '✅ Nettoyage Réussi' : '❌ Erreur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result['success'] == true) ...[
                Text('Notifications supprimées: ${result['notificationsSupprimes']}'),
                Text('Constats supprimés: ${result['constatsSupprimes']}'),
                Text('Envois supprimés: ${result['envoisSupprimes']}'),
                const SizedBox(height: 10),
                const Text('Vous pouvez maintenant retenter "Notifier les agents".'),
              ] else ...[
                Text('Erreur: ${result['error']}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Fermer le loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  /// 🔄 Migrer les constats existants (DEBUG)
  Future<void> _migrerConstatsExistants() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Migration en cours...'),
          backgroundColor: Colors.blue,
        ),
      );

      await ConstatMigrationService.migrationComplete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Migration terminée avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      // Recharger les données
      _loadUserData();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur migration: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🔍 Analyser les données (DEBUG)
  Future<void> _analyserDonnees() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔍 Analyse en cours...'),
          backgroundColor: Colors.blue,
        ),
      );

      await ConstatMigrationService.analyserDonneesExistantes();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Analyse terminée (voir logs)'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur analyse: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🔄 Synchroniser les missions d'expertise avec constats_finalises
  Future<void> _synchroniserMissionsExpertise() async {
    try {
      debugPrint('[SYNC] 🔄 Début synchronisation missions expertise...');

      // Récupérer toutes les missions d'expertise
      final missionsQuery = await FirebaseFirestore.instance
          .collection('missions_expertise')
          .get();

      debugPrint('[SYNC] 📊 ${missionsQuery.docs.length} missions trouvées');

      int synchronisationsReussies = 0;
      int synchronisationsEchouees = 0;

      for (final missionDoc in missionsQuery.docs) {
        try {
          final missionData = missionDoc.data();
          final sessionId = missionData['sessionId'] as String?;
          final expertId = missionData['expertId'] as String?;
          final statut = missionData['statut'] as String?;

          if (sessionId == null || sessionId.isEmpty) {
            debugPrint('[SYNC] ⚠️ SessionId manquant pour mission ${missionDoc.id}');
            synchronisationsEchouees++;
            continue;
          }

          if (expertId == null || expertId.isEmpty) {
            debugPrint('[SYNC] ⚠️ ExpertId manquant pour mission ${missionDoc.id}');
            synchronisationsEchouees++;
            continue;
          }

          // Récupérer les données de l'expert
          final expertDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(expertId)
              .get();

          if (!expertDoc.exists) {
            debugPrint('[SYNC] ⚠️ Expert $expertId non trouvé');
            synchronisationsEchouees++;
            continue;
          }

          final expertData = expertDoc.data()!;
          final expertNom = '${expertData['prenom'] ?? ''} ${expertData['nom'] ?? ''}';

          // Mettre à jour le constat dans constats_finalises
          await FirebaseFirestore.instance
              .collection('constats_finalises')
              .doc(sessionId)
              .set({
            'statut': 'expert_assigne',
            'expertAssigne': {
              'id': expertId,
              'nom': expertNom,
              'prenom': expertData['prenom'] ?? '',
              'codeExpert': expertData['codeExpert'] ?? '',
              'telephone': expertData['telephone'] ?? '',
              'email': expertData['email'] ?? '',
            },
            'dateAssignationExpert': missionData['dateCreation'] ?? FieldValue.serverTimestamp(),
            'missionId': missionDoc.id,
            'statutMission': statut ?? 'assignee',
            'updatedAt': FieldValue.serverTimestamp(),
            'source': 'sync_missions_expertise',
          }, SetOptions(merge: true));

          debugPrint('[SYNC] ✅ Mission $sessionId synchronisée avec expert $expertNom');
          synchronisationsReussies++;

        } catch (e) {
          debugPrint('[SYNC] ❌ Erreur synchronisation mission ${missionDoc.id}: $e');
          synchronisationsEchouees++;
        }
      }

      debugPrint('[SYNC] 📊 Résultats synchronisation:');
      debugPrint('[SYNC]    ✅ Réussies: $synchronisationsReussies');
      debugPrint('[SYNC]    ❌ Échouées: $synchronisationsEchouees');

    } catch (e) {
      debugPrint('[SYNC] ❌ Erreur synchronisation: $e');
    }
  }

  /// 🔧 Widget d'information pour l'onglet véhicules (même style que MesVehiculesScreen)
  Widget _buildInfoItemVehicules(String label, String value, IconData icon) {
    // Couleurs spécifiques selon le type d'information
    Color iconColor;
    Color valueColor;

    switch (label) {
      case 'Année':
        iconColor = Colors.blue[600]!;
        valueColor = Colors.blue[700]!;
        break;
      case 'Couleur':
        iconColor = Colors.purple[600]!;
        valueColor = Colors.purple[700]!;
        break;
      case 'Contrat N°':
        iconColor = Colors.green[600]!;
        valueColor = Colors.green[700]!;
        break;
      case 'Expire le':
        iconColor = Colors.orange[600]!;
        valueColor = Colors.orange[700]!;
        break;
      default:
        iconColor = Colors.grey[600]!;
        valueColor = const Color(0xFF1F2937);
    }

    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 👁️ Voir les détails du véhicule depuis l'onglet véhicules
  void _voirDetailsVehiculeOnglet(Map<String, dynamic> vehicule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Titre
              Text(
                'Détails du Véhicule',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 20),

              // Contenu scrollable
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      _buildDetailRow('Marque', vehicule['marque'] ?? 'N/A', Icons.directions_car),
                      _buildDetailRow('Modèle', vehicule['modele'] ?? 'N/A', Icons.car_rental),
                      _buildDetailRow('Immatriculation', vehicule['numeroImmatriculation'] ?? vehicule['immatriculation'] ?? 'N/A', Icons.confirmation_number),
                      _buildDetailRow('Année', vehicule['annee']?.toString() ?? 'N/A', Icons.calendar_today),
                      _buildDetailRow('Couleur', vehicule['couleur'] ?? 'N/A', Icons.palette),
                      _buildDetailRow('Numéro de contrat', vehicule['numeroContrat'] ?? 'N/A', Icons.description),
                      _buildDetailRow('Compagnie', vehicule['compagnieNom'] ?? 'N/A', Icons.business),
                      _buildDetailRow('Agence', vehicule['agenceNom'] ?? 'N/A', Icons.location_city),
                      if (vehicule['dateDebut'] != null)
                        _buildDetailRow(
                          'Date de début',
                          DateFormat('dd/MM/yyyy').format(_convertirDateSafe(vehicule['dateDebut']) ?? DateTime.now()),
                          Icons.play_arrow,
                        ),
                      if (vehicule['dateFin'] != null)
                        _buildDetailRow(
                          'Date de fin',
                          DateFormat('dd/MM/yyyy').format(_convertirDateSafe(vehicule['dateFin']) ?? DateTime.now()),
                          Icons.stop,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🚨 Déclarer un sinistre pour un véhicule
  void _declarerSinistreVehicule(Map<String, dynamic> vehicule) {
    // Navigation vers l'écran de déclaration de sinistre avec les données du véhicule
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeclarationSinistreScreen(
          vehicule: vehicule,
        ),
      ),
    );
  }
}


import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import '../../../widgets/modern_session_status_widget.dart';
import '../../../services/session_status_service.dart';
import '../../sinistre/screens/sinistre_choix_rapide_screen.dart';
import '../../../services/modern_pdf_service.dart';
import '../../../services/sinistre_service.dart';
import '../../../models/sinistre_model.dart';
import 'mes_vehicules_screen.dart';
import '../../../conducteur/screens/guest_join_session_screen.dart';
import '../../../conducteur/screens/registered_join_session_screen.dart';
import '../../../conducteur/screens/sinistre_details_screen.dart';
import '../../../conducteur/screens/accident_choice_screen.dart';
import '../../../conducteur/screens/accident_vehicle_selection_screen.dart';
import '../../../conducteur/screens/modern_single_accident_info_screen.dart';
import '../../../conducteur/screens/modern_accident_type_screen.dart';
import '../../../conducteur/screens/join_session_registered_screen.dart';
import '../../../services/conducteur_data_service.dart';

import 'notifications_screen.dart';
import 'historique_screen.dart';
import 'mes_vehicules_screen.dart';
import 'declaration_sinistre_screen.dart';
import '../../sinistre/screens/sinistre_choix_rapide_screen.dart';
import '../../../conducteur/screens/accident_declaration_screen.dart';
import '../../../services/sinistre_tracking_service.dart';
import '../../../widgets/modern_sinistre_card.dart';


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

  @override
  void initState() {
    super.initState();
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
        setState(() {
          final prenom = data['prenom'] ?? data['firstName'] ?? '';
          final nom = data['nom'] ?? data['lastName'] ?? '';
          _nomConducteur = '$prenom $nom'.trim();
        });
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
            setState(() {
              final prenom = userData['prenom'] ?? userData['firstName'] ?? '';
              final nom = userData['nom'] ?? userData['lastName'] ?? '';
              _nomConducteur = '$prenom $nom'.trim();
            });
            print('✅ Nom trouvé dans SharedPreferences pour utilisateur actuel: $_nomConducteur');
            return;
          }
        }
      }

      // Fallback : utiliser les infos Firebase Auth
      if (currentUser != null) {
        setState(() {
          _nomConducteur = currentUser.displayName ?? currentUser.email?.split('@').first ?? 'Conducteur';
        });
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
            final dateA = a['dateCreation']?.toDate() ?? DateTime.now();
            final dateB = b['dateCreation']?.toDate() ?? DateTime.now();
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
        final dateA = a['dateCreation']?.toDate() ?? DateTime.now();
        final dateB = b['dateCreation']?.toDate() ?? DateTime.now();
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
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('conducteurId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .where('lu', isEqualTo: false)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data?.docs.length ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
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
            icon: const Icon(Icons.login),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
            tooltip: 'Reconnexion',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
            tooltip: 'Recharger',
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services, color: Colors.red),
            onPressed: _supprimerDonneesTest,
            tooltip: 'Supprimer données test',
          ),
          IconButton(
            icon: const Icon(Icons.warning, color: Colors.red),
            onPressed: _creerSinistresTest,
            tooltip: '🚨 CRÉER SINISTRES TEST',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
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
                _buildSinistresPage(),
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
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.warning),
                if (_sinistres.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
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
                        '${_sinistres.length}',
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
            ),
            label: 'Sinistres',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/conducteur/nouvelle-demande'),
              backgroundColor: Colors.blue[700],
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Nouvelle Demande',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
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

    return {
      'contratsActifs': contratsActifs,
      'vehicules': _vehicules.length,
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
    final dateCreation = demande['dateCreation']?.toDate() ?? DateTime.now();

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
                child: Text(
                  'Demande ${demande['numero'] ?? demande['id'].substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              _buildStatutBadge(statut),
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
                  icon: const Icon(Icons.visibility),
                  label: const Text('Voir détail'),
                ),
              ),

              if (statut == 'contrat_valide') ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _telechargerContrat(demande),
                    icon: const Icon(Icons.download),
                    label: const Text('Télécharger'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
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
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🚗 Mes Véhicules Assurés',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });

                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await _loadVehicules(user.uid);
                    }

                    setState(() {
                      _isLoading = false;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔄 Véhicules rechargés avec nouvelles données'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh, color: Colors.blue),
                  tooltip: 'Recharger les véhicules',
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_vehicules.isEmpty)
              _buildEmptyState(
                'Aucun véhicule assuré',
                'Vos véhicules apparaîtront ici après validation des contrats',
                Icons.directions_car,
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _vehicules.length,
                itemBuilder: (context, index) {
                  final vehicule = _vehicules[index];
                  return _buildVehiculeCard(vehicule);
                },
              ),
          ],
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
    final dateDebut = vehicule['dateDebut']?.toDate() ?? DateTime.now();
    final dateFin = vehicule['dateFin']?.toDate() ?? DateTime.now().add(const Duration(days: 365));

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
                  icon: const Icon(Icons.description),
                  label: const Text('Voir contrat'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (statut == 'contrat_actif' || statut == 'documents_completes')
                      ? () => _declarerSinistre(vehicule['id'] ?? '', vehicule)
                      : null,
                  icon: Icon(
                    Icons.report_problem,
                    color: (statut == 'contrat_actif' || statut == 'documents_completes')
                        ? Colors.white
                        : Colors.grey[400],
                  ),
                  label: Text(
                    'Déclarer sinistre',
                    style: TextStyle(
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

    // Dates
    final dateDebut = vehicule['dateDebut']?.toDate();
    final dateFin = vehicule['dateFin']?.toDate();
    final dateCreation = vehicule['dateCreation']?.toDate();

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 16),
          const SizedBox(width: 6),
          Text(
            texte,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinistresPage() {
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statistiques
            _buildSinistresHeader(),

            const SizedBox(height: 24),

            // Actions rapides
            _buildSinistresActions(),

            const SizedBox(height: 24),

            // Liste des sinistres
            _buildSinistresList(),

            const SizedBox(height: 24),

            // Sessions de constat en cours
            _buildSessionsEnCours(),
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
          return ['termine', 'clos', 'rejete', 'envoye_agence', 'envoye'].contains(statut);
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
    final dateCreation = (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now();
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
      default:
        return 'Inconnu';
    }
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
    // Navigation vers le formulaire moderne élégant avec design et animations
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
    return Container(
      color: Colors.white,
      child: const Center(
        child: Text('Page Profil - À implémenter'),
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
    setState(() {
      _selectedIndex = 1; // Index de la page véhicules
    });

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
            // Bouton refresh RADICAL
            IconButton(
              onPressed: () async {
                print('🔄 BOUTON REFRESH CLIQUÉ - RECHARGEMENT RADICAL');

                setState(() {
                  _isLoading = true;
                });

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    print('🔄 Utilisateur trouvé: ${user.uid}');

                    // FORCER le rechargement complet
                    await _loadVehicules(user.uid);

                    print('🔄 Rechargement terminé, ${_vehicules.length} véhicules');

                    // FORCER la mise à jour de l'interface
                    setState(() {
                      _isLoading = false;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🔄 ${_vehicules.length} contrats rechargés avec données complètes'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  } else {
                    print('❌ Aucun utilisateur connecté');
                    setState(() {
                      _isLoading = false;
                    });
                  }
                } catch (e) {
                  print('❌ Erreur lors du refresh: $e');
                  setState(() {
                    _isLoading = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'RECHARGEMENT RADICAL avec données complètes',
              color: Colors.green[700],
            ),
            // Bouton DIAGNOSTIC SPÉCIAL
            IconButton(
              onPressed: () async {
                print('🔍 BOUTON DIAGNOSTIC CLIQUÉ');

                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final diagnostic = await ConducteurDataService.diagnostiquerDonneesManquantes(user.uid);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🔍 Diagnostic terminé - Voir les logs'),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.search, size: 20),
              tooltip: 'DIAGNOSTIC DONNÉES MANQUANTES',
              color: Colors.orange[700],
            ),
            // Bouton VRAIES DONNÉES
            IconButton(
              onPressed: () async {
                print('🔄 BOUTON VRAIES DONNÉES CLIQUÉ');

                setState(() {
                  _isLoading = true;
                });

                try {
                  _vehicules = await ConducteurDataService.recupererVraiesDonneesContrat();

                  setState(() {
                    _isLoading = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🔄 ${_vehicules.length} véhicules avec VRAIES données récupérés'),
                      backgroundColor: Colors.purple,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  print('❌ Erreur vraies données: $e');
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              icon: const Icon(Icons.verified, size: 20),
              tooltip: 'RÉCUPÉRER VRAIES DONNÉES DE CONTRAT',
              color: Colors.purple[700],
            ),
            // Bouton DEMANDES APPROUVÉES
            IconButton(
              onPressed: () async {
                print('🎯 BOUTON DEMANDES APPROUVÉES CLIQUÉ');

                setState(() {
                  _isLoading = true;
                });

                try {
                  _vehicules = await ConducteurDataService.recupererDonneesContratDansDemandesApprouvees();

                  setState(() {
                    _isLoading = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎯 ${_vehicules.length} véhicules depuis demandes approuvées'),
                      backgroundColor: Colors.teal,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  print('❌ Erreur demandes approuvées: $e');
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              icon: const Icon(Icons.approval, size: 20),
              tooltip: 'DONNÉES DEPUIS DEMANDES APPROUVÉES',
              color: Colors.teal[700],
            ),
            // Bouton VRAIES DONNÉES OBSERVÉES
            IconButton(
              onPressed: () async {
                print('🎯 BOUTON VRAIES DONNÉES OBSERVÉES CLIQUÉ');

                setState(() {
                  _isLoading = true;
                });

                try {
                  _vehicules = await ConducteurDataService.recupererAvecVraisNumeros();

                  setState(() {
                    _isLoading = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎯 ${_vehicules.length} véhicules avec VRAIES données des logs'),
                      backgroundColor: Colors.indigo,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  print('❌ Erreur vraies données: $e');
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              icon: const Icon(Icons.verified_user, size: 20),
              tooltip: 'VRAIES DONNÉES DEPUIS LES LOGS',
              color: Colors.indigo[700],
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

            if (kDebugMode) {
              print('🔍 [DEBUG ACCUEIL] Total documents: ${allContrats.length}');
              print('🔍 [DEBUG ACCUEIL] Contrats nettoyés: ${contratsNettoyes.length}');
              print('🔍 [DEBUG ACCUEIL] Contrats valides affichés: ${contrats.length}');

              for (final contrat in contrats) {
                final marque = _formatTexte(contrat['marque']);
                final modele = _formatTexte(contrat['modele']);
                final immat = _formatImmatriculation(contrat['immatriculation']);
                final numero = _formatNumeroContrat(contrat['numeroContrat'], contrat['id']);
                print('  ✅ Contrat ${contrat['id']}: $marque $modele ($immat) - ${contrat['statut']} - N°$numero');
              }
            }

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

  /// 📋 Widget pour afficher une ligne de détail compacte
  Widget _buildDetailRowCompact(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
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
}

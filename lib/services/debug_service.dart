import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 🔧 Service de debug pour diagnostiquer les problèmes
class DebugService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔍 Diagnostiquer les problèmes d'auto-remplissage
  static Future<void> debugAutoFill() async {
    print('\n=== 🔍 DEBUG AUTO-REMPLISSAGE ===');
    
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ Aucun utilisateur connecté');
      return;
    }

    print('👤 Utilisateur connecté:');
    print('  - UID: ${user.uid}');
    print('  - Email: ${user.email}');
    print('  - DisplayName: ${user.displayName}');

    // Vérifier collection 'users'
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        print('✅ Trouvé dans collection "users":');
        print('  - Données: ${userDoc.data()}');
      } else {
        print('❌ Pas trouvé dans collection "users"');
      }
    } catch (e) {
      print('❌ Erreur collection "users": $e');
    }

    // Vérifier collection 'conducteurs'
    try {
      final conducteurDoc = await _firestore.collection('conducteurs').doc(user.uid).get();
      if (conducteurDoc.exists) {
        print('✅ Trouvé dans collection "conducteurs":');
        print('  - Données: ${conducteurDoc.data()}');
      } else {
        print('❌ Pas trouvé dans collection "conducteurs"');
      }
    } catch (e) {
      print('❌ Erreur collection "conducteurs": $e');
    }

    // Vérifier SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.contains('conducteur')).toList();
      print('📱 SharedPreferences:');
      print('  - Clés trouvées: $keys');
      
      for (String key in keys) {
        final data = prefs.getString(key);
        if (data != null) {
          try {
            final userData = json.decode(data);
            print('  - $key: $userData');

            // Analyser les problèmes potentiels
            final nom = userData['nom'] ?? '';
            final prenom = userData['prenom'] ?? '';
            if (nom.isEmpty && prenom.isNotEmpty && prenom.contains(' ')) {
              print('  ⚠️ PROBLÈME DÉTECTÉ: Nom complet dans le champ prénom');
              final parts = prenom.split(' ');
              print('  🔧 Suggestion: prénom="${parts.first}", nom="${parts.sublist(1).join(' ')}"');
            }
          } catch (e) {
            print('  - $key: [Erreur décodage] $data');
          }
        }
      }
    } catch (e) {
      print('❌ Erreur SharedPreferences: $e');
    }

    print('=== FIN DEBUG AUTO-REMPLISSAGE ===\n');
  }

  /// 🔍 Diagnostiquer les problèmes d'affichage utilisateur
  static Future<void> debugUserDisplay() async {
    print('\n=== 🔍 DEBUG AFFICHAGE UTILISATEUR ===');
    
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ Aucun utilisateur connecté');
      return;
    }

    print('👤 Firebase Auth:');
    print('  - UID: ${user.uid}');
    print('  - Email: ${user.email}');
    print('  - DisplayName: ${user.displayName}');

    // Vérifier si les données correspondent
    await debugAutoFill();

    print('=== FIN DEBUG AFFICHAGE UTILISATEUR ===\n');
  }

  /// 🔍 Diagnostiquer les problèmes de demandes admin agence
  static Future<void> debugAdminAgenceDemandes(String agenceId) async {
    print('\n=== 🔍 DEBUG DEMANDES ADMIN AGENCE ===');
    print('🏢 Agence ID: $agenceId');

    try {
      // Compter toutes les demandes
      final allDemandes = await _firestore.collection('demandes_contrats').get();
      print('📊 Total demandes dans la base: ${allDemandes.docs.length}');

      // Compter les demandes pour cette agence
      final agenceDemandes = await _firestore
          .collection('demandes_contrats')
          .where('agenceId', isEqualTo: agenceId)
          .get();
      print('📊 Demandes pour agence $agenceId: ${agenceDemandes.docs.length}');

      // Afficher quelques exemples
      print('📋 Exemples de demandes:');
      for (int i = 0; i < allDemandes.docs.length && i < 5; i++) {
        final doc = allDemandes.docs[i];
        final data = doc.data();
        print('  - ${doc.id}: agenceId=${data['agenceId']}, statut=${data['statut']}');
      }

      // Vérifier les statuts disponibles
      final statuts = <String>{};
      for (final doc in allDemandes.docs) {
        final statut = doc.data()['statut'] as String?;
        if (statut != null) statuts.add(statut);
      }
      print('📊 Statuts trouvés: $statuts');

      // Vérifier les agenceIds disponibles
      final agenceIds = <String>{};
      for (final doc in allDemandes.docs) {
        final agenceId = doc.data()['agenceId'] as String?;
        if (agenceId != null) agenceIds.add(agenceId);
      }
      print('📊 AgenceIds trouvés: $agenceIds');

    } catch (e) {
      print('❌ Erreur debug demandes: $e');
    }

    print('=== FIN DEBUG DEMANDES ADMIN AGENCE ===\n');
  }

  /// 🔧 Nettoyer les données en cache
  static Future<void> clearCache() async {
    print('\n=== 🔧 NETTOYAGE CACHE ===');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.contains('conducteur')).toList();
      
      for (String key in keys) {
        await prefs.remove(key);
        print('🗑️ Supprimé: $key');
      }
      
      print('✅ Cache nettoyé');
    } catch (e) {
      print('❌ Erreur nettoyage cache: $e');
    }
    
    print('=== FIN NETTOYAGE CACHE ===\n');
  }

  /// 🔧 Forcer la reconnexion
  static Future<void> forceReconnect() async {
    print('\n=== 🔧 FORCE RECONNEXION ===');
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        print('📧 Email actuel: ${user.email}');
        await _auth.signOut();
        print('🚪 Déconnexion effectuée');
      }
    } catch (e) {
      print('❌ Erreur reconnexion: $e');
    }
    
    print('=== FIN FORCE RECONNEXION ===\n');
  }

  /// 🔧 Créer des données de test pour les demandes
  static Future<void> createTestDemandes(String agenceId) async {
    print('\n=== 🔧 CRÉATION DONNÉES TEST ===');
    print('🏢 Agence ID: $agenceId');

    try {
      final testDemandes = [
        {
          'numero': 'TEST001',
          'agenceId': agenceId,
          'statut': 'en_attente',
          'nom': 'Test',
          'prenom': 'Utilisateur',
          'email': 'test@example.com',
          'marque': 'Toyota',
          'modele': 'Corolla',
          'dateCreation': FieldValue.serverTimestamp(),
          'isTestData': true,
        },
        {
          'numero': 'TEST002',
          'agenceId': agenceId,
          'statut': 'approuve',
          'nom': 'Test2',
          'prenom': 'Utilisateur2',
          'email': 'test2@example.com',
          'marque': 'Peugeot',
          'modele': '208',
          'dateCreation': FieldValue.serverTimestamp(),
          'isTestData': true,
        },
        {
          'numero': 'TEST003',
          'agenceId': agenceId,
          'statut': 'rejete',
          'nom': 'Test3',
          'prenom': 'Utilisateur3',
          'email': 'test3@example.com',
          'marque': 'Renault',
          'modele': 'Clio',
          'dateCreation': FieldValue.serverTimestamp(),
          'isTestData': true,
        },
      ];

      for (final demande in testDemandes) {
        await _firestore.collection('demandes_contrats').add(demande);
        print('✅ Créé: ${demande['numero']} - ${demande['statut']}');
      }

      print('✅ Données de test créées');
    } catch (e) {
      print('❌ Erreur création test: $e');
    }

    print('=== FIN CRÉATION DONNÉES TEST ===\n');
  }

  /// 🔧 Corriger les agenceId des demandes existantes
  static Future<void> fixDemandesAgenceId(String correctAgenceId) async {
    print('\n=== 🔧 CORRECTION AGENCE ID ===');
    print('🏢 Agence ID correct: $correctAgenceId');

    try {
      // Récupérer toutes les demandes sans agenceId ou avec un mauvais agenceId
      final allDemandes = await _firestore.collection('demandes_contrats').get();

      int corrected = 0;
      for (final doc in allDemandes.docs) {
        final data = doc.data();
        final currentAgenceId = data['agenceId'] as String?;

        // Si pas d'agenceId ou agenceId différent, corriger
        if (currentAgenceId == null || currentAgenceId.isEmpty) {
          await doc.reference.update({'agenceId': correctAgenceId});
          print('✅ Corrigé ${doc.id}: ajouté agenceId $correctAgenceId');
          corrected++;
        }
      }

      print('✅ $corrected demandes corrigées');
    } catch (e) {
      print('❌ Erreur correction: $e');
    }

    print('=== FIN CORRECTION AGENCE ID ===\n');
  }

  /// 🔧 Créer des agents de test pour une agence
  static Future<void> createTestAgents(String agenceId) async {
    print('\n=== 🔧 CRÉATION AGENTS TEST ===');
    print('🏢 Agence ID: $agenceId');

    try {
      final testAgents = [
        {
          'nom': 'Dupont',
          'prenom': 'Jean',
          'email': 'jean.dupont@agence.com',
          'telephone': '+216 98 123 456',
          'agenceId': agenceId,
          'statut': 'actif',
          'specialites': ['Toyota', 'Peugeot'],
          'dateEmbauche': FieldValue.serverTimestamp(),
          'isTestData': true,
        },
        {
          'nom': 'Martin',
          'prenom': 'Marie',
          'email': 'marie.martin@agence.com',
          'telephone': '+216 98 234 567',
          'agenceId': agenceId,
          'statut': 'actif',
          'specialites': ['BMW', 'Mercedes'],
          'dateEmbauche': FieldValue.serverTimestamp(),
          'isTestData': true,
        },
        {
          'nom': 'Benali',
          'prenom': 'Ahmed',
          'email': 'ahmed.benali@agence.com',
          'telephone': '+216 98 345 678',
          'agenceId': agenceId,
          'statut': 'actif',
          'specialites': ['Renault', 'Citroën'],
          'dateEmbauche': FieldValue.serverTimestamp(),
          'isTestData': true,
        },
      ];

      for (final agent in testAgents) {
        await _firestore.collection('agents_assurance').add(agent);
        print('✅ Créé: ${agent['prenom']} ${agent['nom']}');
      }

      print('✅ ${testAgents.length} agents de test créés');
    } catch (e) {
      print('❌ Erreur création agents test: $e');
    }

    print('=== FIN CRÉATION AGENTS TEST ===\n');
  }

  /// 🗑️ Supprimer les données de test
  static Future<void> deleteTestData() async {
    print('\n=== 🗑️ SUPPRESSION DONNÉES TEST ===');

    try {
      final testDocs = await _firestore
          .collection('demandes_contrats')
          .where('isTestData', isEqualTo: true)
          .get();

      for (final doc in testDocs.docs) {
        await doc.reference.delete();
        print('🗑️ Supprimé: ${doc.id}');
      }

      print('✅ Données de test supprimées');
    } catch (e) {
      print('❌ Erreur suppression test: $e');
    }

    print('=== FIN SUPPRESSION DONNÉES TEST ===\n');
  }
}

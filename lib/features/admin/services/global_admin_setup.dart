import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🌍 Service d'initialisation globale du système admin
class GlobalAdminSetup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🚀 Initialiser TOUT le système admin
  static Future<bool> initializeCompleteSystem() async {
    try {
      print('🌍 Début initialisation système complet...');

      // 1. Nettoyer les données existantes
      await _cleanExistingData();

      // 2. Créer les compagnies d'assurance
      await _createCompagnies();

      // 3. Créer les agences
      await _createAgences();

      // 4. Créer tous les comptes admin avec Firebase Auth
      await _createAllAdminAccounts();

      // 5. Créer des données de test
      await _createTestData();

      print('✅ Système complet initialisé !');
      return true;
    } catch (e) {
      print('❌ Erreur initialisation système: $e');
      return false;
    }
  }

  /// 🧹 Nettoyer les données existantes
  static Future<void> _cleanExistingData() async {
    final collections = [
      'compagnies_assurance',
      'agences_assurance', 
      'admins_users',
      'demandes_agents',
      'agents_assurance',
    ];

    for (final collection in collections) {
      final snapshot = await _firestore.collection(collection).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      print('🧹 Collection $collection nettoyée');
    }
  }

  /// 🏢 Créer les compagnies d'assurance tunisiennes
  static Future<void> _createCompagnies() async {
    final compagnies = [
      // Compagnies principales
      {
        'id': 'star_assurance',
        'nom': 'STAR Assurance',
        'logo': 'https://www.star.com.tn/images/logo.png',
        'adresse': 'Avenue Habib Bourguiba, Tunis 1001',
        'telephone': '+216 71 123 456',
        'email': 'contact@star.tn',
        'adminEmail': 'admin.star@constat-tunisie.tn',
        'dateCreation': DateTime.now().millisecondsSinceEpoch,
        'active': true,
        'secteur': 'Assurance Automobile',
        'fondee': 1960,
      },
      {
        'id': 'maghrebia_assurance',
        'nom': 'Maghrebia Assurance',
        'logo': 'https://www.maghrebia.com.tn/images/logo.png',
        'adresse': 'Rue de la Liberté, Tunis 1002',
        'telephone': '+216 71 234 567',
        'email': 'contact@maghrebia.tn',
        'adminEmail': 'admin.maghrebia@constat-tunisie.tn',
        'dateCreation': DateTime.now().millisecondsSinceEpoch,
        'active': true,
        'secteur': 'Assurance Automobile',
        'fondee': 1962,
      },
      {
        'id': 'gat_assurance',
        'nom': 'GAT Assurance',
        'logo': 'https://www.gat.com.tn/images/logo.png',
        'adresse': 'Avenue Mohamed V, Tunis 1003',
        'telephone': '+216 71 345 678',
        'email': 'contact@gat.tn',
        'adminEmail': 'admin.gat@constat-tunisie.tn',
        'dateCreation': DateTime.now().millisecondsSinceEpoch,
        'active': true,
        'secteur': 'Assurance Automobile',
        'fondee': 1958,
      },
      {
        'id': 'bh_assurance',
        'nom': 'BH Assurance',
        'logo': 'https://www.bh.com.tn/images/logo.png',
        'adresse': 'Avenue de la République, Tunis 1004',
        'telephone': '+216 71 456 789',
        'email': 'contact@bh.tn',
        'adminEmail': 'admin.bh@constat-tunisie.tn',
        'dateCreation': DateTime.now().millisecondsSinceEpoch,
        'active': true,
        'secteur': 'Assurance Automobile',
        'fondee': 1965,
      },
      // Autres compagnies tunisiennes
      {
        'id': 'ctama_assurance',
        'nom': 'CTAMA',
        'logo': 'https://www.ctama.com.tn/images/logo.png',
        'adresse': 'Rue de Marseille, Tunis',
        'telephone': '+216 71 567 890',
        'email': 'contact@ctama.tn',
        'adminEmail': 'admin.ctama@constat-tunisie.tn',
        'dateCreation': DateTime.now().millisecondsSinceEpoch,
        'active': true,
        'secteur': 'Assurance Automobile',
        'fondee': 1958,
      },
      {
        'id': 'lloyd_tunisien',
        'nom': 'Lloyd Tunisien',
        'logo': 'https://www.lloyd.com.tn/images/logo.png',
        'adresse': 'Avenue de la Liberté, Tunis',
        'telephone': '+216 71 678 901',
        'email': 'contact@lloyd.tn',
        'adminEmail': 'admin.lloyd@constat-tunisie.tn',
        'dateCreation': DateTime.now().millisecondsSinceEpoch,
        'active': true,
        'secteur': 'Assurance Automobile',
        'fondee': 1949,
      },
      {
        'id': 'zitouna_takaful',
        'nom': 'Zitouna Takaful',
        'logo': 'https://www.zitouna-takaful.com.tn/images/logo.png',
        'adresse': 'Avenue Mohamed V, Tunis',
        'telephone': '+216 71 789 012',
        'email': 'contact@zitouna-takaful.tn',
        'adminEmail': 'admin.zitouna@constat-tunisie.tn',
        'dateCreation': DateTime.now().millisecondsSinceEpoch,
        'active': true,
        'secteur': 'Assurance Takaful',
        'fondee': 2010,
      },
      {
        'id': 'assurances_salim',
        'nom': 'Assurances Salim',
        'logo': 'https://www.salim.com.tn/images/logo.png',
        'adresse': 'Rue de Rome, Tunis',
        'telephone': '+216 71 890 123',
        'email': 'contact@salim.tn',
        'adminEmail': 'admin.salim@constat-tunisie.tn',
        'dateCreation': DateTime.now().millisecondsSinceEpoch,
        'active': true,
        'secteur': 'Assurance Automobile',
        'fondee': 1975,
      },
      {
        'id': 'carte_assurance',
        'nom': 'CARTE Assurance',
        'logo': 'https://www.carte.com.tn/images/logo.png',
        'adresse': 'Avenue Habib Thameur, Tunis',
        'telephone': '+216 71 901 234',
        'email': 'contact@carte.tn',
        'adminEmail': 'admin.carte@constat-tunisie.tn',
        'dateCreation': DateTime.now().millisecondsSinceEpoch,
        'active': true,
        'secteur': 'Assurance Automobile',
        'fondee': 1990,
      },
      {
        'id': 'attijari_assurance',
        'nom': 'Attijari Assurance',
        'logo': 'https://www.attijari-assurance.com.tn/images/logo.png',
        'adresse': 'Avenue de France, Tunis',
        'telephone': '+216 71 012 345',
        'email': 'contact@attijari-assurance.tn',
        'adminEmail': 'admin.attijari@constat-tunisie.tn',
        'dateCreation': DateTime.now().millisecondsSinceEpoch,
        'active': true,
        'secteur': 'Assurance Automobile',
        'fondee': 2005,
      },
      {
        'id': 'comar_assurance',
        'nom': 'COMAR Assurance',
        'logo': 'https://www.comar.com.tn/images/logo.png',
        'adresse': 'Rue de la Kasbah, Tunis',
        'telephone': '+216 71 123 456',
        'email': 'contact@comar.tn',
        'adminEmail': 'admin.comar@constat-tunisie.tn',
        'dateCreation': DateTime.now().millisecondsSinceEpoch,
        'active': true,
        'secteur': 'Assurance Automobile',
        'fondee': 1967,
      },
      {
        'id': 'tunis_re',
        'nom': 'Tunis Re',
        'logo': 'https://www.tunis-re.com.tn/images/logo.png',
        'adresse': 'Rue du Lac, Tunis',
        'telephone': '+216 71 234 567',
        'email': 'contact@tunis-re.tn',
        'adminEmail': 'admin.tunisre@constat-tunisie.tn',
        'dateCreation': DateTime.now().millisecondsSinceEpoch,
        'active': true,
        'secteur': 'Réassurance',
        'fondee': 1981,
      },
    ];

    for (final compagnie in compagnies) {
      await _firestore
          .collection('compagnies_assurance')
          .doc(compagnie['id'] as String)
          .set(compagnie);
      print('🏢 Compagnie créée: ${compagnie['nom']}');
    }
  }

  /// 🏪 Créer les agences
  static Future<void> _createAgences() async {
    final agences = [
      // Agences STAR
      {
        'id': 'star_tunis_centre',
        'compagnieId': 'star_assurance',
        'nom': 'STAR Tunis Centre',
        'adresse': 'Avenue Bourguiba, Tunis Centre',
        'ville': 'Tunis',
        'gouvernorat': 'Tunis',
        'telephone': '+216 71 111 111',
        'email': 'tunis.centre@star.tn',
        'adminEmail': 'admin.star.tunis@constat-tunisie.tn',
        'dateCreation': DateTime.now().millisecondsSinceEpoch,
        'active': true,
      },
      {
        'id': 'star_manouba',
        'compagnieId': 'star_assurance',
        'nom': 'STAR Manouba',
        'adresse': 'Centre ville Manouba',
        'ville': 'Manouba',
        'gouvernorat': 'Manouba',
        'telephone': '+216 71 222 222',
        'email': 'manouba@star.tn',
        'adminEmail': 'admin.star.manouba@constat-tunisie.tn',
        'dateCreation': DateTime.now().millisecondsSinceEpoch,
        'active': true,
      },
      {
        'id': 'star_ariana',
        'compagnieId': 'star_assurance',
        'nom': 'STAR Ariana',
        'adresse': 'Centre ville Ariana',
        'ville': 'Ariana',
        'gouvernorat': 'Ariana',
        'telephone': '+216 71 333 333',
        'email': 'ariana@star.tn',
        'adminEmail': 'admin.star.ariana@constat-tunisie.tn',
        'dateCreation': DateTime.now().millisecondsSinceEpoch,
        'active': true,
      },
      // Agences Maghrebia
      {
        'id': 'maghrebia_sfax',
        'compagnieId': 'maghrebia_assurance',
        'nom': 'Maghrebia Sfax',
        'adresse': 'Avenue Hedi Chaker, Sfax',
        'ville': 'Sfax',
        'gouvernorat': 'Sfax',
        'telephone': '+216 74 444 444',
        'email': 'sfax@maghrebia.tn',
        'adminEmail': 'admin.maghrebia.sfax@constat-tunisie.tn',
        'dateCreation': DateTime.now().millisecondsSinceEpoch,
        'active': true,
      },
      {
        'id': 'maghrebia_sousse',
        'compagnieId': 'maghrebia_assurance',
        'nom': 'Maghrebia Sousse',
        'adresse': 'Avenue Léopold Sédar Senghor, Sousse',
        'ville': 'Sousse',
        'gouvernorat': 'Sousse',
        'telephone': '+216 73 555 555',
        'email': 'sousse@maghrebia.tn',
        'adminEmail': 'admin.maghrebia.sousse@constat-tunisie.tn',
        'dateCreation': DateTime.now().millisecondsSinceEpoch,
        'active': true,
      },
      // Agences GAT
      {
        'id': 'gat_nabeul',
        'compagnieId': 'gat_assurance',
        'nom': 'GAT Nabeul',
        'adresse': 'Avenue Habib Thameur, Nabeul',
        'ville': 'Nabeul',
        'gouvernorat': 'Nabeul',
        'telephone': '+216 72 666 666',
        'email': 'nabeul@gat.tn',
        'adminEmail': 'admin.gat.nabeul@constat-tunisie.tn',
        'dateCreation': DateTime.now().millisecondsSinceEpoch,
        'active': true,
      },
      // Agences BH
      {
        'id': 'bh_bizerte',
        'compagnieId': 'bh_assurance',
        'nom': 'BH Bizerte',
        'adresse': 'Avenue de l\'Indépendance, Bizerte',
        'ville': 'Bizerte',
        'gouvernorat': 'Bizerte',
        'telephone': '+216 72 777 777',
        'email': 'bizerte@bh.tn',
        'adminEmail': 'admin.bh.bizerte@constat-tunisie.tn',
        'dateCreation': DateTime.now().millisecondsSinceEpoch,
        'active': true,
      },
    ];

    for (final agence in agences) {
      await _firestore
          .collection('agences_assurance')
          .doc(agence['id'] as String)
          .set(agence);
      print('🏪 Agence créée: ${agence['nom']}');
    }
  }

  /// 👨‍💼 Créer tous les comptes admin avec Firebase Auth
  static Future<void> _createAllAdminAccounts() async {
    final adminAccounts = [
      // Super Admin
      {
        'email': 'super.admin@constat-tunisie.tn',
        'password': 'SuperAdmin2024!',
        'type': 'super_admin',
        'nom': 'Super',
        'prenom': 'Administrateur',
        'telephone': '+216 20 000 000',
      },
      // Admins Compagnies
      {
        'email': 'admin.star@constat-tunisie.tn',
        'password': 'AdminStar2024!',
        'type': 'admin_compagnie',
        'compagnieId': 'star_assurance',
        'nom': 'Ben Ali',
        'prenom': 'Ahmed',
        'telephone': '+216 20 111 111',
      },
      {
        'email': 'admin.maghrebia@constat-tunisie.tn',
        'password': 'AdminMaghrebia2024!',
        'type': 'admin_compagnie',
        'compagnieId': 'maghrebia_assurance',
        'nom': 'Trabelsi',
        'prenom': 'Fatma',
        'telephone': '+216 20 222 222',
      },
      {
        'email': 'admin.gat@constat-tunisie.tn',
        'password': 'AdminGat2024!',
        'type': 'admin_compagnie',
        'compagnieId': 'gat_assurance',
        'nom': 'Khelifi',
        'prenom': 'Mohamed',
        'telephone': '+216 20 333 333',
      },
      {
        'email': 'admin.bh@constat-tunisie.tn',
        'password': 'AdminBH2024!',
        'type': 'admin_compagnie',
        'compagnieId': 'bh_assurance',
        'nom': 'Sassi',
        'prenom': 'Leila',
        'telephone': '+216 20 444 444',
      },
      // Admins Agences
      {
        'email': 'admin.star.tunis@constat-tunisie.tn',
        'password': 'AdminStarTunis2024!',
        'type': 'admin_agence',
        'compagnieId': 'star_assurance',
        'agenceId': 'star_tunis_centre',
        'nom': 'Bouazizi',
        'prenom': 'Karim',
        'telephone': '+216 20 555 555',
      },
      {
        'email': 'admin.star.manouba@constat-tunisie.tn',
        'password': 'AdminStarManouba2024!',
        'type': 'admin_agence',
        'compagnieId': 'star_assurance',
        'agenceId': 'star_manouba',
        'nom': 'Jemli',
        'prenom': 'Sarra',
        'telephone': '+216 20 666 666',
      },
      {
        'email': 'admin.maghrebia.sfax@constat-tunisie.tn',
        'password': 'AdminMaghrebiaSfax2024!',
        'type': 'admin_agence',
        'compagnieId': 'maghrebia_assurance',
        'agenceId': 'maghrebia_sfax',
        'nom': 'Hamdi',
        'prenom': 'Nour',
        'telephone': '+216 20 777 777',
      },
    ];

    for (final admin in adminAccounts) {
      try {
        // Créer le compte Firebase Auth
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: admin['email'] as String,
          password: admin['password'] as String,
        );

        // Créer le document admin dans Firestore
        await _firestore
            .collection('admins_users')
            .doc(userCredential.user!.uid)
            .set({
          'id': userCredential.user!.uid,
          'email': admin['email'],
          'type': admin['type'],
          'nom': admin['nom'],
          'prenom': admin['prenom'],
          'telephone': admin['telephone'],
          'compagnieId': admin['compagnieId'],
          'agenceId': admin['agenceId'],
          'dateCreation': DateTime.now().millisecondsSinceEpoch,
          'active': true,
          'permissions': _getPermissions(admin['type'] as String),
        });

        print('👨‍💼 Admin créé: ${admin['email']}');
      } catch (e) {
        print('❌ Erreur création admin ${admin['email']}: $e');
      }
    }

    // Se déconnecter après création des comptes
    await _auth.signOut();
  }

  /// 🔐 Obtenir les permissions selon le type d'admin
  static Map<String, dynamic> _getPermissions(String type) {
    switch (type) {
      case 'super_admin':
        return {
          'canManageAll': true,
          'canCreateCompagnies': true,
          'canCreateAgences': true,
          'canCreateAdmins': true,
          'canViewAllStats': true,
        };
      case 'admin_compagnie':
        return {
          'canManageCompagnie': true,
          'canViewCompagnieStats': true,
          'canApproveAgents': true,
        };
      case 'admin_agence':
        return {
          'canManageAgence': true,
          'canViewAgenceStats': true,
          'canApproveAgents': true,
        };
      default:
        return {};
    }
  }

  /// 📊 Créer des données de test
  static Future<void> _createTestData() async {
    // Créer quelques demandes d'agents de test
    final demandes = [
      {
        'id': 'demande_001',
        'nom': 'Ben Ahmed',
        'prenom': 'Mohamed',
        'email': 'mohamed.benahmed@email.com',
        'telephone': '+216 20 123 456',
        'cin': '12345678',
        'compagnieId': 'star_assurance',
        'agenceId': 'star_tunis_centre',
        'dateCreation': DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch,
        'statut': 'en_attente',
        'documentUrl': null,
      },
      {
        'id': 'demande_002',
        'nom': 'Khelifi',
        'prenom': 'Ahmed',
        'email': 'ahmed.khelifi@email.com',
        'telephone': '+216 20 234 567',
        'cin': '23456789',
        'compagnieId': 'maghrebia_assurance',
        'agenceId': 'maghrebia_sfax',
        'dateCreation': DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch,
        'statut': 'en_attente',
        'documentUrl': null,
      },
    ];

    for (final demande in demandes) {
      await _firestore
          .collection('demandes_agents')
          .doc(demande['id'] as String)
          .set(demande);
      print('📋 Demande créée: ${demande['email']}');
    }
  }

  /// 📧 Obtenir tous les emails admin pour affichage
  static Map<String, List<String>> getAllAdminEmails() {
    return {
      'Super Admin': [
        'super.admin@constat-tunisie.tn (SuperAdmin2024!)',
      ],
      'Admins Compagnies': [
        'admin.star@constat-tunisie.tn (AdminStar2024!)',
        'admin.maghrebia@constat-tunisie.tn (AdminMaghrebia2024!)',
        'admin.gat@constat-tunisie.tn (AdminGat2024!)',
        'admin.bh@constat-tunisie.tn (AdminBH2024!)',
      ],
      'Admins Agences': [
        'admin.star.tunis@constat-tunisie.tn (AdminStarTunis2024!)',
        'admin.star.manouba@constat-tunisie.tn (AdminStarManouba2024!)',
        'admin.maghrebia.sfax@constat-tunisie.tn (AdminMaghrebiaSfax2024!)',
      ],
    };
  }
}

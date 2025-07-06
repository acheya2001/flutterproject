import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/hierarchical_structure.dart';

/// 🏗️ Service d'initialisation de la hiérarchie admin
class HierarchySetupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🚀 Initialiser toute la hiérarchie
  static Future<bool> initializeHierarchy() async {
    try {
      print('🏗️ Début initialisation hiérarchie...');

      // 1. Créer le super admin
      await _createSuperAdmin();

      // 2. Créer les compagnies
      await _createCompagnies();

      // 3. Créer les agences
      await _createAgences();

      // 4. Créer les admins
      await _createAdmins();

      print('✅ Hiérarchie initialisée avec succès !');
      return true;
    } catch (e) {
      print('❌ Erreur initialisation hiérarchie: $e');
      return false;
    }
  }

  /// 👑 Créer le super admin
  static Future<void> _createSuperAdmin() async {
    final superAdmin = AdminUser(
      id: 'super_admin_001',
      email: 'constat.tunisie.app@gmail.com',
      nom: 'Super',
      prenom: 'Admin',
      telephone: '+216 20 123 456',
      type: AdminType.superAdmin,
      dateCreation: DateTime.now(),
      permissions: {
        'canManageAll': true,
        'canCreateCompagnies': true,
        'canCreateAgences': true,
        'canCreateAdmins': true,
      },
    );

    await _firestore
        .collection('admins_users')
        .doc(superAdmin.id)
        .set(superAdmin.toMap());

    print('👑 Super admin créé: ${superAdmin.email}');
  }

  /// 🏢 Créer les compagnies d'assurance
  static Future<void> _createCompagnies() async {
    final compagnies = [
      CompagnieAssurance(
        id: 'star_assurance',
        nom: 'STAR Assurance',
        logo: 'https://example.com/star_logo.png',
        adresse: 'Avenue Habib Bourguiba, Tunis',
        telephone: '+216 71 123 456',
        email: 'contact@star.tn',
        adminCompagnieId: 'admin_star_001',
        dateCreation: DateTime.now(),
        metadata: {'secteur': 'automobile', 'fondee': '1960'},
      ),
      CompagnieAssurance(
        id: 'maghrebia_assurance',
        nom: 'Maghrebia Assurance',
        logo: 'https://example.com/maghrebia_logo.png',
        adresse: 'Rue de la Liberté, Tunis',
        telephone: '+216 71 234 567',
        email: 'contact@maghrebia.tn',
        adminCompagnieId: 'admin_maghrebia_001',
        dateCreation: DateTime.now(),
        metadata: {'secteur': 'automobile', 'fondee': '1962'},
      ),
      CompagnieAssurance(
        id: 'gat_assurance',
        nom: 'GAT Assurance',
        logo: 'https://example.com/gat_logo.png',
        adresse: 'Avenue Mohamed V, Tunis',
        telephone: '+216 71 345 678',
        email: 'contact@gat.tn',
        adminCompagnieId: 'admin_gat_001',
        dateCreation: DateTime.now(),
        metadata: {'secteur': 'automobile', 'fondee': '1958'},
      ),
    ];

    for (final compagnie in compagnies) {
      await _firestore
          .collection('compagnies_assurance')
          .doc(compagnie.id)
          .set(compagnie.toMap());
      print('🏢 Compagnie créée: ${compagnie.nom}');
    }
  }

  /// 🏪 Créer les agences
  static Future<void> _createAgences() async {
    final agences = [
      // Agences STAR
      AgenceAssurance(
        id: 'star_tunis_centre',
        compagnieId: 'star_assurance',
        nom: 'STAR Tunis Centre',
        adresse: 'Avenue Bourguiba, Tunis',
        ville: 'Tunis',
        gouvernorat: 'Tunis',
        telephone: '+216 71 111 111',
        email: 'tunis.centre@star.tn',
        adminAgenceId: 'admin_star_tunis_001',
        dateCreation: DateTime.now(),
      ),
      AgenceAssurance(
        id: 'star_manouba',
        compagnieId: 'star_assurance',
        nom: 'STAR Manouba',
        adresse: 'Centre ville Manouba',
        ville: 'Manouba',
        gouvernorat: 'Manouba',
        telephone: '+216 71 222 222',
        email: 'manouba@star.tn',
        adminAgenceId: 'admin_star_manouba_001',
        dateCreation: DateTime.now(),
      ),
      // Agences Maghrebia
      AgenceAssurance(
        id: 'maghrebia_sfax',
        compagnieId: 'maghrebia_assurance',
        nom: 'Maghrebia Sfax',
        adresse: 'Avenue Hedi Chaker, Sfax',
        ville: 'Sfax',
        gouvernorat: 'Sfax',
        telephone: '+216 74 333 333',
        email: 'sfax@maghrebia.tn',
        adminAgenceId: 'admin_maghrebia_sfax_001',
        dateCreation: DateTime.now(),
      ),
      // Agences GAT
      AgenceAssurance(
        id: 'gat_sousse',
        compagnieId: 'gat_assurance',
        nom: 'GAT Sousse',
        adresse: 'Avenue Léopold Sédar Senghor, Sousse',
        ville: 'Sousse',
        gouvernorat: 'Sousse',
        telephone: '+216 73 444 444',
        email: 'sousse@gat.tn',
        adminAgenceId: 'admin_gat_sousse_001',
        dateCreation: DateTime.now(),
      ),
    ];

    for (final agence in agences) {
      await _firestore
          .collection('agences_assurance')
          .doc(agence.id)
          .set(agence.toMap());
      print('🏪 Agence créée: ${agence.nom}');
    }
  }

  /// 👨‍💼 Créer les admins
  static Future<void> _createAdmins() async {
    final admins = [
      // Admins compagnies
      AdminUser(
        id: 'admin_star_001',
        email: 'admin@star.tn',
        nom: 'Ben Ali',
        prenom: 'Ahmed',
        telephone: '+216 20 111 111',
        type: AdminType.compagnie,
        compagnieId: 'star_assurance',
        dateCreation: DateTime.now(),
        permissions: {'canManageCompagnie': true},
      ),
      AdminUser(
        id: 'admin_maghrebia_001',
        email: 'admin@maghrebia.tn',
        nom: 'Trabelsi',
        prenom: 'Fatma',
        telephone: '+216 20 222 222',
        type: AdminType.compagnie,
        compagnieId: 'maghrebia_assurance',
        dateCreation: DateTime.now(),
        permissions: {'canManageCompagnie': true},
      ),
      AdminUser(
        id: 'admin_gat_001',
        email: 'admin@gat.tn',
        nom: 'Khelifi',
        prenom: 'Mohamed',
        telephone: '+216 20 333 333',
        type: AdminType.compagnie,
        compagnieId: 'gat_assurance',
        dateCreation: DateTime.now(),
        permissions: {'canManageCompagnie': true},
      ),
      // Admins agences
      AdminUser(
        id: 'admin_star_tunis_001',
        email: 'tunis@star.tn',
        nom: 'Sassi',
        prenom: 'Leila',
        telephone: '+216 20 444 444',
        type: AdminType.agence,
        compagnieId: 'star_assurance',
        agenceId: 'star_tunis_centre',
        dateCreation: DateTime.now(),
        permissions: {'canManageAgence': true},
      ),
      AdminUser(
        id: 'admin_star_manouba_001',
        email: 'manouba@star.tn',
        nom: 'Bouazizi',
        prenom: 'Karim',
        telephone: '+216 20 555 555',
        type: AdminType.agence,
        compagnieId: 'star_assurance',
        agenceId: 'star_manouba',
        dateCreation: DateTime.now(),
        permissions: {'canManageAgence': true},
      ),
    ];

    for (final admin in admins) {
      await _firestore
          .collection('admins_users')
          .doc(admin.id)
          .set(admin.toMap());
      print('👨‍💼 Admin créé: ${admin.email}');
    }
  }

  /// 📋 Créer des demandes de test
  static Future<void> createTestDemandes() async {
    final demandes = [
      DemandeAgent(
        id: 'demande_001',
        nom: 'Ben Ahmed',
        prenom: 'Mohamed',
        email: 'mohamed.benahmed@email.com',
        telephone: '+216 20 123 456',
        cin: '12345678',
        compagnieId: 'star_assurance',
        agenceId: 'star_tunis_centre',
        dateCreation: DateTime.now().subtract(const Duration(days: 2)),
        statut: StatutDemande.enAttente,
      ),
      DemandeAgent(
        id: 'demande_002',
        nom: 'Khelifi',
        prenom: 'Ahmed',
        email: 'ahmed.khelifi@email.com',
        telephone: '+216 20 234 567',
        cin: '23456789',
        compagnieId: 'star_assurance',
        agenceId: 'star_manouba',
        dateCreation: DateTime.now().subtract(const Duration(days: 1)),
        statut: StatutDemande.enAttente,
      ),
      DemandeAgent(
        id: 'demande_003',
        nom: 'Trabelsi',
        prenom: 'Sarra',
        email: 'sarra.trabelsi@email.com',
        telephone: '+216 20 345 678',
        cin: '34567890',
        compagnieId: 'maghrebia_assurance',
        agenceId: 'maghrebia_sfax',
        dateCreation: DateTime.now().subtract(const Duration(hours: 5)),
        statut: StatutDemande.enAttente,
      ),
    ];

    for (final demande in demandes) {
      await _firestore
          .collection('demandes_agents')
          .doc(demande.id)
          .set(demande.toMap());
      print('📋 Demande créée: ${demande.email}');
    }
  }

  /// 🧹 Nettoyer les données existantes
  static Future<void> cleanExistingData() async {
    final collections = [
      'admins_users',
      'compagnies_assurance',
      'agences_assurance',
      'demandes_agents',
    ];

    for (final collection in collections) {
      final snapshot = await _firestore.collection(collection).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      print('🧹 Collection $collection nettoyée');
    }
  }
}

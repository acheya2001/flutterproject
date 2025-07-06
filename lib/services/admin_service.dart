import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/admin_models.dart';
import '../features/auth/models/user_model.dart';
import '../utils/user_type.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Créer une compagnie d'assurance
  Future<String> creerCompagnie(CompagnieAssurance compagnie) async {
    try {
      // Vérifier les permissions
      await _verifierPermissionSuperAdmin();

      // Vérifier l'unicité du SIRET
      final existant = await _firestore
          .collection('compagnies')
          .where('siret', isEqualTo: compagnie.siret)
          .get();

      if (existant.docs.isNotEmpty) {
        throw Exception('Une compagnie avec ce SIRET existe déjà');
      }

      // Créer la compagnie
      final docRef = await _firestore
          .collection('compagnies')
          .add(compagnie.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la compagnie: $e');
    }
  }

  /// Créer une agence
  Future<String> creerAgence(AgenceAssurance agence) async {
    try {
      // Vérifier les permissions
      await _verifierPermissionCompagnie(agence.compagnieId);

      // Vérifier l'unicité du code agence
      final existant = await _firestore
          .collection('agences')
          .where('compagnieId', isEqualTo: agence.compagnieId)
          .where('code', isEqualTo: agence.code)
          .get();

      if (existant.docs.isNotEmpty) {
        throw Exception('Une agence avec ce code existe déjà dans cette compagnie');
      }

      // Créer l'agence
      final docRef = await _firestore
          .collection('agences')
          .add(agence.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'agence: $e');
    }
  }

  /// Créer un agent d'assurance
  Future<String> creerAgent({
    required AgentAssurance agent,
    required String motDePasse,
  }) async {
    try {
      // Vérifier les permissions
      await _verifierPermissionAgence(agent.agenceId);

      // Vérifier l'unicité de l'email
      final existantEmail = await _firestore
          .collection('users')
          .where('email', isEqualTo: agent.email)
          .get();

      if (existantEmail.docs.isNotEmpty) {
        throw Exception('Un utilisateur avec cet email existe déjà');
      }

      // Vérifier l'unicité du matricule
      final existantMatricule = await _firestore
          .collection('agents')
          .where('compagnieId', isEqualTo: agent.compagnieId)
          .where('matricule', isEqualTo: agent.matricule)
          .get();

      if (existantMatricule.docs.isNotEmpty) {
        throw Exception('Un agent avec ce matricule existe déjà dans cette compagnie');
      }

      // Créer le compte Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: agent.email,
        password: motDePasse,
      );

      final userId = userCredential.user!.uid;

      // Créer l'utilisateur dans Firestore
      final userModel = UserModel(
        uid: userId,
        email: agent.email,
        nom: agent.nom,
        prenom: agent.prenom,
        telephone: agent.telephone,
        userType: UserType.assureur,
        dateCreation: DateTime.now(),
        compagnieId: agent.compagnieId,
        agenceId: agent.agenceId,
        matricule: agent.matricule,
        poste: agent.poste,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .set(userModel.toFirestore());

      // Créer l'agent dans la collection agents
      await _firestore
          .collection('agents')
          .doc(userId)
          .set(agent.toFirestore());

      return userId;
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'agent: $e');
    }
  }

  /// Obtenir toutes les compagnies
  Future<List<CompagnieAssurance>> obtenirCompagnies() async {
    try {
      final snapshot = await _firestore
          .collection('compagnies')
          .where('active', isEqualTo: true)
          .orderBy('nom')
          .get();

      return snapshot.docs
          .map((doc) => CompagnieAssurance.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des compagnies: $e');
    }
  }

  /// Obtenir les agences d'une compagnie
  Future<List<AgenceAssurance>> obtenirAgences(String compagnieId) async {
    try {
      final snapshot = await _firestore
          .collection('agences')
          .where('compagnieId', isEqualTo: compagnieId)
          .where('active', isEqualTo: true)
          .orderBy('nom')
          .get();

      return snapshot.docs
          .map((doc) => AgenceAssurance.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des agences: $e');
    }
  }

  /// Obtenir les agents d'une agence
  Future<List<AgentAssurance>> obtenirAgents(String agenceId) async {
    try {
      final snapshot = await _firestore
          .collection('agents')
          .where('agenceId', isEqualTo: agenceId)
          .where('active', isEqualTo: true)
          .orderBy('nom')
          .get();

      return snapshot.docs
          .map((doc) => AgentAssurance.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des agents: $e');
    }
  }

  /// Vérifier si l'utilisateur actuel est super admin
  Future<void> _verifierPermissionSuperAdmin() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      throw Exception('Utilisateur non trouvé');
    }

    final userData = userDoc.data()!;
    if (userData['userType'] != 'admin') {
      throw Exception('Permissions insuffisantes');
    }
  }

  /// Vérifier les permissions pour une compagnie
  Future<void> _verifierPermissionCompagnie(String compagnieId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      throw Exception('Utilisateur non trouvé');
    }

    final userData = userDoc.data()!;
    final userType = userData['userType'];
    
    if (userType == 'admin') {
      return; // Super admin peut tout faire
    }

    if (userType == 'assureur' && userData['compagnieId'] == compagnieId) {
      return; // Responsable de cette compagnie
    }

    throw Exception('Permissions insuffisantes');
  }

  /// Vérifier les permissions pour une agence
  Future<void> _verifierPermissionAgence(String agenceId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      throw Exception('Utilisateur non trouvé');
    }

    final userData = userDoc.data()!;
    final userType = userData['userType'];
    
    if (userType == 'admin') {
      return; // Super admin peut tout faire
    }

    // Récupérer l'agence pour vérifier la compagnie
    final agenceDoc = await _firestore.collection('agences').doc(agenceId).get();
    if (!agenceDoc.exists) {
      throw Exception('Agence non trouvée');
    }

    final agenceData = agenceDoc.data()!;
    
    if (userType == 'assureur' && 
        (userData['compagnieId'] == agenceData['compagnieId'] ||
         userData['agenceId'] == agenceId)) {
      return; // Responsable de cette compagnie ou agence
    }

    throw Exception('Permissions insuffisantes');
  }

  /// Initialiser le système avec un super admin
  Future<void> initialiserSuperAdmin() async {
    try {
      // Vérifier si un super admin existe déjà
      final existant = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'admin')
          .get();

      if (existant.docs.isNotEmpty) {
        print('Super admin déjà existant');
        return;
      }

      // Créer le compte super admin
      const email = 'admin@constat-tunisie.tn';
      const password = 'AdminConstat2024!';

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Créer l'utilisateur admin dans Firestore
      final adminUser = UserModel(
        uid: userId,
        email: email,
        nom: 'Administrateur',
        prenom: 'Système',
        telephone: '+216 70 000 000',
        userType: UserType.admin,
        dateCreation: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .set(adminUser.toFirestore());

      print('Super admin créé avec succès');
      print('Email: $email');
      print('Mot de passe: $password');
    } catch (e) {
      print('Erreur lors de l\'initialisation du super admin: $e');
    }
  }
}

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../insurance/services/insurance_data_generator.dart';
import '../../insurance/models/vehicule_complet_model.dart';
import '../../insurance/models/compagnie_assurance_model.dart';
import '../../vehicule/models/vehicule_assure_model.dart';
import '../../vehicule/models/vehicule_conducteur_liaison_model.dart';
import '../../vehicule/services/vehicule_affectation_service.dart';
import '../../admin/models/agent_validation_model.dart';

/// 🗄️ Organisateur de données Firebase
class FirebaseDataOrganizer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  /// 🚀 Générer toutes les données organisées
  static Future<void> generateCompleteDatabase() async {
    debugPrint('🚀 Génération complète de la base de données...');
    
    try {
      // 1. Générer la hiérarchie assurance
      await _generateInsuranceHierarchy();
      
      // 2. Générer les véhicules assurés
      await _generateVehiclesAssures();
      
      // 3. Générer les liaisons véhicule-conducteur
      await _generateVehiculeLiaisons();
      
      // 4. Générer les demandes de validation agents
      await _generateAgentValidations();
      
      // 5. Créer les index et règles de sécurité
      await _setupFirebaseIndexes();
      
      debugPrint('✅ Base de données générée avec succès !');
      
    } catch (e) {
      debugPrint('❌ Erreur génération base de données: $e');
      rethrow;
    }
  }

  /// 🏢 Générer la hiérarchie assurance
  static Future<void> _generateInsuranceHierarchy() async {
    debugPrint('🏢 Génération hiérarchie assurance...');
    await InsuranceDataGenerator.generateAllTestData();
  }

  /// 🚗 Générer les véhicules assurés
  static Future<void> _generateVehiclesAssures() async {
    debugPrint('🚗 Génération véhicules assurés...');
    
    final List<String> marques = [
      'Peugeot', 'Renault', 'Citroën', 'Volkswagen', 'Toyota', 
      'Hyundai', 'Kia', 'Nissan', 'Ford', 'Opel'
    ];
    
    final Map<String, List<String>> modeles = {
      'Peugeot': ['208', '308', '3008', '5008', '2008'],
      'Renault': ['Clio', 'Megane', 'Captur', 'Kadjar', 'Scenic'],
      'Citroën': ['C3', 'C4', 'C5 Aircross', 'Berlingo', 'Picasso'],
      'Volkswagen': ['Golf', 'Polo', 'Tiguan', 'Passat', 'T-Cross'],
      'Toyota': ['Yaris', 'Corolla', 'RAV4', 'C-HR', 'Prius'],
    };

    final List<String> assureurs = ['STAR', 'MAGHREBIA', 'LLOYD', 'GAT', 'AST'];
    final List<String> couleurs = ['Blanc', 'Noir', 'Gris', 'Rouge', 'Bleu', 'Argent'];

    final batch = _firestore.batch();
    
    for (int i = 0; i < 500; i++) {
      final marque = marques[_random.nextInt(marques.length)];
      final modele = modeles[marque]?[_random.nextInt(modeles[marque]!.length)] ?? 'Modèle';
      final assureur = assureurs[_random.nextInt(assureurs.length)];
      
      final vehiculeId = _firestore.collection('vehicules_assures').doc().id;
      final now = DateTime.now();
      
      final vehicule = VehiculeAssureModel(
        id: vehiculeId,
        numeroContrat: '$assureur-${now.year}-${(i + 1).toString().padLeft(6, '0')}',
        assureurId: assureur,
        vehicule: VehiculeModel(
          id: 'veh_$vehiculeId',
          immatriculation: _generateImmatriculation(),
          marque: marque,
          modele: modele,
          annee: 2015 + _random.nextInt(9), // 2015-2023
          couleur: couleurs[_random.nextInt(couleurs.length)],
          numeroChassis: _generateNumeroChassis(),
          puissanceFiscale: 4 + _random.nextInt(8), // 4-11 CV
          typeCarburant: _random.nextBool() ? 'Essence' : 'Diesel',
          nombrePlaces: 5,
          createdAt: now,
          updatedAt: now,
        ),
        proprietaire: ProprietaireModel(
          nom: _generateNom(),
          prenom: _generatePrenom(),
          cin: _generateCin(),
          telephone: _generateTelephone(),
          adresse: _generateAdresse(),
        ),
        contrat: ContratAssuranceModel(
          typeCouverture: _random.nextBool() ? 'Tous risques' : 'Tiers',
          dateDebut: DateTime(now.year, 1, 1),
          dateFin: DateTime(now.year, 12, 31),
          primeAnnuelle: 800 + _random.nextInt(1200).toDouble(), // 800-2000 TND
          franchise: 200 + _random.nextInt(300).toDouble(), // 200-500 TND
        ),
        createdAt: now,
        updatedAt: now,
      );

      batch.set(
        _firestore.collection('vehicules_assures').doc(vehiculeId),
        vehicule.toFirestore(),
      );

      // Commit par batch de 100
      if ((i + 1) % 100 == 0) {
        await batch.commit();
        debugPrint('✅ ${i + 1} véhicules créés');
      }
    }

    // Commit final
    await batch.commit();
    debugPrint('✅ 500 véhicules assurés créés');
  }

  /// 🔗 Générer les liaisons véhicule-conducteur
  static Future<void> _generateVehiculeLiaisons() async {
    debugPrint('🔗 Génération liaisons véhicule-conducteur...');
    
    // Récupérer quelques véhicules
    final vehiculesSnapshot = await _firestore
        .collection('vehicules_assures')
        .limit(100)
        .get();

    final List<String> emailsConducteurs = [
      'conducteur1@test.com',
      'conducteur2@test.com',
      'conducteur3@test.com',
      'rahma.hammami@test.com',
      'mohamed.ben.ali@test.com',
      'fatma.trabelsi@test.com',
      'ahmed.bouazizi@test.com',
      'salma.chedly@test.com',
    ];

    int liaisonsCreees = 0;
    
    for (final vehiculeDoc in vehiculesSnapshot.docs) {
      // 30% de chance qu'un véhicule soit affecté
      if (_random.nextDouble() < 0.3) {
        final email = emailsConducteurs[_random.nextInt(emailsConducteurs.length)];
        
        try {
          await VehiculeAffectationService.affecterVehicule(
            vehiculeId: vehiculeDoc.id,
            conducteurEmail: email,
            agentAffecteur: 'agent_test_${_random.nextInt(10)}',
            agenceId: 'agence_test_${_random.nextInt(5)}',
            compagnieId: 'STAR',
            droits: ConducteurDroits.defaultDroits,
            dateExpiration: _random.nextBool() 
                ? DateTime.now().add(Duration(days: 365 + _random.nextInt(730)))
                : null,
          );
          liaisonsCreees++;
        } catch (e) {
          debugPrint('⚠️ Erreur affectation véhicule ${vehiculeDoc.id}: $e');
        }
      }
    }

    debugPrint('✅ $liaisonsCreees liaisons véhicule-conducteur créées');
  }

  /// 📋 Générer les demandes de validation agents
  static Future<void> _generateAgentValidations() async {
    debugPrint('📋 Génération demandes validation agents...');
    
    final List<String> compagnies = ['STAR', 'MAGHREBIA', 'LLOYD', 'GAT', 'AST'];
    final List<String> agences = ['tunis_centre', 'sfax_nord', 'sousse', 'monastir_centre'];
    final List<String> zones = ['Tunis', 'Sfax', 'Sousse', 'Monastir', 'Nabeul'];
    final List<String> delegations = ['Centre Ville', 'Nord', 'Sud', 'Est', 'Ouest'];
    
    final batch = _firestore.batch();
    
    for (int i = 0; i < 20; i++) {
      final validationId = _firestore.collection('agents_validation').doc().id;
      final now = DateTime.now();
      
      final validation = AgentValidationModel(
        id: validationId,
        userId: 'user_agent_$i',
        email: 'agent$i@${compagnies[_random.nextInt(compagnies.length)].toLowerCase()}.tn',
        nom: _generateNom(),
        prenom: _generatePrenom(),
        telephone: _generateTelephone(),
        compagnieDemandee: compagnies[_random.nextInt(compagnies.length)],
        agenceDemandee: agences[_random.nextInt(agences.length)],
        zoneGeographique: [zones[_random.nextInt(zones.length)]],
        delegation: delegations[_random.nextInt(delegations.length)],
        matriculeAgent: 'AG${(i + 1).toString().padLeft(4, '0')}',
        numeroCarteAgent: 'CA${_random.nextInt(999999).toString().padLeft(6, '0')}',
        documents: ['carte_agent.pdf', 'attestation_travail.pdf', 'cin_recto.pdf'],
        statut: i < 5 
            ? ValidationStatus.enAttente 
            : i < 15 
                ? ValidationStatus.approuve 
                : ValidationStatus.rejete,
        adminValidateur: i >= 5 ? 'admin_001' : null,
        dateValidation: i >= 5 ? now.subtract(Duration(days: _random.nextInt(30))) : null,
        commentaireAdmin: i >= 5 ? 'Validation automatique' : null,
        raisonRejet: i >= 15 ? 'Documents incomplets' : null,
        createdAt: now.subtract(Duration(days: _random.nextInt(60))),
        updatedAt: now,
      );

      batch.set(
        _firestore.collection('agents_validation').doc(validationId),
        validation.toFirestore(),
      );
    }

    await batch.commit();
    debugPrint('✅ 20 demandes de validation agents créées');
  }

  /// 📊 Configurer les index Firebase
  static Future<void> _setupFirebaseIndexes() async {
    debugPrint('📊 Configuration des index Firebase...');
    
    // Les index doivent être créés manuellement dans la console Firebase
    // Voici la liste des index recommandés :
    
    final indexesRecommandes = [
      // vehicules_assures
      'vehicules_assures: assureur_id, numero_contrat',
      'vehicules_assures: vehicule.immatriculation',
      'vehicules_assures: proprietaire.cin',
      
      // vehicules_conducteurs_liaisons
      'vehicules_conducteurs_liaisons: conducteur_email, statut',
      'vehicules_conducteurs_liaisons: vehicule_id, statut',
      'vehicules_conducteurs_liaisons: agent_affecteur, createdAt',
      
      // vehicules_recherches
      'vehicules_recherches: conducteur_rechercheur, date_recherche',
      'vehicules_recherches: contexte, date_recherche',
      
      // agents_validation
      'agents_validation: statut, createdAt',
      'agents_validation: compagnie_demandee, statut',
      
      // compagnies_assurance
      'compagnies_assurance: nom',
      
      // agences
      'agences: compagnie_id, zone_geographique',
      
      // agents_assurance
      'agents_assurance: compagnie_id, agence_id',
    ];

    debugPrint('📊 Index recommandés à créer dans la console Firebase:');
    for (final index in indexesRecommandes) {
      debugPrint('  - $index');
    }
  }

  /// 🧹 Nettoyer toutes les données
  static Future<void> clearAllData() async {
    debugPrint('🧹 Nettoyage de toutes les données...');
    
    final collections = [
      'vehicules_assures',
      'vehicules_conducteurs_liaisons',
      'vehicules_recherches',
      'agents_validation',
      'compagnies_assurance',
      'agences',
      'agents_assurance',
    ];

    for (final collection in collections) {
      final snapshot = await _firestore.collection(collection).get();
      final batch = _firestore.batch();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      if (snapshot.docs.isNotEmpty) {
        await batch.commit();
        debugPrint('🗑️ ${snapshot.docs.length} documents supprimés de $collection');
      }
    }

    debugPrint('✅ Nettoyage terminé');
  }

  // Méthodes utilitaires pour générer des données réalistes
  static String _generateImmatriculation() {
    final letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final numbers = _random.nextInt(999) + 1;
    final region = ['TUN', 'SFX', 'SOU', 'BIZ', 'GAB'][_random.nextInt(5)];
    final suffix = _random.nextInt(999) + 1;
    return '${numbers.toString().padLeft(3, '0')} $region ${suffix.toString().padLeft(3, '0')}';
  }

  static String _generateNumeroChassis() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(17, (index) => chars[_random.nextInt(chars.length)]).join();
  }

  static String _generateCin() {
    return (10000000 + _random.nextInt(90000000)).toString();
  }

  static String _generateTelephone() {
    final prefixes = ['20', '21', '22', '23', '24', '25', '26', '27', '28', '29'];
    final prefix = prefixes[_random.nextInt(prefixes.length)];
    final number = _random.nextInt(999999).toString().padLeft(6, '0');
    return '$prefix$number';
  }

  static String _generateNom() {
    final noms = [
      'Ben Ali', 'Trabelsi', 'Bouazizi', 'Chedly', 'Hammami', 'Jebali',
      'Marzouki', 'Essebsi', 'Karoui', 'Belhaj', 'Sfar', 'Gharbi',
      'Nasri', 'Khelifi', 'Mansouri', 'Agrebi', 'Dridi', 'Mejri'
    ];
    return noms[_random.nextInt(noms.length)];
  }

  static String _generatePrenom() {
    final prenoms = [
      'Mohamed', 'Ahmed', 'Ali', 'Mahmoud', 'Omar', 'Youssef', 'Karim', 'Sami',
      'Fatma', 'Aisha', 'Khadija', 'Maryam', 'Salma', 'Nour', 'Rahma', 'Ines',
      'Amira', 'Yasmine', 'Dorra', 'Emna', 'Hajer', 'Rim', 'Sarra', 'Wiem'
    ];
    return prenoms[_random.nextInt(prenoms.length)];
  }

  static String _generateAdresse() {
    final rues = [
      'Avenue Habib Bourguiba', 'Rue de la Liberté', 'Avenue Mohamed V',
      'Rue Ibn Khaldoun', 'Avenue de la République', 'Rue de la Paix',
      'Avenue Hedi Chaker', 'Rue Mongi Bali', 'Avenue Taieb Mehiri'
    ];
    final villes = ['Tunis', 'Sfax', 'Sousse', 'Bizerte', 'Gabès', 'Monastir'];
    
    final rue = rues[_random.nextInt(rues.length)];
    final numero = _random.nextInt(200) + 1;
    final ville = villes[_random.nextInt(villes.length)];
    
    return '$numero $rue, $ville';
  }
}

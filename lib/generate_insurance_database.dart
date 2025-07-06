import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(DatabaseGeneratorApp());
}

class DatabaseGeneratorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Générateur Base de Données Assurance',
      home: DatabaseGeneratorScreen(),
    );
  }
}

class DatabaseGeneratorScreen extends StatefulWidget {
  @override
  _DatabaseGeneratorScreenState createState() => _DatabaseGeneratorScreenState();
}

class _DatabaseGeneratorScreenState extends State<DatabaseGeneratorScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isGenerating = false;
  String _status = '';
  int _progress = 0;
  int _total = 0;

  // Données de base pour la génération
  final List<String> compagnies = [
    'STAR', 'GAT', 'BH', 'MAGHREBIA', 'LLOYD', 'COMAR', 'CTAMA', 'ZITOUNA'
  ];

  final List<String> gouvernorats = [
    'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan',
    'Bizerte', 'Béja', 'Jendouba', 'Kef', 'Siliana', 'Sousse',
    'Monastir', 'Mahdia', 'Sfax', 'Kairouan', 'Kasserine', 'Sidi Bouzid',
    'Gabès', 'Médenine', 'Tataouine', 'Gafsa', 'Tozeur', 'Kébili'
  ];

  final List<String> marques = [
    'Peugeot', 'Renault', 'Citroën', 'Volkswagen', 'Ford', 'Opel',
    'Fiat', 'Seat', 'Skoda', 'Hyundai', 'Kia', 'Toyota', 'Nissan',
    'Dacia', 'Suzuki', 'Mitsubishi', 'Mazda', 'Honda', 'Chevrolet'
  ];

  final List<String> modeles = [
    '206', '207', '208', '307', '308', '407', '508', 'Clio', 'Megane',
    'Logan', 'Sandero', 'Symbol', 'C3', 'C4', 'Berlingo', 'Golf',
    'Polo', 'Passat', 'Fiesta', 'Focus', 'Mondeo', 'Corsa', 'Astra',
    'Punto', 'Panda', 'Ibiza', 'Leon', 'Fabia', 'Octavia', 'i10',
    'i20', 'i30', 'Accent', 'Elantra', 'Picanto', 'Rio', 'Cerato',
    'Yaris', 'Corolla', 'Auris', 'Micra', 'Note', 'Qashqai'
  ];

  final List<String> prenoms = [
    'Ahmed', 'Mohamed', 'Ali', 'Mahmoud', 'Omar', 'Youssef', 'Karim',
    'Sami', 'Rami', 'Nabil', 'Farid', 'Tarek', 'Walid', 'Hichem',
    'Amine', 'Fares', 'Marwan', 'Aymen', 'Bilel', 'Chokri',
    'Fatma', 'Aicha', 'Khadija', 'Amina', 'Salma', 'Nour', 'Ines',
    'Sarra', 'Rim', 'Dorra', 'Emna', 'Olfa', 'Wafa', 'Samia',
    'Leila', 'Monia', 'Sonia', 'Rania', 'Meriem', 'Asma'
  ];

  final List<String> noms = [
    'Ben Ali', 'Trabelsi', 'Bouazizi', 'Chaieb', 'Dridi', 'Gharbi',
    'Jemli', 'Karray', 'Lassoued', 'Maaloul', 'Nasri', 'Ouali',
    'Riahi', 'Saidi', 'Tlili', 'Zouari', 'Abidi', 'Belhaj',
    'Chaabane', 'Derbali', 'Essid', 'Ferjani', 'Ghanmi', 'Hamdi',
    'Jebali', 'Kacem', 'Labidi', 'Mahfoudh', 'Nouri', 'Oueslati'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Générateur Base de Données Assurance'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Génération de Base de Données',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Ce script va générer:\n'
                      '• 8 compagnies d\'assurance\n'
                      '• 24 gouvernorats avec agences\n'
                      '• 200+ agents d\'assurance\n'
                      '• 5000+ contrats de véhicules\n'
                      '• 1000+ conducteurs',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateDatabase,
              child: Text(_isGenerating ? 'Génération en cours...' : 'Générer Base de Données'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 20),
            if (_isGenerating) ...[
              LinearProgressIndicator(
                value: _total > 0 ? _progress / _total : 0,
              ),
              SizedBox(height: 10),
              Text(
                'Progression: $_progress / $_total',
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _status,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateStatus(String message) {
    setState(() {
      _status += '${DateTime.now().toString().substring(11, 19)} - $message\n';
    });
    print(message);
  }

  void _updateProgress() {
    setState(() {
      _progress++;
    });
  }

  Future<void> _generateDatabase() async {
    setState(() {
      _isGenerating = true;
      _status = '';
      _progress = 0;
      _total = 8 + (24 * 3) + 200 + 5000 + 1000; // Estimation
    });

    try {
      _updateStatus('🚀 Début de la génération de la base de données...');

      // 1. Générer les compagnies d'assurance
      await _generateCompagnies();

      // 2. Générer les agences par gouvernorat
      await _generateAgences();

      // 3. Générer les agents d'assurance
      await _generateAgents();

      // 4. Générer les conducteurs
      await _generateConducteurs();

      // 5. Générer les contrats de véhicules
      await _generateContrats();

      _updateStatus('✅ Génération terminée avec succès !');
      _updateStatus('📊 Base de données créée avec ${_progress} éléments');

    } catch (e) {
      _updateStatus('❌ Erreur: $e');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _generateCompagnies() async {
    _updateStatus('📋 Génération des compagnies d\'assurance...');
    
    for (String compagnie in compagnies) {
      await _firestore.collection('insurance_companies').doc(compagnie.toLowerCase()).set({
        'code': compagnie,
        'nom': compagnie,
        'nom_complet': _getCompagnieNomComplet(compagnie),
        'adresse_siege': 'Avenue Habib Bourguiba, Tunis',
        'telephone': '+216 71 ${Random().nextInt(900000) + 100000}',
        'email': '${compagnie.toLowerCase()}@assurance.tn',
        'site_web': 'www.${compagnie.toLowerCase()}.com.tn',
        'date_creation': DateTime.now().subtract(Duration(days: Random().nextInt(7300))),
        'statut': 'active',
        'logo_url': 'https://example.com/logos/${compagnie.toLowerCase()}.png',
      });
      _updateProgress();
      _updateStatus('✅ Compagnie $compagnie créée');
    }
  }

  String _getCompagnieNomComplet(String code) {
    switch (code) {
      case 'STAR': return 'Société Tunisienne d\'Assurance et de Réassurance';
      case 'GAT': return 'Groupe Assurances Tunis';
      case 'BH': return 'BH Assurance';
      case 'MAGHREBIA': return 'Compagnie d\'Assurance Maghrebia';
      case 'LLOYD': return 'Lloyd Tunisien';
      case 'COMAR': return 'Compagnie Méditerranéenne d\'Assurance et de Réassurance';
      case 'CTAMA': return 'Compagnie Tuniso-Arabe d\'Assurance Maritime et d\'Aviation';
      case 'ZITOUNA': return 'Zitouna Takaful';
      default: return code;
    }
  }

  Future<void> _generateAgences() async {
    _updateStatus('🏢 Génération des agences par gouvernorat...');

    for (String compagnie in compagnies) {
      for (String gouvernorat in gouvernorats) {
        int nbAgences = Random().nextInt(3) + 1; // 1 à 3 agences par gouvernorat

        for (int i = 1; i <= nbAgences; i++) {
          String agenceId = '${compagnie.toLowerCase()}_${gouvernorat.toLowerCase()}_agence$i';

          await _firestore.collection('agences').doc(agenceId).set({
            'id': agenceId,
            'nom': 'Agence $compagnie $gouvernorat $i',
            'compagnie': compagnie,
            'gouvernorat': gouvernorat,
            'adresse': '${Random().nextInt(200) + 1} Avenue ${_getRandomStreet()}, $gouvernorat',
            'telephone': '+216 ${_getGouvernoratCode(gouvernorat)} ${Random().nextInt(900000) + 100000}',
            'email': 'agence$i.${gouvernorat.toLowerCase()}@${compagnie.toLowerCase()}.tn',
            'responsable': '${prenoms[Random().nextInt(prenoms.length)]} ${noms[Random().nextInt(noms.length)]}',
            'date_ouverture': DateTime.now().subtract(Duration(days: Random().nextInt(3650))),
            'statut': 'active',
            'horaires': {
              'lundi_vendredi': '08:00-17:00',
              'samedi': '08:00-12:00',
              'dimanche': 'fermé'
            },
          });
          _updateProgress();
        }
      }
    }
    _updateStatus('✅ Agences créées pour tous les gouvernorats');
  }

  String _getRandomStreet() {
    List<String> streets = [
      'Habib Bourguiba', 'de la République', 'de l\'Indépendance', 'du 20 Mars',
      'Farhat Hached', 'Mongi Slim', 'de la Liberté', 'des Martyrs',
      'Hédi Chaker', 'Tahar Sfar', 'de Carthage', 'du 9 Avril'
    ];
    return streets[Random().nextInt(streets.length)];
  }

  String _getGouvernoratCode(String gouvernorat) {
    Map<String, String> codes = {
      'Tunis': '71', 'Ariana': '71', 'Ben Arous': '71', 'Manouba': '71',
      'Nabeul': '72', 'Zaghouan': '72', 'Bizerte': '72', 'Béja': '78',
      'Jendouba': '78', 'Kef': '78', 'Siliana': '78', 'Sousse': '73',
      'Monastir': '73', 'Mahdia': '73', 'Sfax': '74', 'Kairouan': '77',
      'Kasserine': '77', 'Sidi Bouzid': '76', 'Gabès': '75', 'Médenine': '75',
      'Tataouine': '75', 'Gafsa': '76', 'Tozeur': '76', 'Kébili': '76'
    };
    return codes[gouvernorat] ?? '71';
  }

  Future<void> _generateAgents() async {
    _updateStatus('👥 Génération des agents d\'assurance...');

    // Récupérer toutes les agences
    QuerySnapshot agencesSnapshot = await _firestore.collection('agences').get();

    for (QueryDocumentSnapshot agenceDoc in agencesSnapshot.docs) {
      Map<String, dynamic> agenceData = agenceDoc.data() as Map<String, dynamic>;

      int nbAgents = Random().nextInt(5) + 2; // 2 à 6 agents par agence

      for (int i = 1; i <= nbAgents; i++) {
        String prenom = prenoms[Random().nextInt(prenoms.length)];
        String nom = noms[Random().nextInt(noms.length)];
        String email = '${prenom.toLowerCase()}.${nom.toLowerCase().replaceAll(' ', '')}@${agenceData['compagnie'].toString().toLowerCase()}.tn';

        // Créer l'utilisateur dans users
        String userId = _firestore.collection('users').doc().id;

        await _firestore.collection('users').doc(userId).set({
          'uid': userId,
          'email': email,
          'nom': nom,
          'prenom': prenom,
          'telephone': '+216 ${Random().nextInt(90000000) + 10000000}',
          'date_naissance': DateTime.now().subtract(Duration(days: Random().nextInt(14600) + 7300)), // 20-60 ans
          'adresse': '${Random().nextInt(100) + 1} Rue ${_getRandomStreet()}, ${agenceData['gouvernorat']}',
          'cin': '${Random().nextInt(90000000) + 10000000}',
          'date_creation': DateTime.now().subtract(Duration(days: Random().nextInt(365))),
          'statut': 'actif',
          'role': 'assureur',
          'compagnie': agenceData['compagnie'],
          'agence': agenceData['id'],
          'gouvernorat': agenceData['gouvernorat'],
        });

        // Créer le type d'utilisateur
        await _firestore.collection('user_types').doc(userId).set({
          'type': 'assureur',
          'userId': userId,
        });

        // Créer l'entrée dans assureurs
        await _firestore.collection('assureurs').doc(userId).set({
          'userId': userId,
          'email': email,
          'nom': nom,
          'prenom': prenom,
          'compagnie': agenceData['compagnie'],
          'agence': agenceData['id'],
          'gouvernorat': agenceData['gouvernorat'],
          'poste': _getRandomPoste(),
          'date_embauche': DateTime.now().subtract(Duration(days: Random().nextInt(1825))),
          'salaire': Random().nextInt(2000) + 1000,
          'commission': Random().nextDouble() * 5 + 2, // 2-7%
          'objectif_mensuel': Random().nextInt(50) + 20,
          'statut': 'actif',
        });

        _updateProgress();
      }
    }
    _updateStatus('✅ Agents d\'assurance créés');
  }

  String _getRandomPoste() {
    List<String> postes = [
      'Agent Commercial', 'Conseiller Clientèle', 'Chargé de Clientèle',
      'Agent de Souscription', 'Responsable Agence', 'Superviseur'
    ];
    return postes[Random().nextInt(postes.length)];
  }

  Future<void> _generateConducteurs() async {
    _updateStatus('🚗 Génération des conducteurs...');

    for (int i = 1; i <= 1000; i++) {
      String prenom = prenoms[Random().nextInt(prenoms.length)];
      String nom = noms[Random().nextInt(noms.length)];
      String email = '${prenom.toLowerCase()}.${nom.toLowerCase().replaceAll(' ', '')}$i@gmail.com';

      String userId = _firestore.collection('users').doc().id;

      // Créer l'utilisateur dans users
      await _firestore.collection('users').doc(userId).set({
        'uid': userId,
        'email': email,
        'nom': nom,
        'prenom': prenom,
        'telephone': '+216 ${Random().nextInt(90000000) + 10000000}',
        'date_naissance': DateTime.now().subtract(Duration(days: Random().nextInt(21900) + 6570)), // 18-78 ans
        'adresse': '${Random().nextInt(200) + 1} ${_getRandomStreet()}, ${gouvernorats[Random().nextInt(gouvernorats.length)]}',
        'cin': '${Random().nextInt(90000000) + 10000000}',
        'date_creation': DateTime.now().subtract(Duration(days: Random().nextInt(365))),
        'statut': 'actif',
        'role': 'conducteur',
      });

      // Créer le type d'utilisateur
      await _firestore.collection('user_types').doc(userId).set({
        'type': 'conducteur',
        'userId': userId,
      });

      // Créer l'entrée dans conducteurs
      await _firestore.collection('conducteurs').doc(userId).set({
        'userId': userId,
        'email': email,
        'nom': nom,
        'prenom': prenom,
        'date_naissance': DateTime.now().subtract(Duration(days: Random().nextInt(21900) + 6570)),
        'lieu_naissance': gouvernorats[Random().nextInt(gouvernorats.length)],
        'cin': '${Random().nextInt(90000000) + 10000000}',
        'adresse': '${Random().nextInt(200) + 1} ${_getRandomStreet()}, ${gouvernorats[Random().nextInt(gouvernorats.length)]}',
        'telephone': '+216 ${Random().nextInt(90000000) + 10000000}',
        'profession': _getRandomProfession(),
        'permis_numero': 'P${Random().nextInt(9000000) + 1000000}',
        'permis_date_obtention': DateTime.now().subtract(Duration(days: Random().nextInt(7300) + 365)),
        'permis_categorie': _getRandomPermisCategorie(),
        'date_creation': DateTime.now().subtract(Duration(days: Random().nextInt(365))),
        'statut': 'actif',
      });

      _updateProgress();

      if (i % 100 == 0) {
        _updateStatus('✅ $i conducteurs créés');
      }
    }
    _updateStatus('✅ 1000 conducteurs créés');
  }

  String _getRandomProfession() {
    List<String> professions = [
      'Ingénieur', 'Médecin', 'Enseignant', 'Comptable', 'Avocat', 'Pharmacien',
      'Architecte', 'Dentiste', 'Infirmier', 'Technicien', 'Commercial', 'Fonctionnaire',
      'Entrepreneur', 'Consultant', 'Journaliste', 'Traducteur', 'Designer', 'Développeur',
      'Mécanicien', 'Électricien', 'Plombier', 'Maçon', 'Chauffeur', 'Vendeur',
      'Cuisinier', 'Serveur', 'Coiffeur', 'Esthéticienne', 'Photographe', 'Musicien'
    ];
    return professions[Random().nextInt(professions.length)];
  }

  String _getRandomPermisCategorie() {
    List<String> categories = ['B', 'A', 'A1', 'C', 'D', 'BE', 'CE'];
    return categories[Random().nextInt(categories.length)];
  }

  Future<void> _generateContrats() async {
    _updateStatus('📄 Génération des contrats de véhicules...');

    // Récupérer tous les agents
    QuerySnapshot agentsSnapshot = await _firestore.collection('assureurs').get();
    List<QueryDocumentSnapshot> agents = agentsSnapshot.docs;

    // Récupérer tous les conducteurs
    QuerySnapshot conducteursSnapshot = await _firestore.collection('conducteurs').get();
    List<QueryDocumentSnapshot> conducteurs = conducteursSnapshot.docs;

    for (int i = 1; i <= 5000; i++) {
      // Sélectionner un agent et un conducteur aléatoirement
      QueryDocumentSnapshot agent = agents[Random().nextInt(agents.length)];
      QueryDocumentSnapshot conducteur = conducteurs[Random().nextInt(conducteurs.length)];

      Map<String, dynamic> agentData = agent.data() as Map<String, dynamic>;
      Map<String, dynamic> conducteurData = conducteur.data() as Map<String, dynamic>;

      String marque = marques[Random().nextInt(marques.length)];
      String modele = modeles[Random().nextInt(modeles.length)];
      int annee = DateTime.now().year - Random().nextInt(20); // Véhicules de 0 à 20 ans

      String contractId = _firestore.collection('contracts').doc().id;

      await _firestore.collection('contracts').doc(contractId).set({
        'id': contractId,
        'numero_contrat': 'C${agentData['compagnie']}${DateTime.now().year}${i.toString().padLeft(6, '0')}',
        'compagnie': {
          'code': agentData['compagnie'],
          'nom': _getCompagnieNomComplet(agentData['compagnie']),
        },
        'agence': {
          'id': agentData['agence'],
          'gouvernorat': agentData['gouvernorat'],
        },
        'agent': {
          'id': agent.id,
          'nom': agentData['nom'],
          'prenom': agentData['prenom'],
          'email': agentData['email'],
        },
        'conducteur': {
          'id': conducteur.id,
          'nom': conducteurData['nom'],
          'prenom': conducteurData['prenom'],
          'cin': conducteurData['cin'],
          'telephone': conducteurData['telephone'],
          'adresse': conducteurData['adresse'],
        },
        'vehicule': {
          'marque': marque,
          'modele': modele,
          'annee': annee,
          'immatriculation': _generateImmatriculation(),
          'numero_chassis': _generateNumeroChassis(),
          'couleur': _getRandomCouleur(),
          'carburant': _getRandomCarburant(),
          'puissance': Random().nextInt(200) + 50,
          'nombre_places': Random().nextInt(5) + 2,
          'usage': _getRandomUsage(),
        },
        'assurance': {
          'type_couverture': _getRandomCouverture(),
          'date_debut': DateTime.now().subtract(Duration(days: Random().nextInt(365))),
          'date_fin': DateTime.now().add(Duration(days: Random().nextInt(365) + 1)),
          'prime_annuelle': Random().nextInt(2000) + 300,
          'franchise': Random().nextInt(500) + 100,
          'bonus_malus': (Random().nextDouble() * 2 + 0.5).toStringAsFixed(2),
        },
        'date_creation': DateTime.now().subtract(Duration(days: Random().nextInt(365))),
        'statut': 'actif',
        'createdBy': agent.id,
        'conducteurId': conducteur.id,
      });

      _updateProgress();

      if (i % 500 == 0) {
        _updateStatus('✅ $i contrats créés');
      }
    }
    _updateStatus('✅ 5000 contrats créés');
  }

  String _generateImmatriculation() {
    // Format tunisien: 123 TUN 1234
    int num1 = Random().nextInt(900) + 100;
    List<String> letters = ['TUN', 'TUS', 'TUG', 'TUB', 'TUA', 'TUZ', 'TUJ', 'TUK'];
    String letter = letters[Random().nextInt(letters.length)];
    int num2 = Random().nextInt(9000) + 1000;
    return '$num1 $letter $num2';
  }

  String _generateNumeroChassis() {
    // Format: 17 caractères alphanumériques
    String chars = 'ABCDEFGHJKLMNPRSTUVWXYZ1234567890';
    String chassis = '';
    for (int i = 0; i < 17; i++) {
      chassis += chars[Random().nextInt(chars.length)];
    }
    return chassis;
  }

  String _getRandomCouleur() {
    List<String> couleurs = [
      'Blanc', 'Noir', 'Gris', 'Rouge', 'Bleu', 'Vert', 'Jaune', 'Orange',
      'Violet', 'Marron', 'Beige', 'Argent', 'Bordeaux', 'Rose'
    ];
    return couleurs[Random().nextInt(couleurs.length)];
  }

  String _getRandomCarburant() {
    List<String> carburants = ['Essence', 'Diesel', 'GPL', 'Hybride', 'Électrique'];
    return carburants[Random().nextInt(carburants.length)];
  }

  String _getRandomUsage() {
    List<String> usages = ['Personnel', 'Professionnel', 'Taxi', 'Location', 'Transport'];
    return usages[Random().nextInt(usages.length)];
  }

  String _getRandomCouverture() {
    List<String> couvertures = [
      'Responsabilité Civile', 'Tous Risques', 'Tiers Collision',
      'Tiers Étendu', 'Vol et Incendie'
    ];
    return couvertures[Random().nextInt(couvertures.length)];
  }
}

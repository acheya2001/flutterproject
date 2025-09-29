import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🎯 Générateur de données complètes pour PDF de démonstration
class TestDataCompleteGenerator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// 🎨 Créer une session complète avec 3 véhicules pour démonstration
  static Future<String> creerSessionCompleteDemo() async {
    final sessionId = 'DEMO_${DateTime.now().millisecondsSinceEpoch}';
    
    print('🎯 [DEMO] Création session complète: $sessionId');
    
    // 1. Données de session principales
    final sessionData = {
      'sessionCode': 'DEMO2025',
      'dateAccident': Timestamp.fromDate(DateTime(2025, 1, 15, 14, 30)),
      'heureAccident': '14:30',
      'lieuAccident': 'Avenue Habib Bourguiba, intersection avec Rue de la Liberté, Tunis',
      'lieuGps': '36.8065, 10.1815',
      'nombreConducteurs': 3,
      'status': 'completed',
      'createdAt': Timestamp.now(),
      'createdBy': 'demo_user',
      
      // Données communes détaillées
      'donneesCommunes': {
        'dateAccident': '2025-01-15',
        'heureAccident': '14:30',
        'lieuAccident': 'Avenue Habib Bourguiba, intersection avec Rue de la Liberté, Tunis',
        'lieuGps': '36.8065, 10.1815',
        'gouvernorat': 'Tunis',
        'meteo': 'Ensoleillé',
        'visibilite': 'Bonne',
        'etatRoute': 'Sèche',
        'circulation': 'Dense',
        'blesses': true,
        'detailsBlesses': 'Blessures légères au conducteur du véhicule B',
        'degatsMateriels': 'Dégâts importants sur les véhicules A et B, légers sur C',
        'temoins': [
          {
            'nom': 'Ben Ali',
            'prenom': 'Mohamed',
            'telephone': '+216 98 123 456',
            'adresse': 'Rue de la République, Tunis'
          },
          {
            'nom': 'Trabelsi',
            'prenom': 'Fatma',
            'telephone': '+216 71 987 654',
            'adresse': 'Avenue Bourguiba, Tunis'
          }
        ],
        'dateModification': DateTime.now().toIso8601String(),
      }
    };

    // 2. Créer les 3 participants avec formulaires complets
    final participants = await _creerParticipantsDemo();
    
    // 3. Créer les signatures
    final signatures = await _creerSignaturesDemo();
    
    // 4. Créer le croquis
    final croquis = await _creerCroquisDemo();
    
    // 5. Créer les photos d'accident
    final photos = await _creerPhotosDemo();
    
    // 6. Sauvegarder dans Firestore
    await _firestore.collection('sessions_collaboratives').doc(sessionId).set(sessionData);
    
    // Sauvegarder participants
    for (int i = 0; i < participants.length; i++) {
      await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('participants_data')
          .doc('participant_${i + 1}')
          .set({
        'donneesFormulaire': participants[i],
        'userId': 'user_${i + 1}',
        'roleVehicule': String.fromCharCode(65 + i), // A, B, C
      });
    }
    
    // Sauvegarder signatures
    for (int i = 0; i < signatures.length; i++) {
      await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('signatures')
          .doc('user_${i + 1}')
          .set(signatures[i]);
    }
    
    // Sauvegarder croquis
    await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .collection('croquis')
        .doc('principal')
        .set(croquis);
    
    // Sauvegarder photos
    for (int i = 0; i < photos.length; i++) {
      await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('photos')
          .doc('photo_${i + 1}')
          .set(photos[i]);
    }
    
    print('✅ [DEMO] Session complète créée: $sessionId');
    return sessionId;
  }

  /// 👥 Créer 3 participants avec formulaires complets
  static Future<List<Map<String, dynamic>>> _creerParticipantsDemo() async {
    return [
      // Véhicule A - BMW
      {
        'vehiculeSelectionne': {
          'compagnieAssurance': 'STAR Assurances',
          'numeroContrat': 'STA-2025-001234',
          'agence': 'Agence STAR Tunis Centre',
          'dateDebut': Timestamp.fromDate(DateTime(2024, 6, 1)),
          'dateFin': Timestamp.fromDate(DateTime(2025, 6, 1)),
        },
        'donneesPersonnelles': {
          'nomConducteur': 'Ben Salem',
          'prenomConducteur': 'Ahmed',
          'adresseConducteur': '15 Avenue de la République, 1000 Tunis',
          'telephoneConducteur': '+216 98 765 432',
          'numeroPermis': 'TN-2018-123456',
          'dateDelivrancePermis': Timestamp.fromDate(DateTime(2018, 3, 15)),
        },
        'vehicule': {
          'marque': 'BMW',
          'modele': 'Serie 3',
          'immatriculation': '123 TUN 2024',
          'annee': 2022,
          'couleur': 'Noir',
          'typeVehicule': 'Berline',
        },
        'circonstances': [
          'roulait',
          'virait_droite',
          'ignorait_priorite'
        ],
        'pointsChoc': ['Avant droit', 'Pare-chocs avant'],
        'degatsApparents': ['Rayures importantes', 'Phare cassé'],
        'observations': 'Le conducteur n\'a pas respecté la priorité à droite lors du virage. Impact violent avec le véhicule B.',
        'remarques': 'Accident survenu pendant les heures de pointe. Circulation dense.',
        'estProprietaire': true,
      },
      
      // Véhicule B - Mercedes
      {
        'vehiculeSelectionne': {
          'compagnieAssurance': 'AMI Assurances',
          'numeroContrat': 'AMI-2025-567890',
          'agence': 'Agence AMI Menzah',
          'dateDebut': Timestamp.fromDate(DateTime(2024, 8, 15)),
          'dateFin': Timestamp.fromDate(DateTime(2025, 8, 15)),
        },
        'donneesPersonnelles': {
          'nomConducteur': 'Trabelsi',
          'prenomConducteur': 'Leila',
          'adresseConducteur': '42 Rue de la Liberté, 2080 Ariana',
          'telephoneConducteur': '+216 71 234 567',
          'numeroPermis': 'TN-2015-789012',
          'dateDelivrancePermis': Timestamp.fromDate(DateTime(2015, 7, 22)),
        },
        'vehicule': {
          'marque': 'Mercedes',
          'modele': 'Classe C',
          'immatriculation': '456 TUN 2023',
          'annee': 2021,
          'couleur': 'Blanc',
          'typeVehicule': 'Berline',
        },
        'circonstances': [
          'roulait',
          'arretait',
          'respectait_priorite'
        ],
        'pointsChoc': ['Côté gauche', 'Portière avant gauche'],
        'degatsApparents': ['Enfoncement portière', 'Vitre cassée'],
        'observations': 'Véhicule qui respectait la priorité. Impact reçu sur le côté gauche. Conductrice légèrement blessée.',
        'remarques': 'Véhicule immobilisé après l\'impact. Nécessite dépannage.',
        'estProprietaire': false,
      },
      
      // Véhicule C - Peugeot
      {
        'vehiculeSelectionne': {
          'compagnieAssurance': 'GAT Assurances',
          'numeroContrat': 'GAT-2025-345678',
          'agence': 'Agence GAT Lac',
          'dateDebut': Timestamp.fromDate(DateTime(2024, 10, 1)),
          'dateFin': Timestamp.fromDate(DateTime(2025, 10, 1)),
        },
        'donneesPersonnelles': {
          'nomConducteur': 'Jlassi',
          'prenomConducteur': 'Karim',
          'adresseConducteur': '78 Avenue Habib Bourguiba, 1001 Tunis',
          'telephoneConducteur': '+216 22 345 678',
          'numeroPermis': 'TN-2020-345678',
          'dateDelivrancePermis': Timestamp.fromDate(DateTime(2020, 11, 10)),
        },
        'vehicule': {
          'marque': 'Peugeot',
          'modele': '308',
          'immatriculation': '789 TUN 2024',
          'annee': 2023,
          'couleur': 'Rouge',
          'typeVehicule': 'Compacte',
        },
        'circonstances': [
          'roulait',
          'evitait_obstacle',
          'freinage_urgence'
        ],
        'pointsChoc': ['Arrière', 'Pare-chocs arrière'],
        'degatsApparents': ['Rayures légères', 'Feu arrière fissuré'],
        'observations': 'Véhicule qui a tenté d\'éviter la collision. Dégâts mineurs à l\'arrière suite au freinage d\'urgence.',
        'remarques': 'Pas de blessés. Véhicule encore en état de rouler.',
        'estProprietaire': true,
      },
    ];
  }

  /// ✍️ Créer 3 signatures électroniques
  static Future<List<Map<String, dynamic>>> _creerSignaturesDemo() async {
    return [
      {
        'userId': 'user_1',
        'roleVehicule': 'A',
        'signatureBase64': _genererSignatureBase64('Ahmed Ben Salem'),
        'dateSignature': DateTime.now().subtract(Duration(minutes: 5)).toIso8601String(),
        'nom': 'Ben Salem',
        'prenom': 'Ahmed',
        'accord': true,
      },
      {
        'userId': 'user_2',
        'roleVehicule': 'B',
        'signatureBase64': _genererSignatureBase64('Leila Trabelsi'),
        'dateSignature': DateTime.now().subtract(Duration(minutes: 3)).toIso8601String(),
        'nom': 'Trabelsi',
        'prenom': 'Leila',
        'accord': true,
      },
      {
        'userId': 'user_3',
        'roleVehicule': 'C',
        'signatureBase64': _genererSignatureBase64('Karim Jlassi'),
        'dateSignature': DateTime.now().subtract(Duration(minutes: 1)).toIso8601String(),
        'nom': 'Jlassi',
        'prenom': 'Karim',
        'accord': true,
      },
    ];
  }

  /// 🎨 Créer un croquis d'accident
  static Future<Map<String, dynamic>> _creerCroquisDemo() async {
    return {
      'imageBase64': _genererCroquisBase64(),
      'dateCreation': DateTime.now().toIso8601String(),
      'createdBy': 'user_1',
      'description': 'Croquis de l\'intersection avec positions des véhicules au moment de l\'impact',
      'validated': true,
      'source': 'principal',
    };
  }

  /// 📸 Créer des photos d'accident
  static Future<List<Map<String, dynamic>>> _creerPhotosDemo() async {
    return [
      {
        'imageBase64': _genererPhotoAccidentBase64('vue_generale'),
        'type': 'vue_generale',
        'description': 'Vue générale de l\'intersection après l\'accident',
        'dateCreation': DateTime.now().toIso8601String(),
        'vehiculeConcerne': 'tous',
      },
      {
        'imageBase64': _genererPhotoAccidentBase64('degats_vehicule_a'),
        'type': 'degats',
        'description': 'Dégâts sur le véhicule A (BMW)',
        'dateCreation': DateTime.now().toIso8601String(),
        'vehiculeConcerne': 'A',
      },
      {
        'imageBase64': _genererPhotoAccidentBase64('degats_vehicule_b'),
        'type': 'degats',
        'description': 'Dégâts sur le véhicule B (Mercedes)',
        'dateCreation': DateTime.now().toIso8601String(),
        'vehiculeConcerne': 'B',
      },
    ];
  }

  /// ✍️ Générer une signature base64 simple
  static String _genererSignatureBase64(String nom) {
    // Signature SVG simple convertie en base64
    final svg = '''
    <svg width="200" height="80" xmlns="http://www.w3.org/2000/svg">
      <path d="M10,40 Q50,10 90,40 T170,40" stroke="blue" stroke-width="2" fill="none"/>
      <text x="10" y="70" font-family="Arial" font-size="12" fill="black">$nom</text>
    </svg>
    ''';
    return base64Encode(utf8.encode(svg));
  }

  /// 🎨 Générer un croquis base64 simple
  static String _genererCroquisBase64() {
    // Croquis SVG d'intersection
    final svg = '''
    <svg width="400" height="300" xmlns="http://www.w3.org/2000/svg">
      <!-- Routes -->
      <rect x="0" y="140" width="400" height="20" fill="gray"/>
      <rect x="190" y="0" width="20" height="300" fill="gray"/>

      <!-- Véhicule A (BMW) -->
      <rect x="120" y="145" width="40" height="20" fill="black"/>
      <text x="125" y="158" fill="white" font-size="10">BMW A</text>

      <!-- Véhicule B (Mercedes) -->
      <rect x="195" y="100" width="20" height="40" fill="white" stroke="black"/>
      <text x="198" y="118" fill="black" font-size="8">MB B</text>

      <!-- Véhicule C (Peugeot) -->
      <rect x="195" y="180" width="20" height="40" fill="red"/>
      <text x="198" y="198" fill="white" font-size="8">PG C</text>

      <!-- Flèches de direction -->
      <path d="M140,155 L180,155" stroke="red" stroke-width="2" marker-end="url(#arrowhead)"/>

      <!-- Légende -->
      <text x="10" y="20" font-size="12">Intersection Bourguiba/Liberté</text>
      <text x="10" y="280" font-size="10">A: BMW (virage droite)</text>
      <text x="150" y="280" font-size="10">B: Mercedes (priorité)</text>
      <text x="280" y="280" font-size="10">C: Peugeot (évitement)</text>

      <defs>
        <marker id="arrowhead" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
          <polygon points="0 0, 10 3.5, 0 7" fill="red"/>
        </marker>
      </defs>
    </svg>
    ''';
    return base64Encode(utf8.encode(svg));
  }

  /// 📸 Générer une photo d'accident base64 simple
  static String _genererPhotoAccidentBase64(String type) {
    // Image SVG simple représentant une photo
    final svg = '''
    <svg width="300" height="200" xmlns="http://www.w3.org/2000/svg">
      <rect width="300" height="200" fill="lightblue"/>
      <rect x="50" y="50" width="200" height="100" fill="white" stroke="black"/>
      <text x="150" y="105" text-anchor="middle" font-size="14">Photo: $type</text>
      <text x="150" y="125" text-anchor="middle" font-size="10">Accident du 15/01/2025</text>
      <text x="150" y="140" text-anchor="middle" font-size="10">Avenue Bourguiba, Tunis</text>

      <!-- Simule des véhicules -->
      <rect x="80" y="160" width="30" height="15" fill="black"/>
      <rect x="120" y="160" width="30" height="15" fill="white" stroke="black"/>
      <rect x="160" y="160" width="30" height="15" fill="red"/>
    </svg>
    ''';
    return base64Encode(utf8.encode(svg));
  }
}

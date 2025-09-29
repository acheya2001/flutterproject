import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'complete_elegant_pdf_service.dart';

/// 🔍 Service de debug pour tester le PDF avec des données réelles
class DebugPdfService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🧪 Créer une session de test avec des données réelles et générer le PDF
  static Future<String> creerSessionTestEtGenererPDF() async {
    try {
      print('🔍 [DEBUG PDF] Début création session de test avec données réelles');

      // 1. Créer une session de test avec ID unique
      final sessionId = 'debug_session_${DateTime.now().millisecondsSinceEpoch}';
      
      // 2. Créer la session principale avec des données réelles
      await _creerSessionPrincipale(sessionId);
      
      // 3. Créer les participants avec formulaires complets
      await _creerParticipantsAvecFormulaires(sessionId);
      
      // 4. Créer les signatures
      await _creerSignatures(sessionId);
      
      // 5. Créer le croquis
      await _creerCroquis(sessionId);
      
      // 6. Créer les photos
      await _creerPhotos(sessionId);
      
      print('✅ [DEBUG PDF] Session de test créée: $sessionId');
      
      // 7. Générer le PDF
      print('📄 [DEBUG PDF] Génération du PDF...');
      final pdfPath = await CompleteElegantPdfService.genererConstatCompletElegant(
        sessionId: sessionId,
      );
      
      print('✅ [DEBUG PDF] PDF généré avec succès: $pdfPath');
      return pdfPath;
      
    } catch (e) {
      print('❌ [DEBUG PDF] Erreur: $e');
      rethrow;
    }
  }

  /// 📋 Créer la session principale
  static Future<void> _creerSessionPrincipale(String sessionId) async {
    final sessionData = {
      'sessionCode': 'DBG_${sessionId.substring(sessionId.length - 6)}',
      'typeAccident': 'Collision frontale - Test Debug',
      'nombreVehicules': 2,
      'statut': 'en_cours',
      'conducteurCreateur': 'user_debug_a',
      'dateCreation': Timestamp.now(),
      'dateModification': Timestamp.now(),
      'participants': [
        {
          'userId': 'user_debug_a',
          'roleVehicule': 'A',
          'nom': 'Ben Salah',
          'prenom': 'Ahmed',
          'email': 'ahmed.bensalah@email.tn',
          'telephone': '+216 98 123 456',
          'estCreateur': true,
          'statut': 'signe',
          'formulaireStatus': 'termine',
        },
        {
          'userId': 'user_debug_b',
          'roleVehicule': 'B',
          'nom': 'Trabelsi',
          'prenom': 'Fatma',
          'email': 'fatma.trabelsi@email.tn',
          'telephone': '+216 97 654 321',
          'estCreateur': false,
          'statut': 'signe',
          'formulaireStatus': 'termine',
        },
      ],
    };

    await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .set(sessionData);
  }

  /// 👥 Créer les participants avec formulaires complets
  static Future<void> _creerParticipantsAvecFormulaires(String sessionId) async {
    // Participant A
    await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .collection('participants_data')
        .doc('user_debug_a')
        .set({
      'userId': 'user_debug_a',
      'roleVehicule': 'A',
      'etapeActuelle': '6',
      'statut': 'termine',
      'donneesFormulaire': {
        // Données personnelles
        'donneesPersonnelles': {
          'nom': 'Ben Salah',
          'prenom': 'Ahmed',
          'dateNaissance': '1985-03-15',
          'adresse': '123 Avenue Habib Bourguiba, Tunis 1000',
          'telephone': '+216 98 123 456',
          'email': 'ahmed.bensalah@email.tn',
          'cin': '12345678',
          'permisConduire': 'PC123456',
          'categoriePermis': 'B',
          'dateDelivrancePermis': '2005-06-20',
        },
        
        // Données véhicule
        'donneesVehicule': {
          'marque': 'Peugeot',
          'modele': '308',
          'annee': '2020',
          'couleur': 'Blanc',
          'immatriculation': '123 TUN 456',
          'numeroSerie': 'VF3XXXXXXXXXXXXXXX',
          'puissanceFiscale': '7 CV',
          'nombrePlaces': '5',
          'usage': 'Personnel',
        },
        
        // Données assurance
        'donneesAssurance': {
          'compagnie': 'STAR Assurances',
          'numeroPolice': 'POL123456789',
          'agence': 'Agence Tunis Centre',
          'dateEcheance': '2024-12-31',
          'attestationValide': true,
        },
        
        // Informations accident
        'dateAccident': '2024-01-15',
        'heureAccident': '14:30',
        'lieuAccident': 'Avenue de la République, intersection avec Rue de la Liberté, Tunis',
        'lieuGps': {
          'latitude': 36.8065,
          'longitude': 10.1815,
        },
        
        // Circonstances
        'circonstances': {
          'stationnait': false,
          'quittaitStationnement': false,
          'prenaitStationnement': false,
          'sortaitParking': false,
          'entrait': false,
          'circulait': true,
          'changeaitFile': false,
          'depassait': false,
          'tournaitDroite': false,
          'tournaitGauche': false,
          'reculait': false,
          'empiétait': false,
          'venaitDroite': false,
          'respectaitPriorite': true,
        },
        'circonstancesSelectionnees': ['circulait', 'respectaitPriorite'],
        
        // Dégâts
        'degats': {
          'avant': true,
          'arriere': false,
          'droite': false,
          'gauche': false,
          'description': 'Dégâts importants à l\'avant du véhicule, pare-chocs et capot endommagés',
        },
        
        // Témoins
        'temoins': [
          {
            'nom': 'Gharbi',
            'prenom': 'Mohamed',
            'adresse': '456 Rue de la Paix, Tunis',
            'telephone': '+216 20 111 222',
          }
        ],
        
        // Signature
        'aSigne': true,
        'signatureData': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
      },
    });

    // Participant B
    await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .collection('participants_data')
        .doc('user_debug_b')
        .set({
      'userId': 'user_debug_b',
      'roleVehicule': 'B',
      'etapeActuelle': '6',
      'statut': 'termine',
      'donneesFormulaire': {
        // Données personnelles
        'donneesPersonnelles': {
          'nom': 'Trabelsi',
          'prenom': 'Fatma',
          'dateNaissance': '1990-08-22',
          'adresse': '789 Boulevard du 7 Novembre, Ariana 2080',
          'telephone': '+216 97 654 321',
          'email': 'fatma.trabelsi@email.tn',
          'cin': '87654321',
          'permisConduire': 'PC987654',
          'categoriePermis': 'B',
          'dateDelivrancePermis': '2010-09-15',
        },
        
        // Données véhicule
        'donneesVehicule': {
          'marque': 'Renault',
          'modele': 'Clio',
          'annee': '2019',
          'couleur': 'Rouge',
          'immatriculation': '789 TUN 123',
          'numeroSerie': 'VF1XXXXXXXXXXXXXXX',
          'puissanceFiscale': '6 CV',
          'nombrePlaces': '5',
          'usage': 'Personnel',
        },
        
        // Données assurance
        'donneesAssurance': {
          'compagnie': 'AMI Assurances',
          'numeroPolice': 'POL987654321',
          'agence': 'Agence Ariana',
          'dateEcheance': '2024-11-30',
          'attestationValide': true,
        },
        
        // Informations accident
        'dateAccident': '2024-01-15',
        'heureAccident': '14:30',
        'lieuAccident': 'Avenue de la République, intersection avec Rue de la Liberté, Tunis',
        'lieuGps': {
          'latitude': 36.8065,
          'longitude': 10.1815,
        },
        
        // Circonstances
        'circonstances': {
          'stationnait': false,
          'quittaitStationnement': false,
          'prenaitStationnement': false,
          'sortaitParking': false,
          'entrait': false,
          'circulait': true,
          'changeaitFile': false,
          'depassait': false,
          'tournaitDroite': true,
          'tournaitGauche': false,
          'reculait': false,
          'empiétait': false,
          'venaitDroite': true,
          'respectaitPriorite': false,
        },
        'circonstancesSelectionnees': ['circulait', 'tournaitDroite', 'venaitDroite'],
        
        // Dégâts
        'degats': {
          'avant': false,
          'arriere': false,
          'droite': true,
          'gauche': false,
          'description': 'Dégâts sur le côté droit du véhicule, portière et rétroviseur endommagés',
        },
        
        // Témoins
        'temoins': [
          {
            'nom': 'Mansouri',
            'prenom': 'Leila',
            'adresse': '321 Avenue Bourguiba, Tunis',
            'telephone': '+216 25 333 444',
          }
        ],
        
        // Signature
        'aSigne': true,
        'signatureData': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
      },
    });
  }

  /// ✍️ Créer les signatures
  static Future<void> _creerSignatures(String sessionId) async {
    await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .collection('signatures')
        .doc('user_debug_a')
        .set({
      'userId': 'user_debug_a',
      'signatureData': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
      'dateSignature': Timestamp.now(),
      'nom': 'Ben Salah Ahmed',
    });

    await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .collection('signatures')
        .doc('user_debug_b')
        .set({
      'userId': 'user_debug_b',
      'signatureData': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
      'dateSignature': Timestamp.now(),
      'nom': 'Trabelsi Fatma',
    });
  }

  /// 🎨 Créer le croquis
  static Future<void> _creerCroquis(String sessionId) async {
    await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .collection('croquis')
        .doc('principal')
        .set({
      'imageUrl': 'https://example.com/croquis_debug.png',
      'dateCreation': Timestamp.now(),
      'validePar': ['user_debug_a', 'user_debug_b'],
      'description': 'Croquis de l\'accident - Collision à l\'intersection',
      'elements': [
        {
          'type': 'vehicule',
          'id': 'A',
          'position': {'x': 100, 'y': 200},
          'angle': 0,
        },
        {
          'type': 'vehicule',
          'id': 'B',
          'position': {'x': 200, 'y': 150},
          'angle': 90,
        },
      ],
    });
  }

  /// 📸 Créer les photos
  static Future<void> _creerPhotos(String sessionId) async {
    await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .collection('photos')
        .doc('photo_1')
        .set({
      'url': 'https://example.com/photo_accident_1.jpg',
      'type': 'accident',
      'description': 'Vue générale de l\'accident',
      'uploadedBy': 'user_debug_a',
      'dateUpload': Timestamp.now(),
    });

    await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .collection('photos')
        .doc('photo_2')
        .set({
      'url': 'https://example.com/photo_degats_a.jpg',
      'type': 'degats',
      'description': 'Dégâts véhicule A',
      'uploadedBy': 'user_debug_a',
      'dateUpload': Timestamp.now(),
    });
  }

  /// 🧹 Nettoyer les données de test
  static Future<void> nettoyerDonneesTest() async {
    try {
      // Supprimer toutes les sessions de test debug
      final sessionsSnapshot = await _firestore
          .collection('sessions_collaboratives')
          .where('sessionCode', isGreaterThanOrEqualTo: 'DBG_')
          .where('sessionCode', isLessThan: 'DBG_z')
          .get();

      for (var doc in sessionsSnapshot.docs) {
        await doc.reference.delete();
      }

      print('✅ [DEBUG PDF] Données de test nettoyées');
    } catch (e) {
      print('❌ [DEBUG PDF] Erreur nettoyage: $e');
    }
  }
}

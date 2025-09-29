import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/tunisian_constat_pdf_service.dart';

/// 🧪 Test du service PDF amélioré
class TestPDFAmeliore {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🎯 Créer des données de test complètes
  static Future<String> creerDonneesTestCompletes() async {
    try {
      print('🧪 [TEST] Création des données de test complètes...');

      // 1. Créer une session collaborative de test
      final sessionId = 'test_session_${DateTime.now().millisecondsSinceEpoch}';
      
      // 2. Données de la session principale
      final sessionData = {
        'id': sessionId,
        'codeSession': 'TST${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        'statut': 'complete',
        'dateCreation': Timestamp.now(),
        'nombreParticipants': 2,
        'participants': [
          {
            'userId': 'user1_test',
            'nom': 'Dupont',
            'prenom': 'Jean',
            'email': 'jean.dupont@test.com',
            'role': 'A',
          },
          {
            'userId': 'user2_test', 
            'nom': 'Martin',
            'prenom': 'Marie',
            'email': 'marie.martin@test.com',
            'role': 'B',
          }
        ],
      };

      // 3. Données d'accident complètes
      final donneesAccident = {
        'dateAccident': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'heureAccident': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1, hours: 2))),
        'localisation': {
          'adresse': 'Avenue Habib Bourguiba, Tunis',
          'ville': 'Tunis',
          'codePostal': '1000',
          'lat': 36.8065,
          'lng': 10.1815,
        },
        'blesses': false,
        'degatsAutres': true,
        'temoins': [
          {
            'nom': 'Témoin',
            'prenom': 'Ahmed',
            'telephone': '+216 20 123 456',
            'adresse': 'Rue de la République, Tunis',
            'estPassager': false,
          },
          {
            'nom': 'Passager',
            'prenom': 'Fatma',
            'telephone': '+216 25 789 012',
            'adresse': 'Avenue Mohamed V, Tunis',
            'estPassager': true,
          }
        ],
      };

      // 4. Formulaires détaillés pour chaque participant
      final formulaires = {
        'user1_test': {
          // Données d'assurance
          'vehiculeSelectionne': {
            'compagnieAssurance': 'STAR Assurances',
            'numeroContrat': 'STA-2024-001234',
            'agence': 'Agence Tunis Centre',
            'dateDebut': Timestamp.fromDate(DateTime(2024, 1, 1)),
            'dateFin': Timestamp.fromDate(DateTime(2024, 12, 31)),
          },
          
          // Données du conducteur
          'donneesPersonnelles': {
            'nomConducteur': 'Dupont',
            'prenomConducteur': 'Jean',
            'adresseConducteur': '123 Rue de la Liberté, Tunis',
            'telephoneConducteur': '+216 71 123 456',
            'numeroPermis': 'TN123456789',
            'dateDelivrancePermis': Timestamp.fromDate(DateTime(2010, 5, 15)),
          },
          
          // Données du véhicule
          'vehicule': {
            'marque': 'Peugeot',
            'modele': '208',
            'immatriculation': '123 TUN 456',
            'annee': 2020,
            'couleur': 'Blanc',
            'typeVehicule': 'Voiture particulière',
          },
          
          // Dégâts et points de choc
          'pointsChoc': ['Avant gauche', 'Pare-chocs avant'],
          'degats': {
            'description': 'Rayures importantes sur le pare-chocs avant et phare gauche cassé',
            'gravite': 'moyen',
          },
          'photosDegats': ['photo1.jpg', 'photo2.jpg'],
          
          // Circonstances
          'circonstancesSelectionnees': [
            'roulait',
            'virait_droite',
            'ignorait_signal_arret'
          ],
          
          // Observations
          'observations': 'Le conducteur du véhicule B n\'a pas respecté le stop. Visibilité réduite à cause de la pluie.',
          'remarques': 'Accident survenu pendant les heures de pointe.',
          
          'estProprietaire': true,
        },
        
        'user2_test': {
          // Données d'assurance
          'vehiculeSelectionne': {
            'compagnieAssurance': 'GAT Assurances',
            'numeroContrat': 'GAT-2024-567890',
            'agence': 'Agence Sfax',
            'dateDebut': Timestamp.fromDate(DateTime(2024, 3, 1)),
            'dateFin': Timestamp.fromDate(DateTime(2025, 2, 28)),
          },
          
          // Données du conducteur
          'donneesPersonnelles': {
            'nomConducteur': 'Martin',
            'prenomConducteur': 'Marie',
            'adresseConducteur': '456 Avenue Bourguiba, Sfax',
            'telephoneConducteur': '+216 74 987 654',
            'numeroPermis': 'TN987654321',
            'dateDelivrancePermis': Timestamp.fromDate(DateTime(2015, 8, 20)),
          },
          
          // Données du véhicule
          'vehicule': {
            'marque': 'Renault',
            'modele': 'Clio',
            'immatriculation': '789 TUN 012',
            'annee': 2018,
            'couleur': 'Rouge',
            'typeVehicule': 'Voiture particulière',
          },
          
          // Dégâts et points de choc
          'pointsChoc': ['Arrière droit', 'Feu arrière'],
          'degats': {
            'description': 'Enfoncement de la portière arrière droite et feu cassé',
            'gravite': 'leger',
          },
          'photosDegats': ['photo3.jpg'],
          
          // Circonstances
          'circonstancesSelectionnees': [
            'stationnait',
            'quittait_stationnement'
          ],
          
          // Observations
          'observations': 'J\'étais en train de sortir de ma place de parking quand l\'autre véhicule m\'a percuté.',
          
          'estProprietaire': false,
          'relationProprietaire': 'Épouse du propriétaire',
        }
      };

      // 5. Signatures
      final signatures = {
        'user1_test': {
          'nom': 'Jean Dupont',
          'dateSignature': Timestamp.now(),
          'signatureUrl': 'signature1.png',
          'estSigne': true,
        },
        'user2_test': {
          'nom': 'Marie Martin',
          'dateSignature': Timestamp.now(),
          'signatureUrl': 'signature2.png',
          'estSigne': true,
        }
      };

      // 6. Croquis
      final croquisData = {
        'imageUrl': 'croquis_test.png',
        'dateCreation': Timestamp.now(),
        'validePar': ['user1_test', 'user2_test'],
        'elements': [
          {
            'type': 'vehicle',
            'position': {'x': 100, 'y': 150},
            'label': 'A',
          },
          {
            'type': 'vehicle', 
            'position': {'x': 200, 'y': 150},
            'label': 'B',
          }
        ],
      };

      // 7. Sauvegarder dans Firestore
      await _firestore.collection('sessions_collaboratives').doc(sessionId).set(sessionData);
      
      await _firestore.collection('sessions_collaboratives').doc(sessionId)
          .collection('donnees_accident').doc('infos').set(donneesAccident);
      
      for (final entry in formulaires.entries) {
        await _firestore.collection('sessions_collaboratives').doc(sessionId)
            .collection('participants_data').doc(entry.key).set({
          'donneesFormulaire': entry.value,
        });
      }
      
      await _firestore.collection('sessions_collaboratives').doc(sessionId)
          .collection('signatures').doc('all').set(signatures);
      
      await _firestore.collection('sessions_collaboratives').doc(sessionId)
          .collection('croquis').doc('main').set(croquisData);

      print('✅ [TEST] Données de test créées avec succès: $sessionId');
      return sessionId;
      
    } catch (e) {
      print('❌ [TEST] Erreur création données test: $e');
      rethrow;
    }
  }

  /// 🧪 Tester la génération PDF avec les données complètes
  static Future<void> testerGenerationPDFComplete() async {
    try {
      print('🧪 [TEST] Début test génération PDF complète...');
      
      // 1. Créer les données de test
      final sessionId = await creerDonneesTestCompletes();
      
      // 2. Attendre un peu pour que Firestore soit synchronisé
      await Future.delayed(const Duration(seconds: 2));
      
      // 3. Générer le PDF
      print('📄 [TEST] Génération du PDF...');
      final pdfUrl = await TunisianConstatPdfService.genererConstatTunisien(
        sessionId: sessionId,
      );
      
      print('✅ [TEST] PDF généré avec succès: $pdfUrl');
      
      // 4. Nettoyer les données de test
      await _nettoyerDonneesTest(sessionId);
      
    } catch (e) {
      print('❌ [TEST] Erreur test génération PDF: $e');
      rethrow;
    }
  }

  /// 🧹 Nettoyer les données de test
  static Future<void> _nettoyerDonneesTest(String sessionId) async {
    try {
      print('🧹 [TEST] Nettoyage des données de test...');
      
      // Supprimer toutes les sous-collections
      final collections = ['donnees_accident', 'participants_data', 'signatures', 'croquis'];
      
      for (final collection in collections) {
        final docs = await _firestore.collection('sessions_collaboratives')
            .doc(sessionId).collection(collection).get();
        
        for (final doc in docs.docs) {
          await doc.reference.delete();
        }
      }
      
      // Supprimer le document principal
      await _firestore.collection('sessions_collaboratives').doc(sessionId).delete();
      
      print('✅ [TEST] Données de test nettoyées');
      
    } catch (e) {
      print('⚠️ [TEST] Erreur nettoyage: $e');
    }
  }
}

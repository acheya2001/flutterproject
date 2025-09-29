import 'package:flutter/material.dart';
import 'modern_tunisian_pdf_service.dart';
import 'test_pdf_moderne.dart';

/// 🧪 Service de test pour le générateur PDF de constat tunisien
class TestPdfService {
  
  /// 📋 Générer des données de test complètes pour le constat
  static Map<String, dynamic> genererDonneesTest() {
    return {
      'sessionId': 'TEST_${DateTime.now().millisecondsSinceEpoch}',
      'dateAccident': DateTime.now().toIso8601String(),
      'heureAccident': '14:30',
      'lieuAccident': 'Avenue Habib Bourguiba, Tunis',
      'degatsMateriels': true,
      'blesses': false,
      'temoins': [
        {
          'nom': 'Ahmed Ben Ali',
          'telephone': '+216 98 123 456',
          'adresse': 'Rue de la République, Tunis'
        }
      ],
      'observations': [
        {
          'type': 'general',
          'contenu': 'Collision frontale à faible vitesse'
        },
        {
          'type': 'remarque', 
          'contenu': 'Conditions météorologiques normales'
        }
      ],
      'vehicules': [
        {
          'index': 0,
          'assurance': {
            'compagnie': 'STAR Assurances',
            'numeroPolice': 'POL123456789',
            'agence': 'Agence Tunis Centre',
            'validiteDebut': '2024-01-01',
            'validiteFin': '2024-12-31',
            'attestationVerte': true
          },
          'conducteur': {
            'nom': 'Mohamed',
            'prenom': 'Salah',
            'dateNaissance': '1985-03-15',
            'adresse': '123 Rue de la Liberté, Tunis',
            'telephone': '+216 98 765 432',
            'permis': {
              'numero': 'P123456789',
              'categorie': 'B',
              'dateObtention': '2005-06-20',
              'validite': '2030-06-20'
            }
          },
          'vehicule': {
            'marque': 'Peugeot',
            'modele': '208',
            'immatriculation': '123 TUN 456',
            'couleur': 'Blanc',
            'annee': 2020,
            'numeroSerie': 'VF3XXXXXXXXXXXXXXX',
            'puissance': '75 CV'
          },
          'pointChoc': {
            'avant': true,
            'arriere': false,
            'droite': false,
            'gauche': false,
            'description': 'Choc frontal côté droit'
          },
          'degatsApparents': [
            'Pare-chocs avant endommagé',
            'Phare droit cassé',
            'Capot légèrement déformé'
          ],
          'circonstances': [
            'Stationnait',
            'Quittait un stationnement',
            'Prenait place dans la circulation'
          ]
        },
        {
          'index': 1,
          'assurance': {
            'compagnie': 'AMI Assurances',
            'numeroPolice': 'AMI987654321',
            'agence': 'Agence Sfax',
            'validiteDebut': '2024-02-01',
            'validiteFin': '2025-01-31',
            'attestationVerte': true
          },
          'conducteur': {
            'nom': 'Fatma',
            'prenom': 'Zahra',
            'dateNaissance': '1990-07-22',
            'adresse': '456 Avenue de la République, Sfax',
            'telephone': '+216 97 111 222',
            'permis': {
              'numero': 'P987654321',
              'categorie': 'B',
              'dateObtention': '2010-09-15',
              'validite': '2035-09-15'
            }
          },
          'vehicule': {
            'marque': 'Renault',
            'modele': 'Clio',
            'immatriculation': '789 TUN 012',
            'couleur': 'Rouge',
            'annee': 2019,
            'numeroSerie': 'VF1XXXXXXXXXXXXXXX',
            'puissance': '90 CV'
          },
          'pointChoc': {
            'avant': true,
            'arriere': false,
            'droite': true,
            'gauche': false,
            'description': 'Choc frontal côté gauche'
          },
          'degatsApparents': [
            'Pare-chocs avant déformé',
            'Aile gauche rayée',
            'Rétroviseur gauche cassé'
          ],
          'circonstances': [
            'Allait tout droit',
            'Tournait à droite',
            'Changeait de file'
          ]
        }
      ],
      'croquisUrl': 'https://example.com/croquis.jpg',
      'signature': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
      'signatureTimestamp': DateTime.now().toIso8601String()
    };
  }

  /// 🧪 Tester la génération du PDF avec des données complètes
  static Future<void> testerGenerationPdf(BuildContext context) async {
    try {
      // Utiliser une session réelle existante pour le test
      const sessionIdTest = 'FJqpcwzC86m9EsXs1PcC';

      // Utiliser le nouveau service de test avec vérification
      await TestPdfModerne.testerGenerationPdfAvecVerification(context, sessionIdTest);
      return;
    } catch (e) {
      // Afficher l'erreur
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('❌ Erreur'),
          content: Text('Erreur lors du test PDF:\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    }
  }

  /// 📊 Afficher les statistiques des données de test
  static void afficherStatistiques(BuildContext context) {
    final donnees = genererDonneesTest();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 Statistiques des données de test'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🚗 Nombre de véhicules: ${donnees['vehicules'].length}'),
              Text('👥 Nombre de témoins: ${donnees['temoins'].length}'),
              Text('📝 Nombre d\'observations: ${donnees['observations'].length}'),
              const SizedBox(height: 10),
              const Text('🔍 Détails:'),
              Text('• Date: ${donnees['dateAccident']}'),
              Text('• Heure: ${donnees['heureAccident']}'),
              Text('• Lieu: ${donnees['lieuAccident']}'),
              Text('• Dégâts matériels: ${donnees['degatsMateriels'] ? 'Oui' : 'Non'}'),
              Text('• Blessés: ${donnees['blesses'] ? 'Oui' : 'Non'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

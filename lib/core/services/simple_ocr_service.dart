import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// 📄 Service OCR simplifié pour PFE
/// Version sans dépendances externes - retourne des données simulées
/// Parfait pour démonstration et soutenance
class SimpleOCRService {
  
  /// 🆔 Extraire les informations d'un permis de conduire (SIMULÉ)
  Future<Map<String, dynamic>?> extractPermisInfo(File imageFile) async {
    try {
      debugPrint('[SimpleOCR] Simulation extraction permis de conduire');
      
      // Simulation d'un délai de traitement
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Données simulées réalistes pour un permis tunisien
      return {
        'numero': 'TN${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        'nom': 'HAMMAMI',
        'prenom': 'Rahma',
        'dateNaissance': '15/03/1995',
        'lieuNaissance': 'Tunis',
        'dateDelivrance': DateFormat('dd/MM/yyyy').format(DateTime.now().subtract(const Duration(days: 365))),
        'dateExpiration': DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 3650))),
        'categories': ['B', 'A1'],
        'confidence': 0.85,
        'source': 'simulation_ocr',
      };
    } catch (e) {
      debugPrint('[SimpleOCR] Erreur simulation permis: $e');
      return null;
    }
  }

  /// 🆔 Extraire les informations d'une CIN (SIMULÉ)
  Future<Map<String, dynamic>?> extractCINInfo(File imageFile) async {
    try {
      debugPrint('[SimpleOCR] Simulation extraction CIN');
      
      await Future.delayed(const Duration(milliseconds: 1200));
      
      return {
        'numero': '${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        'nom': 'HAMMAMI',
        'prenom': 'Rahma',
        'nomPere': 'Mohamed',
        'nomMere': 'Fatma',
        'dateNaissance': '15/03/1995',
        'lieuNaissance': 'Tunis',
        'adresse': 'Avenue Habib Bourguiba, Tunis',
        'dateDelivrance': DateFormat('dd/MM/yyyy').format(DateTime.now().subtract(const Duration(days: 1095))),
        'confidence': 0.88,
        'source': 'simulation_ocr',
      };
    } catch (e) {
      debugPrint('[SimpleOCR] Erreur simulation CIN: $e');
      return null;
    }
  }

  /// 🚗 Extraire les informations d'une carte grise (SIMULÉ)
  Future<Map<String, dynamic>?> extractCarteGriseInfo(File imageFile) async {
    try {
      debugPrint('[SimpleOCR] Simulation extraction carte grise');
      
      await Future.delayed(const Duration(milliseconds: 1800));
      
      final currentYear = DateTime.now().year;
      final randomYear = currentYear - (5 + (DateTime.now().millisecond % 15));
      
      return {
        'numeroImmatriculation': '${DateTime.now().millisecond}TUN${DateTime.now().second}',
        'marque': ['Toyota', 'Peugeot', 'Renault', 'Hyundai'][DateTime.now().second % 4],
        'modele': ['Corolla', '208', 'Clio', 'i20'][DateTime.now().second % 4],
        'annee': randomYear.toString(),
        'couleur': ['Blanc', 'Noir', 'Gris', 'Rouge'][DateTime.now().second % 4],
        'numeroSerie': 'VF${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        'puissance': '${90 + (DateTime.now().second % 50)} CV',
        'proprietaire': 'HAMMAMI Rahma',
        'datePremiereImmatriculation': DateFormat('dd/MM/yyyy').format(DateTime(randomYear, 1, 1)),
        'confidence': 0.82,
        'source': 'simulation_ocr',
      };
    } catch (e) {
      debugPrint('[SimpleOCR] Erreur simulation carte grise: $e');
      return null;
    }
  }

  /// 🛡️ Extraire les informations d'une attestation d'assurance (SIMULÉ)
  Future<Map<String, dynamic>?> extractAssuranceInfo(File imageFile) async {
    try {
      debugPrint('[SimpleOCR] Simulation extraction attestation assurance');
      
      await Future.delayed(const Duration(milliseconds: 1400));
      
      final compagnies = ['STAR', 'GAT', 'COMAR', 'MAGHREBIA'];
      final types = ['Tous Risques', 'Tiers Complet', 'Responsabilité Civile'];
      
      return {
        'compagnie': compagnies[DateTime.now().second % compagnies.length],
        'numeroPolice': 'POL${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
        'typeAssurance': types[DateTime.now().second % types.length],
        'dateDebut': DateFormat('dd/MM/yyyy').format(DateTime.now().subtract(const Duration(days: 30))),
        'dateFin': DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 335))),
        'vehiculeImmatriculation': '${DateTime.now().millisecond}TUN${DateTime.now().second}',
        'assure': 'HAMMAMI Rahma',
        'agence': 'Agence Tunis Centre',
        'confidence': 0.79,
        'source': 'simulation_ocr',
      };
    } catch (e) {
      debugPrint('[SimpleOCR] Erreur simulation assurance: $e');
      return null;
    }
  }

  /// 📄 Extraction de texte générique (SIMULÉ)
  Future<String> extractText(File imageFile) async {
    try {
      debugPrint('[SimpleOCR] Simulation extraction texte générique');
      
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Texte simulé basé sur le nom du fichier ou contenu générique
      final fileName = imageFile.path.split('/').last.toLowerCase();
      
      if (fileName.contains('permis')) {
        return 'RÉPUBLIQUE TUNISIENNE\nPERMIS DE CONDUIRE\nNom: HAMMAMI\nPrénom: Rahma\nCatégories: B, A1';
      } else if (fileName.contains('cin')) {
        return 'RÉPUBLIQUE TUNISIENNE\nCARTE D\'IDENTITÉ NATIONALE\nNom: HAMMAMI\nPrénom: Rahma\nNé(e) le: 15/03/1995';
      } else if (fileName.contains('carte') || fileName.contains('grise')) {
        return 'CARTE GRISE\nImmatriculation: 123TUN456\nMarque: Toyota\nModèle: Corolla\nAnnée: 2018';
      } else if (fileName.contains('assurance')) {
        return 'ATTESTATION D\'ASSURANCE\nCompagnie: STAR\nPolice: POL123456\nVéhicule: 123TUN456\nValide jusqu\'au: 31/12/2024';
      } else {
        return 'Texte extrait de l\'image\nContenu simulé pour démonstration\nService OCR simplifié\nPour PFE - Version gratuite';
      }
    } catch (e) {
      debugPrint('[SimpleOCR] Erreur simulation extraction texte: $e');
      return 'Erreur lors de l\'extraction du texte';
    }
  }

  /// 🔍 Rechercher des mots-clés dans une image (SIMULÉ)
  Future<List<String>> findKeywords(File imageFile, List<String> keywords) async {
    try {
      debugPrint('[SimpleOCR] Simulation recherche mots-clés: $keywords');
      
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Simulation : retourne quelques mots-clés trouvés
      final foundKeywords = <String>[];
      final fileName = imageFile.path.toLowerCase();
      
      for (final keyword in keywords) {
        // Simulation basée sur le nom du fichier et des probabilités
        if (fileName.contains(keyword.toLowerCase()) || 
            DateTime.now().millisecond % 3 == 0) {
          foundKeywords.add(keyword);
        }
      }
      
      // Ajouter quelques mots-clés génériques si rien trouvé
      if (foundKeywords.isEmpty) {
        foundKeywords.addAll(['document', 'texte', 'information']);
      }
      
      return foundKeywords;
    } catch (e) {
      debugPrint('[SimpleOCR] Erreur simulation recherche: $e');
      return [];
    }
  }

  /// 📊 Obtenir les statistiques de confiance (SIMULÉ)
  Future<Map<String, double>> getConfidenceStats(File imageFile) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final random = DateTime.now().millisecond;
      return {
        'overall': 0.75 + (random % 20) / 100, // 75-95%
        'text_quality': 0.70 + (random % 25) / 100, // 70-95%
        'image_clarity': 0.80 + (random % 15) / 100, // 80-95%
        'processing_time': (1000 + random % 2000) / 1000, // 1-3 secondes
      };
    } catch (e) {
      debugPrint('[SimpleOCR] Erreur simulation stats: $e');
      return {
        'overall': 0.75,
        'text_quality': 0.70,
        'image_clarity': 0.80,
        'processing_time': 1.5,
      };
    }
  }

  /// 🧹 Nettoyer les ressources (SIMULÉ)
  Future<void> dispose() async {
    debugPrint('[SimpleOCR] Nettoyage des ressources (simulation)');
    // Rien à nettoyer dans la version simulée
  }

  /// ✅ Vérifier si le service est disponible
  bool get isAvailable => true; // Toujours disponible en mode simulation

  /// 📋 Obtenir les informations du service
  Map<String, dynamic> get serviceInfo => {
    'name': 'SimpleOCR Service',
    'version': '1.0.0',
    'type': 'simulation',
    'features': [
      'Extraction permis de conduire',
      'Extraction CIN',
      'Extraction carte grise',
      'Extraction attestation assurance',
      'Extraction texte générique',
      'Recherche mots-clés',
      'Statistiques de confiance',
    ],
    'cost': 'Gratuit',
    'dependencies': 'Aucune',
  };
}

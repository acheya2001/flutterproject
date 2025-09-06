import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicule_model.dart';

/// 🚗 Service de gestion des véhicules
class VehiculeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'vehicules_assures';

  /// 📋 Obtenir tous les véhicules d'un utilisateur
  static Future<List<VehiculeModel>> obtenirVehiculesUtilisateur(String userId) async {
    try {
      // D'abord essayer dans vehicules_assures
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('conducteurId', isEqualTo: userId)
          .get();

      List<VehiculeModel> vehicules = [];

      if (querySnapshot.docs.isNotEmpty) {
        vehicules = querySnapshot.docs.map((doc) {
          final data = doc.data();

          // Conversion sécurisée de l'année
          int annee = DateTime.now().year;
          if (data['annee'] != null) {
            if (data['annee'] is int) {
              annee = data['annee'];
            } else if (data['annee'] is String) {
              annee = int.tryParse(data['annee']) ?? DateTime.now().year;
            }
          }

          return VehiculeModel(
            id: doc.id,
            conducteurId: data['conducteurId'] ?? '',
            marque: data['marque'] ?? '',
            modele: data['modele'] ?? '',
            numeroImmatriculation: data['numeroImmatriculation'] ?? '',
            couleur: data['couleur'] ?? '',
            annee: annee,
            compagnieAssurance: data['compagnieAssurance'],
            numeroPolice: data['numeroPolice'],
            contratActif: data['contratActif'] ?? false,
            createdAt: (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt: (data['dateModification'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        }).toList();
      } else {
        // Si aucun véhicule dans vehicules_assures, chercher dans demandes_contrats
        print('🔍 Recherche dans demandes_contrats pour userId: $userId');
        final demandesSnapshot = await _firestore
            .collection('demandes_contrats')
            .where('conducteurId', isEqualTo: userId)
            .where('statut', whereIn: ['contrat_actif', 'documents_completes', 'frequence_choisie'])
            .get();

        print('📋 ${demandesSnapshot.docs.length} contrats trouvés avec statuts actifs');

        vehicules = demandesSnapshot.docs.map((doc) {
          final data = doc.data();

          print('🚗 Traitement contrat ${doc.id}: ${data['marque']} ${data['modele']} - Statut: ${data['statut']}');

          // Conversion sécurisée de l'année
          int annee = DateTime.now().year;
          if (data['annee'] != null) {
            if (data['annee'] is int) {
              annee = data['annee'];
            } else if (data['annee'] is String) {
              annee = int.tryParse(data['annee']) ?? DateTime.now().year;
            }
          }

          final statutsActifs = ['contrat_actif', 'documents_completes', 'frequence_choisie'];
          final contratActif = statutsActifs.contains(data['statut']);
          print('  ✅ Contrat actif: $contratActif (statut: ${data['statut']})');

          return VehiculeModel(
            id: doc.id,
            conducteurId: data['conducteurId'] ?? '',
            marque: data['marque'] ?? '',
            modele: data['modele'] ?? '',
            numeroImmatriculation: data['numeroImmatriculation'] ?? '',
            couleur: data['couleur'] ?? 'Non spécifiée',
            annee: annee,
            compagnieAssurance: data['compagnieAssurance'],
            numeroPolice: data['numeroPolice'],
            contratActif: contratActif,
            createdAt: (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt: (data['dateModification'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        }).toList();
      }

      // Tri côté client par date de création (plus récent en premier)
      vehicules.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return vehicules;
    } catch (e) {
      print('Erreur lors de la récupération des véhicules: $e');
      return [];
    }
  }

  /// ➕ Ajouter un nouveau véhicule
  static Future<VehiculeModel> ajouterVehicule({
    required String conducteurId,
    required String marque,
    required String modele,
    required String numeroImmatriculation,
    required String couleur,
    required int annee,
    String? compagnieAssurance,
    String? numeroPolice,
    bool contratActif = true,
  }) async {
    try {
      final vehiculeData = {
        'conducteurId': conducteurId,
        'marque': marque,
        'modele': modele,
        'numeroImmatriculation': numeroImmatriculation,
        'couleur': couleur,
        'annee': annee,
        'compagnieAssurance': compagnieAssurance,
        'numeroPolice': numeroPolice,
        'contratActif': contratActif,
        'dateCreation': FieldValue.serverTimestamp(),
        'dateModification': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection(_collection).add(vehiculeData);

      return VehiculeModel(
        id: docRef.id,
        conducteurId: conducteurId,
        marque: marque,
        modele: modele,
        numeroImmatriculation: numeroImmatriculation,
        couleur: couleur,
        annee: annee,
        compagnieAssurance: compagnieAssurance,
        numeroPolice: numeroPolice,
        contratActif: contratActif,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Erreur lors de l\'ajout du véhicule: $e');
      throw Exception('Impossible d\'ajouter le véhicule: $e');
    }
  }

  /// ✏️ Modifier un véhicule existant
  static Future<void> modifierVehicule({
    required String vehiculeId,
    String? marque,
    String? modele,
    String? numeroImmatriculation,
    String? couleur,
    int? annee,
    String? compagnieAssurance,
    String? numeroPolice,
    bool? contratActif,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'dateModification': FieldValue.serverTimestamp(),
      };

      if (marque != null) updateData['marque'] = marque;
      if (modele != null) updateData['modele'] = modele;
      if (numeroImmatriculation != null) updateData['numeroImmatriculation'] = numeroImmatriculation;
      if (couleur != null) updateData['couleur'] = couleur;
      if (annee != null) updateData['annee'] = annee;
      if (compagnieAssurance != null) updateData['compagnieAssurance'] = compagnieAssurance;
      if (numeroPolice != null) updateData['numeroPolice'] = numeroPolice;
      if (contratActif != null) updateData['contratActif'] = contratActif;

      await _firestore.collection(_collection).doc(vehiculeId).update(updateData);
    } catch (e) {
      print('Erreur lors de la modification du véhicule: $e');
      throw Exception('Impossible de modifier le véhicule: $e');
    }
  }

  /// 🗑️ Supprimer un véhicule
  static Future<void> supprimerVehicule(String vehiculeId) async {
    try {
      await _firestore.collection(_collection).doc(vehiculeId).delete();
    } catch (e) {
      print('Erreur lors de la suppression du véhicule: $e');
      throw Exception('Impossible de supprimer le véhicule: $e');
    }
  }

  /// 🔍 Rechercher un véhicule par immatriculation
  static Future<VehiculeModel?> rechercherParImmatriculation(String numeroImmatriculation) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('numeroImmatriculation', isEqualTo: numeroImmatriculation)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      
      return VehiculeModel(
        id: doc.id,
        conducteurId: data['conducteurId'] ?? '',
        marque: data['marque'] ?? '',
        modele: data['modele'] ?? '',
        numeroImmatriculation: data['numeroImmatriculation'] ?? '',
        couleur: data['couleur'] ?? '',
        annee: data['annee'] ?? DateTime.now().year,
        compagnieAssurance: data['compagnieAssurance'],
        numeroPolice: data['numeroPolice'],
        contratActif: data['contratActif'] ?? false,
        createdAt: (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['dateModification'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      print('Erreur lors de la recherche du véhicule: $e');
      return null;
    }
  }

  /// 📊 Obtenir les statistiques des véhicules d'un utilisateur
  static Future<Map<String, int>> obtenirStatistiquesVehicules(String userId) async {
    try {
      final vehicules = await obtenirVehiculesUtilisateur(userId);
      
      return {
        'total': vehicules.length,
        'actifs': vehicules.where((v) => v.contratActif).length,
        'inactifs': vehicules.where((v) => !v.contratActif).length,
      };
    } catch (e) {
      print('Erreur lors du calcul des statistiques: $e');
      return {'total': 0, 'actifs': 0, 'inactifs': 0};
    }
  }

  /// 🔧 Valider les données d'un véhicule
  static Map<String, String> validerVehicule({
    required String marque,
    required String modele,
    required String numeroImmatriculation,
    required String couleur,
    required int annee,
  }) {
    final erreurs = <String, String>{};

    if (marque.trim().isEmpty) {
      erreurs['marque'] = 'La marque est requise';
    }

    if (modele.trim().isEmpty) {
      erreurs['modele'] = 'Le modèle est requis';
    }

    if (numeroImmatriculation.trim().isEmpty) {
      erreurs['numeroImmatriculation'] = 'Le numéro d\'immatriculation est requis';
    } else if (!_validerFormatImmatriculation(numeroImmatriculation)) {
      erreurs['numeroImmatriculation'] = 'Format d\'immatriculation invalide';
    }

    if (couleur.trim().isEmpty) {
      erreurs['couleur'] = 'La couleur est requise';
    }

    final anneeActuelle = DateTime.now().year;
    if (annee < 1900 || annee > anneeActuelle + 1) {
      erreurs['annee'] = 'Année invalide';
    }

    return erreurs;
  }

  /// 🔧 Valider le format d'immatriculation tunisien
  static bool _validerFormatImmatriculation(String immatriculation) {
    // Formats tunisiens acceptés:
    // XXX TUN XXXX (ancien format)
    // XXXX TUN XX (nouveau format)
    final regex = RegExp(r'^\d{3,4}\s?(TUN|تونس)\s?\d{2,4}$', caseSensitive: false);
    return regex.hasMatch(immatriculation.trim());
  }

  /// 🎨 Obtenir les couleurs de véhicules disponibles
  static List<String> obtenirCouleursDisponibles() {
    return [
      'Blanc',
      'Noir',
      'Gris',
      'Argent',
      'Rouge',
      'Bleu',
      'Vert',
      'Jaune',
      'Orange',
      'Marron',
      'Violet',
      'Rose',
      'Beige',
      'Doré',
      'Autre',
    ];
  }

  /// 🏭 Obtenir les marques de véhicules populaires
  static List<String> obtenirMarquesPopulaires() {
    return [
      'Peugeot',
      'Renault',
      'Citroën',
      'Volkswagen',
      'Ford',
      'Opel',
      'Fiat',
      'Seat',
      'Skoda',
      'Hyundai',
      'Kia',
      'Toyota',
      'Nissan',
      'Dacia',
      'BMW',
      'Mercedes',
      'Audi',
      'Autre',
    ];
  }

  /// 🔄 Synchroniser avec les données d'assurance
  static Future<void> synchroniserAvecAssurance(String vehiculeId, Map<String, dynamic> donneesAssurance) async {
    try {
      await _firestore.collection(_collection).doc(vehiculeId).update({
        'compagnieAssurance': donneesAssurance['compagnie'],
        'numeroPolice': donneesAssurance['numeroPolice'],
        'contratActif': donneesAssurance['actif'] ?? true,
        'dateModification': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors de la synchronisation avec l\'assurance: $e');
      throw Exception('Impossible de synchroniser avec l\'assurance: $e');
    }
  }
}

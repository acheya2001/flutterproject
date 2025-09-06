import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import '../models/vehicule_model.dart';
import '../../../services/cloudinary_storage_service.dart';
import '../../../services/vehicle_tracking_service.dart';
import '../../../services/notification_service.dart';

/// 🚗 Service pour gérer les véhicules dans Firestore
class VehiculeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 📝 Créer un nouveau véhicule
  static Future<String> createVehicule(Vehicule vehicule) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // 🎯 AFFECTATION AUTOMATIQUE : Si pas d'agence sélectionnée, affecter automatiquement
      Vehicule vehiculeToSave = vehicule;

      print('🔍 [AFFECTATION] Véhicule reçu - agenceAssuranceId: "${vehiculeToSave.agenceAssuranceId}"');
      print('🔍 [AFFECTATION] Véhicule reçu - compagnieAssuranceId: "${vehiculeToSave.compagnieAssuranceId}"');
      print('🔍 [AFFECTATION] Véhicule reçu - estAssure: ${vehiculeToSave.estAssure}');
      print('🔍 [AFFECTATION] Véhicule reçu - etatCompte: "${vehiculeToSave.etatCompte}"');

      // 🎯 FORCER L'ÉTAT "EN ATTENTE" pour tous les nouveaux véhicules
      vehiculeToSave = vehiculeToSave.copyWith(etatCompte: 'En attente');
      print('🔄 État forcé à "En attente" pour validation par l\'agence');

      if (vehiculeToSave.agenceAssuranceId == null || vehiculeToSave.agenceAssuranceId!.isEmpty) {
        print('🔄 Véhicule sans agence, affectation automatique...');

        // Affecter à une agence par défaut ou selon la localisation
        final agenceInfo = await _assignToDefaultAgency();
        if (agenceInfo != null) {
          vehiculeToSave = Vehicule(
            conducteurId: vehiculeToSave.conducteurId,
            marque: vehiculeToSave.marque,
            modele: vehiculeToSave.modele,
            numeroImmatriculation: vehiculeToSave.numeroImmatriculation,
            couleur: vehiculeToSave.couleur,
            annee: vehiculeToSave.annee,
            typeVehicule: vehiculeToSave.typeVehicule,
            carburant: vehiculeToSave.carburant,
            usage: vehiculeToSave.usage,
            nombrePlaces: vehiculeToSave.nombrePlaces,
            numeroSerie: vehiculeToSave.numeroSerie,
            puissanceFiscale: vehiculeToSave.puissanceFiscale,
            cylindree: vehiculeToSave.cylindree,
            poids: vehiculeToSave.poids,
            genre: vehiculeToSave.genre,
            numeroCarteGrise: vehiculeToSave.numeroCarteGrise,
            datePremiereImmatriculation: vehiculeToSave.datePremiereImmatriculation,
            dateMiseEnCirculation: vehiculeToSave.dateMiseEnCirculation,
            imageCarteGriseUrl: vehiculeToSave.imageCarteGriseUrl,
            nomProprietaire: vehiculeToSave.nomProprietaire,
            prenomProprietaire: vehiculeToSave.prenomProprietaire,
            adresseProprietaire: vehiculeToSave.adresseProprietaire,
            numeroPermis: vehiculeToSave.numeroPermis,
            categoriePermis: vehiculeToSave.categoriePermis,
            dateObtentionPermis: vehiculeToSave.dateObtentionPermis,
            dateExpirationPermis: vehiculeToSave.dateExpirationPermis,
            imagePermisUrl: vehiculeToSave.imagePermisUrl,
            estAssure: vehiculeToSave.estAssure,
            // 🎯 AFFECTATION AUTOMATIQUE
            compagnieAssuranceId: agenceInfo['compagnieId'],
            compagnieAssuranceNom: agenceInfo['compagnieNom'],
            agenceAssuranceId: agenceInfo['agenceId'],
            agenceAssuranceNom: agenceInfo['agenceNom'],
            numeroContratAssurance: vehiculeToSave.numeroContratAssurance,
            typeAssurance: vehiculeToSave.typeAssurance,
            dateDebutAssurance: vehiculeToSave.dateDebutAssurance,
            dateFinAssurance: vehiculeToSave.dateFinAssurance,
            dateDerniereAssurance: vehiculeToSave.dateDerniereAssurance,
            etatCompte: 'En attente', // Forcer le statut en attente
            controleValide: vehiculeToSave.controleValide,
            dateProchainControle: vehiculeToSave.dateProchainControle,
            createdAt: vehiculeToSave.createdAt,
            updatedAt: vehiculeToSave.updatedAt,
            createdBy: vehiculeToSave.createdBy,
            isActive: vehiculeToSave.isActive,
          );

          print('✅ Véhicule affecté à l\'agence: ${agenceInfo['agenceNom']} (${agenceInfo['agenceId']})');
        }
      }

      final vehiculeMap = vehiculeToSave.toFirestore();
      final docRef = await _firestore
          .collection('vehicules')
          .add(vehiculeMap);

      print('✅ Véhicule créé avec succès: ${docRef.id}');
      print('🔍 [AFFECTATION] Véhicule sauvé - agenceAssuranceId: "${vehiculeMap['agenceAssuranceId']}"');
      print('🔍 [AFFECTATION] Véhicule sauvé - compagnieAssuranceId: "${vehiculeMap['compagnieAssuranceId']}"');
      print('🔍 [AFFECTATION] Véhicule sauvé - etatCompte: "${vehiculeMap['etatCompte']}"');

      // 📊 Créer le suivi de statut pour le conducteur
      await VehicleTrackingService.createVehicleTracking(
        vehicleId: docRef.id,
        conducteurId: currentUser.uid,
        agenceId: vehiculeToSave.agenceAssuranceId,
        agenceNom: vehiculeToSave.agenceAssuranceNom,
      );

      // 🔔 Notifier l'agent de l'agence (maintenant toujours définie)
      await _notifyAgentNewVehicle(
        vehiculeId: docRef.id,
        vehicule: vehiculeToSave,
        conducteurId: currentUser.uid,
      );

      return docRef.id;
    } catch (e) {
      print('❌ Erreur création véhicule: $e');
      throw Exception('Erreur lors de la création du véhicule: $e');
    }
  }

  /// 📸 Met à jour les URLs des images d'un véhicule
  static Future<void> updateVehiculeImages(String vehiculeId, String? imageCarteGriseUrl, String? imagePermisUrl) async {
    try {
      final Map<String, dynamic> updates = {
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (imageCarteGriseUrl != null) {
        updates['imageCarteGriseUrl'] = imageCarteGriseUrl;
        print('📄 Mise à jour URL carte grise: $imageCarteGriseUrl');
      }

      if (imagePermisUrl != null) {
        updates['imagePermisUrl'] = imagePermisUrl;
        print('🪪 Mise à jour URL permis: $imagePermisUrl');
      }

      await _firestore.collection('vehicules').doc(vehiculeId).update(updates);
      print('✅ Images mises à jour pour véhicule: $vehiculeId');
    } catch (e) {
      print('❌ Erreur mise à jour images: $e');
      throw Exception('Erreur lors de la mise à jour des images: $e');
    }
  }

  /// 📖 Obtenir tous les véhicules d'un conducteur
  static Future<List<Vehicule>> getVehiculesByConducteur(String conducteurId) async {
    try {
      final querySnapshot = await _firestore
          .collection('vehicules')
          .where('conducteurId', isEqualTo: conducteurId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Vehicule.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur récupération véhicules: $e');
      throw Exception('Erreur lors de la récupération des véhicules: $e');
    }
  }

  /// 📖 Obtenir les véhicules du conducteur actuel
  static Future<List<Vehicule>> getMyVehicules() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Utilisateur non connecté');
    }
    return getVehiculesByConducteur(currentUser.uid);
  }

  /// 🔍 Obtenir un véhicule par son ID
  static Future<Vehicule?> getVehiculeById(String vehiculeId) async {
    try {
      final doc = await _firestore
          .collection('vehicules')
          .doc(vehiculeId)
          .get();

      if (doc.exists) {
        return Vehicule.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Erreur récupération véhicule: $e');
      throw Exception('Erreur lors de la récupération du véhicule: $e');
    }
  }

  /// ✏️ Mettre à jour un véhicule
  static Future<void> updateVehicule(String vehiculeId, Vehicule vehicule) async {
    try {
      final updatedVehicule = vehicule.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('vehicules')
          .doc(vehiculeId)
          .update(updatedVehicule.toFirestore());

      print('✅ Véhicule mis à jour avec succès: $vehiculeId');
    } catch (e) {
      print('❌ Erreur mise à jour véhicule: $e');
      throw Exception('Erreur lors de la mise à jour du véhicule: $e');
    }
  }

  /// 🗑️ Supprimer un véhicule (soft delete)
  static Future<void> deleteVehicule(String vehiculeId) async {
    try {
      await _firestore
          .collection('vehicules')
          .doc(vehiculeId)
          .update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Véhicule supprimé avec succès: $vehiculeId');
    } catch (e) {
      print('❌ Erreur suppression véhicule: $e');
      throw Exception('Erreur lors de la suppression du véhicule: $e');
    }
  }

  /// 📷 Uploader une image avec alternatives gratuites
  static Future<String> uploadImage(File imageFile, String vehiculeId, String type) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      print('🚀 Début upload image avec alternatives gratuites...');

      // 1. Tentative Cloudinary (25GB gratuit/mois)
      try {
        final result = await HybridStorageService.uploadImage(
          imageFile: imageFile,
          vehiculeId: vehiculeId,
          type: type,
        );

        if (result['success'] == true) {
          print('✅ ${result['message']}');
          return result['url'];
        }
      } catch (e) {
        print('⚠️ Échec Cloudinary: $e');
      }

      // 2. Imgur temporairement désactivé (simplifié pour test)
      print('⚠️ Imgur non configuré - passage au fallback local');

      // 3. Supabase temporairement désactivé (pas configuré)
      print('⚠️ Supabase non configuré - passage au fallback local');

      // 4. Fallback final: stockage local
      final localPath = await _saveImageLocally(imageFile, vehiculeId, type);
      if (localPath != null) {
        await _markForLaterUpload(vehiculeId, type, localPath);
        print('💾 Image sauvée localement en dernier recours');
        return localPath;
      }

      throw Exception('Impossible de sauvegarder l\'image');
    } catch (e) {
      print('❌ Erreur upload image: $e');
      throw Exception('Erreur lors de l\'upload de l\'image: $e');
    }
  }

  /// 💾 Sauvegarder l'image localement
  static Future<String> _saveImageLocally(File imageFile, String vehiculeId, String type) async {
    try {
      // Créer un répertoire local pour les images en attente
      final directory = await getApplicationDocumentsDirectory();
      final localDir = Directory('${directory.path}/pending_uploads');
      if (!await localDir.exists()) {
        await localDir.create(recursive: true);
      }

      // Copier l'image avec un nom unique
      final fileName = '${vehiculeId}_${type}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localFile = File('${localDir.path}/$fileName');
      await imageFile.copy(localFile.path);

      return localFile.path;
    } catch (e) {
      print('❌ Erreur sauvegarde locale: $e');
      rethrow;
    }
  }

  /// 📝 Marquer l'image pour upload ultérieur
  static Future<void> _markForLaterUpload(String vehiculeId, String type, String localPath) async {
    try {
      await _firestore.collection('pending_uploads').add({
        'vehiculeId': vehiculeId,
        'type': type,
        'localPath': localPath,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      print('❌ Erreur marquage upload: $e');
    }
  }

  /// 🔍 Rechercher des véhicules par numéro d'immatriculation
  static Future<List<Vehicule>> searchVehiculesByPlate(String numeroImmatriculation) async {
    try {
      final querySnapshot = await _firestore
          .collection('vehicules')
          .where('numeroImmatriculation', isEqualTo: numeroImmatriculation.toUpperCase())
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Vehicule.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur recherche véhicule: $e');
      throw Exception('Erreur lors de la recherche du véhicule: $e');
    }
  }

  /// 📊 Obtenir les statistiques des véhicules d'un conducteur
  static Future<Map<String, dynamic>> getVehiculeStats(String conducteurId) async {
    try {
      final vehicules = await getVehiculesByConducteur(conducteurId);
      
      final stats = {
        'total': vehicules.length,
        'assures': vehicules.where((v) => v.estAssure).length,
        'nonAssures': vehicules.where((v) => !v.estAssure).length,
        'controleValide': vehicules.where((v) => v.controleValide).length,
        'controleExpire': vehicules.where((v) => !v.controleValide).length,
        'parType': <String, int>{},
        'parMarque': <String, int>{},
      };

      // Statistiques par type
      final parType = stats['parType'] as Map<String, int>;
      final parMarque = stats['parMarque'] as Map<String, int>;

      for (final vehicule in vehicules) {
        parType[vehicule.typeVehicule] = (parType[vehicule.typeVehicule] ?? 0) + 1;
        parMarque[vehicule.marque] = (parMarque[vehicule.marque] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('❌ Erreur statistiques véhicules: $e');
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }

  /// 🔔 Vérifier les véhicules avec contrôle technique expiré
  static Future<List<Vehicule>> getVehiculesControleExpire(String conducteurId) async {
    try {
      final vehicules = await getVehiculesByConducteur(conducteurId);
      final now = DateTime.now();
      
      return vehicules.where((vehicule) {
        if (vehicule.dateProchainControle == null) return false;
        return vehicule.dateProchainControle!.isBefore(now);
      }).toList();
    } catch (e) {
      print('❌ Erreur vérification contrôle: $e');
      throw Exception('Erreur lors de la vérification du contrôle technique: $e');
    }
  }

  /// 🔔 Vérifier les véhicules avec assurance expirée
  static Future<List<Vehicule>> getVehiculesAssuranceExpiree(String conducteurId) async {
    try {
      final vehicules = await getVehiculesByConducteur(conducteurId);
      final now = DateTime.now();
      
      return vehicules.where((vehicule) {
        if (!vehicule.estAssure || vehicule.dateFinAssurance == null) return false;
        return vehicule.dateFinAssurance!.isBefore(now);
      }).toList();
    } catch (e) {
      print('❌ Erreur vérification assurance: $e');
      throw Exception('Erreur lors de la vérification de l\'assurance: $e');
    }
  }

  /// 📋 Valider les données d'un véhicule
  static String? validateVehicule(Vehicule vehicule) {
    if (vehicule.marque.isEmpty) return 'La marque est obligatoire';
    if (vehicule.modele.isEmpty) return 'Le modèle est obligatoire';
    if (vehicule.numeroImmatriculation.isEmpty) return 'Le numéro d\'immatriculation est obligatoire';
    if (vehicule.numeroCarteGrise.isEmpty) return 'Le numéro de carte grise est obligatoire';
    if (vehicule.numeroPermis.isEmpty) return 'Le numéro de permis est obligatoire';
    if (vehicule.nomProprietaire.isEmpty) return 'Le nom du propriétaire est obligatoire';
    if (vehicule.prenomProprietaire.isEmpty) return 'Le prénom du propriétaire est obligatoire';
    
    // Validation des dates
    final now = DateTime.now();
    if (vehicule.dateExpirationPermis.isBefore(now)) {
      return 'Le permis de conduire est expiré';
    }
    
    if (vehicule.estAssure && vehicule.dateFinAssurance != null) {
      if (vehicule.dateFinAssurance!.isBefore(now)) {
        return 'L\'assurance est expirée';
      }
    }
    
    return null; // Pas d'erreur
  }

  /// 🎯 Affecter automatiquement un véhicule à une agence par défaut
  static Future<Map<String, String>?> _assignToDefaultAgency() async {
    try {
      print('🔍 Recherche d\'une agence par défaut...');

      // Essayer plusieurs collections possibles
      final collectionsToTry = ['agences_assurance', 'agences', 'agencies'];

      for (final collectionName in collectionsToTry) {
        print('🔍 Tentative avec collection: $collectionName');

        try {
          final agencesSnapshot = await _firestore
              .collection(collectionName)
              .limit(5) // Récupérer les 5 premières pour debug
              .get();

          print('📊 ${agencesSnapshot.docs.length} documents trouvés dans $collectionName');

          if (agencesSnapshot.docs.isNotEmpty) {
            // Afficher toutes les agences trouvées pour debug
            for (var doc in agencesSnapshot.docs) {
              final data = doc.data();
              print('🏢 Agence trouvée: ${doc.id} - ${data['nom'] ?? 'Sans nom'} - Status: ${data['status'] ?? data['isActive'] ?? 'N/A'}');
            }

            // Chercher une agence active
            DocumentSnapshot? agenceDoc;
            for (var doc in agencesSnapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final isActive = data['status'] == 'active' ||
                              data['isActive'] == true ||
                              data['status'] == null; // Par défaut active si pas de status

              if (isActive) {
                agenceDoc = doc;
                break;
              }
            }

            // Si aucune agence active, prendre la première
            agenceDoc ??= agencesSnapshot.docs.first;

            final agenceData = agenceDoc.data() as Map<String, dynamic>;
            final agenceId = agenceDoc.id;
            final agenceNom = agenceData['nom'] ?? 'Agence par défaut';
            final compagnieId = agenceData['compagnieId'] ?? agenceData['compagnieAssuranceId'];

            print('✅ Agence sélectionnée: $agenceNom (ID: $agenceId)');

            // Récupérer les infos de la compagnie
            String compagnieNom = 'Compagnie par défaut';
            if (compagnieId != null) {
              try {
                final compagnieDoc = await _firestore
                    .collection('compagnies_assurance')
                    .doc(compagnieId)
                    .get();

                if (compagnieDoc.exists) {
                  compagnieNom = compagnieDoc.data()?['nom'] ?? compagnieNom;
                } else {
                  // Essayer avec 'compagnies'
                  final compagnieDoc2 = await _firestore
                      .collection('compagnies')
                      .doc(compagnieId)
                      .get();

                  if (compagnieDoc2.exists) {
                    compagnieNom = compagnieDoc2.data()?['nom'] ?? compagnieNom;
                  }
                }
              } catch (e) {
                print('⚠️ Erreur récupération compagnie: $e');
              }
            }

            print('✅ Affectation: Agence "$agenceNom" (ID: $agenceId) - Compagnie: "$compagnieNom"');

            return {
              'agenceId': agenceId,
              'agenceNom': agenceNom,
              'compagnieId': compagnieId ?? '',
              'compagnieNom': compagnieNom,
            };
          }
        } catch (e) {
          print('⚠️ Erreur avec collection $collectionName: $e');
          continue;
        }
      }

      print('❌ Aucune agence trouvée dans toutes les collections testées');

      // FALLBACK: Utiliser l'agence connue directement
      print('🔄 Utilisation de l\'agence connue en fallback...');
      return {
        'agenceId': '3SlpifCIp4Wp5bMXdcD1',
        'agenceNom': 'test agence final',
        'compagnieId': 'testini_comp_id',
        'compagnieNom': 'testini',
      };

    } catch (e) {
      print('❌ Erreur générale affectation agence: $e');

      // FALLBACK: Utiliser l'agence connue directement
      print('🔄 Utilisation de l\'agence connue en fallback d\'urgence...');
      return {
        'agenceId': '3SlpifCIp4Wp5bMXdcD1',
        'agenceNom': 'test agence final',
        'compagnieId': 'testini_comp_id',
        'compagnieNom': 'testini',
      };
    }
  }

  /// 🔔 Notifier l'agent quand un nouveau véhicule est ajouté
  static Future<void> _notifyAgentNewVehicle({
    required String vehiculeId,
    required Vehicule vehicule,
    required String conducteurId,
  }) async {
    try {
      // Vérifier que l'agence est définie
      if (vehicule.agenceAssuranceId == null || vehicule.agenceAssuranceId!.isEmpty) {
        print('⚠️ Pas d\'agence définie pour la notification');
        return;
      }

      // Récupérer les infos du conducteur
      final conducteurDoc = await _firestore.collection('users').doc(conducteurId).get();
      if (!conducteurDoc.exists) return;

      final conducteurData = conducteurDoc.data()!;
      final conducteurNom = '${conducteurData['prenom'] ?? ''} ${conducteurData['nom'] ?? ''}'.trim();

      // Construire les infos du véhicule
      final vehiculeInfo = '${vehicule.marque} ${vehicule.modele} (${vehicule.numeroImmatriculation})';

      // Envoyer la notification
      await NotificationService.notifyAgentNewVehicule(
        agenceId: vehicule.agenceAssuranceId!,
        vehiculeId: vehiculeId,
        conducteurId: conducteurId,
        conducteurNom: conducteurNom.isNotEmpty ? conducteurNom : 'Conducteur',
        vehiculeInfo: vehiculeInfo,
      );

      print('🔔 Notification envoyée à l\'agence ${vehicule.agenceAssuranceId}');
    } catch (e) {
      print('❌ Erreur notification agent: $e');
      // Ne pas faire échouer la création du véhicule si la notification échoue
    }
  }
}

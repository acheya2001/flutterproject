import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/constat_officiel_model.dart';
import '../../conducteur/models/conducteur_profile_model.dart';
import '../../conducteur/models/conducteur_vehicle_model.dart';

/// 🔧 Service pour la gestion du constat amiable officiel
class ConstatOfficielService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Créer un nouveau constat avec auto-remplissage
  Future<ConstatOfficielModel> createNewConstat({
    required List<String> vehicleIds,
    required String currentUserId,
  }) async {
    try {
      final constatsRef = _firestore.collection('constats_officiels');
      final newConstatRef = constatsRef.doc();

      // Créer les parties basées sur les véhicules sélectionnés
      final parties = <ConstatPartieModel>[];
      
      for (int i = 0; i < vehicleIds.length; i++) {
        final partieId = String.fromCharCode(65 + i); // A, B, C, D...
        final vehicleId = vehicleIds[i];
        
        // Récupérer les données du véhicule et du conducteur
        final partieData = await _getPartieDataFromVehicle(vehicleId, currentUserId);
        
        final partie = ConstatPartieModel(
          partieId: partieId,
          conducteurUid: partieData['conducteurUid'],
          isEditable: partieData['conducteurUid'] == currentUserId,
          // Données d'assurance
          societeAssurance: partieData['societeAssurance'],
          numeroContrat: partieData['numeroContrat'],
          agence: partieData['agence'],
          attestationValable: partieData['attestationValable'],
          // Données conducteur
          nomConducteur: partieData['nomConducteur'],
          prenomConducteur: partieData['prenomConducteur'],
          adresseConducteur: partieData['adresseConducteur'],
          telephoneConducteur: partieData['telephoneConducteur'],
          permisNumero: partieData['permisNumero'],
          permisDelivreLe: partieData['permisDelivreLe'],
          permisValableJusquau: partieData['permisValableJusquau'],
          categoriePermis: partieData['categoriePermis'],
          // Données véhicule
          marqueVehicule: partieData['marqueVehicule'],
          typeVehicule: partieData['typeVehicule'],
          numeroImmatriculation: partieData['numeroImmatriculation'],
          paysImmatriculation: partieData['paysImmatriculation'],
          degatsApparents: [],
        );
        
        parties.add(partie);
      }

      final constat = ConstatOfficielModel(
        id: newConstatRef.id,
        dateAccident: DateTime.now(),
        parties: parties,
        observations: [],
        circumstances: {},
        createdAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
        createdBy: currentUserId,
      );

      await newConstatRef.set(constat.toMap());
      return constat;
    } catch (e) {
      throw Exception('Erreur lors de la création du constat: $e');
    }
  }

  /// Récupérer les données d'une partie à partir d'un véhicule
  Future<Map<String, dynamic>> _getPartieDataFromVehicle(
    String vehicleId, 
    String currentUserId,
  ) async {
    try {
      // Récupérer le véhicule
      final vehicleDoc = await _firestore
          .collection('conducteurs')
          .doc(currentUserId)
          .collection('vehicles')
          .doc(vehicleId)
          .get();

      if (!vehicleDoc.exists) {
        throw Exception('Véhicule non trouvé');
      }

      final vehicle = ConducteurVehicleModel.fromMap(vehicleDoc.data()!);
      
      // Récupérer le profil du conducteur
      final conducteurDoc = await _firestore
          .collection('conducteurs')
          .doc(currentUserId)
          .get();

      ConducteurProfileModel? conducteur;
      if (conducteurDoc.exists) {
        conducteur = ConducteurProfileModel.fromMap(conducteurDoc.data()!);
      }

      // Récupérer le contrat actif
      final activeContract = vehicle.activeContract;

      return {
        'conducteurUid': currentUserId,
        // Données d'assurance
        'societeAssurance': activeContract?.companyName,
        'numeroContrat': activeContract?.contractNumber,
        'agence': activeContract?.agencyName,
        'attestationValable': activeContract?.isValid == true ? 'Oui' : 'Non',
        // Données conducteur
        'nomConducteur': conducteur?.lastName,
        'prenomConducteur': conducteur?.firstName,
        'adresseConducteur': _formatAddress(conducteur),
        'telephoneConducteur': conducteur?.phone,
        'permisNumero': conducteur?.drivingLicense?.licenseNumber,
        'permisDelivreLe': _formatDate(conducteur?.drivingLicense?.issueDate),
        'permisValableJusquau': _formatDate(conducteur?.drivingLicense?.expiryDate),
        'categoriePermis': conducteur?.drivingLicense?.category,
        // Données véhicule
        'marqueVehicule': vehicle.brand,
        'typeVehicule': vehicle.model,
        'numeroImmatriculation': vehicle.plate,
        'paysImmatriculation': 'Tunisie',
      };
    } catch (e) {
      // Retourner des données vides en cas d'erreur
      return {
        'conducteurUid': currentUserId,
      };
    }
  }

  /// Récupérer un constat existant
  Future<ConstatOfficielModel?> getConstat(String constatsId) async {
    try {
      final doc = await _firestore
          .collection('constats_officiels')
          .doc(constatsId)
          .get();

      if (!doc.exists) return null;

      final constat = ConstatOfficielModel.fromMap(doc.data()!);
      
      // Mettre à jour les permissions d'édition
      final currentUserId = _auth.currentUser?.uid;
      final updatedParties = constat.parties.map((partie) {
        return partie.copyWith(
          isEditable: partie.conducteurUid == currentUserId,
        );
      }).toList();

      return constat.copyWith(parties: updatedParties);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du constat: $e');
    }
  }

  /// Mettre à jour un constat
  Future<void> updateConstat(ConstatOfficielModel constat) async {
    try {
      await _firestore
          .collection('constats_officiels')
          .doc(constat.id)
          .update(constat.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du constat: $e');
    }
  }

  /// Écouter les changements d'un constat en temps réel
  Stream<ConstatOfficielModel?> getConstatStream(String constatsId) {
    return _firestore
        .collection('constats_officiels')
        .doc(constatsId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;

      final constat = ConstatOfficielModel.fromMap(doc.data()!);
      
      // Mettre à jour les permissions d'édition
      final currentUserId = _auth.currentUser?.uid;
      final updatedParties = constat.parties.map((partie) {
        return partie.copyWith(
          isEditable: partie.conducteurUid == currentUserId,
        );
      }).toList();

      return constat.copyWith(parties: updatedParties);
    });
  }

  /// Inviter un conducteur à rejoindre le constat
  Future<void> inviteToConstat({
    required String constatsId,
    required String email,
    required String partieId,
  }) async {
    try {
      // Créer une invitation
      final invitationRef = _firestore.collection('constat_invitations').doc();
      
      await invitationRef.set({
        'id': invitationRef.id,
        'constatsId': constatsId,
        'partieId': partieId,
        'email': email,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': FieldValue.serverTimestamp(), // TODO: Ajouter 24h
        'createdBy': _auth.currentUser?.uid,
      });

      // TODO: Envoyer l'email d'invitation
    } catch (e) {
      throw Exception('Erreur lors de l\'invitation: $e');
    }
  }

  /// Rejoindre un constat via invitation
  Future<void> joinConstat({
    required String invitationId,
    required String vehicleId,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer l'invitation
      final invitationDoc = await _firestore
          .collection('constat_invitations')
          .doc(invitationId)
          .get();

      if (!invitationDoc.exists) {
        throw Exception('Invitation non trouvée');
      }

      final invitation = invitationDoc.data()!;
      final constatsId = invitation['constatsId'] as String;
      final partieId = invitation['partieId'] as String;

      // Récupérer les données du véhicule et conducteur
      final partieData = await _getPartieDataFromVehicle(vehicleId, currentUserId);

      // Mettre à jour la partie dans le constat
      await _firestore
          .collection('constats_officiels')
          .doc(constatsId)
          .update({
        'parties': FieldValue.arrayUnion([
          {
            'partieId': partieId,
            'conducteurUid': currentUserId,
            'isEditable': true,
            ...partieData,
          }
        ]),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Marquer l'invitation comme acceptée
      await invitationDoc.reference.update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        'acceptedBy': currentUserId,
      });
    } catch (e) {
      throw Exception('Erreur lors de la participation au constat: $e');
    }
  }

  /// Formater une adresse
  String? _formatAddress(ConducteurProfileModel? conducteur) {
    if (conducteur?.address == null) return null;
    
    final address = conducteur!.address!;
    return '${address.street ?? ''}, ${address.city ?? ''}, ${address.postalCode ?? ''}, ${address.governorate ?? ''}';
  }

  /// Formater une date
  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Obtenir les constats d'un conducteur
  Future<List<ConstatOfficielModel>> getConducteurConstats(String conducteurUid) async {
    try {
      final querySnapshot = await _firestore
          .collection('constats_officiels')
          .where('parties', arrayContains: {'conducteurUid': conducteurUid})
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ConstatOfficielModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des constats: $e');
    }
  }

  /// Supprimer un constat (seulement si pas encore signé)
  Future<void> deleteConstat(String constatsId) async {
    try {
      final doc = await _firestore
          .collection('constats_officiels')
          .doc(constatsId)
          .get();

      if (!doc.exists) {
        throw Exception('Constat non trouvé');
      }

      final constat = ConstatOfficielModel.fromMap(doc.data()!);
      
      if (constat.isSigned) {
        throw Exception('Impossible de supprimer un constat signé');
      }

      await doc.reference.delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }
}



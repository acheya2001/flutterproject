import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/models/user_model.dart';
import '../../vehicule/models/vehicule_model.dart';
import '../../conducteur/models/conducteur_model.dart';

/// Service pour automatiser le remplissage des formulaires de constat
/// en utilisant les données déjà saisies lors de l'inscription
class AutoFillService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Données pré-remplies pour le formulaire de constat
  static Future<AutoFillData> getAutoFillData({
    required UserModel currentUser,
    VehiculeModel? selectedVehicule,
  }) async {
    debugPrint('[AutoFillService] 🚀 Récupération des données d\'auto-remplissage');
    debugPrint('[AutoFillService] 👤 Utilisateur: ${currentUser.nom} ${currentUser.prenom}');
    debugPrint('[AutoFillService] 🚗 Véhicule sélectionné: ${selectedVehicule?.immatriculation ?? 'Aucun'}');

    try {
      // Récupérer les données détaillées du conducteur
      ConducteurModel? conducteurDetails;
      try {
        final conducteurDoc = await _firestore
            .collection('conducteurs')
            .doc(currentUser.id)
            .get();
        
        if (conducteurDoc.exists) {
          conducteurDetails = ConducteurModel.fromFirestore(conducteurDoc);
          debugPrint('[AutoFillService] ✅ Données conducteur trouvées');
        }
      } catch (e) {
        debugPrint('[AutoFillService] ⚠️ Erreur récupération conducteur: $e');
      }

      return AutoFillData(
        // Données du conducteur
        conducteurNom: currentUser.nom,
        conducteurPrenom: currentUser.prenom,
        conducteurAdresse: currentUser.adresse ?? '',
        conducteurTelephone: currentUser.telephone ?? '',
        conducteurEmail: currentUser.email ?? '',
        
        // Données du permis (si disponibles)
        permisNumero: conducteurDetails?.permisNumero ?? '',
        permisDelivreLe: conducteurDetails?.permisDelivreLe,
        permisValideJusquau: conducteurDetails?.permisValideJusquau,
        
        // Données du véhicule (si sélectionné)
        vehiculeMarque: selectedVehicule?.marque ?? '',
        vehiculeModele: selectedVehicule?.modele ?? '',
        vehiculeImmatriculation: selectedVehicule?.immatriculation ?? '',
        
        // Données d'assurance du véhicule
        assuranceCompagnie: selectedVehicule?.compagnieAssurance ?? '',
        assuranceNumeroContrat: selectedVehicule?.numeroContrat ?? '',
        assuranceAgence: selectedVehicule?.agence ?? '',
        assuranceQuittance: selectedVehicule?.quittance ?? '',
        assuranceDateDebut: selectedVehicule?.dateDebutValidite,
        assuranceDateFin: selectedVehicule?.dateFinValidite,
        
        // Statut propriétaire
        estProprietaire: selectedVehicule?.proprietaireId == currentUser.id,
        
        // URLs des photos (si disponibles)
        photoCarteGriseRectoUrl: selectedVehicule?.photoCarteGriseRecto,
        photoCarteGriseVersoUrl: selectedVehicule?.photoCarteGriseVerso,
        photoPermisUrl: conducteurDetails?.urlPhotoPermis,
        photoCINUrl: conducteurDetails?.urlPhotoCIN,
      );
    } catch (e) {
      debugPrint('[AutoFillService] ❌ Erreur lors de la récupération: $e');
      
      // Retourner au minimum les données de base
      return AutoFillData(
        conducteurNom: currentUser.nom,
        conducteurPrenom: currentUser.prenom,
        conducteurAdresse: currentUser.adresse ?? '',
        conducteurTelephone: currentUser.telephone ?? '',
        conducteurEmail: currentUser.email ?? '',
        estProprietaire: selectedVehicule?.proprietaireId == currentUser.id,
      );
    }
  }

  /// Applique les données d'auto-remplissage aux contrôleurs de texte
  static void applyAutoFillData(
    AutoFillData data,
    Map<String, TextEditingController> controllers,
  ) {
    debugPrint('[AutoFillService] 📝 Application des données d\'auto-remplissage');

    // Remplir les champs du conducteur
    _setControllerText(controllers['nom'], data.conducteurNom);
    _setControllerText(controllers['prenom'], data.conducteurPrenom);
    _setControllerText(controllers['adresse'], data.conducteurAdresse);
    _setControllerText(controllers['telephone'], data.conducteurTelephone);
    _setControllerText(controllers['numeroPermis'], data.permisNumero);

    // Remplir les champs du véhicule
    _setControllerText(controllers['marque'], data.vehiculeMarque);
    _setControllerText(controllers['type'], data.vehiculeModele);
    _setControllerText(controllers['immatriculation'], data.vehiculeImmatriculation);

    // Remplir les champs d'assurance
    _setControllerText(controllers['societeAssurance'], data.assuranceCompagnie);
    _setControllerText(controllers['numeroContrat'], data.assuranceNumeroContrat);
    _setControllerText(controllers['agence'], data.assuranceAgence);

    debugPrint('[AutoFillService] ✅ Auto-remplissage terminé');
  }

  /// Méthode utilitaire pour définir le texte d'un contrôleur de manière sécurisée
  static void _setControllerText(TextEditingController? controller, String? text) {
    if (controller != null && text != null && text.isNotEmpty) {
      controller.text = text;
    }
  }
}

/// Classe contenant toutes les données pré-remplies
class AutoFillData {
  // Données du conducteur
  final String conducteurNom;
  final String conducteurPrenom;
  final String conducteurAdresse;
  final String conducteurTelephone;
  final String conducteurEmail;
  
  // Données du permis
  final String permisNumero;
  final DateTime? permisDelivreLe;
  final DateTime? permisValideJusquau;
  
  // Données du véhicule
  final String vehiculeMarque;
  final String vehiculeModele;
  final String vehiculeImmatriculation;
  
  // Données d'assurance
  final String assuranceCompagnie;
  final String assuranceNumeroContrat;
  final String assuranceAgence;
  final String assuranceQuittance;
  final DateTime? assuranceDateDebut;
  final DateTime? assuranceDateFin;
  
  // Statut
  final bool estProprietaire;
  
  // URLs des photos
  final String? photoCarteGriseRectoUrl;
  final String? photoCarteGriseVersoUrl;
  final String? photoPermisUrl;
  final String? photoCINUrl;

  AutoFillData({
    required this.conducteurNom,
    required this.conducteurPrenom,
    required this.conducteurAdresse,
    required this.conducteurTelephone,
    required this.conducteurEmail,
    this.permisNumero = '',
    this.permisDelivreLe,
    this.permisValideJusquau,
    this.vehiculeMarque = '',
    this.vehiculeModele = '',
    this.vehiculeImmatriculation = '',
    this.assuranceCompagnie = '',
    this.assuranceNumeroContrat = '',
    this.assuranceAgence = '',
    this.assuranceQuittance = '',
    this.assuranceDateDebut,
    this.assuranceDateFin,
    this.estProprietaire = false,
    this.photoCarteGriseRectoUrl,
    this.photoCarteGriseVersoUrl,
    this.photoPermisUrl,
    this.photoCINUrl,
  });

  /// Vérifie si les données d'assurance sont complètes
  bool get assuranceComplete {
    return assuranceCompagnie.isNotEmpty &&
           assuranceNumeroContrat.isNotEmpty &&
           assuranceAgence.isNotEmpty;
  }

  /// Vérifie si les données du véhicule sont complètes
  bool get vehiculeComplete {
    return vehiculeMarque.isNotEmpty &&
           vehiculeModele.isNotEmpty &&
           vehiculeImmatriculation.isNotEmpty;
  }

  /// Vérifie si les données du conducteur sont complètes
  bool get conducteurComplete {
    return conducteurNom.isNotEmpty &&
           conducteurPrenom.isNotEmpty &&
           conducteurTelephone.isNotEmpty;
  }

  @override
  String toString() {
    return 'AutoFillData(conducteur: $conducteurNom $conducteurPrenom, '
           'véhicule: $vehiculeMarque $vehiculeModele $vehiculeImmatriculation, '
           'assurance: $assuranceCompagnie, propriétaire: $estProprietaire)';
  }
}

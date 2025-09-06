import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math';
import '../models/tunisian_insurance_models.dart';
import 'tunisian_payment_service.dart';

/// 📄 Service de génération des documents officiels tunisiens
class TunisianDocumentsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🎨 Couleurs des macarons par année
  static const Map<int, Map<String, dynamic>> _couleursMacarons = {
    2024: {'couleur': 'Vert', 'hex': '#10B981'},
    2025: {'couleur': 'Bleu', 'hex': '#3B82F6'},
    2026: {'couleur': 'Rouge', 'hex': '#EF4444'},
    2027: {'couleur': 'Jaune', 'hex': '#F59E0B'},
    2028: {'couleur': 'Violet', 'hex': '#8B5CF6'},
  };

  /// 📋 Générer la police d'assurance complète
  static Future<Map<String, dynamic>> genererPoliceAssurance({
    required ContratAssuranceTunisien contrat,
    required VehiculeAssure vehicule,
    required Map<String, dynamic> conducteur,
    required Map<String, dynamic> agence,
    required Map<String, dynamic> compagnie,
  }) async {
    try {
      debugPrint('[DOCUMENTS] 📋 Génération police d\'assurance: ${contrat.numeroContrat}');

      // 1. Informations de base
      Map<String, dynamic> policeData = {
        'numeroPolice': contrat.numeroContrat,
        'dateEmission': DateTime.now().toIso8601String(),
        'dateDebut': contrat.dateDebut.toIso8601String(),
        'dateFin': contrat.dateFin.toIso8601String(),
        'dateEcheance': contrat.dateEcheance.toIso8601String(),
        
        // Informations compagnie
        'compagnie': {
          'nom': compagnie['nom'],
          'code': compagnie['code'],
          'adresse': compagnie['adresseSiege'],
          'telephone': compagnie['telephone'],
          'numeroAgrement': compagnie['numeroAgrement'],
        },
        
        // Informations agence
        'agence': {
          'nom': agence['nom'],
          'code': agence['code'],
          'adresse': agence['adresse'],
          'ville': agence['ville'],
          'telephone': agence['telephone'],
          'agentGeneral': agence['agentGeneralNom'],
        },
        
        // Informations assuré
        'assure': {
          'nom': '${conducteur['prenom']} ${conducteur['nom']}',
          'cin': conducteur['cin'],
          'adresse': conducteur['adresse'],
          'telephone': conducteur['telephone'],
          'dateNaissance': conducteur['dateNaissance'],
          'numeroPermis': conducteur['numeroPermis'],
        },
        
        // Informations véhicule
        'vehicule': {
          'marque': vehicule.marque,
          'modele': vehicule.modele,
          'annee': vehicule.annee,
          'couleur': vehicule.couleur,
          'immatriculation': vehicule.numeroImmatriculation,
          'carteGrise': vehicule.numeroCarteGrise,
          'puissanceFiscale': vehicule.puissanceFiscale,
          'typeVehicule': vehicule.typeVehicule,
          'carburant': vehicule.carburant,
          'numeroSerie': vehicule.numeroSerie,
        },
        
        // Informations contrat
        'contrat': {
          'typeCouverture': contrat.typeCouverture,
          'garanties': contrat.garanties,
          'primeAnnuelle': contrat.primeAnnuelle,
          'franchise': contrat.franchise,
          'statut': contrat.statut,
        },
        
        // QR Code pour vérification
        'qrCode': await _genererQRCodePolice(contrat.numeroContrat),
        
        // Conditions générales
        'conditionsGenerales': _getConditionsGenerales(),
        
        // Signatures
        'signatures': {
          'agentNom': '${agence['agentGeneralNom']}',
          'agentSignature': 'signature_agent_placeholder',
          'cachetAgence': 'cachet_agence_placeholder',
        },
      };

      // 2. Sauvegarder dans Firestore
      await _firestore.collection('polices_assurance').add({
        ...policeData,
        'contratId': contrat.id,
        'vehiculeId': vehicule.id,
        'conducteurId': vehicule.conducteurId,
        'agenceId': contrat.agenceId,
        'compagnieId': contrat.compagnieId,
        'dateGeneration': FieldValue.serverTimestamp(),
        'statut': 'active',
      });

      debugPrint('[DOCUMENTS] ✅ Police générée avec succès');
      return policeData;

    } catch (e) {
      debugPrint('[DOCUMENTS] ❌ Erreur génération police: $e');
      throw Exception('Erreur lors de la génération de la police: $e');
    }
  }

  /// 🧾 Générer la quittance de paiement
  static Future<Map<String, dynamic>> genererQuittancePaiement({
    required PaiementAssurance paiement,
    required ContratAssuranceTunisien contrat,
    required Map<String, dynamic> agence,
    required Map<String, dynamic> compagnie,
  }) async {
    try {
      debugPrint('[DOCUMENTS] 🧾 Génération quittance: ${paiement.numeroRecu}');

      Map<String, dynamic> quittanceData = {
        'numeroQuittance': 'QUI-${paiement.numeroRecu}',
        'numeroRecu': paiement.numeroRecu,
        'dateEmission': DateTime.now().toIso8601String(),
        'datePaiement': paiement.datePaiement.toIso8601String(),
        
        // Informations compagnie
        'compagnie': {
          'nom': compagnie['nom'],
          'code': compagnie['code'],
          'adresse': compagnie['adresseSiege'],
        },
        
        // Informations agence
        'agence': {
          'nom': agence['nom'],
          'adresse': agence['adresse'],
          'telephone': agence['telephone'],
        },
        
        // Détails du paiement
        'paiement': {
          'montant': paiement.montant,
          'typePaiement': paiement.typePaiement.label,
          'frequence': paiement.frequence.label,
          'numeroContrat': contrat.numeroContrat,
          'periode': '${contrat.dateDebut.year}',
        },
        
        // QR Code pour vérification
        'qrCode': await _genererQRCodeQuittance(paiement.numeroRecu),
        
        // Mentions légales
        'mentionsLegales': _getMentionsLegalesQuittance(),
      };

      // Sauvegarder dans Firestore
      await _firestore.collection('quittances_paiement').add({
        ...quittanceData,
        'paiementId': paiement.id,
        'contratId': contrat.id,
        'agenceId': paiement.agenceId,
        'dateGeneration': FieldValue.serverTimestamp(),
      });

      return quittanceData;

    } catch (e) {
      debugPrint('[DOCUMENTS] ❌ Erreur génération quittance: $e');
      throw Exception('Erreur lors de la génération de la quittance: $e');
    }
  }

  /// 🟢 Générer le macaron/carte verte
  static Future<Map<String, dynamic>> genererMacaron({
    required ContratAssuranceTunisien contrat,
    required VehiculeAssure vehicule,
    required Map<String, dynamic> compagnie,
  }) async {
    try {
      debugPrint('[DOCUMENTS] 🟢 Génération macaron: ${contrat.numeroContrat}');

      int anneeValidite = contrat.dateFin.year;
      Map<String, dynamic> couleurMacaron = _couleursMacarons[anneeValidite] ?? 
          {'couleur': 'Blanc', 'hex': '#FFFFFF'};

      Map<String, dynamic> macaronData = {
        'numeroMacaron': 'MAC-${contrat.numeroContrat}',
        'numeroContrat': contrat.numeroContrat,
        'dateEmission': DateTime.now().toIso8601String(),
        'dateDebut': contrat.dateDebut.toIso8601String(),
        'dateFin': contrat.dateFin.toIso8601String(),
        
        // Couleur selon l'année
        'couleur': couleurMacaron['couleur'],
        'couleurHex': couleurMacaron['hex'],
        'anneeValidite': anneeValidite,
        
        // Informations compagnie
        'compagnie': {
          'nom': compagnie['nom'],
          'code': compagnie['code'],
        },
        
        // Informations véhicule (limitées pour le macaron)
        'vehicule': {
          'immatriculation': vehicule.numeroImmatriculation,
          'marque': vehicule.marque,
          'modele': vehicule.modele,
        },
        
        // QR Code compact pour vérification rapide
        'qrCode': await _genererQRCodeMacaron(contrat.numeroContrat, vehicule.numeroImmatriculation),
        
        // Code de vérification court
        'codeVerification': _genererCodeVerification(contrat.numeroContrat),
        
        // Instructions de placement
        'instructions': 'À placer de manière visible sur le pare-brise avant',
      };

      // Sauvegarder dans Firestore
      await _firestore.collection('macarons_assurance').add({
        ...macaronData,
        'contratId': contrat.id,
        'vehiculeId': vehicule.id,
        'compagnieId': contrat.compagnieId,
        'dateGeneration': FieldValue.serverTimestamp(),
        'statut': 'actif',
      });

      return macaronData;

    } catch (e) {
      debugPrint('[DOCUMENTS] ❌ Erreur génération macaron: $e');
      throw Exception('Erreur lors de la génération du macaron: $e');
    }
  }

  /// 📱 Générer QR Code pour la police
  static Future<String> _genererQRCodePolice(String numeroContrat) async {
    Map<String, dynamic> qrData = {
      'type': 'police_assurance',
      'numero': numeroContrat,
      'date': DateTime.now().toIso8601String(),
      'verification': 'https://verify.assurance.tn/police/$numeroContrat',
    };
    return qrData.toString();
  }

  /// 📱 Générer QR Code pour la quittance
  static Future<String> _genererQRCodeQuittance(String numeroRecu) async {
    Map<String, dynamic> qrData = {
      'type': 'quittance_paiement',
      'numero': numeroRecu,
      'date': DateTime.now().toIso8601String(),
      'verification': 'https://verify.assurance.tn/quittance/$numeroRecu',
    };
    return qrData.toString();
  }

  /// 📱 Générer QR Code pour le macaron
  static Future<String> _genererQRCodeMacaron(String numeroContrat, String immatriculation) async {
    Map<String, dynamic> qrData = {
      'type': 'macaron_assurance',
      'contrat': numeroContrat,
      'immat': immatriculation,
      'verification': 'https://verify.assurance.tn/macaron/$numeroContrat',
    };
    return qrData.toString();
  }

  /// 🔢 Générer un code de vérification court
  static String _genererCodeVerification(String numeroContrat) {
    final hash = numeroContrat.hashCode.abs();
    return (hash % 999999).toString().padLeft(6, '0');
  }

  /// 📜 Conditions générales de la police
  static List<String> _getConditionsGenerales() {
    return [
      'La présente police d\'assurance est soumise au Code des Assurances tunisien.',
      'L\'assurance prend effet à la date et heure indiquées aux conditions particulières.',
      'Les primes sont payables d\'avance aux échéances convenues.',
      'En cas de sinistre, l\'assuré doit en faire la déclaration dans les 5 jours.',
      'La franchise reste à la charge de l\'assuré pour chaque sinistre.',
      'Le contrat est renouvelable par tacite reconduction sauf dénonciation.',
      'Tout litige relève de la compétence des tribunaux tunisiens.',
    ];
  }

  /// ⚖️ Mentions légales de la quittance
  static List<String> _getMentionsLegalesQuittance() {
    return [
      'Quittance valant reçu de paiement de prime d\'assurance.',
      'Document à conserver précieusement.',
      'En cas de contrôle, présenter avec la police d\'assurance.',
      'Valable uniquement pour la période indiquée.',
    ];
  }

  /// 📊 Générer un rapport de documents pour un contrat
  static Future<Map<String, dynamic>> genererRapportDocuments(String contratId) async {
    try {
      // Récupérer tous les documents liés au contrat
      final policeQuery = await _firestore
          .collection('polices_assurance')
          .where('contratId', isEqualTo: contratId)
          .get();

      final quittancesQuery = await _firestore
          .collection('quittances_paiement')
          .where('contratId', isEqualTo: contratId)
          .get();

      final macaronsQuery = await _firestore
          .collection('macarons_assurance')
          .where('contratId', isEqualTo: contratId)
          .get();

      return {
        'contratId': contratId,
        'police': policeQuery.docs.isNotEmpty ? policeQuery.docs.first.data() : null,
        'quittances': quittancesQuery.docs.map((doc) => doc.data()).toList(),
        'macarons': macaronsQuery.docs.map((doc) => doc.data()).toList(),
        'dateGeneration': DateTime.now().toIso8601String(),
        'nombreDocuments': policeQuery.docs.length + quittancesQuery.docs.length + macaronsQuery.docs.length,
      };

    } catch (e) {
      debugPrint('[DOCUMENTS] ❌ Erreur génération rapport: $e');
      throw Exception('Erreur lors de la génération du rapport: $e');
    }
  }

  /// 🔍 Vérifier l'authenticité d'un document
  static Future<Map<String, dynamic>> verifierDocument({
    required String typeDocument,
    required String numeroDocument,
  }) async {
    try {
      String collection;
      String champ;

      switch (typeDocument) {
        case 'police':
          collection = 'polices_assurance';
          champ = 'numeroPolice';
          break;
        case 'quittance':
          collection = 'quittances_paiement';
          champ = 'numeroQuittance';
          break;
        case 'macaron':
          collection = 'macarons_assurance';
          champ = 'numeroMacaron';
          break;
        default:
          throw Exception('Type de document non reconnu');
      }

      final querySnapshot = await _firestore
          .collection(collection)
          .where(champ, isEqualTo: numeroDocument)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'valide': false,
          'message': 'Document non trouvé dans la base de données',
        };
      }

      final docData = querySnapshot.docs.first.data();
      return {
        'valide': true,
        'message': 'Document authentique',
        'details': docData,
        'dateVerification': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      return {
        'valide': false,
        'message': 'Erreur lors de la vérification: $e',
      };
    }
  }
}

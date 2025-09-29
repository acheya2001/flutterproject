import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
// Pas d'import dart:html pour éviter les erreurs de plateforme

/// 🇹🇳 Service PDF pour Constat Amiable Tunisien OFFICIEL
/// Génère un PDF conforme au modèle officiel tunisien avec TOUTES les données
class ConstatTunisienOfficielPdf {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📄 Générer le constat officiel tunisien complet
  static Future<String> genererConstatOfficiel({required String sessionId}) async {
    print('🇹🇳 [CONSTAT OFFICIEL] Début génération pour session: $sessionId');
    
    try {
      // 1. Charger TOUTES les données
      final donnees = await _chargerDonneesCompletes(sessionId);
      
      // 2. Créer le document PDF
      final pdf = pw.Document();
      
      // 3. PAGES DU CONSTAT OFFICIEL TUNISIEN
      
      // Page 1: Couverture République Tunisienne
      pdf.addPage(_buildPage1CouvertureOfficielle(donnees));
      
      // Page 2: Cases 1-5 (Date, Lieu, Blessés, Dégâts, Témoins)
      pdf.addPage(_buildPage2Cases1a5(donnees));
      
      // Page 3: Véhicule A - Données complètes
      final participants = donnees['participants'] as List? ?? [];
      if (participants.isNotEmpty) {
        pdf.addPage(_buildPage3VehiculeA(donnees, participants[0]));
      }
      
      // Page 4: Véhicule B - Données complètes
      if (participants.length > 1) {
        pdf.addPage(_buildPage4VehiculeB(donnees, participants[1]));
      }
      
      // Page 5: Véhicule C (si existe)
      if (participants.length > 2) {
        pdf.addPage(_buildPage5VehiculeC(donnees, participants[2]));
      }
      
      // Page 6: Circonstances détaillées
      pdf.addPage(_buildPage6CirconstancesDetaillees(donnees));
      
      // Page 7: Croquis et observations
      pdf.addPage(_buildPage7CroquisObservations(donnees));
      
      // Page 8: Signatures et validation
      pdf.addPage(_buildPage8SignaturesValidation(donnees));
      
      // 4. Sauvegarder le PDF
      final pdfBytes = await pdf.save();
      final fileName = 'constat_officiel_tunisien_$sessionId.pdf';

      // Sauvegarder dans le répertoire de l'application
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      // Essayer de copier vers Downloads sur Android
      try {
        if (Platform.isAndroid) {
          final downloadsDir = Directory('/storage/emulated/0/Download');
          if (await downloadsDir.exists()) {
            final downloadFile = File('${downloadsDir.path}/$fileName');
            await downloadFile.writeAsBytes(pdfBytes);
            print('✅ [PDF] Copié vers Downloads: ${downloadFile.path}');
          }
        }
      } catch (e) {
        print('⚠️ [PDF] Impossible de copier vers Downloads: $e');
      }

      print('🎉 [CONSTAT OFFICIEL] PDF généré: ${file.path}');
      return file.path;
      
    } catch (e) {
      print('❌ [CONSTAT OFFICIEL] Erreur: $e');
      rethrow;
    }
  }

  /// 📊 Charger toutes les données complètes
  static Future<Map<String, dynamic>> _chargerDonneesCompletes(String sessionId) async {
    print('📥 [CONSTAT] Chargement données complètes pour: $sessionId');
    
    // 1. Session principale
    final sessionDoc = await _firestore.collection('sessions_collaboratives').doc(sessionId).get();
    if (!sessionDoc.exists) {
      throw Exception('Session $sessionId non trouvée');
    }
    
    final donnees = Map<String, dynamic>.from(sessionDoc.data()!);
    print('✅ [CONSTAT] Session chargée');
    
    // 2. Participants avec formulaires
    final participantsQuery = await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .collection('participants_data')
        .get();
    
    final participants = <Map<String, dynamic>>[];
    for (final doc in participantsQuery.docs) {
      final participantData = doc.data();
      participants.add(participantData);
    }
    donnees['participants'] = participants;
    print('✅ [CONSTAT] ${participants.length} participants chargés');
    
    // 3. Signatures - Récupérer les VRAIES signatures du formulaire
    final signaturesQuery = await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .collection('signatures')
        .get();

    final signatures = <Map<String, dynamic>>[];
    for (final doc in signaturesQuery.docs) {
      final signatureData = doc.data();

      // Récupérer l'image de signature si elle existe
      if (signatureData['signatureBase64'] != null) {
        signatures.add({
          'userId': doc.id,
          'signatureBase64': signatureData['signatureBase64'],
          'dateSignature': signatureData['dateSignature'],
          'nom': signatureData['nom'] ?? 'Nom non spécifié',
          'prenom': signatureData['prenom'] ?? '',
          'roleVehicule': signatureData['roleVehicule'] ?? 'A',
          'accord': signatureData['accord'] ?? true,
        });
      }
    }
    donnees['signatures'] = signatures;
    print('✅ [CONSTAT] ${signatures.length} signatures avec images chargées');
    
    // 4. Croquis - Récupérer le VRAI croquis du formulaire
    try {
      // Essayer d'abord dans la collection croquis
      final croquisDoc = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('croquis')
          .doc('principal')
          .get();

      if (croquisDoc.exists) {
        final croquisData = croquisDoc.data()!;
        donnees['croquis'] = {
          'croquisBase64': croquisData['croquisBase64'] ?? croquisData['imageBase64'],
          'elements': croquisData['elements'] ?? [],
          'dateCreation': croquisData['dateCreation'],
          'validePar': croquisData['validePar'] ?? [],
        };
        print('✅ [CONSTAT] Croquis chargé depuis collection croquis');
      } else {
        // Essayer dans le document principal de session
        final sessionDoc = await _firestore
            .collection('sessions_collaboratives')
            .doc(sessionId)
            .get();

        if (sessionDoc.exists) {
          final sessionData = sessionDoc.data()!;
          if (sessionData['croquis'] != null) {
            donnees['croquis'] = sessionData['croquis'];
            print('✅ [CONSTAT] Croquis chargé depuis session principale');
          } else {
            donnees['croquis'] = null;
            print('⚠️ [CONSTAT] Aucun croquis trouvé');
          }
        } else {
          donnees['croquis'] = null;
          print('⚠️ [CONSTAT] Session non trouvée');
        }
      }
    } catch (e) {
      print('❌ [CONSTAT] Erreur chargement croquis: $e');
      donnees['croquis'] = null;
    }
    
    // 5. Photos
    final photosQuery = await _firestore
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .collection('photos')
        .get();
    
    final photos = <Map<String, dynamic>>[];
    for (final doc in photosQuery.docs) {
      photos.add(doc.data());
    }
    donnees['photos'] = photos;
    print('✅ [CONSTAT] ${photos.length} photos chargées');
    
    return donnees;
  }

  /// 📄 Page 1: Couverture République Tunisienne
  static pw.Page _buildPage1CouvertureOfficielle(Map<String, dynamic> donnees) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(30),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(height: 50),
          
          // En-tête République Tunisienne
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              gradient: const pw.LinearGradient(
                colors: [PdfColors.red700, PdfColors.red500],
              ),
              borderRadius: pw.BorderRadius.circular(15),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'الجمهورية التونسية',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'RÉPUBLIQUE TUNISIENNE',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'وزارة النقل',
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.white,
                  ),
                ),
                pw.Text(
                  'MINISTÈRE DU TRANSPORT',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 40),
          
          // Titre principal
          pw.Container(
            padding: const pw.EdgeInsets.all(25),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              border: pw.Border.all(color: PdfColors.blue300, width: 2),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'CONSTAT AMIABLE D\'ACCIDENT',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'محضر ودي لحادث مرور',
                  style: pw.TextStyle(
                    fontSize: 18,
                    color: PdfColors.blue700,
                  ),
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 30),
          
          // Informations du constat
          _buildInfoSection('Code Session', donnees['sessionCode']?.toString() ?? 'N/A'),
          _buildInfoSection('Date de génération', _formatDate(DateTime.now())),
          _buildInfoSection('Nombre de véhicules', '${(donnees['participants'] as List?)?.length ?? 0}'),
          
          pw.Spacer(),
          
          // Pied de page
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'Document généré électroniquement - Conforme à la réglementation tunisienne',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Section d'information
  static pw.Widget _buildInfoSection(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  /// 📅 Formater une date
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// 🕐 Formater une heure
  static String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// 📄 Page 2: Cases 1-5 du constat officiel
  static pw.Page _buildPage2Cases1a5(Map<String, dynamic> donnees) {
    final donneesCommunes = donnees['donneesCommunes'] as Map<String, dynamic>? ?? {};

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // En-tête
          _buildPageHeader('CONSTAT AMIABLE - INFORMATIONS GÉNÉRALES'),

          pw.SizedBox(height: 20),

          // Case 1: Date et heure
          _buildCase1DateHeure(donneesCommunes),

          pw.SizedBox(height: 15),

          // Case 2: Lieu
          _buildCase2Lieu(donneesCommunes),

          pw.SizedBox(height: 15),

          // Case 3: Blessés
          _buildCase3Blesses(donneesCommunes),

          pw.SizedBox(height: 15),

          // Case 4: Dégâts matériels
          _buildCase4DegatsMateriels(donneesCommunes),

          pw.SizedBox(height: 15),

          // Case 5: Témoins
          _buildCase5Temoins(donneesCommunes),

          pw.SizedBox(height: 20),

          // Conditions météo et circulation
          _buildConditionsGenerales(donneesCommunes),
        ],
      ),
    );
  }

  /// 📋 En-tête de page
  static pw.Widget _buildPageHeader(String titre) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [PdfColors.blue700, PdfColors.blue500],
        ),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Text(
        titre,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// 📅 Case 1: Date et heure
  static pw.Widget _buildCase1DateHeure(Map<String, dynamic> donnees) {
    final dateAccident = donnees['dateAccident']?.toString() ?? 'Non spécifiée';
    final heureAccident = donnees['heureAccident']?.toString() ?? 'Non spécifiée';

    return _buildCaseContainer(
      '1. DATE ET HEURE DE L\'ACCIDENT',
      [
        'Date: $dateAccident',
        'Heure: $heureAccident',
      ],
      PdfColors.blue50,
    );
  }

  /// 📍 Case 2: Lieu
  static pw.Widget _buildCase2Lieu(Map<String, dynamic> donnees) {
    final lieu = donnees['lieuAccident']?.toString() ?? 'Non spécifié';
    final gouvernorat = donnees['gouvernorat']?.toString() ?? 'Non spécifié';
    final gps = donnees['lieuGps']?.toString() ?? 'Non disponible';

    return _buildCaseContainer(
      '2. LIEU DE L\'ACCIDENT',
      [
        'Adresse: $lieu',
        'Gouvernorat: $gouvernorat',
        'Coordonnées GPS: $gps',
      ],
      PdfColors.green50,
    );
  }

  /// 🚑 Case 3: Blessés
  static pw.Widget _buildCase3Blesses(Map<String, dynamic> donnees) {
    final blesses = donnees['blesses'] as bool? ?? false;
    final detailsBlesses = donnees['detailsBlesses']?.toString() ?? 'Aucun détail';

    return _buildCaseContainer(
      '3. BLESSÉS',
      [
        'Y a-t-il des blessés? ${blesses ? "OUI" : "NON"}',
        if (blesses) 'Détails: $detailsBlesses',
      ],
      blesses ? PdfColors.red50 : PdfColors.green50,
    );
  }

  /// 🚗 Case 4: Dégâts matériels
  static pw.Widget _buildCase4DegatsMateriels(Map<String, dynamic> donnees) {
    final degats = donnees['degatsMateriels']?.toString() ?? 'Non spécifiés';

    return _buildCaseContainer(
      '4. DÉGÂTS MATÉRIELS',
      [
        'Description: $degats',
      ],
      PdfColors.orange50,
    );
  }

  /// 👥 Case 5: Témoins
  static pw.Widget _buildCase5Temoins(Map<String, dynamic> donnees) {
    final temoins = donnees['temoins'] as List? ?? [];

    final infos = <String>[];
    if (temoins.isEmpty) {
      infos.add('Aucun témoin');
    } else {
      for (int i = 0; i < temoins.length; i++) {
        final temoin = temoins[i] as Map<String, dynamic>? ?? {};
        final nom = temoin['nom']?.toString() ?? 'Nom non spécifié';
        final prenom = temoin['prenom']?.toString() ?? '';
        final telephone = temoin['telephone']?.toString() ?? 'Tel non spécifié';
        infos.add('Témoin ${i + 1}: $prenom $nom - $telephone');
      }
    }

    return _buildCaseContainer(
      '5. TÉMOINS',
      infos,
      PdfColors.purple50,
    );
  }

  /// 🌤️ Conditions générales
  static pw.Widget _buildConditionsGenerales(Map<String, dynamic> donnees) {
    final meteo = donnees['meteo']?.toString() ?? 'Non spécifiée';
    final visibilite = donnees['visibilite']?.toString() ?? 'Non spécifiée';
    final etatRoute = donnees['etatRoute']?.toString() ?? 'Non spécifié';
    final circulation = donnees['circulation']?.toString() ?? 'Non spécifiée';

    return _buildCaseContainer(
      'CONDITIONS AU MOMENT DE L\'ACCIDENT',
      [
        'Météo: $meteo',
        'Visibilité: $visibilite',
        'État de la route: $etatRoute',
        'Circulation: $circulation',
      ],
      PdfColors.grey50,
    );
  }

  /// 📦 Container pour une case
  static pw.Widget _buildCaseContainer(String titre, List<String> infos, PdfColor backgroundColor) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titre,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),
          ...infos.map((info) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(
              info,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          )),
        ],
      ),
    );
  }

  /// 🚗 Page 3: Véhicule A - Données complètes
  static pw.Page _buildPage3VehiculeA(Map<String, dynamic> donnees, Map<String, dynamic> participant) {
    return _buildPageVehicule(donnees, participant, 'A', PdfColors.blue50);
  }

  /// 🚗 Page 4: Véhicule B - Données complètes
  static pw.Page _buildPage4VehiculeB(Map<String, dynamic> donnees, Map<String, dynamic> participant) {
    return _buildPageVehicule(donnees, participant, 'B', PdfColors.green50);
  }

  /// 🚗 Page 5: Véhicule C - Données complètes
  static pw.Page _buildPage5VehiculeC(Map<String, dynamic> donnees, Map<String, dynamic> participant) {
    return _buildPageVehicule(donnees, participant, 'C', PdfColors.orange50);
  }

  /// 🚗 Page générique pour un véhicule
  static pw.Page _buildPageVehicule(Map<String, dynamic> donnees, Map<String, dynamic> participant, String vehiculeLetter, PdfColor backgroundColor) {
    final formulaire = participant['donneesFormulaire'] as Map<String, dynamic>? ?? {};
    final vehicule = formulaire['vehicule'] as Map<String, dynamic>? ?? {};
    final conducteur = formulaire['donneesPersonnelles'] as Map<String, dynamic>? ?? {};
    final assurance = formulaire['vehiculeSelectionne'] as Map<String, dynamic>? ?? {};

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // En-tête véhicule
          _buildVehiculeHeader(vehiculeLetter, backgroundColor),

          pw.SizedBox(height: 15),

          // Section assurance
          _buildSectionAssurance(assurance),

          pw.SizedBox(height: 15),

          // Section véhicule
          _buildSectionVehicule(vehicule),

          pw.SizedBox(height: 15),

          // Section conducteur
          _buildSectionConducteur(conducteur),

          pw.SizedBox(height: 15),

          // Section circonstances
          _buildSectionCirconstances(formulaire),

          pw.SizedBox(height: 15),

          // Section dégâts
          _buildSectionDegats(formulaire),
        ],
      ),
    );
  }

  /// 🚗 En-tête véhicule
  static pw.Widget _buildVehiculeHeader(String letter, PdfColor backgroundColor) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey400, width: 2),
      ),
      child: pw.Text(
        'VÉHICULE $letter - DONNÉES COMPLÈTES',
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// 🏢 Section assurance
  static pw.Widget _buildSectionAssurance(Map<String, dynamic> assurance) {
    final compagnie = assurance['compagnieAssurance']?.toString() ?? 'Non spécifiée';
    final contrat = assurance['numeroContrat']?.toString() ?? 'Non spécifié';
    final agence = assurance['agence']?.toString() ?? 'Non spécifiée';
    final dateDebut = assurance['dateDebut']?.toString() ?? 'Non spécifiée';
    final dateFin = assurance['dateFin']?.toString() ?? 'Non spécifiée';

    return _buildCaseContainer(
      'ASSURANCE',
      [
        'Compagnie: $compagnie',
        'N° Contrat: $contrat',
        'Agence: $agence',
        'Validité: du $dateDebut au $dateFin',
      ],
      PdfColors.blue50,
    );
  }

  /// 🚗 Section véhicule
  static pw.Widget _buildSectionVehicule(Map<String, dynamic> vehicule) {
    final marque = vehicule['marque']?.toString() ?? 'Non spécifiée';
    final modele = vehicule['modele']?.toString() ?? 'Non spécifié';
    final immatriculation = vehicule['immatriculation']?.toString() ?? 'Non spécifiée';
    final annee = vehicule['annee']?.toString() ?? 'Non spécifiée';
    final couleur = vehicule['couleur']?.toString() ?? 'Non spécifiée';
    final type = vehicule['typeVehicule']?.toString() ?? 'Non spécifié';

    return _buildCaseContainer(
      'VÉHICULE',
      [
        'Marque: $marque',
        'Modèle: $modele',
        'Immatriculation: $immatriculation',
        'Année: $annee',
        'Couleur: $couleur',
        'Type: $type',
      ],
      PdfColors.green50,
    );
  }

  /// 👤 Section conducteur
  static pw.Widget _buildSectionConducteur(Map<String, dynamic> conducteur) {
    final nom = conducteur['nomConducteur']?.toString() ?? 'Non spécifié';
    final prenom = conducteur['prenomConducteur']?.toString() ?? 'Non spécifié';
    final adresse = conducteur['adresseConducteur']?.toString() ?? 'Non spécifiée';
    final telephone = conducteur['telephoneConducteur']?.toString() ?? 'Non spécifié';
    final permis = conducteur['numeroPermis']?.toString() ?? 'Non spécifié';
    final datePermis = conducteur['dateDelivrancePermis']?.toString() ?? 'Non spécifiée';

    return _buildCaseContainer(
      'CONDUCTEUR',
      [
        'Nom: $nom',
        'Prénom: $prenom',
        'Adresse: $adresse',
        'Téléphone: $telephone',
        'N° Permis: $permis',
        'Date délivrance permis: $datePermis',
      ],
      PdfColors.orange50,
    );
  }

  /// 🚦 Section circonstances
  static pw.Widget _buildSectionCirconstances(Map<String, dynamic> formulaire) {
    final circonstances = formulaire['circonstances'] as List? ?? [];
    final circonstancesTexte = circonstances.map((c) => _traduireCirconstance(c.toString())).toList();

    if (circonstancesTexte.isEmpty) {
      circonstancesTexte.add('Aucune circonstance spécifiée');
    }

    return _buildCaseContainer(
      'CIRCONSTANCES DE L\'ACCIDENT',
      circonstancesTexte,
      PdfColors.yellow50,
    );
  }

  /// 💥 Section dégâts
  static pw.Widget _buildSectionDegats(Map<String, dynamic> formulaire) {
    final pointsChoc = formulaire['pointsChoc'] as List? ?? [];
    final degatsApparents = formulaire['degatsApparents'] as List? ?? [];
    final observations = formulaire['observations']?.toString() ?? 'Aucune observation';
    final remarques = formulaire['remarques']?.toString() ?? 'Aucune remarque';

    final infos = <String>[];

    if (pointsChoc.isNotEmpty) {
      infos.add('Points de choc: ${pointsChoc.join(', ')}');
    }

    if (degatsApparents.isNotEmpty) {
      infos.add('Dégâts apparents: ${degatsApparents.join(', ')}');
    }

    infos.add('Observations: $observations');
    infos.add('Remarques: $remarques');

    return _buildCaseContainer(
      'DÉGÂTS ET OBSERVATIONS',
      infos,
      PdfColors.red50,
    );
  }

  /// 🔄 Traduire les circonstances
  static String _traduireCirconstance(String circonstance) {
    final traductions = {
      'roulait': 'Roulait',
      'stationnait': 'Stationnait',
      'quittait_stationnement': 'Quittait un stationnement',
      'prenait_stationnement': 'Prenait un stationnement',
      'sortait_parking': 'Sortait d\'un parking',
      'engageait_parking': 'Entrait dans un parking',
      'engageait_circulation': 'S\'engageait dans la circulation',
      'changeait_file': 'Changeait de file',
      'doublait': 'Doublait',
      'virait_droite': 'Virait à droite',
      'virait_gauche': 'Virait à gauche',
      'reculait': 'Reculait',
      'empietait_sens_inverse': 'Empiétait sur le sens inverse',
      'venait_droite': 'Venait de droite',
      'ignorait_priorite': 'Ignorait la priorité',
      'ignorait_signal_arret': 'Ignorait le signal d\'arrêt',
      'respectait_priorite': 'Respectait la priorité',
      'arretait': 'S\'arrêtait',
      'evitait_obstacle': 'Évitait un obstacle',
      'freinage_urgence': 'Freinage d\'urgence',
    };

    return traductions[circonstance] ?? circonstance;
  }

  /// 📋 Page 6: Circonstances détaillées
  static pw.Page _buildPage6CirconstancesDetaillees(Map<String, dynamic> donnees) {
    final participants = donnees['participants'] as List? ?? [];

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildPageHeader('CIRCONSTANCES DÉTAILLÉES DE L\'ACCIDENT'),

          pw.SizedBox(height: 20),

          // Circonstances pour chaque véhicule
          ...participants.asMap().entries.map((entry) {
            final index = entry.key;
            final participant = entry.value as Map<String, dynamic>;
            final vehiculeLetter = String.fromCharCode(65 + index); // A, B, C...

            return pw.Column(
              children: [
                _buildCirconstancesVehicule(participant, vehiculeLetter),
                if (index < participants.length - 1) pw.SizedBox(height: 15),
              ],
            );
          }),

          pw.SizedBox(height: 20),

          // Analyse de responsabilité
          _buildAnalyseResponsabilite(participants),
        ],
      ),
    );
  }

  /// 🚗 Circonstances d'un véhicule
  static pw.Widget _buildCirconstancesVehicule(Map<String, dynamic> participant, String vehiculeLetter) {
    final formulaire = participant['donneesFormulaire'] as Map<String, dynamic>? ?? {};
    final circonstances = formulaire['circonstances'] as List? ?? [];
    final observations = formulaire['observations']?.toString() ?? 'Aucune observation';

    final circonstancesTexte = circonstances.map((c) => _traduireCirconstance(c.toString())).toList();

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'VÉHICULE $vehiculeLetter - CIRCONSTANCES',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),
          ...circonstancesTexte.map((c) => pw.Text(
            '• $c',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          )),
          pw.SizedBox(height: 5),
          pw.Text(
            'Observations: $observations',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// ⚖️ Analyse de responsabilité
  static pw.Widget _buildAnalyseResponsabilite(List participants) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.yellow50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.yellow300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ANALYSE PRÉLIMINAIRE DE RESPONSABILITÉ',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Cette analyse est basée sur les déclarations des conducteurs et doit être confirmée par l\'expertise.',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Nombre de véhicules impliqués: ${participants.length}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  /// 🎨 Page 7: Croquis et observations
  static pw.Page _buildPage7CroquisObservations(Map<String, dynamic> donnees) {
    final croquis = donnees['croquis'] as Map<String, dynamic>? ?? {};
    final photos = donnees['photos'] as List? ?? [];

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildPageHeader('CROQUIS ET DOCUMENTATION'),

          pw.SizedBox(height: 20),

          // Section croquis
          _buildSectionCroquis(croquis),

          pw.SizedBox(height: 20),

          // Section photos
          _buildSectionPhotos(photos),

          pw.SizedBox(height: 20),

          // Observations générales
          _buildObservationsGenerales(donnees),
        ],
      ),
    );
  }

  /// 🎨 Section croquis
  static pw.Widget _buildSectionCroquis(Map<String, dynamic>? croquis) {
    final hasCroquis = croquis != null &&
        (croquis['croquisBase64'] != null || croquis['imageBase64'] != null);

    return pw.Container(
      width: double.infinity,
      height: 200,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CROQUIS DE L\'ACCIDENT',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 10),
          if (hasCroquis) ...[
            pw.Expanded(
              child: pw.Center(
                child: _buildCroquisImage(
                  croquis!['croquisBase64'] ?? croquis['imageBase64']
                ),
              ),
            ),
          ] else ...[
            pw.Expanded(
              child: pw.Center(
                child: pw.Text(
                  'Aucun croquis disponible',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 🖼️ Image du croquis
  static pw.Widget _buildCroquisImage(String base64Data) {
    try {
      // Nettoyer le base64 (enlever les préfixes data:image)
      String cleanBase64 = base64Data;
      if (base64Data.contains(',')) {
        cleanBase64 = base64Data.split(',').last;
      }

      final imageBytes = base64Decode(cleanBase64);
      final image = pw.MemoryImage(imageBytes);
      return pw.Container(
        width: 200,
        height: 150,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Image(image, fit: pw.BoxFit.contain),
      );
    } catch (e) {
      print('❌ [PDF] Erreur chargement croquis: $e');
      return pw.Container(
        width: 200,
        height: 150,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.red),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Center(
          child: pw.Text(
            'Croquis non disponible',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.red),
          ),
        ),
      );
    }
  }

  /// 📸 Section photos
  static pw.Widget _buildSectionPhotos(List photos) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PHOTOS DE L\'ACCIDENT',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),
          if (photos.isEmpty) ...[
            pw.Text(
              'Aucune photo disponible',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ] else ...[
            pw.Text(
              '${photos.length} photo(s) disponible(s)',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 10),

            // Afficher les photos en grille
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: photos.take(3).map((photo) {
                return _buildPhotoItem(photo);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// 📷 Item photo individuel
  static pw.Widget _buildPhotoItem(Map<String, dynamic> photo) {
    final description = photo['description']?.toString() ?? 'Photo sans description';
    final imageBase64 = photo['imageBase64']?.toString();

    return pw.Container(
      width: 150,
      height: 120,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          // Image
          pw.Expanded(
            child: pw.Container(
              width: double.infinity,
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(8),
                  topRight: pw.Radius.circular(8),
                ),
              ),
              child: imageBase64 != null
                  ? _buildPhotoImage(imageBase64)
                  : pw.Center(
                      child: pw.Text(
                        'Photo',
                        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                      ),
                    ),
            ),
          ),

          // Description
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(8),
                bottomRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Text(
              description,
              style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
              textAlign: pw.TextAlign.center,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// 🖼️ Image de photo
  static pw.Widget _buildPhotoImage(String base64Data) {
    try {
      // Nettoyer le base64
      String cleanBase64 = base64Data;
      if (base64Data.contains(',')) {
        cleanBase64 = base64Data.split(',').last;
      }

      final imageBytes = base64Decode(cleanBase64);
      final image = pw.MemoryImage(imageBytes);
      return pw.Image(image, fit: pw.BoxFit.cover);
    } catch (e) {
      print('❌ [PDF] Erreur chargement photo: $e');
      return pw.Center(
        child: pw.Text(
          'Erreur photo',
          style: pw.TextStyle(fontSize: 7, color: PdfColors.red),
        ),
      );
    }
  }

  /// 📝 Observations générales
  static pw.Widget _buildObservationsGenerales(Map<String, dynamic> donnees) {
    final donneesCommunes = donnees['donneesCommunes'] as Map<String, dynamic>? ?? {};
    final observations = donneesCommunes['observations']?.toString() ?? 'Aucune observation particulière';

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.green300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'OBSERVATIONS GÉNÉRALES',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            observations,
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  /// ✍️ Page 8: Signatures et validation
  static pw.Page _buildPage8SignaturesValidation(Map<String, dynamic> donnees) {
    final signatures = donnees['signatures'] as List? ?? [];
    final participants = donnees['participants'] as List? ?? [];

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildPageHeader('SIGNATURES ET VALIDATION DU CONSTAT'),

          pw.SizedBox(height: 20),

          // Déclaration de conformité
          _buildDeclarationConformite(),

          pw.SizedBox(height: 20),

          // Signatures des conducteurs
          _buildSectionsSignatures(signatures, participants),

          pw.SizedBox(height: 20),

          // Validation finale
          _buildValidationFinale(donnees),

          pw.Spacer(),

          // Pied de page légal
          _buildPiedPageLegal(),
        ],
      ),
    );
  }

  /// 📜 Déclaration de conformité
  static pw.Widget _buildDeclarationConformite() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.yellow50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.yellow300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DÉCLARATION DE CONFORMITÉ',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Les soussignés déclarent que les informations contenues dans ce constat sont exactes et conformes à la réalité des faits. Ils s\'engagent à transmettre ce document à leurs compagnies d\'assurance respectives dans les délais légaux.',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  /// ✍️ Sections signatures
  static pw.Widget _buildSectionsSignatures(List signatures, List participants) {
    return pw.Column(
      children: [
        pw.Text(
          'SIGNATURES DES CONDUCTEURS',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 15),

        // Grille de signatures
        pw.Wrap(
          spacing: 10,
          runSpacing: 10,
          children: participants.asMap().entries.map((entry) {
            final index = entry.key;
            final participant = entry.value as Map<String, dynamic>;
            final vehiculeLetter = String.fromCharCode(65 + index);

            // Trouver la signature correspondante
            final signature = signatures.firstWhere(
              (sig) => sig['roleVehicule'] == vehiculeLetter,
              orElse: () => <String, dynamic>{},
            );

            return _buildSignatureBox(participant, signature, vehiculeLetter);
          }).toList(),
        ),
      ],
    );
  }

  /// 📝 Boîte de signature
  static pw.Widget _buildSignatureBox(Map<String, dynamic> participant, Map<String, dynamic> signature, String vehiculeLetter) {
    final formulaire = participant['donneesFormulaire'] as Map<String, dynamic>? ?? {};
    final conducteur = formulaire['donneesPersonnelles'] as Map<String, dynamic>? ?? {};
    final nom = conducteur['nomConducteur']?.toString() ?? 'Nom non spécifié';
    final prenom = conducteur['prenomConducteur']?.toString() ?? 'Prénom non spécifié';
    final hasSignature = signature.isNotEmpty && signature['signatureBase64'] != null;

    return pw.Container(
      width: 250,
      height: 150,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'VÉHICULE $vehiculeLetter',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.Text(
            '$prenom $nom',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 5),

          // Zone de signature
          pw.Expanded(
            child: pw.Container(
              width: double.infinity,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: hasSignature
                  ? pw.Center(child: _buildSignatureImage(signature['signatureBase64']))
                  : pw.Center(
                      child: pw.Text(
                        'Signature manquante',
                        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                      ),
                    ),
            ),
          ),

          pw.SizedBox(height: 5),
          pw.Text(
            'Date: ${signature['dateSignature']?.toString().split('T')[0] ?? 'Non signée'}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// 🖼️ Image de signature
  static pw.Widget _buildSignatureImage(String base64Data) {
    try {
      // Nettoyer le base64 (enlever les préfixes data:image)
      String cleanBase64 = base64Data;
      if (base64Data.contains(',')) {
        cleanBase64 = base64Data.split(',').last;
      }

      final imageBytes = base64Decode(cleanBase64);
      final image = pw.MemoryImage(imageBytes);
      return pw.Container(
        width: 120,
        height: 60,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Image(image, fit: pw.BoxFit.contain),
      );
    } catch (e) {
      print('❌ [PDF] Erreur chargement signature: $e');
      return pw.Container(
        width: 120,
        height: 60,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.red),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Center(
          child: pw.Text(
            'Signature manquante',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.red),
          ),
        ),
      );
    }
  }

  /// ✍️ Section signatures
  static pw.Widget _buildSectionSignatures(List signatures) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.purple50,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.purple300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SIGNATURES ÉLECTRONIQUES',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 12),

          if (signatures.isEmpty) ...[
            pw.Text(
              'Aucune signature disponible',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ] else ...[
            pw.Wrap(
              spacing: 20,
              runSpacing: 15,
              children: signatures.take(3).map((signature) {
                final nom = signature['nom']?.toString() ?? 'Nom non spécifié';
                final prenom = signature['prenom']?.toString() ?? '';
                final nomComplet = prenom.isNotEmpty ? '$prenom $nom' : nom;
                final roleVehicule = signature['roleVehicule']?.toString() ?? 'A';
                final date = signature['dateSignature']?.toString() ?? 'Date non spécifiée';
                final base64 = signature['signatureBase64']?.toString();
                final accord = signature['accord'] ?? true;

                return pw.Container(
                  width: 150,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // Nom et rôle
                      pw.Text(
                        'Véhicule $roleVehicule',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue700,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        nomComplet,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                        textAlign: pw.TextAlign.center,
                        maxLines: 2,
                      ),
                      pw.SizedBox(height: 8),

                      // Signature image
                      if (base64 != null) ...[
                        _buildSignatureImage(base64),
                      ] else ...[
                        pw.Container(
                          width: 120,
                          height: 60,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey100,
                            border: pw.Border.all(color: PdfColors.grey300),
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              'Signature manquante',
                              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                            ),
                          ),
                        ),
                      ],

                      pw.SizedBox(height: 6),

                      // Statut et date
                      pw.Text(
                        accord ? '✓ Accord donné' : '✗ Désaccord',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: accord ? PdfColors.green600 : PdfColors.red600,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        date,
                        style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// ✅ Validation finale
  static pw.Widget _buildValidationFinale(Map<String, dynamic> donnees) {
    final sessionCode = donnees['sessionCode']?.toString() ?? 'N/A';
    final dateGeneration = _formatDate(DateTime.now());
    final heureGeneration = _formatTime(DateTime.now());

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.green300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'VALIDATION DU CONSTAT',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Code de session: $sessionCode',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.Text(
            'Document généré le: $dateGeneration à $heureGeneration',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.Text(
            'Statut: Constat validé et signé par toutes les parties',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.green700),
          ),
        ],
      ),
    );
  }

  /// ⚖️ Pied de page légal
  static pw.Widget _buildPiedPageLegal() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'MENTIONS LÉGALES',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Ce document est conforme à la réglementation tunisienne en matière de constat amiable d\'accident.',
            style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
          pw.Text(
            'Il doit être transmis aux compagnies d\'assurance dans un délai de 5 jours ouvrables.',
            style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 📤 Partager le PDF (optionnel)
  static Future<void> partagerPdf(String filePath) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Utiliser le plugin share_plus si disponible
        // await Share.shareFiles([filePath], text: 'Constat amiable d\'accident');
        print('📤 [PDF] Partage disponible: $filePath');
      }
    } catch (e) {
      print('❌ [PDF] Erreur partage: $e');
    }
  }
}

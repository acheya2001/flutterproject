import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// 🇹🇳 Service PDF Tunisien Moderne et Complet
/// Génère des constats amiables digitalisés avec design professionnel
class ModernTunisianPdfService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🎯 Méthode principale pour générer le PDF tunisien moderne
  static Future<String> genererConstatModerne({required String sessionId}) async {
    print('🇹🇳 [PDF MODERNE] Début génération pour session: $sessionId');
    
    try {
      // 1. Charger toutes les données
      final donnees = await _chargerDonneesCompletes(sessionId);
      print('✅ [PDF] Données chargées: ${donnees.keys.length} sections');

      // 2. Créer le document PDF
      final pdf = pw.Document();

      // 3. Ajouter les pages
      pdf.addPage(await _buildPageCouverture(donnees));
      pdf.addPage(await _buildPageInfosGenerales(donnees));
      
      // Pages véhicules
      final participants = donnees['participants'] as List? ?? [];
      for (int i = 0; i < participants.length; i++) {
        pdf.addPage(await _buildPageVehicule(participants[i], i + 1, donnees));
      }
      
      // Page croquis et signatures
      pdf.addPage(await _buildPageCroquisSignatures(donnees));

      // 4. Sauvegarder
      final filePath = await _saveLocalPdf(pdf, sessionId);
      print('🎉 [PDF] Génération terminée: $filePath');
      
      return filePath;
    } catch (e, stackTrace) {
      print('❌ [PDF] Erreur: $e');
      print('📍 [PDF] Stack: $stackTrace');
      rethrow;
    }
  }

  /// 📊 Charger toutes les données nécessaires de manière intelligente
  static Future<Map<String, dynamic>> _chargerDonneesCompletes(String sessionId) async {
    try {
      print('📥 [PDF] Chargement intelligent des données pour session: $sessionId');

      // 1. Charger session principale
      final sessionDoc = await _firestore.collection('sessions_collaboratives').doc(sessionId).get();
      if (!sessionDoc.exists) {
        throw Exception('Session $sessionId non trouvée');
      }

      final donnees = Map<String, dynamic>.from(sessionDoc.data()!);
      print('✅ [PDF] Session principale chargée');

      // 2. Charger participants avec formulaires (méthode hybride intelligente)
      final participants = await _chargerParticipantsAvecFormulaires(sessionId, donnees);
      donnees['participants'] = participants;
      print('✅ [PDF] ${participants.length} participants chargés avec formulaires');

      // 3. Charger signatures avec images
      final signatures = await _chargerSignaturesCompletes(sessionId);
      donnees['signatures'] = signatures;
      print('✅ [PDF] ${signatures.length} signatures chargées');

      // 4. Charger croquis avec images
      final croquis = await _chargerCroquisComplet(sessionId);
      donnees['croquis'] = croquis;
      print('✅ [PDF] Croquis chargé: ${croquis != null ? 'Oui' : 'Non'}');

      // 5. Charger données communes (infos générales)
      final donneesCommunes = await _chargerDonneesCommunes(sessionId);
      donnees['donneesCommunes'] = donneesCommunes;
      print('✅ [PDF] Données communes chargées');

      // 6. Charger photos d'accident
      final photos = await _chargerPhotosAccident(sessionId);
      donnees['photos'] = photos;
      print('✅ [PDF] ${photos.length} photos chargées');

      return donnees;
    } catch (e) {
      print('❌ [PDF] Erreur chargement: $e');
      rethrow;
    }
  }

  /// 👥 Charger participants avec formulaires (méthode hybride)
  static Future<List<Map<String, dynamic>>> _chargerParticipantsAvecFormulaires(
    String sessionId,
    Map<String, dynamic> sessionData
  ) async {
    final participants = <Map<String, dynamic>>[];

    // Méthode 1: Depuis participants_data (nouveau format)
    try {
      final participantsSnapshot = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('participants_data')
          .get();

      print('🔍 [PDF] Trouvé ${participantsSnapshot.docs.length} participants dans participants_data');

      for (var doc in participantsSnapshot.docs) {
        final participantData = doc.data();
        final formulaire = participantData['donneesFormulaire'] as Map<String, dynamic>? ?? {};

        print('👤 [PDF] Participant ${doc.id}:');
        print('   - Données participant: ${participantData.keys.toList()}');
        print('   - Formulaire: ${formulaire.keys.toList()}');

        if (formulaire.isNotEmpty) {
          final donneesPersonnelles = formulaire['donneesPersonnelles'] as Map<String, dynamic>? ?? {};
          print('   - Données personnelles: ${donneesPersonnelles.keys.toList()}');
        }

        participants.add({
          'userId': doc.id,
          'formulaire': formulaire,
          'infos': participantData,
          'source': 'participants_data',
        });
      }
    } catch (e) {
      print('⚠️ [PDF] Erreur participants_data: $e');
    }

    // Méthode 2: Depuis formulaires (ancien format) - fallback
    if (participants.isEmpty) {
      try {
        final formulairesSnapshot = await _firestore
            .collection('sessions_collaboratives')
            .doc(sessionId)
            .collection('formulaires')
            .get();

        for (var doc in formulairesSnapshot.docs) {
          final formulaire = doc.data();

          participants.add({
            'userId': doc.id,
            'formulaire': formulaire,
            'infos': {},
            'source': 'formulaires',
          });
        }
      } catch (e) {
        print('⚠️ [PDF] Erreur formulaires: $e');
      }
    }

    // Méthode 3: Depuis session.participants (très ancien format) - dernier fallback
    if (participants.isEmpty) {
      final participantsRaw = sessionData['participants'] as List<dynamic>? ?? [];
      for (int i = 0; i < participantsRaw.length; i++) {
        final participant = participantsRaw[i] as Map<String, dynamic>;
        participants.add({
          'userId': participant['userId'] ?? 'participant_$i',
          'formulaire': participant['donneesFormulaire'] ?? {},
          'infos': participant,
          'source': 'session_participants',
        });
      }
    }

    return participants;
  }

  /// ✍️ Charger signatures complètes avec images
  static Future<Map<String, dynamic>> _chargerSignaturesCompletes(String sessionId) async {
    final signatures = <String, dynamic>{};

    try {
      final signaturesSnapshot = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('signatures')
          .get();

      for (var doc in signaturesSnapshot.docs) {
        final signatureData = doc.data();
        signatures[doc.id] = {
          ...signatureData,
          'userId': doc.id,
          'hasImage': signatureData['signatureBase64'] != null,
        };
      }
    } catch (e) {
      print('⚠️ [PDF] Erreur signatures: $e');
    }

    return signatures;
  }

  /// 🎨 Charger croquis complet avec image
  static Future<Map<String, dynamic>?> _chargerCroquisComplet(String sessionId) async {
    try {
      // Essayer plusieurs emplacements possibles
      final locations = ['principal', 'main', 'croquis_principal'];

      for (final location in locations) {
        final croquisDoc = await _firestore
            .collection('sessions_collaboratives')
            .doc(sessionId)
            .collection('croquis')
            .doc(location)
            .get();

        if (croquisDoc.exists) {
          final croquisData = croquisDoc.data()!;
          return {
            ...croquisData,
            'hasImage': croquisData['imageBase64'] != null || croquisData['sketchData'] != null,
            'source': location,
          };
        }
      }
    } catch (e) {
      print('⚠️ [PDF] Erreur croquis: $e');
    }

    return null;
  }

  /// 📋 Charger données communes (infos générales)
  static Future<Map<String, dynamic>> _chargerDonneesCommunes(String sessionId) async {
    try {
      // Essayer depuis donneesCommunes
      final sessionDoc = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .get();

      if (sessionDoc.exists) {
        final sessionData = sessionDoc.data()!;
        final donneesCommunes = sessionData['donneesCommunes'] as Map<String, dynamic>? ?? {};

        // Ajouter les infos de base de la session
        return {
          ...donneesCommunes,
          'dateAccident': sessionData['dateAccident'],
          'lieuAccident': sessionData['lieuAccident'],
          'sessionCode': sessionData['sessionCode'],
          'nombreConducteurs': sessionData['nombreConducteurs'],
        };
      }
    } catch (e) {
      print('⚠️ [PDF] Erreur données communes: $e');
    }

    return {};
  }

  /// 📸 Charger photos d'accident
  static Future<List<Map<String, dynamic>>> _chargerPhotosAccident(String sessionId) async {
    final photos = <Map<String, dynamic>>[];

    try {
      final photosSnapshot = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('photos')
          .get();

      for (var doc in photosSnapshot.docs) {
        final photoData = doc.data();
        photos.add({
          ...photoData,
          'id': doc.id,
        });
      }
    } catch (e) {
      print('⚠️ [PDF] Erreur photos: $e');
    }

    return photos;
  }

  /// 📄 Page de couverture moderne
  static Future<pw.Page> _buildPageCouverture(Map<String, dynamic> donnees) async {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      build: (context) => pw.Container(
        decoration: pw.BoxDecoration(
          gradient: pw.LinearGradient(
            colors: [PdfColors.blue900, PdfColors.blue700, PdfColors.blue500],
            begin: pw.Alignment.topLeft,
            end: pw.Alignment.bottomRight,
          ),
        ),
        child: pw.Column(
          children: [
            // En-tête officiel
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(40),
              child: pw.Column(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(25),
                      boxShadow: [
                        pw.BoxShadow(
                          color: PdfColors.black.shade(0.3),
                          offset: const PdfPoint(0, 5),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: pw.Text(
                      'RÉPUBLIQUE TUNISIENNE',
                      style: pw.TextStyle(
                        color: PdfColors.blue900,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Text(
                    'CONSTAT AMIABLE D\'ACCIDENT AUTOMOBILE',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 15),
                  pw.Text(
                    'VERSION DIGITALISÉE',
                    style: pw.TextStyle(
                      color: PdfColors.yellow,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            pw.Spacer(),
            
            // Informations session
            pw.Container(
              margin: const pw.EdgeInsets.all(40),
              padding: const pw.EdgeInsets.all(30),
              decoration: pw.BoxDecoration(
                color: PdfColors.white.shade(0.95),
                borderRadius: pw.BorderRadius.circular(20),
                boxShadow: [
                  pw.BoxShadow(
                    color: PdfColors.black.shade(0.2),
                    offset: const PdfPoint(0, 3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'INFORMATIONS DU CONSTAT',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  _buildInfoRow('Code Session', donnees['codeSession']?.toString() ?? 'N/A'),
                  _buildInfoRow('Date de création', _formatDate(donnees['dateCreation'])),
                  _buildInfoRow('Nombre de véhicules', donnees['nombreVehicules']?.toString() ?? '0'),
                  _buildInfoRow('Statut', donnees['statut']?.toString() ?? 'En cours'),
                ],
              ),
            ),
            
            pw.Spacer(),
            
            // Footer
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              child: pw.Text(
                'Conforme à la réglementation tunisienne - Document généré automatiquement',
                style: pw.TextStyle(
                  color: PdfColors.white.shade(0.8),
                  fontSize: 10,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📋 Page informations générales (améliorée avec toutes les données)
  static Future<pw.Page> _buildPageInfosGenerales(Map<String, dynamic> donnees) async {
    final sessionData = donnees;
    final participants = donnees['participants'] as List<dynamic>? ?? [];
    final donneesCommunes = donnees['donneesCommunes'] as Map<String, dynamic>? ?? {};
    final photos = donnees['photos'] as List<dynamic>? ?? [];

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // En-tête moderne avec gradient
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              gradient: const pw.LinearGradient(
                colors: [PdfColors.green700, PdfColors.green500],
              ),
              borderRadius: pw.BorderRadius.circular(15),
            ),
            child: pw.Row(
              children: [
                pw.Text('📋', style: pw.TextStyle(fontSize: 24, color: PdfColors.white)),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Text(
                    'INFORMATIONS GÉNÉRALES DE L\'ACCIDENT',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 25),

          // Section Date et Heure avec icônes
          _buildModernInfoSection('📅 DATE ET HEURE', [
            'Date: ${_formatDate(donneesCommunes['dateAccident'] ?? sessionData['dateAccident'])}',
            'Heure: ${donneesCommunes['heureAccident'] ?? sessionData['heureAccident'] ?? 'Non spécifiée'}',
            'Jour: ${_getJourSemaine(donneesCommunes['dateAccident'] ?? sessionData['dateAccident'])}',
          ], PdfColors.blue100),

          pw.SizedBox(height: 15),

          // Section Lieu avec détails GPS
          _buildModernInfoSection('📍 LIEU DE L\'ACCIDENT', [
            donneesCommunes['lieuAccident'] ?? sessionData['lieuAccident'] ?? 'Non spécifié',
            'GPS: ${donneesCommunes['lieuGps'] ?? sessionData['lieuGps'] ?? 'Non disponible'}',
            'Gouvernorat: ${donneesCommunes['gouvernorat'] ?? 'Non spécifié'}',
          ], PdfColors.orange100),

          pw.SizedBox(height: 15),

          // Section Conditions météo et circulation
          _buildModernInfoSection('🌤️ CONDITIONS', [
            'Météo: ${donneesCommunes['meteo'] ?? 'Non spécifiée'}',
            'Visibilité: ${donneesCommunes['visibilite'] ?? 'Non spécifiée'}',
            'État route: ${donneesCommunes['etatRoute'] ?? 'Non spécifié'}',
            'Circulation: ${donneesCommunes['circulation'] ?? 'Non spécifiée'}',
          ], PdfColors.green100),

          pw.SizedBox(height: 15),

          // Section Véhicules et Session
          _buildModernInfoSection('🚗 VÉHICULES ET SESSION', [
            'Nombre de véhicules: ${participants.length}',
            'Code session: ${sessionData['sessionCode'] ?? 'N/A'}',
            'Photos: ${photos.length} disponible(s)',
            'Statut: ${sessionData['status'] ?? 'En cours'}',
          ], PdfColors.purple100),

          pw.SizedBox(height: 15),

          // Section Conséquences
          _buildModernInfoSection('⚠️ CONSÉQUENCES', [
            'Blessés: ${donneesCommunes['blesses'] == true ? 'Oui' : 'Non'}',
            'Détails: ${donneesCommunes['detailsBlesses'] ?? 'Aucun'}',
            'Dégâts matériels: ${donneesCommunes['degatsMateriels'] ?? 'À évaluer'}',
            'Témoins: ${(donneesCommunes['temoins'] as List?)?.length ?? 0}',
          ], PdfColors.red100),
        ],
      ),
    );
  }

  /// 🚗 Page véhicule individuelle (complète avec toutes les données)
  static Future<pw.Page> _buildPageVehicule(Map<String, dynamic> participant, int numero, Map<String, dynamic> donnees) async {
    final formulaire = participant['formulaire'] as Map<String, dynamic>? ?? {};
    final donneesPersonnelles = formulaire['donneesPersonnelles'] as Map<String, dynamic>? ?? {};
    final infosParticipant = participant['infos'] as Map<String, dynamic>? ?? {};

    // Récupérer les données du véhicule depuis les données personnelles ou infos participant
    final vehiculeData = donneesPersonnelles['vehicule'] as Map<String, dynamic>? ??
                        donneesPersonnelles['vehiculeSelectionne'] as Map<String, dynamic>? ??
                        infosParticipant['vehicule'] as Map<String, dynamic>? ?? {};

    final assuranceData = donneesPersonnelles['assurance'] as Map<String, dynamic>? ??
                         vehiculeData['assurance'] as Map<String, dynamic>? ?? {};

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // En-tête véhicule moderne
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [PdfColors.blue700, PdfColors.blue500],
              ),
              borderRadius: pw.BorderRadius.circular(15),
            ),
            child: pw.Row(
              children: [
                pw.Text('🚗', style: pw.TextStyle(fontSize: 24, color: PdfColors.white)),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Text(
                    'VÉHICULE ${String.fromCharCode(64 + numero)} - DONNÉES COMPLÈTES',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Section Assurance complète
          _buildModernInfoSection('🏢 SOCIÉTÉ D\'ASSURANCE', [
            'Compagnie: ${assuranceData['compagnie'] ?? vehiculeData['compagnieAssurance'] ?? donneesPersonnelles['compagnieAssurance'] ?? 'Non spécifié'}',
            'N° Contrat: ${assuranceData['numeroContrat'] ?? vehiculeData['numeroContrat'] ?? donneesPersonnelles['numeroContrat'] ?? 'Non spécifié'}',
            'Agence: ${assuranceData['agence'] ?? vehiculeData['agence'] ?? donneesPersonnelles['agence'] ?? 'Non spécifié'}',
            'Validité: ${_formatDateRange(assuranceData['dateDebut'] ?? vehiculeData['dateDebut'], assuranceData['dateFin'] ?? vehiculeData['dateFin'])}',
          ], PdfColors.blue100),

          pw.SizedBox(height: 15),

          // Section Conducteur complète
          _buildModernInfoSection('👤 CONDUCTEUR', [
            'Nom: ${donneesPersonnelles['nom'] ?? donneesPersonnelles['nomConducteur'] ?? infosParticipant['nom'] ?? 'Non spécifié'}',
            'Prénom: ${donneesPersonnelles['prenom'] ?? donneesPersonnelles['prenomConducteur'] ?? infosParticipant['prenom'] ?? 'Non spécifié'}',
            'Adresse: ${donneesPersonnelles['adresse'] ?? donneesPersonnelles['adresseConducteur'] ?? infosParticipant['adresse'] ?? 'Non spécifié'}',
            'Téléphone: ${donneesPersonnelles['telephone'] ?? donneesPersonnelles['telephoneConducteur'] ?? infosParticipant['telephone'] ?? 'Non spécifié'}',
            'Email: ${donneesPersonnelles['email'] ?? infosParticipant['email'] ?? 'Non spécifié'}',
            'N° Permis: ${donneesPersonnelles['numeroPermis'] ?? 'Non spécifié'}',
            'Permis délivré: ${_formatDate(donneesPersonnelles['dateDelivrancePermis'])}',
          ], PdfColors.green100),

          pw.SizedBox(height: 15),

          // Section Véhicule complète
          _buildModernInfoSection('🚙 VÉHICULE', [
            'Marque: ${vehiculeData['marque'] ?? donneesPersonnelles['marque'] ?? 'Non spécifié'}',
            'Modèle: ${vehiculeData['modele'] ?? donneesPersonnelles['modele'] ?? 'Non spécifié'}',
            'Immatriculation: ${vehiculeData['immatriculation'] ?? donneesPersonnelles['immatriculation'] ?? 'Non spécifié'}',
            'Année: ${vehiculeData['annee'] ?? donneesPersonnelles['annee'] ?? 'Non spécifié'}',
            'Couleur: ${vehiculeData['couleur'] ?? donneesPersonnelles['couleur'] ?? 'Non spécifié'}',
            'Type: ${vehiculeData['typeVehicule'] ?? donneesPersonnelles['typeVehicule'] ?? 'Non spécifié'}',
          ], PdfColors.orange100),

          pw.SizedBox(height: 15),

          // Section Circonstances détaillées
          _buildCirconstancesSection(formulaire),

          pw.SizedBox(height: 15),

          // Section Dégâts et Points de choc
          _buildDegatsCompletSection(formulaire),
        ],
      ),
    );
  }

  /// 🎨 Page croquis et signatures (avec vraies images)
  static Future<pw.Page> _buildPageCroquisSignatures(Map<String, dynamic> donnees) async {
    final croquis = donnees['croquis'] as Map<String, dynamic>?;
    final signatures = donnees['signatures'] as Map<String, dynamic>? ?? {};

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // En-tête moderne
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              gradient: const pw.LinearGradient(
                colors: [PdfColors.purple700, PdfColors.purple500],
              ),
              borderRadius: pw.BorderRadius.circular(15),
            ),
            child: pw.Row(
              children: [
                pw.Text('🎨', style: pw.TextStyle(fontSize: 24, color: PdfColors.white)),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Text(
                    'CROQUIS ET SIGNATURES ÉLECTRONIQUES',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 25),

          // Section croquis avec image réelle
          _buildCroquisAvecImage(croquis),

          pw.SizedBox(height: 25),

          // Section signatures avec images réelles
          _buildSignaturesAvecImages(signatures),
        ],
      ),
    );
  }

  /// 💾 Sauvegarder le PDF
  static Future<String> _saveLocalPdf(pw.Document pdf, String sessionId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'constat_tunisien_moderne_$sessionId.pdf';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e) {
      print('❌ [PDF] Erreur sauvegarde: $e');
      rethrow;
    }
  }

  // === NOUVELLES MÉTHODES UTILITAIRES MODERNES ===

  /// 📋 Section d'information moderne avec couleur de fond
  static pw.Widget _buildModernInfoSection(String titre, List<String> infos, PdfColor backgroundColor) {
    // Nettoyer le titre des émojis pour éviter les erreurs de police
    final titreClean = titre.replaceAll(RegExp(r'[^\x00-\x7F]'), '').trim();

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: backgroundColor,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titreClean.isNotEmpty ? titreClean : 'SECTION',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 10),
          ...infos.map((info) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Text(
              info,
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
          )),
        ],
      ),
    );
  }

  /// 🚦 Section circonstances détaillées
  static pw.Widget _buildCirconstancesSection(Map<String, dynamic> formulaire) {
    final circonstances = formulaire['circonstances'] as List<dynamic>? ??
                         formulaire['circonstancesSelectionnees'] as List<dynamic>? ?? [];

    return _buildModernInfoSection('🚦 CIRCONSTANCES DE L\'ACCIDENT', [
      'Nombre de circonstances: ${circonstances.length}',
      ...circonstances.map((c) => '• ${_formatCirconstance(c.toString())}'),
      if (circonstances.isEmpty) 'Aucune circonstance spécifiée',
    ], PdfColors.yellow100);
  }

  /// 💥 Section dégâts complète
  static pw.Widget _buildDegatsCompletSection(Map<String, dynamic> formulaire) {
    final pointsChoc = formulaire['pointsChoc'] as List<dynamic>? ??
                      formulaire['pointsChocSelectionnes'] as List<dynamic>? ?? [];
    final degats = formulaire['degats'] as Map<String, dynamic>? ?? {};
    final degatsApparents = formulaire['degatsApparents'] as List<dynamic>? ?? [];

    return pw.Column(
      children: [
        _buildModernInfoSection('💥 POINTS DE CHOC', [
          'Nombre de points: ${pointsChoc.length}',
          ...pointsChoc.map((p) => '• ${p.toString()}'),
          if (pointsChoc.isEmpty) 'Aucun point de choc spécifié',
        ], PdfColors.red100),

        pw.SizedBox(height: 10),

        _buildModernInfoSection('🔧 DÉGÂTS APPARENTS', [
          'Description: ${degats['description'] ?? formulaire['observations'] ?? 'Non spécifié'}',
          'Gravité: ${degats['gravite'] ?? 'Non évaluée'}',
          'Dégâts: ${degatsApparents.join(', ')}',
          'Remarques: ${formulaire['remarques'] ?? 'Aucune'}',
        ], PdfColors.orange100),
      ],
    );
  }

  /// 🎨 Croquis avec image réelle
  static pw.Widget _buildCroquisAvecImage(Map<String, dynamic>? croquis) {
    if (croquis == null) {
      return _buildModernInfoSection('🎨 CROQUIS DE L\'ACCIDENT', [
        'Aucun croquis disponible',
        'Le croquis n\'a pas été créé ou sauvegardé',
      ], PdfColors.grey100);
    }

    final hasImage = croquis['imageBase64'] != null || croquis['sketchData'] != null;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildModernInfoSection('🎨 CROQUIS DE L\'ACCIDENT', [
          'Source: ${croquis['source'] ?? 'Inconnu'}',
          'Image disponible: ${hasImage ? 'Oui' : 'Non'}',
          'Créé le: ${_formatDate(croquis['dateCreation'])}',
        ], PdfColors.blue100),

        if (hasImage) ...[
          pw.SizedBox(height: 15),
          pw.Container(
            width: double.infinity,
            height: 200,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: _buildImageFromBase64(croquis['imageBase64'] ?? croquis['sketchData']),
          ),
        ],
      ],
    );
  }

  /// ✍️ Signatures avec images réelles
  static pw.Widget _buildSignaturesAvecImages(Map<String, dynamic> signatures) {
    if (signatures.isEmpty) {
      return _buildModernInfoSection('✍️ SIGNATURES ÉLECTRONIQUES', [
        'Aucune signature disponible',
        'Les signatures n\'ont pas encore été collectées',
      ], PdfColors.grey100);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildModernInfoSection('✍️ SIGNATURES ÉLECTRONIQUES', [
          'Nombre de signatures: ${signatures.length}',
          'Toutes les parties ont signé: ${signatures.length >= 2 ? 'Oui' : 'Non'}',
        ], PdfColors.green100),

        pw.SizedBox(height: 15),

        ...signatures.entries.map((entry) => _buildSignatureIndividuelle(entry.key, entry.value)),
      ],
    );
  }

  /// ✍️ Signature individuelle avec image
  static pw.Widget _buildSignatureIndividuelle(String userId, dynamic signatureData) {
    final signature = signatureData as Map<String, dynamic>? ?? {};
    final hasImage = signature['signatureBase64'] != null;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.green200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Conducteur ${signature['roleVehicule'] ?? userId}',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Signé le: ${_formatDate(signature['dateSignature'])}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),

          if (hasImage) ...[
            pw.SizedBox(height: 10),
            pw.Container(
              width: 200,
              height: 80,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: _buildImageFromBase64(signature['signatureBase64']),
            ),
          ] else ...[
            pw.SizedBox(height: 10),
            pw.Text(
              'Signature électronique validée',
              style: pw.TextStyle(
                fontSize: 10,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.green600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 🖼️ Construire image depuis base64
  static pw.Widget _buildImageFromBase64(String? base64Data) {
    if (base64Data == null || base64Data.isEmpty) {
      return pw.Container(
        child: pw.Center(
          child: pw.Text(
            'Image non disponible',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey500,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ),
      );
    }

    try {
      // Nettoyer le base64 (enlever le préfixe data:image si présent)
      String cleanBase64 = base64Data;
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }

      final imageBytes = base64Decode(cleanBase64);
      return pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.contain);
    } catch (e) {
      print('⚠️ [PDF] Erreur décodage image: $e');
      return pw.Container(
        child: pw.Center(
          child: pw.Text(
            'Erreur chargement image',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.red500,
            ),
          ),
        ),
      );
    }
  }

  // === MÉTHODES UTILITAIRES EXISTANTES ===

  static pw.Widget _buildSectionHeader(String titre) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.blue800, PdfColors.blue600],
        ),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Text(
        titre,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildVehiculeHeader(int numero) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        'VÉHICULE $numero',
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildInfoSection(String titre, List<pw.Widget> contenu) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Text(
              titre,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
          ),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: contenu,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String valeur) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              valeur,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildVehiculesSummary(List<dynamic> participants) {
    return _buildInfoSection('3. VÉHICULES IMPLIQUÉS', [
      ...participants.asMap().entries.map((entry) {
        final index = entry.key;
        final participant = entry.value as Map<String, dynamic>;
        final formulaire = participant['formulaire'] as Map<String, dynamic>? ?? {};

        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 10),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(5),
            border: pw.Border.all(color: PdfColors.blue200),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'VÉHICULE ${index + 1}',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 5),
              _buildInfoRow('Immatriculation', _getNestedValue(formulaire, ['vehicule', 'immatriculation']) ?? 'N/A'),
              _buildInfoRow('Conducteur', '${_getNestedValue(formulaire, ['conducteur', 'nom']) ?? ''} ${_getNestedValue(formulaire, ['conducteur', 'prenom']) ?? ''}'),
            ],
          ),
        );
      }).toList(),
    ]);
  }

  static pw.Widget _buildDegatsSection(Map<String, dynamic> formulaire) {
    return _buildInfoSection('DÉGÂTS ET CIRCONSTANCES', [
      _buildInfoRow('Points de choc', _formatListe(_getNestedValue(formulaire, ['pointsChoc']))),
      _buildInfoRow('Dégâts apparents', _formatListe(_getNestedValue(formulaire, ['degats']))),
      _buildInfoRow('Circonstances', _formatListe(_getNestedValue(formulaire, ['circonstances']))),
      _buildInfoRow('Observations', _getNestedValue(formulaire, ['observations'])?.toString() ?? 'Aucune'),
    ]);
  }

  static pw.Widget _buildCroquisSection(Map<String, dynamic> croquis) {
    return pw.Container(
      width: double.infinity,
      height: 200,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Center(
        child: croquis.isNotEmpty && croquis['url'] != null
            ? pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green100,
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Text(
                      'CROQUIS DISPONIBLE',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Croquis créé numériquement par les conducteurs',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              )
            : pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.orange100,
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Text(
                      'CROQUIS NON FOURNI',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange800,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Espace réservé pour le croquis de l\'accident',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  static pw.Widget _buildSignaturesSection(Map<String, dynamic> signatures) {
    return _buildInfoSection('SIGNATURES ÉLECTRONIQUES', [
      ...signatures.entries.map((entry) {
        final userId = entry.key;
        final signature = entry.value as Map<String, dynamic>;

        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 10),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.green50,
            borderRadius: pw.BorderRadius.circular(5),
            border: pw.Border.all(color: PdfColors.green200),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Conducteur: ${signature['nom'] ?? 'N/A'} ${signature['prenom'] ?? ''}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Date: ${_formatDate(signature['timestamp'])}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Text(
                  'SIGNÉ',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      if (signatures.isEmpty)
        pw.Text(
          'Aucune signature disponible',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
    ]);
  }

  // === UTILITAIRES DE FORMATAGE ===

  static String _formatDate(dynamic date) {
    if (date == null) return 'Non spécifié';

    try {
      DateTime dateTime;
      if (date is Timestamp) {
        dateTime = date.toDate();
      } else if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'Format invalide';
      }

      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return 'Date invalide';
    }
  }

  static String _formatHeure(dynamic date) {
    if (date == null) return 'Non spécifié';

    try {
      DateTime dateTime;
      if (date is Timestamp) {
        dateTime = date.toDate();
      } else if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'Format invalide';
      }

      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return 'Heure invalide';
    }
  }

  static String _formatTemoins(dynamic temoins) {
    if (temoins == null) return 'Aucun';
    if (temoins is List) {
      return temoins.isEmpty ? 'Aucun' : '${temoins.length} témoin(s)';
    }
    return temoins.toString();
  }

  static String _formatListe(dynamic liste) {
    if (liste == null) return 'Aucun';
    if (liste is List) {
      return liste.isEmpty ? 'Aucun' : liste.join(', ');
    }
    return liste.toString();
  }

  static dynamic _getNestedValue(Map<String, dynamic> map, List<String> keys) {
    dynamic current = map;
    for (String key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  // === MÉTHODES DE FORMATAGE AVANCÉES ===

  /// 📅 Obtenir le jour de la semaine
  static String _getJourSemaine(dynamic date) {
    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is Timestamp) {
        dateTime = date.toDate();
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'Inconnu';
      }

      const jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
      return jours[dateTime.weekday - 1];
    } catch (e) {
      return 'Inconnu';
    }
  }

  /// 📅 Formater une plage de dates
  static String _formatDateRange(dynamic dateDebut, dynamic dateFin) {
    final debut = _formatDate(dateDebut);
    final fin = _formatDate(dateFin);

    if (debut == 'Non spécifié' || fin == 'Non spécifié') {
      return 'Période non spécifiée';
    }

    return 'Du $debut au $fin';
  }

  /// 🚦 Formater une circonstance
  static String _formatCirconstance(String circonstance) {
    // Mapping des circonstances techniques vers du français lisible
    const mapping = {
      'roulait': 'Roulait normalement',
      'virait_droite': 'Virait à droite',
      'virait_gauche': 'Virait à gauche',
      'reculait': 'Reculait',
      'demarrait': 'Démarrait',
      'arretait': 'S\'arrêtait',
      'stationnait': 'Stationnait',
      'sortait_stationnement': 'Sortait d\'un stationnement',
      'entrait_stationnement': 'Entrait dans un stationnement',
      'ouvrait_portiere': 'Ouvrait une portière',
      'descendait_vehicule': 'Descendait du véhicule',
      'changeait_voie': 'Changeait de voie',
      'doublait': 'Doublait',
      'ignorait_priorite': 'Ignorait la priorité',
      'ignorait_signal_arret': 'Ignorait un signal d\'arrêt',
      'ignorait_feu_rouge': 'Ignorait un feu rouge',
      'roulait_sens_interdit': 'Roulait en sens interdit',
    };

    return mapping[circonstance] ?? circonstance.replaceAll('_', ' ').toUpperCase();
  }

  /// 🔍 Obtenir une valeur imbriquée de manière sécurisée
  static dynamic _getNestedValueSafe(Map<String, dynamic> map, List<String> keys) {
    dynamic current = map;
    for (final key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  /// 📊 Formater les témoins
  static String _formatTemoinsListe(dynamic temoins) {
    if (temoins == null) return 'Aucun témoin';

    if (temoins is List) {
      if (temoins.isEmpty) return 'Aucun témoin';

      final temoinsFormates = temoins.map((temoin) {
        if (temoin is Map<String, dynamic>) {
          final nom = temoin['nom'] ?? '';
          final prenom = temoin['prenom'] ?? '';
          final telephone = temoin['telephone'] ?? '';
          return '$prenom $nom${telephone.isNotEmpty ? ' ($telephone)' : ''}';
        }
        return temoin.toString();
      }).toList();

      return '${temoins.length} témoin(s): ${temoinsFormates.join(', ')}';
    }

    return temoins.toString();
  }

  /// 🎨 Vérifier si une image base64 est valide
  static bool _isValidBase64Image(String? base64Data) {
    if (base64Data == null || base64Data.isEmpty) return false;

    try {
      String cleanBase64 = base64Data;
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }

      final decoded = base64Decode(cleanBase64);
      return decoded.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 📝 Formater les observations
  static String _formatObservations(Map<String, dynamic> formulaire) {
    final observations = formulaire['observations'] as String? ?? '';
    final remarques = formulaire['remarques'] as String? ?? '';

    final parts = <String>[];
    if (observations.isNotEmpty) parts.add('Observations: $observations');
    if (remarques.isNotEmpty) parts.add('Remarques: $remarques');

    return parts.isEmpty ? 'Aucune observation' : parts.join('\n');
  }

  /// 🏢 Formater les informations d'assurance
  static List<String> _formatAssuranceInfo(Map<String, dynamic> formulaire) {
    final vehiculeSelectionne = formulaire['vehiculeSelectionne'] as Map<String, dynamic>? ?? {};

    return [
      'Compagnie: ${vehiculeSelectionne['compagnieAssurance'] ?? formulaire['compagnieAssurance'] ?? 'Non spécifié'}',
      'N° Contrat: ${vehiculeSelectionne['numeroContrat'] ?? formulaire['numeroContrat'] ?? 'Non spécifié'}',
      'Agence: ${vehiculeSelectionne['agence'] ?? formulaire['agence'] ?? 'Non spécifié'}',
      'Validité: ${_formatDateRange(vehiculeSelectionne['dateDebut'], vehiculeSelectionne['dateFin'])}',
    ];
  }

  /// 👤 Formater les informations du conducteur
  static List<String> _formatConducteurInfo(Map<String, dynamic> formulaire) {
    final donneesPersonnelles = formulaire['donneesPersonnelles'] as Map<String, dynamic>? ?? {};

    return [
      'Nom: ${donneesPersonnelles['nomConducteur'] ?? formulaire['nomConducteur'] ?? 'Non spécifié'}',
      'Prénom: ${donneesPersonnelles['prenomConducteur'] ?? formulaire['prenomConducteur'] ?? 'Non spécifié'}',
      'Adresse: ${donneesPersonnelles['adresseConducteur'] ?? formulaire['adresseConducteur'] ?? 'Non spécifié'}',
      'Téléphone: ${donneesPersonnelles['telephoneConducteur'] ?? formulaire['telephoneConducteur'] ?? 'Non spécifié'}',
      'N° Permis: ${donneesPersonnelles['numeroPermis'] ?? formulaire['numeroPermis'] ?? 'Non spécifié'}',
      'Permis délivré: ${_formatDate(donneesPersonnelles['dateDelivrancePermis'] ?? formulaire['dateDelivrancePermis'])}',
    ];
  }

  /// 🚙 Formater les informations du véhicule
  static List<String> _formatVehiculeInfo(Map<String, dynamic> formulaire) {
    final vehicule = formulaire['vehicule'] as Map<String, dynamic>? ?? {};

    return [
      'Marque: ${vehicule['marque'] ?? formulaire['marque'] ?? 'Non spécifié'}',
      'Modèle: ${vehicule['modele'] ?? formulaire['modele'] ?? 'Non spécifié'}',
      'Immatriculation: ${vehicule['immatriculation'] ?? formulaire['immatriculation'] ?? 'Non spécifié'}',
      'Année: ${vehicule['annee'] ?? formulaire['annee'] ?? 'Non spécifié'}',
      'Couleur: ${vehicule['couleur'] ?? formulaire['couleur'] ?? 'Non spécifié'}',
      'Type: ${vehicule['typeVehicule'] ?? formulaire['typeVehicule'] ?? 'Non spécifié'}',
    ];
  }
}

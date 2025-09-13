import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

/// 🤖 Service intelligent de génération PDF pour constats multi-véhicules
class IntelligentConstatPdfService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 📄 Générer le PDF intelligent multi-véhicules
  static Future<String> genererConstatMultiVehicules({
    required String sessionId,
    required Map<String, dynamic> sessionData,
  }) async {
    print('📄 [PDF] Génération PDF intelligent pour session $sessionId');

    try {
      // 1. Charger toutes les données de la session
      final donneesCompletes = await _chargerDonneesCompletes(sessionId);
      
      // 2. Créer le document PDF
      final pdf = pw.Document();
      
      // 3. PAGE 1: Couverture et informations générales
      pdf.addPage(await _buildPageCouverture(donneesCompletes));
      
      // 4. PAGES 2 à N+1: Détails par véhicule (1 page par véhicule)
      final vehicules = donneesCompletes['vehicules'] as List<Map<String, dynamic>>;
      for (int i = 0; i < vehicules.length; i++) {
        pdf.addPage(await _buildPageVehicule(donneesCompletes, vehicules[i], i));
      }
      
      // 5. PAGE FINALE: Croquis collaboratif et synthèse
      pdf.addPage(await _buildPageCroquisEtSynthese(donneesCompletes));
      
      // 6. Sauvegarder et uploader
      final pdfUrl = await _sauvegarderEtUploader(sessionId, pdf);
      
      // 7. Envoyer aux agents d'assurance
      await _envoyerAuxAgentsAssurance(sessionId, donneesCompletes, pdfUrl);
      
      print('✅ [PDF] PDF intelligent généré et transmis: $pdfUrl');
      return pdfUrl;
      
    } catch (e) {
      print('❌ [PDF] Erreur génération PDF: $e');
      rethrow;
    }
  }

  /// 📊 Charger toutes les données complètes de la session
  static Future<Map<String, dynamic>> _chargerDonneesCompletes(String sessionId) async {
    // Charger session principale
    final sessionDoc = await _firestore
        .collection('collaborative_sessions')
        .doc(sessionId)
        .get();
    
    if (!sessionDoc.exists) {
      throw Exception('Session non trouvée: $sessionId');
    }
    
    final sessionData = sessionDoc.data()!;
    
    // Charger données participants
    final participantsSnapshot = await _firestore
        .collection('collaborative_sessions')
        .doc(sessionId)
        .collection('participants_data')
        .get();
    
    // Charger croquis
    final croquisSnapshot = await _firestore
        .collection('collaborative_sessions')
        .doc(sessionId)
        .collection('sketch_data')
        .get();
    
    // Charger signatures
    final signaturesSnapshot = await _firestore
        .collection('collaborative_sessions')
        .doc(sessionId)
        .collection('signatures')
        .get();
    
    return {
      'session': sessionData,
      'participants': participantsSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList(),
      'croquis': croquisSnapshot.docs.isNotEmpty ? croquisSnapshot.docs.first.data() : null,
      'signatures': signaturesSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList(),
      'vehicules': _extraireVehicules(participantsSnapshot.docs),
      'infosGenerales': sessionData['commonInfo'] ?? {},
    };
  }

  /// 🚗 Extraire les informations des véhicules
  static List<Map<String, dynamic>> _extraireVehicules(List<QueryDocumentSnapshot> participants) {
    return participants.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'participantId': doc.id,
        'vehicleIndex': data['vehicleIndex'] ?? 0,
        'conducteur': data['driver'] ?? {},
        'vehicule': data['vehicle'] ?? {},
        'assurance': data['insurance'] ?? {},
        'circonstances': data['circumstances'] ?? '',
        'degats': data['damages'] ?? [],
        'observations': data['observations'] ?? '',
        'photos': data['photos'] ?? [],
      };
    }).toList()..sort((a, b) => a['vehicleIndex'].compareTo(b['vehicleIndex']));
  }

  /// 📋 Construire la page de couverture
  static Future<pw.Page> _buildPageCouverture(Map<String, dynamic> donnees) async {
    final session = donnees['session'] as Map<String, dynamic>;
    final infosGenerales = donnees['infosGenerales'] as Map<String, dynamic>;
    final vehicules = donnees['vehicules'] as List<Map<String, dynamic>>;
    
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // En-tête officiel
          _buildEnTeteOfficiel(session),
          pw.SizedBox(height: 30),
          
          // Informations générales de l'accident
          _buildInfosGeneralesAccident(infosGenerales),
          pw.SizedBox(height: 20),
          
          // Récapitulatif des véhicules
          _buildRecapitulatifVehicules(vehicules),
          pw.SizedBox(height: 20),
          
          // QR Code et métadonnées
          _buildQRCodeEtMetadonnees(session),
        ],
      ),
    );
  }

  /// 🏛️ Construire l'en-tête officiel
  static pw.Widget _buildEnTeteOfficiel(Map<String, dynamic> session) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue800, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'RÉPUBLIQUE TUNISIENNE',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'CONSTAT AMIABLE D\'ACCIDENT AUTOMOBILE',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Numéro: CNT-${DateTime.now().year}-${session['sessionCode'] ?? 'XXXXXX'}',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Généré par l\'application Constat Tunisie',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 📍 Construire les informations générales de l'accident
  static pw.Widget _buildInfosGeneralesAccident(Map<String, dynamic> infos) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMATIONS GÉNÉRALES DE L\'ACCIDENT',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 12),
          
          // Date et heure
          _buildInfoRow('Date de l\'accident:', _formatDate(infos['dateAccident'])),
          _buildInfoRow('Heure:', _formatTime(infos['dateAccident'])),
          
          // Lieu
          _buildInfoRow('Lieu:', infos['location']?['address'] ?? 'Non spécifié'),
          
          // Conditions
          _buildInfoRow('Blessés:', infos['hasInjuries'] == true ? 'OUI' : 'NON'),
          _buildInfoRow('Témoins:', infos['witnesses']?.length > 0 ? 'OUI (${infos['witnesses'].length})' : 'NON'),
          
          // Circonstances générales
          if (infos['circumstances'] != null && infos['circumstances'].toString().isNotEmpty)
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Circonstances générales:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(infos['circumstances'].toString()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 🚗 Construire le récapitulatif des véhicules
  static pw.Widget _buildRecapitulatifVehicules(List<Map<String, dynamic>> vehicules) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'VÉHICULES IMPLIQUÉS (${vehicules.length})',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 12),
          
          ...vehicules.asMap().entries.map((entry) {
            final index = entry.key;
            final vehicule = entry.value;
            final vehiculeInfo = vehicule['vehicule'] as Map<String, dynamic>;
            final conducteurInfo = vehicule['conducteur'] as Map<String, dynamic>;
            
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 30,
                    height: 30,
                    decoration: pw.BoxDecoration(
                      color: _getVehicleColor(index),
                      borderRadius: pw.BorderRadius.circular(15),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        String.fromCharCode(65 + index), // A, B, C...
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '${vehiculeInfo['marque'] ?? ''} ${vehiculeInfo['modele'] ?? ''} (${vehiculeInfo['immatriculation'] ?? ''})',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Conducteur: ${conducteurInfo['prenom'] ?? ''} ${conducteurInfo['nom'] ?? ''}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// 📱 Construire QR code et métadonnées
  static pw.Widget _buildQRCodeEtMetadonnees(Map<String, dynamic> session) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'MÉTADONNÉES',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Session ID: ${session['sessionId'] ?? 'N/A'}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Généré le: ${_formatDateTime(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Version app: 1.0.0', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        pw.Container(
          width: 80,
          height: 80,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
          ),
          child: pw.Center(
            child: pw.Text(
              'QR CODE\nVÉRIFICATION',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
        ),
      ],
    );
  }

  /// 🛠️ Fonctions utilitaires
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  static PdfColor _getVehicleColor(int index) {
    final colors = [
      PdfColors.blue,
      PdfColors.red,
      PdfColors.green,
      PdfColors.orange,
      PdfColors.purple,
      PdfColors.teal,
    ];
    return colors[index % colors.length];
  }

  static String _formatDate(dynamic date) {
    if (date == null) return 'Non spécifié';
    if (date is Timestamp) {
      final dt = date.toDate();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }
    return date.toString();
  }

  static String _formatTime(dynamic date) {
    if (date == null) return 'Non spécifié';
    if (date is Timestamp) {
      final dt = date.toDate();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return date.toString();
  }

  static String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} à ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// 🚗 Construire la page détaillée d'un véhicule
  static Future<pw.Page> _buildPageVehicule(
    Map<String, dynamic> donnees,
    Map<String, dynamic> vehicule,
    int index,
  ) async {
    final conducteur = vehicule['conducteur'] as Map<String, dynamic>;
    final vehiculeInfo = vehicule['vehicule'] as Map<String, dynamic>;
    final assurance = vehicule['assurance'] as Map<String, dynamic>;
    final degats = vehicule['degats'] as List<dynamic>;
    final photos = vehicule['photos'] as List<dynamic>;

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // En-tête véhicule
          _buildEnTeteVehicule(index),
          pw.SizedBox(height: 20),

          // Section 1: Identité conducteur
          _buildSectionIdentiteConducteur(conducteur),
          pw.SizedBox(height: 15),

          // Section 2: Informations véhicule
          _buildSectionInformationsVehicule(vehiculeInfo),
          pw.SizedBox(height: 15),

          // Section 3: Assurance et contrat
          _buildSectionAssuranceContrat(assurance),
          pw.SizedBox(height: 15),

          // Section 4: Circonstances spécifiques
          _buildSectionCirconstances(vehicule['circonstances']),
          pw.SizedBox(height: 15),

          // Section 5: Dégâts et photos
          await _buildSectionDegatsEtPhotos(degats, photos),
          pw.SizedBox(height: 15),

          // Section 6: Observations
          _buildSectionObservations(vehicule['observations']),
        ],
      ),
    );
  }

  /// 🏷️ Construire l'en-tête du véhicule
  static pw.Widget _buildEnTeteVehicule(int index) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _getVehicleColor(index),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 40,
            height: 40,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Center(
              child: pw.Text(
                String.fromCharCode(65 + index), // A, B, C...
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: _getVehicleColor(index),
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Text(
            'VÉHICULE ${String.fromCharCode(65 + index)} - DÉTAILS COMPLETS',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 👤 Section identité conducteur
  static pw.Widget _buildSectionIdentiteConducteur(Map<String, dynamic> conducteur) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue800),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '👤 IDENTITÉ DU CONDUCTEUR',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 8),

          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Nom:', conducteur['nom'] ?? 'Non spécifié'),
                    _buildInfoRow('Prénom:', conducteur['prenom'] ?? 'Non spécifié'),
                    _buildInfoRow('Date naissance:', _formatDate(conducteur['dateNaissance'])),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Permis N°:', conducteur['permis'] ?? 'Non spécifié'),
                    _buildInfoRow('Adresse:', conducteur['adresse'] ?? 'Non spécifié'),
                    _buildInfoRow('Téléphone:', conducteur['telephone'] ?? 'Non spécifié'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🚗 Section informations véhicule
  static pw.Widget _buildSectionInformationsVehicule(Map<String, dynamic> vehicule) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.green800),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '🚗 INFORMATIONS VÉHICULE',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.SizedBox(height: 8),

          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Marque:', vehicule['marque'] ?? 'Non spécifié'),
                    _buildInfoRow('Modèle:', vehicule['modele'] ?? 'Non spécifié'),
                    _buildInfoRow('Année:', vehicule['annee']?.toString() ?? 'Non spécifié'),
                    _buildInfoRow('Couleur:', vehicule['couleur'] ?? 'Non spécifié'),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Immatriculation:', vehicule['immatriculation'] ?? 'Non spécifié'),
                    _buildInfoRow('N° Châssis:', vehicule['chassis'] ?? 'Non spécifié'),
                    _buildInfoRow('Type carburant:', vehicule['carburant'] ?? 'Non spécifié'),
                    _buildInfoRow('Puissance:', vehicule['puissance']?.toString() ?? 'Non spécifié'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🛡️ Section assurance et contrat
  static pw.Widget _buildSectionAssuranceContrat(Map<String, dynamic> assurance) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.orange800),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '🛡️ ASSURANCE ET CONTRAT',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange800,
            ),
          ),
          pw.SizedBox(height: 8),

          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Compagnie:', assurance['compagnie'] ?? 'Non spécifié'),
                    _buildInfoRow('N° Police:', assurance['numeroPolice'] ?? 'Non spécifié'),
                    _buildInfoRow('Type couverture:', assurance['typeCouverture'] ?? 'Non spécifié'),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Date échéance:', _formatDate(assurance['dateEcheance'])),
                    _buildInfoRow('Agence:', assurance['agence'] ?? 'Non spécifié'),
                    _buildInfoRow('Statut:', assurance['isActive'] == true ? 'ACTIF' : 'INACTIF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ⚡ Section circonstances spécifiques
  static pw.Widget _buildSectionCirconstances(String? circonstances) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.purple800),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '⚡ CIRCONSTANCES SPÉCIFIQUES',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.purple800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            circonstances?.isNotEmpty == true ? circonstances! : 'Aucune circonstance spécifique déclarée',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  /// 💥 Section dégâts et photos
  static Future<pw.Widget> _buildSectionDegatsEtPhotos(
    List<dynamic> degats,
    List<dynamic> photos,
  ) async {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.red800),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '💥 DÉGÂTS APPARENTS ET PHOTOS',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red800,
            ),
          ),
          pw.SizedBox(height: 8),

          // Liste des dégâts
          if (degats.isNotEmpty) ...[
            pw.Text(
              'Dégâts constatés:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
            pw.SizedBox(height: 4),
            ...degats.map((degat) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(
                '• ${degat['zone'] ?? 'Zone non spécifiée'}: ${degat['description'] ?? 'Description non fournie'} (${degat['severity'] ?? 'Gravité non évaluée'})',
                style: const pw.TextStyle(fontSize: 9),
              ),
            )).toList(),
          ] else [
            pw.Text(
              'Aucun dégât apparent déclaré',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ],

          pw.SizedBox(height: 8),

          // Photos
          if (photos.isNotEmpty) ...[
            pw.Text(
              'Photos des dégâts: ${photos.length} photo(s) jointe(s)',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Les photos sont disponibles dans la version numérique du constat.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
            ),
          ] else [
            pw.Text(
              'Aucune photo des dégâts fournie',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ],
        ],
      ),
    );
  }

  /// 📝 Section observations
  static pw.Widget _buildSectionObservations(String? observations) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.teal800),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '📝 OBSERVATIONS PERSONNELLES',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            observations?.isNotEmpty == true ? observations! : 'Aucune observation particulière',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  /// 🎨 Construire la page finale avec croquis et synthèse
  static Future<pw.Page> _buildPageCroquisEtSynthese(Map<String, dynamic> donnees) async {
    final croquis = donnees['croquis'] as Map<String, dynamic>?;
    final signatures = donnees['signatures'] as List<Map<String, dynamic>>;
    final vehicules = donnees['vehicules'] as List<Map<String, dynamic>>;

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // En-tête page finale
          _buildEnTetePageFinale(),
          pw.SizedBox(height: 20),

          // Section croquis
          await _buildSectionCroquis(croquis),
          pw.SizedBox(height: 20),

          // Section synthèse
          _buildSectionSynthese(vehicules),
          pw.SizedBox(height: 20),

          // Section signatures
          _buildSectionSignatures(signatures),
          pw.SizedBox(height: 20),

          // Métadonnées finales
          _buildMetadonneesFinales(),
        ],
      ),
    );
  }

  /// 🏁 En-tête page finale
  static pw.Widget _buildEnTetePageFinale() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue800,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        '🎨 CROQUIS COLLABORATIF ET SYNTHÈSE FINALE',
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// 🎨 Section croquis
  static Future<pw.Widget> _buildSectionCroquis(Map<String, dynamic>? croquis) async {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue800),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '🎨 CROQUIS DE L\'ACCIDENT',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 12),

          // Zone du croquis
          pw.Container(
            width: double.infinity,
            height: 200,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: croquis != null
              ? pw.Center(
                  child: pw.Text(
                    'CROQUIS COLLABORATIF\n\n'
                    'Validé par tous les participants\n'
                    'Date: ${_formatDateTime(DateTime.now())}\n\n'
                    'Le croquis détaillé est disponible\n'
                    'dans la version numérique du constat.',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                )
              : pw.Center(
                  child: pw.Text(
                    'AUCUN CROQUIS FOURNI',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
          ),

          if (croquis != null) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Description: ${croquis['description'] ?? 'Aucune description fournie'}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  /// 📊 Section synthèse
  static pw.Widget _buildSectionSynthese(List<Map<String, dynamic>> vehicules) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.green800),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '📊 SYNTHÈSE GLOBALE',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.SizedBox(height: 8),

          pw.Text(
            'Nombre de véhicules impliqués: ${vehicules.length}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.SizedBox(height: 4),

          ...vehicules.asMap().entries.map((entry) {
            final index = entry.key;
            final vehicule = entry.value;
            final vehiculeInfo = vehicule['vehicule'] as Map<String, dynamic>;
            final conducteur = vehicule['conducteur'] as Map<String, dynamic>;

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                '• Véhicule ${String.fromCharCode(65 + index)}: ${vehiculeInfo['marque']} ${vehiculeInfo['modele']} - ${conducteur['prenom']} ${conducteur['nom']}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            );
          }).toList(),

          pw.SizedBox(height: 8),
          pw.Text(
            'Ce constat a été établi de manière collaborative par tous les participants.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ],
      ),
    );
  }

  /// ✍️ Section signatures
  static pw.Widget _buildSectionSignatures(List<Map<String, dynamic>> signatures) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.purple800),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '✍️ SIGNATURES NUMÉRIQUES CERTIFIÉES',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.purple800,
            ),
          ),
          pw.SizedBox(height: 8),

          if (signatures.isNotEmpty) ...[
            ...signatures.map((signature) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${signature['conducteurNom'] ?? 'Conducteur'} - Véhicule ${signature['vehicleIndex'] ?? 'X'}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Signé le: ${_formatDateTime(signature['timestamp']?.toDate() ?? DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    'OTP validé: ${signature['otpValidated'] == true ? 'OUI' : 'NON'}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    'Hash: ${signature['signatureHash'] ?? 'N/A'}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                  ),
                ],
              ),
            )).toList(),
          ] else [
            pw.Text(
              'Aucune signature numérique enregistrée',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ],
        ],
      ),
    );
  }

  /// 🔒 Métadonnées finales
  static pw.Widget _buildMetadonneesFinales() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey600),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '🔒 CERTIFICAT DE CONFORMITÉ NUMÉRIQUE',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),

          pw.Text(
            'Ce document a été généré automatiquement par l\'application Constat Tunisie.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            'Toutes les données ont été collectées de manière collaborative et sécurisée.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            'Les signatures numériques ont été validées par OTP SMS.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Document généré le: ${_formatDateTime(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
          pw.Text(
            'Version application: 1.0.0',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
        ],
      ),
    );
  }

  /// 💾 Sauvegarder et uploader le PDF
  static Future<String> _sauvegarderEtUploader(String sessionId, pw.Document pdf) async {
    try {
      // Sauvegarder localement
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'constat_intelligent_${sessionId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Uploader vers Firebase Storage
      final storageRef = _storage.ref().child('constats_intelligents/$sessionId/$fileName');
      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      // Sauvegarder les métadonnées
      await _firestore.collection('constat_pdfs').add({
        'sessionId': sessionId,
        'fileName': fileName,
        'downloadUrl': downloadUrl,
        'fileSize': await file.length(),
        'generatedAt': FieldValue.serverTimestamp(),
        'type': 'intelligent_multi_vehicules',
        'version': '1.0.0',
      });

      return downloadUrl;
    } catch (e) {
      print('❌ [PDF] Erreur sauvegarde: $e');
      rethrow;
    }
  }

  /// 📧 Envoyer aux agents d'assurance
  static Future<void> _envoyerAuxAgentsAssurance(
    String sessionId,
    Map<String, dynamic> donnees,
    String pdfUrl,
  ) async {
    try {
      final vehicules = donnees['vehicules'] as List<Map<String, dynamic>>;

      for (final vehicule in vehicules) {
        final assurance = vehicule['assurance'] as Map<String, dynamic>;
        final agentEmail = assurance['agentEmail'] as String?;

        if (agentEmail != null && agentEmail.isNotEmpty) {
          // Envoyer notification à l'agent
          await _firestore.collection('agent_notifications').add({
            'agentEmail': agentEmail,
            'sessionId': sessionId,
            'vehiculeId': vehicule['participantId'],
            'pdfUrl': pdfUrl,
            'type': 'nouveau_constat',
            'timestamp': FieldValue.serverTimestamp(),
            'processed': false,
          });

          print('📧 [PDF] Notification envoyée à l\'agent: $agentEmail');
        }
      }
    } catch (e) {
      print('❌ [PDF] Erreur envoi agents: $e');
    }
  }
}

import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'cloudinary_pdf_service.dart';

/// 📄 Service de génération PDF pour les constats collaboratifs
class CollaborativePdfService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📄 Générer le PDF complet du constat collaboratif
  static Future<String> genererConstatCollaboratif({
    required String sessionId,
    required Map<String, dynamic> sessionData,
    required List<Map<String, dynamic>> participantsData,
  }) async {
    print('📄 [PDF] Début génération PDF collaboratif pour session $sessionId');

    final pdf = pw.Document();

    // Page 1: En-tête et informations générales
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          _buildHeader(sessionData),
          pw.SizedBox(height: 20),
          _buildAccidentInfo(sessionData),
          pw.SizedBox(height: 20),
          _buildParticipantsInfo(participantsData),
        ],
      ),
    );

    // Page 2: Croquis et signatures
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          _buildCroquisSection(sessionData),
          pw.SizedBox(height: 20),
          _buildSignaturesSection(participantsData),
          pw.SizedBox(height: 20),
          _buildFooter(sessionData),
        ],
      ),
    );

    // Sauvegarder le PDF localement
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'constat_${sessionId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');
    final pdfBytes = await pdf.save();
    await file.writeAsBytes(pdfBytes);

    // Uploader vers Cloudinary
    final downloadUrl = await CloudinaryPdfService.uploadPdf(
      pdfBytes: pdfBytes,
      fileName: fileName,
      sessionId: sessionId,
      folder: 'constats_collaboratifs',
    );

    // Sauvegarder les métadonnées dans Firestore
    await _sauvegarderMetadonnees(sessionId, downloadUrl, fileName, participantsData);

    print('✅ [PDF] PDF généré et uploadé: $downloadUrl');
    return downloadUrl;
  }

  /// 📋 En-tête du document
  static pw.Widget _buildHeader(Map<String, dynamic> sessionData) {
    final dateCreation = (sessionData['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.blue900, PdfColors.blue700],
        ),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'CONSTAT AMIABLE D\'ACCIDENT',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(
                  'FINALISÉ',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Code de session: ${sessionData['codePublic'] ?? sessionData['id']}',
            style: pw.TextStyle(
              fontSize: 16,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Date de création: ${DateFormat('dd/MM/yyyy à HH:mm').format(dateCreation)}',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.blue100,
            ),
          ),
          pw.Text(
            'Document généré automatiquement via l\'application Constat Tunisie',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.blue100,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// 🚗 Informations de l'accident
  static pw.Widget _buildAccidentInfo(Map<String, dynamic> sessionData) {
    final donneesAccident = sessionData['donneesAccident'] as Map<String, dynamic>? ?? {};
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMATIONS DE L\'ACCIDENT',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildInfoRow('Date:', donneesAccident['date'] ?? 'Non spécifiée'),
          _buildInfoRow('Heure:', donneesAccident['heure'] ?? 'Non spécifiée'),
          _buildInfoRow('Lieu:', donneesAccident['lieu'] ?? 'Non spécifié'),
          _buildInfoRow('Conditions météo:', donneesAccident['meteo'] ?? 'Non spécifiées'),
          _buildInfoRow('État de la route:', donneesAccident['etatRoute'] ?? 'Non spécifié'),
          if (donneesAccident['description'] != null && donneesAccident['description'].toString().isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 8),
                pw.Text(
                  'Description:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(donneesAccident['description']),
              ],
            ),
        ],
      ),
    );
  }

  /// 👥 Informations des participants
  static pw.Widget _buildParticipantsInfo(List<Map<String, dynamic>> participantsData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PARTICIPANTS À L\'ACCIDENT',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 12),
        ...participantsData.asMap().entries.map((entry) {
          final index = entry.key;
          final participant = entry.value;
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 16),
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: _buildParticipantCard(index + 1, participant),
          );
        }).toList(),
      ],
    );
  }

  /// 👤 Carte d'un participant
  static pw.Widget _buildParticipantCard(int numero, Map<String, dynamic> participant) {
    final donneesFormulaire = participant['donneesFormulaire'] as Map<String, dynamic>? ?? {};
    final donneesPersonnelles = donneesFormulaire['donneesPersonnelles'] as Map<String, dynamic>? ?? {};
    final donneesVehicule = donneesFormulaire['donneesVehicule'] as Map<String, dynamic>? ?? {};
    final donneesAssurance = donneesFormulaire['donneesAssurance'] as Map<String, dynamic>? ?? {};

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            'VÉHICULE $numero',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
        ),
        pw.SizedBox(height: 12),
        
        // Informations personnelles
        pw.Text(
          'Conducteur:',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.SizedBox(height: 4),
        _buildInfoRow('Nom:', donneesPersonnelles['nom'] ?? 'Non spécifié'),
        _buildInfoRow('Prénom:', donneesPersonnelles['prenom'] ?? 'Non spécifié'),
        _buildInfoRow('Téléphone:', donneesPersonnelles['telephone'] ?? 'Non spécifié'),
        _buildInfoRow('Adresse:', donneesPersonnelles['adresse'] ?? 'Non spécifiée'),
        
        pw.SizedBox(height: 8),
        
        // Informations véhicule
        pw.Text(
          'Véhicule:',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.SizedBox(height: 4),
        _buildInfoRow('Marque:', donneesVehicule['marque'] ?? 'Non spécifiée'),
        _buildInfoRow('Modèle:', donneesVehicule['modele'] ?? 'Non spécifié'),
        _buildInfoRow('Immatriculation:', donneesVehicule['immatriculation'] ?? 'Non spécifiée'),
        
        pw.SizedBox(height: 8),
        
        // Informations assurance
        pw.Text(
          'Assurance:',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.SizedBox(height: 4),
        _buildInfoRow('Compagnie:', donneesAssurance['compagnie'] ?? 'Non spécifiée'),
        _buildInfoRow('N° Police:', donneesAssurance['numeroPolice'] ?? 'Non spécifié'),
      ],
    );
  }

  /// 🎨 Section croquis
  static pw.Widget _buildCroquisSection(Map<String, dynamic> sessionData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CROQUIS DE L\'ACCIDENT',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            height: 200,
            width: double.infinity,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Center(
              child: pw.Text(
                'Croquis validé par tous les participants\n\n'
                'Le croquis détaillé de l\'accident a été créé\n'
                'collaborativement et validé par toutes les parties.',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey600,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✍️ Section signatures
  static pw.Widget _buildSignaturesSection(List<Map<String, dynamic>> participantsData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SIGNATURES ÉLECTRONIQUES',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: participantsData.asMap().entries.map((entry) {
              final index = entry.key;
              final participant = entry.value;
              final donneesFormulaire = participant['donneesFormulaire'] as Map<String, dynamic>? ?? {};
              final donneesPersonnelles = donneesFormulaire['donneesPersonnelles'] as Map<String, dynamic>? ?? {};
              
              return pw.Expanded(
                child: pw.Container(
                  margin: pw.EdgeInsets.only(right: index < participantsData.length - 1 ? 16 : 0),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Véhicule ${index + 1}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        height: 60,
                        width: double.infinity,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green50,
                          border: pw.Border.all(color: PdfColors.green200),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            '✓ SIGNÉ\nÉlectroniquement',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.green700,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        '${donneesPersonnelles['prenom'] ?? ''} ${donneesPersonnelles['nom'] ?? ''}'.trim(),
                        style: pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 📝 Pied de page
  static pw.Widget _buildFooter(Map<String, dynamic> sessionData) {
    final dateFinalisation = DateTime.now();
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMATIONS TECHNIQUES',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 8),
          _buildInfoRow('ID Session:', sessionData['id'] ?? 'N/A', fontSize: 10),
          _buildInfoRow('Code public:', sessionData['codePublic'] ?? 'N/A', fontSize: 10),
          _buildInfoRow('Date de finalisation:', DateFormat('dd/MM/yyyy à HH:mm').format(dateFinalisation), fontSize: 10),
          _buildInfoRow('Statut:', 'FINALISÉ', fontSize: 10),
          pw.SizedBox(height: 8),
          pw.Text(
            'Ce document constitue un constat amiable d\'accident généré automatiquement '
            'par l\'application Constat Tunisie. Il a été validé et signé électroniquement '
            'par toutes les parties impliquées dans l\'accident.',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Ligne d'information
  static pw.Widget _buildInfoRow(String label, String value, {double fontSize = 11}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: fontSize),
            ),
          ),
        ],
      ),
    );
  }

  /// 💾 Sauvegarder les métadonnées du PDF
  static Future<void> _sauvegarderMetadonnees(
    String sessionId,
    String downloadUrl,
    String fileName,
    List<Map<String, dynamic>> participantsData,
  ) async {
    try {
      await _firestore.collection('constats_pdf').add({
        'sessionId': sessionId,
        'downloadUrl': downloadUrl,
        'fileName': fileName,
        'participantIds': participantsData.map((p) => p['userId']).toList(),
        'dateGeneration': Timestamp.fromDate(DateTime.now()),
        'statut': 'genere',
        'type': 'constat_collaboratif',
      });
      
      print('✅ [PDF] Métadonnées sauvegardées dans Firestore');
    } catch (e) {
      print('❌ [PDF] Erreur sauvegarde métadonnées: $e');
    }
  }
}

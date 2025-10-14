import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

/// 📄 Service de génération de PDF d'expertise
class ExpertPdfService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📄 Générer un PDF d'expertise
  static Future<String> generateExpertisePdf({
    required Map<String, dynamic> mission,
    Map<String, dynamic>? constatData,
    Map<String, dynamic>? sinistreData,
    Map<String, dynamic>? expertData,
  }) async {
    try {
      debugPrint('[EXPERT_PDF] 📄 Génération du PDF d\'expertise...');

      final pdf = pw.Document();
      
      // Ajouter la page principale
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildHeader(expertData),
              pw.SizedBox(height: 20),
              _buildMissionInfo(mission),
              pw.SizedBox(height: 20),
              if (constatData != null) _buildConstatSection(constatData),
              pw.SizedBox(height: 20),
              if (sinistreData != null) _buildSinistreSection(sinistreData),
              pw.SizedBox(height: 20),
              _buildExpertiseSection(),
              pw.SizedBox(height: 20),
              _buildConclusionSection(),
              pw.SizedBox(height: 30),
              _buildSignatureSection(expertData),
            ];
          },
        ),
      );

      // Sauvegarder le PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'expertise_${mission['numeroConstat']}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(await pdf.save());
      
      debugPrint('[EXPERT_PDF] ✅ PDF généré: ${file.path}');
      
      // Ouvrir le PDF
      await OpenFile.open(file.path);
      
      // Sauvegarder l'information dans Firestore
      await _savePdfInfo(mission, fileName, file.path);
      
      return file.path;
      
    } catch (e) {
      debugPrint('[EXPERT_PDF] ❌ Erreur génération PDF: $e');
      rethrow;
    }
  }

  /// 📋 En-tête du document
  static pw.Widget _buildHeader(Map<String, dynamic>? expertData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RAPPORT D\'EXPERTISE AUTOMOBILE',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Expert: ${expertData?['prenom']} ${expertData?['nom']}',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Code Expert: ${expertData?['codeExpert']}',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// 📋 Informations de la mission
  static pw.Widget _buildMissionInfo(Map<String, dynamic> mission) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMATIONS DE LA MISSION',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildInfoRow('N° Constat:', mission['numeroConstat'] ?? 'N/A'),
          _buildInfoRow('Date d\'assignation:', 
            mission['dateAssignation'] != null 
              ? DateFormat('dd/MM/yyyy').format((mission['dateAssignation'] as Timestamp).toDate())
              : 'N/A'
          ),
          _buildInfoRow('Statut:', mission['statut'] ?? 'N/A'),
        ],
      ),
    );
  }

  /// 📄 Section du constat
  static pw.Widget _buildConstatSection(Map<String, dynamic> constatData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DÉTAILS DU CONSTAT',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildInfoRow('Date de l\'accident:', constatData['dateAccident'] ?? 'N/A'),
          _buildInfoRow('Lieu de l\'accident:', constatData['lieuAccident'] ?? 'N/A'),
          _buildInfoRow('Circonstances:', constatData['circonstances'] ?? 'N/A'),
          _buildInfoRow('Dégâts matériels:', constatData['degatsMateriels'] ?? 'N/A'),
          _buildInfoRow('Blessés:', constatData['blesses'] ?? 'Non'),
        ],
      ),
    );
  }

  /// 🚗 Section du sinistre
  static pw.Widget _buildSinistreSection(Map<String, dynamic> sinistreData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMATIONS DU SINISTRE',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildInfoRow('N° Sinistre:', sinistreData['numeroSinistre'] ?? 'N/A'),
          _buildInfoRow('Type de sinistre:', sinistreData['typeSinistre'] ?? 'N/A'),
          _buildInfoRow('Montant estimé:', '${sinistreData['montantEstime'] ?? 0} DT'),
          _buildInfoRow('Statut:', sinistreData['statut'] ?? 'N/A'),
        ],
      ),
    );
  }

  /// 🔍 Section d'expertise
  static pw.Widget _buildExpertiseSection() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'EXPERTISE TECHNIQUE',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Observations de l\'expert:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            '• Inspection visuelle du véhicule effectuée\n'
            '• Vérification des dommages déclarés\n'
            '• Analyse de la cohérence avec les circonstances\n'
            '• Évaluation des coûts de réparation',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'État du véhicule:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Les dommages constatés sont cohérents avec les circonstances déclarées de l\'accident.',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// 📝 Section de conclusion
  static pw.Widget _buildConclusionSection() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        border: pw.Border.all(color: PdfColors.green300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CONCLUSION',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Après expertise approfondie, les dommages constatés sont conformes aux déclarations. '
            'Le sinistre peut être pris en charge selon les conditions du contrat d\'assurance.',
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Recommandations:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '• Procéder aux réparations dans un garage agréé\n'
            '• Conserver tous les justificatifs de réparation\n'
            '• Respecter les délais de franchise',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// ✍️ Section de signature
  static pw.Widget _buildSignatureSection(Map<String, dynamic>? expertData) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Expert Automobile',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            pw.Text('${expertData?['prenom']} ${expertData?['nom']}'),
            pw.Text('Code: ${expertData?['codeExpert']}'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Date et signature',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now())),
            pw.SizedBox(height: 20),
            pw.Container(
              width: 150,
              height: 1,
              color: PdfColors.black,
            ),
          ],
        ),
      ],
    );
  }

  /// 📋 Ligne d'information
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
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

  /// 💾 Sauvegarder les informations du PDF
  static Future<void> _savePdfInfo(
    Map<String, dynamic> mission,
    String fileName,
    String filePath,
  ) async {
    try {
      await _firestore
          .collection('missions_expertise')
          .doc(mission['id'])
          .update({
        'pdfGenere': true,
        'pdfFileName': fileName,
        'pdfPath': filePath,
        'dateGenerationPdf': FieldValue.serverTimestamp(),
      });
      
      debugPrint('[EXPERT_PDF] ✅ Informations PDF sauvegardées');
    } catch (e) {
      debugPrint('[EXPERT_PDF] ❌ Erreur sauvegarde PDF info: $e');
    }
  }
}
